FROM openjdk:8-jdk-alpine

RUN apk --no-cache --update add bash ca-certificates curl tar

# https://github.com/Yelp/dumb-init
RUN curl -fLsS -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && chmod +x /usr/local/bin/dumb-init

ENV COMPRESSION NONE
ENV HBASE_VERSION 1.2.6
VOLUME /hbase

# https://www.apache.org/mirrors/dist.html
RUN mkdir /opt && \
    curl -fL http://mirror.bit.edu.cn/apache/hbase/stable/hbase-${HBASE_VERSION}-bin.tar.gz | tar xzf - -C /opt && \
    mv /opt/hbase-${HBASE_VERSION} /opt/hbase && \
    rm -rf /opt/hbase/docs && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENV HBASE_HOME /opt/hbase
WORKDIR /opt/hbase

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/hbase/bin

COPY conf/* /opt/hbase/conf/
COPY entrypoint.sh /

RUN chmod a+x /entrypoint.sh
ENV HADOOP_USER_NAME hadoop

ENTRYPOINT ["/usr/local/bin/dumb-init", "/entrypoint.sh"]
