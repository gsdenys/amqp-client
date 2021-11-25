require "busted.runner"()

local uri = require "amqp.uri"

describe("[uri.parse]", function()
    local function parse(u) return uri.parse(u) end

    it("should not be nil", function() assert.is_not.Nil(uri) end)

    describe("URI nil", function()
        it("should throw an error", function()
            local _, err = pcall(parse, nil)
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI empty", function()
        it("should throw an error", function()
            local _, err = pcall(parse, "")
            assert.is_not.Nil(err)
        end)
    end)

    describe("White space URI", function()
        it("should throw an error", function()
            local _, err = pcall(parse, " ")
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with white space", function()
        it("should throw an error", function()
            local _, err = pcall(parse, " amgp://localhost")
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with incorrect scheme", function()
        it("should throw an error", function()
            local _, err = pcall(parse, "http://guest:guet@localhost:5672/test")
            assert.is_not.Nil(err)
        end)
    end)

    describe("URI with no valid path", function()
        it("should throws an error", function()
            local _, err = pcall(parse, "amqps://localhost/test/tes")
            assert.is_not.Nil(err)
        end)
    end)

    describe("amqp URI with no port", function()
        it("should add 5672 automaticaly", function()
            local u = "amqp://localhost/test"

            local builder = uri.parse(u)
            assert.equal(5672, builder["port"])
        end)
    end)

    describe("amqps URI with no port", function()
        it("should add 5671 automaticaly", function()
            local u = "amqps://localhost/test"

            local builder = uri.parse(u)
            assert.equal(5671, builder["port"])
        end)
    end)

    describe("amqps URI with no path", function()
        it("should add '' automaticaly", function()
            local u = "amqps://localhost"

            local builder = uri.parse(u)
            assert.equal("/", builder["path"])
        end)
    end)

    describe("amqps URI with path equals /", function()
        it("should add '' automaticaly", function()
            local u = "amqps://localhost/"

            local builder = uri.parse(u)
            assert.equal("/", builder["path"])
        end)
    end)

    describe("AMQP URI", function()
        local u = "amqps://tst:test@some.test.com:1234/t"
        local builder = uri.parse(u)

        it("should be parserd", function() assert.is_not.Nil(builder) end)
        it("should have scheme == amqps",
           function() assert.equal("amqps", builder["scheme"]) end)
        it("should have user == tst",
           function() assert.equal("tst", builder["user"]) end)
        it("should have password == test",
           function() assert.equal("test", builder["password"]) end)
        it("should have host == some.test.com",
           function() assert.equal("some.test.com", builder["host"]) end)
        it("should have port == 1234",
           function() assert.equal(1234, builder["port"]) end)
        it("should have path == path",
           function() assert.equal("/t", builder["path"]) end)
    end)
end)
