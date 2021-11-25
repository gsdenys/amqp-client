local neturl = require "net.url"
local table = require "ptable"

local assertion = require "amqp.utils.assertion"
local messages = require "amqp.utils.messages"
local helper = require "amqp.utils.helper"

-- local URI = {}

local schemesPorts = table({amqp = 5672, amqps = 5671})

local defaultURI = table({
    scheme = "amqp",
    host = "localhost",
    port = nil,
    user = "guest",
    password = "guest",
    path = "/"
})

local function uri_parser(uri)
    local builder = defaultURI:clone()

    local parsed_uri = table(neturl.parse(uri))
    parsed_uri:del("authority", "userinfo", "query")

    builder:merge(parsed_uri)

    return builder
end

local function set_default_port(builder)
    if builder["port"] == nil then
        builder["port"] = schemesPorts[builder["scheme"]]
    end
end

local function validate_schema(scheme, fn)
    local schemes = schemesPorts:keys()
    assertion.contains(schemes, scheme, messages.ERR_URI_SCHEME, fn)
end

local function validate(builder, fn) validate_schema(builder["scheme"], fn) end

local function parse(uri)
    local FUNCTION_NAME = helper.function_name()

    if uri == nil or uri == "" then return defaultURI end

    -- the URI cannot contains whitespace
    assertion.whitespace(uri, FUNCTION_NAME)

    local builder = uri_parser()

    validate(builder, FUNCTION_NAME)

	set_default_port(builder)



    -- if u.User != nil {
    -- 	builder.Username = u.User.Username()
    -- 	if password, ok := u.User.Password(); ok {
    -- 		builder.Password = password
    -- 	}
    -- }

    -- if u.Path != "" {
    -- 	if strings.HasPrefix(u.Path, "/") {
    -- 		if u.Host == "" && strings.HasPrefix(u.Path, "///") {
    -- 			// net/url doesn't handle local context authorities and leaves that up
    -- 			// to the scheme handler.  In our case, we translate amqp:/// into the
    -- 			// default host and whatever the vhost should be
    -- 			if len(u.Path) > 3 {
    -- 				builder.Vhost = u.Path[3:]
    -- 			}
    -- 		} else if len(u.Path) > 1 {
    -- 			builder.Vhost = u.Path[1:]
    -- 		}
    -- 	} else {
    -- 		builder.Vhost = u.Path
    -- 	}
    -- }

    return builder, nil
end

return parse
