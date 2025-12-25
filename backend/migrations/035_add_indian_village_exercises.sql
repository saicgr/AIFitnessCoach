-- Migration: 035_add_indian_village_exercises.sql
-- Description: Add traditional Indian village exercises (Kushti, Vyayam, Kalaripayattu)
-- Date: 2025-12-25
--
-- Categories:
--   - Kushti/Pehlwani (Indian Wrestling) exercises
--   - Vyayam (Traditional Indian Physical Culture)
--   - Kalaripayattu (South Indian Martial Art)
--   - Agricultural/Farm-inspired exercises
--   - Traditional Indian equipment exercises (Gada, Jori, Lathi, etc.)

-- ============================================
-- 1. KUSHTI/PEHLWANI EXERCISES (Indian Wrestling)
-- ============================================

-- Dand (Hindu Push-up)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Dand (Hindu Push-up)',
    'upper body',
    'bodyweight',
    'chest',
    ARRAY['shoulders', 'triceps', 'core', 'lower_back', 'hip_flexors', 'hamstrings'],
    '1. Start in downward dog position - hands and feet on floor, hips raised high forming inverted V-shape. 2. Keep hands slightly wider than shoulder-width, feet together. 3. Engage core and lower body by bending elbows. 4. Swoop chest forward and down, bringing it close to ground between hands (like diving under a bar). 5. Continue arching back, pressing chest forward and up into upward-facing dog. 6. Thighs should be off floor with full spine arch. 7. Push hips back up to starting inverted V position. 8. Keep movement smooth and flowing. Exhale going down, inhale coming up. Traditional wrestlers perform 500-3000 daily. Made famous by The Great Gama who remained undefeated in 5000+ matches.',
    'Intermediate',
    'strength',
    'https://gymvisual.com/img/p/1/7/2/6/1/17261.gif'
);

-- Baithak (Hindu Squat)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Baithak (Hindu Squat)',
    'lower body',
    'bodyweight',
    'quadriceps',
    ARRAY['glutes', 'calves', 'hamstrings', 'hip_flexors', 'core', 'ankle_stabilizers'],
    '1. Stand upright with feet shoulder-width apart, arms at sides. 2. Swing arms back behind you as you initiate descent. 3. Lower by bending knees, keeping back straight and looking forward. 4. As you approach bottom, rise onto balls of feet (heels come off ground). 5. At bottom, thighs should be parallel or lower to ground. 6. Swing arms forward and up as you reverse movement. 7. Use arm swing momentum to propel back to standing. 8. Return to standing on flat feet, arms swinging back. 9. Breathe out descending, breathe in rising. The Great Gama performed 5000 baithaks before breakfast. Traditional ratio is 2:1 (baithaks to dands).',
    'Beginner',
    'strength',
    'https://gymvisual.com/img/p/2/0/4/5/4/20454.gif'
);

-- Ram Murti Dand (Dive Bomber Push-up)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Ram Murti Dand (Dive Bomber Push-up)',
    'upper body',
    'bodyweight',
    'shoulders',
    ARRAY['chest', 'triceps', 'core', 'back', 'hip_flexors'],
    '1. Start in downward dog (inverted V) position. 2. Bend elbows and lower chest toward ground. 3. Swoop forward between hands. 4. Continue through to upward dog position. 5. Key difference from Hindu Push-up: Reverse entire motion back through the swoop. 6. Return to downward dog by diving back through. 7. This creates continuous back-and-forth motion. Named after Ram Murti Naidu, legendary Indian wrestler and strongman.',
    'Advanced',
    'strength',
    'https://gymvisual.com/img/p/1/7/2/6/1/17261.gif'
);

-- Hanuman Dand (Power Hindu Push-up)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Hanuman Dand (Power Hindu Push-up)',
    'upper body',
    'bodyweight',
    'chest',
    ARRAY['shoulders', 'triceps', 'core', 'back', 'hip_flexors', 'legs'],
    '1. Perform with explosive power and greater range of motion. 2. Start in downward dog with higher hip position than standard dand. 3. Dive down deeply, chest nearly touching ground. 4. Push through aggressively to upward dog. 5. Higher intensity version designed for power and strength. 6. Named after Lord Hanuman, the deity of strength. Focus on explosive movement throughout the entire range of motion.',
    'Advanced',
    'strength',
    NULL
);

-- ============================================
-- 2. GADA (MACE) EXERCISES
-- ============================================

-- Gada 360 Swing
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Gada 360-Degree Swing',
    'upper body',
    'gada (mace)',
    'shoulders',
    ARRAY['upper_back', 'core', 'forearms', 'grip', 'chest', 'obliques'],
    '1. Stand with feet shoulder-width apart, core engaged. 2. Hold gada directly in front with both hands gripped at end of handle. 3. Position hands close together - if left hand above right, swing over right shoulder. 4. Push mace ball over your right shoulder. 5. Allow ball to swing behind back in pendulum arc. 6. When ball reaches left shoulder, pull mace back over left shoulder. 7. Return to starting position with mace in front. 8. Repeat for desired reps, then switch direction. 9. Keep elbows close to ears, maintain core tension throughout. Start with 10 reps each direction. Beginner: 5-7kg, Intermediate: 10-15kg, Advanced: 20-25kg+.',
    'Intermediate',
    'strength',
    NULL
);

-- Gada Pendulum Swing
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Gada Pendulum Swing',
    'upper body',
    'gada (mace)',
    'shoulders',
    ARRAY['core', 'back', 'forearms', 'grip'],
    '1. Stand with feet shoulder-width apart. 2. Hold gada at end of handle with both hands. 3. Swing gada from between legs to gain initial momentum (Rumali/Head Move). 4. Launch it over your shoulder. 5. Control the pendulum swing behind your body. 6. Pull up and over the opposite shoulder. 7. This was traditionally done one-handed by advanced practitioners. Focus on controlled movements, not speed.',
    'Intermediate',
    'strength',
    NULL
);

-- Gada Figure 8
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Gada Figure 8 Swing',
    'full body',
    'gada (mace)',
    'core',
    ARRAY['shoulders', 'obliques', 'back', 'forearms'],
    '1. Stand with feet wider than shoulder-width. 2. Hold gada at mid-handle with both hands. 3. Swing the mace head in a figure-8 pattern around your body. 4. Pass the mace between your legs and around each hip. 5. Keep core engaged throughout the rotational movement. 6. Maintain fluid, continuous motion. 7. Start with light weight to master the pattern. 8. Increases rotational power and core stability.',
    'Intermediate',
    'strength',
    NULL
);

-- ============================================
-- 3. JORI/MUGDAR (INDIAN CLUBS) EXERCISES
-- ============================================

-- Jori Basic Swing
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Jori Basic Swing',
    'upper body',
    'jori (indian clubs)',
    'shoulders',
    ARRAY['rotator_cuff', 'upper_back', 'core', 'forearms', 'grip'],
    '1. Stand with feet shoulder-width apart. 2. Hold one mugdar in each hand, or single club for one-handed practice. 3. Arms extended in front at shoulder height. 4. Swing clubs backward and forward in controlled motion. 5. Keep core tight and shoulders stable. 6. Coordinate breathing with movement. 7. Start with 10-15 repetitions per hand. Beginner: 2-3kg per club, Intermediate: 4-5kg, Advanced: 6-12kg+.',
    'Beginner',
    'strength',
    NULL
);

-- Jori Figure 8
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Jori Figure 8',
    'upper body',
    'jori (indian clubs)',
    'shoulders',
    ARRAY['core', 'forearms', 'grip', 'chest'],
    '1. Hold the mugdar with both hands, arms extended in front. 2. Move the club in a figure 8 pattern, crossing smoothly across your body. 3. Keep the motion controlled with engaged core. 4. Complete 10-15 repetitions. 5. Then switch directions. 6. Focus on smooth, continuous motion. Develops shoulder mobility and coordination.',
    'Beginner',
    'strength',
    NULL
);

-- Jori Windmill
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Jori Windmill',
    'full body',
    'jori (indian clubs)',
    'shoulders',
    ARRAY['obliques', 'hamstrings', 'core', 'grip'],
    '1. Hold mugdar in one hand, extended overhead. 2. Bend at hips and lower the club toward the ground. 3. Circle the club around your leg. 4. Return to starting position. 5. Switch hands and repeat. 6. Start with 5-10 reps per side. Develops shoulder flexibility and core stability.',
    'Intermediate',
    'strength',
    NULL
);

-- Jori Circular Swings
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Jori Circular Swings',
    'upper body',
    'jori (indian clubs)',
    'shoulders',
    ARRAY['rotator_cuff', 'forearms', 'grip', 'upper_back'],
    '1. Hold one club in each hand at sides. 2. Begin swinging clubs in circular motions. 3. Circles can be forward, backward, or alternating. 4. Keep wrists firm but not rigid. 5. Maintain controlled tempo throughout. 6. Increases shoulder joint mobility and strengthens rotator cuff. 7. Traditional wrestlers used for joint health and injury prevention.',
    'Beginner',
    'cardio',
    NULL
);

-- ============================================
-- 4. SAMTOLA (INDIAN BARBELL) EXERCISES
-- ============================================

-- Samtola Bicep Curl
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Samtola Bicep Curl',
    'upper body',
    'samtola (indian barbell)',
    'biceps',
    ARRAY['forearms', 'grip'],
    '1. Hold samtola (wooden barbell) with palms facing up at mid-point. 2. Stand with feet shoulder-width apart. 3. Curl upward toward shoulders. 4. Lower with control. 5. Repeat 10-15 times. Samtola means "balanced weight" in Hindi. Traditional equipment made from single log with weighted blocks at both ends. Beginner: 4-8kg, Intermediate: 8-14kg, Advanced: 15-25kg+.',
    'Beginner',
    'strength',
    NULL
);

-- Samtola Overhead Press
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Samtola Overhead Press',
    'upper body',
    'samtola (indian barbell)',
    'shoulders',
    ARRAY['triceps', 'core', 'upper_back'],
    '1. Hold samtola at shoulder height with both hands. 2. Press overhead until arms are fully extended. 3. Lower with control back to shoulders. 4. Repeat 10-15 times. 5. Keep core engaged throughout. Traditional Indian barbell exercise for upper body strength.',
    'Beginner',
    'strength',
    NULL
);

-- Samtola Row
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Samtola Bent Over Row',
    'back',
    'samtola (indian barbell)',
    'latissimus_dorsi',
    ARRAY['biceps', 'rhomboids', 'rear_deltoids', 'core'],
    '1. Bend at hips, keeping back flat. 2. Hold samtola with arms extended down. 3. Pull samtola toward chest, squeezing shoulder blades. 4. Lower with control. 5. Repeat 10-15 times. Keep core engaged and back straight throughout.',
    'Beginner',
    'strength',
    NULL
);

-- Samtola Rotational Swing
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Samtola Rotational Swing',
    'full body',
    'samtola (indian barbell)',
    'core',
    ARRAY['obliques', 'shoulders', 'back', 'hips'],
    '1. Hold samtola with both hands at chest level. 2. Swing in circular pattern around body. 3. Rotate through hips and core. 4. Maintain controlled tempo. 5. Complete 10 rotations each direction. Engages core and builds rotational power essential for wrestling.',
    'Intermediate',
    'strength',
    NULL
);

-- ============================================
-- 5. LATHI (BAMBOO STAFF) EXERCISES
-- ============================================

-- Lathi Basic Handling
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Lathi Basic Staff Handling',
    'upper body',
    'lathi (bamboo staff)',
    'forearms',
    ARRAY['grip', 'shoulders', 'core', 'coordination'],
    '1. Hold the lathi (6-8 foot bamboo staff) at mid-point with dominant hand. 2. Practice grip strength by twirling the staff. 3. Develop coordination through figure-8 patterns. 4. Build endurance through extended holding exercises. 5. Traditional martial art from Punjab, Bengal, and Maharashtra. Silambam (Tamil Nadu) and Gatka (Sikh) are related arts.',
    'Beginner',
    'strength',
    NULL
);

-- Lathi Overhead Stretch
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Lathi Overhead Side Bend',
    'full body',
    'lathi (bamboo staff)',
    'obliques',
    ARRAY['shoulders', 'latissimus_dorsi', 'core'],
    '1. Hold lathi with both hands, wider than shoulder-width. 2. Raise overhead with arms extended. 3. Perform side bends, keeping arms straight. 4. Alternate left and right. 5. Hold each stretch for 2-3 seconds. 6. Repeat 10-15 times each side. Increases flexibility and range of motion.',
    'Beginner',
    'flexibility',
    NULL
);

-- Lathi Balance Training
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Lathi Single-Leg Balance',
    'lower body',
    'lathi (bamboo staff)',
    'core',
    ARRAY['glutes', 'ankle_stabilizers', 'hip_flexors'],
    '1. Hold lathi horizontally at chest height. 2. Perform single-leg stands. 3. Extend non-standing leg forward, backward, or to side. 4. Hold each position for 15-30 seconds. 5. Switch legs and repeat. 6. Progress to walking on uneven surfaces while balancing lathi. Develops proprioception and stability.',
    'Beginner',
    'balance',
    NULL
);

-- ============================================
-- 6. NAL AND GAR NAL EXERCISES
-- ============================================

-- Nal Grip Training
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Nal Stone Lock Lift',
    'upper body',
    'nal (stone lock)',
    'grip',
    ARRAY['forearms', 'biceps', 'core', 'shoulders'],
    '1. Nal is a hollow stone cylinder with interior handle. 2. Insert hand into hollow cylinder and grip interior handle. 3. Lift the nal from ground. 4. Perform various lifting and swinging movements. 5. The hollow design uniquely challenges grip strength. 6. Used for developing crushing grip strength needed in wrestling. Progress from lighter to heavier stones.',
    'Intermediate',
    'strength',
    NULL
);

-- Gar Nal Weighted Squats
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Gar Nal Weighted Baithak',
    'full body',
    'gar nal (stone neck ring)',
    'quadriceps',
    ARRAY['neck', 'trapezius', 'shoulders', 'glutes', 'core'],
    '1. Place stone ring around neck, resting on trapezius muscles. 2. Perform Baithak (Hindu squats) with added resistance. 3. Rise onto balls of feet at bottom of squat. 4. Swing arms for momentum. 5. Start with lighter weight (20-40 lbs). The Great Gama ran one mile daily with 120-pound stone ring. Advanced: 100-200+ lbs. Always work with spotter for heavy weights.',
    'Advanced',
    'strength',
    NULL
);

-- ============================================
-- 7. ROPE EXERCISES
-- ============================================

-- Rassi Chadna (Rope Climbing)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Rassi Chadna (Rope Climbing)',
    'upper body',
    'rope',
    'latissimus_dorsi',
    ARRAY['biceps', 'forearms', 'grip', 'core', 'shoulders', 'chest'],
    '1. Stand at base of rope (15-20 feet), reach up and grab with both hands. 2. Jump up and wrap legs around rope (one foot on top of other to lock). 3. Pinch rope between feet for secure hold. 4. Reach up with one hand, then other, pulling body upward. 5. Simultaneously re-lock feet higher on rope. 6. Continue alternating until reaching top. 7. To descend, reverse motion in controlled manner. 8. Never slide down quickly (rope burn risk). Essential exercise in traditional Indian akharas (wrestling gyms).',
    'Intermediate',
    'strength',
    NULL
);

-- ============================================
-- 8. MALLAKHAMB (POLE GYMNASTICS)
-- ============================================

-- Mallakhamb Basic Mounting
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Mallakhamb Basic Mounting',
    'full body',
    'mallakhamb pole',
    'core',
    ARRAY['grip', 'upper_body', 'lower_body', 'flexibility', 'balance'],
    '1. Mallakhamb is vertical wooden pole (teak or sheesham), 2.6m height, 8-10 inches diameter, smeared with castor oil. 2. Approach pole and grip firmly with both hands. 3. Jump and wrap legs around pole. 4. Use feet and inner thighs to grip and support body. 5. Climb to desired height using alternating hand and leg movements. 6. Practice under guidance of trained instructor. 7. First master basic gymnastics and yoga for flexibility. Ancient Indian sport dating to 12th century Manasollasa text.',
    'Advanced',
    'strength',
    NULL
);

-- Mallakhamb Pole Sit (Danda)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Mallakhamb Pole Sit (Danda)',
    'full body',
    'mallakhamb pole',
    'core',
    ARRAY['inner_thighs', 'grip', 'balance'],
    '1. Grip the pole at comfortable height. 2. Swing legs to wrap around pole. 3. Release hands and balance in seated position on the pole. 4. Core engaged, arms extended for balance. 5. Hold position for as long as possible. 6. Develops exceptional core strength and balance. Competition categories include mounting, acrobatics, catches, balances, and dismounts.',
    'Advanced',
    'balance',
    NULL
);

-- ============================================
-- 9. VYAYAM (YOGA-INFLUENCED EXERCISES)
-- ============================================

-- Surya Namaskar
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Surya Namaskar (Sun Salutation)',
    'full body',
    'bodyweight',
    'full_body',
    ARRAY['chest', 'shoulders', 'core', 'legs', 'back', 'flexibility'],
    '12-pose sequence: 1. Pranamasana (Prayer Pose) - Stand, palms at heart. 2. Hasta Uttanasana - Inhale, arms overhead, slight backbend. 3. Uttanasana - Exhale, forward fold. 4. Ashwa Sanchalanasana - Inhale, right leg back, lunge. 5. Dandasana - Hold breath, plank position. 6. Ashtanga Namaskara - Exhale, lower knees-chest-chin. 7. Bhujangasana - Inhale, cobra pose. 8. Adho Mukha Svanasana - Exhale, downward dog. 9. Ashwa Sanchalanasana - Inhale, right foot forward. 10. Uttanasana - Exhale, forward fold. 11. Hasta Uttanasana - Inhale, rise up. 12. Pranamasana - Exhale, return to prayer. Slow pace builds flexibility, fast pace is cardiovascular.',
    'Beginner',
    'flexibility',
    'https://gymvisual.com/img/p/1/7/0/3/7/17037.gif'
);

-- Chakki Chalanasana
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Chakki Chalanasana (Mill Churning Pose)',
    'core',
    'bodyweight',
    'abdominals',
    ARRAY['obliques', 'lower_back', 'arms', 'shoulders', 'hips', 'hamstrings'],
    '1. Sit on floor with legs extended wide apart (V-shape). 2. Interlock fingers and extend arms straight in front. 3. Keep arms parallel to ground throughout. 4. Begin making large circular motions with torso and arms. 5. Rotate from waist, moving forward then to each side. 6. Imagine turning a traditional grinding stone (chakki). 7. Complete 10 rotations clockwise. 8. Then 10 rotations counter-clockwise. 9. This is one set; perform 2-3 sets. Inhale rotating forward, exhale rotating back. Reduces belly fat, improves digestion. Traditionally prescribed to pregnant women for easier childbirth.',
    'Beginner',
    'flexibility',
    NULL
);

-- Shirshasana
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Shirshasana (Headstand)',
    'full body',
    'bodyweight',
    'core',
    ARRAY['shoulders', 'arms', 'neck', 'back', 'balance'],
    '1. Kneel on floor, interlock fingers and place forearms on mat. 2. Place crown of head on floor, cradled by interlocked hands. 3. Lift knees off floor, walking feet closer to head. 4. Slowly lift one leg at a time (or both for advanced). 5. Extend legs straight up, body in one vertical line. 6. Engage core, press forearms firmly into mat. 7. Hold 30 seconds to 3 minutes as comfortable. 8. To exit, slowly lower legs with control. Called "King of Asanas." Listed in 13th-century Malla Purana as one of 18 asanas for wrestlers. Never perform with neck injuries or high blood pressure.',
    'Advanced',
    'balance',
    NULL
);

-- ============================================
-- 10. KALARIPAYATTU EXERCISES
-- ============================================

-- Gaja Vadivu (Elephant Stance)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Gaja Vadivu (Elephant Stance)',
    'lower body',
    'bodyweight',
    'quadriceps',
    ARRAY['hips', 'thighs', 'spine', 'ankles', 'core'],
    '1. Stand with feet very wide apart. 2. Bend knees deeply into wide squat. 3. Position arms like elephant trunk (one arm extended, other bent at elbow). 4. Keep spine straight, weight distributed evenly. 5. Hold position, building hip and thigh strength. 6. Called "Amarcha" position in Kalaripayattu. One of 8 animal-based Vadivu stances from ancient South Indian martial art. Builds hip, thigh, spine, and ankle strength.',
    'Intermediate',
    'strength',
    NULL
);

-- Simha Vadivu (Lion Stance)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Simha Vadivu (Lion Stance)',
    'lower body',
    'bodyweight',
    'quadriceps',
    ARRAY['glutes', 'core', 'hip_flexors'],
    '1. Low crouching position with weight on balls of feet. 2. Hands positioned like claws, ready to spring. 3. Keep back straight, chest open. 4. Hold position, building leg power. 5. Practice transitioning quickly to standing. 6. One of 8 animal Vadivu stances from Kalaripayattu. Develops leg power and core stability, prepares body for explosive movements.',
    'Intermediate',
    'strength',
    NULL
);

-- Ashwa Vadivu (Horse Stance)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Ashwa Vadivu (Horse Stance)',
    'lower body',
    'bodyweight',
    'quadriceps',
    ARRAY['glutes', 'adductors', 'core'],
    '1. Stand with feet very wide (2-3 shoulder widths). 2. Turn toes slightly outward. 3. Bend knees to 90 degrees or lower. 4. Keep spine vertical, weight distributed evenly. 5. Hold position for time (start 30 seconds, progress to minutes). 6. Arms can be extended forward or at sides. Foundation stance in Kalaripayattu and many martial arts. Develops lower body endurance and mental focus.',
    'Beginner',
    'strength',
    NULL
);

-- Sarpa Vadivu (Snake Stance)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Sarpa Vadivu (Snake Stance)',
    'full body',
    'bodyweight',
    'core',
    ARRAY['hips', 'spine', 'flexibility'],
    '1. Low to ground position with sinuous, snake-like posture. 2. Body weight shifts fluidly between positions. 3. Movements are smooth and continuous. 4. Practice low evasive movements. 5. Develop flexibility and ability to avoid attacks. One of 8 animal Vadivu stances from Kalaripayattu. Develops flexibility, fluidity, and evasion skills.',
    'Intermediate',
    'flexibility',
    NULL
);

-- Kalaripayattu High Kicks
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Kalaripayattu High Kick (Kalugal)',
    'lower body',
    'bodyweight',
    'hip_flexors',
    ARRAY['quadriceps', 'hamstrings', 'glutes', 'core', 'flexibility'],
    '1. Stand in ready position, weight balanced. 2. Chamber leg by raising knee high. 3. Extend leg in controlled high kick. 4. Target forehead height or higher. 5. Return leg with control. 6. Alternate legs. 7. Practice in all directions: front, side, back. 8. There are 12 types of leg exercises (Kalugal) in Kalaripayattu. Develops hip flexibility, leg strength, and balance.',
    'Intermediate',
    'cardio',
    NULL
);

-- ============================================
-- 11. AGRICULTURAL/FARM EXERCISES
-- ============================================

-- Matka Carry (Head)
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Matka Head Carry',
    'full body',
    'matka (water pot)',
    'core',
    ARRAY['neck', 'trapezius', 'shoulders', 'back', 'legs', 'balance'],
    '1. Lift clay pot (matka) filled with water or sand to chest level. 2. Raise it above head and balance on crown of head. 3. Release hands carefully, maintaining balance through core and neck. 4. Walk with controlled steps, spine straight. 5. Start with light weight, increase gradually. Indian village women have carried water pots on heads for centuries - elite loaded carry training now called "rucking" in Western fitness.',
    'Intermediate',
    'strength',
    NULL
);

-- Matka Hip Carry
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Matka Hip Carry',
    'core',
    'matka (water pot)',
    'obliques',
    ARRAY['core', 'hips', 'shoulders', 'legs'],
    '1. Hold matka (or weighted object) at hip level on one side. 2. Walk while maintaining upright posture. 3. Engages core asymmetrically, building anti-lateral flexion strength. 4. Walk for 30-60 seconds per side. 5. Switch sides for balanced training. Modern alternative: sandbag, kettlebell, or weighted bag.',
    'Beginner',
    'strength',
    NULL
);

-- Well Water Drawing
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Kuan Pani Khinchna (Well Water Drawing)',
    'upper body',
    'rope',
    'biceps',
    ARRAY['forearms', 'latissimus_dorsi', 'grip', 'core', 'shoulders', 'upper_back'],
    '1. Stand at anchor point with feet shoulder-width apart. 2. Grasp rope firmly with both hands. 3. Pull rope hand-over-hand, lowering into slight squat. 4. Engage core to stabilize as you pull. 5. Release and repeat in rhythmic fashion. 6. Traditional villagers drew multiple buckets daily. Modern alternative: cable machine, resistance bands, or battle ropes. Develops pulling strength and grip endurance.',
    'Beginner',
    'strength',
    NULL
);

-- ============================================
-- 12. KABADDI CONDITIONING
-- ============================================

-- Kabaddi Squat Jumps
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Kabaddi Squat Jumps',
    'lower body',
    'bodyweight',
    'quadriceps',
    ARRAY['glutes', 'calves', 'hamstrings', 'core'],
    '1. Start in squat position, thighs parallel to ground. 2. Explode upward, jumping as high as possible. 3. Land softly back into squat position. 4. Immediately repeat without pausing. 5. Perform 3 sets of 15-20 reps. Essential for quick movements and tackles in Kabaddi. Develops explosive power for raiding and defending.',
    'Intermediate',
    'plyometrics',
    NULL
);

-- Kabaddi Shuttle Runs
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Kabaddi Shuttle Run',
    'full body',
    'bodyweight',
    'quadriceps',
    ARRAY['hamstrings', 'calves', 'cardiovascular', 'agility'],
    '1. Set up two markers 10-15 meters apart. 2. Sprint to first marker, touch ground. 3. Sprint back to start, touch ground. 4. Repeat for 30-60 seconds. 5. Rest and repeat for 3-5 sets. Mimics raider''s quick bursts in Kabaddi. Develops speed, agility, and cardiovascular endurance. Traditional sport of India now in Asian Games and Pro Kabaddi League.',
    'Intermediate',
    'cardio',
    NULL
);

-- Kabaddi Breath Hold Practice
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Kabaddi Cant Breathing Practice',
    'respiratory',
    'bodyweight',
    'diaphragm',
    ARRAY['core', 'lungs', 'intercostals'],
    '1. Stand or sit in comfortable position. 2. Take deep breath and begin chanting "Kabaddi-Kabaddi-Kabaddi" continuously. 3. Maintain continuous chant without taking new breath. 4. Time how long you can maintain the cant. 5. Practice extending duration. 6. In actual game, raiders must chant continuously while in opponent''s half. Critical for maintaining continuous "Kabaddi" chant during raids. Increases lung capacity and breath control.',
    'Beginner',
    'cardio',
    NULL
);

-- ============================================
-- Grant permissions
-- ============================================

-- Note: Views like exercise_library_cleaned will automatically include
-- these new exercises since they query from exercise_library table

COMMENT ON TABLE exercise_library IS 'Exercise library now includes traditional Indian village exercises (Kushti, Vyayam, Kalaripayattu) added via migration 035';
