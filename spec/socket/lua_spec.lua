require 'busted.runner'()


describe("Lua Socket", function ()
    it("Should connect to server", function()
        local sock = require "amqp.socket.lua"
        sock:connect('httpbin.org', 80)
    end)

    it("Should send message", function()
        local sock = require "amqp.socket.lua"
        sock:connect('httpbin.org', 80)
        a = sock:send("GET /anything")

        assert.not_nil(a)
    end)
end)