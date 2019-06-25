
# Build a completely static 'slua' on Linux with the Musl C library 
# (with the 'musl-gcc' wrapper provided with Musl C)
#
# This build requires only
#   - the musl libc installed with the linux headers
#   - make, gcc and associated tools
#
# A script building the musl libc and its gcc wrapper is available
# in directory 'tools'. Check it before using it! :-)
#
# Building statically with Glibc:  TL;DR: Don't do it.  :-)
# The l5 library requires functions that cannot be linked 
# statically (getaddrinfo, gethostbyaddr, gesthostbyname). 
# In addition, the executable would be _much_ larger with Glibc,
# eg.  988KB with glibc vs 326KB with musl libc.
# 
# note: to build with glibc or uClibc, must add " -lpthread -lm " at 
# the end of the link lines for slua and sluac.
#
#
# ----------------------------------------------------------------------

CC= /opt/musl/bin/musl-gcc
AR= ar

LUA= lua-5.3.5

CFLAGS= -Os -Isrc/$(LUA)/ \
		-DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
        -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG \


LDFLAGS= 


			 
smoketest:  slua
	./slua  test/smoketest.lua

slua:  src/$(LUA)/*.c src/$(LUA)/*.h  src/luazen/*.c src/*.c src/*.h
	#~ $(CC) -c $(CFLAGS) src/$(LUA)/*.c
	$(CC) -c $(CFLAGS) -DMAKE_LIB  src/*.c
	$(CC) -c $(CFLAGS) src/luazen/*.c
	$(AR) rcu slua.a *.o
	$(CC) -static -o slua $(LDFLAGS) slua.o slua.a
	strip slua
	rm -f *.o

sluac:
	$(CC) -static -o sluac -DMAKE_LUAC $(CFLAGS) $(LDFLAGS) src/one.c
	strip sluac

clean:
	rm -f slua sluac sglua *.o *.a *.so

allbin:
	make -f Makefile.armhf  clean
	make -f Makefile.armhf smoketest sluac
	mv slua bin/slua-armhf
	mv sluac bin/sluac-armhf
	make -f Makefile.i586 clean
	make -f Makefile.i586 smoketest sluac
	mv slua bin/slua-i586
	mv sluac bin/sluac-i586
	make clean
	make smoketest sluac
	cp slua bin/slua
	cp sluac bin/sluac

test:  slua
	./slua test/test_luazen.lua
	
.PHONY: clean setbin smoketest test allbin

