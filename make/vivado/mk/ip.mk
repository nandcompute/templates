# ===================================================================
# ip.mk: package each IP in IP_DIR for the Vivado IP catalog
# Nand Compute Templates — make/vivado/mk/
#
# Packaged IPs go to $(BUILD_DIR)/ip/<name>/, which designs use as
# their IP repository. Packaging copies the sources in, so each
# packaged IP is self-contained.
# ===================================================================

##
## IP (replace <ip> with one of the IPs above):
##   ip-<ip>             Package an IP (and the IPs it depends on)
##   ip-all              Package every IP
##   clean-ip-<ip>       Remove a packaged IP
##   clean-ips           Remove every packaged IP

IPS := $(sort $(notdir $(patsubst %/ip.tcl,%,$(wildcard $(IP_DIR)/*/ip.tcl))))

IP_BUILD_DIR = $(BUILD_DIR)/ip
IP_WORK_DIR  = $(BUILD_DIR)/work/ip

# -------------------------------------------------------------------
# Sources of an IP
# ip_own_sources: ip.<name>.sources, else every HDL file in the IP
# folder with *_pkg files first, so VHDL packages compile before use.
# ip_sources: the sources of its dependencies first, then its own.
# -------------------------------------------------------------------
_ip_hdl = $(sort $(wildcard $(addprefix $(IP_DIR)/$(1)/*.,vhd vhdl v sv)))
_ip_pkg = $(filter %_pkg.vhd %_pkg.vhdl,$(call _ip_hdl,$(1)))

ip_own_sources = $(if $(ip.$(1).sources),$(addprefix $(IP_DIR)/$(1)/,$(ip.$(1).sources)),$(call _ip_pkg,$(1)) $(filter-out $(call _ip_pkg,$(1)),$(call _ip_hdl,$(1))))
ip_sources     = $(call uniq,$(foreach d,$(ip.$(1).deps),$(call ip_sources,$(d))) $(call ip_own_sources,$(1)))
ip_xdc         = $(wildcard $(IP_DIR)/$(1)/*.xdc)
ip_component   = $(IP_BUILD_DIR)/$(1)/component.xml

# -------------------------------------------------------------------
# $(call ip_rule,<name>)
# -------------------------------------------------------------------
define ip_rule
$(call ip_component,$(1)): $(call ip_sources,$(1)) $(call ip_xdc,$(1)) $(IP_DIR)/$(1)/ip.tcl \
		$(foreach d,$(ip.$(1).deps),$(call ip_component,$(d))) \
		$(TCL_DIR)/common.tcl $(TCL_DIR)/ip_helpers.tcl $(TCL_DIR)/package_ip.tcl $(MK_DIR)/project.mk | vivado-check
	$$(call run_logged,Packaging IP $(1),$(IP_WORK_DIR)/$(1)/package.log,\
		cd "$(IP_WORK_DIR)/$(1)" && $(VIVADO_SHELL) $(VIVADO_ENV) \
		TPL_IP_NAME="$(1)" \
		TPL_IP_DIR="$(IP_DIR)/$(1)" \
		TPL_IP_OUT="$(IP_BUILD_DIR)/$(1)" \
		TPL_IP_WORK="$(IP_WORK_DIR)/$(1)" \
		TPL_IP_SOURCES="$(strip $(call ip_sources,$(1)))" \
		TPL_IP_XDC="$(strip $(call ip_xdc,$(1)))" \
		TPL_IP_VENDOR="$(IP_VENDOR)" \
		TPL_IP_VENDOR_NAME="$(IP_VENDOR_NAME)" \
		TPL_IP_LIBRARY="$(IP_LIBRARY)" \
		TPL_IP_TAXONOMY="$(IP_TAXONOMY)" \
		TPL_IP_VERSION="$(or $(ip.$(1).version),$(IP_VERSION))" \
		TPL_IP_URL="$(IP_URL)" \
		TPL_IP_PART="$(IP_PART)" \
		TPL_VHDL_2008="$(or $(ip.$(1).vhdl_2008),$(IP_VHDL_2008))" \
		vivado -mode batch -nojournal -nolog -notrace \
		-source "$(TCL_DIR)/package_ip.tcl")

.PHONY: ip-$(1) clean-ip-$(1)
ip-$(1): $(call ip_component,$(1))

clean-ip-$(1):
	@rm -rf "$(IP_BUILD_DIR)/$(1)" "$(IP_WORK_DIR)/$(1)"
endef

$(foreach ip,$(IPS),$(eval $(call ip_rule,$(ip))))

.PHONY: ip-all clean-ips
CLEAN_ALL += clean-ips

ip-all: $(addprefix ip-,$(IPS))

clean-ips:
	@rm -rf "$(IP_BUILD_DIR)" "$(IP_WORK_DIR)"