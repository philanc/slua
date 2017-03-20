
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
# The minisock library requires functions that cannot be linked 
# statically (getaddrinfo, gethostbyaddr, gesthostbyname). 
# In addition, the executable would be _much_ larger with Glibc,
# eg.  988KB with glibc vs 326KB with musl libc.
# 
# note: to build with glibc or uClibc, must add " -lpthread -lm " at 
# the end of the link lines for slua and sluac.
#
# Compile options (CFLAGS):
#
#    -DNOLEGACY  - do not include the md5 and rc4 legacy functions
#    -DNOARGON   - do not include the (somewhat large) argon2i
#                  password derivation function
#
# ----------------------------------------------------------------------

CC= /opt/musl-1.1.14/bin/musl-gcc
AR= ar
CFLAGS= -Os -Isrc/lua/ \
		-DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
        -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG \
		-DNOLEGACY
##	-DNOARGON -DNOLEGACY
	
LDFLAGS= 


# list of additional libraries 
# (lua, linenoise and slua are not included here)
SLUALIBS= lfs.a lz.a minisock.a luaproc.a


SLUA_O=      slua.o linit.o sluacode.o
LUA_O=       \
	lapi.o lcode.o ldebug.o lgc.o lmem.o loslib.o lstrlib.o lundump.o  \
	lauxlib.o lcorolib.o ldo.o liolib.o loadlib.o lparser.o ltable.o   \
	lutf8lib.o lbaselib.o lctype.o ldump.o llex.o lobject.o lstate.o   \
	ltablib.o lvm.o lbitlib.o ldblib.o lfunc.o lmathlib.o lopcodes.o   \
	lstring.o ltm.o lzio.o
LINENOISE_O= linenoise.o 
LFS_O=       lfs.o
LZ_O=        lz.o lzf_c.o lzf_d.o md5.o rc4.o base58.o \
             norx.o mono.o randombytes.o
MINISOCK_O=  minisock.o
LUAPROC_O=   luaproc.o lpsched.o

smoketest:  slua
	./slua  test/smoketest.lua

slua:  slua.a lua.a linenoise.a $(SLUALIBS)
	$(CC) -static -o slua $(LDFLAGS) slua.a linenoise.a $(SLUALIBS) lua.a
	strip slua

slua.a:  lua.a linenoise.a src/slua.c src/linit.c src/sluacode.c 
	$(CC) -c $(CFLAGS) -Isrc/linenoise/ src/*.c
	$(AR) rcu slua.a $(SLUA_O)
	rm -f *.o

lua.a:  src/lua/*.c src/lua/*.h
	$(CC) -c $(CFLAGS) src/lua/*.c
	$(AR) rcu lua.a $(LUA_O)
	# build also the lua compiler before removing the .o files
	$(CC) -static -o sluac luac.o lua.a
	
	rm -f *.o

linenoise.a:  lua.a src/linenoise/*.c src/linenoise/*.h
	$(CC) -c $(CFLAGS) src/linenoise/*.c
	$(AR) rcu linenoise.a $(LINENOISE_O)
	rm -f *.o

lfs.a:  lua.a src/lfs/*.c src/lfs/*.h
	$(CC) -c $(CFLAGS) src/lfs/*.c
	$(AR) rcu lfs.a $(LFS_O)
	rm -f *.o

lz.a:  lua.a src/lz/*.c src/lz/*.h
	$(CC) -c $(CFLAGS) src/lz/*.c
	$(AR) rcu lz.a $(LZ_O)
	rm -f *.o

minisock.a:  lua.a src/minisock/*.c
	$(CC) -c $(CFLAGS) src/minisock/*.c
	$(AR) rcu minisock.a $(MINISOCK_O)
	rm -f *.o

luaproc.a:  lua.a src/luaproc/*.c src/luaproc/*.h
	$(CC) -c $(CFLAGS) src/luaproc/*.c
	$(AR) rcu luaproc.a $(LUAPROC_O)
	rm -f *.o

clean:
	rm -f slua sluac sglua *.o *.a *.so

setbin:
	md5sum slua >bin/slua.md5	
	cp slua bin/
	
testlz:
	( cd test ; ../slua test_lz.lua )
	
.PHONY: clean setbin smoketest testlz

