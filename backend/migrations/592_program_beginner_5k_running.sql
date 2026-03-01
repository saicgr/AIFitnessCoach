-- Program: Beginner 5K Running
-- Category: Endurance -> endurance
-- Priority: High
-- Durations: [9], Sessions: [3]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Beginner 5K Running',
    'Couch to 5K style progressive running program for complete beginners',
    'endurance',
    'beginner',
    9,
    3,
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

-- Variant: Beginner 5K Running - 9w 3x/wk
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
    'Easy',
    9,
    'Beginner 5K Running - 9w 3x/wk',
    'endurance',
    3,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Beginner 5K Running'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Foundation (Base Building)',
    'Week 1',
    '[{"workout_name": "Week 1 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 6", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Week 1 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 6", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Week 1 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 6", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    2,
    'Foundation (Base Building)',
    'Week 2',
    '[{"workout_name": "Week 2 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Week 2 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}, {"workout_name": "Week 2 - Walk/Jog", "type": "cardio", "duration_minutes": 25, "exercises": [{"name": "Walk/Jog Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 1 min jog / 2 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Easy jog pace, walk to fully recover between intervals", "substitution": "Treadmill Walk/Jog"}, {"name": "Bodyweight Squat", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Warm up legs with air squats", "substitution": "Wall Sit"}, {"name": "Calf Raise", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Calves", "secondary_muscles": ["Tibialis Anterior"], "difficulty": "beginner", "form_cue": "Strengthen calves for running", "substitution": "Seated Calf Raise"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    3,
    'Build (Progressive Overload)',
    'Week 3',
    '[{"workout_name": "Week 3 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 3 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 3 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 7", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    4,
    'Build (Progressive Overload)',
    'Week 4',
    '[{"workout_name": "Week 4 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 8", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 4 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 8", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 4 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 8", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    5,
    'Peak (Intensification)',
    'Week 5',
    '[{"workout_name": "Week 5 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 9", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 5 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 9", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}, {"workout_name": "Week 5 - Building Runs", "type": "cardio", "duration_minutes": 30, "exercises": [{"name": "Jog/Walk Interval", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Alternate 3 min jog / 1 min walk x 9", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "beginner", "form_cue": "Extend jog intervals, shorter walks, find your pace", "substitution": "Treadmill Jog"}, {"name": "Walking Lunge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight per leg", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "beginner", "form_cue": "Build running-specific leg strength", "substitution": "Stationary Lunge"}, {"name": "Glute Bridge", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Glutes", "primary_muscle": "Gluteus Maximus", "secondary_muscles": ["Hamstrings"], "difficulty": "beginner", "form_cue": "Activate glutes for better running form", "substitution": "Single-Leg Bridge"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    6,
    'Peak (Intensification)',
    'Week 6',
    '[{"workout_name": "Week 6 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 15 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 6 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 15 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 6 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 15 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    7,
    'Taper (Deload)',
    'Week 7',
    '[{"workout_name": "Week 7 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 18 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 7 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 18 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 7 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 18 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    8,
    'Taper (Deload)',
    'Week 8',
    '[{"workout_name": "Week 8 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 21 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 8 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 21 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 8 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 21 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    9,
    'Test/Maintenance',
    'Week 9',
    '[{"workout_name": "Week 9 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 24 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 9 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 24 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}, {"workout_name": "Week 9 - Continuous Runs", "type": "cardio", "duration_minutes": 35, "exercises": [{"name": "Continuous Run", "exercise_library_id": null, "in_library": false, "sets": 1, "reps": 1, "rest_seconds": 0, "weight_guidance": "Run 24 minutes continuously", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "beginner", "form_cue": "Maintain steady pace, focus on breathing rhythm", "substitution": "Treadmill Run"}, {"name": "High Knees", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 20, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Quadriceps", "Core"], "difficulty": "beginner", "form_cue": "Running form drill, lift knees high", "substitution": "March in Place"}, {"name": "Plank", "exercise_library_id": null, "in_library": false, "sets": 2, "reps": 1, "rest_seconds": 30, "weight_guidance": "Hold 45 seconds", "equipment": "Bodyweight", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Obliques"], "difficulty": "beginner", "form_cue": "Build core for running posture", "substitution": "Forearm Plank"}]}]'::jsonb,
    'Beginner 5K Running',
    'Beginner 5K Running - 9w 3x/wk',
    'High',
    false,
    'Couch to 5K style progressive running program for complete beginners',
    'Endurance'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Beginner 5K Running'
  AND pv.duration_weeks = 9
  AND pv.sessions_per_week = 3
ON CONFLICT DO NOTHING;
