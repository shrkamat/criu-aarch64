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
# TODO: make user name dynamic $USERNAME should have worked but doesn't 
ARG UNAME=skamath
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
USER $UNAME

WORKDIR /home/skamath

ENTRYPOINT ./build.sh
