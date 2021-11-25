local neturl = require "net.url"
local table = require "ptable"

local assertion = require "amqp.utils.assertion"
local messages = require "amqp.utils.messages"

local parser = {}

--- possibles schemes
local schemesPorts = table({amqp = 5672, amqps = 5671})

-- the dafault builder
local defaultURI = table({
    scheme = "amqp",
    host = "localhost",
    port = nil,
    user = "guest",
    password = "guest",
    path = "/"
})

--- parse AMQP URI and create a builder with de parsed data.
---
---@param uri string the URI to be parsed
---@return any - the created builder
local function parse_uri(uri)
    local builder = defaultURI:clone()

    local parsed_uri = table(neturl.parse(uri))
    parsed_uri:del("authority", "userinfo", "query")

    builder:merge(parsed_uri)

    if builder["path"] == "" then builder["path"] = "/" end

    return builder
end

--- Set the value of port on builder in cases of builder has no defined port.
---
--- @param builder any
local function set_default_port(builder)
    if builder["port"] == nil then
        builder["port"] = schemesPorts[builder["scheme"]]
    end
end

--- Validate schema to certify that just 'amqp' and 'amqps' can be used. In case of some others
--- utilization, the sistem will throws an error.
---
--- @param scheme any - the scheme to be validated
--- @param fn any - the caller function
local function validate_scheme(scheme, fn)
    local schemes = schemesPorts:keys()
    assertion.contains(schemes, scheme, messages.ERR_URI_SCHEME, fn)
end

--- Validade the AMQP URI. Case the URI is not compatible this function will throw an error
---
---@param uri any the uri to be validated
---@param fname any the caller function
local function validate_uri(uri, fname)
    -- the URI cannot be nil
    assertion.True(fname, messages.ERR_URI_NIL, uri ~= nil)

    -- the URI cannot be an empty string error
    assertion.True(fname, messages.ERR_URI_EMPTY, uri ~= "")

    -- the URI cannot contains whitespace
    assertion.whitespace(fname, uri)
end

--- Validata path to grant that there is just one level of path
--
---@param path any the path to be check
---@param fname any the caller function
local function validate_path(path, fname)
    local count = 0
    for _ in string.gmatch(path, "/") do count = count + 1 end

    assertion.True(fname, messages.ERR_URI_SUB_PATH, count <= 1)
end

--- Parse the URI and return a builder table with all data necessary to create a
--- connection between the AMQP provider and consumer.
---
---@param uri any the URI to be parsed
---@return table - the builder table
function parser.parse(uri)
    local fname = "uri.parse"

    -- make some validations at URI
    validate_uri(uri, fname)

    -- parse the URI
    local builder = parse_uri(uri)

    -- validade the scheme. just accept 'amqp' and 'amqps'
    validate_scheme(builder["scheme"], fname)

    validate_path(builder["path"], fname)

    -- set default port in the casses it has no set.
    set_default_port(builder)

    return builder
end

--- make URI validaton and return true for valid URI or false for not valid one
---
---@param uri any the URI to validate
---@return boolean - true to valid URI and false to invalid
function parser.validate(uri)
    local _, err = pcall(validate_uri, uri)

    if err ~= nil then return false end

    return true
end

return parser
