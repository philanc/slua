

local lt = require "ltbox"

local strf = string.format
local byte, char = string.byte, string.char
local app, concat = table.insert, table.concat

------------------------------------------------------------------------
-- attributes and key definitions

local colors = {
	default = 0,
	-- foreground colors:             fgcolor << 32 
	black     = 0x000100000000,
	red       = 0x000200000000,
	green     = 0x000300000000,
	yellow    = 0x000400000000,
	blue      = 0x000500000000,
	magenta   = 0x000600000000,
	cyan      = 0x000700000000,
	white     = 0x000800000000,
	-- backgroud colors:              bgcolor << 48
	bgblack   = 0x0001000000000000,
	bgred     = 0x0002000000000000,
	bggreen   = 0x0003000000000000,
	bgyellow  = 0x0004000000000000,
	bgblue    = 0x0005000000000000,
	bgmagenta = 0x0006000000000000,
	bgcyan    = 0x0007000000000000,
	bgwhite   = 0x0008000000000000,
	
	-- attributes
	bold      = 0x010000000000,      -- 0x100 << 32
	underline = 0x020000000000,      -- 0x200 << 32
	reverse   = 0x040000000000,      -- 0x400 << 32
	bgbold    = 0x0100000000000000,  -- 0x100 << 48
}

local keys = {
	escape         = 0x1b,
	kf1            = 0xffff,  -- 0xffff-0
	kf2            = 0xfffe,  -- 0xffff-1
	kf3            = 0xfffd,  -- ...
	kf4            = 0xfffc,
	kf5            = 0xfffb,
	kf6            = 0xfffa,
	kf7            = 0xfff9,
	kf8            = 0xfff8,
	kf9            = 0xfff7,
	kf10           = 0xfff6,
	kf11           = 0xfff5,
	kf12           = 0xfff4,
	kins           = 0xfff3,
	kdel           = 0xfff2,
	khome          = 0xfff1,
	kend           = 0xfff0,
	kpgup          = 0xffef,
	kpgdn          = 0xffee,
	kup            = 0xffed,
	kdown          = 0xffec,
	kleft          = 0xffeb,
	kright         = 0xffea,
	mouseleft      = 0xffe9,
	mouseright     = 0xffe8,
	mousemiddle    = 0xffe7,
	mouserelease   = 0xffe6,
	mousewheelup   = 0xffe5,
	mousewheeldown = 0xffe4,  -- 0xffff-27
	-- modifiers
	mod_alt        = 0x01,
}

------------------------------------------------------------------------

local function putstr(s, x, y, xmax, attr)
	-- put string s starting at coordinates x, y with attribute attr
	-- ensure the string does not go beyond column xmax
	-- (assume that x, y, xmax are compatible with the screen dimensions)
	-- attr defaults to 0 (default mode)
	attr = attr or 0
	local ch, xi
	for i = 1, #s do
		ch = byte(s, i)
		xi = x + i - 1
		if xi <= xmax then lt.putcell(xi, y, ch | attr) end
	end
end

local function erase_screen(w, h)
	-- erase the screen
	for i = 1, w do
		for j = 1, h do
			lt.putcell(i, j, 0)
		end
	end
end

local function paint_corners(w, h)
	-- paint the screen given its dimensions (width, height)
	local attr_corners = colors.red | colors.bold
	local tl, bl, tr, br
	tl = strf("top-left is [%d,%d]", 1, 1)
	bl = strf("bottom-left is [%d,%d]", 1, h)
	tr = strf("top-right is [%d,%d]", w, 1)
	br = strf("bottom-right is [%d,%d]", w, h)
	putstr(tl, 1, 1, w, attr_corners)
	putstr(bl, 1, h, w, attr_corners)
	putstr(tr, w-#tr, 1, w, attr_corners)
	putstr(br, w-#br, h, w, attr_corners)
end

local scrw, scrh  -- the screen width and height

local function paint_keyevent(evt)
	local attr_evt = colors.green | colors.bold | colors.bgmagenta
	local x, y = 3,  scrh // 2 - 1
	local qs = "Press 'q' to exit"
	putstr(qs, x, y, scrw, attr_evt)
	if evt.ch then 
		local es = strf(
--~ 		"character code: 0x%02x   keycode: 0x%08x   modifier: 0x%08x", 
		"character code: 0x%02x   keycode: 0x%08x   modifier: %d", 
		evt.ch, evt.key, evt.mod)
		putstr(es, x, y+2, scrw, attr_evt)
	end
end

-- initialize the screen
lt.init()
lt.inputmode(2)

scrw, scrh = lt.screen_wh()

local quit = false
local evt = {}  -- the event table
local etype

-- the main loop
while not quit do
	-- (re)display the screen - the redisplay is not very subtle :-)
	erase_screen(scrw, scrh)
	paint_corners(scrw, scrh)
	paint_keyevent(evt)
	lt.present()
	etype = lt.pollevent(evt, 10000)
	if etype == 1 then -- key pressed
		if evt.ch == byte('q') then break end
		-- continue
	elseif etype == 2 then -- terminal resized
		scrw = evt.w
		scrh = evt.h
		-- continue
	else
		-- ignore other events
	end
end --main loop

--reset the screen and exit
lt.shutdown()

