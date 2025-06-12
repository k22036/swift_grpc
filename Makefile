# server
PROTO_OUT_SERVER = server/proto

PROTO_GEN_SERVER = protoc \
	-I=proto proto/pinger.proto \
	--go_out=$(PROTO_OUT_SERVER) \
	--go_opt=paths=source_relative \
	--go-grpc_out=$(PROTO_OUT_SERVER) \
	--go-grpc_opt=paths=source_relative \
	proto/pinger.proto

# swift
PROTOC_GEN_SWIFT=/opt/homebrew/bin/protoc-gen-swift
PROTOC_GEN_GRPC_SWIFT=/opt/homebrew/bin/protoc-gen-grpc-swift

PROTO_OUT_CLIENT = client/grpc_client_ios/grpc_client_ios/proto

PROTO_GEN_CLIENT_PB = protoc \
	--proto_path=proto \
	--plugin=$(PROTOC_GEN_SWIFT) \
	--swift_opt=Visibility=Public \
	--swift_out=$(PROTO_OUT_CLIENT) \
	proto/pinger.proto

PROTO_GEN_CLIENT_GRPC = protoc \
	--proto_path=proto \
	--plugin=$(PROTOC_GEN_GRPC_SWIFT) \
	--grpc-swift_opt=Visibility=Public \
	--grpc-swift_out=$(PROTO_OUT_CLIENT) \
	proto/pinger.proto

# server
gen_server_proto:
	$(PROTO_GEN_SERVER)

# client
gen_client_pb:
	$(PROTO_GEN_CLIENT_PB)
gen_client_grpc:
	$(PROTO_GEN_CLIENT_GRPC)
gen_client_proto: gen_client_pb gen_client_grpc

# generate all protos
gen_all_proto: gen_server_proto gen_client_proto

# run server
run_server:
	cd server && go run server.go

# send ping
send_ping:
	cd server && go run cmd/command.go