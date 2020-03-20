require 'net/ssh'

module AmiSpec
  class WaitForCloudInit
    def self.wait(ip_address, user, key, port=22)
      Net::SSH.start(ip_address, user, keys: [key], :verify_host_key => :never, port: port) do |ssh|
        ssh.exec '/usr/bin/cloud-init status --wait'
      end
    end
  end
end
