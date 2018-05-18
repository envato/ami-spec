require 'hashie'

module AmiSpec
  class ServerSpecOptions < Hashie::Dash
    include Hashie::Extensions::IgnoreUndeclared

    property :instance
    property :aws_public_ip
    property :debug
    property :key_file
    property :specs
    property :ssh_user
    property :user_data_file
  end
end
