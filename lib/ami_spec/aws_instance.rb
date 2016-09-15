require 'aws-sdk'
require 'forwardable'

module AmiSpec
  class AwsInstance
    extend Forwardable

    def self.start(args)
      new(args).tap do |instance|
        instance.start
      end
    end

    def initialize(options)
      @role = options.fetch(:role)
      @ami = options.fetch(:ami)
      @subnet_id = options.fetch(:subnet_id)
      @key_name = options.fetch(:key_name)
      @instance_type = options.fetch(:aws_instance_type)
      @public_ip = options.fetch(:aws_public_ip)
      @region = options.fetch(:aws_region)
      @security_group_ids = options.fetch(:aws_security_groups)
      @tags = ec2ify_tags(options.fetch(:tags))
    end

    def_delegators :@instance, :instance_id, :tags, :terminate, :private_ip_address, :public_ip_address

    def start
      client = Aws::EC2::Client.new(client_options)
      placeholder_instance = client.run_instances(instances_options).instances.first

      @instance = Aws::EC2::Instance.new(placeholder_instance.instance_id, client_options)
      @instance.wait_until_running
      tag_instance
    end

    private

    def client_options
      !@region.nil? ? {region: @region} : {}
    end

    def ec2ify_tags(tags)
      tags.map { |k,v| {key: k, value: v} }
    end

    def instances_options
      params = {
        image_id: @ami,
        min_count: 1,
        max_count: 1,
        instance_type: @instance_type,
        key_name: @key_name,
        network_interfaces: [{
          device_index: 0,
          associate_public_ip_address: @public_ip,
          subnet_id: @subnet_id,
        }]
      }

      unless @security_group_ids.nil?
        params[:network_interfaces][0][:groups] = @security_group_ids
      end

      params
    end

    def tag_instance
      @instance.create_tags(tags: [{ key: 'AmiSpec', value: @role }] + @tags)
    end
  end
end
