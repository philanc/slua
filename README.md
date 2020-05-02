
# slua

A static build of [Lua](http://www.lua.org/) 5.4 for Linux, with a few extension libraries.

Additional libraries are *pre-loaded*. They must be require()'d before use.

### Preloaded libraries

- [luazen](https://github.com/philanc/luazen), a small library with compression, encoding and cryptographic functions.
- [l5](https://github.com/philanc/l5), a minimal binding to low-level OS function for Linux (mostly basic Linux system calls, eg. open(2), ioctl(2), poll(2), socket I/O, etc.)
- [linenoise](src/linenoise.md) - slua is built on Linux with linenoise to replace readline. A limited Lua binding to linenoise is also provided to allow usage of linenoise in applications.

### Static build

slua is linked completely statically. It uses no dynamic library, not even libc.  

It can be used anywhere, whatever the platform dynamic linker. The Linux x86 version is built with the Musl C library which allows a very compact executable. If the i586 version is built, it can be run on any Linux system (x86 or x86_64)

It can be dropped and run from any directory, without interference with the local dynamic libraries and linker.  

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

The default Lua paths ('package.path' and 'package.cpath') have been modified. They point only to the current directory, to minimize the risk of "catching" Lua files at the standard locations, intended to be used by a regular, installed Lua.

* `package.path:  "./?.lua;./?/init.lua" `
* `package.cpath: "./?.so" ` (unused by slua)

slua still respects the environment variables LUA_PATH and LUA_CPATH.

### Extension mechanism

The possibility to append Lua source code or Lua compiled bytecode to the slua executable has been removed. 

### Installation

There is no installation. The slua executable is static. It can be placed and executed anywhere. 

To build slua on Linux, just adjust the 'Makefile' (eg. to compile with Musl libc, the CC variable must be set to the path of the 'musl-gcc' wrapper, or a complete cross-compile toolchain can be used), run 'make' at the root of the project tree:
```
  # adjust the GCC variable in the Makefile, then:
  make
```

The Makefile supports luazen modular build:  Constants can be defined at compile time to include the corresponding functions in the luazen library. Check the Makefile and src.luazen/luazen.c.

Default build includes only the following luazen functions: base64 encode/decode, LZMA compress/uncompress, blake2b hash, argon2i key derivation, morus AEAD encrypt/decrypt, ec25519 key exchange and ed25519 signature functions. Change variable LZFUNCS in the makefile to add or remove more functions.

The makefile also allows to build slua for armhf and Intel i586 (32-bit) architectures:
```
  # adjust the CROSS and GCC variables in the Makefile, then:
  make arm
  make i586
```

Binary versions of slua (and sluac, the Lua bytecode compiler) are provided here for convenience. These are standalone executables, statically compiled with musl-1.1.22, for x86_64, i586 and armhf. They are built with cross-compilation environments based on gcc-6.4.0, setup with 'musl-cross-make' by Rich Felker (see https://github.com/richfelker/musl-cross-make)

### Dynamic linking version ('sglua')

A makefile target is provided to build 'sglua', a dynamic version of slua, with the same additional libraries statically linked and preloaded.  'sglua' is built with Glibc. It has the same functions as slua (built-in linenoise line-editing, preloaded libraries). It is intended to be built with the regular glibc (so the only runtime dependencies are libc, libm, libpthread and libdl). Additional C libraries can be loaded with 'require()'.

To build sglua:
```
  make sglua
```


### Package versions

Lua 5.4.0-rc2 - http://www.lua.org/work/lua-5.4.0-rc2.tar.gz

Luazen 0.15 - https://github.com/philanc/luazen

L5 0.5 - https://github.com/philanc/l5

Linenoise - The full *readline* library is not used. It is replaced by the much smaller *linenoise* library.  The linenoise implementation included here has been simplified to keep only functions used by Lua and extended to include a Lua binding. It is derived from Linenoise v1.0 - commit 027dbce - https://github.com/antirez/linenoise

Musl libc - slua has been built against musl-1.1.22

### Modifications of the vanilla Lua

src/lua/luaconf.h:
- modification of LUA_PATH_DEFAULT and LUA_CPATH_DEFAULT

- lua.c is not used. It is replaced with src/slua.c. The only differences between lua.c and slua.c are the replacement of the readline interface with linenoise, and the addition of the preloaded libraries (look for "preloaded libraries", close to the end of the slua.c)

- replacement of readline with linenoise

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

Lua and all extension libraries are distributed under the terms of their respective licenses (MIT or equivalent). See LICENSE files in the ./src directory.

The luazen library includes some code from various authors (see src/luazen):
- linenoise by Salvatore Sanfilippo - https://github.com/antirez/linenoise
- lzf compression by Marc Alexander Lehmann - http://software.schmorp.de/pkg/liblzf.html
- brieflz compression by Joergen Ibsen - https://github.com/jibsen/brieflz
- lzma compression by Igor Pavlov - https://www.7-zip.org/sdk.html
- norx encryption from the Caesar submission - http://norx.io
- morus encryption from the Caesar submission - http://www3.ntu.edu.sg/home/wuhj/research/caesar/caesar.html
- ascon encryption from the Caesar submission - https://ascon.iaik.tugraz.at/
- xchacha20/poly1305, blake2b, argon2i from Loup Vaillant's Monocypher - http://loup-vaillant.fr/projects/monocypher/
- x25519, ed25519 and sha512 from tweetnacl - http://nacl.cr.yp.to/ 
- base64 functions by Luiz Henrique de Figueiredo (public domain)
- base58 functions by Luke Dashjr (MIT)
- md5 by Cameron Rich (BSD)

Luazen and minisock are distributed under the MIT License (see file LICENSE)

Copyright (c) 2017  Phil Leblanc 



