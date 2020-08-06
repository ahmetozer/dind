#!/bin/bash

args=()

if [ -z "$default_eth_interface" ];then
default_eth_interface="eth0"
fi

ipv4_netmask_to_cidr() {
    bits=0
    for octet in $(echo $1| sed 's/\./ /g'); do 
         binbits=$(echo "obase=2; ibase=10; ${octet}"| bc | sed 's/0//g') 
         let bits+=${#binbits}
    done
    echo "${bits}"
}

docker_net_set() {
    if [ ! -z "$ipv6" ] && [ "$ipv6" != "no" ] && [ "$bind" != "yes" ]
    then
        docker run  --rm -d --cap-add NET_ADMIN --cap-add NET_RAW --name ndppd-service --network host ahmetozer/ndppd
    fi

    if [ "$bind" == "yes" ]; then
        brctl addif docker0 $default_eth_interface
        ip addr flush dev docker0
        ip addr flush dev $default_eth_interface
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
                if [ "$bind" == "yes" ]; then
                    new_ipv6_block=`ifconfig | grep "Global" | sed 's/^.*addr: \([^ ]*\).*$/\1/;q'`
                else
                    current_depth=`echo $current_ipv6_addr | sed 's/::/:/g' | grep -o -i ":" | wc -l`
                    new_ipv6_addr=`echo $current_ipv6_addr | sed 's/::/:/g'`::1
                    if [ $current_depth -gt 5 ]
                    then
                        >&2 echo "You are reach maximum depth in IPv6 Calculation"
                    else
                        new_ipv6_depth=$((current_depth+1))
                        new_ipv6_cidr=$((new_ipv6_depth*16))
                        new_ipv6_block="$new_ipv6_addr/$new_ipv6_cidr"
                        echo "IPv6 detected and setted to $new_ipv6_block"
                    fi
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
    ifconfig $default_eth_interface || true
    ifconfig docker0 || true
    brctl show
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

if [ "$bind" == "yes" ]; then
        current_ipv4_mask=$(ifconfig $default_eth_interface | grep "Mask" | sed 's/^.*Mask:\([^ ]*\).*$/\1/;q')
        current_ipv4_cidr=$(ipv4_netmask_to_cidr $current_ipv4_mask)
        current_ipv4=$(traceroute 192.88.99.1  -m 1 | grep -v "192.88.99.1" |cut -d"(" -f2 | cut -d")" -f 1)
        if [ -z "$current_ipv4" ];then #Maybe getaway not response the request
            current_ipv4=$(ifconfig $default_eth_interface | grep "Mask" | sed 's/^.*addr:\([^ ]*\).*$/\1/;q')
            current_ipv4_first=$(echo $current_ipv4 | cut -d"." -f -3)
            current_ipv4_gw=$(bc <<< "$(ifconfig $default_eth_interface | grep "Mask" | sed 's/^.*addr:\([^ ]*\).*$/\1/;q' | cut -d"." -f 4)-1")
            current_ipv4="$current_ipv4_first.$current_ipv4_gw"
        fi
        args+=(--bip $current_ipv4/$current_ipv4_cidr)
fi

if [ "$buildx" == "yes" ] || [ "$experimental" == "yes" ] 
then
    args+=(--experimental)
fi


if [ "$listenlhost" == "yes" ]
then
    args+=(-H tcp://127.0.0.1:2375)
    echo "127.0.0.1 docker" >> /etc/hosts
fi 

args+=(-H unix:///var/run/docker.sock)

docker_deamon_wait &
dockerd ${args[@]}

dockerd_exit_status=$?
if [ $dockerd_exit_status -eq 0 ]
then
    echo "Docker closed without problem."
else
    echo "Docker closed with error."
    echo "$dockerd_exit_status" > /var/lib/dockerd_exit_status
fi