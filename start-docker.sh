#!/bin/bash

screen -dmS dockerd /src/entrypoint.sh

echo "Waiting docker service ready"
docker_deamon_wait() {
    while [ "$docker_daemon_stat" != "200" ]
    do
        if [ -S "/var/run/docker.sock" ]
        then
        docker_daemon_stat=$(curl --unix-socket /var/run/docker.sock http/containers/json -s -o /dev/null -w '%{http_code}\n')
        fi
        sleep 1
        if [ -f "/var/lib/dockerd_exit_code" ]; then
            dockerd_exit_code=`cat /var/lib/dockerd_exit_code`
            echo "Docker is exited with $dockerd_exit_code"
            rm /var/lib/dockerd_exit_code
            exit 1
        fi
    done
    echo "Docker Deamon ready"
}

docker_deamon_wait