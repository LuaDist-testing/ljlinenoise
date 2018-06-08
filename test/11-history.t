#!/usr/bin/env luajit

local l = require 'linenoise'

require 'Test.More'

plan(36)

local h1 = l.new_history()
type_ok( h1, 'table', "history" )
is( h1.max_len, 100, "default max" )
is( #h1, 0, "empty" )

ok( h1:setmaxlen(6), "setmaxlen" )
is( h1.max_len, 6, "setmaxlen" )

nok( h1:setmaxlen(0), "setmaxlen(0)" )
is( h1.max_len, 6 )
nok( h1:setmaxlen(-1), "setmaxlen(-1)" )
is( h1.max_len, 6 )

h1:add'line1'
is( #h1, 1, "1 line" )
is( h1[1], 'line1', "line1" )

h1:add'line2'
h1:add'line3'
is( #h1, 3, "3 lines" )
is( h1[1], 'line1', "line1" )
is( h1[2], 'line2', "line2" )
is( h1[3], 'line3', "line3" )

h1:add'line4'
h1:add'line5'
h1:add'line6'
h1:add'line7'
h1:add'line8'
is( #h1, 6, "max lines" )
is( h1[1], 'line3', "line3" )
is( h1[6], 'line8', "line8" )

h1:setmaxlen(4)
is( #h1, 4, "max lines -> 4" )
is( h1[1], 'line5', "line5" )
is( h1[4], 'line8', "line8" )

h1:add'line9'
is( #h1, 4, "max lines" )
is( h1[1], 'line6', "line6" )
is( h1[4], 'line9', "line9" )

h1:setmaxlen(8)
is( h1.max_len, 8, "max lines -> 8" )
is( #h1, 4 )

ok( h1:save'test.txt', "save" )

h1:clean()
is( #h1, 0, "free" )

local h2 = l.new_history()
ok( h2:load'test.txt', "load" )
is( #h2, 4, "restored" )
is( h2[1], 'line6', "line6" )
is( h2[4], 'line9', "line9" )

h2:updatelast'line0'
is( #h2, 4, "updatelast" )
is( h2[4], 'line0' )

local r, msg = h2:load'no_file'
nok( r, "load no file" )
like( msg, "no_file" )
