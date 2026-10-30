# ===================================================================
# env.mk: NCS toolchain environment script
# Nand Compute Templates — make/zephyr-ncs/mk/
#
# The script is generated automatically the first time a target needs
# it (see ncs-check in Makefile). "make env" regenerates it, e.g.
# after a toolchain update.
# ===================================================================

##
## Environment:
##   env                 Regenerate the NCS environment script
##   clean-env           Remove NCS environment scripts

# Write to a temporary file first, so a failed nrfutil call can't leave
# an empty script behind that later builds would source silently.
define generate_env
@echo "Generating $(notdir $(NCS_ENV_SCRIPT))"
@nrfutil toolchain-manager env --ncs-version $(NCS_VERSION) --as-script > "$(NCS_ENV_SCRIPT).tmp" \
	|| { rm -f "$(NCS_ENV_SCRIPT).tmp"; exit 1; }
@mv "$(NCS_ENV_SCRIPT).tmp" "$(NCS_ENV_SCRIPT)"
@chmod +x "$(NCS_ENV_SCRIPT)"
endef

$(NCS_ENV_SCRIPT):
	$(generate_env)

.PHONY: env clean-env
CLEAN_ALL += clean-env

env:
	$(generate_env)

clean-env:
	@rm -f "$(MK_DIR)"/ncs_env_*.sh