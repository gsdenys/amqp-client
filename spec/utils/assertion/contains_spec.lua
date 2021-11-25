require "busted.runner"()

describe("[Contains]", function()
    local function some_test(t, dt)
        local assertion = require "amqp.utils.assertion"

        assertion.contains(t, dt, "some error", "test")
    end

    describe("table containing the data", function()
        local test = " amqp://user:password@host:123/vhost"

        it("should not throw errors", function()
            local t = {"amqp", "amqps"}
            local dt = "amqps"

            local _, err = pcall(some_test, t, dt)
            assert.Nil(err)
        end)
    end)

    describe("table without the data", function()
        local test = " amqp://user:password@host:123/vhost"

        it("should throw an error", function()
            local t = {"amqp", "amqps"}
            local dt = "http"

            local _, err = pcall(some_test, t, dt)
            assert.is_not.Nil(err)
        end)
    end)
end)
