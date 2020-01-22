FROM ubuntu:18.04

RUN true \
  && apt-get update \
  && apt-get install -y \
        build-essential \
        git-core \
        pkg-config \
        flex \
        libtool-bin \
        strace \
        wget \
        bison \
        gcc-7-aarch64-linux-gnu \
        g++-7-aarch64-linux-gnu


RUN apt-get install -y gcc-aarch64-linux-gnu
RUN apt-get install -y g++-aarch64-linux-gnu libprotobuf-dev libprotobuf-c0-dev protobuf-c-compiler protobuf-compiler python-protobuf 

WORKDIR /opt/criu

# ENTRYPOINT ./build.sh
