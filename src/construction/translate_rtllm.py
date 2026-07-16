"""
VHDLSuite - Construction Stage: Verilog -> VHDL translation (RTLLM)

Translates each RTLLM design into VHDL via an LLM, then verifies the result
with a simulation-driven repair loop:

    generate -> compile & simulate (GHDL/VUnit) -> classify failure
             -> feed the error back to the model -> regenerate

The loop runs at most MAX_REPAIR_ROUNDS times per design. Note this is a
*repair* budget, not pass@k sampling: each round is a fresh attempt that has
seen the previous attempt's code and its simulator errors.

For each design the model is asked to emit two VHDL code blocks:
    ```testbench  -> tb.vhd   (VHDL port of the RTLLM Verilog testbench)
    ```dut        -> dut.vhd  (VHDL port of the verified reference design)

Outputs are written to data/experiments_TB/<model>_<timestamp>/Prob<NNNNN>/,
one directory per design, containing the original Verilog inputs alongside the
generated VHDL and a logs.log summary.

Prerequisites:
    * data/RTLLM_merged_folders/ populated by src/preprocessing/rtllm_data_management.py
    * GHDL + VUnit installed (see src/simulation/run.py)
    * An OpenRouter API key (see API_KEY_PATH below)

Run from the repository root:

    python src/construction/translate_rtllm.py
"""

import os
import re
import sys
import time
from pathlib import Path

from openai import OpenAI
from tqdm import tqdm

# Make the repository root importable so the shared prompt/simulation modules
# resolve when this file is run directly as a script.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.prompts.prompt import *              # noqa: E402,F403
from src.prompts.TB_examples_RTLLM import *   # noqa: E402,F403
from src.simulation.run import evaluate, run_dir_self  # noqa: E402

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# Flattened RTLLM problems produced by the preprocessing stage.
RTLLM_DATA_DIR = REPO_ROOT / "data" / "RTLLM_merged_folders"

# File holding the OpenRouter API key, at the repository root and excluded by
# .gitignore. Override with the VHDLSUITE_API_KEY_PATH environment variable.
API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))

API_BASE_URL = "https://openrouter.ai/api/v1"

# Number of RTLLM designs (RTLLM v2.0 ships 50).
# NUM_PROBLEMS = 50
NUM_PROBLEMS = 1

# Maximum tokens per completion. Translations of large testbenches are long,
# so this is well above a typical code-generation budget.
MAX_TOKENS = 15000

# Maximum generate->simulate->repair rounds per design.
MAX_REPAIR_ROUNDS = 5

SYSTEM_PROMPT = SYSTEM_PROMPT_v116  # noqa: F405


# ---------------------------------------------------------------------------
# Dataset access
# ---------------------------------------------------------------------------

def document_search(benchmark_name, target_number):
    """
    Locate one RTLLM design by its problem number.

    Expects the flattened layout produced by the preprocessing stage, where
    each design directory is named Prob<NNN>_<category>_<group>_<design>.

    Returns:
        (tb_name, prompt, ref_name):
            tb_name  - Path to the Verilog testbench (testbench.v)
            prompt   - contents of design_description.txt
            ref_name - Path to the verified Verilog reference design
    """
    if benchmark_name != "RTLLM":
        raise ValueError(f"Unsupported benchmark: {benchmark_name}")

    pattern = re.compile(rf"^Prob{target_number:03d}_.*$")

    for file_path in RTLLM_DATA_DIR.iterdir():
        if not pattern.match(file_path.name):
            continue

        print(f"Found folder: {file_path.name}")
        tb_name = file_path / "testbench.v"

        with open(file_path / "design_description.txt", "r", encoding="utf-8") as f:
            prompt = f.read()

        ref_name = None
        for sub_file_path in file_path.iterdir():
            if "verified" in sub_file_path.name:
                ref_name = sub_file_path
        if ref_name is None:
            raise FileNotFoundError(
                f"No verified reference design in {file_path.name}"
            )

        return tb_name, prompt, ref_name

    raise FileNotFoundError(
        f"Did not find folder No. {target_number} under {RTLLM_DATA_DIR}"
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
# LLM interaction
# ---------------------------------------------------------------------------

def test_once(client, model_name, prompt, examples,
              max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
              stop=["<|end▁of▁sentence|>"], stream=False,
              round_idx=0, last=None, errors=None):
    """
    Request one translation from the model.

    On the first round (round_idx == 0) the model sees only the system prompt,
    the few-shot examples, and the task. On later rounds its previous output
    and the simulator's error output are appended, so it repairs rather than
    starts over.

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

Please fix these errors and return both VHDL code blocks again in the standard format (testbench, dut).
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
# Translation driver
# ---------------------------------------------------------------------------

def test_all(client, model_name, benchmark_name,
             max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
             stop=["<|end▁of▁sentence|>"], stream=False,
             max_repair_rounds=MAX_REPAIR_ROUNDS):
    """
    Translate every RTLLM design, repairing each until it simulates or the
    repair budget is exhausted.

    Returns:
        (all_accuracy, logs, error_list):
            all_accuracy - [functionally correct, compiles, attempted]
            logs         - newline-joined per-design log lines
            error_list   - problem numbers that never reached a passing run
    """
    # A single few-shot example: the full Verilog->VHDL translation of one
    # RTLLM design, demonstrating the expected two-block output format.
    examples = {"prompt": [example1_input], "answer": [example1_output]}  # noqa: F405

    all_accuracy = [0, 0, 0]

    base_experiment_dir = REPO_ROOT / "data" / "experiments_TB"
    base_experiment_dir.mkdir(parents=True, exist_ok=True)

    current_time = time.strftime("%Y-%m-%d_%H-%M-%S")

    # Strip the provider prefix so directory names stay filesystem-friendly.
    if "/" in model_name:
        file_model_name = model_name[model_name.index("/") + 1:]
    else:
        file_model_name = model_name

    folder_name = base_experiment_dir / f"{file_model_name}_rtll_{current_time}"
    folder_name.mkdir(parents=True, exist_ok=True)

    error_list = []
    logs = []

    for i in range(1, NUM_PROBLEMS + 1):
        test_file, description, ref_file = document_search(benchmark_name, i)

        with open(test_file, "r", encoding="utf-8") as f:
            test_file_code = f.read()
        with open(ref_file, "r", encoding="utf-8") as f:
            ref_file_code = f.read()

        prompt = f"""
## Input Format

```description
{description}
```

```testbench
{test_file_code}
```
```reference
{ref_file_code}
```
"""

        accuracy = [0, 0, 0]
        error_list.append(i)

        subfolder_path = folder_name / f"Prob{i:05d}"
        subfolder_path.mkdir(parents=True, exist_ok=True)

        # Preserve the original Verilog inputs next to the generated VHDL so
        # each problem directory is self-contained for later inspection.
        with open(subfolder_path / "original_ref.sv", "w", encoding="utf-8") as f:
            f.write(ref_file_code)
        with open(subfolder_path / "original_test.sv", "w", encoding="utf-8") as f:
            f.write(test_file_code)
        with open(subfolder_path / "original_prompt.txt", "w", encoding="utf-8") as f:
            f.write(description)

        dut_file_path = subfolder_path / "dut.vhd"
        tb_file_path = subfolder_path / "tb.vhd"

        last = ""
        errors = "Success"
        issue = 0

        for round_idx in range(max_repair_rounds):
            # summary.txt is written by the VHDL testbench itself into the
            # working directory; clear it so a stale file from the previous
            # round cannot be mistaken for this round's result.
            with open("summary.txt", "w") as f:
                f.write("")

            # Regenerate unless a previous run already produced a passing dut
            # (supports resuming an interrupted sweep).
            if not dut_file_path.exists() or issue:
                generated_code = test_once(
                    client, model_name, prompt, examples,
                    max_tokens=max_tokens, temp=temp, top_p=top_p,
                    stop=stop, stream=stream,
                    round_idx=round_idx, last=last, errors=errors,
                )
                last = ""

                blocks = extract_code(generated_code[0])
                testbench_code = blocks.get("testbench", "")
                dut_code = blocks.get("dut", "")

                with open(dut_file_path, "w", encoding="utf-8") as f:
                    f.write(dut_code)
                with open(tb_file_path, "w", encoding="utf-8") as f:
                    f.write(testbench_code)
            else:
                print(f"{subfolder_path} already has generated output; skipping generation.")

            issue, errors = evaluate(run_dir_self, subfolder_path)
            print(f"Evaluation finished. Issue Number: {issue}")

            if issue == 0:
                accuracy[0] += 1
                accuracy[1] += 1
            elif issue == 2:
                # Compiles and runs, but the simulation reports mismatches.
                # evaluate() already returns summary.txt's full contents as
                # `errors` for this issue code, so there is nothing to append.
                # (An earlier version re-read summary.txt here and appended it
                # again; the re-read was both redundant and inert, since it
                # called f.read() after f.readlines() had already consumed the
                # file, so the appended text was always empty.)
                accuracy[1] += 1
                if not errors.strip():
                    print("\nThere's even no summary.txt.")
                    errors += "\n\nThe TB doesn't even generate summary.txt."

            accuracy[2] += 1

            if accuracy[0] > 0:
                error_list.pop(-1)
                break

            # Feed the failed attempt back for the next repair round.
            with open(tb_file_path, "r", encoding="utf-8") as f:
                tb_text = f.read()
                last += "```testbench\n" + tb_text + "\n```"
            with open(dut_file_path, "r", encoding="utf-8") as f:
                dut_text = f.read()
                last += "```dut\n" + dut_text + "\n```"

            if "" in [tb_text, dut_text]:
                errors += (
                    "\n There's a lack of some output blocks. You should not only "
                    "fix the possible errors in the code but also add to the lacked blocks.\n"
                )

        log_line = f"{model_name}, Prob{i:05d}: Ended"
        print(log_line)
        logs.append(log_line)

        for x in range(len(all_accuracy)):
            all_accuracy[x] += 1 if accuracy[x] > 0 else 0
        print("Now the accuracy is:", all_accuracy)

    logs = "\n".join(logs)
    with open(folder_name / "logs.log", "w") as f:
        f.write(logs)
        f.write("\n")
        for value in all_accuracy:
            f.write(str(value) + "\n")

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

    models = ["anthropic/claude-sonnet-4.5"]
    benchmark_name = "RTLLM"

    print("TESTING")
    for model_name in models:
        print(model_name, end="\n\n\n")

        all_accuracy, logs, error_list = test_all(
            client, model_name, benchmark_name,
            max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
            max_repair_rounds=MAX_REPAIR_ROUNDS,
        )
        print(all_accuracy)
        print(error_list)


if __name__ == "__main__":
    main()