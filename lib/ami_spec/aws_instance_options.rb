require 'hashie'

module AmiSpec
  class AwsInstanceOptions < Hashie::Dash
    include Hashie::Extensions::IgnoreUndeclared

    property :ami
    property :role
    property :subnet_id
    property :key_name
    property :aws_instance_type
    property :aws_public_ip
    property :aws_region
    property :aws_security_groups
  end
end
