
local function keys(t)
	local st = {}
	for k, v in pairs(t) do table.insert(st, k) end
	table.sort(st)
	return st
end

for i, lib in ipairs(keys(package.preload)) do
	print(lib, table.concat(keys(require(lib)), ", "))
end
