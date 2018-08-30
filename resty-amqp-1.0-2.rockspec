package = "resty-amqp"
version = "1.0-2"
source = {
   url = "https://github.com/4mig4/resty-amqp.git",
   tag = "",
}
description = {
   summary = "RabbitMQ / AMQP 0.9.1 client",
   detailed = [[
      RabbitMQ / AMQP 0.9.1 client, pure Lua solution by Meng Zhang, Aleksey Konovkin, 4mig4.
   ]],
   homepage = "https:////github.com/4mig4/resty-amqp",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
     ['amqp'] = "amqp.lua",
     ['amqp.buffer'] = "amqp/buffer.lua",
     ['amqp.consts'] = "amqp/consts.lua",
     ['amqp.frame'] = "amqp/frame.lua",
     ['amqp.logger'] = "amqp/logger.lua"
   }
}
