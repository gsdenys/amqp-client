package = "amqp-client"
version = "1.2.0-1"
source = {
   url = "git://github.com/gsdenys/amqp-client.git"
}
description = {
   summary = "Lua AMQP 0.9.1 client",
   detailed = [[
      A pure Lua Client for AMQP 0.9.1. 
      This library is already tested with RabbitMQ and should work with any other AMQP 0.9.1 broker and can be used with LuaJIT and does not have to be used only in OpenResty.
      
      Developed by: Meng Zhang, Aleksey Konovkin, 4mig4 and Denys Santos.
   ]],
   homepage = "https://github.com/gsdenys/amqp-client",
   maintainer = "Denys G. Santos <gsdenys@gmail.com>",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
     ['amqp'] = "src/amqp/init.lua",
     ['amqp.buffer'] = "src/amqp/buffer.lua",
     ['amqp.consts'] = "src/amqp/consts.lua",
     ['amqp.frame'] = "src/amqp/frame.lua",
     ['amqp.logger'] = "src/amqp/logger.lua"
   }
}
