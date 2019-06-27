
local function keys(t)
	local st = {}
	for k, v in pairs(t) do table.insert(st, k) end
	table.sort(st)
	return st
end

print("\nsglua - a dynamic build of Lua 5.3 with some preloaded libraries:")
for i, lib in ipairs(keys(package.preload)) do
	l = require(lib)
	kl = keys(l)
	print(string.format(
		"%-15s %3d functions and constants (version: %s)", 
		lib, #kl, (l.VERSION or l._VERSION)))
end


