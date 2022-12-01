require 'ami_spec/aws_instance'
require 'ami_spec/aws_instance_options'
require 'ami_spec/aws_default_vpc'
require 'ami_spec/aws_key_pair'
require 'ami_spec/aws_security_group'
require 'ami_spec/server_spec'
require 'ami_spec/server_spec_options'
require 'ami_spec/wait_for_ssh'
require 'ami_spec/wait_for_rc'
require 'ami_spec/wait_for_cloud_init'
require 'optimist'
require 'logger'

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
  #   The SSH key name to assign to instances. If not provided a temporary key pair will be generated in AWS
  # key_file::
  #   The SSH key file to use to connect to the host.
  # aws_region::
  #   AWS region to connect to
  #   Defaults to AWS_DEFAULT_REGION
  # aws_security_group_ids::
  #   AWS Security groups to assign to the instances
  #   If not provided a temporary security group will be generated in AWS
  # allow_any_temporary_security_group::
  #   The temporary security group will allow SSH connections from any IP address (0.0.0.0/0)
  # aws_instance_type::
  #   AWS ec2 instance type
  # aws_public_ip::
  #   Should the instances get a public IP address and use that IP for SSH
  # associate_public_ip::
  #   Launch instances with a public IP but don't use that IP for SSH
  # ssh_user::
  #   The username to SSH to the AMI with.
  # ssh_retries::
  #   Set the maximum number of ssh retries while waiting for the instance to boot.
  # tags:::
  #   Additional tags to add to launched instances in the form of comma separated key=value pairs
  # debug::
  #   Don't terminate the instances on exit
  # buildkite::
  #   Output section separators for buildkite
  # == Returns:
  # Boolean - The result of all the server specs.
  def self.run(options)
    logger = Logger.new(STDOUT, formatter: proc { |_sev, _time, _name, message| "#{message}\n" })

    ec2 = Aws::EC2::Resource.new(options[:aws_region] ? {region: options[:aws_region]} : {})

    if options[:subnet_id].nil?
      default_vpc_subnet = AwsDefaultVpc.find_subnet(ec2: ec2)
      raise 'No default VPC subnet found. Please specify a subnet id.' if default_vpc_subnet.nil?
      options[:subnet_id] = default_vpc_subnet.id
      logger.info("Using subnet #{options[:subnet_id]} from the default VPC")
    end

    unless options[:key_name]
      key_pair = AwsKeyPair.create(ec2: ec2, logger: logger)
      options[:key_name] = key_pair.key_name
      options[:key_file] = key_pair.key_file
    end

    if options[:aws_security_groups].nil? || options[:aws_security_groups].empty?
      temporary_security_group = AwsSecurityGroup.create(
        ec2: ec2,
        subnet_id: options[:subnet_id],
        allow_any_ip: options[:allow_any_temporary_security_group],
        logger: logger
      )
      options[:aws_security_groups] = [temporary_security_group.group_id]
    end

    instances = []
    options[:amis].each_pair do |role, ami|
      aws_instance_options = AwsInstanceOptions.new(options.merge(role: role, ami: ami, logger: logger))
      instances << AwsInstance.start(aws_instance_options)
    end

    results = []
    instances.each do |instance|
      ip_address = options[:aws_public_ip] ? instance.public_ip_address : instance.private_ip_address
      logger.info("Waiting for SSH…")
      WaitForSSH.wait(ip_address, options[:ssh_user], options[:key_file], options[:ssh_retries])
      if options[:wait_for_rc]
        logger.info("Waiting for RC…")
        WaitForRC.wait(ip_address, options[:ssh_user], options[:key_file])
      end
      if options[:wait_for_cloud_init]
        logger.info("Waiting for cloud init…")
        WaitForCloudInit.wait(ip_address, options[:ssh_user], options[:key_file])
      end

      logger.info("Running serverspec…")
      server_spec_options = ServerSpecOptions.new(options.merge(instance: instance))
      results << ServerSpec.new(server_spec_options).run
     end

    results.all?
  ensure
    stop_instances(instances, options[:debug])
    key_pair.delete if key_pair
    temporary_security_group.delete if temporary_security_group
  end

  def self.stop_instances(instances, debug)
    instances && instances.each do |instance|
      begin
        if debug
          puts "EC2 instance ##{instance.instance_id} has not been stopped due to debug mode."
        else
          instance.terminate
        end
      rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
        puts "Failed to stop EC2 instance ##{instance.instance_id}"
      end
    end
  end

  private_class_method :stop_instances

  def self.invoke
    options = Optimist::options do
      opt :role,
          'The role to test, this should map to a directory in the spec folder',
          type: :string, short: :r
      opt :ami, 'The ami ID to run tests against', type: :string, short: :a
      opt :role_ami_file,
          'A file containing comma separated roles and amis. i.e.
web_server,ami-id.',
          type: :string, short: :o
      opt :specs, 'The directory to find ServerSpecs',
          type: :string, required: true, short: :s
      opt :subnet_id,
          'The subnet to start the instance in. If not provided a subnet will be chosen from the default VPC',
          type: :string, short: :u
      opt :key_name, 'The SSH key name to assign to instances. If not provided a temporary key pair will be generated in AWS',
          type: :string, short: :k
      opt :key_file, 'The SSH private key file associated to the key_name', type: :string, short: :e
      opt :ssh_user, 'The user to ssh to the instance as', type: :string, required: true, short: :h
      opt :aws_region, 'The AWS region, defaults to AWS_DEFAULT_REGION environment variable',
          type: :string, short: :w
      opt :aws_instance_type, 'The ec2 instance type, defaults to t2.micro',
          type: :string, default: 't2.micro', short: :i
      opt :aws_security_groups,
          'Security groups to associate to the launched instances. May be specified multiple times. If not provided a temporary security group will be generated in AWS',
          type: :string, default: nil, multi: true, short: :c
      opt :allow_any_temporary_security_group, 'The temporary security group will allow SSH connections from any IP address (0.0.0.0/0)',
          short: :n
      opt :aws_public_ip, 'Launch instances with a public IP and use that IP for SSH', short: :p
      opt :associate_public_ip, "Launch instances with a public IP but don't use that IP for SSH", short: :q
      opt :ssh_retries, 'The number of times we should try sshing to the ec2 instance before giving up. Defaults to 30',
          type: :int, default: 30, short: :t
      opt :tags, 'Additional tags to add to launched instances in the form of comma separated key=value pairs. i.e. Name=AmiSpec',
          type: :string, default: '', short: :g
      opt :debug, "Don't terminate instances on exit", short: :d
      opt :buildkite, 'Output section separators for buildkite', short: :b
      opt :wait_for_rc, 'Wait for oldschool SystemV scripts to run before conducting tests. Currently only supports Ubuntu with upstart',
          short: :f
      opt :wait_for_cloud_init, 'Wait for Cloud Init to complete before running tests'
      opt :user_data_file, 'File path for aws ec2 user data', type: :string, default: nil, short: :l
      opt :iam_instance_profile_arn, 'IAM instance profile to use', type: :string, short: :m
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

    fail "Key file #{options[:key_file]} not found" if options[:key_name] && !File.exist?(options.fetch(:key_file))

    if options[:user_data_file] and !File.exist? options[:user_data_file]
      fail "User Data file #{options[:user_data_file]} not found"
    end

    options[:tags] = parse_tags(options[:tags])

    options[:amis].each_pair do |role, _|
      unless Dir.exist?("#{options[:specs]}/#{role}")
        fail "Role directory #{options[:specs]}/#{role} does not exist. If you'd like to skip the role '#{role}', create the directory but leave it empty (except for a .gitignore file)."
      end
    end

    exit run(options)
  end

  def self.parse_tags(tags)
    tag_pairs = tags.split(',')
    tag_key_values = tag_pairs.collect{ |pair| pair.split('=')}.flatten
    Hash[*tag_key_values]
  end
end
