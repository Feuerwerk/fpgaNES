set_global_assignment -entity "master_reconfig" -library "lib_master_reconfig" -name IP_TOOL_NAME "altera_pll_reconfig"
set_global_assignment -entity "master_reconfig" -library "lib_master_reconfig" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "master_reconfig" -library "lib_master_reconfig" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_master_reconfig" -name SPD_FILE [file join $::quartus(sip_path) "master_reconfig.spd"]

set_global_assignment -library "lib_master_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "master_reconfig_sim/master_reconfig.vhd"]
set_global_assignment -library "lib_master_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "master_reconfig_sim/altera_pll_reconfig/altera_pll_reconfig_top.v"]
set_global_assignment -library "lib_master_reconfig" -name MISC_FILE [file join $::quartus(sip_path) "master_reconfig_sim/altera_pll_reconfig/altera_pll_reconfig_core.v"]
