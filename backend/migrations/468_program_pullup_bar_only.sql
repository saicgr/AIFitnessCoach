-- Program: Pull-up Bar Only
-- Category: Equipment-Specific -> equipment_specific
-- Priority: low
-- Durations: [2, 4, 8], Sessions: [4, 5]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Pull-up Bar Only',
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'equipment_specific',
    'all_levels',
    8,
    5,
    'custom',
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
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

-- Variant: Pull-up Bar Only - 2w 4x/wk
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
    'Pull-up Bar Only - 2w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 2w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 2w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Pull-up Bar Only - 2w 5x/wk
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
    'Pull-up Bar Only - 2w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 2w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 2 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 2w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Pull-up Bar Only - 4w 4x/wk
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
    'Pull-up Bar Only - 4w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Pull-up Bar Only - 4w 5x/wk
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
    'Pull-up Bar Only - 4w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Build (Progressive Overload)',
    'Week 2 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Peak (Intensification)',
    'Week 3 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Test/Maintenance',
    'Week 4 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 4w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 4
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

-- Variant: Pull-up Bar Only - 8w 4x/wk
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
    'Pull-up Bar Only - 8w 4x/wk',
    'equipment_specific',
    4,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
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
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 4x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 4
ON CONFLICT DO NOTHING;

-- Variant: Pull-up Bar Only - 8w 5x/wk
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
    'Pull-up Bar Only - 8w 5x/wk',
    'equipment_specific',
    5,
    60,
    ARRAY['Increase maximal strength', 'Progressive overload', 'Build functional strength', 'Improve body control']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pull-up Bar Only'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2 - Foundation',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4 - Progressive overload',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6 - Peak intensity',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Test/Maintenance',
    'Week 8 - Consolidation and maintenance',
    '[{"workout_name": "Day 1 - Pull-Up Bar Upper Body", "type": "strength", "exercises": [{"name": "Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Full range, chin over bar", "substitution": "Negative Pull-Up"}, {"name": "Chin-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Supinated grip, full range", "substitution": "Negative Chin-Up"}, {"name": "Hanging Leg Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging, controlled raise", "substitution": "Hanging Knee Raise"}, {"name": "Hanging Knee Raise", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Knees to chest, slow lower", "substitution": "Hanging Leg Raise"}, {"name": "Dead Hang", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 1, "rest_seconds": 30, "weight_guidance": "Bodyweight - hold 30 sec", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Forearms", "Grip Strength"], "difficulty": "beginner", "form_cue": "Full relaxed hang, shoulders packed", "substitution": "Active Hang"}, {"name": "Wide-Grip Pull-Up", "exercise_library_id": null, "in_library": false, "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Teres Major", "Biceps"], "difficulty": "intermediate", "form_cue": "Wide grip, pull to upper chest", "substitution": "Negative Wide Pull-Up"}]}]'::jsonb,
    'Pull-up Bar Only',
    'Pull-up Bar Only - 8w 5x/wk',
    'low',
    true,
    'Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.',
    'Equipment-Specific'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pull-up Bar Only'
  AND pv.duration_weeks = 8
  AND pv.sessions_per_week = 5
ON CONFLICT DO NOTHING;
