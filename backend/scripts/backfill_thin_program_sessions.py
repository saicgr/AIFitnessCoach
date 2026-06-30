#!/usr/bin/env python3
"""
Backfill under-populated sessions in the 16 variant-backed launch programs.

CONTEXT (2026-06) — see .claude/plans/one-more-change-to-tingly-wreath.md
------------------------------------------------------------------------
An audit found ~1,133 sessions across 48 variants of the published programs had
only 3 main exercises in a 45-60min slot that should hold ~5 (root cause: the
variant generator's validation gate only required sessions*3 as a WEEK TOTAL).
This script repairs the already-shipped data by topping every thin, non-exempt
session up to its duration-scaled FLOOR using the SAME deterministic engine the
generator now runs before ingest (services/program_session_filler.py).

KEY PROPERTIES
  • Deterministic, idempotent (re-run adds 0), dry-run by DEFAULT (--apply writes).
  • Equipment-gated PER PROGRAM: a bodyweight/home program can only ever receive
    bodyweight additions (the union of its existing exercises' equipment).
  • Additions resolve to a library exercise_id → their illustration auto-maps.
    The script flags any addition whose library row lacks gif/video/image so the
    media gap can be handed to the program-variant-builder Phase 4 mapping.
  • Writes are id-scoped UPDATEs (UPDATE program_variant_weeks SET workouts WHERE
    id=row_id) → two workers on disjoint programs never clobber a row.
  • Self-contained: uses supabase-py (REST) + an in-memory candidate pool filtered
    in Python (mirrors exercise_rag.fetch_safe_candidates), so it needs neither the
    async DB engine nor the heavy backend imports.
  • NO materialized-view refresh needed — we write only program_variant_weeks.

USAGE
  python3 scripts/backfill_thin_program_sessions.py --dry-run            # all programs, preview
  python3 scripts/backfill_thin_program_sessions.py --program-id A,B --apply
  python3 scripts/backfill_thin_program_sessions.py --variant-id V --apply --verbose

  --program-id   repeatable / comma-separated programs.id values (default: all 16)
  --variant-id   restrict to specific program_variants.id values
  --apply        perform writes (default is dry-run, writes nothing)
  --limit        cap number of week rows processed (debugging)
  --include-express  also process 7-minute/express programs (skipped by default —
                     their thinness is a separate duration bug, not under-population)
  --verbose      print every planned addition
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from collections import Counter
from pathlib import Path

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

from services.program_session_filler import fill_thin_sessions, _norm  # noqa: E402

# Programs whose thin sessions are an unrelated duration bug, not under-population.
EXPRESS_TOKENS = ("7-minute", "7 minute", "express")

_DIFF_RANK = {"beginner": 1, "intermediate": 2, "advanced": 3, "elite": 4}

# Anchored focus → (exact body_part values, target_muscle substrings).
# Copied from exercise_rag.service.fetch_safe_candidates so candidate selection
# matches the runtime path exactly.
_FOCUS_SYNONYMS = {
    "pull": (("back", "upper arms", "lower arms"),
             ("lat", "biceps", "trap", "rear delt", "posterior delt",
              "rhomboid", "forearm", "back")),
    "push": (("chest", "shoulders", "upper arms"),
             ("pectoralis", "anterior delt", "lateral delt", "triceps", "chest")),
    "legs": (("upper legs", "lower legs"),
             ("quadriceps", "hamstring", "glute", "calf", "calves",
              "adductor", "abductor")),
    "lower_body": (("upper legs", "lower legs"),
                   ("quadriceps", "hamstring", "glute", "calf")),
    "upper_body": (("back", "chest", "shoulders", "upper arms", "lower arms"),
                   ("lat", "pectoralis", "delt", "biceps", "triceps",
                    "trap", "rhomboid", "forearm")),
    "core": (("waist", "abdominals"),
             ("abdominis", "oblique", "core", "transverse")),
    "arms": (("upper arms", "lower arms"), ("biceps", "triceps", "forearm")),
    "back": (("back",), ("back", "lat", "trap", "rhomboid")),
    "chest": (("chest",), ("pectoralis", "chest")),
    "shoulders": (("shoulders",), ("delt", "shoulder", "rotator cuff")),
}


# ── Supabase client ───────────────────────────────────────────────────────────
_sb = None


def get_sb():
    global _sb
    if _sb is None:
        from supabase import create_client
        if not (SUPABASE_URL and SUPABASE_KEY):
            raise SystemExit("SUPABASE_URL / SUPABASE_KEY not set in backend/.env")
        _sb = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _sb


# ── Candidate pool (loaded once, filtered in Python per session) ───────────────
def load_candidate_pool():
    """All safety-tagged library exercises (~2.4k rows). Carries media columns so
    we can flag any addition that lacks an illustration."""
    sb = get_sb()
    cols = ("exercise_id,name,name_normalized,body_part,equipment,target_muscle,"
            "safety_difficulty,movement_pattern,gif_url,video_url,image_url")
    rows, start, step = [], 0, 1000
    while True:
        r = (sb.table("exercise_safety_index_mat").select(cols)
             .eq("is_tagged", True).range(start, start + step - 1).execute())
        batch = r.data or []
        rows.extend(batch)
        if len(batch) < step:
            break
        start += step
    return rows


def _equip_matches(cand_equip: str, allowed: list) -> bool:
    """Bidirectional substring match, mirroring the SQL ILIKE-ANY clause. A NULL/
    empty candidate equipment is always allowed (fail-open like the runtime)."""
    ce = (cand_equip or "").strip().lower()
    if not ce:
        return True
    for a in allowed:
        a = (a or "").strip().lower()
        if not a:
            continue
        if a in ce or ce in a:
            return True
    return False


# The library is the (noisy) free-exercise dataset: alongside real lifts it holds
# thousands of stretches, warmups, plyo/cardio drills, and oddly-named pose
# variants. Selecting alphabetically ships junk ("180 Jump Turns"). We HARD-EXCLUDE
# those so only real, loadable accessory lifts remain.
_JUNK_RE = re.compile(
    r"(stretch|mobilit|warm|circle|pulse|swing|punch|\bhold\b|\bmarch|jump|"
    r"sprinter|\btap\b|\btaps\b|pose|\bflow\b|\bhang\b|\bair\b|\brun|\bjog|"
    r"\bskip|\bjack\b|burpee|crawl|\bkick|clap|shuffle| and |wiper|scissor|"
    r"flutter|\bdrill\b|\bduck\b|\bbear\b|\bcrab\b|\bgallop|\bhop\b)", re.I)

# Tokens stripped to derive a BASE movement key for diversity dedupe (so
# "Barbell Bench Press Incline" / "...Decline" / "Dumbbell Incline Bench Press"
# all collapse to "bench press" and we never add 3 near-duplicate variants, nor
# add a bench when the session already has one). Movement-defining words (press,
# row, curl, raise, squat, …) are deliberately KEPT.
_QUALIFIER_TOKENS = {
    "barbell", "dumbbell", "dumbbells", "cable", "machine", "smith", "resistance",
    "band", "bands", "kettlebell", "kettlebells", "ez", "ezbar", "ez-bar", "plate",
    "seated", "standing", "lying", "incline", "decline", "flat", "single", "arm",
    "single-arm", "alternate", "alternating", "wide", "close", "close-grip",
    "grip", "normal", "neutral", "reverse", "behind", "neck", "assisted",
    "weighted", "bodyweight", "two", "one", "left", "right", "front", "high",
    "low", "rope", "straight", "preacher", "concentration", "with", "and",
    "the", "a", "to", "of", "on", "in", "v", "bar",
}

# Accessory movement BUCKETS per focus, ordered by desirability. Each bucket is a
# set of synonyms for ONE movement category — we pick at most ONE exercise per
# bucket so a Push day gets press + fly + lateral raise (not three chest presses),
# and a bucket already covered by an existing exercise is consumed (skipped).
_ACCESSORY_BUCKETS = {
    "push": [
        ["incline press", "incline bench"],
        ["lateral raise", "side lateral", "lateral raises"],
        ["chest fly", "pec deck", "pec dec", "cable crossover", "chest cross", " fly"],
        ["overhead press", "shoulder press", "military press", "arnold"],
        ["tricep", "triceps", "pushdown", "skullcrusher", "close-grip"],
        ["dip"],
        ["bench press", "chest press", "floor press"],
        ["push-up", "pushup"],
    ],
    "pull": [
        ["lat pulldown", "pulldown"],
        ["seated row", "cable row", "chest supported row", "seal row", "machine row"],
        ["bent over row", "barbell row", "pendlay", "t-bar", "t bar", "dumbbell row"],
        ["face pull", "rear delt", "reverse fly", "reverse pec"],
        ["bicep curl", "biceps curl", "barbell curl", "dumbbell curl", "ez curl"],
        ["hammer curl", "preacher curl", "concentration curl", "incline curl"],
        ["shrug"],
        ["chin-up", "pull-up", "pullup", "chinup"],
    ],
    "legs": [
        ["romanian deadlift", "rdl", "stiff leg", "stiff-leg", "good morning"],
        ["leg press", "hack squat"],
        ["leg extension"],
        ["leg curl", "hamstring curl"],
        ["lunge", "split squat", "step-up", "step up"],
        ["hip thrust", "glute bridge"],
        ["calf raise", "calf press"],
        ["goblet squat", "front squat", "bulgarian"],
    ],
    "core": [
        ["plank"], ["leg raise", "knee raise", "leg lift"],
        ["crunch", "cable crunch"], ["russian twist", "twist"], ["dead bug"],
        ["hollow"], ["ab wheel", "rollout"], ["side plank"], ["bird dog"],
        ["sit-up", "situp"], ["hanging"],
    ],
    "arms": [
        ["bicep curl", "biceps curl", "barbell curl", "dumbbell curl"],
        ["hammer curl", "preacher curl", "concentration curl"],
        ["tricep", "triceps", "pushdown", "skullcrusher"],
        ["dip"], ["cable curl"], ["overhead extension"],
    ],
}
_ACCESSORY_BUCKETS["upper_body"] = _ACCESSORY_BUCKETS["push"] + _ACCESSORY_BUCKETS["pull"]
_ACCESSORY_BUCKETS["full_body"] = [
    ["goblet squat", "front squat"], ["romanian deadlift", "rdl"],
    ["leg press", "hack squat"], ["bench press", "chest press", "push-up"],
    ["seated row", "cable row", "dumbbell row"], ["lat pulldown", "pull-up"],
    ["shoulder press", "overhead press"], ["lunge", "split squat"],
    ["hip thrust", "glute bridge"], ["plank"], ["bicep curl", "biceps curl"],
    ["tricep", "pushdown"], ["lateral raise"], ["calf raise"],
]

_LOADED_HINTS = ("barbell", "dumbbell", "cable", "machine", "kettlebell",
                 "smith", "ez", "plate", "band")


def _base_movement(name: str) -> str:
    """Collapse a verbose library name to its core movement for diversity dedupe."""
    words = re.findall(r"[a-z0-9-]+", (name or "").lower())
    kept = [w for w in words if w not in _QUALIFIER_TOKENS]
    return " ".join(kept).strip()


def _bucket_of(name: str, focus_key: str):
    """Return (bucket_index, name) for the FIRST accessory bucket this exercise
    belongs to, or (None, ...) if it doesn't match any classic bucket."""
    n = (name or "").lower()
    for i, syns in enumerate(_ACCESSORY_BUCKETS.get(focus_key, [])):
        if any(s in n for s in syns):
            return i
    return None


def make_candidate_fetcher(pool: list):
    """High-quality curated selector for fill_thin_sessions: junk-filtered,
    focus-relevant, equipment-gated, DIVERSE (one per base movement, and never a
    base already in the session), ordered by classic-accessory priority then media.
    """
    async def _fetch(*, injuries, focus_areas, equipment, difficulty_ceiling, k,
                     session=None, **_ignored):
        ceiling = _DIFF_RANK.get((difficulty_ceiling or "beginner").lower(), 2)
        focuses = [str(f).lower().strip().replace(" ", "_") for f in (focus_areas or [])]
        focus_key = next((f for f in focuses if f in _ACCESSORY_BUCKETS), "full_body")
        is_full = any(f.startswith("full_body") or f.startswith("fullbody")
                      or f in ("full body", "general", "") for f in focuses)
        anchored = [f for f in focuses if f in _FOCUS_SYNONYMS]
        exact_bp, wild_tm = set(), []
        for f in anchored:
            bp, tm = _FOCUS_SYNONYMS[f]
            exact_bp.update(b.lower() for b in bp)
            wild_tm.extend(tm)
        prefer_loaded = any(h in " ".join(equipment or []) for h in _LOADED_HINTS)
        buckets = _ACCESSORY_BUCKETS.get(focus_key, [])

        # Buckets + base movements already covered by the session's existing
        # exercises — never re-add the same movement category or pattern.
        used_buckets = set()
        seen_bases = set()
        for e in ((session or {}).get("exercises") or []):
            nm = e.get("name") or ""
            seen_bases.add(_base_movement(nm))
            bi = _bucket_of(nm, focus_key)
            if bi is not None:
                used_buckets.add(bi)

        scored = []
        for c in pool:
            name = c.get("name") or ""
            if _JUNK_RE.search(name):
                continue
            rank = _DIFF_RANK.get((c.get("safety_difficulty") or "").lower())
            if rank is None or rank > ceiling:
                continue
            if not _equip_matches(c.get("equipment"), equipment or []):
                continue
            bp = (c.get("body_part") or "").lower()
            tm = (c.get("target_muscle") or "").lower()
            if is_full:
                pass
            elif anchored:
                if not (bp in exact_bp or any(w in tm for w in wild_tm)):
                    continue
                if bp.startswith("full body"):
                    continue
            elif focuses and not any(f in bp or f in tm for f in focuses):
                continue
            base = _base_movement(name)
            if not base or base in seen_bases:
                continue
            bucket = _bucket_of(name, focus_key)
            ce = (c.get("equipment") or "").lower()
            loaded = any(h in ce for h in _LOADED_HINTS)
            scored.append({
                "base": base,
                "bucket": bucket,
                # Classic-bucket exercises first (in bucket order); non-bucket last.
                "prio": bucket if bucket is not None else len(buckets) + 50,
                "loaded_pref": 0 if (loaded == prefer_loaded) else 1,
                "media": 0 if (c.get("gif_url") or c.get("video_url") or c.get("image_url")) else 1,
                "namelen": len(name),
                "row": {
                    "exercise_id": c.get("exercise_id"),
                    "name": name,
                    "body_part": c.get("body_part"),
                    "equipment": c.get("equipment"),
                    "target_muscle": c.get("target_muscle"),
                    "safety_difficulty": c.get("safety_difficulty"),
                    "is_stretch": False,
                    "_has_media": bool(c.get("gif_url") or c.get("video_url") or c.get("image_url")),
                },
            })
        # Order: bucket priority → loaded-preference → has-media → shortest
        # (canonical) name. Keep ONE per bucket AND one per base movement, and
        # skip buckets already covered by the session — yields diverse accessories.
        scored.sort(key=lambda s: (s["prio"], s["loaded_pref"], s["media"],
                                   s["namelen"], s["row"]["name"]))
        out, used_bases = [], set()
        for s in scored:
            if s["base"] in used_bases:
                continue
            if s["bucket"] is not None and s["bucket"] in used_buckets:
                continue
            used_bases.add(s["base"])
            if s["bucket"] is not None:
                used_buckets.add(s["bucket"])
            out.append(s["row"])
            if len(out) >= k:
                break
        return out

    return _fetch


# ── Program / variant resolution ───────────────────────────────────────────────
def resolve_programs(program_ids):
    sb = get_sb()
    q = (sb.table("programs")
         .select("id, program_name, difficulty_level, variant_base_id")
         .eq("is_published", True).not_.is_("variant_base_id", "null"))
    rows = q.execute().data or []
    if program_ids:
        wanted = set(program_ids)
        rows = [r for r in rows if r["id"] in wanted]
    return rows


def fetch_variant_ids(variant_base_id, only_variant_ids):
    sb = get_sb()
    rows = (sb.table("program_variants").select("id")
            .eq("base_program_id", variant_base_id).execute().data or [])
    ids = [r["id"] for r in rows]
    if only_variant_ids:
        ids = [v for v in ids if v in set(only_variant_ids)]
    return ids


def fetch_week_rows(variant_ids):
    """All week rows for the given variants (paged)."""
    sb = get_sb()
    out, step = [], 500
    for i in range(0, len(variant_ids), 50):  # PostgREST `in` list cap safety
        chunk = variant_ids[i:i + 50]
        start = 0
        while True:
            r = (sb.table("program_variant_weeks")
                 .select("id, variant_id, week_number, workouts")
                 .in_("variant_id", chunk).range(start, start + step - 1).execute())
            batch = r.data or []
            out.extend(batch)
            if len(batch) < step:
                break
            start += step
    return out


def program_equipment_union(week_rows):
    """Allowed-equipment set = normalized union of every existing exercise's
    equipment across the program. Bodyweight programs → bodyweight-only additions."""
    import re
    eq = set()
    for w in week_rows:
        for sess in (w.get("workouts") or []):
            for e in (sess.get("exercises") or []):
                val = (e.get("equipment") or "").strip().lower()
                if val:
                    eq.update(p.strip() for p in re.split(r"[/,]| or | and ", val))
    eq = {x for x in eq if x}
    eq.update({"bodyweight", "none"})
    return sorted(eq)


def _is_express(program_name: str) -> bool:
    n = (program_name or "").lower()
    return any(t in n for t in EXPRESS_TOKENS)


# ── Main ───────────────────────────────────────────────────────────────────────
async def _run_async(args):
    program_ids = []
    for chunk in (args.program_id or []):
        program_ids.extend(p.strip() for p in chunk.split(",") if p.strip())
    only_variant_ids = []
    for chunk in (args.variant_id or []):
        only_variant_ids.extend(p.strip() for p in chunk.split(",") if p.strip())

    print("⏳ Loading candidate pool…")
    pool = load_candidate_pool()
    fetcher = make_candidate_fetcher(pool)
    print(f"   pool: {len(pool)} safety-tagged exercises")

    programs = resolve_programs(program_ids)
    if not programs:
        raise SystemExit("No matching published variant-backed programs found.")

    sb = get_sb()
    total_added = 0
    total_sessions_filled = 0
    media_gaps = []
    processed_rows = 0
    apply = args.apply

    for prog in sorted(programs, key=lambda p: p["program_name"]):
        name = prog["program_name"]
        if _is_express(name) and not args.include_express:
            print(f"\n⏭  SKIP (express/duration-bug, use --include-express): {name}")
            continue
        ceiling = (prog.get("difficulty_level") or "intermediate").strip().lower()
        if ceiling not in _DIFF_RANK:
            ceiling = "intermediate"

        variant_ids = fetch_variant_ids(prog["variant_base_id"], only_variant_ids)
        if not variant_ids:
            continue
        week_rows = fetch_week_rows(variant_ids)
        equipment = program_equipment_union(week_rows)
        is_bw = set(equipment) <= {"bodyweight", "none", "wall", "chair", "doorframe",
                                   "mat", "furniture", "floor", "box", "step", "backpack",
                                   "chair/bench", "elevated surface"}
        print(f"\n▶ {name}  (level={ceiling}, variants={len(variant_ids)}, "
              f"weeks={len(week_rows)}, equipment={'BODYWEIGHT-only' if is_bw else equipment[:6]})")

        prog_added = 0
        for wr in week_rows:
            if args.limit and processed_rows >= args.limit:
                break
            processed_rows += 1
            workouts = wr.get("workouts") or []
            res = await fill_thin_sessions(
                workouts,
                equipment=equipment,
                difficulty_ceiling=ceiling,
                program_name=name,
                candidate_fetcher=fetcher,
                dry_run=not apply,
            )
            adds = res["added"]
            if not adds:
                continue
            prog_added += len(adds)
            total_sessions_filled += len({a["session"] for a in adds})
            # media-gap flag
            media_map = {c["name"]: bool(c.get("gif_url") or c.get("video_url") or c.get("image_url"))
                         for c in pool}
            for a in adds:
                if media_map.get(a["name"]) is False:
                    media_gaps.append((name, a["name"]))
                if args.verbose:
                    print(f"      + [{wr['week_number']:>2}] {a['session']}: {a['name']}")
            if apply:
                (sb.table("program_variant_weeks")
                 .update({"workouts": res["workouts"]}).eq("id", wr["id"]).execute())
        total_added += prog_added
        print(f"   → {prog_added} accessory exercises "
              f"{'APPLIED' if apply else 'PLANNED (dry-run)'}")

    print("\n" + "=" * 64)
    print(f"{'APPLIED' if apply else 'DRY-RUN'} summary")
    print(f"  week rows processed : {processed_rows}")
    print(f"  sessions topped up  : {total_sessions_filled}")
    print(f"  exercises added     : {total_added}")
    if media_gaps:
        uniq = sorted(set(n for _, n in media_gaps))
        print(f"  ⚠️  media-less additions ({len(uniq)} distinct) — hand to "
              f"program-variant-builder Phase 4 mapping:")
        for nm in uniq[:40]:
            print(f"        - {nm}")
    else:
        print("  media: every addition resolves an illustration ✅")
    if not apply:
        print("\n  (dry-run — nothing written. Re-run with --apply to persist.)")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--program-id", action="append", default=[],
                    help="repeatable / comma-separated programs.id values")
    ap.add_argument("--variant-id", action="append", default=[],
                    help="repeatable / comma-separated program_variants.id values")
    ap.add_argument("--apply", action="store_true", help="persist writes (default: dry-run)")
    ap.add_argument("--limit", type=int, default=0, help="cap week rows processed")
    ap.add_argument("--include-express", action="store_true",
                    help="also process 7-minute/express programs")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    import asyncio
    asyncio.run(_run_async(args))


if __name__ == "__main__":
    main()
