"""
VHDLSuite - Analysis: weighted AST similarity between VHDL designs

Scores how structurally close a generated VHDL design is to the reference,
independent of whether it simulates correctly. Functional pass/fail is binary
and says nothing about *how* wrong a failure was; this gives a graded signal,
which is what makes it possible to ask whether designs that fail to compile are
merely superficially broken or structurally unlike the reference.

--- How the score is computed ---

Both designs are parsed with tree-sitter-vhdl and flattened into a preorder
token sequence, with an explicit END: marker per node so nesting survives the
flattening. Two views of those sequences are then combined:

  weighted sequence ratio -- how much of the two token streams aligns *in
      order*, via difflib's matching blocks. Sensitive to structure and
      ordering.

  weighted Jaccard -- how much the two token *multisets* overlap, ignoring
      order. Sensitive to which constructs appear and how often.

    score = SEQ_W * sequence_ratio + JAC_W * jaccard

Sequence ratio dominates (SEQ_W = 0.8) because two designs built from the same
constructs in a different order are not the same design.

--- Normalisation ---

Identifiers collapse to a single `identifier` token and literals to
`<type>:LIT`: a design that renames every signal or changes a constant is still
the same structure, and the reference's naming is arbitrary. Comments and
library/use clauses are dropped as non-structural.

--- Token weights ---

Node types are grouped (see auto_group) and each group carries a weight, so that
matching an if-statement counts for more than matching a punctuation-level node.
The values in WEIGHTS are a design choice, not a measurement. In practice the
score is insensitive to them: because the sequence ratio's denominator uses the
same weights as its numerator, scaling them cancels out, and only their relative
distribution matters. END: markers count half -- a closing marker carries the
same information as its opening node, so counting both at full weight would
double-count nesting.
"""

import difflib
from collections import Counter

from tree_sitter import Language, Parser
import tree_sitter_vhdl

# Fallback weight for node types no group claims.
DEFAULT_W = 0.4

# Split between the two similarity views. Sequence ordering dominates.
SEQ_W = 0.8
JAC_W = 1 - SEQ_W

# Per-group token weights. Hand-set: constructs that carry design intent
# (control flow, processes, instantiation) outweigh incidental structure.
WEIGHTS = {
    "CONTROL": 4.0,
    "PROCESS": 4.0,
    "ASSIGN": 3.0,
    "INSTANTIATE": 4.0,
    "CONNECT": 1.0,
    "DECL": 2.0,
    "STRUCTURE": 2.0,
    "LITERAL": 2 * DEFAULT_W,
    "identifier": DEFAULT_W,
    "OTHER": DEFAULT_W,
}

# Non-structural nodes: present in the source, irrelevant to the design.
DROP_TYPES = {
    "line_comment", "block_comment",
    "library_clause", "use_clause",
}


def auto_group(node_type: str):
    """
    Map a tree-sitter node type to a weight group.

    Matching is by substring on the lowercased type name rather than an exact
    table, so the grouping survives grammar revisions that rename or add node
    types -- `if_statement`, `case_statement_alternative`, and `loop_statement`
    all land in CONTROL without being enumerated.

    Returns:
        str | None: the group name, or None for identifiers (weighted
        separately, since they are normalised away).
    """
    t = node_type.lower()

    if "if" in t or "case" in t or "loop" in t:
        return "CONTROL"
    if "process" in t or "wait" in t:
        return "PROCESS"
    if "assign" in t:
        return "ASSIGN"
    if "instantiation" in t:
        return "INSTANTIATE"
    if "map" in t:
        return "CONNECT"
    if "declaration" in t:
        return "DECL"
    if "block" in t or "architecture" in t:
        return "STRUCTURE"
    if "identifier" in t:
        return None

    return "OTHER"


def weight(tok: str) -> float:
    """Weight one token from make_tokens (see module docstring)."""
    # Closing markers count half: they restate their opening node's identity.
    if tok.startswith("END:"):
        return weight(tok[4:]) * 0.5
    if tok.startswith("identifier(") or tok == "identifier":
        return WEIGHTS["identifier"]
    if ":LIT" in tok:
        return WEIGHTS["LITERAL"]

    group = auto_group(tok)
    if group is None:
        return WEIGHTS["identifier"]
    return WEIGHTS.get(group, DEFAULT_W)


def make_tokens(root, src_bytes: bytes,
                named_only=True,
                normalize_ident=True,
                normalize_literal=True,
                drop_trivia=True):
    """
    Flatten a parse tree into a preorder token sequence.

    Every node contributes its type on the way down and an `END:<type>` marker
    on the way back up, so the flat sequence still encodes nesting: two designs
    with the same node types in the same order but different nesting produce
    different sequences.

    Args:
        root:              tree-sitter root node.
        src_bytes:         the source the tree was parsed from.
        named_only:        skip anonymous nodes (punctuation, keywords).
        normalize_ident:   collapse identifiers to a single token.
        normalize_literal: collapse literals to `<type>:LIT`.
        drop_trivia:       skip comments and library/use clauses.

    Returns:
        list[str]: the token sequence.
    """
    drop_types = DROP_TYPES if drop_trivia else set()

    def text(node):
        return src_bytes[node.start_byte:node.end_byte].decode("utf-8", errors="ignore")

    def is_literal_type(t: str) -> bool:
        return "literal" in t or t in {
            "character_literal", "string_literal",
            "decimal_literal", "based_literal",
        }

    tokens = []

    def visit(node):
        if named_only and not node.is_named:
            return
        t = node.type
        if t in drop_types:
            return

        if normalize_ident and t == "identifier":
            tokens.append("identifier")
        elif normalize_literal and is_literal_type(t):
            tokens.append(f"{t}:LIT")
        else:
            tokens.append(t)

        for c in node.children:
            visit(c)

        # Identifiers are leaves; a closing marker would add nothing.
        if t != "identifier":
            tokens.append(f"END:{t}")

    visit(root)
    return tokens


def weighted_jaccard(a_tokens, b_tokens):
    """
    Weighted Jaccard overlap of two token multisets.

    Order-insensitive: measures which constructs both designs use and how often,
    not where. Two empty sequences count as identical.
    """
    ca, cb = Counter(a_tokens), Counter(b_tokens)
    inter = 0.0
    union = 0.0
    for k in set(ca) | set(cb):
        w = weight(k)
        inter += w * min(ca.get(k, 0), cb.get(k, 0))
        union += w * max(ca.get(k, 0), cb.get(k, 0))
    return (inter / union) if union else 1.0


def weighted_sequence_ratio(a_tokens, b_tokens):
    """
    Weighted fraction of two token sequences that aligns in order.

    difflib finds the matching blocks; each matched token then contributes its
    weight, normalised by the mean total weight of the two sequences. Because
    numerator and denominator share the weighting, uniformly scaling WEIGHTS
    leaves this unchanged -- only the relative weights matter.
    """
    sm = difflib.SequenceMatcher(a=a_tokens, b=b_tokens, autojunk=False)

    match_w = 0.0
    for (i, _j, n) in sm.get_matching_blocks():
        for k in range(n):
            match_w += weight(a_tokens[i + k])

    a_w = sum(weight(t) for t in a_tokens)
    b_w = sum(weight(t) for t in b_tokens)
    denom = (a_w + b_w) / 2.0
    return (match_w / denom) if denom else 1.0


def compare_ast_weighted(dut_src: bytes, ref_src: bytes, parser):
    """
    Score one generated design against its reference.

    A design that does not parse scores 0 rather than raising: models do emit
    malformed VHDL, and that is a result to record, not an error to crash on.

    Returns:
        dict with `ok` and `score`; on success also the two component scores and
        both token counts.
    """
    dut_root = parser.parse(dut_src).root_node
    ref_root = parser.parse(ref_src).root_node

    if dut_root.has_error or ref_root.has_error:
        return {
            "ok": False,
            "reason": f"parse_error dut={dut_root.has_error} ref={ref_root.has_error}",
            "score": 0.0,
        }

    dut_toks = make_tokens(dut_root, dut_src, drop_trivia=True)
    ref_toks = make_tokens(ref_root, ref_src, drop_trivia=True)

    wj = weighted_jaccard(dut_toks, ref_toks)
    ws = weighted_sequence_ratio(dut_toks, ref_toks)
    score = SEQ_W * ws + JAC_W * wj

    return {
        "ok": True,
        "score": round(score, 4),
        "weighted_sequence": round(ws, 4),
        "weighted_jaccard": round(wj, 4),
        "dut_len": len(dut_toks),
        "ref_len": len(ref_toks),
    }


def build_parser():
    """Construct a tree-sitter parser for VHDL."""
    parser = Parser()
    parser.language = Language(tree_sitter_vhdl.language())
    return parser