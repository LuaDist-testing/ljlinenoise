
# ljlinenoise

---

## Overview

ljlinenoise is a pure [LuaJIT](http://luajit.org/)
port of [linenoise](https://github.com/antirez/linenoise),
a small alternative to readline and libedit.

ljlinenoise is based on
[ljsyscall](https://github.com/justincormack/ljsyscall).

ljlinenoise is compatible with
[lua-linenoise](https://github.com/hoelzro/lua-linenoise).

## Status

ljlinenoise is in beta stage.

It's developed for LuaJIT 2.x.

## Download

ljlinenoise source can be downloaded from
[GitHub](http://github.com/fperrad/ljlinenoise/releases/).

## Installation

The easiest way to install ljlinenoise is to use LuaRocks:

```sh
luarocks install ljlinenoise
```

or manually, with:

```sh
make install
```

## Copyright and License

Copyright &copy; 2013-2018 Fran&ccedil;ois Perrad
[![OpenHUB](http://www.openhub.net/accounts/4780/widgets/account_rank.gif)](http://www.openhub.net/accounts/4780?ref=Rank)
[![LinkedIn](http://www.linkedin.com/img/webpromo/btn_liprofile_blue_80x15.gif)](http://www.linkedin.com/in/fperrad)

This library is licensed under the terms of the MIT/X11 license,
like Lua itself.
