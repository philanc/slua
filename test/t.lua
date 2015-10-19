
local function keys(t)
	local st = {}
	for k, v in pairs(t) do table.insert(st, k) end
	table.sort(st)
	return st
end

for i, lib in ipairs(keys(package.preload)) do
	kl = keys(require(lib))
	print(string.format("%-15s %3d functions and constants", lib, #kl))
--~  	print("...", table.concat(keys(require(lib)), ", "))
end


