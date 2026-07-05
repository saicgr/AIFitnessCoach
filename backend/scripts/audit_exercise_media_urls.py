"""
Audit that every exercise media path in the DB points at a REAL S3 object.

Why this exists: "media coverage" checks that only assert image_s3_path /
video_s3_path are non-null can pass while every URL 403s. 2026-07-04: the S3
folder `Calisthenics-Cardio-Functional/` was renamed to
`Calisthenics-Cardio-Plyo-Functional/`; exercise_library was updated but
exercise_demos was not — 256 image + 259 video rows silently dead, so every
cardio exercise in every program schedule showed the fallback icon.

This script resolves every distinct media path in exercise_demos +
exercise_library to its public URL (same logic as api/v1/library/utils
static_url) and HEAD-checks it against S3 concurrently.

Usage:
    python scripts/audit_exercise_media_urls.py --check          # report only, exit 1 on dead paths
    python scripts/audit_exercise_media_urls.py --check --table exercise_demos
    python scripts/audit_exercise_media_urls.py --fix-folder OLD NEW --apply
        # rewrite folder OLD -> NEW in dead paths (both tables), only where the
        # renamed URL HEAD-checks 200. Without --apply it dry-runs.

Environment variables: SUPABASE_URL, SUPABASE_SERVICE_KEY (via core.supabase_client)
"""

import argparse
import concurrent.futures
import os
import sys
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase  # noqa: E402

BUCKET = "ai-fitness-coach"
S3_BASE = f"https://{BUCKET}.s3.us-east-1.amazonaws.com"

# Authenticated client when AWS creds are present — anonymous HEAD returns 403
# for BOTH missing and private-but-existing objects (videos are not public),
# so an unauthenticated audit reports every video as dead. boto3 head_object
# distinguishes 404 (truly missing) from private-but-present.
_S3 = None
if os.getenv("AWS_ACCESS_KEY_ID"):
    try:
        import boto3
        _S3 = boto3.client("s3")
    except Exception:
        _S3 = None

# (table, media column, name column) — every place a media S3 path lives.
MEDIA_COLUMNS = [
    ("exercise_demos", "image_s3_path", "id"),
    ("exercise_demos", "video_s3_path", "id"),
    ("exercise_library", "image_s3_path", "exercise_name"),
    ("exercise_library", "video_s3_path", "exercise_name"),
]


def s3_key(s3_path: str):
    if not s3_path or not s3_path.startswith("s3://"):
        return None
    without = s3_path[5:]
    idx = without.find("/")
    if idx < 0:
        return None
    return without[idx + 1:]


def public_url(s3_path: str):
    key = s3_key(s3_path)
    if not key:
        return None
    return f"{S3_BASE}/{urllib.parse.quote(key, safe='/')}"


def head_ok(url: str) -> bool:
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return 200 <= resp.status < 300
    except Exception:
        return False


def object_exists(s3_path: str) -> bool:
    # A few legacy demo rows hold plain https URLs (YouTube embeds) — those
    # aren't S3 objects; accept them rather than flagging as dead.
    if s3_path and s3_path.startswith(("http://", "https://")):
        return True
    key = s3_key(s3_path)
    if not key:
        return False
    if _S3 is not None:
        try:
            _S3.head_object(Bucket=BUCKET, Key=key)
            return True
        except Exception:
            return False
    return head_ok(public_url(s3_path))


def fetch_paths(db, table: str, column: str):
    """All non-null media paths for one column, paginated past the 1000 cap."""
    rows, offset = [], 0
    while True:
        resp = (
            db.client.table(table)
            .select(f"id, {column}")
            .not_.is_(column, "null")
            .range(offset, offset + 999)
            .execute()
        )
        batch = resp.data or []
        rows.extend(batch)
        if len(batch) < 1000:
            return rows
        offset += 1000


def check_urls(paths):
    """path -> bool(exists), concurrently."""
    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=24) as pool:
        futs = {pool.submit(object_exists, p): p for p in paths}
        for fut in concurrent.futures.as_completed(futs):
            results[futs[fut]] = fut.result()
    return results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="audit and exit 1 on dead paths")
    ap.add_argument("--table", default=None, help="limit to one table")
    ap.add_argument("--fix-folder", nargs=2, metavar=("OLD", "NEW"),
                    help="rewrite folder OLD->NEW in dead paths where NEW verifies")
    ap.add_argument("--apply", action="store_true", help="write fixes (default dry-run)")
    args = ap.parse_args()

    db = get_supabase()
    columns = [c for c in MEDIA_COLUMNS if not args.table or c[0] == args.table]

    # 1. Collect rows + distinct paths.
    table_rows = {}   # (table, column) -> rows
    all_paths = set()
    for table, column, _ in columns:
        rows = fetch_paths(db, table, column)
        table_rows[(table, column)] = rows
        all_paths.update(r[column] for r in rows if r.get(column))
        print(f"  {table}.{column}: {len(rows)} rows")

    print(f"HEAD-checking {len(all_paths)} distinct paths ...")
    exists = check_urls(all_paths)
    dead = sorted(p for p, ok in exists.items() if not ok)

    # 2. Report per table/column.
    exit_code = 0
    for (table, column), rows in table_rows.items():
        bad = [r for r in rows if r.get(column) and not exists.get(r[column], False)]
        status = "OK" if not bad else f"{len(bad)} DEAD"
        print(f"{table}.{column}: {len(rows)} rows -> {status}")
        if bad:
            exit_code = 1
            folders = {}
            for r in bad:
                key = s3_key(r[column]) or ""
                parts = key.split("/")
                folder = "/".join(parts[:2]) if len(parts) > 2 else parts[0]
                folders[folder] = folders.get(folder, 0) + 1
            for folder, n in sorted(folders.items(), key=lambda kv: -kv[1]):
                print(f"    {folder}/: {n}")

    # 3. Optional folder-rename fix.
    if args.fix_folder:
        old, new = args.fix_folder
        fixed = skipped = 0
        for (table, column), rows in table_rows.items():
            for r in rows:
                p = r.get(column)
                if not p or exists.get(p, False) or f"/{old}/" not in p:
                    continue
                candidate = p.replace(f"/{old}/", f"/{new}/")
                if not object_exists(candidate):
                    skipped += 1
                    print(f"  SKIP (target missing): {p}")
                    continue
                if args.apply:
                    db.client.table(table).update({column: candidate}).eq("id", r["id"]).execute()
                fixed += 1
        verb = "fixed" if args.apply else "would fix (dry-run)"
        print(f"fix-folder {old} -> {new}: {verb} {fixed}, skipped {skipped}")
        if args.apply and fixed:
            exit_code = 0  # re-run --check to confirm

    if args.check and dead:
        print(f"\nFAIL: {len(dead)} dead media paths")
    sys.exit(exit_code if args.check else 0)


if __name__ == "__main__":
    main()
