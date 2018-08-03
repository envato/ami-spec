FROM ubuntu-upstart:trusty

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y openssh-server && apt-get clean

COPY ami-spec.pub /root/.ssh/authorized_keys

EXPOSE 22
