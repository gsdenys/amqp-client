require 'busted.runner'()

describe("[amqp]", function()
	describe("client", function()
		local logger = require("amqp.logger")
		logger.set_level(7)
			
		it("should be rejected with wrong user name or password", function()
			local amqp = require("amqp")
			local ctx = amqp:new({
				role = 'producer',
				exchange = 'amq.topic',
				routing_key = 'xpto',
				ssl = false,
				user = 'admin',
				password = 'adminerr'
			})
			
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			-- expects access denied
			assert.is_equal(403,err)
			assert.falsy(ok)
		end)
	end)	    
end)
