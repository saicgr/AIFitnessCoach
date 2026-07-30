#!/usr/bin/env python3
"""Rewrite program copy into plain language (E2E register row 91).

`audit_program_copy_clarity.py` was blind to the per-exercise prose inside
`program_variant_weeks.workouts`; commit dd3a4663 fixed the DETECTION and the
gate now fails over 57,814 week rows with 3,963 distinct unclear strings
(`exercise.weight_guidance` 3755, `exercise.form_cue` 140, `focus` 33,
`exercise.setup` 22, `exercise.breathing_cue` 7, `session.focus` 5,
`exercise.notes` 1). This script is the content half.

Deterministic, no LLM. Every rule TRANSLATES — nothing is deleted:

  RPE 7            -> effort 7 out of 10
  RPE 7-8          -> effort 7-8 out of 10
  70% 1RM          -> 70% of your heaviest single
  60-70% dl 1RM    -> 60-70% of your heaviest single deadlift
  85% 5RM          -> 85% of your heaviest set of 5
  eccentric        -> lowering            concentric   -> lifting
  unilateral       -> single-side         hypertrophy  -> muscle growth
  proprioception   -> balance awareness   neural drive -> power and speed
  time under tension -> time the muscle spends working
  "60s on 20s off" -> "60 seconds on 20 seconds off"
  "10-20% BW"      -> "10-20% of your body weight"

Every row it changes is copied to `program_variant_weeks_copy_backup` first
(full focus/phase/workouts snapshot), so any rewrite is reversible.

    .venv/bin/python scripts/rewrite_program_copy_plain_language.py            # dry run
    .venv/bin/python scripts/rewrite_program_copy_plain_language.py --apply

Then re-run:
    .venv/bin/python scripts/audit_program_copy_clarity.py --check
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

import psycopg2
import psycopg2.extras

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Prose fields the schedule tab renders (mirrors audit_program_copy_clarity).
EXERCISE_PROSE_FIELDS = (
    "weight_guidance", "form_cue", "setup", "breathing_cue", "notes",
    "coaching_cue",
)
SESSION_PROSE_FIELDS = ("focus", "notes", "description")


# ---------------------------------------------------------------------------
# Atom 1 — RPE n[-m]  ->  effort n[-m] out of 10
# ---------------------------------------------------------------------------
_RPE = re.compile(
    # The range separator and its surrounding space live INSIDE the optional
    # group, so "RPE 5 — easy" keeps its em dash instead of swallowing it.
    r"\bRPE\s*(\d+(?:\.\d+)?)(?:\s*[-–—]\s*(\d+(?:\.\d+)?))?", re.IGNORECASE
)


def _rpe(m: re.Match) -> str:
    lo, hi = m.group(1), m.group(2)
    span = f"{lo}-{hi}" if hi else lo
    return f"effort {span} out of 10"


# ---------------------------------------------------------------------------
# Atom 2 — n% [lift] mRM  ->  n% of your heaviest single / set of m [on lift]
# ---------------------------------------------------------------------------
# "60-70% deadlift 1RM" — a percentage OF a named lift's max.
_RM_PCT_LIFT = re.compile(
    r"(%\s*\+?)\s*(?:of\s+)?([A-Za-z][A-Za-z\- ]{2,20}?)\s+(\d+)\s*RM\b",
    re.IGNORECASE,
)
# "70% 1RM", "85%+ 1RM" — a percentage of the max.
_RM_PCT = re.compile(r"(%\s*\+?)\s*(\d+)\s*RM\b", re.IGNORECASE)
# "Squat 1RM testing" — the max itself, used as a NOUN. "of your heaviest
# single" only reads correctly after a percentage, so the bare form gets the
# noun phrase instead.
_RM_PLAIN = re.compile(r"\b(\d+)\s*RM\b", re.IGNORECASE)
_RM_BARE = re.compile(r"(?<![A-Za-z0-9])RM\b")


def _rm_noun(n: str) -> str:
    return "heaviest single" if n == "1" else f"heaviest set of {n}"


def _rm_pct(m: re.Match) -> str:
    return f"{m.group(1).strip()} of your {_rm_noun(m.group(2))}"


def _rm_pct_lift(m: re.Match) -> str:
    pct, lift, n = m.group(1).strip(), m.group(2).strip(), m.group(3)
    if n == "1":
        return f"{pct} of your heaviest single {lift}"
    return f"{pct} of your heaviest set of {n} on {lift}"


# ---------------------------------------------------------------------------
# Atom 3 — the residual jargon words, translated in context. Ordered: the
# multi-word phrases must run before the single words they contain.
# ---------------------------------------------------------------------------
_PHRASES = [
    (re.compile(r"\bmitochondrial supercompensation\b", re.I),
     "builds your aerobic engine"),
    (re.compile(r"\bsupercompensation\b", re.I),
     "the extra fitness you gain while recovering"),
    (re.compile(r"\btime under tension\b", re.I),
     "time the muscle spends working"),
    (re.compile(r"\bneural drive\b", re.I), "power and speed"),
    (re.compile(r"\bneural\b", re.I), "brain-to-muscle"),
    (re.compile(r"\bslow eccentric,\s*fast concentric\b", re.I),
     "slow lowering, fast lift"),
    (re.compile(r"\beccentric (?:descent|phase)\b", re.I), "lowering"),
    (re.compile(r"\bon (?:the )?concentric\b", re.I), "as you lift"),
    (re.compile(r"\bfor (?:the )?concentric\b", re.I), "for the lift"),
    (re.compile(r"\bconcentric\b", re.I), "lifting"),
    (re.compile(r"\beccentric\b", re.I), "lowering"),
    (re.compile(r"\bpropriocept(?:ion|ive)\b", re.I), "balance awareness"),
    (re.compile(r"\bhypertrophy\b", re.I), "muscle growth"),
    (re.compile(r"\bunilateral\b", re.I), "single-side"),
    (re.compile(r"\bmechanical tension\b", re.I), "steady load on the muscle"),
    (re.compile(r"\bmotor unit(s?)\b", re.I), r"muscle fibre\1"),
    (re.compile(r"\bautoregulat(?:e|ed|ion|ing)\b", re.I),
     "adjust to how you feel"),
    (re.compile(r"\bpotentiation\b", re.I), "priming"),
    (re.compile(r"\bperiodization\b", re.I), "planned progression"),
    (re.compile(r"\bglycolytic\b", re.I), "hard, breathless"),
    (re.compile(r"\blactate\b", re.I), "burn"),
    (re.compile(r"\banaerobic\b", re.I), "all-out, breathless"),
    (re.compile(r"\bmyofibrillar\b", re.I), "strength-focused"),
    (re.compile(r"\bsarcoplasmic\b", re.I), "size-focused"),
    (re.compile(r"\bsupramaximal\b", re.I), "heavier than your best lift"),
    (re.compile(r"\bcontractile\b", re.I), "muscle-working"),
    (re.compile(r"\bosteogenic\b", re.I), "bone-strengthening"),
    (re.compile(r"\bCNS\b"), "nervous system"),
]

# ---------------------------------------------------------------------------
# Atom 4 — cryptic numeric shorthand.
# ---------------------------------------------------------------------------
_SECONDS = re.compile(r"\b(\d+)s\b")
_BW = re.compile(r"%\s*BW\b")
_PER_BW = re.compile(r"\bBW\b(?!\s*[)\]])")


def _preserve_case(original: str, replacement: str) -> str:
    """Keep sentence capitalization when the source word was capitalized."""
    if original[:1].isupper() and replacement[:1].islower():
        return replacement[:1].upper() + replacement[1:]
    return replacement


def rewrite(text: str) -> str:
    """Plain-language rewrite of one prose string. Idempotent."""
    if not text or not isinstance(text, str):
        return text
    out = _RPE.sub(_rpe, text)
    out = _RM_PCT_LIFT.sub(_rm_pct_lift, out)
    out = _RM_PCT.sub(_rm_pct, out)
    out = _RM_PLAIN.sub(lambda m: _rm_noun(m.group(1)), out)
    out = _RM_BARE.sub("heaviest lift", out)
    for pat, repl in _PHRASES:
        def _sub(m, _r=repl):
            expanded = m.expand(_r) if "\\" in _r else _r
            return _preserve_case(m.group(0), expanded)
        out = pat.sub(_sub, out)
    # "60s on 20s off" — only when the string LEADS with the shorthand or uses
    # the a/b form; a trailing "x10" or "30s" inside prose reads fine expanded
    # either way, so expand every bare Ns token.
    if re.search(r"(^\s*\d+s\b|\b\d+s\s*/\s*\d+s\b|\b\d+s\b)", out):
        out = _SECONDS.sub(lambda m: f"{m.group(1)} seconds", out)
    out = _BW.sub("% of your body weight", out)
    out = _PER_BW.sub("body weight", out)
    out = re.sub(r"\s{2,}", " ", out).strip()
    # "RPE 7" / "1RM Testing" opened with a capital or a digit; keep the line
    # sentence-cased after the leading token is translated.
    if out and text[:1].isalnum() and not text[:1].islower() \
            and out[:1].islower():
        out = out[:1].upper() + out[1:]
    return out


def rewrite_workouts(workouts):
    """Rewrite every prose string in a week's `workouts` array. Returns
    (new_workouts, n_changed_strings)."""
    changed = 0
    if not isinstance(workouts, list):
        return workouts, 0
    for sess in workouts:
        if not isinstance(sess, dict):
            continue
        for f in SESSION_PROSE_FIELDS:
            v = sess.get(f)
            if isinstance(v, str) and v.strip():
                nv = rewrite(v)
                if nv != v:
                    sess[f] = nv
                    changed += 1
        for block in ("exercises", "warmup", "cooldown"):
            for ex in sess.get(block) or []:
                if not isinstance(ex, dict):
                    continue
                for f in EXERCISE_PROSE_FIELDS:
                    v = ex.get(f)
                    if isinstance(v, str) and v.strip():
                        nv = rewrite(v)
                        if nv != v:
                            ex[f] = nv
                            changed += 1
    return workouts, changed


def dsn() -> str:
    d = os.environ.get("DATABASE_URL", "")
    if not d:
        print("DATABASE_URL is not set", file=sys.stderr)
        sys.exit(2)
    d = d.replace("postgresql+asyncpg://", "postgresql://")
    if "sslmode" not in d:
        d += ("&" if "?" in d else "?") + "sslmode=require"
    return d


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--samples", type=int, default=25)
    args = ap.parse_args()

    conn = psycopg2.connect(dsn())
    conn.autocommit = False
    cur = conn.cursor(name="pvw_scan", cursor_factory=psycopg2.extras.DictCursor)
    cur.itersize = 500
    cur.execute(
        "SELECT id, variant_id, week_number, focus, phase, workouts "
        "FROM program_variant_weeks ORDER BY id"
    )

    updates = []
    backups = []
    samples = []
    n_rows = n_strings = 0
    for r in cur:
        focus, phase = r["focus"], r["phase"]
        new_focus = rewrite(focus) if isinstance(focus, str) else focus
        new_phase = rewrite(phase) if isinstance(phase, str) else phase
        workouts = r["workouts"]
        new_workouts, changed = rewrite_workouts(workouts)
        col_changed = (new_focus != focus) + (new_phase != phase)
        if not changed and not col_changed:
            continue
        n_rows += 1
        n_strings += changed + col_changed
        if len(samples) < args.samples:
            if new_focus != focus:
                samples.append(("focus", focus, new_focus))
        backups.append((
            r["id"], r["variant_id"], r["week_number"], focus, phase,
            json.dumps(workouts) if workouts is not None else None,
        ))
        updates.append((
            new_focus, new_phase,
            json.dumps(new_workouts) if new_workouts is not None else None,
            r["id"],
        ))
    cur.close()

    print(f"rows to rewrite: {n_rows}  (strings changed: {n_strings})")
    for path, before, after in samples[:args.samples]:
        print(f"  [{path}] {before[:80]!r}\n        -> {after[:80]!r}")

    if not args.apply:
        print("dry run — pass --apply to write")
        conn.rollback()
        return 0
    if not updates:
        print("nothing to write")
        return 0

    with conn.cursor() as w:
        w.execute("""
            CREATE TABLE IF NOT EXISTS program_variant_weeks_copy_backup (
                id            bigserial PRIMARY KEY,
                week_row_id   uuid NOT NULL,
                variant_id    uuid,
                week_number   integer,
                focus         text,
                phase         text,
                workouts      jsonb,
                reason        text DEFAULT 'row91_plain_language_rewrite',
                backed_up_at  timestamptz NOT NULL DEFAULT now()
            )
        """)
        psycopg2.extras.execute_batch(
            w,
            "INSERT INTO program_variant_weeks_copy_backup "
            "(week_row_id, variant_id, week_number, focus, phase, workouts) "
            "VALUES (%s,%s,%s,%s,%s,%s::jsonb)",
            backups, page_size=200,
        )
        psycopg2.extras.execute_batch(
            w,
            "UPDATE program_variant_weeks "
            "SET focus = %s, phase = %s, workouts = %s::jsonb WHERE id = %s",
            updates, page_size=200,
        )
    conn.commit()
    conn.close()
    print(f"backed up {len(backups)} rows; rewrote {len(updates)} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
