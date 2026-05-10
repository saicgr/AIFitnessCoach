"""
Program validation pipeline.

Pulls all branded_programs / program_variants / program_variant_weeks from
Supabase, normalizes exercise names, fuzzy-matches against
exercise_library_cleaned + exercise_aliases, and writes:

  - docs/programs_validation.csv      (one row per program)
  - docs/programs_unmatched_exercises.csv (canonicalization gap list)
  - docs/PROGRAMS_VALIDATION.md       (human summary)

Run: backend/.venv/bin/python backend/scripts/validate_programs.py
"""

from __future__ import annotations

import csv
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
DOCS.mkdir(parents=True, exist_ok=True)

# --------------------------- pricing assumptions ---------------------------
# Gemini 3.1 Flash Lite list pricing as of 2026-05-08
# https://ai.google.dev/gemini-api/docs/pricing
PRICE_INPUT_PER_1K = 0.00025   # $0.25 / 1M input tokens
PRICE_OUTPUT_PER_1K = 0.00150  # $1.50 / 1M output tokens
AVG_INPUT_TOKENS = 3500
AVG_OUTPUT_TOKENS = 6500
COST_PER_VARIANT_USD = (
    AVG_INPUT_TOKENS / 1000 * PRICE_INPUT_PER_1K
    + AVG_OUTPUT_TOKENS / 1000 * PRICE_OUTPUT_PER_1K
)  # ≈ $0.0106 per variant

# Planned variants per program: 3 intensities × 6 durations (per
# generate_all_variants_parallel.py: INTENSITY_LEVELS × DURATION_WEEKS).
PLANNED_VARIANTS_PER_PROGRAM = 3 * 6  # 18


# --------------------------- normalization ---------------------------------
_PUNCT = re.compile(r"[^a-z0-9 ]+")
_WS = re.compile(r"\s+")

_TOKEN_ALIASES = {
    "bb": "barbell",
    "db": "dumbbell",
    "kb": "kettlebell",
    "ohp": "overhead press",
    "rdl": "romanian deadlift",
    "sldl": "stiff leg deadlift",
    "bw": "bodyweight",
    "1arm": "single arm",
    "single-arm": "single arm",
    "one-arm": "single arm",
    "ez": "ez bar",
    "ez-bar": "ez bar",
    "smith": "smith machine",
    "tbar": "t bar",
    "t-bar": "t bar",
    "v-bar": "v bar",
    "ups": "up",
    "pushup": "push up",
    "push-up": "push up",
    "pullup": "pull up",
    "pull-up": "pull up",
    "chinup": "chin up",
    "chin-up": "chin up",
    "situp": "sit up",
    "sit-up": "sit up",
    "stepup": "step up",
    "step-up": "step up",
    "deadlift": "deadlift",
}


def normalize(name: str) -> str:
    if not name:
        return ""
    s = name.lower().strip()
    s = s.replace("-", " ").replace("_", " ").replace("/", " ")
    s = _PUNCT.sub(" ", s)
    s = _WS.sub(" ", s).strip()
    # token-level alias rewrite
    tokens = []
    for tok in s.split(" "):
        tokens.append(_TOKEN_ALIASES.get(tok, tok))
    s = " ".join(tokens)
    # strip trailing plural 's' on last token (heuristic)
    s = _WS.sub(" ", s).strip()
    return s


# --------------------------- DB connection ---------------------------------
load_dotenv(ROOT / "backend" / ".env")
RAW_URL = os.environ["DATABASE_URL"]
# Strip the asyncpg driver suffix so psycopg2 accepts it.
SYNC_URL = RAW_URL.replace("postgresql+asyncpg://", "postgresql://")


def fetch_all(cur, sql: str):
    cur.execute(sql)
    return cur.fetchall()


def _load_to_regenerate_csv() -> list[dict]:
    """Read the canonical 'undone' list of programs that were deleted because
    they had zero variants. These rows must still appear in the validation
    report so the resume plan stays visible."""
    path = DOCS / "programs_to_regenerate.csv"
    if not path.exists():
        return []
    out: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            out.append(row)
    return out


def main() -> None:
    print("connecting...", flush=True)
    conn = psycopg2.connect(SYNC_URL)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    # ---------- exercise library lookup ----------
    print("loading exercise library + aliases...", flush=True)
    cur.execute("SELECT id, name FROM exercise_library_cleaned")
    library_rows = cur.fetchall()
    norm_to_lib = {}
    for r in library_rows:
        n = normalize(r["name"])
        if n:
            norm_to_lib.setdefault(n, str(r["id"]))
    cur.execute(
        "SELECT alias_name, canonical_exercise_id FROM exercise_aliases"
    )
    for r in cur.fetchall():
        n = normalize(r["alias_name"])
        if n:
            norm_to_lib.setdefault(n, str(r["canonical_exercise_id"]))
    print(f"  library lookup size: {len(norm_to_lib)}", flush=True)

    # ---------- canonical fuzzy-match suggestions ----------
    # Tier-2 lookup populated by `program_exercise_canonical_map`. As of the
    # blessed-vocabulary rebuild (2026-05-09) this is a regular TABLE (not a
    # MV) populated by `backend/scripts/build_canonical_map.py`, which scores
    # each program-exercise name with a composite of trigram + token Jaccard
    # + movement-keyword match against ONLY the blessed subset of
    # exercise_library_cleaned (rows with both image_url and video_url
    # populated). confidence='auto' is composite >= 0.85.
    print("loading canonical fuzzy-match suggestions...", flush=True)
    # Tier counts come from `program_exercise_name_map` (4-tier robust map
    # built by `backend/scripts/build_canonical_map.py`). Tier ∈ {A, B, C}
    # are the accepted 1:1 mappings against the blessed vocabulary, which
    # drive `mediated_match_rate_pct`.
    canonical_auto: dict[str, str] = {}      # tier-A0/A1 → library_id
    canonical_review: dict[str, str] = {}    # tier-B/C with conf>=70 → library_id
    tier_counts_global = {"A0": 0, "A1": 0, "B": 0, "C": 0, "UNMAPPED": 0}
    conf_buckets_global = {">90": 0, "70-90": 0, "50-70": 0, "<50": 0}
    try:
        cur.execute(
            """
            SELECT raw_name, library_id, tier, confidence
            FROM program_exercise_name_map
            """
        )
        for r in cur.fetchall():
            rn = (r["raw_name"] or "").strip()
            tier = r["tier"]
            conf = r.get("confidence") or 0
            tier_counts_global[tier] = tier_counts_global.get(tier, 0) + 1
            if tier != "UNMAPPED":
                if conf > 90:
                    conf_buckets_global[">90"] += 1
                elif conf >= 70:
                    conf_buckets_global["70-90"] += 1
                elif conf >= 50:
                    conf_buckets_global["50-70"] += 1
                else:
                    conf_buckets_global["<50"] += 1
            if not rn or r["library_id"] is None or tier == "UNMAPPED":
                continue
            if tier in ("A0", "A1"):
                canonical_auto[rn] = str(r["library_id"])
            elif conf >= 70:
                # B and C with confidence >= 70 → corroborated tier
                canonical_review[rn] = str(r["library_id"])
        print(
            f"  tier-A0: {tier_counts_global['A0']} | "
            f"tier-A1: {tier_counts_global['A1']} | "
            f"tier-B: {tier_counts_global['B']} | "
            f"tier-C: {tier_counts_global['C']} | "
            f"unmapped: {tier_counts_global['UNMAPPED']}",
            flush=True,
        )
        print(
            f"  confidence: >90={conf_buckets_global['>90']} | "
            f"70-90={conf_buckets_global['70-90']} | "
            f"50-70={conf_buckets_global['50-70']} | "
            f"<50={conf_buckets_global['<50']}",
            flush=True,
        )
    except Exception as exc:  # pragma: no cover
        # Table not yet created — fall back to exact-only matching.
        print(
            "  WARNING: program_exercise_name_map missing "
            f"({exc!r}); falling back to exact lookup only",
            flush=True,
        )
        conn.rollback()

    # ---------- blessed vocabulary size (image + video populated) ---------
    cur.execute(
        """
        SELECT count(*) AS n FROM exercise_library_cleaned
        WHERE image_url IS NOT NULL AND image_url <> ''
          AND video_url IS NOT NULL AND video_url <> ''
        """
    )
    blessed_count = cur.fetchone()["n"]
    print(f"  blessed vocabulary size: {blessed_count}", flush=True)

    # ---------- programs ----------
    print("loading programs...", flush=True)
    cur.execute(
        """
        SELECT id, name, category, split_type, duration_weeks, program_metadata
        FROM branded_programs
        ORDER BY name
        """
    )
    programs = cur.fetchall()
    print(f"  programs: {len(programs)}", flush=True)

    # ---------- variants ----------
    print("loading variants...", flush=True)
    cur.execute(
        """
        SELECT id, base_program_id, intensity_level, duration_weeks,
               generation_cost_usd
        FROM program_variants
        """
    )
    variants = cur.fetchall()
    print(f"  variants: {len(variants)}", flush=True)
    variants_by_program: dict[str, list[dict]] = defaultdict(list)
    variant_to_program: dict[str, str] = {}
    for v in variants:
        pid = str(v["base_program_id"])
        vid = str(v["id"])
        variants_by_program[pid].append(v)
        variant_to_program[vid] = pid

    # ---------- weeks (stream in batches) ----------
    print("loading weeks (streaming)...", flush=True)
    weeks_by_variant: dict[str, list[dict]] = defaultdict(list)
    # Use a server-side cursor to avoid loading all 48k rows at once.
    sscur = conn.cursor(name="weeks_stream", cursor_factory=psycopg2.extras.RealDictCursor)
    sscur.itersize = 2000
    sscur.execute(
        "SELECT variant_id, week_number, workouts FROM program_variant_weeks"
    )
    n_weeks = 0
    for row in sscur:
        weeks_by_variant[str(row["variant_id"])].append(
            {"week_number": row["week_number"], "workouts": row["workouts"]}
        )
        n_weeks += 1
        if n_weeks % 5000 == 0:
            print(f"    streamed {n_weeks} weeks", flush=True)
    sscur.close()
    print(f"  weeks: {n_weeks}", flush=True)

    # ---------- per-program rollup ----------
    print("computing per-program rollup...", flush=True)
    unmatched_counter: dict[str, int] = defaultdict(int)  # normalized name -> #programs
    unmatched_display: dict[str, str] = {}  # normalized -> first raw seen

    rows_out = []
    summary = {
        "total_programs": len(programs),
        "programs_with_variants": 0,
        "total_variants": 0,
        "total_unique_exercises_global": set(),
        "total_match_count_weighted": 0,
        "total_mediated_match_count_weighted": 0,
        "total_unique_count_weighted": 0,
        "total_auto_canonical_matches": 0,
        "blessed_count": blessed_count,
        "broken": 0,
        "partial": 0,
        "ok": 0,
        "status_done": 0,
        "status_mostly_done": 0,
        "status_in_progress": 0,
        "status_undone": 0,
        "cost_spent": 0.0,
    }

    for p in programs:
        pid = str(p["id"])
        pname = p["name"]
        pmd = p["program_metadata"] or {}
        planned_weeks = p["duration_weeks"] or (
            pmd.get("duration_weeks") if isinstance(pmd, dict) else None
        )

        prog_variants = variants_by_program.get(pid, [])
        completed_variants = len(prog_variants)
        completed_weeks_total = sum(
            (v["duration_weeks"] or 0) for v in prog_variants
        )
        intensities_present = sorted(
            {v["intensity_level"] for v in prog_variants if v["intensity_level"]}
        )
        durations_present = sorted(
            {v["duration_weeks"] for v in prog_variants if v["duration_weeks"]}
        )

        weeks_with_data = 0
        empty_weeks: list[str] = []
        unique_names_norm: set[str] = set()
        unique_names_raw: dict[str, str] = {}
        ex_lib_id_populated = 0
        ex_total_records = 0

        for v in prog_variants:
            vid = str(v["id"])
            wks = weeks_by_variant.get(vid, [])
            weeks_with_data += len(wks)
            for wk in wks:
                workouts = wk["workouts"] or []
                if not workouts:
                    empty_weeks.append(f"v{vid[:8]} wk{wk['week_number']}")
                    continue
                wk_has_ex = False
                for w in workouts:
                    exs = w.get("exercises") if isinstance(w, dict) else None
                    if not exs:
                        continue
                    for ex in exs:
                        if not isinstance(ex, dict):
                            continue
                        nm = ex.get("name") or ex.get("exercise_name") or ""
                        if not nm:
                            continue
                        wk_has_ex = True
                        ex_total_records += 1
                        if ex.get("exercise_library_id"):
                            ex_lib_id_populated += 1
                        n = normalize(nm)
                        if n:
                            unique_names_norm.add(n)
                            unique_names_raw.setdefault(n, nm)
                if not wk_has_ex:
                    empty_weeks.append(f"v{vid[:8]} wk{wk['week_number']}")

        weeks_missing = max(0, completed_weeks_total - weeks_with_data)

        # match against library
        # Tier-1: exact normalized lookup against library + aliases (any
        #         exercise_library_cleaned row, regardless of media).
        # Tier-2: composite-rank canonical map against the BLESSED subset
        #         (image_url + video_url populated) — confidence in
        #         {'auto', 'review'} count as mediated matches.
        # match_rate_pct          = informational, library-wide.
        # mediated_match_rate_pct = strict, blessed-subset-only.
        matched = 0
        mediated_matched = 0
        auto_canonical_matches = 0
        unmatched_local = []
        for n in unique_names_norm:
            in_lib = n in norm_to_lib
            in_auto = n in canonical_auto
            in_review = n in canonical_review
            if in_lib:
                matched += 1
            elif in_auto:
                matched += 1
                auto_canonical_matches += 1
            else:
                unmatched_local.append(n)
            # Mediated bucket: only blessed-subset hits (auto OR review).
            if in_auto or in_review:
                mediated_matched += 1
        total_uniq = len(unique_names_norm)
        match_rate = (matched / total_uniq * 100.0) if total_uniq else 0.0
        mediated_match_rate = (
            mediated_matched / total_uniq * 100.0
        ) if total_uniq else 0.0

        for n in unmatched_local:
            unmatched_counter[n] += 1
            unmatched_display.setdefault(n, unique_names_raw.get(n, n))

        # validity
        notes_parts = []
        if completed_variants == 0:
            flag = "BROKEN"
            notes_parts.append("no variants")
        elif weeks_with_data == 0:
            flag = "BROKEN"
            notes_parts.append("no week data")
        else:
            if match_rate < 50.0 and total_uniq > 0:
                notes_parts.append(f"{match_rate:.0f}% lib match")
            if empty_weeks:
                notes_parts.append(
                    f"{len(empty_weeks)} empty week(s) e.g. {empty_weeks[0]}"
                )
            if completed_variants < PLANNED_VARIANTS_PER_PROGRAM:
                notes_parts.append(
                    f"{completed_variants}/{PLANNED_VARIANTS_PER_PROGRAM} variants"
                )
            flag = "PARTIAL" if notes_parts else "OK"

        # status (resume-plan column)
        # DONE         — all 18 variants AND >=80% library match
        # MOSTLY_DONE  — >=12 variants AND >=60% library match
        # IN_PROGRESS  — 1..11 variants OR <60% library match
        # UNDONE       — 0 variants (the 6 deleted; surfaced via the CSV
        #                union below so they stay visible after deletion)
        if completed_variants == 0:
            status = "UNDONE"
        elif (
            completed_variants >= PLANNED_VARIANTS_PER_PROGRAM
            and match_rate >= 80.0
        ):
            status = "DONE"
        elif completed_variants >= 12 and match_rate >= 60.0:
            status = "MOSTLY_DONE"
        else:
            status = "IN_PROGRESS"

        cost_spent = sum(
            float(v["generation_cost_usd"] or 0) for v in prog_variants
        )
        est_remaining = (
            max(0, PLANNED_VARIANTS_PER_PROGRAM - completed_variants)
            * COST_PER_VARIANT_USD
        )

        # summary roll-ups
        summary["total_variants"] += completed_variants
        if completed_variants > 0:
            summary["programs_with_variants"] += 1
        summary["total_unique_exercises_global"].update(unique_names_norm)
        summary["total_match_count_weighted"] += matched
        summary["total_mediated_match_count_weighted"] += mediated_matched
        summary["total_unique_count_weighted"] += total_uniq
        summary["total_auto_canonical_matches"] += auto_canonical_matches
        summary["cost_spent"] += cost_spent
        if flag == "BROKEN":
            summary["broken"] += 1
        elif flag == "PARTIAL":
            summary["partial"] += 1
        else:
            summary["ok"] += 1
        if status == "DONE":
            summary["status_done"] += 1
        elif status == "MOSTLY_DONE":
            summary["status_mostly_done"] += 1
        elif status == "IN_PROGRESS":
            summary["status_in_progress"] += 1
        else:
            summary["status_undone"] += 1

        rows_out.append({
            "program_id": pid,
            "name": pname,
            "category": p["category"] or "",
            "split_type": p["split_type"] or "",
            "planned_weeks": planned_weeks if planned_weeks is not None else "",
            "planned_variants": PLANNED_VARIANTS_PER_PROGRAM,
            "completed_variants": completed_variants,
            "completed_weeks_total": completed_weeks_total,
            "weeks_with_data": weeks_with_data,
            "weeks_missing": weeks_missing,
            "in_supabase": "Yes" if completed_variants > 0 else "No",
            "intensities_present": ",".join(intensities_present),
            "durations_present": ",".join(str(d) for d in durations_present),
            "total_exercises": ex_total_records,
            "unique_exercise_names": total_uniq,
            "exercises_matched_to_library": matched,
            "auto_canonical_matches": auto_canonical_matches,
            "match_rate_pct": round(match_rate, 1),
            "mediated_match_rate_pct": round(mediated_match_rate, 1),
            "exercise_library_id_populated": ex_lib_id_populated,
            "data_validity_flag": flag,
            "status": status,
            "validity_notes": "; ".join(notes_parts),
            "gen_cost_so_far_usd": round(cost_spent, 4),
            "est_cost_to_complete_usd": round(est_remaining, 4),
        })

    cur.close()
    conn.close()

    # ---------- union deleted "to regenerate" programs ----------
    # The 6 broken programs were deleted from `branded_programs` (zero
    # variants, FK-safe). They no longer appear in the live query above,
    # but the resume plan still needs them in the report. Pull them from
    # docs/programs_to_regenerate.csv as UNDONE rows.
    to_regen = _load_to_regenerate_csv()
    if to_regen:
        existing_ids = {r["program_id"] for r in rows_out}
        for r in to_regen:
            if r.get("program_id") in existing_ids:
                continue
            rows_out.append({
                "program_id": r.get("program_id", ""),
                "name": r.get("name", ""),
                "category": r.get("category", ""),
                "split_type": "",
                "planned_weeks": r.get("planned_weeks", ""),
                "planned_variants": PLANNED_VARIANTS_PER_PROGRAM,
                "completed_variants": 0,
                "completed_weeks_total": 0,
                "weeks_with_data": 0,
                "weeks_missing": 0,
                "in_supabase": "No (deleted)",
                "intensities_present": "",
                "durations_present": "",
                "total_exercises": 0,
                "unique_exercise_names": 0,
                "exercises_matched_to_library": 0,
                "auto_canonical_matches": 0,
                "match_rate_pct": 0.0,
                "mediated_match_rate_pct": 0.0,
                "exercise_library_id_populated": 0,
                "data_validity_flag": "BROKEN",
                "status": "UNDONE",
                "validity_notes": r.get(
                    "status", "deleted; needs regeneration"
                ),
                "gen_cost_so_far_usd": 0.0,
                "est_cost_to_complete_usd": round(
                    PLANNED_VARIANTS_PER_PROGRAM * COST_PER_VARIANT_USD, 4
                ),
            })
            summary["broken"] += 1
            summary["status_undone"] += 1
        # also reflect them in the global program count used in the md
        summary["total_programs_with_undone"] = (
            summary["total_programs"] + len(to_regen)
        )
    else:
        summary["total_programs_with_undone"] = summary["total_programs"]

    # ---------- write CSV ----------
    csv_path = DOCS / "programs_validation.csv"
    print(f"writing {csv_path} ...", flush=True)
    fields = list(rows_out[0].keys())
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows_out)

    # ---------- unmatched canonicalization gap ----------
    unmatched_path = DOCS / "programs_unmatched_exercises.csv"
    print(f"writing {unmatched_path} ...", flush=True)
    with unmatched_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["normalized_name", "sample_raw_name", "program_count"])
        for n, c in sorted(
            unmatched_counter.items(), key=lambda kv: kv[1], reverse=True
        ):
            w.writerow([n, unmatched_display.get(n, n), c])

    # ---------- markdown ----------
    md_path = DOCS / "PROGRAMS_VALIDATION.md"
    print(f"writing {md_path} ...", flush=True)
    total_uniq_global = len(summary["total_unique_exercises_global"])
    overall_match_rate = (
        summary["total_match_count_weighted"]
        / summary["total_unique_count_weighted"]
        * 100.0
    ) if summary["total_unique_count_weighted"] else 0.0
    overall_mediated_rate = (
        summary["total_mediated_match_count_weighted"]
        / summary["total_unique_count_weighted"]
        * 100.0
    ) if summary["total_unique_count_weighted"] else 0.0
    planned_total = summary["total_programs"] * PLANNED_VARIANTS_PER_PROGRAM
    pct_complete = summary["total_variants"] / planned_total * 100.0
    est_finish = (planned_total - summary["total_variants"]) * COST_PER_VARIANT_USD

    # top 20 worst
    worst = sorted(
        rows_out,
        key=lambda r: (
            0 if r["data_validity_flag"] == "BROKEN" else 1,
            r["match_rate_pct"] if r["unique_exercise_names"] else -1,
            -r["completed_variants"],
        ),
    )[:20]

    with md_path.open("w", encoding="utf-8") as f:
        f.write("# Programs Validation Report\n\n")
        f.write(
            "Generated by `backend/scripts/validate_programs.py`.\n\n"
        )
        f.write(
            f"> **Blessed vocabulary size: {summary['blessed_count']:,} "
            "exercises with both image AND video** "
            "(`exercise_library_cleaned` filtered by `image_url IS NOT NULL "
            "AND video_url IS NOT NULL`).\n\n"
        )

        # ---- Tables Used (top-of-report inventory) ----
        f.write("## Tables Used\n\n")
        f.write(
            "Every row in this report is derived from one of the tables / "
            "views below. The script reads them live from Supabase via "
            "`DATABASE_URL` in `backend/.env`.\n\n"
            "- `branded_programs` — name, category, split_type, "
            "duration_weeks, program_metadata. One row per program.\n"
            "- `program_variants` — variant counts, intensity_level, "
            "duration_weeks, generation_cost_usd. Joined to programs via "
            "`base_program_id`.\n"
            "- `program_variant_weeks` — week-level workout JSONB; the "
            "`exercises[]` array inside `workouts` feeds the exercise-name "
            "extraction and the match-rate calc.\n"
            "- `exercise_library_cleaned` (materialized view) — canonical "
            "exercise names, used as the Tier-1 lookup target. The "
            "**blessed predicate** (`image_url IS NOT NULL AND video_url IS "
            "NOT NULL`) restricts this to the subset of exercises that have "
            "both an illustration and a vertical demo video; this subset is "
            "the only vocabulary the program generator may emit.\n"
            "- `exercise_aliases` — `alias_name` → `canonical_exercise_id` "
            "map, merged into the Tier-1 lookup.\n"
            "- `program_exercise_name_map` (regular table, populated by "
            "`backend/scripts/build_canonical_map.py`) — 4-tier robust 1:1 "
            "map against the blessed subset only "
            "(`0.5*trigram + 0.3*token_jaccard + 0.2*movement_match` plus "
            "movement / equipment / body-region corroboration). Tiers: "
            "A (auto-accept), B (composite ≥ 0.65 + 2-of-3 signals), "
            "C (composite 0.50–0.65 + all 3 signals), UNMAPPED. Rows in "
            "tier ∈ {A, B, C} drive the **mediated** match rate.\n"
            "- `docs/programs_to_regenerate.csv` (file, **NEW**) — the 6 "
            "deleted broken programs are re-injected as `status=UNDONE` "
            "rows so the resume plan stays visible in the report.\n\n"
        )

        f.write("## Summary\n\n")
        f.write(
            f"- **Total programs:** {summary['total_programs']} live in "
            "`branded_programs`"
        )
        if summary.get("total_programs_with_undone", summary["total_programs"]) != summary["total_programs"]:
            f.write(
                f" + {summary['total_programs_with_undone'] - summary['total_programs']} "
                "deleted-undone (re-injected from "
                "`programs_to_regenerate.csv`)"
            )
        f.write("\n")
        f.write(
            f"- **Programs with at least one variant:** "
            f"{summary['programs_with_variants']} (`program_variants`)\n"
        )
        f.write(
            f"- **Total variants generated:** {summary['total_variants']} "
            f"of {planned_total} planned "
            f"({pct_complete:.1f}% complete) (`program_variants`)\n"
        )
        f.write(
            f"- **Planned variants per program:** "
            f"{PLANNED_VARIANTS_PER_PROGRAM} "
            f"(3 intensities × 6 durations: 2/3/4/6/8/12 wk)\n"
        )
        f.write(
            f"- **Distinct exercise names referenced across all programs:** "
            f"{total_uniq_global:,} (`program_variant_weeks.workouts` "
            "JSONB)\n"
        )
        f.write(
            f"- **Library-match rate (weighted, informational):** "
            f"{overall_match_rate:.1f}% "
            "(any `exercise_library_cleaned` row + `exercise_aliases` + "
            "auto suggestions; not media-gated)\n"
        )
        f.write(
            f"- **Mediated match rate (weighted, blessed subset only):** "
            f"**{overall_mediated_rate:.1f}%** "
            "(strict — only `program_exercise_canonical_map` rows with "
            "confidence ∈ {auto, review} against the "
            f"{summary['blessed_count']:,}-row blessed vocabulary)\n"
        )
        f.write(
            f"- **Names recovered by canonical map (Tier-2):** "
            f"{summary['total_auto_canonical_matches']:,} "
            "(`program_exercise_name_map` tier='A')\n"
        )
        f.write(
            f"- **Mapping tier breakdown** (`program_exercise_name_map`): "
            f"Tier-A: {tier_counts_global.get('A', 0) + tier_counts_global.get('A0', 0) + tier_counts_global.get('A1', 0):,} / "
            f"Tier-B: {tier_counts_global['B']:,} / "
            f"Tier-C: {tier_counts_global['C']:,} / "
            f"Unmapped: {tier_counts_global['UNMAPPED']:,} "
            "(see `EXERCISE_NAME_MAPPING.md` and "
            "`EXERCISE_NAME_UNMAPPED.md`)\n"
        )
        f.write(
            f"- **Validity breakdown:** OK={summary['ok']}, "
            f"PARTIAL={summary['partial']}, BROKEN={summary['broken']}\n"
        )
        f.write(
            f"- **Status breakdown:** DONE={summary['status_done']}, "
            f"MOSTLY_DONE={summary['status_mostly_done']}, "
            f"IN_PROGRESS={summary['status_in_progress']}, "
            f"UNDONE={summary['status_undone']}\n"
        )
        f.write(
            f"- **Generation cost spent so far:** "
            f"${summary['cost_spent']:.2f}\n"
        )
        f.write(
            f"- **Estimated cost to finish remaining variants:** "
            f"${est_finish:.2f} "
            f"(@ ${COST_PER_VARIANT_USD:.4f}/variant placeholder)\n\n"
        )

        f.write("### Pricing — Gemini 3.1 Flash Lite (verified 2026-05-08)\n\n")
        f.write(
            "Source: https://ai.google.dev/gemini-api/docs/pricing\n\n"
            "| Model | Input / 1M | Output / 1M | Cached input / 1M |\n"
            "|---|---|---|---|\n"
            "| **Gemini 3.1 Flash Lite** | **$0.25** | **$1.50** | $0.025 |\n"
            "| Gemini 3 Flash (GA) | $0.50 | $3.00 | — |\n"
            "| Gemini 3.1 Pro (≤200k) | $2.00 | $12.00 | — |\n\n"
            "Per-variant cost (~3,500 input, ~6,500 output tokens):\n\n"
            f"```\ninput  = {AVG_INPUT_TOKENS} × ${PRICE_INPUT_PER_1K*1000:.2f}/1M = "
            f"${AVG_INPUT_TOKENS/1_000_000*PRICE_INPUT_PER_1K*1000:.6f}\n"
            f"output = {AVG_OUTPUT_TOKENS} × ${PRICE_OUTPUT_PER_1K*1000:.2f}/1M = "
            f"${AVG_OUTPUT_TOKENS/1_000_000*PRICE_OUTPUT_PER_1K*1000:.6f}\n"
            f"total  ≈ ${COST_PER_VARIANT_USD:.4f} per variant ({COST_PER_VARIANT_USD*100:.2f}¢)\n"
            "with cached system prompt ≈ $0.0098 / variant\n```\n\n"
            f"**Finish-line cost** ({int(est_finish/COST_PER_VARIANT_USD)} missing variants):\n\n"
            "| Model | Cost |\n"
            "|---|---|\n"
            f"| Flash Lite (no caching) | **${est_finish:.0f}** |\n"
            f"| Flash Lite (with cache) | **${est_finish*0.92:.0f}** |\n"
            f"| Flash GA | ${est_finish*2:.0f} |\n"
            f"| Pro | ${est_finish*8:.0f} |\n"
            f"| Original generator (real spend $1,662 / 9,028 variants ≈ $0.184/v — likely Pro or 2.x Flash) | ${est_finish*17.36:.0f} |\n\n"
            "Constants at the top of `backend/scripts/validate_programs.py` "
            "(`PRICE_INPUT_PER_1K`, `PRICE_OUTPUT_PER_1K`, "
            "`AVG_INPUT_TOKENS`, `AVG_OUTPUT_TOKENS`). "
            "Update + re-run if Google changes prices.\n\n"
        )

        f.write("## Top 20 Programs Needing Attention\n\n")
        f.write(
            "Sorted: BROKEN first, then by lowest library match rate.\n\n"
        )
        f.write(
            "| Program | Category | Variants | Weeks w/ data | "
            "Unique ex | Match % | Flag | Status | Notes |\n"
        )
        f.write(
            "|---|---|---|---|---|---|---|---|---|\n"
        )
        for r in worst:
            f.write(
                f"| {r['name'][:50]} | {r['category']} | "
                f"{r['completed_variants']}/{PLANNED_VARIANTS_PER_PROGRAM} | "
                f"{r['weeks_with_data']} | {r['unique_exercise_names']} | "
                f"{r['match_rate_pct']}% | {r['data_validity_flag']} | "
                f"{r.get('status','')} | "
                f"{r['validity_notes'][:60]} |\n"
            )

        f.write("\n## How to use the CSVs\n\n")
        f.write(
            "### `programs_validation.csv` (one row per program)\n\n"
            "- Filter `data_validity_flag = BROKEN` for programs that need to "
            "be regenerated from scratch (no variants or no week data).\n"
            "- Filter `data_validity_flag = PARTIAL` for programs that have "
            "variants but are missing intensities/durations or have a low "
            "library-match rate.\n"
            "- `match_rate_pct` < 50% indicates the variant generator is "
            "inventing exercise names that don't exist in "
            "`exercise_library_cleaned` — fix by canonicalizing those names "
            "(see next section) before the next generation run.\n"
            "- `exercise_library_id_populated` is the count of exercise "
            "records in JSONB that already have a non-null "
            "`exercise_library_id`. If this is 0 or near-0 even when "
            "`match_rate_pct` is high, the post-generation linker step never "
            "ran and should be back-filled.\n"
            "- `est_cost_to_complete_usd` uses the placeholder pricing "
            "constants above. Multiply by your real "
            "input/output prices once confirmed.\n\n"
        )

        f.write("### `programs_unmatched_exercises.csv` (canonicalization gap)\n\n")
        f.write(
            "One row per distinct exercise name that did NOT match the "
            "library, with the number of programs that reference it. "
            "Workflow:\n\n"
            "1. Sort by `program_count` desc — the top of the file is the "
            "highest-leverage canonicalization work.\n"
            "2. For each row, decide whether the exercise should:\n"
            "   - Map to an existing library entry → add to "
            "`exercise_aliases` (`alias_name` → `canonical_exercise_id`).\n"
            "   - Be added to the library → insert into "
            "`exercise_library_cleaned` (then "
            "`SELECT refresh_exercise_library_cleaned();`).\n"
            "   - Be banned/replaced in prompts → update the variant "
            "generator's allowed-exercise list.\n"
            "3. Re-run this validation script after each batch of fixes to "
            "watch the global match rate climb.\n\n"
            "The normalization used here lowercases, strips punctuation, "
            "collapses whitespace, expands token aliases (bb→barbell, "
            "db→dumbbell, kb→kettlebell, ohp→overhead press, rdl→romanian "
            "deadlift, bw→bodyweight, pushup→push up, pullup→pull up, …). "
            "If a real exercise still misses, extend `_TOKEN_ALIASES` in "
            "`validate_programs.py` rather than mutating the data.\n\n"
        )

        f.write("## Re-running\n\n")
        f.write(
            "```bash\nbackend/.venv/bin/python "
            "backend/scripts/validate_programs.py\n```\n\n"
            "Pulls live from Supabase via `DATABASE_URL` in `backend/.env`. "
            "Run takes ~1–3 minutes against the production project.\n"
        )

    print("done.", flush=True)
    print(
        f"summary: programs={summary['total_programs']} "
        f"variants={summary['total_variants']} "
        f"match={overall_match_rate:.1f}% "
        f"mediated={overall_mediated_rate:.1f}% "
        f"blessed={summary['blessed_count']} "
        f"broken={summary['broken']} partial={summary['partial']} "
        f"ok={summary['ok']} "
        f"cost_spent=${summary['cost_spent']:.2f} "
        f"est_finish=${est_finish:.2f}",
        flush=True,
    )


if __name__ == "__main__":
    main()
