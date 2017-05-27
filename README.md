# fpgaNES

This is an implementation of the Nintendo Entertainment System in an FPGA.

It is based on the development board Cyclone V GX Starter Kit by Terasic with an
Altera Cyclone V on board. It features plenty of memory, an HDMI out and an analog
Audio Codec. For some reason they decided to not connect the HDMI audio pins of the
ADV7513 HDMI chip to the FPGA. But kindly they added solder points for the audio pins
so i was able to access them trough some GPIO pins of the FPGA getting 44.1 kHz Audio
directly through the HDMI connection. The hdmi video resolution is 640x480 at a
framerate of 50 Hz having 2x2 display pixels per NES pixel. Beside the HDMI audio pins i
soldered a NES Four Score to the GPIO-Port to simply plug/unplug the controllers to the
FPGA.

The following tests are from http://wiki.nesdev.com/w/index.php/Emulator_tests.

Test Results:

CPU)
- cpu_interrupts_v2 (5/5)
- instr_misc (2/4) : 03-dummy_reads, 04_dummy_reads_apu
- instr_timing (1/2) : 1-instr_timing (because illegal opcodes not supported yet)
- instr_test-v5 (16/16) : OFFICIAL Opcodes only
- cpu_dummy_reads (1/1)

PPU)
- oam_read (1/1)
- oam_stress (1/1)
- ppu_sprite_hit (10/10)
- ppu_open_bus (1/1)
- ppu_vbl_nmi (10/10)
- ppu_sprite_overflow (4/5) : 05-emulator

APU)
- blargg_apu_2005.07.30 (10/11) :  09.reset_timing
- apu_test (8/8)
- apu_mixer (2/4) : noise, triangle
- dmc_dma_during_read4 (1/5) : dma_2007_read, dma_2007_write, dma_4016_read, read_write_2007
- square_timer_div2 (1/1)
- test_apu_env (1/1)
- test_apu_sweep (2/2)
- test_apu_timers (4/4)
- test_tri_lin_ctr (?/1) UNSURE


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
