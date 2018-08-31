# Minisock

A **minimal** Lua socket library for unix / tcp / udp connections, written and tested on Linux.

The level of functionality is sufficient for some simple applications, but is definitely more primitive than, for example, socket.core in LuaSocket. The API is very close to the standard Unix system calls.

Addresses used as parameters in the API functions are *raw addresses* (`struct sockaddr`) stored in Lua as (binary) strings.

Raw addresses for a hostname/port pair can be obtained with function getaddrinfo().

Raw addresses can also be built in Lua by the application:

* the IPv4 raw address for 1.2.3.4 port 80 is\
`string.pack("<H>HBBBB", 2, 80, 1, 2, 3, 4) .. "\0\0\0\0\0\0\0\0"`

* the AF_UNIX raw address for a socket with pathname `/tmp/xyz.sock` is\
`"\1\0" .. "/tmp/xyz.sock"`

Lua utility functions will be provided for building Unix, IPv4 and IPv6 addresses.


### Build and test

To build, adjust the LUADIR variable at the top of the makefile, then `make`.

A very limited test is provided: run `lua echoclient.lua`, or `make test`.

echoclient.lua tests in sequence a Unix, a TCP and a UDP socket connection (launch echoserver.lua, send a string to the server, get a reply from the server)


### Minisock functions

```

--- Generic, TCP and unix sockets

bind(addr)
	create a server socket, bind it, then listen. 
	arguments: raw address, as a string
	return the server socket file descriptor (as an integer),  
	or nil, error msg

accept(fd)
	accept incoming connections on a server socket
	fd: the server socket file descriptor (as an integer)
	return the client socket file descriptor (as an integer) and
	the raw client address as a string,  or nil, error msg
	
connect(addr)
	connect to a server
	argument: the server raw address, as a string
	return the connection socket fd (as an integer), 
	or nil, error msg
	
read(fd [, timeout])
	read bytes from a socket
	fd: the socket descriptor (as an integer)
	timeout: an integer number of milliseconds (defaults to 10,000 - see
	  DEFAULT_TIMEOUT in minisock.c)
	the function reads up to BUFSIZE bytes (read uses an internal buffer
	which is BUFSIZE bytes large - default BUFSIZE value is 4,096)
	return the bytes read as a string, or (nil, error msg) on error or 
	timeout. The error msg includes the value of 'errno'.
	
write(fd, s [, idx, n])
	write bytes from a string to a socket
	fd: the socket descriptor (as an integer)
	s: the string containing the bytes to send
	idx: integer index in s. The bytes to send start in s at idx
	n: number of bytes to send (if too large, n is adjusted to the number
	   of bytes remaining in string s at idx)
	idx and n are optional. If not present they are assumed to be 1 and 
	the number of bytes remaining in string s at idx.
	return the number of bytes sent, or (nil error msg). In case of 
	write error, the error msg includes the value of 'errno'
	
close(fd)
	close a socket 
	fd: the socket file descriptor (as integer)
	return true on success or nil, errmsg	


--- UDP sockets

udpsocket([addr])
	create a UDP socket. Optionnally bind it if an address is provided.
	addr: the server sockaddr as a binary string. 
	addr is optional. if addr is null or empty, an AF_INET socket 
	is created and not bound. if addr is "\x0a", an AF_INET6 
	socket is created and not bound. if addr length is > 1, 
	the socket is created and bound.
	return the socket file descriptor as integer or nil, errmsg

sendto(fd, addr, msg)
	send a message on a socket
	fd: integer - socket descriptor
	addr: raw address (sockaddr) of the recipient
	msg: string to send
	return number of bytes sent or nil, errmsg

recvfrom(fd [, timeout])
	receive message from a socket file descriptor
	Lua args:  
	   socket fd: integer
	   optional timeout: integer (in milliseconds). defaults to
	   DEFAULT_TIMEOUT (10,000 i.e. 10 seconds)
	reads at most UDPMAXSIZE bytes (2,048) 
	return the received message as a string, and the sender 
	raw address, or (nil, error msg) on error or timeout


--- Information

getsockname(fd)
	get the address a socket is bound to
	fd: the socket file descriptor (as integer)
	return the raw client address as a string,  or nil, errmsg
	
getpeername(fd)
	get the address of the peer a socket is connected to
	fd: the socket file descriptor (as integer)
	return the raw client address as a string,  or nil, errmsg	

getaddrinfo(hostname [, port])
	get a list of addresses corresponding to a hostname and port
	return the list of ip addresses as a Lua table

getnameinfo(addr [, numeric_host])
	converts a raw address into a host and port
	addr: a raw address (sockaddr) as returned by bind, connect, 
    accept, getaddrinfo.
	numeric_host: if true, the function returns a numeric IP address for 
	the host.
	return hostname-or-IP-address, port (port is returned as an integer)


--- Misc

msleep(n)
	suspend the execution of the calling thread for n milliseconds
	(it uses the linux nanosleep() function)
	return value: true on success, or (nil, error msg)

```

### License

Minisock is distributed under the terms of the MIT License.

Copyright (c) 2018 Phil Leblanc

