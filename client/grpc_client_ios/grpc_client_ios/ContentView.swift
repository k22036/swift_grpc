//
//  ContentView.swift
//  grpc_client_ios
//
//  Created by k22036kk on 2025/05/22.
//

import SwiftUI
import GRPCCore
import GRPCNIOTransportHTTP2

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("gRPC接続テスト（Verification）") {
            Task {
                print("Connecting to gRPC server...")
                do {
                    try await withGRPCClient(
                        transport: .http2NIOPosix(
                            target: .dns(host: "10.14.2.162", port: 5300),
                            transportSecurity: .plaintext
                        )
                    ) { client in
                        print("Connected to gRPC server.")
                        let verification = Pinger_Verification.Client(wrapping: client)
                        print("Sending verification stream...")
                        try await verification.verify(requestProducer: { writer in
                            for n in 1...11 {
                                var req = Pinger_VerificationRequest()
                                req.number = Int32(n)
                                print("Send: \(n)")
                                try await writer.write(req)
                                try await Task.sleep(nanoseconds: 60 * 1_000_000_000) // 1分待つ
                            }
                        }, onResponse: { responseStream in
                            // AsyncSequenceに変換してイテレート
                            for try await response in responseStream.messages {
                                print("Received: isAck=\(response.isAck), message=\(response.message)")
                            }
                        })
                        print("Verification stream finished.")
                    }
                } catch {
                    print("Failed to connect to gRPC server: \(error)")
                }
            }
        }
            Button("RTT測定（100回）") {
                Task {
                    print("Connecting to gRPC server for latency test...")
                    do {
                        try await withGRPCClient(
                            transport: .http2NIOPosix(
                                target: .dns(host: "k22036kknoMacBook-Air.local", port: 5300),
                                transportSecurity: .plaintext
                            )
                        ) { client in
                            print("Connected to gRPC server.")
                            let latencyTest = Pinger_LatencyTest.Client(wrapping: client)
                            let numRequests = 100
                            var totalLatency: TimeInterval = 0
                            var successfulRequests = 0
                            for i in 1...numRequests {
                                let clientSentTimestamp = Int64(Date().timeIntervalSince1970 * 1_000_000_000)
                                var req = Pinger_LatencyRequest()
                                req.clientSentTimestampNs = clientSentTimestamp
                                req.payload = Data("request-\(i)".utf8)
                                let start = Date()
                                do {
                                    let resp = try await latencyTest.measureLatency(req)
                                    let end = Date()
                                    let rtt = end.timeIntervalSince(start)
                                    totalLatency += rtt
                                    successfulRequests += 1
                                    if resp.clientSentTimestampNs != clientSentTimestamp {
                                        print("警告: リクエスト\(i)でエコーバックされたタイムスタンプが一致しません。送信: \(clientSentTimestamp), 受信: \(resp.clientSentTimestampNs)")
                                    }
                                    print("リクエスト\(i): RTT = \(rtt * 1000) ms")
                                } catch {
                                    print("リクエスト\(i)が失敗: \(error)")
                                }
                                try await Task.sleep(nanoseconds: 50_000_000) // 50ms
                            }
                            if successfulRequests > 0 {
                                let avg = totalLatency / Double(successfulRequests)
                                print("--- 結果 ---")
                                print("成功したリクエストの総数: \(successfulRequests)")
                                print("平均RTT: \(avg) 秒")
                                print("平均RTT (ミリ秒): \(avg * 1000) ms")
                            } else {
                                print("成功したリクエストはありませんでした。")
                            }
                        }
                    } catch {
                        print("Failed to connect to gRPC server: \(error)")
                    }
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    ContentView()
//}
