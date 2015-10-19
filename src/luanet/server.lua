local net = require 'net'
local unix = require 'unix'

local s = net.bind('localhost', '4711')

while true do
	local s2 = s:accept()

	if unix.fork() == 0 then
		s2:print('Hallo')
		print(s2:readln())
		s2:close()
		os.exit(0)
	else
		s2:close()
	end
end

s:close()
