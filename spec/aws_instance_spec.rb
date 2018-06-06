require 'spec_helper'
require 'base64'
require 'tempfile'

describe AmiSpec::AwsInstance do
  let(:role) { 'web_server' }
  let(:sec_group_id) { nil }
  let(:region) { nil }
  let(:client_double) { instance_double(Aws::EC2::Client) }
  let(:new_ec2_double) { instance_double(Aws::EC2::Types::Instance) }
  let(:ec2_double) { instance_double(Aws::EC2::Instance) }
  let(:tags) { {} }
  let(:iam_instance_profile_arn) { nil }
  let(:user_data_file) { nil }

  subject(:aws_instance) do
    described_class.new(
      role: role,
      ami: 'ami',
      subnet_id: 'subnet',
      key_name: 'key',
      aws_instance_type: 't2.micro',
      aws_public_ip: false,
      aws_security_groups: sec_group_id,
      aws_region: region,
      tags: tags,
      user_data_file: user_data_file,
      iam_instance_profile_arn: iam_instance_profile_arn
    )
  end

  before do
    allow(Aws::EC2::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:run_instances).and_return(double(instances: [new_ec2_double]))
    allow(ec2_double).to receive(:create_tags).and_return(double)
    allow(Aws::EC2::Instance).to receive(:new).and_return(ec2_double)
    allow(new_ec2_double).to receive(:instance_id)
    allow(ec2_double).to receive(:instance_id)
    allow(ec2_double).to receive(:wait_until_running)
  end

  describe '#start' do
    subject(:start) { aws_instance.start }
    context 'without optional values' do
      it 'does not include the security group' do
        expect(client_double).to receive(:run_instances).with(
                                   hash_excluding(:network_interfaces=>array_including(hash_including(:groups)))
                                 )
        start
      end

      it 'does include the region' do
        expect(Aws::EC2::Client).to receive(:new).with(
                                      hash_excluding(:region => region)
                                    )
        start
      end
    end

    context 'with security group' do
      let(:sec_group_id) { ['1234'] }

      it 'does include security groups' do
        expect(client_double).to receive(:run_instances).with(
                                   hash_including(:network_interfaces=>array_including(hash_including(:groups)))
                                 )
        start
      end
    end

    context 'with region' do
      let(:region) { 'us-east-1' }

      it 'does include the region in the intial connection' do
        expect(Aws::EC2::Client).to receive(:new).with(
                                      hash_including(:region => region)
                                    )
        start
      end

      it 'does include the region in the subsequent connection' do
        expect(Aws::EC2::Instance).to receive(:new).with(
                                        anything,
                                        hash_including(:region => region)
                                      )
        start
      end
    end

    context 'with tags' do
      let(:tags) { {"Name" => "AmiSpec"} }

      it 'tags the instance' do
        expect(ec2_double).to receive(:create_tags).with(
                                 {tags: [{ key: 'AmiSpec', value: role}, { key: "Name", value: "AmiSpec"}]}
                               )
        start
      end
    end

    context 'with user_data' do
      let(:user_data_file) {
        file = Tempfile.new('user_data.txt')
        file.write("my file\ncontent")
        file.close
        file.path
      }

      it 'does include user_data' do
        expect(client_double).to receive(:run_instances).with(
            hash_including(:user_data =>  Base64.encode64("my file\ncontent"))
        )
        start
      end
    end

    context 'with iam_instance_profile_arn' do
      let(:iam_instance_profile_arn) { "my_arn" }

      it 'does include iam_instance_profile_arn' do
        expect(client_double).to receive(:run_instances).with(
            hash_including(:iam_instance_profile =>  { arn: 'my_arn'})
        )
        start
      end
    end

    it 'tags the instance with a role' do
      expect(ec2_double).to receive(:create_tags).with(
                                 hash_including(tags: [{ key: 'AmiSpec', value: role}])
                               )
      start
    end

    it 'delegates some methods to the instance variable' do
      expect(ec2_double).to receive(:instance_id)
      start
      aws_instance.instance_id
    end
  end

end
