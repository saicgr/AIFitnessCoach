"""Re-derive correct injury-test verdicts from the recorded per-run data.

The original harness flagged any SSE containing the substring "500" (a calorie or
weight number) as an HTTP 500, polluting the `err` flag and the `verdict` column.
The per-run `n_ex` / `n_leak` data is reliable (it comes from a DB cross-check
against exercise_safety_index_mat), so we recompute verdicts WITHOUT re-running
Gemini:

  - any run with n_leak > 0           -> LEAK   (unsafe exercise shipped)
  - else any run with n_ex == 0       -> EMPTY  (stuck onboarding / RAG miss)
  - else min n_ex <= 2 and injuries   -> THIN
  - else                              -> PASS

A genuine HTTP 500 would have produced n_ex == 0 (no workout persisted), so it
surfaces here as EMPTY — no real crash is hidden by dropping the `err` flag.
"""
import json
from collections import Counter
from pathlib import Path

from injury_test_harness import write_md  # reuse the exact MD renderer

JSONL = Path(__file__).with_name("injury_test_results.jsonl")


def recompute(res):
    runs = res.get("runs") or []
    injuries = res.get("injuries") or []
    if not runs:
        return res.get("verdict", "?")  # AUTH_FAIL / SYNC_FAIL / HARNESS_ERR — leave as-is
    max_leak = max(r["n_leak"] for r in runs)
    min_ex = min(r["n_ex"] for r in runs)
    if max_leak > 0:
        return "LEAK"
    if min_ex == 0:
        return "EMPTY"
    if min_ex <= 2 and injuries:
        return "THIN"
    return "PASS"


def main():
    by_num = {}
    for line in JSONL.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        r = json.loads(line)
        runs = r.get("runs") or []
        old = r.get("verdict")
        r["verdict"] = recompute(r)
        r["leak_runs"] = sum(1 for x in runs if x["n_leak"] > 0)
        r["runs_done"] = len(runs)
        r["err"] = False  # the substring-500 flag was bogus; cleared
        if old != r["verdict"]:
            print(f"  #{r['num']:<2} {','.join(r.get('injuries') or ['none']):<28} "
                  f"{old:<6} -> {r['verdict']}")
        by_num[r["num"]] = r

    # Rewrite the JSONL with corrected verdicts (sorted by scenario number).
    with JSONL.open("w") as f:
        for n in sorted(by_num):
            f.write(json.dumps(by_num[n]) + "\n")

    write_md(by_num)

    c = Counter(r["verdict"] for r in by_num.values())
    leaks = sorted(n for n, r in by_num.items() if r["verdict"] == "LEAK")
    passes = sorted(n for n, r in by_num.items() if r["verdict"] == "PASS")
    empties = sorted(n for n, r in by_num.items() if r["verdict"] == "EMPTY")
    print(f"\n=== CORRECTED SUMMARY === {dict(c)}")
    print(f"LEAK:  {leaks}")
    print(f"PASS:  {passes}")
    print(f"EMPTY: {empties}")


if __name__ == "__main__":
    main()
