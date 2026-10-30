# ===================================================================
# AMD Vivado project Makefile
# Nand Compute Templates — make/vivado/Makefile
#
# Generic entry point: do not edit per project. Project settings live
# in project.mk. The targets live in the mk/*.mk fragments, and the
# Vivado scripts they run live in tcl/.
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
TCL_DIR  := $(MK_DIR)/tcl

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------
empty :=
space := $(empty) $(empty)
comma := ,

# $(call uniq,<list>) -> list without repeats, first occurrence kept
uniq = $(if $(1),$(firstword $(1)) $(call uniq,$(filter-out $(firstword $(1)),$(1))))

# Fragments append their clean-* targets here for clean-all.
CLEAN_ALL :=

# -------------------------------------------------------------------
# Layout defaults. Set before project.mk is read, so project.mk can
# both use them and override them.
# -------------------------------------------------------------------
IP_DIR     ?= $(PROJ_DIR)/library
DESIGN_DIR ?= $(PROJ_DIR)/designs
BUILD_DIR  ?= $(PROJ_DIR)/build

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

ifeq ($(strip $(VIVADO_VERSION)),)
$(error VIVADO_VERSION is not set in project.mk)
endif

MK_FRAGMENTS ?=

# -------------------------------------------------------------------
# Vivado
# If vivado is already on PATH it is used as is. Otherwise each recipe
# sources VIVADO_SETTINGS first. Set XILINX_ROOT (the folder holding
# one subfolder per Vivado version) in local.mk, so a version change
# in project.mk needs no change on any machine. Installations laid out
# differently (2024.2 and older: <root>/Vivado/<version>/) set
# VIVADO_SETTINGS directly instead.
#
# VERSION_CHECK=warn turns a Vivado version mismatch into a warning.
# -------------------------------------------------------------------
XILINX_ROOT     ?= /tools/Xilinx
VIVADO_SETTINGS ?= $(XILINX_ROOT)/$(VIVADO_VERSION)/Vivado/settings64.sh
VERSION_CHECK   ?= error
VHDL_2008       ?= 1
JOBS            ?= $(shell nproc 2>/dev/null || echo 4)
VERBOSE         ?= 0

_VIVADO_ON_PATH := $(shell command -v vivado 2>/dev/null)

# Recipe prefix for anything that needs the Vivado tools:
#   @$(VIVADO_SHELL) xvhdl ...
VIVADO_SHELL = $(if $(_VIVADO_ON_PATH),,source "$(VIVADO_SETTINGS)" >/dev/null &&)

# Settings every Vivado script receives (read in tcl/common.tcl).
VIVADO_ENV = \
	TPL_VIVADO_VERSION="$(VIVADO_VERSION)" \
	TPL_VERSION_CHECK="$(VERSION_CHECK)" \
	TPL_VHDL_2008="$(VHDL_2008)"

# -------------------------------------------------------------------
# $(call run_logged,<description>,<log file>,<command>)
# Runs a long tool command with its output in a log file, and prints
# one line when it starts and one with the result. VERBOSE=1 shows
# the full output instead.
# -------------------------------------------------------------------
define run_logged
@mkdir -p "$(dir $(2))"
@echo "==> $(1)"
@if [ "$(VERBOSE)" = 1 ]; then \
	( $(3) ) 2>&1 | tee "$(2)"; status=$${PIPESTATUS[0]}; \
else \
	( $(3) ) > "$(2)" 2>&1; status=$$?; \
fi; \
if [ $$status -eq 0 ]; then \
	echo "    OK      $(1)"; \
else \
	echo "    FAILED  $(1)"; \
	grep -m 5 -E '^(ERROR|CRITICAL WARNING|Error|Failure|FATAL)' "$(2)" | sed 's/^/            /'; \
	echo "            Full log: $(2)"; \
	exit 1; \
fi
endef

# -------------------------------------------------------------------
# Vivado check: runs once before any target that needs Vivado.
# -------------------------------------------------------------------
.PHONY: vivado-check
vivado-check:
	@if [ -z "$(_VIVADO_ON_PATH)" ] && [ ! -f "$(VIVADO_SETTINGS)" ]; then \
		echo "Error: vivado is not on PATH and $(VIVADO_SETTINGS) does not exist."; \
		echo "Set XILINX_ROOT (or VIVADO_SETTINGS) in $(MK_DIR)/local.mk; see local.mk.example."; \
		exit 1; \
	fi

# -------------------------------------------------------------------
# Fragments. ip, sim and design are always included; others (e.g.
# doxygen, copied from make/common/ in nandcompute/templates) are
# chosen in project.mk with MK_FRAGMENTS.
# -------------------------------------------------------------------
MK_FRAGMENT_FILES   := $(foreach f,ip sim design $(MK_FRAGMENTS),$(MK_DIR)/mk/$(f).mk)
MK_FRAGMENT_MISSING := $(filter-out $(wildcard $(MK_FRAGMENT_FILES)),$(MK_FRAGMENT_FILES))
ifneq ($(MK_FRAGMENT_MISSING),)
$(error Fragment(s) not found: $(notdir $(MK_FRAGMENT_MISSING)). Copy them into $(MK_DIR)/mk/, or remove them from MK_FRAGMENTS)
endif

include $(MK_FRAGMENT_FILES)

# -------------------------------------------------------------------
# Clean everything
# -------------------------------------------------------------------
.PHONY: clean-all
clean-all: $(CLEAN_ALL)
	@rm -rf "$(BUILD_DIR)"

# -------------------------------------------------------------------
# Help: IPs and designs found, then the "##" lines from each fragment.
# -------------------------------------------------------------------
.PHONY: help
help:
	@echo "Usage: make <target> [VERBOSE=1] [JOBS=<n>]"
	@echo ""
	@echo "Vivado $(VIVADO_VERSION)$(if $(_VIVADO_ON_PATH), (on PATH), (from $(VIVADO_SETTINGS)))"
	@echo "IPs:     $(if $(IPS),$(IPS),(none found in $(IP_DIR)))"
	@echo "Designs: $(if $(DESIGNS),$(DESIGNS),(none listed in project.mk))"
	@sed -n 's/^## \{0,1\}//p' $(filter $(MK_DIR)/mk/%.mk,$(abspath $(MAKEFILE_LIST)))
	@echo ""
	@echo "Housekeeping:"
	@echo "  clean-all           Remove everything under $(notdir $(BUILD_DIR))/"
	@echo "  help                Show this help"