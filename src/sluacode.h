/// slua embedded code loader module
///
/// The content of 'embedded[]' is loaded as Lua
/// code and executed by slua before the regular REPL.
///
/// The embedded loader Lua code is executed only if the 4 bytes 
/// starting at embedded[4] are not (0, 0, 0, 0)
///
/// The embedded code can be Lua source code or bytecode.
///

#ifndef EMBSIZE
#define EMBSIZE 4096
#endif

unsigned char embedded[EMBSIZE] = {
	// first 4 bytes are EMBSIZE (as uint32, little endian)
	EMBSIZE & 0xff,	
	(EMBSIZE >> 8) & 0xff,
	(EMBSIZE >> 16) & 0xff,
	(EMBSIZE >> 24) & 0xff,
	// next 32 bytes are a marker (32 * '#') for binary patching
	35,35,35,35,35,35,35,35,35,35,35,35,35,35,35,35, // marker
	35,35,35,35,35,35,35,35,35,35,35,35,35,35,35,35, // marker
	// next 4 bytes are the size of embedded code as an uint32, 
	// little endian -- or (0,0,0,0) if there is no embedded code
	0, 0, 0, 0, 	
	0  // the embedded code (if any) starts here.
};

static int do_slua_embedded_code(lua_State *L) {
	size_t buflen = embedded[36]
		| (embedded[37] << 8)
		| (embedded[38] << 16)
		| (embedded[39] << 24);
	if (buflen != 0 ) {
		return dochunk(L, 
			luaL_loadbuffer(L, embedded+40, buflen, ""));
	}
	/// if the embedded code buffer is empty, just ignore it
	return LUA_OK;
}

