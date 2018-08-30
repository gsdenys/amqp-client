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


--       PING PONG (Client) example 
--       https://www.rabbitmq.com/direct-reply-to.html

---------------------------------------------------------------------------------
-- Requires

local amqp = require ('resty.amqp')
local uuid = require('resty.uuid')
local inspect = require('inspect')

---------------------------------------------------------------------------------
-- Main

--
-- Instantiate a context
--

local ctx = amqp:new({role = "consumer", 
                      exchange = '',
                      queue = 'amq.rabbitmq.reply-to', 
                      routing_key = 'test',
                      ssl = false,
                      user = "guest",
                      password = "guest",
                      no_ack = true, 
                      durable = true,
                      auto_delete = true,
                      consumer_tag = '',
                      exclusive = false,
                      properties = {}
                    })


--
-- Define callback function that will process the answer (see below)
--

ctx.opts.callback =  
  function(f)

    print('---f---',inspect(f))

    if f.body == 'pong' then 

      print('received: pong')

      local payload = 'ping'
      local correlation_id = uuid.generate()
      local properties = { 
                           reply_to = 'amq.rabbitmq.reply-to',
                           content_type = 'application/json',
                           content_encoding = 'utf-8',
                           correlation_id = correlation_id,
                           delivery_mode = 2, 
                           headers = { ['api-version'] = 1,   -- custome headers
                                       correlation_id = correlation_id }
                         }

        local ok, err = ctx:publish(payload, ctx.opts, properties)

        if ok then
          print('replied: ping')
        else
          error('could not publish: '..err)
        end

      end
    end
 
local ok , err = ctx:connect("127.0.0.1",5672)

if not ok then 
  error('could not connect'..err)
end

--
-- Setup connection to AMQP server
--


local ok, err = ctx:setup() -- because of this we need to use consume_loop()

if not ok then
  error('could not setup: '..err)
end

--
-- Prepare to consume
--

local ok, err = ctx:prepare_to_consume() -- this has to be right after setup()

if not ok then
  error('could not prepare to consume: '..err)
end

--
-- Publish ( AKA send command to PING-PONG server in our case )
--

local correlation_id = uuid.generate()
local properties = {   
                     reply_to = 'amq.rabbitmq.reply-to',
                     content_type = 'application/json',
                     content_encoding = 'utf-8',
                     correlation_id = correlation_id, 
                     delivery_mode = 2, 
                     headers = { ['api-version'] = 1,
                                 correlation_id = correlation_id }
                   }

local payload = 'ping'

local  ok, err = ctx:publish(payload, ctx.opts, properties)

if not ok then
  error('could not publish: '..err)
end

print('sent: ping')

--
-- Wait for answer
--

-- Enter consume loop
-- callback will be called only on reception of BODY_FRAME.
-- setup() and prepare_to_consume() calls are needed because were are using 
-- consume_loop(callback) method and not consume() method. 

local ok, err = ctx:consume_loop(ctx.opts.callback)

if not ok then
  error('could not consume loop: ')
end
