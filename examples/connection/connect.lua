-- Import the AMQP Client Library
local amqp = require("amqp")

-- Define the connection URL and Port 
local host = "127.0.0.1"
local port = 5672

-- Pepare to connect to AMQP server
local ctx = amqp:new({
    role = 'producer',
    exchange = 'amq.topic',
    routing_key = 'xpto',
    ssl = false,
    user = 'admin',
    password = 'admin'
})
local ok, err = ctx:connect(host, port)
print("Connection Created:", ok, "Errors:", err)

local ok, err = ctx:setup()
print("Connection setup:", ok, "Errors:", err)