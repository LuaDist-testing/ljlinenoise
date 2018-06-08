#!/usr/bin/env luajit

require 'Test.More'

plan(21)

if not require_ok 'linenoise' then
    BAIL_OUT "no lib"
end

local m = require 'linenoise'
type_ok( m, 'table' )
is( m, package.loaded['linenoise'] )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'editing', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

type_ok( m.linenoise, 'function', 'linenoise' )
type_ok( m.historyadd, 'function', 'historyadd' )
type_ok( m.historysetmaxlen, 'function', 'historysetmaxlen' )
type_ok( m.historysave, 'function', 'historysave' )
type_ok( m.historyload, 'function', 'historyload' )
type_ok( m.clearscreen, 'function', 'clearscreen' )
type_ok( m.setcompletion, 'function', 'setcompletion' )
type_ok( m.addcompletion, 'function', 'addcompletion' )
type_ok( m.addhistory, 'function', 'addhistory' )
type_ok( m.sethistorymaxlen, 'function', 'sethistorymaxlen' )
type_ok( m.savehistory, 'function', 'savehistory' )
type_ok( m.loadhistory, 'function', 'loadhistory' )
type_ok( m.line, 'function', 'line' )
type_ok( m.lines, 'function', 'lines' )
