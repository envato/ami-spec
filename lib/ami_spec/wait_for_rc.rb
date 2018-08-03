require 'net/ssh'

module AmiSpec
  class WaitForRC
    def self.wait(ip_address, user, key, port=22)
      Net::SSH.start(ip_address, user, keys: [key], paranoid: false, port: port) do |ssh|
        distrib_stdout = ""
        # Determine the OS family
        ssh.exec!("source /etc/*release && echo -n $DISTRIB_ID && echo -n $ID") do |channel, stream, data|
          distrib_stdout << data if stream == :stdout
        end
        if distrib_stdout == "Ubuntu"
          codename_stdout = ""
          ssh.exec!("source /etc/*release && echo -n $DISTRIB_CODENAME") do |channel, stream, data|
            codename_stdout << data if stream == :stdout
          end
          if codename_stdout == "trusty"
            ssh.exec 'while /usr/sbin/service rc status | grep -q "^rc start/running, process"; do sleep 1; done'
          elsif codename_stdout == "xenial"
            ssh.exec 'while /usr/sbin/service rc status >/dev/null; do sleep 1; done'
          else
            puts "WARNING: Only Ubuntu trusty and xenial supported and we detected '#{codename_stdout}'. --wait-for-rc has no effect."
          end
        elsif distrib_stdout == "amzn"
          version_stdout = ""
          ssh.exec!("source /etc/*release && echo -n $VERSION_ID") do |channel, stream, data|
            version_stdout << data if stream == :stdout
          end
          if version_stdout =~ %r{201[0-9]{1}\.[0-9]+}
            ssh.exec 'while initctl status rc |grep -q "^rc start/running"; do sleep 1; done'
          else
            puts "WARNING: Only Amazon Linux 1 is supported and we detected '#{version_stdout}'. --wait-for-rc has no effect."
          end
        else
          puts "WARNING: Only Ubuntu and Amazon linux are supported and we detected '#{distrib_stdout}'. --wait-for-rc has no effect."
        end
      end
    end
  end
end
