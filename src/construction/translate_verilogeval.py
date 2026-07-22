"""
VHDLSuite - Construction Stage: Verilog -> VHDL translation (VerilogEval)

Translates each VerilogEval problem into VHDL via an LLM, then verifies the
result with a simulation-driven repair loop:

    generate -> compile & simulate (GHDL/VUnit) -> classify failure
             -> feed the error back to the model -> regenerate

The loop runs at most MAX_REPAIR_ROUNDS times per problem. Note this is a
*repair* budget, not pass@k sampling: each round is a fresh attempt that has
seen the previous attempt's code and its simulator errors.

--- Why this is separate from translate_rtllm.py ---

The two source benchmarks differ in more than scale:

  * Layout. RTLLM ships one directory per design; VerilogEval ships a flat
    directory of files whose companions are found by name
    (Prob001_zero_prompt.txt, _ref.sv, _test.sv). Hence no preprocessing step
    for VerilogEval -- document_search below reads the upstream layout directly.

  * Output shape. RTLLM designs are translated as two blocks (testbench, dut).
    VerilogEval testbenches separate stimulus generation from checking, so four
    blocks are required (stimulus, testbench, reference, dut) -> gen.vhd, tb.vhd,
    ref.vhd, dut.vhd.

  * Prompting. Different system prompt, and three few-shot examples rather than
    one.

Merging the two would mean branching on the benchmark at nearly every step, so
they are kept apart.

Outputs are written to data/experiments_TB/<model>_<mode>_<timestamp>/Prob<NNNNN>/,
one directory per problem, containing the original Verilog inputs alongside the
generated VHDL, plus a logs.jsonl recording every attempt: its issue code, the
code it produced, and the simulator report fed back for repair.

Prerequisites:
    * GHDL + VUnit installed (see src/simulation/run.py)
    * An OpenRouter API key in key.txt at the repository root
    * VerilogEval; downloaded automatically on first run (see download_verilogeval)

Run from the repository root:

    python src/construction/translate_verilogeval.py
"""

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from openai import OpenAI
from tqdm import tqdm

# Make the repository root importable so the shared prompt/simulation modules
# resolve when this file is run directly as a script.
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.prompts.prompt import *                   # noqa: E402,F403
from src.prompts.TB_examples_VerilogEval import *  # noqa: E402,F403
from src.simulation.run import evaluate, run_dir_self  # noqa: E402

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# Upstream VerilogEval benchmark.
VERILOGEVAL_REPO = "https://github.com/NVlabs/verilog-eval"
VERILOGEVAL_DIR = REPO_ROOT / "data" / "verilog-eval"

# Pinned commit for reproducibility: cloning plain `main` would drift as
# upstream changes, altering the problem set and file layout this stage assumes.
VERILOGEVAL_COMMIT = "c498220d0a52248f8e3fdffe279075215bde2da6"

# File holding the OpenRouter API key, at the repository root and excluded by
# .gitignore. Override with the VHDLSUITE_API_KEY_PATH environment variable.
API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))

API_BASE_URL = "https://openrouter.ai/api/v1"

# Number of VerilogEval problems (both task variants ship the same 156).
NUM_PROBLEMS = 156

# Maximum tokens per completion. Translations of large testbenches are long,
# so this is well above a typical code-generation budget.
MAX_TOKENS = 15000

# Maximum generate->simulate->repair rounds per problem.
MAX_REPAIR_ROUNDS = 5

# Number of few-shot examples drawn from TB_examples_VerilogEval.
EXAMPLE_NUM = 3

SYSTEM_PROMPT = SYSTEM_PROMPT_v022  # noqa: F405


# ---------------------------------------------------------------------------
# Dataset acquisition
# ---------------------------------------------------------------------------

def download_verilogeval(dest=VERILOGEVAL_DIR):
    """Clone the VerilogEval benchmark at the pinned commit, unless present."""
    if dest.exists():
        print(f"{dest} already exists, skipping download")
        return

    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Cloning {VERILOGEVAL_REPO} -> {dest}")
    subprocess.run(["git", "clone", VERILOGEVAL_REPO, str(dest)], check=True)
    print(f"Checking out pinned commit {VERILOGEVAL_COMMIT}")
    subprocess.run(
        ["git", "checkout", VERILOGEVAL_COMMIT], cwd=str(dest), check=True
    )
    print("Download complete")


# ---------------------------------------------------------------------------
# Dataset access
# ---------------------------------------------------------------------------

def document_search(benchmark_name, mode_name, target_number, dataset_dir):
    """
    Locate one VerilogEval problem by its number.

    VerilogEval stores each problem as a set of sibling files sharing a stem,
    e.g. Prob001_zero_prompt.txt / _ref.sv / _test.sv. Only the prompt file's
    number is known up front, so it is matched first and the companions are
    derived from its name.

    Returns:
        (test_path, ref_path, prompt):
            test_path - Path to the Verilog testbench (_test.sv)
            ref_path  - Path to the reference design (_ref.sv)
            prompt    - contents of the problem description (_prompt.txt)
    """
    if benchmark_name != "verilog-eval":
        raise ValueError(f"Unsupported benchmark: {benchmark_name}")

    target_dir = dataset_dir / f"dataset_{mode_name}"
    pattern = re.compile(rf"^Prob{target_number:03d}_.*_prompt\.txt$")

    for file_path in target_dir.iterdir():
        if not pattern.match(file_path.name):
            continue

        print(f"Found document: {file_path.name}")
        with open(file_path, "r", encoding="utf-8") as f:
            prompt = f.read()

        # Companions share the prompt file's stem: strip "prompt.txt" (10 chars)
        # and append the sibling suffix.
        stem = file_path.name[:-10]
        return (
            target_dir / (stem + "test.sv"),
            target_dir / (stem + "ref.sv"),
            prompt,
        )

    raise FileNotFoundError(
        f"Did not find prompt document No. {target_number} under {target_dir}"
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

Please fix these errors and return all four VHDL code blocks again in the standard format (stimulus, testbench, reference, dut).
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

def test_all(client, model_name, benchmark_name, mode_name, example_num=EXAMPLE_NUM,
             max_tokens=MAX_TOKENS, temp=0.85, top_p=0.95,
             stop=["<|end▁of▁sentence|>"], stream=False,
             max_repair_rounds=MAX_REPAIR_ROUNDS):
    """
    Translate every VerilogEval problem, repairing each until it simulates or
    the repair budget is exhausted.

    Returns:
        (all_accuracy, logs, error_list):
            all_accuracy - [functionally correct, compiles, attempted]
            logs         - newline-joined per-problem log lines
            error_list   - problem numbers that never reached a passing run
    """
    examples = {
        "prompt": [example1_input, example2_input, example3_input],    # noqa: F405
        "answer": [example1_output, example2_output, example3_output],  # noqa: F405
    }
    if example_num > len(examples["prompt"]):
        raise ValueError(
            f"example_num={example_num} exceeds the "
            f"{len(examples['prompt'])} available examples."
        )
    examples["prompt"] = examples["prompt"][:example_num]
    examples["answer"] = examples["answer"][:example_num]

    all_accuracy = [0, 0, 0]

    base_experiment_dir = REPO_ROOT / "data" / "experiments_TB"
    base_experiment_dir.mkdir(parents=True, exist_ok=True)

    current_time = time.strftime("%Y-%m-%d_%H-%M-%S")

    # Strip the provider prefix so directory names stay filesystem-friendly.
    if "/" in model_name:
        file_model_name = model_name[model_name.index("/") + 1:]
    else:
        file_model_name = model_name

    folder_name = base_experiment_dir / f"{file_model_name}_{mode_name[:4]}_{current_time}"
    folder_name.mkdir(parents=True, exist_ok=True)

    error_list = []

    # Every attempt is appended to logs.jsonl as it happens, so an interrupted
    # sweep keeps its results. Reload any existing records first.
    logs_file = folder_name / "logs.jsonl"
    logs = []
    if logs_file.exists():
        with open(logs_file, "r", encoding="utf-8") as f:
            logs = [json.loads(line) for line in f]

    for i in range(1, NUM_PROBLEMS + 1):
        test_file, ref_file, description = document_search(
            benchmark_name, mode_name, i, VERILOGEVAL_DIR
        )

        with open(test_file, "r", encoding="utf-8") as f:
            test_file_code = f.read()
        with open(ref_file, "r", encoding="utf-8") as f:
            ref_file_code = f.read()

        prompt = f"""
## Input Format

```reference
{ref_file_code}
```

```description
{description}
```

```testbench
{test_file_code}
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
        gen_file_path = subfolder_path / "gen.vhd"
        tb_file_path = subfolder_path / "tb.vhd"
        ref_vhd_path = subfolder_path / "ref.vhd"

        last = ""
        errors = "Success"
        issue = 0

        for round_idx in range(max_repair_rounds):
            need_to_be_logged = False

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
                need_to_be_logged = True

                blocks = extract_code(generated_code[0])
                stimulus_code = blocks.get("stimulus", "")
                testbench_code = blocks.get("testbench", "")
                reference_code = blocks.get("reference", "")
                dut_code = blocks.get("dut", "")

                with open(dut_file_path, "w", encoding="utf-8") as f:
                    f.write(dut_code)
                with open(ref_vhd_path, "w", encoding="utf-8") as f:
                    f.write(reference_code)
                with open(tb_file_path, "w", encoding="utf-8") as f:
                    f.write(testbench_code)
                with open(gen_file_path, "w", encoding="utf-8") as f:
                    f.write(stimulus_code)
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
                accuracy[1] += 1

            accuracy[2] += 1

            # Read back what this round produced: needed both for the log record
            # and, on failure, to show the model its own work in the next round.
            with open(gen_file_path, "r", encoding="utf-8") as f:
                gen_text = f.read()
            with open(tb_file_path, "r", encoding="utf-8") as f:
                tb_text = f.read()
            with open(ref_vhd_path, "r", encoding="utf-8") as f:
                ref_text = f.read()
            with open(dut_file_path, "r", encoding="utf-8") as f:
                dut_text = f.read()

            # Append rather than assign: an earlier revision overwrote `errors`
            # here, discarding the simulator output the model needs to repair.
            if "" in [gen_text, tb_text, ref_text, dut_text]:
                errors += (
                    "\n There's a lack of some output blocks. You should not only "
                    "fix the possible errors in the code but also add to the lacked blocks.\n"
                )

            if need_to_be_logged:
                logs.append({
                    "id": i,
                    "attempt": round_idx + 1,
                    "issue": issue,
                    "stimulus": gen_text,
                    "testbench": tb_text,
                    "reference": ref_text,
                    "dut": dut_text,
                    "report": errors,
                })
                with open(logs_file, "a", encoding="utf-8") as f:
                    f.write(json.dumps(logs[-1], ensure_ascii=False) + "\n")

            if accuracy[0] > 0:
                error_list.pop(-1)
                break

            # Feed the failed attempt back for the next repair round.
            last += "```stimulus\n" + gen_text + "\n```"
            last += "```testbench\n" + tb_text + "\n```"
            last += "```reference\n" + ref_text + "\n```"
            last += "```dut\n" + dut_text + "\n```"

        print(f"{model_name}, {mode_name}, Prob{i:05d}: Ended")

        for x in range(len(all_accuracy)):
            all_accuracy[x] += 1 if accuracy[x] > 0 else 0
        print("Now the accuracy is:", all_accuracy)

    return all_accuracy, logs, error_list


def main():
    print("Start")

    download_verilogeval()

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
    benchmark_name = "verilog-eval"
    mode_list = ["code-complete-iccad2023"]

    print("TESTING")
    for model_name in models:
        print(model_name, end="\n\n\n")
        for mode_name in mode_list:
            print(mode_name, end="\n\n\n")
            if mode_name not in ("code-complete-iccad2023", "spec-to-rtl"):
                raise ValueError(f"Unsupported mode: {mode_name}")

            all_accuracy, logs, error_list = test_all(
                client, model_name, benchmark_name, mode_name,
                example_num=EXAMPLE_NUM, max_tokens=MAX_TOKENS,
                temp=0.85, top_p=0.95, max_repair_rounds=MAX_REPAIR_ROUNDS,
            )
            print(all_accuracy)
            print(error_list)


if __name__ == "__main__":
    main()