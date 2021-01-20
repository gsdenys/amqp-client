-- Copyright 2021 gsdenys. All Rights Reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http:--www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local logger = require ('amqp.logger')
local utils = require 'amqp.utils'

local socket = {}

local function create_socket()
    local sckt = require("socket")

    local tcp = sckt.tcp
    local sock = tcp()

    return sckt, tcp, sock
end


function socket:getType()
    return "LuaSocket"
end

function socket:send(str)
    return self.sock:send(str)
end

function socket:receive(int)
    return self.sock:receive(int)
end

function socket:sslhandshake(ssl_ctx)
    local ssl = require("ssl")

    local default_params = {
        mode = "client",
        protocol = "any",
        verify = "none",
        options = {"all", "no_sslv2","no_sslv3"}
    }

    local wsock, err = ssl.wrap(self.sock, ssl_ctx or default_params)
    utils.failOnError(err, "[amqp:sslhandshake] Socket wrapping failed: ")

    logger.dbg("[amqp:sslhandshake] Wrapped socket")
    self.sock = wsock

    -- if not wsock then
    --     logger.error("[amqp:sslhandshake] Socket wrapping failed: ", err)
    --     return wsock, err -- return
    -- else
    --     logger.dbg("[amqp:sslhandshake] Wrapped socket")
    --     self.sock = wsock
    -- end

    local ok, msg = self.sock:dohandshake()

    if not ok then
        logger.error("[amqp:sslhandshake] SSL handshake failed: ", msg)
    else
        logger.dbg("[amqp:sslhandshake] SSL handshake")
    end

    return ok, msg -- return
end

function socket:new()
    local sckt, tcp, sock = create_socket()

    local state = {
        sckt = sckt,
        tcp = tcp,
        sock = sock
    }

    return setmetatable(state, { __index = socket })
end

return socket