# mariadb-ebpf-exporter

This project aims to utilize eBPF technology to measure query execution latency in MariaDB and probably also MySQL databases. Focusing on standardizing similar queries and transforming them into a unified format, and to export the data as Prometheus metrics for efficient performance analysis.

Build Instruction:

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


build static binary with docker
```
docker build -t mariadb-ebpf-exporter .

docker cp $(docker create mariadb-ebpf-exporter):/build/output ./.output-docker
```
