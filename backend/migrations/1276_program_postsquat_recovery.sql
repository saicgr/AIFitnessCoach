-- Program: Post-Squat Recovery
-- Category: Lift Mobility -> mobility
-- Priority: Med
-- Durations: [1, 2], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Squat Recovery',
    'Recovery mobility work after squats for quads, hips, and IT band',
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

-- Variant: Post-Squat Recovery - 1w 3x/wk
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
    'Post-Squat Recovery - 1w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Squat Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build',
    '[{"workout_name": "Post-Squat Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll IT Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "IT Band", "secondary_muscles": ["Vastus Lateralis"], "difficulty": "beginner", "form_cue": "Roll from hip to just above knee", "substitution": "Lacrosse Ball TFL"}, {"name": "Couch Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Rectus Femoris"], "difficulty": "beginner", "form_cue": "Rear knee against wall, squeeze glute of back leg", "substitution": "Half Kneeling Hip Flexor Stretch"}, {"name": "Seated Adductor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Sit tall, soles together, press knees toward floor", "substitution": "Standing Adductor Stretch"}, {"name": "Quad Foam Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Slow rolls, pause on tight spots", "substitution": "Lacrosse Ball Quad"}, {"name": "Standing Calf Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Heel pressed down, lean into wall", "substitution": "Step Calf Stretch"}, {"name": "Supine Knee to Chest", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Pull one knee to chest, keep other leg flat", "substitution": "Double Knee to Chest"}]}]'::jsonb,
    'Post-Squat Recovery',
    'Post-Squat Recovery - 1w 3x/wk',
    'Med',
    false,
    'Recovery mobility work after squats for quads, hips, and IT band',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Squat Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Post-Squat Recovery - 2w 3x/wk
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
    'Post-Squat Recovery - 2w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Improve flexibility', 'Enhance body awareness', 'Promote active recovery']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Squat Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build',
    '[{"workout_name": "Post-Squat Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll IT Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "IT Band", "secondary_muscles": ["Vastus Lateralis"], "difficulty": "beginner", "form_cue": "Roll from hip to just above knee", "substitution": "Lacrosse Ball TFL"}, {"name": "Couch Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Rectus Femoris"], "difficulty": "beginner", "form_cue": "Rear knee against wall, squeeze glute of back leg", "substitution": "Half Kneeling Hip Flexor Stretch"}, {"name": "Seated Adductor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Sit tall, soles together, press knees toward floor", "substitution": "Standing Adductor Stretch"}, {"name": "Quad Foam Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Slow rolls, pause on tight spots", "substitution": "Lacrosse Ball Quad"}, {"name": "Standing Calf Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Heel pressed down, lean into wall", "substitution": "Step Calf Stretch"}, {"name": "Supine Knee to Chest", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Pull one knee to chest, keep other leg flat", "substitution": "Double Knee to Chest"}]}, {"workout_name": "Post-Squat Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll IT Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "IT Band", "secondary_muscles": ["Vastus Lateralis"], "difficulty": "beginner", "form_cue": "Roll from hip to just above knee", "substitution": "Lacrosse Ball TFL"}, {"name": "Couch Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Rectus Femoris"], "difficulty": "beginner", "form_cue": "Rear knee against wall, squeeze glute of back leg", "substitution": "Half Kneeling Hip Flexor Stretch"}, {"name": "Seated Adductor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Sit tall, soles together, press knees toward floor", "substitution": "Standing Adductor Stretch"}, {"name": "Quad Foam Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Slow rolls, pause on tight spots", "substitution": "Lacrosse Ball Quad"}, {"name": "Standing Calf Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Heel pressed down, lean into wall", "substitution": "Step Calf Stretch"}, {"name": "Supine Knee to Chest", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Pull one knee to chest, keep other leg flat", "substitution": "Double Knee to Chest"}]}]'::jsonb,
    'Post-Squat Recovery',
    'Post-Squat Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery mobility work after squats for quads, hips, and IT band',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Squat Recovery'
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
    '[{"workout_name": "Post-Squat Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll IT Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "IT Band", "secondary_muscles": ["Vastus Lateralis"], "difficulty": "beginner", "form_cue": "Roll from hip to just above knee", "substitution": "Lacrosse Ball TFL"}, {"name": "Couch Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Rectus Femoris"], "difficulty": "beginner", "form_cue": "Rear knee against wall, squeeze glute of back leg", "substitution": "Half Kneeling Hip Flexor Stretch"}, {"name": "Seated Adductor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Sit tall, soles together, press knees toward floor", "substitution": "Standing Adductor Stretch"}, {"name": "Quad Foam Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Slow rolls, pause on tight spots", "substitution": "Lacrosse Ball Quad"}, {"name": "Standing Calf Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Heel pressed down, lean into wall", "substitution": "Step Calf Stretch"}, {"name": "Supine Knee to Chest", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Pull one knee to chest, keep other leg flat", "substitution": "Double Knee to Chest"}]}, {"workout_name": "Post-Squat Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll IT Band", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "IT Band", "secondary_muscles": ["Vastus Lateralis"], "difficulty": "beginner", "form_cue": "Roll from hip to just above knee", "substitution": "Lacrosse Ball TFL"}, {"name": "Couch Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Rectus Femoris"], "difficulty": "beginner", "form_cue": "Rear knee against wall, squeeze glute of back leg", "substitution": "Half Kneeling Hip Flexor Stretch"}, {"name": "Seated Adductor Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Sit tall, soles together, press knees toward floor", "substitution": "Standing Adductor Stretch"}, {"name": "Quad Foam Roll", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Slow rolls, pause on tight spots", "substitution": "Lacrosse Ball Quad"}, {"name": "Standing Calf Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Heel pressed down, lean into wall", "substitution": "Step Calf Stretch"}, {"name": "Supine Knee to Chest", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 30s each side", "equipment": "Bodyweight", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Pull one knee to chest, keep other leg flat", "substitution": "Double Knee to Chest"}]}]'::jsonb,
    'Post-Squat Recovery',
    'Post-Squat Recovery - 2w 3x/wk',
    'Med',
    false,
    'Recovery mobility work after squats for quads, hips, and IT band',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Squat Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
