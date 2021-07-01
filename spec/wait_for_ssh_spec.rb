RSpec.describe AmiSpec::WaitForSSH do
  describe '#wait' do
    let(:retries) { 30 }
    subject { described_class.wait('127.0.0.1', 'ubuntu', 'key.pem', 30) }

    before do
      allow_any_instance_of(Object).to receive(:sleep)
    end

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
        expect(Net::SSH).to receive(:start).and_raise(Net::SSH::ConnectionTimeout, 'some other error')
        expect{subject}.to raise_error(AmiSpec::InstanceConnectionTimeout, /ssh failed/)
      end

      it 'tries the number of retries specified' do
        expect(Net::SSH).to receive(:start).exactly(retries).times

        expect{subject}.to raise_error(AmiSpec::InstanceConnectionTimeout)
      end
    end
  end
end
