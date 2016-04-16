/// slua embedded code loader module
///
/// The content of the string 'slua_embedded_buffer' is loaded as Lua
/// code and executed by slua before the regular REPL.
/// The default code provided is intended to look if some Lua code
/// has been appended to the slua executable file. If so, the appended
/// Lua code is loaded and executed in turn before entering the REPL
/// (see Lua code in 'slua_embedded_buffer' below).
/// A (unique) marker is added at the beginning and the end of 
/// 'slua_embedded_buffer' to allow the replacement of the content
/// of the buffer without recompiling slua.
///
/// The embedded loader Lua code is executed only if the first
/// 8 bytes after the "++slua++ marker in 'slua_embedded_buffer'
/// are different from 0x20 (space) - see slua.c.
/// If the embedded code loader overhead is too high, it can be
/// deactivated without recompiling by replacing in the slua executable
/// the first 8 bytes after the ++slua++" marker by 8 spaces.
/// That is, in the code below:
///   replace "++slua++-- slua " with "++slua++        "
///
/// Some extra space is available in 'slua_embedded_buffer' to allow
/// patching slua with a different implementation of the loader (eg. 
/// with compression or encryption) or even with some arbitrary code
/// without recompiling.
///
/// beware of double quotes within slua_embedded_buffer - use 
/// single quotes to delimit Lua strings!
///
/// Test appending Lua code to slua: append first the append marker
/// '--slua appended code\n', then append the Lua code:
///   echo "--slua appended code" >> slua
///   echo "print('Hello slua')" >> slua
///   ./slua  <-- will display 'Hello slua' before the Lua banner.

char *slua_embedded_buffer = 
	"++slua++" // start of embedded code marker - must be 8 bytes
	//~ "print[["  // uncomment this line and ']]' below to display the code
	"-- slua embedded loader                                    \n"
	"local asep = '%-%-slua appended code\\r?\\n'               \n"
	"local f = assert(io.open('/proc/self/exe', 'rb'))          \n"
	"local s = f:read('*a')                                     \n"
	"f:close()                                                  \n"
	"local i,j = s:find(asep, 1)                                \n"
	"if i then                                                  \n"
	"  local ac = s:sub(j+1);                                   \n"
	"  local f, msg = load(ac)                                  \n"
	"  if f then f()                                            \n"
	"  else                                                     \n"
	"    print('slua: cannot load appended code'                \n"
	"         ..'(maybe a syntax error)')                       \n"
	"  end                                                      \n"
	"end                                                        \n"
	//~ "]]"  // uncomment this to display the code
	"                                                           \n" 
	"                                                           \n" 
	"                                                           \n" 
	"                                                           \n" 
	"                                                           \n" 
	"                                                           \n" 
	"\0"        // ensure the embedded Lua code will be null terminated
	"++slua++"; // same marker than at beginning of buffer (8 bytes)
	
//~ #include <stdio.h>
//~ void main() {printf("size: %d\n", sizeof(slua_embedded_buffer));}