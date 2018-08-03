require 'spec_helper'

describe AmiSpec::WaitForRC, integration: true do
  let(:private_key_file) { File.expand_path(File.join('..', 'containers', 'ami-spec'), __FILE__) }
  context 'xenial server' do
    let(:ssh_port) { 1122 }
    it 'executes without printing any errors' do
      expect { described_class.wait("localhost", "root", private_key_file, ssh_port) }.to_not output.to_stdout
    end
  end

  context 'trusty server' do
    let(:ssh_port) { 1123 }
    it 'executes without printing any errors' do
      expect { described_class.wait("localhost", "root", private_key_file, ssh_port) }.to_not output.to_stdout
    end
  end

  context 'amazon linux server' do
    let(:ssh_port) { 1124 }
    it 'executes without printing any errors' do
      expect { described_class.wait("localhost", "root", private_key_file, ssh_port) }.to_not output.to_stdout
    end
  end
end
