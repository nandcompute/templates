# ===================================================================
# Zephyr / nRF Connect SDK project Makefile
# Nand Compute Templates — make/zephyr-ncs/Makefile
#
# Generic entry point: do not edit per project. Project settings live
# in project.mk. The targets live in the mk/*.mk fragments.
#
# Run "make help" for usage.
# ===================================================================

SHELL := bash
.DEFAULT_GOAL := help

# -------------------------------------------------------------------
# Locations
# MK_DIR is the directory holding this Makefile, so "make -C <dir>" and
# running from any working directory both behave the same.
# PROJ_DIR defaults to its parent (Makefile lives in e.g. <proj>/make/).
# -------------------------------------------------------------------
MK_DIR   := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PROJ_DIR ?= $(abspath $(MK_DIR)/..)

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------
empty :=
space := $(empty) $(empty)
comma := ,

# $(call join_with,<sep>,<list>) -> list items joined by <sep>
join_with = $(subst $(space),$(1),$(strip $(2)))

# $(call per_app,<prefix>) -> sets APP for every <prefix>-<app> target
per_app = $(foreach a,$(APPS),$(eval $(1)-$(a): APP := $(a)))

# Fragments append their clean-* targets here for clean-all.
CLEAN_ALL :=

# -------------------------------------------------------------------
# Layout defaults. Set before project.mk is read, so project.mk can
# both use them (e.g. $(APPS_DIR)/common) and override them.
# -------------------------------------------------------------------
APPS_DIR     ?= $(PROJ_DIR)/apps
TESTS_DIR    ?= $(PROJ_DIR)/tests
BOARD_ROOT   ?= $(PROJ_DIR)

# -------------------------------------------------------------------
# Project settings (the only file edited per project)
# -------------------------------------------------------------------
include $(MK_DIR)/project.mk

# -------------------------------------------------------------------
# Machine settings (optional, never committed): install locations and
# other values that differ between machines. See local.mk.example.
# Values given on the make command line still take precedence.
# -------------------------------------------------------------------
-include $(MK_DIR)/local.mk

ifeq ($(strip $(NCS_VERSION)),)
$(error NCS_VERSION is not set in project.mk)
endif
ifeq ($(strip $(APPS)),)
$(error APPS is not set in project.mk)
endif

# Shared fragments such as doxygen are opt-in, since they're copied
# separately from make/common/ in nandcompute/templates.
MK_FRAGMENTS ?= ninja twister nrfutil pem

# -------------------------------------------------------------------
# nRF Connect SDK
# Override per machine without editing files, e.g.
#   make build-app NCS_ROOT=/opt/ncs/v3.4.1
# or, for every build on this machine, NCS_INSTALL_DIR in local.mk.
# -------------------------------------------------------------------
NCS_INSTALL_DIR   ?= $(HOME)/ncs
NCS_ROOT          ?= $(NCS_INSTALL_DIR)/$(NCS_VERSION)
ZEPHYR_ENV_SCRIPT ?= $(NCS_ROOT)/zephyr/zephyr-env.sh
NCS_ENV_SCRIPT    ?= $(MK_DIR)/ncs_env_$(NCS_VERSION).sh

# Recipe prefix for anything that needs the NCS toolchain:
#   @$(NCS_SHELL) west build ...
NCS_SHELL = source "$(ZEPHYR_ENV_SCRIPT)" && source "$(NCS_ENV_SCRIPT)" &&

# -------------------------------------------------------------------
# Board selection: short name -> full board target + device family,
# from the board.<name>.* table in project.mk.
# -------------------------------------------------------------------
BOARD ?= $(DEFAULT_BOARD)

ifeq ($(filter $(BOARD),$(BOARDS)),)
$(error Unknown BOARD: "$(BOARD)". Allowed values: $(BOARDS))
endif

BOARD_TARGET  := $(board.$(BOARD).target)
DEVICE_FAMILY := $(board.$(BOARD).family)

ifeq ($(BOARD_TARGET),)
$(error board.$(BOARD).target is not set in project.mk)
endif

# -------------------------------------------------------------------
# Fragments. env and west are required; the rest are chosen in
# project.mk with MK_FRAGMENTS. Help is printed in this order.
# -------------------------------------------------------------------
include $(MK_DIR)/mk/west.mk
include $(foreach f,$(MK_FRAGMENTS),$(MK_DIR)/mk/$(f).mk)
include $(MK_DIR)/mk/env.mk

# -------------------------------------------------------------------
# NCS check: runs once before any target that needs the toolchain.
# Generates the environment script on first use.
# -------------------------------------------------------------------
.PHONY: ncs-check
ncs-check: | $(NCS_ENV_SCRIPT)
	@if [ ! -f "$(ZEPHYR_ENV_SCRIPT)" ]; then \
		echo "Error: NCS $(NCS_VERSION) not found at $(NCS_ROOT)"; \
		echo "Install it with nrfutil toolchain-manager, or set NCS_INSTALL_DIR in $(MK_DIR)/local.mk (see local.mk.example)."; \
		exit 1; \
	fi
	@echo "NCS $(NCS_VERSION)$(if $(NCS_TOOLCHAIN_VERSION), (toolchain $(NCS_TOOLCHAIN_VERSION))) at $(NCS_ROOT)"
	@echo "Board: $(BOARD) -> $(BOARD_TARGET)"

# -------------------------------------------------------------------
# Clean everything
# -------------------------------------------------------------------
.PHONY: clean-all
clean-all: $(CLEAN_ALL) $(addprefix clean-,$(APPS))

# -------------------------------------------------------------------
# Help: boards and apps from project.mk, then the "##" lines from
# each fragment.
# -------------------------------------------------------------------
.PHONY: help
help:
	@echo "Usage: make <target> [BOARD=<board>] [DEBUG=1] [SNR=<probe serial>]"
	@echo ""
	@echo "Boards:"
	@$(foreach b,$(BOARDS),printf '  BOARD=%-20s %s%s\n' '$(b)' '$(board.$(b).target)' '$(if $(filter $(b),$(DEFAULT_BOARD)), (default))';)
	@echo ""
	@echo "Applications: $(APPS)"
	@sed -n 's/^## \{0,1\}//p' $(filter $(MK_DIR)/mk/%.mk,$(abspath $(MAKEFILE_LIST)))
	@echo ""
	@echo "Housekeeping:"
	@echo "  clean-all           Run every clean target"
	@echo "  help                Show this help"