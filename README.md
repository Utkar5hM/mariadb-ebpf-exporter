# mariadb-ebpf-exporter

This project aims to utilize eBPF technology to measure query execution latency in MariaDB and MySQL databases. Focusing on grouping similar queries by fingerprinting(kind of normalizing them) and to export the data as Prometheus metrics for efficient performance analysis.

# Usage Instruction:

Build the project using the provided build instructions. This will create a completely static binary, eliminating the need for installing any dependencies once built. Ensure that the kernel supports the eBPF features used. I do not have a list of kernel versions that support the features used, but I have tested it on Arch Linux with kernel version `6.5.3-arch1-1`.

To simplify the building process, you can use the `build.sh` script.

## build script guide 

#### The first argument is the build type. The following build types are supported:

- `docker-run`: will build the project using docker and run the generated binary.

- `local-build`: will build the project locally and generate the binary.

- `docker-build` will build the project using docker and copy the generated binary to the ./output directory.

- `docker-attach-build` will build a docker image by default for the latest mariadb docker image and copy the generated binary to the ./output directory. db image can be specified using the `-di` flag.

- `docker-attach-run` will build the project using docker by default for the running mariadb docker container with name `some-mariadb` and run the generated binary.

#### Additional optional arguments can be passed to the build script. The following arguments are supported:

- The `-f` flag is an optional argument. Use it if your mysqld is located in a different path and not symlinked. By default, mariadbd is usually symlinked to /usr/bin/mysqld, so the argument is not required in that case better to have a check. This also makes sure that the correct symbol name is found and used while building for your version of mariadb/mysql.


- The `-d` flag is an optional argument. Use it if you want to build for a different version of mariadb/mysql. The support for mysql is in development and will be added soon.

- The `-a` flag is an optional argument. It is for specifying mysqld/mariadbd path where the ebpf probes will be attached. By default, it is set to /usr/bin/mysqld. It is not required to be set for docker-attach-run and docker-attach-build as it will be automatically set to the running container's process pid exe path `/proc/1/exe`. ( Note: This docker-attach-run will start a container by having pid namespace of the the db container and will attach the probes to the process with pid 1 in that namespace. So, make sure that the db container is running before running this command. )

- The `-i` flag is an optional argument. It is for specifying the docker image name to be used for all the docker-* commands. By default, it is set to mariadb-ebpf-exporter.

- The `-di` flag is an optional argument. It is for specifying the docker image of database to be used to build ebpf exporter for. By default, it is set to `mariadb:latest`.

- The `-c` flag is for specifying the name of the container to be used by docker-run and docker-attach-run. By default, it is set to `mariadb-ebpf-exporter`. 

- The `-dc` flag is for specifying the name of the database container to be used by docker-attach-run. By default, it is set to `some-mariadb`.

- The `-p` flag is for specifying the port to be used by docker-run and docker-attach-run. By default, it is set to `2112`.

-------------------

## Docker:

Build the static binary and start the container by running the following command.

```sh
./build.sh docker-start
```

To only build the static binary with Docker and copy it to the ./output directory, run the following command, lets also specify the mariadbd path to be used for finding the symbols as an example.

```sh
./build.sh docker-build -f  /pathto/mysqld/or/mariadbd/
```

## Docker-attach:
An example to Build the static binary and attach the probes to the running db container by running the following command. This will attach to a db container with name MY_PROD_DB and will start a container with name db_query_monitor. 

```sh
./build.sh docker-attach-run -c db_query_monitor -dc MY_PROD_DB
```

To only build the docker Image to later start the container for a specific db docker image, run the following command. This will build the docker image for the latest mariadb docker image.

```sh
./build.sh docker-attach-build -di mariadb:latest
```

## Locally:

Run the build.sh script with the local-build argument. Make sure you have all the prerequisites installed. You can refer to builder/prepare-ubuntu.sh for more information or simply use the Docker version. Let us specify a process path to be used for attaching the probes as an example.

```sh
./build.sh local-build -f /pathto/mysqld/or/mariadbd/ -a /proc/2020/exe
```

-----------------

### Once the project is built (by docker or locally), you can execute the generated binary by running:

```sh
./output/main-static
```