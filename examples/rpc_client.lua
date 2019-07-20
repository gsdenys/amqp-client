
local amqp = require "amqp"
local uuid = require('resty.uuid')
local inspect = require('inspect')

local host = "127.0.0.1"
local port = 5672

local producer = amqp:new({
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

uid = uuid.generate()

local ok1, err1 = producer:connect(host, port)
local ok2, err2 = producer:setup()
local ok3, err3 = producer:publish("Hello world!",{},{correlation_id = uid})

-- ############

local consumer = amqp:new({
    role = 'consumer',
    exchange = '',
    queue = uid..'-queue',
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

local ok, err
ok , err = consumer:connect(host, port)
if not ok then
    error('could not connect'..err)
end

-- register calback 
consumer.opts.callback = function(f)
    print('-- f --', inspect(f)) 
end

local ok, err = consumer:consume()
