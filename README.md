# HBase image for Docker

## How to build

```
make build
```

## Full distributed mode

Start master:

```
docker run -d --net=host --name=hbase-master -e HBASE_ROOTDIR=hdfs://ns1/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -e NN_NGINX_LIST=10.0.0.4:9090,10.0.0.5:9090 -v /data/hbase:/hbase -e MODE=master liubin/hbase:1.2.6
```

Start back master(optional):

```
docker run -d --net=host --name=hbase-backup -e HBASE_ROOTDIR=hdfs://ns1:8020/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -e NN_NGINX_LIST=10.0.0.4:9090,10.0.0.5:9090 -v /data/hbase:/hbase -e MODE=backup liubin/hbase:1.2.6

```

Start region server:

```
docker run -d --net=host --name=hbase-region -e HBASE_ROOTDIR=hdfs://ns1:8020/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -v /data/hbase:/hbase -e MODE=regionserver liubin/hbase:1.2.6
```

## Standalone mode

All in one container(ZK,HBase, for dev only)

```
docker run -d --net=host --name=hbase-standalone -e MODE=standalone liubin/hbase:1.2.6
```
