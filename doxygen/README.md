# Doxygen

Doxygen run through CMake: HTML, an optional PDF, call graphs, and a strict mode that fails on undocumented code for CI.

## Files

| File | Copy to | Purpose |
|---|---|---|
| `CMakeLists.txt` | `<project>/docs/` | CMake project that runs Doxygen and builds the PDF |
| `Doxyfile.in` | `<project>/docs/` | Doxygen settings: only those that differ from Doxygen's defaults |
| [`../make/common/doxygen.mk`](../make/common/doxygen.mk) | `<project>/make/mk/` | `make docs` and `make clean-docs` |
| [`../gitignore/doxygen.gitignore`](../gitignore/doxygen.gitignore) | Append to `.gitignore` | Ignores `build-docs/` |

## Setup

1. Copy the files as listed above, and add `doxygen` to `MK_FRAGMENTS` in `project.mk`.
2. In `project.mk`, say what to document:

   ```make
   DOC_PROJECT_NAME  := Acme Firmware
   DOC_PROJECT_BRIEF := Firmware for the Acme sensor node
   DOC_INPUT         := $(APPS_DIR) $(PROJ_DIR)/docs
   ```

   `DOC_INPUT` defaults to the whole project. Build and Twister output folders are always excluded.
3. Run `make docs`. The output goes to `build-docs/html/index.html`.

Markdown files in `DOC_INPUT` become pages. A page whose heading ends in `{#mainpage}` becomes the front page.

Without Make, run CMake directly from the project root:

```sh
cmake -B build-docs -S docs -DDOC_PROJECT_ROOT="$PWD" -DDOC_INPUT="src;docs"
cmake --build build-docs --target doc
```

## Options

| Variable | Default | Effect |
|---|---|---|
| `DOC_GEN_PDF` | `OFF` | `ON` also builds `build-docs/<name>.pdf` |
| `DOC_EXTRACT_ALL` | `ON` | `OFF` documents only commented code, and warns about the rest |
| `DOC_WARN_AS_ERROR` | `OFF` | `ON` fails the build on any warning, for CI |
| `DOC_OUTPUT_DIR` | `build-docs` | Where the output goes. Add it to `.gitignore` if you change it. |
| `DOCVER` | `git describe` | Version shown in the documentation |

For example, `make docs DOC_EXTRACT_ALL=OFF DOC_WARN_AS_ERROR=ON` checks that every function is documented.

## Requirements

- CMake 3.16 or newer and Doxygen. Tested with Doxygen 1.9.8.
- Graphviz (`dot`) for call graphs. Without it, the docs build without graphs.
- For `DOC_GEN_PDF=ON`: `pdflatex` and `make`, with TeX Live's extra packages (Debian/Ubuntu: `texlive-latex-extra texlive-plain-generic`).

## Changing settings

`Doxyfile.in` lists only settings that differ from Doxygen's defaults, so it stays short and survives Doxygen upgrades. To change one for a project, add it to the project's copy with a comment saying why. `doxygen -g full.Doxyfile` writes the full list of settings with descriptions.

The exclusion patterns match folder names anywhere in a file's full path, including folders above the project. Don't check a project out inside a folder named `build`, `debug` or `release`, or the documentation will come out empty.