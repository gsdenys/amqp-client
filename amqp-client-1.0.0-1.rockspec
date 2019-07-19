package = "amqp-client"
version = "1.0.0-1"
source = {
   url = "https://github.com/4mig4/lua-amqp.git",
   tag = "amqp, queue, cqueues, RPC, rabbitmq",
}
description = {
   summary = "Lua AMQP 0.9.1 client",
   detailed = [[
      Lua AMQP 0.9.1 client - A pure Lua solution by Meng Zhang, Aleksey Konovkin, 4mig4 and Denys Santos.
   ]],
   homepage = "https://github.com/gsdenys/amqp-client",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
     ['amqp'] = "amqp/init.lua",
     ['amqp.buffer'] = "amqp/buffer.lua",
     ['amqp.consts'] = "amqp/consts.lua",
     ['amqp.frame'] = "amqp/frame.lua",
     ['amqp.logger'] = "amqp/logger.lua"
   }
}
