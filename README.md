![CI](https://github.com/philanc/slua/workflows/CI/badge.svg)

# slua

A static build of [Lua](http://www.lua.org/) 5.4 for Linux, with a few extension libraries.

For convenience, a slua binary is provided for x86_64.

### Preloaded libraries

Additional libraries are *pre-loaded*. They must be require()'d before use.

- [lualzma](https://github.com/philanc/lualzma), a small library with LZMA compression functions.
- [luamonocypher](https://github.com/philanc/luamonocypher), a binding to the Monocypher crypto library.
- [lualinux](https://github.com/philanc/lualinux), a minimal binding to common Linux/Posix functions. -- see a list of [lualinux available functions](https://github.com/philanc/lualinux#available-functions))
- [linenoise](src/linenoise.md) - slua is built on Linux with linenoise to replace readline. A limited Lua binding to linenoise is also provided to allow usage of linenoise in applications.


### Extension mechanism

[srlua](https://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/#srlua) by Luiz Henrique de Figueiredo (lhf@tecgraf.puc-rio.br) is included. As put by its author, this is a self-running Lua interpreter.  It is meant to be combined with a Lua program  into a single, stand-alone program that  will execute the given Lua program when it is run.

It has been slightly modified:

* `srlua` and its companion program `srglue` are statically built (do `make srlua`). They are used exactly as the original `srlua` and `srglue`. See for example the target `srlua` in the Makefile.

* The additional slua libraries are also built in `srlua`.


### Static build

slua is linked completely statically. It uses no dynamic library, not even libc.  So it can be used anywhere, whatever the platform dynamic linker and libraries versions. It is built with the Musl C library which allows a very compact executable. 

It can be dropped and run from any directory, without interference with the local dynamic libraries and linker.  

On the other end, obviously, slua cannot load dynamic C libraries. It is *not* intended to be a replacement for a full fledged Lua installation.

slua respects the environment variables LUA_PATH and LUA_CPATH.

### Installation

The `src` directory includes all the required sources, so building `slua` doesn't require any external dependencies.

There is no installation. The slua executable is static. It can be placed and executed anywhere. 

The default slua build procedure assumes that the C compiler is gcc and that musl libc is installed. It uses the `musl-gcc`  wrapper.

With a recent Debian (or Ubuntu, Mint, ...) musl libc can be installed with
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
 
### Dynamic linking version ('sglua')

A makefile target is provided to build 'sglua', a dynamic version of slua, with the same additional libraries statically linked and preloaded.  'sglua' is built with Glibc. It has the same functions as slua (built-in linenoise line-editing, preloaded libraries). It is intended to be built with the regular glibc (so the only runtime dependencies are the default libc, libm, libpthread and libdl). 

To build sglua:
```
  make sglua
```

### Pre-built binary

A binary version of slua is provided here for convenience. This is a standalone executable, statically compiled with musl-1.2.2 for x86_64.

### Package versions

lua-5.4.3 - http://www.lua.org/ftp/lua-5.4.2.tar.gz

lualzma-0.16 - https://github.com/philanc/lualzma

luamonocypher-0.3 - https://github.com/philanc/luamonocypher - based on Monocypher-3.1.2

lualinux-0.3 - https://github.com/philanc/lualinux

linenoise - The full *readline* library is not used. It is replaced by the much smaller *linenoise* library.  The linenoise implementation included here has been simplified to keep only functions used by the Lua REPL and extended to include a Lua binding. It is derived from Linenoise v1.0 - commit 027dbce - https://github.com/antirez/linenoise

### Modifications of the vanilla Lua

lua.c is not used. It is replaced with src/slua.c. The only differences between lua.c and slua.c are the replacement of the readline interface with linenoise, and the addition of the preloaded libraries (look for "preloaded libraries", close to the end of slua.c)

### License and credits

Lua and all extension libraries are distributed under the terms of their respective licenses (MIT or equivalent - see in the ./src directory).

I am of course grateful to the PUC-Rio team for the great [Lua](http://www.lua.org/).

The built-in libraries include some code from various authors:
- linenoise by Salvatore Sanfilippo - https://github.com/antirez/linenoise
- lzma compression by Igor Pavlov - https://www.7-zip.org/sdk.html
- xchacha20/poly1305, blake2b, argon2i, x25519 DH key exchange and ed25519 signature from Loup Vaillant's Monocypher -  https://monocypher.org/
- srlua by Luiz Henrique de Figueiredo (public domain)

slua itslef and the library bindings are distributed under the MIT License (see file LICENSE)

Copyright (c) 2021  Phil Leblanc 



