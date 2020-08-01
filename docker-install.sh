#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive; \
apt-get update && \
apt-get install  -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    gnupg \
    screen

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && 

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install --no-install-recommends -y docker-ce docker-ce-cli containerd.io

apt clean
apt autoclean

find /var/lib/apt/lists/ -maxdepth 1 -type f -print0 | xargs -0 rm

adduser --disabled-password --gecos "" dinduserns

mkdir -p ~/.docker/cli-plugins
curl https://github.com/docker/buildx/releases/download/v0.4.1/buildx-v0.4.1.linux-amd64 -L -o ~/.docker/cli-plugins/docker-buildx
#if [ $? -eq 0 ]
#then
        chmod +x ~/.docker/cli-plugins/docker-buildx
#else
#     echo "Error while getting buildx"
#     exit 1
#fi
