FROM amazonlinux:1

RUN yum install -y upstart openssh-server && yum clean all
ADD rc.conf /etc/init/rc.conf

COPY ami-spec.pub /root/.ssh/authorized_keys
COPY sshd_config /etc/ssh/sshd_config

CMD ["/bin/bash", "-c", "exec /sbin/init"]
