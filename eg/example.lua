#!/usr/bin/env luajit

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

