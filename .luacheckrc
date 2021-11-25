cache = false
include_files = {"src", "spec/*.lua", "*.rockspec", "*.luacheckrc"}

max_line_length = 120
globals = {'table', 'debug'}

files["src/table.lua"] = {ignore = {"212"}}
files["src/operations/basic.lua"] = {ignore = {"212"}}