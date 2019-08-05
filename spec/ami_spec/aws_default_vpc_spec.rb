RSpec.describe AmiSpec::AwsDefaultVpc do
  subject(:aws_default_vpc) { described_class.create(ec2: ec2, logger: logger) }

  let(:ec2) { instance_spy(Aws::EC2::Resource, vpcs: vpcs) }

  describe '#find_subnet' do
    subject(:find_subnet) { described_class.find_subnet(ec2: ec2) }

    context 'given no default vpc' do
      let(:vpcs) { instance_spy(Aws::EC2::Vpc::Collection, first: nil) }

      it 'returns nil' do
        expect(find_subnet).to be_nil
      end
    end

    context 'given a default vpc' do
      let(:vpcs) { instance_spy(Aws::EC2::Vpc::Collection, first: default_vpc) }
      let(:default_vpc) { instance_spy(Aws::EC2::Vpc, subnets: subnets) }

      context 'given the default vpc has no subnets' do
        let(:subnets) { instance_spy(Aws::EC2::Subnet::Collection, first: nil) }

        it 'returns nil' do
          expect(find_subnet).to be_nil
        end
      end

      context 'given the default vpc has a subnet' do
        let(:subnets) { instance_spy(Aws::EC2::Subnet::Collection, first: subnet) }
        let(:subnet) { instance_spy(Aws::EC2::Subnet) }

        it 'returns the subnet' do
          expect(find_subnet).to eq(subnet)
        end
      end
    end
  end
end
