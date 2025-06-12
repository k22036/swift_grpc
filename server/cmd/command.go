package main

import (
	"context"
	"fmt"
	"os"

	pinger "server/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func cmd() {
	conn, err := grpc.NewClient("localhost:5300", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to connect: %v\n", err)
		return
	}
	defer conn.Close()
	client := pinger.NewPingerClient(conn)
	req := &pinger.Empty{}
	pong, err := client.Ping(context.Background(), req)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Ping: %v\n", err)
		return
	}
	fmt.Fprintf(os.Stdout, "Pong: %s\n", pong.Text)
}
