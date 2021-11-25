require "busted.runner"()

local uri = require "amqp.uri"

describe("[Contains]", function()
    it("should not be nil", function ()
        assert.is_not.Nil(uri)
    end)
end)
