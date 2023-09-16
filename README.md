# mariadb-ebpf-exporter

This project aims to utilize eBPF technology to measure query execution latency in MariaDB and MySQL databases. Focusing on grouping similar queries by fingerprinting(kind of normalizing them) and to export the data as Prometheus metrics for efficient performance analysis.

# Usage Instruction:

Build the project using the provided build instructions. This will create a completely static binary, eliminating the need for installing any dependencies once built. Please ensure that the kernel supports the eBPF features used.

To simplify the building process, you can use the `build.sh` script. The `-f` flag is an optional argument. Use it if your mysqld is located in a different path and not symlinked. By default, mariadbd is usually symlinked to /usr/bin/mysqld, so the argument is not required in that case. This also makes sure that the correct symbol name is found and used while building for your version of mariadb/mysql.

## Docker:

Build the static binary and start the container by running the following command.

```sh
./build.sh docker-start -f /pathto/mysqld/or/mariadbd/
```

To only build the static binary with Docker and copy it to the ./output directory, run the following command:

```sh
./build.sh docker-build -f  /pathto/mysqld/or/mariadbd/
```

## Locally:

Run the build.sh script with the local-build argument. Make sure you have all the prerequisites installed. You can refer to builder/prepare-ubuntu.sh for more information or simply use the Docker version.

```sh
./build.sh local-build -f /pathto/mysqld/or/mariadbd/
```

If you are using Arch Linux and encountering issues with the zstd library, add -lzstd to CGO_LDFLAGS_STATIC in the makefile. Remove it if you are using Docker/Debian.

-----------------

### Once the project is built (by docker or locally), you can execute the generated binary by running:

```sh
./output/main-static
```



