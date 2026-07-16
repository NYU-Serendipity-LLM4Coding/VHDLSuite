"""
VHDLSuite - Construction Stage: prompt refinement (RTLLM / VerilogEval)

Turns the Verilog-oriented problem statements of the source benchmarks into the
language-neutral prompts that VHDLBench ships. Two artifacts are produced per
design, from the same inputs but with different system prompts:

  description -> prompt_new.txt
      The source benchmarks describe their designs in Verilog terms: Verilog
      types, Verilog idioms, and occasionally the reference implementation's
      Verilog structure. Handing that text to a model and asking for VHDL leaks
      the source language into the task. This rewrite specifies the same
      hardware without presupposing Verilog.

  declaration -> declaration.txt
      A VHDL design cannot compile without the right `library` / `use` clauses:
      std_logic_1164 for the logic types, numeric_std for unsigned arithmetic
      and resize, and so on. Verilog has no equivalent, so the source
      descriptions never mention them. This produces a short paragraph naming
      the packages a design needs and why.

The two are kept in separate files rather than merged into one. Evaluation
concatenates them (see src/evaluation/), so the benchmark can be run either with
the declaration hint or without it, and the hint's contribution measured
separately.

Deliberately excluded from the model's input: the testbench, in either language.
An earlier revision of the description task did supply it, but a description
written with the testbench in view can encode the exact stimulus and expected
values, leaking the evaluation signal into the prompt later used to *solve* the
problem.

No simulation runs here. Both outputs are prose, not code, so there is nothing
to compile or verify -- this stage only calls the model and writes the result.

Input  (per problem, from the translation stage's output directory):
    original_prompt.txt  - the source benchmark's original description
    original_ref.sv      - the source benchmark's Verilog reference design
    dut.vhd              - the VHDL design produced by the translation stage
Output (written back into the same directory):
    prompt_new.txt       - refined, language-neutral description
    declaration.txt      - prose naming the required VHDL libraries

Prerequisites:
    * A completed translation run per benchmark; list them in BENCHMARK_RUNS below.
    * An OpenRouter API key in key.txt at the repository root.

Every benchmark listed in BENCHMARK_RUNS is processed, both tasks each. Outputs
that already exist are skipped, so re-running after an interruption resumes
rather than regenerating.

Run from the repository root:

    python src/construction/refine_prompt.py
"""

import os
import re
import sys
from pathlib import Path

from openai import OpenAI
from tqdm import tqdm

# Make the repository root importable so the shared prompt module resolves when
# this file is run directly as a script.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.prompts.prompt import *  # noqa: E402,F403

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# The translation runs to refine, one entry per source benchmark:
#
#     (benchmark name, number of designs, translation output directory)
#
# Each directory is a completed translation run holding one Prob<NNNNN>/ per
# design; this stage writes its outputs back into those same directories, so the
# paths must point at real runs rather than fresh timestamps. Fill in the
# timestamps from your own translate.py runs. Every entry listed here is
# processed, so drop a line to skip that benchmark.
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

# The two refinement tasks, each mapping to (system prompt, output filename).
# Both read the same inputs and differ only in what the model is asked to write.
# The prompts are shared across benchmarks: the task -- restate this design
# without Verilog assumptions / name the VHDL libraries it needs -- does not
# depend on which benchmark the design came from.
TASKS = {
    "description": (SYSTEM_PROMPT_v123, "prompt_new.txt"),    # noqa: F405
    "declaration": (SYSTEM_PROMPT_v1242, "declaration.txt"),  # noqa: F405
}

# File holding the OpenRouter API key, at the repository root and excluded by
# .gitignore. Override with the VHDLSUITE_API_KEY_PATH environment variable.
API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))

API_BASE_URL = "https://openrouter.ai/api/v1"

# Maximum tokens per completion.
MAX_TOKENS = 15000


# ---------------------------------------------------------------------------
# Dataset access
# ---------------------------------------------------------------------------

def document_search(target_number, target_dir):
    """
    Locate one problem directory inside a translation run.

    Unlike the translation stage -- which reads each source benchmark's own
    layout -- this stage reads the directories the translation stage emitted,
    named simply Prob<NNNNN>. That layout is the same for both benchmarks, so
    no benchmark-specific handling is needed here.

    Returns:
        (description, ref_path, new_ref_path):
            description  - contents of original_prompt.txt
            ref_path     - Path to original_ref.sv (Verilog reference)
            new_ref_path - Path to dut.vhd (translated VHDL design)
    """
    pattern = re.compile(rf"^Prob{target_number:05d}$")

    for file_path in target_dir.iterdir():
        if not pattern.match(file_path.name):
            continue

        print(f"Found folder: {file_path.name}")

        with open(file_path / "original_prompt.txt", "r", encoding="utf-8") as f:
            description = f.read()

        return description, file_path / "original_ref.sv", file_path / "dut.vhd"

    raise FileNotFoundError(
        f"Did not find folder No. {target_number} under {target_dir}"
    )


# ---------------------------------------------------------------------------
# LLM interaction
# ---------------------------------------------------------------------------

def test_once(client, model_name, system_prompt, prompt, examples,
              max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
              stop=["<|end▁of▁sentence|>"], stream=False):
    """
    Request one refinement from the model.

    Single-shot: unlike the translation stage there is no repair loop, since
    prose cannot be compiled and so yields no error signal to feed back.

    Returns:
        list[str]: the raw model response(s).
    """
    messages = [{"role": "system", "content": system_prompt}]

    if examples:
        for i in range(len(examples["prompt"])):
            messages.append({"role": "user", "content": examples["prompt"][i]})
            messages.append({"role": "assistant", "content": examples["answer"][i]})

    messages.append({
        "role": "user",
        "content": "Now this is the task you need to solve: \n" + prompt,
    })

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
# Refinement driver
# ---------------------------------------------------------------------------

def test_all(client, model_name, benchmark_name, num_problems, run_dir, task_name,
             max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
             stop=["<|end▁of▁sentence|>"], stream=False):
    """
    Run one refinement task over every design in one translation run.

    Each problem's output is written back into its own directory. Problems whose
    output file already exists and is non-empty are skipped, so an interrupted
    sweep can be resumed without paying for repeated generations.

    Args:
        num_problems: number of designs in this benchmark.
        run_dir:      the translation output directory to refine in place.
        task_name:    key into TASKS, selecting the system prompt and output file.

    Returns:
        list[int]: problem numbers whose generation produced empty output.
    """
    # Zero-shot: the system prompts fully specify both tasks, so no worked
    # examples are supplied.
    examples = {"prompt": [], "answer": []}

    system_prompt, output_filename = TASKS[task_name]

    if not run_dir.is_dir():
        raise FileNotFoundError(
            f"Translation run directory not found: {run_dir}\n"
            f"Set the {benchmark_name} entry in BENCHMARK_RUNS to a completed "
            "translation output directory (see the module docstring)."
        )

    error_list = []

    for i in range(1, num_problems + 1):
        description, ref_file, new_ref_file = document_search(i, run_dir)

        with open(ref_file, "r", encoding="utf-8") as f:
            ref_file_code = f.read()
        with open(new_ref_file, "r", encoding="utf-8") as f:
            new_ref_file_code = f.read()

        # The model sees the original description, the Verilog reference, and
        # the VHDL translation -- but never a testbench (see module docstring).
        prompt = f"""
## Input Format

```old_description
{description}
```
```old_ref
{ref_file_code}
```
```new_ref
{new_ref_file_code}
```
"""

        target = run_dir / f"Prob{i:05d}" / output_filename

        # Resume support: keep any output a previous run already produced.
        if target.exists():
            with open(target, "r") as f:
                existing = f.read()
            if existing.strip():
                print(f"{target} already exists; skipping generation.")
                continue

        generated_code = test_once(
            client, model_name, system_prompt, prompt, examples,
            max_tokens=max_tokens, temp=temp, top_p=top_p,
            stop=stop, stream=stream,
        )

        with open(target, "w", encoding="utf-8") as f:
            f.write(generated_code[0])

        if not generated_code[0].strip():
            print(f"Warning: empty {task_name} for Prob{i:05d}")
            error_list.append(i)

        print(f"{model_name}, {benchmark_name}, {task_name}, Prob{i:05d}: Ended")

    return error_list


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

    models = ["anthropic/claude-sonnet-4.5"]


    print("TESTING")
    for model_name in models:
        print(model_name, end="\n\n\n")
       

        for benchmark_name, num_problems, run_dir in BENCHMARK_RUNS:
            print(benchmark_name, end="\n\n\n")

            for task_name in TASKS:
                print(task_name, end="\n\n\n")
                error_list = test_all(
                    client, model_name, benchmark_name, num_problems,
                    run_dir, task_name,
                    max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
                )
                if error_list:
                    print(
                        f"{benchmark_name}: problems with empty "
                        f"{task_name}:", error_list
                    )
                else:
                    print(f"{benchmark_name}: all {task_name} outputs generated.")


if __name__ == "__main__":
    main()