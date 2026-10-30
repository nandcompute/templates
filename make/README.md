# Make templates

| Folder | Contents |
|---|---|
| [`zephyr-ncs/`](zephyr-ncs/) | Make front end for Zephyr / nRF Connect SDK projects |
| [`vivado/`](vivado/) | Make front end for AMD Vivado projects |
| [`common/`](common/) | Fragments that work with any template here |

## How the templates fit together

Each template is a generic `Makefile`, a `project.mk` holding the project's settings, and a set of fragments in `mk/`, one per group of targets. A project copies all three into a folder such as `<project>/make/` and edits only `project.mk`.

Fragments are chosen in `project.mk` with `MK_FRAGMENTS`. A fragment from `common/` is copied into the same `mk/` folder as the template's own, so the project ends up with one flat folder and the Makefile doesn't need to know where a fragment came from.

## Shared fragments

| File | Targets | Setup |
|---|---|---|
| [`common/doxygen.mk`](common/doxygen.mk) | `docs`, `clean-docs` | [`../doxygen/`](../doxygen/README.md) |
| [`common/graphviz.mk`](common/graphviz.mk) | `diagrams`, `clean-diagrams` | Add `graphviz` to `MK_FRAGMENTS`. Renders each `docs/*.dot` to PDF and SVG in `build-docs/diagrams/`. Set `DIAGRAM_SRC`, `DIAGRAM_OUT` or `DIAGRAM_FORMATS` in `project.mk` to change that. Needs Graphviz. |

## What a shared fragment may rely on

A fragment in `common/` must work under any template's Makefile, so it uses only these, which every template Makefile provides:

| Name | Meaning |
|---|---|
| `PROJ_DIR` | Project root, absolute |
| `MK_DIR` | Directory holding the Makefile, absolute |
| `CLEAN_ALL` | Fragments append their `clean-*` targets here for `clean-all` |
| `##` comment lines | Printed by `make help`, in `MK_FRAGMENTS` order |

A fragment that needs anything more (an SDK environment, a board, `NCS_SHELL`) belongs in that template's own `mk/`, not in `common/`. That includes helpers like `$(space)`: define them in the fragment.