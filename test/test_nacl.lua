
tw = require "tweetnacl"

-- gen alice keypair with keypair()
apk, ask = tw.box_keypair()
-- gen bob keypair with randombytes() and getpk()
bsk = tw.randombytes(32); bpk = tw.box_getpk(bsk)
-- gen random nonce
nonce = tw.randombytes(23)
msg = "Hello, Bob"
ma = string.rep("\0", 32) .. msg -- must start with 32 zerobytes
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




