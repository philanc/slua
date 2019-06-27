
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

# if GCC is the musl wrapper, CROSS must be empty; else GCC=gcc
GCC= /opt/musl/bin/musl-gcc
CROSS=

CC= $(CROSS)$(GCC)
AR= $(CROSS)ar
LD= $(CROSS)ld
STRIP= $(CROSS)strip

# is used to run the test (empty for x86, or e.g. qemu-arm for arm)
RUN=

LUA= lua-5.3.5

CFLAGS= -Os -Isrc/$(LUA)/ \
	-DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
        -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG \


LDFLAGS= 


# ----------------------------------------------------------------------
# luazen modular build: 
# the following constants can be defined to include
# the corresponding functions in the luazen library:
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
       
# not included by default: 
#	-DBASE58 -DBLZ -DLZF 
#	-DNORX -DCHACHA -DRC4 -DMD5 -DSHA2 -DASCON 
#       
# ----------------------------------------------------------------------

smoketest:  slua
	$(RUN) ./slua  test/smoketest.lua

slua:  src/$(LUA)/*.c src/$(LUA)/*.h  src/luazen/*.c src/*.c src/*.h
	#~ $(CC) -c $(CFLAGS) src/$(LUA)/*.c
	$(CC) -c $(CFLAGS) -DMAKE_LIB  src/*.c
	$(CC) -c $(CFLAGS) $(LZFUNCS) src/luazen/*.c
	$(AR) rcu slua.a *.o
	$(CC) -static -o slua $(LDFLAGS) slua.o slua.a
	$(STRIP) slua
	rm -f *.o

sluac:
	$(CC) -static -o sluac -DMAKE_LUAC $(CFLAGS) $(LDFLAGS) src/one.c
	$(STRIP) sluac

clean:
	rm -f slua sluac sglua *.o *.a *.so

i586:
	make clean
	make smoketest sluac \
		GCC=gcc CROSS=/opt/cross/bin/i586-linux-musl-
	mv slua bin/slua-i586
	mv sluac bin/sluac-i586

arm:
	make clean 
	make smoketest sluac \
		RUN=qemu-arm \
		GCC=gcc CROSS=/opt/cross/bin/arm-linux-musleabihf-
	mv slua bin/slua-armhf
	mv sluac bin/sluac-armhf
	
sglua:
	rm -f slua sluac sglua *.o *.a *.so
	gcc -c $(CFLAGS) -DLUA_USE_DLOPEN -DMAKE_LIB  src/*.c
	gcc -c $(CFLAGS) $(LZFUNCS) src/luazen/*.c
	ar rcu slua.a *.o
	gcc -o sglua $(LDFLAGS) slua.o slua.a  -Wl,-E -lpthread -lm -ldl
	strip ./sglua
	$(RUN) ./sglua  test/smoketest_g.lua
	rm -f *.o *.a	
	
allbin: 
	make i586
	make arm
	make clean
	make smoketest sluac
	cp slua bin/slua
	cp sluac bin/sluac

test:  slua
	$(RUN)./slua test/test_luazen.lua
	
.PHONY: clean smoketest test i586 arm sglua allbin

