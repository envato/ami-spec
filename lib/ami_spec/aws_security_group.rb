require 'aws-sdk-ec2'
require 'forwardable'
require 'securerandom'

module AmiSpec
  class AwsSecurityGroup
    extend Forwardable

    def self.create(**args)
      new(**args).tap(&:create)
    end

    def initialize(ec2: Aws::EC2::Resource.new,
                   group_name_prefix: "ami-spec-",
                   connection_port: 22,
                   subnet_id:,
                   allow_any_ip: false,
                   logger: Logger.new(STDOUT))
      @ec2 = ec2
      @group_name = "#{group_name_prefix}#{SecureRandom.uuid}"
      @connection_port = connection_port
      @subnet_id = subnet_id
      @allow_any_ip = allow_any_ip
      @logger = logger
    end

    def_delegators :@security_group, :group_id
    attr_reader :group_name

    def create
      @logger.info "Creating temporary AWS security group: #{@group_name}"
      create_security_group
      allow_ingress_via_connection_port
    end

    def delete
      @logger.info "Deleting temporary AWS security group: #{@group_name}"
      @security_group.delete
    end

    private

    def create_security_group
      @security_group = @ec2.create_security_group(
        group_name: @group_name,
        description: "A temporary security group for running AmiSpec",
        vpc_id: subnet.vpc_id,
      )
    end

    def allow_ingress_via_connection_port
      @security_group.authorize_ingress(
        ip_permissions: [
          {
            ip_protocol: "tcp",
            from_port: @connection_port,
            to_port: @connection_port,
            ip_ranges: [{cidr_ip: cidr_block}],
          },
        ],
      )
    end

    def cidr_block
      @allow_any_ip ? "0.0.0.0/0" : subnet.cidr_block
    end

    def subnet
      @subnet ||= @ec2.subnet(@subnet_id)
    end
  end
end
