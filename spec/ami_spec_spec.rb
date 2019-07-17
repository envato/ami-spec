RSpec.describe AmiSpec do
  let(:amis) { {'web_server' => 'ami-1234abcd', 'db_server' => 'ami-1234abcd'} }
  let(:ec2) { instance_spy(Aws::EC2::Resource) }
  let(:ec2_double) { instance_double(AmiSpec::AwsInstance) }
  let(:aws_key_pair) { instance_spy(AmiSpec::AwsKeyPair) }
  let(:aws_security_group) { instance_spy(AmiSpec::AwsSecurityGroup) }
  let(:state) { double(name: 'running') }
  let(:test_result) { true }
  let(:server_spec_double) { double(run: test_result) }
  let(:key_name) { 'key' }
  let(:security_groups) { ['sg-1234'] }
  let(:subnet_id) { 'subnet-1234abcd' }
  let(:allow_any_temporary_security_group) { false }
  subject do
    described_class.run(
      amis: amis,
      specs: '/tmp/foobar',
      subnet_id: subnet_id,
      key_name: key_name,
      key_file: 'key.pem',
      aws_public_ip: false,
      aws_instance_type: 't2.micro',
      ssh_user: 'ubuntu',
      debug: false,
      ssh_retries: 30,
      aws_security_groups: security_groups,
      allow_any_temporary_security_group: allow_any_temporary_security_group,
    )
  end


  describe '#invoke' do
    context 'given no arguments' do
      it 'prints to STDERR and raises a system exit' do
        expect{ described_class.invoke }.to output.to_stderr.and raise_error(SystemExit)
      end
    end
  end

  describe '#run' do
    before do
      allow(AmiSpec::WaitForSSH).to receive(:wait).and_return(true)
      allow(AmiSpec::AwsInstance).to receive(:start).and_return(ec2_double)
      allow(AmiSpec::ServerSpec).to receive(:new).and_return(server_spec_double)
      allow(AmiSpec::AwsKeyPair).to receive(:create).and_return(aws_key_pair)
      allow(AmiSpec::AwsSecurityGroup).to receive(:create).and_return(aws_security_group)
      allow(Aws::EC2::Resource).to receive(:new).and_return(ec2)
      allow(ec2_double).to receive(:terminate).and_return(true)
      allow(ec2_double).to receive(:private_ip_address).and_return('127.0.0.1')
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

    context 'given a key name is not provided' do
      let(:key_name) { nil }

      it 'creates a key pair' do
        subject
        expect(AmiSpec::AwsKeyPair).to have_received(:create)
      end

      it 'deletes the key pair' do
        subject
        expect(aws_key_pair).to have_received(:delete)
      end
    end

    context 'given a key name is provided' do
      let(:key_name) { 'key' }

      it 'does not create a key pair' do
        subject
        expect(AmiSpec::AwsKeyPair).not_to have_received(:create)
      end
    end

    context 'given a security group id is not provided' do
      let(:security_groups) { [] }

      it 'creates a temporary security group' do
        subject
        expect(AmiSpec::AwsSecurityGroup).to have_received(:create)
      end

      it 'passes the subnet id' do
        subject
        expect(AmiSpec::AwsSecurityGroup).to have_received(:create)
          .with(a_hash_including(subnet_id: subnet_id))
      end

      context 'given allow_any_temporary_security_group: true' do
        let(:allow_any_temporary_security_group) { true }

        it 'passes allow_any_ip: true' do
          subject
          expect(AmiSpec::AwsSecurityGroup).to have_received(:create)
            .with(a_hash_including(allow_any_ip: true))
        end
      end

      context 'given allow_any_temporary_security_group: false' do
        let(:allow_any_temporary_security_group) { false }

        it 'passes allow_any_ip: true' do
          subject
          expect(AmiSpec::AwsSecurityGroup).to have_received(:create)
            .with(a_hash_including(allow_any_ip: false))
        end
      end

      it 'deletes the temporary security group' do
        subject
        expect(aws_security_group).to have_received(:delete)
      end
    end

    context 'given a security group id is provided' do
      let(:security_groups) { ['sg-4321'] }

      it 'does not create a temporary security group' do
        subject
        expect(AmiSpec::AwsSecurityGroup).not_to have_received(:create)
      end
    end
  end

  describe '#parse_tags' do
    it 'parses a single key/value pair' do
      expect(described_class.parse_tags("Name=AmiSpec")).to eq( { "Name"=>"AmiSpec" } )
    end

    it 'parses multiple key/value pairs' do
      expect(described_class.parse_tags("Name=AmiSpec,Owner=Me")).to eq( { "Name"=>"AmiSpec", "Owner"=>"Me" } )
    end

    it 'parses an empty string' do
      expect(described_class.parse_tags("")).to eq({})
    end
  end
end
