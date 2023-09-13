package main

import (
	"net/http"

	"github.com/Utkar5hM/mariadb-ebpf-exporter/pkg/probes"
	"github.com/Utkar5hM/mariadb-ebpf-exporter/pkg/queryNormalizer"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {

	histogramVec := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "ebpf_exporter",
		Name:      "query_latencies",
		Help:      "latencies of queries executed by DB",
		Buckets:   []float64{5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000},
	}, []string{"query"})

	prometheus.Register(histogramVec)
	http.Handle("/metrics", promhttp.Handler())

	go http.ListenAndServe(":2112", nil)

	queryLatencyChan := probes.GetQueryLatencies(300)
	for q := range queryLatencyChan {
		query := queryNormalizer.Normalize(q.Query)
		latency := q.Latency / 1000000
		histogramVec.WithLabelValues(query).Observe(latency)
	}
}
