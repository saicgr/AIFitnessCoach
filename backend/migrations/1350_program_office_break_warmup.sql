-- Program: Office Break Warmup
-- Category: Warmup & Cooldown -> warmup_cooldown
-- Priority: High
-- Durations: [1, 2], Sessions: [7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Office Break Warmup',
    'Quick desk-break mobility to fight sitting stiffness',
    'warmup_cooldown',
    'all_levels',
    2,
    7,
    'flow',
    ARRAY['Improve flexibility', 'Enhance body awareness']::text[],
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

-- Variant: Office Break Warmup - 1w 7x/wk
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
    'Office Break Warmup - 1w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Office Break Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}]'::jsonb,
    'Office Break Warmup',
    'Office Break Warmup - 1w 7x/wk',
    'High',
    false,
    'Quick desk-break mobility to fight sitting stiffness',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Office Break Warmup'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Office Break Warmup - 2w 7x/wk
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
    'Office Break Warmup - 2w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Office Break Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}]'::jsonb,
    'Office Break Warmup',
    'Office Break Warmup - 2w 7x/wk',
    'High',
    false,
    'Quick desk-break mobility to fight sitting stiffness',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Office Break Warmup'
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
    'Week 2 - Peak: full routine mastery, self-directed',
    '[{"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}, {"workout_name": "Office Break Warmup", "type": "warmup", "duration_minutes": 5, "exercises": [{"name": "Seated Neck Rolls", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 8, "rest_seconds": 0, "weight_guidance": "Each direction", "equipment": "Bodyweight", "body_part": "Neck", "primary_muscle": "Trapezius", "secondary_muscles": ["Scalenes"], "difficulty": "beginner", "form_cue": "Slow circles, ear to shoulder, chin to chest", "substitution": "Neck Side Stretch"}, {"name": "Shoulder Shrugs", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Up and release", "equipment": "Bodyweight", "body_part": "Shoulders", "primary_muscle": "Trapezius", "secondary_muscles": ["Levator Scapulae"], "difficulty": "beginner", "form_cue": "Shrug to ears, hold 2 seconds, drop", "substitution": "Shoulder Rolls"}, {"name": "Seated Spinal Twist", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "15 seconds each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Obliques", "secondary_muscles": ["Erector Spinae"], "difficulty": "beginner", "form_cue": "Sit tall, rotate from mid-back", "substitution": "Standing Twist"}, {"name": "Standing Chest Opener", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 20 seconds", "equipment": "Bodyweight", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "beginner", "form_cue": "Clasp hands behind back, open chest", "substitution": "Doorway Stretch"}, {"name": "Standing Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Quick pump", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range up on toes, quick tempo", "substitution": "Heel Walks"}]}]'::jsonb,
    'Office Break Warmup',
    'Office Break Warmup - 2w 7x/wk',
    'High',
    false,
    'Quick desk-break mobility to fight sitting stiffness',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Office Break Warmup'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
