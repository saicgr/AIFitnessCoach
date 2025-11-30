# S3 Data Import Scripts

## 🚀 Quick Start

**New to this?** Start here: [QUICKSTART.md](QUICKSTART.md) (2-minute setup)

**Need AWS credentials?** Run the interactive setup:
```bash
cd backend/scripts
./setup_aws.sh
```

**Detailed guide:** [AWS_SETUP_GUIDE.md](AWS_SETUP_GUIDE.md)

---

## Overview

This directory contains scripts to import data from S3 into Supabase.

## import_s3_data.py

Imports all S3 video paths and the Excel exercise database into Supabase.

### What it does

1. **Creates Tables**:
   - `s3_video_paths` - All video paths from S3
   - `exercise_library` - Exercise data from Excel file

2. **Imports Data**:
   - Scans `s3://ai-fitness-coach/VERTICAL VIDEOS/` for all videos
   - Downloads and parses `s3://ai-fitness-coach/1500+ exercise data.xlsx`
   - Imports everything to Supabase

3. **Creates Views**:
   - `vw_exercises_with_videos` - Exercises matched with videos
   - `vw_video_folder_stats` - Video statistics by folder
   - `vw_exercises_by_body_part` - Exercise counts by body part
   - `vw_exercises_by_equipment` - Exercise counts by equipment

### Usage

```bash
# Install dependencies first
cd backend
pip install pandas openpyxl boto3

# Run the import script
python scripts/import_s3_data.py
```

### Expected Output

```
============================================================
🚀 S3 Data Import to Supabase
============================================================

📊 Creating s3_video_paths table...
✅ Table created successfully

📊 Creating exercise_library table...
✅ Table created successfully

📹 Scanning S3 for videos...
📊 Found 2000 videos in S3
✅ Imported 2000 video paths

📥 Downloading Excel file from S3: 1500+ exercise data.xlsx
📊 Found 1500 exercises in Excel file
📋 Columns: name, body_part, equipment, target, instructions, ...
✅ Imported 1500 exercises

📊 Creating database views...
✅ Created 4 database views

============================================================
✅ Import completed successfully!
============================================================

📊 Summary:
   - Videos imported: 2000
   - Exercises imported: 1500
```

### Database Schema

#### s3_video_paths
```sql
CREATE TABLE s3_video_paths (
    id UUID PRIMARY KEY,
    relative_path TEXT UNIQUE,      -- "Upper Body/Chest/bench_press.mp4"
    full_s3_key TEXT,                -- "VERTICAL VIDEOS/Upper Body/Chest/bench_press.mp4"
    folder_path TEXT,                -- "Upper Body/Chest"
    filename TEXT,                   -- "bench_press.mp4"
    file_extension TEXT,             -- ".mp4"
    size_bytes BIGINT,
    size_mb NUMERIC(10,2),
    last_modified TIMESTAMPTZ,
    created_at TIMESTAMPTZ
);
```

#### exercise_library
```sql
CREATE TABLE exercise_library (
    id UUID PRIMARY KEY,
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
    raw_data JSONB,                  -- Full Excel row as JSON
    created_at TIMESTAMPTZ
);
```

### Query Examples

#### Get all chest exercises with videos
```sql
SELECT
    exercise_name,
    body_part,
    equipment,
    video_path,
    video_s3_key
FROM vw_exercises_with_videos
WHERE body_part = 'chest'
ORDER BY exercise_name;
```

#### Video statistics by folder
```sql
SELECT * FROM vw_video_folder_stats
ORDER BY video_count DESC;
```

#### Exercises grouped by equipment
```sql
SELECT * FROM vw_exercises_by_equipment
WHERE equipment = 'barbell';
```

#### Find exercises with matching videos
```sql
SELECT
    e.exercise_name,
    e.body_part,
    v.relative_path,
    v.size_mb
FROM exercise_library e
INNER JOIN s3_video_paths v
    ON LOWER(v.filename) LIKE '%' || LOWER(REPLACE(e.exercise_name, ' ', '')) || '%'
WHERE e.body_part = 'legs'
LIMIT 10;
```

### Troubleshooting

**Issue**: Script fails with AWS credentials error
**Solution**: Configure AWS CLI with `aws configure`

**Issue**: Excel file not found
**Solution**: Verify file exists at `s3://ai-fitness-coach/1500+ exercise data.xlsx`

**Issue**: Database connection error
**Solution**: Check `.env` has correct `DATABASE_URL` for Supabase

### Re-running

The script is **idempotent** - you can run it multiple times safely. It will:
- Clear existing data before importing
- Use `ON CONFLICT` to update existing records

### Next Steps

After importing, you can:
1. Query the data via Supabase dashboard
2. Use the views in your FastAPI endpoints
3. Build recommendation algorithms based on exercise data
4. Match exercises to videos programmatically
