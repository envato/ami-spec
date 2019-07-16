RSpec.describe AmiSpec::AwsSecurityGroup do
  subject(:aws_security_group) do
    described_class.create(
      ec2: ec2,
      subnet_id: test_subnet_id,
      allow_any_ip: allow_any_ip,
      logger: logger
    )
  end

  let(:ec2) { instance_spy(Aws::EC2::Resource, create_security_group: security_group, subnet: subnet) }
  let(:security_group) { instance_spy(Aws::EC2::SecurityGroup, group_id: test_group_id) }
  let(:subnet) { instance_spy(Aws::EC2::Subnet, vpc_id: test_vpc_id, cidr_block: test_cidr_block) }
  let(:test_subnet_id) { 'test-subnet-id' }
  let(:test_group_id) { 'test-group-id' }
  let(:test_vpc_id) { 'test-vpc-id' }
  let(:test_cidr_block) { '172.16.0.0/24' }
  let(:allow_any_ip) { false }
  let(:logger) { instance_spy(Logger) }

  describe '#create' do
    subject(:create) { aws_security_group }

    it 'creates the security group in AWS' do
      create
      expect(ec2).to have_received(:create_security_group).with(group_name: aws_security_group.group_name, vpc_id: test_vpc_id, description: anything)
    end

    context 'given allow_any_ip: true' do
      let(:allow_any_ip) { true }

      it 'adds the ingress rule for SSH, allowing any IP address' do
        create
        expect(security_group).to have_received(:authorize_ingress).with(
          ip_permissions: [{ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{cidr_ip: "0.0.0.0/0"}]}]
        )
      end
    end

    context 'given allow_any_ip: false' do
      let(:allow_any_ip) { false }

      it 'adds the ingress rule for SSH, allowing only IP addresses from the subnet CIDR block' do
        create
        expect(security_group).to have_received(:authorize_ingress).with(
          ip_permissions: [{ip_protocol: "tcp", from_port: 22, to_port: 22, ip_ranges: [{cidr_ip: test_cidr_block}]}]
        )
      end
    end

    it 'loads the subnet to find the vpc id' do
      create
      expect(ec2).to have_received(:subnet).with(test_subnet_id)
    end

    it 'logs the creation of the key pair in AWS' do
      create
      expect(logger).to have_received(:info).with "Creating temporary AWS security group: #{aws_security_group.group_name}"
    end
  end

  describe '#group_name' do
    subject(:key_name) { aws_security_group.group_name }

    it { should start_with('ami-spec-') }
  end

  describe '#group_id' do
    subject(:group_id) { aws_security_group.group_id }

    it 'is obtained from the AWS create-security-group API response' do
      expect(group_id).to eq test_group_id
    end
  end

  describe '#delete' do
    subject(:delete) { aws_security_group.delete }

    it 'deletes the security group in AWS' do
      delete
      expect(security_group).to have_received(:delete)
    end

    it 'logs the deletion of the key pair in AWS' do
      delete
      expect(logger).to have_received(:info).with "Deleting temporary AWS security group: #{aws_security_group.group_name}"
    end
  end
end

