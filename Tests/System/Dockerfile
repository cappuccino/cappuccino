FROM ubuntu:18.04

RUN apt-get update && apt-get install -y \
    curl \
    default-jre \
    unzip

ADD bootstrap.sh /tmp/cappuccino_bootstrap.sh

RUN chmod a+x /tmp/cappuccino_bootstrap.sh && /tmp/cappuccino_bootstrap.sh --noprompt --directory /usr/local/narwhal
