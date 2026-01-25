# Program Media Coverage Summary

**Generated:** 2026-01-23
**Database View:** `program_exercises_with_media`

## Overview

The `program_exercises_with_media` view is a consolidated view that combines:
- All program exercises from `program_exercises_flat`
- Week completion status (complete, partial, empty)
- Sub-program names (format: `Program_Name_12w_5d`)
- Canonical exercise names and media paths (video_s3_path, image_s3_path)
- Media status for each exercise

## Key Columns

| Column | Description |
|--------|-------------|
| `sub_program_name` | Unique identifier: `{Program}_{weeks}w_{days}d` |
| `duration_weeks` | Total weeks in program |
| `weeks_ingested` | Weeks actually loaded in database |
| `week_status` | `complete`, `partial`, or `empty` |
| `status_icon` | ✅ complete, ⚠️ partial, ❌ empty |
| `canonical_name` | Standardized exercise name |
| `video_s3_path` | S3 path to exercise video |
| `image_s3_path` | S3 path to exercise image |
| `media_status` | `complete`, `missing_media`, `no_alias`, etc. |

## Week Completion Status

| Priority | Total Variants | Complete | Partial |
|----------|----------------|----------|---------|
| High     | 280            | 277      | 3       |
| Med      | 473            | 462      | 11      |
| Low      | 176            | 164      | 12      |
| **TOTAL** | **929**       | **903**  | **26**  |

**✅ 97.2% of variants have all weeks loaded**

## Media Coverage Statistics

### By Variant (Sub-Program Level)

| Priority | Total Variants | 100% Coverage | % |
|----------|----------------|---------------|---|
| High     | 280            | 1             | 0.4% |
| Med      | 473            | 10            | 2.1% |
| Low      | 176            | 3             | 1.7% |
| **TOTAL** | **929**       | **14**        | **1.5%** |

### By Program Name (At Least One Variant Complete)

| Priority | Total Programs | ≥1 Variant 100% | % |
|----------|----------------|-----------------|---|
| High     | 54             | 1               | 1.9% |
| Med      | 92             | 5               | 5.4% |
| Low      | 38             | 3               | 7.9% |
| **TOTAL** | **184**       | **9**           | **4.9%** |

### By Program Name (ALL Variants Complete)

| Priority | Total Programs | All Variants 100% | % |
|----------|----------------|-------------------|---|
| High     | 54             | 0                 | 0.0% |
| Med      | 92             | 0                 | 0.0% |
| Low      | 38             | 0                 | 0.0% |
| **TOTAL** | **184**       | **0**             | **0.0%** |

## Programs with 100% Media Coverage (14 variants)

1. **Leg Development** (8w_4d) - 244 exercises - Med priority
2. **Leg Development** (4w_4d) - 120 exercises - Med priority
3. **5/3/1 Progression** (4w_4d) - 120 exercises - Med priority
4. **Deadlift Specialization** (4w_4d) - 99 exercises - Med priority
5. **Leg Development** (4w_3d) - 81 exercises - Med priority
6. **Squat Specialization** (4w_3d) - 81 exercises - Low priority
7. **20-Minute Total Body** (2w_4d) - 48 exercises - Low priority
8. **20-Minute Total Body** (2w_5d) - 45 exercises - Low priority
9. **15-Minute Strength** (2w_4d) - 30 exercises - High priority
10. **PMS Relief Movement** (1w_4d) - 29 exercises - Low priority
11-14. (Additional 4 variants)

## Example: "Leg Development" Program

| Variant ID | Sub-Program | Priority | Exercises | With Both | Coverage % |
|------------|-------------|----------|-----------|-----------|------------|
| 7c02057b-4a21-4254-9dac-0e5fe5dbb056 | Leg_Development_8w_4d | Med | 244 | 244 | 100.00% ✅ |
| d31ad861-c0ab-4ce9-8f67-06e3d7e6eeef | Leg_Development_4w_4d | Med | 120 | 120 | 100.00% ✅ |
| ca635636-f21f-4b57-9ee1-072ffb196ef4 | Leg_Development_4w_3d | Med | 81 | 81 | 100.00% ✅ |
| c825ad30-8d65-4973-9ff5-9dd9ba726ffd | Leg_Development_8w_3d | Med | 187 | 183 | 97.86% ⚠️ |

**Result:** 3 out of 4 "Leg Development" variants are shippable.

## Usage Examples

### Check if a specific sub-program is shippable

```sql
SELECT
    sub_program_name,
    week_status,
    COUNT(*) as total_exercises,
    COUNT(CASE WHEN video_s3_path IS NOT NULL AND image_s3_path IS NOT NULL THEN 1 END) as with_both,
    ROUND(100.0 * COUNT(CASE WHEN video_s3_path IS NOT NULL AND image_s3_path IS NOT NULL THEN 1 END) / COUNT(*), 2) as pct
FROM program_exercises_with_media
WHERE sub_program_name = 'Leg_Development_8w_4d'
GROUP BY sub_program_name, week_status;
```

### Get all shippable variants

```sql
WITH variant_stats AS (
    SELECT
        variant_id,
        sub_program_name,
        priority,
        COUNT(*) as total_exercises,
        COUNT(CASE WHEN video_s3_path IS NOT NULL AND image_s3_path IS NOT NULL THEN 1 END) as with_both
    FROM program_exercises_with_media
    WHERE week_status = 'complete'
    GROUP BY variant_id, sub_program_name, priority
)
SELECT
    sub_program_name,
    priority,
    total_exercises
FROM variant_stats
WHERE with_both = total_exercises
ORDER BY priority, total_exercises DESC;
```

### Check week completion for a program

```sql
SELECT DISTINCT
    sub_program_name,
    duration_weeks,
    weeks_ingested,
    week_status,
    status_icon
FROM program_exercises_with_media
WHERE program_name = 'Leg Development';
```

## Next Steps to Improve Coverage

1. **Manual Exercise Mapping** - Add more aliases for unmatched exercises
2. **Placeholder Videos** - Use generic exercise videos for missing media
3. **Focus on High Priority** - Prioritize completing High priority programs first
4. **Batch Processing** - Process programs by priority level

## Notes

- **"Shippable"** = Week status is `complete` AND all exercises have both video + image
- **Variant** = A specific configuration of a program (e.g., 8w_4d vs 4w_3d)
- **Program** = The base program name (may have multiple variants)
- No programs have ALL their variants at 100% coverage yet
- 9 programs have at least 1 shippable variant
- 14 variants out of 929 are currently shippable (1.5%)
