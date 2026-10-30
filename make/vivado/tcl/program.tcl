# ===================================================================
# program.tcl: load a design onto hardware
# Nand Compute Templates — make/vivado/tcl/
#
# Run by "make program-<name>" and "make flash-<name>" (mk/design.mk),
# which pass the settings as TPL_* environment variables.
#
#   TPL_PROGRAM_MODE=jtag   load the bitstream into the FPGA (lost at
#                           power-off)
#   TPL_PROGRAM_MODE=flash  write the configuration flash, then reboot
#                           the FPGA from it
# ===================================================================

set tcl_dir [file dirname [file normalize [info script]]]
source [file join $tcl_dir common.tcl]

tpl::check_version

set mode   [tpl::require_env TPL_PROGRAM_MODE]
set part   [tpl::require_env TPL_DESIGN_PART]
set file   [tpl::require_env TPL_PROGRAM_FILE]
set server [tpl::env TPL_HW_SERVER localhost:3121]
set serial [tpl::env TPL_HW_TARGET]

if {![file exists $file]} {
    error "$file does not exist."
}

# Zynq, Zynq UltraScale+ and Versal boot through the processor from a
# BOOT.BIN, not from a configuration-flash image.
if {$mode eq "flash" && [regexp -nocase {^xc(7z|zu|k26|v[cempha])} $part]} {
    error "$part boots through its processor, so its flash holds a BOOT.BIN from Vitis (bootgen, then program_flash), not this image. Use make program-<design> to load the bitstream over JTAG."
}

# -------------------------------------------------------------------
# Connect to the JTAG cable. With several cables connected, HW_TARGET
# (part of the cable's serial number) picks one.
# -------------------------------------------------------------------
open_hw_manager
connect_hw_server -url $server

set targets [get_hw_targets -quiet]
if {$serial ne ""} {
    set targets [lsearch -all -inline $targets "*$serial*"]
}
if {[llength $targets] == 0} {
    error "No JTAG cable found on $server[expr {$serial ne "" ? " matching HW_TARGET=$serial" : ""}]. Check the cable, power and cable drivers."
}
if {[llength $targets] > 1} {
    error "Several JTAG cables found; set HW_TARGET to part of one serial number:\n  [join $targets "\n  "]"
}
open_hw_target [lindex $targets 0]

# The FPGA on the chain whose part matches the design (a Zynq chain
# also shows the ARM debug port, which is skipped this way).
set device ""
foreach d [get_hw_devices] {
    set dev_part [get_property PART $d]
    if {$dev_part ne "" && [string match -nocase "${dev_part}*" $part]} {
        set device $d
        break
    }
}
if {$device eq ""} {
    error "No device matching $part on the JTAG chain. Found: [get_hw_devices]"
}
current_hw_device $device
refresh_hw_device -update_hw_probes false $device

# -------------------------------------------------------------------
# JTAG: load the bitstream, plus debug probes (ILA, VIO) if built
# -------------------------------------------------------------------
if {$mode eq "jtag"} {
    set_property PROGRAM.FILE $file $device
    set probes [file rootname $file].ltx
    set_property PROBES.FILE [expr {[file exists $probes] ? $probes : ""}] $device
    set_property FULL_PROBES.FILE [expr {[file exists $probes] ? $probes : ""}] $device
    program_hw_devices $device
    refresh_hw_device $device
    puts "INFO: Programmed $device with [file tail $file]"
}

# -------------------------------------------------------------------
# Flash: load Vivado's flash-programming design into the FPGA, write
# the configuration memory through it, then reboot from flash.
# -------------------------------------------------------------------
if {$mode eq "flash"} {
    set flash_part [tpl::require_env TPL_FLASH_PART]
    set cfgmem_part [lindex [get_cfgmem_parts $flash_part] 0]
    if {$cfgmem_part eq ""} {
        error "Unknown flash part $flash_part. List valid names in the Vivado Tcl console with: get_cfgmem_parts"
    }
    create_hw_cfgmem -hw_device $device $cfgmem_part
    set mem [get_property PROGRAM.HW_CFGMEM $device]
    set_property PROGRAM.ADDRESS_RANGE         use_file  $mem
    set_property PROGRAM.FILES                 [list $file] $mem
    set_property PROGRAM.UNUSED_PIN_TERMINATION pull-none $mem
    set_property PROGRAM.BLANK_CHECK           0 $mem
    set_property PROGRAM.ERASE                 1 $mem
    set_property PROGRAM.CFG_PROGRAM           1 $mem
    set_property PROGRAM.VERIFY                1 $mem
    set_property PROGRAM.CHECKSUM              0 $mem

    create_hw_bitstream -hw_device $device [get_property PROGRAM.HW_CFGMEM_BITFILE $device]
    program_hw_devices $device
    refresh_hw_device $device
    program_hw_cfgmem -hw_cfgmem $mem

    boot_hw_device $device
    puts "INFO: Wrote [file tail $file] to $flash_part and rebooted $device from it"
}

close_hw_target
disconnect_hw_server
close_hw_manager