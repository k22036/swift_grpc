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
        }
        .padding()
        .onAppear() {
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
    }
}

//#Preview {
//    ContentView()
//}
