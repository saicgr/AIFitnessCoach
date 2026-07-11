#!/usr/bin/env python3
"""
Bridge exercise_library / exercise_library_manual entries into the
exercise_canonical / exercise_demos stack that program-schedule media
resolution depends on.

CONTEXT (2026-07-10)
------------------------------------------------------------------------
The program schedule endpoint (GET /library/{id}/schedule) resolves an
exercise's media AND the exercise_id it links for the detail-screen tap-
through purely through exercise_aliases -> exercise_canonical -> exercise_demos
(see resolve_exercise_demo_media RPC / program_exercises_with_media view).
It has NO fallback to exercise_library by name.

A large slice of exercise_library / exercise_library_manual — verified real,
with working S3 media — was never bridged into exercise_canonical /
exercise_demos. So an alias can exist and "resolve" to *some* canonical
exercise, while a much better, exact-name match with real media sits
unbridged in the library tables and is never considered. This is the same
class of bug as the Ski Erg Easy incident, one layer lower.

Scope: this ONLY affects the program schedule tab. The Library tab
(/library/exercises/{id}) and the active-workout image fetch
(get_image_by_exercise_name) both already read exercise_library /
exercise_library_cleaned directly and are unaffected.

WHAT THIS SCRIPT DOES
  For every exercise_aliases row whose alias_name has an EXACT (case-
  insensitive) name match in exercise_library or exercise_library_manual
  with real media (image_s3_path or video_s3_path), where that library
  entry is NOT already what the alias resolves to:
    1. Reuse an existing exercise_canonical row with a matching
       canonical_name if one exists; otherwise create one.
    2. Reuse an existing exercise_demos row for that canonical id if one
       exists; otherwise create one from the library row's S3 paths
       (already verified to exist by the caller — this script does not
       re-verify S3, run audit_exercise_media_urls.py for that).
    3. Repoint the exercise_aliases row's canonical_exercise_id.

  When multiple library rows share the same exercise_name (duplicate
  imports, or male/female demo variants), prefers: non "_Female"-suffixed
  name > has both image AND video > lowest id (deterministic tiebreak).

KEY PROPERTIES
  • Dry-run by DEFAULT — --apply required to write.
  • Idempotent — re-run finds 0 candidates once bridged.
  • --only-name to scope to specific alias names (comma-separated/repeatable).
  • Does NOT touch program_variant_weeks / programs.workouts — this is a
    read-time fix (schedule resolution improves for every existing AND
    future program automatically, no backfill needed).

USAGE
  python3 scripts/bridge_library_exercises_to_canonical.py --check
  python3 scripts/bridge_library_exercises_to_canonical.py --apply --only-name "Hack Squat,Lat Pulldown"
  python3 scripts/bridge_library_exercises_to_canonical.py --apply   # all candidates
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

_sb = None


def get_sb():
    global _sb
    if _sb is None:
        from supabase import create_client
        if not (SUPABASE_URL and SUPABASE_KEY):
            raise SystemExit("SUPABASE_URL / SUPABASE_KEY not set in backend/.env")
        _sb = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _sb


def _norm(s: Optional[str]) -> str:
    return re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).strip()


def fetch_all(table: str, columns: str) -> List[Dict[str, Any]]:
    sb = get_sb()
    out, start, step = [], 0, 1000
    while True:
        r = sb.table(table).select(columns).range(start, start + step - 1).execute()
        batch = r.data or []
        out.extend(batch)
        if len(batch) < step:
            break
        start += step
    return out


def _pick_best(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    def score(r):
        is_female = "_female" in (r.get("exercise_name") or "").lower()
        has_both = bool(r.get("image_s3_path")) and bool(r.get("video_s3_path"))
        return (0 if not is_female else 1, 0 if has_both else 1, str(r.get("id")))
    return sorted(rows, key=score)[0]


def _build_library_name_index() -> Dict[str, List[Dict[str, Any]]]:
    """One bulk fetch per table (~3.4k rows total) instead of a query per alias —
    turns an O(aliases) network-bound scan into two paginated fetches + in-memory
    lookups."""
    index: Dict[str, List[Dict[str, Any]]] = {}
    for table in ("exercise_library", "exercise_library_manual"):
        rows = fetch_all(table, "id,exercise_name,image_s3_path,video_s3_path")
        for r in rows:
            name = (r.get("exercise_name") or "").strip()
            if not name:
                continue
            index.setdefault(name.lower(), []).append(r)
    return index


def find_bridge_candidates(only_names: Optional[set] = None):
    aliases = fetch_all("exercise_aliases", "id,alias_name,alias_name_normalized,canonical_exercise_id")
    if only_names:
        aliases = [a for a in aliases if a["alias_name"].strip().lower() in only_names]

    canon_ids = {a["canonical_exercise_id"] for a in aliases if a.get("canonical_exercise_id")}
    canon_names: Dict[str, str] = {}
    ids_list = list(canon_ids)
    for i in range(0, len(ids_list), 200):
        chunk = ids_list[i:i + 200]
        rows = get_sb().table("exercise_canonical").select("id, canonical_name").in_("id", chunk).execute().data or []
        for r in rows:
            canon_names[r["id"]] = r["canonical_name"]

    print("⏳ Bulk-fetching exercise_library + exercise_library_manual (~3.4k rows)…")
    library_index = _build_library_name_index()
    print(f"   indexed {sum(len(v) for v in library_index.values())} library rows "
          f"under {len(library_index)} distinct names")

    candidates = []
    seen_alias_names: set = set()
    for a in aliases:
        name = a["alias_name"].strip()
        if not name:
            continue
        key = name.lower()
        if key in seen_alias_names:
            continue  # dedupe repeat alias_name text across rows
        seen_alias_names.add(key)

        hits = library_index.get(key, [])
        hits_with_media = [r for r in hits if r.get("image_s3_path") or r.get("video_s3_path")]
        if not hits_with_media:
            continue

        current_canonical_name = canon_names.get(a.get("canonical_exercise_id"))
        if current_canonical_name and _norm(current_canonical_name) == _norm(name):
            continue  # already correctly self-matching

        best = _pick_best(hits_with_media)
        candidates.append({
            "alias_id": a["id"],
            "alias_name": name,
            "current_canonical_id": a.get("canonical_exercise_id"),
            "current_canonical_name": current_canonical_name,
            "library_row": best,
        })
    return candidates


def apply_bridge(candidates: List[Dict[str, Any]]):
    sb = get_sb()
    created_canonical = 0
    created_demos = 0
    updated_aliases = 0

    for c in candidates:
        name = c["alias_name"]
        lib = c["library_row"]

        existing_canon = sb.table("exercise_canonical").select("id").ilike("canonical_name", name).execute().data
        if existing_canon:
            canon_id = existing_canon[0]["id"]
        else:
            inserted = sb.table("exercise_canonical").insert({
                "canonical_name": name,
                "canonical_name_normalized": _norm(name),
            }).execute().data
            canon_id = inserted[0]["id"]
            created_canonical += 1

        existing_demo = sb.table("exercise_demos").select("id").eq("canonical_exercise_id", canon_id).execute().data
        if not existing_demo:
            sb.table("exercise_demos").insert({
                "canonical_exercise_id": canon_id,
                "demo_gender": "neutral",
                "image_s3_path": lib.get("image_s3_path"),
                "video_s3_path": lib.get("video_s3_path"),
                "original_exercise_library_id": lib.get("id"),
                "original_exercise_name": lib.get("exercise_name"),
            }).execute()
            created_demos += 1

        sb.table("exercise_aliases").update({"canonical_exercise_id": canon_id}).eq("id", c["alias_id"]).execute()
        updated_aliases += 1

    return created_canonical, created_demos, updated_aliases


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
                                  allow_abbrev=False)
    ap.add_argument("--check", action="store_true", help="Dry-run report (default behavior)")
    ap.add_argument("--apply", action="store_true", help="Write the bridge (default: dry-run)")
    ap.add_argument("--only-name", action="append",
                     help="Comma-separated/repeatable alias names to scope to")
    ap.add_argument("--exclude-name", action="append",
                     help="Comma-separated/repeatable alias names to exclude — for confirmed cases "
                          "where the current canonical mapping is deliberate/correct despite an exact "
                          "text match existing in the library (e.g. the Ski Erg Easy alias)")
    args = ap.parse_args()

    only_names = None
    if args.only_name:
        only_names = set()
        for chunk in args.only_name:
            only_names.update(n.strip().lower() for n in chunk.split(",") if n.strip())

    exclude_names = set()
    if args.exclude_name:
        for chunk in args.exclude_name:
            exclude_names.update(n.strip().lower() for n in chunk.split(",") if n.strip())

    print("⏳ Scanning exercise_aliases for library entries needing a canonical bridge…")
    candidates = find_bridge_candidates(only_names)
    if exclude_names:
        before = len(candidates)
        candidates = [c for c in candidates if c["alias_name"].strip().lower() not in exclude_names]
        print(f"   excluded {before - len(candidates)} candidate(s) via --exclude-name")

    if not candidates:
        print("✅ no bridge candidates found")
        return

    print(f"⚠️  {len(candidates)} alias(es) can be bridged to a better exact-name library match:")
    for c in candidates:
        lib_name = c["library_row"]["exercise_name"]
        print(f"  {c['alias_name']!r:35} currently -> {c['current_canonical_name']!r:35} "
              f"would bridge to library entry {lib_name!r} ({c['library_row']['id']})")

    if args.apply:
        created_canonical, created_demos, updated_aliases = apply_bridge(candidates)
        print(f"\n✅ applied: {created_canonical} new exercise_canonical row(s), "
              f"{created_demos} new exercise_demos row(s), {updated_aliases} alias(es) repointed")
    else:
        print("\n(dry-run — pass --apply to write, optionally --only-name to scope)")


if __name__ == "__main__":
    main()
