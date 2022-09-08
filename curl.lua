--- download a file from the internet

local internet = component.proxy(component.list("internet")())
local filesystem = component.proxy(component.list("filesystem")())

-- usage instructions
if #args == 0 then
    io.stdout:write("Usage: curl <url> [path]\n")
    io.stdout:write("  url: the URL to download\n")
    io.stdout:write("  path: a file to save the downloaded content into\n")
    io.stdout:write("If no path is specified, the file will be printed to stdout.\n")
    return
end

local url = args[1]

-- start the file download
local handle = internet.request(url)

-- combine all downloaded chunks
local result = ""
for chunk in handle do result = result..chunk end

if #args > 1 then
    local filename = shell.resolve(args[2])

    -- save the file
    local file = io.open(filename, "wb")
    file:write(result)
    file:close()
else
    -- print the file
    io.stdout:write(result)
end
