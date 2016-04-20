
### ltbox

A wrapper for the termbox library.  It allows to write simple text-based interfaces without the huge ncurses overhead. 

Functions directly map to termbox functions. See reference at https://github.com/nsf/termbox and for a detailed API doc, the comments in src/ltbox/termbox.h.

The screen is seen as a two-dimension matrix of cells. Each cell is a 64-bit integer. It contains a character code and attributes. Attributes are defined so that they can be OR'ed together and with the character code (see attribute definition after the function descriptions)

UTF8 -- Character codes are 32-bit integers. UTF8 should be supported in termbox but *has not been tested* in this binding.


Functions:
```
init()
	Initializes the termbox library. This function should be called 
	before any other functions. 
	
shutdown()
	After initialization and usage, the library must be finalized 
	with this function.

screen_wh()
	return the width and height of the terminal in characters
	(eg. 80, 24)

clear([color])
	clear the screen
	color is an optional (64-bit) integer.
	(this function combines termbox tb_set_clear_attributes() 
	and tb_clear() functions)

present()
	synchronize the internal buffer with the terminal. It must be 
	called to actually display all the modifications to the cells.
	return nothing.

setcursor([x, y])
	set the position of the cursor. x is the column
	and y is the row. The origin is the top-left cell, its position
	is (1,1) (contrary to termbox which numbers columns and rows
	starting at 0)
	x and y are optional. if they are both 0 or not provided, the 
	cursor is hidden.

putcell(x, y, cell)
	change the content of a cell at position (x, y)
	cell is a 64-bit integer which contains the character code and 
	attributes OR'ed together.

inputmode([mode])
	set the input mode (regarding how character ESC is processed)
	if mode is not provided, the current mode is returned
	mode=1: return ESC as-is (except when ESC is part of a known 
	        escape sequence)
	mode=2: set the ALT modifier for the next input event
			(except when ESC is part of a known escape sequence)
			

outputmode([mode])
	set the output mode
	if mode is not provided, the current mode is returned
	mode=1: normal mode, 16 colors
	mode=2: 256 colors
	mode=3: 216 colors
	mode=4: 24 grays
	(see src/ltbox/termbox.h for a description of the modes)

utf8encoding([mode])
	set the UTF8 mode
	if mode is not provided, the current mode is returned	
	mode=0: no UTF8 encoding (1 byte is 1 character)
			this is the default mode.
	mode=1: set UTF8 encoding -- !!not tested!!

pollevent(evt [, timeout])
	wait for an event
	evt is a table provided by the caller. It is filled with the event
	details according to the event type.
	The function returns the event type, or (nil, error msg)
	event types:  0  timeout
	              1  key pressed
	              2  terminal window resized
				  3  mouse event
	evt table fields:
	if event is keypress:
	   'ch'    the character code
	   'key'   the key code
	   'mod'   the modifier(s)
	if event is terminal resized:
	   'w'     the new terminal width
	   'h'     the new terminal height
	if event is mouse
	   'x'     the mouse column coordinate
	   'y'     the mouse row coordinate
	   (mouse button events are returned as key events - see 
	   key codes below)

```

Attributes and key codes are defined in the Lua code below. 

Note: The exact behavior of attributes depends on thetype of the terminal (Linux console, xterm, rxvt, etc.). All attributes are not supported everywhere.
```

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
```