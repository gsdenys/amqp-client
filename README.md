# AMQP

Lua Client for AMQP 0.9.1

This library is fork of : 

https://github.com/mengz0/amqp

https://github.com/ZigzagAK/amqp

This library at the moment supports ngx.socket and socket, but plans have been discussed to move to cqueues

## Additional features

This fork contains the code that is missing in the original library.

* Decode all AMQP packets
* Several other fixes
* Examples on how to use this library.
* Removed bitopers.lua as I do not need it and it was not working, if someone else wants to provide a better solution for compatibility with Lua 5.1 please do not hesitate to pull request.

## Requirements

1. LuaJIT 2.1
2. busted 2.0 (Testing framework)

### Examples Requirements

* lua inspect is needed 

```
luarocks install inspect
```

## Typical Use Cases

The examples below are really really misleading, so please look at the example directory instead.

+ Consumer

```lua
local amqp = require "resty.amqp"
local ctx = amqp.new({role = "consumer", queue = "mengz0", exchange = "amq.topic", ssl = false, user = "guest", password = "guest"})
ctx:connect("127.0.0.1",5672)
local ok, err = ctx:consume()
```

+ Producer

```lua
local amqp = require "resty.amqp"
local ctx = amqp.new({role = "publisher", exchange = "amq.topic", ssl = false, user = "guest", password = "guest"})
ctx:connect("127.0.0.1",5672)
ctx:setup()
local ok, err = ctx:publish("Hello world!")
```
