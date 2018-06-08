
# linenoise

---

# Reference

All functions return `nil` on error;
functions that don't have an obvious return value return `true` on success.

#### linenoise( prompt ) or line( prompt )

Prompts for a line of input, using `prompt` as the prompt string.
Returns `nil` if no more input is available.

#### lines( prompt )

Iterator over line.

#### historyadd( line ) or addhistory( line )

Adds `line` to the history list.

#### historysetmaxlen( length ) or sethistorymaxlen( length )

Sets the history list size to `length`.

#### historysave( filename ) or savehistory( filename )

Saves the history list to `filename`.

#### historyload( filename ) or loadhistory( filename )

Loads the history list from `filename`.

#### clearscreen()

Clears the screen.

#### setcompletion( callback )

Sets the completion callback.
This `callback` is called with two arguments:

- A completions object. Use `addcompletion` to add a completion to this object.
- The current line of input.

#### addcompletion( completions, string )

Adds `string` to the list of `completions`.

# Examples

```lua
local L = require 'linenoise'

local function completion (c, s)
    if s:sub(1, 1) == 'h' then
        L.addcompletion(c, 'hello')
        L.addcompletion(c, 'hello there')
    end
end

L.setcompletion(completion)

local history = 'history.txt'
L.historyload(history)

for line in L.lines( 'hello> ') do
    if line ~= '' then
        if line:sub(1, 1) == '/' then
            local len = line:match'/historylen%s+(%d+)'
            if len then
                L.historysetmaxlen(len)
            else
                print("Unreconized command: " .. line)
            end
        else
            print("echo: '" .. line .. "'")
            L.historyadd(line)
            L.historysave(history)
        end
    end
end
```

# Scripts

The library is used to implement two Lua
[REPL](https://en.wikipedia.org/wiki/REPL) scripts.

```text
usage: lrepl [options] [script [args]]
Available options are:
  -e stat  execute string 'stat'
  -i       enter interactive mode after executing 'script'
  -l name  require library 'name'
  -v       show version information
  -E       ignore environment variables
  --       stop handling options
  -        stop handling options and execute stdin
```

```text
usage: ljrepl [options]... [script [args]...].
Available options are:
  -e chunk  Execute string 'chunk'.
  -l name   Require library 'name'.
  -b ...    Save or list bytecode.
  -j cmd    Perform LuaJIT control command.
  -O[opt]   Control LuaJIT optimizations.
  -i        Enter interactive mode after executing 'script'.
  -v        Show version information.
  -E        Ignore environment variables.
  --        Stop handling options.
  -         Execute stdin and stop handling options.
```
