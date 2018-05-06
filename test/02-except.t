#!/usr/bin/env luajit

local l = require 'linenoise'

require 'Test.More'

plan(7)

error_like( function () assert(l.historysetmaxlen(true)) end,
            "bad argument #1 to setmaxlen %(number expected" )

error_like( function () assert(l.historysetmaxlen(-1)) end,
            "bad argument #1 to setmaxlen" )

error_like( function () assert(l.setcompletion(true)) end,
            "bad argument #1 to setcompletion %(function expected" )

error_like( function () l.addcompletion(true, "text") end,
            "bad argument" )

error_like( function () l.historysave(true) end,
            "bad argument" )

error_like( function () l.historyload(true) end,
            "bad argument" )

error_like( function () assert(l.historyload('no_file')) end,
            "no_file" )

