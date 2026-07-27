"""
VHDLSuite - Analysis, Stage 1: failure root-cause labeling
===========================================================

Tags every *failed* evaluation attempt with flat, free-form root-cause labels.
For each problem a model got wrong, an LLM judge compares the buggy design
against the verified golden design -- with the description, testbench, the
model's own reasoning, and the simulator error report as context -- and names
the underlying bug(s).

This is stage 1 of two:

  stage 1 (this file): each failure -> 1-3 flat snake_case root-cause labels
      (e.g. reset_polarity_mismatch), written to `chosen_labels`. Labels
      accumulate in a single growing pool so the judge reuses prior labels
      instead of coining synonyms. Output: <run>/error_type_logs.jsonl.

  stage 2 (classify_failures.py): the finished pool -> a fixed three-level
      taxonomy (six major categories, model-defined middle and minor). Runs
      once over the whole pool so cross-category duplicates are resolved
      globally rather than incrementally.

--- The label pool is dynamic and not reproducible ---

ERROR_POOL_PATH grows as problems are processed: each judged failure may add
labels the next failure then sees and can reuse. The resulting labels depend on
processing order and on the judge sampling (temperature 0.85), and will differ
between runs. The pool is a working artifact, not a fixed output -- it is
git-ignored and regenerated per run. Stage 2 is what turns whatever pool
emerged into the stable taxonomy.

--- Only failures, only the first attempt ---

The runs to label are the paper's own runs, imported from log_check.py so the
labeled set is exactly the reported set. For each run this reads logs.jsonl,
skips problems that were solved (issue 0), and labels only the first generation
(Prob<NNNNN>_1.vhd). No repair.

The buggy design is re-simulated to regenerate its error report; evaluate()
returns the full report -- including summary.txt for issue 2 -- as `errors`,
the same contract src/evaluation/solve.py relies on. The golden design,
testbench, and description come from the construction output in VHDLBENCH_DIRS.

Merged from solve_rtllm_v2_failure.py + solve_verilogeval_v2_failure.py, which
were identical apart from per-benchmark config.

Run from the repository root:

    python src/analysis/label_failures.py
"""

import json
import os
import re
import sys
from pathlib import Path

from openai import OpenAI
from tqdm import tqdm

# Make the repository root importable so the shared modules resolve when this
# file is run directly as a script (mirrors src/evaluation/solve.py).
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.simulation.run import evaluate, run_dir_vhdl  # noqa: E402
from src.analysis.log_check import (  # noqa: E402
    check_jsonl_issue_id,
    TABLES,
    EXPERIMENT_DIR,
)
from src.prompts.prompt import SYSTEM_PROMPT_v90  # noqa: E402


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# The judge/classifier model, as an OpenRouter model string. This is now a
# hyperparameter; the merged-from scripts hard-coded it inside the request.
CLASSIFIER_MODEL = "google/gemini-3-pro-preview"

# Stage 1 keeps the flat-label prompt (v90) unchanged. Swap this constant to
# point at a different version if needed.
SYSTEM_PROMPT = SYSTEM_PROMPT_v90

# Single, dynamic, git-ignored label pool shared across every run and benchmark.
# Stage 2 reads it as its input.
ERROR_POOL_PATH = REPO_ROOT / "data" / "error_pool.json"

# File holding the OpenRouter API key, at the repository root and excluded by
# .gitignore. Override with the VHDLSUITE_API_KEY_PATH environment variable.
API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))
API_BASE_URL = "https://openrouter.ai/api/v1"

# The construction output per benchmark: one Prob<NNNNN>/ per problem holding the
# refined prompt, declaration, verified tb.vhd, and golden dut.vhd. The runs
# being labeled were generated against these frozen testbenches, so the same
# directories supply the golden reference the judge compares against.
VHDLBENCH_DIRS = {
    "RTLLM": REPO_ROOT / "data" / "experiments_TB"
    / "claude-sonnet-4.5_code_2025-11-09_02-55-52",
    "verilog-eval": REPO_ROOT / "data" / "experiments_TB"
    / "claude-sonnet-4.5_code_2025-11-03_13-45-44",
}

# Judge sampling. Kept as the merged-from scripts had them.
MAX_TOKENS = 25000
TEMPERATURE = 0.85
TOP_P = 0.95


# ---------------------------------------------------------------------------
# Pool + I/O helpers
# ---------------------------------------------------------------------------

def load_error_pool(pool_path):
    """Load the flat label pool. Accepts a bare list or {"pool": [...]}."""
    if pool_path.exists():
        data = json.loads(pool_path.read_text(encoding="utf-8"))
        if isinstance(data, dict) and "pool" in data:
            return data["pool"]
        if isinstance(data, list):
            return data
    return []


def save_error_pool(pool_path, pool_list):
    pool_path.parent.mkdir(parents=True, exist_ok=True)
    pool_path.write_text(
        json.dumps({"pool": pool_list}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def append_jsonl(path, obj):
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps(obj, ensure_ascii=False) + "\n")


def safe_parse_json_object(text):
    """Grab the first JSON object from the model output (defensive: the prompt
    already constrains it to JSON-only)."""
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except Exception:
        return None


def normalize_label(label):
    """Force lowercase snake_case."""
    label = label.strip().lower()
    label = re.sub(r"[^a-z0-9]+", "_", label)
    label = re.sub(r"_+", "_", label).strip("_")
    return label


def load_done_problem_ids(jsonl_path):
    """Problem ids already recorded in a run's error_type_logs.jsonl, so an
    interrupted labeling pass resumes instead of relabeling."""
    done = set()
    if not jsonl_path.exists():
        return done
    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                pid = json.loads(line).get("problem_id")
                if isinstance(pid, int):
                    done.add(pid)
            except Exception:
                continue  # skip a bad line rather than fail the whole run
    return done


def load_reference(target_number, vhdlbench_dir):
    """
    Load one problem's judge context from the construction output.

    Returns:
        (description, testbench, golden_dut) -- description is prompt_new.txt and
        declaration.txt concatenated (the same text solve.py shows the model);
        testbench and golden_dut are the verified tb.vhd and dut.vhd.
    """
    pattern = re.compile(rf"^Prob{target_number:05d}$")

    for file_path in vhdlbench_dir.iterdir():
        if not pattern.match(file_path.name):
            continue

        print(f"Found folder: {file_path.name}")
        prompt = (file_path / "prompt_new.txt").read_text(encoding="utf-8")
        declaration = (file_path / "declaration.txt").read_text(encoding="utf-8")
        tb = (file_path / "tb.vhd").read_text(encoding="utf-8")
        golden_dut = (file_path / "dut.vhd").read_text(encoding="utf-8")
        return prompt + "\n\n" + declaration, tb, golden_dut

    raise FileNotFoundError(
        f"Did not find folder No. {target_number} under {vhdlbench_dir}"
    )


def build_judge_prompt(description, tb, golden_dut, buggy_dut, buggy_cot,
                       error_pool, errors):
    """
    Assemble the user message shown to the judge.

    Includes the model's own reasoning (buggy_cot) alongside its code: seeing
    what the model intended helps the judge separate a flawed idea from a
    correct idea implemented wrongly. The pool is passed as pretty JSON rather
    than a Python repr so it stays readable as it grows.
    """
    return f"""## Input Format

```description
{description}
```

```testbench
{tb}
```

```golden_dut
{golden_dut}
```

```buggy_dut
{buggy_dut}
```

```buggy_reasoning
{buggy_cot}
```

```error_pool
{json.dumps(error_pool, ensure_ascii=False, indent=2)}
```

```error_report
{errors}
```
"""


# ---------------------------------------------------------------------------
# Judge call
# ---------------------------------------------------------------------------

def classify_failure(client, prompt, classifier_model=CLASSIFIER_MODEL,
                     system_prompt=SYSTEM_PROMPT, max_tokens=MAX_TOKENS,
                     temp=TEMPERATURE, top_p=TOP_P):
    """One judge call: buggy design + context -> raw JSON string."""
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": prompt},
    ]

    generated = []
    for _ in tqdm(range(1), desc="Classifying failure", unit="call", dynamic_ncols=True):
        response = client.chat.completions.create(
            model=classifier_model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temp,
            top_p=top_p,
            stream=False,
            n=1,
        )
        generated.append(response.choices[0].message.content if response else "")

    return generated[0]


# ---------------------------------------------------------------------------
# Labeling driver
# ---------------------------------------------------------------------------

def label_run(client, benchmark_name, num_problems, vhdlbench_dir, run_dir,
              classifier_model=CLASSIFIER_MODEL, system_prompt=SYSTEM_PROMPT,
              max_tokens=MAX_TOKENS, temp=TEMPERATURE, top_p=TOP_P):
    """
    Label every failing problem in one run directory.

    Reads run_dir/logs.jsonl to find which problems failed, re-simulates each
    failing design to regenerate its error report, and appends the judge's
    labels to run_dir/error_type_logs.jsonl. New labels grow ERROR_POOL_PATH.

    Returns:
        int: number of failing problems labeled this call.
    """
    logs_file = run_dir / "logs.jsonl"
    error_type_logs_path = run_dir / "error_type_logs.jsonl"

    done_ids = load_done_problem_ids(error_type_logs_path)

    error_pool = load_error_pool(ERROR_POOL_PATH)
    save_error_pool(ERROR_POOL_PATH, error_pool)  # ensure the file exists

    # Maintained across the loop rather than rebuilt per problem.
    pool_set = {normalize_label(x) for x in error_pool}

    # records is one (line_no, issue, id) per problem, ordered 1..num_problems
    # (attempt_max=1 keeps single-shot only).
    logs_record = check_jsonl_issue_id(logs_file, num_problems, attempt_max=1)["records"]

    labeled = 0
    for i in range(1, num_problems + 1):
        if logs_record[i - 1][2] != i:
            raise RuntimeError(
                f"{logs_file}: problem-id misalignment at index {i} "
                f"(got id {logs_record[i - 1][2]})"
            )
        if logs_record[i - 1][1] == 0:
            continue  # solved -> nothing to label
        if i in done_ids:
            print(f"[SKIP] Prob{i:05d} already labeled.")
            continue

        description, tb, golden_dut = load_reference(i, vhdlbench_dir)

        subfolder = run_dir / f"Prob{i:05d}"
        dut_file_path = subfolder / f"Prob{i:05d}_1.vhd"
        cot_file_path = subfolder / f"Prob{i:05d}_1_cot.txt"

        # summary.txt is written by the testbench into the working directory;
        # clear it so a stale file cannot be mistaken for this run's result.
        Path("summary.txt").write_text("", encoding="utf-8")

        # Re-simulate to regenerate the report. evaluate() returns the full
        # simulator report (including summary.txt for issue 2) as `errors`,
        # the same contract solve.py uses -- so nothing is appended by hand.
        tb_dir = vhdlbench_dir / f"Prob{i:05d}"
        issue, errors = evaluate(run_dir_vhdl, dir_name=tb_dir, top_name=dut_file_path)
        print(f"Prob{i:05d}: evaluate issue={issue}")

        # Read back what the model produced. Both are exists-guarded: they were
        # written by a prior run, and a missing/empty attempt should not crash
        # labeling. The reasoning is passed to the judge; a missing code block
        # also flags the failure as an incomplete generation.
        cot_text = cot_file_path.read_text(encoding="utf-8") if cot_file_path.exists() else ""
        dut_text = dut_file_path.read_text(encoding="utf-8") if dut_file_path.exists() else ""
        if not dut_text:
            errors += (
                "\n The model produced no DUT code block for this problem; the "
                "failure is at least partly an incomplete generation.\n"
            )

        prompt = build_judge_prompt(
            description, tb, golden_dut, dut_text, cot_text, error_pool, errors
        )
        raw = classify_failure(
            client, prompt,
            classifier_model=classifier_model, system_prompt=system_prompt,
            max_tokens=max_tokens, temp=temp, top_p=top_p,
        )

        parsed = safe_parse_json_object(raw)
        if parsed is None:
            chosen = ["unparsed_classifier_output"]
            new_labels = []
        else:
            chosen = (parsed.get("chosen_labels") or [])[:3]
            new_labels = (parsed.get("new_labels_to_add") or [])[:3]
        normalized = [normalize_label(x) for x in chosen]

        # Grow the shared pool, de-duped.
        for lab in new_labels:
            nl = normalize_label(lab)
            if nl and nl not in pool_set:
                error_pool.append(nl)
                pool_set.add(nl)
        save_error_pool(ERROR_POOL_PATH, error_pool)

        append_jsonl(error_type_logs_path, {
            "problem_id": i,
            "prob_folder": f"Prob{i:05d}",
            "issue": issue,
            "labels": normalized[:3],
            "new_labels_added": [normalize_label(x) for x in new_labels][:3],
            "classifier_raw": raw[:2000],
            "error_report_preview": str(errors)[:2000],
        })
        labeled += 1
        print(f"{benchmark_name}, {run_dir.name}, Prob{i:05d}: Ended")

    print(f"[{benchmark_name}] {run_dir.name}: labeled {labeled} failing problems")
    return labeled


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

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

    # The benchmarks and their runs come from log_check.py, so the labeled set is
    # exactly the reported set.
    for benchmark_name, num_problems, table in TABLES:
        print(f"\n=== {benchmark_name} ===")

        vhdlbench_dir = VHDLBENCH_DIRS[benchmark_name]
        if not vhdlbench_dir.is_dir():
            raise FileNotFoundError(
                f"VHDLBench directory not found: {vhdlbench_dir}\n"
                f"Set the {benchmark_name} entry in VHDLBENCH_DIRS to the "
                "construction output the runs were generated against."
            )

        for row in table:
            for run_name in row:
                run_dir = EXPERIMENT_DIR / run_name
                if not (run_dir / "logs.jsonl").exists():
                    print(f"[skip] {run_name}: no logs.jsonl")
                    continue

                label_run(
                    client, benchmark_name, num_problems, vhdlbench_dir, run_dir,
                )


if __name__ == "__main__":
    main()