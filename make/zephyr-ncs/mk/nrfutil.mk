# ===================================================================
# nrfutil.mk: device utilities
# Nand Compute Templates — make/zephyr-ncs/mk/
#
# The device family comes from board.<name>.family in project.mk.
# ===================================================================

##
## Device:
##   recover             Recover (unlock and erase) the device for BOARD
##   reset               Reset the device for BOARD

_NRFUTIL_SNR = $(if $(SNR),--serial-number $(SNR))

define require_family
if [ -z "$(DEVICE_FAMILY)" ]; then \
	echo "Error: board.$(BOARD).family is not set in project.mk"; \
	exit 1; \
fi
endef

.PHONY: recover reset
recover:
	@$(require_family)
	@echo "Recovering $(BOARD) ($(DEVICE_FAMILY))"
	@nrfutil device recover --x-family $(DEVICE_FAMILY) $(_NRFUTIL_SNR)

reset:
	@$(require_family)
	@nrfutil device reset --x-family $(DEVICE_FAMILY) $(_NRFUTIL_SNR)