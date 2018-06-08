#!/usr/bin/env luajit
--
--  Copyright (C) 2013 Francois Perrad.
--

local function dostring (chunk, name)
    local f, msg = load(chunk, name)
    if f then
        f()
    else
       error(msg, 0)
    end
end

local function dotty ()
    local l = require 'linenoise'
    local history = 'history.txt'
    l.loadhistory(history)
    for line in l.lines( '> ') do
        if #line > 0 then
            local r, msg = pcall(function () dostring(line, '=stdin') end)
            if msg then
                print(msg)
            end
            l.addhistory(line)
            l.savehistory(history)
        end
    end
end

dotty()
