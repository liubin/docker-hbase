#!/usr/bin/env bash

echo -e "**********************\n\nStarting HBase as ${MODE}:"
NN_NGINX_LIST=${NN_NGINX_LIST:-"localhost:9090"}

download_hadoop_files(){
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
    #curl -s -o /opt/hbase/conf/hdfs-site.xml ${NN_NGINX}/hdfs-site.xml
    #curl -s -o /opt/hbase/conf/core-site.xml ${NN_NGINX}/core-site.xml

    curl -s -o /tmp/hadoop.conf.tar.gz ${NN_NGINX}/hadoop.conf.tar.gz
    cd /tmp && tar zxf hadoop.conf.tar.gz \
    && cp hadoop/hdfs-site.xml /opt/hbase/conf/hdfs-site.xml \
    && cp hadoop/core-site.xml /opt/hbase/conf/core-site.xml \
    && cd /tmp/ && rm -rf hadoop && rm hadoop.conf.tar.gz

    curl -s -o /tmp/hadoop.lib.native.tar.gz ${NN_NGINX}/hadoop.lib.native.tar.gz
    tar zxf /tmp/hadoop.lib.native.tar.gz -C /opt/hbase/lib/
    rm /tmp/hadoop.*.tar.gz
    # export HBASE_LIBRARY_PATH=$HBASE_HOME/lib/native
    # bin/hbase org.apache.hadoop.hbase.util.CompressionTest file:///tmp/test.txt snappy
}

trap_func(){
    if [ "$MODE" == 'regionserver' ]
    then
        echo -e "**********************\n\nShutting down HBase regionserver"
        /opt/hbase/bin/hbase-daemon.sh stop regionserver
    else
        echo -e "**********************\n\nShutting down HBase master"
        /opt/hbase/bin/hbase-daemon.sh stop master
    fi
    sleep 1
}

trap trap_func INT QUIT TRAP ABRT TERM EXIT

if [ "$MODE" == 'standalone' ]
then
    if [ -f /opt/hbase/conf/hbase-site-standalone.xml ]; then
        mv /opt/hbase/conf/hbase-site-standalone.xml /opt/hbase/conf/hbase-site.xml
    fi
    /opt/hbase/bin/start-hbase.sh
    # /opt/hbase/bin/hbase-daemon.sh start rest
else
    if [ -f /opt/hbase/conf/hbase-site-distributed.xml ]; then
        mv /opt/hbase/conf/hbase-site-distributed.xml /opt/hbase/conf/hbase-site.xml
    fi
    sed -i "s|{{hbase.rootdir}}|$HBASE_ROOTDIR|g" /opt/hbase/conf/hbase-site.xml
    sed -i "s|{{zookeeper.quorum}}|$ZOOKEEPER_QUORUM|g" /opt/hbase/conf/hbase-site.xml

    ZOOKEEPER_ZNODE_PARENT=${ZOOKEEPER_ZNODE_PARENT:-"/hbase"}
    sed -i "s|{{zookeeper.znode.parent}}|$ZOOKEEPER_ZNODE_PARENT|g" /opt/hbase/conf/hbase-site.xml
    download_hadoop_files

    if [ "$MODE" == 'master' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master
        # /opt/hbase/bin/hbase-daemon.sh start rest
    elif [ "$MODE" == 'regionserver' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start regionserver
    fi
fi

echo "Waiting HBase to startup..."
sleep 10
echo "Check if HBase is running..."
echo 'status' | hbase shell -n
status=$?
echo "status: ${status}"

until [[ $status -eq 0 ]]; do
    echo "Waiting for HBase to be available, status: ${status}"
    sleep 5
    echo 'status' | hbase shell -n
    status=$?
done

if [ "$MODE" != 'regionserver' -a "$OPENTSDB_ENABLED" == "true" ]
then
    echo "Check if opentsdb tables exits ..."
    /create-opentsdb-tables.sh
fi

echo -e "\nInit has completed, HBase is running ..."
while true; do
    x=$(ps -ef | grep java | grep -v "grep" | wc -l)
    if [[ $x -eq 0 ]]; then
        echo "No Java processes is running, exit ...."
        exit 0
    fi
    sleep 10
done
