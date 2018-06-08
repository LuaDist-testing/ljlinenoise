#!/usr/bin/env luajit

require 'Test.More'

if os.getenv'TRAVIS' then
    skip_all "too old LuaJIT on Travis CI"
end

local lua = './lrepl'

plan(24)

local f = io.open('hello.lua', 'w')
f:write([[
print 'Hello World'
]])
f:close()

local cmd = lua .. " hello.lua"
f = io.popen(cmd)
is(f:read'*l', 'Hello World', "file")
f:close()

cmd = lua .. " no_file.lua 2>&1"
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: cannot open no_file.lua", "no file")
f:close()

cmd = lua .. " < hello.lua"
f = io.popen(cmd)
is(f:read'*l', 'Hello World', "redirect")
f:close()

cmd = lua .. [[ -e"a=1" -e "print(a)"]]
f = io.popen(cmd)
is(f:read'*l', '1', "-e")
f:close()

cmd = lua .. [[ -e "error('msg')"  2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: %(command line%):1: msg", "error")
is(f:read'*l', "stack traceback:", "backtrace")
f:close()

cmd = lua .. [[ -e "error(setmetatable({}, {__tostring=function() return 'MSG' end}))"  2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: MSG", "error with object")
f:close()

cmd = lua .. [[ -e "error{}"  2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: %(.-error .-%)", "error")
is(f:read'*l', nil, "not backtrace")
f:close()

cmd = lua .. [[ -e"a=1" -e "print(a)" hello.lua]]
f = io.popen(cmd)
is(f:read'*l', '1', "-e & script")
is(f:read'*l', 'Hello World')
f:close()

cmd = lua .. [[ -e "?syntax error?" 2>&1]]
f = io.popen(cmd)
like(f:read'*l', "lua", "-e bad")
f:close()

cmd = lua .. [[ -e 2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: '%-e' needs argument", "no file")
like(f:read'*l', "^usage: ", "no file")
f:close()

cmd = lua .. [[ -v 2>&1]]
f = io.popen(cmd)
like(f:read'*l', '^Lua', "-v")
f:close()

cmd = lua .. [[ -v hello.lua 2>&1]]
f = io.popen(cmd)
like(f:read'*l', '^Lua', "-v & script")
is(f:read'*l', 'Hello World')
f:close()

cmd = lua .. [[ -E hello.lua 2>&1]]
f = io.popen(cmd)
is(f:read'*l', 'Hello World')
f:close()

cmd = lua .. [[ -u 2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: unrecognized option '%-u'", "unknown option")
like(f:read'*l', "^usage: ", "no file")
f:close()

cmd = lua .. [[ -lTest.More -e "print(type(ok))"]]
f = io.popen(cmd)
is(f:read'*l', 'function', "-lTest.More")
f:close()

cmd = lua .. [[ -l Test.More -e "print(type(ok))"]]
f = io.popen(cmd)
is(f:read'*l', 'function', "-l Test.More")
f:close()

cmd = lua .. [[ -l socket -e "print(1)" 2>&1]]
f = io.popen(cmd)
isnt(f:read'*l', nil, "-l socket")
f:close()

cmd = lua .. [[ -l no_lib hello.lua 2>&1]]
f = io.popen(cmd)
like(f:read'*l', "^[^:]+: module 'no_lib' not found:", "-l no lib")
f:close()

os.remove('hello.lua') -- clean up
