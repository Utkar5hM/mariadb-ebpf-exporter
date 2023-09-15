FROM ubuntu  as builder

WORKDIR /build

RUN apt-get update && apt-get install -y git sudo 

COPY ./builder/prepare-ubuntu.sh .

RUN ./prepare-ubuntu.sh

RUN git clone --recursive https://github.com/aquasecurity/libbpfgo


# generate vmlinux.h
RUN git clone --recurse-submodules https://github.com/libbpf/bpftool.git

WORKDIR /build/bpftool/src

RUN make -j$(nproc)

COPY . /build/

RUN ./bpftool btf dump file /sys/kernel/btf/vmlinux format c > /build/builder/vmlinux.h

# compile
WORKDIR /build

RUN go mod tidy

RUN make main-static

FROM gcr.io/distroless/static-debian11 as mariadb_exporter

COPY --from=builder /build/output/main-static /main-static

ENTRYPOINT ["/main-static"]