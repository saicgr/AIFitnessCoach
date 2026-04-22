#!/usr/bin/env python3
"""
Apply (or refresh) the S3 lifecycle rule that auto-deletes DSAR export
archives under the `dsar-exports/` prefix after 8 days.

Why 8 days:
    * DSAR signed download URLs expire after 7 days (see `api/v1/dsar.py`
      DOWNLOAD_TTL). The 8-day deletion window is belt-and-suspenders —
      once the URL no longer works, we also remove the object itself so
      we're not storing every user's personal archive indefinitely.
    * Matches the retention promises we added to privacy_policy.html §7.

Usage:
    cd backend && python3 scripts/apply_s3_dsar_lifecycle.py

Idempotent: reruns replace the rule rather than duplicating it.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

# Load .env so standalone script has the same creds the backend uses.
try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).resolve().parent.parent / ".env")
except ImportError:
    pass

import boto3
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
BUCKET = os.environ.get("S3_BUCKET_NAME")
PREFIX = "dsar-exports/"
RULE_ID = "dsar-exports-auto-delete-8d"
DAYS = 8


def main() -> int:
    if not BUCKET:
        print("❌ S3_BUCKET_NAME not set. Aborting.", file=sys.stderr)
        return 1

    s3 = boto3.client(
        "s3",
        region_name=REGION,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
    )

    # Fetch existing rules so we can merge rather than clobber. Buckets
    # with no lifecycle config raise NoSuchLifecycleConfiguration.
    existing_rules = []
    try:
        resp = s3.get_bucket_lifecycle_configuration(Bucket=BUCKET)
        existing_rules = resp.get("Rules", [])
    except ClientError as e:
        if e.response["Error"]["Code"] != "NoSuchLifecycleConfiguration":
            raise

    # Drop any previous version of our rule so the update is idempotent.
    merged = [r for r in existing_rules if r.get("ID") != RULE_ID]

    dsar_rule = {
        "ID": RULE_ID,
        "Status": "Enabled",
        "Filter": {"Prefix": PREFIX},
        "Expiration": {"Days": DAYS},
        # Also clean up failed multipart uploads so a partial put_object
        # never leaves hidden storage sitting around.
        "AbortIncompleteMultipartUpload": {"DaysAfterInitiation": 1},
        # Non-current versions (if versioning is on) also disappear after
        # 8 days — we don't want a "delete" to leave a private copy.
        "NoncurrentVersionExpiration": {"NoncurrentDays": DAYS},
    }

    merged.append(dsar_rule)

    s3.put_bucket_lifecycle_configuration(
        Bucket=BUCKET,
        LifecycleConfiguration={"Rules": merged},
    )

    print(f"✅ Applied lifecycle rule '{RULE_ID}' on s3://{BUCKET}/{PREFIX}")
    print(f"   Objects auto-delete after {DAYS} days.")
    print(f"   Total rules on bucket: {len(merged)}")
    print()
    print("Rule JSON:")
    print(json.dumps(dsar_rule, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
