#!/bin/sh

# slua - a static build of Lua 5.3 with some extension libraries
#		- built on Linux against the Musl C library 
#-----------------------------------------------------------------------
# To build with gcc and the Musl C library, 
# define the Musl gcc wrapper as CC
# CC=/path/to/musl/bin/musl-gcc

CC=/mu/bin/musl-gcc

if [ ! -f $CC ] ; then
	echo "Musl gcc wrapper ('musl-gcc') not found"
	exit 1
fi

# Building statically with Glibc:  TL;DR: Don't.  :-)
# The luasocket library requires functions that cannot be linked 
# statically (getaddrinfo, gethostbyaddr, gesthostbyname). 
# In addition the executable is much larger with Glibc 
# (936KB vs 294KB for Musl C and probably even less with uClibc).
# CC=gcc


#-----------------------------------------------------------------------
# exit on error
set -e

echo "building slua ..."
LUAINCL=lua/src
# don't use LUA_USE_LINUX (don't want readline, dynlib support)
DEFS="-DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
	  -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG"

# compile everything
$CC -static -o slua -Os -I$LUAINCL $DEFS -DLUASOCKET_API="" \
	lua/src/*.c	\
	luafilesystem/src/lfs.c \
	lpeg/*.c  \
	luasocket/src/{luasocket.c,timeout.c,buffer.c,io.c,auxiliar.c} \
	luasocket/src/{compat.c,options.c,inet.c,except.c,select.c} \
	luasocket/src/{tcp.c,udp.c,usocket.c,mime.c}


rm -f lua/src/*.o luafilesystem/src/*.o lpeg/*.o luasocket/src/*.o
strip slua
mv slua bin/

# smoke test
bin/slua -e' print "slua: done." '
exit

