# Zephyr / nRF Connect SDK build template

A Make front end for west, Twister, nrfutil and the other tools used in Nordic nRF Connect SDK (NCS) projects. It gives every project the same commands (`make build-<app>`, `make flash-<app>`, `make test-hw`, ...) whatever the board or the application.

## Quick start

1. Copy this directory into the project, for example as `<project>/make/`. Leave out this README.
2. For documentation, set up Doxygen as described in [`doxygen/`](../../doxygen/README.md).
3. Edit `project.mk`: NCS version, applications, boards, and which optional fragments to use.
4. On each machine where the SDK isn't in `~/ncs/`, copy `local.mk.example` to `local.mk` and set `NCS_INSTALL_DIR`.
5. Build the project's `.gitignore` from [`gitignore/`](../../gitignore/): `c.gitignore` plus `zephyr.gitignore`, and `doxygen.gitignore` if the project uses Doxygen. See the root README for the command.
6. Run `make help` from that directory, or `make -C make help` from the project root.

The NCS environment script is generated automatically the first time a target needs it.

## Expected project layout

```
<project>/
├── apps/<app>/          # One Zephyr application per directory (APPS_DIR)
│   ├── prj.conf
│   ├── debug.conf       #   optional, merged when DEBUG=1
│   ├── release.conf     #   optional, merged otherwise
│   ├── boards/<board_target>.conf / .overlay   # optional, per board
│   └── sysbuild.conf, sysbuild/                # MCUboot etc.
├── boards/<vendor>/<board>/   # Custom boards (BOARD_ROOT/boards)
├── tests/               # Twister tests (TESTS_DIR)
├── docs/                # Doxygen CMakeLists.txt + Doxyfile.in (from doxygen/)
├── cbor/*.cddl          # Only with the cbor fragment
└── make/                # This template
```

Every location can be changed in `project.mk`.

## Files

| File | Edit per project? | Purpose |
|---|---|---|
| `project.mk` | **Yes** | NCS version, applications, board table, fragments, paths |
| `local.mk.example` | Copy to `local.mk` | Settings for one machine; never committed |
| `Makefile` | No | Loads project settings, resolves `BOARD`, includes fragments, `help`, `clean-all` |
| `mk/west.mk` | No (required) | `build-`, `flash-`, `menuconfig-`, `clean-<app>` |
| `mk/env.mk` | No (required) | Generates the NCS environment script |
| `mk/ninja.mk` | No | `ram-report-`, `rom-report-`, `rom-plot-<app>` |
| `mk/twister.mk` | No | `test-compile`, `test-hw`, `test-hw-rtt`, `test-sim` |
| `mk/nrfutil.mk` | No | `recover`, `reset` |
| `mk/cbor.mk` | No | zcbor code generation from CDDL |
| `mk/pem.mk` | No | MCUboot signing key generation |

Fragments that aren't specific to Zephyr, such as `doxygen.mk`, live in [`../common/`](../README.md) and are copied into the same `mk/` folder. The `.gitignore` additions for this template are in [`gitignore/zephyr.gitignore`](../../gitignore/zephyr.gitignore).

Don't edit the generic files in a project. Keeping them unchanged means a project can upgrade by copying a newer version over them, and a diff against the template shows only real differences. Project-specific targets go in a new `mk/<name>.mk` listed in `MK_FRAGMENTS`. If a generic file needs a change, make it in your copy and note it, since copying a newer version over it would undo the change.

## Common options

| Variable | Default | Effect |
|---|---|---|
| `BOARD` | `DEFAULT_BOARD` | Short board name from the `BOARDS` table |
| `DEBUG` | `0` | `1` builds into `build-debug-<board>` and merges `debug.conf` |
| `PRISTINE` | `1` | `0` for an incremental build |
| `ERASE` | `1` | `0` to flash without a full erase (keeps provisioned settings) |
| `RUNNER` | `jlink` | `west flash` runner |
| `SNR` | | Probe serial number when several are connected (flash, tests, recover) |
| `EXTRA_CONF` / `EXTRA_DTC` | | Extra Kconfig fragments / devicetree overlays |
| `NCS_INSTALL_DIR` | `~/ncs` | Folder holding one subfolder per NCS version; set in `local.mk` |
| `NCS_ROOT` | `$(NCS_INSTALL_DIR)/<NCS_VERSION>` | Full path to one NCS version, for other layouts |
| `TWISTER_ARGS` | | Extra Twister options, e.g. `TWISTER_ARGS="-s tests.foo"` |

Machine-specific values (`NCS_INSTALL_DIR`, probe serials, serial ports) go in `local.mk`, which Git ignores, never in `project.mk`, which everyone shares. A value given on the make command line overrides both.

## Adding a board

Add the short name to `BOARDS` and two table entries in `project.mk`:

```make
board.acme_node.target := acme_node/nrf54l15/cpuapp
board.acme_node.family := nrf54l
```

`make help` and the `BOARD` check pick it up automatically.

## Notes

- **Board Kconfig fragments.** Because `CONF_FILE` lists more than one file, Zephyr stops merging `boards/<board>.conf` automatically, so the Makefile passes it as `EXTRA_CONF_FILE`. Devicetree overlays use Zephyr's own lookup (`boards/<board>.overlay`, else `app.overlay`). The Makefile does not set `DTC_OVERLAY_FILE`, because that turns the lookup off.
- **Sysbuild.** `-D` options reach the main application image only. MCUboot is configured through the app's `sysbuild.conf` and `sysbuild/` directory.
- **Signing keys.** `make pem` never overwrites an existing key. Keep the key out of git and backed up, since deployed devices only accept images signed with it.
- **RTT tests.** `test-hw-rtt` needs a project-supplied `rtt_pty.py` (`RTT_PTY`) and `tests/common/rtt.conf` (`RTT_CONF`).