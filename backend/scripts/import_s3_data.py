"""
Script to import S3 video paths and Excel exercise data into Supabase.

Usage:
    python scripts/import_s3_data.py
"""
import asyncio
import boto3
import pandas as pd
from sqlalchemy import text
from io import BytesIO
import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase
from core.config import get_settings

settings = get_settings()

# S3 client
s3_client = boto3.client('s3', region_name='us-east-1')

BUCKET_NAME = 'ai-fitness-coach'
VIDEO_BASE_PREFIX = 'VERTICAL VIDEOS/'
EXCEL_KEY = '1500+ exercise data.xlsx'


async def create_video_paths_table():
    """Create table to store S3 video paths."""
    print("\n📊 Creating s3_video_paths table...")

    supabase_manager = get_supabase()
    session = supabase_manager.get_session()

    try:
        # Create table for video paths
        await session.execute(text("""
            CREATE TABLE IF NOT EXISTS s3_video_paths (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                relative_path TEXT NOT NULL UNIQUE,  -- Path without "VERTICAL VIDEOS/"
                full_s3_key TEXT NOT NULL,           -- Full S3 key
                folder_path TEXT,                     -- Parent folder (e.g., "Upper Body/Chest")
                filename TEXT NOT NULL,               -- Just the filename
                file_extension TEXT,                  -- .mp4, .mov, etc.
                size_bytes BIGINT,
                size_mb NUMERIC(10,2),
                last_modified TIMESTAMPTZ,
                created_at TIMESTAMPTZ DEFAULT NOW()
            );

            -- Create index for faster searches
            CREATE INDEX IF NOT EXISTS idx_video_paths_folder ON s3_video_paths(folder_path);
            CREATE INDEX IF NOT EXISTS idx_video_paths_filename ON s3_video_paths(filename);
        """))

        await session.commit()
        print("✅ Table created successfully")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating table: {e}")
        raise
    finally:
        await session.close()


async def import_video_paths():
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
                'last_modified': obj['LastModified'].isoformat()
            })

    print(f"📊 Found {len(videos)} videos in S3")

    # Insert into Supabase
    supabase_manager = get_supabase()
    session = supabase_manager.get_session()

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
    finally:
        await session.close()


async def create_exercise_data_table():
    """Create table to store exercise data from Excel."""
    print("\n📊 Creating exercise_library table...")

    supabase_manager = get_supabase()
    session = supabase_manager.get_session()

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
                video_s3_path TEXT,  -- Link to s3_video_paths
                raw_data JSONB,      -- Store entire row as JSON
                created_at TIMESTAMPTZ DEFAULT NOW()
            );

            -- Indexes for common queries
            CREATE INDEX IF NOT EXISTS idx_exercise_library_body_part ON exercise_library(body_part);
            CREATE INDEX IF NOT EXISTS idx_exercise_library_equipment ON exercise_library(equipment);
            CREATE INDEX IF NOT EXISTS idx_exercise_library_target ON exercise_library(target_muscle);
            CREATE INDEX IF NOT EXISTS idx_exercise_library_name ON exercise_library(exercise_name);
        """))

        await session.commit()
        print("✅ Table created successfully")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating table: {e}")
        raise
    finally:
        await session.close()


async def import_excel_data():
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
        df.columns = [col.lower().replace(' ', '_').replace('-', '_') for col in df.columns]

        # Convert DataFrame to list of dicts
        exercises = df.to_dict('records')

        # Import to Supabase
        supabase_manager = get_supabase()
        session = supabase_manager.get_session()

        try:
            # Clear existing data
            await session.execute(text("DELETE FROM exercise_library"))

            # Insert exercises in batches
            batch_size = 100
            imported = 0

            for i in range(0, len(exercises), batch_size):
                batch = exercises[i:i + batch_size]

                for exercise in batch:
                    # Extract common fields (adjust based on actual Excel columns)
                    exercise_name = exercise.get('name') or exercise.get('exercise_name') or exercise.get('title')
                    body_part = exercise.get('body_part') or exercise.get('bodypart')
                    equipment = exercise.get('equipment')
                    target_muscle = exercise.get('target') or exercise.get('target_muscle')
                    instructions = exercise.get('instructions') or exercise.get('description')
                    gif_url = exercise.get('gif_url') or exercise.get('gifurl')

                    # Convert entire row to JSON
                    import json
                    raw_data = json.dumps(exercise, default=str)

                    await session.execute(text("""
                        INSERT INTO exercise_library
                        (exercise_name, body_part, equipment, target_muscle, instructions, gif_url, raw_data)
                        VALUES
                        (:exercise_name, :body_part, :equipment, :target_muscle, :instructions, :gif_url, :raw_data::jsonb)
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
        finally:
            await session.close()

    except Exception as e:
        print(f"❌ Error downloading Excel: {e}")
        raise


async def create_views():
    """Create useful views for querying the data."""
    print("\n📊 Creating database views...")

    supabase_manager = get_supabase()
    session = supabase_manager.get_session()

    try:
        # View 1: Exercise library with matched videos
        await session.execute(text("""
            CREATE OR REPLACE VIEW vw_exercises_with_videos AS
            SELECT
                e.id,
                e.exercise_name,
                e.body_part,
                e.equipment,
                e.target_muscle,
                e.instructions,
                e.gif_url,
                v.relative_path as video_path,
                v.full_s3_key as video_s3_key,
                v.folder_path as video_folder,
                v.size_mb as video_size_mb
            FROM exercise_library e
            LEFT JOIN s3_video_paths v
                ON LOWER(v.filename) LIKE '%' || LOWER(REPLACE(e.exercise_name, ' ', '%')) || '%'
            ORDER BY e.exercise_name;
        """))

        # View 2: Video folder statistics
        await session.execute(text("""
            CREATE OR REPLACE VIEW vw_video_folder_stats AS
            SELECT
                folder_path,
                COUNT(*) as video_count,
                SUM(size_mb) as total_size_mb,
                AVG(size_mb) as avg_size_mb,
                MIN(size_mb) as min_size_mb,
                MAX(size_mb) as max_size_mb
            FROM s3_video_paths
            WHERE folder_path IS NOT NULL
            GROUP BY folder_path
            ORDER BY video_count DESC;
        """))

        # View 3: Exercises by body part
        await session.execute(text("""
            CREATE OR REPLACE VIEW vw_exercises_by_body_part AS
            SELECT
                body_part,
                COUNT(*) as exercise_count,
                COUNT(DISTINCT equipment) as equipment_types,
                COUNT(DISTINCT target_muscle) as target_muscles
            FROM exercise_library
            WHERE body_part IS NOT NULL
            GROUP BY body_part
            ORDER BY exercise_count DESC;
        """))

        # View 4: Exercises by equipment
        await session.execute(text("""
            CREATE OR REPLACE VIEW vw_exercises_by_equipment AS
            SELECT
                equipment,
                COUNT(*) as exercise_count,
                COUNT(DISTINCT body_part) as body_parts_targeted
            FROM exercise_library
            WHERE equipment IS NOT NULL
            GROUP BY equipment
            ORDER BY exercise_count DESC;
        """))

        await session.commit()
        print("✅ Created 4 database views:")
        print("   - vw_exercises_with_videos (exercises matched with S3 videos)")
        print("   - vw_video_folder_stats (folder statistics)")
        print("   - vw_exercises_by_body_part (exercises grouped by body part)")
        print("   - vw_exercises_by_equipment (exercises grouped by equipment)")

    except Exception as e:
        await session.rollback()
        print(f"❌ Error creating views: {e}")
        raise
    finally:
        await session.close()


async def main():
    """Main import process."""
    print("=" * 60)
    print("🚀 S3 Data Import to Supabase")
    print("=" * 60)

    try:
        # Step 1: Create tables
        await create_video_paths_table()
        await create_exercise_data_table()

        # Step 2: Import S3 video paths
        await import_video_paths()

        # Step 3: Import Excel data
        await import_excel_data()

        # Step 4: Create views
        await create_views()

        print("\n" + "=" * 60)
        print("✅ Import completed successfully!")
        print("=" * 60)
        print("\n📊 Summary:")

        # Get counts
        supabase_manager = get_supabase()
        session = supabase_manager.get_session()

        try:
            video_count = await session.execute(text("SELECT COUNT(*) FROM s3_video_paths"))
            exercise_count = await session.execute(text("SELECT COUNT(*) FROM exercise_library"))

            video_total = (await video_count.fetchone())[0]
            exercise_total = (await exercise_count.fetchone())[0]

            print(f"   - Videos imported: {video_total}")
            print(f"   - Exercises imported: {exercise_total}")

        finally:
            await session.close()

        print("\n🔍 Query examples:")
        print("   SELECT * FROM vw_exercises_with_videos WHERE body_part = 'chest';")
        print("   SELECT * FROM vw_video_folder_stats;")
        print("   SELECT * FROM vw_exercises_by_body_part;")

    except Exception as e:
        print(f"\n❌ Import failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
