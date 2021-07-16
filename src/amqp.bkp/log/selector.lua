if _G.ngx and _G.ngx.socket then
    -- not implemented yet
end

local use_cqueues, lfs = pcall(require,"cqueues")
if use_cqueues == true then
    -- not implemented yet
end

-- select the lua socket and their extensions
return require 'amqp.log.simple'