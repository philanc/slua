// Copyright (c) 2015  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/* 

mtcp - A minimal Lua socket library for tcp connections

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

The sockaddr structure, returned as a string by getpeername, getsockname,
bind, accept and connect (second return value), is the raw, binary value.
It can be parsed by getnameinfo.

It can also easily be parsed with string.unpack:  eg. for a IPv4 address:
  family, port, ip1, ip2, ip3, ip4 = string.unpack("<H>HBBBB", addr)
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

// for mtcp_msleep()
#include <time.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

// ---------------------------------------------------------------------
#define MTCP_VERSION "0.2"
#define BUFSIZE 1024
#define BACKLOG 32

// default timeout: 10 seconds
#define DEFAULT_TIMEOUT 10000


int mtcp_bind(lua_State *L) {
	// create a server socket, bind, then listen 
	// Lua args: host, service (as strings)
	// returns server socket file descriptor (as integer) and
	// the raw host address as a string,  or nil, errmsg
	const char *host, *service;
	struct addrinfo hints;
	struct addrinfo *result, *rp;	
	int sfd;
	int n;
	
	host = luaL_checkstring(L, 1);
	service = luaL_checkstring(L, 2);

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;	 /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_STREAM; 
	n = getaddrinfo(host, service, &hints, &result);
	if (n) {luaL_error(L, "getaddrinfo (%s) %s", host, gai_strerror(n));}
	
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		sfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
		if (sfd == -1) { continue; }
		n = bind(sfd, rp->ai_addr, rp->ai_addrlen);
		if (n == 0) break;
		close(sfd);
	}	
	if (rp == NULL) {  /* No address succeeded */
		lua_pushnil (L);
		lua_pushfstring (L, "bind error: %d  %d", n, errno);
		return 2;      
	}
	n = listen(sfd, BACKLOG);
	if (n) {
		lua_pushnil (L);
		lua_pushfstring (L, "listen error: %d  %d", n, errno);
		return 2;      
	}
	// success, return server socket fd
	lua_pushinteger (L, sfd);
	lua_pushlstring(L, (const char *)rp->ai_addr, rp->ai_addrlen);
	return 2;
} //mtcp_bind

int mtcp_accept(lua_State *L) {
	// accept incoming connections on a server socket 
	// Lua args: server socket file descriptor (as integer)
	// returns client socket file descriptor (as integer) and
	// the raw client address as a string,  or nil, errmsg
	int cfd, sfd;
	struct sockaddr_storage addr;
	socklen_t len = sizeof(addr); //enough for ip4&6 addr

	sfd = luaL_checkinteger(L, 1); // get server socket fd

	cfd = accept(sfd, (struct sockaddr *)&addr, &len);
	if (cfd == -1) {
		lua_pushnil (L);
		lua_pushfstring (L, "accept error: %d", errno);
		return 2;
	}
	//success, return client socket fd
	lua_pushinteger (L, cfd);
	lua_pushlstring(L, (const char *)&addr, len);
	return 2;
} //mtcp_accept


int mtcp_connect(lua_State *L) {
	// connect to a host
	// Lua args: host, service or port (as strings)
	// returns connection socket fd (as integer) and host raw address 
	// as a string, or nil, errmsg
	const char *host, *service;
	struct addrinfo hints;
	struct addrinfo *result, *rp;	
	int cfd;
	int n;
	
	host = luaL_checkstring(L, 1);
	service = luaL_checkstring(L, 2);

	/* Obtain address(es) matching host/port */
	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;       /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_STREAM; 
	n = getaddrinfo(host, service, &hints, &result);
	if (n) {
		luaL_error(L, "getaddrinfo (%s) %s", host, gai_strerror(n));
	}
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		cfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
		if (cfd == -1) { continue; }
		n = connect(cfd, rp->ai_addr, rp->ai_addrlen);
		if (n == 0) break;
		close(cfd);
	}	
	if (rp == NULL) {  /* No address succeeded */
		lua_pushnil (L);
		lua_pushfstring (L, "connect error: %d  %d", n, errno);
		return 2;      
	}
	//success, return connection socket fd
	lua_pushinteger (L, cfd);
	lua_pushlstring(L, (const char *)rp->ai_addr, rp->ai_addrlen);
	return 2;
} //mtcp_connect

int mtcp_write(lua_State *L) {
	// Lua args:
	//   fd: integer - socket descriptor
	//   s: string - string to send
	//   idx: integer - 
	//   sbytes: integer - number of bytes to send 
	//		(adjusted to idx and string length if too large)
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
} //mtcp_write

int mtcp_read(lua_State *L) {
	// read bytes from a socket file descriptor
	// Lua args:  
	//    socket fd: integer
	//    nbytes: integer - max number of bytes to read 
	//              (optional - defaults to BUFSIZE)
	//    timeout: integer (in milliseconds)
	//				(optional - defaults to DEFAULT_TIMEOUT)
	// reading stops on error, on timeout, when at least nbytes bytes 
	// have been read, or when last read() returned less than BUFSIZE.
	//
	int fd;
	int n;
	luaL_Buffer b;
	char buf[BUFSIZE];
	struct pollfd pfd;
	int timeout;
	int nbytes, rbytes;

	fd = luaL_checkinteger(L, 1);
	nbytes = luaL_optinteger(L, 2, BUFSIZE); 
	timeout = luaL_optinteger(L, 3, DEFAULT_TIMEOUT); 

	luaL_buffinit(L,&b);
	pfd.fd = fd;
	pfd.events = POLLIN;
	pfd.revents = 0;
	rbytes = 0; // total number of bytes read
	while(1) {
		n = poll(&pfd, (nfds_t) 1, timeout);
		if (n < 0) {  // poll error
			lua_pushnil (L);
			lua_pushfstring (L, "poll error: %d  %d", n, errno);
			return 2;      
		}
		if (n == 0) { // poll timeout
			lua_pushnil (L);
			lua_pushfstring (L, "poll timeout");
			return 2;      
		}
		n = read(fd, buf, BUFSIZE);
		if (n == 0) { // nothing read
			break;
		}
		if (n < 0) {  // read error
			lua_pushnil (L);
			lua_pushfstring (L, "read error: %d  %d", n, errno);
			return 2;      
		}		
		luaL_addlstring(&b, buf, n);
		rbytes += n;
		if (n < BUFSIZE) break;
		if (rbytes >= nbytes) break;
	}
	//success, return read bytes
	luaL_pushresult(&b);
	return 1;
} //mtcp_read

int mtcp_close(lua_State *L) {
	// close a socket 
	// Lua args: socket file descriptor (as integer)
	// returns true on success or nil, errmsg
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
} //mtcp_close

int mtcp_getpeername(lua_State *L) {
	// get the address the peer a socket is connected to
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
} //mtcp_getpeername

int mtcp_getsockname(lua_State *L) {
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
} //mtcp_getsockname

int mtcp_getaddrinfo(lua_State *L) {
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
		lua_pushfstring (L, "getaddrinfo: %d %s", n, gai_strerror(n));
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
	// return the address table
	return 1;
} //mtcp_getaddrinfo

#define HOSTLEN 512
#define SERVLEN 128

int mtcp_getnameinfo(lua_State *L) {
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
	int addrlen;
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
} //mtcp_getnameinfo

int mtcp_msleep(lua_State *L) {
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
	//success, return socket addr
	lua_pushboolean (L, 1);
	return 1;
} //mtcp_msleep


// ---------------------------------------------------------------------
// Lua library function

static const struct luaL_Reg mtcplib[] = {
	{"bind", mtcp_bind},
	{"accept", mtcp_accept},
	{"connect", mtcp_connect},
	{"write", mtcp_write},
	{"read", mtcp_read},
	{"close", mtcp_close},
	{"getsockname", mtcp_getsockname},
	{"getpeername", mtcp_getpeername},
	{"getaddrinfo", mtcp_getaddrinfo},
	{"getnameinfo", mtcp_getnameinfo},
	{"msleep", mtcp_msleep},
	
	{NULL, NULL},
};


int luaopen_mtcp (lua_State *L) {
	luaL_newlib (L, mtcplib);
    // 
    lua_pushliteral (L, "VERSION");
	lua_pushliteral (L, MTCP_VERSION); 
	lua_settable (L, -3);
    lua_pushliteral (L, "BUFSIZE");
	lua_pushinteger (L, BUFSIZE); 
	lua_settable (L, -3);
	return 1;
}

