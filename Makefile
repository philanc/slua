
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
LUALZMA= lualzma-0.16
LUALINUX=lualinux-0.3
LUAMONO=luamonocypher-0.3
SRLUA=srlua-102

CFLAGS= -Os -Isrc/$(LUA)/src  -DLUA_USE_LINUX
LDFLAGS= 

# ----------------------------------------------------------------------

default: smoketest sluac srlua

smoketest:  ./slua
	./slua  test/smoketest.lua

slua: 
	$(CC) -c $(CFLAGS)  src/$(LUA)/src/*.c
	$(CC) -c $(CFLAGS) src/vl5core.c src/linenoise.c 
	$(CC) -c $(CFLAGS) src/$(LUAMONO)/*.c
	$(CC) -c $(CFLAGS) src/$(LUALINUX)/*.c
	$(CC) -c $(CFLAGS) src/$(LUALZMA)/*.c
	$(CC) -c $(CFLAGS)  -D_7ZIP_ST src/$(LUALZMA)/lzma/*.c
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
	gcc -c $(CFLAGS) src/vl5core.c src/linenoise.c
	gcc -c $(CFLAGS) src/$(LUAMONO)/*.c
	gcc -c $(CFLAGS) src/$(LUALINUX)/*.c
	gcc -c $(CFLAGS) src/$(LUALZMA)/*.c
	gcc -c $(CFLAGS)  -D_7ZIP_ST src/$(LUALZMA)/lzma/*.c
	ar rc slua.a *.o
	gcc -o sglua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a  \
		-Wl,-E -lpthread -lm -ldl
	strip ./sglua
	./sglua  test/smoketest_g.lua
	rm -f *.o *.a	
	
test:  ./slua
	./slua test/test_lualzma.lua
	./slua test/test_luamonocypher.lua

bin:  ./slua
	cp ./slua ./bin/slua
	
.PHONY: clean smoketest default sglua

