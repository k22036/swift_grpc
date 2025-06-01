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
                            target: .dns(host: "localhost", port: 5300),
                            transportSecurity: .plaintext
                        )
                    ) { client in
                        print("Connected to gRPC server.")
                        let pinger = Pinger_Pinger.Client(wrapping: client)
                        print("Sending ping request...")
                        let pong = try await pinger.ping(request: .init(message: Pinger_Empty()))
                        print(pong)
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
