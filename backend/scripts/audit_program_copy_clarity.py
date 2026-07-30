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

# Word-boundary matters: plain "RPE" also matches inside "sharpen"/"burpee" —
# but only WITHOUT \b, since both have a word character before the "r". With the
# boundary, bare `RPE` used as a noun ("Push the RPE on your main compounds") is
# caught too; requiring a digit let that form through every pass.
JARGON = re.compile(
    r"\b(supercompensation|CNS|neural|RPE|\d*\s*RM\b|mechanical tension|motor unit"
    r"|anaerobic|unilateral|eccentric|concentric|time under tension"
    # Bare `metabolic` — "metabolic conditioning" / "metabolic limits" slipped
    # past the three-noun enumeration this used to be.
    r"|metabolic|hypertrophy|propriocept\w*"
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
        progs, p_off = [], 0
        while True:
            p_batch = db.client.table("programs").select(
                "variant_base_id, editorial_name, created_at"
            ).gte("created_at", since).order("id").range(
                p_off, p_off + 999
            ).execute().data or []
            progs.extend(p_batch)
            if len(p_batch) < 1000:
                break
            p_off += 1000
        base_ids = {p["variant_base_id"] for p in progs if p.get("variant_base_id")}
        if not base_ids:
            return []
        # PostgREST caps an unpaginated .execute() at 1000 rows, so the
        # `--since` set was silently truncated — the exact invocation CLAUDE.md
        # prescribes after a generation run could miss whole variants.
        vids = []
        v_off = 0
        while True:
            v_batch = db.client.table("program_variants").select(
                "id, base_program_id"
            ).in_("base_program_id", list(base_ids)).order("id").range(
                v_off, v_off + 999
            ).execute().data or []
            vids.extend(v["id"] for v in v_batch)
            if len(v_batch) < 1000:
                break
            v_off += 1000
    else:
        vids = None

    rows, offset = [], 0
    page = 200  # 1000-row pages of `workouts` jsonb 57014'd on PostgREST
    while True:
        q = db.client.table("program_variant_weeks").select(
            "variant_id, week_number, focus, phase, workouts"
        ).order("id").range(offset, offset + page - 1)
        if vids is not None:
            q = q.in_("variant_id", vids)
        batch = q.execute().data or []
        rows.extend(batch)
        if len(batch) < page:
            return rows
        offset += page


def fetch_weeks_direct(since):
    """Same rows straight from Postgres with a server-side cursor.

    `workouts` is a fat jsonb column and the catalog is ~58k week rows — the
    PostgREST path times out (57014) on a full-catalog run, which would leave
    this gate unrunnable exactly when it matters. Used whenever DATABASE_URL is
    present; the PostgREST path stays as the fallback."""
    import psycopg2  # local import: only needed on this path

    dsn = os.environ["DATABASE_URL"].replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    if "sslmode" not in dsn:
        dsn += ("&" if "?" in dsn else "?") + "sslmode=require"
    sql = (
        "SELECT w.variant_id, w.week_number, w.focus, w.phase, w.workouts "
        "FROM program_variant_weeks w"
    )
    params = ()
    if since:
        sql += (
            " JOIN program_variants v ON v.id = w.variant_id"
            " JOIN programs p ON p.variant_base_id = v.base_program_id"
            " WHERE p.created_at >= %s"
        )
        params = (since,)
    conn = psycopg2.connect(dsn)
    try:
        cur = conn.cursor(name="copy_clarity_scan")
        cur.itersize = 500
        cur.execute(sql, params)
        return [
            {"variant_id": r[0], "week_number": r[1], "focus": r[2],
             "phase": r[3], "workouts": r[4]}
            for r in cur
        ]
    finally:
        conn.close()


# Free-text, user-facing prose inside `program_variant_weeks.workouts`. The
# schedule tab renders these per exercise, so they need the same plain-language
# bar as focus/phase — linting only focus/phase let "~60.0% 1RM (RPE 5 — easy)"
# ship to 10,691 week rows across 1,835 variants while this gate reported clean.
# Deliberately NOT linted: name / equipment / primary_muscle / body_part /
# difficulty / substitution are controlled vocabulary, not prose.
EXERCISE_PROSE_FIELDS = (
    "weight_guidance",
    "form_cue",
    "setup",
    "breathing_cue",
    "notes",
    "coaching_cue",
)
# `workout_name` IS user-facing free text, not controlled vocabulary: it is the
# day title on the Schedule tab (program_templates.py `day_name`) and becomes
# `workouts.name` — the Today card / workout-detail title — once the program is
# started (program_template_expander `day["day_name"]`). Gemini authors it from
# the same prompt as `focus` (generate_programs.py), and it carried 322 distinct
# jargon titles ("Hypertrophy Upper", "Back Squat 1RM Test Day") while this gate
# reported clean. `coach_notes` is the same: 1,028 distinct free-text notes.
SESSION_PROSE_FIELDS = (
    "focus", "notes", "description", "workout_name", "coach_notes",
    "workout_description", "rounds_note",
)
# The warmup / cooldown arrays hold exercise dicts with the SAME prose keys as
# `exercises` (37,058 sessions carry each) and were never walked — 111 distinct
# RPE-bearing strings ("Bodyweight (RPE 2)", "Moderate stretch (RPE 6-7)") sat
# permanently outside the gate.
EXERCISE_BLOCKS = ("exercises", "warmup", "cooldown")


def iter_workout_copy(workouts):
    """Yield (field_path, text) for every user-facing string in a week's
    `workouts` array. Shape-tolerant: bad/legacy rows are skipped, never raised."""
    if not isinstance(workouts, list):
        return
    for sess in workouts:
        if not isinstance(sess, dict):
            continue
        for f in SESSION_PROSE_FIELDS:
            v = sess.get(f)
            if isinstance(v, str) and v.strip():
                yield f"session.{f}", v
        for block in EXERCISE_BLOCKS:
            for ex in sess.get(block) or []:
                if not isinstance(ex, dict):
                    continue
                for f in EXERCISE_PROSE_FIELDS:
                    v = ex.get(f)
                    if isinstance(v, str) and v.strip():
                        label = (
                            "exercise" if block == "exercises" else block
                        )
                        yield f"{label}.{f}", v


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

    if os.environ.get("DATABASE_URL"):
        rows = fetch_weeks_direct(args.since)
    else:
        rows = fetch_weeks(get_supabase(), args.since)
    print(f"linting {len(rows)} week rows ...")

    failures = {}
    for r in rows:
        for col in ("focus", "phase"):
            why = lint(r.get(col))
            if why:
                key = (col, r.get(col))
                failures.setdefault(key, []).append(r["variant_id"])
        # Per-session / per-exercise copy the schedule tab renders.
        for path, text in iter_workout_copy(r.get("workouts")):
            why = lint(text)
            if why:
                failures.setdefault((path, text), []).append(r["variant_id"])

    if not failures:
        print("OK: no jargon or cryptic shorthand in program copy")
        sys.exit(0)

    print(f"FAIL: {len(failures)} distinct unclear strings:")
    for (col, text), vids in sorted(failures.items()):
        print(f"  [{col}] ({len(vids)} rows) {text[:140]}")
    sys.exit(1)


if __name__ == "__main__":
    main()
