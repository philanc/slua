-- a quick and dirty test for lualzma

local lzma = require "lualzma"

-- some local definitions

local strf = string.format
local byte, char = string.byte, string.char
local spack, sunpack = string.pack, string.unpack

local app, concat = table.insert, table.concat

--~ assert(lzma.VERSION == "lualzma-0.16")

------------------------------------------------------------------------

print("\ntesting " .. lzma.VERSION)
local x	

-- test round-trip compress/uncompress
x = ""; assert(lzma.unlzma(lzma.lzma(x)) == x)
x = "a"; assert(lzma.unlzma(lzma.lzma(x)) == x)
x = "Hello world"; assert(lzma.unlzma(lzma.lzma(x)) == x)
x = ("\0"):rep(301); assert(lzma.unlzma(lzma.lzma(x)) == x)

assert(#lzma.lzma(("a"):rep(301)) < 30)



------------------------------------------------------------------------
print("\ntest_lualzma", "ok\n")
