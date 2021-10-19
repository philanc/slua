
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
# The binaries provided here for convenience are built with a 
# 'musl-cross-make'-based  toolchains for x86_64, i586 and armhf
#


# note: to build with glibc (or uClibc), must add " -lpthread -lm " at 
# the end of the link lines for slua and sluac (see the sglua target)


# ----------------------------------------------------------------------


# This makefile uses the standard gcc compiler and the musl-gcc wrapper

CC= musl-gcc
AR= ar
LD= ld
STRIP= strip

# LUA is the src/ subdirectory where Lua sources can be found
LUA= lua-5.4.2

# LUAZEN is the src/ subdirectory where luazen sources can be found
LUAZEN=luazen-0.16

# SRLUA is the src/ subdirectory where srlua sources can be found
SRLUA=srlua-102

CFLAGS= -Os -Isrc/$(LUA)/src  -DLUA_USE_LINUX
LDFLAGS= 


# ----------------------------------------------------------------------
# luazen modular build (see luazen at https://github.com/philanc/luazen)
# the following constants can be defined to include
# the corresponding functions in the builtin luazen library:
#
#   BASE64     Base64 encode/decode
#   BASE58     Base58 encode/decode
#   BLZ        BriefLZ compress/uncompress
#   LZF        LZF compress/uncompress
#   LZMA       LZMA compress/uncompress
#   NORX       Norx AEAD encrypt/decrypt
#   CHACHA     Xchacha20 AEAD encrypt/decrypt
#   RC4        RC4 encrypt/decrypt
#   MD5        MD5 hash
#   BLAKE      Blake2b hash, Argon2i key derivation
#   SHA2       SHA2-512 hash
#   X25519     Ec25519 key exchange and ed25519 signature functions
#   MORUS      Morus AEAD encrypt/decrypt
#   ASCON      Ascon128a AEAD encrypt/decrypt
#
# the list of functions for the default build:

LZFUNCS= -DBASE64 -DLZMA -DBLAKE -DX25519 -DMORUS
       
# not included in the default build: 
#	-DBASE58 -DBLZ -DLZF 
#	-DNORX -DCHACHA -DRC4 -DMD5 -DSHA2 -DASCON 
#       

# ----------------------------------------------------------------------

smoketest:  slua
	$(RUN) ./slua  test/smoketest.lua

slua:  src/$(LUA)/src/*.c src/$(LUA)/src/*.h src/$(LUA)/*.c src/$(LUAZEN)/*.c src/*.c src/*.h
	$(CC) -c $(CFLAGS)  src/$(LUA)/src/*.c
	$(CC) -c $(CFLAGS) src/l5.c src/linenoise.c 
	$(CC) -c $(CFLAGS) $(LZFUNCS) src/$(LUAZEN)/*.c
	$(CC) -c $(CFLAGS)  -D_7ZIP_ST src/$(LUAZEN)/lzma/*.c
	$(AR) rcu slua.a *.o
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
	./srtest

clean:
	rm -f slua sluac sglua *.o *.a *.so
	rm -f srlua srglue srtest

# sglua is built with the default compiler and glibc
sglua:
	rm -f slua sluac sglua *.o *.a *.so
	gcc -c $(CFLAGS) src/$(LUA)/src/*.c
	gcc -c $(CFLAGS) src/l5.c src/linenoise.c
	gcc -c $(CFLAGS) $(LZFUNCS) src/$(LUAZEN)/*.c
	gcc -c $(CFLAGS)  -D_7ZIP_ST src/$(LUAZEN)/lzma/*.c
	ar rcu slua.a *.o
	gcc -o sglua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a  \
		-Wl,-E -lpthread -lm -ldl
	strip ./sglua
	./sglua  test/smoketest_g.lua
	rm -f *.o *.a	
	
test:  slua
	./slua test/test_luazen.lua
	
.PHONY: clean smoketest test sglua 

