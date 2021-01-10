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
local socket = {}


-- Create a new socket generic module
function socket:new()
    local sckt, tcp, sock

    if self.hasNginxSocket() then
        sckt, tcp = self.getNginxChannel()
        sock = tcp()
    elseif self.hasCqueuesSocket() then
        sckt, tcp = self.getCqueuesChannel()
        sock = tcp
    else
        sckt, tcp = self.getLuaChannel()
        sock = tcp()
    end
end

-- Get the prioritized socket
-- @return the loaded socket
function socket:getSocket()
    return self.sckt
end

-- Get the sock
-- @return sock
function socket:getSock()
    return self.sock
end

-- Get the TCP
-- @return tcp
function socket:getTcp()
    return self.tcp
end

-- verify if there is nginx socket loaded
-- @return boolean true case there is, and false if not
local function hasNginxSocket()
    if _G.ngx and _G.ngx.socket then
        return true
    end

    return false
end

-- Verify if the cqueues socket is installed
-- @return boolean true case there is, and false if not
local function hasCqueuesSocket()
    local cqueues, lfs = pcall(require,"cqueues")

    if cqueues == true then
        return true
    end

    return false
end

-- Get the NGINX socket and tcp
-- @return first socket
-- @return second tcp
local function getNginxChannel()
    local sckt = _G.ngx.socket
    local tcp = sckt.tcp

    return sckt, tcp
end

-- Get the CQUEUES socket and tcp
-- @return first socket
-- @return second tcp
local function getCqueuesChannel()
    local sckt = require('cqueues.socket')
    local tcp = sckt

    return sckt, tcp
end

-- Get the Lua socket and tcp
-- @return first socket
-- @return second tcp
local function getLuaChannel()
    local sckt = require("socket")
    local tcp = sckt.tcp

    return socket, tcp
end

return socket