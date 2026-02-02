-- Migration: 204_weight_machine_exercises.sql
-- Created: 2025-02-01
-- Purpose: Add weight machine exercises to exercise_library
-- Equipment covered: Smith Machine, Leg Press, Lat Pulldown, Leg Curl, Leg Extension,
--                    Pec Deck, Shoulder Press Machine, Hack Squat, Seated Row, Chest Press, Assisted Pullup

-- ============================================
-- SMITH MACHINE EXERCISES (5 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Smith Machine Squat', 'legs', 'smith_machine', 'quadriceps', ARRAY['glutes', 'hamstrings', 'core'],
     'Position bar on upper back, feet slightly forward of the bar path. Unrack and descend until thighs are parallel. Drive through heels to stand. The fixed path provides stability for beginners.',
     'Beginner', 'strength'),

    ('Smith Machine Bench Press', 'chest', 'smith_machine', 'chest', ARRAY['triceps', 'shoulders'],
     'Lie on bench with bar at mid-chest level. Grip slightly wider than shoulders. Unrack, lower to chest, and press up. The guided bar path helps focus on chest contraction.',
     'Beginner', 'strength'),

    ('Smith Machine Shoulder Press', 'shoulders', 'smith_machine', 'shoulders', ARRAY['triceps', 'core'],
     'Sit on bench with back support, bar at chin level. Press overhead until arms are extended but not locked. Lower with control. Safe overhead pressing option.',
     'Beginner', 'strength'),

    ('Smith Machine Romanian Deadlift', 'legs', 'smith_machine', 'hamstrings', ARRAY['glutes', 'lower_back', 'core'],
     'Stand close to bar, grip shoulder-width. Hinge at hips, pushing glutes back while keeping bar close to legs. Feel stretch in hamstrings at bottom. Drive hips forward to return.',
     'Intermediate', 'strength'),

    ('Smith Machine Calf Raise', 'legs', 'smith_machine', 'calves', NULL,
     'Position bar on upper back, stand on edge of platform or plates. Rise onto toes, pause at top, lower with control below platform level for full stretch. Great isolation for calves.',
     'Beginner', 'strength')
;

-- ============================================
-- LEG PRESS EXERCISES (5 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Leg Press', 'legs', 'leg_press', 'quadriceps', ARRAY['glutes', 'hamstrings'],
     'Sit with back flat against pad, feet shoulder-width on platform. Release safeties and lower weight by bending knees to 90 degrees. Press through feet to extend legs without locking knees.',
     'Beginner', 'strength'),

    ('Leg Press Wide Stance', 'legs', 'leg_press', 'adductors', ARRAY['quadriceps', 'glutes'],
     'Place feet wider than shoulder-width, toes pointed outward. Lower weight with knees tracking over toes. This stance targets inner thighs and glutes more than standard position.',
     'Intermediate', 'strength'),

    ('Leg Press Narrow Stance', 'legs', 'leg_press', 'quadriceps', ARRAY['glutes'],
     'Position feet closer together (hip-width) and lower on the platform. This emphasizes quadriceps, especially the outer sweep. Keep knees tracking over toes throughout.',
     'Intermediate', 'strength'),

    ('Single Leg Press', 'legs', 'leg_press', 'quadriceps', ARRAY['glutes', 'hamstrings'],
     'Place one foot on platform, other leg extended or foot on floor. Press with single leg, focusing on control. Excellent for correcting strength imbalances between legs.',
     'Intermediate', 'strength'),

    ('Leg Press Calf Raise', 'legs', 'leg_press', 'calves', NULL,
     'Position feet at bottom of platform with only balls of feet on edge. Press through toes, extending ankles fully. Lower for a deep stretch. High-rep isolation for calf development.',
     'Beginner', 'strength')
;

-- ============================================
-- LAT PULLDOWN EXERCISES (5 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Lat Pulldown', 'back', 'lat_pulldown', 'lats', ARRAY['biceps', 'rear_delts', 'rhomboids'],
     'Grip bar slightly wider than shoulders, palms forward. Pull bar to upper chest while squeezing shoulder blades together. Control the weight on the way up. Foundation back exercise.',
     'Beginner', 'strength'),

    ('Wide Grip Lat Pulldown', 'back', 'lat_pulldown', 'lats', ARRAY['biceps', 'rear_delts'],
     'Take extra-wide grip on the bar. Pull to upper chest, focusing on driving elbows down and back. This width emphasizes the outer lats for width development.',
     'Intermediate', 'strength'),

    ('Close Grip Lat Pulldown', 'back', 'lat_pulldown', 'lats', ARRAY['biceps', 'middle_back'],
     'Use V-bar or close grip handle. Pull to lower chest while keeping elbows close to body. Emphasizes lower lat development and allows heavier loading.',
     'Intermediate', 'strength'),

    ('Reverse Grip Lat Pulldown', 'back', 'lat_pulldown', 'lats', ARRAY['biceps', 'lower_lats'],
     'Grip bar with palms facing you, shoulder-width apart. Pull to upper chest, squeezing at bottom. Underhand grip recruits more biceps and targets lower lat fibers.',
     'Intermediate', 'strength'),

    ('Behind Neck Lat Pulldown', 'back', 'lat_pulldown', 'lats', ARRAY['rear_delts', 'rhomboids', 'traps'],
     'ONLY perform if you have good shoulder mobility. Wide grip, pull behind head to base of neck. Keep head forward. Targets upper back differently but higher injury risk.',
     'Advanced', 'strength')
;

-- ============================================
-- LEG CURL MACHINE EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Lying Leg Curl', 'legs', 'leg_curl_machine', 'hamstrings', ARRAY['calves', 'glutes'],
     'Lie face down, position pad just above heels. Curl weight toward glutes, squeezing hamstrings at top. Lower with control, don''t let weight drop. Key hamstring isolation exercise.',
     'Beginner', 'strength'),

    ('Seated Leg Curl', 'legs', 'leg_curl_machine', 'hamstrings', ARRAY['calves'],
     'Sit with back against pad, legs extended. Position pad behind ankles. Curl weight under the seat while gripping handles. Squeeze at bottom, return with control.',
     'Beginner', 'strength'),

    ('Single Leg Curl', 'legs', 'leg_curl_machine', 'hamstrings', ARRAY['calves'],
     'Perform lying or seated curl with one leg only. Focus on smooth, controlled movement. Excellent for addressing hamstring imbalances between legs.',
     'Intermediate', 'strength')
;

-- ============================================
-- LEG EXTENSION EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Leg Extension', 'legs', 'leg_extension_machine', 'quadriceps', NULL,
     'Sit with back against pad, ankles behind roller pad. Extend legs fully, squeezing quads at top. Lower with control. Pure quadriceps isolation - great for definition.',
     'Beginner', 'strength'),

    ('Single Leg Extension', 'legs', 'leg_extension_machine', 'quadriceps', NULL,
     'Perform extension one leg at a time. Allows focus on weaker leg and ensures equal development. Use lighter weight than bilateral version.',
     'Intermediate', 'strength')
;

-- ============================================
-- PEC DECK / CHEST FLY MACHINE EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Pec Deck Fly', 'chest', 'chest_fly_machine', 'chest', ARRAY['front_delts'],
     'Sit with back flat against pad, elbows at chest height on pads. Squeeze chest to bring pads together in front. Control the return, feeling stretch in chest. Pure chest isolation.',
     'Beginner', 'strength'),

    ('Reverse Pec Deck', 'shoulders', 'chest_fly_machine', 'rear_delts', ARRAY['rhomboids', 'traps'],
     'Face the machine, chest against pad. Grip handles and open arms outward, squeezing shoulder blades together. Great for rear delt development and posture improvement.',
     'Beginner', 'strength')
;

-- ============================================
-- SHOULDER PRESS MACHINE EXERCISES (1 exercise)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Machine Shoulder Press', 'shoulders', 'shoulder_press_machine', 'shoulders', ARRAY['triceps', 'upper_chest'],
     'Sit with back against pad, grip handles at shoulder level. Press overhead until arms are extended. Lower with control. Safe option for building shoulder strength.',
     'Beginner', 'strength')
;

-- ============================================
-- HACK SQUAT EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Hack Squat', 'legs', 'hack_squat', 'quadriceps', ARRAY['glutes', 'hamstrings'],
     'Position shoulders under pads, feet shoulder-width on platform. Release safeties, descend until thighs are parallel. Drive through feet to return. Quad-dominant squat variation.',
     'Intermediate', 'strength'),

    ('Reverse Hack Squat', 'legs', 'hack_squat', 'glutes', ARRAY['hamstrings', 'quadriceps'],
     'Face the machine with chest against pad. Position feet lower on platform. Descend into squat, feeling glute stretch. This variation emphasizes glutes and posterior chain.',
     'Intermediate', 'strength')
;

-- ============================================
-- SEATED ROW MACHINE EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Seated Row Machine', 'back', 'seated_row_machine', 'middle_back', ARRAY['lats', 'biceps', 'rear_delts'],
     'Sit with chest against pad, grip handles. Pull toward torso, squeezing shoulder blades together at end. Control the return, maintaining tension. Great for back thickness.',
     'Beginner', 'strength'),

    ('Wide Grip Seated Row', 'back', 'seated_row_machine', 'upper_back', ARRAY['rear_delts', 'rhomboids', 'biceps'],
     'Use wide grip attachment or handles. Pull with elbows out to sides, targeting upper back and rear delts. Focus on squeezing shoulder blades together.',
     'Intermediate', 'strength')
;

-- ============================================
-- CHEST PRESS MACHINE EXERCISES (2 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Machine Chest Press', 'chest', 'chest_press_machine', 'chest', ARRAY['triceps', 'front_delts'],
     'Sit with back flat, grip handles at chest level. Press forward until arms are extended but not locked. Return with control. Safe chest pressing option for beginners.',
     'Beginner', 'strength'),

    ('Incline Machine Press', 'chest', 'chest_press_machine', 'upper_chest', ARRAY['triceps', 'front_delts'],
     'Use incline chest press machine or adjust seat for incline angle. Press upward and forward. This angle targets upper chest development.',
     'Beginner', 'strength')
;

-- ============================================
-- ASSISTED PULLUP MACHINE EXERCISES (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Assisted Pull-up', 'back', 'assisted_pullup_machine', 'lats', ARRAY['biceps', 'rear_delts', 'core'],
     'Set assistance weight (more weight = easier). Grip bar wider than shoulders, kneel on pad. Pull chin above bar, squeezing lats. Lower with control. Progress by reducing assistance.',
     'Beginner', 'strength'),

    ('Assisted Chin-up', 'back', 'assisted_pullup_machine', 'biceps', ARRAY['lats', 'core'],
     'Use underhand (supinated) grip, shoulder-width. Pull until chin clears bar, emphasizing bicep contraction. This grip shifts emphasis from lats to biceps.',
     'Beginner', 'strength'),

    ('Assisted Dip', 'chest', 'assisted_pullup_machine', 'triceps', ARRAY['chest', 'shoulders'],
     'Grip dip handles, kneel on assistance pad. Lower body by bending elbows to 90 degrees. Push back up, focusing on triceps. Forward lean increases chest involvement.',
     'Beginner', 'strength')
;

-- ============================================
-- CABLE MACHINE EXERCISES (5 bonus exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES
    ('Cable Tricep Pushdown', 'arms', 'cable_machine', 'triceps', NULL,
     'Stand facing high pulley, grip rope or bar. Keep elbows at sides, push down until arms are straight. Squeeze triceps at bottom. Control the return. Classic tricep isolation.',
     'Beginner', 'strength'),

    ('Cable Bicep Curl', 'arms', 'cable_machine', 'biceps', ARRAY['forearms'],
     'Stand facing low pulley, grip bar or handles. Curl weight up, keeping elbows stationary at sides. Squeeze at top, lower with control. Constant tension throughout range.',
     'Beginner', 'strength'),

    ('Cable Face Pull', 'shoulders', 'cable_machine', 'rear_delts', ARRAY['rhomboids', 'traps', 'rotator_cuff'],
     'Set cable at face height with rope attachment. Pull toward face, separating rope ends, elbows high. Squeeze shoulder blades together. Essential for shoulder health and posture.',
     'Beginner', 'strength'),

    ('Cable Woodchop', 'core', 'cable_machine', 'obliques', ARRAY['core', 'shoulders'],
     'Set cable high, grip with both hands. Rotate torso diagonally downward across body while pivoting feet. Control the return. Targets rotational core strength.',
     'Intermediate', 'strength'),

    ('Cable Crunch', 'core', 'cable_machine', 'abs', ARRAY['obliques'],
     'Kneel facing high pulley, rope behind head. Crunch down, bringing elbows toward thighs. Focus on contracting abs, not pulling with arms. Weighted ab isolation.',
     'Beginner', 'strength')
;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE exercise_library IS 'Main exercise database with weight machine exercises added in migration 204';
