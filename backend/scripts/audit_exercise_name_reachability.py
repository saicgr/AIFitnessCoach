"""
Audit that every exercise is REACHABLE BY THE NAME the app actually asks for.

Why this exists
---------------
`audit_exercise_media_urls.py` answers "does this stored S3 path exist?". It
cannot answer "can the app FIND this exercise's media in the first place?" —
and on 2026-07-30 that was the failing half.

`resolve_exercise_demo_media()` (migration 2290) is the read-time chokepoint for
exercise images and videos, and it matches names ONLY through `exercise_aliases`.
But aliases were only ever populated with *alternate* spellings — a canonical
exercise's own name was never registered. 1697 of 2070 canonical exercises (82%)
had no alias for their own name and were therefore invisible to the resolver,
even though `exercise_demos` held real, live S3 media for them.

Production symptom: a continuous 404 storm on
    GET /api/v1/exercise-images/Bodyweight%20standing%20calf%20raise
    GET /api/v1/videos/by-exercise/Bodyweight%20standing%20calf%20raise
That exercise had BOTH a real image and a real video on S3 the entire time.
Every non-null-path media audit passed. Nothing caught it.

Migration 2391 backfilled the self-aliases. This gate stops the gap reopening.

What it checks
--------------
  1. CANONICAL REACHABILITY — every `exercise_canonical.canonical_name` resolves
     through `resolve_exercise_demo_media_batch()` to at least one media path.
     Failures split into:
       * no-media       — the exercise genuinely has no demo asset (generate one)
       * unreachable    — media EXISTS but the name does not resolve (alias gap;
                          this is the regression this gate exists for)
  2. IN-USE NAMES — every distinct exercise name written into recent workouts'
     `exercises_json` resolves. This is the user-visible signal: an unresolvable
     name here is a 404 someone is seeing right now.

Usage:
    python scripts/audit_exercise_name_reachability.py            # full report
    python scripts/audit_exercise_name_reachability.py --check    # GATE: exit 1 on unreachable
    python scripts/audit_exercise_name_reachability.py --check --allow-no-media
        # only fail on the alias-gap class, tolerate genuinely media-less exercises
    python scripts/audit_exercise_name_reachability.py --workout-sample 800

Environment: SUPABASE_URL, SUPABASE_SERVICE_KEY (via core.supabase_client)
"""

import argparse
import json
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402

BATCH = 500


def _fetch_all(client, table, cols):
    out, offset = [], 0
    while True:
        rows = client.table(table).select(cols).range(offset, offset + 999).execute().data
        if not rows:
            break
        out.extend(rows)
        if len(rows) < 1000:
            break
        offset += 1000
    return out


def _resolve(client, names):
    """name -> {'image': bool, 'video': bool} for every name that resolves."""
    resolved = {}
    for i in range(0, len(names), BATCH):
        chunk = names[i:i + BATCH]
        try:
            res = client.rpc(
                "resolve_exercise_demo_media_batch", {"p_names": chunk}
            ).execute()
        except Exception as e:
            print(f"❌ resolve_exercise_demo_media_batch failed: {e}", file=sys.stderr)
            print("   (is migration 2392 applied?)", file=sys.stderr)
            sys.exit(2)
        for row in (res.data or []):
            rn = row.get("requested_name")
            if rn:
                resolved[rn] = {
                    "image": bool(row.get("image_s3_path")),
                    "video": bool(row.get("video_s3_path")),
                }
    return resolved


def _workout_names(client, sample):
    rows = (
        client.table("workouts")
        .select("exercises_json,warmup_json,stretch_json,generation_method")
        .order("created_at", desc=True)
        .limit(sample)
        .execute()
        .data
    ) or []
    names, by_method = Counter(), {}
    for w in rows:
        gm = w.get("generation_method") or "unknown"
        for field in ("exercises_json", "warmup_json", "stretch_json"):
            blob = w.get(field)
            if isinstance(blob, str):
                try:
                    blob = json.loads(blob)
                except Exception:
                    continue
            if isinstance(blob, dict):
                blob = blob.get("exercises") or []
            if not isinstance(blob, list):
                continue
            for e in blob:
                if not isinstance(e, dict):
                    continue
                n = (e.get("name") or e.get("exercise_name") or "").strip()
                if n:
                    names[n] += 1
                    by_method.setdefault(gm, Counter())[n] += 1
    return names, by_method


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="exit 1 when anything is unreachable")
    ap.add_argument("--allow-no-media", action="store_true",
                    help="only fail on the alias-gap class, not genuinely media-less exercises")
    ap.add_argument("--workout-sample", type=int, default=400,
                    help="how many recent workouts to scan for in-use names")
    args = ap.parse_args()

    client = get_supabase().client

    # ---- 1. Canonical reachability -------------------------------------------
    canon = _fetch_all(client, "exercise_canonical", "id,canonical_name")
    demos = _fetch_all(client, "exercise_demos",
                       "canonical_exercise_id,image_s3_path,video_s3_path")
    has_media = {
        d["canonical_exercise_id"] for d in demos
        if d.get("image_s3_path") or d.get("video_s3_path")
    }

    names = [c["canonical_name"] for c in canon if c.get("canonical_name")]
    resolved = _resolve(client, names)

    unreachable, no_media = [], []
    for c in canon:
        n = c.get("canonical_name")
        if not n or n in resolved:
            continue
        (no_media if c["id"] not in has_media else unreachable).append(n)

    print(f"exercise_canonical            : {len(canon)}")
    print(f"  resolvable by own name      : {len(resolved)}")
    print(f"  UNREACHABLE (media exists!) : {len(unreachable)}")
    print(f"  no demo media at all        : {len(no_media)}")

    if unreachable:
        print("\n❌ UNREACHABLE — these have media but no alias resolves their own name.")
        print("   This is the 2026-07-30 regression class. Fix by registering a")
        print("   self-alias (see migrations/2391_canonical_self_alias_backfill.sql),")
        print("   NOT by adding fuzzy matching.")
        for n in unreachable[:40]:
            print(f"     {n}")
        if len(unreachable) > 40:
            print(f"     ... {len(unreachable) - 40} more")

    if no_media:
        print(f"\n⚠️  NO MEDIA — {len(no_media)} exercise(s) have no demo asset.")
        print("   Generate illustrations (docs/planning/exercise-images/run_pipeline.py).")
        for n in no_media[:20]:
            print(f"     {n}")
        if len(no_media) > 20:
            print(f"     ... {len(no_media) - 20} more")

    # ---- 2. Names actually in use --------------------------------------------
    in_use, by_method = _workout_names(client, args.workout_sample)
    used_resolved = _resolve(client, list(in_use.keys()))
    used_missing = {n: c for n, c in in_use.items() if n not in used_resolved}

    print(f"\nrecent workouts scanned       : {args.workout_sample}")
    print(f"  distinct exercise names     : {len(in_use)}")
    print(f"  UNRESOLVABLE in-use names   : {len(used_missing)} "
          f"({sum(used_missing.values())} occurrences)")
    if used_missing:
        print("\n❌ These names are being written into workouts but resolve to NO media —")
        print("   every request for them 404s. Fix at the SOURCE (the generator emitting")
        print("   the name) or register an alias; do not add a client-side fallback.")
        for n, ct in sorted(used_missing.items(), key=lambda kv: -kv[1])[:30]:
            print(f"     {ct:5d}x  {n}")
        print("\n   by generation_method:")
        for gm, cnt in sorted(by_method.items(), key=lambda kv: -sum(kv[1].values())):
            bad = sum(c for n, c in cnt.items() if n in used_missing)
            tot = sum(cnt.values())
            if tot:
                print(f"     {gm:24s} {bad:5d}/{tot:5d}  ({100 * bad / tot:.1f}% unresolvable)")

    if args.check:
        fail = bool(unreachable) or bool(used_missing)
        if not args.allow_no_media:
            fail = fail or bool(no_media)
        if fail:
            print("\n❌ GATE FAILED")
            sys.exit(1)
        print("\n✅ every exercise is reachable by name")
    return 0


if __name__ == "__main__":
    sys.exit(main())
