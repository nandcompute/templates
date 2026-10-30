# ===================================================================
# ninja.mk: memory reports from an existing application build
# Nand Compute Templates — make/zephyr-ncs/mk/
#
# Reuses BUILD_PATH from west.mk, so BOARD and DEBUG must match
# the build being reported on.
# ===================================================================

##
## Memory reports (after build-<app> with the same BOARD/DEBUG):
##   ram-report-<app>    RAM usage report
##   rom-report-<app>    ROM usage report
##   rom-plot-<app>      ROM usage plot

# -------------------------------------------------------------------
# Zephyr ninja targets to expose. Each one becomes <name>-<app>, with
# '_' replaced by '-' (ram_report -> ram-report-<app>). A project can
# add others in project.mk, e.g. NINJA_TARGETS += ram_plot puncover
# -------------------------------------------------------------------
NINJA_TARGETS ?= ram_report rom_report rom_plot

# Sysbuild puts the application image in <build-dir>/<app-name>.
NINJA_BUILD_PATH = $(BUILD_PATH)/$(APP)

# -------------------------------------------------------------------
# $(call ninja_rule,<ninja target>)
# A static pattern rule per ninja target, so asking for several apps
# at once (make rom-report-a rom-report-b) runs each of them.
# -------------------------------------------------------------------
define ninja_rule
$(subst _,-,$(1))_TARGETS := $(addprefix $(subst _,-,$(1))-,$(APPS))
$$(call per_app,$(subst _,-,$(1)))
.PHONY: $$($(subst _,-,$(1))_TARGETS)
$$($(subst _,-,$(1))_TARGETS): $(subst _,-,$(1))-%: ncs-check
	@$$(call require_build,$$(NINJA_BUILD_PATH)/build.ninja)
	@$$(NCS_SHELL) ninja -C "$$(NINJA_BUILD_PATH)" $(1)
endef

$(foreach t,$(NINJA_TARGETS),$(eval $(call ninja_rule,$(t))))