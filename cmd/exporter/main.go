package main

import (
	"net/http"

	"github.com/Utkar5hM/mariadb-ebpf-exporter/pkg/probes"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {

	histogramVec := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "ebpf_exporter",
		Name:      "query_latencies",
		Help:      "latencies of queries executed by DB",
		Buckets:   []float64{0.01, 0.02, 0.04, 0.08},
	}, []string{"query"})

	prometheus.Register(histogramVec)
	http.Handle("/metrics", promhttp.Handler())

	go http.ListenAndServe(":2112", nil)

	queryLatencyChan := probes.GetQueryLatencies(300)
	for q := range queryLatencyChan {
		histogramVec.WithLabelValues(q.Query).Observe(q.Latency)
	}
}
