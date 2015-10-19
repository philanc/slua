local net = require 'net'

conn = net.connect('www.google.com', 'http')
conn:write('GET / HTTP/1.0\n\n')
page = conn:read(10000)
print(page)

while conn:read(1000) do
	print('p2 read')
end


conn:close()
