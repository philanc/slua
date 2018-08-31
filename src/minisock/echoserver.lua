
-- echoserver.lua  --  should be launched by echoclient.lua 
-- 
-- must be launched with 2 arguments:  
--	lua echoserver.lua {verbose|quiet} {af_unix|af_inet|udp}

local verbose = arg[1]
local test = arg[2]

local ms = require "minisock"

local function repr(x) return string.format("%q", x) end

local function printv(...)
	if verbose == "verbose" then print(...) end
end

printv("echoserver: testing " .. test)

if test == "udp" then 
	goto udp
elseif test == "af_unix" then 
	-- unix socket
	af_unix = true
	sockpath = "/tmp/minisock_test.sock"
	addr = "\1\0" .. sockpath .. "\0\0\0\0\0"
else
	-- assume af_inet
	-- net socket: 127.0.0.1:4096 (0x1000, big endian)
	af_unix = false
	-- addr = family | port | IP addr | 00 * 8	
	addr = "\2\0" .. "\x10\x00" .. "\127\0\0\1" .. "\0\0\0\0\0\0\0\0"
end

sfd, msg = ms.bind(addr)
if not sfd then print("echoserver:", msg); goto exit end

cfd, addr = ms.accept(sfd)
if not cfd then print("echoserver:", addr); goto exit end

if af_unix then 
	printv("echoserver: accept connection from unix socket:", repr(addr))
else
	printv("echoserver: accept connection from:", ms.getnameinfo(addr))
end

req, msg = ms.read(cfd)
if not req then print("echoserver:", msg); goto exit end

r, msg = ms.write(cfd, "echo:" .. req)
if not r then print("echoserver:", msg); goto exit end

r, msg = ms.close(sfd)
if not r then print("echoserver:", msg); goto exit end

goto exit

::udp::
addr = "\2\0" .. "\x10\x00" .. "\127\0\0\1" .. "\0\0\0\0\0\0\0\0"
sfd, msg = ms.udpsocket(addr)
if not sfd then print("echoserver:", msg); goto exit end

req, senderaddr = ms.recvfrom(sfd)
if not req then 
	print("echoserver:", senderaddr); goto exit end

printv("echoserver: received message from:", ms.getnameinfo(senderaddr))

r, msg = ms.sendto(sfd, senderaddr, "echo:" .. req)
if not r then print("echoserver:", msg); goto exit end

r, msg = ms.close(sfd)
if not r then print("echoserver:", msg); goto exit end

::exit::


