
-- This is an example of how to embed some Lua code in slua

------------------------------------------------------------------------
-- utility functions to read and write a file

function fget(fname)
	-- return content of file 'fname' or nil, msg in case of error
	local f, msg, s
	f, msg = io.open(fname, 'rb')
	if not f then return nil, msg end
	s, msg = f:read("*a")
	f:close()
	if not s then return nil, msg end
	return s
end

local function fput(fname, content)
	-- write 'content' to file 'fname'
	-- return true in case of success, or nil, msg in case of error
	local f, msg, r
	f, msg = io.open(fname, 'wb')
	if not f then return nil, msg end
	r, msg = f:write(content)
	f:flush(); f:close()
	if not r then return nil, msg else return true end
end

------------------------------------------------------------------------
-- embedded Lua code

elua = [[

-- this is the code to embed
print("hello, world!!")

]]


-- load the content of the executable slua
slua = fget('slua')

-- the marker is used to find the location of the embed[] 
-- array in the slua executable.
marker = string.rep('#', 32)

-- look for the marker in embed[] array
ex = string.find(slua, marker)

-- the embed[] array contains:
--       EMBSIZE (uint32, little endian) -- the size of embed[]
--       marker  (32 '#')
--       emblen  (uint32) -- the length of the embedded lua code
--                        -- or 0 if embed[] doesn't contain code
--       embedded lua code ('emblen' bytes)
--       trailing null bytes

-- esize is the embed[] array size (constant EMBSIZE)
-- it is stored 4 bytes before the marker
esize = string.unpack("<I4", slua, ex-4)

-- the code to embed is prefixed with its length, stored as 
-- a uint32, little endian
embed = string.pack("<I4", #elua) .. elua

-- make sure embed[] is large enough for the array length + the marker
-- + the embedded code
assert(4 + 32 + #embed <  esize)

-- overwrite the embedded code
slua1 = slua:sub(1, ex-1) .. marker .. embed .. slua:sub(ex + 32 + #embed )

-- make sure the executable length has not changed
assert(#slua1 == #slua)

-- write the executable to a new file
fput('slua_hello', slua1)

-- make the new file executable:   chmod +x slua_hello








--[[
-- extract chunk
local elen = string.unpack("<I4", slua, ex+32)

]]

