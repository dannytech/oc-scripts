-- write a ROM onto the actively running system from across the network.
-- note that writing the EEPROM will overwrite this program, so the client should send a copy of this program
-- every time if this functionality needs to be preserved.

local modem = component.proxy(component.list("modem")())
local eeprom = component.eeprom

-- listen for incoming flash connections
modem.open(122)
io.write("Autoflash: My address is " + modem.address + "\n")

-- when a remote flash message is received, write the data to the EEPROM
event.listen("modem_message", function(_, _, from, port, _, message, rom)
    if port == 122 and message == "remote_flash" then
      -- write the revceived ROM to the EEPROM
      eeprom.set(rom)

      -- reboot into the new ROM
      computer.shutdown(true)
    end
end)
