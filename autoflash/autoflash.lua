-- write a ROM onto the actively running system from across the network.
-- note that writing the EEPROM will overwrite this program, so the client should send a copy of this program
-- every time if this functionality needs to be preserved.

(function()
  local modem = component.proxy(component.list("modem")())
  local eeprom = component.proxy(component.list("eeprom")())

  local AF_WAIT = 5
  local AF_PORT = 122

  -- start listening for flash messages
  modem.open(AF_PORT)

  -- start a timer for flash messages
  local startup = os.time()

  -- wait for a flash request
  ::connect::
  local passed = os.difftime(startup, os.time())
  if passed < AF_WAIT then
    -- wait for a flash request
    message, _, _, port, _, command, rom = computer.pullSignal(AF_WAIT - passed)

    if message == "modem_message" and port == AF_PORT and command == "autoflash" then
      -- write the received ROM to the EEPROM
      eeprom.set(rom)

      -- success beeps
      for i = 1, 3 do
        computer.beep(1000, 0.1)
      end

      -- reboot into the new ROM
      computer.shutdown()
    end
  end

  modem.close()
end)()

-- loads the commented ROM from the EEPROM
local code = string.gmatch(eeprom.get(), "-%-%[=====%[(.)-%-%]=====%]")()

-- load and run the code
local bin, err = load(code)
if bin then
  local _, err = pcall(bin)

-- throw any errors
if err then error(err)
