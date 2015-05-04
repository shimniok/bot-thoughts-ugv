# Assembly #

## Install pin headers ##

### MCU Sockets ###
  1. Cut black female sockets to 27 pins
  1. Install 1 female socket in each LPCXPRESSO/mbed row of holes

### LPCXPresso Preparation ###
  1. Optionally, cut apart LPCXpresso from LPC-Link.
  1. Follow [Instructions](http://www.bot-thoughts.com/2012/01/lpcxpresso-surgery.html) for separating boards
  1. Install male pin headers on LPCXpresso, top
  1. Install female pin headers on LPC-Link, bottom

### Power and Reset Ports ###
  1. Black 2-pin header on POWER and RST
  1. Black 3-pin header on BECSEL

### Control Port ###
  1. Yellow 4-pin header on CONTROL:SIG
  1. Red 4-pin header on CONTROL:5V/6V
  1. Black 4-pin header on CONTROL:GND

### Encoders Port ###
  1. Black 4-pin header on one of two ENCODERS
  1. White 4-pin header on one of two ENCODERS

### I2C Port ###
  1. Yellow 5-pin header on I2C:SDA
  1. Blue 5-pin header on I2C:SCL
  1. 2x Red 5-pin header on I2C:3V and IC2:5V
  1. Black 5-pin header on I2C:GND,

### UART Ports ###
  1. Black 5-pin headers on UART0, UART1, UART2, UART3

### Rear analog/digital/pwm ports ###
  1. Yellow 11-pin header on rearmost port with 11 pins, SIG
  1. Red 11-pin header on rearmost port with 11 pins, 3.3V
  1. Black 11-pin header on rearmost port with 11 pins, GND

# Power #

Power your RoverBaseboard with an external 5V regulator connected to the POWER:5V and POWER:GND pins. This will supply power to the 5V pins. On the mbed version of the board, 3.3V comes from the mbed's 3.3V regulator connected to Vout. The LPCXpresso version has a 3.3V regulator populated onto the RoverBaseboard. Both versions have a wire jumper from the POWER:5V pin to VIN.

## LPCXpresso Power ##
The LPCXpresso LPCLink board has a 3.3V regulator and can power the LPCXpresso from USB. With the LPCLink disconnected, power is supplied to the LPCXpresso by an onboard 3.3V NCP1117 1A regulator.

## mbed Power ##
The mbed, unlike the LPCXpresso, already has an onboard 3.3V, 1A regulator, and lacks a diode on the Vout pin. For this reason, the mbed version of the RoverBaseboard leaves the onboard regulator unpopulated.

## Control Port ##
The CONTROL port's 5V/6V pins are all connected together but not connected to anything else on the board.