require 'busted.runner'()

describe("[amqp]", function()
	describe("client", function()
		local logger = require("amqp.logger")
		logger.set_level(9)

		local options = {
		    role = "producer",
			exchange = "amq.topic",
			routing_key = 'xpto',
			ssl = false,
			user = "admin",
			password = "admin"
		}

		it("should be able to declare exchange", function()
			local amqp = require("amqp")
			local ctx = amqp:new(options)
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			assert.truthy(ok)
			local ok, err = amqp.exchange_declare(ctx,{
				exchange = "topic.xpto",
				passive = false,
				durable = true,
				internal = false,
				auto_delete = true
			})
			assert.truthy(ok)
			ctx:teardown()
			ctx:close()
		end)

		it("should be able to bind exchange", function()
			local amqp = require("amqp")
			local ctx = amqp:new(options)
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			assert.truthy(ok)

			local ok, err = amqp.exchange_bind(ctx,{
				source = "amq.topic",
				destination = "topic.xpto",
				routing_key = "Kiwi"
			})
			
			assert.truthy(ok)
			ctx:teardown()
			ctx:close()
		end)

		it("should be able to unbind exchange", function()
			local amqp = require("amqp")
			local ctx = amqp:new(options)
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			assert.truthy(ok)

			local ok, err = amqp.exchange_unbind(ctx,{
				source = "amq.topic",
				destination = "topic.xpto",
				routing_key = "Kiwi"
			})

			assert.truthy(ok)
			ctx:teardown()
			ctx:close()
		end)

		it("should be able to delete exchange", function()
			local amqp = require("amqp")
			local ctx = amqp:new(options)
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			assert.truthy(ok)

			local ok, err = amqp.exchange_delete(ctx,{
				exchange = "topic.xpto"					
			})
			
			assert.truthy(ok)
			ctx:teardown()
			ctx:close()
		end)

		it("should succeed to delete non existing exchanges", function()
			local amqp = require("amqp")
			local ctx = amqp:new(options)
			local ok, err = ctx:connect("127.0.0.1",5672)
			assert.truthy(ok)
			local ok, err = ctx:setup()
			assert.truthy(ok)

			local ok, err = amqp.exchange_delete(ctx,{
				exchange = "topic.xpto"			      
			})
				  
			assert.truthy(ok)
			ctx:teardown()
			ctx:close()
		end)	
	end)
end)
