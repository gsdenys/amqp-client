package = "amqp-client"
version = "2.0.0-1"
source = {
   url = "git://github.com/gsdenys/amqp-client.git",
   branch = "v1.3.0-1"
}
description = {
   summary = "Lua AMQP 0.9.1 client",
   detailed = [[
      A pure Lua Client for AMQP 0.9.1.
      This library is already tested with RabbitMQ and should work with any other AMQP 0.9.1
      broker and can be used with LuaJIT and does not have to be used only in OpenResty.

      Developed by: Meng Zhang, Aleksey Konovkin, 4mig4 and Denys Santos.
   ]],
   homepage = "https://github.com/gsdenys/amqp-client",
   maintainer = "Denys G. Santos <gsdenys@gmail.com>",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1",
   "power-table >= 1.0.1-1",
   "net-url >= 1.1-1"
}
build = {
   type = "builtin",
   modules = {
   --   ['amqp.buffer'] = "src/amqp/buffer.lua",
   --   ['amqp.consts'] = "src/amqp/consts.lua",
   --   ['amqp.frame'] = "src/amqp/frame.lua",

   --   ['amqp'] = 'src/amqp/amqp.lua',
   --   ['amqp.context'] = "src/amqp/context.lua",
   --   ['amqp.socket.lua'] = "src/amqp/socket/lua.lua",

   --   ['amqp.log.simple'] = "src/amqp/log/simple.lua"

      ['amqp.uri'] = "src/uri.lua",

      ['amqp.utils.assertion'] = "src/utils/assertion.lua",
      ['amqp.utils.messages'] = "src/utils/messages.lua",
      ['amqp.utils.level'] = "src/utils/level.lua",
   }
}
