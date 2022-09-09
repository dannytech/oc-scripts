-- write a ROM over the network to a device running autoflash

local modem = component.proxy(component.list("modem")())
local filesystem = component.proxy(component.list("filesystem")())
local shell = require("shell")

-- parse shell arguments
local args, opts = shell.parse()

-- usage instructions
if #args == 0 and not options.f then
    io.stdout:write("Usage: autoflash-client [-f] [ip] [eeprom.lua]\n")
    io.stdout:write("  f: do not write an autoflash server to the EEPROM\n")
    io.stdout:write("  ip: the IP address of the device to flash\n")
    io.stdout:write("  file: the path to the ROM to write\n")
    io.stdout:write("If no IP is specified, listens for device identifier broadcasts.\n")
    io.stdout:write("If no file is specified, a blank autoflash ROM will be written.\n")
    return
end

if #args < 2 and opts.f then
    io.stderr:write("Must either specify a ROM or remove the -f flag.\n")
    return
end

-- hold the complete ROM in memory
local rom = ""

-- prepend an autoflash ROM to allow continued remote flashing
if not opts.f then
    local filename = shell.resolve("autoflash.lua")

    -- read the autoflash ROM
    if fs.exists(filename) then
        local file = io.open(filename, "rb")
        rom = rom..file:read("*a")
        file:close()
    else
        io.stderr:write("Autoflash ROM file not found\n")
        return
    end
end

-- read the provided ROM file, if any
if #args >= 2 then
    local filename = shell.resolve(args[2])

    -- read the ROM file
    if fs.exists(filename) then
        local file = io.open(filename, "rb")
        rom = rom.."\n"..file:read("*a")
        file:close()
    else
        io.stderr:write("ROM file not found\n")
        return
    end
end

-- get the IP address of the target system
local ip = args[1]

event.pull("modem_message", function(_, _, from, port, _, command)
    if port == 122 then
        -- listen for autoflash registrations
        if command == "af_register" then
            if ip == nil then
                -- listen for registrations
                io.stderr:write("Registration from "..from.."\n")
            else
                -- send the ROM
                if from == ip and #rom > 0 then
                    modem.send(ip, 122, "af_flash", rom)
                end
            end
        end
    end
end)
