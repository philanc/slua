-- Copyright (c) 2015  Phil Leblanc  -- see LICENSE file
------------------------------------------------------------------------
--[[	term.lua

terminal utility module (based on the ltbox library)


]]


------------------------------------------------------------------------
-- some local definitions

local lt = require 'ltbox'

local strf = string.format
local byte, char = string.byte, string.char
local spack, sunpack = string.pack, string.unpack

local app, concat = table.insert, table.concat

------------------------------------------------------------------------


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

local function putsubstring(s, i, j, x, y, xm, attr, fill)
	-- put part of a string on screen at coordinates x, y
	-- i: index of first byte to display in string
	-- j: index of last byte to display in string
	--    contrary to string.sub, negative values for i, j are not 
	--    accepted, except j == -1 which is equivalent to the string length)

	-- x, y: column, line where the string should be displayed
	-- xm: right margin - chars are put on screen between x and at most xm
	-- attr: cells attribute (default to 0)
	-- fill: if true, fill the rest of the row (up to xm) with spaces
	-- return nexti, nextx
	--    nexti: index of the first non-displayed char in string 
	--           or 0 if none (at end of string)
	--    nextx: horizontal index of first non-filled cell on screen
	--
	attr = attr or 0
	if (j == -1) or (j > #s) then j = #s end
	while i <= j do
		-- get next char in s  (some utf8 magic here in the future :-)
		ch = byte(s, i); i = i+1
		if x > xm then break end
		lt.putcell(x, y, ch | attr)
		x = x+1
	end
	-- process fill now
	if fill then 
		while x <= xm do
			lt.putcell(x, y, 32 | attr)
			x = x+1
		end
	end
	return i, x
end --putsubstring
		
local function putstring(s, x, y, xm, attr, fill)
	-- put a string on screen at coordinates x, y
	-- xm: right margin - chars are put on screen between x and at most xm
	-- attr: cells attribute (default to 0)
	-- fill: if true, fill the rest of the row (up to xm) with spaces
	-- return nexti, nextx
	--    nexti: index of the first non-displayed char in string 
	--           or 0 if none (at end of string)
	--    nextx: horizontal index of first non-filled cell on screen
	return putsubstring(s, 1, -1, x, y, xm, attr, fill)
end

local function newbox(x, y, xm, ym, attr, selattr)
	-- initialize a "box" that represent a region on the screen
	-- x, y: top left corner of the box
	-- xm, ym: bottom right corner of the box
	--     (caller must ensure that the box fits with the screen 
	--     dimensions - not checked here)
	-- attr: cells attribute for all lines in the box (default to 0)
	-- selattr: attribute used to highlight cells in the box 
	--     (defaults to reverse)
	local box = {
		x = x, 
		y = y,
		xm = xm, 
		ym = ym,
		attr = attr or 0,
		selattr = selattr or colors.reverse,
	}
	return box
end -- newbox

local function putfiller(box, filler)
	if filler & 0xffffffff00000000 == 0 then 
		filler = filler | box.attr 
	end
	for y = box.y, box.ym do
		for x = box.x, box.xm do
			lt.putcell(x, y, filler)
		end
	end
end

local function putlist(box, sl, idx, seloffset)
	-- display a list of string on screen
	-- box: the box in which the list is displayed (see newbox())
	-- sl: a list of strings
	-- idx: index in sl of the first item to display
	-- seloffset: if defined, this is the line to highlight
	--     relative to idx (seloffset = 0 => highlight the top line)
	-- end of lines and empty lines at bottom are filled with space
	local lineattr 
	-- index of the line to highlight
	local idxhi = (seloffset) and (idx+seloffset) or -1 
	local attr, selattr = box.attr, box.selattr
	local s
	for yy = box.y, box.ym do
		lineattr = (idx == idxhi) and selattr or attr
		if idx > #sl then s = "" else s = sl[idx] end
		putstring(s, box.x, yy, box.xm, lineattr, true)
		idx = idx+1
	end
end -- putlist


------------------------------------------------------------------------
return  { -- term module
	putsubstring = putsubstring,
	putstring = putstring,
	newbox = newbox,
	putlist = putlist,
	putfiller = putfiller,
	--
	keys = keys,
	colors = colors,
	--
	}
