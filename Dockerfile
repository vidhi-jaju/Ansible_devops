FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y openssh-server python3 && \
    mkdir /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
