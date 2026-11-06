# ===================================================================
# doxygen.mk: Doxygen documentation through CMake
# Nand Compute Templates — make/common/
#
# Shared by every build template; needs no SDK or toolchain beyond
# CMake and Doxygen (plus Graphviz for graphs, pdflatex for the PDF).
# Expects $(DOC_SRC) to hold CMakeLists.txt and Doxyfile.in from
# the doxygen/ folder of nandcompute/templates.
#
# Uses from the including Makefile: PROJ_DIR, CLEAN_ALL.
# ===================================================================

##
## Documentation (DOC_WARN_AS_ERROR=ON for CI):
##   docs                Generate Doxygen documentation
##   clean-docs          Remove generated documentation

# -------------------------------------------------------------------
# Settings. Set the project's values in project.mk, e.g.
#   DOC_PROJECT_NAME  := Acme Firmware
#   DOC_PROJECT_BRIEF := Firmware for the Acme sensor node
#   DOC_INPUT         := $(PROJ_DIR)/apps $(PROJ_DIR)/docs
# -------------------------------------------------------------------
DOC_PROJECT_NAME  ?= $(notdir $(PROJ_DIR))
DOC_PROJECT_BRIEF ?=
DOC_INPUT         ?= $(PROJ_DIR)
DOC_SRC           ?= $(PROJ_DIR)/docs
DOC_BUILD         ?= $(PROJ_DIR)/build-docs
DOC_OUTPUT_DIR    ?= $(DOC_BUILD)
DOCVER            ?= $(shell git -C "$(PROJ_DIR)" describe --tags --always --dirty 2>/dev/null || echo unknown)

DOC_GEN_HTML      ?= ON
DOC_GEN_PDF       ?= ON
DOC_GEN_RTF       ?= OFF
DOC_GEN_MAN       ?= OFF
DOC_EXTRACT_ALL   ?= ON
DOC_WARN_AS_ERROR ?= OFF

# DOC_INPUT as a CMake list. Defined here, not taken from the
# including Makefile, so the fragment stays template-independent.
_DOC_EMPTY :=
_DOC_INPUT_LIST = $(subst $(_DOC_EMPTY) $(_DOC_EMPTY),;,$(strip $(DOC_INPUT)))

.PHONY: docs clean-docs
CLEAN_ALL += clean-docs

docs:
	@if [ ! -f "$(DOC_SRC)/CMakeLists.txt" ] || [ ! -f "$(DOC_SRC)/Doxyfile.in" ]; then \
		echo "Error: $(DOC_SRC) needs CMakeLists.txt and Doxyfile.in"; \
		echo "Copy them from the doxygen/ folder of nandcompute/templates."; \
		exit 1; \
	fi
	@cmake -B "$(DOC_BUILD)" -S "$(DOC_SRC)" --log-level=WARNING \
		-DDOC_PROJECT_ROOT="$(PROJ_DIR)" \
		-DDOC_PROJECT_NAME="$(DOC_PROJECT_NAME)" \
		-DDOC_PROJECT_BRIEF="$(DOC_PROJECT_BRIEF)" \
		-DDOC_INPUT="$(_DOC_INPUT_LIST)" \
		-DDOC_OUTPUT_DIR="$(DOC_OUTPUT_DIR)" \
		-DDOCVER="$(DOCVER)" \
		-DDOC_GEN_HTML=$(DOC_GEN_HTML) \
		-DDOC_GEN_PDF=$(DOC_GEN_PDF) \
		-DDOC_GEN_RTF=$(DOC_GEN_RTF) \
		-DDOC_GEN_MAN=$(DOC_GEN_MAN) \
		-DDOC_EXTRACT_ALL=$(DOC_EXTRACT_ALL) \
		-DDOC_WARN_AS_ERROR=$(DOC_WARN_AS_ERROR)
	@cmake --build "$(DOC_BUILD)" --target doc
	@echo "Documentation in $(DOC_OUTPUT_DIR)/"
	@$(if $(filter ON,$(DOC_GEN_HTML)),echo "  html/index.html";)
	@$(if $(filter ON,$(DOC_GEN_PDF)),cd "$(DOC_OUTPUT_DIR)" && ls *.pdf | sed 's/^/  /';)

# Output formats are removed by name, so a DOC_OUTPUT_DIR outside the
# build folder may also hold other files.
clean-docs:
	@rm -rf "$(DOC_BUILD)" "$(DOC_OUTPUT_DIR)/html" "$(DOC_OUTPUT_DIR)/latex" \
		"$(DOC_OUTPUT_DIR)/rtf" "$(DOC_OUTPUT_DIR)/man"