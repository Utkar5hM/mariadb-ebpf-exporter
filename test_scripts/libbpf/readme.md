
## Finding mangled Name:

```sh
nm -D /usr/bin/mariadbd | grep dispatch_command | awk -F " " '{ print $3 }'
```

finding idirafter:
```sh
clang  -v -E - </dev/null 2>&1    | sed -n '/<...> search starts here:/,/End of search list./{ s| \(/.*\)|-idirafter \1|p }'
```

vmlinux.sh
```sh
bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
```

building object file manually 
```sh
clang -mcpu=v3 -g -O2 -Wall -Werror -D__TARGET_ARCH_x86 -idirafter /usr/lib/clang/15.0.7/include -idirafter /usr/local/include -idirafter /usr/include -c -target bpf -o mariadb_latency.o mariadb_latency.bpf.c
```