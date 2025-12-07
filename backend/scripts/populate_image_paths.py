#!/usr/bin/env python3
"""
Script to populate image_s3_path in exercise_library table
by matching exercise names to S3 illustration files.
"""

import boto3
import psycopg2
import os
import re
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

# Configuration from .env
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
S3_BUCKET = 'ai-fitness-coach'
S3_PREFIX = 'ILLUSTRATIONS/'

DB_HOST = 'db.hpbzfahijszqmgsybuor.supabase.co'
DB_NAME = 'postgres'
DB_USER = 'postgres'
DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD')


def normalize_name(name):
    """Normalize exercise name for matching"""
    if not name:
        return ''
    # Lowercase, remove special chars, normalize spaces
    normalized = name.lower().strip()
    # Remove _male/_female suffix for matching
    normalized = re.sub(r'[_\s]*(male|female)\s*$', '', normalized, flags=re.IGNORECASE)
    # Remove trailing numbers (like exercise1.jpeg -> exercise)
    normalized = re.sub(r'\d+$', '', normalized)
    # Normalize spaces and special chars
    normalized = re.sub(r'[^a-z0-9\s]', ' ', normalized)
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    return normalized


def main():
    print("=" * 60)
    print("Populating image_s3_path in exercise_library")
    print("=" * 60)

    # 1. Connect to database
    print("\n1. Connecting to database...")
    conn = psycopg2.connect(
        host=DB_HOST, database=DB_NAME,
        user=DB_USER, password=DB_PASSWORD, port=5432
    )
    cur = conn.cursor()

    # 2. Add image_s3_path column if it doesn't exist
    print("\n2. Adding image_s3_path column if not exists...")
    cur.execute('''
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'exercise_library'
                AND column_name = 'image_s3_path'
            ) THEN
                ALTER TABLE exercise_library ADD COLUMN image_s3_path TEXT;
            END IF;
        END $$;
    ''')
    conn.commit()
    print("   Column added/verified")

    # 3. Connect to S3 and list all images
    print("\n3. Connecting to S3 and listing images...")
    s3 = boto3.client('s3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

    # Build lookup: normalized_name -> s3_path
    # Store the first/primary image (without "1" suffix)
    image_lookup = {}
    paginator = s3.get_paginator('list_objects_v2')

    for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=S3_PREFIX):
        if 'Contents' in page:
            for obj in page['Contents']:
                key = obj['Key']
                if key.lower().endswith(('.jpeg', '.jpg', '.png', '.gif')):
                    # Extract filename without extension
                    filename = key.rsplit('/', 1)[-1]
                    name_without_ext = os.path.splitext(filename)[0]

                    # Skip files ending with "1" (secondary images)
                    if name_without_ext.endswith('1'):
                        continue

                    # Normalize for matching
                    normalized = normalize_name(name_without_ext)

                    if normalized and normalized not in image_lookup:
                        image_lookup[normalized] = key

    print(f"   Found {len(image_lookup)} unique images in S3")

    # 4. Get all exercises
    cur.execute("SELECT id, exercise_name FROM exercise_library")
    exercises = cur.fetchall()
    print(f"   Found {len(exercises)} exercises in database")

    # 5. Match and update
    print("\n4. Matching exercises to images...")
    matched = 0
    unmatched = []
    match_details = []

    for exercise_id, exercise_name in exercises:
        if not exercise_name:
            continue

        # Normalize exercise name
        normalized_exercise = normalize_name(exercise_name)

        # Try exact match first
        s3_key = image_lookup.get(normalized_exercise)

        if s3_key:
            # Store full S3 URI
            s3_path = f"s3://{S3_BUCKET}/{s3_key}"
            cur.execute(
                "UPDATE exercise_library SET image_s3_path = %s WHERE id = %s",
                (s3_path, exercise_id)
            )
            matched += 1
            if len(match_details) < 10:
                match_details.append((exercise_name, s3_key))
        else:
            unmatched.append(exercise_name)

    conn.commit()

    print("\n" + "=" * 60)
    print("Results:")
    print("=" * 60)
    print(f"  Matched: {matched}")
    print(f"  Unmatched: {len(unmatched)}")

    print(f"\nSample matches:")
    for name, path in match_details:
        print(f"  ✅ {name}")
        print(f"     -> {path}")

    if unmatched:
        print(f"\nFirst 30 unmatched exercises:")
        for name in unmatched[:30]:
            print(f"  ❌ {name}")

        if len(unmatched) > 30:
            print(f"  ... and {len(unmatched) - 30} more")

    # Show some sample unmatched images for debugging
    matched_names = set(normalize_name(e[1]) for e in exercises if e[1])
    unmatched_images = []
    for img_name in image_lookup.keys():
        if img_name not in matched_names:
            unmatched_images.append(img_name)

    if unmatched_images:
        print(f"\nFirst 10 S3 images without matching exercises:")
        for name in unmatched_images[:10]:
            print(f"  - {name}")

    cur.close()
    conn.close()

    print("\nDone!")


if __name__ == '__main__':
    main()
