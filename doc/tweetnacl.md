

### tweetnacl

This is a binding to the wonderful NaCl crypto library by 
Dan Bernstein, Tanja Lange et al. -- http://nacl.cr.yp.to/

The version included here is the "Tweet" version ("NaCl in 100 tweets")
by Dan Bernstein et al. --  http://tweetnacl.cr.yp.to/index.html 
(all the tweet nacl code is included in this library.

To understand the NaCl specs, the reader is referred to the NaCl specs at http://nacl.cr.yp.to/.  This binding is very thin and should be easy
to use for anybody knowing NaCl. 

On the other hand, the binding does not include convenience functions (eg, for dealing with the "32-byte null prefix" and other API specificity). Convenience functions are expected to be implemented in Lua (or maybe in this library in the future)


Functions:
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
	is strictly equivalent to:
		sk = randombytes(32); pk = box_getpk(sk)

box(plain, nonce, bpk, ask)
	plain is the plain text that Alice encrypts for Bob
	plain MUST start with 32 null bytes, ie. ('\0'):rep(32)
	nonce is 24 bytes (must be different for each encryption)
	bpk (32 bytes):  Bob's public key 
	ask (32 bytes):  Alice's secret key
	return the encrypted text or (nil, error msg)
	--
	the box() and box_open functions perform the following steps:
	- generate a session key common to Alice and Bob with a 
	  Diffie-Hellman based on the elliptic curve 25519 scalar multiplication
	- authenticated en(de)cryption with Salsa20 stream encryption
	  and Poly1305 MAC generation/verification using the session key
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
		
secretbox(plain, n, k)
	encrypt plain string with key k and nonce n
	plain MUST start with 32 null bytes
	k: a 32-byte string
	n: a 24-byte nonce
	return the encrypted text
	example: to encrypt string 'abc'  with key 'kkk...' and nonce 'nnn...':
	   e = secretbox(('\0'):rep32)..'abc', ('n'):rep(24), ('k'):rep(32))
	Note: secretbox() performs an authenticated encryption, that is
	encrypt the plain test (with Salsa20) and compute a MAC (with Poly1305)
	of the encrypted text. It allows the receiver of the encrypted text to
	detect if it has been tampered with. The MAC is embedded in the
	encrypted text (at the beginning, bytes 16 to 32)
	
secretbox_open(encr, n, k)
	decrypt encrypted string encr with key k and nonce n. The MAC
	embedded in 'encr' is checked before the actual decryption.
	k: a 32-byte string
	n: a 24-byte nonce
	return the decrypted text (including the leading 32 null char...)
	or (nil, error msg) if the MAC is wrong of if the nonce or key 
	lengths are not valid.

stream(ln, n, k)
	generate an encrypting stream with the salsa20 algorithm
	ln: integer, number of bytes to generate
	k: a 32-byte string
	n: a 24-byte nonce
	return a ln-byte long string or (nil error message) if the 
	nonce or key lengths are not valid.

stream_xor(text, n, k)
	encrypt or decrypt text with the salsa20 algorithm. The same 
	function is used to encrypt and decrypt.
	k: a 32-byte string
	n: a 24-byte nonce
	As for secretbox(), the text to encrypt MUST start with 32 null bytes.
	return an encrypted or decrypted string or (nil, error message) if the 
	nonce or key lengths are not valid.	

onetimeauth(text, k)
	compute the 16-byte MAC for the text and key k.
	the MAC algorithm is Poly1305
	k: a 32-byte string
	return the 16-byte MAC as a string or (nil, error message) if the 
	key length is not valid.	

poly1305() is an alias of onetimeauth()

hash(s)
	compute the SHA2-512 hash of string s
	return the hash as a 64-byte binary string (no hex encoding)
	
sha512() is an alias of hash()

sign_keypair()
	generate a random key pair for the siganture algorithm (ed25519)
	return pk, sk
	where pk is the public key (a 32-byte string)
	where sk is the secret key (a 64-byte string)
	(actually, the last 32 bytes of the secret key are the public key)

sign(text, sk)
	sign a text with a secret key
	sk: a 64-byte string
	return the signed text, including the text and the signature
	return (nil, error msg) if the sk lemgth is not valid (not 64)

sign_open(text, pk)
	verify a signed text with the corresponding public key
	pk: a 32-byte string
	if the signature is valid, return the original text 
	(ie. without the signature)
	return (nil, error msg) if the signature is not valid or if the 
	pk lemgth is not valid (not 32)

```

	

