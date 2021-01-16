require 'busted.runner'()

local selector = require("amqp.selector")

describe("Socket Selector", function ()
    describe("(Automatic execution)", function ()
        it("should return LUA socket", function ()
            local s = selector.new(selector.LUA)
        --    local socket = s.GetSocket()
            local socke = s:GetSocket()
            print(socke._VERSION )
            -- local version = socket._VERSION
        end)
    end)

    describe("Is socket from each type", function ()
        
    end)
end)
