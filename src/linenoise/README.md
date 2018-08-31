# linenoise

Linenoise is *"A minimal, zero-config, BSD licensed, readline replacement used in Redis, MongoDB, and Android."* - https://github.com/antirez/linenoise

This is a Lua wrapper for the Linenoise library. It also includes some tty-related functions (get and set tty mode, test if a file descriptor is a tty, test if a key has been pressed).

The version of linenoise included here has been both simplified (no support for multi-line edition and tab completion) and extended with a small Lua binding. It includes all the functions used by the regular Lua interpreter (see lua.c)

### API

```
--- Linenoise functions

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


--- Other tty functions

isatty(fd)
	wraps the unix isatty() function
	return true if the file descriptor fd is a tty, or else false

getmode(mode)
	get the current terminal mode
	return the current mode as a binary string
	(a copy of the termios structure)
	in case of error, the function returns (nil, error message)
	(usually fails because stdin is not a tty)

setmode(mode)
	set the terminal mode
	'mode' is a binary string obtained by getmode()
	return true on success or (nil, error message)
	(can fail because either stdin is not a tty or mode is not valid)

setrawmode([opost])
	set the current tty in raw mode
	if the optional parameter opost is 1, output post processing 
	is not disabled. By default, output post processing is disabled.
	return true on success or (nil, error message)
	(usually fails because stdin is not a tty)

kbhit()
	this is the old conio kbhit() function
	It is intended to be used in raw mode.
	return true if a key has been hit or else false
	in case of poll error, the function returns nil, error msg.	


```
