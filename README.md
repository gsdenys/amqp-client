# AMQP Client #

Lua Client for AMQP 0.9.1. This library is already tested with RabbitMQ and should work with any other AMQP 0.9.1 broker.

It is a fork of : 
* https://github.com/mengz0/amqp
* https://github.com/ZigzagAK/amqp
* https://github.com/4mig4/lua-amqp

This library can be used with LuaJIT and does not have to be used only in OpenResty.

## Usage

As this library is already published at [Luarocks](https://luarocks.org), you can use this through following command:

```sh
luarocks install amqp-client
```

then, follow this [Wiki Documentation](https://github.com/gsdenys/amqp-client/wiki) to know how to use this library.

## Develop

To facilitate to create the lua development environment, was created a [Lua Vagrant Image](https://github.com/gsdenys/lua-vagrant). Use it to gain time.

Case you already have your environment done, just clone this repository and start working. Other else, execute the following steps ([Vagrant](https://www.vagrantup.com) need to be installed)

### Prepare the Environmen

First of all you need to clone the [lua-vagrant](https://github.com/gsdenys/lua-vagrant) environment executing this command:

```sh
git clone https://github.com/gsdenys/vagrant-lua.git
cd vagrant-lua
```

As we'll install the [RabbitMQ](https://www.rabbitmq.com), is very interesting expose the ports to be accessed through the host, this way we can easilly access the administrator enviromnent in your browser. So, to to this, you need to locate the code below at the __Vagrantfile__

```sh
###
# add the network fowarded port here
# ex: config.vm.network "forwarded_port", guest: 15672, host: 8080
###
  
# config.vm.network "forwarded_port", guest: 8080, host: 8080
```
and insert the the next 2 lines after that:

```sh
config.vm.network "forwarded_port", guest: 15672, host: 8080
config.vm.network "forwarded_port", guest: 672, host: 672
```

So, let's clone this repository inside [lua-vagrant](https://github.com/gsdenys/lua-vagrant) project and start it.

```sh
git clone https://github.com/gsdenys/amqp-client.git

vagrant up #it takes a lot of time 
vagrant ssh
```
Now, you already are inside the [lua-vagrant](https://github.com/gsdenys/lua-vagrant) VM. Then you need to install the [RabbitMQ](https://www.rabbitmq.com).

```sh
#install RabbitMQ
wget https://bit.ly/2Ycybe8 -O install.sh
sh install.sh
```
Your environment is ready now. the amqp-client project is in the _/lua/amqp-client_ directory. Go to the project and start to use it.

```sh
#go to amqp-client source code
cd /lua/amqp-client
```

### Building

This library have some requirements shown below. If you're using the [Lua Vagrant Image](https://github.com/gsdenys/vagrant-lua) just take care about the busted lib, the others is already done.

1. LuaJIT >= 2.1 
2. busted 2.0 (Testing framework)
3. luabitop (if you are using lua 5.1)

To install busted lib >= 2.1 execute the following command:

```sh
luarocks install busted
```

This library can use [cqueues](https://luarocks.org/modules/daurnimator/cqueues); once [cqueues](https://luarocks.org/modules/daurnimator/cqueues) is installed the library automatically starts to use it. to install [cqueues](https://luarocks.org/modules/daurnimator/cqueues) use this command.

```sh
luarocks install cqueues
```

case you don't want to use cqueues you need to use the lua socket. Install it with this command:

```sh
luarocks install luasocket
```

After requirements solved, you can run the unit tests with busted using the following command:

```sh
busted
```

Wow you are ready to build the library executing following command::

```sh
luarocks make
```

the output should be like this:

    amqp-client 1.0.0-1 is now installed in /usr/local (license: Apache 2.0)

### Examples

The examples needs some dependencies that can be solved through the following commands:

```sh
luarocks install inspect
luarocks install lua-resty-uuid
luarocks install argparse
```

Beyond dependences, the examples depends on build of this library. Other way to execute the examples less building the library is import this library from luarocks. You can do this executing this command.

 ```sh
 luarocks install amqp-client
 ```   
