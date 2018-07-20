set_global_assignment -entity "audio_pll" -library "lib_audio_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "audio_pll" -library "lib_audio_pll" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "audio_pll" -library "lib_audio_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_audio_pll" -name SPD_FILE [file join $::quartus(sip_path) "audio_pll.spd"]

set_global_assignment -library "lib_audio_pll" -name MISC_FILE [file join $::quartus(sip_path) "audio_pll_sim/audio_pll.vho"]
