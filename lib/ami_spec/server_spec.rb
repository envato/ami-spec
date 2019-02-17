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
      @buildkite = options.fetch(:buildkite)
      @user_data_file = options.fetch(:user_data_file)
      @iam_instance_profile_arn = options.fetch(:user_data_file)
    end

    def run
      if @buildkite
        puts "--- Running tests for #{@role}"
      else
        puts "Running tests for #{@role}"
      end

      $LOAD_PATH.unshift(@spec) unless $LOAD_PATH.include?(@spec)
      begin
        require File.join(@spec, 'spec_helper')
      rescue LoadError
        puts 'Spec Helper does not exist. Skipping!'
      end

      set :backend, :ssh
      set :host, @ip
      set :ssh_options, :user => @user, :keys => [@key_file], :paranoid => false

      RSpec.configuration.fail_fast = true if @debug

      RSpec::Core::Runner.disable_autorun!
      result = RSpec::Core::Runner.run(Dir.glob("#{@spec}/#{@role}/*_spec.rb"))

      # We can't use Rspec.clear_examples here because it also clears the shared_examples.
      # As shared examples are loaded in via the spec_helper, we cannot reload them.
      RSpec.world.example_groups.clear

      Specinfra::Backend::Ssh.clear

      puts "^^^ +++" if @buildkite && !result.zero?
      result.zero?
    end
  end
end
