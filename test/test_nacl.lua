-- test_nacl.lua

bin = require "bin"
tw = require "tweetnacl"

local function prx(s)
	-- print hex repr of s, 16 bytes per line, separated by space
	print(bin.stohex(s, 16, " "))
end
------------------------------------------------------------
-- box functions - curve25519 + salsa20 + poly1305
--
-- gen alice keypair with keypair()
apk, ask = tw.box_keypair()
-- gen bob keypair with randombytes() and getpk()
bsk = tw.randombytes(32); bpk = tw.box_getpk(bsk)
-- gen random nonce
nonce = tw.randombytes(24)
-- prx(nonce)
zero16 = string.rep("\0", 16) -- leading zero bytes (in encrypted text)
zero32 = string.rep("\0", 32) -- leading zero bytes
msg = "Hello, Bob"
ma = zero32 .. msg -- must start with 32 zerobytes
c = tw.box(ma, nonce, bpk, ask) -- msg encrypted by alice for bob
mb = tw.box_open(c, nonce, apk, bsk)  -- msg decrypted by bob
assert(ma == mb)
-- try to decode with beforenm/afternm functions
k = tw.box_beforenm(apk, bsk)
mb2 = tw.box_open_afternm(c, nonce, k)
assert(ma == mb2)
-- try to encode with beforenm/afternm functions
k = tw.box_beforenm(apk, bsk)
c2 = tw.box_afternm(ma, nonce, k)
assert(c == c2)
assert(c:sub(1,16) == zero16)
-- check aliases are defined
assert(tw.box_afternm == tw.secretbox)
assert(tw.box_open_afternm == tw.secretbox_open)
assert(tw.box_beforenm == tw.box_stream_key)
--
-- salsa20 functions
-- 
-- fixed (non random) key and nonce
k32 = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
   .. "\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"
n24 = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f"
   .. "\x10\x11\x12\x13\x14\x15\x16\x17"
-- gen stream with arbitrary size
s7 = tw.stream(7, n24, k32); assert(#s7 == 7); -- prx(s7)
s17 = tw.stream(17, n24, k32); assert(#s17 == 17); -- prx(s17)
assert(s7 == s17:sub(1, 7))
--
-- poly1305 / onetimeauth
--
-- test from rfc7539
rfcmsg = "Cryptographic Forum Research Group"
rfckey = bin.hextos(
	"85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b")
rfcmac = bin.hextos("a8061dc1305136c6c22b8baf0c0127a9")
mac = tw.onetimeauth(rfcmsg, rfckey)
assert(mac == rfcmac)
assert(poly1305 == onetimeauth) -- check alias is defined
--
-- hash and signature functions
--
msg = "Hello, Bob"
msg_sha512 = bin.hextos[[
	337b1bcce024a75803dfd616a604a89875081d85e5f0c8fe7b3b303b322f06b1
	ead23183ae3c53fb6ca14e62f8ba449cee596c73533c133cdab4fccbc09b5bf3
]] -- generated with echo -n "Hello, Bob" | sha512sum
assert(tw.hash(msg) == msg_sha512)
assert(tw.hash == tw.sha512) -- check alias is defined
--
-- test signature
-- alice sign keypair
aspk, assk = tw.sign_keypair()
-- print'aspk'; prx(aspk); print'assk'; prx(assk); print'--'
assert(#aspk == 32 and #assk == 64)
assert(assk:sub(33) == aspk) -- the last 32 bytes of the sk are the pk
signedmsg, r = tw.sign(msg, assk)
assert(#signedmsg == #msg + 64)
--~ prx(signedmsg)
checkmsg, r = tw.sign_open(signedmsg, aspk)
if r then print(r) end
assert(checkmsg == msg)


------------------------------------------------------------
print("ok - test_nacl")
