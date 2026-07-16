"""
VHDLSuite - Analysis: pass@k and problem difficulty from evaluation logs

Reads the logs.jsonl that src/evaluation/solve.py writes and reports, per model:

  * per-run outcome counts -- [correct, compiles, attempted]
  * pass@1 / pass@3 / pass@5 -- a problem counts as passed at k if any of the
    first k independent runs solved it
  * insoluble problems -- never solved by this model in any run
  * super-insoluble problems -- never solved by *any* model, which is the set
    worth inspecting by hand: either genuinely hard, or a flaw in the benchmark

and, across all models, a difficulty split by aggregate pass rate.

--- Why runs are listed explicitly ---

TABLE_RTLLM and TABLE_VERILOGEVAL name the exact run directories behind the
paper's results, rather than scanning data/experiments/ for whatever is there.
A sweep leaves behind aborted runs, retries, and experiments from other
configurations; globbing would silently fold those into the numbers. Naming the
runs makes the reported figures reproducible and auditable.

These names are the paper's own runs, produced before the output directories
were renamed to <model>_<benchmark>_<timestamp>; hence the older `code` segment.
To analyse your own sweep, replace them with your run directory names.

--- pass@k here is the max-over-runs kind ---

Each run is one independent sample of a model over the whole benchmark. pass@k
asks whether any of the first k runs solved a problem -- so the ordering within
each row matters, and rows must hold at least k entries for pass@k to be
reported.

Run from the repository root:

    python src/analysis/log_check.py
"""

import json
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# Where evaluation runs live (see src/evaluation/solve.py).
EXPERIMENT_DIR = REPO_ROOT / "data" / "experiments"

# Aggregate pass-rate thresholds for the difficulty split. A problem is easy if
# more than EASY_RATE of all runs across all models solved it, hard if at most
# HARD_RATE did, medium in between.
EASY_RATE, HARD_RATE = 0.8, 0.4

# Repair rounds to count. The logs record every round, so this filters after the
# fact: 1 measures single-shot generation (the paper's main result), higher
# values measure how much simulator feedback helps.
ATTEMPT_MAX = 1

# Run directories behind the paper's results, one row per model, ordered by run.
TABLE_RTLLM = [
    ['claude-sonnet-4.5_code_2026-01-05_13-48-59', 'claude-sonnet-4.5_code_2026-01-05_22-32-16', 'claude-sonnet-4.5_code_2026-01-06_07-19-40', 'claude-sonnet-4.5_code_2026-01-06_19-02-42', 'claude-sonnet-4.5_code_2026-01-07_03-37-37'],
    ['deepseek-v3.2-speciale_code_2026-01-05_14-08-17', 'deepseek-v3.2-speciale_code_2026-01-05_22-56-12', 'deepseek-v3.2-speciale_code_2026-01-06_07-43-29', 'deepseek-v3.2-speciale_code_2026-01-06_19-21-59', 'deepseek-v3.2-speciale_code_2026-01-07_03-57-00'],
    ['gemini-3-pro-preview_code_2026-01-05_17-52-55', 'gemini-3-pro-preview_code_2026-01-06_02-11-08', 'gemini-3-pro-preview_code_2026-01-06_11-18-19', 'gemini-3-pro-preview_code_2026-01-06_22-38-09', 'gemini-3-pro-preview_code_2026-01-07_17-33-24'],
    ['glm-4.6v_code_2026-01-05_18-36-27', 'glm-4.6v_code_2026-01-06_03-01-21', 'glm-4.6v_code_2026-01-06_12-11-39', 'glm-4.6v_code_2026-01-06_23-19-12', 'glm-4.6v_code_2026-01-07_18-14-46'],
    ['gpt-5.1-codex-max_code_2026-01-05_19-33-56', 'gpt-5.1-codex-max_code_2026-01-06_04-02-13', 'gpt-5.1-codex-max_code_2026-01-06_13-00-58', 'gpt-5.1-codex-max_code_2026-01-07_00-10-18', 'gpt-5.1-codex-max_code_2026-01-07_18-56-19'],
    ['grok-4_code_2026-01-05_19-58-02', 'grok-4_code_2026-01-06_04-39-46', 'grok-4_code_2026-01-06_16-00-27', 'grok-4_code_2026-01-07_00-30-37', 'grok-4_code_2026-01-07_19-16-02'],
    ['qwen3-max_code_2026-01-05_21-49-47', 'qwen3-max_code_2026-01-06_06-41-47', 'qwen3-max_code_2026-01-06_18-26-16', 'qwen3-max_code_2026-01-07_02-16-55', 'qwen3-max_code_2026-01-08_00-18-48'],
]

TABLE_VERILOGEVAL = [
    ['claude-sonnet-4.5_code_2026-01-08_01-12-10', 'claude-sonnet-4.5_code_2026-01-09_06-04-20', 'claude-sonnet-4.5_code_2026-01-09_19-37-11', 'claude-sonnet-4.5_code_2026-01-10_18-53-10', 'claude-sonnet-4.5_code_2026-01-11_20-04-11'],
    ['deepseek-v3.2-speciale_code_2026-01-08_03-13-02', 'deepseek-v3.2-speciale_code_2026-01-09_07-06-25', 'deepseek-v3.2-speciale_code_2026-01-09_20-24-15', 'deepseek-v3.2-speciale_code_2026-01-10_19-54-57', 'deepseek-v3.2-speciale_code_2026-01-11_20-51-31'],
    ['gemini-3-pro-preview_code_2026-01-08_17-41-36', 'gemini-3-pro-preview_code_2026-01-09_11-37-22', 'gemini-3-pro-preview_code_2026-01-10_02-02-26', 'gemini-3-pro-preview_code_2026-01-11_00-56-42', 'gemini-3-pro-preview_code_2026-01-12_04-29-58'],
    ['glm-4.6v_code_2026-01-08_19-01-17', 'glm-4.6v_code_2026-01-09_13-20-31', 'glm-4.6v_code_2026-01-10_03-22-06', 'glm-4.6v_code_2026-01-11_02-29-37', 'glm-4.6v_code_2026-01-12_05-58-00'],
    ['gpt-5.1-codex-max_code_2026-01-08_20-53-18', 'gpt-5.1-codex-max_code_2026-01-09_15-02-00', 'gpt-5.1-codex-max_code_2026-01-10_04-49-02', 'gpt-5.1-codex-max_code_2026-01-11_16-07-47', 'gpt-5.1-codex-max_code_2026-01-12_07-18-59'],
    ['grok-4_code_2026-01-08_22-02-33', 'grok-4_code_2026-01-09_15-59-12', 'grok-4_code_2026-01-10_14-43-54', 'grok-4_code_2026-01-11_16-49-34', 'grok-4_code_2026-01-12_08-07-43'],
    ['qwen3-max_code_2026-01-09_04-35-43', 'qwen3-max_code_2026-01-09_18-25-36', 'qwen3-max_code_2026-01-10_17-21-47', 'qwen3-max_code_2026-01-11_18-48-17', 'qwen3-max_code_2026-01-12_10-02-57'],
]

# The benchmarks to report on: (display name, problem count, run table).
TABLES = [
    ("RTLLM", 50, TABLE_RTLLM),
    ("verilog-eval", 156, TABLE_VERILOGEVAL),
]


# ---------------------------------------------------------------------------
# Log parsing
# ---------------------------------------------------------------------------

def check_jsonl_issue_id(jsonl_file, id_size=50, attempt_max=1):
    """
    Tally one run's logs.jsonl.

    Args:
        jsonl_file:  path to a run's logs.jsonl.
        id_size:     number of problems in the benchmark.
        attempt_max: ignore repair rounds beyond this, so a log recorded with
                     repair enabled can still be read as a single-shot result.

    Returns:
        dict with:
            records       - (line_no, issue, id) for every counted attempt
            issue_count   - [correct, compiles, attempted]
            id_count      - attempts per problem
            success_count - passing attempts per problem
            errors        - (line_no, reason) for malformed lines
    """
    records = []
    issue_counter = [0] * 3
    id_counter = [0] * id_size
    success_counter = [0] * id_size
    errors = []

    with open(jsonl_file, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue

            try:
                obj = json.loads(line)
            except json.JSONDecodeError as exc:
                errors.append((line_no, "json_parse_error"))
                raise ValueError(f"{jsonl_file}:{line_no} is not valid JSON") from exc

            issue = obj.get("issue")
            id_num = obj.get("id")
            attempt_num = obj.get("attempt")

            if attempt_num > attempt_max:
                continue

            if issue is None or id_num is None:
                errors.append((line_no, "missing_issue_or_id"))
                raise ValueError(f"{jsonl_file}:{line_no} lacks 'issue' or 'id'")

            records.append((line_no, issue, id_num))

            # Count each problem once, at whichever attempt settled it: either
            # the round that succeeded, or the last round allowed.
            if issue == 0:
                issue_counter[0] += 1
                issue_counter[1] += 1
                issue_counter[2] += 1
            elif attempt_num == attempt_max:
                # issue 1 is the only code meaning "did not compile"; every
                # other non-zero code got far enough to run.
                if issue != 1:
                    issue_counter[1] += 1
                issue_counter[2] += 1

            id_counter[id_num - 1] += 1
            if issue == 0:
                success_counter[id_num - 1] += 1

    return {
        "records": records,
        "issue_count": issue_counter,
        "id_count": id_counter,
        "success_count": success_counter,
        "errors": errors,
    }


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def table_print(benchmark_name, table, id_size, attempt_max=ATTEMPT_MAX,
                show_error=False):
    """
    Report pass@k and difficulty for one benchmark.

    Args:
        benchmark_name: shown in the section header.
        table:          rows of run directory names, one row per model.
        id_size:        number of problems in this benchmark.
        attempt_max:    repair rounds to count (see check_jsonl_issue_id).
        show_error:     also list each run's failing problems.
    """
    print(f"\n{'#' * 60}")
    print(f"# {benchmark_name}")
    print(f"{'#' * 60}")

    all_error_statistics = set()
    pass_counter = [0] * id_size
    total_runs = sum(len(row) for row in table)

    for i, row in enumerate(table):
        if not row:
            continue

        model_name = row[0][: row[0].index("_")]
        print(f"\n=== {model_name} ===")

        # Failures common to the first 1 / 3 / 5 runs, i.e. the complement of
        # pass@1 / pass@3 / pass@5.
        error_statistics = [set(), set(), set()]

        for j, run_name in enumerate(row):
            log_path = EXPERIMENT_DIR / run_name / "logs.jsonl"
            single_log = check_jsonl_issue_id(log_path, id_size, attempt_max)
            success_counter = single_log["success_count"]

            error_list = [k + 1 for k in range(id_size) if not success_counter[k]]
            print(f"{run_name}: {single_log['issue_count']}")
            if show_error:
                print(f"error list: {error_list}")

            if j == 0:
                error_statistics = [set(error_list) for _ in range(3)]
            if len(row) >= 3 and j < 3:
                error_statistics[1] &= set(error_list)
            if len(row) >= 5 and j < 5:
                error_statistics[2] &= set(error_list)

            pass_counter = [
                pass_counter[k] + success_counter[k] for k in range(id_size)
            ]

        print(f"pass@1: {id_size - len(error_statistics[0])}/{id_size}")
        if len(row) >= 3:
            print(f"pass@3: {id_size - len(error_statistics[1])}/{id_size}")
        if len(row) >= 5:
            print(f"pass@5: {id_size - len(error_statistics[2])}/{id_size}")
            print(f"Insoluble Problems: {sorted(error_statistics[2])}")

        if i == 0:
            all_error_statistics = error_statistics[2]
        all_error_statistics &= error_statistics[2]

        print("\n--------------------------")

    print(f"Super Insoluble Problems: {sorted(all_error_statistics)}")

    # Difficulty split over the aggregate pass rate across every run of every
    # model. Problems no model ever solved are reported separately rather than
    # as merely "hard".
    difficulty_list = [[], [], []]
    for k, passes in enumerate(pass_counter):
        pass_rate = passes / total_runs
        if pass_rate > EASY_RATE:
            difficulty_list[0].append(k + 1)
        elif pass_rate <= HARD_RATE:
            difficulty_list[2].append(k + 1)
        else:
            difficulty_list[1].append(k + 1)

    print(
        f"Num of Easy Cases: {len(difficulty_list[0])}, "
        f"Num of Medium Cases: {len(difficulty_list[1])}, "
        f"Num of Hard Cases: {len(difficulty_list[2]) - len(all_error_statistics)}, "
        f"Num of Impossible Cases: {len(all_error_statistics)}"
    )


def main():
    for benchmark_name, id_size, table in TABLES:
        table_print(benchmark_name, table, id_size, attempt_max=ATTEMPT_MAX)


if __name__ == "__main__":
    main()