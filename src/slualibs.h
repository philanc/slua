
/// This should be included after 
///   	luaL_openlibs(L);  /* open standard libraries */
/// in the main program

/// slua: preloaded libraries
	luaL_getsubtable(L, LUA_REGISTRYINDEX, "_PRELOAD");
	/// l5
	int luaopen_l5(lua_State *L); 
	lua_pushcfunction(L, luaopen_l5);
	lua_setfield(L, -2, "l5");
	/// luazen
	int luaopen_luazen(lua_State *L); 
	lua_pushcfunction(L, luaopen_luazen);
	lua_setfield(L, -2, "luazen");
	/// linenoise
	int luaopen_linenoise(lua_State *L); 
	lua_pushcfunction(L, luaopen_linenoise);
	lua_setfield(L, -2, "linenoise");
	///
	/// remove _PRELOAD table
	lua_pop(L, 1);
  
  /// slua: end of preloaded libraries