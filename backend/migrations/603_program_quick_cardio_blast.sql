-- Program: Quick Cardio Blast
-- Category: Quick Workouts -> quick_workout
-- Priority: Low
-- Durations: [1, 2], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Quick Cardio Blast',
    '10-minute heart-pumping cardio session for when time is tight',
    'quick_workout',
    'all_levels',
    2,
    5,
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

-- Variant: Quick Cardio Blast - 1w 4x/wk
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
    1,
    'Quick Cardio Blast - 1w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Quick Cardio Blast'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 1w 4x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Quick Cardio Blast - 1w 5x/wk
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
    1,
    'Quick Cardio Blast - 1w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Quick Cardio Blast'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 1w 5x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Quick Cardio Blast - 2w 4x/wk
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
    2,
    'Quick Cardio Blast - 2w 4x/wk',
    'quick_workout',
    4,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Quick Cardio Blast'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 2w 4x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 2w 4x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Quick Cardio Blast - 2w 5x/wk
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
    2,
    'Quick Cardio Blast - 2w 5x/wk',
    'quick_workout',
    5,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Quick Cardio Blast'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progress: faster pace, less rest, more reps',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 2w 5x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Push: maximum effort, beat your personal best',
    '[{"workout_name": "Quick Cardio Blast", "type": "hiit", "duration_minutes": 10, "exercises": [{"name": "Jumping Jack", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Full range, quick pace", "substitution": "Step Jack"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Sprint in place, max effort", "substitution": "March in Place"}, {"name": "Burpee", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 8, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Chest", "Core"], "difficulty": "intermediate", "form_cue": "Keep moving, no rest at bottom", "substitution": "Squat Thrust"}, {"name": "Mountain Climber", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Fast feet, drive knees", "substitution": "Plank March"}, {"name": "Squat Jump", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 15, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up each rep", "substitution": "Bodyweight Squat"}]}]'::jsonb,
    'Quick Cardio Blast',
    'Quick Cardio Blast - 2w 5x/wk',
    'Low',
    false,
    '10-minute heart-pumping cardio session for when time is tight',
    'Quick Workouts'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Quick Cardio Blast'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
