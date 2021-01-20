require 'busted.runner'()

local selector = require("amqp.selector")

describe("Socket Selector", function ()
    describe("(Automatic execution)", function ()
        it("should return LUA socket", function ()
            local s = selector:new(selector.LUA)
            local socket = s:GetSocket()

            assert.not_nil(socket)
            assert.truthy(socket._VERSION:find("^LuaSocket"))
        end)

        it("should return CQUEUES socket", function ()
            local s = selector:new(selector.CQUEUES)
            local socket = s:GetSocket()

            for key,value in pairs(socket) do
                print("found member " .. key);
            end

            --print(socket._VERSION)

            assert.not_nil(socket)
            -- assert.truthy(socket._VERSION:find("^LuaSocket"))
        end)
    end)

end)
