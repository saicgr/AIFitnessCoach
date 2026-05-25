#!/usr/bin/env python3
"""Slice reports/i18n_keys.json into 20 per-batch files for the translation
agent swarm. Slices by camelCase key prefix so related keys land together
(translators can be consistent within a domain).
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
KEYS = REPO_ROOT / "reports" / "i18n_keys.json"
OUT_DIR = REPO_ROOT / "scripts" / "translations"

# Number of batches. Smaller = each Sonnet agent gets a manageable chunk.
# 60 batches × ~150 keys × 36 locales ≈ 54K tokens output per agent — safe.
NUM_BATCHES = 60
BATCH_PREFIX = "batch_v2"  # v2 to avoid clobbering v1 files written by failed agents


# SKIP these obvious junk keys/values surfaced by Wave-1 agent feedback:
# - literal escape sequences (just `\n`)
# - CSV column-identifier lists
# - template/syntax artifacts (start with `]`, `}`, etc.)
_BAD_VALUE_RE = re.compile(
    r"""^(
        \\n |                          # just a literal backslash-n
        \s* |                          # whitespace-only
        [a-z_]+(,\s*[a-z_]+){2,} |     # 3+ comma-separated snake_case (CSV cols)
        [\]\}\)\[].* |                 # starts with closing bracket
        .*\s+[a-z_]+\s*$               # ends with bare snake_case identifier
    )$""",
    re.VERBOSE,
)


def _prefix(key: str) -> str:
    """Return the leading lowercase letters of a camelCase key."""
    m = re.match(r"^([a-z]+)", key)
    return m.group(1) if m else "misc"


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with KEYS.open() as f:
        all_keys = json.load(f)
    if not isinstance(all_keys, dict):
        print(f"❌ {KEYS} must be a dict", file=sys.stderr)
        return 1

    # Filter out junk extracted by overly-generous lexer
    before = len(all_keys)
    filtered = {k: v for k, v in all_keys.items() if not _BAD_VALUE_RE.match(v)}
    dropped = before - len(filtered)
    if dropped:
        print(f"Filtered {dropped} junk keys (literal-\\n, CSV-col-lists, template artifacts)",
              file=sys.stderr)
    all_keys = filtered

    # Group by prefix
    by_prefix: dict[str, dict[str, str]] = defaultdict(dict)
    for k, v in all_keys.items():
        by_prefix[_prefix(k)][k] = v

    target_per_batch = max(1, len(all_keys) // NUM_BATCHES)
    # Split oversized prefix-groups (> 1.5× target) so no single batch is huge.
    # Sonnet output cap means 200 keys × 36 locales ≈ 50K tokens — safe.
    cap = int(target_per_batch * 1.5)
    split_prefixes: list[tuple[str, dict[str, str]]] = []
    for prefix, keys in by_prefix.items():
        if len(keys) <= cap:
            split_prefixes.append((prefix, keys))
            continue
        items = list(keys.items())
        chunk = 0
        while items:
            head, rest = items[:cap], items[cap:]
            split_prefixes.append((f"{prefix}{chunk+1}", dict(head)))
            items = rest
            chunk += 1

    # Sort prefixes by size descending; bin-pack into N batches
    sorted_prefixes = sorted(split_prefixes, key=lambda x: -len(x[1]))
    print(f"Total keys: {len(all_keys)}; "
          f"slicing into {NUM_BATCHES} batches (~{target_per_batch} keys each, "
          f"cap {cap})",
          file=sys.stderr)

    batches: list[dict[str, str]] = [{} for _ in range(NUM_BATCHES)]
    batch_labels: list[list[str]] = [[] for _ in range(NUM_BATCHES)]
    batch_sizes = [0] * NUM_BATCHES

    # Greedy bin-pack: put each prefix into the smallest current batch
    for prefix, keys in sorted_prefixes:
        # Find smallest batch
        idx = batch_sizes.index(min(batch_sizes))
        batches[idx].update(keys)
        batch_labels[idx].append(prefix)
        batch_sizes[idx] += len(keys)

    # Write batches
    for i, (b, labels, size) in enumerate(zip(batches, batch_labels, batch_sizes), start=1):
        label = "_".join(sorted(labels)[:2])
        if len(label) > 40:
            label = label[:40]
        out_path = OUT_DIR / f"{BATCH_PREFIX}_{i:02d}_{label}.json"
        with out_path.open("w") as f:
            json.dump(b, f, ensure_ascii=False, indent=2, sort_keys=True)
        if i <= 5 or i % 10 == 0:
            print(f"  {BATCH_PREFIX}_{i:02d}: {size:>4} keys → {out_path.name}",
                  file=sys.stderr)

    print(f"\n✓ wrote {NUM_BATCHES} batches to {OUT_DIR}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
