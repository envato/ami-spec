require 'aws-sdk-ec2'
require 'securerandom'
require 'tempfile'
require 'pathname'

module AmiSpec
  class AwsKeyPair

    def self.create(**args)
      new(**args).tap(&:create)
    end

    def initialize(ec2: Aws::EC2::Resource.new, key_name_prefix: 'ami-spec-')
      @ec2 = ec2
      @key_name = "#{key_name_prefix}#{SecureRandom.uuid}"
    end

    attr_reader :key_name, :key_file

    def create
      @key_pair = @ec2.create_key_pair(key_name: @key_name)
      @temp_file = Tempfile.new
      @temp_file.write(@key_pair.key_material)
      @temp_file.close
      @key_file = Pathname.new(@temp_file.path)
    end

    def delete
      @key_pair.delete
    end
  end
end
