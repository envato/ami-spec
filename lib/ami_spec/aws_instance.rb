require 'aws-sdk'

module AmiSpec
  class AwsInstance
    def self.start(*args)
      self.new(args).tap do |instance|
        instance.start
      end
    end

    def initialize(tag:, role:)

    end
  end
end
