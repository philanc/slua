
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
# ----------------------------------------------------------------------

CC= /f/b/musl1114/bin/musl-gcc
AR= ar
CFLAGS= -Os -Isrc/lua/ -DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
         -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG
LDFLAGS= 


# list of additional libraries 
# (lua, linenoise and slua are not included here)
SLUALIBS= lfs.a lpeg.a luazen.a tweetnacl.a minisock.a luaproc.a


SLUA_O=      slua.o linit.o sluacode.o
LUA_O=       \
	lapi.o lcode.o ldebug.o lgc.o lmem.o loslib.o lstrlib.o lundump.o  \
	lauxlib.o lcorolib.o ldo.o liolib.o loadlib.o lparser.o ltable.o   \
	lutf8lib.o lbaselib.o lctype.o ldump.o llex.o lobject.o lstate.o   \
	ltablib.o lvm.o lbitlib.o ldblib.o lfunc.o lmathlib.o lopcodes.o   \
	lstring.o ltm.o lzio.o
LINENOISE_O= linenoise.o 
LFS_O=       lfs.o
LPEG_O=      lpcap.o lpcode.o lpprint.o lptree.o lpvm.o
LUAZEN_O=    luazen.o lzf_c.o lzf_d.o md5.o rc4.o sha1.o base58.o rabbit.o
TWEETNACL_O= luatweetnacl.o randombytes.o tweetnacl.o
MINISOCK_O=      minisock.o
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

lpeg.a:  lua.a src/lpeg/*.c src/lpeg/*.h
	$(CC) -c $(CFLAGS) src/lpeg/*.c
	$(AR) rcu lpeg.a $(LPEG_O)
	rm -f *.o

luazen.a:  lua.a src/luazen/*.c src/luazen/*.h
	$(CC) -c $(CFLAGS) src/luazen/*.c
	$(AR) rcu luazen.a $(LUAZEN_O)
	rm -f *.o

tweetnacl.a:  lua.a src/tweetnacl/*.c src/tweetnacl/*.h
	$(CC) -c $(CFLAGS) src/tweetnacl/*.c
	$(AR) rcu tweetnacl.a $(TWEETNACL_O)
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
	rm -f slua sluac sdlua *.o *.a *.so

setbin:
	md5sum slua >bin/slua.md5	
	cp slua bin/
	
.PHONY: clean setbin smoketest

