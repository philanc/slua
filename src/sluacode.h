/// slua appended code loader module
///
/// The mechanism is partially inspired by srlua, by 
/// Luiz Henrique de Figueiredo.
///
/// The content of 'slua_append_indicator' tells if Lua code has been 
/// appended to the slua executable.
/// if the 4 string chars at offset 20 are zero, there is no appended code
/// else "xxxx" is the appended code offset in the slua executable
/// and "yyyy" is the code length. xxxx and yyyy are little-endian encoded.
///
/// If code is appended, it is loaded and executed by slua before 
/// the regular REPL.
///
/// The embedded code can be Lua source code or bytecode.
///

#define MAX_APPEND_LEN (1024 * 1024)

const unsigned char * slua_append_indicator = 
	"+++appended code+++ \0\0\0\0\0\0\0\0 +++";
	

static void exiterr(char *msg1, char *msg2) {
	fprintf(stderr,"slua: %s %s\n", msg1, msg2);
	exit(1);
}

static int do_slua_appended_code(lua_State *L) {
	unsigned char *slua_appended;
	size_t r;
	int lstatus;
	// char *name = "/proc/self/exe"; 
	// use 'progname' already set here to argv[0]
	char *name = (char *) progname;
	size_t slua_append_offset = slua_append_indicator[20]
			| (slua_append_indicator[21] << 8)
			| (slua_append_indicator[22] << 16)
			| (slua_append_indicator[23] << 24);
	int slua_append_length = slua_append_indicator[24]
			| (slua_append_indicator[25] << 8)
			| (slua_append_indicator[26] << 16)
			| (slua_append_indicator[27] << 24);
	if (slua_append_offset == 0 ) {
		/// if the embedded code buffer is empty, just ignore it
		return LUA_OK;
	}
	if (slua_append_length > MAX_APPEND_LEN ) {
		exiterr("invalid code length", "");
	}
	slua_appended = malloc(slua_append_length);
	FILE *f=fopen(name,"rb");
	if (!f) exiterr("cannot open", name);
	r = fseek(f,slua_append_offset,SEEK_SET); 
	if (r != 0) exiterr("cannot seek", name);
	r = fread(slua_appended, 1, slua_append_length, f); 
	// fprintf(stderr,"slua: read %d  expected %d\n",
	//	r, slua_append_length);
	if (r != slua_append_length) exiterr("cannot read", name);
	fclose(f); 
	lstatus = dochunk(L, 
		luaL_loadbuffer(L, slua_appended, slua_append_length, ""));
	free(slua_appended);
	return lstatus;
}

