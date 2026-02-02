-- Migration: 203_cardio_machine_exercises.sql
-- Created: 2025-02-01
-- Purpose: Add cardio machine exercises to exercise_library
-- Equipment covered: Treadmill, Stationary Bike, Rowing Machine, Elliptical, Stair Climber, Assault Bike, Ski Erg, Sled

-- ============================================
-- TREADMILL EXERCISES (5 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Treadmill Walk', 'cardio', 'treadmill', 'quadriceps', ARRAY['calves', 'glutes', 'hamstrings'],
     'Walk at a comfortable pace of 2.5-3.5 mph. Maintain good posture with shoulders back and core engaged. Swing arms naturally. Great for warming up or active recovery.',
     'Beginner', 'cardio'),

    ('Treadmill Incline Walk', 'cardio', 'treadmill', 'glutes', ARRAY['calves', 'hamstrings', 'quadriceps'],
     'Set incline to 3-6% and walk at 2.5-3.5 mph. Keep chest up and avoid holding handrails. The incline activates your posterior chain (glutes, hamstrings) more than flat walking. Excellent for warmup or low-impact cardio.',
     'Beginner', 'cardio'),

    ('Treadmill Jog', 'cardio', 'treadmill', 'quadriceps', ARRAY['calves', 'hamstrings', 'glutes', 'core'],
     'Jog at 5-6 mph with a comfortable stride. Land midfoot and keep arms bent at 90 degrees. Maintain steady breathing. Good for building aerobic base.',
     'Intermediate', 'cardio'),

    ('Treadmill Run', 'cardio', 'treadmill', 'quadriceps', ARRAY['calves', 'hamstrings', 'glutes', 'core', 'hip_flexors'],
     'Run at moderate pace of 6-8 mph. Focus on efficient form with quick turnover. Keep core engaged and avoid overstriding. Use for cardio conditioning.',
     'Intermediate', 'cardio'),

    ('Treadmill Sprint Intervals', 'cardio', 'treadmill', 'quadriceps', ARRAY['glutes', 'hamstrings', 'calves', 'core'],
     'Alternate between 30-second sprints (8-12 mph) and 60-second recovery walks (3-4 mph). Gradually increase speed during sprints. Focus on explosive drive and quick turnover. Advanced HIIT training.',
     'Advanced', 'cardio')
;

-- ============================================
-- STATIONARY BIKE EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Stationary Bike Easy', 'cardio', 'stationary_bike', 'quadriceps', ARRAY['calves', 'hamstrings'],
     'Pedal at easy pace with low resistance (level 2-4). Maintain 70-80 RPM. Keep back straight and shoulders relaxed. Great for warmup or recovery.',
     'Beginner', 'cardio'),

    ('Stationary Bike Moderate', 'cardio', 'stationary_bike', 'quadriceps', ARRAY['glutes', 'hamstrings', 'calves'],
     'Pedal at moderate resistance (level 5-7) with 80-90 RPM. Stay seated and push through the pedals. Focus on smooth circular motion. Good steady-state cardio.',
     'Intermediate', 'cardio'),

    ('Spin Bike HIIT', 'cardio', 'stationary_bike', 'quadriceps', ARRAY['glutes', 'hamstrings', 'calves', 'core'],
     'Alternate 30 seconds all-out effort with 30 seconds easy spinning. Increase resistance for seated climbs or stand for sprints. Maintain 100+ RPM during sprints. High-intensity interval training.',
     'Advanced', 'cardio')
;

-- ============================================
-- ROWING MACHINE EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Rowing Machine Easy', 'cardio', 'rowing_machine', 'lats', ARRAY['quadriceps', 'glutes', 'biceps', 'core'],
     'Row at easy pace (18-22 strokes/min) with damper at 3-5. Focus on the sequence: legs-back-arms on drive, arms-back-legs on recovery. Keep core engaged and maintain steady rhythm.',
     'Beginner', 'cardio'),

    ('Rowing Machine Moderate', 'cardio', 'rowing_machine', 'lats', ARRAY['quadriceps', 'glutes', 'hamstrings', 'biceps', 'core', 'shoulders'],
     'Row at moderate intensity (24-28 strokes/min). Increase power on the drive phase while maintaining form. Keep chest up and avoid rounding the back. Good for full-body cardio conditioning.',
     'Intermediate', 'cardio'),

    ('Rowing Machine Intervals', 'cardio', 'rowing_machine', 'lats', ARRAY['quadriceps', 'glutes', 'hamstrings', 'biceps', 'core', 'shoulders', 'triceps'],
     'Row 500m hard, then 500m easy recovery. Repeat 4-6 times. Push for sub-2:00/500m pace on hard intervals. Focus on powerful leg drive and quick hands. Advanced HIIT for full-body conditioning.',
     'Advanced', 'cardio')
;

-- ============================================
-- ELLIPTICAL EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Elliptical Easy', 'cardio', 'elliptical', 'quadriceps', ARRAY['glutes', 'hamstrings', 'calves'],
     'Use low resistance and comfortable stride. Maintain 120-140 strides per minute. Keep posture upright with core engaged. Let arms move naturally or use handles lightly. Low-impact cardio option.',
     'Beginner', 'cardio'),

    ('Elliptical Moderate', 'cardio', 'elliptical', 'quadriceps', ARRAY['glutes', 'hamstrings', 'calves', 'biceps', 'triceps', 'shoulders'],
     'Increase resistance to moderate level. Use arm handles to engage upper body. Push and pull with arms while driving with legs. Vary incline for different muscle emphasis. Full-body steady-state cardio.',
     'Intermediate', 'cardio')
;

-- ============================================
-- STAIR CLIMBER EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Stair Climber Easy', 'cardio', 'stair_climber', 'quadriceps', ARRAY['glutes', 'calves', 'hamstrings'],
     'Start at slow pace (level 4-6). Lightly hold rails for balance only. Push through your whole foot, not just toes. Keep upright posture. Great for building leg endurance.',
     'Beginner', 'cardio'),

    ('Stair Climber Moderate', 'cardio', 'stair_climber', 'glutes', ARRAY['quadriceps', 'calves', 'hamstrings', 'core'],
     'Increase speed to moderate pace (level 7-9). Minimize rail use - fingertip touch only. Focus on driving through heels to engage glutes. Keep core tight for balance. Effective leg conditioning.',
     'Intermediate', 'cardio'),

    ('StairMaster Intervals', 'cardio', 'stair_climber', 'quadriceps', ARRAY['glutes', 'calves', 'hamstrings', 'core'],
     'Alternate 1 minute fast (level 10-12) with 1 minute slow (level 5-6). No hand rails during fast intervals. Take big steps and drive through the full range of motion. Advanced HIIT for legs.',
     'Advanced', 'cardio')
;

-- ============================================
-- ASSAULT BIKE / AIR BIKE EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Assault Bike Easy', 'cardio', 'assault_bike', 'quadriceps', ARRAY['biceps', 'triceps', 'shoulders', 'core', 'calves'],
     'Pedal and push/pull handles at easy pace. The fan resistance increases with effort, so go slow for warmup. Coordinate arm and leg movement. Focus on smooth, rhythmic motion.',
     'Beginner', 'cardio'),

    ('Assault Bike HIIT', 'cardio', 'assault_bike', 'quadriceps', ARRAY['glutes', 'biceps', 'triceps', 'shoulders', 'core'],
     'Perform 20 seconds all-out effort, 40 seconds rest. Repeat 8-10 rounds. Push and pull the handles explosively while driving hard with legs. Maximum calorie burn per minute. Brutal but effective.',
     'Advanced', 'cardio'),

    ('Assault Bike Calories', 'cardio', 'assault_bike', 'quadriceps', ARRAY['glutes', 'biceps', 'triceps', 'shoulders', 'core', 'hamstrings'],
     'Set target calories (e.g., 20-50 cal) and complete as fast as possible. All-out effort from start. Coordinate pushing/pulling arms with powerful leg drive. Track time and try to beat it. CrossFit-style conditioning.',
     'Advanced', 'cardio')
;

-- ============================================
-- SKI ERG EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Ski Erg Easy', 'cardio', 'ski_erg', 'lats', ARRAY['triceps', 'shoulders', 'core', 'glutes'],
     'Stand with slight knee bend. Pull handles down in smooth arc, hinging at hips. Extend arms overhead on recovery. Focus on lat engagement and core bracing. Keep a steady rhythm at low intensity.',
     'Beginner', 'cardio'),

    ('Ski Erg Intervals', 'cardio', 'ski_erg', 'lats', ARRAY['triceps', 'shoulders', 'core', 'glutes', 'hamstrings'],
     'Row 250m hard, 250m easy. Repeat 6-8 times. On hard intervals, explosively drive handles down while hinging at hips. Aim for sub-1:00/250m. Great for upper body and core conditioning.',
     'Advanced', 'cardio')
;

-- ============================================
-- SLED EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Sled Push', 'full body', 'sled', 'quadriceps', ARRAY['glutes', 'calves', 'core', 'shoulders', 'triceps'],
     'Grip low handles and lean into the sled at 45-degree angle. Drive through your legs with powerful strides. Keep arms extended and core braced. Push for distance or time. Excellent for leg power and conditioning.',
     'Intermediate', 'strength'),

    ('Sled Pull', 'full body', 'sled', 'hamstrings', ARRAY['glutes', 'lats', 'biceps', 'core'],
     'Attach rope to sled and walk backwards while pulling. Keep tension on the rope throughout. Drive through heels and squeeze glutes with each step. Targets posterior chain. Great for athletic conditioning.',
     'Intermediate', 'strength'),

    ('Sled Drag', 'full body', 'sled', 'glutes', ARRAY['hamstrings', 'calves', 'core', 'lower_back'],
     'Attach harness or hold rope over shoulder. Walk forward, dragging sled behind you. Take powerful strides and maintain upright posture. Focus on hip extension each step. Builds leg strength and work capacity.',
     'Intermediate', 'strength')
;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE exercise_library IS 'Main exercise database with cardio machine exercises added in migration 203';
