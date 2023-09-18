package probes

import "C"

import (
	"bytes"
	_ "embed"
	"encoding/binary"
	"fmt"
	"os"
	"strconv"

	bpf "github.com/aquasecurity/libbpfgo"
	"github.com/aquasecurity/libbpfgo/helpers"
)

//go:embed build/main.bpf.o
var mainBpfObject []byte

//go:embed symbol.txt
var symbolName string

//go:embed binaryPath.txt
var binaryPath string

//go:embed minimumDuration.txt
var minimumDurationString string

const (
	TASK_QUERY_LEN = 52488
)

type QueryLatency struct {
	Query   string
	Latency float64
}

func trimString(input []byte) []byte {
	if idx := bytes.IndexByte(input, 0x00); idx != -1 {
		return input[:idx]
	}
	return input
}

func GetQueryLatencies(rate int, argMinimumDurationMs uint64) <-chan QueryLatency {

	queryLatencyChan := make(chan QueryLatency)
	go func() {

		bpfModule, err := bpf.NewModuleFromBuffer(mainBpfObject, "main")
		if err != nil {
			panic(err)
		}
		defer bpfModule.Close()
		/* Parameterize BPF code with minimum duration parameter */

		minimumDurationMs, err := strconv.ParseUint(minimumDurationString, 10, 64)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			fmt.Fprintln(os.Stderr, "Error parsing minimum duration, using default value of 0ms")
			minimumDurationMs = 0
		}
		if argMinimumDurationMs > 0 {
			minimumDurationMs = argMinimumDurationMs
		}
		fmt.Println("Minimum Duration: ", minimumDurationMs)
		bpfModule.InitGlobalVariable("min_duration_ns", uint64(minimumDurationMs*(1000000)))

		bpfModule.BPFLoadObject()

		prog, err := bpfModule.GetProgram("uprobe_query")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}
		offset, err := helpers.SymbolToOffset(binaryPath, symbolName)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}

		// Attach Probes
		_, err = prog.AttachUprobe(-1, binaryPath, offset)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}

		prog, err = bpfModule.GetProgram("uretprobe_query")
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}

		_, err = prog.AttachURetprobe(-1, binaryPath, offset)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}

		//Init Events
		eventsChannel := make(chan []byte)
		rb, err := bpfModule.InitRingBuf("rb", eventsChannel)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(-1)
		}
		rb.Poll(rate)
		for {
			eventBytes := <-eventsChannel
			DurationNS := float64(binary.LittleEndian.Uint64(eventBytes[0:8]))
			Query := string(trimString(eventBytes[8 : 8+TASK_QUERY_LEN]))
			queryLatencyChan <- QueryLatency{Query: Query, Latency: DurationNS}
		}
	}()

	return queryLatencyChan
}
