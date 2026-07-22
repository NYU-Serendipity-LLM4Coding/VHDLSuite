"""
VHDLSuite - Analysis, Stage 2: failure taxonomy construction
=============================================================

Turns the flat root-cause label pool from stage 1 into a fixed three-level
taxonomy in a single pass.

  stage 1 (label_failures.py): each failure -> flat snake_case root-cause
      labels, accumulated in a growing pool (data/error_pool.json).

  stage 2 (this file): that whole pool -> a three-level taxonomy:
      six fixed major categories -> model-defined middle -> the pool's labels
      as minors. Output: data/error_taxonomy.json.

--- Why a second stage, run once, over the whole pool ---

Stage 1's pool is order-dependent and can hold near-duplicate or loosely
grouped labels. Organizing it incrementally (as each label appears) would let
the same root cause land under different parents depending on arrival order.
Instead this runs once with the entire pool visible, so grouping and dedupe
decisions are made globally. The six major categories are fixed; the model only
groups the existing labels beneath them and never invents or drops one.

--- Determinism note ---

The pool this reads is itself not reproducible (see label_failures.py), and the
organizing model samples at temperature. Re-running can therefore yield a
different middle-level grouping. The fixed majors and the requirement that every
input label appears exactly once keep the taxonomy well-formed regardless, but
the exact middles are not guaranteed stable. Output is git-ignored.

--- Output shape ---

    {
      "Syntax & Declaration": {
        "identifiers_and_scope": ["undeclared_identifier", ...],
        ...
      },
      "Types & Data Objects": { ... },
      ...
    }

with majors in the fixed order below, and middles and minors sorted
alphabetically within each level.

Run from the repository root:

    python src/analysis/classify_failures.py
"""

import json
import os
import re
import sys
from pathlib import Path

from openai import OpenAI

REPO_ROOT = Path(__file__).resolve().parents[2]

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Input: the flat pool produced by stage 1.
ERROR_POOL_PATH = REPO_ROOT / "data" / "error_pool.json"

# Output: the organized three-level taxonomy.
TAXONOMY_PATH = REPO_ROOT / "data" / "error_taxonomy.json"

# The model that organizes the pool, as an OpenRouter model string.
CLASSIFIER_MODEL = "google/gemini-3-pro-preview"

API_KEY_PATH = os.environ.get("VHDLSUITE_API_KEY_PATH", str(REPO_ROOT / "key.txt"))
API_BASE_URL = "https://openrouter.ai/api/v1"

MAX_TOKENS = 25000
TEMPERATURE = 0.85
TOP_P = 0.95

# The six fixed top-level categories. The model must use exactly these, verbatim.
MAJOR_CATEGORIES = [
    "Syntax & Declaration",
    "Types & Data Objects",
    "Interfaces & Instantiation",
    "Combinational Logic",
    "Sequential & FSM",
    "Initialization & Miscellaneous",
]

# Inlined here rather than in src/prompts/prompt.py: this prompt is specific to
# this one organizing step and is not shared with the generation pipeline.
SYSTEM_PROMPT = """
You are an expert VHDL bug taxonomy organizer. You are given a flat list of
root-cause bug labels collected from many VHDL designs. Organize ALL of them
into a fixed three-level taxonomy.

INPUT:
A JSON list of flat snake_case root-cause labels (the error pool).

OUTPUT FORMAT (STRICT JSON ONLY):
{
  "taxonomy": {
    "<MAJOR>": {
      "<middle_label>": ["<minor_label>", ...],
      ...
    },
    ...
  },
  "notes": string
}

MAJOR CATEGORIES (FIXED -- use exactly these six keys, verbatim, including the
ampersand and spacing):
- "Syntax & Declaration"
- "Types & Data Objects"
- "Interfaces & Instantiation"
- "Combinational Logic"
- "Sequential & FSM"
- "Initialization & Miscellaneous"

RULES:
A) EVERY input label must appear exactly once as a minor label somewhere in the
   taxonomy. Do not drop, merge, rename, or invent labels -- each input string
   must appear verbatim as exactly one minor.
B) Assign each input label to exactly one (major, middle) path.
C) The six majors are fixed. You define the middle level: group related minors
   under a descriptive middle label (lowercase snake_case, 2-4 words).
D) A minor label must not appear under more than one (major, middle) path.
E) If a label does not fit the first five majors, place it under
   "Initialization & Miscellaneous".

OUTPUT FIELD DEFINITIONS:
- taxonomy: the full three-level structure containing every input label.
- notes: <=3 sentences on any non-obvious grouping choices.

FORBIDDEN:
- Do not invent minor labels not in the input.
- Do not omit any input label.
- No code, no long explanations.
"""


# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------

def load_error_pool(pool_path):
    """Load the flat label pool. Accepts a bare list or {"pool": [...]}."""
    if not pool_path.exists():
        raise FileNotFoundError(
            f"Label pool not found: {pool_path}\n"
            "Run src/analysis/label_failures.py first to produce it."
        )
    data = json.loads(pool_path.read_text(encoding="utf-8"))
    if isinstance(data, dict) and "pool" in data:
        return data["pool"]
    if isinstance(data, list):
        return data
    raise ValueError(f"Unrecognized pool format in {pool_path}")


def safe_parse_json_object(text):
    """Grab the first JSON object from the model output."""
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Taxonomy validation + sorting
# ---------------------------------------------------------------------------

def flatten_minors(taxonomy):
    """Yield every minor label in a taxonomy, with its (major, middle) path."""
    for major, middles in taxonomy.items():
        for middle, minors in middles.items():
            for minor in minors:
                yield major, middle, minor


def validate_taxonomy(taxonomy, pool):
    """
    Check the model's taxonomy against the invariants the prompt promised.

    Verifies that the majors are exactly the fixed six, that every pool label
    appears exactly once as a minor, that no extra minors were invented, and
    that no minor sits under two paths. Returns a list of human-readable
    problems (empty if the taxonomy is well-formed).
    """
    problems = []

    majors = list(taxonomy.keys())
    unexpected = [m for m in majors if m not in MAJOR_CATEGORIES]
    if unexpected:
        problems.append(f"unexpected major categories: {unexpected}")

    seen = {}
    for major, middle, minor in flatten_minors(taxonomy):
        seen.setdefault(minor, []).append((major, middle))

    duplicated = {k: v for k, v in seen.items() if len(v) > 1}
    if duplicated:
        problems.append(f"minors under multiple paths: {duplicated}")

    pool_set = set(pool)
    placed_set = set(seen.keys())

    missing = pool_set - placed_set
    if missing:
        problems.append(f"pool labels missing from taxonomy: {sorted(missing)}")

    invented = placed_set - pool_set
    if invented:
        problems.append(f"labels not in the pool: {sorted(invented)}")

    return problems


def sort_taxonomy(taxonomy):
    """
    Return the taxonomy with a stable order: majors in the fixed order, middles
    and minors sorted alphabetically. Majors the model left empty are dropped.
    """
    ordered = {}
    for major in MAJOR_CATEGORIES:
        middles = taxonomy.get(major)
        if not middles:
            continue
        ordered[major] = {
            middle: sorted(middles[middle])
            for middle in sorted(middles)
        }
    return ordered


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    print("Start")

    pool = load_error_pool(ERROR_POOL_PATH)
    print(f"Loaded {len(pool)} labels from {ERROR_POOL_PATH}")
    if not pool:
        print("Pool is empty; nothing to organize.")
        return

    key_path = Path(API_KEY_PATH).expanduser()
    if not key_path.exists():
        raise FileNotFoundError(
            f"API key file not found: {key_path}\n"
            "Write your OpenRouter key to that path, or set "
            "VHDLSUITE_API_KEY_PATH to point at it."
        )
    api_key = key_path.read_text(encoding="utf-8").strip()
    client = OpenAI(api_key=api_key, base_url=API_BASE_URL)

    user_prompt = (
        "Organize the following error pool into the three-level taxonomy.\n\n"
        "```error_pool\n"
        + json.dumps(pool, ensure_ascii=False, indent=2)
        + "\n```"
    )

    print(f"Organizing with {CLASSIFIER_MODEL} ...")
    response = client.chat.completions.create(
        model=CLASSIFIER_MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_prompt},
        ],
        max_tokens=MAX_TOKENS,
        temperature=TEMPERATURE,
        top_p=TOP_P,
        n=1,
    )
    raw = response.choices[0].message.content if response else ""

    parsed = safe_parse_json_object(raw)
    if parsed is None or "taxonomy" not in parsed:
        # Keep the raw reply for inspection rather than losing the API spend.
        fallback = TAXONOMY_PATH.with_suffix(".raw.txt")
        fallback.parent.mkdir(parents=True, exist_ok=True)
        fallback.write_text(raw, encoding="utf-8")
        raise ValueError(
            f"Could not parse a taxonomy from the model output. "
            f"Raw reply saved to {fallback}"
        )

    taxonomy = parsed["taxonomy"]

    # Validate against the promised invariants, but do not abort: an imperfect
    # taxonomy is still worth saving for manual repair. Report every problem.
    problems = validate_taxonomy(taxonomy, pool)
    if problems:
        print("\n[warning] taxonomy did not fully satisfy the invariants:")
        for p in problems:
            print(f"  - {p}")
        print("Saving anyway for manual inspection.\n")

    taxonomy = sort_taxonomy(taxonomy)

    TAXONOMY_PATH.parent.mkdir(parents=True, exist_ok=True)
    TAXONOMY_PATH.write_text(
        json.dumps(taxonomy, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    n_middles = sum(len(m) for m in taxonomy.values())
    n_minors = sum(len(v) for m in taxonomy.values() for v in m.values())
    print(f"Wrote taxonomy: {len(taxonomy)} majors, {n_middles} middles, "
          f"{n_minors} minors -> {TAXONOMY_PATH}")
    if parsed.get("notes"):
        print(f"\nModel notes: {parsed['notes']}")


if __name__ == "__main__":
    main()