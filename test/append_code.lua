--[[

Append some Lua code to the slua executable. The appended code will 
be run by slua before entering the REPL  (this is similar to 
'lua -i somecode.lua'). 

If entering the REPL is not wanted, just end the appended 
code with "os.exit()".

The appended code must start with the following exact string:  
"--slua appended code", ending with a newline.

Then it is enough to:
	cp slua my_program
	cat some_code.lua >> my_program

If some_code.lua does not start with the magic string, it is easy to
add it. For example let's build a standalone program running the 
nacl test and exiting:

	cp slua my_nacl_test
	echo "--slua appended code" >>my_nacl_test
	cat test/test_nacl.lua >> my_nacl_test
	echo "os.exit()" >>my_nacl_test

Then './my_nacl_test'  will just run the test.

---
	
The append code mechanism within slua is itself written in Lua 
(see src/sluacode.c).  It is invoked in src/slua.c (after 
comment "/// slua embedded Lua code buffer").

It can be easily modified --in Lua!-- to, for example, 
load compressed or encrypted code. Or for anything else.


]]


local function fget(fname)
	-- return content of file 'fname'
	local f = assert(io.open(fname, 'rb'))
	local s = f:read("*a") ;  f:close()
	return s
end

local function fput(fname, content)
	-- write 'content' to file 'fname'
	local f = assert(io.open(fname, 'wb'))
	assert(f:write(content) ); 
	assert(f:flush()) ; f:close()
end

local appended_code = [[
--slua appended code
print("Hello from slua, then enter the interpreter")
]]

local appended_code_exit = [[
--slua appended code
print("Hello from slua, then exit")
os.exit()
]]

slua = fget('slua') 
newexe = slua .. appended_code
fput('slua_hello', newexe)
-- then, chmod +x slua_hello  and run it.
-- "Hello from slua . . . " is printed before the standard lua banner

newexe = slua .. appended_code_exit
fput('slua_hello_exit', newexe)
-- then, chmod +x slua_hello_exit  and run it.
-- "Hello from slua . . . " is printed and the program exits.

