require 'busted.runner'()

local selector

describe("Socket Selector", function ()
    setup(function()
        selector = require("amqp.selector")
    end)

    it("Selector should exists", function ()
        assert.is_not_equals(selector, nil)
    end)

    describe("Get Socket", function ()
        it("should return LUA Socket", function ()
            local skt, tcp = selector.GetFromLua()
            local s = skt.tcp
    
            assert.is_not_nil(skt)
            assert.is_not_nil(tcp)
            assert.is.equal(tcp, s)
        end)
    
        it("should return CQUEUES Socket", function ()
            local skt, tcp = selector.GetFromCqueues()
            local s = skt
    
            assert.is_not_nil(skt)
            assert.is_not_nil(tcp)
            assert.is.equal(tcp, s)
        end)

        -- TODO: create GetFromNginx test
    end)

    describe("Is socket from each type", function ()
        
    end)
end)
