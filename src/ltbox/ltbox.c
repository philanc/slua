// Copyright (c) 2015  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/* 

ltbox - a Lua wrapper for termbox


(for a full wrapper, see lua-termbox
https://github.com/robem/lua-termbox)


Functions:



*/
// ---------------------------------------------------------------------
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "termbox.h"

// ---------------------------------------------------------------------
#define LTBOX_VERSION "0.1"


// ---------------------------------------------------------------------

static int ltb_init(lua_State *L) {
	lua_pushinteger(L, tb_init());
	return 1;
}

static int ltb_shutdown(lua_State *L) {
	tb_shutdown();
	return 0;
}

static int ltb_screen_wh(lua_State *L) {
	lua_pushinteger(L, tb_width());
	lua_pushinteger(L, tb_height());
	return 2;
}

static int ltb_clear(lua_State *L) {
	// clear screen and set colors if optional argument is provided
	// Lua args: colors: integer = (fg << 32) | (bg << 48)
	// (this color representation can be directly or'ed to a 
	// character code for putcell)
	int64_t colors = luaL_optinteger(L, 1, 0);
	uint16_t fg = (colors >> 32) & 0xffff;
	uint16_t bg = (colors >> 48) & 0xffff;
	tb_set_clear_attributes(fg, bg);
	tb_clear();
	return 0;
}

static int ltb_present(lua_State *L) {
	tb_present();
	return 0;
}

static int ltb_setcursor(lua_State *L) {
	int cx = luaL_optinteger(L, 1, -1);
	int cy = luaL_optinteger(L, 2, -1);
	// on the Lua side, top left is (1,1) vs. (0,0) for termbox
	tb_set_cursor(cx-1, cy-1);
	return 0;
}

static int ltb_putcell(lua_State *L) {
	//
	int cx = luaL_checkinteger(L, 1) - 1; // termbox origin is 0,0
 	int cy = luaL_checkinteger(L, 2) - 1; // id.
	int64_t ch = luaL_checkinteger(L, 3);
	struct tb_cell cell;
	cell.ch = ch & 0xffffffff;
	cell.fg = (ch >> 32) & 0xffff;
	cell.bg = (ch >> 48) & 0xffff;
	tb_put_cell(cx, cy, &cell);
	return 0;
}

static int ltb_inputmode(lua_State *L) {
	int mode = luaL_optinteger(L, 1, 0);
	lua_pushinteger(L, tb_select_input_mode(mode));
	return 1;
}

static int ltb_outputmode(lua_State *L) {
	int mode = luaL_optinteger(L, 1, 0);
	lua_pushinteger(L, tb_select_output_mode(mode));
	return 1;
}

extern int tb_utf8encoding;

static int ltb_utf8encoding(lua_State *L) {
	// Lua args: 
	//    nothing: returns current mode
	//    0: set no utf8 encoding (1 char = 1 byte)
	//    1: set utf8 encoding (1 char = 1..6 bytes)
	int mode = luaL_optinteger(L, 1, -1);
	if (mode != -1) {tb_utf8encoding = mode;}
	lua_pushinteger(L, tb_utf8encoding);
	return 1;
}

static int ltb_pollevent(lua_State *L) {
	// Lua args:
	//   an event table that will be filled with event parameters
	//   timeout (integer): 
	//   if timeout is not given, wait forever (use tb_poll_event())
	//   if timeout is >= 0, wait up to timeout milliseconds 
	//       (use tb_peek_event())
	// return the event type (or 0 on timeout), or nil, errmsg on error
	//
	struct tb_event ev;
	int timeout = luaL_optinteger(L, 2, -1); // timeout in milliseconds
	int evt; // event type, or 0 on timeout, or -1 on error
	// here, the evt table argument is at stack index 1. 
	if (timeout == -1) {
		evt = tb_poll_event(&ev);
	} else {
		evt = tb_peek_event(&ev, timeout);
	}
	if (evt == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "pollevent error");
		return 2;
	}
	// success, or timeout if evt==0
	lua_pushinteger(L, evt);
	lua_setfield(L, 1, "type");
	if (evt == TB_EVENT_KEY) {
		lua_pushinteger(L, ev.ch);
		lua_setfield(L, 1, "ch");
		lua_pushinteger(L, ev.key);
		lua_setfield(L, 1, "key");
		lua_pushinteger(L, ev.mod);
		lua_setfield(L, 1, "mod");
	} else if (evt == TB_EVENT_RESIZE) {
		lua_pushinteger(L, ev.w);
		lua_setfield(L, 1, "w");
		lua_pushinteger(L, ev.h);
		lua_setfield(L, 1, "h");
	} else if (evt == TB_EVENT_MOUSE) {
		lua_pushinteger(L, ev.x + 1); // termbox origin is 0,0
		lua_setfield(L, 1, "x");
		lua_pushinteger(L, ev.y + 1); // termbox origin is 0,0
		lua_setfield(L, 1, "y");		
	}
	lua_pop(L, 1); // pop the table
	lua_pushinteger(L, evt); // and return the event
	return 1; 
} //ltb_pollevent


// ---------------------------------------------------------------------
// Lua open library function

static const struct luaL_Reg ltboxlib[] = {
	{"init", ltb_init},
	{"shutdown", ltb_shutdown},
	{"screen_wh", ltb_screen_wh},
	{"clear", ltb_clear},
	{"present", ltb_present},
	{"putcell", ltb_putcell},
	{"inputmode", ltb_inputmode},
	{"outputmode", ltb_outputmode},
	{"utf8encoding", ltb_utf8encoding},
	{"pollevent", ltb_pollevent},
	
	{NULL, NULL},
};


int luaopen_ltbox (lua_State *L) {
	luaL_newlib (L, ltboxlib);
    // 
    lua_pushliteral (L, "VERSION");
	lua_pushliteral (L, LTBOX_VERSION); 
	lua_settable (L, -3);
	return 1;
}

