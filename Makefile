all: test

help:		## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

build:		## Compiles the binaries and leaves them in the root folder. You may want to move them to your ${GOPATH}/bin
	./misc/local/build.sh

init:   	## Install dependencies
	go get -u github.com/AlekSi/gocoverutil
	go get -u golang.org/x/perf/cmd/benchstat
	go get -u github.com/dvyukov/go-fuzz/...
	go get -u gopkg.in/alecthomas/gometalinter.v2
	gometalinter.v2 --install

protos: 	## Generate proto files
	go install -v ./vendor/github.com/golang/protobuf/protoc-gen-go
	go install -v ./vendor/github.com/gogo/protobuf/protoc-gen-gogo

	rm -f prompb/*.pb.go
	protoc -Ivendor/github.com/gogo/protobuf -Iprompb prompb/*.proto --gogo_out=prompb

install:	## Install promhouse
	go install -v ./...

install-race:
	go install -v -race ./...

test: install	 ## Install and run tests
	go test -v -tags gofuzzgen ./...

test-race: install-race
	go test -v -tags gofuzzgen -race ./...

bench: install
	go test -run=NONE -bench=. -benchtime=3s -count=5 -benchmem ./... | tee new.txt

run: install 	## Install and run promhouse
	go run ./cmd/promhouse/*.go --log.level=info

run-race: install-race
	go run -race ./cmd/promhouse/*.go --log.level=info

cover: install
	gocoverutil test -v -covermode=count ./...

check: install
	-gometalinter.v2 --tests --vendor --skip=prompb --deadline=300s --sort=linter ./...

gofuzz: test
	go-fuzz-build -func=FuzzJSON -o=json-fuzz.zip github.com/Percona-Lab/PromHouse/storages/clickhouse
	go-fuzz -bin=json-fuzz.zip -workdir=go-fuzz/json

up:	## Starts the test environment (Linux)
	docker-compose -f misc/docker-compose-linux.yml -p promhouse up --force-recreate --abort-on-container-exit --renew-anon-volumes --remove-orphans

up-mac:
	docker-compose -f misc/docker-compose-mac.yml -p promhouse up --force-recreate --abort-on-container-exit --renew-anon-volumes --remove-orphans

down:
	docker-compose -f misc/docker-compose-linux.yml -p promhouse down --volumes --remove-orphans

down-mac:
	docker-compose -f misc/docker-compose-mac.yml -p promhouse down --volumes --remove-orphans

clickhouse-client:
	docker exec -ti -u root promhouse_clickhouse_1 /usr/bin/clickhouse --client --database=prometheus
