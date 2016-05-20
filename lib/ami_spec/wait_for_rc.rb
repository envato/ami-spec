require 'net/ssh'

module AmiSpec
  class WaitForRC
    def self.wait(ip_address, user, key)
      Net::SSH.start(ip_address, user, keys: [key], paranoid: false) do |ssh|
        # Wait for SystemV to start
        # This only works for Ubuntu with upstart.
        # Detecting OS and Release will need something like this
        # https://github.com/mizzy/specinfra/blob/master/lib/specinfra/helper/detect_os/debian.rb
        ssh.exec 'while /usr/sbin/service rc status | grep -q "^rc start/running, process"; do sleep 1; done'
      end
    end
  end
end

