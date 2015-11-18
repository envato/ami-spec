require 'hashie'

module AmiSpec
  class ServerSpecOptions < Hashie::Dash
    include Hashie::Extensions::IgnoreUndeclared

    property :aws_public_ip
    property :debug
    property :instance
    property :key_file
    property :spec
    property :user
  end
end
