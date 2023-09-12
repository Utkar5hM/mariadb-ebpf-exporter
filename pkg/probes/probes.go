package probes

import "C"

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"os"

	bpf "github.com/aquasecurity/libbpfgo"
	"github.com/aquasecurity/libbpfgo/helpers"
)

const (
	TASK_QUERY_LEN = 52488
)

type QueryLatency struct {
	Query   string
	Latency uint64
}

func trimString(input []byte) []byte {
	if idx := bytes.IndexByte(input, 0x00); idx != -1 {
		return input[:idx]
	}
	return input
}

func GetQueryLatencies(rate int) <-chan QueryLatency {
	bpfModule, err := bpf.NewModuleFromFile("./main.bpf.o")
	if err != nil {
		panic(err)
	}
	defer bpfModule.Close()

	bpfModule.BPFLoadObject()

	prog, err := bpfModule.GetProgram("uprobe_query")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(-1)
	}
	binaryPath := "/usr/bin/mariadbd"
	symbolName := "_Z16dispatch_command19enum_server_commandP3THDPcjb"
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

	queryLatencyChan := make(chan QueryLatency)
	go func() {
		for {
			eventBytes := <-eventsChannel
			DurationNS := binary.LittleEndian.Uint64(eventBytes[0:8]) / 1000000
			Query := string(trimString(eventBytes[8 : 8+TASK_QUERY_LEN]))
			queryLatencyChan <- QueryLatency{Query: Query, Latency: DurationNS}
		}
	}()

	return queryLatencyChan
}