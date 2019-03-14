require 'aws-sdk-ec2'
require 'logger'
require 'securerandom'
require 'tempfile'
require 'pathname'

module AmiSpec
  class AwsKeyPair

    def self.create(**args)
      new(**args).tap(&:create)
    end

    def initialize(ec2: Aws::EC2::Resource.new, key_name_prefix: 'ami-spec-', logger: Logger.new(STDOUT))
      @ec2 = ec2
      @key_name = "#{key_name_prefix}#{SecureRandom.uuid}"
      @logger = logger
    end

    attr_reader :key_name, :key_file

    def create
      @logger.info "Creating temporary AWS key pair: #{@key_name}"
      @key_pair = @ec2.create_key_pair(key_name: @key_name)
      @temp_file = Tempfile.new('key')
      @temp_file.write(@key_pair.key_material)
      @temp_file.close
      @key_file = Pathname.new(@temp_file.path)
    end

    def delete
      @logger.info "Deleting temporary AWS key pair: #{@key_name}"
      @key_pair.delete
    end
  end
end
