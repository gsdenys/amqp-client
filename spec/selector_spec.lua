require 'busted.runner'()

local selector

describe("Socket Selector", function ()
    setup(function()
        _G._TEST = true
        selector = require("amqp.selector")
    end)

    describe("Lua socket", function ()
        it("Selector should exists", function ()
            assert.is_not_equals(selector, nil)
        end)

        it("should return LUA Socket", function ()
            local socket, tcp = selector._GetFromLua()
            
           -- assert(socket ~= nil, "Socket should exist.")
        end)
    end)
end)