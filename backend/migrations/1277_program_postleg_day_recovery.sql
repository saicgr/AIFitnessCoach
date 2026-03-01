-- Program: Post-Leg Day Recovery
-- Category: Lift Mobility -> mobility
-- Priority: Med
-- Durations: [1, 2], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Leg Day Recovery',
    'Comprehensive leg day recovery with foam rolling, stretching, and PNF',
    'mobility',
    'all_levels',
    2,
    3,
    'flow',
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
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

-- Variant: Post-Leg Day Recovery - 1w 3x/wk
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
    'Post-Leg Day Recovery - 1w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Leg Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build',
    '[{"workout_name": "Post-Leg Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Glutes", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Sit on roller, cross ankle over knee, roll glute", "substitution": "Lacrosse Ball Glute"}, {"name": "Standing Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Prone Quad Stretch"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Hamstring PNF Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 3, "rest_seconds": 0, "weight_guidance": "Contract-relax each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Contract 5s against resistance, relax and deepen", "substitution": "Passive Hamstring Stretch"}, {"name": "Ankle Circle", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range of motion circles", "substitution": "Ankle Pump"}, {"name": "Legs Up the Wall", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 2 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Scoot close to wall, legs vertical, relax", "substitution": "Elevated Leg Rest"}]}]'::jsonb,
    'Post-Leg Day Recovery',
    'Post-Leg Day Recovery - 1w 3x/wk',
    'Med',
    false,
    'Comprehensive leg day recovery with foam rolling, stretching, and PNF',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Leg Day Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

-- Variant: Post-Leg Day Recovery - 2w 3x/wk
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
    'Post-Leg Day Recovery - 2w 3x/wk',
    'mobility',
    3,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Leg Day Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build',
    '[{"workout_name": "Post-Leg Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Glutes", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Sit on roller, cross ankle over knee, roll glute", "substitution": "Lacrosse Ball Glute"}, {"name": "Standing Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Prone Quad Stretch"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Hamstring PNF Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 3, "rest_seconds": 0, "weight_guidance": "Contract-relax each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Contract 5s against resistance, relax and deepen", "substitution": "Passive Hamstring Stretch"}, {"name": "Ankle Circle", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range of motion circles", "substitution": "Ankle Pump"}, {"name": "Legs Up the Wall", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 2 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Scoot close to wall, legs vertical, relax", "substitution": "Elevated Leg Rest"}]}, {"workout_name": "Post-Leg Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Glutes", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Sit on roller, cross ankle over knee, roll glute", "substitution": "Lacrosse Ball Glute"}, {"name": "Standing Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Prone Quad Stretch"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Hamstring PNF Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 3, "rest_seconds": 0, "weight_guidance": "Contract-relax each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Contract 5s against resistance, relax and deepen", "substitution": "Passive Hamstring Stretch"}, {"name": "Ankle Circle", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range of motion circles", "substitution": "Ankle Pump"}, {"name": "Legs Up the Wall", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 2 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Scoot close to wall, legs vertical, relax", "substitution": "Elevated Leg Rest"}]}]'::jsonb,
    'Post-Leg Day Recovery',
    'Post-Leg Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Comprehensive leg day recovery with foam rolling, stretching, and PNF',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Leg Day Recovery'
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
    '[{"workout_name": "Post-Leg Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Glutes", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Sit on roller, cross ankle over knee, roll glute", "substitution": "Lacrosse Ball Glute"}, {"name": "Standing Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Prone Quad Stretch"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Hamstring PNF Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 3, "rest_seconds": 0, "weight_guidance": "Contract-relax each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Contract 5s against resistance, relax and deepen", "substitution": "Passive Hamstring Stretch"}, {"name": "Ankle Circle", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range of motion circles", "substitution": "Ankle Pump"}, {"name": "Legs Up the Wall", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 2 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Scoot close to wall, legs vertical, relax", "substitution": "Elevated Leg Rest"}]}, {"workout_name": "Post-Leg Day Recovery", "type": "flexibility", "duration_minutes": 20, "exercises": [{"name": "Foam Roll Glutes", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each side", "equipment": "Foam Roller", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Sit on roller, cross ankle over knee, roll glute", "substitution": "Lacrosse Ball Glute"}, {"name": "Standing Quad Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 45s each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Pull heel to glute, keep knees together", "substitution": "Prone Quad Stretch"}, {"name": "Pigeon Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 60s each side", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Front shin across, fold forward", "substitution": "Figure-4 Stretch"}, {"name": "Hamstring PNF Stretch", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 3, "rest_seconds": 0, "weight_guidance": "Contract-relax each side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "intermediate", "form_cue": "Contract 5s against resistance, relax and deepen", "substitution": "Passive Hamstring Stretch"}, {"name": "Ankle Circle", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each direction each foot", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Full range of motion circles", "substitution": "Ankle Pump"}, {"name": "Legs Up the Wall", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 0, "weight_guidance": "Hold 2 minutes", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Scoot close to wall, legs vertical, relax", "substitution": "Elevated Leg Rest"}]}]'::jsonb,
    'Post-Leg Day Recovery',
    'Post-Leg Day Recovery - 2w 3x/wk',
    'Med',
    false,
    'Comprehensive leg day recovery with foam rolling, stretching, and PNF',
    'Lift Mobility'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Leg Day Recovery'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
