-- write a ROM onto the actively running system from across the network.
-- note that writing the EEPROM will overwrite this program, so the client should send a copy of this program
-- every time if this functionality needs to be preserved.

local modem = component.proxy(component.list("modem")())
local eeprom = component.proxy(component.list("eeprom")())

-- start listening for flash messages
modem.open(122)

-- register the current device with the flash server
modem.broadcast(122, "af_register", component.address)

-- start a timer for flash messages
local startup = os.time()

-- check if a flash request is queued
::connect::
local passed = os.difftime(startup, os.time())
if passed < 10 then
  -- wait for a flash request
  message, _, _, port, _, command, rom = computer.pullSignal(10 - passed)

  if message == "modem_message" and port == 122 and command == "af_flash" then
    -- write the received ROM to the EEPROM
    eeprom.set(rom)

    -- success beeps
    for i = 1, 3 do
      computer.beep(1000, 0.1)
    end

    -- reboot into the new ROM
    computer.shutdown(true)
  end
end

modem.close()
