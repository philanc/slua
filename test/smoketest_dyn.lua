
local function keys(t)
	local st = {}
	for k, v in pairs(t) do table.insert(st, k) end
	table.sort(st)
	return st
end

local libs = {
	'linenoise',
	'lfs',
	'lpeg',
	'luaproc',
	'luazen',
	'mtcp',
	'tweetnacl',
}
print("\nsdlua - a dynamic build of Lua 5.3 with some shared libraries:")
for i, lib in ipairs(libs) do
	kl = keys(require(lib))
	print(string.format("%-15s %3d functions and constants", lib, #kl))
--~  	print("...", table.concat(keys(require(lib)), ", "))
end


