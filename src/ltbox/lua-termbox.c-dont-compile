/// slua
/// Lua binding to termbox
/// this file comes from  https://github.com/robem/lua-termbox
/// the termbox C library (included here) comes from 
/// https://github.com/nsf/termbox
/// --------------------------------------------------------------------

/// slua 150715 
/// - fixed #include "termbox"
/// - s/luaL_checkunsigned/(int) luaL_checkinteger/

#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h> //malloc, free
#include <string.h> //strlen, strncpy


///  #include <termbox.h> 
#include "termbox.h"

static int l_tb_init(lua_State *L)
{
  lua_pushinteger(L, tb_init());
  return 1;
}

static int l_tb_shutdown(lua_State *L)
{
  tb_shutdown();
  return 0;
}

static int l_tb_width(lua_State *L)
{
  lua_pushinteger(L, tb_width());
  return 1;
}

static int l_tb_height(lua_State *L)
{
  lua_pushinteger(L, tb_height());
  return 1;
}

static int l_tb_clear(lua_State *L)
{
  tb_clear();
  return 0;
}

static int l_tb_set_clear_attributes(lua_State *L)
{
  uint16_t fg = (int) luaL_checkinteger(L, 1);
  uint16_t bg = (int) luaL_checkinteger(L, 2);

  lua_pop(L, 2);

  tb_set_clear_attributes(fg, bg);
  return 0;
}

static int l_tb_present(lua_State *L)
{
  tb_present();
  return 0;
}

static int l_tb_set_cursor(lua_State *L)
{
  int cx = luaL_checkinteger(L, 1);
  int cy = luaL_checkinteger(L, 2);

  lua_pop(L, 2);

  tb_set_cursor(cx, cy);
  return 0;
}

static int l_tb_put_cell(lua_State *L)
{
  int x = luaL_checkinteger(L, 1);
  int y = luaL_checkinteger(L, 2);

  luaL_checktype(L, 3, LUA_TTABLE);

/* TODO: allow less than 3 members by default values */

  lua_getfield(L, 3, "ch");
  lua_getfield(L, 3, "fg");
  lua_getfield(L, 3, "bg");

  const struct tb_cell cell = {
    .ch = luaL_checkstring(L, -3)[0],
    .fg = luaL_checkinteger(L, -2),
    .bg = luaL_checkinteger(L, -1),
  };

  lua_pop(L, 6);

  tb_put_cell(x, y, &cell);

  return 0;
}

static int l_tb_change_cell(lua_State* L)
{
  int x       = luaL_checkinteger(L, 1);
  int y       = luaL_checkinteger(L, 2);
  char ch     = luaL_checkstring(L, 3)[0];
  uint16_t fg = (int) luaL_checkinteger(L, 4);
  uint16_t bg = (int) luaL_checkinteger(L, 5);

  lua_pop(L, 5);

  tb_change_cell(x, y, ch, fg, bg);
  return 0;
}

static int l_tb_blit(lua_State *L)
{
  int x = luaL_checkinteger(L, 1);
  int y = luaL_checkinteger(L, 2);
  int w = luaL_checkinteger(L, 3);
  int h = luaL_checkinteger(L, 4);

  luaL_checktype(L, 5, LUA_TTABLE);
  unsigned len = luaL_len(L, 5); // number of cells

  struct tb_cell *cells = (struct tb_cell*)malloc(sizeof(struct tb_cell) * len);

  unsigned i;
  for (i=1; i<=len; ++i) {
    lua_rawgeti(L, 5, i); // push table/cell
    luaL_checktype(L, 6, LUA_TTABLE);

    lua_getfield(L, 6, "ch");
    lua_getfield(L, 6, "fg");
    lua_getfield(L, 6, "bg");

    cells[i-1].ch = luaL_checkstring(L, -3)[0];
    cells[i-1].fg = luaL_checkinteger(L, -2);
    cells[i-1].bg = luaL_checkinteger(L, -1);

    lua_pop(L, 4); // pop table + elements
  }

  lua_pop(L, 5);

  tb_blit(x, y, w, h, cells);

  free(cells);
  return 0;
}

static int l_tb_select_input_mode(lua_State *L)
{
  int mode = luaL_checkinteger(L, 1);

  lua_pop(L, 1);

  lua_pushinteger(L, tb_select_input_mode(mode));
  return 1;
}

static int l_tb_select_output_mode(lua_State *L)
{
  int mode = luaL_checkinteger(L, 1);

  lua_pop(L, 1);

  lua_pushinteger(L, tb_select_output_mode(mode));
  return 1;
}

static int l_tb_peek_event(lua_State *L)
{
  luaL_checktype(L, 1, LUA_TTABLE);
  int timeout = luaL_checkinteger(L, 2);

  struct tb_event event;
  int ret = tb_peek_event(&event, timeout);

  lua_pushnumber(L, event.type);
  lua_setfield(L, 1, "type");

  lua_pushnumber(L, event.mod);
  lua_setfield(L, 1, "mod");

  lua_pushnumber(L, event.key);
  lua_setfield(L, 1, "key");

  char string[2] = {event.ch,'\0'};
  string[0] = event.ch;
  lua_pushstring(L, string);
  lua_setfield(L, 1, "ch");

  lua_pushnumber(L, event.w);
  lua_setfield(L, 1, "w");

  lua_pushnumber(L, event.h);
  lua_setfield(L, 1, "h");

  lua_pop(L, 2);

  lua_pushinteger(L, ret);

  return 1;
}

static int l_tb_poll_event(lua_State *L)
{
  luaL_checktype(L, 1, LUA_TTABLE);

  struct tb_event event;
  int ret = tb_poll_event(&event);

  lua_pushnumber(L, event.type);
  lua_setfield(L, 1, "type");

  lua_pushnumber(L, event.mod);
  lua_setfield(L, 1, "mod");

  lua_pushnumber(L, event.key);
  lua_setfield(L, 1, "key");

  char string[2] = {event.ch,'\0'};
  string[0] = event.ch;
  lua_pushstring(L, string);
  lua_setfield(L, 1, "ch");

  lua_pushnumber(L, event.w);
  lua_setfield(L, 1, "w");

  lua_pushnumber(L, event.h);
  lua_setfield(L, 1, "h");

  lua_pop(L, 1);

  lua_pushinteger(L, ret);

  return 1;
}

static int l_tb_utf8_char_length(lua_State *L)
{
  char c = luaL_checkstring(L, 1)[0];

  lua_pop(L, 1);

  lua_pushinteger(L, tb_utf8_char_length(c));
  return 1;
}

static int l_tb_utf8_char_to_unicode(lua_State *L)
{
  uint32_t *out = (uint32_t*)(uintptr_t)(int) luaL_checkinteger(L, 1);
  const char *c = luaL_checkstring(L, 2);

  lua_pop(L, 2);

  lua_pushinteger(L, tb_utf8_char_to_unicode(out, c));
  return 1;
}

static int l_tb_utf8_unicode_to_char(lua_State *L)
{
  uint32_t *out = (uint32_t*)(uintptr_t)(int) luaL_checkinteger(L, 1);
  const char *c = luaL_checkstring(L, 2);

  lua_pop(L, 2);

  lua_pushinteger(L, tb_utf8_char_to_unicode(out, c));
  return 1;
}

static const struct luaL_Reg l_termbox[] = {
  {"init",                   l_tb_init},
  {"shutdown",               l_tb_shutdown},
  {"width",                  l_tb_width},
  {"height",                 l_tb_height},
  {"clear",                  l_tb_clear},
  {"set_clear_attributes",   l_tb_set_clear_attributes},
  {"present",                l_tb_present},
  {"set_cursor",             l_tb_set_cursor},
  {"put_cell",               l_tb_put_cell},
  {"change_cell",            l_tb_change_cell},
  {"blit",                   l_tb_blit},
  {"select_input_mode",      l_tb_select_input_mode},
  {"select_output_mode",     l_tb_select_output_mode},
  {"peek_event",             l_tb_peek_event},
  {"poll_event",             l_tb_poll_event},
  {"utf8_char_length",       l_tb_utf8_char_length},
  {"utf8_char_to_unicode",   l_tb_utf8_char_to_unicode},
  {"utf8_unicode_to_char",   l_tb_utf8_unicode_to_char},
  {NULL,NULL}
};

/* remove TB_ prefix and register constant */
#define REGISTER_CONSTANT(constant) {\
  char* full_name = #constant; \
  unsigned len = strlen(full_name)+1; \
  char* name = (char*)malloc(len-3); \
  strncpy(name, full_name+3, len-3); \
  lua_pushnumber(L, constant); \
  lua_setfield(L, -2, name); \
  free(name); \
}

int luaopen_termbox (lua_State *L)
{
  luaL_newlib(L, l_termbox);

  /// constants deinition moved to an external lua file
  /// (reduce termbox dead-weight when it is not used)
  //~ REGISTER_CONSTANT(TB_KEY_F1);
  //~ REGISTER_CONSTANT(TB_KEY_F2);
  //~ REGISTER_CONSTANT(TB_KEY_F3);
  //~ REGISTER_CONSTANT(TB_KEY_F4);
  //~ REGISTER_CONSTANT(TB_KEY_F5);
  //~ REGISTER_CONSTANT(TB_KEY_F6);
  //~ REGISTER_CONSTANT(TB_KEY_F7);
  //~ REGISTER_CONSTANT(TB_KEY_F8);
  //~ REGISTER_CONSTANT(TB_KEY_F9);
  //~ REGISTER_CONSTANT(TB_KEY_F10);
  //~ REGISTER_CONSTANT(TB_KEY_F11);
  //~ REGISTER_CONSTANT(TB_KEY_F12);
  //~ REGISTER_CONSTANT(TB_KEY_INSERT);
  //~ REGISTER_CONSTANT(TB_KEY_DELETE);
  //~ REGISTER_CONSTANT(TB_KEY_HOME);
  //~ REGISTER_CONSTANT(TB_KEY_END);
  //~ REGISTER_CONSTANT(TB_KEY_PGUP);
  //~ REGISTER_CONSTANT(TB_KEY_PGDN);
  //~ REGISTER_CONSTANT(TB_KEY_ARROW_UP);
  //~ REGISTER_CONSTANT(TB_KEY_ARROW_DOWN);
  //~ REGISTER_CONSTANT(TB_KEY_ARROW_LEFT);
  //~ REGISTER_CONSTANT(TB_KEY_ARROW_RIGHT);

  //~ REGISTER_CONSTANT(TB_KEY_CTRL_TILDE);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_2);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_A);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_B);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_C);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_D);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_E);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_F);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_G);
  //~ REGISTER_CONSTANT(TB_KEY_BACKSPACE);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_H);
  //~ REGISTER_CONSTANT(TB_KEY_TAB);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_I);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_J);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_K);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_L);
  //~ REGISTER_CONSTANT(TB_KEY_ENTER);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_M);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_N);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_O);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_P);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_Q);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_R);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_S);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_T);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_U);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_V);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_W);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_X);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_Y);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_Z);
  //~ REGISTER_CONSTANT(TB_KEY_ESC);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_LSQ_BRACKET);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_3);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_4);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_BACKSLASH);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_5);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_RSQ_BRACKET);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_6);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_7);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_SLASH);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_UNDERSCORE);
  //~ REGISTER_CONSTANT(TB_KEY_SPACE);
  //~ REGISTER_CONSTANT(TB_KEY_BACKSPACE2);
  //~ REGISTER_CONSTANT(TB_KEY_CTRL_8);

  //~ REGISTER_CONSTANT(TB_MOD_ALT);

  //~ REGISTER_CONSTANT(TB_DEFAULT);
  //~ REGISTER_CONSTANT(TB_BLACK);
  //~ REGISTER_CONSTANT(TB_RED);
  //~ REGISTER_CONSTANT(TB_GREEN);
  //~ REGISTER_CONSTANT(TB_YELLOW);
  //~ REGISTER_CONSTANT(TB_BLUE);
  //~ REGISTER_CONSTANT(TB_MAGENTA);
  //~ REGISTER_CONSTANT(TB_CYAN);
  //~ REGISTER_CONSTANT(TB_WHITE);

  //~ REGISTER_CONSTANT(TB_BOLD);
  //~ REGISTER_CONSTANT(TB_UNDERLINE);
  //~ REGISTER_CONSTANT(TB_REVERSE);

  //~ REGISTER_CONSTANT(TB_EVENT_KEY);
  //~ REGISTER_CONSTANT(TB_EVENT_RESIZE);

  //~ REGISTER_CONSTANT(TB_EUNSUPPORTED_TERMINAL);
  //~ REGISTER_CONSTANT(TB_EFAILED_TO_OPEN_TTY);
  //~ REGISTER_CONSTANT(TB_EPIPE_TRAP_ERROR);

  //~ REGISTER_CONSTANT(TB_HIDE_CURSOR);

  //~ REGISTER_CONSTANT(TB_INPUT_CURRENT);
  //~ REGISTER_CONSTANT(TB_INPUT_ESC);
  //~ REGISTER_CONSTANT(TB_INPUT_ALT);

  //~ REGISTER_CONSTANT(TB_OUTPUT_NORMAL);
  //~ REGISTER_CONSTANT(TB_OUTPUT_256);
  //~ REGISTER_CONSTANT(TB_OUTPUT_216);
  //~ REGISTER_CONSTANT(TB_OUTPUT_GRAYSCALE);

  //~ REGISTER_CONSTANT(TB_EOF);

  return 1;
}

