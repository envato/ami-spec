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
    property :associate_public_ip
    property :tags
    property :user_data_file
    property :iam_instance_profile_arn
  end
end
