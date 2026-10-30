# ===================================================================
# common.tcl: shared helpers for the Vivado template scripts
# Nand Compute Templates — make/vivado/tcl/
#
# Settings arrive from Make as TPL_* environment variables.
# ===================================================================

namespace eval tpl {}

## Value of environment variable <name>, or <default> if unset or empty.
proc tpl::env {name {default ""}} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

## Value of environment variable <name>; stops if it is unset or empty.
proc tpl::require_env {name} {
    set value [tpl::env $name]
    if {$value eq ""} {
        error "$name is not set. Run this script through make."
    }
    return $value
}

## Stop (or warn, with VERSION_CHECK=warn) if the running Vivado isn't
## the version in project.mk. A patch release (2025.2.1) counts as a
## match for 2025.2.
proc tpl::check_version {} {
    set want [tpl::env TPL_VIVADO_VERSION]
    if {$want eq ""} {
        return
    }
    set have [version -short]
    if {$have eq $want || [string match "${want}.*" $have]} {
        return
    }
    set msg "Vivado $have is running, but project.mk asks for $want."
    if {[tpl::env TPL_VERSION_CHECK error] eq "warn"} {
        puts "CRITICAL WARNING: $msg Continuing because VERSION_CHECK=warn."
    } else {
        error "$msg Install $want, or run make with VERSION_CHECK=warn to continue anyway."
    }
}

## Add HDL files to the current project's sources. VHDL files are
## marked VHDL-2008 unless VHDL_2008=0.
proc tpl::add_hdl {files} {
    if {[llength $files] == 0} {
        return
    }
    add_files -norecurse -fileset sources_1 $files
    if {[tpl::env TPL_VHDL_2008 1] eq "1"} {
        set vhdl [get_files -quiet -of_objects [get_filesets sources_1] -filter {FILE_TYPE == VHDL}]
        if {[llength $vhdl] > 0} {
            set_property FILE_TYPE {VHDL 2008} $vhdl
        }
    }
}

## Add constraint files to the current project.
proc tpl::add_xdc {files} {
    if {[llength $files] > 0} {
        add_files -norecurse -fileset constrs_1 $files
    }
}

## Source <file> at global level if it exists.
proc tpl::source_if_exists {file} {
    if {[file exists $file]} {
        puts "INFO: Sourcing $file"
        uplevel #0 [list source $file]
    }
}