#!/bin/sh
set -e
apk add docker screen curl bash

adduser --disabled-password --gecos "" dinduserns

arch=`arch`
if [ "$arch" == "x86_64" ]
then
    buildx_arch="amd64"
elif [ "$arch" == "armv7l" ]
then
    buildx_arch="arm-v7"
elif [ "$arch" == "aarch64"]
then
    buildx_arch="arm64"
else
    echo "Not supported arch: $arch"
fi

if [ ! -z "$buildx_arch" ]
then
mkdir -p ~/.docker/cli-plugins
curl https://github.com/docker/buildx/releases/download/v0.4.1/buildx-v0.4.1.linux-$buildx_arch -L -o ~/.docker/cli-plugins/docker-buildx
    if [ $? -eq 0 ]
    then
        chmod +x ~/.docker/cli-plugins/docker-buildx
    else
        echo "Error while getting buildx"
        exit 1
    fi
fi
