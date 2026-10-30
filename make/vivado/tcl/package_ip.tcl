# ===================================================================
# package_ip.tcl: package one IP for the Vivado IP catalog
# Nand Compute Templates — make/vivado/tcl/
#
# Run by "make ip-<name>" (mk/ip.mk), which passes the settings as
# TPL_* environment variables.
# ===================================================================

set tcl_dir [file dirname [file normalize [info script]]]
source [file join $tcl_dir common.tcl]
source [file join $tcl_dir ip_helpers.tcl]

tpl::check_version

set name    [tpl::require_env TPL_IP_NAME]
set ip_dir  [tpl::require_env TPL_IP_DIR]
set out_dir [tpl::require_env TPL_IP_OUT]
set work    [tpl::require_env TPL_IP_WORK]
set sources [tpl::require_env TPL_IP_SOURCES]
set xdc     [tpl::env TPL_IP_XDC]

# -------------------------------------------------------------------
# Project with the IP's sources
# -------------------------------------------------------------------
file delete -force $out_dir
file mkdir $out_dir
if {[tpl::env TPL_IP_PART] ne ""} {
    create_project -force ${name}_package [file join $work project] -part [tpl::env TPL_IP_PART]
} else {
    create_project -force ${name}_package [file join $work project]
}

tpl::add_hdl $sources
tpl::add_xdc $xdc
set_property top $name [current_fileset]
update_compile_order -fileset sources_1

# -------------------------------------------------------------------
# Package. -import_files copies the sources into the IP, so the
# packaged IP doesn't depend on the library folder.
# -------------------------------------------------------------------
ipx::package_project -root_dir $out_dir -import_files -set_current true \
    -vendor   [tpl::require_env TPL_IP_VENDOR] \
    -library  [tpl::env TPL_IP_LIBRARY user] \
    -taxonomy [tpl::env TPL_IP_TAXONOMY /UserIP]

set cc [ipx::current_core]
set_property name    $name $cc
set_property version [tpl::env TPL_IP_VERSION 1.0] $cc
set_property display_name $name $cc
set_property vendor_display_name [tpl::env TPL_IP_VENDOR_NAME [tpl::env TPL_IP_VENDOR]] $cc
if {[tpl::env TPL_IP_URL] ne ""} {
    set_property company_url [tpl::env TPL_IP_URL] $cc
}
# Usable on every device family Vivado supports.
set_property AUTO_FAMILY_SUPPORT_LEVEL level_2 $cc

# Drop what packaging inferred on its own; ip.tcl declares the
# interfaces explicitly.
ipx::remove_all_bus_interface $cc
foreach map [ipx::get_memory_maps -quiet -of_objects $cc] {
    ipx::remove_memory_map [get_property NAME $map] $cc
}

# -------------------------------------------------------------------
# The IP's own settings: interfaces, GUI
# -------------------------------------------------------------------
uplevel #0 [list source [file join $ip_dir ip.tcl]]

ipx::create_xgui_files $cc
ipx::update_checksums $cc
ipx::check_integrity $cc
ipx::save_core $cc
close_project

puts "INFO: Packaged $name in $out_dir"