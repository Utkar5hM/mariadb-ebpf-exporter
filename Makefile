BASEDIR = $(abspath ./libbpfgo)

LIBBPF_OUTPUT = ./libbpfgo/output
PROBES_PATH = ./pkg/probes
GOLANG_CODE_PATH = ./cmd/exporter
OUTPUT = ./output
BUILDER_PATH = ./builder
LIBBPF_SRC = $(abspath ./libbpfgo/libbpf/src)
LIBBPF_OBJ = $(abspath $(LIBBPF_OUTPUT)/libbpf.a)

CC = gcc
CLANG = clang
GO = go

ARCH := $(shell uname -m | sed 's/x86_64/amd64/g; s/aarch64/arm64/g')
BPF_ARCH:= $(shell uname -m | sed 's/x86_64/x86/g; s/aarch64/arm64/g')

CFLAGS = -g -O2 -Wall -fpie
LDFLAGS =

CGO_CFLAGS_STATIC = "-I$(abspath $(LIBBPF_OUTPUT)) -I$(abspath $(BUILDER_PATH)) -I$(abspath ./libbpfgo/selftest/common) "
CGO_LDFLAGS_STATIC = "-lelf -lz -lzstd $(LIBBPF_OBJ)" ## -lzstd
CGO_EXTLDFLAGS_STATIC = '-w -extldflags "-static"'

CGO_CFLAGS_DYN = "-I. -I/usr/include/"
CGO_LDFLAGS_DYN = "-lelf -lz -lbpf"


.PHONY: main
.PHONY: $(GOLANG_CODE_PATH)/main.go
.PHONY: $(PROBES_PATH)/main.bpf.c
.PHONY: $(BUILDER_PATH)/vmlinux.h

all: main-static

.PHONY: libbpfgo
.PHONY: libbpfgo-static
.PHONY: libbpfgo-dynamic

$(BUILDER_PATH)/vmlinux.h:
	bpftool btf dump file /sys/kernel/btf/vmlinux format c > $(BUILDER_PATH)/vmlinux.h
## libbpfgo

libbpfgo-static:
	$(MAKE) -C $(BASEDIR) libbpfgo-static

libbpfgo-dynamic:
	$(MAKE) -C $(BASEDIR) libbpfgo-dynamic

## test (bpf)

$(OUTPUT)/main.bpf.o: $(PROBES_PATH)/main.bpf.c
	mkdir -p output
	$(CLANG) $(CFLAGS) -target bpf -D__TARGET_ARCH_$(BPF_ARCH) -I$(LIBBPF_OUTPUT) -I$(BUILDER_PATH) -c $< -o $@


## test

.PHONY: main-static
.PHONY: main-dynamic

main-static: libbpfgo-static | $(OUTPUT)/main.bpf.o
	CC=$(CLANG) \
		CGO_CFLAGS=$(CGO_CFLAGS_STATIC) \
		CGO_LDFLAGS=$(CGO_LDFLAGS_STATIC) \
		GOOS=linux GOARCH=$(ARCH) \
		$(GO) build \
		-tags netgo -ldflags $(CGO_EXTLDFLAGS_STATIC) \
		-o $(OUTPUT)/main-static $(GOLANG_CODE_PATH)/main.go

main-dynamic: libbpfgo-dynamic | $(OUTPUT)/main.bpf.o
	CC=$(CLANG) \
		CGO_CFLAGS=$(CGO_CFLAGS_DYN) \
		CGO_LDFLAGS=$(CGO_LDFLAGS_DYN) \
		$(GO) build -o $(OUTPUT)/main-dynamic $(GOLANG_CODE_PATH)/main.go

clean:
	rm -f *.o main-static main-dynamic
