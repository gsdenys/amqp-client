local level = require "amqp.utils.level"
local messages = require "amqp.utils.messages"

local format = string.format

---Table that contains all implementation type of assertion.
---Basically this table just contains functions
local assertion = {}

---failOnAssert function that throws an exception each called time
---@param msg string the error message
---@param fn string the function name
local function failOnAssert(msg, fn)
    local message = messages.MESSAGE_BASE .. msg
    error(format(message, level.ERROR, fn))
end

--- validade uri and certify that there is no white spaces
---
--- @param uri any the uri to be validate
--- @param fn any the function name
function assertion.whitespace(uri, fn)
    local WHITESPACE = " "
    if string.find(uri, WHITESPACE) then
        failOnAssert(messages.ERR_URI_WHITE_SPACE, fn)
    end
end

--- validate the used protocol
---
--- @param t table the list of possibilities
--- @param dt table the data to assert
--- @param msg string the message to create error
--- @param fn string the name of function
function assertion.contains(t, dt, msg, fn)
    for _, value in pairs(t) do
        if value == dt  then
            return
        end
    end

    failOnAssert(msg, fn)
end

---True function that throws exception when <test> is false
---@param fn string the function name
---@param msg string the error message
---@param test boolean the test
function assertion.True(fn, msg, test) if not test then failOnAssert(msg, fn) end end

-- Export assertion table function
return assertion
