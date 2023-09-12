module github.com/Utkar5hM/mariadb-ebpf-exporter

go 1.18

require (
	github.com/aquasecurity/libbpfgo v0.4.7-libbpf-1.2.0-b2e29a1
	github.com/aquasecurity/libbpfgo/helpers v0.4.5
	github.com/prometheus/client_golang v1.16.0
)

require (
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.4 // indirect
	github.com/prometheus/client_model v0.3.0 // indirect
	github.com/prometheus/common v0.42.0 // indirect
	github.com/prometheus/procfs v0.10.1 // indirect
	golang.org/x/sys v0.12.0 // indirect
	google.golang.org/protobuf v1.30.0 // indirect
)

replace github.com/aquasecurity/libbpfgo => ./libbpfgo

replace github.com/aquasecurity/libbpfgo/helpers => ./libbpfgo/helpers
