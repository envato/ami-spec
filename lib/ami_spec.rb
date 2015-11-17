require 'ami_spec/aws_instance'
require 'ami_spec/server_spec'
require 'trollop'

module AmiSpec
  class InstanceConnectionTimeout < StandardError; end
  # == Parameters:
  # amis::
  #   A hash of roles and amis in the format of:
  #   {role => ami_id}. i.e.
  #   {'web_server' => 'ami-abcd1234'}
  # specs::
  #   A string of the directory to find ServerSpecs.
  #   There should be a folder in this directory for each role found in ::amis
  # subnet_id::
  #   The subnet_id to start instances in.
  # key_name::
  #   The SSH key name to assign to instances. This key name must exist on the executing host for passwordless login.
  # key_file::
  #   The SSH key file to use to connect to the host.
  # aws_region::
  #   AWS region to connect to
  #   Defaults to AWS_DEFAULT_REGION
  # aws_security_group_ids::
  #   AWS Security groups to assign to the instances
  #   Defaults to the default security group for the VPC
  # aws_instance_type::
  #   AWS ec2 instance type
  # aws_public_ip::
  #   Should the instances get a public IP address
  # ssh_user::
  #   The username to SSH to the AMI with.
  # ssh_retries::
  #   Set the maximum number of ssh retries while waiting for the instance to boot.
  # debug::
  #   Don't terminate the instances on exit
  # == Returns:
  # Boolean - The result of all the server specs.
  def self.run(options)
    amis = options.fetch(:amis)
    specs = options.fetch(:specs)
    subnet_id = options.fetch(:subnet_id)
    key_name = options.fetch(:key_name)
    key_file = options.fetch(:key_file)
    aws_public_ip = options.fetch(:aws_public_ip)
    aws_instance_type = options.fetch(:aws_instance_type)
    aws_security_groups = options.fetch(:aws_security_groups, nil)
    aws_region = options.fetch(:aws_region, nil)
    ssh_user = options.fetch(:ssh_user)
    debug = options.fetch(:debug)
    ssh_retries = options.fetch(:ssh_retries)

    instances = []
    amis.each_pair do |role, ami|
      instances.push(
        AwsInstance.start(
          role: role,
          ami: ami,
          subnet_id: subnet_id,
          key_name: key_name,
          public_ip: aws_public_ip,
          instance_type: aws_instance_type,
          security_group_ids: aws_security_groups,
          region: aws_region,
        )
      )
    end

    results = []
    instances.each do |ec2|
      ip = options[:aws_public_ip] ? ec2.public_ip_address : ec2.private_ip_address
      wait_for_ssh(ip: ip, user: ssh_user, key_file: key_file, retries: ssh_retries)
      results.push(
        ServerSpec.run(
          instance: ec2,
          spec: specs,
          private_ip: options[:aws_public_ip],
          user: ssh_user,
          key_file: key_file,
          debug: debug,
        )
      )
    end

    results.all?
  ensure
    instances.each do |ec2|
      begin
        ec2.terminate unless debug
      rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
        puts "Failed to stop #{ec2.instance_id}"
      end
    end
  end

  def self.wait_for_ssh(options)
    ip = options.fetch(:ip)
    user = options.fetch(:user)
    key_file = options.fetch(:key_file)
    retries = options.fetch(:retries)

    last_error = ''
    while retries > 0
      begin
        Net::SSH.start(ip, user, keys: [key_file]) { |ssh| ssh.exec 'echo boo!'}
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Timeout::Error => error
        last_error = error
      else
        break
      end
      retries = retries - 1
    end

    if retries < 1
      raise InstanceConnectionTimeout.new("Timed out waiting for SSH to become available: #{last_error}")
    end
  end

  def self.invoke
    options = Trollop::options do
      opt :role, "The role to test, this should map to a directory in the spec folder", type: :string
      opt :ami, "The ami ID to run tests against", type: :string
      opt :role_ami_file, "A file containing comma separated roles and amis. i.e.\nweb_server,ami-id.",
          type: :string
      opt :specs, "The directory to find ServerSpecs", type: :string, required: true
      opt :subnet_id, "The subnet to start the instance in", type: :string, required: true
      opt :key_name, "The SSH key name to assign to instances", type: :string, required: true
      opt :key_file, "The SSH private key file associated to the key_name", type: :string, required: true
      opt :ssh_user, "The user to ssh to the instance as", type: :string, required: true
      opt :aws_region, "The AWS region, defaults to AWS_DEFAULT_REGION environment variable", type: :string
      opt :aws_instance_type, "The ec2 instance type, defaults to t2.micro", type: :string, default: 't2.micro'
      opt :aws_security_groups, "Security groups to associate to the launched instances. May be specified multiple times",
          type: :strings, default: nil
      opt :aws_public_ip, "Launch instances with a public IP"
      opt :ssh_retries, "The number of times we should try sshing to the ec2 instance before giving up. Defaults to 30",
          type: :int, default: 30
      opt :debug, "Don't terminate instances on exit"
    end

    if options[:role] && options[:ami]
      options[:amis] = { options[:role] => options[:ami] }
      options.delete(:role)
      options.delete(:ami)
    elsif options[:role_ami_file]
      file_lines = File.read(options[:role_ami_file]).split("\n")
      file_array = file_lines.collect { |line| line.split(',') }.flatten
      options[:amis] = Hash[*file_array]
      options.delete(:role_ami_file)
    else
      fail "You must specify either role and ami or role_ami_file"
    end

    exit run(options)
  end
end
