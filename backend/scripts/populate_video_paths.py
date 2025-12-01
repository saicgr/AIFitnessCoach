#!/usr/bin/env python3
"""
Script to populate video_s3_path in exercise_library table
by matching exercise names to S3 video files.
"""

import boto3
import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

# Configuration from .env
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
S3_BUCKET = 'ai-fitness-coach'
S3_PREFIX = 'VERTICAL VIDEOS/'

DB_HOST = 'db.hpbzfahijszqmgsybuor.supabase.co'
DB_NAME = 'postgres'
DB_USER = 'postgres'
DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD')


def main():
    print("=" * 60)
    print("Populating video_s3_path in exercise_library")
    print("=" * 60)

    # 1. Connect to S3 and list all videos
    print("\n1. Connecting to S3 and listing videos...")
    s3 = boto3.client('s3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

    # Build lookup: exercise_name_lower -> s3_path
    video_lookup = {}
    paginator = s3.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=S3_PREFIX):
        if 'Contents' in page:
            for obj in page['Contents']:
                key = obj['Key']
                if key.endswith('.mp4'):
                    # Extract filename without extension
                    filename = key.rsplit('/', 1)[-1].replace('.mp4', '')
                    video_lookup[filename.lower()] = key

    print(f"   Found {len(video_lookup)} videos in S3")

    # 2. Connect to database
    print("\n2. Connecting to database...")
    conn = psycopg2.connect(
        host=DB_HOST, database=DB_NAME,
        user=DB_USER, password=DB_PASSWORD, port=5432
    )
    cur = conn.cursor()

    # 3. Get all exercises
    cur.execute("SELECT id, exercise_name FROM exercise_library")
    exercises = cur.fetchall()
    print(f"   Found {len(exercises)} exercises in database")

    # 4. Match and update
    print("\n3. Matching exercises to videos...")
    matched = 0
    unmatched = []

    for exercise_id, exercise_name in exercises:
        if not exercise_name:
            continue

        # Try exact match (case-insensitive)
        s3_key = video_lookup.get(exercise_name.lower())

        if s3_key:
            # Store full S3 URI
            s3_path = f"s3://{S3_BUCKET}/{s3_key}"
            cur.execute(
                "UPDATE exercise_library SET video_s3_path = %s WHERE id = %s",
                (s3_path, exercise_id)
            )
            matched += 1
        else:
            unmatched.append(exercise_name)

    conn.commit()

    print("\n" + "=" * 60)
    print("Results:")
    print("=" * 60)
    print(f"  Matched: {matched}")
    print(f"  Unmatched: {len(unmatched)}")

    if unmatched:
        print(f"\nFirst 30 unmatched exercises:")
        for name in unmatched[:30]:
            print(f"  - {name}")

        if len(unmatched) > 30:
            print(f"  ... and {len(unmatched) - 30} more")

    # Show some sample unmatched videos for debugging
    matched_names = set(e[1].lower() for e in exercises if e[1])
    unmatched_videos = []
    for video_name in video_lookup.keys():
        if video_name not in matched_names:
            unmatched_videos.append(video_name)

    if unmatched_videos:
        print(f"\nFirst 10 S3 videos without matching exercises:")
        for name in unmatched_videos[:10]:
            print(f"  - {name}")

    cur.close()
    conn.close()

    print("\nDone!")


if __name__ == '__main__':
    main()
