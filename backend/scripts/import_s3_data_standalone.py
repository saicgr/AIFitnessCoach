"""
Standalone script to import S3 video paths and Excel exercise data into Supabase.
Uses direct SQLAlchemy connection to avoid Supabase client dependency conflicts.

Usage:
    python scripts/import_s3_data_standalone.py
"""
import asyncio
import boto3
import pandas as pd
from sqlalchemy import text, create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from io import BytesIO
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get database URL from env
DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable not set")

# S3 client
s3_client = boto3.client('s3', region_name='us-east-1')

BUCKET_NAME = 'ai-fitness-coach'
VIDEO_BASE_PREFIX = 'VERTICAL VIDEOS/'
EXCEL_KEY = '1500+ exercise data.xlsx'


async def create_video_paths_table(session):
    """Create table to store S3 video paths."""
    print("\n📊 Creating s3_video_paths table...")

    try:
        # Create table for video paths
        await session.execute(text("""
            CREATE TABLE IF NOT EXISTS s3_video_paths (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                relative_path TEXT NOT NULL UNIQUE,
                full_s3_key TEXT NOT NULL,
                folder_path TEXT,
                filename TEXT NOT NULL,
                file_extension TEXT,
                size_bytes BIGINT,
                size_mb NUMERIC(10,2),
                last_modified TIMESTAMPTZ,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        """))

        # Create indexes separately
        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_video_paths_folder ON s3_video_paths(folder_path)
        """))

        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_video_paths_filename ON s3_video_paths(filename)
        """))

        await session.commit()
        print("✅ Table created successfully")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating table: {e}")
        raise


async def import_video_paths(session):
    """Scan S3 and import all video paths to Supabase."""
    print("\n📹 Scanning S3 for videos...")

    # List all objects in S3
    paginator = s3_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=BUCKET_NAME, Prefix=VIDEO_BASE_PREFIX)

    videos = []
    for page in pages:
        if 'Contents' not in page:
            continue

        for obj in page['Contents']:
            key = obj['Key']

            # Only process video files
            if not key.lower().endswith(('.mp4', '.mov', '.avi', '.webm', '.mkv')):
                continue

            # Extract path components
            relative_path = key.replace(VIDEO_BASE_PREFIX, '', 1)
            filename = relative_path.split('/')[-1]
            file_extension = os.path.splitext(filename)[1]

            # Get folder path (everything except filename)
            path_parts = relative_path.split('/')[:-1]
            folder_path = '/'.join(path_parts) if path_parts else None

            videos.append({
                'relative_path': relative_path,
                'full_s3_key': key,
                'folder_path': folder_path,
                'filename': filename,
                'file_extension': file_extension,
                'size_bytes': obj['Size'],
                'size_mb': round(obj['Size'] / (1024 * 1024), 2),
                'last_modified': obj['LastModified']  # Keep as datetime object, not string
            })

    print(f"📊 Found {len(videos)} videos in S3")

    try:
        # Clear existing data
        await session.execute(text("DELETE FROM s3_video_paths"))

        # Insert videos in batches
        batch_size = 100
        for i in range(0, len(videos), batch_size):
            batch = videos[i:i + batch_size]

            for video in batch:
                await session.execute(text("""
                    INSERT INTO s3_video_paths
                    (relative_path, full_s3_key, folder_path, filename, file_extension,
                     size_bytes, size_mb, last_modified)
                    VALUES
                    (:relative_path, :full_s3_key, :folder_path, :filename, :file_extension,
                     :size_bytes, :size_mb, :last_modified)
                    ON CONFLICT (relative_path) DO UPDATE SET
                        full_s3_key = EXCLUDED.full_s3_key,
                        size_bytes = EXCLUDED.size_bytes,
                        size_mb = EXCLUDED.size_mb,
                        last_modified = EXCLUDED.last_modified
                """), video)

            print(f"✅ Imported {min(i + batch_size, len(videos))}/{len(videos)} videos")

        await session.commit()
        print(f"✅ Successfully imported {len(videos)} video paths")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error importing videos: {e}")
        raise


async def create_exercise_data_table(session):
    """Create table to store exercise data from Excel."""
    print("\n📊 Creating exercise_library table...")

    try:
        # Create table for exercise data
        await session.execute(text("""
            CREATE TABLE IF NOT EXISTS exercise_library (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                exercise_name TEXT,
                body_part TEXT,
                equipment TEXT,
                target_muscle TEXT,
                secondary_muscles TEXT[],
                instructions TEXT,
                difficulty_level TEXT,
                category TEXT,
                gif_url TEXT,
                video_s3_path TEXT,
                raw_data JSONB,
                created_at TIMESTAMPTZ DEFAULT NOW()
            )
        """))

        # Create indexes separately
        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_exercise_library_body_part ON exercise_library(body_part)
        """))

        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_exercise_library_equipment ON exercise_library(equipment)
        """))

        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_exercise_library_target ON exercise_library(target_muscle)
        """))

        await session.execute(text("""
            CREATE INDEX IF NOT EXISTS idx_exercise_library_name ON exercise_library(exercise_name)
        """))

        await session.commit()
        print("✅ Table created successfully")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating table: {e}")
        raise


async def import_excel_data(session):
    """Download Excel from S3 and import to Supabase."""
    print(f"\n📥 Downloading Excel file from S3: {EXCEL_KEY}")

    try:
        # Download Excel file from S3
        response = s3_client.get_object(Bucket=BUCKET_NAME, Key=EXCEL_KEY)
        excel_data = response['Body'].read()

        # Read Excel file
        df = pd.read_excel(BytesIO(excel_data))
        print(f"📊 Found {len(df)} exercises in Excel file")
        print(f"📋 Columns: {', '.join(df.columns.tolist())}")

        # Clean column names (lowercase, replace spaces with underscores)
        df.columns = [col.lower().replace(' ', '_').replace('-', '_').replace('(', '').replace(')', '') for col in df.columns]

        # Replace NaN with None for proper NULL handling
        df = df.where(pd.notnull(df), None)

        # Convert DataFrame to list of dicts
        exercises = df.to_dict('records')

        try:
            # Clear existing data
            await session.execute(text("DELETE FROM exercise_library"))

            # Insert exercises in batches
            batch_size = 100
            imported = 0

            for i in range(0, len(exercises), batch_size):
                batch = exercises[i:i + batch_size]

                for exercise in batch:
                    # Extract common fields (based on actual Excel columns: Categories, Exercise, Exercise Instructions (step by step), Exercise Tips, Primary Activating Muscles, Secondary Activating Muscles, Equipment)
                    exercise_name = exercise.get('exercise') or exercise.get('name') or exercise.get('exercise_name')
                    body_part = exercise.get('categories') or exercise.get('body_part') or exercise.get('bodypart')
                    equipment = exercise.get('equipment')
                    target_muscle = exercise.get('primary_activating_muscles') or exercise.get('target') or exercise.get('target_muscle')
                    instructions = exercise.get('exercise_instructions_step_by_step') or exercise.get('exercise_tips') or exercise.get('instructions')
                    gif_url = exercise.get('gif_url') or exercise.get('gifurl')

                    # Convert entire row to JSON
                    import json
                    raw_data = json.dumps(exercise, default=str)

                    await session.execute(text("""
                        INSERT INTO exercise_library
                        (exercise_name, body_part, equipment, target_muscle, instructions, gif_url, raw_data)
                        VALUES
                        (:exercise_name, :body_part, :equipment, :target_muscle, :instructions, :gif_url, CAST(:raw_data AS jsonb))
                    """), {
                        'exercise_name': exercise_name,
                        'body_part': body_part,
                        'equipment': equipment,
                        'target_muscle': target_muscle,
                        'instructions': instructions,
                        'gif_url': gif_url,
                        'raw_data': raw_data
                    })

                    imported += 1

                print(f"✅ Imported {min(i + batch_size, len(exercises))}/{len(exercises)} exercises")

            await session.commit()
            print(f"✅ Successfully imported {imported} exercises")

        except Exception as e:
            await session.rollback()
            print(f"❌ Error importing exercises: {e}")
            raise

    except Exception as e:
        print(f"❌ Error downloading Excel: {e}")
        raise


async def create_views(session):
    """Create useful views for querying the data."""
    print("\n📊 Creating database views...")

    try:
        # Drop all old views first
        await session.execute(text("DROP VIEW IF EXISTS vw_exercises_with_videos CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS vw_video_folder_stats CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS vw_exercises_by_body_part CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS vw_exercises_by_equipment CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS vw_exercise_detail CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS vw_exercise_muscle_details CASCADE"))
        await session.execute(text("DROP VIEW IF EXISTS exercise_detail_vw CASCADE"))

        # Single fully normalized view with separate primary and secondary muscle columns

        await session.execute(text("""
            CREATE VIEW exercise_detail_vw AS
            WITH parsed_primary AS (
                SELECT
                    id,
                    exercise_name,
                    -- Split by '), ' to preserve commas within parentheses
                    trim(unnest(regexp_split_to_array(raw_data->>'primary_activating_muscles', '\),\s*'))) AS muscle_string
                FROM exercise_library
                WHERE raw_data->>'primary_activating_muscles' IS NOT NULL
            ),
            extracted_primary AS (
                SELECT
                    id,
                    exercise_name,
                    trim(split_part(muscle_string, '(', 1)) AS muscle_group,
                    trim(both ')' from split_part(muscle_string, '(', 2)) AS muscle_details
                FROM parsed_primary
            ),
            primary_expanded AS (
                SELECT
                    id,
                    exercise_name,
                    muscle_group,
                    CASE
                        WHEN muscle_details = '' THEN NULL
                        ELSE muscle_details
                    END AS muscle_details
                FROM extracted_primary
                WHERE muscle_group != ''
            ),
            primary_normalized AS (
                SELECT
                    id,
                    exercise_name,
                    trim(both ')' from muscle_group) AS primary_muscle_group,
                    trim(both ')' from trim(detail)) AS primary_muscle_detail
                FROM primary_expanded
                CROSS JOIN LATERAL (
                    SELECT unnest(string_to_array(muscle_details, ',')) AS detail
                    WHERE muscle_details IS NOT NULL
                    UNION ALL
                    SELECT NULL AS detail
                    WHERE muscle_details IS NULL
                ) AS details
            ),
            parsed_secondary AS (
                SELECT
                    id,
                    exercise_name,
                    -- Split by '), ' to preserve commas within parentheses
                    trim(unnest(regexp_split_to_array(raw_data->>'secondary_activating_muscles', '\),\s*'))) AS muscle_string
                FROM exercise_library
                WHERE raw_data->>'secondary_activating_muscles' IS NOT NULL
            ),
            extracted_secondary AS (
                SELECT
                    id,
                    exercise_name,
                    trim(split_part(muscle_string, '(', 1)) AS muscle_group,
                    trim(both ')' from split_part(muscle_string, '(', 2)) AS muscle_details
                FROM parsed_secondary
            ),
            secondary_expanded AS (
                SELECT
                    id,
                    exercise_name,
                    muscle_group,
                    CASE
                        WHEN muscle_details = '' THEN NULL
                        ELSE muscle_details
                    END AS muscle_details
                FROM extracted_secondary
                WHERE muscle_group != ''
            ),
            secondary_normalized AS (
                SELECT
                    id,
                    exercise_name,
                    trim(both ')' from muscle_group) AS secondary_muscle_group,
                    trim(both ')' from trim(detail)) AS secondary_muscle_detail
                FROM secondary_expanded
                CROSS JOIN LATERAL (
                    SELECT unnest(string_to_array(muscle_details, ',')) AS detail
                    WHERE muscle_details IS NOT NULL
                    UNION ALL
                    SELECT NULL AS detail
                    WHERE muscle_details IS NULL
                ) AS details
            )
            SELECT
                e.id,
                e.exercise_name,
                -- Extract gender from name
                CASE
                    WHEN e.exercise_name LIKE '%\\_female' THEN 'F'
                    WHEN e.exercise_name LIKE '%\\_male' THEN 'M'
                    ELSE NULL
                END AS gender,
                -- Rename body_part to categories
                e.body_part AS categories,
                -- Body Region Classification
                CASE
                    WHEN e.body_part ILIKE ANY(ARRAY['%chest%', '%back%', '%shoulder%', '%arm%', '%bicep%', '%tricep%', '%forearm%', '%trap%'])
                        THEN 'Upper Body'
                    WHEN e.body_part ILIKE ANY(ARRAY['%abs%', '%oblique%', '%core%', '%lower back%'])
                        THEN 'Core'
                    WHEN e.body_part ILIKE ANY(ARRAY['%leg%', '%quad%', '%hamstring%', '%glute%', '%calve%', '%hip%', '%adductor%', '%abductor%'])
                        THEN 'Lower Body'
                    WHEN e.body_part ILIKE ANY(ARRAY['%cardio%', '%full body%'])
                        THEN 'Full Body'
                    ELSE 'Other'
                END AS body_region,
                e.equipment,
                -- Equipment Needed (as TEXT array)
                CASE
                    WHEN e.exercise_name ILIKE '%dumbbell%' THEN ARRAY['Dumbbells']
                    WHEN e.exercise_name ILIKE '%barbell%' THEN ARRAY['Barbells']
                    WHEN e.exercise_name ILIKE '%cable%' THEN ARRAY['Cable Machine']
                    WHEN e.exercise_name ILIKE '%machine%' THEN ARRAY['Machine']
                    WHEN e.exercise_name ILIKE '%kettlebell%' THEN ARRAY['Kettlebells']
                    WHEN e.exercise_name ILIKE '%resistance band%' THEN ARRAY['Resistance Bands']
                    WHEN e.exercise_name ILIKE '%trx%' THEN ARRAY['TRX']
                    WHEN e.exercise_name ILIKE '%medicine ball%' THEN ARRAY['Medicine Ball']
                    WHEN e.exercise_name ILIKE '%pull%up%' OR e.exercise_name ILIKE '%chin%up%' THEN ARRAY['Pull-up Bar']
                    WHEN e.exercise_name ILIKE '%bench%' THEN ARRAY['Bench']
                    WHEN e.equipment ILIKE '%bodyweight%' OR e.equipment IS NULL THEN ARRAY['Bodyweight']
                    ELSE ARRAY['Other']
                END AS equipment_needed,
                e.instructions AS exercise_instructions,
                -- Extract exercise tips from raw_data
                e.raw_data->>'exercise_tips' AS exercise_tips,
                e.difficulty_level,
                e.gif_url,
                e.video_s3_path,
                e.created_at,
                -- Default training parameters
                CASE
                    -- Strength exercises: 3-5 sets
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%barbell%', '%squat%', '%deadlift%', '%bench press%', '%overhead press%'])
                        THEN 4
                    -- Isolation exercises: 3 sets
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%curl%', '%extension%', '%raise%', '%fly%'])
                        THEN 3
                    -- Cardio/endurance: 1 set
                    WHEN e.body_part ILIKE '%cardio%'
                        THEN 1
                    -- Default: 3 sets
                    ELSE 3
                END AS default_sets,
                CASE
                    -- Heavy compound lifts: 5-8 reps
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%squat%', '%deadlift%', '%bench press%', '%overhead press%'])
                        THEN '5-8'
                    -- Hypertrophy: 8-12 reps
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%dumbbell%', '%cable%', '%machine%'])
                        THEN '8-12'
                    -- Isolation/accessories: 10-15 reps
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%curl%', '%extension%', '%raise%', '%fly%'])
                        THEN '10-15'
                    -- Bodyweight: 12-20 reps or to failure
                    WHEN e.equipment ILIKE '%bodyweight%'
                        THEN '12-20'
                    -- Cardio: time-based
                    WHEN e.body_part ILIKE '%cardio%'
                        THEN 'N/A'
                    -- Default: 8-12 reps
                    ELSE '8-12'
                END AS default_reps,
                CASE
                    -- Heavy compound lifts: 3-5 min rest
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%squat%', '%deadlift%', '%bench press%', '%overhead press%'])
                        THEN 180
                    -- Moderate compound: 90-120 sec
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%barbell%', '%row%', '%pull%up%'])
                        THEN 90
                    -- Isolation: 60 sec
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%curl%', '%extension%', '%raise%', '%fly%'])
                        THEN 60
                    -- Cardio: minimal rest
                    WHEN e.body_part ILIKE '%cardio%'
                        THEN 30
                    -- Default: 90 sec
                    ELSE 90
                END AS default_rest_seconds,
                CASE
                    -- Plank variations: 30-60 sec
                    WHEN e.exercise_name ILIKE '%plank%'
                        THEN '30-60 seconds'
                    -- Cardio exercises: 20-30 min
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%run%', '%jog%', '%bike%', '%row%', '%swim%'])
                        THEN '20-30 minutes'
                    -- Stretching: 30 sec per side
                    WHEN e.body_part ILIKE ANY(ARRAY['%stretch%', '%flexibility%'])
                        THEN '30 seconds per side'
                    -- Wall sits, holds: 45-90 sec
                    WHEN e.exercise_name ILIKE ANY(ARRAY['%wall sit%', '%hold%'])
                        THEN '45-90 seconds'
                    -- Default: N/A for rep-based
                    ELSE NULL
                END AS default_duration_target,
                -- World records (sample data - will need comprehensive database)
                CASE
                    WHEN e.exercise_name ILIKE '%barbell squat%' THEN '575 kg'
                    WHEN e.exercise_name ILIKE '%deadlift%' THEN '501 kg'
                    WHEN e.exercise_name ILIKE '%bench press%' THEN '350 kg'
                    WHEN e.exercise_name ILIKE '%overhead press%' THEN '228 kg'
                    ELSE NULL
                END AS world_record_weight,
                CASE
                    WHEN e.exercise_name ILIKE '%plank%' THEN '9 hours 30 min 1 sec'
                    WHEN e.exercise_name ILIKE '%100m%' OR e.exercise_name ILIKE '%sprint%' THEN '9.58 seconds'
                    WHEN e.exercise_name ILIKE '%marathon%' THEN '2:01:09'
                    WHEN e.exercise_name ILIKE '%pull%up%' AND e.exercise_name ILIKE '%24%hour%' THEN '8008 reps'
                    ELSE NULL
                END AS world_record_time,
                CASE
                    WHEN e.exercise_name ILIKE '%barbell squat%' THEN 37
                    WHEN e.exercise_name ILIKE '%deadlift%' THEN 28
                    WHEN e.exercise_name ILIKE '%bench press%' THEN 35
                    WHEN e.exercise_name ILIKE '%100m%' OR e.exercise_name ILIKE '%sprint%' THEN 23
                    WHEN e.exercise_name ILIKE '%plank%' THEN 62
                    ELSE NULL
                END AS world_record_age,
                -- Primary muscle data
                p.primary_muscle_group,
                p.primary_muscle_detail,
                -- Secondary muscle data
                s.secondary_muscle_group,
                s.secondary_muscle_detail
            FROM exercise_library e
            LEFT JOIN primary_normalized p ON e.id = p.id
            LEFT JOIN secondary_normalized s ON e.id = s.id;
        """))

        await session.commit()
        print("✅ Created 1 database view:")
        print("   - exercise_detail_vw (fully normalized with body_region, equipment_needed, training defaults, world records, muscle breakdown)")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating views: {e}")
        raise


async def main():
    """Main import process."""
    print("=" * 60)
    print("🚀 S3 Data Import to Supabase")
    print("=" * 60)

    # Create async engine
    engine = create_async_engine(DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    try:
        async with async_session() as session:
            # Step 1: Create tables
            await create_video_paths_table(session)
            await create_exercise_data_table(session)

            # Step 2: Import S3 video paths
            await import_video_paths(session)

            # Step 3: Import Excel data
            await import_excel_data(session)

            # Step 4: Create views
            await create_views(session)

            print("\n" + "=" * 60)
            print("✅ Import completed successfully!")
            print("=" * 60)
            print("\n📊 Summary:")

            # Get counts
            video_count_result = await session.execute(text("SELECT COUNT(*) FROM s3_video_paths"))
            exercise_count_result = await session.execute(text("SELECT COUNT(*) FROM exercise_library"))

            video_total = video_count_result.fetchone()[0]
            exercise_total = exercise_count_result.fetchone()[0]

            print(f"   - Videos imported: {video_total}")
            print(f"   - Exercises imported: {exercise_total}")

            print("\n🔍 Query examples:")
            print("   SELECT * FROM vw_exercises_with_videos WHERE body_part = 'chest';")
            print("   SELECT * FROM vw_video_folder_stats;")
            print("   SELECT * FROM vw_exercises_by_body_part;")

    except Exception as e:
        print(f"\n❌ Import failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

    finally:
        await engine.dispose()

    return 0


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    exit(exit_code)
