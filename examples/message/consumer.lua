-- Import the AMQP Client Library
local amqp = require "amqp"
local inspect = require('inspect')

-- Define the connection URL and Port 
local host = "127.0.0.1"
local port = 5672

-- Connect to AMQP server
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
local ok, err = ctx:connect(host, port)

-- Define a callback for consumer
ctx.opts.callback = function(f)
    print(inspect(f))
end

-- Start consume loop
ok, err = ctx:consume()