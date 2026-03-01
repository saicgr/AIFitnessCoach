-- Program: Post-Hike Recovery
-- Category: Hiking & Trail Fitness -> hiking
-- Priority: Low
-- Durations: [1], Sessions: [1]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Post-Hike Recovery',
    'Recovery stretching and mobility after long trail days',
    'hiking',
    'all_levels',
    1,
    1,
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

-- Variant: Post-Hike Recovery - 1w 1x/wk
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
    'Post-Hike Recovery - 1w 1x/wk',
    'hiking',
    1,
    60,
    ARRAY['Improve flexibility', 'Enhance body awareness', 'Promote active recovery', 'Reduce injury risk']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Post-Hike Recovery'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: increase intensity and duration',
    '[{"workout_name": "Trail Balance & Stability", "type": "balance", "duration_minutes": 35, "exercises": [{"name": "Single-Leg Stand", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 30 seconds each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Core", "Ankle Stabilizers"], "difficulty": "beginner", "form_cue": "Eyes forward, engage core, slight knee bend", "substitution": "Tandem Stand"}, {"name": "BOSU Ball Squat", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Bodyweight", "equipment": "BOSU Ball", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Ankle Stabilizers"], "difficulty": "intermediate", "form_cue": "Flat side up, controlled descent", "substitution": "Bodyweight Squat"}, {"name": "Lateral Hop", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Side to side", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Soft landing, absorb with knees", "substitution": "Lateral Step"}, {"name": "Single-Leg Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Full range, hold rail lightly for balance", "substitution": "Double-Leg Calf Raise"}, {"name": "Banded Ankle Dorsiflexion", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Resistance band", "equipment": "Resistance Band", "body_part": "Legs", "primary_muscle": "Tibialis Anterior", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Pull toes toward shin against band", "substitution": "Toe Tap"}, {"name": "Single-Leg Deadlift", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Bodyweight or light DB", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Hinge forward, maintain flat back", "substitution": "Romanian Deadlift"}]}]'::jsonb,
    'Post-Hike Recovery',
    'Post-Hike Recovery - 1w 1x/wk',
    'Low',
    false,
    'Recovery stretching and mobility after long trail days',
    'Hiking & Trail Fitness'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Post-Hike Recovery'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 1
ON CONFLICT DO NOTHING;
