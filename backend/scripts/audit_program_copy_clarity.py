"""
Audit program copy for exercise-science jargon and cryptic shorthand.

Why: 2026-07-04 a user could not understand "1 × 4×4 VO2max day + zone-2
volume" (schedule-tab week focus). A full sweep found 1,627 distinct
jargon-heavy focus strings across the catalog ("supercompensation", "CNS
restoration", "neural drive", "RPE 7-8", "Wave 1 — Volume 8s", "@ ~5% BW"...).
All were rewritten to plain language, but newly generated programs (Gemini
authors free-text focus lines) can reintroduce jargon. This gate catches that.

Usage:
    python scripts/audit_program_copy_clarity.py --check                 # whole catalog
    python scripts/audit_program_copy_clarity.py --check --since 2026-07-04
        # only programs created on/after DATE (use after a generation run)

Exit 1 when any focus/phase string fails the clarity lint.

Environment: SUPABASE_URL, SUPABASE_SERVICE_KEY (via core.supabase_client)
"""

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402

# Word-boundary matters: plain "RPE" also matches inside "sharpen"/"burpee".
JARGON = re.compile(
    r"\b(supercompensation|CNS|neural|RPE\s*\d|mechanical tension|motor unit"
    r"|anaerobic|unilateral|eccentric|concentric|time under tension"
    r"|metabolic (?:demand|efficiency|stress)|hypertrophy|propriocept\w*"
    r"|glycolytic|lactate|myofibrillar|sarcoplasmic|autoregulat\w*"
    r"|supramaximal|potentiation|contractile|osteogenic|periodization)\b",
    re.IGNORECASE,
)

# Cryptic shorthand patterns (numeric notation with no words explaining it).
SHORTHAND = [
    re.compile(r"%\s*BW\b"),                      # "@ ~5% BW"
    re.compile(r"^\d+s\b"),                        # "30s rope intervals"
    re.compile(r"\b\d+s/\d+s\b"),                  # "30s/30s intervals"
    re.compile(r"—\s*(Volume|Strength|Intensity)\s+\d+s\b"),  # "Volume 8s"
    re.compile(r"^Run/Walk \d"),                   # "Run/Walk 1:1.5"
    re.compile(r"\d\s*×\s*\d+×\d+"),               # "1 × 4×4"
]


def fetch_weeks(db, since):
    """(program_name, focus, phase) rows, paginated with a stable order."""
    prog_names = {}
    if since:
        progs = db.client.table("programs").select(
            "variant_base_id, editorial_name, created_at"
        ).gte("created_at", since).execute().data or []
        base_ids = {p["variant_base_id"] for p in progs if p.get("variant_base_id")}
        if not base_ids:
            return []
        variants = db.client.table("program_variants").select(
            "id, base_program_id"
        ).in_("base_program_id", list(base_ids)).execute().data or []
        vids = [v["id"] for v in variants]
    else:
        vids = None

    rows, offset = [], 0
    while True:
        q = db.client.table("program_variant_weeks").select(
            "variant_id, week_number, focus, phase"
        ).order("id").range(offset, offset + 999)
        if vids is not None:
            q = q.in_("variant_id", vids)
        batch = q.execute().data or []
        rows.extend(batch)
        if len(batch) < 1000:
            return rows
        offset += 1000


def lint(text):
    if not text:
        return None
    m = JARGON.search(text)
    if m:
        return f"jargon:{m.group(0)}"
    for pat in SHORTHAND:
        if pat.search(text):
            return f"shorthand:{pat.pattern}"
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--since", default=None, help="only programs created >= DATE")
    args = ap.parse_args()

    db = get_supabase()
    rows = fetch_weeks(db, args.since)
    print(f"linting {len(rows)} week rows ...")

    failures = {}
    for r in rows:
        for col in ("focus", "phase"):
            why = lint(r.get(col))
            if why:
                key = (col, r.get(col))
                failures.setdefault(key, []).append(r["variant_id"])

    if not failures:
        print("OK: no jargon or cryptic shorthand in program copy")
        sys.exit(0)

    print(f"FAIL: {len(failures)} distinct unclear strings:")
    for (col, text), vids in sorted(failures.items()):
        print(f"  [{col}] ({len(vids)} rows) {text[:140]}")
    sys.exit(1)


if __name__ == "__main__":
    main()
