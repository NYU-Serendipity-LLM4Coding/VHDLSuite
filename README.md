# VHDLSuite

> **[VHDLSuite: Unified Pipeline for LLM VHDL Generation with Data Synthesis and Evaluation]**

> [Yijun Shen, Minghao Shao, Yichen Zhao, Zhuoyan Yu, Boyuan Chen, Yik-Cheung Tam, Muhammad Shafique]

> MLCAD 2026

VHDLSuite is a pipeline for building and evaluating a VHDL code-generation
benchmark. It translates the Verilog-based RTLLM and VerilogEval benchmarks into
verified VHDL (yielding **VHDLBench**), then evaluates language models on
generating VHDL from natural-language specifications, scoring each design by
simulation against a golden testbench.

The pipeline has three stages:

1. **Construction** — translate each Verilog problem into a VHDL design and a
   VHDL testbench, verified by simulation; refine the problem descriptions into
   language-neutral prompts.
2. **Evaluation** — have models generate VHDL from those prompts and score the
   results against VHDLBench's testbenches.
3. **Analysis** — pass@k, AST similarity to the reference, and an LLM-assigned
   failure taxonomy.

The curated **VHDLBench** dataset is included in this repository under
`data/VHDLBench/`, so the evaluation and analysis stages can be run without
rebuilding the benchmark from scratch.

---

## 1. Requirements

### GHDL (not a pip package)

Simulation uses [GHDL](https://github.com/ghdl/ghdl). Install it from your
system package manager:

```bash
# macOS
brew install ghdl

# Debian/Ubuntu
sudo apt-get install ghdl
```

Results were produced with **GHDL 5.1.1**. Verify it is on your PATH:

```bash
ghdl --version
```

### Python

Python 3.10+ is recommended. Install the pinned dependencies:

```bash
pip install -r requirements.txt
```

This installs VUnit (the Python driver for GHDL), the OpenAI client, tree-sitter
with its VHDL grammar, and supporting libraries.

### API key

Model calls go through [OpenRouter](https://openrouter.ai/). Put your key in a
file named `key.txt` at the repository root:

```bash
echo "sk-or-v1-xxxxxxxx" > key.txt
```

`key.txt` is git-ignored. Alternatively, set `VHDLSUITE_API_KEY_PATH` to point
at a key file elsewhere.

---

## 2. Repository layout

```
src/
  preprocessing/
    rtllm_data_management.py     Download RTLLM (pinned) and flatten its layout
  construction/
    translate_rtllm.py           Verilog -> VHDL translation (RTLLM)
    translate_verilogeval.py     Verilog -> VHDL translation (VerilogEval)
    refine_prompt.py             Language-neutral descriptions + library declarations
  evaluation/
    solve.py                     Generate VHDL from prompts; score by simulation
  analysis/
    log_check.py                 pass@1/3/5 and problem-difficulty split
    ast_similarity.py            Weighted AST-similarity metric (library)
    ast_check.py                 AST similarity by outcome, per model
    label_failures.py            Stage 1: flat root-cause labels for failures
    classify_failures.py         Stage 2: organize labels into a taxonomy
  prompts/
    prompt.py                    System prompts used across the pipeline
    TB_examples_RTLLM.py         Few-shot examples (RTLLM)
    TB_examples_VerilogEval.py   Few-shot examples (VerilogEval)
  simulation/
    run.py                       GHDL/VUnit harness; classifies each run

data/
  VHDLBench/
    VHDLBench-RTLLM/             Curated benchmark: 50 problems
    VHDLBench-VerilogEval/       Curated benchmark: 156 problems
```

Everything under `data/` except `data/VHDLBench/` is git-ignored: downloads,
intermediate folders, and experiment runs are all regenerated locally.

> **Note on running scripts.** Every script is meant to be run from the
> repository root, e.g. `python src/evaluation/solve.py`. The scripts add the
> repository root to the import path themselves, so they resolve shared modules
> regardless — but the relative `data/` paths assume the root as the working
> directory.

---

## 3. Quick start — evaluate against the included VHDLBench

The fastest path: skip construction entirely and evaluate models against the
VHDLBench dataset shipped in this repo.

**a. Point the evaluator at VHDLBench.** In `src/evaluation/solve.py`, set
`BENCHMARK_RUNS` to the included dataset:

```python
BENCHMARK_RUNS = [
    ("RTLLM", 50, REPO_ROOT / "data" / "VHDLBench" / "VHDLBench-RTLLM"),
    ("verilog-eval", 156, REPO_ROOT / "data" / "VHDLBench" / "VHDLBench-VerilogEval"),
]
```

Choose which models to run in `MODELS`, and how many independent samples per
model in `NUM_RUNS` (default 5; used for pass@k).

**b. Run the evaluation.**

```bash
python src/evaluation/solve.py
```

Each run writes to `data/experiments/<model>_<benchmark>_<timestamp>/`, with a
`logs.jsonl` recording every problem's outcome.

**c. Report pass@k.** In `src/analysis/log_check.py`, set `TABLE_RTLLM` and
`TABLE_VERILOGEVAL` to the run directory names produced in step b (one row per
model, one entry per run), then:

```bash
python src/analysis/log_check.py
```

This prints pass@1/3/5 per model and the easy/medium/hard/impossible split.

> **Cost.** Evaluation calls a model once per problem per run. With the default
> 7 models × 5 runs, that is 7 × 5 × (50 + 156) ≈ 7,200 completions. Trim
> `MODELS` and `NUM_RUNS` to sample a smaller slice.

---

## 4. Full pipeline — rebuild VHDLBench from scratch

To reconstruct the benchmark from the original Verilog sources.

### 4.1 Preprocess RTLLM

```bash
python src/preprocessing/rtllm_data_management.py
```

Clones RTLLM at the pinned commit into `data/RTLLM/` and flattens it into
`data/RTLLM_merged_folders/`. (VerilogEval needs no flattening; it is downloaded
automatically in the next step.)

### 4.2 Construction

Translate each benchmark's Verilog into verified VHDL:

```bash
python src/construction/translate_rtllm.py
python src/construction/translate_verilogeval.py
```

Each writes one directory per run under `data/experiments_TB/`, containing per
problem the original Verilog, the generated `dut.vhd` and `tb.vhd`, and a
`logs.jsonl`.

Then refine the descriptions and generate library declarations. Set
`BENCHMARK_RUNS` in `src/construction/refine_prompt.py` to the translation
output directories from the previous step, then:

```bash
python src/construction/refine_prompt.py
```

This adds `prompt_new.txt` (language-neutral description) and `declaration.txt`
(required VHDL libraries) to each problem directory. Together these directories
are the newly built VHDLBench.

### 4.3 Evaluation

Set `BENCHMARK_RUNS` in `src/evaluation/solve.py` to the construction output
directories, then run as in the Quick Start:

```bash
python src/evaluation/solve.py
```

### 4.4 Analysis

**pass@k** — as in the Quick Start, via `src/analysis/log_check.py`.

**AST similarity** — set the reference directories near the top of
`src/analysis/ast_check.py` to the construction output, then:

```bash
python src/analysis/ast_check.py
```

Reports each model's structural similarity to the reference, split by
success/failure and by compile/runtime failure.

**Failure taxonomy** — a two-stage, LLM-assisted labeling of failures:

```bash
# Stage 1: assign flat root-cause labels to every failure, growing a label pool
python src/analysis/label_failures.py

# Stage 2: organize the pool into a fixed three-level taxonomy
python src/analysis/classify_failures.py
```

Stage 1 writes `error_type_logs.jsonl` into each run directory and accumulates
`data/error_pool.json`; stage 2 reads that pool and writes
`data/error_taxonomy.json`.

---

## 5. Configuring run directories

Several scripts need to be pointed at directories produced by earlier stages.
Because those directory names include a timestamp from when they were generated,
they are left as placeholders (`<model>_<mode>_<timestamp>`) for you to fill in
with your own runs:

| Script | Constant | Points at |
|---|---|---|
| `construction/refine_prompt.py` | `BENCHMARK_RUNS` | translation output dirs |
| `evaluation/solve.py` | `BENCHMARK_RUNS` | VHDLBench / construction output |
| `analysis/log_check.py` | `TABLE_RTLLM`, `TABLE_VERILOGEVAL` | evaluation run dirs |
| `analysis/ast_check.py` | `RTLLM_BENCHMARK`, `VERILOGEVAL_BENCHMARK` | construction output |
| `analysis/label_failures.py` | `VHDLBENCH_DIRS` | construction output |

For the Quick Start, `evaluation/solve.py` points directly at the included
`data/VHDLBench/` and needs no construction run.

---

## 6. Notes and limitations

**Dataset versions are pinned.** RTLLM and VerilogEval have no release tags for
the versions used, so the preprocessing/translation scripts pin exact upstream
commits (`RTLLM_COMMIT`, `VERILOGEVAL_COMMIT`). The reconstruction path therefore
reproduces the same source data regardless of later upstream changes. The Quick
Start uses the frozen `data/VHDLBench/` and does not touch the upstream repos at
all.

**The failure label pool is not reproducible.** `label_failures.py` grows its
label pool as problems are processed, and the LLM judge samples at temperature,
so the exact labels differ between runs. Stage 2's fixed six major categories and
its "every label appears exactly once" invariant keep the resulting taxonomy
well-formed, but the middle-level grouping is not guaranteed identical across
runs. `data/error_pool.json` and `data/error_taxonomy.json` are git-ignored.

**Repair is off by default.** `solve.py` sets `MAX_REPAIR_ROUNDS = 1`
(single-shot generation), matching the reported results. Raising it lets a model
see the simulator's error and revise.

**Everything runs from the repository root**, and API usage scales with the
number of models, runs, and problems — see the cost note in the Quick Start.