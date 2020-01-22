#!/bin/bash
set -xe

# Configs
ARCH=`uname -m`
PREFIX="/output/"$ARCH

XARCH="aarch64"
XPREFIX="/output/"$XARCH
XHOST="aarch64-linux-gnu"

# Resources
# =========
# https://criu.org/ARM_crosscompile
# https://github.com/cyrillos/criu/blob/master/Documentation/HOWTO.cross-compile

if [ ! -f .fetch ]; then
    wget -P download -i fetch.txt
    touch .fetch
fi

if [ ! -f .source ]; then
    mkdir -p source
    find download -mindepth 1 | xargs -n 1 -I {} tar -xvf {} -C source/
    touch .source
fi

# SHELL = bash
ln -sf /bin/bash /bin/sh

# 01. build protobuf (target)
if [ ! -f source/.protobuf_$XARCH ]; then
    pushd .
    cd source/protobuf-3.11.2
    mkdir -p build_$XARCH && cd build_$XARCH
    ../configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no
    make -j4
    make install
    popd
    touch source/.protobuf_$XARCH
fi

# 02. build protobuf-c (host)
if [ ! -f source/.protobuf-c_$XARCH ]; then
    pushd .
    cd source/protobuf-c-*
    mkdir -p build_$XARCH && cd build_$XARCH
    PKG_CONFIG_PATH=$XPREFIX/lib/pkgconfig ../configure --host=$XHOST --prefix=$XPREFIX --enable-shared=no
    make -j4
    make install
    popd
    touch source/.protobuf-c_$XARCH
fi

# 03. build libnet
if [ ! -f source/.libnet ]; then
    cd source/libnet-*
    ./configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no
    make -j4
    make install
    cd -
    touch source/.libnet
fi

# 04. build libnl3
if [ ! -f source/.libnl3 ]; then
    cd source/libnl-*
    ./configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no
    make -j4
    make install
    cd -
    touch source/.libnl3
fi

# 05. build libaio
if [ ! -f source/.libaio ]; then
    cd source/libaio-*
    CC=$XHOST-gcc make -j4
    CC=$XHOST-gcc make prefix=$XPREFIX install
    cd -
    touch source/.libaio
fi

# libcap is a bit tricky
# https://wiki.beyondlogic.org/index.php?title=Cross_Compiling_SystemD_for_ARM

# 06. build libcap
# TODO: currently libcap is built independent of kernel headers
#       it is wrong to do so & might fail badly in some circumstances 
if [ ! -f source/.libcap ]; then
    cd source/libcap-*
    make prefix=$XPREFIX BUILD_CC=gcc CC=$XHOST-gcc LDFLAGS="-L$XPREFIX/lib" DYNAMIC=no PROGS=getpcaps LIBATTR=no install V=1
    cd -
    touch source/.libcap
fi

# CRIU unable build will all required packages ??
# dont understand Makefile call try-cc, is try-cc really using crosstool ?
# How can I make try-cc verbose ?
if [ ! -f source/.criu_patched ]; then
    patch -d source/criu-* -p1 < patches/Fix-CRIU-find-packages.patch
    touch source/.criu_patched
fi

# TODO: toolchain is not able to find pthread ?? 
#       work around -L/usr/aarch64-linux-gnu/lib

# 07. build criu
if [ ! -f source/.criu ]; then
    cd source/criu-*
    export PKG_CONFIG_PATH=$XPREFIX/lib/pkgconfig:$PKG_CONFIG_PATH
    make mrproper
    make ARCH=$XARCH CROSS_COMPILE=/usr/bin/aarch64-linux-gnu- USERCFLAGS="-I$XPREFIX/include -I$XPREFIX/include/libnl3 -I/usr/aarch64-linux-gnu/include -L/usr/aarch64-linux-gnu/lib -L/$XPREFIX/lib64 -L/$XPREFIX/lib -lprotobuf-c -lpthread -lrt" V=1
    touch source/.criu
fi

echo "success"
