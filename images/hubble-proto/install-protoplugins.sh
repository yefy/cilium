#!/bin/bash

set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

mkdir /proto
cd /proto

unset GOPATH

go mod init github.com/cilium/hubble/protoc

# latest tag at the time. For some reason `go get foo/bar/baz@vX.Y.Z` doesn't
# work with nested go.mod definitions.
# a80e650 == tag: cmd/protoc-gen-go-grpc/v1.0.1
go get google.golang.org/grpc/cmd/protoc-gen-go-grpc@a80e65018272ac6bd58ee44d0d3e37374b090c1f
go build google.golang.org/grpc/cmd/protoc-gen-go-grpc

# protoc-gen-go-json doesn't have releases, this is the latest commit at the time
go get github.com/mitchellh/protoc-gen-go-json@364b693
go build github.com/mitchellh/protoc-gen-go-json

go get github.com/golang/protobuf@v1.4.3
go build github.com/golang/protobuf/protoc-gen-go
