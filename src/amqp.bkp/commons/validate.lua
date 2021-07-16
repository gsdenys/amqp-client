local log = require 'amqp.log.selector'

local validate = {}

function validate.opts(opts)
    if not opts then
       log.err("no opts provided")
       os.exit()
    end
    
    if type(opts) ~= "table" then
        log.err("opts is not valid")
        os.exit()
    end
    
    if (opts.role == nil or opts.role == "consumer") and not opts.queue then
        log.err("The 'queue' is required to connect as a consumer")
        os.exit()
    end
end

return validate