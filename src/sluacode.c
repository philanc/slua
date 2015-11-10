/// slua embedded code module
	
char *slua_embedded_buffer = 
	"++slua++" // must be 8 bytes
	"                                                            " // 60bytes
	"                                                            " // 2 
	"                                                            " // 3
	"                                                            " // 4
	"                                                            " // 5
	"                                                            " // 6
	"                                                            " // 7
	"                                                            " // 8
	"                                                            " // 9
	"                                                            " // 10
	"                                                            " // 11
	"                                                            " // 12
	"                                                            " // 13
	"                                                            " // 14
	"                                                            " // 15
	"                                                            " // 16
	"                                                            " // 17
	"                                                            " // 18
	"                                                            " // 19
	"                                                            " // 20
	"\0"        // ensure the embedded Lua code will be null terminated
	"++slua++"; // same marker than at beginning of buffer (8 bytes)
	
//~ #include <stdio.h>
//~ void main() {printf("size: %d\n", sizeof(slua_embedded_buffer));}