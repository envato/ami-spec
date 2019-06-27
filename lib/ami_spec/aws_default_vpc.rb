require 'aws-sdk-ec2'

module AmiSpec
  class AwsDefaultVpc
    def self.find_subnet(ec2: Aws::EC2::Resource.new)
      default_vpc = ec2.vpcs(filters: [{name: 'isDefault', values: ['true']}]).first
      default_vpc && default_vpc.subnets.first
    end
  end
end
