package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"time"

	pinger "server/proto"

	"google.golang.org/grpc"
)

func main() {
	listener, err := net.Listen("tcp", ":5300")
	if err != nil {
		log.Fatalf("failed to listen: %v\n", err)
		return
	}
	grpcSrv := grpc.NewServer()
	pinger.RegisterPingerServer(grpcSrv, &server{})
	pinger.RegisterVerificationServer(grpcSrv, &server{})
	pinger.RegisterLatencyTestServer(grpcSrv, &server{})
	log.Printf("Pinger service is running!")
	grpcSrv.Serve(listener)
}

type server struct {
	pinger.UnimplementedPingerServer
	pinger.UnimplementedVerificationServer
	pinger.UnimplementedLatencyTestServer
}

func (s *server) Ping(ctx context.Context, req *pinger.Empty) (*pinger.Pong, error) {
	pong := &pinger.Pong{
		Text: "pong",
	}
	println("Received ping request")
	return pong, nil
}

const maxVerificationCount = 11

func (s *server) Verify(stream pinger.Verification_VerifyServer) error {
	count := 0
	for {
		req, err := stream.Recv()
		if err != nil {
			if errors.Is(err, io.EOF) {
				break
			}
			log.Printf("stream recv error: %v", err)
			return err
		}
		count++
		log.Printf("Received VerificationRequest #%d: %v", count, req.GetNumber())

		resp := &pinger.VerificationResponse{
			IsAck:   true,
			Message: "Received number: " + fmt.Sprint(req.GetNumber()),
		}
		if err := stream.Send(resp); err != nil {
			log.Printf("stream send error: %v", err)
			return err
		}
		// If the count reaches the maximum verification count, exit the loop.
		// This ensures that after receiving the specified number of requests,
		// the server waits for 10 minutes before sending the final message.
		if count == maxVerificationCount {
			break
		}
	}

	// 11回受信したら10分後にメッセージを返す
	select {
	case <-stream.Context().Done():
		log.Println("Stream context done, exiting Verify")
		return stream.Context().Err()
	case <-time.After(10 * time.Minute):
		finalResp := &pinger.VerificationResponse{
			IsAck:   false,
			Message: "Final message after 10 minutes",
		}
		if err := stream.Send(finalResp); err != nil {
			log.Printf("stream send error after 10 minutes: %v", err)
			return err
		}
		log.Println("Sent final message after 10 minutes")
	}
	log.Println("Verify stream completed")

	return nil
}

// MeasureLatency implements the LatencyTestServer interface.
func (s *server) MeasureLatency(ctx context.Context, req *pinger.LatencyRequest) (*pinger.LatencyResponse, error) {
	log.Printf("Received MeasureLatency request with client timestamp: %d", req.GetClientSentTimestampNs())

	resp := &pinger.LatencyResponse{
		ClientSentTimestampNs: req.GetClientSentTimestampNs(),
		Payload:               req.GetPayload(),
	}

	log.Printf("Sending MeasureLatency response")
	return resp, nil
}
