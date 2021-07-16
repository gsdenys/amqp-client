local consts = require 'amqp.consts'

local function new(opts, sock)
    local default_ctx = {
        connection_state = consts.state.CLOSED,
        channel_state    = consts.state.CLOSED,
        channel_max      = consts.DEFAULT_MAX_CHANNELS,
        frame_max        = consts.DEFAULT_FRAME_SIZE,
        mechanism        = consts.MECHANISM_PLAIN,
        revision         = consts.PROTOCOL_VERSION_REVISION,
        ssl_ctx          = opts.ssl_ctx or nil,
        timeout          = consts.DEFAULT_TIMEOUT,
        major            = consts.PROTOCOL_VERSION_MAJOR,
        minor            = consts.PROTOCOL_VERSION_MINOR,
        sock             = sock,
        opts             = opts
    }

    local ctx = default_ctx

    -- Set opts
    -- function to set opts inside context. As ssl_ctx is dependent of opts,
    -- this function, when called, will overwrite it.
    --
    -- @param opts connection and socket options
    function ctx:set_opts (opts)
        self.opts = opts

        self.ssl_ctx = opts.ssl_ctx or nil
    end

    -- Set sock
    -- function to set the sock
    --
    -- @param sock the sock 
    function ctx:set_sock(sock)
        self.sock = sock
    end

    -- Set timeout
    -- Change the system timeou. It's just functional before connect to provider, 
    -- after connection made, function will have no effect.
    --
    -- @param timeout the timeout to be set (default 5000)
    function ctx:set_timeout(timeout)
        self.timeout = timeout or consts.DEFAULT_TIMEOUT
    end

    -- Set ssl_ctx
    -- Change the default ssl_ctx (default nil), when true the connection should try
    -- to use the ssl to connect with provider. 
    -- It's just functional before connect to provider, after connection made, this 
    -- function will have no effect.
    --
    -- @param ssl_ctx the context ssl
    function ctx:set_ssl_ctx(ssl_ctx)
        self.ssl_ctx = ssl_ctx
    end
    
    -- Set max channels
    -- This function enable to set the max channels to this connection.
    -- It's just functional before connect to provider, after connection made, this 
    -- function will have no effect.
    --
    -- @param channel_max the max channel
    function ctx:set_channel_max(channel_max)
        self.channel_max = channel_max or consts.DEFAULT_MAX_CHANNELS,
    end


    -- Set frame max size
    -- This function enable to set the max size of frame. Take 
    -- It's just functional before connect to provider, after connection made, this 
    -- function will have no effect.
    --
    -- @param frame_max the frame max size 
    function ctx:set_frame_max(frame_max)
        self.frame_max = frame_max
    end
    
    return ctx
end


return new