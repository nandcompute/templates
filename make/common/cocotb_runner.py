# SPDX-FileCopyrightText: 2026 Nand Compute LLC
# SPDX-License-Identifier: MIT-0

# ===================================================================
# cocotb_runner.py: build and run one unit under cocotb
# Nand Compute Templates — make/common/
#
# cocotb.mk passes the unit's sources and settings as TPL_COCOTB_*
# environment variables and puts this file on PYTHONPATH. A test file
# calls run() once per set of generics, typically from a pytest
# function:
#
#   import pytest
#   from cocotb_runner import run
#
#   @pytest.mark.parametrize("depth", [1, 16, 17])
#   def test_my_core(depth):
#       run(__file__, parameters={"DEPTH": depth})
#
# The cocotb tests themselves (@cocotb.test) live in the same file.
# Give them names that don't start with "test", or pytest also tries
# to collect them.
# ===================================================================

import os
import re
from pathlib import Path

from cocotb_tools.runner import get_runner

# Arguments that select the VHDL standard, for analysis and for the
# simulation run, per simulator.
_STD_ARGS = {
    "ghdl": lambda std: ([f"--std={std[-2:]}"], [f"--std={std[-2:]}"]),
    "nvc":  lambda std: ([f"--std={std}"], []),
}


def _require(name):
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(f"{name} is not set. Run the tests through make: make test-<unit>")
    return value


def run(test_file, parameters=None):
    """Build the unit and run every cocotb test in test_file.

    test_file  The test file's path (pass __file__); its cocotb tests run.
    parameters Generics for this run, as a dict of name to value.

    Each set of parameters gets its own build folder, named after the
    values, so results and waveforms of every configuration are kept.
    The run fails (raises) if any cocotb test fails.
    """
    parameters = dict(parameters or {})
    sim = os.environ.get("TPL_COCOTB_SIM", "ghdl")
    std = os.environ.get("TPL_COCOTB_STD", "2008")
    waves = os.environ.get("TPL_COCOTB_WAVES", "0") == "1"
    top = _require("TPL_COCOTB_TOPLEVEL")
    sources = _require("TPL_COCOTB_SOURCES").split()

    tag = "_".join(f"{name}{value}" for name, value in parameters.items()) or "default"
    build_dir = Path(_require("TPL_COCOTB_BUILD")) / re.sub(r"[^\w.-]", "_", tag)

    build_args, test_args = _STD_ARGS.get(sim, lambda std: ([], []))(std)

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_library="work",
        hdl_toplevel=top,
        build_dir=build_dir,
        build_args=build_args,
        parameters=parameters,
        always=True,
    )
    runner.test(
        test_module=Path(test_file).stem,
        hdl_toplevel=top,
        hdl_toplevel_library="work",
        build_dir=build_dir,
        test_dir=build_dir,
        test_args=test_args,
        parameters=parameters,
        waves=waves,
    )