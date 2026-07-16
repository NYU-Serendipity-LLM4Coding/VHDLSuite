"""
VHDLSuite - VHDL Simulation & Verification Harness
===================================================

Shared simulation backend used by BOTH pipeline stages:

  1. Construction stage  (src/construction/*): compiles and simulates a
     translated VHDL design against its VHDL testbench, feeding failures
     back to the LLM for iterative repair.
  2. Evaluation stage    (src/evaluation/*):   compiles and simulates a
     model-generated VHDL design against the released VHDLBench testbench.

The core entry point is `evaluate()`, which wraps a single VUnit/GHDL run in
a spawned subprocess with a hard timeout (so a hanging GHDL simulation cannot
block the pipeline), captures its output, and classifies the result into an
integer `issue` code (see the "Issue codes" table below).

Requirements
------------
  * GHDL              (VHDL simulator backend)
  * VUnit             (`pip install vunit_hdl`)
  * psutil            (`pip install psutil`)
VHDL is compiled/simulated under the VHDL-2008 standard (``--std=08``).

Issue codes returned by `evaluate()`
------------------------------------
  0 : Success            - compiles and all simulation checks pass
  1 : Fail               - generic failure (e.g. compilation error)
  2 : Functional fail    - compiles & runs but simulation reports mismatches
                           (details taken from summary.txt)
  3 : Timeout            - simulation exceeded MAX_RUNTIME_SECONDS
  4 : Fixed-timeout bug  - testbench ran to a hard sample cap instead of
                           honouring the sim_done signal in verify_process
  5 : Early-report bug   - report_process fired before all tests completed
  6 : Inconsistent pass  - test "passed" but mismatches were reported
"""

import io
import re
import subprocess
import traceback
from contextlib import redirect_stdout, redirect_stderr
from multiprocessing import get_context
from pathlib import Path

import psutil
from vunit import VUnit

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Maximum wall-clock time (seconds) allowed for a single compile+simulate run.
# Runs exceeding this are killed and classified as a timeout (issue 3).
MAX_RUNTIME_SECONDS = 20

# Log file written by evaluate() with the captured VUnit/GHDL output of the
# most recent run. summary.txt (written by the VHDL testbench itself) is read
# alongside it to extract functional-mismatch details.
LOG_PATH = "single_experiment_log.txt"


# ---------------------------------------------------------------------------
# VUnit build helpers
# ---------------------------------------------------------------------------

def clean_vunit():
    """Remove stale VUnit/GHDL build artifacts before a fresh run."""
    try:
        subprocess.run(["rm", "-rf", "vunit_out", "work-obj08.cf"], check=True)
        print("Cleaned build artifacts successfully.")
    except subprocess.CalledProcessError as e:
        print("Failed to clean build artifacts:", e)


def add_source_file_if_exists(lib, file_path, required=True):
    """
    Add a VHDL source file to a VUnit library if it exists.

    Args:
        lib:       VUnit library object.
        file_path: Path to the .vhd source file.
        required:  If True, raise FileNotFoundError when the file is missing;
                   if False, emit a warning and skip it.

    Returns:
        bool: True if the file was added, False if it was optional and absent.
    """
    file_path = Path(file_path)
    if file_path.exists():
        lib.add_source_files(str(file_path))
        print(f"Added: {file_path}")
        return True
    if required:
        raise FileNotFoundError(f"Required source file not found: {file_path}")
    print(f"Warning: optional source file not found: {file_path}")
    return False


def run_dir_vhdl(dir_name, top_name, read_ref=True):
    """
    Compile and simulate one problem directory with VUnit + GHDL (VHDL-2008).

    Expected files inside `dir_name`:
        gen.vhd   (optional)  - auxiliary stimulus/signal generator
        ref.vhd   (optional)  - reference/golden design
        tb.vhd    (required)  - VHDL testbench
    plus `top_name` (required) - the design under test (typically dut.vhd).

    Args:
        dir_name:  Path to the problem directory.
        top_name:  Path to the top-level DUT VHDL file.
        read_ref:  Whether to include ref.vhd if present.
    """
    clean_vunit()
    vu = VUnit.from_argv()
    vu.add_vhdl_builtins()  # provides vunit_lib.vunit_context

    lib = vu.add_library("lib")
    add_source_file_if_exists(lib, dir_name / "gen.vhd", required=False)
    if read_ref:
        add_source_file_if_exists(lib, dir_name / "ref.vhd", required=False)
    add_source_file_if_exists(lib, top_name, required=True)
    add_source_file_if_exists(lib, dir_name / "tb.vhd", required=True)

    vu.set_compile_option("ghdl.flags", ["--std=08"])
    vu.set_sim_option("ghdl.elab_flags", ["--std=08"])
    vu.main()


def run_dir_self(dir_name):
    """
    Convenience wrapper: simulate a problem directory using its own dut.vhd
    as the top-level design. This is the callable passed to `evaluate()`
    throughout the construction and evaluation pipelines.
    """
    root = Path(dir_name)
    top_name = root / "dut.vhd"
    run_dir_vhdl(dir_name=root, top_name=top_name)


# ---------------------------------------------------------------------------
# Subprocess execution with a hard timeout
# ---------------------------------------------------------------------------

def _terminate_process_tree(proc):
    """Kill a process and all of its children (so GHDL leaves no orphans)."""
    try:
        parent = psutil.Process(proc.pid)
    except psutil.NoSuchProcess:
        return

    children = parent.children(recursive=True)
    for child in children:
        try:
            child.terminate()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    _, alive = psutil.wait_procs(children, timeout=1)
    for child in alive:
        try:
            child.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    try:
        parent.terminate()
        parent.wait(1)
    except (psutil.NoSuchProcess, psutil.TimeoutExpired):
        try:
            parent.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass


def _worker_main(queue, func, args, kwargs):
    """Subprocess entry point: run `func`, capturing stdout/stderr and errors."""
    stdout_buffer = io.StringIO()
    stderr_buffer = io.StringIO()
    try:
        with redirect_stdout(stdout_buffer), redirect_stderr(stderr_buffer):
            func(*args, **kwargs)  # e.g. run_dir_self / run_dir_vhdl (calls vu.main())
        queue.put({
            "stdout": stdout_buffer.getvalue(),
            "stderr": stderr_buffer.getvalue(),
            "exception": None,
        })
    except BaseException as exc:  # noqa: BLE001 - we forward everything to the parent
        queue.put({
            "stdout": stdout_buffer.getvalue(),
            "stderr": stderr_buffer.getvalue() + traceback.format_exc(),
            "exception": exc,
        })


def run_callable_with_timeout(func, *args, timeout=None, **kwargs):
    """
    Run `func` in a spawned subprocess and enforce a wall-clock timeout.

    A spawned (not forked) context is used so the child does not inherit any
    VUnit/GHDL global state from the parent process.

    Returns:
        (output, exception): combined stdout+stderr text, and the exception
        raised in the worker (or None). On timeout the exception is a
        TimeoutError; if the worker dies silently it is a RuntimeError.
    """
    ctx = get_context("spawn")
    queue = ctx.Queue()
    proc = ctx.Process(target=_worker_main, args=(queue, func, args, kwargs), daemon=False)
    proc.start()
    proc.join(timeout)

    if proc.is_alive():
        _terminate_process_tree(proc)
        return "", TimeoutError(f"Function execution exceeded {timeout} seconds")

    if queue.empty():
        return "", RuntimeError("Worker exited without sending results")

    payload = queue.get()
    output = payload["stdout"] + payload["stderr"]
    return output, payload["exception"]


def capture_function_output(func, *args, **kwargs):
    """Thin wrapper around run_callable_with_timeout that pops `timeout`."""
    timeout = kwargs.pop("timeout", None)
    return run_callable_with_timeout(func, *args, timeout=timeout, **kwargs)


def kill_long_running_sim():
    """
    Safety net: kill any lingering VUnit simulation processes (tb-sim) that
    have been running longer than MAX_RUNTIME_SECONDS. Used to clean up after
    a timeout so orphaned GHDL simulations do not accumulate.
    """
    import time
    now = time.time()
    killed = []
    for proc in psutil.process_iter(["pid", "name", "create_time", "cmdline"]):
        try:
            name = proc.info.get("name", "") or ""
            cmdline = proc.info.get("cmdline") or []
            if "tb-sim" in name or any("tb-sim" in str(arg) for arg in cmdline):
                runtime = now - proc.info.get("create_time", now)
                if runtime > MAX_RUNTIME_SECONDS:
                    try:
                        proc.kill()
                        killed.append((proc.pid, runtime))
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        continue
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    if killed:
        print("Killed the following long-running tb-sim processes:")
        for pid, runtime in killed:
            print(f"  PID: {pid}, Runtime: {int(runtime)}s")
    else:
        print("No long-running tb-sim processes found.")


# ---------------------------------------------------------------------------
# Evaluation entry point
# ---------------------------------------------------------------------------

def evaluate(func, *args, **kwargs):
    """
    Run one compile+simulate job and classify the outcome.

    `func` is the simulation callable (typically `run_dir_self`) and *args /
    **kwargs are forwarded to it (e.g. the problem directory path). The job is
    executed under a hard timeout; its captured output and the testbench's
    summary.txt are then inspected to assign an issue code.

    Returns:
        (issue, result):
            issue  - integer issue code (see module docstring).
            result - human-readable message / error log for that issue,
                     suitable for feeding back to the LLM during repair.
    """
    issue = 0
    result = "Success"

    try:
        output, exception = capture_function_output(
            func, *args, **kwargs, timeout=MAX_RUNTIME_SECONDS
        )

        # Timeout while simulating.
        if isinstance(exception, TimeoutError):
            kill_long_running_sim()
            return 3, f"Timeout Error: Function exceeded {MAX_RUNTIME_SECONDS} seconds"

        with open(LOG_PATH, "w") as f:
            f.write(output)
        with open(LOG_PATH, "r") as log_file:
            text = log_file.read()

        try:
            with open("summary.txt", "r") as log_file:
                summary = log_file.read()
        except OSError:
            summary = ""

        # Primary pass/fail classification.
        if "All passed" not in output:
            issue = 1
            result = "Fail"
            if "fail" in text:
                if "compilation error" in text or summary == "":
                    # Compilation failure: return the tail after the last "passed".
                    match = re.search(r"passed(?!.*passed)", text, re.DOTALL)
                    if match:
                        result = text[match.end():].strip()
                else:
                    # Compiles & runs but functionally wrong.
                    issue = 2
                    result = summary
            else:
                result = text

        # --- Specific testbench-quality diagnostics -----------------------
        # These detect malformed *testbenches* (not the DUT) so the repair
        # loop can regenerate a correct testbench.

        # issue 5: report_process fired before all tests completed.
        if "Mismatches: 0" in summary and "fail" in text.lower():
            if "0 errors detected" in text or "Test failed: 0" in text:
                issue = 5
                result = (
                    "CRITICAL ERROR: report_process started before all tests completed.\n"
                    "The log shows 0 mismatches (functionality correct) but the test "
                    "FAILED because case_num_shared < expected_cases.\n"
                    "report_process used a FIXED delay instead of waiting for sim_done.\n"
                    "Fix: replace `wait for <fixed> ps;` with "
                    "`wait until sim_done; wait for PERIOD * 2;`"
                )

        # issue 4: sim_done ignored in verify_process (ran to fixed sample cap).
        #
        # The magic number 199999 is not arbitrary: the testbench/generator
        # templates iterate a fixed stimulus loop `for i in 1 to 200000 loop`
        # (mirroring the original Verilog `repeat(200000)`). A correct testbench
        # stops early once `sim_done` is asserted; a broken one that omits the
        # `if not sim_done then` guard instead runs the loop to completion,
        # yielding exactly 199999 counted samples. This string is therefore the
        # signature of a testbench that ignored sim_done, and pairs with the
        # sim_done guidance enforced in the system prompt (see src/prompts).
        # Kept as an exact match to reproduce the paper's evaluation behaviour;
        # if the template's loop bound changes, update this constant accordingly.
        elif "Mismatches: 0 in 199999 samples" in summary:
            issue = 4
            result = (
                "CRITICAL ERROR: sim_done signal has no effect in verify_process.\n"
                "The testbench counted exactly 199999 samples (a fixed timeout), "
                "meaning verify_process does not guard on `if not sim_done then`.\n"
                "Fix: wrap the per-clock counting logic in `if not sim_done then ... end if;`"
            )

        # issue 6: reported pass but mismatches present (inconsistent).
        elif "Mismatches: 0" not in summary and issue == 0:
            issue = 6
            result = (
                "CRITICAL ERROR: the test reported success but the summary does not "
                "show 0 mismatches (functionality is not actually correct)."
            )

    except subprocess.TimeoutExpired:
        kill_long_running_sim()
        return 3, "Timeout Error when compiling"

    return issue, result


if __name__ == "__main__":
    # Minimal self-check: simulate a single problem directory passed on the CLI.
    #   python simulation.py <path/to/problem_dir>


    kill_long_running_sim()
    with open("summary.txt", "w") as f:
        f.write("")

    target = ''

    # target = '~/experiments_TB/claude-sonnet-4.5_code_2025-11-09_02-55-52/Prob00001'
    issue, result = evaluate(run_dir_self, target)
    print(f"issue = {issue}")
    print(result)

    kill_long_running_sim()