/// slua
/// this is the regular Lua 'linit.c' file with a small addition
/// to preload additional libraries (see PRELOAD macro and
/// luaL_openlibs() at the end).
/// --------------------------------------------------------------------
/*
** $Id: linit.c,v 1.38 2015/01/05 13:48:33 roberto Exp $
** Initialization of libraries for lua.c and other clients
** See Copyright Notice in lua.h
*/


#define linit_c
#define LUA_LIB

/*
** If you embed Lua in your program and need to open the standard
** libraries, call luaL_openlibs in your program. If you need a
** different set of libraries, copy this file to your project and edit
** it to suit your needs.
**
** You can also *preload* libraries, so that a later 'require' can
** open the library, which is already linked to the application.
** For that, do the following code:
**
**  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
**  lua_pushcfunction(L, luaopen_modname);
**  lua_setfield(L, -2, modname);
**  lua_pop(L, 1);  // remove _PRELOAD table
*/

#include "lprefix.h"

#include <stddef.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

/*
** these libs are loaded by lua.c and are readily available to any Lua
** program
*/
static const luaL_Reg loadedlibs[] = {
  {"_G", luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_COLIBNAME, luaopen_coroutine},
  {LUA_TABLIBNAME, luaopen_table},
  {LUA_IOLIBNAME, luaopen_io},
  {LUA_OSLIBNAME, luaopen_os},
  {LUA_STRLIBNAME, luaopen_string},
  {LUA_MATHLIBNAME, luaopen_math},
  {LUA_UTF8LIBNAME, luaopen_utf8},
  {LUA_DBLIBNAME, luaopen_debug},
#if defined(LUA_COMPAT_BITLIB)
  {LUA_BITLIBNAME, luaopen_bit32},
#endif
  {NULL, NULL}
};

// PRELOAD: preload a library (see luaL_openlibs below)
#define PRELOAD(libname)  \
	int luaopen_##libname (lua_State *L); \
	lua_pushcfunction(L, luaopen_##libname);	\
    lua_setfield(L, -2, #libname);	

// PRELOAD2 is used for special cases, eg. for mime.core:
// PRELOAD2(mime.core, mime_core)
#define PRELOAD2(libname, libfuncname)  \
	int luaopen_##libfuncname (lua_State *L); \
	lua_pushcfunction(L, luaopen_##libfuncname);	\
    lua_setfield(L, -2, #libname);	


LUALIB_API void luaL_openlibs (lua_State *L) {
  const luaL_Reg *lib;
  /* "require" functions from 'loadedlibs' and set results to global table */
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);  /* remove lib */
  }
  ///-------------------------------------------------------
  ///slua 151018 - add preloaded libraries
  luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");

  PRELOAD(linenoise)
  PRELOAD(lfs)
  PRELOAD(lpeg)
  PRELOAD(mtcp)
  //~ PRELOAD2(socket.core, socket_core)
  //~ PRELOAD2(mime.core, mime_core)
  PRELOAD(luazen)
  PRELOAD(tweetnacl)
  PRELOAD(termbox)
  PRELOAD(luaproc)

  lua_pop(L, 1);  /* remove _PRELOAD table */
  ///-------------------------------------------------------
}

