-- Program: Pre-Run Warmup
-- Category: Warmup & Cooldown -> warmup_cooldown
-- Priority: High
-- Durations: [1, 2], Sessions: [7]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Pre-Run Warmup',
    'Targeted warmup for running and jogging sessions',
    'warmup_cooldown',
    'all_levels',
    2,
    7,
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

-- Variant: Pre-Run Warmup - 1w 7x/wk
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
    'Pre-Run Warmup - 1w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pre-Run Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}]'::jsonb,
    'Pre-Run Warmup',
    'Pre-Run Warmup - 1w 7x/wk',
    'High',
    false,
    'Targeted warmup for running and jogging sessions',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Run Warmup'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;

-- Variant: Pre-Run Warmup - 2w 7x/wk
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
    'Pre-Run Warmup - 2w 7x/wk',
    'warmup_cooldown',
    7,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Pre-Run Warmup'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Build: refine technique and increase range',
    '[{"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}]'::jsonb,
    'Pre-Run Warmup',
    'Pre-Run Warmup - 2w 7x/wk',
    'High',
    false,
    'Targeted warmup for running and jogging sessions',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Run Warmup'
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
    '[{"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}, {"workout_name": "Pre-Run Warmup", "type": "warmup", "duration_minutes": 8, "exercises": [{"name": "Brisk Walk", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "90 seconds", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps"], "difficulty": "beginner", "form_cue": "Quick walk to start warming up", "substitution": "March in Place"}, {"name": "Leg Swings Front-Back", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Hold wall, swing freely", "substitution": "Walking Knee Hug"}, {"name": "Leg Swings Side-Side", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Hips", "primary_muscle": "Hip Adductors", "secondary_muscles": ["Hip Abductors"], "difficulty": "beginner", "form_cue": "Cross midline, open wide", "substitution": "Lateral Step"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 15, "rest_seconds": 0, "weight_guidance": "Both legs", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, prep achilles", "substitution": "Ankle Circles"}, {"name": "A-Skip", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 10, "rest_seconds": 0, "weight_guidance": "Each leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Drive knee up, skip rhythm", "substitution": "High Knees"}, {"name": "Strides", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 4, "rest_seconds": 0, "weight_guidance": "Build to 80% effort over 50 meters", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Gradually build speed, relax at top end", "substitution": "Light Jog"}]}]'::jsonb,
    'Pre-Run Warmup',
    'Pre-Run Warmup - 2w 7x/wk',
    'High',
    false,
    'Targeted warmup for running and jogging sessions',
    'Warmup & Cooldown'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Pre-Run Warmup'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 7
ON CONFLICT DO NOTHING;
