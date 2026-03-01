-- Program: Spartan Challenge
-- Category: Hell Mode -> hell_mode
-- Priority: High
-- Durations: [1, 2], Sessions: [6]

-- Insert branded program
INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    'Spartan Challenge',
    'Obstacle race-inspired intense conditioning',
    'hell_mode',
    'advanced',
    2,
    6,
    'circuit',
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

-- Variant: Spartan Challenge - 1w 6x/wk
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
    'Spartan Challenge - 1w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Spartan Challenge'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Single Session',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}]'::jsonb,
    'Spartan Challenge',
    'Spartan Challenge - 1w 6x/wk',
    'High',
    false,
    'Obstacle race-inspired intense conditioning',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Spartan Challenge'
  AND pv.duration_weeks = 1
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;

-- Variant: Spartan Challenge - 2w 6x/wk
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
    'Spartan Challenge - 2w 6x/wk',
    'hell_mode',
    6,
    60,
    ARRAY['Build cardiovascular endurance', 'Improve VO2 max']::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = 'Spartan Challenge'
ON CONFLICT DO NOTHING;

INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    1,
    'Build (Progressive Overload)',
    'Week 1 - Endure: push beyond previous limits',
    '[{"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}]'::jsonb,
    'Spartan Challenge',
    'Spartan Challenge - 2w 6x/wk',
    'High',
    false,
    'Obstacle race-inspired intense conditioning',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Spartan Challenge'
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
    '[{"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}, {"workout_name": "Spartan Challenge", "type": "hell_mode", "duration_minutes": 50, "exercises": [{"name": "Bear Crawl", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "25 meters forward and back", "equipment": "Bodyweight", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Quadriceps", "Hip Flexors"], "difficulty": "advanced", "form_cue": "Hips low, opposite arm and leg, fast crawl", "substitution": "Mountain Climber"}, {"name": "Wall Ball", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 20, "rest_seconds": 30, "weight_guidance": "20lb ball, 10ft target", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Core"], "difficulty": "advanced", "form_cue": "Deep squat, explosive throw, catch and go immediately", "substitution": "Thruster"}, {"name": "Kettlebell Swing", "exercise_library_id": null, "in_library": false, "sets": 5, "reps": 25, "rest_seconds": 30, "weight_guidance": "Heavy bell", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "advanced", "form_cue": "Unbroken sets, max hip power", "substitution": "Dumbbell Swing"}, {"name": "Rope Slam", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "30 seconds continuous", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Deltoids", "secondary_muscles": ["Core", "Forearms"], "difficulty": "advanced", "form_cue": "All-out effort, alternating waves to double slams", "substitution": "Medicine Ball Slam"}, {"name": "Box Jump", "exercise_library_id": null, "in_library": false, "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "30-inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Explosive jump, stick landing, step down", "substitution": "Squat Jump"}, {"name": "Sprint", "exercise_library_id": null, "in_library": false, "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "200 meter sprint", "equipment": "Bodyweight", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "advanced", "form_cue": "All-out 200m, walk back for recovery", "substitution": "High Knees"}]}]'::jsonb,
    'Spartan Challenge',
    'Spartan Challenge - 2w 6x/wk',
    'High',
    false,
    'Obstacle race-inspired intense conditioning',
    'Hell Mode'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = 'Spartan Challenge'
  AND pv.duration_weeks = 2
  AND pv.sessions_per_week = 6
ON CONFLICT DO NOTHING;
