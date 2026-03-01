-- Program: Navy SEAL Inspired
-- Category: Hell Mode -> hell_mode
-- Priority: High
-- Durations: [1, 2], Sessions: [6, 7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Navy SEAL Inspired',
    'Military-grade calisthenics and endurance training',
    'hell_mode',
    'advanced',
    2,
    7,
    'custom',
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max', 'Build functional strength', 'Improve body control']::text[],
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

-- Variant: Navy SEAL Inspired - 1w 6x/wk
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
    'Navy SEAL Inspired - 1w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Navy SEAL Inspired'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 1w 6x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: Navy SEAL Inspired - 1w 7x/wk
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
    'Navy SEAL Inspired - 1w 7x/wk',
    'hell_mode',
    7,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Navy SEAL Inspired'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 1w 7x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Navy SEAL Inspired - 2w 6x/wk
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
    'Navy SEAL Inspired - 2w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Navy SEAL Inspired'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 2w 6x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Conquer: break through mental and physical barriers',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 2w 6x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: Navy SEAL Inspired - 2w 7x/wk
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
    'Navy SEAL Inspired - 2w 7x/wk',
    'hell_mode',
    7,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Navy SEAL Inspired'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 2w 7x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Conquer: break through mental and physical barriers',
    '[{"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}, {"workout_name": "Navy SEAL Inspired", "type": "hell_mode", "duration_minutes": 60, "exercises": [{"name": "Push-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 30, "weight_guidance": "150 total, no excuses", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "advanced", "form_cue": "Perfect form, chest to floor every rep, grind", "substitution": "Knee Push-Up"}, {"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "75 total", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Dead hang start, chin over bar, no kipping", "substitution": "Band-Assisted Pull-Up"}, {"name": "Sit-Up", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 30, "rest_seconds": 20, "weight_guidance": "150 total", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "advanced", "form_cue": "Full range, touch toes, shoulder blades to floor", "substitution": "Crunch"}, {"name": "Air Squat", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 40, "rest_seconds": 30, "weight_guidance": "200 total", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel every rep, full depth", "substitution": "Half Squat"}, {"name": "Flutter Kick", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 50, "rest_seconds": 20, "weight_guidance": "25 each leg per set", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "advanced", "form_cue": "Hands under glutes, legs 6 inches off ground, kick", "substitution": "Lying Leg Raise"}, {"name": "Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "1.5 mile run to finish", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Max effort 1.5 mile run, push the pace", "substitution": "Jog"}]}]'::jsonb,
    'Navy SEAL Inspired',
    'Navy SEAL Inspired - 2w 7x/wk',
    'High',
    false,
    'Military-grade calisthenics and endurance training',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Navy SEAL Inspired'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
