

### tweetnacl

This is a binding to the wonderful NaCl crypto library by 
Dan Bernstein, Tanja Lange et al. -- http://nacl.cr.yp.to/

The version included here is the "Tweet" version ("NaCl in 100 tweets")
by Dan Bernstein et al. --  http://tweetnacl.cr.yp.to/index.html 
(all the tweet nacl code is included in this library.

To understand the NaCl specs, the reader is referred to the NaCl specs at http://nacl.cr.yp.to/.  This binding is very thin and should be easy
to use for anybody knowing NaCl. 

Usage in Lua programs:
```
randombytes(n)
	return a string containing n random bytes

box_keypair()
	generate a curve25519 keypair to be used with box()
	return publickey, secretkey

box_getpk(sk)
	return the public key associated to secret key sk
	sk must be 32 bytes
	Note: this function is not in NaCl but may be useful in some 
	contexts. Actually, 
		pk, sk = keypair()
	is trictly equivalent to:
		sk = randombytes(32); pk = box_getpk(sk)

box(plain, nonce, bpk, ask)
	plain is the plain text that Alice encrypts for Bob
	plain MUST start with 32 null bytes
	nonce is 24 bytes (must be different for each encryption)
	bpk (32 bytes):  Bob's public key 
	ask (32 bytes):  Alice's secret key
	return the encrypted text or (nil, error msg)
	--
	the box() and box_open functions perfor the following steps:
	- generate a session key common to Alice and Bob with a 
	  Diffie-Hellman based on the elliptic curve 25519 scalar multiplication
	- authenticated en(de)cryption with Salsa20 stream encryption
	  and Poly1305 MAC using the session key
	(see http://nacl.cr.yp.to/ for details and rationale!)

box_open(encr, nonce, apk, bsk)
	decrypt the text encrypted by Alice for Bob
	nonce is 24 bytes (must be the nonce used for encryption)
	apk (32 bytes):  Alice's public key 
	bsk (32 bytes):  Bob's secret key
	return the decrypted text or (nil, error msg)

box_beforenm(bpk, ask)
	perform the 1st step of box()
	return a session key (32 bytes) derived from bpk and ask
	bpk and ask are 32-byte strings.

box_stream_key() is an alias of box_beforenm()
box_afternm() is an alias of secretbox()
box_afternm_open() is an alias of secretbox_open()
		
secretbox()

secretbox_open()

stream()

stream_xor()

onetimeauth()

poly1305() is an alias of onetimeauth()

hash()

sha512() is an alias of hash()

sign()

sign_open()

sign_keypair()


```

	

