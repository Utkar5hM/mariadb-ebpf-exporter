package main

import (
	"flag"
	"net/http"

	"github.com/Utkar5hM/mariadb-ebpf-exporter/pkg/probes"
	"github.com/percona/go-mysql/query"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	var argMinimumDurationMs uint64 = 0
	flag.Uint64Var(&argMinimumDurationMs, "t", 0, "Minimum latency duration for queries to be captured")
	flag.Parse()
	histogramVec := prometheus.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "ebpf_exporter",
		Name:      "query_latencies",
		Help:      "latencies of queries executed by DB",
		Buckets:   []float64{5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000},
	}, []string{"query"})

	prometheus.Register(histogramVec)
	http.Handle("/metrics", promhttp.Handler())

	go http.ListenAndServe(":2112", nil)
	queryLatencyChan := probes.GetQueryLatencies(300, argMinimumDurationMs)
	for q := range queryLatencyChan {

		fquery := query.Fingerprint(q.Query)
		latency := q.Latency / 1000000
		histogramVec.WithLabelValues(fquery).Observe(latency)
	}
}
