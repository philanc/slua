
local ecode = [[
-- slua emmbedded loader
local asep="++sluapp++";asep=asep..asep
-- local f = assert(io.open(arg[0], 'rb'))
local f = assert(io.open("/proc/self/exe", 'rb'))
local s = f:read("*a"); f:close()
local i,j=s:find(asep, 1, true)
if i then 
	local ac = s:sub(j+1); 
	local f, msg = load(ac)
	if f then f() 
	else 
		print("slua: cannot load appended code (maybe a syntax error)")
	end
end
]]

local appcode = [[
--appended code
package.preload.myapp = function()
 local m = { hello = function() print"hello, myapp!!!"; end }
 return m
end
print("myapp has been appended. Yay!")
--print"Now, exiting..."
--os.exit(3)
]]

local ecodesep = "++slua++"
local appcodesep = "++sluapp++"
-- the complete appended code separator should not be in the regular slua
-- nor in the embedded code loading the appended code
appcodesep = appcodesep .. appcodesep 
 
local slua = 'slua'
local newprogname = 'sle'

function fget(fname)
	-- return content of file 'fname'
	local f = assert(io.open(fname, 'rb'))
	local s = f:read("*a") ;  f:close()
	return s
end

function fput(fname, content)
	-- write 'content' to file 'fname'
	local f = assert(io.open(fname, 'wb'))
	assert(f:write(content) ); 
	assert(f:flush()) ; f:close()
end

function embedcode(prog, ecode)
	local i1, j1 = prog:find(ecodesep, 1, true)
	local i2, j2 = prog:find(ecodesep, j1+1, true)
	if not i1 or not i2 then 
		error"embedded code buffer not found" 
	end
	local emax = i2 - j1 - 1 --embedded max size
	assert(#ecode < emax, "not enough space in embedded code buffer")
	local newprog = prog:sub(1,j1) 
			.. ecode .. ("\0"):rep(emax - #ecode) 
			.. prog:sub(i2)
	return newprog
end

function appendcode(prog, appcode)
	local i1, j1 = prog:find(appcodesep, 1, true)
	local newprog
	if i1 then -- prog has already some code appended - replace it
		newprog = prog:sub(1, j1) .. appcode
	else
		newprog = prog .. appcodesep .. appcode
	end
	return newprog
end

prog = fget(slua)
newprog = embedcode(prog, ecode)
assert(#prog == #newprog, "new program must keep the same size)")
newprog = appendcode(newprog, appcode)
fput(newprogname, newprog)
