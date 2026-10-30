# ===================================================================
# graphviz.mk: render Graphviz diagrams (*.dot) to PDF and SVG
# Nand Compute Templates — make/common/
#
# Shared by every build template; needs only Graphviz. Renders every
# *.dot file in DIAGRAM_SRC, and only those that changed since the
# last run.
#
# Uses from the including Makefile: PROJ_DIR, CLEAN_ALL.
# ===================================================================

##
## Diagrams (Graphviz):
##   diagrams            Render every .dot file to PDF and SVG
##   clean-diagrams      Remove rendered diagrams

# -------------------------------------------------------------------
# Settings. Override in project.mk, e.g.
#   DIAGRAM_SRC     := $(PROJ_DIR)/docs/diagrams
#   DIAGRAM_FORMATS := pdf png
# The default output folder is under build-docs/, which
# gitignore/doxygen.gitignore already ignores.
# -------------------------------------------------------------------
DIAGRAM_SRC     ?= $(PROJ_DIR)/docs
DIAGRAM_OUT     ?= $(PROJ_DIR)/build-docs/diagrams
DIAGRAM_FORMATS ?= pdf svg
DOT             ?= dot

_DIAGRAM_DOT_FILES := $(wildcard $(DIAGRAM_SRC)/*.dot)
_DIAGRAM_OUTPUTS   := $(foreach f,$(DIAGRAM_FORMATS),$(patsubst $(DIAGRAM_SRC)/%.dot,$(DIAGRAM_OUT)/%.$(f),$(_DIAGRAM_DOT_FILES)))

# One pattern rule per output format: <name>.dot -> <name>.<format>
define _diagram_rule
$(DIAGRAM_OUT)/%.$(1): $(DIAGRAM_SRC)/%.dot | _diagram-check
	@mkdir -p "$$(@D)"
	@echo "Rendering $$(notdir $$@)"
	@$(DOT) -T$(1) "$$<" -o "$$@"
endef
$(foreach f,$(DIAGRAM_FORMATS),$(eval $(call _diagram_rule,$(f))))

.PHONY: diagrams clean-diagrams _diagram-check
CLEAN_ALL += clean-diagrams

diagrams: $(_DIAGRAM_OUTPUTS)
	@$(if $(_DIAGRAM_DOT_FILES),echo "Diagrams in $(DIAGRAM_OUT)/",echo "No .dot files in $(DIAGRAM_SRC)")

_diagram-check:
	@command -v $(DOT) >/dev/null || { \
		echo "Error: $(DOT) not found. Install Graphviz (Debian/Ubuntu: graphviz)."; \
		exit 1; }

clean-diagrams:
	@rm -rf "$(DIAGRAM_OUT)"