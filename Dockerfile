FROM oberthur/docker-ubuntu-java:jdk8_8.112.15

MAINTAINER Tima Kulishov <kulishovt@gmail.com>

ENV HOME=/opt/app

WORKDIR /opt/app

COPY jpagent /opt/jpagent

ENV JPAGENT_PATH="-agentpath:/usr/local/jprofiler8/bin/linux-x64/libjprofilerti.so=nowait"
EXPOSE 8849

