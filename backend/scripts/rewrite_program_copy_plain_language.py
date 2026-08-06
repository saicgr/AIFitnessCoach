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
SESSION_PROSE_FIELDS = (
    "focus", "notes", "description", "coach_notes", "workout_description",
    "rounds_note",
)
# `workout_name` is a TITLE — the Schedule-tab day heading and, once the program
# is started, `workouts.name` on the Today card. It gets the same translation
# but title-cased, so "Back & Shoulders Hypertrophy" becomes "Back & Shoulders
# Muscle Growth" rather than "Back & Shoulders Muscle growth".
SESSION_TITLE_FIELDS = ("workout_name",)

# Exact-match rewrite for `program_variant_weeks.phase` (row 35, 2026-08).
# These are precisely the labels determine_phase()/​_derive_phase() used to
# emit (scripts/generate_programs.py, scripts/program_sql_helper.py,
# services/program_duration_service.py — since fixed to plain language
# directly). Existing rows generated before that fix still carry the old
# jargon, so this maps them onto the SAME new labels those functions now
# produce, keeping old and newly-generated programs consistent. Case-sensitive
# exact match only — anything not listed here falls through to the
# word-level `rewrite()` below (covers the long tail of one-off phase strings
# like "Volume Accumulation" via the `_PHRASES` jargon-word rules).
PHASE_LABEL_MAP = {
    "Foundation (Base Building)": "Building Your Foundation",
    "Build (Progressive Overload)": "Building Strength and Volume",
    "Peak (Intensification)": "Peak Effort",
    "Taper (Deload)": "Easing Off to Recover",
    "Test/Maintenance": "Testing Your Progress",
    "Deload": "Recovery Week",
    "Blueprint (Aerobic Foundation)": "Building Your Aerobic Base",
    "Build (Race-Specific)": "Race-Specific Training",
    "Race (Peak Performance)": "Peak Race Performance",
    "Taper/Race Week": "Tapering for Race Week",
}


# ---------------------------------------------------------------------------
# Atom 1 — RPE n[-m]  ->  effort n[-m] out of 10
# ---------------------------------------------------------------------------
_RPE = re.compile(
    # The range separator and its surrounding space live INSIDE the optional
    # group, so "RPE 5 — easy" keeps its em dash instead of swallowing it.
    r"\bRPE\s*(\d+(?:\.\d+)?)(?:\s*[-–—]\s*(\d+(?:\.\d+)?))?", re.IGNORECASE
)


# Bare "RPE" used as a noun — "Push the RPE on your main compounds". No digit,
# so the numbered rule never touched it and the jargon survived every pass.
# \b keeps it off "burpee" / "sharpen" (both have a word char before the r).
_RPE_BARE = re.compile(r"\bRPE\b", re.IGNORECASE)


def _rpe(m: re.Match) -> str:
    lo, hi = m.group(1), m.group(2)
    span = f"{lo}-{hi}" if hi else lo
    return f"effort {span} out of 10"


# ---------------------------------------------------------------------------
# Atom 1b — RIR ("reps in reserve") notation -> plain language (row 103/35).
# Real catalog forms (2026-08 sweep of `weight_guidance`): "RIR 1-2
# (Bodyweight)", "Bodyweight (RIR 1-2)", "RIR 0 (failure)", "Effort 9 out of
# 10 (1-2 RIR)" (number BEFORE "RIR" too), plus the spelled-out "leave 1-2
# reps in reserve" / "should feel 2 reps in reserve" / "plenty of reps in
# reserve". All of these collapse to ONE plain noun phrase — "N reps in the
# tank" — kept as a noun phrase (not a full sentence rewrite) so it drops
# into any of the surrounding grammar without contorting it, same discipline
# _rm_noun() uses below. Ordered most-specific first.
# ---------------------------------------------------------------------------
_RIR_PAREN = re.compile(
    r"\(RIR\s*(\d+(?:\s*[-–—]\s*\d+)?)\)", re.IGNORECASE
)
# Reversed order — "(1-2 RIR)".
_NUM_RIR_PAREN = re.compile(
    r"\((\d+(?:\s*[-–—]\s*\d+)?)\s*RIR\)", re.IGNORECASE
)
_RIR_BARE_NUM = re.compile(
    r"\bRIR\s*(\d+(?:\s*[-–—]\s*\d+)?)\b", re.IGNORECASE
)
_NUM_RIR_BARE = re.compile(
    r"\b(\d+(?:\s*[-–—]\s*\d+)?)\s*RIR\b", re.IGNORECASE
)
# "leave 1-2 reps in reserve" / "should feel 2 reps in reserve" / "aim for
# 0-1 reps in reserve" — the verb phrase before the number varies, so only the
# number-and-noun tail is captured and re-composed.
_REPS_IN_RESERVE_NUM = re.compile(
    r"\b(\d+(?:\s*[-–—]\s*\d+)?)\s+reps?\s+in\s+reserve\b", re.IGNORECASE
)
_REPS_IN_RESERVE_BARE = re.compile(r"\breps?\s+in\s+reserve\b", re.IGNORECASE)
_RIR_BARE = re.compile(r"\bRIR\b")


def _reserve_span(span: str) -> str:
    return re.sub(r"\s*[-–—]\s*", "-", span.strip())


def _rir_noun(span: str) -> str:
    n = _reserve_span(span)
    return f"{n} rep{'' if n == '1' else 's'} in the tank"


def _reps_in_reserve_num(m: re.Match) -> str:
    return _rir_noun(m.group(1))


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
    # Plurals used as nouns ("controlled eccentrics") — the singular rules
    # below have a word boundary after the "c" and never matched these.
    (re.compile(r"\beccentrics\b", re.I), "lowering reps"),
    (re.compile(r"\bconcentrics\b", re.I), "lifting reps"),
    (re.compile(r"\bmetabolic stress\b", re.I), "muscle burn"),
    (re.compile(r"\bmetabolic demand\b", re.I), "how hard your body works"),
    (re.compile(r"\bmetabolic efficiency\b", re.I),
     "how efficiently your body uses fuel"),
    (re.compile(r"\bmetabolic conditioning\b", re.I),
     "breathless conditioning work"),
    # Noun phrase, so it has to stay a noun phrase — "push your metabolic
    # limits" must not become "push your how much work your body can handle".
    (re.compile(r"\bmetabolic limits\b", re.I), "physical limits"),
    (re.compile(r"\bmetabolic\b", re.I), "energy-burning"),
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
    # 2026-08 sweep (row 35/102) — phase-label + focus-line jargon that shipped
    # to thousands of program_variant_weeks rows while the old JARGON list
    # reported clean. Compound phrases before the single words they contain.
    (re.compile(r"\bneuromuscular recruitment\b", re.I), "muscle engagement"),
    (re.compile(r"\bmuscle recruitment\b", re.I), "muscle engagement"),
    (re.compile(r"\bdeep core recruitment\b", re.I), "deep core engagement"),
    (re.compile(r"\bneuromuscular\b", re.I), "muscle-and-nerve"),
    (re.compile(r"\brecruitment\b", re.I), "engagement"),
    (re.compile(r"\bvolume accumulation\b", re.I), "training volume buildup"),
    (re.compile(r"\baccumulation\b", re.I), "buildup"),
    (re.compile(r"\bintensification\b", re.I), "harder effort"),
    (re.compile(r"\bdeloaded\b", re.I), "eased off the load"),
    (re.compile(r"\bdeloading\b", re.I), "easing off the load"),
    (re.compile(r"\bto deload\b", re.I), "to ease off the load"),
    (re.compile(r"\bdeload\b", re.I), "recovery week"),
    (re.compile(r"\bprogressive overload\b", re.I), "gradually adding weight"),
    # Authoring scaffolding that leaked into user-facing focus text — Gemini
    # referencing its own multi-phase generation structure instead of
    # describing the workout (row 102: "...in Phase 2"). Translated, not
    # deleted, per repo policy — "in the next phase" reads naturally in every
    # sentence this appeared in ("...to prepare for increased intensity in
    # the next phase").
    (re.compile(r"\bin Phase \d+\b", re.I), "in the next phase"),
]

# ---------------------------------------------------------------------------
# Atom 4 — cryptic numeric shorthand.
# ---------------------------------------------------------------------------
# "Strength 5s" / "Volume 8s" is a REP scheme, not a duration — expanding it as
# "5 seconds" would state the opposite of what the block prescribes, so it is
# translated first and the seconds rule never sees it.
_SET_REP_SHORTHAND = re.compile(
    r"\b(Volume|Strength|Intensity|Power|Speed)\s+(\d+)s\b", re.IGNORECASE
)
_SECONDS = re.compile(r"\b(\d+)s\b")
_BW = re.compile(r"%\s*BW\b")
_PER_BW = re.compile(r"\bBW\b(?!\s*[)\]])")
# Row 110, 2026-08: interval descriptions like "3 rounds: 1 min hard, 0.5 min
# easy" — a decimal minute is not how anyone reads a rest interval. Convert
# to whole seconds instead ("0.5 min" -> "30 sec", "1.5 min" -> "90 sec").
_FRACTIONAL_MIN = re.compile(r"\b(\d+\.\d+)\s*(?:minutes?|min)\b", re.IGNORECASE)


def _fractional_min_to_sec(m: "re.Match") -> str:
    seconds = round(float(m.group(1)) * 60)
    return f"{seconds} sec"


def _preserve_case(original: str, replacement: str) -> str:
    """Keep sentence capitalization when the source word was capitalized."""
    if original[:1].isupper() and replacement[:1].islower():
        return replacement[:1].upper() + replacement[1:]
    return replacement


def _title_phrase(replacement: str) -> str:
    """Title-case a replacement noun phrase for use inside a heading."""
    return " ".join(
        w if w.isupper() else w[:1].upper() + w[1:] for w in replacement.split(" ")
    )


def rewrite(text: str, *, title: bool = False) -> str:
    """Plain-language rewrite of one prose string. Idempotent.

    `title=True` renders the substituted noun phrases in Title Case, for the
    fields that are headings rather than sentences (`workout_name`).
    """
    if not text or not isinstance(text, str):
        return text

    def _starts_a_sentence(m: re.Match) -> bool:
        """An ACRONYM (RPE, CNS, 1RM) is capitalized wherever it appears, so
        copying its capitalization onto the replacement produced 'Push the
        Effort level on...' mid-sentence. Capitalize only where a sentence
        actually starts."""
        before = m.string[: m.start()].rstrip()
        return not before or before[-1] in ".!?:;—-–("

    def _shape(m: re.Match, replacement: str) -> str:
        original = m.group(0)
        # "1RM Test Day" starts with a digit, so isupper() alone would leave
        # "Back Squat heaviest single Test Day" mid-sentence-cased in a heading.
        if title and (original[:1].isupper() or original[:1].isdigit()):
            return _title_phrase(replacement)
        if not _starts_a_sentence(m):
            return replacement
        return _preserve_case(original, replacement)

    out = _RPE.sub(_rpe, text)
    out = _RPE_BARE.sub(lambda m: _shape(m, "effort level"), out)
    # RIR ("reps in reserve") — most-specific forms first, same discipline
    # as RPE above: the numbered forms must run before the bare noun phrase
    # they contain, or "leave 1-2 reps in reserve" would half-translate then
    # get re-touched by the bare rule. Parenthetical (both orders) before
    # bare, since "(RIR 1-2)" and "(1-2 RIR)" both contain a bare-number form.
    out = _RIR_PAREN.sub(lambda m: f"({_rir_noun(m.group(1))})", out)
    out = _NUM_RIR_PAREN.sub(lambda m: f"({_rir_noun(m.group(1))})", out)
    out = _REPS_IN_RESERVE_NUM.sub(_reps_in_reserve_num, out)
    out = _RIR_BARE_NUM.sub(lambda m: _shape(m, _rir_noun(m.group(1))), out)
    out = _NUM_RIR_BARE.sub(lambda m: _shape(m, _rir_noun(m.group(1))), out)
    out = _REPS_IN_RESERVE_BARE.sub(
        lambda m: _shape(m, "reps in the tank"), out
    )
    out = _RIR_BARE.sub(lambda m: _shape(m, "reps in the tank"), out)
    out = _RM_PCT_LIFT.sub(_rm_pct_lift, out)
    out = _RM_PCT.sub(_rm_pct, out)
    out = _RM_PLAIN.sub(lambda m: _shape(m, _rm_noun(m.group(1))), out)
    out = _RM_BARE.sub(lambda m: _shape(m, "heaviest lift"), out)
    for pat, repl in _PHRASES:
        def _sub(m, _r=repl):
            expanded = m.expand(_r) if "\\" in _r else _r
            return _shape(m, expanded)
        out = pat.sub(_sub, out)
    # "60s on 20s off" — only when the string LEADS with the shorthand or uses
    # the a/b form; a trailing "x10" or "30s" inside prose reads fine expanded
    # either way, so expand every bare Ns token.
    out = _SET_REP_SHORTHAND.sub(
        lambda m: f"{m.group(1)} sets of {m.group(2)}", out
    )
    if re.search(r"(^\s*\d+s\b|\b\d+s\s*/\s*\d+s\b|\b\d+s\b)", out):
        out = _SECONDS.sub(lambda m: f"{m.group(1)} seconds", out)
    out = _FRACTIONAL_MIN.sub(_fractional_min_to_sec, out)
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
        for f in SESSION_TITLE_FIELDS:
            v = sess.get(f)
            if isinstance(v, str) and v.strip():
                nv = rewrite(v, title=True)
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
        # `phase` is a short label, not a sentence — exact-match it against
        # the canonical labels determine_phase() now produces first (keeps old
        # rows byte-identical to newly generated ones), then fall through to
        # the word-level rewrite (title-cased, since it's a heading) for any
        # phase string not in that fixed set.
        if isinstance(phase, str) and phase in PHASE_LABEL_MAP:
            new_phase = PHASE_LABEL_MAP[phase]
        elif isinstance(phase, str):
            new_phase = rewrite(phase, title=True)
        else:
            new_phase = phase
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
            if new_phase != phase:
                samples.append(("phase", phase, new_phase))
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
