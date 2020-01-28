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
        gcc-5-aarch64-linux-gnu \
        g++-5-aarch64-linux-gnu


RUN apt-get install -y libprotobuf-dev libprotobuf-c0-dev protobuf-c-compiler protobuf-compiler python-protobuf 

RUN ln -s /usr/bin/aarch64-linux-gnu-cpp-5 /usr/bin/aarch64-linux-gnu-cpp
RUN ln -s /usr/bin/aarch64-linux-gnu-g++-5 /usr/bin/aarch64-linux-gnu-g++
RUN ln -s /usr/bin/aarch64-linux-gnu-gcc-5 /usr/bin/aarch64-linux-gnu-gcc

WORKDIR /opt/criu

# ENTRYPOINT ./build.sh
