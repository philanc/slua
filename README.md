
# slua

A static build of [Lua](http://www.lua.org/) 5.3 for Linux, with a few extension libraries.

Additional libraries are *pre-loaded*. They must be require()'d before use (see lua/src/linit.c)

### Preloaded libraries

- lfs (from LuaFileSystem)
- luazen (a small library with compression, encoding and encryption functions)
- minisock (a minimal socket library for tcp connections)
- linenoise (slua is built on Linux with linenoise to replace readline. A limited Lua binding to linenoise is also provided to allow usage of linenoise in applications)

Some documentation and references about these libraries is available in [doc/all_libraries.md](https://github.com/philanc/slua/tree/master/doc/all_libraries.md) and directory doc.

(Note: the old luazen and tweetnacl libraries have been replaced by the new luazen library. The last slua version with the old luazen and tweetnacl is v0.6)


### Static build

slua is linked completely statically. It uses no dynamic library, not even libc.  

It can be used anywhere, whatever the platform dynamic linker. The Linux x86 version is built with the Musl C library which allows a very compact executable. If built in a x86 (32-bit) environment, it can be run on any Linux system (x86 or x86_64)

It can be dropped and run from any directory, without interference or dynamic library incompatibilities.  

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

The default Lua paths ('package.path' and 'package.cpath') have been modified. They point only to the current directory, to minimize the risk of "catching" Lua files at the standard locations, intended to be used by a regular, installed Lua.

* `package.path:  "./?.lua;./?/init.lua" `
* `package.cpath: "./?.so" ` (unused by slua)

slua still respects the environment variables LUA_PATH and LUA_CPATH.

### Extension mechanism

It is possible to append Lua source code or Lua compiled bytecode to the slua executable. The appended code is run by slua before entering the Lua REPL and before processing the '-l' and '-e' options.

If entering the REPL is not wanted, the embedded code can just be ended with `os.exit()`.

The appended code can be written into the slua executable after compilation (see test/append.lua). The loading mechanism is in src/sluacode.h. 


### Installation

There is no installation. The slua executable is static. It can be placed and executed anywhere. 

To build slua on Linux, just adjust the 'Makefile' (eg. to compile with Musl libc, the CC variable must be set to the path of the 'musl-gcc' wrapper), run 'make' at the root of the source tree:
```
  # adjust the CC variable in the Makefile, then:
  make
```

Makefiles are also provided to build slua for armhf and Intel i586 (32-bit) architectures. They use cross-compilation environments based on gcc-5.3.0, built with 'musl-cross-make' by Rich Felker (see https://github.com/richfelker/musl-cross-make)

Binary versions of slua are provided here for convenience. These are standalone executables, statically compiled with musl-1.1.18, for x86_64, i586 and armhf.

### Dynamic linking version

A makefile is provided to build 'sglua', a dynamic version of slua, with the same additional libraries statically linked and preloaded.  'sglua' is built with Glibc. It has the same functions as slua (built-in linenoise line-editing, execution of appended lua code). It is intended to be built with the regular glibc (so the only runtime dependencies are libc, libm, libpthread and libdl). Additional C libraries can be loaded with 'require()'.

For 'sglua', the default Lua paths are slightly different:
* `package.path:  "lua;./?/init.lua" `
* `package.cpath: "./?.so" `

To build sglua:
```
    make -f Makefile.glibc
```

### Package versions

Lua 5.3.4 - http://www.lua.org/ftp/lua-5.3.4.tar.gz

LuaFileSystem 1.7.0 - https://github.com/keplerproject/luafilesystem

Luazen 0.11 - https://github.com/philanc/luazen

Linenoise - The full *readline* library is not used. It is replaced by the much smaller *linenoise* library.  The linenoise implementation included here has been extended to include a Lua binding. It is derived from Linenoise v1.0 - commit 027dbce - https://github.com/antirez/linenoise

Musl libc - slua has been built against musl-1.1.18

### Modifications of the vanilla Lua

src/lua/luaconf.h:
- modification of LUA_PATH_DEFAULT and LUA_CPATH_DEFAULT

src/lua/linit.c - not used. It is replaced with src/linit.c
- addition of the preloaded libraries

src/lua/lua.c - not used. It is replaced with src/slua.c
- replacement of readline with linenoise
- extension mechanism (see above)

### Pre-built binaries

The Linux binary versions of  slua have been built on a x86_64 (64-bit) platform with GCC 5.3.0 and the Musl C library (version 1.1.18)

The i586 and armhf versions have been cross-compiled with [musl-cross-make](https://github.com/richfelker/musl-cross-make), 
a toolchain setup designed by Rich Felker.


### Related projects

I am of course grateful to the PUC-Rio team for the wonderful [Lua](http://www.lua.org/).

Although their objectives are different, slua has been inspired by other projects:
- MurgaLua, by John Murga - http://www.murga-projects.com/murgaLua.html
- BonaLuna, by Christophe Delord - http://www.cdsoft.fr/bl/bonaluna.html
- Luabuild, by Steve Donovan, which is a more ambitious tool to build a static Lua with bundled libraries - https://github.com/stevedonovan/luabuild

Other related projects
- Luastatic -  https://github.com/ers35/luastatic
- Omnia (based on Luastatic) - https://github.com/tongson/omnia

### License and credits

Lua and all extension libraries are distributed under the terms of their respective licenses (MIT or equivalent). See LICENSE files in directories lua, and luafilesystem.

The luazen library includes some code from various authors (see src/luazen):
- linenoise by Salvatore Sanfilippo - https://github.com/antirez/linenoise
- lzf compression by Marc Alexander Lehmann - http://software.schmorp.de/pkg/liblzf.html
- brieflz compression by Joergen Ibsen - https://github.com/jibsen/brieflz
- norx encryption from the Caesar submission - http://norx.io
- morus encryption from the Caesar submission - http://www3.ntu.edu.sg/home/wuhj/research/caesar/caesar.html
- xchacha20/poly1305, blake2b, argon2i from Loup Vaillant's Monocypher - http://loup-vaillant.fr/projects/monocypher/
- x25519, ed25519 and sha512 from tweetnacl - http://nacl.cr.yp.to/ 
- base64 functions by Luiz Henrique de Figueiredo (public domain)
- base58 functions by Luke Dashjr (MIT)
- md5 by Cameron Rich (BSD)

Luazen and minisock are distributed under the MIT License (see file LICENSE)

Copyright (c) 2017  Phil Leblanc 



