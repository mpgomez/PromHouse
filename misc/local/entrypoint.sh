#!/bin/bash

set -ex
cd /go/src/github.com/Percona-Lab/PromHouse

echo "Init:"
make init

echo "Genrate Proto"
make protos

echo "Build"
make install

echo "Test"

make test

echo "Copying binaries"
cp /go/bin/prom* /go/src/github.com/Percona-Lab/PromHouse/

echo "Project built. You may want to move the binaries to your ${GOPATH}/bin now"


