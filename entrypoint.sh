#!/bin/bash
set -e

args=()

docker_net_set() {
    if [ ! -z "$ipv6" ] && [ "$ipv6" != "no" ]
    then
        docker run  --rm -d --cap-add NET_ADMIN --cap-add NET_RAW --name ndppd-service --network host ahmetozer/ndppd
    fi

}


ipv6_detection() {
    current_ipv6_addr=`ip -6 route get 2001:: | sed 's/^.*src \([^ ]*\).*$/\1/;q'`
    if [ $? -eq 0 ]
    then
        if [ ! -z "$current_ipv6_addr" ]
        then
            ping -6 -c 2 -i 0.3 2606:4700:4700::1111 >/dev/null
            if [ $? -eq 0 ]
            then
                current_depth=`echo $current_ipv6_addr | sed 's/::/:/g' | grep -o -i ":" | wc -l`
                if [ $current_depth -gt 7 ]
                then
                    >&2 echo "You are reach maximum depth in IPv6 Calculation"
                else
                    new_ipv6_depth=$((current_depth+1))
                    new_ipv6_cidr=$((new_ipv6_depth*16))
                    new_ipv6_block="$current_ipv6_addr/$new_ipv6_cidr"
                    echo "IPv6 detected and setted to $new_ipv6_block"
                fi
            fi
        fi
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
                printf "Dind system prune: "; docker system prune -f
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

if [ "$userns" == "yes" ]
then
    args+=(--userns-remap="dinduserns:dinduserns")
fi

if [ "$ipv6" != "no" ]
then
    if [ -z "$ipv6" ]
    then
        ipv6_detection
        if [ ! -z "$new_ipv6_block" ]
        then
            ipv6=$new_ipv6_block
            args+=(--ipv6)
            args+=(--fixed-cidr-v6="$ipv6")
        fi
    else 
        args+=(--ipv6)
        args+=(--fixed-cidr-v6="$ipv6")
    fi
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

docker_deamon_wait &
dockerd ${args[@]}