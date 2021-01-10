require 'busted.runner'()

local selector

describe("Socket Selector", function ()
    setup(function()
        _G._TEST = true
        selector = require("amqp.selector")
    end)

    teardown(function()
        _G._TEST = nil
    end)

    it("Selector should exists", function ()
        assert.is_not_equals(selector, nil)
    end)

    describe("Get from LUA", function ()

        it("should return LUA Socket", function ()
            local skt, tcp = selector.GetFromLua()
            local s = skt.tcp

            assert.is_not_nil(skt)
            assert.is_not_nil(tcp)
            assert.is.equal(tcp, s)
        end)
    end)

    it("should return CQUEUES Socket", function ()
        local skt, tcp = selector.GetFromCqueues()
        local s = skt

        assert.is_not_nil(skt)
        assert.is_not_nil(tcp)
        assert.is.equal(tcp, s)
    end)
end)
