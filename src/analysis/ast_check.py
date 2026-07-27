"""
VHDLSuite - Analysis: AST similarity of generated designs, by outcome

Reports how structurally close each model's VHDL is to the reference, split by
what the simulator said about it. The question this answers: when a model fails,
does it fail *narrowly* -- right structure, wrong detail -- or does it produce
something unlike the reference altogether?

Per model, for every run, the mean similarity over:

    Success   - problems the model solved
    Failure   - problems it did not, further split by:
        Compiling - issue 1: never compiled
        Runtime   - issues 2/3: compiled but mismatched or hung
    All       - every problem

plus, across the model's runs, the mean of each problem's *best* score, which
asks how close the model gets when it gets closest.

Similarity is computed against the construction stage's dut.vhd -- the VHDL
translation that was itself simulation-verified -- not against the original
Verilog.

--- Scope ---

Only the first repair round is scored (ATTEMPT_MAX = 1). The outcome tallies
come from the same logs.jsonl that src/analysis/log_check.py reads, and the
per-problem bookkeeping here assumes one record per problem, which holds only at
a single attempt.

Prerequisites:
    * tree-sitter and tree-sitter-vhdl (`pip install tree_sitter tree_sitter_vhdl`)
    * Completed construction and evaluation runs; see BENCHMARKS below.

Run from the repository root:

    python src/analysis/ast_check.py
"""

import sys
from pathlib import Path

import numpy

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.analysis.ast_similarity import (  # noqa: E402
    JAC_W, SEQ_W, build_parser, compare_ast_weighted,
)
from src.analysis.log_check import (  # noqa: E402
    EXPERIMENT_DIR, TABLE_RTLLM, TABLE_VERILOGEVAL, check_jsonl_issue_id,
)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]

# Construction runs holding the reference dut.vhd per problem -- the same
# directories src/evaluation/solve.py evaluated against.
CONSTRUCTION_DIR = REPO_ROOT / "data" / "experiments_TB"

RTLLM_BENCHMARK = CONSTRUCTION_DIR / "<model>_<mode>_<timestamp>"
VERILOGEVAL_BENCHMARK = CONSTRUCTION_DIR / "<model>_<mode>_<timestamp>"


# Repair round to score. See the module docstring: the per-problem bookkeeping
# below assumes one log record per problem, which only holds at 1.
ATTEMPT_MAX = 1

# (display name, problem count, reference directory, evaluation run table)
BENCHMARKS = [
    ("RTLLM", 50, RTLLM_BENCHMARK, TABLE_RTLLM),
    ("verilog-eval", 156, VERILOGEVAL_BENCHMARK, TABLE_VERILOGEVAL),
]


# Issue codes, as classified by src/simulation/run.py.
ISSUE_COMPILE_FAIL = 1
ISSUE_RUNTIME_FAIL = (2, 3)


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------

def single_ast_check(parser, benchmark_dir, run_dir, index, attempt=1):
    """
    Score one problem's generated design against its reference.

    Args:
        benchmark_dir: construction run holding the reference dut.vhd.
        run_dir:       evaluation run holding the generated design.
        index:         zero-based problem index.
        attempt:       repair round to read.
    """
    problem = f"Prob{index + 1:05d}"
    dut_src = (run_dir / problem / f"{problem}_{attempt}.vhd").read_bytes()
    ref_src = (benchmark_dir / problem / "dut.vhd").read_bytes()
    return compare_ast_weighted(dut_src, ref_src, parser)


def score_run(parser, benchmark_dir, run_dir, id_size, attempt_max):
    """
    Score every problem in one evaluation run, grouped by simulator outcome.

    Means are guarded: a run where every problem passed has no failures to
    average over, and one where nothing failed to compile has no compile
    failures -- both are real outcomes, not errors, so the corresponding mean is
    None rather than a division by zero.

    Returns:
        dict with the four means (None where undefined), `issue_count` from the
        log, and `scores`, the per-problem scores for cross-run aggregation.
    """
    log = check_jsonl_issue_id(run_dir / "logs.jsonl", id_size, attempt_max)
    success_counter = log["success_count"]
    records = log["records"]

    buckets = {"success": [], "failure": [], "compiling": [], "runtime": []}
    scores = []

    for k in range(id_size):
        score = single_ast_check(parser, benchmark_dir, run_dir, k, attempt=1)["score"]
        scores.append(score)

        if success_counter[k]:
            buckets["success"].append(score)
        else:
            buckets["failure"].append(score)

        # records is ordered by problem; verify before trusting the index.
        if k != records[k][2] - 1:
            raise ValueError(
                f"{run_dir.name}: log record {k} is for problem "
                f"{records[k][2]}, expected {k + 1}. This analysis needs one "
                f"record per problem, which only holds at attempt_max=1."
            )

        issue = records[k][1]
        if issue == ISSUE_COMPILE_FAIL:
            buckets["compiling"].append(score)
        elif issue in ISSUE_RUNTIME_FAIL:
            buckets["runtime"].append(score)

    def mean(values):
        return float(numpy.mean(values)) if values else None

    return {
        "success": mean(buckets["success"]),
        "failure": mean(buckets["failure"]),
        "compiling": mean(buckets["compiling"]),
        "runtime": mean(buckets["runtime"]),
        "all": mean(scores),
        "issue_count": log["issue_count"],
        "scores": scores,
    }


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def fmt(value, digits=4):
    """Format a possibly-undefined mean."""
    return "n/a" if value is None else str(round(value, digits))


def mean_over_runs(run_results, key):
    """Mean of one metric across runs, skipping runs where it is undefined."""
    values = [r[key] for r in run_results if r[key] is not None]
    return float(numpy.mean(values)) if values else None


def ast_table_print(parser, benchmark_name, benchmark_dir, table, id_size,
                    attempt_max=ATTEMPT_MAX):
    """Report AST similarity for one benchmark, one section per model."""
    print(f"\n{'#' * 60}")
    print(f"# {benchmark_name}   (SEQ_W={SEQ_W}, JAC_W={round(JAC_W, 2)})")
    print(f"# reference: {benchmark_dir}")
    print(f"{'#' * 60}")

    for row in table:
        if not row:
            continue

        model_name = row[0][: row[0].index("_")]
        print(f"\n=== {model_name} ===")

        run_results = []
        # Best score per problem across this model's runs.
        best_per_problem = [0.0] * id_size

        for run_name in row:
            result = score_run(
                parser, benchmark_dir, EXPERIMENT_DIR / run_name,
                id_size, attempt_max,
            )
            run_results.append(result)

            for k, score in enumerate(result["scores"]):
                best_per_problem[k] = max(best_per_problem[k], score)

            print(
                f"{run_name}: {result['issue_count']}"
                f"    Success, Failure (Compiling / Runtime), All: "
                f"{fmt(result['success'])}, {fmt(result['failure'])}"
                f"({fmt(result['compiling'])}, {fmt(result['runtime'])}), "
                f"{fmt(result['all'])}"
            )

        n = len(row)
        print(
            f"Maximum AST Accuracy of {model_name} when n = {n}: "
            f"{round(float(numpy.mean(best_per_problem)), 4)}"
            f"          Average AST Accuracy of {model_name} when n = {n}: "
            f"{fmt(mean_over_runs(run_results, 'success'))}, "
            f"{fmt(mean_over_runs(run_results, 'failure'))}"
            f"({fmt(mean_over_runs(run_results, 'compiling'))}, "
            f"{fmt(mean_over_runs(run_results, 'runtime'))}), "
            f"{fmt(mean_over_runs(run_results, 'all'))}"
        )

        print("\n--------------------------")


def main():
    parser = build_parser()

    for benchmark_name, id_size, benchmark_dir, table in BENCHMARKS:
        if not benchmark_dir.is_dir():
            raise FileNotFoundError(
                f"Reference directory not found: {benchmark_dir}\n"
                f"Set the {benchmark_name} entry near the top of this file to a "
                f"completed construction output directory."
            )
        ast_table_print(parser, benchmark_name, benchmark_dir, table, id_size,
                        attempt_max=ATTEMPT_MAX)


if __name__ == "__main__":
    main()