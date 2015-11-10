module AmiSpec
  class ServerSpec
    def self.run(*args)
      self.new(args).tap do |instance|
        instance.run
      end
    end

    def initialize(tag:, role:)

    end
  end
end
