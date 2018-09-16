# LUA-AMQP

Lua Client for AMQP 0.9.1, while this has been tested only with RabbitMQ it should work with any other AMQP 0.9.1 broker.

This library is fork of : 

https://github.com/mengz0/amqp

https://github.com/ZigzagAK/amqp

This library can be used with LuaJIT and does not have to be used only in OpenResty.

## Additional features

This fork contains the code that is missing in the original library and some additions:

- [x] Support for CQUEUES, NGX.SOCKET, SOCKET
- [x] Decode all AMQP packets
- [x] Support SSL
- [x] Examples on how to use this library.
- [x] Removed not working bitopers.lua, also not needed for my use case.
- [x] Automatic installation of most dependencies.

## Requirements

1. LuaJIT >= 2.1 
2. busted 2.0 (Testing framework)
3. luabitop (if you are using lua 5.1)

### Examples

Please look at the example directory instead.

* lua inspect is needed by the example, though you are of course free not to use it and remove it.

```
luarocks install inspect
luarocks install lua-resty-uuid
luarocks install argparse
```
