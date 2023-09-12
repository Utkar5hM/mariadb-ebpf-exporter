package main

import (
	"fmt"
	"net/http"

	"github.com/Utkar5hM/mariadb-ebpf-exporter/pkg/probes"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {

	histogramVec := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "ebpf_exporter",
		Name:      "query_latencies",
		Help:      "Time it has taken to retrieve the metrics",
		Buckets:   []float64{0.01, 0.02, 0.04, 0.08},
	}, []string{"query"})

	go prometheus.Register(histogramVec)
	http.Handle("/metrics", promhttp.Handler())

	histogramVec.WithLabelValues("SELECT * FROM users").Observe(0.05)

	queryLatencyChan := probes.GetQueryLatencies(300)
	for ql := range queryLatencyChan {
		fmt.Printf("Query: %s, Latency: %d\n", ql.Query, ql.Latency)
	}

	http.ListenAndServe(":2112", nil)
}
