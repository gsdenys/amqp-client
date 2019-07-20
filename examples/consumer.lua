local amqp = require "amqp"
local inspect = require('inspect')

local host = "127.0.0.1"
local port = 5672

local ctx = amqp:new({
    role = 'consumer',
    exchange = '',
    queue = 'test',
    ssl = false,
    user = 'admin',
    password = 'admin',
    no_ack = false,
    durable = true,
    auto_delete = false,
    consumer_tag = '',
    exclusive = false,
    properties = {}
})

local ok, err
ok , err = ctx:connect(host, port)
if not ok then
    error('could not connect'..err)
end

-- Define a callback for consume
ctx.opts.callback = function(f)
    print(inspect(f))
end

ok, err = ctx:consume()
print(ok, err)
