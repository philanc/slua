/// luaproc_preload.h
/// slua - this file is intended to be included in luaproc.c,
///        at the end of luaproc_openlualibs()
///
// PRELOAD: preload a library (see luaL_openlibs below)
#define PRELOAD(libname)  \
	int luaopen_##libname (lua_State *L); \
	luaproc_reglualib( L, #libname, luaopen_##libname );
///
#if !defined(SLUA_DYNLINK)
PRELOAD(lfs)
//~ PRELOAD(lpeg)
PRELOAD(minisock)
PRELOAD(luatweetnacl)
PRELOAD(luazen)
#endif
///
/// end luaproc_preload.h