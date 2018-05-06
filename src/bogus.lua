
if not jit then
    -- dummy module for Lua 5.1 and 5.2
    package.loaded['syscall'] = {
        getenv = os.getenv
    }
    print("# bogus", _VERSION)
end
