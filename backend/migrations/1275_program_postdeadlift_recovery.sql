-- Program: Post-Deadlift Recovery
-- Category: Lift Mobility -> mobility
-- Priority: Med
-- Durations: [1, 2], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Deadlift Recovery',
    'Recovery work after deadlifts targeting lower back, glutes, and hamstrings',
    'mobility',
    'all_levels',
    2,
    3,
    'flow',
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
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

-- Variant: Post-Deadlift Recovery - 1w 3x/wk
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
    'Post-Deadlift Recovery - 1w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Deadlift Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build',
    '[{"workout_name": "Post-Deadlift Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lower Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Gentle pressure", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Quadratus Lumborum"], "difficulty": "beginner", "form_cue": "Roll around lower back, avoid direct spine pressure", "substitution": "Lacrosse Ball Glute Release"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, sink hips back", "substitution": "Puppy Pose"}, {"name": "Supine Figure-4 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Gluteus Medius"], "difficulty": "beginner", "form_cue": "Cross ankle over knee, pull bottom knee to chest", "substitution": "Seated Piriformis Stretch"}, {"name": "Lying Hamstring Stretch with Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Leg straight up, use band to pull gently", "substitution": "Standing Hamstring Stretch"}, {"name": "Crocodile Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Deep breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Prone position, breathe into belly against floor", "substitution": "Supine Diaphragmatic Breathing"}, {"name": "Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Supine, knees to one side, arms opposite", "substitution": "Seated Spinal Twist"}]}]'::jsonb,
    'Post-Deadlift Recovery',
    'Post-Deadlift Recovery - 1w 3x/wk',
    'Med',
    false,
    'Recovery work after deadlifts targeting lower back, glutes, and hamstrings',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Deadlift Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Post-Deadlift Recovery - 2w 3x/wk
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
    'Post-Deadlift Recovery - 2w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Deadlift Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build',
    '[{"workout_name": "Post-Deadlift Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lower Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Gentle pressure", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Quadratus Lumborum"], "difficulty": "beginner", "form_cue": "Roll around lower back, avoid direct spine pressure", "substitution": "Lacrosse Ball Glute Release"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, sink hips back", "substitution": "Puppy Pose"}, {"name": "Supine Figure-4 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Gluteus Medius"], "difficulty": "beginner", "form_cue": "Cross ankle over knee, pull bottom knee to chest", "substitution": "Seated Piriformis Stretch"}, {"name": "Lying Hamstring Stretch with Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Leg straight up, use band to pull gently", "substitution": "Standing Hamstring Stretch"}, {"name": "Crocodile Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Deep breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Prone position, breathe into belly against floor", "substitution": "Supine Diaphragmatic Breathing"}, {"name": "Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Supine, knees to one side, arms opposite", "substitution": "Seated Spinal Twist"}]}, {"workout_name": "Post-Deadlift Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lower Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Gentle pressure", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Quadratus Lumborum"], "difficulty": "beginner", "form_cue": "Roll around lower back, avoid direct spine pressure", "substitution": "Lacrosse Ball Glute Release"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, sink hips back", "substitution": "Puppy Pose"}, {"name": "Supine Figure-4 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Gluteus Medius"], "difficulty": "beginner", "form_cue": "Cross ankle over knee, pull bottom knee to chest", "substitution": "Seated Piriformis Stretch"}, {"name": "Lying Hamstring Stretch with Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Leg straight up, use band to pull gently", "substitution": "Standing Hamstring Stretch"}, {"name": "Crocodile Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Deep breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Prone position, breathe into belly against floor", "substitution": "Supine Diaphragmatic Breathing"}, {"name": "Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Supine, knees to one side, arms opposite", "substitution": "Seated Spinal Twist"}]}]'::jsonb,
    'Post-Deadlift Recovery',
    'Post-Deadlift Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after deadlifts targeting lower back, glutes, and hamstrings',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Deadlift Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Test/Maintenance',
    'Week 2 - Peak',
    '[{"workout_name": "Post-Deadlift Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lower Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Gentle pressure", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Quadratus Lumborum"], "difficulty": "beginner", "form_cue": "Roll around lower back, avoid direct spine pressure", "substitution": "Lacrosse Ball Glute Release"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, sink hips back", "substitution": "Puppy Pose"}, {"name": "Supine Figure-4 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Gluteus Medius"], "difficulty": "beginner", "form_cue": "Cross ankle over knee, pull bottom knee to chest", "substitution": "Seated Piriformis Stretch"}, {"name": "Lying Hamstring Stretch with Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Leg straight up, use band to pull gently", "substitution": "Standing Hamstring Stretch"}, {"name": "Crocodile Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Deep breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Prone position, breathe into belly against floor", "substitution": "Supine Diaphragmatic Breathing"}, {"name": "Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Supine, knees to one side, arms opposite", "substitution": "Seated Spinal Twist"}]}, {"workout_name": "Post-Deadlift Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Lower Back", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Gentle pressure", "equipment": "Foam Roller", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Quadratus Lumborum"], "difficulty": "beginner", "form_cue": "Roll around lower back, avoid direct spine pressure", "substitution": "Lacrosse Ball Glute Release"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Knees wide, reach arms forward, sink hips back", "substitution": "Puppy Pose"}, {"name": "Supine Figure-4 Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Piriformis", "secondary_muscles": ["Gluteus Medius"], "difficulty": "beginner", "form_cue": "Cross ankle over knee, pull bottom knee to chest", "substitution": "Seated Piriformis Stretch"}, {"name": "Lying Hamstring Stretch with Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Leg straight up, use band to pull gently", "substitution": "Standing Hamstring Stretch"}, {"name": "Crocodile Breathing", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Deep breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "Prone position, breathe into belly against floor", "substitution": "Supine Diaphragmatic Breathing"}, {"name": "Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Supine, knees to one side, arms opposite", "substitution": "Seated Spinal Twist"}]}]'::jsonb,
    'Post-Deadlift Recovery',
    'Post-Deadlift Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery work after deadlifts targeting lower back, glutes, and hamstrings',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Deadlift Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
