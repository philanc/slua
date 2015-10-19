// Copyright (c) 2015  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/* tweetnacl

A binding to the wonderful NaCl crypto library by Dan Bernstein et al.
The version included here is the "Tweet" version ("NaCl in 100 tweets")
by Dan Bernstein


150721
	split luazen and tweetnacl.  
	nacl lua interface is in this file (luatweetnacl.c)

*/

#define TWEETNACL_VERSION "tweetnacl-0.1"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "tweetnacl.h"


//=========================================================
// compatibility with Lua 5.2  --and lua 5.3, added 150621
// (from roberto's lpeg 0.10.1 dated 101203)
//
#if (LUA_VERSION_NUM >= 502)

#undef lua_equal
#define lua_equal(L,idx1,idx2)  lua_compare(L,(idx1),(idx2),LUA_OPEQ)

#undef lua_getfenv
#define lua_getfenv	lua_getuservalue
#undef lua_setfenv
#define lua_setfenv	lua_setuservalue

#undef lua_objlen
#define lua_objlen	lua_rawlen

#undef luaL_register
#define luaL_register(L,n,f) \
	{ if ((n) == NULL) luaL_setfuncs(L,f,0); else luaL_newlib(L,f); }

#endif
//=========================================================


//------------------------------------------------------------
// nacl functions (the "tweetnacl version")

extern void randombytes(unsigned char *x,unsigned long long xlen); 


static int luazen_randombytes(lua_State *L)
{
	
    size_t bufln; 
	lua_Integer li = luaL_checkinteger(L, 1);  // 1st arg
	bufln = (size_t) li;
    unsigned char *buf = malloc(bufln); 
	randombytes(buf, li);
    lua_pushlstring (L, buf, bufln); 
    free(buf);
	return 1;
}

static int luazen_box_keypair(lua_State *L)
{
	unsigned char pk[crypto_box_PUBLICKEYBYTES];
	unsigned char sk[crypto_box_SECRETKEYBYTES];
	int r = crypto_box_keypair(pk, sk);
	lua_pushlstring (L, pk, crypto_box_PUBLICKEYBYTES); 
	lua_pushlstring (L, sk, crypto_box_SECRETKEYBYTES); 
	return 2;
}

static int luazen_box(lua_State *L)
{
	int r = 0;
	size_t mln;
	const char *m=luaL_checklstring(L,1,&mln);	
	size_t nln;
	const char *n=luaL_checklstring(L,2,&nln);	
	size_t pkln;
	const char *pk=luaL_checklstring(L,3,&pkln);	
	size_t skln;
	const char *sk=luaL_checklstring(L,4,&skln);	
	if (mln <= crypto_box_ZEROBYTES) { r = 101 ; goto error; }
	if (nln != crypto_box_NONCEBYTES) { r = 102 ; goto error; }
	if (pkln != crypto_box_PUBLICKEYBYTES) { r = 103 ; goto error; }
	if (skln != crypto_box_SECRETKEYBYTES) { r = 104 ; goto error; }
	unsigned char * buf = malloc(mln);
	r = crypto_box(buf, m, mln, n, pk, sk);
	if (r != 0) { free(buf); goto error; } 
	lua_pushlstring (L, buf, mln); 
	free(buf);
	return 1;

	error:
    lua_pushnil (L);
	lua_pushfstring (L, "nacl: box_open error %d", r);
	return 2;         
}// box()

static int luazen_box_open(lua_State *L)
{
	int r = 0;
	char * msg = "box_open: argument error";
	size_t cln;
	const char *c=luaL_checklstring(L,1,&cln);	
	size_t nln;
	const char *n=luaL_checklstring(L,2,&nln);	
	size_t pkln;
	const char *pk=luaL_checklstring(L,3,&pkln);	
	size_t skln;
	const char *sk=luaL_checklstring(L,4,&skln);	
	if (cln <= crypto_box_ZEROBYTES) { r = 101 ; goto error; }
	if (nln != crypto_box_NONCEBYTES) { r = 102 ; goto error; }
	if (pkln != crypto_box_PUBLICKEYBYTES) { r = 103 ; goto error; }
	if (skln != crypto_box_SECRETKEYBYTES) { r = 104 ; goto error; }
	unsigned char * buf = malloc(cln);
	r = crypto_box_open(buf, c, cln, n, pk, sk);
	if (r != 0) { 
		free(buf); 
		msg = "box_open: integrity error";
		goto error; 
	} 
	lua_pushlstring (L, buf, cln); 
	free(buf);
	return 1;

	error:
    lua_pushnil (L);
	lua_pushinteger (L, (lua_Integer) r);
	lua_pushstring(L, msg);
	return 3;         
} // box_open()


static int luazen_sha512(lua_State *L) {
    size_t sln; 
    const char *src = luaL_checklstring (L, 1, &sln);
    char digest[64];
	crypto_hash(digest, (const unsigned char *) src, (unsigned long long) sln);  
    lua_pushlstring (L, digest, 64); 
    return 1;
}


//------------------------------------------------------------
// (pk) encrypt, decrypt easier functions


static int luazen_pkencrypt(lua_State *L)
{
	//arguments:
	//  1.  clrtxt msg
	//  2.  pk
	//  3.  sk
	//
	int r = 0;
	// get arguments
	size_t mln;
	const char *m=luaL_checklstring(L,1,&mln);	
    // get the pk, sk 
	size_t pkln;
	const char *pk=luaL_checklstring(L,2,&pkln);	
	size_t skln;
	const char *sk=luaL_checklstring(L,3,&skln);	
	if (pkln != crypto_box_PUBLICKEYBYTES) { r = 103 ; goto error; }
	if (skln != crypto_box_SECRETKEYBYTES) { r = 104 ; goto error; }	
	// create the src buffer
	size_t mbufln = crypto_box_ZEROBYTES + mln;
	unsigned char * mbuf = malloc(mbufln);
	// add the zero bytes required by box()
	int i;
	for (i = 0; i < crypto_box_ZEROBYTES; i++) { mbuf[i] = 0; } 
	// append the msg to the buffer
	for (i = 0; i < mln; i++) { mbuf[crypto_box_ZEROBYTES + i] = m[i]; } 

	// create the dest buffer
	size_t bufln = crypto_box_NONCEBYTES + mbufln;
	unsigned char * buf = malloc(bufln);
	// create a random nonce, put it at the beginning of the dest buffer
	randombytes(buf, crypto_box_NONCEBYTES);
	// now encrypt 
	r = crypto_box(buf+crypto_box_NONCEBYTES, mbuf, mbufln, buf, pk, sk);
	if (r != 0) { 
		free(buf); 
		goto error; 
	} 
	lua_pushlstring (L, buf, bufln); 
	free(mbuf); 
	free(buf);
	return 1;
	//
	error:
	free(mbuf); 
    lua_pushnil (L);
	lua_pushfstring (L, "pkencrypt error %d", r);
	return 2;         
}// pkencrypt()

static int luazen_pkdecrypt(lua_State *L)
{
	int r = 0;
	char * msg = "pkdecrypt: argument error";
	size_t cln;
	const char *c=luaL_checklstring(L,1,&cln);	
	size_t pkln;
	const char *pk=luaL_checklstring(L,2,&pkln);	
	size_t skln;
	const char *sk=luaL_checklstring(L,3,&skln);	
	if (cln <= crypto_box_ZEROBYTES + crypto_box_NONCEBYTES) { 
		r = 101 ; goto error; 
	}
	if (pkln != crypto_box_PUBLICKEYBYTES) { r = 103 ; goto error; }
	if (skln != crypto_box_SECRETKEYBYTES) { r = 104 ; goto error; }
	unsigned char * buf = malloc(cln);
	size_t nln = crypto_box_NONCEBYTES;
	// here, c :: nonce, c+nln :: encr msg
	r = crypto_box_open(buf, c+nln, cln-nln, c, pk, sk);
	if (r != 0) { 
		free(buf); 
		msg = "pkdecrypt: integrity error";
		goto error; 
	} 
	lua_pushlstring (L, buf+crypto_box_ZEROBYTES, cln-nln-crypto_box_ZEROBYTES); 
	free(buf);
	return 1;
	//
	error:
    lua_pushnil (L);
	lua_pushinteger (L, (lua_Integer) r);
	lua_pushstring(L, msg);
	return 3;         
} // pkdecrypt()

static int luazen_pkecdh(lua_State *L)
{
	//arguments:
	//  1.  pk (32 bytes)
	//  2.  sk (32 bytes)
	//  returns  k
	//
	int r = 0;
	// get arguments
    // get the pk, sk 
	size_t pkln;
	const char *pk=luaL_checklstring(L,1,&pkln);	
	size_t skln;
	const char *sk=luaL_checklstring(L,2,&skln);	
	if (pkln != crypto_box_PUBLICKEYBYTES) { r = 301 ; goto error; }
	if (skln != crypto_box_SECRETKEYBYTES) { r = 302 ; goto error; }	
	// create the key buffer
	size_t bufln = crypto_box_BEFORENMBYTES;
	unsigned char * buf = malloc(bufln);
	// compute the key
	r = crypto_box_beforenm(buf, pk, sk);
	if (r != 0) { 
		free(buf); 
		goto error; 
	} 
	lua_pushlstring (L, buf, bufln); 
	free(buf);
	return 1;
	//
	error:
    lua_pushnil (L);
	lua_pushfstring (L, "pkecdh error %d", r);
	return 2;         
}// pkecdh()

//------------------------------------------------------------
// secret key encryption

static int luazen_encrypt(lua_State *L)
{
	//arguments:
	//  1.  clrtxt msg
	//  2.  key (must be 32 bytes)
	//  returns encrypted msg
	//
	int r = 0;
	// get arguments
	size_t mln;
	const char *m=luaL_checklstring(L,1,&mln);	
    // get the key
	size_t kln;
	const char *k=luaL_checklstring(L,2,&kln);	
	if (kln != crypto_box_BEFORENMBYTES) { r = 202 ; goto error; }	
	
	// create the src buffer
	size_t mbufln = crypto_box_ZEROBYTES + mln;
	unsigned char * mbuf = malloc(mbufln);
	// add the zero bytes required by box()
	int i;
	for (i = 0; i < crypto_box_ZEROBYTES; i++) { mbuf[i] = 0; } 
	// append the msg to the buffer
	for (i = 0; i < mln; i++) { mbuf[crypto_box_ZEROBYTES + i] = m[i]; } 

	// create the dest buffer
	size_t bufln = crypto_box_NONCEBYTES + mbufln;
	unsigned char * buf = malloc(bufln);
	
	// check if an explicit nonce has been given. Else generate a random nonce.
	// any optional 3rd argument? (would be a nonce)
	if ( !lua_isnoneornil(L, 3) ) {  	
		size_t optln;
		const char * optnonce = luaL_checklstring(L,3,&optln);
		if (optln != crypto_box_NONCEBYTES) { r = 203 ; goto error; }	
		// copy the nonce at beginning of buf
			for (i = 0; i < optln; i++) { buf[i] = optnonce[i]; } 
	}	else {  
		// no nonce provided
		// create a random nonce, put it at the beginning of the dest buffer
		randombytes(buf, crypto_box_NONCEBYTES);
	}
	// now encrypt 
	r = crypto_box_afternm(buf+crypto_box_NONCEBYTES, mbuf, mbufln, buf, k);
	if (r != 0) { 
		free(buf); 
		goto error; 
	} 
	lua_pushlstring (L, buf, bufln); 
	free(mbuf); 
	free(buf);
	return 1;
	//
	error:
	free(mbuf); 
    lua_pushnil (L);
	lua_pushfstring (L, "encrypt error %d", r);
	return 2;         
}// encrypt()

static int luazen_decrypt(lua_State *L)
{
	int r = 0;
	char * msg = "decrypt: argument error";
	// get arguments
	// 1. encrypted text
	// 2. key (32 bytes)
	size_t cln;
	const char *c=luaL_checklstring(L,1,&cln);	
	size_t kln;
	const char *k=luaL_checklstring(L,2,&kln);	
	if (cln <= crypto_box_ZEROBYTES + crypto_box_NONCEBYTES) { 
		r = 101 ; goto error; 
	}
	if (kln != crypto_box_BEFORENMBYTES) { r = 202 ; goto error; }
	unsigned char * buf = malloc(cln);
	size_t nln = crypto_box_NONCEBYTES;
	// here, c :: nonce, c+nln :: encr msg
	r = crypto_box_open_afternm(buf, c+nln, cln-nln, c, k);
	if (r != 0) { 
		free(buf); 
		msg = "decrypt: integrity error";
		goto error; 
	} 
	lua_pushlstring (L, buf+crypto_box_ZEROBYTES, cln-nln-crypto_box_ZEROBYTES); 
	free(buf);
	return 1;
	//
	error:
    lua_pushnil (L);
	lua_pushinteger (L, (lua_Integer) r);
	lua_pushstring(L, msg);
	return 3;         
} // decrypt()

//
//------------------------------------------------------------
// lzo compress, decompress

//  tried 100904. compression significantly worse than zlib
//	eg. 117k vs 86k ...

//------------------------------------------------------------
// lua library declaration
//
static const struct luaL_Reg tweetnacllib[] = {
	// nacl functions
	{"randombytes", luazen_randombytes},
	{"box", luazen_box},
	{"box_open", luazen_box_open},
	{"box_keypair", luazen_box_keypair},
	//~ {"box_beforenm", luazen_box_beforenm},
	//~ {"box_afternm", luazen_box_afternm},
	//~ {"box_open_afternm", luazen_box_open_afternm},
	{"sha512", luazen_sha512},
	
	// convenience functions
	{"pkencrypt", luazen_pkencrypt},
	{"pkdecrypt", luazen_pkdecrypt},
	{"pkecdh", luazen_pkecdh},
	{"encrypt", luazen_encrypt},
	{"decrypt", luazen_decrypt},
	
	{NULL, NULL},
};

int luaopen_tweetnacl (lua_State *L) {
	luaL_register (L, "tweetnacl", tweetnacllib);
    // 
    lua_pushliteral (L, "_VERSION");
	lua_pushliteral (L, TWEETNACL_VERSION); 
	lua_settable (L, -3);
	return 1;
}

