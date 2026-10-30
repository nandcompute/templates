# Nand Compute Templates

Build files, Git configuration and documentation setup for embedded firmware and FPGA projects. These are the starting points Nand Compute uses on its own and its clients' projects, published so anyone can use them.

Each template is a plain file or folder that you copy into your project and own from then on. There's nothing to install and no dependency on this repository.

## What's here

| Folder | Contents |
|---|---|
| [`gitignore/`](gitignore/) | `.gitignore` building blocks: C projects, Zephyr / nRF Connect SDK, Vivado, Doxygen output |
| [`gitattributes/`](gitattributes/) | `.gitattributes` for firmware and FPGA projects: line endings, binaries, Git LFS |
| [`make/zephyr-ncs/`](make/zephyr-ncs/) | Make front end for Zephyr / nRF Connect SDK: build, flash, Twister tests, memory reports, nrfutil, zcbor, MCUboot keys |
| [`make/vivado/`](make/vivado/) | Make front end for AMD Vivado: IP packaging, xsim testbenches, bitstream and XSA builds |
| [`make/common/`](make/common/) | Make fragments for any build template: `make docs` (Doxygen), `make diagrams` (Graphviz) |
| [`doxygen/`](doxygen/) | Doxygen setup run through CMake: HTML, PDF, call graphs, strict mode for CI |

Each folder's README covers setup, options and requirements.

## Quick start

A Zephyr / nRF Connect SDK project with documentation:

```sh
T=path/to/templates   # a checkout of this repository, at a release tag

# Git configuration
{ for f in c zephyr doxygen; do cat "$T/gitignore/$f.gitignore"; echo; done; } > .gitignore
cp "$T/gitattributes/firmware.gitattributes" .gitattributes

# Build
mkdir -p make/mk
cp "$T"/make/zephyr-ncs/{Makefile,project.mk} make/
cp "$T"/make/zephyr-ncs/mk/*.mk "$T"/make/common/doxygen.mk make/mk/

# Documentation
mkdir -p docs
cp "$T"/doxygen/{CMakeLists.txt,Doxyfile.in} docs/
```

Then edit `make/project.mk` for your SDK version, applications and boards, and run `make -C make help`.

The `.gitignore` files are combined with an `echo` between them because they don't end with a newline. A plain `cat a b` would join the last line of one file to the first line of the next.

## Updates

The templates change over time, with no promise that a newer version works as a drop-in replacement for an older one. Note the commit you copied from in your project, for example in its README. To pick up a newer version, copy the files over yours and review the difference with `git diff` before committing.

## Conventions

- **The parts you edit are kept separate from the rest.** In `make/zephyr-ncs/`, only `project.mk` is edited per project. That keeps upgrades a matter of copying files over.
- **Examples use the placeholder name Acme**, so a leftover example value is easy to spot in review.
- **Each file starts with a header** naming the template it came from, so a copied file can be traced back to its source.
- **Formatting is set in [`.editorconfig`](.editorconfig)**, including tabs in Makefiles and no final newline.

## Support

The templates are provided as they are. Issues and pull requests aren't accepted; to change something, fork the repository or edit your copy.

## License

Free to copy, modify and use in any project, commercial or not, with no attribution required. See [LICENSE](LICENSE).

Portions are derived from [github/gitignore](https://github.com/github/gitignore) (CC0 1.0).