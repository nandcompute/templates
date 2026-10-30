# ===================================================================
# pem.mk: MCUboot image signing key
# Nand Compute Templates — make/zephyr-ncs/mk/
#
# Point the application at the key in its sysbuild.conf:
#   SB_CONFIG_BOOT_SIGNATURE_KEY_FILE="${APP_DIR}/../../keys/signing-key.pem"
# and make SIGNING_KEY_TYPE match SB_CONFIG_BOOT_SIGNATURE_TYPE_*
# (NCS defaults to ED25519 on nRF54L and ECDSA P-256 elsewhere).
#
# @note Never commit the key (*.pem is in gitignore/c.gitignore).
# Back it up somewhere safe: devices in the field only accept updates
# signed with it.
# ===================================================================

##
## Signing:
##   pem                 Generate an MCUboot signing key (never overwrites)

SIGNING_KEY      ?= $(PROJ_DIR)/keys/signing-key.pem
SIGNING_KEY_TYPE ?= ecdsa-p256
IMGTOOL          ?= $(NCS_ROOT)/bootloader/mcuboot/scripts/imgtool.py

.PHONY: pem
pem: ncs-check
	@if [ -e "$(SIGNING_KEY)" ]; then \
		echo "Error: $(SIGNING_KEY) already exists; refusing to overwrite it."; \
		exit 1; \
	fi
	@mkdir -p "$(dir $(SIGNING_KEY))"
	@$(NCS_SHELL) python3 "$(IMGTOOL)" keygen -k "$(SIGNING_KEY)" -t $(SIGNING_KEY_TYPE)
	@chmod 600 "$(SIGNING_KEY)"
	@echo "Created $(SIGNING_KEY) ($(SIGNING_KEY_TYPE)). Back it up; do not commit it."