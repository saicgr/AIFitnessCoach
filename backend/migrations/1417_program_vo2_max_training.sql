-- Program: VO2 Max Training
-- Category: Longevity & Biohacking -> longevity
-- Priority: Low
-- Durations: [4, 8, 12], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'VO2 Max Training',
    'Cardiovascular longevity through high-intensity intervals',
    'longevity',
    'all_levels',
    12,
    4,
    'custom',
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    true,
    true
) ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty_level = EXCLUDED.difficulty_level,
    duration_weeks = EXCLUDED.duration_weeks,
    sessions_per_week = EXCLUDED.sessions_per_week,
    split_type = EXCLUDED.split_type,
    goals = EXCLUDED.goals,
    requires_gym = EXCLUDED.requires_gym,
    updated_at = NOW();

-- Variant: VO2 Max Training - 4w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    4,
    'VO2 Max Training - 4w 3x/wk',
    'longevity',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: VO2 Max Training - 4w 4x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    4,
    'VO2 Max Training - 4w 4x/wk',
    'longevity',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 4w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: VO2 Max Training - 8w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    8,
    'VO2 Max Training - 8w 3x/wk',
    'longevity',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: VO2 Max Training - 8w 4x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    8,
    'VO2 Max Training - 8w 4x/wk',
    'longevity',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 8w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: VO2 Max Training - 12w 3x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    12,
    'VO2 Max Training - 12w 3x/wk',
    'longevity',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Foundation (Base Building)',
    'Week 3 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Build (Progressive Overload)',
    'Week 5 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Build (Progressive Overload)',
    'Week 6 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Peak (Intensification)',
    'Week 7 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Peak (Intensification)',
    'Week 8 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Peak (Intensification)',
    'Week 9 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    10,
    'Taper (Deload)',
    'Week 10 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    11,
    'Test/Maintenance',
    'Week 11 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    12,
    'Test/Maintenance',
    'Week 12 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 3x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: VO2 Max Training - 12w 4x/wk
INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    'Medium',
    12,
    'VO2 Max Training - 12w 4x/wk',
    'longevity',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'VO2 Max Training'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Foundation (Base Building)',
    'Week 3 - Foundation: establish baseline and learn protocols',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Build (Progressive Overload)',
    'Week 5 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Build (Progressive Overload)',
    'Week 6 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Peak (Intensification)',
    'Week 7 - Optimization: refine protocols and increase stimulus',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Peak (Intensification)',
    'Week 8 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Peak (Intensification)',
    'Week 9 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    10,
    'Taper (Deload)',
    'Week 10 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    11,
    'Test/Maintenance',
    'Week 11 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    12,
    'Test/Maintenance',
    'Week 12 - Integration: combine protocols for peak health outcomes',
    '[{"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}, {"workout_name": "VO2 Max Training", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "4x4 Interval", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 180, "weight_guidance": "4 min at 90-95% max HR", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Run or row at near-max effort for 4 minutes, rest 3 min", "substitution": "High Intensity Bike"}, {"name": "Tabata Sprint", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 10, "weight_guidance": "20 sec max, 10 sec rest", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "advanced", "form_cue": "All-out sprint for 20 seconds, 10 seconds rest x4", "substitution": "Burpee"}, {"name": "Cool Down Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Easy walking to bring heart rate down", "substitution": "Standing Rest"}]}]'::jsonb,
    'VO2 Max Training',
    'VO2 Max Training - 12w 4x/wk',
    'Low',
    false,
    'Cardiovascular longevity through high-intensity intervals',
    'Longevity & Biohacking'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'VO2 Max Training'
  AND pv.duration_weeks = 12
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
