
# slua

A static build of Lua 5.3 for Linux, with a few extension libraries.

Additional libraries are *pre-loaded*. They must be require()'d before use (see lua/src/linit.c)

slua preloaded libraries:
- lfs (from LuaFileSystem)
- lpeg (from LPeg 1.0.0)
- luazen (a small library with basic crypto and compression functions)
- nacl (the NaCl crypto library, from Dan Bernstein et al. This small Lua wrapper is based on the *tweet nacl* implementation which is also included)
- mtcp (a minimal socket library for tcp connections)
- luaproc (multi-threading library)
- linenoise (slua is built on Linux with linenoise to replace readline. A limited Lua binding to linenoise is also provided to allow usage of linenoise in applications)
- ltbox - a small library to write text-based user interfaces based on the termbox library

slua is linked completely statically. It uses no dynamic library, not even libc.  

It can be used anywhere, whatever the platform dynamic linker. The Linux x86 version is built with the Musl C library which allows a very compact executable. If built in a x86 environment, it can be run on any Linux system (x86 or x86_64)

It can be dropped and run from any directory, without interference or dynamic library incompatibilities.  Defaults paths ("package.path") are limited to the current directory to minimize the risk of "catching" Lua files at the standard locations, intended to be used by a regular, installed Lua.

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

### Installation

To build slua on Linux, just adjust the 'Makefile' (eg. to compile with Musl libc, the CC variable must be set to the path of the 'musl-gcc' wrapper), run 'make' at the root of the source tree. 

There is no installation. The slua binary can be placed and executed anywhere. 

The default Lua paths ('package.path' and 'package.cpath') have been modified. The default Lua path points only to the current directory, and the (unused) Lua cpath is empty.
* `package.path:  "./?.lua;./?/init.lua" `
* `package.cpath: "" `

slua still respects the environment variables LUA_PATH and LUA_CPATH.
		
Binary versions of slua are provided here for convenience.


### Package versions

Lua 5.3.2 - http://www.lua.org/ftp/lua-5.3.2.tar.gz

LuaFileSystem 1.6.3  - commit 6d039ff385 - https://github.com/keplerproject/luafilesystem
	
LPeg - http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.0.tar.gz

Luaproc 1.0.4 - commit 990ecf6 - https://github.com/askyrme/luaproc

ltbox - the termbox C library comes from https://github.com/nsf/termbox.

The full *readline* library is not used. It is replaced by the much smaller *linenoise* library.  The linenoise implementation included here has been extended to include a Lua binding. It is derived from Linenoise v1.0 - commit 027dbce - https://github.com/antirez/linenoise


### Pre-built binaries

The Linux x86 binary version of  slua has been built on a x86 (32-bit) platform with the Musl C library (version 1.1.10)


### Related projects

Although their objectives are different, slua has been inspired by other projects:
- MurgaLua, by John Murga - http://www.murga-projects.com/murgaLua.html
- BonaLuna, by Christophe Delord - http://www.cdsoft.fr/bl/bonaluna.html

### License

Lua and all extension libraries are distributed under the terms of their respective licenses (MIT or equivalent). See LICENSE files in directories lua, luafilesystem, and the file lpeg.html in directory lpeg.

Luazen, mtcp, the tweetnacl Lua wrapper are distributed under the MIT License. The "tweet" NaCl core implementation is public domain, by Daniel Bernstein et al.

The luazen library includes some code from various authors (see src/luazen):
- base64 functions by Luiz Henrique de Figueiredo (public domain)
- base58 functions by Luke Dashjr (MIT)
- md5, sha1 by Cameron Rich (BSD)

Copyright (c) 2015  Phil Leblanc 



