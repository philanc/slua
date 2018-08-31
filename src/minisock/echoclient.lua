

-- echoclient.lua  
-- launched with an optional argument ("verbose" or "quiet")
-- default is "verbose"

local verbose = arg[1] or "verbose"

local lua = os.getenv("LUA") or "lua"
local echoserver = arg[0]:gsub("echoclient", "echoserver")

local he = require "he"
local ms = require "minisock"

local strf = string.format
local function repr(x) return strf("%q", x) end

local function printv(...)
	if verbose == "verbose" then print(...) end
end

--
function test(what)
	if what == "af_unix" then 
		-- unix socket
		sockpath = "/tmp/minisock_test.sock"
		os.remove(sockpath)
		addr = "\1\0" .. sockpath .. "\0\0\0\0\0"
		req = "Hello af_unix!"
		printv("---")
		printv("spawning echoserver.lua listening on " .. sockpath)
		
		os.execute(strf("%s %s %s af_unix & ", 
			lua, echoserver, verbose))
	elseif what == "af_inet" then 
		-- net socket: 127.0.0.1:4096 (0x1000)
		addr = "\2\0\x10\x00\x7f\0\0\1\0\0\0\0\0\0\0\0"
		req = "Hello af_inet!"
		s = "127.0.0.1 port 4096"
		printv("---")
		printv("spawning echoserver.lua listening on " .. s)
		os.execute(strf("%s %s %s af_inet & ", 
			lua, echoserver, verbose))
	else
		print("unknown test:", what)
		os.exit(1)
	end

	-- ensure server has enough time to start listening
	ms.msleep(500)

	sfd, msg = ms.connect(addr)
	if not sfd then print("echoclient:", msg); goto exit end

	
	r, msg = ms.write(sfd, req)
	printv("echoclient sends on fd ".. sfd .. ":", req)

	resp, msg = ms.read(sfd)
	if not resp then print("echoclient:", msg); goto exit end

	printv("echoclient receives on fd ".. sfd .. ":", resp)
	assert(resp == "echo:" .. req)

	r, msg = ms.close(sfd)
	if not r then print("echoclient:", msg); goto exit end
	
	do return "ok" end

	::exit::
	return "failed"
	
end--test()

function testudp()
	-- server:  127.0.0.1 port 4096
	addr = "\2\0\x10\x00\x7f\0\0\1\0\0\0\0\0\0\0\0"
	printv("---")
	-- launch server, ensure it has enough time to start listening
	printv("spawning echoserver.lua udp receiving on " .. s)
	os.execute(strf("%s %s %s udp & ", lua, echoserver, verbose))
	ms.msleep(500)

	sfd, msg = ms.udpsocket()
	if not sfd then print("echoclient:", msg); goto exit end

	req = "Hello udp!"
	r, msg = ms.sendto(sfd, addr, req)
	printv("echoclient sendto on fd ".. sfd .. ":", req)

	resp, msg = ms.recvfrom(sfd)
	if not resp then print("echoclient:", msg); goto exit end

	printv("echoclient recvfrom on fd ".. sfd .. ":", resp)
	assert(resp == "echo:" .. req)

	r, msg = ms.close(sfd)
	if not r then print("echoclient:", msg); goto exit end

	do return "ok" end
	
	::exit::
	return "failed"
	
end --testudp()


print("test af_unix", test("af_unix"))
os.remove(sockpath)

print("test af_inet", test("af_inet"))

print("test udp", testudp())


------------------------------------------------------------------------
--[[

unix socket
	sockaddr:    family (uint16, =1) | socket path | 0
	family = 1    (0x01, 0x00)
	max len of a unix socket path: 108 incl null at end
		"SIZEOF_SOCKADDR_UN_SUN_PATH 108"

AF_INET (IPv4)
	sockaddr:  (cf return values of getaddrinfo)  len=16
	family=2  (u16) | port (u16) | IPv4 addr (u8 * 4) | u8=0 * 8
	note: family is little endian, port is big endian
	ie: family=2, port=80 =>  0x02, 0x00, 0x00, 0x50 

AF_INET6 (IPv6)
	sockaddr:  (cf return values of getaddrinfo)  len=28
	family=10  (u16) | port (u16) | flow_id=0 (u32) |  \
	IPv6 addr (u8 * 16) | u8=0 * 4
	note: family is little endian, port is big endian



]]


