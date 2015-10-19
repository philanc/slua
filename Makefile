
CC= /mu/bin/musl-gcc
AR= ar
CFLAGS= -Os -Isrc/lua/src -DLUA_USE_POSIX -DLUA_USE_STRTODHEX \
         -DLUA_USE_AFORMAT -DLUA_USE_LONGLONG
LDFLAGS= 


# list of additional libraries (lua and slua are not included here)
SLUALIBS= lfs.a lpeg.a luazen.a tweetnacl.a termbox.a luanet.a luasocket.a



SLUA_O=      slua.o linit.o linenoise.o
LUA_O=       \
	lapi.o lcode.o ldebug.o lgc.o lmem.o loslib.o lstrlib.o lundump.o  \
	lauxlib.o lcorolib.o ldo.o liolib.o loadlib.o lparser.o ltable.o   \
	lutf8lib.o lbaselib.o lctype.o ldump.o llex.o lobject.o lstate.o   \
	ltablib.o lvm.o lbitlib.o ldblib.o lfunc.o lmathlib.o lopcodes.o   \
	lstring.o ltm.o lzio.o
LFS_O=       lfs.o
LPEG_O=      lpcap.o lpcode.o lpprint.o lptree.o lpvm.o
LUAZEN_O=    hmac.o luazen.o lzf_c.o lzf_d.o md5.o rc4.o sha1.o
TWEETNACL_O= luatweetnacl.o randombytes.o tweetnacl.o
TERMBOX_O=   lua-termbox.o termbox.o utf8.o
LUANET_O=    luanet.o
LUASOCKET_O= \
	luasocket.o timeout.o buffer.o io.o auxiliar.o compat.o \
	options.o inet.o except.o select.o tcp.o udp.o usocket.o mime.o

smoketest:  slua
	./slua  test/t.lua

slua:  slua.a lua.a $(SLUALIBS)
	$(CC) -static -o slua $(LDFLAGS) slua.a $(SLUALIBS) lua.a
	strip slua

slua.a:  lua.a src/*.c src/*.h
	$(CC) -c $(CFLAGS) src/*.c
	$(AR) rcu slua.a $(SLUA_O)
	rm -f *.o

lua.a:  src/lua/src/*.c src/lua/src/*.h
	$(CC) -c $(CFLAGS) src/lua/src/*.c
	$(AR) rcu lua.a $(LUA_O)
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

termbox.a:  lua.a src/termbox/*.c src/termbox/*.h src/termbox/*.inl
	$(CC) -c $(CFLAGS) src/termbox/*.c
	$(AR) rcu termbox.a $(TERMBOX_O)
	rm -f *.o

luanet.a:  lua.a src/luanet/*.c src/luanet/*.h
	$(CC) -c $(CFLAGS) src/luanet/*.c
	$(AR) rcu luanet.a $(LUANET_O)
	rm -f *.o

luasocket.a:  lua.a src/luasocket/*.c src/luasocket/*.h
	$(CC) -c $(CFLAGS) -DLUASOCKET_API="" src/luasocket/*.c
	$(AR) rcu luasocket.a $(LUASOCKET_O)
	rm -f *.o

clean:
	rm -f slua *.o *.a 

setbin:
	md5sum slua >slua.md5	
	cp slua slua.md5 bin/
	
.PHONY: clean setbin smoketest

