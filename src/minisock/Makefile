
# ----------------------------------------------------------------------
# adjust the following to the location of your Lua install
#
#   Lua binary and include files are to be found repectively in 
#   $(LUADIR)/bin and $(LUADIR)/include

LUADIR ?= ../lua

# ----------------------------------------------------------------------

CC= gcc
AR= ar
#LUA ?= $(LUADIR)/bin/lua
LUA= lua

INCFLAGS= -I$(LUADIR)/include
CFLAGS= -Os -fPIC $(INCFLAGS) 
LDFLAGS= -fPIC

smoketest: minisock.so
	$(LUA) smoketest.lua

minisock.so:  minisock.c
	$(CC) -c $(CFLAGS) minisock.c
	$(CC) -shared $(LDFLAGS) -o minisock.so minisock.o

test:  minisock.so
	$(LUA) echoclient.lua quiet
	
clean:
	rm -f *.o *.a *.so

.PHONY: clean test smoketest

