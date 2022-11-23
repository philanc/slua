
# slua build makefile

# To build musl libc-based executables on your current platform, 
# with the default gcc compiler, use instructions for 
# the _musl-gcc wrapper_ at https://www.musl-libc.org/how.html
# or simply install musl libc:  with a recent Debian (or Ubuntu, Mint, ...)
# do:
#	sudo apt install  musl  musl-dev  musl-tools
#
# To build a complete gcc-based cross-compile toolchain, the easiest
# solution is to use 'musl-cross-make' by Rich Felker at
# https://github.com/richfelker/musl-cross-make
#
# note: to build with glibc (or uClibc), must add " -lpthread -lm " at 
# the end of the link lines for slua and sluac (see the sglua target)


# ----------------------------------------------------------------------


# This makefile uses the standard gcc compiler and the musl-gcc wrapper

CC= musl-gcc
AR= ar
LD= ld
STRIP= strip

# Directories where the sources can be found
LUA= lua-5.4.3
LUAZEN= luazen-2.0
LUALINUX=lualinux-0.3
SRLUA=srlua-102

CFLAGS= -Os -Isrc/$(LUA)/src  -DLUA_USE_LINUX
LDFLAGS= 

B3DEFS= -DBLAKE3_NO_SSE2 -DBLAKE3_NO_SSE41 -DBLAKE3_NO_AVX2 -DBLAKE3_NO_AVX512

# ----------------------------------------------------------------------

default: smoketest sluac srlua

smoketest:  ./slua
	./slua  test/smoketest.lua

slua: 
	$(CC) -c $(CFLAGS)  src/$(LUA)/src/*.c
	$(CC) -c $(CFLAGS) src/lsccore.c src/linenoise.c 
	$(CC) -c $(CFLAGS) src/$(LUALINUX)/*.c
	$(CC) -c $(CFLAGS) src/$(LUAZEN)/*.c
	$(CC) -c $(CFLAGS)  -D_7ZIP_ST src/$(LUAZEN)/lzma/*.c
	$(CC) -c $(CFLAGS)  $(B3DEFS) src/$(LUAZEN)/blake3/*.c
	$(CC) -c $(CFLAGS)  src/$(LUAZEN)/mono/*.c
	$(AR) rc slua.a *.o
	$(CC) -static -o slua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a
	$(STRIP) slua
	rm -f *.o

sluac: slua
	$(CC) -static -o sluac $(CFLAGS) $(LDFLAGS) src/$(LUA)/luac.c slua.a
	$(STRIP) sluac

srlua: slua
	$(CC) -static -o srlua -Isrc/$(SRLUA) -Isrc $(CFLAGS) $(LDFLAGS) \
	   src/$(SRLUA)/srlua.c slua.a
	$(STRIP) srlua
	$(CC) -static -o srglue -Isrc/$(SRLUA) -Isrc $(CFLAGS) $(LDFLAGS) \
	   src/$(SRLUA)/srglue.c slua.a
	$(STRIP) srglue
	./srglue ./srlua src/$(SRLUA)/test.lua srtest
	chmod +x ./srtest 
	./srtest arg1 arg2 arg3 

clean:
	rm -f slua sluac sglua *.o *.a *.so
	rm -f srlua srglue srtest

# sglua is built with the default compiler and glibc
sglua:
	rm -f sglua *.o *.a *.so
	gcc -c $(CFLAGS) src/$(LUA)/src/*.c
	gcc -c $(CFLAGS) src/lsccore.c src/linenoise.c 
	gcc -c $(CFLAGS) src/$(LUALINUX)/*.c
	gcc -c $(CFLAGS) src/$(LUAZEN)/*.c
	gcc -c $(CFLAGS)  -D_7ZIP_ST src/$(LUAZEN)/lzma/*.c
	gcc -c $(CFLAGS)  $(B3DEFS) src/$(LUAZEN)/blake3/*.c
	gcc -c $(CFLAGS)  src/$(LUAZEN)/mono/*.c
	ar rc slua.a *.o
	gcc -o sglua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a  \
		-Wl,-E -lpthread -lm -ldl
	strip ./sglua
	./sglua  test/smoketest_g.lua
	rm -f *.o *.a	
	
test:  ./slua
	./slua test/test_luazen.lua

bin:  ./slua
	cp ./slua ./bin/slua
	
.PHONY: clean smoketest default sglua

