local helper = {}

-- Parameter to be used in the reflection and make reference to the obtention of
-- function name.
local PARAMETER_NAME = "n"

-- Parameter to be used in the reflection and make reference to the obtention of
-- thread stack.
local STACK_NUMBER = 2

--- function to get the executuion function name
---
--- @return string the function name
function helper.function_name()
    return debug.getinfo(STACK_NUMBER, PARAMETER_NAME).name
end

return helper
