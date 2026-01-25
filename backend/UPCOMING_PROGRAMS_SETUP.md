# Upcoming Programs Setup

**Status:** ✅ Complete
**Date:** 2026-01-23

## What Was Done

All 965 program variants have been marked as `status = 'upcoming'` in the database.

### Database Changes

1. **Added `status` column to `program_variants` table**
   - Type: TEXT
   - Default: 'upcoming'
   - Values: 'upcoming', 'active', 'archived'

2. **Created `app_programs` view** - App-ready view with all program metadata
   - Includes program status
   - Includes media coverage percentage
   - Includes week completion status
   - Includes sub_program_name

## Current Status

| Status | Variant Count |
|--------|---------------|
| upcoming | 965 |
| active | 0 |
| archived | 0 |

## Using in Flutter App

### 1. Query for Programs List

```sql
-- Get all programs for display in app
SELECT
    variant_id,
    sub_program_name,
    program_name,
    priority,
    duration_weeks,
    sessions_per_week,
    status,
    week_status,
    weeks_ingested,
    total_exercises,
    exercises_with_media,
    media_coverage_pct
FROM app_programs
WHERE status = 'upcoming'
ORDER BY priority, program_name;
```

### 2. Display in App UI

Show programs with "Upcoming" or "Coming Soon" badge:

```dart
// Example Flutter widget
Container(
  decoration: BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(8),
  ),
  child: ListTile(
    title: Text(program.programName),
    subtitle: Text('${program.durationWeeks} weeks, ${program.sessionsPerWeek}x/week'),
    trailing: Chip(
      label: Text('UPCOMING'),
      backgroundColor: Colors.orange.shade100,
    ),
  ),
)
```

### 3. Make Programs Active (When Ready)

When you want to make specific programs available:

```sql
-- Mark specific variants as active
UPDATE program_variants
SET status = 'active'
WHERE id IN (
    -- The 14 variants with 100% media coverage
    SELECT variant_id
    FROM app_programs
    WHERE media_coverage_pct = 100.0
);
```

Or mark individual programs:

```sql
-- Make Leg Development 8w_4d active
UPDATE program_variants
SET status = 'active'
WHERE id = '7c02057b-4a21-4254-9dac-0e5fe5dbb056';
```

## App Programs View Schema

| Column | Type | Description |
|--------|------|-------------|
| `variant_id` | UUID | Unique program variant ID |
| `base_program_id` | UUID | Base program reference |
| `sub_program_name` | TEXT | Format: `Program_Name_12w_5d` |
| `program_name` | TEXT | Human-readable name |
| `priority` | TEXT | High, Med, Low |
| `duration_weeks` | INT | Total weeks |
| `sessions_per_week` | INT | Days per week |
| `status` | TEXT | upcoming, active, archived |
| `weeks_ingested` | INT | Weeks loaded in DB |
| `week_status` | TEXT | complete, partial, empty |
| `total_exercises` | INT | Total exercises in program |
| `exercises_with_media` | INT | Exercises with video+image |
| `media_coverage_pct` | NUMERIC | % exercises with media |

## Program Status Workflow

```
┌─────────────┐
│  upcoming   │ ← All programs start here
└──────┬──────┘
       │
       │ (When media coverage is good + ready to launch)
       ↓
┌─────────────┐
│   active    │ ← Available in app
└──────┬──────┘
       │
       │ (When program is outdated/replaced)
       ↓
┌─────────────┐
│  archived   │ ← Hidden from app
└─────────────┘
```

## Filters for Different Views

### Show only upcoming programs
```sql
SELECT * FROM app_programs WHERE status = 'upcoming';
```

### Show only active programs (when you start activating them)
```sql
SELECT * FROM app_programs WHERE status = 'active';
```

### Show programs ready to activate (100% media coverage)
```sql
SELECT * FROM app_programs
WHERE status = 'upcoming'
  AND media_coverage_pct = 100.0
  AND week_status = 'complete';
```

### Show programs by priority (for admin dashboard)
```sql
SELECT
    priority,
    status,
    COUNT(*) as count,
    ROUND(AVG(media_coverage_pct), 1) as avg_coverage
FROM app_programs
GROUP BY priority, status
ORDER BY priority, status;
```

## Current "Ready to Activate" Programs (14 variants)

These have 100% media coverage and can be set to `active` whenever you want:

1. Leg_Development_8w_4d (Med)
2. Leg_Development_4w_4d (Med)
3. Leg_Development_4w_3d (Med)
4. 5/3/1_Progression_4w_4d (Med)
5. Deadlift_Specialization_4w_4d (Med)
6. Squat_Specialization_4w_3d (Low)
7. 20-Minute_Total_Body_2w_4d (Low)
8. 20-Minute_Total_Body_2w_5d (Low)
9. 15-Minute_Strength_2w_4d (High)
10. PMS_Relief_Movement_1w_4d (Low)
11-14. (4 more variants)

## Recommended App UI Strategy

### Option A: Show Everything as "Upcoming"
```
┌─────────────────────────────────┐
│ Programs (184)                  │
├─────────────────────────────────┤
│ 🔶 High Priority Weight Loss    │
│    UPCOMING - 8 weeks, 5x/week  │
├─────────────────────────────────┤
│ 🔶 Beginner Full Body           │
│    UPCOMING - 12 weeks, 4x/week │
└─────────────────────────────────┘
```

### Option B: Show Active + Upcoming Sections
```
┌─────────────────────────────────┐
│ Available Now (14)              │
├─────────────────────────────────┤
│ ✅ Leg Development              │
│    8 weeks, 4x/week             │
├─────────────────────────────────┤
│ Coming Soon (951)               │
├─────────────────────────────────┤
│ 🔶 Weight Loss Program          │
│    UPCOMING - 8 weeks, 5x/week  │
└─────────────────────────────────┘
```

### Option C: Just Show Upcoming (Hide Count)
```
┌─────────────────────────────────┐
│ Programs                        │
├─────────────────────────────────┤
│ 🔶 High Priority Weight Loss    │
│    Coming Soon                  │
├─────────────────────────────────┤
│ 🔶 Beginner Full Body           │
│    Coming Soon                  │
└─────────────────────────────────┘
```

## Admin Dashboard Query

To track progress toward activating programs:

```sql
SELECT
    priority,
    COUNT(*) as total_variants,
    COUNT(CASE WHEN media_coverage_pct = 100 THEN 1 END) as ready_to_activate,
    COUNT(CASE WHEN media_coverage_pct >= 90 THEN 1 END) as nearly_ready,
    ROUND(AVG(media_coverage_pct), 1) as avg_coverage
FROM app_programs
WHERE status = 'upcoming'
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'High' THEN 1
        WHEN 'Med' THEN 2
        WHEN 'Low' THEN 3
    END;
```

## Next Steps

1. **In Flutter App:**
   - Query `app_programs` view
   - Filter by `status = 'upcoming'`
   - Display with "Coming Soon" badge
   - Optionally show media_coverage_pct in admin view

2. **When Ready to Launch Programs:**
   - Update specific variants to `status = 'active'`
   - App will automatically show them as available

3. **To Track Progress:**
   - Use `media_coverage_pct` column to see completion
   - Focus on getting High priority programs to 100% first

## Files Created

- `/backend/scripts/mark_programs_upcoming.py` - Script to mark programs
- `/backend/UPCOMING_PROGRAMS_SETUP.md` - This file
- Database: `program_variants.status` column added
- Database: `app_programs` view created
