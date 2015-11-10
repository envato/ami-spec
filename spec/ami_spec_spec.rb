require 'spec_helper'

describe AmiSpec do
  let(:amis) { {'web_server' => 'ami-1234abcd', 'db_server' => 'ami-1234abcd'} }
  subject { described_class.run(amis: amis, specs: '/tmp/foobar', subnet_id: 'subnet-1234abcd', key_name: 'key') }

  before do
    allow(AmiSpec::AwsInstance).to receive(:start).and_return(double(terminate: true))
    allow(AmiSpec::ServerSpec).to receive(:run).and_return(double(result: test_result))
  end

  describe 'successful tests' do
    let(:test_result) { true }

    it 'calls aws instance for each ami' do
      expect(AmiSpec::AwsInstance).to receive(:start).with(hash_including(role: 'web_server'))
      expect(AmiSpec::AwsInstance).to receive(:start).with(hash_including(role: 'db_server'))
      subject
    end

    it 'returns true' do
      expect(subject).to be_truthy
    end
  end

  describe 'failed tests' do
    let(:test_result) { false }

    it 'returns false' do
      expect(subject).to be_falsey
    end
  end
end
