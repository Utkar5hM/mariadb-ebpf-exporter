Tested on
```sh
mariadb from 11.0.2-MariaDB, client 15.2 for Linux (x86_64) using readline 5.1

6.4.8-arch1-1
```

Tracing Queries:
```sh
sudo bpftrace -e 'uprobe:/usr/bin/mysqld:dispatch_command { printf("%s\n", str(arg2)); }'
```

For Latency
```sh
bpftrace -e 'uprobe:/usr/bin/mysqld:dispatch_command { @sql[tid] = str(arg2); @start[tid] = nsecs; }
uretprobe:/usr/bin/mysqld:dispatch_command /@start[tid] != 0/ { printf("%s : %u64 %u64 ms\n", @sql[tid], tid, (nsecs - @start[tid])/1000000); }'
```


Sources:

https://mysqlentomologist.blogspot.com/2019/10/dynamic-tracing-of-mariadb-server-with.html
