package main

import (
	"context"
	"fmt"
	"log"
	"time"

	pinger "server/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

const numRequests = 100
const serverAddress = "localhost:5300"

func measureLatency() {
	// gRPCサーバーに接続
	conn, err := grpc.NewClient(serverAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("サーバー %s への接続に失敗しました: %v", serverAddress, err)
	}
	defer conn.Close()

	client := pinger.NewLatencyTestClient(conn)

	var totalLatency time.Duration
	var successfulRequests int64

	fmt.Printf("%d 回のリクエストを %s に送信中...", numRequests, serverAddress)

	for i := 0; i < numRequests; i++ {
		// リクエスト送信前のクライアント側タイムスタンプ
		clientSentTimestampClientNs := time.Now().UnixNano()

		req := &pinger.LatencyRequest{
			ClientSentTimestampNs: clientSentTimestampClientNs,            // このタイムスタンプをサーバーに送信
			Payload:               []byte(fmt.Sprintf("request-%d", i+1)), // オプションのペイロード
		}

		startTime := time.Now() // RTT計測開始

		resp, err := client.MeasureLatency(context.Background(), req)
		if err != nil {
			log.Printf("リクエスト %d が失敗しました: %v", i+1, err)
			continue // エラーが発生した場合はこのリクエストをスキップ
		}

		endTime := time.Now() // RTT計測終了
		latency := endTime.Sub(startTime)
		totalLatency += latency
		successfulRequests++

		// サーバーからエコーバックされたタイムスタンプが一致するか確認 (オプション)
		if resp.GetClientSentTimestampNs() != clientSentTimestampClientNs {
			log.Printf("警告: リクエスト %d でエコーバックされたクライアントタイムスタンプが一致しません。送信: %d, 受信: %d",
				i+1, clientSentTimestampClientNs, resp.GetClientSentTimestampNs())
		}

		fmt.Printf("リクエスト %d: RTT = %v\n", i+1, latency)

		// リクエスト間に短い遅延を挿入 (サーバーへの負荷を軽減するため)
		time.Sleep(50 * time.Millisecond)
	}

	if successfulRequests > 0 {
		averageLatency := totalLatency / time.Duration(successfulRequests)
		fmt.Printf("--- 結果 ---")
		fmt.Printf("成功したリクエストの総数: %d", successfulRequests)
		fmt.Printf("平均RTT: %v", averageLatency)
		fmt.Printf("平均RTT (ミリ秒): %.3f ms", float64(averageLatency.Nanoseconds())/1e6)
	} else {
		fmt.Println("成功したリクエストはありませんでした。")
	}
}
