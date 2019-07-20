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

ok, err = ctx:setup() -- because of this we need to use consume_loop()
if not ok then
    error('could not setup: '..err)
end

ok, err = ctx:prepare_to_consume() -- this has to be right after setup()
if not ok then
    error('could not prepare to consume: '..err)
end

local callback = function(f)
    print('---f---',inspect(f))
end

ok, err = ctx:consume_loop(callback)
print(ok, err)
