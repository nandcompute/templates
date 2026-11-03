# ===================================================================
# project.mk: per-project settings for the Vivado Makefile
# Nand Compute Templates — make/vivado/
#
# This is the only build file you edit in a project. Everything else
# (Makefile, mk/*.mk, tcl/*.tcl) is copied unchanged, so it can be
# upgraded by copying a newer version of the template over it.
# ===================================================================

# -------------------------------------------------------------------
# Vivado version. Builds stop if the installed version differs
# (make ... VERSION_CHECK=warn to continue anyway).
# -------------------------------------------------------------------
VIVADO_VERSION := 2025.2

# -------------------------------------------------------------------
# IP packaging: how the packaged IP appears in the Vivado IP catalog.
# The VLNV of each IP is <IP_VENDOR>:<IP_LIBRARY>:<name>:<version>.
# -------------------------------------------------------------------
IP_VENDOR      := acme.com
IP_VENDOR_NAME := Acme
IP_LIBRARY     := user
IP_TAXONOMY    := /Acme
IP_VERSION     := 1.0
# IP_URL       := https://www.acme.com
# Part used while packaging (default: Vivado's default part). Set it
# when an IP uses primitives of a specific family, e.g. UltraScale.
# IP_PART      := xczu9eg-ffvb1156-2-e

# -------------------------------------------------------------------
# IPs are found automatically: every folder in IP_DIR with an ip.tcl.
# Per-IP settings, all optional:
#
#   ip.<name>.deps     Other IPs whose sources this one includes
#   ip.<name>.sources  HDL files in compile order (default: all *.vhd,
#                      *.vhdl, *.v, *.sv in the folder, *_pkg first)
#   ip.<name>.version  Overrides IP_VERSION
#   ip.<name>.tb_top   Testbench top (default: <name>_tb)
# -------------------------------------------------------------------
# ip.mux_synchronizer.deps := flip_flop_synchronizer

# -------------------------------------------------------------------
# Designs: folders in DESIGN_DIR built into a bitstream and an XSA.
# Per-design settings:
#
#   design.<name>.part      FPGA part (required)
#   design.<name>.board     Board part, e.g. digilentinc.com:arty-z7-20:part0:1.1
#   design.<name>.libs      IPs from IP_DIR whose HDL is compiled into
#                           the design, for RTL top levels: instantiate
#                           them as entity work.<ip>
#   design.<name>.ips       IPs from IP_DIR used as packaged IP, in a
#                           block design (system_bd.tcl) or ips.tcl
#   design.<name>.ip_repos  Extra IP repositories for third-party IP
#                           (space-separated, no spaces in paths), e.g.
#                           $(PROJ_DIR)/vendor/<vendor>/<dist>
#   design.<name>.top       Top module (default: system_top)
#   design.<name>.generics  Top-level generics, e.g. CHANNELS=4 DEBUG=0
#
# For make flash-<name> (FPGAs that boot from configuration flash;
# Zynq and Versal boot from a BOOT.BIN made in Vitis instead):
#
#   design.<name>.flash            Vivado's name for the board's flash
#                                  part (see get_cfgmem_parts)
#   design.<name>.flash_size       Flash size in MB
#   design.<name>.flash_interface  SPIx1, SPIx2, SPIx4 (default), SPIx8,
#                                  BPIx8, BPIx16
# -------------------------------------------------------------------
DESIGNS :=

# DESIGNS += acme_arty
# design.acme_arty.part  := xc7z020clg400-1
# design.acme_arty.board := digilentinc.com:arty-z7-20:part0:1.1
# design.acme_arty.ips   := clock_forwarder mux_synchronizer

# DESIGNS += acme_artix
# design.acme_artix.part       := xc7a35ticsg324-1L
# design.acme_artix.flash      := s25fl128sxxxxxx0-spi-x1_x2_x4
# design.acme_artix.flash_size := 16

# -------------------------------------------------------------------
# Optional fragments from make/common/ in nandcompute/templates,
# e.g. doxygen.
# -------------------------------------------------------------------
MK_FRAGMENTS :=

# -------------------------------------------------------------------
# Layout (defaults shown; uncomment to change)
# -------------------------------------------------------------------
# IP_DIR     := $(PROJ_DIR)/library
# DESIGN_DIR := $(PROJ_DIR)/designs
# BUILD_DIR  := $(PROJ_DIR)/build

# -------------------------------------------------------------------
# Machine-specific settings (XILINX_ROOT, JOBS, HW_SERVER, HW_TARGET)
# go in local.mk, not here: this file is shared by everyone working
# on the project.
# -------------------------------------------------------------------