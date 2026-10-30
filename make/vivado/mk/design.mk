# ===================================================================
# design.mk: build each design into a bitstream and an XSA
# Nand Compute Templates — make/vivado/mk/
#
# A design is a folder in DESIGN_DIR, listed in DESIGNS in project.mk.
# It holds the top-level HDL, constraints (*.xdc), and optionally
# system_bd.tcl (block design), ips.tcl (third-party IP, run before
# synthesis) and msg.tcl (message severities).
# Output goes to $(BUILD_DIR)/designs/<name>/: <name>.bit, <name>.xsa,
# timing and utilization reports, <name>.ltx when the design has debug
# cores (ILA, VIO), and <name>.mcs when it has a flash part.
#
# program-<name> and flash-<name> load the last build onto hardware;
# they never start a build themselves.
# ===================================================================

##
## Designs (replace <design> with one of the designs above):
##   bit-<design>        Build the bitstream and XSA (and the IPs it uses)
##   program-<design>    Load the bitstream over JTAG (lost at power-off)
##   flash-<design>      Write the configuration flash, then boot from it
##   gui-<design>        Open the built design's project in the Vivado GUI
##   clean-design-<design>  Remove a design's build output
##   clean-designs       Remove every design's build output

DESIGN_BUILD_DIR = $(BUILD_DIR)/designs
DESIGN_WORK_DIR  = $(BUILD_DIR)/work/designs

# IP cache shared by all designs, so unchanged IP isn't synthesized
# again. IP_CACHE= (empty) turns it off.
IP_CACHE ?= $(BUILD_DIR)/ipcache

# Hardware server and JTAG cable, for program-/flash-. Set them in
# local.mk: HW_SERVER for a board attached to another machine (which
# runs hw_server), HW_TARGET (part of the cable's serial number) when
# several cables are connected.
HW_SERVER ?= localhost:3121
HW_TARGET ?=

_design_hdl     = $(sort $(wildcard $(addprefix $(DESIGN_DIR)/$(1)/*.,vhd vhdl v sv)))
_design_xdc     = $(sort $(wildcard $(DESIGN_DIR)/$(1)/*.xdc))
_design_tcl     = $(wildcard $(addprefix $(DESIGN_DIR)/$(1)/,system_bd.tcl ips.tcl msg.tcl))
_design_ips     = $(foreach ip,$(design.$(1).ips),$(call ip_component,$(ip)))
_design_xsa     = $(DESIGN_BUILD_DIR)/$(1)/$(1).xsa

# $(call _design_require,<file>,<design>): stop with a hint if <file>
# hasn't been built.
define _design_require
if [ ! -f "$(1)" ]; then \
	echo "No $(notdir $(1)) in $(dir $(1)). Run: make bit-$(2)"; \
	exit 1; \
fi
endef

# $(call _design_program,<design>,<mode>,<file>,<description>)
define _design_program
$$(call run_logged,$(4),$(DESIGN_WORK_DIR)/$(1)/$(2).log,\
	cd "$(DESIGN_WORK_DIR)/$(1)" && $$(VIVADO_SHELL) $$(VIVADO_ENV) \
	TPL_PROGRAM_MODE="$(2)" \
	TPL_PROGRAM_FILE="$(3)" \
	TPL_DESIGN_PART="$(design.$(1).part)" \
	TPL_FLASH_PART="$(design.$(1).flash)" \
	TPL_HW_SERVER="$$(HW_SERVER)" \
	TPL_HW_TARGET="$$(HW_TARGET)" \
	vivado -mode batch -nojournal -nolog -notrace \
	-source "$(TCL_DIR)/program.tcl")
endef

# -------------------------------------------------------------------
# $(call design_rule,<name>)
# -------------------------------------------------------------------
define design_rule
ifeq ($$(strip $$(design.$(1).part)),)
$$(error design.$(1).part is not set in project.mk)
endif
ifeq ($$(wildcard $(DESIGN_DIR)/$(1)),)
$$(error Design folder $(DESIGN_DIR)/$(1) does not exist)
endif
$$(foreach ip,$$(design.$(1).ips),$$(if $$(filter $$(ip),$$(IPS)),,$$(error design.$(1).ips: no IP "$$(ip)" in $$(IP_DIR))))
ifneq ($$(strip $$(design.$(1).flash)),)
ifeq ($$(strip $$(design.$(1).flash_size)),)
$$(error design.$(1).flash_size (in MB) is not set in project.mk)
endif
endif

$(call _design_xsa,$(1)): $(call _design_hdl,$(1)) $(call _design_xdc,$(1)) $(call _design_tcl,$(1)) \
		$(call _design_ips,$(1)) \
		$(TCL_DIR)/common.tcl $(TCL_DIR)/build_design.tcl $(MK_DIR)/project.mk | vivado-check
	$$(call run_logged,Building design $(1),$(DESIGN_WORK_DIR)/$(1)/build.log,\
		cd "$(DESIGN_WORK_DIR)/$(1)" && $(VIVADO_SHELL) $(VIVADO_ENV) \
		TPL_DESIGN_NAME="$(1)" \
		TPL_DESIGN_DIR="$(DESIGN_DIR)/$(1)" \
		TPL_DESIGN_OUT="$(DESIGN_BUILD_DIR)/$(1)" \
		TPL_DESIGN_WORK="$(DESIGN_WORK_DIR)/$(1)" \
		TPL_DESIGN_PART="$(design.$(1).part)" \
		TPL_DESIGN_BOARD="$(design.$(1).board)" \
		TPL_DESIGN_TOP="$(or $(design.$(1).top),system_top)" \
		TPL_DESIGN_GENERICS="$(strip $(design.$(1).generics))" \
		TPL_DESIGN_SOURCES="$(call _design_hdl,$(1))" \
		TPL_DESIGN_XDC="$(call _design_xdc,$(1))" \
		TPL_FLASH_PART="$(design.$(1).flash)" \
		TPL_FLASH_SIZE="$(design.$(1).flash_size)" \
		TPL_FLASH_INTERFACE="$(or $(design.$(1).flash_interface),SPIx4)" \
		TPL_IP_REPO="$(IP_BUILD_DIR)" \
		TPL_EXTRA_IP_REPOS="$(strip $(design.$(1).ip_repos))" \
		TPL_IP_CACHE="$$(IP_CACHE)" \
		TPL_JOBS="$$(JOBS)" \
		vivado -mode batch -nojournal -nolog -notrace \
		-source "$(TCL_DIR)/build_design.tcl")

.PHONY: bit-$(1) program-$(1) flash-$(1) gui-$(1) clean-design-$(1)
bit-$(1): $(call _design_xsa,$(1))

program-$(1): | vivado-check
	@$$(call _design_require,$(DESIGN_BUILD_DIR)/$(1)/$(1).bit,$(1))
	$(call _design_program,$(1),jtag,$(DESIGN_BUILD_DIR)/$(1)/$(1).bit,Programming $(1) over JTAG)

flash-$(1): | vivado-check
ifeq ($$(strip $$(design.$(1).flash)),)
	@echo "Error: design.$(1).flash is not set in project.mk (the board's flash part, e.g. s25fl128sxxxxxx0-spi-x1_x2_x4)."
	@exit 1
else
	@$$(call _design_require,$(DESIGN_BUILD_DIR)/$(1)/$(1).mcs,$(1))
	$(call _design_program,$(1),flash,$(DESIGN_BUILD_DIR)/$(1)/$(1).mcs,Writing $(1) to flash)
endif

gui-$(1): | vivado-check
	@if [ ! -f "$(DESIGN_WORK_DIR)/$(1)/$(1).xpr" ]; then \
		echo "No project at $(DESIGN_WORK_DIR)/$(1). Run: make bit-$(1)"; exit 1; \
	fi
	@cd "$(DESIGN_WORK_DIR)/$(1)" && $(VIVADO_SHELL) vivado -nojournal -nolog "$(1).xpr"

clean-design-$(1):
	@rm -rf "$(DESIGN_BUILD_DIR)/$(1)" "$(DESIGN_WORK_DIR)/$(1)"
endef

$(foreach d,$(DESIGNS),$(eval $(call design_rule,$(d))))

.PHONY: clean-designs
CLEAN_ALL += clean-designs

clean-designs:
	@rm -rf "$(DESIGN_BUILD_DIR)" "$(DESIGN_WORK_DIR)"