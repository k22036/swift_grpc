PROTO_OUT_SERVER = server/proto

PROTO_GEN_SERVER = protoc \
	-I=proto proto/pinger.proto \
	--go_out=$(PROTO_OUT_SERVER) \
	--go_opt=paths=source_relative \
	--go-grpc_out=$(PROTO_OUT_SERVER) \
	--go-grpc_opt=paths=source_relative \
	proto/pinger.proto

gen_server_proto:
	$(PROTO_GEN_SERVER)
