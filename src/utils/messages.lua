local messages = {}

messages.MESSAGE_BASE = "%s amqp.%s(): "

messages.ERR_URI_WHITE_SPACE = "URI must not contain whitespace"
messages.ERR_URI_SCHEME = "AMQP scheme must be either 'amqp://' or 'amqps://'"
messages.ERR_URI_NIL = "The URI cannot be nil"
messages.ERR_URI_EMPTY = "The URI cannot be an empty string"
messages.ERR_URI_SUB_PATH = "The URI cannot contain sub paths"

return messages
