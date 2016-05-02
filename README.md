# fpgaNES

This is an implementation of the nintendo entertainment system in an FPGA.

It is based on the development board Cyclone V GX Starter Kit by Terasic with an
Altera Cyclone V on board. It features plenty of memory, an HDMI out and an analog
Audio Codec. For some reason they decided to not connect the HDMI audio pins of the
ADV7513 HDMI chip to the FPGA. But kindly they added solder points for the audio pins
so i was able to access them trough some GPIO pins of the FPGA getting 44.1 kHz Audio
directly through the HDMI connection. The hdmi video resolution is 640x480 at a
framerate of 50 Hz having 2x2 display pixels per nes pixel. Beside the HDMI audio pins i
soldered a NES Four Score to the GPIO-Port to simply plug/unplug the controllers to the
FPGA.

What works:

- https://github.com/Klaus2m5/6502_65C02_functional_tests
- Super Mario Brothers 1
- blargg_ppu_tests_2005.09.15b
- NEStress
- ppu_vbl_nmi
- sprite_hit_tests_2005.10.05
(Audio test roms are the next things on my todo list)


What is currently not implemented:

- PPU color emphasize
- low / high pass filter (i added both with the equations blargg published but for some reason they don’t work)
- Support for PAL games (currently i only implemented the clock speed and lookup tables for NTSC games)
