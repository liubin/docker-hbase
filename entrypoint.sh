#!/usr/bin/env bash

echo -e "\n\nStarting HBase as ${MODE}:"

trap_func(){
    echo -e "\n\nShutting down HBase:"
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
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master
        /opt/hbase/bin/hbase-daemon.sh start rest
    elif [ "$MODE" == 'backup' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start master-backup
    elif [ "$MODE" == 'regionserver' ]
    then
        /opt/hbase/bin/hbase-daemon.sh --config /opt/hbase/conf/ start regionserver
    fi
fi


tail -f /opt/hbase/logs/* &
wait || :
