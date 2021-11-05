ln = require'linenoise'

l5 = require'l5' -- for msleep()

strf = string.format
printf = function(...) print(strf(...)) end

function t1()
	curmode = ln.getmode() -- save current terminal mode
	ln.setrawmode(1) -- opost=1 : keep output post-processing
	i = 0
	while not ln.kbhit() do
		i = i + 1
		print(i, "Terminal is in raw mode. Press any key to stop")
		l5.msleep(200) --  sleep 200 millisec
	end
	-- we are still in raw mode so input is not buffered
	ch = io.read(1) 
	-- restore the terminal mode
	print("restore normal mode", ln.setmode(curmode)) 
	printf("stop key: %q", ch)
end

t1()
