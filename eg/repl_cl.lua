#!/usr/bin/env luajit
--
--  Copyright (C) 2014 Francois Perrad.
--

--[[

    $ eg/repl_cl.lua
    > set me tarzan
    > set you jane
    > set us "tarzan & jane"
    > print us $me and $you
    us	tarzan	and	jane

    $ eg/repl_cl.lua
    > (set 'me' "tarzan")
    > (set 'you' "jane")
    > (set 'us' "tarzan & jane")
    > (print 'us' me "and" you)
    us	tarzan	and	jane
    > (print (* 6 7))
    42

--]]

local _G = _G

function set (name, value)
    _G[name] = value
end

function get (name)
    return name, _G[name]
end

function list (...)
    return ...
end

set('true', true)
set('false', false)
set('+', function (x, y) return x + y end)
set('-', function (x, y) return x - y end)
set('*', function (x, y) return x * y end)
set('/', function (x, y) return x / y end)

local function dotty ()
    local cl = require 'cl' -- see http://luarocks.org/repositories/rocks/#cl
    local l = require 'linenoise'
    local history = 'history.txt'
    l.loadhistory(history)
    for line in l.lines( '> ') do
        if #line > 0 then
            local r, msg = cl[line:match'%s*%(' and 'sexp' or 'eval'](line)
            if msg then
                print(msg)
            end
            l.addhistory(line)
            l.savehistory(history)
        end
    end
end

dotty()
