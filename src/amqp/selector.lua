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


--- Socket module to help amqp works with different kind of socket. Currently,
--- there are 3 types of sockets that are organized below according their
--- priorities:
---      1. NGINX Socket
---      2. CQUEUES Socket
---      3. LUA Socket
--- However, you can define wich of them you want manualy though th function 
--- selector:SetType(type)
---
--- @module socket
local selector = {}

-- Get the NGINX socket and tcp
-- @return first socket
-- @return second tcp
local function _getFromNginx()
    local sckt = _G.ngx.socket
    local tcp = sckt.tcp
    local sock = tcp()
    
    return sckt, tcp, sock
end

--- Get the CQUEUES socket and tcp
--- @return socket
--- @return second tcp
local function _getFromCqueues()
    local skt = require('cqueues.socket')
    local tcp = skt
    
    return skt, tcp, tcp
end

-- Get the Lua socket and tcp
-- @return first socket
-- @return second tcp
local function _getFromLua()
    local sckt = require("socket")
    local tcp = sckt.tcp
    local sock = tcp()

    return sckt, tcp, sock
end

-- verify if there is nginx socket loaded
-- @return boolean true case there is, and false if not
local function _hasNginxSocket()
    if _G.ngx and _G.ngx.socket then
        return true
    end

    return false
end

--- Verify if the cqueues socket is installed
--- @return boolean true case there is, and false if not
local function _hasCqueuesSocket()
    local cqueues, lfs = pcall(require,"cqueues")

    if cqueues == true then
        return true
    end

    return false
end


local function _selfSelect()
    if _hasNginxSocket() then
        return _getFromNginx
    elseif _hasCqueuesSocket() then
       return _getFromCqueues
    else
        return _getFromLua
    end
end


--- Set the selector type.
--- @param type string (nginx | cqueues | lua)
function selector:SetType(type)
    if type == "nginx" then
        selector.socket_definer = _getFromNginx
    elseif type == "cqueues" then
        selector.socket_definer = _getFromCqueues
    elseif type == "lua" then
        selector.socket_definer = _getFromLua
    else
        error("This function accepts just 'nginx | cqueues | lua'.")
    end
end

--- Create a new socket generic module
function selector:load()

    if self.socket_definer == nil then
        self.socket_definer = _selfSelect
    end

    self.sckt, self.tcp, self.sock = self.socket_definer()
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



return selector