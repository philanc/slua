/*
 * Copyright (c) 2011 - 2014, Micro Systems Marc Balmer, CH-5073 Gipf-Oberfrick
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Micro Systems Marc Balmer nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* network access extension module  */

#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#ifdef LIBFETCH
#include <fetch.h>
#endif
#include <netdb.h>
#include <poll.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "luanet.h"

static int
asread(int fd, char **ret, int ms)
{
	struct pollfd p;
	int r, n;
	size_t len, nread;
	char *s;

	p.fd = fd;
	p.events = POLLIN;
	p.revents = 0;

	*ret = malloc(NET_BUFSIZ);
	if (*ret == NULL)
		return -1;
	len = NET_BUFSIZ;
	nread = 0;
	s = *ret;
	do {
		n = 0;
		r = poll(&p, 1, ms);
		switch (r) {
		case 0:
			fprintf(stderr, "poll timeout\n");
			break;
		case -1:
			fprintf(stderr, "poll error\n");
			break;
		default:
			if (len - nread > 0) {
				n = read(fd, s, len - nread);
				nread += n;
				s += n;
			} else {
				len *= 2;
				*ret = realloc(*ret, len);
				if (*ret == NULL)
					fprintf(stderr, "memory error\n");
				s = *ret + nread;
				n = 1;
			}
		}
	} while (n > 0);
	(*ret)[nread] = '\0';
	return nread;
}

/* XXX factor out common code */
static int
asreadln(int fd, char **ret, int ms)
{
	struct pollfd p;
	int r, n;
	size_t len, nread;
	char *s;

	p.fd = fd;
	p.events = POLLIN;
	p.revents = 0;

	*ret = malloc(NET_BUFSIZ);
	if (*ret == NULL)
		return -1;
	len = NET_BUFSIZ;
	nread = 0;
	s = *ret;
	do {
		n = 0;
		r = poll(&p, 1, ms);
		switch (r) {
		case 0:
			fprintf(stderr, "poll timeout\n");
			break;
		case -1:
			fprintf(stderr, "poll error\n");
			break;
		default:
			if (len - nread > 0) {
				n = read(fd, s, len - nread);
				nread += n;
				s += n;
			} else {
				len *= 2;
				*ret = realloc(*ret, len);
				if (*ret == NULL)
					fprintf(stderr, "memory error\n");
				s = *ret + nread;
				n = 1;
			}
		}
	} while (n > 0 && (*ret)[nread - 1] != '\n');
	(*ret)[nread] = '\0';
	return nread;
}

static int
luanet_accept(lua_State *L)
{
	struct sockaddr_storage addr;
	socklen_t len = sizeof(addr);
	int s, *data;

	s = accept(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE),
	    (struct sockaddr *)&addr, &len);
	if (s == -1) {
		lua_pushnil(L);
		return 1;
	}
	data = (int *)lua_newuserdata(L, sizeof(int *));
	*data = s;
	luaL_getmetatable(L, SOCKET_METATABLE);
	lua_setmetatable(L, -2);
	return 1;
}

static int
luanet_bind(lua_State *L)
{
	struct addrinfo hints, *res, *res0;
	int fd, error, *data;
	char hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
	const char *port, *host;

	host = luaL_checkstring(L, 1);
	port = luaL_checkstring(L, 2);

	memset(&hints, 0, sizeof(hints));
	hints.ai_socktype = SOCK_STREAM;
	error = getaddrinfo(host, port, &hints, &res0);
	if (error) {
		fprintf(stderr, "%s: %s\n", host, gai_strerror(error));
		return -1;
	}
	fd = -1;
	for (res = res0; res; res = res->ai_next) {
		error = getnameinfo(res->ai_addr, res->ai_addrlen, hbuf,
		    sizeof(hbuf), sbuf, sizeof(sbuf), NI_NUMERICHOST |
		    NI_NUMERICSERV);
		if (error)
			continue;
		fd = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol);
		if (fd < 0)
			continue;
		if (bind(fd, res->ai_addr, res->ai_addrlen) < 0) {
			close(fd);
			fd = -1;
			continue;
		}
		break;
	}

	if (fd < 0)
		return luaL_error(L, "connection error");

	if (listen(fd, lua_gettop(L) > 1 ? luaL_checkinteger(L, 2) : 32))
		return luaL_error(L, "listen error");

	data = (int *)lua_newuserdata(L, sizeof(int *));
	*data = fd;
	luaL_getmetatable(L, SOCKET_METATABLE);
	lua_setmetatable(L, -2);

	return 1;
}

static int
luanet_connect(lua_State *L)
{
	struct addrinfo hints, *res, *res0;
	int fd, error, *data;
	char hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
	const char *port, *host;

	host = luaL_checkstring(L, 1);
	port = luaL_checkstring(L, 2);

	memset(&hints, 0, sizeof(hints));
	hints.ai_socktype = SOCK_STREAM;
	error = getaddrinfo(host, port, &hints, &res0);
	if (error) {
		fprintf(stderr, "%s: %s\n", host, gai_strerror(error));
		return -1;
	}
	fd = -1;
	for (res = res0; res; res = res->ai_next) {
		error = getnameinfo(res->ai_addr, res->ai_addrlen, hbuf,
		    sizeof(hbuf), sbuf, sizeof(sbuf), NI_NUMERICHOST |
		    NI_NUMERICSERV);
		if (error)
			continue;
		fd = socket(res->ai_family, res->ai_socktype,
		    res->ai_protocol);
		if (fd < 0)
			continue;
		if (connect(fd, res->ai_addr, res->ai_addrlen) < 0) {
			close(fd);
			fd = -1;
			continue;
		}
		break;
	}

	if (fd < 0)
		return luaL_error(L, "connection error");
	else {
		data = (int *)lua_newuserdata(L, sizeof(int *));
		*data = fd;
		luaL_getmetatable(L, SOCKET_METATABLE);
		lua_setmetatable(L, -2);
	}
	return 1;
}

static int
luanet_printf(int fd, const char *fmt, ...)
{
	va_list ap;
	int len, nwritten;
	char *text;

	va_start(ap, fmt);
	len = vasprintf(&text, fmt, ap);
	va_end(ap);
	if (len == -1) {
		fprintf(stderr, "vasprintf failed");
		return -1;
	}

	nwritten = write(fd, text, len);
	free(text);
	return nwritten;
}

static int
luanet_print(lua_State *L)
{
	const char *p;

	p = luaL_checkstring(L, 2);
	if (luanet_printf(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE),
	    "%s\n", p) < 0)
		return luaL_error(L, "error printing data");
	return 0;
}

static int
luanet_read(lua_State *L)
{
	size_t len;
	int timeout_ms;
	char *buf;

	if (lua_gettop(L) == 2)
		timeout_ms = luaL_checkinteger(L, 2);
	else
		timeout_ms = -1;

	len = asread(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE),
	    &buf, timeout_ms);
	if (len > 0)
		lua_pushstring(L, buf);
	else
		lua_pushnil(L);
	free(buf);
	return 1;
}

static int
luanet_readln(lua_State *L)
{
	size_t len;
	int timeout_ms;
	char *buf;

	if (lua_gettop(L) == 2)
		timeout_ms = luaL_checkinteger(L, 2);
	else
		timeout_ms = -1;

	len = asreadln(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE),
	    &buf, timeout_ms);
	if (len > 0)
		lua_pushstring(L, buf);
	else
		lua_pushnil(L);
	free(buf);
	return 1;
}

static int
luanet_socket(lua_State *L)
{
	lua_pushinteger(L, *(int *)luaL_checkudata(L, 1, SOCKET_METATABLE));
	return 1;
}

static int
luanet_write(lua_State *L)
{
	size_t len;
	const char *p;

	p = luaL_checklstring(L, 2, &len);
	if (write(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE), p, len)
	    != len)
		return luaL_error(L, "error writing data");
	return 0;
}

static int
luanet_close(lua_State *L)
{
	close(*(int *)luaL_checkudata(L, 1, SOCKET_METATABLE));
	return 0;
}

static int
luanet_clear(lua_State *L)
{
	int *fd;

	fd = luaL_checkudata(L, 1, SOCKET_METATABLE);
	if (*fd >= 0)  {
		close(*fd);
		*fd = -1;
	}
	return 0;
}

static void
set_info(lua_State *L)
{
	lua_pushliteral(L, "_COPYRIGHT");
	lua_pushliteral(L, "Copyright (C) 2012, 2013, 2014 by "
	    "micro systems marc balmer");
	lua_settable(L, -3);
	lua_pushliteral(L, "_DESCRIPTION");
	lua_pushliteral(L, "network access for Lua");
	lua_settable(L, -3);
	lua_pushliteral(L, "_VERSION");
	lua_pushliteral(L, "net 1.1.1");
	lua_settable(L, -3);
}

int
luaopen_luanet(lua_State *L)
{
	struct luaL_Reg net_methods[] = {
		{ "bind",	luanet_bind },
		{ "connect",	luanet_connect },
		{ NULL, NULL }
	};

	struct luaL_Reg socket_methods[] = {
		{ "accept",	luanet_accept },
		{ "close",	luanet_close },
		{ "print",	luanet_print },
		{ "read",	luanet_read },
		{ "readln",	luanet_readln },
		{ "socket",	luanet_socket },
		{ "write",	luanet_write },
		{ NULL, NULL }
	};

	if (luaL_newmetatable(L, SOCKET_METATABLE)) {
#if LUA_VERSION_NUM >= 502
		luaL_setfuncs(L, socket_methods, 0);
#else
		luaL_register(L, NULL, socket_methods);
#endif
		lua_pushliteral(L, "__gc");
		lua_pushcfunction(L, luanet_clear);
		lua_settable(L, -3);

		lua_pushliteral(L, "__index");
		lua_pushvalue(L, -2);
		lua_settable(L, -3);

		//~ lua_pushliteral(L, "__metatable");
		//~ lua_pushliteral(L, "must not access this metatable");
		//~ lua_settable(L, -3);
	}
	lua_pop(L, 1);

#if LUA_VERSION_NUM >= 502
	luaL_newlib(L, net_methods);
#else
	luaL_register(L, "net", net_methods);
#endif
	set_info(L);
	return 1;
}
