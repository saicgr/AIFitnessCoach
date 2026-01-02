-- Migration: 103_ultimate_strength_program.sql
-- Description: Add Ultimate Strength Builder program with complete workout templates
-- Created: 2025-12-30

-- ============================================================================
-- ADD UNIQUE CONSTRAINT FOR ON CONFLICT
-- ============================================================================
-- First add a unique constraint on program_name so ON CONFLICT works
CREATE UNIQUE INDEX IF NOT EXISTS idx_programs_name_unique ON programs(program_name);

-- ============================================================================
-- ULTIMATE STRENGTH BUILDER PROGRAM
-- ============================================================================
-- A comprehensive 12-week strength building program with 4 distinct phases:
--   - Foundation (Weeks 1-3): Learn proper form, moderate volume
--   - Volume (Weeks 4-6): Increase training volume for hypertrophy
--   - Intensity (Weeks 7-9): Increase weight, lower reps
--   - Peak (Weeks 10-12): Prepare for testing maxes
--
-- 4 workouts per week:
--   - Day 1: Squat Focus (Lower body, squat emphasis)
--   - Day 2: Bench Focus (Upper push, bench emphasis)
--   - Day 3: Deadlift Focus (Posterior chain, deadlift emphasis)
--   - Day 4: Accessories & Conditioning (Overhead press, carries, core)

-- ============================================================================
-- INSERT ULTIMATE STRENGTH BUILDER (12-Week Full Program)
-- ============================================================================

INSERT INTO programs (
    program_name,
    program_category,
    program_subcategory,
    country,
    celebrity_name,
    difficulty_level,
    duration_weeks,
    sessions_per_week,
    session_duration_minutes,
    tags,
    goals,
    description,
    short_description,
    workouts
) VALUES (
    'Ultimate Strength Builder',
    'Goal-Based',
    'Muscle Building',
    ARRAY['Global'],
    NULL,
    'Intermediate',
    12,
    4,
    60,
    ARRAY['strength', 'powerlifting', 'compound', 'progressive overload', 'periodization'],
    ARRAY['Build Strength', 'Build Muscle', 'Increase 1RM'],
    'The definitive strength building program combining powerlifting fundamentals, progressive overload, and periodization. Master the big 3 lifts (squat, bench, deadlift) while building total body strength through compound movements. Features 4 distinct phases: Foundation (weeks 1-3), Volume (weeks 4-6), Intensity (weeks 7-9), and Peak (weeks 10-12).',
    'Complete 12-week strength mastery program with periodized training',
    '{
        "program_phases": [
            {"name": "Foundation", "weeks": "1-3", "focus": "Technique and moderate volume"},
            {"name": "Volume", "weeks": "4-6", "focus": "Increased volume for hypertrophy"},
            {"name": "Intensity", "weeks": "7-9", "focus": "Heavy weights, lower reps"},
            {"name": "Peak", "weeks": "10-12", "focus": "Peaking for max attempts"}
        ],
        "weekly_structure": [
            {
                "day": 1,
                "workout_name": "Squat Focus",
                "type": "Strength",
                "focus": "Lower body, squat emphasis",
                "exercises": [
                    {
                        "exercise_name": "Barbell Back Squat",
                        "sets": 5,
                        "reps": "5",
                        "rest_seconds": 180,
                        "notes": "Main lift - focus on depth and bar path",
                        "progression": "Add 2.5kg per week during Foundation phase"
                    },
                    {
                        "exercise_name": "Pause Squat",
                        "sets": 3,
                        "reps": "3",
                        "rest_seconds": 180,
                        "notes": "2 second pause at bottom, 70% of working squat weight"
                    },
                    {
                        "exercise_name": "Leg Press",
                        "sets": 4,
                        "reps": "8-10",
                        "rest_seconds": 120,
                        "notes": "Higher reps for hypertrophy"
                    },
                    {
                        "exercise_name": "Romanian Deadlift",
                        "sets": 3,
                        "reps": "10-12",
                        "rest_seconds": 90,
                        "notes": "Hamstring focus, controlled eccentric"
                    },
                    {
                        "exercise_name": "Plank",
                        "sets": 3,
                        "reps": "45-60 seconds",
                        "rest_seconds": 60,
                        "notes": "Core stability for squat support"
                    }
                ]
            },
            {
                "day": 2,
                "workout_name": "Bench Focus",
                "type": "Strength",
                "focus": "Upper push, bench emphasis",
                "exercises": [
                    {
                        "exercise_name": "Barbell Bench Press",
                        "sets": 5,
                        "reps": "5",
                        "rest_seconds": 180,
                        "notes": "Main lift - maintain proper arch and leg drive",
                        "progression": "Add 1.25-2.5kg per week during Foundation phase"
                    },
                    {
                        "exercise_name": "Close-Grip Bench Press",
                        "sets": 3,
                        "reps": "6-8",
                        "rest_seconds": 120,
                        "notes": "Tricep emphasis, 80% of bench weight"
                    },
                    {
                        "exercise_name": "Incline Dumbbell Press",
                        "sets": 4,
                        "reps": "8-10",
                        "rest_seconds": 90,
                        "notes": "Upper chest development"
                    },
                    {
                        "exercise_name": "Dips",
                        "sets": 3,
                        "reps": "8-12",
                        "rest_seconds": 90,
                        "notes": "Add weight when bodyweight becomes easy"
                    },
                    {
                        "exercise_name": "Tricep Pushdown",
                        "sets": 3,
                        "reps": "12-15",
                        "rest_seconds": 60,
                        "notes": "Isolation finisher for triceps"
                    }
                ]
            },
            {
                "day": 3,
                "workout_name": "Deadlift Focus",
                "type": "Strength",
                "focus": "Posterior chain, deadlift emphasis",
                "exercises": [
                    {
                        "exercise_name": "Conventional Deadlift",
                        "sets": 5,
                        "reps": "5",
                        "rest_seconds": 180,
                        "notes": "Main lift - reset each rep, maintain neutral spine",
                        "progression": "Add 2.5-5kg per week during Foundation phase"
                    },
                    {
                        "exercise_name": "Deficit Deadlift",
                        "sets": 3,
                        "reps": "4-6",
                        "rest_seconds": 150,
                        "notes": "2-3 inch deficit, builds off-floor strength"
                    },
                    {
                        "exercise_name": "Barbell Row",
                        "sets": 4,
                        "reps": "6-8",
                        "rest_seconds": 90,
                        "notes": "Upper back strength for deadlift support"
                    },
                    {
                        "exercise_name": "Pull-ups",
                        "sets": 3,
                        "reps": "6-10",
                        "rest_seconds": 90,
                        "notes": "Add weight when bodyweight becomes easy"
                    },
                    {
                        "exercise_name": "Barbell Curl",
                        "sets": 3,
                        "reps": "10-12",
                        "rest_seconds": 60,
                        "notes": "Arm development and grip support"
                    }
                ]
            },
            {
                "day": 4,
                "workout_name": "Accessories & Conditioning",
                "type": "Strength",
                "focus": "Overhead press, carries, core work",
                "exercises": [
                    {
                        "exercise_name": "Overhead Press",
                        "sets": 4,
                        "reps": "6-8",
                        "rest_seconds": 150,
                        "notes": "Shoulder strength, strict form"
                    },
                    {
                        "exercise_name": "Push Press",
                        "sets": 3,
                        "reps": "5",
                        "rest_seconds": 120,
                        "notes": "Explosive overhead power"
                    },
                    {
                        "exercise_name": "Farmer Walks",
                        "sets": 3,
                        "reps": "40 meters",
                        "rest_seconds": 90,
                        "notes": "Grip strength and core stability"
                    },
                    {
                        "exercise_name": "Face Pulls",
                        "sets": 3,
                        "reps": "15-20",
                        "rest_seconds": 60,
                        "notes": "Shoulder health and rear delt development"
                    },
                    {
                        "exercise_name": "Hanging Leg Raise",
                        "sets": 3,
                        "reps": "10-15",
                        "rest_seconds": 60,
                        "notes": "Core strength and hip flexor development"
                    },
                    {
                        "exercise_name": "Ab Wheel Rollout",
                        "sets": 3,
                        "reps": "10-12",
                        "rest_seconds": 60,
                        "notes": "Core anti-extension strength"
                    }
                ]
            }
        ],
        "progression_guidelines": {
            "foundation_phase": {
                "weeks": "1-3",
                "squat_intensity": "70-75%",
                "bench_intensity": "70-75%",
                "deadlift_intensity": "70-75%",
                "notes": "Focus on technique, add weight weekly"
            },
            "volume_phase": {
                "weeks": "4-6",
                "squat_intensity": "75-80%",
                "bench_intensity": "75-80%",
                "deadlift_intensity": "75-80%",
                "notes": "Add 1-2 sets to main lifts"
            },
            "intensity_phase": {
                "weeks": "7-9",
                "squat_intensity": "80-87%",
                "bench_intensity": "80-87%",
                "deadlift_intensity": "80-87%",
                "notes": "Reduce reps to 3-5, increase weight"
            },
            "peak_phase": {
                "weeks": "10-12",
                "squat_intensity": "87-95%",
                "bench_intensity": "87-95%",
                "deadlift_intensity": "87-95%",
                "notes": "Singles and doubles, reduce volume, test 1RM in week 12"
            }
        },
        "equipment_required": ["barbell", "squat_rack", "bench", "dumbbells", "pull_up_bar", "cable_machine"]
    }'::jsonb
)
ON CONFLICT (program_name) DO UPDATE SET
    workouts = EXCLUDED.workouts,
    updated_at = NOW();

-- ============================================================================
-- INSERT PROGRAM VARIANTS
-- ============================================================================

-- Easy variant (Beginner)
INSERT INTO programs (
    program_name,
    program_category,
    program_subcategory,
    country,
    celebrity_name,
    difficulty_level,
    duration_weeks,
    sessions_per_week,
    session_duration_minutes,
    tags,
    goals,
    description,
    short_description,
    workouts
) VALUES (
    'Ultimate Strength Builder - Easy',
    'Goal-Based',
    'Muscle Building',
    ARRAY['Global'],
    NULL,
    'Beginner',
    12,
    3,
    45,
    ARRAY['strength', 'beginner', 'compound', 'foundation'],
    ARRAY['Build Strength', 'Learn Fundamentals', 'Build Muscle'],
    'A beginner-friendly version of the Ultimate Strength Builder program. Focus on learning proper form for the big 3 lifts while building a solid strength foundation. Lower volume and intensity with emphasis on technique mastery.',
    'Beginner-friendly strength foundation program',
    '{
        "weekly_structure": [
            {
                "day": 1,
                "workout_name": "Squat & Legs",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Goblet Squat", "sets": 3, "reps": "8-10", "rest_seconds": 120, "notes": "Learn squat pattern with goblet position"},
                    {"exercise_name": "Barbell Back Squat", "sets": 3, "reps": "5", "rest_seconds": 180, "notes": "Light weight, focus on form"},
                    {"exercise_name": "Leg Press", "sets": 3, "reps": "10-12", "rest_seconds": 90},
                    {"exercise_name": "Plank", "sets": 3, "reps": "30 seconds", "rest_seconds": 60}
                ]
            },
            {
                "day": 2,
                "workout_name": "Bench & Push",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Dumbbell Bench Press", "sets": 3, "reps": "8-10", "rest_seconds": 90, "notes": "Learn pressing pattern"},
                    {"exercise_name": "Barbell Bench Press", "sets": 3, "reps": "5", "rest_seconds": 180, "notes": "Light weight, focus on form"},
                    {"exercise_name": "Incline Dumbbell Press", "sets": 3, "reps": "10-12", "rest_seconds": 90},
                    {"exercise_name": "Tricep Dips (Assisted)", "sets": 2, "reps": "10-12", "rest_seconds": 60}
                ]
            },
            {
                "day": 3,
                "workout_name": "Deadlift & Pull",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Dumbbell Romanian Deadlift", "sets": 3, "reps": "10-12", "rest_seconds": 90, "notes": "Learn hip hinge pattern"},
                    {"exercise_name": "Conventional Deadlift", "sets": 3, "reps": "5", "rest_seconds": 180, "notes": "Light weight, focus on form"},
                    {"exercise_name": "Lat Pulldown", "sets": 3, "reps": "10-12", "rest_seconds": 90},
                    {"exercise_name": "Dumbbell Row", "sets": 3, "reps": "10-12", "rest_seconds": 60}
                ]
            }
        ],
        "equipment_required": ["barbell", "squat_rack", "bench", "dumbbells", "cable_machine"]
    }'::jsonb
)
ON CONFLICT (program_name) DO UPDATE SET
    workouts = EXCLUDED.workouts,
    updated_at = NOW();

-- Hard variant (Advanced)
INSERT INTO programs (
    program_name,
    program_category,
    program_subcategory,
    country,
    celebrity_name,
    difficulty_level,
    duration_weeks,
    sessions_per_week,
    session_duration_minutes,
    tags,
    goals,
    description,
    short_description,
    workouts
) VALUES (
    'Ultimate Strength Builder - Hard',
    'Goal-Based',
    'Muscle Building',
    ARRAY['Global'],
    NULL,
    'Advanced',
    12,
    5,
    75,
    ARRAY['strength', 'powerlifting', 'advanced', 'high volume', 'periodization'],
    ARRAY['Build Strength', 'Maximize 1RM', 'Competition Prep'],
    'An advanced variation of the Ultimate Strength Builder for experienced lifters. Higher volume, greater intensity, and more accessory work. Designed for those looking to push their limits and prepare for powerlifting competitions.',
    'Advanced high-intensity strength program',
    '{
        "weekly_structure": [
            {
                "day": 1,
                "workout_name": "Heavy Squat",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Back Squat", "sets": 6, "reps": "4-5", "rest_seconds": 240, "notes": "Work up to heavy singles on peak phase"},
                    {"exercise_name": "Pause Squat", "sets": 4, "reps": "3", "rest_seconds": 180, "notes": "3 second pause"},
                    {"exercise_name": "Front Squat", "sets": 3, "reps": "5-6", "rest_seconds": 150},
                    {"exercise_name": "Leg Press", "sets": 4, "reps": "8-10", "rest_seconds": 120},
                    {"exercise_name": "Romanian Deadlift", "sets": 4, "reps": "8-10", "rest_seconds": 90}
                ]
            },
            {
                "day": 2,
                "workout_name": "Heavy Bench",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Bench Press", "sets": 6, "reps": "4-5", "rest_seconds": 240, "notes": "Work up to heavy singles on peak phase"},
                    {"exercise_name": "Pause Bench Press", "sets": 4, "reps": "3", "rest_seconds": 180, "notes": "2 second pause on chest"},
                    {"exercise_name": "Close-Grip Bench Press", "sets": 4, "reps": "5-6", "rest_seconds": 150},
                    {"exercise_name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10", "rest_seconds": 90},
                    {"exercise_name": "Weighted Dips", "sets": 3, "reps": "6-8", "rest_seconds": 90}
                ]
            },
            {
                "day": 3,
                "workout_name": "Heavy Deadlift",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Conventional Deadlift", "sets": 6, "reps": "3-4", "rest_seconds": 300, "notes": "Work up to heavy singles on peak phase"},
                    {"exercise_name": "Deficit Deadlift", "sets": 3, "reps": "4", "rest_seconds": 180},
                    {"exercise_name": "Barbell Row", "sets": 5, "reps": "5-6", "rest_seconds": 120},
                    {"exercise_name": "Weighted Pull-ups", "sets": 4, "reps": "5-8", "rest_seconds": 120},
                    {"exercise_name": "Barbell Shrug", "sets": 4, "reps": "8-10", "rest_seconds": 90}
                ]
            },
            {
                "day": 4,
                "workout_name": "Volume Squat/Bench",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Back Squat", "sets": 4, "reps": "6-8", "rest_seconds": 150, "notes": "70-75% of max"},
                    {"exercise_name": "Barbell Bench Press", "sets": 4, "reps": "6-8", "rest_seconds": 150, "notes": "70-75% of max"},
                    {"exercise_name": "Leg Curl", "sets": 4, "reps": "10-12", "rest_seconds": 90},
                    {"exercise_name": "Tricep Extension", "sets": 4, "reps": "10-12", "rest_seconds": 60}
                ]
            },
            {
                "day": 5,
                "workout_name": "Accessories & OHP",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Overhead Press", "sets": 5, "reps": "5-6", "rest_seconds": 150},
                    {"exercise_name": "Push Press", "sets": 3, "reps": "4-5", "rest_seconds": 120},
                    {"exercise_name": "Farmer Walks", "sets": 4, "reps": "50 meters", "rest_seconds": 90},
                    {"exercise_name": "Face Pulls", "sets": 4, "reps": "15-20", "rest_seconds": 60},
                    {"exercise_name": "Hanging Leg Raise", "sets": 4, "reps": "12-15", "rest_seconds": 60},
                    {"exercise_name": "Ab Wheel Rollout", "sets": 3, "reps": "12-15", "rest_seconds": 60}
                ]
            }
        ],
        "equipment_required": ["barbell", "squat_rack", "bench", "dumbbells", "pull_up_bar", "cable_machine", "farmers_handles"]
    }'::jsonb
)
ON CONFLICT (program_name) DO UPDATE SET
    workouts = EXCLUDED.workouts,
    updated_at = NOW();

-- 4-Week variant
INSERT INTO programs (
    program_name,
    program_category,
    program_subcategory,
    country,
    celebrity_name,
    difficulty_level,
    duration_weeks,
    sessions_per_week,
    session_duration_minutes,
    tags,
    goals,
    description,
    short_description,
    workouts
) VALUES (
    'Ultimate Strength Builder - 4 Week',
    'Goal-Based',
    'Muscle Building',
    ARRAY['Global'],
    NULL,
    'Intermediate',
    4,
    4,
    60,
    ARRAY['strength', 'powerlifting', 'compound', 'short program'],
    ARRAY['Build Strength', 'Build Muscle', 'Quick Results'],
    'A condensed 4-week strength program based on the Ultimate Strength Builder methodology. Perfect for those with limited time or looking for a strength-focused mesocycle to insert into their training.',
    'Condensed 4-week strength boost program',
    '{
        "program_phases": [
            {"name": "Buildup", "weeks": "1-2", "focus": "Volume accumulation"},
            {"name": "Intensity", "weeks": "3-4", "focus": "Heavy singles and doubles"}
        ],
        "weekly_structure": [
            {
                "day": 1,
                "workout_name": "Squat Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Back Squat", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Romanian Deadlift", "sets": 3, "reps": "8", "rest_seconds": 90},
                    {"exercise_name": "Leg Press", "sets": 3, "reps": "10", "rest_seconds": 90},
                    {"exercise_name": "Plank", "sets": 3, "reps": "45 seconds", "rest_seconds": 60}
                ]
            },
            {
                "day": 2,
                "workout_name": "Bench Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Bench Press", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Close-Grip Bench Press", "sets": 3, "reps": "6-8", "rest_seconds": 120},
                    {"exercise_name": "Incline Dumbbell Press", "sets": 3, "reps": "10", "rest_seconds": 90},
                    {"exercise_name": "Dips", "sets": 3, "reps": "10", "rest_seconds": 60}
                ]
            },
            {
                "day": 3,
                "workout_name": "Deadlift Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Conventional Deadlift", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Barbell Row", "sets": 4, "reps": "6-8", "rest_seconds": 90},
                    {"exercise_name": "Pull-ups", "sets": 3, "reps": "8", "rest_seconds": 90},
                    {"exercise_name": "Barbell Curl", "sets": 3, "reps": "10", "rest_seconds": 60}
                ]
            },
            {
                "day": 4,
                "workout_name": "Accessories",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Overhead Press", "sets": 4, "reps": "6", "rest_seconds": 150},
                    {"exercise_name": "Farmer Walks", "sets": 3, "reps": "40 meters", "rest_seconds": 90},
                    {"exercise_name": "Face Pulls", "sets": 3, "reps": "15", "rest_seconds": 60},
                    {"exercise_name": "Hanging Leg Raise", "sets": 3, "reps": "12", "rest_seconds": 60}
                ]
            }
        ],
        "equipment_required": ["barbell", "squat_rack", "bench", "dumbbells", "pull_up_bar", "cable_machine"]
    }'::jsonb
)
ON CONFLICT (program_name) DO UPDATE SET
    workouts = EXCLUDED.workouts,
    updated_at = NOW();

-- 8-Week variant
INSERT INTO programs (
    program_name,
    program_category,
    program_subcategory,
    country,
    celebrity_name,
    difficulty_level,
    duration_weeks,
    sessions_per_week,
    session_duration_minutes,
    tags,
    goals,
    description,
    short_description,
    workouts
) VALUES (
    'Ultimate Strength Builder - 8 Week',
    'Goal-Based',
    'Muscle Building',
    ARRAY['Global'],
    NULL,
    'Intermediate',
    8,
    4,
    60,
    ARRAY['strength', 'powerlifting', 'compound', 'periodization'],
    ARRAY['Build Strength', 'Build Muscle', 'Increase 1RM'],
    'An 8-week strength program featuring two training phases: Foundation (weeks 1-4) and Intensity (weeks 5-8). Streamlined version of the full 12-week Ultimate Strength Builder.',
    'Streamlined 8-week strength building program',
    '{
        "program_phases": [
            {"name": "Foundation", "weeks": "1-4", "focus": "Volume and technique"},
            {"name": "Intensity", "weeks": "5-8", "focus": "Heavy weights, lower reps"}
        ],
        "weekly_structure": [
            {
                "day": 1,
                "workout_name": "Squat Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Back Squat", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Pause Squat", "sets": 3, "reps": "3", "rest_seconds": 150},
                    {"exercise_name": "Romanian Deadlift", "sets": 3, "reps": "10", "rest_seconds": 90},
                    {"exercise_name": "Leg Press", "sets": 3, "reps": "10", "rest_seconds": 90},
                    {"exercise_name": "Plank", "sets": 3, "reps": "45 seconds", "rest_seconds": 60}
                ]
            },
            {
                "day": 2,
                "workout_name": "Bench Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Barbell Bench Press", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Close-Grip Bench Press", "sets": 3, "reps": "6-8", "rest_seconds": 120},
                    {"exercise_name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10", "rest_seconds": 90},
                    {"exercise_name": "Dips", "sets": 3, "reps": "10", "rest_seconds": 90},
                    {"exercise_name": "Tricep Pushdown", "sets": 3, "reps": "12", "rest_seconds": 60}
                ]
            },
            {
                "day": 3,
                "workout_name": "Deadlift Focus",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Conventional Deadlift", "sets": 5, "reps": "5", "rest_seconds": 180},
                    {"exercise_name": "Deficit Deadlift", "sets": 3, "reps": "4", "rest_seconds": 150},
                    {"exercise_name": "Barbell Row", "sets": 4, "reps": "6-8", "rest_seconds": 90},
                    {"exercise_name": "Pull-ups", "sets": 3, "reps": "8", "rest_seconds": 90},
                    {"exercise_name": "Barbell Curl", "sets": 3, "reps": "10", "rest_seconds": 60}
                ]
            },
            {
                "day": 4,
                "workout_name": "Accessories",
                "type": "Strength",
                "exercises": [
                    {"exercise_name": "Overhead Press", "sets": 4, "reps": "6", "rest_seconds": 150},
                    {"exercise_name": "Push Press", "sets": 3, "reps": "5", "rest_seconds": 120},
                    {"exercise_name": "Farmer Walks", "sets": 3, "reps": "40 meters", "rest_seconds": 90},
                    {"exercise_name": "Face Pulls", "sets": 3, "reps": "15", "rest_seconds": 60},
                    {"exercise_name": "Hanging Leg Raise", "sets": 3, "reps": "12", "rest_seconds": 60},
                    {"exercise_name": "Ab Wheel Rollout", "sets": 3, "reps": "10", "rest_seconds": 60}
                ]
            }
        ],
        "equipment_required": ["barbell", "squat_rack", "bench", "dumbbells", "pull_up_bar", "cable_machine"]
    }'::jsonb
)
ON CONFLICT (program_name) DO UPDATE SET
    workouts = EXCLUDED.workouts,
    updated_at = NOW();

-- ============================================================================
-- UPDATE BRANDED PROGRAMS (if not already present)
-- ============================================================================
-- The branded_programs table may have an "Ultimate Strength" entry from migration 101.
-- This ensures consistency and adds workout templates if missing.

UPDATE branded_programs
SET
    description = 'The definitive strength building program combining powerlifting fundamentals, progressive overload, and periodization. Master the big 3 lifts (squat, bench, deadlift) while building total body strength through compound movements. Features 4 distinct phases: Foundation (weeks 1-3), Volume (weeks 4-6), Intensity (weeks 7-9), and Peak (weeks 10-12).',
    tagline = 'Master the Big 3, build raw power',
    updated_at = NOW()
WHERE name = 'Ultimate Strength';

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON COLUMN programs.workouts IS 'JSONB containing workout templates with exercises, sets, reps, and progression guidelines';
