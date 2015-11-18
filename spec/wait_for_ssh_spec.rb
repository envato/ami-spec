require 'spec_helper'

describe AmiSpec::WaitForSSH do
  describe '#wait' do
    subject { described_class.wait('127.0.0.1', 'ubuntu', 'key.pem', 30) }

    it 'returns after one attempt if ssh connection succeeds' do
      expect(Net::SSH).to receive(:start)

      subject
    end

    context 'ssh fails' do
      before do
        allow(Net::SSH).to receive(:start).and_raise(Errno::ECONNREFUSED, 'ssh failed')
      end

      it 'raises an exception' do
        expect{subject}.to raise_error(AmiSpec::InstanceConnectionTimeout)
      end

      it 'returns the last error' do
        expect(Net::SSH).to receive(:start).and_raise(Errno::ECONNREFUSED, 'some other error')
        expect{subject}.to raise_error(AmiSpec::InstanceConnectionTimeout, /ssh failed/)
      end
    end
  end
end
