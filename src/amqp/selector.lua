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


-- Socket module to help amqp works with different kind of socket. Currently,
-- there are 3 types of sockets that are organized below according their
-- priorities
--      1. NGINX Socket
--      2. CQUEUES Socket
--      3. LUA Socket
-- @module socket
local selector = {}
_TEST = false

--- Create a new socket generic module
function selector:load()
    local sckt, tcp, sock

    if self.hasNginxSocket() then
        sckt, tcp = self.GetFromNginx()
        sock = tcp()
    elseif self.hasCqueuesSocket() then
        sckt, tcp = self.GetFromCqueues()
        sock = tcp
    else
        sckt, tcp = self.GetFromLua()
        sock = tcp()
    end
end

--- Get the prioritized socket
--- @return socket
function selector:getSocket()
    return self.sckt
end

--- Get the sock
--- @return sock
function selector:getSock()
    return self.sock
end

-- Get the TCP
-- @return tcp
function selector:getTcp()
    return self.tcp
end

-- verify if there is nginx socket loaded
-- @return boolean true case there is, and false if not
function selector:hasNginxSocket()
    if _G.ngx and _G.ngx.socket then
        return true
    end

    return false
end

-- Verify if the cqueues socket is installed
-- @return boolean true case there is, and false if not
function selector:hasCqueuesSocket()
    local cqueues, lfs = pcall(require,"cqueues")

    if cqueues == true then
        return true
    end

    return false
end

-- Get the NGINX socket and tcp
-- @return first socket
-- @return second tcp
function selector:GetFromNginx()
    local sckt = _G.ngx.socket
    local tcp = sckt.tcp

    return sckt, tcp
end

-- Get the CQUEUES socket and tcp
-- @return first socket
-- @return second tcp
function selector:GetFromCqueues()
    local skt = require('cqueues.socket')
    local tcp = skt

    return skt, tcp
end

-- Get the Lua socket and tcp
-- @return first socket
-- @return second tcp
function selector:GetFromLua()
    local sckt = require("socket")
    local tcp = sckt.tcp

    return sckt, tcp
end

return selector