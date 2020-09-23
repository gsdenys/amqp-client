--
-- Copyright (C) 2016 Meng Zhang @ Yottaa,Inc
-- Copyright (C) 2018 4mig4
-- Copyright (C) 2019 gsdenys
--

local c = require ('amqp.consts')
local frame = require ('amqp.frame')
local logger = require ('amqp.logger')
local bit = require('bit')

local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift

local format = string.format
local gmatch = string.gmatch
local min = math.min

local socket
local tcp

local use_cqueues, lfs = pcall(require,"cqueues")

local amqp = {}

-- let ngx.socket take precedence to lua socket
--[[
if _G.ngx and _G.ngx.socket then
  logger.dbg("[socket] Unsing ngx socket.")
  socket = _G.ngx.socket
  tcp = socket.tcp
else
--]]
if use_cqueues == true then
  logger.dbg("[socket] Unsing cqueues socket.")
  socket = require('cqueues.socket')
  tcp = socket
else
  logger.dbg("[socket] Unsing lua socket.")
  socket = require("socket")
  tcp = socket.tcp
end


if use_cqueues == true then
  function amqp:send(str)
    if self.sock == nil then
      return false, 'sock is nil'
    else
      local ok, err = pcall(self.sock.xwrite, self.sock, str, 'bnf')
      if not ok then
        if err then
          return nil, err
        else
          return nil, 'self.sock.xwrite failed'
        end
      else
        return err
      end
    end
  end
  function amqp:receive(int)
    if self.sock == nil then
      return false, 'sock is nil'
    else
      local ok, err = pcall(self.sock.xread, self.sock, int)
      if not ok then
        if err then
          return nil, err
        else
          return nil, 'self.sock.xread failed'
        end
      else
        return err
      end
    end
  end
else
  function amqp:send(str) return self.sock:send(str) end
  function amqp:receive(int) return self.sock:receive(int) end
end

-- getopt(key, table, table, ..., value)
-- return the key's value from the first table that has it, or VALUE if none do
local  function _getopt(k,t,...)
  if select('#',...)==0 then
    return t
  elseif t[k]~=nil then
    return t[k]
  else
    return _getopt(k,...)
  end
end

-- to check whether we have valid parameters to setup
local function mandatory_options(opts)
  if not opts then
    error("no opts provided")
  end

  if type(opts) ~= "table" then
    error("opts is not valid")
  end

  if (opts.role == nil or opts.role == "consumer") and not opts.queue then
    error("as a consumer, queue is required")
  end
end


--
-- initialize the context
--
function amqp:new(opts)
  local sock, err
  local mt = { __index = self }

  mandatory_options(opts)

  if use_cqueues == true then
    sock = tcp
  else
    sock, err = tcp()
  end

  if not sock then
    return nil, err
  end

  local ctx = {
    sock = sock,
    ssl_ctx = opts.ssl_ctx or nil,
    opts = opts,
    connection_state = c.state.CLOSED,
    channel_state = c.state.CLOSED,
    major = c.PROTOCOL_VERSION_MAJOR,
    minor = c.PROTOCOL_VERSION_MINOR,
    revision = c.PROTOCOL_VERSION_REVISION,
    frame_max = c.DEFAULT_FRAME_SIZE,
    channel_max = c.DEFAULT_MAX_CHANNELS,
    mechanism = c.MECHANISM_PLAIN
  }

  setmetatable(ctx,mt)

  return ctx
end

local function sslhandshake(ctx)
  local sock = ctx.sock
  local ssl_ctx = ctx.ssl_ctx

  local session
  local err
  local errno

  if _G.ngx then
    session, err = sock:sslhandshake()
    if not session then
      logger.error("[amqp:sslhandshake] SSL handshake failed: ", err)
    end

    return session, err -- return
  elseif use_cqueues == true then
    if ssl_ctx then
      session, err, errno = sock:starttls(ssl_ctx)
    else
      session, err, errno = sock:starttls()
    end
    if not session then
      logger.error("[amqp:sslhandshake] SSL handshake failed: ", err)
    end

    return session, err -- return
  end

  -- if none of the above then continue down

  local ssl = require("ssl") -- require library only for socket

  local default_params = {
    mode = "client",
    protocol = "any",
    verify = "none",
    options = {"all", "no_sslv2","no_sslv3"}
  }

  local wsock, err = ssl.wrap(sock, ssl_ctx or default_params)

  if not wsock then
    logger.error("[amqp:sslhandshake] Socket wrapping failed: ", err)
    return wsock, err -- return
  else
    logger.dbg("[amqp:sslhandshake] Wrapped socket")
    ctx.sock = wsock
  end

  local ok, msg = ctx.sock:dohandshake()

  if not ok then
    logger.error("[amqp:sslhandshake] SSL handshake failed: ", msg)
  else
    logger.dbg("[amqp:sslhandshake] SSL handshake")
  end

  return ok, msg -- return
end



-- connect to the AMQP server (broker)
--

function amqp:connect(...)
  local sock = self.sock
  if not sock then
    return nil, "not initialized"
  end

  self._subscribed = false

  if use_cqueues == true then
    local s, err = sock.connect(...)
    if not s then
      logger.error("[amqp:connect] failed: ", err)
      return nil, err
    else
      self.sock = s
      self.sock:settimeout(self.opts.connect_timeout or 5000) -- configurable but 5 seconds timeout
    end
  else
    sock:settimeout(self.opts.connect_timeout or 5000) -- configurable but 5 seconds timeout
    local ok, err = sock:connect(...)
    if not ok then
      logger.error("[amqp:connect] failed: ", err)
      return nil, err
    end
  end

  if self.opts.ssl then
    return sslhandshake(self)
  end
  return true
end


-- to close the socket
--
function amqp:close()
  local sock = self.sock
  if not sock then
    return nil, "not initialized"
  end
  return sock:close()
end


local function platform()
  local has_jit, jit = pcall(require, "jit")
  if has_jit then
    return jit.os .. "_" .. jit.arch
  end
  return "posix"
end


-- connection and channel
--

function amqp:connection_start_ok()
  local user = self.opts.user or "guest"
  local password = self.opts.password or "guest"
  local f = frame.new_method_frame(c.DEFAULT_CHANNEL,
  c.class.CONNECTION,
  c.method.connection.START_OK)
  f.method = {
    properties = {
      product = c.PRODUCT,
      version = c.VERSION,
      platform = platform(),
      copyright = c.COPYRIGHT,
      capabilities = {
        authentication_failure_close = true
      }
    },
    mechanism = self.mechanism,
    response = format("\0%s\0%s", user, password),
    locale = c.LOCALE
  }

  return frame.wire_method_frame(self, f)
end

function amqp:connection_tune_ok()
  local f = frame.new_method_frame(c.DEFAULT_CHANNEL,
    c.class.CONNECTION,
    c.method.connection.TUNE_OK)
  f.method = {
    no_wait = true,
    channel_max = self.channel_max or c.DEFAULT_MAX_CHANNELS,
    frame_max = self.frame_max or c.DEFAULT_FRAME_SIZE,
    heartbeat = self.opts.heartbeat or c.DEFAULT_HEARTBEAT
  }
  return frame.wire_method_frame(self,f)
end

function amqp:connection_open()
  local f = frame.new_method_frame(c.DEFAULT_CHANNEL,
  c.class.CONNECTION,
  c.method.connection.OPEN)
  f.method = {
    virtual_host = self.opts.virtual_host or "/"
  }

  return frame.wire_method_frame(self,f)
end

local function sanitize_close_reason(ctx, reason)
  reason = reason or {}
  local ongoing = ctx.ongoing or {}
  return {
    reply_code = reason.reply_code or c.err.CONNECTION_FORCED,
    reply_text = reason.reply_text or "",
    class_id = ongoing.class_id or 0,
    method_id = ongoing.method_id or 0
  }
end

function amqp:connection_close(reason)
  local f = frame.new_method_frame(c.DEFAULT_CHANNEL,
    c.class.CONNECTION,
    c.method.connection.CLOSE)
  f.method = sanitize_close_reason(self, reason)
  return frame.wire_method_frame(self,f)
end


function amqp:connection_close_ok()
  local f = frame.new_method_frame(self.channel or 1,
    c.class.CONNECTION,
    c.method.connection.CLOSE_OK)
  return frame.wire_method_frame(self,f)
end

--- method to open an AMQP channel
-- @param none implied self (context)
-- @return the channel number

function amqp:channel_open()
  local f = frame.new_method_frame(self.opts.channel or 1,
  c.class.CHANNEL,
  c.method.channel.OPEN)
  f.method = { no_wait = false }
  logger.dbg("[channel_open] wired a frame", "[class_id]: ", f.class_id, "[method_id]: ", f.method_id)
  local res, err = frame.wire_method_frame(self,f)
  if res then
    logger.dbg("[channel_open] channel: ", res.channel)
    self.channel = res.channel
  end
  return res, err
end

function amqp:channel_close(reason)
  local f = frame.new_method_frame(self.channel or c.DEFAULT_CHANNEL, c.class.CHANNEL, c.method.channel.CLOSE)
  f.method = sanitize_close_reason(self, reason)
  return frame.wire_method_frame(self,f)
end

function amqp:channel_close_ok()
  local f = frame.new_method_frame(self.channel or 1, c.class.CHANNEL, c.method.channel.CLOSE_OK)
  return frame.wire_method_frame(self,f)
end

--- check if protocol version matches
-- @param self (context)
-- @param major major version of the protocol
-- @param minor minor version of the protocol
-- @return true or false

local function is_version_acceptable(self,major,minor)
  return self.major == major and self.minor == minor
end

local function is_mechanism_acceptable(self,method)
  local mechanism = method.mechanism
  if not mechanism then
    return nil, "broker does not support any mechanism"
  end
  for me in gmatch(mechanism, "%S+") do
    if me == self.mechanism then
      return true
    end
  end
  return nil, "mechanism does not match"
end

function amqp:verify_capabilities(method)
  if not is_version_acceptable(self, method.major, method.minor) then
    return nil, "protocol version does not match"
  end

  if not is_mechanism_acceptable(self,method) then
    return nil, "mechanism does not match"
  end
  return true
end

local function negotiate_connection_tune_params(ctx,method)
  if not method then
    return
  end

  if method.channel_max ~= nil and method.channel_max ~= 0 then
    -- 0 means no limit
    ctx.channel_max = min(ctx.channel_max, method.channel_max)
  end

  if method.frame_max ~= nil and method.frame_max ~= 0 then
    ctx.frame_max = min(ctx.frame_max, method.frame_max)
  end
end

local function set_state(ctx, channel_state, connection_state)
  ctx.channel_state = channel_state
  ctx.connection_state = connection_state
end


--- setup connection to AMQP server
-- @param implied self (context)
-- @return true or nil
-- @error TBD

function amqp:setup()
  local res
  local err
  local sock = self.sock
  if not sock then
    return nil, "not initialized"
  end

  -- configurable but 30 seconds read timeout
  sock:settimeout(self.opts.read_timeout or 30000)

  res, err = frame.wire_protocol_header(self)

  if not res then
    logger.error("[amqp:setup] wire_protocol_header failed: ", err)
    return nil, err
  end

  if res.method then
    logger.dbg("[amqp:setup] connection_start: ",res.method)
    res, err = amqp.verify_capabilities(self, res.method)
    if not res then
      -- in order to close the socket without sending futher data
      set_state(self,c.state.CLOSED, c.state.CLOSED)
      return nil, err
    end
  end

  res, err = amqp.connection_start_ok(self)
  if not res then
    logger.error("[amqp:setup] connection_start_ok failed: ", err)
    return nil, err
  end

  negotiate_connection_tune_params(self,res.method)

  res, err = amqp.connection_tune_ok(self)
  if not res then
    logger.error("[amqp:setup] connection_tune_ok failed: ", err)
    return nil, err
  end

  res, err = amqp.connection_open(self)
  if not res then
    logger.error("[amqp:setup] connection_open failed: ", err)
    return nil, err
  end

  self.connection_state = c.state.ESTABLISHED

  res, err = amqp.channel_open(self)
  if not res then
    logger.error("[amqp:setup] channel_open failed: ", err)
    return nil, err
  end
  self.channel_state = c.state.ESTABLISHED
  return true
end

--
-- close channel and connection if needed.
--
function amqp:teardown(reason)
  local ok
  local err

  if self.channel_state == c.state.ESTABLISHED then
    ok, err = amqp.channel_close(self, reason)
    if not ok then
      logger.error("[channel_close] err: ", err)
    end
  elseif self.channel_state == c.state.CLOSE_WAIT then
    ok, err = amqp.channel_close_ok(self)
    if not ok then
      logger.error("[channel_close_ok] err: ", err)
    end
  end

  if self.connection_state == c.state.ESTABLISHED then
    ok, err = amqp.connection_close(self, reason)
    if not ok then
      logger.error("[connection_close] err: ", err)
    end
  elseif self.connection_state == c.state.CLOSE_WAIT then
    ok, err = amqp:connection_close_ok()
    if not ok then
      logger.error("[connection_close_ok] err: ", err)
    end
  end
end

--
-- initialize the consumer
--
function amqp:prepare_to_consume()
  local res
  local err

  if self.channel_state ~= c.state.ESTABLISHED then
    return nil, "[prepare_to_consume] channel is not open"
  end

  res, err = amqp.queue_declare(self)
  if not res then
    logger.error("[prepare_to_consume] queue_declare failed: ", err)
    return nil, err
  end

  if self.opts.exchange ~= '' then
    res, err = amqp.queue_bind(self)
    if not res then
      logger.error("[prepare_to_consume] queue_bind failed: ", err)
      return nil, err
    end
  end

  res, err = amqp.basic_consume(self)
  if not res then
    logger.error("[prepare_to_consume] basic_consume failed: ", err)
    return nil, err
  end

  return true
end

--
-- conclude a heartbeat timeout
-- if and only if we see ctx.threshold or more failure heartbeats in the recent heartbeats ctx.window
--

local function timedout(ctx, timeouts)
  local window = ctx.window or 5
  local threshold = ctx.threshold or 4
  local counter = 0
  for i = 1, window do
    if band(rshift(timeouts,i-1),1) ~= 0 then
      counter = counter + 1
    end
  end
  return counter >= threshold
end

function amqp:timedout(timeouts)
  return timedout(self, timeouts)
end

local function exiting()
  return _G.ngx and _G.ngx.worker and _G.ngx.worker.exiting()
end

--
-- consumer
--

function amqp:basic_ack(ok, delivery_tag)
  local f = frame.new_method_frame(self.channel or 1,
  c.class.BASIC,
  ok and c.method.basic.ACK or c.method.basic.NACK)

  f.method = {
    delivery_tag = delivery_tag,
    multiple = false,
    no_wait = true
  }

  return frame.wire_method_frame(self,f)
end

function amqp:consume_loop(callback)
  local ok
  local err
  local err0
  local f
  local hb = { last = os.time(), timeouts = 0 }
  local f_deliver
  local f_header
  local status

  while true do
    --
    ::continue::
    --
    f, err0 = frame.consume_frame(self)
    if not f then -- if start
      if exiting() then
        err = "exiting"
        break
      end
      -- in order to send the heartbeat,
      -- the very read op need be awaken up periodically, so the timeout is expected.
      if err0 ~= "timeout" then
        logger.error("[amqp:consume_loop]", err0 or "?")
      end

      if err0 == "closed" then
        err = err0
        set_state(self, c.state.CLOSED, c.state.CLOSED)
        logger.error("[amqp:consume_loop] socket closed")
        break
      end

      if err0 == "wantread" then
        err = err0
        set_state(self, c.state.CLOSED, c.state.CLOSED)
        logger.error("[amqp:consume_loop] SSL socket needs to dohandshake again")
        break
      end

      -- intented timeout?
      local now = os.time()
      if now - hb.last > c.DEFAULT_HEARTBEAT then
        logger.dbg("[amqp:consume_loop] timeouts inc. [ts]: ",now)
        hb.timeouts = bor(lshift(hb.timeouts,1),1)
        hb.last = now
        ok, err0 = frame.wire_heartbeat(self)
        if not ok then
          logger.error("[heartbeat]","pong error: ", err0 or "?", "[ts]: ", hb.last)
        else
          logger.dbg("[heartbeat]","pong sent. [ts]: ",hb.last)
        end
      end

      if timedout(self,hb.timeouts) then
        err = "heartbeat timeout"
        logger.error("[amqp:consume_loop] timedout. [ts]: ", now)
        break
      end --if end

      logger.dbg("[amqp:consume_loop] continue consuming ", err0)
      goto continue
    end

    if f.type == c.frame.METHOD_FRAME then
      if f.class_id == c.class.CHANNEL then
        if f.method_id == c.method.channel.CLOSE then
          set_state(self, c.state.CLOSE_WAIT, self.connection_state)
          logger.dbg("[channel close method]", f.method.reply_code, f.method.reply_text)
          break
        end
      elseif f.class_id == c.class.CONNECTION then
        if f.method_id == c.method.connection.CLOSE then
          set_state(self, c.state.CLOSED, c.state.CLOSE_WAIT)
          logger.dbg("[connection close method]", f.method.reply_code, f.method.reply_text)
          break
        end
      elseif f.class_id == c.class.BASIC then
        if f.method_id == c.method.basic.DELIVER then
          f_deliver = f.method
          if f.method ~= nil then
            logger.dbg("[basic_deliver] ", f.method)
          end
        end
      end
    elseif f.type == c.frame.HEADER_FRAME then
      f_header = f
      logger.dbg(format("[header] class_id: %d weight: %d, body_size: %d",
      f.class_id, f.weight, f.body_size))
      logger.dbg("[frame.properties]",f.properties)
    elseif f.type == c.frame.BODY_FRAME then
      status = true
      if callback then
        status, err0 = pcall(callback, {
          body = f.body,
          frame = f_deliver,
          properties = f_header.properties
        })
        if not status then
          logger.error("calling callback failed: ", err0)
        end
      end
      if not self.opts.no_ack then
        -- ack
        self:basic_ack(status, f_deliver.delivery_tag)
      end
      f_deliver, f_header = nil, nil
      logger.dbg("[body]", f.body)
    elseif f.type == c.frame.HEARTBEAT_FRAME then
      hb.last = os.time()
      logger.dbg("[heartbeat]","ping received. [ts]: ", hb.last)
      hb.timeouts = band(lshift(hb.timeouts,1),0)
      ok, err0 = frame.wire_heartbeat(self)
      if not ok then
        logger.error("[heartbeat]","pong error: ", err0 or "?", "[ts]: ", hb.last)
      else
        logger.dbg("[heartbeat]","pong sent. [ts]: ", hb.last)
      end
    end
  end

  self:teardown()
  -- return not err or err ~= "exiting", err
  return nil, err or err0
end

function amqp:consume()
  local ok
  local err

  ok, err = self:setup()
  if not ok then
    self:teardown()
    return nil, err
  end

  ok, err = self:prepare_to_consume()
  if not ok then
    self:teardown()
    return nil, err
  end

  return self:consume_loop(self.opts.callback)
end

--
-- get
--
function amqp:get()
  local ok, res, err
  ok, err = self:setup()
  if not ok then
    self:teardown()
    return nil, err
  end

  if self.channel_state ~= c.state.ESTABLISHED then
    self:teardown()
    return nil, err
  end

  res, err = amqp.basic_get(self)
  if not res then
    logger.error("[amqp:get] basic_get failed: " .. err)
    return nil, err
  end

  local message
  if res.method_id == c.method.basic.GET_OK and res.method.message_count > 0 then
    local f = frame.consume_frame(self)
    if f.type == c.frame.HEADER_FRAME then
      logger.dbg(format("[header] class_id: %d weight: %d, body_size: %d",
                        f.class_id, f.weight, f.body_size))
      logger.dbg("[frame.properties]",f.properties)
    end

    f = frame.consume_frame(self)
    if f.type == c.frame.BODY_FRAME then
      message = f.body
    end
    logger.dbg("[message]", message)
  end

  self:teardown()

  return message, err
end

--
-- publisher
--

function amqp:publish(payload,opts,properties)

  local ok
  local err
  local size = #payload

  ok, err = amqp.basic_publish(self, opts)
  if not ok then
    logger.error("[amqp.publish] failed: ", err)
    return nil, err
  end

  ok, err = frame.wire_header_frame(self,size,properties)
  if not ok then
    logger.error("[amqp.publish] failed: ", err)
    return nil, err
  end

  ok, err = frame.wire_body_frame(self,payload)
  if not ok then
    logger.error("[amqp.publish] failed: ", err)
    return nil, err
  end

  return true
end

--
-- queue
--
function amqp:queue_declare(opts)

  opts = opts or {}

  if not opts.queue and not self.opts.queue then
    return nil, "[queue_declare] queue is not specified"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.QUEUE,
    c.method.queue.DECLARE)
  f.method = {
    queue = opts.queue or self.opts.queue,
    passive = _getopt('passive', opts, self.opts, false),
    durable = _getopt('durable', opts, self.opts, false),
    exclusive = _getopt('exclusive', opts, self.opts, false),
    auto_delete = _getopt('auto_delete', opts, self.opts, true),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

function amqp:queue_bind(opts)
  opts = opts or {}

  if not opts.queue and not self.opts.queue then
    return nil, "[queue_bind] queue is not specified"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.QUEUE,
    c.method.queue.BIND)

  f.method = {
    queue = opts.queue or self.opts.queue,
    exchange = opts.exchange or self.opts.exchange,
    routing_key = _getopt('routing_key', opts, self.opts, ""),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }

  return frame.wire_method_frame(self,f)
end

function amqp:queue_unbind(opts)
  opts = opts or {}

  if not opts.queue and not self.opts.queue then
    return nil, "[queue_unbind] queue is not specified"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.QUEUE,
    c.method.queue.UNBIND)

  f.method = {
    queue = opts.queue or self.opts.queue,
    exchange = opts.exchange or self.opts.exchange,
    routing_key = _getopt('routing_key', opts, self.opts, ""),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }

  return frame.wire_method_frame(self,f)
end

function amqp:queue_delete(opts)
  opts = opts or {}

  if not opts.queue and not self.opts.queue then
    return nil, "[queue_delete] queue is not specified"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.QUEUE,
    c.method.queue.DELETE)

  f.method = {
    queue = opts.queue or self.opts.queue,
    if_unused = _getopt('if_unused', opts, self.opts, false),
    if_empty = _getopt('if_empty', opts, self.opts, false),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }

  return frame.wire_method_frame(self,f)
end

--
-- exchange
--

function amqp:exchange_declare(opts)
  opts = opts or {}
  local f = frame.new_method_frame(self.channel or 1,
    c.class.EXCHANGE,
    c.method.exchange.DECLARE)
  f.method = {
    exchange = opts.exchange or self.opts.exchange,
    typ = opts.typ or "topic",
    passive = _getopt('passive', opts, self.opts, false),
    durable = _getopt('durable', opts, self.opts, false),
    auto_delete = _getopt('auto_delete', opts, self.opts, false),
    internal = _getopt('internal', opts, self.opts, false),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

function amqp:exchange_bind(opts)
  if not opts then
    return nil, "[exchange_bind] opts is required"
  end

  if not opts.source then
    return nil, "[exchange_bind] source is required"
  end

  if not opts.destination then
    return nil, "[exchange_bind] destination is required"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.EXCHANGE,
    c.method.exchange.BIND)

  f.method = {
    destination = opts.destination,
    source = opts.source,
    routing_key = _getopt('routing_key', opts, self.opts, ''),
    no_wait = _getopt('no_wait', opts, self,opts, false)
  }

  return frame.wire_method_frame(self,f)
end

function amqp:exchange_unbind(opts)
  if not opts then
    return nil, "[exchange_unbind] opts is required"
  end

  if not opts.source then
    return nil, "[exchange_unbind] source is required"
  end

  if not opts.destination then
    return nil, "[exchange_unbind] destination is required"
  end

  local f = frame.new_method_frame(self.channel or 1,
    c.class.EXCHANGE,
    c.method.exchange.UNBIND)
  f.method = {
    destination = opts.destination,
    source = opts.source,
    routing_key = _getopt('routing_key', opts, self.opts, ""),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

function amqp:exchange_delete(opts)
  opts = opts or {}
  local f = frame.new_method_frame(self.channel or 1,
    c.class.EXCHANGE,
    c.method.exchange.DELETE)
  f.method = {
    exchange = opts.exchange or self.opts.exchange,
    if_unused = _getopt('if_unused', opts, self.opts, true),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

--
-- basic
--

function amqp:basic_consume(opts)
  opts = opts or {}
  if not opts.queue and not self.opts.queue then
    return nil, "[basic_consume] queue is not specified"
  end
  local f = frame.new_method_frame(self.channel or 1,
    c.class.BASIC,
    c.method.basic.CONSUME)
  f.method = {
    queue = opts.queue or self.opts.queue,
    no_local = _getopt('no_local',opts, self.opts, false),
    no_ack = _getopt('no_ack', opts, self.opts, true),
    exclusive = _getopt('exclusive', opts, self.opts, false),
    no_wait = _getopt('no_wait', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

function amqp:basic_publish(opts)
  opts = opts or {}
  local f = frame.new_method_frame(self.channel or 1,
    c.class.BASIC,
    c.method.basic.PUBLISH)
  f.method = {
    no_wait = true,
    exchange = opts.exchange or self.opts.exchange,
    routing_key = _getopt('routing_key',opts, self.opts, ""),
    mandatory = _getopt('mandatory', opts, self.opts, false),
    immediate = _getopt('immediate', opts, self.opts, false)
  }
  return frame.wire_method_frame(self,f)
end

function amqp:basic_get(opts)
  opts = opts or {}
  if not opts.queue and not self.opts.queue then
    return nil, "[basic_get] queue is not specified."
  end
  local f = frame.new_method_frame(self.channel or 1,
                                  c.class.BASIC,
                                  c.method.basic.GET)
  f.method = {
    queue = opts.queue or self.opts.queue,
    no_ack = _getopt('no_ack', opts, self.opts, true)
  }
  return frame.wire_method_frame(self,f)
end

return amqp
