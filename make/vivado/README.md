# AMD Vivado build template

A Make front end for Vivado: packages a library of IP for the IP catalog, runs each IP's testbench in xsim, and builds designs into a bitstream and an XSA. Every step runs in batch mode, with the full Vivado output in a log file and one result line on the console.

Targets Vivado 2025.2.

## Quick start

1. Copy this directory into the project, for example as `<project>/make/`. Leave out this README.
2. Edit `project.mk`: Vivado version, IP vendor details, and the designs to build.
3. On each machine, copy `local.mk.example` to `local.mk` and set where Vivado is installed.
4. Append `gitignore/vivado.gitignore` to the project's `.gitignore` (built from `gitignore/c.gitignore`, which ignores `local.mk`).
5. Run `make help` from that directory, or `make -C make help` from the project root.

## Project and machine settings

Settings live in two files:

- **`project.mk`** is committed and the same for everyone: the Vivado version, IP vendor details, designs.
- **`local.mk`** is never committed and holds what differs between machines: where Vivado is installed, and the number of parallel jobs.

If `vivado` isn't on `PATH`, recipes source `$(XILINX_ROOT)/$(VIVADO_VERSION)/Vivado/settings64.sh` first. `XILINX_ROOT` defaults to `/tools/Xilinx`; set it in `local.mk` if Vivado is installed elsewhere. Because the version comes from `project.mk`, moving a project to a new Vivado version needs no change on any machine that has it installed. For any other installation layout, such as 2024.2 and older (`<root>/Vivado/<version>/`), set `VIVADO_SETTINGS` to the full path of `settings64.sh` instead.

A value given on the make command line overrides both files, for example `make ip-all XILINX_ROOT=/opt/Xilinx`.

## Expected project layout

```
<project>/
├── library/                   # IP_DIR: one folder per IP
│   ├── <ip>/
│   │   ├── <ip>.vhd           #   HDL; the top entity/module is named <ip>
│   │   ├── *.xdc              #   optional IP constraints
│   │   ├── ip.tcl             #   interfaces and GUI (marks the folder as an IP)
│   │   ├── tb/<ip>_tb.vhd     #   optional testbench
│   │   └── tb/test_<ip>.py    #   optional cocotb tests
│   └── <lib>/                 #   a library: HDL but no ip.tcl
│       ├── <lib>_pkg.vhd      #   shared packages
│       └── tb/<lib>_tb.vhd    #   optional testbench
├── designs/                   # DESIGN_DIR: one folder per design
│   └── <design>/
│       ├── system_top.vhd     #   top level (design.<name>.top to change)
│       ├── *.xdc              #   constraints
│       ├── system_bd.tcl      #   optional block design
│       ├── ips.tcl            #   optional third-party IP (create_ip)
│       └── msg.tcl            #   optional message severity changes
├── build/                     # BUILD_DIR: everything generated
└── make/                      # This template
```

Every location can be changed in `project.mk`.

## Files

| File | Edit per project? | Purpose |
|---|---|---|
| `project.mk` | **Yes** | Vivado version, IP vendor details, per-IP and per-design settings |
| `local.mk.example` | Copy to `local.mk` | Settings for one machine; never committed |
| `Makefile` | No | Vivado setup, logging, `help`, `clean-all` |
| `mk/ip.mk` | No | `ip-<ip>`, `ip-all`: package IP into `build/ip/` |
| `mk/sim.mk` | No | `sim-<ip>`, `sim-all`: testbenches in xsim |
| `mk/design.mk` | No | `bit-<design>`, `program-<design>`, `flash-<design>`, `gui-<design>` |
| `mk/doxygen.mk` | No | Optional (`MK_FRAGMENTS`): `docs`, from `make/common/` |
| `mk/cocotb.mk`, `mk/cocotb_runner.py` | No | Optional (`MK_FRAGMENTS`): `test-<ip>`, `test-all`, from `make/common/` |
| `tcl/common.tcl` | No | Settings from Make, version check, adding sources |
| `tcl/ip_helpers.tcl` | No | Helpers for each IP's `ip.tcl` |
| `tcl/package_ip.tcl` | No | Packages one IP |
| `tcl/build_design.tcl` | No | Builds one design |
| `tcl/program.tcl` | No | Loads a design over JTAG or into flash |

Don't edit the generic files in a project. Keeping them unchanged means a project can upgrade by copying a newer version over them. Project-specific targets go in a new `mk/<name>.mk` listed in `MK_FRAGMENTS`.

## IP

Any folder in `library/` with an `ip.tcl` is an IP; there's nothing to register. Packaging creates a project with the IP's HDL, packages it with the vendor details from `project.mk`, then sources the IP's `ip.tcl`. Packaging copies the sources in, so each packaged IP in `build/ip/<ip>/` is self-contained.

Packaging starts with no bus interfaces, so `ip.tcl` declares each one:

```tcl
tpl::infer_clock clk {s_axi}         ;# clock, and the interfaces it clocks
tpl::infer_reset rst_n               ;# reset; polarity from the name, or pass high/low
tpl::infer_axi_mm                    ;# every AXI memory-mapped interface
tpl::infer_axis                      ;# every AXI4-Stream interface
tpl::gui_combo   TARGET {XILINX GENERIC}
tpl::gui_range   STAGES 2 8
tpl::gui_order   {TARGET STAGES DATA_WIDTH}
```

Any other `ipx::` or `ipgui::` command works too; `[ipx::current_core]` is the IP being packaged.

`tpl::infer_reset` treats a reset as active-low when its name ends in `rstn`, `rst_n`, `resetn` or `reset_n`, optionally followed by `_i` or `_o`. Everything else is active-high. Pass `low` or `high` for any other naming: `tpl::infer_reset nrst low`.

An IP that reuses another IP's HDL lists it in `project.mk`:

```make
ip.mux_synchronizer.deps := flip_flop_synchronizer
```

Its sources are then included, before the IP's own, both when packaging and in simulation, and `make ip-mux_synchronizer` packages `flip_flop_synchronizer` first.

### Libraries

A folder in `library/` with HDL but no `ip.tcl` is a library: shared code with no top entity of its own, such as VHDL packages. A library is never packaged, but it can be listed in `ip.<name>.deps` and `design.<name>.libs` like an IP, and its testbench runs with `make sim-<lib>` and `sim-all`:

```make
ip.uart.deps         := common
ip.common.tb_top     := util_pkg_tb
```

Files named `*_pkg.vhd` compile before the rest of the folder. `make help` lists the libraries found. A misspelled name in `.deps` or `.libs` stops with an error naming it.

## Simulation

`make sim-<ip>` compiles the IP's sources (including its dependencies) and everything in `<ip>/tb/`, elaborates `<ip>_tb`, and runs it in xsim. Per-IP settings in `project.mk` change that:

- `ip.<name>.tb_top`: the testbench top, when it isn't `<ip>_tb`.
- `ip.<name>.tb_sources`: testbench-only HDL outside `tb/`, such as a vendor simulation model, relative to the IP folder and in compile order. It compiles before `tb/`; listing a file from `tb/` here moves it first.
- `ip.<name>.tb_incdirs`: Verilog `` `include `` folders for the testbench, relative to the IP folder.

A testbench:

- **Reports failures** with `severity error` or `severity failure` (VHDL) or `$error` / `$fatal` (SystemVerilog). Any `Error:`, `Failure:` or `FATAL_ERROR:` in the simulator output fails the target.
- **Ends the simulation itself**, with `std.env.finish` (VHDL-2008), `$finish`, or by stopping every clock. Otherwise xsim runs forever.

`SIM_GUI=1` opens the waveform viewer instead of running in batch. UNISIM and UNIMACRO are linked by default, so testbenches can simulate Xilinx primitives; set `SIM_LIBS` to change that.

## cocotb tests

The optional `cocotb` fragment runs Python tests in GHDL (default) or NVC. cocotb doesn't support xsim. To add it, copy `make/common/cocotb.mk` and `make/common/cocotb_runner.py` into `mk/`, and add `cocotb` to `MK_FRAGMENTS`. Each machine needs Python with cocotb 2.x and pytest (`pip install cocotb pytest`), and the simulator on `PATH`.

A unit's tests go in `<ip>/tb/test_<ip>.py`. The cocotb tests and the pytest function that runs them live in the same file, and the pytest function calls `run()` once per set of generics:

```python
import cocotb
import pytest
from cocotb_runner import run

@cocotb.test()
async def fills_and_drains(dut):    # cocotb tests must not start with "test"
    ...

@pytest.mark.parametrize("depth", [1, 16, 17])
def test_my_fifo(depth):
    run(__file__, parameters={"DEPTH": depth})
```

`make test-<ip>` compiles the IP's sources, dependencies first as for xsim, and runs every configuration. It prints one line on success, and the first failures plus the log path otherwise. `make test-all` runs every unit with a `tb/test_*.py`. A unit can have both an xsim testbench and cocotb tests.

| Variable | Default | Effect |
|---|---|---|
| `COCOTB_SIM` | `ghdl` | Simulator: `ghdl` or `nvc` |
| `COCOTB_WAVES` | `0` | `1` writes waveforms into each configuration's build folder |
| `COCOTB_PYTEST_ARGS` | | Extra pytest arguments, e.g. `-k DEPTH16` |

Testbenches that use Xilinx primitives need the UNISIM library compiled for that simulator, so keep those on xsim.

## Designs

List each design in `project.mk`:

```make
DESIGNS += acme_arty
design.acme_arty.part     := xc7z020clg400-1
design.acme_arty.board    := digilentinc.com:arty-z7-20:part0:1.1
design.acme_arty.ips      := clock_forwarder mux_synchronizer
design.acme_arty.generics := CHANNELS=4
```

A design uses IP from `library/` in one of two ways:

- **`.libs`: compiled into the design.** For an RTL top level. The IP's HDL, after that of the IPs it depends on, is added to the design's sources, and the top level instantiates it like any other entity: `u_clk : entity work.clk_gen`. Its generics are set in the top level, and the IP keeps its own testbench (`make sim-<ip>`). Its `*.xdc` files are not added: constraints for the design go in the design's folder.
- **`.ips`: packaged IP.** For a block design (`system_bd.tcl`) or `create_ip` in `ips.tcl`, with the VLNV `<IP_VENDOR>:<IP_LIBRARY>:<ip>:<version>`. The IP is packaged first and used from the IP catalog.

`make bit-acme_arty` packages the IPs in `.ips`, creates the project, creates the third-party IP from `ips.tcl` and builds the block design from `system_bd.tcl` if the design has them, then runs synthesis and implementation. The output in `build/designs/acme_arty/` is `acme_arty.bit`, `acme_arty.xsa` (with the bitstream, for Vitis), `timing.rpt` and `utilization.rpt`.

The build fails, with a clear message, if a run fails or timing isn't met. When timing fails, the bitstream and XSA are still written, but as `acme_arty_bad_timing.*`, so they can't be mistaken for a good build. Registers with no clock, which don't show up as timing failures, produce a warning and `no_clock.rpt`.

`make gui-acme_arty` opens the built project in the Vivado GUI, for looking at timing, the floorplan or the block design. Changes made there aren't kept: the next `make bit-acme_arty` recreates the project from the sources.

### Third-party IP

IP from outside `library/`, such as a vendor's IP repository, is listed per design and created in the design's `ips.tcl`:

```make
design.acme_arty.ip_repos := $(PROJ_DIR)/vendor/acme/acme-ip-v1.0
```

```tcl
# designs/acme_arty/ips.tcl
create_ip -vlnv acme.com:ip:widget:1.0 -module_name widget_0
set_property -dict [list CONFIG.WIDTH {32}] [get_ips widget_0]
```

The repositories are added after the project's own packaged IPs. `ips.tcl` runs before the block design, and its IP is generated before synthesis, so configuration errors stop the build early. Instantiate the generated module in the top level by its `-module_name`. Commit the vendor's distribution unchanged, in a versioned folder, so an upgrade only changes the path.

## Loading onto hardware

Both targets use the last build, and never start one themselves. Run `make bit-<design>` first.

**`make program-<design>`** loads the bitstream into the FPGA over JTAG. It's quick, and lost at power-off. If the design has debug cores (ILA, VIO), the build also writes `<design>.ltx`, and `program-` loads it, so the cores appear in the Hardware Manager.

**`make flash-<design>`** writes the board's configuration flash, then reboots the FPGA from it, so the design loads at every power-up. It needs the flash part in `project.mk`:

```make
design.acme_artix.flash      := s25fl128sxxxxxx0-spi-x1_x2_x4
design.acme_artix.flash_size := 16
```

The flash part uses Vivado's name for it: run `get_cfgmem_parts` in the Vivado Tcl console, or take the name the Hardware Manager shows for the board. With a flash part set, `make bit-<design>` also writes the flash image, `<design>.mcs`. For a fast boot from quad SPI, also set the bitstream's configuration options in the design's constraints, for example:

```tcl
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
```

`flash-` is for FPGAs that boot from configuration flash, such as Artix, Kintex and Spartan-7. Zynq, Zynq UltraScale+ and Versal boot through their processor from a `BOOT.BIN`, which is made and written to flash with Vitis (`bootgen`, `program_flash`), so `flash-` refuses those parts. On them, `program-` loads only the programmable logic. A design that uses the processor still needs software (FSBL or a Vitis application) to initialize it.

**Which cable.** By default the targets use a cable on this machine. Set these in `local.mk` when that isn't enough:

- `HW_SERVER`: a board attached to another machine, for example `labpc:3121`. That machine runs `hw_server`, which comes with Vivado and the Vivado Lab Edition.
- `HW_TARGET`: part of one cable's serial number, when several cables are connected. The error message lists the ones found.

## Common options

| Variable | Default | Effect |
|---|---|---|
| `VERBOSE` | `0` | `1` shows the full tool output instead of one line per step |
| `JOBS` | number of CPUs | Parallel jobs for synthesis and implementation runs |
| `VERSION_CHECK` | `error` | `warn` continues when the installed Vivado differs from `VIVADO_VERSION` |
| `VHDL_2008` | `1` | `0` compiles VHDL as VHDL-93 instead of VHDL-2008 |
| `XILINX_ROOT` | `/tools/Xilinx` | Folder holding one subfolder per Vivado version; set in `local.mk` |
| `VIVADO_SETTINGS` | `$(XILINX_ROOT)/<version>/Vivado/settings64.sh` | Full path to `settings64.sh`, for other layouts |
| `IP_CACHE` | `build/ipcache` | Shared IP synthesis cache; empty turns it off |
| `SIM_GUI` | `0` | `1` opens the xsim waveform viewer |
| `HW_SERVER` | `localhost:3121` | Hardware server for `program-` and `flash-` |
| `HW_TARGET` | | Part of a JTAG cable's serial number, to pick one of several |

`make -j` works: independent IPs are packaged in parallel, and each IP waits for the ones it depends on.

## Notes

- **Appending to `project.mk`.** Templates in this repository don't end with a newline. When adding a line with `echo ... >> project.mk`, start it with a newline, or it joins the last comment line and has no effect.