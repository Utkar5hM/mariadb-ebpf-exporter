#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBES_PATH="${SCRIPT_DIR}/pkg/probes"
MYSQLD_PATH="/usr/bin/mysqld"
MYSQLD_PATH_SPECIFIED=false
IMAGE_NAME="mariadb-ebpf-exporter"  
CONTAINER_NAME="mariadb-ebpf-exporter"  
DB_CONTAINER_NAME="some-mariadb"
DB_CONTAINER_MYSQLD_PATH="/usr/sbin/mariadbd"
DB_TYPE="mariadb"
ATTACH_MYSQLD_PATH="/usr/bin/mysqld"
ATTACH_MYSQLD_PATH_SPECIFIED=false
DB_IMAGE_NAME="mariadb:latest"
EXPOSE_PORT=2112
MINIMUM_DURATION_SECONDS=0
# green text
echo -e "\e[32mMariadb eBPF Exporter \e[0m"
echo -e "Github Link: \e[34mhttps://github.com/Utkar5hM/mariadb-ebpf-exporter/\e[0m"
echo "Usage: ./build.sh <command> [options]"
echo "=================================="
while (( "$#" )); do
  case "$1" in
    docker-build|docker-run|local-build|docker-attach-build|docker-attach-run)
      COMMAND=$1
      shift
      if [ "$1" = "-f" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          MYSQLD_PATH=$2
          MYSQLD_PATH_SPECIFIED=true
          shift 2
        else
          echo "Error: Argument for '-f' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-a" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          ATTACH_MYSQLD_PATH=$2
          ATTACH_MYSQLD_PATH_SPECIFIED=true
          shift 2
        else
          echo "Error: Argument for '-a' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-i" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          IMAGE_NAME=$2
          shift 2
        else
          echo "Error: Argument for '-i' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-di" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          DB_IMAGE_NAME=$2
          shift 2
        else
          echo "Error: Argument for '-di' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-c" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          CONTAINER_NAME=$2
          shift 2
        else
          echo "Error: Argument for '-c' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-dc" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          DB_CONTAINER_NAME=$2
          shift 2
        else
          echo "Error: Argument for '-dc' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-p" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          EXPOSE_PORT=$2
          shift 2
        else
          echo "Error: Argument for '-p' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-t" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
          MINIMUM_DURATION_SECONDS=$2
          shift 2
        else
          echo "Error: Argument for '-t' is missing" >&2
          exit 1
        fi
      fi
      if [ "$1" = "-d" ]; then
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            DB_TYPE=$2
            if [ "$DB_TYPE" = "mysql" ]; then
                DB_CONTAINER_MYSQLD_PATH="/usr/sbin/mysqld"
            fi
          shift 2
        else
          echo "Error: Argument for '-d' is missing" >&2
          exit 1
        fi
      fi
      ;;
  esac
done

rm -f pkg/probes/build/main.bpf.c 2>/dev/null
if [ "$DB_TYPE" = "mysql" ]; then
  ln -s ../bpf_c/mysql.bpf.c pkg/probes/build/main.bpf.c
  echo "Created symlink from mysql.bpf.c to main.bpf.c"
else
  ln -s ../bpf_c/mariadb.bpf.c pkg/probes/build/main.bpf.c
  echo "Created symlink from mariadb.bpf.c to main.bpf.c"
fi

symbol_name_extraction() {
    nm -D $MYSQLD_PATH | grep dispatch_command | awk -F " " '{ print $3 }' | tr -d '\n' > "${PROBES_PATH}/symbol.txt"
    echo "MYSQLD FILE TO ATTACH: $MYSQLD_PATH" 
    echo -n "symbol name found: " && echo $(cat ${PROBES_PATH}/symbol.txt)
}

docker_build(){
    docker build -t $IMAGE_NAME "${SCRIPT_DIR}/."
}
docker_stop_existing_container(){
    if [ "$(docker ps -q -a -f name=$CONTAINER_NAME)" ]; then
        echo "Container $CONTAINER_NAME exists. Stopping and removing..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
}

docker_logs(){
    echo "Showing docker logs in 2 seconds..." 
    sleep 2
    docker logs $CONTAINER_NAME 
}

visit_url(){
    echo -e "metrics can be viewed at \e[32mhttp://127.0.0.1:2112/metrics\e[0m"
}

if [ "$COMMAND" = "docker-attach-build" ] || [ "$COMMAND" = "docker-attach-run" ]; then
    if [ "$ATTACH_MYSQLD_PATH_SPECIFIED" = false ]; then
        ATTACH_MYSQLD_PATH="/proc/1/exe"
    fi
    if [ "$MYSQLD_PATH_SPECIFIED" = false ]; then
        MYSQLD_PATH="${SCRIPT_DIR}/output/build/mysqld"
    fi
    mkdir -p $SCRIPT_DIR/output/build
else
    symbol_name_extraction
fi

if [ $MINIMUM_DURATION_SECONDS -ne 0 ]; then
    echo -n $MINIMUM_DURATION_SECONDS > $PROBES_PATH/minimumDuration.txt
    echo "Default minimum execution latency for a query to be captured is now set to $MINIMUM_DURATION_SECONDS seconds"
fi

echo "MySQLD Path where uprobes will be attached: $ATTACH_MYSQLD_PATH"
echo -n $ATTACH_MYSQLD_PATH > $PROBES_PATH/binaryPath.txt

echo "Executing $COMMAND"
if [ "$COMMAND" = "docker-build" ]; then
    docker_build
    docker cp "$(docker create $IMAGE_NAME):/main-static" "${SCRIPT_DIR}/output/main-static"
    echo "main-static copied to ${SCRIPT_DIR}/output/main-static"
elif [ "$COMMAND" = "docker-run" ]; then
    docker_build
    docker_stop_existing_container
    docker run --restart always -p $EXPOSE_PORT:2112 -d --cap-add=CAP_BPF --cap-add=CAP_PERFMON --cap-add=CAP_SYS_RESOURCE \
        --name $CONTAINER_NAME -v $MYSQLD_PATH:$ATTACH_MYSQLD_PATH $IMAGE_NAME
    docker_logs
    visit_url
elif [ "$COMMAND" = "docker-attach-build" ]; then
    docker cp "$(docker create $DB_IMAGE_NAME):$DB_CONTAINER_MYSQLD_PATH" "${SCRIPT_DIR}/output/build/mysqld"
    echo "mysqld from db image $DB_IMAGE_NAME copied to ${SCRIPT_DIR}/output/build/mysqld"
    symbol_name_extraction
    docker_build
    docker cp "$(docker create $IMAGE_NAME):/main-static" "${SCRIPT_DIR}/output/main-static"
    echo "main-static copied to ${SCRIPT_DIR}/output/main-static"
elif [ "$COMMAND" = "docker-attach-run" ]; then
    docker cp "$DB_CONTAINER_NAME:$DB_CONTAINER_MYSQLD_PATH" "${SCRIPT_DIR}/output/build/mysqld"
    symbol_name_extraction
    docker_build
    docker_stop_existing_container
    docker run --restart always -p $EXPOSE_PORT:2112 -d --privileged \
        --pid=container:$DB_CONTAINER_NAME  \
        --name $CONTAINER_NAME $IMAGE_NAME
    docker_logs
    visit_url
elif [ "$COMMAND" = "local-build" ]; then
    echo "Executing $COMMAND"
    rm -rf output libbpfgo # libbpfgo due to unknown occuring issues
    bpftool btf dump file /sys/kernel/btf/vmlinux format c > builder/vmlinux.h
    git clone --recursive https://github.com/aquasecurity/libbpfgo.git
    make main-static
    echo "main-static built at ${SCRIPT_DIR}/output/main-static"
fi

echo "=================================="
echo -e "\e[35mBuild script signing Off ^_^\e[0m"