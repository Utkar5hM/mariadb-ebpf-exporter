# mariadb-ebpf-exporter

This project aims to utilize eBPF technology to measure query execution latency in MariaDB and probably also MySQL databases. Focusing on standardizing similar queries and transforming them into a unified format, and to export the data as Prometheus metrics for efficient performance analysis.

Build Instruction:

## locally
Build `vmlinux.h` for your kernel:
```
bpftool btf dump file /sys/kernel/btf/vmlinux format c > builder/vmlinux.h
```


add `-lzstd` to `CGO_LDFLAGS_STATIC` in makefile if you are on arch linux and having issues with `zstd` library. remove it if you are using docker/debian.

build locally:
```
git clone --recursive https://github.com/aquasecurity/libbpfgo.git

#for static builds
make main-static 
#for dynamic
make main-dynamic
```

## docker
build static binary with docker
```
docker build -t mariadb-ebpf .
```

```
docker cp $(docker create mariadb-ebpf):/main-static ./.output-docker/main-static
```

run it through container(privs need to be checked but right now it works on full):
```
docker run --restart always --rm -p 2112:2112 --privileged --name aasfsaf -v /usr/bin/mariadbd:/usr/bin/mariadbd mariadb-ebpf
```
