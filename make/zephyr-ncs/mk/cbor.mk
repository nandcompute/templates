# ===================================================================
# cbor.mk: generate CBOR encoders/decoders from CDDL with zcbor
# Nand Compute Templates — make/zephyr-ncs/mk/
#
# Enable with "cbor" in MK_FRAGMENTS and set CBOR_ENTRY_TYPES and
# CBOR_OUT_BASE in project.mk.
# ===================================================================

##
## Code generation:
##   cbor                Generate CBOR encode/decode code from CDDL
##   clean-cbor          Remove the generated CBOR code

CBOR_CDDL_DIR    ?= $(PROJ_DIR)/cbor
CBOR_INC_DIR     ?= $(APPS_DIR)/common/include/cbor
CBOR_SRC_DIR     ?= $(APPS_DIR)/common/src/cbor
CBOR_ENTRY_TYPES ?=
CBOR_OUT_BASE    ?=

# All .cddl files are passed to zcbor as context.
CDDL_FILES = $(wildcard $(CBOR_CDDL_DIR)/*.cddl)

define require_cbor_settings
if [ -z "$(strip $(CBOR_ENTRY_TYPES))" ] || [ -z "$(strip $(CBOR_OUT_BASE))" ]; then \
	echo "Error: set CBOR_ENTRY_TYPES and CBOR_OUT_BASE in project.mk"; \
	exit 1; \
fi
endef

.PHONY: cbor clean-cbor
CLEAN_ALL += clean-cbor

# zcbor is run from PROJ_DIR with relative output paths: given absolute
# ones, it creates a stray copy of the output folder under the working
# directory.
_CBOR_REL = $(patsubst $(PROJ_DIR)/%,%,$(1))

cbor: ncs-check
	@$(require_cbor_settings)
	@if [ -z "$(CDDL_FILES)" ]; then echo "Error: no .cddl files found in $(CBOR_CDDL_DIR)"; exit 1; fi
	@mkdir -p "$(CBOR_INC_DIR)" "$(CBOR_SRC_DIR)"
	@cd "$(PROJ_DIR)" && $(NCS_SHELL) zcbor code --decode --encode \
		$(foreach c,$(CDDL_FILES),-c "$(call _CBOR_REL,$(c))") \
		-t $(CBOR_ENTRY_TYPES) \
		--oc "$(call _CBOR_REL,$(CBOR_SRC_DIR))/$(CBOR_OUT_BASE).c" \
		--oh "$(call _CBOR_REL,$(CBOR_INC_DIR))/$(CBOR_OUT_BASE).h" \
		--short-names

# Removes only files named after CBOR_OUT_BASE (zcbor adds _encode,
# _decode and _types suffixes), so the directories may hold other code.
clean-cbor:
	@$(require_cbor_settings)
	@rm -f "$(CBOR_SRC_DIR)/$(CBOR_OUT_BASE)"*.c "$(CBOR_INC_DIR)/$(CBOR_OUT_BASE)"*.h