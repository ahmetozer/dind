#!/bin/bash
set -e

args=()

docker_net_set() {
    if [ ! -z "$ipv6" ]
    then
        docker run  --rm -d --cap-add NET_ADMIN --cap-add NET_RAW --name ndppd-service --network host ahmetozer/ndppd
    fi

}
number_re='^[0-9]+$'
docker_system_prune() {
    if [ "$prune_interval" == "yes" ]; then
    prune_interval = 60
    fi
    if [[ "$prune_interval" =~ $number_re ]] ; then
        echo "Prune enabled, and interval is $prune_interval"
        while true
        do
            sleep $prune_interval
            if [ -S "/var/run/docker.sock" ]
            then
                docker system prune -f
            else
                echo "Docker is not running."
            fi
        done
    fi
}

docker_buildx() {
    if [ "$buildx" == "yes" ]
    then
        docker buildx create --use
        docker run --rm --privileged docker/binfmt:820fdd95a9972a5308930a2bdfb8573dd4447ad3
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
    docker_buildx
    docker_system_prune&
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


if [ "$listenlhost" != "no" ]
then
    args+=(-H tcp://127.0.0.1:2375)
    echo "127.0.0.1 docker" >> /etc/hosts
fi 

args+=(-H unix:///var/run/docker.sock)
dockerd ${args[@]}