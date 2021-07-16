local log = require 'amqp.log.simple'
local config = require 'amqp.socket.config'

local basic = {}

basic.socket = require("socket")
basic.tcp = basic.socket.tcp

basic.sock = basic.tcp()


function basic:connect(...)
    self.sock:settimeout(config.DEFAULT_TIMEOUT)
    
    local ok, err = self.sock:connect(...)
    
    if not ok then
        log.fatal("Error to connect to provider")
        os.exit()
    end
end


-- Sends message through socket
-- Uses created socket to send AMQP message. This function looks simple 
-- but it is necessary to create a patronizing way to call the send 
-- information in the differents type of sockets
--
-- @param str message to be sent
function basic:send(str) 
    return self.sock:send(str) 
end


-- Receives message through socket
-- Uses created socket to send AMQP message. This function looks simple 
-- but it is necessary to create a patronizing way to call the send 
-- information in the differents type of sockets
--
-- @param int the size
function basic:receive(int) 
    return self.sock:receive(int) 
end


-- Close socket connection
-- Enables to close socket connection 
function amqp:close()
    if not self.sock then
      return nil, "not initialized"
    end
    return self.sock:close()
end

return basic