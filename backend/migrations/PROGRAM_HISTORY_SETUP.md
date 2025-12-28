# Program History Feature Setup

## Step 1: Create Database Table

Run this SQL in your Supabase SQL Editor:

```sql
-- Paste the contents of create_program_history_table.sql here
```

Or connect via psql and run:
```bash
psql $DATABASE_URL < backend/migrations/create_program_history_table.sql
```

## Step 2: Verify Table Creation

```sql
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'program_history'
ORDER BY ordinal_position;
```

## Step 3: Test Basic Operations

```sql
-- Insert a test program snapshot
INSERT INTO program_history (user_id, preferences, equipment, program_name, is_current)
VALUES (
    'your-test-user-id',
    '{"intensity_preference": "medium", "workout_duration": 45, "selected_days": [0,2,4]}'::jsonb,
    ARRAY['Dumbbells'],
    'Test Program',
    true
);

-- Query program history
SELECT * FROM program_history WHERE user_id = 'your-test-user-id' ORDER BY created_at DESC;
```

## What This Table Stores

- **User's workout program configurations** as snapshots
- **Preferences**: difficulty, duration, selected days, workout type
- **Equipment and injuries**: arrays of equipment/injury names
- **Metadata**: program name, description, when it was created/applied
- **Analytics**: total workouts completed, last workout date

## Features Enabled

1. **View Program History**: See all past workout program configurations
2. **Restore Previous Program**: One-click restore to a previous setup
3. **Compare Programs**: See what changed between programs
4. **Track Program Success**: See how many workouts completed with each program
