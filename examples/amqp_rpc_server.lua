#!/usr/bin/luajit

-- @author 4mig4 <4mig4-github@gmail.com>
-- @release 1.0.0
-- @licence ISC
--
---------------------------------------------------------------------------------
-- Copyright (c) 2018 4mig4 <4mig4-github@gmail.com>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
---------------------------------------------------------------------------------


--        PING-PONG (Server) example
--        https://www.rabbitmq.com/direct-reply-to.html

---------------------------------------------------------------------------------
-- Requires

local amqp = require('amqp')
local inspect = require('inspect')
local argparse = require('argparse')
--local cqueues = require('cqueues')

---------------------------------------------------------------------------------
-- Main
local parser = argparse()
--
-- Instantiates context
--

local ctx = amqp:new({role = 'consumer',
                      exchange = '',
                      queue = 'test',
                      routing_key = '',
                      ssl = false,
                      user = 'guest',
                      password = 'guest',
                      no_ack = false,
                      durable = true,
                      auto_delete = true,
                      consumer_tag = '',
                      exclusive = false,
                      properties = {}
                      }
                    )

--
-- Definition of the callback function
--

ctx.opts.callback = function(f)
  print('-- f --', inspect(f))
  if f.body == 'ping' then
    print('received: ping')
    local response = 'pong'
    local correlation_id

    if f.properties.reply_to then
      ctx.opts.routing_key = f.properties.reply_to
    end

    if f.properties.correlation_id then
      correlation_id = f.properties.correlation_id
    end

    local properties = { correlation_id = correlation_id,
                         delivery_mode = 2,
                         headers = { ['api-version'] = 1, -- custom headers
                                     correlation_id = correlation_id }
                       }

    local ok , err = ctx:publish(response, ctx.opts, properties)

    if ok then
      print('sent: pong')
      return true
    else
      return nil, 'could not publish' .. inspect(err)
    end
  end
end

local function rpc_main(args)
  local host = '127.0.0.1'
  local port = 5672
  --
  -- Connect to AMQP server (broker)
  --

  if ctx.opts.user and args.user then ctx.opts.user = args.user end
  if ctx.opts.password and args.password then ctx.opts.password = args.password end
  if args.ssl then ctx.opts.ssl = args.ssl end
  if args.host then host = args.host end
  if args.port then port = args.port end

  local ok, err
  ok = ctx:connect(host, port)
  if not ok then
    error('failed to connect')
  end

  --
  -- Enter consume loop
  --

  -- Callback will be called only on reception of BODY_FRAME.
  -- No need for setup() or prepare_to_consume() calls because were are using
  -- consume() and not consume_loop(callback), also note that consume() the
  -- callback function is passed thru the ctx context and not as an argument
  -- of the method like in in consume_loop()

  ok, err = ctx:consume()

  if not ok then
    error('consume failed: '..err)
  end
end

-- Argument handling ---------------------------------------------------------
parser:option('-H --host','rabbitmq hostname', '127.0.0.1')
parser:option('-P --port','rabbitmq port', 5672)
parser:option('-u --user','rabbitmq username', 'guest')
parser:option('-p --password','rabbitmq password', 'guest')
parser:flag('-s --ssl','enable ssl')

local args = parser:parse()

rpc_main(args)
