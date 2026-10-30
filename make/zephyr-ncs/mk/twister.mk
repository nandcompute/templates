# ===================================================================
# twister.mk: tests with Twister
# Nand Compute Templates — make/zephyr-ncs/mk/
# ===================================================================

##
## Testing (TWISTER_ARGS="..." passes extra Twister options):
##   test-compile        Build the tests for BOARD, without running them
##   test-hw             Run the tests on hardware over a serial port
##   test-hw-rtt         Run the tests on hardware over RTT (no UART)
##   test-sim            Run the tests on native_sim
##   clean-tests         Remove Twister output

TWISTER            ?= $(NCS_ROOT)/zephyr/scripts/twister
TWISTER_BOARD_ROOT ?= $(BOARD_ROOT)/boards
TWISTER_OUT        ?= $(MK_DIR)/twister-out
TWISTER_RUNNER     ?= nrfutil
TWISTER_ARGS       ?=
SERIAL_PORT        ?= /dev/ttyACM0
SERIAL_BAUD        ?= 115200
ERASE              ?= 1

# -------------------------------------------------------------------
# Common options
# @note -W stops warnings from being treated as errors.
# -------------------------------------------------------------------
TWISTER_COMMON = \
	-W \
	-T "$(TESTS_DIR)" \
	-O "$(TWISTER_OUT)" \
	$(TWISTER_ARGS)

TWISTER_BOARD = \
	--board-root "$(TWISTER_BOARD_ROOT)" \
	-p $(BOARD_TARGET) \
	--extra-args="BOARD_ROOT=$(BOARD_ROOT)"

# -------------------------------------------------------------------
# Flashing during device tests.
# --west-flash is always given: without it Twister flashes through the
# build system and silently ignores --west-runner.
# -------------------------------------------------------------------
_TWISTER_FLASH_ARGS = $(call join_with,$(comma),$(if $(filter 1,$(ERASE)),--erase) $(if $(SNR),--dev-id=$(SNR)))
TWISTER_FLASH = \
	--west-runner=$(TWISTER_RUNNER) \
	$(if $(_TWISTER_FLASH_ARGS),--west-flash="$(_TWISTER_FLASH_ARGS)",--west-flash)

.PHONY: test-compile test-hw test-hw-rtt test-sim clean-tests
CLEAN_ALL += clean-tests

test-compile: ncs-check
	@$(NCS_SHELL) "$(TWISTER)" $(TWISTER_COMMON) $(TWISTER_BOARD) --build-only

test-hw: ncs-check
	@$(NCS_SHELL) "$(TWISTER)" $(TWISTER_COMMON) $(TWISTER_BOARD) \
		--device-testing \
		--device-serial "$(SERIAL_PORT)" \
		--device-serial-baud $(SERIAL_BAUD) \
		$(TWISTER_FLASH)

# -------------------------------------------------------------------
# Hardware tests with the console over RTT, for boards without a UART.
# RTT_PTY is a project script that bridges J-Link RTT to a pty; it
# reads JLINK_SNR and RTT_ATTACH_DELAY from the environment.
# @note The script needs pylink-square in the NCS toolchain Python;
#       reinstall after toolchain updates (python3 -m pip install pylink-square).
# -------------------------------------------------------------------
RTT_PTY          ?= $(MK_DIR)/rtt_pty.py
RTT_CONF         ?= $(TESTS_DIR)/common/rtt.conf
RTT_ATTACH_DELAY ?= 8

test-hw-rtt: ncs-check
	@for f in "$(RTT_PTY)" "$(RTT_CONF)"; do \
		[ -f "$$f" ] || { echo "Error: $$f not found (see RTT_PTY / RTT_CONF)"; exit 1; }; \
	done
	@$(NCS_SHELL) JLINK_SNR=$(SNR) RTT_ATTACH_DELAY=$(RTT_ATTACH_DELAY) \
		"$(TWISTER)" $(TWISTER_COMMON) $(TWISTER_BOARD) \
		--device-testing \
		--device-serial-pty "$(RTT_PTY)" \
		$(TWISTER_FLASH) \
		--extra-args="EXTRA_CONF_FILE=$(RTT_CONF)"

test-sim: ncs-check
	@$(NCS_SHELL) "$(TWISTER)" $(TWISTER_COMMON) -p native_sim

# Twister renames earlier runs to twister-out.1, .2, ...
clean-tests:
	@rm -rf "$(TWISTER_OUT)" "$(TWISTER_OUT)".*