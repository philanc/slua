
### mtcp

A minimal wrapper over sockets for tcp connections. 

Functions:
```
bind(host, service)
	create a server socket, bind, then listen 
	arguments: host and service, as strings
	return the server socket file descriptor (as an integer) and
	the raw host address as a string,  or nil, error msg

accept(servfd)
	accept incoming connections on a server socket
	servfd: the server socket file descriptor (as an integer)
	return the client socket file descriptor (as an integer) and
	the raw client address as a string,  or nil, error msg
	

connect(host, service)
	connect to a host
	arguments: host and service, as strings
	return the connection socket fd (as an integer) and the host 
	raw address as a string, or nil, error msg
	
read(fd [, n [, timeout]])
	read bytes from a socket
	fd: the socket descriptor (as an integer)
	n: number of bytes to read (defaults to 1,024 - see BUFSIZE in mtcp.c)
	timeout: an integer number of milliseconds (defaults to 10,000 - see
	  DEFAULT_TIMEOUT in mtcp.c)
	reading stops on error, on timeout, when at least nbytes bytes 
	have been read, or when last socket read returned less than BUFSIZE.
	(the read function is not buffered)
	return the number of bytes read, or (nil, error msg)
	
write(fd, s [, idx, n])
	write bytes from a string to a socket
	fd: the socket descriptor (as an integer)
	s: the string containing the bytes to send
	idx: integer index in s. The bytes to send start in s at idx
	n: number of bytes to send (if too large, n is adjusted to the number
	   of bytes remaining in string s at idx)
	idx and n are optional. If not present they are assumed to be 1 and #s.
	return the number of bytes sent, or (nil error msg). In case of 
	write error, the error msg includes the value of 'errno'
	
	
close(fd)
	close a socket 
	fd: the socket file descriptor (as integer)
	return true on success or nil, errmsg	

getsockname(fd)
	get the address a socket is bound to
	fd: the socket file descriptor (as integer)
	return the raw client address as a string,  or nil, errmsg
	
getpeername(fd)
	get the address the peer a socket is connected to
	fd: the socket file descriptor (as integer)
	return the raw client address as a string,  or nil, errmsg	

getaddrinfo(hostname [, port])
	get a list of addresses corresponding to a hostname and port
	return the list of ip addresses as a Lua table

getnameinfo(addr [, numeric_host])
	converts a raw address into a host and port
	addr: a raw address (sockaddr) as returned by bind, connect, getaddrinfo
	numeric_host: if true, the function returns a numeric IP address for 
	the host.
	return hostname-or-IP-addr, port (port is always returned as an integer)

msleep(n)
	suspend the execution of the calling thread for n milliseconds
	(it uses the linux nanosleep() function)
	return value: true on success, or (nil, error msg)





```