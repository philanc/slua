
-- quick and dirty test of the major luamonocypher functions

mc = require"luamonocypher"

------------------------------------------------------------------------
-- some local definitions

local strf = string.format
local byte, char = string.byte, string.char
local spack, sunpack = string.pack, string.unpack

local app, concat = table.insert, table.concat

local function stohex(s, ln, sep)
	-- stohex(s [, ln [, sep]])
	-- return the hex encoding of string s
	-- ln: (optional) a newline is inserted after 'ln' bytes 
	--	ie. after 2*ln hex digits. Defaults to no newlines.
	-- sep: (optional) separator between bytes in the encoded string
	--	defaults to nothing (if ln is nil, sep is ignored)
	-- example: 
	--	stohex('abcdef', 4, ":") => '61:62:63:64\n65:66'
	--	stohex('abcdef') => '616263646566'
	--
	if #s == 0 then return "" end
	if not ln then -- no newline, no separator: do it the fast way!
		return (s:gsub('.', 
			function(c) return strf('%02x', byte(c)) end
			))
	end
	sep = sep or "" -- optional separator between each byte
	local t = {}
	for i = 1, #s - 1 do
		t[#t + 1] = strf("%02x%s", s:byte(i),
				(i % ln == 0) and '\n' or sep) 
	end
	-- last byte, without any sep appended
	t[#t + 1] = strf("%02x", s:byte(#s))
	return concat(t)	
end --stohex()

local function hextos(hs, unsafe)
	-- decode an hex encoded string. return the decoded string
	-- if optional parameter unsafe is defined, assume the hex
	-- string is well formed (no checks, no whitespace removal).
	-- Default is to remove white spaces (incl newlines)
	-- and check that the hex string is well formed
	local tonumber = tonumber
	if not unsafe then
		hs = string.gsub(hs, "%s+", "") -- remove whitespaces
		if string.find(hs, '[^0-9A-Za-z]') or #hs % 2 ~= 0 then
			error("invalid hex string")
		end
	end
	return (hs:gsub(	'(%x%x)', 
		function(c) return char(tonumber(c, 16)) end
		))
end -- hextos

local function px(s, msg) 
	print("--", msg or "")
	print(stohex(s, 16, " ")) 
end

------------------------------------------------------------------------
-- Monocypher test

print("\ntesting " .. mc.VERSION)

-- xchacha test vector from libsodium-1.0.16
-- see test/aead_xchacha20poly1305.c and aead_xchacha20poly1305.exp

print("testing authenticated encryption...")

k = hextos[[ 
	808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f 
	]]
n = hextos[[ 07000000404142434445464748494a4b0000000000000000 ]]
m = "Ladies and Gentlemen of the class of '99: If I could offer you "
	.. "only one tip for the future, sunscreen would be it."

e = hextos[[
	453c0693a7407f04ff4c56aedb17a3c0a1afff01174930fc22287c33dbcf0ac8
	b89ad929530a1bb3ab5e69f24c7f6070c8f840c9abb4f69fbfc8a7ff5126faee
	bbb55805ee9c1cf2ce5a57263287aec5780f04ec324c3514122cfc3231fc1a8b
	718a62863730a2702bb76366116bed09e0fdd4c860b7074be894fac9697399be
	5cc1
]]

c = mc.encrypt(k,n,m)
assert(c == e)

-- xchacha test vector from 
-- https://github.com/golang/crypto/blob/master/chacha20poly1305/ \
--   chacha20poly1305_vectors_test.go

k = hextos[[ 
	194b1190fa31d483c222ec475d2d6117710dd1ac19a6f1a1e8e894885b7fa631
	]]
n = hextos[[ 6b07ea26bb1f2d92e04207b447f2fd1dd2086b442a7b6852 ]]
m = hextos[[
	f7e11b4d372ed7cb0c0e157f2f9488d8efea0f9bbe089a345f51bdc77e30d139
	2813c5d22ca7e2c7dfc2e2d0da67efb2a559058d4de7a11bd2a2915e
	]]
e = hextos[[
	25ae14585790d71d39a6e88632228a70b1f6a041839dc89a74701c06bfa7c4de
	3288b7772cb2919818d95777ab58fe5480d6e49958f5d2481431014a8f88dab8
	f7e08d2a9aebbe691430011d
	]]
c = mc.encrypt(k, n, m)
assert(c == e)

k = hextos[[ 
	a60e09cd0bea16f26e54b62b2908687aa89722c298e69a3a22cf6cf1c46b7f8a
	]]
n = hextos[[ 92da9d67854c53597fc099b68d955be32df2f0d9efe93614 ]]
m = hextos[[
	d266927ca40b2261d5a4722f3b4da0dd5bec74e103fab431702309fd0d0f1a25
	9c767b956aa7348ca923d64c04f0a2e898b0670988b15e
	]]
e = hextos[[
	9dd6d05832f6b4d7f555a5a83930d6aed5423461d85f363efb6c474b6c4c8261
	b680dea393e24c2a3c8d1cc9db6df517423085833aa21f9ab5b42445b914f231
	3bcd205d179430
	]]
c = mc.encrypt(k, n, m)
assert(c == e)

-- decrypt
m2, msg = mc.decrypt(k, n, c)
assert(m2)
assert(m2 == m)


-- test nonce with an arbitrary "increment"
c = mc.encrypt(k, n, m, 123)
m2 = mc.decrypt(k, n, c, 123)
assert(m2 == m)

------------------------------------------------------------------------
print("testing blake2b...")

t = "The quick brown fox jumps over the lazy dog"
e = hextos[[
	a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673
	f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918
	]]

dig = mc.blake2b(t)
assert(e == dig)

dig16 = mc.blake2b(t, 16)
dig31 = mc.blake2b(t, 31)
assert(#dig16 == 16)
assert(#dig31 == 31)
digk = mc.blake2b(t, 16, k)
assert(digk ~= dig16)
assert(#digk == 16)

------------------------------------------------------------------------
print("testing x25519 key exchange...")

local function keypair()
	local sk = mc.randombytes(32)
	local pk = mc.public_key(sk)
	return pk, sk
end

apk, ask = keypair() -- alice keypair
bpk, bsk = keypair() -- bob keypair

k1 = mc.key_exchange(ask, bpk)
k2 = mc.key_exchange(bsk, apk)
assert(k1 == k2)

-- test raw scalar multiplication
-- compute directly alice public key with G, the generator of curve25519
G = '\9\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0'
apk2 = mc.x25519(ask, G)
assert(apk2 == apk)

------------------------------------------------------------------------
print("testing sha512...")

t = "The quick brown fox jumps over the lazy dog"
e = hextos[[
	07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb64
	2e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6
]]

h = mc.sha512(t)
assert(h == e)
--~ px(h)

------------------------------------------------------------------------
print("testing signature...")

local function sign_keypair()
	local sk = mc.randombytes(32)
	local pk = mc.sign_public_key(sk)
	return pk, sk
end

pk, sk = sign_keypair() -- signature keypair

sig = mc.sign(sk, pk, t)
assert(#sig == 64)
--~ px(pk, 'pk')
--~ px(sig, 'sig')

-- check signature
assert(mc.check(sig, pk, t))

-- modified text doesn't check
assert(not mc.check(sig, pk, t .. "!"))

--- ed25519

------------------------------------------------------------------------
print("testing ed25519/sha512 signature...")

sk = hextos[[
	889f5e0ee37f968db2690b805790aac94faf885e8459d30e226672108b172aee
	]]

pk = mc.ed25519_public_key(sk)

assert(pk == hextos[[
	8b8a804d179e015320777bc6d8cf9eaefb6705cf511d4962d8c35cf39659a957
	]])

sig = mc.ed25519_sign(sk, pk, t)
assert(#sig == 64)
--~ px(sk, 'sk')
--~ px(pk, 'pk')
--~ px(sig, 'sig512')
assert(sig == hextos[[
	5c9c1a3c71dbda120341aef1b2828baac68308c88090651333d3ad725bfc4898
	86b38903633053a75b6028295a29b63f2b51b5df6a287703d06ae374cf1c9005
	]])

-- check signature
assert(mc.ed25519_check(sig, pk, t))

-- modified text doesn't check
assert(not mc.ed25519_check(sig, pk, t .. "!"))


------------------------------------------------------------------------
-- key derivation argon2i tests

print("testing argon2i...")

pw = "hello"
salt = "salt salt salt"
k = ""
c0 = os.clock()
k = mc.argon2i(pw, salt, 100000, 10)
assert(#k == 32)
assert(k == hextos[[
	0dae6ce32c7f1be7ada558fbd55f2ebbe149b46c29725b73e5341f04b338bf08
	]])
  
print("argon2i (100MBytes, 10 iter) Execution time (sec): ", os.clock()-c0)

------------------------------------------------------------------------
print("\ntest_luamonocypher", "ok\n")