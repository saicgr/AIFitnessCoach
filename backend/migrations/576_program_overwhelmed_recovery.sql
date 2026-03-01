-- Program: Overwhelmed Recovery
-- Category: Mood & Emotion Based -> mood_based
-- Priority: Med
-- Durations: [1, 2], Sessions: [3, 4]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Overwhelmed Recovery',
    'Reset your nervous system when everything feels like too much',
    'mood_based',
    'all_levels',
    2,
    4,
    'custom',
    ARRAY['Promote active recovery', 'Reduce injury risk']::text[],
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

-- Variant: Overwhelmed Recovery - 1w 3x/wk
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
    'Overwhelmed Recovery - 1w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Overwhelmed Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 1w 3x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Overwhelmed Recovery - 1w 4x/wk
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
    'Overwhelmed Recovery - 1w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Overwhelmed Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 1w 4x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Overwhelmed Recovery - 2w 3x/wk
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
    'Overwhelmed Recovery - 2w 3x/wk',
    'mood_based',
    3,
    60,
    ARRAY['Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Overwhelmed Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 2w 3x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 2w 3x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Overwhelmed Recovery - 2w 4x/wk
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
    'Overwhelmed Recovery - 2w 4x/wk',
    'mood_based',
    4,
    60,
    ARRAY['Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Overwhelmed Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 2w 4x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
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
    'Week 2 - Peak: challenge yourself and test limits',
    '[{"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}, {"workout_name": "Self-Care Movement", "type": "flexibility", "duration_minutes": 25, "exercises": [{"name": "Gentle Neck Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 5, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Slow circles, release neck tension", "substitution": "Neck Stretch"}, {"name": "Shoulder Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Forward and backward", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Deltoids"], "difficulty": "beginner", "form_cue": "Big circles, release shoulder tension", "substitution": "Arm Circle"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Very slow, eyes closed", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, feel each vertebra", "substitution": "Seated Cat-Cow"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Fold forward, breathe into stretch", "substitution": "Figure-4 Stretch"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 90 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Complete surrender, breathe deeply", "substitution": "Puppy Pose"}, {"name": "Savasana", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "5 minutes", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Complete stillness, body scan meditation", "substitution": "Seated Meditation"}]}, {"workout_name": "Calming Movement", "type": "flexibility", "duration_minutes": 30, "exercises": [{"name": "Diaphragmatic Breathing", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 0, "weight_guidance": "Deep belly breaths", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Diaphragm", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "beginner", "form_cue": "4 count inhale, 6 count exhale, hand on belly", "substitution": "Box Breathing"}, {"name": "Cat-Cow", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Slow, rhythmic", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Core"], "difficulty": "beginner", "form_cue": "Sync with breath, close eyes", "substitution": "Seated Cat-Cow"}, {"name": "Child''s Pose", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60 seconds", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Shoulders", "Hips"], "difficulty": "beginner", "form_cue": "Wide knees, reach forward, breathe deep", "substitution": "Puppy Pose"}, {"name": "Supine Twist", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Lower Back", "Glutes"], "difficulty": "beginner", "form_cue": "Let gravity pull knees, relax fully", "substitution": "Seated Twist"}, {"name": "Gentle Walking", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "10 minutes mindful pace", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Focus on each step, breathe naturally", "substitution": "Marching in Place"}, {"name": "Standing Forward Fold", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Lower Back"], "difficulty": "beginner", "form_cue": "Let head hang heavy, shake head yes/no", "substitution": "Seated Forward Fold"}]}]'::jsonb,
    'Overwhelmed Recovery',
    'Overwhelmed Recovery - 2w 4x/wk',
    'Med',
    false,
    'Reset your nervous system when everything feels like too much',
    'Mood & Emotion Based'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Overwhelmed Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;
