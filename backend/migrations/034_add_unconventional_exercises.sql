-- Migration: Add unconventional fitness exercises
-- Created: 2025-12-25
-- Purpose: Add 59 exercises for tire, hay bale, sandbag, and battle rope training
-- Research conducted via web search by database-operations-specialist agents

-- ============================================
-- TIRE EXERCISES (14 exercises)
-- Sources: BOXROX, Iron Bull Strength, Welltech, Garage Gym Reviews, Breaking Muscle
-- ============================================

-- 1. Tire Flip
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Flip',
    'full body',
    'tire',
    'quadriceps',
    ARRAY['hamstrings', 'glutes', 'hip_flexors', 'calves', 'chest', 'trapezius', 'shoulders', 'biceps', 'core'],
    'Position your toes against the tire with feet shoulder-width apart. Bend at the knees and drive your hips back and down into a deep squat position. Place your fingers underneath the tire and secure your grip with palms facing up. Ensure your back is straight and core is braced. Drive through your legs and hips explosively, extending your hips forward rather than lifting straight up. As the tire rises past your waist, quickly transition your hands from an underhand grip to a pushing position on the tire surface. Drive forward as if performing a tackle motion, using momentum to flip the tire over.',
    'Advanced',
    'strength',
    'https://gymvisual.com/img/p/2/0/2/6/8/20268.gif'
);

-- 2. Tire Box Jump
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Box Jump',
    'lower body',
    'tire',
    'quadriceps',
    ARRAY['hamstrings', 'glutes', 'calves', 'core'],
    'Lay the tire flat on its side. Stand facing the tire approximately 1 foot away with feet slightly wider than shoulder-width apart. Drop your hips back and down into a quarter squat, swinging your arms behind you. In one explosive motion, drive through your legs and swing your arms forward as you jump onto the tire. Land softly on the tire with both feet, absorbing the impact by landing in a half-squat position with knees bent. Step or jump back down to the floor, landing in a half squat to absorb shock.',
    'Intermediate',
    'plyometric',
    'https://gymvisual.com/img/p/1/7/8/9/2/17892.gif'
);

-- 3. Tire Sledgehammer Overhead Slams
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Sledgehammer Overhead Slams',
    'full body',
    'tire, sledgehammer',
    'core',
    ARRAY['shoulders', 'lats', 'forearms', 'triceps', 'rhomboids', 'erector_spinae', 'glutes'],
    'Stand facing the tire with feet shoulder-width apart, knees slightly bent. Grip the sledgehammer with your dominant hand near the hammer head and your other hand near the bottom of the handle. Raise the sledgehammer overhead, extending your arms fully. As you swing down, slide your top hand down the handle to meet your bottom hand. Engage your core and use your hips to generate power. Slam the hammer into the center of the tire. Allow the hammer to bounce back naturally and reset. Alternate which hand starts at the top for balanced development.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/1/8/5/4/3/18543.gif'
);

-- 4. Tire Sledgehammer Side Slams
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Sledgehammer Side Slams',
    'full body',
    'tire, sledgehammer',
    'obliques',
    ARRAY['core', 'shoulders', 'lats', 'forearms', 'hips', 'glutes'],
    'Stand in a staggered stance facing the tire at an angle. Grip the sledgehammer with hands spaced apart like a baseball bat grip. Rotate your torso and raise the sledgehammer to the side and overhead in a circular arc. As you swing down, rotate your hips and core powerfully, sliding your top hand down the handle. Slam the hammer onto the tire with controlled force. Allow the hammer to bounce and reset. Complete all reps on one side, then switch your stance and grip to work the opposite side.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/1/8/5/4/4/18544.gif'
);

-- 5. Tire Drag Forward
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Drag Forward',
    'lower body',
    'tire, harness, rope',
    'glutes',
    ARRAY['quadriceps', 'hamstrings', 'core', 'calves', 'hip_flexors'],
    'Attach a rope or chain to the tire. Connect the other end to a weight belt or harness worn around your waist/hips. Stand facing away from the tire with the rope taut. Lean forward slightly and begin walking or running forward, dragging the tire behind you. Maintain a forward lean and drive through your legs with each step. Keep your core engaged and your back straight. Focus on powerful hip extension with each stride. Continue for the desired distance or time.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/2/0/3/1/5/20315.gif'
);

-- 6. Tire Drag Backward
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Drag Backward',
    'lower body',
    'tire, harness, rope',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'core', 'hip_flexors'],
    'Attach a rope or chain to the tire. Connect the other end to a weight belt or harness worn around your waist. Face the tire with the rope taut. Begin walking backward, pulling the tire toward you with each step. Keep your knees slightly bent and drive through your heels. Maintain an upright posture with core engaged. Focus on controlled, powerful steps backward. The backward motion emphasizes quadriceps activation differently than forward dragging.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/2/0/3/1/6/20316.gif'
);

-- 7. Tire Push
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Push',
    'full body',
    'tire',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'shoulders', 'core', 'chest'],
    'Stand the tire upright on its edge. Position yourself behind the tire in an athletic stance with feet shoulder-width apart. Place both hands on the top edge of the tire at chest height. Drive through your legs and lean into the tire, pushing it forward. Keep your core braced and back straight. Take quick, powerful steps to maintain momentum and keep the tire rolling. Focus on leg drive rather than arm pushing. Continue for the desired distance or time.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/2/0/3/2/0/20320.gif'
);

-- 8. Tire Step-Ups
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Step-Ups',
    'lower body',
    'tire',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'core'],
    'Lay the tire flat on the ground. Stand facing the tire with feet shoulder-width apart, arms at your sides or on your hips. Place your right foot firmly on top of the tire edge. Push through your right heel and squeeze your glute to lift your body up onto the tire. Bring your left foot up to meet your right foot, standing fully on the tire. Step down with your left foot first, then your right, returning to the starting position. Alternate the leading leg with each rep.',
    'Beginner',
    'strength',
    'https://gymvisual.com/img/p/1/7/8/9/5/17895.gif'
);

-- 9. Tire Lateral Jumps
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Lateral Jumps',
    'lower body',
    'tire',
    'quadriceps',
    ARRAY['glutes', 'hip_abductors', 'hip_adductors', 'calves', 'core'],
    'Lay the tire flat on the ground. Stand on one side of the tire with feet shoulder-width apart. Perform lateral jumps from one outside edge of the tire, into the inner hole of the tire, and then out to the other outside edge of the tire. Land softly in a half-squat position to absorb impact. Immediately jump back in the opposite direction. Continue alternating side to side for the desired number of reps. Keep your chest up and maintain a slight bend in your knees throughout.',
    'Intermediate',
    'plyometric',
    'https://gymvisual.com/img/p/1/7/9/0/0/17900.gif'
);

-- 10. Tire Quick Feet
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Quick Feet',
    'lower body',
    'tire',
    'calves',
    ARRAY['quadriceps', 'hip_flexors', 'core'],
    'Lay the tire flat on the ground. Stand facing the tire in an athletic stance with feet hip-width apart. Rapidly alternate stepping one foot on top of the tire and back to the floor, then the other foot on the tire and back. Move as quickly as possible while maintaining control. Transfer your weight smoothly from foot to foot. Keep your core engaged and maintain an upright posture. Stay light on your feet with minimal ground contact time.',
    'Beginner',
    'plyometric',
    'https://gymvisual.com/img/p/1/7/9/0/3/17903.gif'
);

-- 11. Tire Center Squat Jump
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Center Squat Jump',
    'lower body',
    'tire',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'core'],
    'Lay a large tire flat on the ground. Stand in the center of the tire (in the hole) in a low squat position with feet shoulder-width apart. From the low squat position, explosively jump straight up and land on the edge/rim of the tire with both feet. Stabilize yourself by landing in a half-squat position. Step or jump back down to the center of the tire, returning to the starting low squat position. Repeat for the desired number of reps.',
    'Intermediate',
    'plyometric',
    'https://gymvisual.com/img/p/1/7/9/0/8/17908.gif'
);

-- 12. Tire Single-Leg Box Jump
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire Single-Leg Box Jump',
    'lower body',
    'tire',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'core', 'hip_stabilizers'],
    'Lay the tire flat on the ground. Stand on one foot facing the tire, approximately one foot away. Balance on your jumping leg with a slight knee bend. Drive your arms back, then explosively swing them forward as you jump off one leg onto the tire. Land on the same single leg on top of the tire, absorbing the impact with a bent knee. Stabilize yourself before stepping or jumping down. Complete all reps on one leg before switching to the other.',
    'Advanced',
    'plyometric',
    'https://gymvisual.com/img/p/1/7/9/1/2/17912.gif'
);

-- 13. Tire-Anchored Battle Rope Waves
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire-Anchored Battle Rope Waves',
    'upper body',
    'tire, battle ropes',
    'shoulders',
    ARRAY['core', 'forearms', 'biceps', 'triceps', 'lats'],
    'Thread the battle rope through the center of a heavy tire laid flat. The tire acts as an anchor. Stand facing the tire at a distance where the ropes have slight slack. Hold one end of the rope in each hand with an overhand grip. Assume an athletic stance with feet shoulder-width apart, knees slightly bent. Rapidly alternate raising and lowering each arm to create waves in the ropes. Keep your core braced and maintain a stable base. Continue creating continuous waves for the desired duration.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/1/5/6/7/8/15678.gif'
);

-- 14. Tire-Anchored Battle Rope Slams
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, gif_url)
VALUES (
    'Tire-Anchored Battle Rope Slams',
    'full body',
    'tire, battle ropes',
    'shoulders',
    ARRAY['core', 'lats', 'forearms', 'triceps', 'chest'],
    'Anchor the battle rope through a heavy tire laid flat on the ground. Stand facing the tire at the appropriate distance, holding one end of the rope in each hand. From an athletic stance, explosively raise both arms overhead together. Forcefully slam both ropes down toward the ground simultaneously, squatting slightly as you slam. Use your entire body - legs, core, and arms - to generate power. Immediately reset and repeat for continuous slams. Maintain a rhythmic, powerful tempo throughout.',
    'Intermediate',
    'conditioning',
    'https://gymvisual.com/img/p/1/5/6/8/0/15680.gif'
);

-- ============================================
-- HAY BALE EXERCISES (14 exercises)
-- Sources: ACE Fitness, Sara Mikulsky PT, CrossFit Games, Garage Strength
-- ============================================

-- 15. Hay Bale Farmer's Carry
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Farmer''s Carry',
    'full body',
    'hay bale',
    'trapezius',
    ARRAY['forearms', 'core', 'quadriceps', 'hamstrings', 'glutes', 'calves', 'erector spinae'],
    'Stand with a hay bale on each side of your body or one bear-hugged to your chest. Squat down and grip the bales firmly with straight arms, keeping your chest up and shoulders back. Drive through your legs to stand up, maintaining a neutral spine. Walk forward with controlled steps for the prescribed distance or time, keeping your core braced and shoulders pulled back. Do not allow the bales to swing or your torso to lean. At the end, squat down to place the bales back on the ground with control.',
    'Beginner',
    'functional'
);

-- 16. Hay Bale Over-Shoulder Throw
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Over-Shoulder Throw',
    'full body',
    'hay bale',
    'glutes',
    ARRAY['hamstrings', 'erector spinae', 'trapezius', 'deltoids', 'core', 'quadriceps', 'forearms'],
    'Stand facing the hay bale with feet slightly wider than shoulder-width apart. Squat down and grip the bale firmly on both sides, keeping your back flat and chest up. In one explosive motion, extend your hips and knees powerfully while pulling the bale upward. As the bale rises past your waist, rotate your torso and throw the bale over one shoulder behind you. The power should come primarily from your legs and hips, not your arms. Turn to face the bale, reset your stance, and repeat on the alternating shoulder.',
    'Advanced',
    'power'
);

-- 17. Standing Hay Baler
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Standing Hay Baler',
    'core',
    'medicine ball, hay bale',
    'obliques',
    ARRAY['rectus abdominis', 'transverse abdominis', 'deltoids', 'trapezius', 'hip flexors'],
    'Stand with legs about hip-width apart. Step one foot forward flat on the ground and position the other leg behind your body on the ball of the foot (staggered stance). Hold a medicine ball or small hay bale in both hands near the hip of your back leg. Keeping both arms straight throughout the entire movement, twist through your chest and shoulders to bring the ball diagonally across your body and up over the opposite shoulder. Control the movement back to the starting position. Complete all reps on one side, then switch your stance to work the opposite side.',
    'Intermediate',
    'core'
);

-- 18. Hay Bale Squat
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Squat',
    'upper legs',
    'hay bale',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'core', 'erector spinae', 'calves'],
    'Stand facing a hay bale with feet shoulder-width apart. Hold the hay bale against your chest in a bear hug grip, or position it on your upper back like a back squat if using a heavier bale. Brace your core and maintain a tall chest. Initiate the squat by pushing your hips back and bending your knees simultaneously. Lower yourself until your thighs are at least parallel to the ground. Drive through your heels to return to the standing position, squeezing your glutes at the top.',
    'Beginner',
    'strength'
);

-- 19. Hay Bale Deadlift
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Deadlift',
    'upper legs',
    'hay bale',
    'hamstrings',
    ARRAY['glutes', 'erector spinae', 'trapezius', 'forearms', 'quadriceps', 'core'],
    'Position the hay bale on the ground in front of you. Stand with feet hip-width apart, toes pointing slightly outward. Hinge at your hips and bend your knees to reach down and grip both sides of the bale firmly. Stack your body in a straight line: shoulders over hips, hips over heels, with a flat back and engaged core. Drive through your heels while extending your hips and knees simultaneously. Keep the bale close to your body as you stand up tall, squeezing your glutes at the top. Reverse the movement by hinging at the hips first.',
    'Intermediate',
    'strength'
);

-- 20. Hay Bale Clean
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Clean',
    'full body',
    'hay bale',
    'trapezius',
    ARRAY['quadriceps', 'glutes', 'hamstrings', 'deltoids', 'core', 'forearms', 'erector spinae'],
    'Position the hay bale on the ground in front of you. Start in a deadlift position with feet shoulder-width apart, hips back, back flat, and arms straight gripping both sides of the bale. Initiate the movement by explosively extending your hips and knees, driving through your heels. As the bale rises past your waist, shrug your shoulders and pull your elbows high. Quickly rotate your elbows under the bale and catch it at chest height in a front rack position. Stand fully upright with the bale secured at your chest.',
    'Advanced',
    'power'
);

-- 21. Hay Bale Overhead Press
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Overhead Press',
    'shoulders',
    'hay bale',
    'deltoids',
    ARRAY['triceps', 'trapezius', 'core', 'serratus anterior'],
    'Clean the hay bale to chest height, securing it against your upper chest with both hands gripping firmly. Stand with feet shoulder-width apart, core braced, and glutes squeezed. Press the bale directly overhead by extending your arms fully, pushing your head slightly forward as the bale passes your face. Lock out your arms at the top with the bale directly over your shoulders and hips. Lower the bale back to chest height with control. Maintain a strong, stable core throughout to protect your lower back.',
    'Intermediate',
    'strength'
);

-- 22. Hay Bale Lunge with Rotation
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Lunge with Rotation',
    'upper legs',
    'hay bale',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'obliques', 'core', 'hip flexors', 'adductors'],
    'Hold a small hay bale or medicine ball at chest height with both hands. Stand with feet hip-width apart. Step forward into a lunge position, lowering your back knee toward the ground until both knees form 90-degree angles. At the bottom of the lunge, rotate your torso toward the forward leg, bringing the bale across your body. Rotate back to center, then drive through your front heel to return to the starting position. Alternate legs with each rep, rotating toward the forward leg each time.',
    'Intermediate',
    'functional'
);

-- 23. Hay Bale Russian Twist
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Russian Twist',
    'core',
    'hay bale',
    'obliques',
    ARRAY['rectus abdominis', 'transverse abdominis', 'hip flexors', 'erector spinae'],
    'Sit on a hay bale with your knees bent and feet flat on the ground. Lean back slightly to engage your core, maintaining a straight back. Hold a small hay bale or weight in front of your chest with both hands, arms slightly bent. Rotate your torso to the right, bringing the weight toward your right hip. Return through center and rotate to the left side. Continue alternating sides in a controlled manner. For added difficulty, lift your feet off the ground.',
    'Beginner',
    'core'
);

-- 24. Hay Bale Clean Burpee
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Clean Burpee',
    'full body',
    'hay bale, hay bale wall',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'core', 'chest', 'triceps', 'deltoids', 'trapezius', 'forearms'],
    'Start standing in front of a hay bale with a hay bale wall (stack of bales) behind it. Squat down and grip the hay bale (100 lbs men, 70 lbs women for competition standard). Explosively clean the bale and throw it over the hay bale wall in one continuous motion. Immediately drop to the ground and perform a burpee (chest to ground, then push up). Jump over the hay bale wall to the other side where your bale landed. Turn, locate the bale, and repeat the sequence. Each clean-throw-burpee-jump counts as one rep.',
    'Elite',
    'conditioning'
);

-- 25. Sheaf Toss
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sheaf Toss',
    'full body',
    'pitchfork, hay bale, sheaf bag',
    'deltoids',
    ARRAY['glutes', 'quadriceps', 'core', 'trapezius', 'erector spinae', 'forearms'],
    'Grip the pitchfork toward the end of the handle with your dominant hand; your other hand provides support slightly below. Stand perpendicular to the bar with feet shoulder-width apart. Insert the pitchfork tines horizontally into the center of the sheaf (16-20 lb bag stuffed with straw). Swing the pitchfork and sheaf backward like a pendulum. Once it reaches behind your body, explosively thrust it upward using your legs, core, and arms. Release the sheaf at the peak of your throw, aiming for maximum height over the bar.',
    'Advanced',
    'power'
);

-- 26. Hay Bale Step-Up
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Step-Up',
    'upper legs',
    'hay bale',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'calves', 'core', 'hip flexors'],
    'Position a stable hay bale on flat ground. Stand facing the bale with feet hip-width apart. Place your entire right foot on top of the bale, ensuring your heel does not hang off. Drive through your right heel to step up onto the bale, bringing your left foot to meet your right at the top. Step down with your left foot first, then your right. Alternate the leading leg with each rep, or complete all reps on one side before switching.',
    'Beginner',
    'functional'
);

-- 27. Hay Bale Shoulder Load
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Hay Bale Shoulder Load',
    'full body',
    'hay bale',
    'trapezius',
    ARRAY['deltoids', 'core', 'biceps', 'forearms', 'erector spinae', 'glutes'],
    'Stand over the hay bale with feet slightly wider than shoulder-width apart. Squat down and grip the bale firmly with both hands, one on each side. Deadlift the bale to hip height, keeping your back flat. In one fluid motion, pull the bale up your body while rotating to load it onto one shoulder. Secure the bale on your shoulder by hugging it with the near arm. You can either hold the position, walk with the bale shouldered, or throw it over your shoulder behind you for power training. Alternate shoulders each set.',
    'Intermediate',
    'strongman'
);

-- 28. Single-Leg Balance on Hay Bale
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Single-Leg Balance on Hay Bale',
    'core',
    'hay bale',
    'core',
    ARRAY['glutes', 'quadriceps', 'calves', 'ankle stabilizers', 'hip abductors'],
    'Position a stable hay bale on flat ground. Step up carefully and stand on top of the bale with both feet. Once stable, shift your weight onto one leg and lift the other foot off the bale. Engage your core for stability and maintain an upright posture. Hold the single-leg stance for the prescribed time (30-60 seconds). For added challenge, close your eyes, perform small knee bends, or reach your free leg in different directions. Switch legs and repeat.',
    'Beginner',
    'balance'
);

-- ============================================
-- SANDBAG EXERCISES (20 exercises)
-- Sources: REP Fitness, NFPT, Onnit, Ultimate Sandbag Training, Navy Fitness
-- ============================================

-- 29. Sandbag Clean
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Clean',
    'full body',
    'sandbag',
    'glutes',
    ARRAY['hamstrings', 'quadriceps', 'trapezius', 'deltoids', 'latissimus dorsi', 'biceps', 'forearms', 'core'],
    'Stand with feet shoulder-width apart, sandbag on the floor between feet. Hinge at hips to grip the sides or handles of the sandbag, keeping back flat and chest up. Pull or rip the handles apart to engage your lats and protect your lower back. Drive through your heels, extending hips and knees explosively. As the bag clears your knees, aggressively pull it upward using hip power to pop the weight up. Dip by bending knees and hips while dropping elbows under the sandbag to catch it in front rack position. Drive through continuing a front squat to full hip extension.',
    'Intermediate',
    'strength'
);

-- 30. Sandbag Shouldering
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Shouldering',
    'full body',
    'sandbag',
    'glutes',
    ARRAY['quadriceps', 'hamstrings', 'core', 'trapezius', 'rhomboids', 'deltoids', 'erector spinae', 'forearms', 'biceps'],
    'Place sandbag lengthways between your feet, aligned with your big toes. Stand with feet shoulder-width apart, toes slightly outward. Lower into a squat-like position keeping chest up, back straight, and eyes forward. Hinge back with neutral spine, keeping hips as far back and high as possible with vertical shins. Pinch shoulder blades to load the posterior chain. Forcefully drive feet into floor, extending hips to standing. Keep elbows and sandbag close to body during acceleration. Explosively shoulder the bag onto one shoulder, standing tall with no rotation. Alternate shoulders each rep.',
    'Advanced',
    'strength'
);

-- 31. Sandbag Bear Hug Carry
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Bear Hug Carry',
    'full body',
    'sandbag',
    'core',
    ARRAY['forearms', 'biceps', 'deltoids', 'trapezius', 'erector spinae', 'quadriceps', 'glutes'],
    'Squat down and wrap your arms around the sandbag, hugging it tightly to your chest. Clasp your hands together around the bag. Stand up by driving through your heels while keeping the bag pressed firmly against your torso. Walk with small, controlled steps maintaining an upright posture. Keep your core braced and ribs down throughout. Breathe steadily despite chest compression from the bag.',
    'Beginner',
    'strength'
);

-- 32. Sandbag Shoulder Carry
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Shoulder Carry',
    'full body',
    'sandbag',
    'core',
    ARRAY['deltoids', 'trapezius', 'obliques', 'erector spinae', 'quadriceps', 'glutes', 'hip stabilizers'],
    'Clean or shoulder the sandbag onto one shoulder. Secure it with one or both arms wrapped around or over the bag. Stand tall with an upright, athletic posture. Keep your core engaged to resist lateral flexion from the offset load. Walk with controlled steps, maintaining balance despite asymmetric loading. Switch shoulders halfway through or between sets to work both sides equally.',
    'Intermediate',
    'strength'
);

-- 33. Sandbag Zercher Carry
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Zercher Carry',
    'full body',
    'sandbag',
    'core',
    ARRAY['biceps', 'forearms', 'erector spinae', 'latissimus dorsi', 'quadriceps', 'glutes'],
    'Deadlift the sandbag and position it horizontally in the crook of your elbows. Flex your arms to secure the bag against your chest. Keep your elbows up so the sandbag stays at chest level. Stand tall with core braced and back straight. Walk with controlled steps, resisting the pull to round forward. Maintain steady breathing despite the demanding front-loaded position.',
    'Intermediate',
    'strength'
);

-- 34. Sandbag Turkish Get-Up
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Get-Up',
    'full body',
    'sandbag',
    'core',
    ARRAY['glutes', 'obliques', 'deltoids', 'triceps', 'quadriceps', 'hamstrings', 'hip flexors'],
    'Lie on your back with sandbag resting over one shoulder, holding it with that hand. Bend knee on same side with opposite arm flat on floor and leg outstretched. Roll toward your free side, using momentum to get onto your elbow. Progress from elbow to hand, then lift hips to form a bridge. Sweep your extended leg underneath, positioning on that knee. Remove hand from floor into kneeling lunge position. Drive through front foot to stand tall. Reverse the entire movement slowly to return to start.',
    'Advanced',
    'strength'
);

-- 35. Sandbag Front Squat
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Front Squat',
    'legs',
    'sandbag',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'core', 'erector spinae', 'deltoids'],
    'Clean the sandbag to front rack position or pick it up from either end and lift in front of chest. Hold with elbows up and pointing forward, bag resting against upper chest and shoulders. Stand with feet shoulder-width apart. Keep core engaged and chest up. Squat down by bending at hips and knees simultaneously, keeping weight on heels. Lower until crease of hip passes below knee. Maintain upright posture throughout - the front load helps keep you vertical. Drive through heels to stand back up, fully extending hips at top.',
    'Beginner',
    'strength'
);

-- 36. Sandbag Goblet Squat
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Goblet Squat',
    'legs',
    'sandbag',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'core', 'deltoids', 'biceps'],
    'Stand upright with feet slightly wider than shoulder-width. Hold the sandbag vertically in front of chest, cupping it with both hands like a goblet. Keep shoulders down and back, head up looking forward. Lower your hips by pushing knees outward, tracking over toes. Squat down until hips are below knee level. Keep chest up and core braced throughout descent. Press through feet, especially heels, to return to standing position.',
    'Beginner',
    'strength'
);

-- 37. Sandbag Walking Lunge
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Walking Lunge',
    'legs',
    'sandbag',
    'glutes',
    ARRAY['quadriceps', 'hamstrings', 'core', 'hip stabilizers', 'deltoids'],
    'Position sandbag across shoulders, resting on upper back. Stand with feet shoulder-width apart. Step forward with one leg, lowering your hips until rear knee nearly touches ground. Ensure front knee tracks over toes and whole front foot makes contact with ground. Keep trailing knee directly underneath hips in a stacked position. Push off front foot and lunge forward with opposite leg. Continue walking forward alternating legs. Keep core engaged to prevent wobbles and maintain balance.',
    'Intermediate',
    'strength'
);

-- 38. Sandbag Reverse Lunge
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Reverse Lunge',
    'legs',
    'sandbag',
    'glutes',
    ARRAY['quadriceps', 'hamstrings', 'core', 'hip stabilizers'],
    'Position sandbag across shoulders or hold in front rack position. Stand with feet hip-width apart. Step backward with one leg, lowering until rear knee nearly touches ground. Keep front knee tracking over toes and torso upright. Drive through front heel, squeezing glutes, to return to starting position. Complete all reps on one side or alternate legs.',
    'Beginner',
    'strength'
);

-- 39. Sandbag Rotational Lunge
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Rotational Lunge',
    'full body',
    'sandbag',
    'glutes',
    ARRAY['quadriceps', 'hamstrings', 'obliques', 'core', 'hip stabilizers'],
    'Hold sandbag at chest level with both hands. Step back into a reverse lunge position. As you lower, rotate your torso and the sandbag toward your front leg. Keep front knee tracking over toes. Rotate back to center as you drive through front heel to return to standing. Alternate legs each rep or complete all reps on one side first.',
    'Intermediate',
    'strength'
);

-- 40. Sandbag Deadlift
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Deadlift',
    'back',
    'sandbag',
    'hamstrings',
    ARRAY['glutes', 'erector spinae', 'quadriceps', 'trapezius', 'forearms', 'core'],
    'Position sandbag so feet are slightly underneath it. Stand with feet shoulder-width apart, toes slightly out. Bend at knees and hips, keeping hips higher than knees, to grip handles. Pull hands apart to engage lats and set back flat. Keep chest up and shoulders back. Push through feet and extend hips and knees to stand, keeping sandbag close to body. Fully extend hips and squeeze glutes at top. Lower by hinging at hips, pushing butt back while maintaining flat back.',
    'Beginner',
    'strength'
);

-- 41. Sandbag Bent Over Row
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Bent Over Row',
    'back',
    'sandbag',
    'latissimus dorsi',
    ARRAY['trapezius', 'rhomboids', 'rear deltoids', 'biceps', 'forearms', 'erector spinae', 'core'],
    'Stand with feet hip-width apart, weight on heels. Hinge at hips with knees slightly bent until torso is nearly parallel to floor. Grab sandbag with both hands, keeping back flat, shoulders packed, and core braced. Activate lats and pull elbows back toward body, squeezing shoulder blades together. Stop when bag reaches torso. Lower with control, maintaining the hinged position throughout. Do not round spine at any point.',
    'Beginner',
    'strength'
);

-- 42. Sandbag Ground to Overhead
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Ground to Overhead',
    'full body',
    'sandbag',
    'glutes',
    ARRAY['hamstrings', 'quadriceps', 'deltoids', 'triceps', 'trapezius', 'core', 'erector spinae'],
    'Start with sandbag on floor between feet. Hinge at hips and squat slightly to grip sides or handles. Brace core and keep chest up. Drive explosively through legs and hips to lift sandbag off floor. Continue upward motion by extending hips while pulling bag close to body. Transition smoothly into front rack position. Press or push-jerk the sandbag overhead until arms are fully extended and stable. Lower with control back to floor and repeat.',
    'Advanced',
    'strength'
);

-- 43. Sandbag Clean and Press
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Clean and Press',
    'full body',
    'sandbag',
    'deltoids',
    ARRAY['glutes', 'hamstrings', 'quadriceps', 'trapezius', 'triceps', 'core', 'latissimus dorsi'],
    'Stand with feet hip-width apart, sandbag on floor. Grip handles and use lower body to propel bag up. Flip the bag and catch it at chest level in front rack position. Go into a shallow squat to absorb the weight. Stand and press the sandbag overhead until arms are fully extended. Lower bag back to chest, then to floor with control. Each rep is a complete clean followed by a press.',
    'Advanced',
    'strength'
);

-- 44. Sandbag Thruster
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Thruster',
    'full body',
    'sandbag',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'deltoids', 'triceps', 'core'],
    'Hold sandbag in front rack position at chest level. Stand with feet shoulder-width apart. Descend into a full front squat, keeping chest up and elbows high. At the bottom, explosively drive through heels to stand. Use the momentum from standing to press the sandbag overhead in one fluid motion. Lock arms out fully overhead. Lower bag back to front rack position and immediately descend into next squat rep.',
    'Intermediate',
    'strength'
);

-- 45. Sandbag Overhead Slam
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Overhead Slam',
    'full body',
    'sandbag',
    'core',
    ARRAY['latissimus dorsi', 'deltoids', 'triceps', 'glutes', 'hip flexors', 'forearms'],
    'Stand with feet shoulder-width apart, sandbag on floor. Deadlift the bag and drive it overhead using explosive hip extension. Reach full triple extension: ankles, knees, and hips. At peak height, forcefully slam the sandbag down to the floor in front of you. Engage your core and lats to power the slam. Immediately pick up bag and repeat. Keep the movement explosive and continuous.',
    'Intermediate',
    'power'
);

-- 46. Sandbag Rotational Throw
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Rotational Throw',
    'full body',
    'sandbag, wall',
    'obliques',
    ARRAY['core', 'deltoids', 'hip rotators', 'glutes', 'quadriceps'],
    'Stand perpendicular to wall, feet shoulder-width apart, holding sandbag at waist with soft bend in arms and knees. Load into trail hip and rotate shoulders back. Explosively rotate through hips first, then shoulders, throwing sandbag into wall. The goal is powerful hip rotation with a relatively stiff core. Catch the rebound or pick up bag and repeat. Complete all reps on one side, then switch.',
    'Intermediate',
    'power'
);

-- 47. Sandbag Drag
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Drag',
    'legs',
    'sandbag',
    'glutes',
    ARRAY['hamstrings', 'quadriceps', 'core', 'grip', 'forearms'],
    'Place sandbag behind you with handles accessible. Get into athletic stance with feet shoulder-width apart. Reach back and grip handles firmly. Drive through heels, extend hips, and walk forward dragging the sandbag behind you. Keep torso upright and core braced. Maintain steady, powerful steps for designated distance or time.',
    'Beginner',
    'conditioning'
);

-- 48. Sandbag Over Shoulder Toss
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Sandbag Over Shoulder Toss',
    'full body',
    'sandbag',
    'glutes',
    ARRAY['hamstrings', 'erector spinae', 'trapezius', 'deltoids', 'core', 'hip extensors'],
    'Stand over sandbag with feet slightly wider than shoulder-width. Hinge at hips and grip the bag handles or sides. Brace core and keep back flat. Explosively extend hips and throw the sandbag up and over one shoulder, releasing at peak extension. The bag should land behind you. Turn around, reset, and repeat, alternating shoulders.',
    'Advanced',
    'power'
);

-- ============================================
-- BATTLE ROPE EXERCISES (11 exercises)
-- Sources: SET FOR SET, Muscle & Strength, ACE Fitness Research, Onnit Academy
-- ============================================

-- 49. Battle Rope Alternating Waves
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, video_s3_path)
VALUES (
    'Battle Rope Alternating Waves',
    'full body',
    'battle ropes',
    'shoulders',
    ARRAY['forearms', 'biceps', 'triceps', 'core', 'lats'],
    'Stand with feet shoulder-width apart, knees slightly bent in an athletic stance. Hold one end of the battle rope in each hand with palms facing each other. Brace your core and begin alternately raising and lowering each arm explosively, creating waves that travel down the rope to the anchor point. The movement should originate from the shoulders rather than the lower arms. Keep your spine neutral and maintain the wave pattern with consistent rhythm. Continue for the prescribed duration.',
    'Beginner',
    'cardio',
    'https://www.youtube.com/embed/4i-vBYXuFho?rel=0'
);

-- 50. Battle Rope Double Waves
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, video_s3_path)
VALUES (
    'Battle Rope Double Waves',
    'full body',
    'battle ropes',
    'shoulders',
    ARRAY['forearms', 'triceps', 'lats', 'core', 'biceps'],
    'Stand in an athletic stance with knees slightly bent and feet shoulder-width apart, holding a rope in each hand. With both arms moving together simultaneously, drive both ropes downward to the floor using your arms while absorbing the impact with your legs. Immediately reverse the motion and bring both arms up together to create synchronized waves. Keep core tension throughout and maintain a consistent rhythm. Continue for the prescribed duration.',
    'Intermediate',
    'cardio',
    'https://www.youtube.com/embed/3vQMDpPCxEI?rel=0'
);

-- 51. Battle Rope Slams
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Slams',
    'full body',
    'battle ropes',
    'shoulders',
    ARRAY['lats', 'core', 'triceps', 'forearms', 'glutes', 'quadriceps', 'hamstrings'],
    'Stand with feet shoulder-width apart, holding the battle rope ends at your sides. In an explosive movement, bring both ropes upward above your head with a small jump. At the top of the movement, immediately descend into a squat position while forcefully slamming the ropes downward to the ground as hard and fast as possible. The goal is maximum force generation. Return to standing and repeat with explosive power for each repetition.',
    'Advanced',
    'cardio'
);

-- 52. Battle Rope Circles
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Circles',
    'upper body',
    'battle ropes',
    'shoulders',
    ARRAY['forearms', 'biceps', 'lats', 'traps', 'core', 'chest'],
    'Stand with feet shoulder-width apart and knees slightly bent. Grasp the rope ends with palms facing down. Lift your arms to shoulder height and move them in circular motions - your right arm circles clockwise and your left arm circles counter-clockwise simultaneously, creating spiral patterns in the ropes. Perform clockwise circles for 30 seconds, then reverse direction for another 30 seconds. Maintain consistent circle size and speed throughout.',
    'Intermediate',
    'cardio'
);

-- 53. Battle Rope Snakes
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Snakes',
    'upper body',
    'battle ropes',
    'shoulders',
    ARRAY['chest', 'forearms', 'rear delts', 'rhomboids', 'core'],
    'Stand facing the anchor point with feet slightly wider than shoulder-width apart, holding the ropes by your sides. Lower into a quarter squat position and pull your arms wide, keeping them parallel to the floor at hip height. Without crossing your hands, move your arms in toward each other and then back out in a horizontal fly-like motion. Move quickly to create snake-like patterns on the floor with the ropes.',
    'Intermediate',
    'cardio'
);

-- 54. Battle Rope Jumping Jacks
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, video_s3_path)
VALUES (
    'Battle Rope Jumping Jacks',
    'full body',
    'battle ropes',
    'shoulders',
    ARRAY['calves', 'quadriceps', 'hamstrings', 'glutes', 'adductors', 'core', 'forearms', 'lats', 'triceps'],
    'Stand in an athletic position holding each end of the rope at your sides. Begin performing a jumping jack while holding the battle ropes. As you jump your feet out wide, raise your arms and the ropes above your head in an arc, bringing them together at the top. As you jump feet back together, bring the ropes back down to your sides. Maintain a consistent rhythm and continue for the prescribed duration.',
    'Intermediate',
    'cardio',
    'https://www.youtube.com/embed/hDwOcrICzfc?rel=0'
);

-- 55. Battle Rope Side-to-Side Waves
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Side-to-Side Waves',
    'full body',
    'battle ropes',
    'core',
    ARRAY['obliques', 'shoulders', 'forearms', 'chest', 'lats', 'hips'],
    'Stand with feet shoulder-width apart, knees slightly bent, holding both rope ends together in front of your body. Keeping your hips stationary, forcefully swing the ropes to your right side, then immediately swing them to your left side, creating horizontal wave patterns. The movement should come from your core and shoulders while your lower body remains stable. Continue alternating sides with power and control.',
    'Intermediate',
    'cardio'
);

-- 56. Battle Rope Grappler Throws
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Grappler Throws',
    'full body',
    'battle ropes',
    'core',
    ARRAY['obliques', 'shoulders', 'hips', 'lats', 'forearms', 'glutes'],
    'Grab both rope ends so they stick out from between your thumb and index fingers (microphone grip) and hold them down by your right hip. In one powerful motion, pivot on your feet and rotate your hips while throwing the ropes up and over to your left hip, mimicking the motion of throwing an opponent over your hip in grappling. The power should come from your hip rotation and core, not just your arms. Repeat the throw from left to right, alternating sides.',
    'Advanced',
    'cardio'
);

-- 57. Battle Rope Hip Toss
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Hip Toss',
    'full body',
    'battle ropes',
    'core',
    ARRAY['obliques', 'shoulders', 'hips', 'glutes', 'lats', 'forearms'],
    'Stand sideways to the anchor point with feet shoulder-width apart. Hold both rope ends at your hip closest to the anchor. Rotate your hips and core explosively while swinging the ropes in an arc up and over to your opposite hip. The motion mimics tossing someone over your hip. Focus on generating power from your hips and core rather than your arms. Perform all reps on one side, then switch to the other side.',
    'Advanced',
    'cardio'
);

-- 58. Battle Rope Squat to Press
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Squat to Press',
    'full body',
    'battle ropes',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'shoulders', 'core', 'forearms', 'calves'],
    'Stand with feet shoulder-width apart, holding the battle rope ends at shoulder height. Descend into a full squat while keeping the ropes at shoulder level. As you drive up explosively from the squat, press the ropes overhead while creating waves. At the top of the movement, the ropes should be extended above your head. Lower the ropes back to shoulders as you descend into the next squat. Maintain a powerful rhythm throughout.',
    'Advanced',
    'cardio'
);

-- 59. Battle Rope Lunges with Waves
INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
VALUES (
    'Battle Rope Lunges with Waves',
    'full body',
    'battle ropes',
    'quadriceps',
    ARRAY['glutes', 'hamstrings', 'shoulders', 'core', 'forearms', 'calves'],
    'Stand holding a battle rope in each hand with a neutral grip. Begin performing alternating waves with your arms. While maintaining the continuous wave pattern, step back into a reverse lunge with your right leg, lowering until your back knee nearly touches the ground. Press through your front heel to return to standing, then immediately step back with your left leg into a reverse lunge. Continue alternating legs while maintaining rapid alternating waves throughout.',
    'Advanced',
    'cardio'
);

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
-- Note: RLS is already enabled on exercise_library table (see 008_enable_rls_security.sql)
-- The existing policies allow public read access

COMMENT ON TABLE exercise_library IS 'Extended with 59 unconventional exercises (tire, hay bale, sandbag, battle rope) on 2025-12-25';
