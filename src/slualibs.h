
/// This should be included after 
///   	luaL_openlibs(L);  /* open standard libraries */
/// in the main program

/// slua: preloaded libraries
	luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
	/// lualinux
	int luaopen_lualinux(lua_State *L); 
	lua_pushcfunction(L, luaopen_lualinux);
	lua_setfield(L, -2, "lualinux");
	/// lsccore
	int luaopen_lsccore(lua_State *L); 
	lua_pushcfunction(L, luaopen_lsccore);
	lua_setfield(L, -2, "lsccore");
	/// luamonocypher
	int luaopen_luamonocypher(lua_State *L); 
	lua_pushcfunction(L, luaopen_luamonocypher);
	lua_setfield(L, -2, "luamonocypher");
	/// lualzma
	int luaopen_lualzma(lua_State *L); 
	lua_pushcfunction(L, luaopen_lualzma);
	lua_setfield(L, -2, "lualzma");
	/// linenoise
	int luaopen_linenoise(lua_State *L); 
	lua_pushcfunction(L, luaopen_linenoise);
	lua_setfield(L, -2, "linenoise");
	///
	/// remove _PRELOAD table
	lua_pop(L, 1);
  
  /// slua: end of preloaded libraries