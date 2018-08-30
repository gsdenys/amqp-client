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
     ['resty.amqp'] = "resty/amqp.lua",
     ['resty.amqp.buffer'] = "resty/amqp/buffer.lua",
     ['resty.amqp.consts'] = "resty/amqp/consts.lua",
     ['resty.amqp.frame'] = "resty/amqp/frame.lua",
     ['resty.amqp.logger'] = "resty/amqp/logger.lua"
   }
}
