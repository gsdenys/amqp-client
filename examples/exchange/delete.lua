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

-- Delete the 'drx.xpto'exchange
local ok, err = amqp.exchange_delete(ctx,{
	exchange = "drt.xpto",
})

-- Finalize proccess and close connection
ctx:teardown()
ctx:close()
