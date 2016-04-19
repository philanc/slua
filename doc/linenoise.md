### linenoise

*"A minimal, zero-config, BSD licensed, readline replacement used in Redis, MongoDB, and Android."* - https://github.com/antirez/linenoise

The version of linenoise included here has been both simplified (no support for multi-line edition and tab completion) and extended with a small Lua binding. It includes all the functions used by the regular Lua interpreter (see lua.c)

Usage in Lua programs:
```
linenoise(prompt)
	display prompt, read a line (with all the linenoise line 
	editing facilities). return read line or (nil, error message)

addhistory(line)
	add a line to the current history (history is created if this is
	the first call).  return true on success or (nil, error message)

gethistory()
	return a table with the list of history entries. if the history 
	is empty or has not been created yet, an empty table is returned

clearhistory()
	empties the current history. return nothing

setrawmode()
	set the current tty in raw mode
	return true on success or (nil, error message)
	(usually fails because stdin is not a tty)

resetmode()
	reset the current tty mode (as saved when setrawmode was called)
	return true on success or (nil, error message)
	(usually fails because stdin is not a tty)

isatty(fd)
	wraps the unix isatty() function
	return true if the file descriptor fd is a tty, or else false
```
