#!/bin/bash
set -x

# toolchain
# /opt/linaro_aarch64_linux-2014.09_r20170413/bin/aarch64-linux-gnu-gcc --version
# export PATH=/opt/linaro_aarch64_linux-2014.09_r20170413/bin:$PATH

# Configs
ARCH=`uname -m`
PREFIX="/NDS/"$ARCH

XARCH="aarch64"
XPREFIX="/NDS/"$XARCH
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

# 01. build protobuf (host)
if [ ! -f source/.protobuf_$ARCH ]; then
    mkdir -p source/protobuf-3.11.2/build_$ARCH
    cd source/protobuf-3.11.2/build_$ARCH
    ../configure --prefix=$PREFIX --enable-shared=no
    make -j4
    make install
    cd -
    touch source/.protobuf_$ARCH
fi

# 02. build protobuf-c (host)
if [ ! -f source/.protobuf-c_$ARCH ]; then
    pushd .
    cd source/protobuf-c-*
    mkdir -p build_$ARCH && cd build_$ARCH
    PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig ../configure --with-protoc=$PREFIX/bin/protoc --prefix=$PREFIX --enable-shared=no
    make -j4
    make install
    popd
    touch source/.protobuf-c_$ARCH
fi

# 03. build protobuf (target)
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

# 04. build protobuf-c (host)
if [ ! -f source/.protobuf-c_$XARCH ]; then
# ---------------------------------------------------------------------------------------
# Facing weird toolchain integration problem with libtool
# currently working around it
    patch -d /NDS/aarch64/lib -p1 < ~/patches/libtool_error_finding_libstdc++.patch
# ---------------------------------------------------------------------------------------
    pushd .
    cd source/protobuf-c-*
    mkdir -p build_$XARCH && cd build_$XARCH
    PKG_CONFIG_PATH=$XPREFIX/lib/pkgconfig ../configure --host=$XHOST --with-protoc=$PREFIX/bin/protoc --prefix=$XPREFIX --enable-shared=no
    make -j4
    make install
    popd
    touch source/.protobuf-c_$XARCH
fi

# 05. build protobuf (target)
if [ ! -f source/.libnet ]; then
    cd source/libnet-*
    ./configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no
    make -j4
    make install
    cd -
    touch source/.libnet
fi

# 06. build protobuf (target)
if [ ! -f source/.libnl3 ]; then
    cd source/libnl-*
    ./configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no
    make -j4
    make install
    cd -
    touch source/.libnl3
fi

# 06. build libaio
if [ ! -f source/.libaio ]; then
    cd source/libaio-*
    ENABLE_SHARED=0 CC=$XHOST-gcc make -j4
    ENABLE_SHARED=0 CC=$XHOST-gcc make prefix=$XPREFIX install
    cd -
    touch source/.libaio
fi

# libcap is a bit tricky
# https://wiki.beyondlogic.org/index.php?title=Cross_Compiling_SystemD_for_ARM

# 06. build libattr
# TODO: this is poobably not required, re-confirm
if [ ! -f source/.libattr ]; then
    cd source/attr-*
    ./configure --prefix=$XPREFIX --host=$XHOST --enable-shared=no --enable-gettext=no
    make -j4
    make install
    cd -
    touch source/.libattr
fi

# 06. build libcap
# TODO: currently libcap is built independent of kernel headers
#       it is wrong to do so & might fail badly in some circumstances 
if [ ! -f source/.libcap ]; then
    cd source/libcap-*
    make prefix=$XPREFIX BUILD_CC=gcc CC=$XHOST-gcc LDFLAGS="-L$XPREFIX/lib" DYNAMIC=no PROGS=getpcaps LIBATTR=no install V=1
    cd -
    touch source/.libcap
fi

# exit 0

# TODO: toolchain is not able to find pthread ?? 
#       work around -L/usr/aarch64-linux-gnu/lib

# 06. build criu
if [ ! -f source/.criu ]; then
    cd source/criu-*
    ln -sf /NDS/aarch64/include/google/protobuf/descriptor.proto ./images/google/protobuf/descriptor.proto
    export PATH=/NDS/$ARCH/bin:$PATH
    export PKG_CONFIG_PATH=$XPREFIX/lib/pkgconfig
    export ARCH=$XARCH
    export CROSS_COMPILE=$XHOST-
    export USERCFLAGS="-I/NDS/$XARCH/include -I/NDS/$XARCH/include/libnl3"
    export CFLAGS=`-I/usr/aarch64-linux-gnu/include pkg-config --cflags libprotobuf-c`
    export LDFLAGS="-L/NDS/$XARCH/lib64 `pkg-config --libs libprotobuf-c` -L/usr/aarch64-linux-gnu/lib -lpthread -lrt"
    make mrproper
    # make V=1 CC=$XHOST-gcc
    make V=1 CC=$XHOST-gcc -C test/zdtm
    cd -
    # touch source/.criu
fi

# exit 1

echo "success"