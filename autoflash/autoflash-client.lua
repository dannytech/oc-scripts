-- write a ROM over the network to a device running autoflash

local component = require("component")
local shell = require("shell")
local event = require("event")
local modem = component.proxy(component.list("modem")())
local fs = component.proxy(component.list("filesystem")())

-- parse shell arguments
local args, opts = shell.parse(...)

AF_WAIT = 5
AF_PORT = 122

-- usage instructions
if (#args == 0 and #opts == 0) or opts.h then
  io.stdout:write("Usage: autoflash-client [-fh] [ip] [file]\n")
  io.stdout:write("  f: do not write an autoflash server to the EEPROM\n")
  io.stdout:write("  h: print this help message\n")
  io.stdout:write("  ip: the IP address of the device to flash\n")
  io.stdout:write("  file: the path to the ROM to write\n")
  io.stdout:write("If no file is specified, a plain autoflash ROM will be written.\n")
  os.exit(0)
end


-- get the IP address of the target system and the firmware to upload
local ip = args[1]
local firmware = args[2]

-- require a rom file if the finalize flag is set
if firmware == nil and opts.f then
  io.stderr:write("Must either specify a ROM or remove the -f flag.\n")
  os.exit(0)
end

-- hold the complete ROM in memory
local rom = ""

-- prepend an autoflash ROM to allow continued remote flashing
if not opts.f and #args >= 1 then
  local filename = shell.resolve("autoflash.lua")

  -- read the autoflash ROM
  if fs.exists(filename) then
    local file = io.open(filename, "rb")
    rom = rom .. file:read("*a") .. "\n"
    file:close()
  else
    io.stderr:write("Autoflash ROM file not found\n")
    os.exit(0)
  end
end

-- read the provided ROM file, if any
if #args >= 2 then
  local filename = shell.resolve(firmware)

  -- read the ROM file
  if fs.exists(filename) then
    local file = io.open(filename, "rb")
    rom = rom .. file:read("*a")
    file:close()
  else
    io.stderr:write("ROM file not found\n")
    return
  end
end

local running = true
local eid = event.listen("interrupted", function()
  running = false
end)

-- send the ROM in a loop
if #rom > 0 then
  while running
  do
    modem.send(ip, AF_PORT, "autoflash", rom)
    os.sleep(AF_WAIT / 2.5) -- trigger at least 2 firmware flash requests during each startup period
  end
end

-- close out the interrupt event listener
event.cancel(eid)
