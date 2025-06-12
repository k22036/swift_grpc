package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	command := flag.String("command", "", "Command to execute (latency or ping)")
	flag.Parse()

	switch *command {
	case "latency":
		measureLatency()
	case "ping":
		cmd()
	default:
		fmt.Fprintf(os.Stderr, "Usage: %s -command <latency|ping>\n", os.Args[0])
		os.Exit(1)
	}
}
