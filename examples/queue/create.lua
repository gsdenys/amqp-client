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

-- Create a new queue with name 'xpto', durable and 
-- with bit auto delete as true
local ok, err = amqp.queue_declare(ctx,{
    queue = "xpto",
    durable = true,
    auto_delete = false,
    typ = "direct"
})

-- Finalize proccess and close connection
ctx:teardown()
ctx:close()
