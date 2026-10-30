# ===================================================================
# project.mk: per-project settings for the Zephyr / NCS Makefile
# Nand Compute Templates — make/zephyr-ncs/
#
# This is the only build file you edit in a project. Everything else
# (Makefile, mk/*.mk) is copied unchanged, so it can be upgraded by
# copying a newer version of the template over it.
# ===================================================================

# -------------------------------------------------------------------
# nRF Connect SDK version
# NCS_TOOLCHAIN_VERSION is informational (printed before builds);
# nrfutil picks the toolchain that matches NCS_VERSION.
# -------------------------------------------------------------------
NCS_VERSION           := v3.4.1
NCS_TOOLCHAIN_VERSION := 8285d8ad56

# -------------------------------------------------------------------
# Applications: directory names under APPS_DIR.
# Each gets build-<app>, flash-<app>, menuconfig-<app>, clean-<app>, ...
# -------------------------------------------------------------------
APPS := app

# -------------------------------------------------------------------
# Boards
# Short name used on the command line (BOARD=<name>), mapped to the
# full Zephyr board target and the nrfutil device family.
#   family: nrf52, nrf53, nrf54l, nrf91, ...
# -------------------------------------------------------------------
BOARDS        := nrf52840dk nrf54l15dk
DEFAULT_BOARD := nrf52840dk

board.nrf52840dk.target := nrf52840dk/nrf52840
board.nrf52840dk.family := nrf52

board.nrf54l15dk.target := nrf54l15dk/nrf54l15/cpuapp
board.nrf54l15dk.family := nrf54l

# Custom boards live under $(BOARD_ROOT)/boards/<vendor>/<board>/, e.g.
#   board.acme_node.target := acme_node/nrf54l15/cpuapp
#   board.acme_node.family := nrf54l

# -------------------------------------------------------------------
# Optional fragments (mk/<name>.mk). Remove what the project doesn't
# use; add cbor if it generates zcbor code from CDDL, and doxygen
# (copied from make/common/ in nandcompute/templates) for documentation.
# -------------------------------------------------------------------
MK_FRAGMENTS := ninja twister nrfutil pem

# -------------------------------------------------------------------
# Layout (defaults shown; uncomment to change)
# -------------------------------------------------------------------
# APPS_DIR   := $(PROJ_DIR)/apps
# TESTS_DIR  := $(PROJ_DIR)/tests
# BOARD_ROOT := $(PROJ_DIR)

# -------------------------------------------------------------------
# CBOR code generation (only with "cbor" in MK_FRAGMENTS)
# Add an entry type whenever a new top-level message is introduced,
# whichever .cddl file it lives in.
# -------------------------------------------------------------------
# CBOR_CDDL_DIR    := $(PROJ_DIR)/cbor
# CBOR_INC_DIR     := $(APPS_DIR)/common/include/cbor
# CBOR_SRC_DIR     := $(APPS_DIR)/common/src/cbor
# CBOR_ENTRY_TYPES := app-msg app-ack
# CBOR_OUT_BASE    := app_msgs

# -------------------------------------------------------------------
# Documentation (only with "doxygen" in MK_FRAGMENTS)
# -------------------------------------------------------------------
# DOC_PROJECT_NAME  := Acme Firmware
# DOC_PROJECT_BRIEF := Firmware for the Acme sensor node
# DOC_INPUT         := $(APPS_DIR) $(PROJ_DIR)/docs

# -------------------------------------------------------------------
# Machine-specific settings (NCS_INSTALL_DIR, probe serials, serial
# ports) go in local.mk, not here: this file is shared by everyone
# working on the project.
# -------------------------------------------------------------------