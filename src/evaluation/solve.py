"""
VHDLSuite - Evaluation Stage: VHDL generation on VHDLBench

Measures how well a model writes VHDL from a natural-language specification.
For each problem the model receives only the refined description plus the
library declaration -- no reference design, no testbench -- and must produce a
complete VHDL entity. The result is compiled and simulated against the VHDL
testbench that the construction stage produced and verified.

    generate dut -> compile & simulate against VHDLBench's tb.vhd
                 -> classify failure -> feed the error back -> regenerate

--- How this differs from the construction stage ---

Construction *translates*: it sees the Verilog reference and testbench, and
produces both a VHDL design and a VHDL testbench. Evaluation *solves*: it sees
only prose, produces only a design, and is judged by a testbench it never sees.
Construction builds the benchmark; this measures models against it.

--- Two nested notions of "try again" ---

  Repair rounds (MAX_REPAIR_ROUNDS) happen *within* one attempt at a problem.
  Each round shows the model its own previous code and the simulator's
  complaint, so it can fix what it wrote. Defaults to 1, i.e. no repair: the
  model gets one shot, which is what the reported numbers measure.

  Runs (NUM_RUNS) are independent repetitions of the whole sweep. Each run is a
  fresh sample of the model at temperature, written to its own timestamped
  directory, and is what pass@k is estimated from. Runs never see each other.

Both benchmarks are evaluated in one invocation; see BENCHMARK_RUNS.

--- Prompt assembly ---

The task text is prompt_new.txt and declaration.txt concatenated. They are
generated and stored separately (see src/construction/refine_prompt.py) so the
declaration hint can be included or withheld independently; joining them here
keeps that choice at the evaluation boundary rather than baked into the data.

The model answers in two blocks:
    ```reason -> Prob<NNNNN>_<round>_cot.txt  (design rationale, kept for analysis)
    ```dut    -> Prob<NNNNN>_<round>.vhd      (the design under test)

Outputs are written to data/experiments/<model>_<benchmark>_<timestamp>/Prob<NNNNN>/,
one directory per run, plus a logs.jsonl recording every attempt: its issue
code, reasoning, code, and the simulator report fed back for repair.

Prerequisites:
    * GHDL + VUnit installed (see src/simulation/run.py)
    * An OpenRouter API key in key.txt at the repository root
    * A completed construction run per benchmark; list them in BENCHMARK_RUNS

Run from the repository root:

    python src/evaluation/solve.py
"""

import json
import os
import re
import sys
import time
from pathlib import Path

from openai import OpenAI
from tqdm import tqdm

# Make the repository root importable so the shared simulation module resolves
# when this file is run directly as a script.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.simulation.run import evaluate, run_dir_vhdl  # noqa: E402

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# The VHDLBench data to evaluate against, one entry per benchmark:
#
#     (benchmark name, number of problems, construction output directory)
#
# Each directory is a completed construction run holding one Prob<NNNNN>/ per
# problem, with prompt_new.txt, declaration.txt, and a verified tb.vhd. Fill in
# the timestamps from your own construction runs. Every entry listed here is
# evaluated, so drop a line to skip that benchmark.
BENCHMARK_RUNS = [
    (
        "RTLLM",
        50,
        REPO_ROOT / "data" / "experiments_TB" / "<model>_<mode>_<timestamp>",
    ),
    (
        "verilog-eval",
        156,
        REPO_ROOT / "data" / "experiments_TB" / "<model>_<mode>_<timestamp>",
    ),
]

# Where evaluation runs are written (one subdirectory per model/mode/timestamp).
EXPERIMENT_DIR = REPO_ROOT / "data" / "experiments"

# File holding the OpenRouter API key, at the repository root and excluded by
# .gitignore. Override with the VHDLSUITE_API_KEY_PATH environment variable.
API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))

API_BASE_URL = "https://openrouter.ai/api/v1"

# Maximum tokens per completion.
MAX_TOKENS = 15000

# Repair rounds within a single attempt (1 = generate once, no repair).
MAX_REPAIR_ROUNDS = 1

# Independent repetitions of the whole sweep, for pass@k estimation.
NUM_RUNS = 5

# Whether to pick up an interrupted sweep. When on, the most recent run
# directory for each model/benchmark is finished off first and counts as one of
# NUM_RUNS, with the remainder started fresh; if that directory turns out to be
# complete already, the script stops rather than guess what you meant. When off,
# all NUM_RUNS runs are started fresh regardless of what is already on disk.
RESUME_LATEST = False

# Models under evaluation, as OpenRouter model strings.
MODELS = [
    "anthropic/claude-sonnet-4.5",
    "deepseek/deepseek-v3.2-speciale",
    "google/gemini-3-pro-preview",
    "z-ai/glm-4.6v",
    "openai/gpt-5.1-codex-max",
    "x-ai/grok-4",
    "qwen/qwen3-max",
]

# Sampling parameters. Temperature is deliberately high: the reported metric is
# pass@k over NUM_RUNS independent samples, which needs diversity between runs.
TEMPERATURE = 0.85
TOP_P = 0.95

# Zero-shot: the system prompt fully specifies the task and output format.
EXAMPLE_NUM = 0

# Kept inline rather than in src/prompts/prompt.py: this is the only prompt the
# evaluation stage uses, and it defines the task being measured, so it belongs
# with the harness that reports the numbers.
SYSTEM_PROMPT = """
You are an AI assistant specialized in **VHDL code generation** and **hardware engineering**.  
Your sole objective is to **generate correct, synthesizable, and well-structured VHDL code**, following industry-standard HDL practices.

### Input Format (strict)
The user will provide:
```description
<task description>
````

### Output Format (strict)

You must respond **only** with the following two blocks:

```reason
<your reasoning: explain design choices, architecture decisions, assumptions>
```

```dut
<VHDL code for the module described above>
```

### Requirements

1. **VHDL-2008 syntax** unless otherwise specified.
2. Code must be **clean, synthesizable**, and include all required ports, types, and internal signals.
3. Avoid unnecessary verbosity; keep the reasoning concise but technically sound.
4. Do **not** generate Verilog.
5. Do **not** include anything outside the two required blocks.
"""


# ---------------------------------------------------------------------------
# Dataset access
# ---------------------------------------------------------------------------

def document_search(target_number, target_dir):
    """
    Assemble one problem's task text from the VHDLBench data.

    Concatenates the refined description and the library declaration, which are
    stored as separate files by the construction stage (see module docstring).
    Both benchmarks share this layout, so no benchmark-specific handling is
    needed here.

    Returns:
        str: the full task description shown to the model.
    """
    pattern = re.compile(rf"^Prob{target_number:05d}$")

    for file_path in target_dir.iterdir():
        if not pattern.match(file_path.name):
            continue

        print(f"Found folder: {file_path.name}")

        with open(file_path / "prompt_new.txt", "r", encoding="utf-8") as f:
            prompt = f.read()
        with open(file_path / "declaration.txt", "r", encoding="utf-8") as f:
            declaration = f.read()

        return prompt + "\n\n" + declaration

    raise FileNotFoundError(
        f"Did not find folder No. {target_number} under {target_dir}"
    )


def extract_code(text):
    """
    Pull fenced code blocks out of an LLM response.

    Returns a dict mapping the fence identifier to the block body, e.g.
    ```dut ... ``` becomes {"dut": "..."}.
    """
    pattern = r"```(\w+)\n(.*?)```"
    matches = re.findall(pattern, text, re.DOTALL)
    return {identifier: code.strip() for identifier, code in matches}


# ---------------------------------------------------------------------------
# Run directory selection
# ---------------------------------------------------------------------------

def is_run_complete(run_dir, num_problems):
    """
    Report whether a run directory already holds a finished sweep.

    A run counts as complete when every problem has at least one non-empty
    generated design. Emptiness matters: a model that returns no ```dut block
    still leaves a zero-byte .vhd behind, and treating that as done would make
    the problem unrecoverable on every later run.
    """
    for i in range(1, num_problems + 1):
        problem_dir = run_dir / f"Prob{i:05d}"
        if not problem_dir.is_dir():
            return False
        if not any(p.stat().st_size > 0 for p in problem_dir.glob("*.vhd")):
            return False
    return True


def find_resumable_run(base_dir, file_model_name, benchmark_name, num_problems):
    """
    Find the latest interrupted run for this model/benchmark, if resuming.

    Only the most recent directory is considered: an interruption can only have
    left the run that was in progress unfinished, so older directories are
    either complete runs from earlier sweeps or someone else's business.

    Raises:
        RuntimeError: if the latest run is already complete. Resuming would have
            nothing to do, and silently reusing or ignoring it would quietly
            change how many samples the results rest on -- so the ambiguity is
            handed back to the caller rather than guessed at.

    Returns:
        Path | None: the directory to resume, or None if there is nothing to
        resume (no prior runs at all).
    """
    prefix = f"{file_model_name}_{benchmark_name}_"
    existing = sorted(
        (p for p in base_dir.glob(f"{prefix}*") if p.is_dir()),
        key=lambda p: p.name,
    )

    if not existing:
        return None

    latest = existing[-1]
    if is_run_complete(latest, num_problems):
        raise RuntimeError(
            f"RESUME_LATEST is on, but the latest run {latest.name} is already "
            f"complete -- there is nothing to resume.\n"
            f"Either set RESUME_LATEST = False to start {NUM_RUNS} fresh runs, "
            f"or move/remove that directory if it should not count."
        )

    return latest


# ---------------------------------------------------------------------------
# LLM interaction
# ---------------------------------------------------------------------------

def test_once(client, model_name, prompt, examples,
              max_tokens=MAX_TOKENS, temp=TEMPERATURE, top_p=TOP_P,
              stop=["<|end▁of▁sentence|>"], stream=False,
              round_idx=0, last=None, errors=None):
    """
    Request one design from the model.

    On the first round (round_idx == 0) the model sees only the system prompt
    and the task. On later rounds its previous output and the simulator's error
    output are appended, so it repairs rather than starts over.

    Returns:
        list[str]: the raw model response(s).
    """
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]

    if examples:
        for i in range(len(examples["prompt"])):
            messages.append({"role": "user", "content": examples["prompt"][i]})
            messages.append({"role": "assistant", "content": examples["answer"][i]})

    messages.append({
        "role": "user",
        "content": "Now this is the task you need to solve: \n" + prompt,
    })

    if round_idx > 0:
        messages.append({"role": "assistant", "content": last})
        messages.append({"role": "user", "content": f"""
Here is the terminal output showing compilation errors:

{errors}

Please fix these errors and return both blocks again in the standard format (reason, dut).
"""})

    generated_codes = []
    for _ in tqdm(range(1), desc="Generating Responses", unit="sample", dynamic_ncols=True):
        response = client.chat.completions.create(
            model=model_name,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temp,
            top_p=top_p,
            stop=stop,
            stream=stream,
            n=1,
        )
        generated_codes.append(response.choices[0].message.content if response else "")

    return generated_codes


# ---------------------------------------------------------------------------
# Evaluation driver
# ---------------------------------------------------------------------------

def test_all(client, model_name, num_problems, vhdlbench_dir, run_dir, 
             max_tokens=MAX_TOKENS, temp=TEMPERATURE, top_p=TOP_P,
             stop=["<|end▁of▁sentence|>"], stream=False,
             max_repair_rounds=MAX_REPAIR_ROUNDS):
    """
    Evaluate one model across every problem in one benchmark, once.

    This is a single run: one independent sample of the model over the whole
    benchmark. Repetition for pass@k is the caller's job.

    Args:
        num_problems:  number of problems in this benchmark.
        vhdlbench_dir: construction output holding the prompts and testbenches.
        run_dir:       where this run's outputs go; resumed if already populated.

    Returns:
        (all_accuracy, logs, error_list):
            all_accuracy - [functionally correct, compiles, attempted]
            logs         - list of per-attempt log records
            error_list   - problem numbers that never reached a passing run
    """
    examples = {"prompt": [], "answer": []}

    all_accuracy = [0, 0, 0]

    # Every attempt is appended to logs.jsonl as it happens, so an interrupted
    # sweep keeps its results. Reload any existing records first.
    logs_file = run_dir / "logs.jsonl"
    logs = []
    if logs_file.exists():
        with open(logs_file, "r", encoding="utf-8") as f:
            logs = [json.loads(line) for line in f]

    error_list = []

    for i in range(1, num_problems + 1):
        description = document_search(i, vhdlbench_dir)

        prompt = f"""
## Input Format

```description
{description}
```
"""

        accuracy = [0, 0, 0]
        error_list.append(i)

        subfolder_path = run_dir / f"Prob{i:05d}"
        subfolder_path.mkdir(parents=True, exist_ok=True)

        # The testbench lives with the benchmark data, not with the model's
        # output: the model never sees it, and every model is judged against
        # the same verified testbench.
        tb_dir = vhdlbench_dir / f"Prob{i:05d}"

        last = ""
        errors = "Success"

        for round_idx in range(max_repair_rounds):
            # Each repair round writes its own attempt, so a problem's history
            # is preserved rather than overwritten.
            file_name = f"Prob{i:05d}_{round_idx + 1}"
            dut_file_path = subfolder_path / f"{file_name}.vhd"
            cot_file_path = subfolder_path / f"{file_name}_cot.txt"
            need_to_be_logged = False

            # summary.txt is written by the VHDL testbench itself into the
            # working directory; clear it so a stale file from the previous
            # round cannot be mistaken for this round's result.
            with open("summary.txt", "w") as f:
                f.write("")

            # Resume support: reuse an attempt a previous run already generated,
            # but only if it is non-empty (see is_run_complete).
            if dut_file_path.exists() and dut_file_path.stat().st_size > 0:
                print(f"{dut_file_path} has existed before generation.")
            else:
                generated_code = test_once(
                    client, model_name, prompt, examples,
                    max_tokens=max_tokens, temp=temp, top_p=top_p,
                    stop=stop, stream=stream,
                    round_idx=round_idx, last=last, errors=errors,
                )
                last = ""
                need_to_be_logged = True

                blocks = extract_code(generated_code[0])
                cot = blocks.get("reason", "")
                dut_code = blocks.get("dut", "")

                with open(dut_file_path, "w", encoding="utf-8") as f:
                    f.write(dut_code)
                with open(cot_file_path, "w", encoding="utf-8") as f:
                    f.write(cot)

            # Compile this attempt's design against the benchmark's testbench.
            issue, errors = evaluate(
                run_dir_vhdl, dir_name=tb_dir, top_name=dut_file_path
            )
            print(f"Evaluation finished. Issue Number: {issue}")

            if issue == 0:
                accuracy[0] += 1
                accuracy[1] += 1
            elif issue == 2:
                # Compiles and runs, but the simulation reports mismatches.
                # evaluate() already returns summary.txt's full contents as
                # `errors` for this issue code, so there is nothing to append.
                accuracy[1] += 1

            accuracy[2] += 1

            with open(cot_file_path, "r", encoding="utf-8") as f:
                cot_text = f.read()
            with open(dut_file_path, "r", encoding="utf-8") as f:
                dut_text = f.read()

            # Feed the failed attempt back for the next repair round.
            last += "```reason\n" + cot_text + "\n```"
            last += "```dut\n" + dut_text + "\n```"

            if "" in [cot_text, dut_text]:
                errors += (
                    "\n There's a lack of some output blocks. You should not only "
                    "fix the possible errors in the code but also add to the lacked blocks.\n"
                )

            if need_to_be_logged:
                logs.append({
                    "id": i,
                    "attempt": round_idx + 1,
                    "issue": issue,
                    "reason": cot_text,
                    "dut": dut_text,
                    "report": errors,
                })
                with open(logs_file, "a", encoding="utf-8") as f:
                    f.write(json.dumps(logs[-1], ensure_ascii=False) + "\n")

            if accuracy[0] > 0:
                error_list.pop(-1)
                break

        print(f"{model_name}, Prob{i:05d}: Ended")
        for x in range(len(all_accuracy)):
            all_accuracy[x] += 1 if accuracy[x] > 0 else 0
        print("Now the accuracy is:", all_accuracy)

    return all_accuracy, logs, error_list


def main():
    print("Start")

    key_path = Path(API_KEY_PATH).expanduser()
    if not key_path.exists():
        raise FileNotFoundError(
            f"API key file not found: {key_path}\n"
            "Write your OpenRouter key to that path, or set "
            "VHDLSUITE_API_KEY_PATH to point at it."
        )
    with open(key_path) as f:
        api_key = f.read().strip()

    client = OpenAI(api_key=api_key, base_url=API_BASE_URL)

    EXPERIMENT_DIR.mkdir(parents=True, exist_ok=True)

    print("TESTING")
    results = {}

    for benchmark_name, num_problems, vhdlbench_dir in BENCHMARK_RUNS:
        print(benchmark_name, end="\n\n\n")

        if not vhdlbench_dir.is_dir():
            raise FileNotFoundError(
                f"VHDLBench directory not found: {vhdlbench_dir}\n"
                f"Set the {benchmark_name} entry in BENCHMARK_RUNS to a "
                "completed construction output directory (see the module "
                "docstring)."
            )

        for model_name in MODELS:
            print(model_name, end="\n\n\n")

            # Strip the provider prefix so directory names stay
            # filesystem-friendly.
            if "/" in model_name:
                file_model_name = model_name[model_name.index("/") + 1:]
            else:
                file_model_name = model_name




            resume_dir = None
            if RESUME_LATEST:
                resume_dir = find_resumable_run(
                    EXPERIMENT_DIR, file_model_name, benchmark_name,
                    num_problems,
                )

            run_accuracies = []
            for run_idx in range(1, NUM_RUNS + 1):
                # The resumed run, if any, is the first: finishing it off
                # before spending on new samples means an interruption costs
                # nothing beyond what it already cost.
                if run_idx == 1 and resume_dir is not None:
                    run_dir = resume_dir
                    print(f"Run {run_idx}/{NUM_RUNS}: resuming {run_dir.name}")
                else:
                    # Two runs finishing within the same second would
                    # otherwise share a directory and silently merge.
                    while True:
                        current_time = time.strftime("%Y-%m-%d_%H-%M-%S")
                        run_dir = EXPERIMENT_DIR / (
                            f"{file_model_name}_{benchmark_name}_{current_time}"
                        )
                        if not run_dir.exists():
                            break
                        time.sleep(1)
                    print(f"Run {run_idx}/{NUM_RUNS}: starting {run_dir.name}")

                run_dir.mkdir(parents=True, exist_ok=True)

                all_accuracy, logs, error_list = test_all(
                    client, model_name, num_problems, vhdlbench_dir,
                    run_dir,
                    max_tokens=MAX_TOKENS, temp=TEMPERATURE, top_p=TOP_P,
                    max_repair_rounds=MAX_REPAIR_ROUNDS,
                )
                print(all_accuracy)
                print(error_list)
                run_accuracies.append(all_accuracy)

            results[(benchmark_name, model_name)] = run_accuracies

    print("\n=== Summary ===")
    for (benchmark_name, model_name), run_accuracies in results.items():
        print(f"{benchmark_name}, {model_name}: {run_accuracies}")


if __name__ == "__main__":
    main()