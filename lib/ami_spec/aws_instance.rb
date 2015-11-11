require 'aws-sdk'
require 'forwardable'

module AmiSpec
  class AwsInstance
    extend Forwardable

    def self.start(args)
      instance = new(args)
      instance.start
      instance
    end

    attr_reader :instance

    def initialize(role:, ami:, subnet_id:, key_name:, options: {})
      @role, @ami, @subnet_id, @key_name, @options = role, ami, subnet_id, key_name, options
      @client = Aws::EC2::Client.new(client_parameters)
      @instance = nil
    end

    def_delegators :@instance, :instance_id, :state, :tag, :terminate

    def start
      @instance = @client.run_instances(run_instance_parameters).instances.first
      tag_instance
    end

    private

    def client_parameters
      if @options[:region]
        { region: @options[:region] }
      else
        {}
      end
    end

    def run_instance_parameters
      params = {
        image_id: @ami,
        min_count: 1,
        max_count: 1,
        instance_type: @options[:instance_type] || 't2.micro',
        subnet_id: @subnet_id,
        key_name: @key_name
      }

      [:region, :security_group_ids].each do |opt|
        params[opt] = @options[opt] unless @options[opt].nil?
      end

      params
    end

    def tag_instance
      @client.create_tags(resources: [@instance.instance_id], tags: [{ key: 'AmiSpec', value: @role }])
    end
  end
end
