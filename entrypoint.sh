#!/usr/bin/env bash

echo -e "**********************\n\nStarting HBase as ${MODE}:"
NN_NGINX_LIST=${NN_NGINX_LIST:-"localhost:9090"}

download_hdfs_conf(){
    IFS=',' read -ra NN_NGINXS <<< "$NN_NGINX_LIST"
    num_nn=${#NN_NGINXS[*]}

    IFS=":" read -ra REMOTE_ADDR <<< "${NN_NGINXS[$((RANDOM%num_nn))]}"

    NGINX_HOST="${REMOTE_ADDR[0]}"
    NGINX_PORT="${REMOTE_ADDR[1]}"
    until $(nc -z -v -w5 ${NGINX_HOST} ${NGINX_PORT}); do
        echo "Waiting for ${NGINX_HOST} ${NGINX_PORT} to be available..."
        sleep 3
    done
    NN_NGINX="${NGINX_HOST}:${NGINX_PORT}"
    curl -s -o /opt/hbase/conf/hdfs-site.xml ${NN_NGINX}/hdfs-site.xml
    curl -s -o /opt/hbase/conf/core-site.xml ${NN_NGINX}/core-site.xml
}

trap_func(){
    if [ "$MODE" == 'regionserver' ]
    then
        echo -e "**********************\n\nShutting down HBase regionserver:"
        /opt/hbase/bin/hbase-daemon.sh stop regionserver
    else
        echo -e "**********************\n\nShutting down HBase cluster:"
        /opt/hbase/bin/stop-hbase.sh
    fi
    sleep 1
}

trap trap_func INT QUIT TRAP ABRT TERM EXIT

if [ "$MODE" == 'standalone' ]
then
    mv /opt/hbase/conf/hbase-site-standalone.xml /opt/hbase/conf/hbase-site.xml

    /opt/hbase/bin/start-hbase.sh
    # /opt/hbase/bin/hbase-daemon.sh start rest
else
    mv /opt/hbase/conf/hbase-site-distributed.xml /opt/hbase/conf/hbase-site.xml
    sed -i "s|{{hbase.rootdir}}|$HBASE_ROOTDIR|g" /opt/hbase/conf/hbase-site.xml
    sed -i "s|{{zookeeper.quorum}}|$ZOOKEEPER_QUORUM|g" /opt/hbase/conf/hbase-site.xml

    download_hdfs_conf

    if [ "$MODE" == 'master' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master
        # /opt/hbase/bin/hbase-daemon.sh start rest
    elif [ "$MODE" == 'regionserver' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start regionserver
    fi
fi


tail -f /opt/hbase/logs/*.log &
wait || :
