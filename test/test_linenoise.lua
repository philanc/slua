ln = require'linenoise'

mtcp = require'mtcp' -- for msleep()

strf = string.format
printf = function(...) print(strf(...)) end

function t1()
	curmode = ln.getmode() -- save current terminal mode
	ln.setrawmode(1) -- opost=1 : keep output post-processing
	i = 0
	while not ln.kbhit() do
		i = i + 1
		print(i, "Press any key to stop")
		mtcp.msleep(100) --  sleep 100 millisec
	end
	ch = io.read(1) -- we are still in raw mode so input is not buffered
	print("restore mode", ln.setmode(curmode)) -- restore the terminal mode
	printf("stop key: %q", ch)
end

t1()
