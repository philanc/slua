#!/usr/local/bin/lua

-- test srlua

local sep = ('='):rep(76)
print("\n\n")
print(sep)
print("== srlua  test\n")

print("This is",_VERSION,
      "running a script embedded inside the executable "
      .. arg[0])
print("The script is 'test.lua' in the src/srlua directory")
print("These are the arguments from varargs (if any):")
print(...)

print("These are the arguments from 'arg' (if any)")
for i=0,#arg do
	print(i,arg[i])
end

print("These are the preloaded libraries (they must be 'require()'d before use)")
for k,v in pairs(package.preload) do 
	io.write(k,', ')
end
io.write('\n')

print(sep)
print("\n\n")

