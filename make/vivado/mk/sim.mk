# ===================================================================
# sim.mk: run each IP's testbench in the Vivado simulator (xsim)
# Nand Compute Templates — make/vivado/mk/
#
# A testbench lives in <ip>/tb/ and its top is <ip>_tb (or
# ip.<name>.tb_top). It passes if xsim reports no Error, Failure or
# Fatal message. It must end the simulation itself, e.g. with
# std.env.finish (VHDL-2008) or $finish (Verilog), or by stopping
# every clock.
# ===================================================================

##
## Simulation (xsim; SIM_GUI=1 opens the waveform viewer):
##   sim-<ip>            Run an IP's testbench from <ip>/tb/
##   sim-all             Run every testbench
##   clean-sims          Remove simulation output

SIM_DIR  = $(BUILD_DIR)/sim
SIM_LIBS ?= unisim unimacro
SIM_GUI  ?= 0

SIM_IPS := $(foreach ip,$(IPS),$(if $(wildcard $(addprefix $(IP_DIR)/$(ip)/tb/*.,vhd vhdl v sv)),$(ip)))

# Testbench files: ip.<name>.tb_sources (testbench-only HDL outside
# tb/, e.g. a vendor simulation model, relative to the IP folder, in
# compile order), then everything in tb/.
_sim_tb      = $(addprefix $(IP_DIR)/$(1)/,$(ip.$(1).tb_sources)) \
               $(sort $(wildcard $(addprefix $(IP_DIR)/$(1)/tb/*.,vhd vhdl v sv)))
_sim_files   = $(call ip_sources,$(1)) $(call _sim_tb,$(1))
_sim_vhdl    = $(filter %.vhd %.vhdl,$(call _sim_files,$(1)))
_sim_verilog = $(filter %.v %.sv,$(call _sim_files,$(1)))
_sim_top     = $(or $(ip.$(1).tb_top),$(1)_tb)
# Include folders for Verilog `include, relative to the IP folder.
_sim_incdirs = $(addprefix -i $(IP_DIR)/$(1)/,$(ip.$(1).tb_incdirs))

# -------------------------------------------------------------------
# $(call sim_rule,<name>)
# Verilog compiles first, then VHDL in order: dependencies, the IP's
# own sources, then the testbench. glbl (the global set/reset model
# that XPM and Verilog UNISIM cells need) is compiled and elaborated
# with every testbench; it does nothing for testbenches that don't
# use it.
# -------------------------------------------------------------------
define sim_rule
.PHONY: sim-$(1)
sim-$(1): | vivado-check
	@rm -rf "$(SIM_DIR)/$(1)"
	$$(call run_logged,Simulating $(1),$(SIM_DIR)/$(1)/sim.log,\
		cd "$(SIM_DIR)/$(1)" && $(VIVADO_SHELL) true \
		&& xvlog "$$$$XILINX_VIVADO/data/verilog/src/glbl.v" \
		$(if $(call _sim_verilog,$(1)),&& xvlog -sv $(call _sim_incdirs,$(1)) $(call _sim_verilog,$(1))) \
		$(if $(call _sim_vhdl,$(1)),&& xvhdl $(if $(filter 1,$(VHDL_2008)),-2008) $(call _sim_vhdl,$(1))) \
		&& xelab -debug typical $(addprefix -L ,$(SIM_LIBS)) work.$(call _sim_top,$(1)) work.glbl -snapshot $(call _sim_top,$(1)) \
		&& xsim $(call _sim_top,$(1)) $$(if $$(filter 1,$$(SIM_GUI)),-gui,-R) \
		&& ! grep -qE '^(Error|Failure|FATAL_ERROR):' xsim.log)
endef

$(foreach ip,$(SIM_IPS),$(eval $(call sim_rule,$(ip))))

.PHONY: sim-all clean-sims
CLEAN_ALL += clean-sims

sim-all: $(addprefix sim-,$(SIM_IPS))

clean-sims:
	@rm -rf "$(SIM_DIR)"