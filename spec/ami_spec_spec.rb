require 'spec_helper'

describe AmiSpec do
  let(:amis) { {'web_server' => 'ami-1234abcd', 'db_server' => 'ami-1234abcd'} }
  let(:ec2_double) { instance_double(AmiSpec::AwsInstance) }
  let(:state) { 'running' }
  let(:test_result) { true }
  subject { described_class.run(amis: amis, specs: '/tmp/foobar', subnet_id: 'subnet-1234abcd', key_name: 'key') }

  before do
    allow(AmiSpec::AwsInstance).to receive(:start).and_return(ec2_double)
    allow(AmiSpec::ServerSpec).to receive(:run).and_return(double(result: test_result))
    allow(ec2_double).to receive(:terminate).and_return(true)
    allow(ec2_double).to receive(:state).and_return(state)
    allow_any_instance_of(Object).to receive(:sleep)
  end

  context 'successful tests' do
    it 'calls aws instance for each ami' do
      expect(AmiSpec::AwsInstance).to receive(:start).with(hash_including(role: 'web_server'))
      expect(AmiSpec::AwsInstance).to receive(:start).with(hash_including(role: 'db_server'))
      subject
    end

    it 'returns true' do
      expect(subject).to be_truthy
    end
  end

  context 'failed tests' do
    let(:test_result) { false }

    it 'returns false' do
      expect(subject).to be_falsey
    end
  end

  context 'instances do not start' do
    let(:state) { 'pending' }

    after do
      expect{subject}.to raise_error(AmiSpec::InstanceCreationTimeout)
    end

    it 'raises an exception' do
    end

    it 'still attempts to terminate the instance' do
      expect(ec2_double).to receive(:terminate).twice
    end

    it 'continues to terminate instances even if an exception is raised' do
      allow(ec2_double).to receive(:terminate).and_raise(Aws::EC2::Errors::InvalidInstanceIDNotFound.new('a', 'b'))
      expect(ec2_double).to receive(:terminate)
    end
  end
end
