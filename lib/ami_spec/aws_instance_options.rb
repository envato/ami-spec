require 'hashie'

module AmiSpec
  class AwsInstanceOptions < Hashie::Dash
    include Hashie::Extensions::IgnoreUndeclared

    property :ami
    property :instance_type
    property :key_name
    property :public_ip
    property :region
    property :role
    property :security_group_ids
    property :subnet_id
  end
end
