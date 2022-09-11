-- eeprom to find the address (uuid) of the attached modem

local modem = component.proxy(component.list("modem")())

-- error out the address so it can be read by an analyzer
error(modem.address)
