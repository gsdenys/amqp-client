local logger = require ('amqp.logger')


local utils = {}


function utils.failOnError(err, message)
    if err ~= nil then
        logger.error(message, err)
        os.exit(1)
    end
end