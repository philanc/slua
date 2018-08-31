
local function keys(t)
	local st = {}
	for k, v in pairs(t) do table.insert(st, k) end
	table.sort(st)
	return st
end

local libs = {
	'minisock',
}
for i, lib in ipairs(libs) do
	local l = require(lib)
	local kl = keys(l)
	print(string.format(
		"%-15s %3d functions and constants (version: %s)", 
		lib, #kl, (l.VERSION or l._VERSION)))
	table.sort(kl)
--~  	print("...", table.concat(kl, ", "))
end


