#!/usr/bin/env python3
"""
Audit script to find mismatches between exercise images and videos.

The issue: populate_video_paths.py uses exact case-insensitive matching,
while populate_image_paths.py uses fuzzy normalized matching. This can cause
the same exercise to match different image vs video files.

Usage:
    python audit_exercise_media.py --output ./audit_results
    python audit_exercise_media.py --generate-sql --threshold 0.9
"""

import argparse
import boto3
import csv
import json
import os
import re
from datetime import datetime
from difflib import SequenceMatcher
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

# Configuration
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
S3_BUCKET = 'ai-fitness-coach'
IMAGE_PREFIX = 'ILLUSTRATIONS/'
VIDEO_PREFIX = 'VERTICAL VIDEOS/'

DB_HOST = 'db.hpbzfahijszqmgsybuor.supabase.co'
DB_NAME = 'postgres'
DB_USER = 'postgres'
DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD')


def normalize_name(name: str) -> str:
    """
    Normalize exercise name for comparison.
    Matches the logic from populate_image_paths.py
    """
    if not name:
        return ''
    normalized = name.lower().strip()
    # Remove _male/_female suffix
    normalized = re.sub(r'[_\s]*(male|female)\s*$', '', normalized, flags=re.IGNORECASE)
    # Remove trailing numbers
    normalized = re.sub(r'\d+$', '', normalized)
    # Normalize spaces and special chars
    normalized = re.sub(r'[^a-z0-9\s]', ' ', normalized)
    normalized = re.sub(r'\s+', ' ', normalized).strip()
    return normalized


def extract_basename(s3_path: str) -> str:
    """Extract filename without extension from S3 path"""
    if not s3_path:
        return ''
    filename = s3_path.rsplit('/', 1)[-1]
    name_without_ext = os.path.splitext(filename)[0]
    return name_without_ext


def similarity_score(s1: str, s2: str) -> float:
    """Calculate similarity between two strings (0.0 to 1.0)"""
    if not s1 or not s2:
        return 0.0
    return SequenceMatcher(None, s1.lower(), s2.lower()).ratio()


def detect_mismatch(exercise_name: str, image_path: str, video_path: str) -> dict:
    """
    Determine if image and video paths are mismatched for an exercise.

    Returns dict with mismatch details.
    """
    image_basename = extract_basename(image_path)
    video_basename = extract_basename(video_path)

    normalized_image = normalize_name(image_basename)
    normalized_video = normalize_name(video_basename)
    normalized_exercise = normalize_name(exercise_name)

    # Calculate similarity scores
    image_video_similarity = similarity_score(normalized_image, normalized_video)
    image_exercise_similarity = similarity_score(normalized_image, normalized_exercise)
    video_exercise_similarity = similarity_score(normalized_video, normalized_exercise)

    # Determine if mismatched
    is_mismatched = False
    confidence = 'low'
    reason = ''

    # Check if image and video basenames match
    if normalized_image == normalized_video:
        # Perfect match
        is_mismatched = False
        reason = 'Image and video names match exactly (normalized)'
    elif image_video_similarity >= 0.9:
        # Very similar
        is_mismatched = False
        reason = f'High similarity between image and video names ({image_video_similarity:.2f})'
    elif image_video_similarity < 0.5:
        # Definite mismatch
        is_mismatched = True
        confidence = 'high'
        reason = f'Low similarity between image ({normalized_image}) and video ({normalized_video}): {image_video_similarity:.2f}'
    elif image_video_similarity < 0.7:
        # Likely mismatch
        is_mismatched = True
        confidence = 'medium'
        reason = f'Moderate mismatch between image and video names: {image_video_similarity:.2f}'
    else:
        # Borderline - check against exercise name
        if video_exercise_similarity > image_exercise_similarity + 0.2:
            is_mismatched = True
            confidence = 'medium'
            reason = f'Video matches exercise better than image ({video_exercise_similarity:.2f} vs {image_exercise_similarity:.2f})'

    return {
        'is_mismatched': is_mismatched,
        'confidence': confidence,
        'reason': reason,
        'image_basename': image_basename,
        'video_basename': video_basename,
        'normalized_image': normalized_image,
        'normalized_video': normalized_video,
        'image_video_similarity': round(image_video_similarity, 3),
        'image_exercise_similarity': round(image_exercise_similarity, 3),
        'video_exercise_similarity': round(video_exercise_similarity, 3),
    }


def find_best_image_match(exercise_name: str, video_basename: str, image_catalog: dict) -> tuple:
    """
    Find the best matching image for an exercise.

    Returns: (best_match_path, confidence_score, match_type)
    """
    normalized_exercise = normalize_name(exercise_name)
    normalized_video = normalize_name(video_basename)

    best_match = None
    best_score = 0
    match_type = 'none'

    for normalized_name, s3_path in image_catalog.items():
        # Check similarity to video name (most reliable)
        video_score = similarity_score(normalized_name, normalized_video)

        # Check similarity to exercise name
        exercise_score = similarity_score(normalized_name, normalized_exercise)

        # Use the higher score
        score = max(video_score, exercise_score)

        # Boost exact matches
        if normalized_name == normalized_video or normalized_name == normalized_exercise:
            score = 1.0

        if score > best_score:
            best_score = score
            best_match = s3_path
            if score == 1.0:
                match_type = 'exact'
            elif score >= 0.8:
                match_type = 'fuzzy'
            else:
                match_type = 'partial'

    return (best_match, round(best_score, 3), match_type)


def build_image_catalog(s3_client) -> dict:
    """Build catalog of all images: {normalized_name: s3_full_path}"""
    catalog = {}
    paginator = s3_client.get_paginator('list_objects_v2')

    for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=IMAGE_PREFIX):
        if 'Contents' in page:
            for obj in page['Contents']:
                key = obj['Key']
                if key.lower().endswith(('.jpeg', '.jpg', '.png', '.gif')):
                    filename = key.rsplit('/', 1)[-1]
                    name_without_ext = os.path.splitext(filename)[0]

                    # Skip secondary images (ending with "1")
                    if name_without_ext.endswith('1'):
                        continue

                    normalized = normalize_name(name_without_ext)
                    if normalized:
                        s3_path = f"s3://{S3_BUCKET}/{key}"
                        # Keep first match (primary image)
                        if normalized not in catalog:
                            catalog[normalized] = s3_path

    return catalog


def run_audit(output_dir: str = None) -> dict:
    """Run the full audit and return results"""
    print("=" * 60)
    print("Exercise Media Audit")
    print("=" * 60)

    # Connect to S3
    print("\n1. Connecting to S3...")
    s3 = boto3.client('s3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

    # Build image catalog
    print("\n2. Building image catalog from S3...")
    image_catalog = build_image_catalog(s3)
    print(f"   Found {len(image_catalog)} unique images")

    # Connect to database
    print("\n3. Connecting to database...")
    conn = psycopg2.connect(
        host=DB_HOST, database=DB_NAME,
        user=DB_USER, password=DB_PASSWORD, port=5432
    )
    cur = conn.cursor()

    # Get exercises with both paths
    print("\n4. Fetching exercises...")
    cur.execute("""
        SELECT id, exercise_name, image_s3_path, video_s3_path
        FROM exercise_library
        WHERE image_s3_path IS NOT NULL
          AND video_s3_path IS NOT NULL
    """)
    exercises = cur.fetchall()
    print(f"   Found {len(exercises)} exercises with both image and video")

    # Analyze each exercise
    print("\n5. Analyzing exercises for mismatches...")
    mismatches = []
    matches = []

    for exercise_id, exercise_name, image_path, video_path in exercises:
        result = detect_mismatch(exercise_name, image_path, video_path)
        result['exercise_id'] = str(exercise_id)
        result['exercise_name'] = exercise_name
        result['current_image_path'] = image_path
        result['current_video_path'] = video_path

        if result['is_mismatched']:
            # Find suggested fix
            best_match, confidence, match_type = find_best_image_match(
                exercise_name,
                result['video_basename'],
                image_catalog
            )
            result['suggested_fix'] = {
                'recommended_image_path': best_match,
                'match_confidence': confidence,
                'match_type': match_type
            }
            mismatches.append(result)
        else:
            matches.append(result)

    cur.close()
    conn.close()

    # Build report
    report = {
        'summary': {
            'total_exercises': len(exercises),
            'matched_count': len(matches),
            'mismatched_count': len(mismatches),
            'mismatch_percentage': round(len(mismatches) / len(exercises) * 100, 2) if exercises else 0,
            'run_timestamp': datetime.now().isoformat(),
        },
        'mismatches': sorted(mismatches, key=lambda x: x['confidence'], reverse=True),
        'high_confidence_fixes': [m for m in mismatches if m['confidence'] == 'high' and m['suggested_fix']['match_confidence'] >= 0.8],
    }

    # Print summary
    print("\n" + "=" * 60)
    print("AUDIT RESULTS")
    print("=" * 60)
    print(f"  Total exercises analyzed: {report['summary']['total_exercises']}")
    print(f"  Matched (OK): {report['summary']['matched_count']}")
    print(f"  Mismatched: {report['summary']['mismatched_count']} ({report['summary']['mismatch_percentage']}%)")
    print(f"  High-confidence auto-fixes: {len(report['high_confidence_fixes'])}")

    if mismatches:
        print("\nTop 10 mismatches:")
        for m in mismatches[:10]:
            print(f"\n  {m['exercise_name']}")
            print(f"    Image: {m['image_basename']}")
            print(f"    Video: {m['video_basename']}")
            print(f"    Reason: {m['reason']}")
            if m['suggested_fix']['recommended_image_path']:
                print(f"    Suggested: {extract_basename(m['suggested_fix']['recommended_image_path'])} (conf: {m['suggested_fix']['match_confidence']})")

    # Save reports if output directory specified
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

        # JSON report
        json_path = os.path.join(output_dir, 'audit_report.json')
        with open(json_path, 'w') as f:
            json.dump(report, f, indent=2)
        print(f"\n  JSON report saved: {json_path}")

        # CSV report
        csv_path = os.path.join(output_dir, 'audit_report.csv')
        with open(csv_path, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                'exercise_name', 'confidence', 'current_image', 'current_video',
                'image_video_similarity', 'reason', 'suggested_image', 'fix_confidence'
            ])
            for m in mismatches:
                writer.writerow([
                    m['exercise_name'],
                    m['confidence'],
                    m['image_basename'],
                    m['video_basename'],
                    m['image_video_similarity'],
                    m['reason'],
                    extract_basename(m['suggested_fix']['recommended_image_path']) if m['suggested_fix']['recommended_image_path'] else '',
                    m['suggested_fix']['match_confidence']
                ])
        print(f"  CSV report saved: {csv_path}")

    return report


def generate_migration_sql(report: dict, threshold: float = 0.9, output_path: str = None) -> str:
    """Generate SQL migration to fix mismatches"""
    fixes = [
        m for m in report['mismatches']
        if m['suggested_fix']['recommended_image_path']
        and m['suggested_fix']['match_confidence'] >= threshold
    ]

    if not fixes:
        print("No fixes meet the confidence threshold.")
        return ""

    sql_lines = [
        "-- Migration: fix_exercise_image_mismatches.sql",
        f"-- Generated: {datetime.now().isoformat()}",
        f"-- Purpose: Fix image/video mismatches identified by audit script",
        f"-- Total fixes: {len(fixes)} exercises (threshold: {threshold})",
        "",
        "BEGIN;",
        "",
        "-- Create backup table for rollback",
        "CREATE TABLE IF NOT EXISTS image_mismatch_backup (",
        "    id UUID PRIMARY KEY,",
        "    exercise_name TEXT,",
        "    old_image_s3_path TEXT,",
        "    new_image_s3_path TEXT,",
        "    applied_at TIMESTAMPTZ DEFAULT NOW()",
        ");",
        "",
    ]

    for i, fix in enumerate(fixes, 1):
        exercise_id = fix['exercise_id']
        exercise_name = fix['exercise_name'].replace("'", "''")
        old_path = fix['current_image_path'].replace("'", "''")
        new_path = fix['suggested_fix']['recommended_image_path'].replace("'", "''")
        confidence = fix['suggested_fix']['match_confidence']

        sql_lines.extend([
            f"-- Fix {i}: {fix['exercise_name']} (confidence: {confidence})",
            f"-- Old: {fix['image_basename']} -> New: {extract_basename(fix['suggested_fix']['recommended_image_path'])}",
            f"INSERT INTO image_mismatch_backup (id, exercise_name, old_image_s3_path, new_image_s3_path)",
            f"SELECT id, exercise_name, image_s3_path, '{new_path}'",
            f"FROM exercise_library",
            f"WHERE id = '{exercise_id}'",
            f"  AND image_s3_path = '{old_path}';",
            "",
            f"UPDATE exercise_library",
            f"SET image_s3_path = '{new_path}'",
            f"WHERE id = '{exercise_id}'",
            f"  AND image_s3_path = '{old_path}';",
            "",
        ])

    sql_lines.extend([
        "COMMIT;",
        "",
        f"-- Summary: Updated {len(fixes)} exercises",
    ])

    sql_content = '\n'.join(sql_lines)

    if output_path:
        with open(output_path, 'w') as f:
            f.write(sql_content)
        print(f"\nMigration SQL saved: {output_path}")

    return sql_content


def main():
    parser = argparse.ArgumentParser(description='Audit exercise image/video mismatches')
    parser.add_argument('--output', '-o', default='./audit_results',
                        help='Output directory for reports')
    parser.add_argument('--generate-sql', action='store_true',
                        help='Generate migration SQL file')
    parser.add_argument('--threshold', type=float, default=0.8,
                        help='Minimum confidence threshold for auto-fix (0.0-1.0)')
    parser.add_argument('--sql-output', default=None,
                        help='Output path for migration SQL (default: migrations/216_fix_exercise_image_mismatches.sql)')

    args = parser.parse_args()

    # Run audit
    report = run_audit(args.output)

    # Generate SQL if requested
    if args.generate_sql:
        sql_path = args.sql_output or os.path.join(
            os.path.dirname(__file__), '..', 'migrations',
            '216_fix_exercise_image_mismatches.sql'
        )
        generate_migration_sql(report, args.threshold, sql_path)


if __name__ == '__main__':
    main()
