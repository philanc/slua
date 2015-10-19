A Network access module for Lua

Copyright (C) 2014 by Micro Systems Marc Balmer.
All rights reserved.
------------------------------------------------------------------------

Note: This module was found at https://github.com/catwell/luanet

------------------------------------------------------------------------
##The net module

The net module is used to implement network servers or clients. 
It supports IPv4 as well as IPv6.

### Creating network servers

bind(hostname, port)
	Bind a socket on the specified hostname and port. 
	This also does the listen system call.

sock:accept()
	Accept a new connection and return a new socket for the 
	new connection.

sock:close()
	Close a socket.

### Creating network clients

connect(hostname, port)
	Connect to hostname at the specified port and return a new socket.

### Transferring data

sock:write(data)
	Write data to the socket.

sock:print(string)
	Write string to the socket and append a newline character.

sock:read([timeout])
	Read data from a socket with an optional timeout in milliseconds. 
	Returns the data read or nil if the timeout expires or an error 
	occured.

sock:readln([timeout])
	Read data up to the first newline character from a socket with 
	an optional timeout in milliseconds. Returns the data read or nil 
	if the timeout expires or an error occured.

sock:socket()
	Return as an integer the underlying socket.

sock:close()
	Close a socket.

