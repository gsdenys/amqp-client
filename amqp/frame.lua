--
-- Copyright (C) 2016 Meng Zhang @ Yottaa,Inc
-- Copyright (C) 2018 4mig4
--
--
-- [0].https://www.rabbitmq.com/resources/specs/amqp0-9-1.pdf
-- [1].https://www.rabbitmq.com/amqp-0-9-1-reference.html
--

local c = require('amqp.consts')
local buffer = require('amqp.buffer')
local logger = require('amqp.logger')
local bit = require('bit')

local band = bit.band
local bor = bit.bor

local byte = string.byte

local debug = logger.dbg
local is_debug_enabled = logger.is_debug_enabled

local amqp_frame = {}


local function declare_exchange_flags(method)
  local bits = 0

  if method.passive then
    bits = bor(bits,1)
  end

  if method.durable then
    bits = bor(bits, 2)
  end

  if method.auto_delete then
    bits = bor(bits, 4)
  end

  if method.internal then
    bits = bor(bits,8)
  end

  if method.no_wait then
    bits = bor(bits, 16)
  end

  return bits
end

local function toboolean(n)
  if n and n ~= 0 then
    return true
  end
  return false
end

local function parse_exchange_flags(bits)
  local flags = {}
  flags.passive = toboolean(band(bits, 1))
  flags.auto_delete = toboolean(band(bits, 4))
  flags.internal = toboolean(band(bits, 8))
  flags.no_wait = toboolean(band(bits, 16))
  return flags
end

local function declare_queue_flags(method)
  local bits = 0

  if method.passive then
    bits = bor(bits,1)
  end

  if method.durable then
    bits = bor(bits, 2)
  end

  if method.exclusive then
    bits = bor(bits, 4)
  end

  if method.auto_delete then
    bits = bor(bits, 8)
  end

  if method.no_wait then
    bits = bor(bits, 16)
  end

  return bits
end

local function parse_queue_flags(bits)
  local flags = {}
  flags.passive = toboolean(band(bits, 1))
  flags.durable = toboolean(band(bits, 2))
  flags.exclusive = toboolean(band(bits, 4))
  flags.auto_delete = toboolean(band(bits, 8))
  flags.no_wait = toboolean(band(bits, 16))
  return flags
end

local function basic_consume_flags(method)
  local bits = 0

  if method.no_local then
    bits = bor(bits,1)
  end

  if method.no_ack then
    bits = bor(bits, 2)
  end

  if method.exclusive then
    bits = bor(bits, 4)
  end

  if method.no_wait then
    bits = bor(bits, 8)
  end

  return bits
end

local function parse_consume_flags(bits)
  local flags = {}
  flags.no_local = toboolean(band(bits,1))
  flags.no_ack = toboolean(band(bits,2))
  flags.exclusive = toboolean(band(bits,4))
  flags.no_wait = toboolean(band(bits,8))
  return flags
end

local function parse_exchange_delete_flags(bits)
  local flags = {}
  flags.if_unused = toboolean(band(bits,1))
  flags.no_wait = toboolean(band(bits,2))
  return flags
end

local function parse_queue_delete_flags(bits)
  local flags = {}
  flags.if_unused = toboolean(band(bits,1))
  flags.if_empty = toboolean(band(bits,2))
  flags.no_wait = toboolean(band(bits,4))
  return flags
end

local function decode_close_reply(b)
  local frame = {}
  frame.reply_code = b:get_i16()
  frame.reply_text = b:get_short_string()
  frame.class_id = b:get_i16()
  frame.method_id = b:get_i16()
  return frame
end

local function encode_close_reply(method)
  local b = buffer.new()
  b:put_i16(method.reply_code)
  b:put_short_string(method.reply_text)
  b:put_i16(method.class_id)
  b:put_i16(method.method_id)
  return b:payload()
end

local function nop()
  return nil
end

local methods_ = {
  [c.class.CONNECTION] = {
    name = "connection",
    --[[
    major octet
    minor octet
    properties field_table
    mechanism long_string
    locales long_string
    --]]
    [c.method.connection.START] = {
      name = "start",
      r = function(b)
        local f = {}
        f.major = b:get_i8()
        f.minor = b:get_i8()
        f.props = b:get_field_table()
        f.mechanism = b:get_long_string()
        f.locales = b:get_long_string()
        return f
      end
    },
    --[[
    client_properties field_table
    mechanism short_string
    response long_string
    locale short_string
    --]]
    [c.method.connection.START_OK] = {
      name = "start_ok",
      w = function(method)
        local b = buffer.new()
        b:put_field_table(method.properties)
        b:put_short_string(method.mechanism)
        b:put_long_string(method.response)
        b:put_short_string(method.locale)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.properties = b:get_field_table()
        f.mechanism = b:get_short_string()
        f.response = b:get_long_string()
        f.locale = b:get_short_string()
        return f
      end
    },
    --[[
    secure long_string
    --]]
    [c.method.connection.SECURE] = {
      name = "secure"
    },
    [c.method.connection.SECURE_OK] = {
      name = "secure_ok"
    },
    --[[
    channel_max i16
    frame_max i32
    beartbeat i16
    --]]
    [c.method.connection.TUNE] = {
      name = "tune",
      r = function(b)
        local f = {}
        f.channel_max = b:get_i16()
        f.frame_max = b:get_i32()
        f.heartbeat = b:get_i16()
        return f
      end
    },
    --[[
    channel_max i16
    frame_max i32
    heartbeat i16
    --]]
    [c.method.connection.TUNE_OK] = {
      name = "tune_ok",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.channel_max)
        b:put_i32(method.frame_max)
        b:put_i16(method.heartbeat or c.DEFAULT_HEARTBEAT)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.channel_max = b:get_i16()
        f.frame_max = b:get_i32()
        f.heartbeat = b:get_i16()
        return f
      end
    },
    --[[
    virtual_host short_string,
    reserved-1(capabilities) octet
    reserved-2 octet
    --]]
    [c.method.connection.OPEN] = {
      name = "open",
      w = function(method)
        local b = buffer.new()
        b:put_short_string(method.virtual_host)
        b:put_i8(0) -- capabilities
        b:put_i8(1) -- insist?
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.virtual_host = b:get_short_string()
        f.capabilities = b:get_i8()
        f.insist = b:get_i8()
        return f
      end
    },
    --[[
    reserved-1 short_string
    --]]
    [c.method.connection.OPEN_OK] = {
      name = "open_ok",
      r = function(b)
        return { reserved1 = b:get_short_string() }
      end
    },
    --[[
    reply_code i16
    reply_text short_string
    class_id i16
    method_id i16
    --]]
    [c.method.connection.CLOSE] = {
      name = "close",
      r = decode_close_reply,
      w = encode_close_reply
    },
    --[[
    --]]
    [c.method.connection.CLOSE_OK] = {
      name = "close_ok",
      r = nop,
      w = nop
    },
    --[[
    reason short_string
    --]]
    [c.method.connection.BLOCKED] = {
      name = "blocked",
      r = function(b)
        return {reason = b:get_short_string()}
      end,
      w = function(method)
        local b = buffer.new()
        b:put_short_string(method.reason)
        return b:payload()
      end
    },
    --[[
    --]]
    [c.method.connection.UNBLOCKED] = {
      name = "unblocked",
      r = function(--[[b--]])
        return nil
      end,
      w = function(--[[method--]])
        return nil
      end
    }
  },
  [c.class.CHANNEL] = {
    name = "channel",
    [c.method.channel.OPEN] = {
      name = "open",
      w = function(--[[method--]])
        -- reserved?
        return '\0'
      end,
      r = function(--[[method--]])
        return '\0'
      end
    },
    [c.method.channel.OPEN_OK] = {
      name = "open_ok",
      r = function(b)
        return {
          reserved1 = b:get_long_string()
        }
      end
    },
    --[[
    active bit
    --]]
    [c.method.channel.FLOW] = {
      name = "flow",
      r = function(b)
        return { active = b:get_bool() }
      end,
      w = function(method)
        local b = buffer.new()
        b:put_bool(method.active)
        return b:payload()
      end

    },
    [c.method.channel.FLOW_OK] = {
      name = "flow_ok",
      r = function(b)
        local bits = b:get_i8()
        return { active = band(bits,1) }
      end,
      w = function(method)
        local b = buffer.new()
        b:put_bool(method.active)
        return b:payload()
      end
    },
    --[[
    reply_code i16
    reply_text short_string
    class_id i16
    method_id i16
    --]]
    [c.method.channel.CLOSE] = {
      name = "close",
      r = decode_close_reply,
      w = encode_close_reply
    },
    [c.method.channel.CLOSE_OK] = {
      name = "close_ok",
      r = nop,
      w = nop
    },
  },
  [c.class.EXCHANGE] = {
    name = "exchange",
    --[[
    reserved1 i16
    exchange short_string
    type short_string
    passive bit
    durable bit
    auto_delete bit
    internal bit
    no_wait bit
    arguments table
    --]]
    [c.method.exchange.DECLARE] = {
      name = "declare",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.exchange)
        b:put_short_string(method.typ)
        b:put_i8(declare_exchange_flags(method))
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.exchange = b:get_short_string()
        f.typ = b:get_short_string()
        f.exchange_flags = parse_exchange_flags(b:get_i8())
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.exchange.DECLARE_OK] = {
      name = "declare_ok",
      r = nop
    },
    --[[
    reserved1 i16
    destination short_string
    source short_string
    routing_key short_string
    no_wait bit
    arguments table
    --]]
    [c.method.exchange.BIND] = {
      name = "bind",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.destination)
        b:put_short_string(method.source)
        b:put_short_string(method.routing_key)
        b:put_bool(method.no_wait)
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.destination = b:get_short_string()
        f.source = b:get_short_string()
        f.routing_key = b:get_short_string()
        f.no_wait = b:get_bool()
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.exchange.BIND_OK] = {
      name = "bind_ok",
      r = nop
    },
    --[[
    --]]
    [c.method.exchange.DELETE] = {
      name = "delete",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.exchange)
        local bits = 0
        if method.if_unused then
          bits = bor(bits,1)
        end
        if method.no_wait then
          bits = bor(bits,2)
        end
        b:put_i8(bits)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.exchange = b:get_short_string()
        f.exchange_flags = parse_exchange_delete_flags(b:get_i8())
        return f
      end
    },
    [c.method.exchange.DELETE_OK] = {
      name = "delete_ok",
      r = nop
    },
    --[[
    --]]
    [c.method.exchange.UNBIND] = {
      name = "unbind",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.destination)
        b:put_short_string(method.source)
        b:put_short_string(method.routing_key)
        b:put_bool(method.no_wait)
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.destination = b:get_short_string()
        f.source = b:get_short_string()
        f.routing_key = b:get_short_string()
        f.no_wait = b:get_bool()
        f.arguments = b:gut_field_table()
        return f
      end
    },
    [c.method.exchange.UNBIND_OK] = {
      name = "unbind_ok",
      r = nop
    },
  },
  [c.class.QUEUE] = {
    name = "queue",
    [c.method.queue.DECLARE] = {
      name = "declare",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.ticket or 0)
        b:put_short_string(method.queue)
        local bits = declare_queue_flags(method)
        b:put_i8(bits)
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.ticket = b:get_i16()
        f.queue =  b:get_short_string()
        f.queue_flags = parse_queue_flags(b:get_i8())
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.queue.DECLARE_OK] = {
      name = "declare_ok",
      r = function(b)
        local f = {}
        f.queue = b:get_short_string()
        f.message_count = b:get_i32()
        f.consumer_count = b:get_i32()
        return f
      end
    },
    [c.method.queue.BIND] = {
      name = "bind",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.queue)
        b:put_short_string(method.exchange)
        b:put_short_string(method.routing_key or "")
        b:put_bool(method.no_wait)
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.queue = b:get_short_string()
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        f.no_wait = b:get_bool()
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.queue.BIND_OK] = {
      name = "bind_ok",
      r = nop
    },
    --[[
    reserved1 i16
    queue short_string
    if_unused bit
    if_empty bit
    no_wait bit
    --]]
    [c.method.queue.DELETE] = {
      name = "delete",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.queue)
        local bits = 0
        if method.if_unused then
          bits = bor(bits,1)
        end
        if method.if_empty then
          bits = bor(bits,2)
        end
        if method.no_wait then
          bits = bor(bits, 4)
        end
        b:put_i8(bits)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.queue = b:get_short_string()
        f.queue_flags = parse_queue_delete_flags(b:get_i8())
        return f
      end
    },
    --[[
    message_count i32
    --]]
    [c.method.queue.DELETE_OK] = {
      name = "delete_ok",
      r = function(b)
        return {
          message_count = b:get_i32()
        }
      end
    },
    [c.method.queue.UNBIND] = {
      name = "unbind",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.queue)
        b:put_short_string(method.exchange)
        b:put_short_string(method.routing_key or "")
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.queue = b:get_short_string()
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.queue.UNBIND_OK] = {
      name = "unbind_ok",
      r = nop
    },
    --[[
    reserved1 i16
    queue short_string
    no_wait bit
    --]]
    [c.method.queue.PURGE] = {
      name = "queue_purge",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.queue)
        local bits = 0
        if method.no_wait then
          bits = bor(bits, 1)
        end
        b:put_i8(bits)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.queue = b:get_short_string()
        f.queue_flags = { no_wait = toboolean(b:get_i8(), 1) }
        return f
      end
    },
    --[[
    message_count i32
    --]]
    [c.method.queue.PURGE_OK] = {
      name = "purge_ok",
      r = function(b)
        return {
          message_count = b:get_i32()
        }
      end
    },


  },
  [c.class.BASIC] = {
    name = "basic",
    [c.method.basic.CONSUME] = {
      name = "consume",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.ticket or 0)
        b:put_short_string(method.queue)
        b:put_short_string(method.consumer_tag or "")
        b:put_i8(basic_consume_flags(method))
        b:put_field_table(method.arguments or {})
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.ticket = b:get_i16()
        f.queue = b:get_short_string()
        f.consumer_tag = b:get_short_string()
        f.consume_flags = parse_consume_flags(b:get_i8())
        f.arguments = b:get_field_table()
        return f
      end
    },
    [c.method.basic.CONSUME_OK] = {
      name = "consume_ok",
      r = function(b)
        return {
          consumer_tag = b:get_short_string()
        }
      end
    },
    --[[
    consumer_tag short_string
    delivery_tag i64
    redelivered bool
    exchange short_string
    routing_key short_string
    --]]
    [c.method.basic.DELIVER] = {
      name = "deliver",
      r = function(b)
        local f = {}
        f.consumer_tag = b:get_short_string()
        f.delivery_tag = b:get_i64()
        f.redelivered = b:get_i8()
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        return f
      end,
      w = function(method)
        local b = buffer.new()
        b:put_short_string(method.consumer_tag)
        b:put_i64(method.delivery_tag)
        b:put_bool(method.redelivered)
        b:put_short_string(method.exchange)
        b:put_short_string(method.routing_key)
        return b:payload()
      end
    },
    --[[
    prefectch_size i32
    prefetch_count i16
    global bit
    --]]
    [c.method.basic.QOS] = {
      name = "qos",
      w = function(method)
        local b = buffer.new()
        b:put_i32(method.prefetch_size)
        b:put_i16(method.prefetch_count)
        b:put_bool(method.global)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.prefetch_size = b:get_i32()
        f.prefetch_count = b:get_i16()
        f.global = b:get_bool()
        return f
      end
    },
    [c.method.basic.QOS_OK] = {
      name = "qos_ok",
      r = nop
    },
    --[[
    consumer_tag short_string
    no_wait bit
    --]]
    [c.method.basic.CANCEL] = {
      name = "cancel",
      w = function(method)
        local b = buffer.new()
        b:put_short_string(method.consumer_tag)
        b:put_bool(method.no_wait)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.consumer_tag = b:get_short_string()
        f.no_wait = b:get_bool()
        return f
      end
    },
    [c.method.basic.CANCEL_OK] = {
      name = "cancel_ok",
      r = function(b)
        return {
          consumer_tag = b:get_short_string()
        }
      end
    },
    --[[
    reserved1 i16
    queue short_string
    no_ack bit
    --]]
    [c.method.basic.GET] = {
      name = "get",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.queue)
        b:put_bool(method.no_ack)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.queue = b:get_short_string()
        f.no_ack = b:get_bool()
        return f
      end
    },
    --[[
    delivery_tag i64
    redelivered bool
    exchange short_string
    routing_key short_string
    message_count i32
    --]]
    [c.method.basic.GET_OK] = {
      name = "get_ok",
      r = function(b)
        local f = {}
        f.delivery_tag = b:get_i64()
        f.redelivered = b:get_bool()
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        f.message_count = b:get_i32()
        return f
      end
    },
    --[[
    requeue bit
    --]]
    [c.method.basic.RECOVER] = {
      name = "recover",
      w = function(method)
        local b = buffer.new()
        b:put_bool(method.requeue)
        return b:payload()
      end,
      r = function(b)
        return {
          requeue = b:get_bool()
        }
      end
    },
    [c.method.basic.RECOVER_OK] = {
      name = "recover_ok",
      r = nop
    },
    [c.method.basic.RECOVER_ASYNC] = {
      name = "recover_async",
      w = function(method)
        local b = buffer.new()
        b:put_bool(method.requeue)
        return b:payload()
      end,
      r = function(b)
        return {
          requeue = b:get_bool()
        }
      end
    },
    --[[
    reserved1 i16
    exchange short_string
    routing_key short_string
    mandatory bit
    immediate bit
    --]]
    [c.method.basic.PUBLISH] = {
      name = "publish",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reserved1 or 0)
        b:put_short_string(method.exchange)
        b:put_short_string(method.routing_key)
        local bits = 0
        if method.mandatory then
          bits = bor(bits,1)
        end
        if method.immediate then
          bits = bor(bits,2)
        end
        b:put_i8(bits)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        local _,reserved1 = pcall(buffer.get_i16, b)
        f.reserved1 = reserved1 or 0
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        local bits = b:get_i8()
        f.mandatory = band(bits,1)
        f.immediate = band(bits,2)
        return f
      end
    },
    --[[
    reply_code i16
    reply_text short_string
    exchange short_string
    routing_key short_string
    --]]
    [c.method.basic.RETURN] = {
      name = "return",
      w = function(method)
        local b = buffer.new()
        b:put_i16(method.reply_code)
        b:put_short_string(method.reply_text)
        b:put_short_string(method.exchange)
        b:put_short_string(method.routing_key)
        return b:payload()
      end,
      r = function(b)
        local f = {}
        f.reply_code = b:get_i16()
        f.reply_text = b:get_short_string()
        f.exchange = b:get_short_string()
        f.routing_key = b:get_short_string()
        return f
      end
    },
    --[[
    reserved1 i16
    --]]
    [c.method.basic.GET_EMPTY] = {
      name = "get_emtpy",
      r = function(b)
        local _,reserved1 = pcall(buffer.get_i16, b)
        return {
          reserved1 = reserved1 or 0
        }
      end
    },
    --[[
    delivery_tag i64
    multiple bit
    --]]
    [c.method.basic.ACK] = {
      name = "ack",
      r = function(b)
        local method = {}
        method.delivery_tag = b:get_i64()
        method.multiple = b:get_bool()
        return method
      end,
      w = function(method)
        local b = buffer.new()
        b:put_i64(method.delivery_tag)
        b:put_bool(method.multiple)
        return b:payload()
      end
    },
    --[[
    delivery_tag i64
    multiple bit
    requeue bit
    --]]
    [c.method.basic.NACK] = {
      name = "nack",
      r = function(b)
        local f = {}
        f.delivery_tag = b:get_i64()
        local v = b:get_i8()
        f.multiple = (band(v,0x1) ~= 0)
        f.requeue = (band(v,0x2) ~= 0)
        return f
      end,
      w = function(method)
        local b = buffer.new()
        b:put_i64(method.delivery_tag)
        local bits = 0
        if method.multiple and method.multiple ~= 0 then
          bits = bor(bits, 1)
        end
        if method.requeue and method.requeue ~= 0 then
          bits = bor(bit, 2)
        end
        b:put_i16(bits)
        return b:payload()
      end
    },
    --[[
    delivery_tag i64
    requeue bit
    --]]
    [c.method.basic.REJECT] = {
      name = "reject",
      r = function(b)
        local f = {}
        f.delivery_tag = b:get_i64()
        f.requeue = b:get_bool()
        return f
      end,
      w = function(method)
        local b = buffer.new()
        b:put_i64(method.delivery_tag)
        b:put_bool(method.requeue)
        return b:payload()
      end
    },

  },
  [c.class.TX] = {
    name = "tx",
    [c.method.tx.SELECT] = {
      name = "select",
      r = nop,
      w = nop
    },
    [c.method.tx.SELECT_OK] = {
      name = "select_ok",
      r = nop,
      w = nop
    },
    [c.method.tx.COMMIT] = {
      name = "commit",
      r = nop,
      w = nop
    },
    [c.method.tx.COMMIT_OK] = {
      name = "commit_ok",
      r = nop,
      w = nop
    },
    [c.method.tx.ROLLBACK] = {
      name = "rollback",
      r = nop,
      w = nop
    },
    [c.method.tx.ROLLBACK_OK] = {
      name = "rollback_ok",
      r = nop,
      w = nop
    },

  },
  [c.class.CONFIRM] = {
    name = "confirm",
    --[[
    no_wait bit
    --]]
    [c.method.confirm.SELECT] = {
      name = "select",
      w = function(method)
        local b = buffer.new()
        b:put_bool(method.no_wait)
        return b:payload()
      end,
      r = function(b)
        return {
          no_wait = b:get_bool()
        }
      end
    },
    [c.method.confirm.SELECT_OK] = {
      name = "select_ok",
      r = nop
    },
  }
}

--
-- decoder
--

local function method_frame(data,channel)
  local frame = { channel = channel }
  local b = buffer.new(data)
  if is_debug_enabled() then
    debug("[method_frame]",b:hex_dump())
  end
  local class_id = b:get_i16()
  local method_id = b:get_i16()
  frame.class_id = class_id
  frame.method_id = method_id
  debug("[method_frame] class_id:",class_id, "method_id:", method_id)
  local codec = methods_[class_id][method_id]
  if not codec then
    local err = "[method_frame]: no codec for class: " .. class_id .. " method: " .. method_id
    return nil,err
  end

  if not codec.r then
    local err = "[method_frame]: no decoder for class: " .. class_id .. " method: " .. method_id
    return nil, err
  end
  debug("[method_frame] class:",methods_[class_id].name, "method:", codec.name)
  frame.method = codec.r(b)
  return frame
end

local function header_frame(data,channel)

  local frame = { channel = channel, properties = {} }
  local b = buffer.new(data)

  if is_debug_enabled() then
    debug("[header_frame]",b:hex_dump())
  end

  frame.class_id = b:get_i16()
  frame.weight = b:get_i16()
  frame.body_size = b:get_i64()

  local flag = b:get_i16()

  frame.flag = flag

  if band(flag,c.flag.CONTENT_TYPE) ~= 0 then
    frame.properties.content_type= b:get_short_string()
  end

  if band(flag,c.flag.CONTENT_ENCODING) ~= 0 then
    frame.properties.content_encoding = b:get_short_string()
  end

  if band(flag,c.flag.HEADERS) ~= 0 then
    frame.properties.headers = b:get_field_table()
  end

  if band(flag,c.flag.DELIVERY_MODE) ~= 0 then
    frame.properties.delivery_mode = b:get_i8()
  end

  if band(flag,c.flag.PRIORITY) ~= 0 then
    frame.properties.priority = b:get_i8()
  end

  if band(flag,c.flag.CORRELATION_ID) ~= 0 then
    frame.properties.correlation_id = b:get_short_string()
  end

  if band(flag,c.flag.REPLY_TO) ~= 0 then
    frame.properties.reply_to = b:get_short_string()
  end

  if band(flag,c.flag.EXPIRATION) ~= 0 then
    frame.properties.expiration = b:get_short_string()
  end

  if band(flag,c.flag.MESSAGE_ID) ~= 0 then
    frame.properties.message_id = b:get_short_string()
  end

  if band(flag,c.flag.TIMESTAMP) ~= 0 then
    frame.properties.timestamp = b:get_timestamp()
  end

  if band(flag,c.flag.TYPE) ~= 0 then
    frame.properties.type = b:get_short_string()
  end

  if band(flag,c.flag.USER_ID) ~= 0 then
    frame.properties.user_id = b:get_short_string()
  end

  if band(flag,c.flag.APP_ID) ~= 0 then
    frame.properties.app_id = b:get_short_string()
  end

  if band(flag,c.flag.RESERVED1) ~= 0 then
    frame.properties.reserved1 = b:get_short_string()
  end

  return frame
end

local function body_frame(data,channel)
  local frame = { channel = channel }
  local b = buffer.new(data)
  if is_debug_enabled() then
    debug("[body_frame]",b:hex_dump())
  end
  frame.body = b:payload()
  return frame
end


local function heartbeat_frame(channel,size)
  local frame = { channel = channel }
  if size > 0 then
    return nil
  end
  return frame
end

local match = string.match

if _G.ngx and _G.ngx.match then
  match = _G.ngx.match
end

function amqp_frame.consume_frame(ctx)

  local ok
  local err
  local fe
  local data


  data,err = ctx:receive(7)

  if not data then
    return nil, err
  end

  local b = buffer.new(data)
  if is_debug_enabled() then
    debug("[frame] take the first 7 octets: ",b:hex_dump())
  end

  local typ = b:get_i8()
  local channel = b:get_i16()
  local size = b:get_i32()

  data, err = ctx:receive(size)

  if not data then
    return nil, err
  end
  if typ == c.frame.METHOD_FRAME then
    ok,fe,err = pcall(method_frame,data,channel)
  elseif typ == c.frame.HEADER_FRAME then
    ok,fe,err = pcall(header_frame,data,channel)
  elseif typ == c.frame.BODY_FRAME then
    ok,fe,err = pcall(body_frame,data,channel)
  elseif typ == c.frame.HEARTBEAT_FRAME then
    ok,fe,err = pcall(heartbeat_frame,channel,size)
  else
    ok = nil
    err = "invalid frame type"
  end

  -- THE END --
  local ok0,err0 = ctx:receive(1)
  if not ok0 then
    return nil,err0
  end

  local tk = byte(ok0,1)
  if tk ~= c.frame.FRAME_END then
    if match(data, "^AMQP") then
      return nil, "connect event"
    end
    return nil,"malformed frame: no frame_end"
  end

  -- err captured by pcall, most likely, due to malformed frames
  if not ok then
    return nil, fe
  end

  -- other errors
  if not fe then
    return nil, err
  end

  fe.type = typ
  return fe, nil
end

--
-- encoder
--

local function encode_frame(typ,channel,payload)
  payload = payload or ""
  local size = #payload
  local b = buffer.new()
  b:put_i8(typ)
  b:put_i16(channel)
  b:put_i32(size)
  b:put_payload(payload)
  b:put_i8(c.frame.FRAME_END)
  return b:payload()
end

local function encode_method_frame(frame)
  local b = buffer.new()
  b:put_i16(frame.class_id)
  b:put_i16(frame.method_id)
  local payload = methods_[frame.class_id][frame.method_id].w(frame.method)
  if payload then
    b:put_payload(payload)
  end
  return encode_frame(c.frame.METHOD_FRAME,frame.channel,b:payload())
end

local function flags_mask(frame)
  local mask = 0
  if not frame.properties then
    return mask
  end
  if frame.properties.content_type ~= nil then
    mask = bor(mask,c.flag.CONTENT_TYPE)
  end
  if frame.properties.content_encoding ~= nil then
    mask = bor(mask,c.flag.CONTENT_ENCODING)
  end
  if frame.properties.headers ~= nil then
    mask = bor(mask,c.flag.HEADERS)
  end
  if frame.properties.delivery_mode ~= nil then
    mask = bor(mask,c.flag.DELIVERY_MODE)
  end
  if frame.properties.priority ~= nil then
    mask = bor(mask,c.flag.PRIORITY)
  end
  if frame.properties.correlation_id ~= nil then
    mask = bor(mask,c.flag.CORRELATION_ID)
  end
  if frame.properties.reply_to ~= nil then
    mask = bor(mask,c.flag.REPLY_TO)
  end
  if frame.properties.expiration ~= nil then
    mask = bor(mask,c.flag.EXPIRATION)
  end
  if frame.properties.timestamp ~= nil then
    mask = bor(mask,c.flag.TIMESTAMP)
  end
  if frame.properties.type ~= nil then
    mask = bor(mask,c.flag.TYPE)
  end
  if frame.properties.user_id ~= nil then
    mask = bor(mask,c.flag.USER_ID)
  end
  if frame.properties.app_id ~= nil then
    mask = bor(mask,c.flag.APP_ID)
  end
  return mask
end

local function encode_header_frame(frame)
  local b = buffer.new()
  b:put_i16(frame.class_id)
  b:put_i16(frame.weight)
  b:put_i64(frame.size)

  local flags = flags_mask(frame)
  b:put_i16(flags)
  if band(flags,c.flag.CONTENT_TYPE) ~= 0 then
    b:put_short_string(frame.properties.content_type)
  end

  if band(flags,c.flag.CONTENT_ENCODING) ~= 0 then
    b:put_short_string(frame.properties.content_encoding)
  end

  if band(flags,c.flag.HEADERS) ~= 0 then
    b:put_field_table(frame.properties.headers)
  end

  if band(flags,c.flag.DELIVERY_MODE) ~= 0 then
    b:put_i8(frame.properties.delivery_mode)
  end

  if band(flags,c.flag.PRIORITY) ~= 0 then
    b:put_i8(frame.properties.priority)
  end

  if band(flags,c.flag.CORRELATION_ID) ~= 0 then
    b:put_short_string(frame.properties.correlation_id)
  end

  if band(flags,c.flag.REPLY_TO) ~= 0 then
    b:put_short_string(frame.properties.reply_to)
  end

  if band(flags,c.flag.EXPIRATION) ~= 0 then
    b:put_short_string(frame.properties.expiration)
  end

  if band(flags,c.flag.MESSAGE_ID) ~= 0 then
    b:put_short_string(frame.properties.message_id)
  end

  if band(flags,c.flag.TIMESTAMP) ~= 0 then
    b:put_time_stamp(frame.properties.timestamp)
  end

  if band(flags,c.flag.TYPE) ~= 0 then
    b:put_short_string(frame.properties.type)
  end

  if band(flags,c.flag.USER_ID) ~= 0 then
    b:put_short_string(frame.properties.user_id)
  end

  if band(flags,c.flag.APP_ID) ~= 0 then
    b:put_short_string(frame.properties.app_id)
  end

  return encode_frame(c.frame.HEADER_FRAME,frame.channel,b:payload())
end

local function encode_body_frame(frame)
  return encode_frame(c.frame.BODY_FRAME,frame.channel,frame.body)
end

local function encode_heartbeat_frame(frame)
  return encode_frame(c.frame.HEARTBEAT_FRAME,frame.channel,nil)
end

local mt = { __index = amqp_frame }

--
-- new a frame
--

function amqp_frame.new(typ,channel)
  return setmetatable({ typ = typ, channel = channel }, mt)
end

function amqp_frame.new_method_frame(channel,class_id,method_id)
  local frame = amqp_frame.new(c.frame.METHOD_FRAME, channel)
  frame.class_id = class_id
  frame.method_id = method_id
  return frame
end

function amqp_frame:encode()
  local typ = self.typ
  if not typ then
    local err = "no frame type specified."
    logger.error("[frame.encode] " .. err)
    return nil,err
  end

  if typ == c.frame.METHOD_FRAME then
    return encode_method_frame(self)
  elseif typ == c.frame.HEADER_FRAME then
    return encode_header_frame(self)
  elseif typ == c.frame.BODY_FRAME then
    return encode_body_frame(self)
  elseif typ == c.frame.HEARTBEAT_FRAME then
    return encode_heartbeat_frame(self)
  else
    local err = "invalid frame type" .. tostring(typ)
    logger.error("[frame.encode]" .. err)
    return nil, err
  end
end

--
-- protocol
--

function amqp_frame.wire_protocol_header(ctx)
  local bytes, err = ctx:send("AMQP\0\0\9\1")
  if not bytes then
    return nil, err
  end
  return amqp_frame.consume_frame(ctx)
end

function amqp_frame.wire_heartbeat(ctx)
  local frame = amqp_frame.new(c.frame.HEARTBEAT_FRAME,c.DEFAULT_CHANNEL)
  local msg = frame:encode()
  local bytes, err = ctx:send(msg)
  if not bytes then
    return nil,"[heartbeat]" .. err
  end

  return bytes
end

function amqp_frame.wire_header_frame(ctx,body_size,properties)
  local frame = amqp_frame.new(c.frame.HEADER_FRAME,ctx.opts.channel or 1)
  frame.class_id = c.class.BASIC
  frame.weight = 0
  frame.size = body_size
  frame.properties = properties
  local msg = frame:encode()
  local bytes, err = ctx:send(msg)
  if not bytes then
    return nil,"[wire_header_frame]" .. err
  end

  return bytes
end

function amqp_frame.wire_body_frame(ctx,payload)
  local frame = amqp_frame.new(c.frame.BODY_FRAME,ctx.opts.channel or 1)
  frame.class_id = c.class.BASIC
  frame.body = payload
  local msg = frame:encode()
  local bytes, err = ctx:send(msg)
  if not bytes then
    return nil,"[wire_body_frame]" .. err
  end
  return bytes
end


local function is_channel_close_received(frame)
  return frame ~= nil and frame.class_id == c.class.CHANNEL and frame.method_id == c.method.channel.CLOSE
end

local function is_connection_close_received(frame)
  return frame ~= nil and frame.class_id == c.class.CONNECTION and frame.method_id == c.method.connection.CLOSE
end


local function ongoing(ctx,frame)
  ctx.ongoing = ctx.ongoing or {}
  ctx.ongoing.class_id = frame.class_id
  ctx.ongoing.method_id = frame.method_id
end

function amqp_frame.wire_method_frame(ctx,frame)
  local f

  local msg = frame:encode()
  local bytes,err = ctx:send(msg)

  if not bytes then
    return nil,"[wire_method_frame]" .. err
  end

  debug("[wire_method_frame] wired a frame.", "[class_id]: ", frame.class_id, "[method_id]: ", frame.method_id)

  if frame.method ~= nil and not frame.method.no_wait then

    f, err = amqp_frame.consume_frame(ctx)

    if f then
      debug("[wire_method_frame] channel: ",f.channel)
      if f.method then
        debug("[wire_method_frame] method: ",f.method)
      end

      if is_channel_close_received(f) then
        ctx.channel_state = c.state.CLOSE_WAIT
        ongoing(ctx,frame)
        return nil, f.method.reply_code, f.method.reply_text
      end

      if is_connection_close_received(f) then
        ctx.channel_state = c.state.CLOSED
        ctx.connection_state = c.state.CLOSE_WAIT
        ongoing(ctx,frame)
        return nil, f.method.reply_code, f.method.reply_text
      end
    end
    return f, err
  end
  return true
end

return amqp_frame
