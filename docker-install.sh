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
    gnupg 

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && 

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install --no-install-recommends -y docker-ce docker-ce-cli containerd.io