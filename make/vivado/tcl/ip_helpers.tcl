# SPDX-FileCopyrightText: 2026 Nand Compute LLC
# SPDX-License-Identifier: MIT-0

# ===================================================================
# ip_helpers.tcl: helpers for an IP's own ip.tcl
# Nand Compute Templates — make/vivado/tcl/
#
# package_ip.tcl creates the project, adds the sources and packages
# the IP, then sources <ip>/ip.tcl, which uses these helpers to
# declare the IP's interfaces and GUI. Packaging starts with no bus
# interfaces, so every interface is declared explicitly.
#
# Example <ip>/ip.tcl:
#   tpl::infer_clock clk
#   tpl::infer_reset rst_n
#   tpl::gui_combo   TARGET {XILINX GENERIC}
#   tpl::gui_range   STAGES 2 8
#   tpl::gui_order   {TARGET STAGES DATA_WIDTH}
# ===================================================================

## Declare <port> as a clock interface.
#  Optional: the bus interfaces it clocks, e.g. {s_axi m_axis}.
proc tpl::infer_clock {port {busifs {}}} {
    set cc [ipx::current_core]
    ipx::infer_bus_interface $port xilinx.com:signal:clock_rtl:1.0 $cc
    if {[llength $busifs] > 0} {
        set intf [ipx::get_bus_interfaces $port -of_objects $cc]
        set param [ipx::add_bus_parameter ASSOCIATED_BUSIF $intf]
        set_property value [join $busifs :] $param
    }
}

## Declare <port> as a reset interface.
#  polarity: high, low, or auto (default). auto means active-low when
#  the name ends in rstn, rst_n, resetn or reset_n, optionally followed
#  by _i or _o (aresetn, rst_n_i, ...), otherwise active-high. Pass
#  the polarity explicitly for any other naming.
#  mode: slave (an input, default) or master (an output).
proc tpl::infer_reset {port {polarity auto} {mode slave}} {
    set cc [ipx::current_core]
    ipx::infer_bus_interface $port xilinx.com:signal:reset_rtl:1.0 $cc
    set intf [ipx::get_bus_interfaces $port -of_objects $cc]
    set_property interface_mode $mode $intf

    if {$polarity eq "auto"} {
        if {[regexp -nocase {(rst|reset)_?n(_[io])?$} $port]} {
            set polarity low
        } else {
            set polarity high
        }
    }
    switch -- $polarity {
        low     { set value ACTIVE_LOW }
        high    { set value ACTIVE_HIGH }
        default { error "tpl::infer_reset $port: polarity must be high, low or auto, not '$polarity'" }
    }
    set param [ipx::add_bus_parameter POLARITY $intf]
    set_property value $value $param
}

## Infer every AXI4 / AXI4-Lite memory-mapped interface from port names.
proc tpl::infer_axi_mm {} {
    ipx::infer_bus_interfaces xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]
}

## Infer every AXI4-Stream interface from port names.
proc tpl::infer_axis {} {
    ipx::infer_bus_interfaces xilinx.com:interface:axis_rtl:1.0 [ipx::current_core]
}

## Show parameter <param> as a drop-down limited to <values>.
proc tpl::gui_combo {param values} {
    set cc [ipx::current_core]
    set uparam [ipx::get_user_parameters $param -of_objects $cc]
    set_property value_validation_type list $uparam
    set_property value_validation_list $values $uparam
    set_property widget comboBox [ipgui::get_guiparamspec -name $param -component $cc]
}

## Limit integer parameter <param> to <min>..<max>.
proc tpl::gui_range {param min max} {
    set cc [ipx::current_core]
    set uparam [ipx::get_user_parameters $param -of_objects $cc]
    set_property value_validation_type range_long $uparam
    set_property value_validation_range_minimum $min $uparam
    set_property value_validation_range_maximum $max $uparam
    set_property widget textEdit [ipgui::get_guiparamspec -name $param -component $cc]
}

## Show the parameters in <params> in that order on the first GUI page.
proc tpl::gui_order {params} {
    set cc [ipx::current_core]
    set page [ipgui::get_pagespec -name "Page 0" -component $cc]
    set index 0
    foreach param $params {
        ipgui::move_param -component $cc -order $index -parent $page \
            [ipgui::get_guiparamspec -name $param -component $cc]
        incr index
    }
}