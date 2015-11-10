require 'serverspec'

module AmiSpec
  class ServerSpec
    def self.run(args)
      new(args).tap(&:run)
    end

    def initialize(instance:, spec:)

    end

    def run

    end
  end
end
