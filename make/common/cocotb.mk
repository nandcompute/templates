# SPDX-FileCopyrightText: 2026 Nand Compute LLC
# SPDX-License-Identifier: MIT-0

# ===================================================================
# cocotb.mk: cocotb tests in an open-source simulator
# Nand Compute Templates — make/common/
#
# Shared by every HDL build template. A unit is a folder in
# COCOTB_ROOT with tests in <unit>/tb/test_*.py; each test file runs
# under pytest, and calls cocotb_runner.run() (next to this file) to
# build and simulate the unit with the sources and settings below.
#
# Needs Python 3 with cocotb 2.x and pytest (pip install cocotb
# pytest), and the simulator (GHDL by default) on PATH.
#
# Uses from the including Makefile: PROJ_DIR, CLEAN_ALL, and, when
# present, BUILD_DIR, IP_DIR, VERBOSE and ip_sources (each unit's HDL
# in compile order, dependencies first).
# ===================================================================

##
## cocotb tests (COCOTB_SIM=ghdl|nvc, COCOTB_WAVES=1 for waveforms):
##   test-<unit>         Run a unit's cocotb tests from <unit>/tb/test_*.py
##   test-all            Run every cocotb test
##   clean-tests         Remove cocotb build output

# -------------------------------------------------------------------
# Settings. Override in project.mk or on the command line, e.g.
#   make test-all COCOTB_SIM=nvc
# -------------------------------------------------------------------
COCOTB_SIM         ?= ghdl
COCOTB_STD         ?= 2008
COCOTB_WAVES       ?= 0
COCOTB_PYTHON      ?= python3
COCOTB_PYTEST_ARGS ?=
COCOTB_ROOT        ?= $(or $(IP_DIR),$(PROJ_DIR)/library)
COCOTB_BUILD       ?= $(or $(BUILD_DIR),$(PROJ_DIR)/build)/cocotb

# This file's folder, which also holds cocotb_runner.py.
_COCOTB_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Units: folders in COCOTB_ROOT with a tb/test_*.py.
COCOTB_UNITS := $(sort $(patsubst $(COCOTB_ROOT)/%/tb/,%,$(dir $(wildcard $(COCOTB_ROOT)/*/tb/test_*.py))))

# -------------------------------------------------------------------
# Sources of a unit: ip_sources from the including template when it
# has one (dependencies first), else every HDL file in the unit's
# folder, *_pkg files first. A project can define cocotb_sources
# itself instead.
# -------------------------------------------------------------------
_cocotb_hdl = $(sort $(wildcard $(addprefix $(COCOTB_ROOT)/$(1)/*.,vhd vhdl v sv)))
_cocotb_pkg = $(filter %_pkg.vhd %_pkg.vhdl,$(call _cocotb_hdl,$(1)))
cocotb_sources ?= $(if $(filter undefined,$(origin ip_sources)),$(call _cocotb_pkg,$(1)) $(filter-out $(call _cocotb_pkg,$(1)),$(call _cocotb_hdl,$(1))),$(call ip_sources,$(1)))

# Top-level entity: the unit's name, or cocotb.<unit>.top.
_cocotb_top = $(or $(cocotb.$(1).top),$(1))

# -------------------------------------------------------------------
# Tool check: runs once before any test.
# -------------------------------------------------------------------
.PHONY: cocotb-check
cocotb-check:
	@if ! command -v "$(COCOTB_SIM)" >/dev/null 2>&1; then \
		echo "Error: $(COCOTB_SIM) is not on PATH. Install it, or choose another simulator with COCOTB_SIM=."; \
		exit 1; \
	fi
	@if ! "$(COCOTB_PYTHON)" -c "import cocotb_tools.runner, pytest" >/dev/null 2>&1; then \
		echo "Error: $(COCOTB_PYTHON) can't import cocotb 2.x and pytest. Install them with: pip install cocotb pytest"; \
		exit 1; \
	fi

# -------------------------------------------------------------------
# $(call cocotb_rule,<unit>)
# The full pytest and simulator output goes to test.log; the console
# shows one line per unit, plus pytest's failure summary on failure.
# VERBOSE=1 shows the full output instead.
# -------------------------------------------------------------------
define cocotb_rule
.PHONY: test-$(1)
test-$(1): | cocotb-check
	@rm -rf "$(COCOTB_BUILD)/$(1)"
	@mkdir -p "$(COCOTB_BUILD)/$(1)"
	@echo "==> Testing $(1) ($(COCOTB_SIM))"
	@cd "$(COCOTB_BUILD)/$(1)" && \
	export PYTHONPATH="$(COCOTB_ROOT)/$(1)/tb:$(_COCOTB_DIR)$$$${PYTHONPATH:+:$$$$PYTHONPATH}" \
		PYTHONDONTWRITEBYTECODE=1 \
		TPL_COCOTB_SIM="$(COCOTB_SIM)" \
		TPL_COCOTB_STD="$(COCOTB_STD)" \
		TPL_COCOTB_WAVES="$(COCOTB_WAVES)" \
		TPL_COCOTB_TOPLEVEL="$(call _cocotb_top,$(1))" \
		TPL_COCOTB_SOURCES="$(strip $(call cocotb_sources,$(1)))" \
		TPL_COCOTB_BUILD="$(COCOTB_BUILD)/$(1)"; \
	cmd='"$(COCOTB_PYTHON)" -m pytest -p no:cacheprovider -q -rf --rootdir="$(COCOTB_BUILD)/$(1)" $(COCOTB_PYTEST_ARGS) $(wildcard $(COCOTB_ROOT)/$(1)/tb/test_*.py)'; \
	if [ "$(VERBOSE)" = 1 ]; then \
		eval "$$$$cmd" 2>&1 | tee test.log; status=$$$${PIPESTATUS[0]}; \
	else \
		eval "$$$$cmd" > test.log 2>&1; status=$$$$?; \
	fi; \
	if [ $$$$status -eq 0 ]; then \
		echo "    OK      $$$$(tail -n 1 test.log | tr -d '=' | sed 's/^ *//')"; \
	else \
		echo "    FAILED  Testing $(1)"; \
		grep -E '^(FAILED|ERROR)|AssertionError|Error:' test.log | head -n 8 | sed 's/^ */            /'; \
		echo "            Full log: $(COCOTB_BUILD)/$(1)/test.log"; \
		exit 1; \
	fi
endef

$(foreach u,$(COCOTB_UNITS),$(eval $(call cocotb_rule,$(u))))

.PHONY: test-all clean-tests
CLEAN_ALL += clean-tests

test-all: $(addprefix test-,$(COCOTB_UNITS))

clean-tests:
	@rm -rf "$(COCOTB_BUILD)"