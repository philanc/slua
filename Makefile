
# slua build makefile

# To build musl libc-based executables on your current platform, 
# with the default gcc compiler, use instructions for 
# the _musl-gcc wrapper_ at https://www.musl-libc.org/how.html
#
# To build a complete gcc-based cross-compile toolchain, the easiest
# solution is to use 'musl-cross-make' by Rich Felker at
# https://github.com/richfelker/musl-cross-make
#
# The binaries provided here are built with 'musl-cross-make'-based
# toolchains for x86_64, i586 and armhf
#


# note: to build with glibc (or uClibc), must add " -lpthread -lm " at 
# the end of the link lines for slua and sluac (see the sglua target)


# ----------------------------------------------------------------------

# the following variables contain the prefix for the toolchain tools
# built with 'musl-cross-make' (see above).
# they are used repectively in x64, i586, arm targets
#
CROSS_X64=/opt/cross/bin/x86_64-linux-musl-
CROSS_I586=/opt/cross/bin/i586-linux-musl-
CROSS_ARM=/opt/cross/bin/arm-linux-musleabihf-

# the following variables indicate how to invoke the slua executable 
# for tests. They assume that make is run on a x86_64 platform, so
# x64 an i586 can be run natively, and arm is run through Qemu
#
RUN_X64=
RUN_I586=
RUN_ARM=qemu-arm

# if the default compiler is used with the musl-gcc wrapper,
# CROSS and RUN must be empty, and GCC is the path to the wrapper script
# else GCC=gcc
#
GCC= /opt/musl/bin/musl-gcc
CROSS=
RUN=

CC= $(CROSS)$(GCC)
AR= $(CROSS)ar
LD= $(CROSS)ld
STRIP= $(CROSS)strip

# LUA is the src/ subdirectory where Lua sources can be found
#LUA= lua-5.3.5
LUA= lua-5.4.2

# LUA is the src/ subdirectory where luazen sources can be found
LUAZEN=luazen-0.16

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
	$(CC) -c $(CFLAGS) src/$(LUA)/src/*.c
	$(CC) -c $(CFLAGS) src/vl5core.c src/l5.c src/linenoise.c 
	$(CC) -c $(CFLAGS) $(LZFUNCS) src/$(LUAZEN)/*.c
	$(CC) -c $(CFLAGS)  -D_7ZIP_ST src/$(LUAZEN)/lzma/*.c
	$(AR) rcu slua.a *.o
	$(CC) -static -o slua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a
	$(STRIP) slua
	rm -f *.o

sluac: slua
	$(CC) -static -o sluac $(CFLAGS) $(LDFLAGS) src/$(LUA)/luac.c slua.a
	$(STRIP) sluac

sluarun: slua
	$(CC) -static -o sluarun $(CFLAGS) $(LDFLAGS) src/srlua-102/srlua.c slua.a
	$(STRIP) sluarun
	$(CC) -static -o srglue $(CFLAGS) $(LDFLAGS) src/srlua-102/srglue.c slua.a
	$(STRIP) sluarun

clean:
	rm -f slua sluac sglua *.o *.a *.so
	rm -f sluarun srglue

x64:
	make clean
	make smoketest sluac \
		GCC=gcc CROSS=$(CROSS_X64) RUN=$(RUN_X64)
	mv slua bin/slua-x64
	mv sluac bin/sluac-x64

i586:
	make clean
	make smoketest sluac \
		GCC=gcc CROSS=$(CROSS_I586) RUN=$(RUN_I586)
	mv slua bin/slua-i586
	mv sluac bin/sluac-i586

arm:
	make clean 
	make smoketest sluac \
		GCC=gcc CROSS=$(CROSS_ARM) RUN=$(RUN_ARM)
	mv slua bin/slua-armhf
	mv sluac bin/sluac-armhf

sglua:
	rm -f slua sluac sglua *.o *.a *.so
	gcc -c $(CFLAGS) src/$(LUA)/src/*.c
	gcc -c $(CFLAGS) src/l5.c src/linenoise.c
	gcc -c $(CFLAGS) $(LZFUNCS) src/luazen/*.c
	$(CC) -c $(CFLAGS)  -D_7ZIP_ST src/luazen/lzma/*.c
	ar rcu slua.a *.o
	gcc -o sglua $(CFLAGS) $(LDFLAGS) src/slua.c slua.a  \
		-Wl,-E -lpthread -lm -ldl
	strip ./sglua
	$(RUN) ./sglua  test/smoketest_g.lua
	rm -f *.o *.a	
	
allbin: x64 i586 arm clean

test:  slua
	$(RUN)./slua test/test_luazen.lua
	
.PHONY: clean smoketest test x64 i586 arm sglua allbin

