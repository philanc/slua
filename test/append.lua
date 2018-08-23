

local he = require'he'

s = he.fget("slua")
a = [[
	print("hello from appended!")
	os.exit()
]]

pat = "%+%+%+appended code%+%+%+ \0\0\0\0\0\0\0\0 %+%+%+"
aoff = #s
alen = #a
repl = "+++appended code+++ " .. string.pack("<I4I4", aoff, alen) .. " +++"
p = s:gsub(pat, repl) .. a
he.fput("t", p)
os.execute("chmod +x t")





