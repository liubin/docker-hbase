#!/bin/sh
# Small script to setup the HBase tables used by OpenTSDB.

test -n "$HBASE_HOME" || {
  echo >&2 'The environment variable HBASE_HOME must be set'
  exit 1
}
test -d "$HBASE_HOME" || {
  echo >&2 "No such directory: HBASE_HOME=$HBASE_HOME"
  exit 1
}

TSDB_TABLE=${TSDB_TABLE-'tsdb'}
UID_TABLE=${UID_TABLE-'tsdb-uid'}
TREE_TABLE=${TREE_TABLE-'tsdb-tree'}
META_TABLE=${META_TABLE-'tsdb-meta'}
BLOOMFILTER=${BLOOMFILTER-'ROW'}
TTL=${TTL-'1209600'}

if echo -e "exists '${TSDB_TABLE}'" | hbase shell 2>&1 | grep -q "does exist" 2>/dev/null 
then
    echo "Table ${TSDB_TABLE} already exists, skip."
else
    echo "Table ${TSDB_TABLE} does not exist, create opentsdb tables"
    ### create tables
    # LZO requires lzo2 64bit to be installed + the hadoop-gpl-compression jar.
    COMPRESSION=${COMPRESSION-'LZO'}
    # All compression codec names are upper case (NONE, LZO, SNAPPY, etc).
    COMPRESSION=`echo "$COMPRESSION" | tr a-z A-Z`

    case $COMPRESSION in
      (NONE|LZO|GZIP|SNAPPY)  :;;  # Known good.
      (*)
        echo >&2 "warning: compression codec '$COMPRESSION' might not be supported."
        ;;
    esac

    # HBase scripts also use a variable named `HBASE_HOME', and having this
    # variable in the environment with a value somewhat different from what
    # they expect can confuse them in some cases.  So rename the variable.
    hbh=$HBASE_HOME
    # unset HBASE_HOME
    "$hbh/bin/hbase" shell <<EOF
    create '$UID_TABLE',
      {NAME => 'id', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'},
      {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}

    create '$TSDB_TABLE',
      {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', TTL => $TTL}

    create '$TREE_TABLE',
      {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}

    create '$META_TABLE',
      {NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER'}
EOF

    echo "OpenTSDB tables created."
    ### create tables
fi
