# Loading serverspec first causes a weird error - stack level too deep
# Requiring rspec first fixes that *shrug*
require 'rspec'
require 'serverspec'

module AmiSpec
  class ServerSpec
    def initialize(options)
      instance = options.fetch(:instance)
      public_ip = options.fetch(:aws_public_ip)

      @debug = options.fetch(:debug)
      @ip = public_ip ? instance.public_ip_address : instance.private_ip_address
      @role = instance.tags.find{ |tag| tag.key == 'AmiSpec' }.value
      @spec = options.fetch(:specs)
      @user = options.fetch(:ssh_user)
      @key_file = options.fetch(:key_file)
    end

    def run
      $LOAD_PATH.unshift(@spec) unless $LOAD_PATH.include?(@spec)
      require File.join(@spec, 'spec_helper')

      set :backend, :ssh
      set :host, @ip
      set :ssh_options, :user => @user, :keys => [@key_file], :paranoid => false

      RSpec.configuration.fail_fast = true if @debug

      RSpec::Core::Runner.disable_autorun!
      result = RSpec::Core::Runner.run(Dir.glob("#{@spec}/#{@role}/*_spec.rb"))

      result.zero?
    end
  end
end
