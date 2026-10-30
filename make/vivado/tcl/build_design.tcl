# ===================================================================
# build_design.tcl: build one design into a bitstream and an XSA
# Nand Compute Templates — make/vivado/tcl/
#
# Run by "make bit-<name>" (mk/design.mk), which passes the settings
# as TPL_* environment variables.
#
# Output in TPL_DESIGN_OUT: <name>.bit, <name>.xsa, timing.rpt and
# utilization.rpt, plus <name>.ltx with debug cores and <name>.mcs
# with a flash part. If timing fails, the bitstream and XSA are named
# <name>_bad_timing.*, no flash image is written, and the build stops
# with an error.
# ===================================================================

set tcl_dir [file dirname [file normalize [info script]]]
source [file join $tcl_dir common.tcl]

tpl::check_version

set name    [tpl::require_env TPL_DESIGN_NAME]
set src_dir [tpl::require_env TPL_DESIGN_DIR]
set out_dir [tpl::require_env TPL_DESIGN_OUT]
set work    [tpl::require_env TPL_DESIGN_WORK]
set part    [tpl::require_env TPL_DESIGN_PART]
set board   [tpl::env TPL_DESIGN_BOARD]
set top     [tpl::env TPL_DESIGN_TOP system_top]
set jobs    [tpl::env TPL_JOBS 4]

## Stop if run <run> didn't complete.
proc tpl::check_run {run} {
    set r [get_runs $run]
    if {[get_property PROGRESS $r] ne "100%"} {
        error "$run failed: [get_property STATUS $r]. See the run logs under [get_property DIRECTORY $r]."
    }
}

# -------------------------------------------------------------------
# Project
# -------------------------------------------------------------------
file delete -force $out_dir
file mkdir $out_dir
create_project -force $name $work -part $part
if {$board ne ""} {
    set_property board_part $board [current_project]
}

set_property ip_repo_paths [list [tpl::require_env TPL_IP_REPO]] [current_project]
update_ip_catalog -rebuild

if {[tpl::env TPL_IP_CACHE] ne ""} {
    file mkdir [tpl::env TPL_IP_CACHE]
    config_ip_cache -use_cache_location [tpl::env TPL_IP_CACHE]
}

# Project-specific message severities, e.g.
#   set_msg_config -id {Synth 8-3331} -new_severity INFO
tpl::source_if_exists [file join $src_dir msg.tcl]

tpl::add_hdl [tpl::env TPL_DESIGN_SOURCES]
tpl::add_xdc [tpl::env TPL_DESIGN_XDC]

# -------------------------------------------------------------------
# Block design, if the design has one
# -------------------------------------------------------------------
set bd_tcl [file join $src_dir system_bd.tcl]
if {[file exists $bd_tcl]} {
    create_bd_design system
    uplevel #0 [list source $bd_tcl]
    validate_bd_design
    save_bd_design
    set bd_file [get_files system.bd]
    generate_target all $bd_file
    tpl::add_hdl [make_wrapper -files $bd_file -top]
}

set_property top $top [current_fileset]
if {[tpl::env TPL_DESIGN_GENERICS] ne ""} {
    set_property generic [tpl::env TPL_DESIGN_GENERICS] [current_fileset]
}
update_compile_order -fileset sources_1

# Compress the bitstream. Set as a pre-bitstream step, so it applies
# to the implemented design the bitstream is written from.
file mkdir $work
set pre_bit [file join $work pre_bitstream.tcl]
set f [open $pre_bit w]
puts $f {set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]}
close $f
set_property STEPS.WRITE_BITSTREAM.TCL.PRE $pre_bit [get_runs impl_1]

# -------------------------------------------------------------------
# Synthesis and implementation
# -------------------------------------------------------------------
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
tpl::check_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
tpl::check_run impl_1

# -------------------------------------------------------------------
# Reports and checks
# -------------------------------------------------------------------
open_run impl_1
report_timing_summary -file [file join $out_dir timing.rpt]
report_utilization    -file [file join $out_dir utilization.rpt]

# Registers with no clock don't show up as timing failures.
set no_clock [check_timing -override_defaults no_clock -no_header -return_string]
if {[regexp {There (?:is|are) (\d+) register} $no_clock -> count] && $count > 0} {
    check_timing -override_defaults no_clock -verbose -file [file join $out_dir no_clock.rpt]
    puts "CRITICAL WARNING: $count register(s) have no clock. See no_clock.rpt."
}

# A design that fails timing still gets its outputs, for debugging,
# but named *_bad_timing so they can't be mistaken for a release.
set wns [get_property STATS.WNS [get_runs impl_1]]
set whs [get_property STATS.WHS [get_runs impl_1]]
set timing_met [expr {$wns >= 0 && $whs >= 0}]
set base [expr {$timing_met ? $name : "${name}_bad_timing"}]

set bit [lindex [glob -directory [get_property DIRECTORY [get_runs impl_1]] *.bit] 0]
file copy -force $bit [file join $out_dir $base.bit]
write_hw_platform -fixed -include_bit -force -file [file join $out_dir $base.xsa]

# Debug probes for ILA / VIO cores, loaded by "make program-<name>".
if {[llength [get_debug_cores -quiet]] > 0} {
    write_debug_probes -force [file join $out_dir $base.ltx]
}

if {!$timing_met} {
    error "Timing not met (WNS $wns ns, WHS $whs ns). See timing.rpt."
}

# Configuration flash image, when the design has a flash part.
if {[tpl::env TPL_FLASH_PART] ne ""} {
    write_cfgmem -force -format mcs \
        -size      [tpl::require_env TPL_FLASH_SIZE] \
        -interface [tpl::env TPL_FLASH_INTERFACE SPIx4] \
        -loadbit   "up 0x00000000 [file join $out_dir $name.bit]" \
        -file      [file join $out_dir $name.mcs]
}

puts "INFO: Built $name: WNS $wns ns, WHS $whs ns"