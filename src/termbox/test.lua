require'he'

tb = require 'termbox'

tb.init()
--~ tb.present()

w = tb.width()
h = tb.height()

rnd = math.random

evt = {}

for i = 1, 10000 do
	ii = i
	x = rnd(tb.width()) -1
	y = rnd(tb.height()) -1
	col = rnd(8)
	colb = rnd(8)
	c = string.char(31 + rnd(96))
	tb.change_cell(x, y, c, col, colb)
	tb.present()
--~ 	os.execute'sleep 0.2'
	et = tb.peek_event(evt,5)
	 if et==tb.EVENT_KEY then
		if evt.ch == 'q' then break end
	end
end

--~ tb.poll_event(evt)
tb.shutdown() -- no return val
print(ii, w, h, x, y, col, colb)
print(tb.RED,tb.WHITE)
print("done.")