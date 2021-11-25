require "busted.runner"()

describe("[Assertion]", function()
    local function some_test(uri)
        local assertion = require "amqp.utils.assertion"

        assertion.whitespace("test", uri)
    end

    describe("URI with white space in the beginning", function()
        local test = " amqp://user:password@host:123/vhost"

        it("should cause an error", function()
            local _, err = pcall(some_test, test)
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with white space in the end", function()
        local test = "amqp://user:password@host:123/vhost "

        it("should cause an error", function()
            local _, err = pcall(some_test, test)
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with white space in the middle", function()
        local test = "amqp://user:password @host:123/vhost"

        it("should cause an error", function()
            local _, err = pcall(some_test, test)
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with no white space", function()
        local test = "amqp://user:password@host:123/vhost"

        it("should not cause an error", function()
            local _, err = pcall(some_test, test)
            assert.Nil(err)
        end)
    end)
end)
