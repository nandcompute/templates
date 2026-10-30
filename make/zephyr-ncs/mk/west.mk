# =============================================================
# west.mk: build, flash, menuconfig and clean each application
# Nand Compute Templates — make/zephyr-ncs/mk/
# =============================================================

##
## Applications (replace <app> with one of the applications above):
##   build-<app>         Build (PRISTINE=0 for an incremental build)
##   flash-<app>         Flash (RUNNER=jlink|nrfutil, ERASE=0, SNR=)
##   menuconfig-<app>    Open menuconfig
##   clean-<app>         Remove the application's build directories

# -------------------------------------------------------------------
# Options
#   DEBUG=1     debug build (prj.conf + debug.conf if present)
#   PRISTINE=0  incremental build (default: pristine)
#   ERASE=0     flash without a full chip erase (default: erase)
#   RUNNER      west flash runner (default: jlink)
#   SNR         probe serial number when several are connected
#   EXTRA_CONF  extra Kconfig fragments, space separated
#   EXTRA_DTC   extra devicetree overlays, space separated
#
# @note A full erase also wipes the settings partition, including any
# keys written during provisioning. Use ERASE=0 when flashing a unit
# that has already been provisioned.
# -------------------------------------------------------------------
DEBUG    ?= 0
PRISTINE ?= 1
ERASE    ?= 1
RUNNER   ?= jlink
SNR      ?=

# -------------------------------------------------------------------
# Paths (APP is set per target; see per_app in Makefile)
# -------------------------------------------------------------------
BUILD_VARIANT = $(if $(filter 1,$(DEBUG)),debug,release)
APP_PATH      = $(APPS_DIR)/$(APP)
BUILD_PATH    = $(APP_PATH)/build-$(BUILD_VARIANT)-$(BOARD)

# -------------------------------------------------------------------
# Kconfig and devicetree inputs
#
# CONF_FILE is prj.conf plus <variant>.conf when present. Because
# CONF_FILE lists more than one file, Zephyr no longer picks up
# boards/<board>.conf by itself, so it is passed as an extra fragment.
# Board file names are the full target with '/' replaced by '_', e.g.
#   nrf52dk/nrf52832 -> boards/nrf52dk_nrf52832.conf
#
# Devicetree overlays are left to Zephyr's own lookup
# (boards/<board>.overlay, else app.overlay). Setting DTC_OVERLAY_FILE
# here would turn that lookup off.
#
# @note With sysbuild these options apply to the main application
# image only. MCUboot takes its configuration from the app's
# sysbuild/mcuboot.conf and sysbuild/mcuboot/ overlays.
# -------------------------------------------------------------------
BOARD_FILE_STEM = $(subst /,_,$(BOARD_TARGET))
CONF_FILES      = prj.conf$(if $(wildcard $(APP_PATH)/$(BUILD_VARIANT).conf),;$(BUILD_VARIANT).conf)
EXTRA_CONF_LIST = $(call join_with,;,$(wildcard $(APP_PATH)/boards/$(BOARD_FILE_STEM).conf) $(EXTRA_CONF))
EXTRA_DTC_LIST  = $(call join_with,;,$(EXTRA_DTC))

_PRISTINE = $(if $(filter 1,$(PRISTINE)),--pristine)
_ERASE    = $(if $(filter 1,$(ERASE)),--erase)
_DEV_ID   = $(if $(SNR),--dev-id $(SNR))

# -------------------------------------------------------------------
# Per-app targets
# -------------------------------------------------------------------
BUILD_TARGETS      := $(addprefix build-,$(APPS))
FLASH_TARGETS      := $(addprefix flash-,$(APPS))
MENUCONFIG_TARGETS := $(addprefix menuconfig-,$(APPS))
APP_CLEAN_TARGETS  := $(addprefix clean-,$(APPS))

$(call per_app,build)
$(call per_app,flash)
$(call per_app,menuconfig)
$(call per_app,clean)

.PHONY: $(BUILD_TARGETS) $(FLASH_TARGETS) $(MENUCONFIG_TARGETS) $(APP_CLEAN_TARGETS)

# @note -DCONF_FILE must be quoted, since it contains ';'.
$(BUILD_TARGETS): build-%: ncs-check
	@echo "Building $(APP) ($(BUILD_VARIANT)): CONF_FILE=$(CONF_FILES)$(if $(EXTRA_CONF_LIST), EXTRA_CONF_FILE=$(EXTRA_CONF_LIST))"
	@$(NCS_SHELL) west build \
		--build-dir "$(BUILD_PATH)" "$(APP_PATH)" \
		--board $(BOARD_TARGET) $(_PRISTINE) -- \
		-DCONF_FILE="$(CONF_FILES)" \
		-DBOARD_ROOT="$(BOARD_ROOT)" \
		$(if $(EXTRA_CONF_LIST),-DEXTRA_CONF_FILE="$(EXTRA_CONF_LIST)") \
		$(if $(EXTRA_DTC_LIST),-DEXTRA_DTC_OVERLAY_FILE="$(EXTRA_DTC_LIST)")

$(FLASH_TARGETS): flash-%: ncs-check
	@$(call require_build,$(BUILD_PATH)/build.ninja)
	@$(NCS_SHELL) west flash --build-dir "$(BUILD_PATH)" --runner $(RUNNER) $(_ERASE) $(_DEV_ID)

$(MENUCONFIG_TARGETS): menuconfig-%: ncs-check
	@$(NCS_SHELL) west build --build-dir "$(BUILD_PATH)" "$(APP_PATH)" --board $(BOARD_TARGET) -t menuconfig

$(APP_CLEAN_TARGETS): clean-%:
	@rm -rf "$(APP_PATH)/build" "$(APP_PATH)"/build-debug* "$(APP_PATH)"/build-release*

# -------------------------------------------------------------------
# $(call require_build,<file>): stop with a hint if the app hasn't been
# built for this BOARD/DEBUG combination yet.
# -------------------------------------------------------------------
define require_build
if [ ! -f "$(1)" ]; then \
	echo "No build found at $(BUILD_PATH)"; \
	echo "Run: make build-$(APP) BOARD=$(BOARD)$(if $(filter 1,$(DEBUG)), DEBUG=1)"; \
	exit 1; \
fi
endef