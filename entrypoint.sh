#!/bin/bash
set -e

args=()

docker_net_set() {
    if [ ! -z "$ipv6" ]
    then
        docker run  --rm -d --cap-add NET_ADMIN --cap-add NET_RAW --name ndppd-service --network host ahmetozer/ndppd
    fi

}

docker_deamon_wait() {
    while [ "$docker_daemon_stat" != "200" ]
    do
        if [ -S "/var/run/docker.sock" ]
        then
        docker_daemon_stat=$(curl --unix-socket /var/run/docker.sock http/containers/json -s -o /dev/null -w '%{http_code}\n')
        fi
        sleep 1
    done
    echo "Deamon ready"
    docker_net_set
}

docker_deamon_wait &

if [ "$userns" == "yes" ]
then
    args+=(--userns-remap="dinduserns:dinduserns")
fi

if [ ! -z "$ipv6" ]
then
    args+=(--ipv6)
    args+=(--fixed-cidr-v6="$ipv6")
fi

if [ "$buildx" == "yes" ] || [ "$experimental" == "yes" ] 
then
    args+=(--experimental)
fi
dockerd ${args[@]}