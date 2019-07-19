# LUA-AMQP

Lua Client for AMQP 0.9.1. This library is already tested with RabbitMQ and should work with any other AMQP 0.9.1 broker.

It is a fork of : 

* https://github.com/mengz0/amqp
* https://github.com/ZigzagAK/amqp
* https://github.com/4mig4/lua-amqp

This library can be used with LuaJIT and does not have to be used only in OpenResty.

## Usage

As this library is already published at [Luarocks](https://luarocks.org), you can use this throught follow command

    luarocks install amqp-client

then, follow this [Wiki Documentation](https://github.com/gsdenys/amqp-client/wiki) to know how to use this library.

## Develop

To facilitate to create the lua development environment, was created a [Lua Vagrant Image](https://github.com/gsdenys/vagrant-lua). Use it to gain time.

Case you already have your environment done, just clone this repository and start working. Other else, follow the steps bellow ([Vagrant](https://www.vagrantup.com) need to be installed) :

```sh
#create lua environment over vagrant
git clone https://github.com/gsdenys/vagrant-lua.git
cd vagrant-lua
vagrant up #it takes a lot of time 
vagran ssh

#install RabbitMQ
wget https://bit.ly/2Ycybe8 -O install.sh
sh install.sh

#Clone this repository
git clone https://github.com/gsdenys/amqp-client.git
cd amqp-client
```
Now, you`re ready to start contributing with the project.

## Building

This library have some requirements shown below. If you're using the [Lua Vagrant Image](https://github.com/gsdenys/vagrant-lua) just take care about the busted lib, the othes is already done.

1. LuaJIT >= 2.1 
2. busted 2.0 (Testing framework)
3. luabitop (if you are using lua 5.1)

to install busted lib >= 2.1 execute the following command:

```sh
luarocks install busted
```

After requirements solved, you can run the test using the following command:

```sh
busted
```

once solved, inside the main folder, execute follow command:

```sh
luarocks make
```

The output should be like this:

    amqp-client 1.0.0-1 is now installed in /usr/local (license: Apache 2.0)

## Examples

The examples needs some dependencies that can be solved throught the follow commands:

```sh
luarocks install inspect
luarocks install lua-resty-uuid
luarocks install cqueues
luarocks install argparse
```

Beyond dependences, the examples depends on build. Other way to execute example less build the library is import this library from luarocks. You can do this executing this command.

 ```sh
 luarocks install amqp-client
 ```   