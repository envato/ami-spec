require 'spec_helper'

describe AmiSpec::AwsKeyPair do
  subject(:aws_key_pair) { described_class.create(ec2: ec2) }

  let(:ec2) { instance_spy(Aws::EC2::Resource, create_key_pair: key_pair) }
  let(:key_pair) { instance_spy(Aws::EC2::KeyPair, key_material: key_material) }
  let(:key_material) { 'test-key-material' }

  describe '#create' do
    subject(:create) { aws_key_pair }

    it 'creates the key pair in AWS' do
      create
      expect(ec2).to have_received(:create_key_pair).with(key_name: aws_key_pair.key_name)
    end
  end

  describe '#key_name' do
    subject(:key_name) { aws_key_pair.key_name }

    it { should start_with('ami-spec-') }
  end

  describe '#key_file' do
    subject(:key_file) { aws_key_pair.key_file }

    it { should exist }

    it 'should contain key material' do
      expect(key_file.read).to eq(key_material)
    end

    it { should be_a Pathname }
  end

  describe '#delete' do
    subject(:delete) { aws_key_pair.delete }

    it 'deletes the key pair in AWS' do
      delete
      expect(key_pair).to have_received(:delete)
    end
  end
end

