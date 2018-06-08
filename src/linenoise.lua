
--
-- ljlinenoise : <http://fperrad.github.io/ljlinenoise/>
--

local assert = assert
local error = error
local setmetatable = setmetatable
local tonumber =tonumber
local tostring = tostring
local type = type
local xpcall = xpcall
local traceback = require'debug'.traceback
local open = require'io'.open
local sub = require'string'.sub
local insert = require'table'.insert
local remove = require'table'.remove

local S = require('syscall')
local getenv = S.getenv
local ioctl = S.ioctl
local stdin = S.stdin
local stdout = S.stdout
local stderr = S.stderr

local TERM = getenv('TERM')
local HARNESS_ACTIVE = getenv('HARNESS_ACTIVE')

_ENV = nil

local function getColumns ()
    local ws = ioctl(stdout, 'TIOCGWINSZ')
    return (not ws or ws.ws_col == 0) and 80 or ws.ws_col
end

local function clearScreen ()
    stdin:write('\x1b[H\x1b[2J')
end

local function beep ()
    stderr:write('\x07')
end

local completionCallback

--[[
    ================================ History =================================
--]]

local H = {}

function H:add (line)
    line = tostring(line)
    while #self >= self.max_len do
        remove(self, 1)
    end
    insert(self, line)
    return true
end

function H:setmaxlen (len)
    len = tonumber(len)
    if not len then
        return nil, "bad argument #1 to setmaxlen (number expected)"
    end
    if len <= 0 then
        return nil, "bad argument #1 to setmaxlen (strict positive number expected)"
    end
    self.max_len = len
    while #self > len do
        remove(self, 1)
    end
    return true
end

function H:clean ()
    for i = 1, #self do
        self[i] = nil
    end
    return true
end

function H:save (filename)
    local f, msg = open(filename, 'w')
    if not f then
        return f, msg
    end
    for i = 1, #self do
        f:write(self[i], '\n')
    end
    f:close()
    return true
end

function H:load (filename)
    local f, msg = open(filename, 'r')
    if not f then
        return f, msg
    end
    for line in f:lines() do
        self:add(line)
    end
    f:close()
    return true
end

function H:updatelast (line)
    self[#self] = line
end

local H_mt = { __index = H }

local function new_history ()
    local h = { max_len = 100 }
    return setmetatable(h, H_mt)
end

--[[
    =========================== Line editing =================================
--]]

local ED = {}

function ED:refreshLine ()
    local s = self.line
    local pos = self.pos
    if self.plen + pos >= self.cols - 1 then
        s = sub(s, self.plen + pos - self.cols + 1)
        pos = self.cols
    end
    if self.plen + #s > self.cols then
        s = sub(s, 1, self.cols - self.plen)
    end
    -- Cursor to left edge
    assert(self.fd:write("\x1b[0G"))
    -- Write the prompt and the current buffer content
    assert(self.fd:write(self.prompt))
    assert(self.fd:write(s))
    -- Erase to right
    assert(self.fd:write("\x1b[0K"))
    -- Move cursor to original position.
    assert(self.fd:write("\x1b[0G\x1b[" .. tostring(pos + self.plen - 1) .. "C"))
end

function ED:Insert (c)
    local line = self.line
    local pos = self.pos
    if #line == pos-1 then
        self.line = line .. c
        self.pos = pos+1
        self.history:updatelast(self.line)
        if self.plen + #self.line < self.cols then
            -- Avoid a full update of the line in the trivial case.
            assert(self.fd:write(c))
        else
            self:refreshLine()
        end
    else
        self.line = sub(line, 1, pos-1) .. c .. sub(line, pos)
        self.pos = pos+1
        self.history:updatelast(self.line)
        self:refreshLine()
    end
end

function ED:MoveLeft ()
    if self.pos > 1 then
        self.pos = self.pos - 1
        self:refreshLine()
    end
end

function ED:MoveRight ()
    if self.pos-1 ~= #self.line then
        self.pos = self.pos + 1
        self:refreshLine()
    end
end

function ED:History (delta)
    local history = self.history
    local history_len = #history
    local history_index = self.history_index
    if history_len > 1 then
        history_index = history_index + delta
        if history_index < 1 then
            self.history_index = 1
            return
        elseif history_index > history_len then
            self.history_index = history_len
            return
        else
            local line = self.history[history_index]
            self.line = line
            self.history_index = history_index
            self.pos = #line + 1
            self:refreshLine()
        end
    end
end

function ED:Delete ()
    local line = self.line
    local pos = self.pos
    if pos > 0 and #line > 0 then
        self.line = sub(line, 1, pos-1) .. sub(line, pos+1)
        self.history:updatelast(self.line)
        self:refreshLine()
    end
end

function ED:Backspace ()
    local line = self.line
    local pos = self.pos
    if pos > 1 and #line > 0 then
        self.line = sub(line, 1, pos-2) .. sub(line, pos)
        self.pos = pos-1
        self.history:updatelast(self.line)
        self:refreshLine()
    end
end

function ED:Swap ()
    local line = self.line
    local pos = self.pos
    if pos > 1 and pos <= #line then
        self.line = sub(line, 1, pos-2) .. sub(line, pos, pos) .. sub(line, pos-1, pos-1) .. sub(line, pos+1)
        if pos ~= #line then
            self.pos = pos+1
        end
        self.history:updatelast(self.line)
        self:refreshLine()
    end
end

function ED:DeleteLine ()
    self.line = ''
    self.pos = 1
    self.history:updatelast(self.line)
    self:refreshLine()
end

function ED:DeleteEnd ()
    self.line = sub(self.line, 1, self.pos - 1)
    self.history:updatelast(self.line)
    self:refreshLine()
end

function ED:MoveHome ()
    self.pos = 1
    self:refreshLine()
end

function ED:MoveEnd ()
    self.pos = #self.line + 1
    self:refreshLine()
end

function ED:Edit ()
    assert(self.fd:write(self.prompt))
    while true do
        local seq
        seq = self.fd:read(seq, 1)
        if seq == '' then
            self.history:updatelast(nil)
            return self.line
        end
        local c = seq:byte()

        if c == 9 and completionCallback then -- Tab
            seq, c = self:completeLine()
        end
        if     c < 0 then
            -- nothing (from completeLine)
        elseif c == 13 then  -- Enter
            self.history:updatelast(nil)
            return self.line
        elseif c == 3 then   -- Ctrl-C
            return nil
        elseif c == 127      -- Backspace
            or c == 8 then   -- Ctrl-H
            self:Backspace()
        elseif c == 4 then          -- Ctrl-D, remove char at right of cursor, or if the
            if #self.line > 0 then  -- line is empty, act as end-of-file.
                self:Delete()
            else
                self.history:updatelast(nil)
                return nil
            end
        elseif c == 20 then  -- Ctrl-T, swaps current character with previous
            self:Swap()
        elseif c == 2 then   -- Ctrl-B
            self:MoveLeft()
        elseif c == 6 then   -- Ctrl-F
            self:MoveRight()
        elseif c == 16 then  -- Ctrl-P
            self:History(-1)
        elseif c == 14 then  -- Ctrl-N
            self:History(1)
        elseif c == 27 then  -- Escape
            local seq -- Read the next two bytes representing the escape sequence.
            seq = assert(self.fd:read(seq, 2))
            local seq1, seq2 = seq:byte(1, 2)
            if     seq1 == 91 and seq2 == 68 then -- Left arrow
                self:MoveLeft()
            elseif seq1 == 91 and seq2 == 67 then -- Right arrow
                self:MoveRight()
            elseif seq1 == 91 and seq2 == 65 then -- Up arrow
                self:History(-1)
            elseif seq1 == 91 and seq2 == 66 then -- Down arrow
                self:History(1)
            elseif seq1 == 79 and seq2 == 72 then -- Home arrow
                self:MoveHome()
            elseif seq1 == 79 and seq2 == 70 then -- End arrow
                self:MoveEnd()
            elseif seq1 == 91 and seq2 > 48 and seq2 < 55 then
                local seq -- extended escape, read additional two bytes.
                seq = assert(self.fd:read(seq, 2))
                local seq3, seq4 = seq:byte(1, 2)
                if seq2 == 51 and seq3 == 126 then  -- Delete key.
                    self:Delete()
                end
            end
        elseif c == 21 then  -- Ctrl-U, delete the whole line.
            self:DeleteLine()
        elseif c == 11 then  -- Ctrl-K, delete from current to end of line.
            self:DeleteEnd()
        elseif c == 1 then   -- Ctrl-A, go to the start of the line
            self:MoveHome()
        elseif c == 5 then   -- Ctrl-E, go to the end of the line
            self:MoveEnd()
        elseif c == 12 then  -- Ctrl-L, clear screen
            clearScreen()
            self:refreshLine()
        else
            self:Insert(seq)
        end
    end
end

function ED:completeLine ()
    local t = { self.line }
    completionCallback(t, self.line)
    if #t <= 1 then
        beep()
        return '', -1
    else
        local i = 2
        while true do
            self.line = t[i]
            self.pos = #self.line + 1
            self:refreshLine()
            local seq
            seq = assert(self.fd:read(seq, 1))
            local c = seq:byte()
            if     c == 9 then  -- Tab
                i = i+1
                if i > #t then
                    i = 1
                    beep()
                end
            elseif c == 27 then -- Escape
                self.line = t[1]
                self.pos = #self.line + 1
                self:refreshLine()
                return '', -1
            else
                return seq, c
            end
        end
    end
end

local ED_mt = { __index = ED }

local function new_edit (fd, prompt, cols, history)
    local line = ''
    history:add(line)
    local ed = {
        fd = fd,
        line = line,
        prompt = prompt,
        plen = #prompt,
        pos = 1,
        cols = cols,
        history = history,
        history_index = #history,
    }
    return setmetatable(ed, ED_mt)
end

--[[
    =================================== Main =================================
--]]

local orig_termios
local rawmode = false

local function disableRawMode (fd)
    if rawmode and fd:tcsetattr('FLUSH', orig_termios) then
        rawmode = false
    end
end

local function enableRawMode (fd)
    if not orig_termios then
        orig_termios = assert(fd:tcgetattr())
    end
    if not rawmode then
        local termios = assert(fd:tcgetattr())
        termios:makeraw()
        assert(fd:tcsetattr('FLUSH', termios))
        rawmode = true
    end
end

local unsupported_term = {
    dumb = true,
    cons25 = true,
}
local history = new_history()

local function linenoise (prompt)
    prompt = tostring(prompt)
    if unsupported_term[TERM] then
        io.stdout:write(prompt)
        io.stdout:flush()
        return io.stdin:read('*L')
    else
        if stdin:isatty() then
            local r, out = xpcall(function ()
                enableRawMode(stdin)
                local ed = new_edit(stdin, prompt, getColumns(), history)
                local line = ed:Edit()
                disableRawMode(stdin)
                stdout:write('\n')
                return line
            end, function (err)
                disableRawMode(stdin)
                return traceback(err)
            end)
            if r then
                return out
            else
                error(out, 0)
            end
        else
            return io.stdin:read('*L')
        end
    end
end

local function historyadd (line)
    return history:add(line)
end

local function historysetmaxlen (len)
    return history:setmaxlen(len)
end

local function historysave (filename)
    return history:save(filename)
end

local function historyload (filename)
    return history:load(filename)
end

local function clearscreen ()
    clearScreen()
    return true
end

local function setcompletion (fn)
    if type(fn) ~= 'function' then
        return nil, "bad argument #1 to setcompletion (function expected)"
    end
    completionCallback = fn
    return true
end

local function addcompletion (t, entry)
    insert(t, tostring(entry))
    return true
end

local function lines (prompt)
    return function ()
        return linenoise(prompt)
    end
end

return {
    linenoise = linenoise,
    historyadd = historyadd,
    historysetmaxlen = historysetmaxlen,
    historysave = historysave,
    historyload = historyload,
    clearscreen = clearscreen,
    setcompletion = setcompletion,
    addcompletion = addcompletion,
    -- Aliases for more consistent function names
    addhistory = historyadd,
    sethistorymaxlen = historysetmaxlen,
    savehistory = historysave,
    loadhistory = historyload,
    line = linenoise,
    -- Iterator
    lines = lines,
    -- Unit Test
    new_history = HARNESS_ACTIVE and new_history or nil,
    new_edit = HARNESS_ACTIVE and new_edit or nil,
    -- Info
    _VERSION = '0.1.2',
    _DESCRIPTION = "ljlinenoise : Line editing in pure LuaJIT",
    _COPYRIGHT = "Copyright (c) 2013-2015 Francois Perrad",
}

--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
