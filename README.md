
# slua

A static build of Lua 5.3, with a few extension libraries. 

Additional libraries are *pre-loaded*. They must be require()'d before use (see lua/src/linit.c)

slua preloaded libraries:
- lfs (from LuaFileSystem)
- lpeg
- socket.core and mime.core (from LuaSocket)

slua is linked completely statically. It uses no dynamic library, not even libc.  

It can be used anywhere, whatever the platform dynamic linker. The Linux x86 version is built with the Musl C library which allows a very compact executable. If built in a x86 environment, it can be run on any Linux system (x86 or x86_64)

It can be dropped and run from any directory, without interference or dynamic library incompatibilities.  Defaults paths ("package.path") are limited to the current directory to minimize the risk of "catching" Lua files at the standard locations, intended to be used by a regular, installed Lua.

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

### Installation

To build slua on Linux, just adjust, then execute the build_slua.sh script at the root of the source tree. 

There is no installation. The slua binary can be placed and executed anywhere. 

The default Lua paths ('package.path' and 'package.cpath') have been modified. The default Lua path points only to the current directory, and the (unused) Lua cpath is empty.
* `package.path:  "./?.lua;./?/init.lua" `
* `package.cpath: "" `

slua still respects the environment variables LUA_PATH and LUA_CPATH.
		
Binary versions of slua are provided here for convenience.


### Package versions

Lua 5.3.1 - http://www.lua.org/ftp/lua-5.3.1.tar.gz

LuaSocket 3.0-rc1 - commit d1ec29be7f - https://github.com/diegonehab/luasocket

LuaFileSystem 1.6.3  - commit 6d039ff385 - https://github.com/keplerproject/luafilesystem
	
LPeg - http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.0.tar.gz

On Linux, the full 'readline' library is not used. It is replaced by the much smaller 'linenoise' library.

Linenoise fits in one source file which has been placed in the Lua source directory (lua/src).

### Pre-built binaries

The Linux binary version of  slua has been built on a x86 (32-bit) platform with the Musl C library (version 1.1.10)

The Windows32 version has benn build with MinGW.

### License

Lua and all extension libraries are distributed under the terms of their respective licenses (MIT or equivalent). See LICENSE files in directories lua, luafilesystem, luasocket, and the file lpeg.html in directory lpeg.

Copyright (c) 2015  Phil Leblanc 



