cache = false
include_files = {"src", "spec/*.lua", "*.rockspec", "*.luacheckrc"}

max_line_length = 120
globals = {'table', 'debug'}

files["src/uri.lua"] = {ignore = {"212"}}