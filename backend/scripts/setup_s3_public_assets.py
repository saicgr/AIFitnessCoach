"""
Set up S3 bucket for public static assets.

Makes ILLUSTRATIONS/* and Ultimate-Muscle-Visuals/* publicly readable
and sets Cache-Control headers for permanent caching.

Idempotent — safe to run multiple times.

Usage:
    cd backend && python scripts/setup_s3_public_assets.py
"""
from typing import Set
import json
import os
import sys

import boto3
from dotenv import load_dotenv

load_dotenv()

BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")

# Prefixes that should be publicly readable
STATIC_PREFIXES = ["ILLUSTRATIONS/*", "Ultimate-Muscle-Visuals/*"]

# Cache-Control header for immutable static assets (1 year)
CACHE_CONTROL = "public, max-age=31536000, immutable"


def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
        region_name=REGION,
    )


def disable_block_public_access(s3):
    """Disable S3 Block Public Access settings that prevent bucket policies."""
    try:
        s3.put_public_access_block(
            Bucket=BUCKET,
            PublicAccessBlockConfiguration={
                "BlockPublicAcls": True,       # Keep ACL blocking
                "IgnorePublicAcls": True,      # Keep ACL blocking
                "BlockPublicPolicy": False,    # Allow bucket policies
                "RestrictPublicBuckets": False, # Allow public access via policy
            },
        )
        print("Disabled BlockPublicPolicy (kept ACL blocking)")
    except Exception as e:
        print(f"Warning: could not update Block Public Access: {e}")
        print("You may need to do this manually in the AWS Console.")
        sys.exit(1)


def apply_bucket_policy(s3):
    """Apply public-read bucket policy for static asset prefixes."""
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadStaticAssets",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": [
                    f"arn:aws:s3:::{BUCKET}/{prefix}"
                    for prefix in STATIC_PREFIXES
                ],
            }
        ],
    }

    # Check for existing policy and merge if needed
    try:
        existing = json.loads(s3.get_bucket_policy(Bucket=BUCKET)["Policy"])
        # Remove any old version of our statement
        existing["Statement"] = [
            stmt
            for stmt in existing["Statement"]
            if stmt.get("Sid") != "PublicReadStaticAssets"
        ]
        existing["Statement"].append(policy["Statement"][0])
        policy = existing
    except s3.exceptions.from_code("NoSuchBucketPolicy"):
        pass
    except Exception:
        # If we can't read the existing policy, just set the new one
        pass

    s3.put_bucket_policy(Bucket=BUCKET, Policy=json.dumps(policy))
    print(f"Bucket policy applied: public read on {STATIC_PREFIXES}")


def set_cache_control(s3, prefix: str):
    """Set Cache-Control headers on all objects under a prefix."""
    paginator = s3.get_paginator("list_objects_v2")
    # Remove trailing wildcard for listing
    list_prefix = prefix.rstrip("*")
    count = 0

    for page in paginator.paginate(Bucket=BUCKET, Prefix=list_prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            try:
                # Copy object in-place with new Cache-Control metadata
                s3.copy_object(
                    Bucket=BUCKET,
                    CopySource={"Bucket": BUCKET, "Key": key},
                    Key=key,
                    CacheControl=CACHE_CONTROL,
                    MetadataDirective="REPLACE",
                    ContentType=_guess_content_type(key),
                )
                count += 1
                if count % 100 == 0:
                    print(f"  Updated {count} objects in {list_prefix}...")
            except Exception as e:
                print(f"  Warning: failed to update {key}: {e}")

    print(f"Set Cache-Control on {count} objects under {list_prefix}")


def _guess_content_type(key: str) -> str:
    """Guess content type from file extension."""
    lower = key.lower()
    if lower.endswith(".png"):
        return "image/png"
    elif lower.endswith(".jpg") or lower.endswith(".jpeg"):
        return "image/jpeg"
    elif lower.endswith(".webp"):
        return "image/webp"
    elif lower.endswith(".gif"):
        return "image/gif"
    elif lower.endswith(".svg"):
        return "image/svg+xml"
    return "application/octet-stream"


def main():
    s3 = get_s3_client()

    print(f"Setting up public static assets for bucket: {BUCKET}")
    print("=" * 60)

    # Step 1: Disable Block Public Access for policies
    print("\n1. Configuring Block Public Access...")
    disable_block_public_access(s3)

    # Step 2: Apply bucket policy
    print("\n2. Applying bucket policy...")
    apply_bucket_policy(s3)

    # Step 3: Set Cache-Control headers
    print("\n3. Setting Cache-Control headers...")
    for prefix in STATIC_PREFIXES:
        set_cache_control(s3, prefix)

    print("\n" + "=" * 60)
    print("Done! Verify with:")
    print(f"  curl -I https://{BUCKET}.s3.{REGION}.amazonaws.com/ILLUSTRATIONS/<any-image>.png")
    print("  Expected: Cache-Control: public, max-age=31536000, immutable")


if __name__ == "__main__":
    main()
