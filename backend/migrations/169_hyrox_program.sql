-- Migration: 169_hyrox_program.sql
-- Description: HYROX Race Prep Program - First real pre-generated variable program
-- Created: 2025-01-20
--
-- This migration:
-- 1. Adds schema updates for race-date targeting and divisions
-- 2. Adds HYROX-specific exercises to the exercises table
-- 3. Creates HYROX Gym and Home branded programs
-- 4. Stores phase templates and division weight configurations

-- ============================================================================
-- STEP 1: SCHEMA UPDATES FOR HYROX PROGRAMS
-- ============================================================================

-- Add program_type to branded_programs for special program handling
ALTER TABLE branded_programs
ADD COLUMN IF NOT EXISTS program_type TEXT DEFAULT 'standard';

-- Add HYROX-specific fields to user_program_assignments
ALTER TABLE user_program_assignments
ADD COLUMN IF NOT EXISTS target_race_date DATE;

ALTER TABLE user_program_assignments
ADD COLUMN IF NOT EXISTS division TEXT CHECK (division IN (
    'open_women', 'open_men', 'pro_women', 'pro_men'
));

ALTER TABLE user_program_assignments
ADD COLUMN IF NOT EXISTS current_phase TEXT CHECK (current_phase IN (
    'blueprint', 'build', 'race', 'restore'
));

-- Add program_metadata JSONB for storing phase templates, division configs, etc.
ALTER TABLE branded_programs
ADD COLUMN IF NOT EXISTS program_metadata JSONB DEFAULT '{}';

-- Create index for HYROX program queries
CREATE INDEX IF NOT EXISTS idx_branded_programs_type ON branded_programs(program_type);
CREATE INDEX IF NOT EXISTS idx_user_program_race_date ON user_program_assignments(target_race_date)
    WHERE target_race_date IS NOT NULL;

-- ============================================================================
-- STEP 2: ADD HYROX-SPECIFIC EXERCISES
-- ============================================================================

-- SkiErg
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_skierg',
    'SkiErg',
    'cardio',
    'hyrox',
    5,
    'lats',
    '["triceps", "core", "shoulders", "glutes"]'::jsonb,
    '["skierg"]'::jsonb,
    'back',
    'skierg',
    'lats',
    1, NULL, 180, 60,
    12.0,
    'Stand facing the SkiErg with feet hip-width apart. Grip both handles and raise arms overhead. Pull down powerfully while hinging at the hips and bending knees slightly. Drive the handles past your hips. Return to start with control and repeat in a rhythmic motion.',
    '["Engage core throughout", "Use hip hinge for power", "Keep a steady rhythm", "Breathe out on the pull", "Drive through the legs"]'::jsonb,
    'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
    true, false,
    '["hyrox", "cardio", "full_body", "endurance"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Sled Push
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_sled_push',
    'Sled Push',
    'strength',
    'hyrox',
    7,
    'quadriceps',
    '["glutes", "calves", "core", "shoulders"]'::jsonb,
    '["sled"]'::jsonb,
    'upper legs',
    'sled',
    'quadriceps',
    1, NULL, 60, 90,
    102.0,
    10.0,
    'Position yourself behind the sled with hands on the high handles. Keep your body at a 45-degree angle with arms extended. Drive forward by pushing through your legs, taking short powerful steps. Keep your core braced and head neutral. Push for the full distance without stopping.',
    '["Stay low for more power", "Drive through your legs not arms", "Take short quick steps", "Keep core tight", "Look down at the ground ahead"]'::jsonb,
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
    true, false,
    '["hyrox", "strength", "legs", "power"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Sled Pull
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_sled_pull',
    'Sled Pull',
    'strength',
    'hyrox',
    7,
    'lats',
    '["biceps", "forearms", "core", "rear_delts"]'::jsonb,
    '["sled", "rope"]'::jsonb,
    'back',
    'sled',
    'lats',
    1, NULL, 90, 90,
    78.0,
    9.0,
    'Face the sled and grip the rope with both hands. Sit back into a squat position with arms extended. Pull the rope hand over hand, bringing the sled towards you. Keep your core braced and maintain a stable base. Continue until the sled reaches you, then reset and repeat.',
    '["Sit back for leverage", "Use your whole body", "Keep rhythm consistent", "Grip firmly but not too tight", "Pull with your back not just arms"]'::jsonb,
    'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400',
    true, false,
    '["hyrox", "strength", "back", "grip"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Burpee Broad Jump
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_burpee_broad_jump',
    'Burpee Broad Jump',
    'cardio',
    'hyrox',
    8,
    'quadriceps',
    '["chest", "shoulders", "core", "glutes", "hamstrings"]'::jsonb,
    '["bodyweight"]'::jsonb,
    'full body',
    'body weight',
    'cardiovascular system',
    3, 10, NULL, 60,
    14.0,
    'Start standing. Drop into a burpee by placing hands on floor, jumping feet back to plank, performing a push-up, then jumping feet forward. From the squat position, explode forward into a broad jump, landing softly. That counts as one rep. Immediately go into the next burpee.',
    '["Land softly to save energy", "Jump forward not up", "Keep a steady pace", "Breathe rhythmically", "Use your arms for momentum"]'::jsonb,
    'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff?w=400',
    true, false,
    '["hyrox", "cardio", "full_body", "explosive"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Wall Balls
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_wall_balls',
    'Wall Balls',
    'cardio',
    'hyrox',
    6,
    'quadriceps',
    '["glutes", "shoulders", "core", "triceps"]'::jsonb,
    '["medicine_ball", "wall"]'::jsonb,
    'full body',
    'medicine ball',
    'quadriceps',
    3, 20, NULL, 60,
    4.0,
    11.0,
    'Stand facing a wall, about arms length away, holding a medicine ball at chest height. Squat down until thighs are parallel to floor. Drive up explosively while throwing the ball to hit a target 10ft (3m) high. Catch the ball and immediately descend into the next squat.',
    '["Use your legs to throw", "Catch and squat in one motion", "Keep elbows high", "Breathe out as you throw", "Find a rhythm"]'::jsonb,
    'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400',
    true, false,
    '["hyrox", "cardio", "full_body", "endurance"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Sandbag Lunges
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_sandbag_lunges',
    'Sandbag Walking Lunges',
    'strength',
    'hyrox',
    6,
    'quadriceps',
    '["glutes", "hamstrings", "core", "shoulders"]'::jsonb,
    '["sandbag"]'::jsonb,
    'upper legs',
    'sandbag',
    'quadriceps',
    3, 20, NULL, 60,
    10.0,
    8.0,
    'Position the sandbag across your shoulders behind your neck, gripping it firmly. Step forward into a lunge, lowering your back knee towards the ground. Drive through your front heel to stand and step forward into the next lunge. Continue walking forward for the prescribed distance.',
    '["Keep torso upright", "Take consistent steps", "Drive through front heel", "Keep core braced", "Control the descent"]'::jsonb,
    'https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=400',
    true, true,
    '["hyrox", "strength", "legs", "endurance"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Kettlebell Farmers Carry (for HYROX)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_farmers_carry',
    'Kettlebell Farmers Carry',
    'strength',
    'hyrox',
    5,
    'forearms',
    '["traps", "core", "shoulders", "glutes"]'::jsonb,
    '["kettlebells"]'::jsonb,
    'forearms',
    'kettlebell',
    'forearms',
    3, NULL, 60, 60,
    16.0,
    7.0,
    'Stand between two heavy kettlebells. Squat down and grip each handle firmly. Stand tall with shoulders back and core engaged. Walk forward with controlled steps, keeping the kettlebells stable at your sides. Maintain upright posture throughout the carry distance.',
    '["Keep shoulders back and down", "Engage core tight", "Take quick short steps", "Breathe steadily", "Grip hard but stay relaxed"]'::jsonb,
    'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400',
    true, false,
    '["hyrox", "strength", "grip", "core"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- 1km Running (for HYROX program structure)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_1km_run',
    '1km Run',
    'cardio',
    'hyrox',
    4,
    'quadriceps',
    '["hamstrings", "calves", "glutes", "core"]'::jsonb,
    '["bodyweight"]'::jsonb,
    'cardio',
    'body weight',
    'cardiovascular system',
    1, NULL, 300, 30,
    10.0,
    'Run 1 kilometer at your target race pace. Focus on maintaining consistent effort and breathing rhythm. In HYROX, this is performed 8 times between functional stations.',
    '["Find your sustainable pace", "Breathe rhythmically", "Stay relaxed in upper body", "Use arms for momentum", "Recover mentally during runs"]'::jsonb,
    'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=400',
    true, false,
    '["hyrox", "cardio", "running", "endurance"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- ============================================================================
-- STEP 3: HOME SUBSTITUTE EXERCISES
-- ============================================================================

-- Battle Ropes (home substitute for SkiErg)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_battle_ropes',
    'Battle Ropes Alternating Waves',
    'cardio',
    'hyrox_substitute',
    5,
    'shoulders',
    '["core", "lats", "biceps", "forearms"]'::jsonb,
    '["battle_ropes"]'::jsonb,
    'shoulders',
    'rope',
    'deltoids',
    3, NULL, 60, 45,
    12.0,
    'Hold one rope end in each hand with slack in the ropes. Stand with feet shoulder-width apart, knees slightly bent. Rapidly alternate raising and lowering each arm to create waves in the ropes. Maintain rhythm and intensity for the duration.',
    '["Stay low in athletic stance", "Use full arm range", "Keep core tight", "Breathe rhythmically", "Generate waves from shoulders"]'::jsonb,
    'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400',
    true, false,
    '["hyrox", "cardio", "home", "substitute"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Banded Bear Crawl (home substitute for Sled Push)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_banded_bear_crawl',
    'Banded Bear Crawl',
    'strength',
    'hyrox_substitute',
    6,
    'quadriceps',
    '["core", "shoulders", "glutes"]'::jsonb,
    '["resistance_bands"]'::jsonb,
    'full body',
    'band',
    'quadriceps',
    3, NULL, 45, 60,
    9.0,
    'Place a resistance band around your thighs above knees. Get into bear crawl position with knees hovering just off the ground. Crawl forward moving opposite hand and foot together. Keep hips low and core tight throughout.',
    '["Keep knees low to ground", "Move opposite limbs together", "Maintain tension on band", "Keep core braced", "Move smoothly not rushed"]'::jsonb,
    'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400',
    true, false,
    '["hyrox", "strength", "home", "substitute"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- High Rep Band Rows (home substitute for Sled Pull)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_band_rows_high_rep',
    'High Rep Resistance Band Rows',
    'strength',
    'hyrox_substitute',
    4,
    'lats',
    '["biceps", "rear_delts", "rhomboids"]'::jsonb,
    '["resistance_bands"]'::jsonb,
    'back',
    'band',
    'lats',
    3, 50, NULL, 45,
    6.0,
    'Anchor a resistance band at chest height. Stand facing the anchor, holding both handles with arms extended. Pull handles to your sides, squeezing shoulder blades together. Return with control. Perform high reps to simulate sled pull endurance.',
    '["Keep elbows close to body", "Squeeze at the back", "Control the return", "Maintain posture", "Find a rhythm"]'::jsonb,
    'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400',
    true, false,
    '["hyrox", "strength", "home", "substitute"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- Dumbbell Thrusters (home substitute for Wall Balls)
INSERT INTO exercises (
    external_id, name, category, subcategory, difficulty_level,
    primary_muscle, secondary_muscles, equipment_required,
    body_part, equipment, target,
    default_sets, default_reps, default_duration_seconds, default_rest_seconds,
    min_weight_kg, calories_per_minute, instructions, tips,
    gif_url, is_compound, is_unilateral, tags
) VALUES (
    'hyrox_dumbbell_thrusters',
    'Dumbbell Thrusters',
    'strength',
    'hyrox_substitute',
    6,
    'quadriceps',
    '["shoulders", "glutes", "triceps", "core"]'::jsonb,
    '["dumbbells"]'::jsonb,
    'full body',
    'dumbbell',
    'quadriceps',
    3, 20, NULL, 60,
    5.0,
    10.0,
    'Hold dumbbells at shoulder height with palms facing each other. Squat down until thighs are parallel to floor. Drive up explosively while pressing the dumbbells overhead. Lower dumbbells back to shoulders as you descend into the next squat.',
    '["Use leg drive for press", "Keep core tight", "Full range of motion", "Breathe out on press", "Find a sustainable rhythm"]'::jsonb,
    'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400',
    true, false,
    '["hyrox", "strength", "home", "substitute"]'::jsonb
)
ON CONFLICT (external_id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    instructions = EXCLUDED.instructions;

-- ============================================================================
-- STEP 4: CREATE HYROX BRANDED PROGRAMS
-- ============================================================================

-- First, delete any existing test programs (keeping the table structure)
-- DELETE FROM user_program_assignments WHERE branded_program_id IN (
--     SELECT id FROM branded_programs WHERE name LIKE '%Test%' OR name LIKE '%test%'
-- );
-- DELETE FROM branded_programs WHERE name LIKE '%Test%' OR name LIKE '%test%';

-- HYROX Race Prep (Gym Version)
INSERT INTO branded_programs (
    name, tagline, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type, goals,
    icon_name, color_hex, is_featured, is_premium, requires_gym, minimum_equipment,
    program_type, program_metadata
) VALUES (
    'HYROX Race Prep',
    'Train for the World Series of Fitness Racing',
    'Complete periodized program for HYROX competition. Automatically adjusts to your race date - from 8-week quick prep to 6-month elite cycles. Includes all 4 phases: Blueprint (aerobic base), Build (race-specific), Race (peak performance), and Restore (recovery). Features all 8 official HYROX stations with proper weights for your division.',
    'athletic',
    'intermediate',
    12,
    5,
    'custom',
    ARRAY['hyrox_race', 'improve_endurance', 'functional_strength', 'race_preparation'],
    'directions_run',
    '#FFD700',
    true,
    false,
    true,
    ARRAY['skierg', 'rower', 'sled', 'kettlebells', 'sandbag', 'wall_ball'],
    'hyrox',
    '{
        "program_type": "hyrox",
        "supports_race_date": true,
        "duration_tiers": {
            "quick_prep": {"min_weeks": 8, "max_weeks": 10, "phases": ["build", "race"]},
            "standard": {"min_weeks": 12, "max_weeks": 16, "phases": ["build", "race"]},
            "full_prep": {"min_weeks": 20, "max_weeks": 24, "phases": ["blueprint", "build", "race"]},
            "elite_cycle": {"min_weeks": 24, "max_weeks": 52, "phases": ["blueprint", "build", "race"]}
        },
        "divisions": {
            "open_women": {
                "sled_push_kg": 102, "sled_pull_kg": 78,
                "farmers_carry_kg": 16, "sandbag_kg": 10, "wall_ball_kg": 4
            },
            "open_men": {
                "sled_push_kg": 152, "sled_pull_kg": 103,
                "farmers_carry_kg": 24, "sandbag_kg": 20, "wall_ball_kg": 6
            },
            "pro_women": {
                "sled_push_kg": 152, "sled_pull_kg": 103,
                "farmers_carry_kg": 24, "sandbag_kg": 20, "wall_ball_kg": 6
            },
            "pro_men": {
                "sled_push_kg": 152, "sled_pull_kg": 153,
                "farmers_carry_kg": 32, "sandbag_kg": 30, "wall_ball_kg": 9
            }
        },
        "stations": [
            {"order": 1, "exercise_id": "hyrox_skierg", "target": "1000m", "type": "distance"},
            {"order": 2, "exercise_id": "hyrox_sled_push", "target": "50m", "type": "distance"},
            {"order": 3, "exercise_id": "hyrox_sled_pull", "target": "50m", "type": "distance"},
            {"order": 4, "exercise_id": "hyrox_burpee_broad_jump", "target": "80m", "type": "distance"},
            {"order": 5, "exercise_id": "rowing", "target": "1000m", "type": "distance"},
            {"order": 6, "exercise_id": "hyrox_farmers_carry", "target": "200m", "type": "distance"},
            {"order": 7, "exercise_id": "hyrox_sandbag_lunges", "target": "100m", "type": "distance"},
            {"order": 8, "exercise_id": "hyrox_wall_balls", "target": "100", "type": "reps"}
        ],
        "phases": {
            "blueprint": {
                "focus": "Build aerobic base, general strength, movement quality",
                "duration_weeks_options": [8, 12, 16],
                "sessions_per_week": 4,
                "weekly_template": {
                    "day_1": {"name": "Compound Strength", "focus": "squats, deadlifts, presses", "rep_range": "8-15"},
                    "day_2": {"name": "Zone 2 Running", "focus": "65-75% max HR", "duration_min": 30},
                    "day_3": {"name": "Upper Body + Core", "focus": "rowing/skierg technique"},
                    "day_4": {"name": "Easy Run", "focus": "recovery pace", "duration_min": 30}
                }
            },
            "build": {
                "focus": "Race-specific fitness, hybrid workouts, brick runs",
                "duration_weeks_options": [8, 10, 12],
                "sessions_per_week": 5,
                "weekly_template": {
                    "day_1": {"name": "Push Stations + Brick", "exercises": ["skierg", "sled_push", "wall_balls"], "brick_run_km": 1},
                    "day_2": {"name": "Running Intervals", "sets": "3-8", "distance_km": 1, "intensity": "race_pace"},
                    "day_3": {"name": "Pull Stations + Brick", "exercises": ["rowing", "sled_pull", "farmers_carry"], "brick_run_km": 1},
                    "day_4": {"name": "Tempo Run", "duration_min": 45, "intensity": "threshold"},
                    "day_5": {"name": "Half HYROX Simulation", "stations": 4, "running_km": 4}
                }
            },
            "race": {
                "focus": "Peak performance, full simulations, tactical execution",
                "duration_weeks_options": [4, 6, 8],
                "sessions_per_week": 5,
                "weekly_template": {
                    "day_1": {"name": "Full HYROX Simulation", "intensity_percent": 85},
                    "day_2": {"name": "1km Pace Runs", "sets": "4-6", "intensity": "race_pace"},
                    "day_3": {"name": "Station Speed Work", "focus": "fast transitions"},
                    "day_4": {"name": "Partial Simulation", "stations": 4, "running_km": 4},
                    "day_5": {"name": "Strength Maintenance", "volume": "reduced"}
                },
                "taper_week": {
                    "volume_reduction_percent": 50,
                    "focus": "technique, sleep, visualization"
                }
            },
            "restore": {
                "focus": "Recovery, injury prevention, next cycle preparation",
                "duration_weeks": 4,
                "sessions_per_week": 3,
                "structure": {
                    "week_1": "Complete rest",
                    "weeks_2_3": "Light activity at 50-60% max HR",
                    "week_4": "Gradual return at 25% peak volume"
                }
            }
        },
        "target_times": {
            "elite_men": {"min": 53, "max": 59, "unit": "minutes"},
            "elite_women": {"min": 58, "max": 65, "unit": "minutes"},
            "competitive": {"min": 60, "max": 75, "unit": "minutes"},
            "finish": {"min": 75, "max": 120, "unit": "minutes"}
        }
    }'::jsonb
)
ON CONFLICT (name) DO UPDATE SET
    tagline = EXCLUDED.tagline,
    description = EXCLUDED.description,
    program_type = EXCLUDED.program_type,
    program_metadata = EXCLUDED.program_metadata,
    updated_at = NOW();

-- HYROX Home Edition
INSERT INTO branded_programs (
    name, tagline, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type, goals,
    icon_name, color_hex, is_featured, is_premium, requires_gym, minimum_equipment,
    program_type, program_metadata
) VALUES (
    'HYROX Home Edition',
    'Race-ready without the gym',
    'Complete HYROX preparation using home-friendly equipment substitutes. Same periodized structure adapted for home training. Perfect for athletes who want to prepare for HYROX but dont have access to specialized equipment like SkiErgs or sleds. Includes scientifically-backed substitute exercises that target the same muscle groups and energy systems.',
    'athletic',
    'intermediate',
    12,
    5,
    'custom',
    ARRAY['hyrox_race', 'improve_endurance', 'functional_strength', 'home_training'],
    'home',
    '#FFD700',
    true,
    false,
    false,
    ARRAY['dumbbells', 'resistance_bands', 'jump_rope', 'pull_up_bar'],
    'hyrox',
    '{
        "program_type": "hyrox_home",
        "supports_race_date": true,
        "is_home_version": true,
        "duration_tiers": {
            "quick_prep": {"min_weeks": 8, "max_weeks": 10, "phases": ["build", "race"]},
            "standard": {"min_weeks": 12, "max_weeks": 16, "phases": ["build", "race"]},
            "full_prep": {"min_weeks": 20, "max_weeks": 24, "phases": ["blueprint", "build", "race"]},
            "elite_cycle": {"min_weeks": 24, "max_weeks": 52, "phases": ["blueprint", "build", "race"]}
        },
        "divisions": {
            "open_women": {"dumbbell_kg": 8, "band_resistance": "light"},
            "open_men": {"dumbbell_kg": 12, "band_resistance": "medium"},
            "pro_women": {"dumbbell_kg": 12, "band_resistance": "medium"},
            "pro_men": {"dumbbell_kg": 16, "band_resistance": "heavy"}
        },
        "substitute_mapping": {
            "hyrox_skierg": {
                "home_exercise": "hyrox_battle_ropes",
                "alt_exercise": "dumbbell_pullover",
                "scaling": "3 min battle ropes = 1000m skierg"
            },
            "hyrox_sled_push": {
                "home_exercise": "hyrox_banded_bear_crawl",
                "alt_exercise": "walking_lunges_weighted",
                "scaling": "50 weighted lunges = 50m sled push"
            },
            "hyrox_sled_pull": {
                "home_exercise": "hyrox_band_rows_high_rep",
                "alt_exercise": "bent_over_row",
                "scaling": "100 band rows = 50m sled pull"
            },
            "hyrox_farmers_carry": {
                "home_exercise": "dumbbell_farmers_walk",
                "scaling": "Same distance, adjust weight"
            },
            "hyrox_sandbag_lunges": {
                "home_exercise": "goblet_walking_lunges",
                "scaling": "Same distance, use dumbbell at chest"
            },
            "hyrox_wall_balls": {
                "home_exercise": "hyrox_dumbbell_thrusters",
                "scaling": "100 thrusters = 100 wall balls"
            }
        },
        "stations_home": [
            {"order": 1, "exercise_id": "hyrox_battle_ropes", "target": "3min", "type": "time"},
            {"order": 2, "exercise_id": "hyrox_banded_bear_crawl", "target": "50m", "type": "distance"},
            {"order": 3, "exercise_id": "hyrox_band_rows_high_rep", "target": "100", "type": "reps"},
            {"order": 4, "exercise_id": "hyrox_burpee_broad_jump", "target": "80m", "type": "distance"},
            {"order": 5, "exercise_id": "rowing", "target": "1000m", "type": "distance", "note": "or 5min jump rope"},
            {"order": 6, "exercise_id": "dumbbell_farmers_walk", "target": "200m", "type": "distance"},
            {"order": 7, "exercise_id": "goblet_walking_lunges", "target": "100m", "type": "distance"},
            {"order": 8, "exercise_id": "hyrox_dumbbell_thrusters", "target": "100", "type": "reps"}
        ],
        "phases": {
            "blueprint": {
                "focus": "Build aerobic base, general strength, movement quality",
                "duration_weeks_options": [8, 12, 16],
                "sessions_per_week": 4,
                "weekly_template": {
                    "day_1": {"name": "Compound Strength", "focus": "goblet squats, RDLs, push-ups", "rep_range": "8-15"},
                    "day_2": {"name": "Zone 2 Running/Cycling", "focus": "65-75% max HR", "duration_min": 30},
                    "day_3": {"name": "Upper Body + Core", "focus": "rows, band work"},
                    "day_4": {"name": "Easy Cardio", "focus": "recovery pace", "duration_min": 30}
                }
            },
            "build": {
                "focus": "Race-specific fitness, hybrid workouts, brick runs",
                "duration_weeks_options": [8, 10, 12],
                "sessions_per_week": 5,
                "weekly_template": {
                    "day_1": {"name": "Push Circuit + Brick", "exercises": ["battle_ropes", "bear_crawl", "thrusters"], "brick_run_km": 1},
                    "day_2": {"name": "Running Intervals", "sets": "3-8", "distance_km": 1, "intensity": "race_pace"},
                    "day_3": {"name": "Pull Circuit + Brick", "exercises": ["band_rows", "farmers_walk"], "brick_run_km": 1},
                    "day_4": {"name": "Tempo Run", "duration_min": 45, "intensity": "threshold"},
                    "day_5": {"name": "Half HYROX Simulation (Home)", "stations": 4, "running_km": 4}
                }
            },
            "race": {
                "focus": "Peak performance, full simulations, tactical execution",
                "duration_weeks_options": [4, 6, 8],
                "sessions_per_week": 5,
                "weekly_template": {
                    "day_1": {"name": "Full HYROX Simulation (Home)", "intensity_percent": 85},
                    "day_2": {"name": "1km Pace Runs", "sets": "4-6", "intensity": "race_pace"},
                    "day_3": {"name": "Station Speed Work", "focus": "fast transitions"},
                    "day_4": {"name": "Partial Simulation", "stations": 4, "running_km": 4},
                    "day_5": {"name": "Strength Maintenance", "volume": "reduced"}
                },
                "taper_week": {
                    "volume_reduction_percent": 50,
                    "focus": "technique, sleep, visualization"
                }
            },
            "restore": {
                "focus": "Recovery, injury prevention, next cycle preparation",
                "duration_weeks": 4,
                "sessions_per_week": 3,
                "structure": {
                    "week_1": "Complete rest",
                    "weeks_2_3": "Light activity at 50-60% max HR",
                    "week_4": "Gradual return at 25% peak volume"
                }
            }
        },
        "target_times": {
            "elite_men": {"min": 53, "max": 59, "unit": "minutes"},
            "elite_women": {"min": 58, "max": 65, "unit": "minutes"},
            "competitive": {"min": 60, "max": 75, "unit": "minutes"},
            "finish": {"min": 75, "max": 120, "unit": "minutes"}
        }
    }'::jsonb
)
ON CONFLICT (name) DO UPDATE SET
    tagline = EXCLUDED.tagline,
    description = EXCLUDED.description,
    program_type = EXCLUDED.program_type,
    program_metadata = EXCLUDED.program_metadata,
    updated_at = NOW();

-- ============================================================================
-- STEP 5: CREATE HELPER FUNCTIONS FOR HYROX PROGRAMS
-- ============================================================================

-- Function to calculate recommended program tier based on race date
CREATE OR REPLACE FUNCTION get_hyrox_program_tier(p_race_date DATE)
RETURNS TABLE (
    tier_name TEXT,
    weeks_available INTEGER,
    phases TEXT[],
    recommended BOOLEAN
) AS $$
DECLARE
    v_weeks INTEGER;
BEGIN
    v_weeks := EXTRACT(DAY FROM (p_race_date - CURRENT_DATE)) / 7;

    RETURN QUERY
    SELECT
        CASE
            WHEN v_weeks < 8 THEN 'too_short'
            WHEN v_weeks BETWEEN 8 AND 10 THEN 'quick_prep'
            WHEN v_weeks BETWEEN 11 AND 16 THEN 'standard'
            WHEN v_weeks BETWEEN 17 AND 24 THEN 'full_prep'
            ELSE 'elite_cycle'
        END::TEXT AS tier_name,
        v_weeks AS weeks_available,
        CASE
            WHEN v_weeks < 8 THEN ARRAY['insufficient_time']
            WHEN v_weeks BETWEEN 8 AND 10 THEN ARRAY['build', 'race']
            WHEN v_weeks BETWEEN 11 AND 16 THEN ARRAY['build', 'race']
            WHEN v_weeks BETWEEN 17 AND 24 THEN ARRAY['blueprint', 'build', 'race']
            ELSE ARRAY['blueprint', 'build', 'race']
        END AS phases,
        CASE
            WHEN v_weeks BETWEEN 17 AND 24 THEN true
            ELSE false
        END AS recommended;
END;
$$ LANGUAGE plpgsql;

-- Function to get division weights for a user
CREATE OR REPLACE FUNCTION get_hyrox_division_weights(p_division TEXT)
RETURNS JSONB AS $$
BEGIN
    RETURN CASE p_division
        WHEN 'open_women' THEN '{
            "sled_push_kg": 102, "sled_pull_kg": 78,
            "farmers_carry_kg": 16, "sandbag_kg": 10, "wall_ball_kg": 4
        }'::jsonb
        WHEN 'open_men' THEN '{
            "sled_push_kg": 152, "sled_pull_kg": 103,
            "farmers_carry_kg": 24, "sandbag_kg": 20, "wall_ball_kg": 6
        }'::jsonb
        WHEN 'pro_women' THEN '{
            "sled_push_kg": 152, "sled_pull_kg": 103,
            "farmers_carry_kg": 24, "sandbag_kg": 20, "wall_ball_kg": 6
        }'::jsonb
        WHEN 'pro_men' THEN '{
            "sled_push_kg": 152, "sled_pull_kg": 153,
            "farmers_carry_kg": 32, "sandbag_kg": 30, "wall_ball_kg": 9
        }'::jsonb
        ELSE '{}'::jsonb
    END;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_hyrox_program_tier(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_hyrox_division_weights(TEXT) TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON COLUMN branded_programs.program_type IS 'Type of program: standard, hyrox, custom';
COMMENT ON COLUMN branded_programs.program_metadata IS 'JSONB containing phase templates, division configs, stations for specialized programs';
COMMENT ON COLUMN user_program_assignments.target_race_date IS 'Target race date for HYROX programs';
COMMENT ON COLUMN user_program_assignments.division IS 'HYROX division: open_women, open_men, pro_women, pro_men';
COMMENT ON COLUMN user_program_assignments.current_phase IS 'Current training phase: blueprint, build, race, restore';

COMMENT ON FUNCTION get_hyrox_program_tier IS 'Returns recommended program tier based on weeks until race date';
COMMENT ON FUNCTION get_hyrox_division_weights IS 'Returns official HYROX weights for a given division';
