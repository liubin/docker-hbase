# HBase image for Docker

## How to build

```
make build
```

## Full distributed mode

Start master:

```
docker run -d --net=host --name=hbase-master -e HDFS_NN=hdfs://10.0.0.4:8020/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -v /data/hbase:/hbase -e MODE=master liubin/hbase
```

Start back master(optional):

```
docker run -d --net=host --name=hbase-backup -e HDFS_NN=hdfs://10.0.0.4:8020/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -v /data/hbase:/hbase -e MODE=backup liubin/hbase

```

Start region server:

```
docker run -d --net=host --name=hbase-region -e HDFS_NN=hdfs://10.0.0.4:8020/hbase -e ZOOKEEPER_QUORUM=10.0.0.4:2181 -v /data/hbase:/hbase -e MODE=regionserver liubin/hbase
```

## Standalone mode

All in one container(ZK,HBase, for dev only)

```
docker run -d --net=host --name=hbase-standalone -e MODE=standalone liubin/hbase
```
