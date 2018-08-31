// Copyright (c) 2018  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/* 

minisock - A minimal Lua socket library for unix / tcp / udp connections

Functions:
  bind         create a socket; bind it to a host address and port; listen
  accept       accept incoming connections
  connect      create a socket; connect to a (host, port)
  write        write to an open connection
  read         read from an open connection (with a timeout)
  close        close a socket
  getpeername  get the address of the peer a socket is connected to
  getsockname  get the address a socket is bound to
  getaddrinfo  get a list of addresses corresponding to a hostname and port
  getnameinfo  get the hostname and port for a socket
  msleep       sleep for some time in milliseconds

bind() and connect() use raw sockaddr structures passed as a string.
Hostname/port translation to a sockaddr is left to the application. 
It can be done with function getaddrinfo().

The sockaddr structure, returned as a string by getpeername, getsockname,
bind, accept and connect (second return value), is the raw, binary value.
It can be parsed by getnameinfo.

sockaddr strings can also easily be parsed with string.unpack:  
eg. for a IPv4 address:
  family, port, ip1, ip2, ip3, ip4 = string.unpack("<H>HBBBB", sockaddr)
  ipaddr = table.concat({ip1, ip2, ip3, ip4}, '.')

*/
// ---------------------------------------------------------------------
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <poll.h>
#include <errno.h>

// for ll_msleep()
#include <time.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

// ---------------------------------------------------------------------
#define ll_VERSION "0.5"
#define BUFSIZE 4096
#define BACKLOG 32
#define UDPMAXSIZE 2048
#define ADDRMAXSIZE 128

// default timeout: 10 seconds
#define DEFAULT_TIMEOUT 10000


int ll_bind(lua_State *L) {
	// create a server socket, bind, then listen 
	// Lua args: server sockaddr as a binary string
	// return server socket file descriptor as integer or nil, errmsg
	//
	const char * addr;
	size_t addr_len;
	int sfd;
	int r;
	int family;  // AF_UNIX=1, AF_INET=2, AF_INET6=10
	addr = luaL_checklstring(L, 1, &addr_len);
	family = (int) addr[0];  // first byte of sockaddr
	sfd = socket(family, SOCK_STREAM, 0); // 0 for default protocol
	if (sfd < 0) { 
		lua_pushnil (L);
		lua_pushfstring (L, "socket() error %d", errno);
		return 2;      	
	}
	// set REUSEADDR option if socket is AF_INET[6]
	int reuseopt = 1;
	if (family == 2 || family == 10) {
		setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &reuseopt, 
			sizeof(int));
	}
	r = bind(sfd, (struct sockaddr *) addr, addr_len);
	if (r < 0) {
		close(sfd);
		lua_pushnil (L);
		lua_pushfstring (L, "bind error %d", errno);
		return 2;      	
	}
	r = listen(sfd, BACKLOG);
	if (r < 0) {
		lua_pushnil (L);
		lua_pushfstring (L, "listen error: %d", errno);
		return 2;      
	}
	// success, return server socket fd
	lua_pushinteger (L, sfd);
	return 1;
} //ll_bind

int ll_accept(lua_State *L) {
	// accept incoming connections on a server socket 
	// Lua args: server socket file descriptor (as integer)
	// return client socket file descriptor (as integer) and
	// the raw client address as a string,  or nil, errmsg
	int cfd, sfd;
	struct sockaddr_storage addr;
	socklen_t len = sizeof(addr); //enough for ip4 & 6 addr
	sfd = luaL_checkinteger(L, 1); // get server socket fd
	cfd = accept(sfd, (struct sockaddr *)&addr, &len);
	if (cfd == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "accept error: %d", errno);
		return 2;
	}
	//success, return client socket fd and client sockaddr
	lua_pushinteger (L, cfd);
	lua_pushlstring(L, (const char *)&addr, len);
	return 2;
} //ll_accept

int ll_connect(lua_State *L) {
	// connect to a host
	// Lua args: sockaddr as a binary string
	// return connection socket fd (as an integer) or nil, errmsg
	const char * addr;
	size_t addr_len;
	int cfd;
	int r;
	int family;
	addr = luaL_checklstring(L, 1, &addr_len);
	family = (int) addr[0];
	cfd = socket(family, SOCK_STREAM, 0); //0 = default protocol
	if (cfd < 0) { 
		lua_pushnil (L);
		lua_pushfstring (L, "socket() error %d", errno);
		return 2;      	
	}
	r = connect(cfd, (struct sockaddr *) addr, addr_len);
	if (r < 0) {
		close(cfd);
		lua_pushnil (L);
		lua_pushfstring (L, "connect error %d", errno);
		return 2;      	
	}
	//success, return connection socket fd
	lua_pushinteger (L, cfd);
	return 1;
} //ll_connect

int ll_write(lua_State *L) {
	// Lua args:
	//   fd: integer - socket descriptor
	//   s: string - string containing bytes to send
	//   idx: integer - index of the first byte in s to send
	//   sbytes: integer - number of bytes to send 
	//	(adjusted to idx and string length if too large)
	int fd;
	int n;
	const char *s;
	size_t slen;
	int idx, sbytes;

	fd = luaL_checkinteger(L, 1); // get socket fd
	s = luaL_checklstring(L, 2, &slen); // string to write
	idx = luaL_optinteger(L, 3, 1); // starting index in string
	sbytes = luaL_optinteger(L, 4, 0); // number of bytes to write
	
	if (idx > slen) {  
		luaL_error(L, "write: idx (%d) too large", idx);
	}
	if (sbytes == 0) { sbytes = slen; }
	if (idx + sbytes -1 > slen) { sbytes = slen - idx + 1; }
	n = write(fd, s+idx-1, sbytes);
	if (n < 0) {  // write error
		lua_pushnil (L);
		lua_pushfstring (L, "write error: %d  %d", n, errno);
		return 2;      
	}
	//success, return number of bytes sent
	lua_pushinteger (L, n);
	return 1;
} //ll_write

int ll_read(lua_State *L) {
	// read bytes from a socket file descriptor
	// Lua args:  
	//    socket fd: integer
	//    timeout: integer (in milliseconds)
	//		(optional - defaults to DEFAULT_TIMEOUT)
	// reads at most BUFSIZE bytes. 
	// return the bytes read as a string, or (nil, error msg) 
	// on error or timeout
	//
	int fd;
	int n;
	luaL_Buffer b;
	char buf[BUFSIZE];
	struct pollfd pfd;
	int timeout;
	int nbytes, rbytes;

	fd = luaL_checkinteger(L, 1);
	timeout = luaL_optinteger(L, 2, DEFAULT_TIMEOUT); 

	pfd.fd = fd;
	pfd.events = POLLIN;
	pfd.revents = 0;
	rbytes = 0; // total number of bytes read
	n = poll(&pfd, (nfds_t) 1, timeout);
	if (n < 0) {  // poll error
		lua_pushnil (L);
		lua_pushfstring (L, "poll error: %d  %d", n, errno);
		return 2;      
	}
	if (n == 0) { // timeout
		lua_pushnil (L);
		lua_pushfstring (L, "read timeout");
		return 2;      
	}
	n = read(fd, buf, BUFSIZE);
	if (n < 0) {  // read error
		lua_pushnil (L);
		lua_pushfstring (L, "read error: %d  %d", n, errno);
		return 2;      
	}		
	lua_pushlstring (L, (const char *)&buf, n);
	return 1;
} //ll_read

int ll_close(lua_State *L) {
	// close a socket 
	// Lua args: socket file descriptor (as integer)
	// return true on success or nil, errmsg
	int fd;
	int n;

	fd = luaL_checkinteger(L, 1); // get socket fd

	n = close(fd);
	if (n == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "close error: %d", errno);
		return 2;
	}
	//success, return true
	lua_pushboolean (L, 1);
	return 1;
} //ll_close

//----------------------------------------------------------------------
// UDP

int ll_udpsocket(lua_State *L) {
	// create a UDP socket. Optionnally bind it to an address
	// if an address is provided.
	// Lua arg: addr, the server sockaddr as a binary string. 
	// addr is optional. if addr is null or empty, an AF_INET socket 
	// is created and not bound. if addr is "\x0a", an AF_INET6 
	// socket is created and not bound. if addr length is > 1, 
	// the socket is created and bound.
	//
	// return socket file descriptor as integer or nil, errmsg
	//
	const char * addr;
	size_t addr_len;
	int sfd;
	int r;
	int family;  // AF_INET=2, AF_INET6=10
	addr = luaL_optlstring(L, 1, NULL, &addr_len);
	//~ printf("addr_len: %d \n", addr_len);
	if (addr_len == 0) {
		family = 2;
	} else {
		family = addr[0];  // first byte of sockaddr
	}
	sfd = socket(family, SOCK_DGRAM, 0); // 0 for default protocol
	if (sfd < 0) { 
		lua_pushnil (L);
		lua_pushfstring (L, "udpsocket() error %d", errno);
		return 2;      	
	}
	if (addr_len > 1) {
		// bind the socket to addr
		r = bind(sfd, (struct sockaddr *) addr, addr_len);
		if (r < 0) {
			close(sfd);
			lua_pushnil (L);
			lua_pushfstring (L, "bind error %d", errno);
			return 2;      	
		}		
	}
	// success, return socket fd
	lua_pushinteger (L, sfd);
	return 1;
} //ll_udpsocket

int ll_sendto(lua_State *L) {
	// Lua args:
	//   fd: integer - socket descriptor
	//   addr: raw address (sockaddr) of the recipient
	//   s: string to send
	int fd;
	int n;
	const char *addr;
	size_t addr_len;
	const char *s;
	size_t slen;
	int flags = 0;

	fd = luaL_checkinteger(L, 1); // get socket fd
	addr = luaL_checklstring(L, 2, &addr_len); // recipient addr
	s = luaL_checklstring(L, 3, &slen); // string to write
	if (slen > UDPMAXSIZE) {  
		luaL_error(L, "sendto: string too large %d", slen);
	}
	n = sendto(fd, s, slen, flags, 
		(const struct sockaddr *)addr, addr_len);
	if (n < 0) {  // write error
		lua_pushnil (L);
		lua_pushfstring (L, "write error: %d  %d", n, errno);
		return 2;      
	}
	//success, return number of bytes sent
	lua_pushinteger (L, n);
	return 1;
} //ll_sendto

int ll_recvfrom(lua_State *L) {
	// receive message from a socket file descriptor
	// Lua args:  
	//    socket fd: integer
	//    timeout: integer (in milliseconds)
	//		(optional - defaults to DEFAULT_TIMEOUT)
	// reads at most UDPMAXSIZE bytes. 
	// return the received message as a string, and the sender 
	// raw address (sockaddr), or (nil, error msg) on error or timeout
	//
	int fd;
	int n;
	char addr[ADDRMAXSIZE];
	size_t addr_len = ADDRMAXSIZE;
	char buf[UDPMAXSIZE];
	struct pollfd pfd;
	int timeout;
	int flags = 0;

	fd = luaL_checkinteger(L, 1);
	timeout = luaL_optinteger(L, 2, DEFAULT_TIMEOUT); 

	pfd.fd = fd;
	pfd.events = POLLIN;
	pfd.revents = 0;
	n = poll(&pfd, (nfds_t) 1, timeout);
	if (n < 0) {  // poll error
		lua_pushnil (L);
		lua_pushfstring (L, "poll error: %d  %d", n, errno);
		return 2;      
	}
	if (n == 0) { // timeout
		lua_pushnil (L);
		lua_pushfstring (L, "recvfrom timeout");
		return 2;      
	}
	n = recvfrom(fd, buf, UDPMAXSIZE, flags, 
		(struct sockaddr *)addr, (socklen_t *) &addr_len);
	if (n < 0) {  // read error
		lua_pushnil (L);
		lua_pushfstring (L, "recvfrom error: %d  %d", n, errno);
		return 2;      
	}		
	lua_pushlstring (L, (const char *)&buf, n);
	lua_pushlstring (L, (const char *)&addr, addr_len);
	return 2;	
} //ll_recvfrom




//----------------------------------------------------------------------
// socket raw address, DNS interface

int ll_getpeername(lua_State *L) {
	// get the address of the peer connected to socket fd
	// Lua args: socket file descriptor (as integer)
	// returns the raw client address as a string,  or nil, errmsg	
	int fd;
	int n;
	struct sockaddr addr;
	socklen_t len = sizeof(addr); //enough for ip4&6 addr
	
	fd = luaL_checkinteger(L, 1); // get socket fd

	n = getpeername(fd, &addr, &len);
	if (n == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "close error: %d", errno);
		return 2;
	}
	//success, return peer socket addr
	lua_pushlstring (L, (const char *)&addr, len);
	return 1;
} //ll_getpeername

int ll_getsockname(lua_State *L) {
	// get the address a socket is bound to
	// Lua args: socket file descriptor (as integer)
	// returns the raw client address as a string,  or nil, errmsg
	int fd;
	int n;
	struct sockaddr addr;
	socklen_t len = sizeof(addr); //enough for ip4&6 addr
	
	fd = luaL_checkinteger(L, 1); // get socket fd

	n = getsockname(fd, &addr, &len);
	if (n == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "close error: %d", errno);
		return 2;
	}
	//success, return socket addr
	lua_pushlstring (L, (const char *)&addr, len);
	return 1;
} //ll_getsockname

int ll_getaddrinfo(lua_State *L) {
	// get a list of addresses corresponding to a hostname and port
	const char *host, *service;
	struct addrinfo hints;
	struct addrinfo *result, *rp;	
	int sfd;
	int n;
	
	host = luaL_checkstring(L, 1);
	service = luaL_optstring(L, 2, "0");

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;	 /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_STREAM; 
	n = getaddrinfo(host, service, &hints, &result);
	if (n) {
		lua_pushnil (L);
		lua_pushfstring(L, "getaddrinfo: %d %s", n, gai_strerror(n));
		return 2;
	}
	// build the table of the returned addresses
	lua_newtable(L);
	n = 1;
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		lua_pushinteger (L, n);
		lua_pushlstring(L, (const char *)rp->ai_addr, rp->ai_addrlen);
		lua_settable(L, -3);
		n += 1;
	}	
	// free the address list
	freeaddrinfo(result);
	// return the address table
	return 1;
} //ll_getaddrinfo

#define HOSTLEN 512
#define SERVLEN 128

int ll_getnameinfo(lua_State *L) {
	// inverse of getaddrinfo(). converts a raw address into a host and port
	// port is always returned as an integer
	// Lua args:
	//   addr - a raw address (sockaddr) as returned by bind, 
	//          connect, getaddrinfo
	//   numerichost - an optional flag. set it to any true value to return
	//          host numeric address or leave it empty for a host name
	//   
	char hostname[HOSTLEN];
	char servname[SERVLEN];
	const char *addr;
	size_t addrlen;
	int numerichost;
	int n;
	addr = luaL_checklstring(L, 1, &addrlen); // raw addr (sockaddr)
	numerichost = lua_toboolean(L, 2);
	numerichost = numerichost ? NI_NUMERICHOST : 0;
	n = getnameinfo((const struct sockaddr *)addr, addrlen, 
			hostname, HOSTLEN, servname, SERVLEN, 
			(NI_NUMERICSERV | numerichost));
	if (n) {
		lua_pushnil (L);
		lua_pushfstring (L, "getnameinfo: %d %s", n, gai_strerror(n));
		return 2;
	}
	//success, return hostame and servname
	lua_pushstring(L, hostname);
	lua_pushinteger(L, atoi(servname));
	return 2;	
} //ll_getnameinfo

int ll_msleep(lua_State *L) {
	// suspend the execution of the calling thread for some time 
	// Lua args: the sleep time in milliseconds as an integer
	// return value: true on success, or nil, errmsg
	//   
	int n;
	long ms = luaL_checkinteger(L, 1); // sleep time in milliseconds
	struct timespec req;
	req.tv_sec = ms / 1000;
	req.tv_nsec = (ms % 1000) * 1000000;
	n = nanosleep(&req, NULL);
	if (n == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "nanosleep error: %d", errno);
		return 2;
	}
	//success, return true
	lua_pushboolean (L, 1);
	return 1;
} //ll_msleep


// ---------------------------------------------------------------------
// Lua library function

static const struct luaL_Reg minisocklib[] = {
	// tcp/unix
	{"bind", ll_bind},
	{"accept", ll_accept},
	{"connect", ll_connect},
	{"write", ll_write},
	{"read", ll_read},
	{"close", ll_close},
	// udp
	{"udpsocket", ll_udpsocket},
	{"sendto", ll_sendto},
	{"recvfrom", ll_recvfrom},
	// info
	{"getsockname", ll_getsockname},
	{"getpeername", ll_getpeername},
	{"getaddrinfo", ll_getaddrinfo},
	{"getnameinfo", ll_getnameinfo},
	// misc
	{"msleep", ll_msleep},
	
	{NULL, NULL},
};


int luaopen_minisock (lua_State *L) {
	luaL_newlib (L, minisocklib);
	// 
	lua_pushliteral (L, "VERSION");
	lua_pushliteral (L, ll_VERSION); 
	lua_settable (L, -3);
	lua_pushliteral (L, "BUFSIZE");
	lua_pushinteger (L, BUFSIZE); 
	lua_settable (L, -3);
	lua_pushliteral (L, "UDPMAXSIZE");
	lua_pushinteger (L, UDPMAXSIZE); 
	lua_settable (L, -3);
	//
	return 1;
	}

