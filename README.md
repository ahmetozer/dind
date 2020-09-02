# Docker In Docker with Builx and IPv6

Some times Docker in Docker is require for more organization or one time runs such as build container with Gitlab-ci.
Regular dind is not support buildx and IPv6. This repository aim that these kind a problems.

This dind is require privileged mode.

To enable buildx, set env variable buildx is to yes.  
If main docker is configured with IPv6, dind container has a IPv6 detection system and system try to find and set IPv6.  
You can set IPv6 by manual with  set `ipv6` env variable to your IPv6 block

Before build command start docker service with `/src/start-docker.sh`

Example gitlab-ci.yml from some project.

```yml
docker-build:
    variables:
      buildx: "yes"
    image: ahmetozer/dind:latest
    stage: build
    before_script:
      - /src/start-docker.sh
      - docker login -u "ahmetozer" -p "$dhub"
    script:
      - docker buildx build --platform linux/amd64,linux/arm64,linux/arm --push -t ahmetozer/cors-proxy .
    only:
      - master
```

Overlay layer is more optimized for performance and disk space. So you can run your dind with mounting docker lib path to real ext4 path on disk.

```bash
#   Create directory for your dind containers
mkdir -p /dind/dind1

docker run -it --rm --privileged -v /dind/dind1:/var/lib/docker ahmetozer/dind
```

Example gitlab-runner config.

```toml
concurrent = 1
check_interval = 0

[session_server]
  session_timeout = 1800
  listen_address = "[::]:8093"

[[runners]]
  name = "dind1"
  url = "https://gitlab.com/"
  token = "My_SECRET_TOKEN"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = true
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache","/var/lib/docker/dind-overlay:/var/lib/docker:rw"]
    shm_size = 0
```
