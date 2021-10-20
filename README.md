
# slua

A static build of [Lua](http://www.lua.org/) 5.4 for Linux, with a few extension libraries.

For convenience, binaries are provided for x86_64, i586 and armhf.

A static build with Lua 5.3.5 is also available. Check out branch "5.3.5".

### Preloaded libraries

Additional libraries are *pre-loaded*. They must be require()'d before use.

- [luazen](https://github.com/philanc/luazen), a small library with compression, encoding and cryptographic functions.
- [l5](https://github.com/philanc/l5), a minimal binding to low-level OS function for Linux (mostly basic Linux system calls, eg. open(2), ioctl(2), poll(2), socket I/O, etc. -- see a list of [l5 available functions](https://github.com/philanc/l5#available-functions))
- [linenoise](src/linenoise.md) - slua is built on Linux with linenoise to replace readline. A limited Lua binding to linenoise is also provided to allow usage of linenoise in applications.


### Extension mechanism

[srlua](https://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/#srlua) by Luiz Henrique de Figueiredo (lhf@tecgraf.puc-rio.br) is included. As put by its author, this is a self-running Lua interpreter.  It is meant to be combined with
a Lua program  into a single, stand-alone program that  will execute the
given Lua program when it is run.

It has been slightly modified:

* `srlua` and its companion program `srglue` are statically built (do `make srlua`). They are used exactly as the original `srlua` and `srglue`. See for example the target `srlua` in the Makefile.

* The additional slua libraries are also built in `srlua`.


### Static build

slua is linked completely statically. It uses no dynamic library, not even libc.  So it can be used anywhere, whatever the platform dynamic linker and libraries versions. It is built with the Musl C library which allows a very compact executable. If the i586 version is built, it can be run on any Linux system (x86 or x86_64)

It can be dropped and run from any directory, without interference with the local dynamic libraries and linker.  

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

The default Lua paths ('package.path' and 'package.cpath') have been modified. They point only to the current directory, to minimize the risk of "catching" Lua files at the standard locations, intended to be used by a regular, installed Lua.

* `package.path:  "./?.lua;./?/init.lua" `
* `package.cpath: "./?.so" ` (unused by slua)

slua still respects the environment variables LUA_PATH and LUA_CPATH.

### Installation

The `src` directory includes all the required sources, so building `slua` doesn't require any external dependencies.

There is no installation. The slua executable is static. It can be placed and executed anywhere. 

The default slua build procedure assumes that the C compiler is gcc and that musl libc is installed. It uses the `musl-gcc`  wrapper.

With recent Debian (or Ubuntu, Mint, ...) musl libc can be installed with
```
 sudo apt install  musl  musl-dev musl-tools
 ```
 
 In that case, the makefile can be used as-is.
 
Other distributions may include musl packages. Alternatively musl libc can easily be built  form source. See instructions at https://www.musl-libc.org/

If the `musl-gcc` wrapper is not accessible in `$PATH`, or if another toolchain is used, the makefile must be adjusted accordingly.

Then run 'make' at the root of the project tree:
```
  make
```

The default target buils the `slua` executable, the associated `sluac` Lua compiler, and `srlua` and its companion `srglue` (See "extension mechanism" above). All these programs are statically linked.
 
The Makefile supports luazen modular build:  Constants can be defined at compile time to include the corresponding functions in the luazen library. Check the Makefile src.luazen/luazen.c, and https://github.com/philanc/luazen.

The default build includes only the following luazen functions: base64 encode/decode, LZMA compress/uncompress, blake2b hash, argon2i key derivation, morus AEAD encrypt/decrypt, ec25519 key exchange and ed25519 signature functions. Change variable LZFUNCS in the makefile to add or remove more functions.

### Dynamic linking version ('sglua')

A makefile target is provided to build 'sglua', a dynamic version of slua, with the same additional libraries statically linked and preloaded.  'sglua' is built with Glibc. It has the same functions as slua (built-in linenoise line-editing, preloaded libraries). It is intended to be built with the regular glibc (so the only runtime dependencies are the default libc, libm, libpthread and libdl). 

To build sglua:
```
  make sglua
```

### Binary versions

Binary versions of slua (and sluac, the Lua bytecode compiler) are provided here for convenience. These are standalone executables, statically compiled with musl-1.1.22, for x86_64, i586 and armhf. They are built with cross-compilation environments based on gcc-6.4.0, built with 'musl-cross-make' by Rich Felker (the musl libc author - see https://github.com/richfelker/musl-cross-make)

### Package versions

Lua 5.4.2 (2020-12-23) - http://www.lua.org/ftp/lua-5.4.2.tar.gz

Luazen 0.16 - https://github.com/philanc/luazen

L5 0.5 - https://github.com/philanc/l5

Linenoise - The full *readline* library is not used. It is replaced by the much smaller *linenoise* library.  The linenoise implementation included here has been simplified to keep only functions used by Lua and extended to include a Lua binding. It is derived from Linenoise v1.0 - commit 027dbce - https://github.com/antirez/linenoise

### Modifications of the vanilla Lua

src/lua/luaconf.h:
- modification of LUA_PATH_DEFAULT and LUA_CPATH_DEFAULT

- lua.c is not used. It is replaced with src/slua.c. The only differences between lua.c and slua.c are the replacement of the readline interface with linenoise, and the addition of the preloaded libraries (look for "preloaded libraries", close to the end of the slua.c)

- replacement of readline with linenoise

### Pre-built binaries

The Linux  x64_86, i586 and armhf binary versions of  slua have been built with the Musl C library (version 1.1.22).

They have been cross-compiled with [musl-cross-make](https://github.com/richfelker/musl-cross-make), 
a toolchain setup designed by Rich Felker (the author and maintainer of the Musl libc).


### Related projects

I am of course grateful to the PUC-Rio team for the wonderful [Lua](http://www.lua.org/).

Although their objectives are different, slua has been inspired by other projects:
- MurgaLua, by John Murga - http://www.murga-projects.com/murgaLua.html
- BonaLuna, by Christophe Delord - http://www.cdsoft.fr/bl/bonaluna.html
- Luabuild, by Steve Donovan, which is a more ambitious tool to build a static Lua with bundled libraries - https://github.com/stevedonovan/luabuild
- Luastatic -  https://github.com/ers35/luastatic

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
- srlua by Luiz Henrique de Figueiredo (public domain)

slua, luazen, l5 and the linenoise binding are distributed under the MIT License (see file LICENSE)

Copyright (c) 2021  Phil Leblanc 



