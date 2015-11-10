require 'ami_spec/aws_instance'
require 'ami_spec/server_spec'

module AmiSpec
  # == Parameters:
  # amis::
  #   A hash of roles and amis in the format of:
  #   {role => ami_id}. i.e.
  #   {'web_server' => 'ami-abcd1234'}
  # specs::
  #   A string of the directory to find ServerSpecs.
  #   There should be a folder in this directory for each role found in ::amis
  def self.run(amis, specs)
    instances = []
    amis.each_pair do |role, ami|
      instances.push(AwsInstance.start(tag: role, ami: ami))
    end

    # Wait for instances to start

    results = []
    instances.each do |ec2|
      results.push(ServerSpec.run(instance: ec2, specs: specs).result)
    end

    results.all?
  end
end
