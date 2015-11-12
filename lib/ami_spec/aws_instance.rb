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
      @options = options.fetch(:options, {})
    end

    def_delegators :@instance, :instance_id, :tags, :terminate, :private_ip_address, :public_ip_address

    def start
      client = Aws::EC2::Client.new(client_options)
      placeholder_instance = client.run_instances(instances_options).instances.first

      @instance = Aws::EC2::Instance.new(placeholder_instance.instance_id)
      @instance.wait_until_running
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
        key_name: @key_name,
        network_interfaces: [{
          device_index: 0,
          associate_public_ip_address: !!@options[:public_ip],
          subnet_id: @subnet_id,
        }]
      }

      unless @options[:security_group_ids].nil?
        params[:network_interfaces][0][:groups] = @options[:security_group_ids]
      end

      params
    end

    def tag_instance
      @instance.create_tags(tags: [{ key: 'AmiSpec', value: @role }])
    end
  end
end
