require 'spec_helper'

describe AmiSpec do
  let(:amis) { {'web_server' => 'ami-1234abcd', 'db_server' => 'ami-1234abcd'} }
  let(:specs) { '/tmp/foobar' }
  subject { described_class.run(amis, specs) }

  before do
    allow(AmiSpec::AwsInstance).to receive(:start).and_return(double)
    allow(AmiSpec::AwsInstance).to receive(:start).and_return(double)
    allow(AmiSpec::ServerSpec).to receive(:run).and_return(double(result: test_result))
  end

  describe 'successful tests' do
    let(:test_result) { true }

    it 'calls aws instance for each ami' do
      expect(AmiSpec::AwsInstance).to receive(:start).with(tag: 'web_server', ami: 'ami-1234abcd').and_return(double)
      expect(AmiSpec::AwsInstance).to receive(:start).with(tag: 'db_server', ami: 'ami-1234abcd').and_return(double)
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
