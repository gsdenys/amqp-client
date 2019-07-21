local amqp = require "amqp"
local logger = require "amqp.logger"
local uuid = require('resty.uuid')

local host = "127.0.0.1"
local port = 5672

logger.set_level(7)

local ctx = amqp:new({
    role = 'producer',
    exchange = 'amq.topic',
    routing_key = 'test',
    ssl = false,
    user = 'admin',
    password = 'admin',
    no_ack = false,
    durable = true,
    auto_delete = true,
    consumer_tag = '',
    exclusive = false,
    properties = {}
})
    
local ok1, err1 = ctx:connect(host, port)
local ok2, err2 = ctx:setup()
local ok3, err3 = ctx:publish("Hello world!",{},{correlation_id = uuid.generate()})

ctx:teardown()
ctx:close()
