#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBES_PATH="${SCRIPT_DIR}/pkg/probes"
MYSQLD_PATH="/usr/bin/mysqld"
IMAGE_NAME="sql-ebpf-exporter"  
CONTAINER_NAME="sql-ebpf-exporter"  

while (( "$#" )); do
  case "$1" in
    docker-start|docker-build|local-build)
      COMMAND=$1
      shift
      if [ "$1" = "-f" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          MYSQLD_PATH=$2
          shift 2
        else
          echo "Error: Argument for '-f' is missing" >&2
          exit 1
        fi
      fi
      ;;
    -f)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        MYSQLD_PATH=$2
        shift 2
      else
        echo "Error: Argument for '-f' is missing" >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

nm -D $MYSQLD_PATH | grep dispatch_command | awk -F " " '{ print $3 }' | tr -d '\n' > "${PROBES_PATH}/symbol.txt"
echo -n "symbol name found: " && echo $(cat ${PROBES_PATH}/symbol.txt)


if [ "$COMMAND" = "docker-build" ]; then
    DOCKER_BUILDKIT=1 docker build -t $IMAGE_NAME "${SCRIPT_DIR}/."
    docker cp "$(docker create mariadb-ebpf):/main-static" "${SCRIPT_DIR}/output/main-static"
fi

if [ "$COMMAND" = "docker-start" ]; then
    DOCKER_BUILDKIT=1 docker build -t $IMAGE_NAME "${SCRIPT_DIR}"
    if [ "$(docker ps -q -a -f name=$CONTAINER_NAME)" ]; then
        echo "Container $CONTAINER_NAME exists. Stopping and removing..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    docker run --restart always -p 2112:2112 -d --cap-add=CAP_BPF --cap-add=CAP_PERFMON --cap-add=CAP_SYS_RESOURCE --name $CONTAINER_NAME -v $MYSQLD_PATH:/usr/bin/mysqld mariadb-ebpf
    echo "Showing docker logs in 2 seconds..." 
    sleep 2
    docker logs $CONTAINER_NAME  
fi

if [ "$COMMAND" = "local-build" ]; then
    rm -rf output
    bpftool btf dump file /sys/kernel/btf/vmlinux format c > builder/vmlinux.h
    git clone --recursive https://github.com/aquasecurity/libbpfgo.git
    make main-static
fi