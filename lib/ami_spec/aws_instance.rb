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

    def initialize(role:, ami:, subnet_id:, key_name:, options: {})
      @role, @ami, @subnet_id, @key_name, @options = role, ami, subnet_id, key_name, options
    end

    def_delegators :@instance, :instance_id, :state, :tags, :terminate

    def start
      client = Aws::EC2::Client.new(client_options)
      placeholder_instance = client.run_instances(instances_options).instances.first

      @instance = Aws::EC2::Instance.new(placeholder_instance.instance_id)
      tag_instance
    end

    private

    def client_options
      !@options[:region].nil? ? {region: @options[:region]} : {}
    end

    def instances_options
      params = {
        image_id: @ami,
        min_count: 1,
        max_count: 1,
        instance_type: @options[:instance_type] || 't2.micro',
        subnet_id: @subnet_id,
        key_name: @key_name
      }

      [:security_group_ids].each do |opt|
        params[opt] = @options[opt] unless @options[opt].nil?
      end

      params
    end

    def tag_instance
      @instance.create_tags(tags: [{ key: 'AmiSpec', value: @role }])
    end
  end
end
