-- Import the AMQP Client Library
local amqp = require("amqp")

-- Define the connection URL and Port 
local host = "127.0.0.1"
local port = 5672

-- Connect to AMQP server
local ctx = amqp:new({
    role = "producer",
    user = "admin",
    password = "admin"
})
local ok, err = ctx:connect("127.0.0.1",5672)
local ok, err = ctx:setup()

-- Unbind the amq.direct to the 'xpto' queue  with
-- the routing key 'potato'
local ok, err = amqp.queue_unbind(ctx,{
	exchange = "amq.direct",
	queue = "xpto",
	routing_key = "potato"
})

-- Finalize proccess and close connection
ctx:teardown()
ctx:close()
