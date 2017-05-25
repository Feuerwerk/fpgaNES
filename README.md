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

The following tests are from http://wiki.nesdev.com/w/index.php/Emulator_tests
Passed Tests:

CPU)
- cpu_interrupts_v2 (all but 5-branch_delays_irq)

PPU)
- oam_read
- oam_stress
- ppu_sprite_hit
- ppu_open_bus
- ppu_vbl_nmi
- ppu_sprite_overflow (all but 03-timing sometimes)

APU)
- blargg_apu_2005.07.30 (all but 07.irq_flag_timing and 09.reset_timing)
- apu_test (all but 6-irq_flag_timing)

What works:

- https://github.com/Klaus2m5/6502_65C02_functional_tests
- Super Mario Brothers 1
- Super Mario Brothers 2
- Super Mario Brothers 3
- Mario Bros. Classic
- Mario & Yoshi
- Donkey Kong
- The Smurfs
- Metroid
- Megaman 1-6


What works a little bit

- Micro Machines (various glitches)
- Battletoads (various glitches)


What is currently not implemented:

- low / high pass filter (i added both with the equations blargg published but for some reason they don’t work)
