#!/usr/bin/env bash

echo -e "**********************\n\nStarting HBase as ${MODE}:"
NN_NGINX=${NN_NGINX:-"localhost:9090"}

download_hdfs_conf(){
    IFS=":" read -ra REMOTE_ADDR <<< "${NN_NGINX}"

    until $(nc -z -v -w5 ${REMOTE_ADDR[0]} ${REMOTE_ADDR[1]}); do
        echo "Waiting for ${NN_NGINX} to be available..."
        sleep 3
    done
    curl -s -o /opt/hbase/conf/hdfs-site.xml ${NN_NGINX}/hdfs-site.xml
    curl -s -o /opt/hbase/conf/core-site.xml ${NN_NGINX}/core-site.xml
}

trap_func(){
    echo -e "**********************\n\nShutting down HBase:"
    /opt/hbase/bin/stop-hbase.sh
    sleep 1
}

trap trap_func INT QUIT TRAP ABRT TERM EXIT

if [ "$MODE" == 'standalone' ]
then
    /opt/hbase/bin/start-hbase.sh
    /opt/hbase/bin/hbase-daemon.sh start rest
else
    sed -i "s|{{hdfs.nn}}|$HDFS_NN|g" /opt/hbase/conf/hbase-site.xml
    sed -i "s|{{zookeeper.quorum}}|$ZOOKEEPER_QUORUM|g" /opt/hbase/conf/hbase-site.xml
    if [ "$MODE" == 'master' ]
    then
        download_hdfs_conf
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master
        /opt/hbase/bin/hbase-daemon.sh start rest
    elif [ "$MODE" == 'backup' ]
    then
        download_hdfs_conf
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master-backup
    elif [ "$MODE" == 'regionserver' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start regionserver
    fi
fi


tail -f /opt/hbase/logs/* &
wait || :
