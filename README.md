# LUA-AMQP

Lua Client for AMQP 0.9.1

This library is fork of : 

https://github.com/mengz0/amqp

https://github.com/ZigzagAK/amqp

This library at the moment supports ngx.socket and socket, it can be used with luajit and does not have to be used only in OpenResty.

## Additional features

This fork contains the code that is missing in the original library.

* Decode all AMQP packets
* Several other fixes
* Examples on how to use this library.
* Removed not working bitopers.lua, also not needed for my use case.

## Requirements

1. LuaJIT 2.1
2. busted 2.0 (Testing framework)
3. luabitop (if you are using lua 5.1)

### Examples

Please look at the example directory instead.

* lua inspect is needed by the example, though you are of course free not to use it and remove it.

```
luarocks install inspect
luarocks install lua-resty-uuid
```
