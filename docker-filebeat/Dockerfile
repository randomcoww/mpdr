FROM debian:sid

ENV DEBIAN_FRONTEND noninteractive

RUN \
    apt-get update -qq && \
    apt-get install -qqy --no-install-recommends wget ca-certificates && \
    wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-5.2.0-amd64.deb && \
    dpkg -i filebeat-*.deb && \
    rm filebeat-*.deb && \
    apt-get purge -y wget && \
    apt autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/*

ENTRYPOINT ["/usr/bin/filebeat.sh"]
