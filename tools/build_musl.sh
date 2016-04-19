#!/bin/sh

# build musl-1.1.14
#
# tested 2016-04-15 on a i386 32-bit linux with gcc 4.7.1
#
# adjust variable musl_topdir below as needed
#   - source is placed or downloaded in $musl_topdir/src
#   - the gcc wrapper is built in $musl_topdir/bin
#   - the musl libraries are built in $musl_topdir/lib
#   - the musl include files and linux headers are installed 
#     in $musl_topdir/include
#
# Note: unzip from info-zip is needed to extract the linux headers
# (or any other unzip capable of extracting symbolic links - ie. 
# not busybox unzip)

musl_topdir=/f/b/musl1114
musl=musl-1.1.14
musl_arch=i386

musl_src=$musl_topdir/src

# ----------------------------------------------------------------------
# exit at first error
set -e  

# create the build directory and source subdir, if needed
mkdir -p $musl_src

# ----------------------------------------------------------------------
# build musl libc
#
# get musl libc
cd $musl_src
[ ! -f $musl.tar.gz ] && \
  wget http://www.musl-libc.org/releases/$musl.tar.gz

tar xzvf  $musl.tar.gz
cd $musl_src/$musl
./configure --prefix=$musl_topdir --syslibdir=$musl_topdir/lib
make
make install

# ----------------------------------------------------------------------
# add linux headers
#
# get linux kernel headers from sabotage linux
# as suggested by http://wiki.musl-libc.org/wiki/FAQ

cd $musl_src
[ ! -f master.zip ] && \
  wget https://github.com/sabotage-linux/kernel-headers/archive/master.zip
unzip master.zip
cd kernel-headers-master
make ARCH=$musl_arch prefix=$musl_topdir install

cd $musl_src


