.PHONY: build
build:
	docker build -t liubin/hbase .

.PHONY: run
run:
	-docker rm -fv hbase-standalone
	docker run -d --net=host --name=hbase-standalone -e MODE=standalone liubin/hbase

all: build run

