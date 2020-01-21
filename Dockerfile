FROM ubuntu:18.04

RUN true \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y \
        build-essential \
        gcc-multilib \
        g++-multilib \
        git-core \
        pkg-config \
        flex \
        libtool-bin \
        strace \
        wget \
        bison \
        zlib1g-dev:i386

# TODO: make user name dynamic $USERNAME should have worked but doesn't 
ARG UNAME=skamath
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
USER $UNAME

WORKDIR /home/skamath

# ENTRYPOINT ./build.sh
