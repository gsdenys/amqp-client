--
-- Copyright (C) 2016 Meng Zhang @ Yottaa,Inc
-- Copyright (C) 2018 4mig4
--
-- logger
--

local logger = {}


-- logging scaffold
local log
if _G.ngx and _G.ngx.log then
  log = _G.ngx.log
else
  log = print
end

-- logging level for print
local ERR   = 4
local INFO  = 7
local DEBUG = 8

-- ngx.log requires a number to indicate the logging level
if _G.ngx then
  ERR   = _G.ngx.ERR
  INFO  = _G.ngx.INFO
  DEBUG = _G.ngx.DEBUG
end

local level_ = INFO

local function to_string(v_)
  if v_ == nil then
    return ""
  end

  if type(v_) ~= "table" then
    return tostring(v_)
  end

  local s = "["
  for k,v in pairs(v_) do
    if k ~= nil then
      s = s .. to_string(k) .. ":"
    end
    if v ~= nil then
      s = s .. to_string(v)
    end
    s = s .. " "
  end
  s = s .. "]"
  return s
end

local function va_table_to_string(tbl)
  local res = ""
  for _,v in pairs(tbl) do
    res = res .. to_string(v) .. "\t"
  end
  return res
end

function logger.set_level(level)
  level_ = level
end

function logger.error(...)
  if level_ < ERR then
    return
  end
  log(ERR, va_table_to_string({...}))
end

function logger.info(...)
  if level_ < INFO then
    return
  end
  log(INFO, va_table_to_string({...}))
end

function logger.dbg(...)
  if level_ ~= DEBUG then
    return
  end

  log(DEBUG, va_table_to_string({...}))
end

function logger.is_debug_enabled()
  return level_ == DEBUG
end

return logger

