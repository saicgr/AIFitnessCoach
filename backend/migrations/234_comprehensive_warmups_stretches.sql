-- Migration: 234_comprehensive_warmups_stretches.sql
-- Created: 2025-02-09
-- Purpose: Add ~150 comprehensive warmup, stretch, mobility, and cardio exercises
-- Categories: Treadmill, Stepper, Bike, Elliptical, Rowing, Bar Hangs, Jump Rope,
--             Dynamic Warmups, Static Stretches, Foam Roller, Mobility Drills, Yoga

-- ============================================
-- 1. TREADMILL VARIATIONS (10 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Treadmill Steep Incline Walk', 'cardio', 'treadmill', 'glutes',
     ARRAY['hamstrings', 'calves', 'core', 'hip_flexors'],
     'Set incline to 10-15% and speed to 2.5-3.0 mph. Do NOT hold handrails — forces glutes and core to stabilize. Keep chest upright, take deliberate heel-to-toe steps, drive through glutes each stride. Mimics hill hiking, excellent for posterior chain activation. Start with 5 min, build to 15. Avoid if you have Achilles tendon issues.',
     'Beginner', 'cardio'),

    ('Treadmill Backward Walk', 'cardio', 'treadmill', 'quadriceps',
     ARRAY['glutes', 'hip_flexors', 'calves', 'core'],
     'Set speed to 1.0-1.5 mph with 0% incline. Hold side rails lightly for balance and carefully turn to face the console. Walk backward with small, controlled steps. Recruits more quadriceps and hip flexors than forward walking. Keep core engaged and eyes on the console display. Excellent for knee rehab and VMO activation. Start with 2 minutes and build up.',
     'Beginner', 'cardio'),

    ('Treadmill Side Shuffle Left', 'cardio', 'treadmill', 'abductors',
     ARRAY['adductors', 'glutes', 'calves', 'core'],
     'Set speed to 2.0-3.0 mph and 0% incline. Turn sideways with left shoulder facing forward. Maintain a slight knee bend and shuffle laterally. Lightly touch the handrail for balance only. Engages hip abductors and adductors for lateral stability. Keep hips level and avoid crossing feet. Do 1-2 minutes per side.',
     'Intermediate', 'cardio'),

    ('Treadmill Side Shuffle Right', 'cardio', 'treadmill', 'abductors',
     ARRAY['adductors', 'glutes', 'calves', 'core'],
     'Set speed to 2.0-3.0 mph and 0% incline. Turn sideways with right shoulder facing forward. Maintain a slight knee bend and shuffle laterally. Lightly touch the handrail for balance only. Engages hip abductors and adductors for lateral stability. Keep hips level and avoid crossing feet. Do 1-2 minutes per side.',
     'Intermediate', 'cardio'),

    ('Treadmill Power Walk', 'cardio', 'treadmill', 'glutes',
     ARRAY['hamstrings', 'calves', 'quadriceps', 'core'],
     'Set speed to 3.5-4.5 mph with 1-3% incline. Pump your arms vigorously at 90-degree angles. Land heel-to-toe with long strides. Keep core braced and shoulders back. Heart rate should reach 60-70% of max. Great transitional warmup before running. Maintain for 5-10 minutes.',
     'Beginner', 'cardio'),

    ('Treadmill High Knee Walk', 'cardio', 'treadmill', 'hip_flexors',
     ARRAY['quadriceps', 'core', 'calves', 'glutes'],
     'Set speed to 2.0-2.5 mph and 0% incline. With each step, drive your knee up to hip height before placing foot down. Keep torso upright and core tight. Swing opposite arm forward as knee comes up. Excellent for hip flexor activation and core engagement. Use handrail lightly if needed for balance. Do 2-3 minutes as warmup.',
     'Beginner', 'cardio'),

    ('Treadmill Incline Jog', 'cardio', 'treadmill', 'glutes',
     ARRAY['hamstrings', 'quadriceps', 'calves', 'core'],
     'Set incline to 4-8% and speed to 4.5-5.5 mph. Lean slightly forward from the ankles, not the waist. Shorten your stride compared to flat running. Drive knees up and push off with the balls of your feet. This builds significant posterior chain strength. Keep breathing steady and rhythmic. Start with 3 minutes, build to 10.',
     'Intermediate', 'cardio'),

    ('Treadmill Walking Lunge', 'cardio', 'treadmill', 'quadriceps',
     ARRAY['glutes', 'hamstrings', 'core', 'hip_flexors'],
     'Set speed to 1.0-1.5 mph with 0% incline. Perform alternating walking lunges on the moving belt. Step forward, lower back knee toward belt, then drive up through the front heel. Keep torso upright and core braced. Use handrails for balance if needed. Excellent lower body warmup that combines mobility and activation. Do 10-12 lunges per leg.',
     'Intermediate', 'cardio'),

    ('Treadmill Tempo Run', 'cardio', 'treadmill', 'quadriceps',
     ARRAY['hamstrings', 'calves', 'glutes', 'core', 'hip_flexors'],
     'Set speed to 7.0-8.5 mph at 1% incline to simulate outdoor conditions. Run at a comfortably hard pace — you should be able to say short phrases but not hold a conversation. Focus on quick turnover with 170-180 steps per minute. Keep arms at 90 degrees swinging forward, not across the body. Maintain for 10-20 minutes.',
     'Advanced', 'cardio'),

    ('Treadmill Gradient Pyramid', 'cardio', 'treadmill', 'glutes',
     ARRAY['hamstrings', 'quadriceps', 'calves', 'core'],
     'Walk at 3.0-3.5 mph. Start at 0% incline, increase by 2% every minute up to 12%, then decrease by 2% every minute back to 0%. Do NOT hold handrails. This pyramids posterior chain demand and heart rate. Keep chest upright and take full heel-to-toe steps throughout. Total duration approximately 12 minutes.',
     'Intermediate', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 2. STEPPER / STAIRMASTER VARIATIONS (7 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('StairMaster Skip Step', 'cardio', 'stair_climber', 'glutes',
     ARRAY['quadriceps', 'hamstrings', 'hip_flexors', 'calves'],
     'Skip every other step on the stair climber to increase stride length and glute engagement. Step up with one leg and drive the opposite knee high before placing it down two steps up. Keep torso upright and avoid leaning on the rails. Set level to 6-8. This mimics bounding and builds explosive hip extension. Do 3-5 minutes.',
     'Intermediate', 'cardio'),

    ('StairMaster Crossover Step', 'cardio', 'stair_climber', 'adductors',
     ARRAY['abductors', 'glutes', 'obliques', 'core'],
     'Turn slightly sideways on the stair climber. Cross your trailing foot over the lead foot onto the next step, alternating which foot leads. Hold the handle lightly for balance. This engages the inner and outer thighs plus obliques. Keep hips level and core tight. Set level to 5-7. Switch sides halfway through. Do 2-3 minutes per side.',
     'Intermediate', 'cardio'),

    ('StairMaster Lateral Step Left', 'cardio', 'stair_climber', 'abductors',
     ARRAY['adductors', 'glutes', 'calves', 'core'],
     'Turn your body 90 degrees so your left side faces the console. Step up sideways, leading with the left foot and bringing the right foot to meet it on each step. Keep knees slightly bent and core engaged. Hold the rail lightly. Targets hip abductors and adductors. Set level to 5-7. Do 2 minutes per side.',
     'Intermediate', 'cardio'),

    ('StairMaster Lateral Step Right', 'cardio', 'stair_climber', 'abductors',
     ARRAY['adductors', 'glutes', 'calves', 'core'],
     'Turn your body 90 degrees so your right side faces the console. Step up sideways, leading with the right foot and bringing the left foot to meet it on each step. Keep knees slightly bent and core engaged. Hold the rail lightly. Targets hip abductors and adductors. Set level to 5-7. Do 2 minutes per side.',
     'Intermediate', 'cardio'),

    ('StairMaster Calf Raise Step', 'cardio', 'stair_climber', 'calves',
     ARRAY['quadriceps', 'glutes', 'core'],
     'With each step on the stair climber, push up onto the ball of your foot and perform a calf raise at the top of the movement before stepping to the next step. Keep core tight and avoid leaning on rails. Set level to 4-6. This adds targeted calf work to your stair climbing. Do 3-5 minutes.',
     'Intermediate', 'cardio'),

    ('StairMaster Double Step Sprint', 'cardio', 'stair_climber', 'quadriceps',
     ARRAY['glutes', 'hamstrings', 'calves', 'core'],
     'Set stair climber to level 10-14. Take two steps at a time with an explosive drive. Push hard through the heel and drive the opposite knee up. No hands on the rails. This is a high-intensity variation that builds power and cardiovascular capacity. Do 30-second bursts with 30 seconds of normal stepping for recovery.',
     'Advanced', 'cardio'),

    ('StairMaster Slow Deep Step', 'cardio', 'stair_climber', 'glutes',
     ARRAY['quadriceps', 'hamstrings', 'core'],
     'Set stair climber to level 3-5. Take slow, deliberate steps, fully extending the hip on each stride. Focus on squeezing the glute at the top of each step. Keep torso tall and core engaged. No rail holding. This slow tempo maximizes time under tension for the glutes and quads. Do 5-10 minutes as a warmup.',
     'Beginner', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 3. STATIONARY BIKE / CYCLING VARIATIONS (6 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Stationary Bike Light Spin', 'cardio', 'stationary_bike', 'quadriceps',
     ARRAY['calves', 'hamstrings'],
     'Pedal at very low resistance (level 1-3) with 60-70 RPM. Keep back straight and shoulders relaxed. Use this as a 5-minute warmup to increase blood flow to the legs without fatiguing them. Ideal before a leg workout. Hands resting lightly on handlebars.',
     'Beginner', 'cardio'),

    ('Stationary Bike Standing Climb', 'cardio', 'stationary_bike', 'glutes',
     ARRAY['quadriceps', 'hamstrings', 'calves', 'core'],
     'Increase resistance to level 7-10 and stand up off the saddle. Maintain 60-70 RPM while standing. Grip the handlebars firmly and shift weight over the pedals. Keep core tight and avoid excessive swaying. This engages more glute and hamstring than seated cycling. Alternate 30 seconds standing with 30 seconds seated.',
     'Intermediate', 'cardio'),

    ('Stationary Bike Single Leg Drill', 'cardio', 'stationary_bike', 'quadriceps',
     ARRAY['hip_flexors', 'hamstrings', 'calves'],
     'Unclip or rest one foot on the frame while pedaling with the other leg only. Use light resistance (level 3-5) and aim for 50-60 RPM. This isolates each leg, exposing and correcting strength imbalances. Focus on pulling through the bottom of the pedal stroke. Do 30 seconds per leg, alternating for 3-5 rounds.',
     'Intermediate', 'cardio'),

    ('Stationary Bike High Cadence Spin', 'cardio', 'stationary_bike', 'quadriceps',
     ARRAY['calves', 'hip_flexors', 'hamstrings'],
     'Set resistance to low-moderate (level 3-5) and pedal at 100-120 RPM. Stay seated with a stable core. Focus on smooth, circular pedal strokes without bouncing in the saddle. This develops neuromuscular efficiency and fast-twitch fiber recruitment. Maintain for 1-2 minute intervals with 1-minute easy spinning between.',
     'Intermediate', 'cardio'),

    ('Recumbent Bike Easy', 'cardio', 'stationary_bike', 'quadriceps',
     ARRAY['hamstrings', 'calves'],
     'Sit back in the recumbent bike with lower back fully supported. Pedal at 60-80 RPM with low resistance (level 2-4). This is a low-impact option ideal for those with lower back issues. Keep feet flat on the pedals and push through the heels. Great for warmup or active recovery. Maintain for 5-15 minutes.',
     'Beginner', 'cardio'),

    ('Stationary Bike Tabata Sprint', 'cardio', 'stationary_bike', 'quadriceps',
     ARRAY['glutes', 'hamstrings', 'calves', 'core'],
     'Perform Tabata intervals: 20 seconds all-out sprint at maximum resistance (level 8-12) and 110+ RPM, followed by 10 seconds complete rest or very easy spin. Repeat 8 rounds for a total of 4 minutes. Stay seated or stand during sprints. This is maximum intensity — not suitable as a warmup. Heart rate will reach 90-100% max.',
     'Advanced', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 4. ELLIPTICAL VARIATIONS (4 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Elliptical Reverse Stride', 'cardio', 'elliptical', 'hamstrings',
     ARRAY['glutes', 'calves', 'quadriceps'],
     'Pedal backward on the elliptical at moderate resistance (level 4-6). Maintain 120-140 strides per minute. This reverse motion shifts emphasis to the hamstrings and glutes. Keep core braced and posture upright. Use the handles lightly. Great variation to alternate with forward striding. Do 3-5 minutes.',
     'Beginner', 'cardio'),

    ('Elliptical High Incline Forward', 'cardio', 'elliptical', 'glutes',
     ARRAY['quadriceps', 'hamstrings', 'calves', 'core'],
     'Set incline to maximum (15-20 on most machines) with moderate resistance (level 5-7). Stride forward at 100-120 SPM. The high incline dramatically increases glute and hamstring recruitment. Push through the heels and keep torso upright. Grip handles for upper body engagement. Excellent for posterior chain activation. Do 5-10 minutes.',
     'Intermediate', 'cardio'),

    ('Elliptical No Hands', 'cardio', 'elliptical', 'core',
     ARRAY['quadriceps', 'glutes', 'hamstrings', 'calves'],
     'Release the handles and place hands on hips or let arms swing naturally. Use moderate resistance (level 4-6) and stride at 120-140 SPM. Without handles your core must work significantly harder to maintain balance and upright posture. Keep abs braced and avoid leaning. Great for core activation. Start with 2 minutes and build up.',
     'Intermediate', 'cardio'),

    ('Elliptical Interval Bursts', 'cardio', 'elliptical', 'quadriceps',
     ARRAY['glutes', 'hamstrings', 'calves', 'biceps', 'triceps'],
     'Alternate 30 seconds at high resistance (level 8-10) and maximum stride rate with 60 seconds at low resistance (level 3-4) and easy pace. Use the arm handles actively during the hard intervals. Push and pull with arms while driving with legs for full-body engagement. Repeat 6-8 rounds. Total time 9-12 minutes.',
     'Advanced', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 5. ROWING WARMUP VARIATIONS (3 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Rowing Machine Legs Only', 'cardio', 'rowing_machine', 'quadriceps',
     ARRAY['glutes', 'hamstrings', 'core'],
     'Set damper to 3-4. Keep arms straight and back upright throughout. Drive only with the legs, pushing through the heels. Arms remain extended holding the handle but do not pull. This isolates the leg drive portion of the rowing stroke and is an excellent warmup drill. Focus on smooth, controlled leg extension. Do 20-30 strokes at 18-20 SPM.',
     'Beginner', 'cardio'),

    ('Rowing Machine Arms Only', 'cardio', 'rowing_machine', 'lats',
     ARRAY['biceps', 'rear_delts', 'core'],
     'Set damper to 3-4. Keep legs straight and body leaned slightly back at 1 o''clock position. Pull the handle to your lower chest using only your arms and upper back. Squeeze shoulder blades together at the finish. Release arms forward to full extension. This isolates the upper body pull portion. Do 20-30 strokes at 20-22 SPM.',
     'Beginner', 'cardio'),

    ('Rowing Machine Pick Drill', 'cardio', 'rowing_machine', 'lats',
     ARRAY['quadriceps', 'glutes', 'hamstrings', 'biceps', 'core'],
     'Set damper to 3-4. Build the full stroke in stages: start with arms only for 10 strokes, then add the back swing for 10 strokes, then add the leg drive for 10 strokes. This ''pick drill'' teaches proper sequencing: legs-back-arms on the drive, arms-back-legs on the recovery. Keep stroke rate at 18-20 SPM. Repeat the full sequence 2-3 times.',
     'Beginner', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 6. BAR HANGS (7 exercises) — Timed exercises
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
SELECT val.*
FROM (VALUES
    ('Dead Hang', 'upper body', 'pull_up_bar', 'forearms',
     ARRAY['lats', 'shoulders', 'core', 'biceps'],
     'Grip the pull-up bar with an overhand grip, hands shoulder-width apart. Let your body hang with arms fully extended and shoulders relaxed up toward the ears. Keep feet off the ground and body still. This decompresses the spine, builds grip strength, and stretches the lats and shoulders. Breathe deeply and avoid swinging. Aim for 20-60 seconds.',
     'Beginner', 'strength', TRUE, 30),

    ('Active Hang', 'upper body', 'pull_up_bar', 'lats',
     ARRAY['shoulders', 'core', 'forearms', 'traps'],
     'Start in a dead hang position with overhand grip. Without bending the elbows, depress your shoulder blades by pulling them down and back — your body will rise 1-2 inches. Hold this engaged position with shoulders packed. This activates the lats, lower traps, and scapular stabilizers. Breathe steadily. Excellent prehab for pull-ups and overhead pressing.',
     'Beginner', 'strength', TRUE, 30),

    ('Scapular Pull-Up', 'upper body', 'pull_up_bar', 'traps',
     ARRAY['lats', 'rhomboids', 'shoulders', 'forearms'],
     'Hang from the bar with overhand grip, arms fully extended. Without bending the elbows, depress and retract the shoulder blades to lift your body 2-3 inches. Slowly return to the dead hang position. This is a controlled scapular depression movement. Focus on squeezing the lower traps and lats. Do 8-12 reps with a 2-second hold at the top of each rep.',
     'Intermediate', 'strength', TRUE, 30),

    ('Mixed Grip Hang', 'upper body', 'pull_up_bar', 'forearms',
     ARRAY['lats', 'biceps', 'shoulders', 'core'],
     'Grip the bar with one hand overhand (pronated) and the other underhand (supinated), hands shoulder-width apart. Hang with arms fully extended. This grip variation challenges the forearms differently and can help build grip endurance for deadlifts. Avoid rotating the torso — keep hips square. Switch grip orientation halfway through.',
     'Beginner', 'strength', TRUE, 30),

    ('Wide Grip Hang', 'upper body', 'pull_up_bar', 'lats',
     ARRAY['shoulders', 'forearms', 'core', 'teres_major'],
     'Grip the bar with an overhand grip, hands 1.5x shoulder width apart. Hang with arms fully extended and body still. The wider grip places more stretch on the lats and teres major. Keep shoulders relaxed initially, then practice engaging them into an active hang. Breathe deeply. Excellent for lat flexibility and decompression.',
     'Beginner', 'strength', TRUE, 30),

    ('Chin-Up Grip Hang', 'upper body', 'pull_up_bar', 'biceps',
     ARRAY['forearms', 'lats', 'shoulders', 'core'],
     'Grip the bar with an underhand (supinated) grip, hands shoulder-width apart. Hang with arms fully extended. The supinated grip places more emphasis on the biceps and is generally easier on the shoulders than an overhand grip. Keep body still and breathe deeply. Good for beginners working toward chin-ups.',
     'Beginner', 'strength', TRUE, 30),

    ('Towel Hang', 'upper body', 'pull_up_bar', 'forearms',
     ARRAY['lats', 'shoulders', 'biceps', 'core'],
     'Drape two small towels over the pull-up bar, one for each hand. Grip the towels tightly and hang with arms extended. The unstable, thick grip surface dramatically increases forearm and grip strength demands compared to a bar hang. Keep body still and core engaged. Start with 10-15 seconds and build up. Excellent for grip-intensive sports like rock climbing or grappling.',
     'Advanced', 'strength', TRUE, 20)

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 7. JUMP ROPE VARIATIONS (6 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Jump Rope Basic Bounce', 'cardio', 'jump_rope', 'calves',
     ARRAY['quadriceps', 'shoulders', 'forearms', 'core'],
     'Hold the rope handles at hip height with elbows close to your sides. Jump 1-2 inches off the ground, landing softly on the balls of your feet. Wrists generate the rope rotation, not the shoulders. Keep core engaged and knees slightly bent on landing. Maintain a steady rhythm at 60-80 jumps per minute. Start with 1-minute rounds, rest 30 seconds between.',
     'Beginner', 'cardio'),

    ('Jump Rope Alternate Foot Step', 'cardio', 'jump_rope', 'calves',
     ARRAY['hip_flexors', 'quadriceps', 'core', 'shoulders'],
     'Instead of jumping with both feet, alternate feet like a running motion. Lift one knee slightly as the other foot lands. This resembles jogging in place with a rope. Maintain a quicker cadence of 80-100 steps per minute. Keep jumps low to the ground and landings soft. Great for building coordination and higher calorie burn than basic bounce.',
     'Beginner', 'cardio'),

    ('Jump Rope Boxer Step', 'cardio', 'jump_rope', 'calves',
     ARRAY['core', 'shoulders', 'forearms', 'quadriceps'],
     'Shift your weight from side to side with each jump, as if shuffling laterally. When the rope passes under your left side, your left foot takes the landing while the right foot lightly taps. Reverse on the next rotation. Keep a relaxed rhythm and stay light on your feet. This is the classic boxing skip pattern. Do 2-3 minute rounds with 30-second rest.',
     'Intermediate', 'cardio'),

    ('Jump Rope High Knees', 'cardio', 'jump_rope', 'hip_flexors',
     ARRAY['calves', 'quadriceps', 'core', 'shoulders'],
     'With each jump, drive one knee up to hip height while the other foot lands. Alternate legs rapidly. The bent knee should reach at least parallel to the ground. Keep torso upright and pump the arms with the rope. This is high-intensity and builds explosive hip flexor power. Do 20-30 second bursts with 30 seconds easy jumping between. Not recommended for beginners.',
     'Intermediate', 'cardio'),

    ('Jump Rope Criss-Cross', 'cardio', 'jump_rope', 'calves',
     ARRAY['shoulders', 'forearms', 'core', 'chest'],
     'As the rope passes overhead, cross your arms in front of your body at waist level. Jump through the crossed rope, then uncross your arms on the next rotation. Timing is critical — cross when the rope is at its highest point above you. Start slowly and build speed. This challenges coordination and adds shoulder/chest engagement. Practice the cross motion without the rope first.',
     'Advanced', 'cardio'),

    ('Jump Rope Double Under', 'cardio', 'jump_rope', 'calves',
     ARRAY['shoulders', 'forearms', 'core', 'quadriceps'],
     'Jump slightly higher than normal (3-4 inches) while spinning the rope twice under your feet per jump. The key is faster wrist rotation, not higher jumping. Keep elbows tight to your sides and use quick wrist flicks. Land softly on the balls of your feet. Start with singles-singles-double pattern until consistent. This is an advanced skill that builds explosive power and coordination.',
     'Advanced', 'cardio')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 8. DYNAMIC WARMUPS — Bodyweight (28 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('A-Skip', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['calves', 'quadriceps', 'core', 'glutes'],
     'Move forward with a skipping motion, driving one knee up to hip height on each skip. The drive leg snaps down quickly while the opposite arm swings forward. Land on the ball of your foot. Keep torso tall and core engaged. Focus on quick ground contact and high knee drive. Cover 20-30 meters per set, do 2-3 sets. Essential running warmup drill.',
     'Beginner', 'warmup'),

    ('B-Skip', 'cardio', 'bodyweight', 'hamstrings',
     ARRAY['hip_flexors', 'glutes', 'calves', 'core'],
     'Similar to A-Skip but add a leg extension at the top of the knee drive. Drive knee up, extend the lower leg forward, then snap the foot down in a pawing motion. This mimics the ground contact phase of sprinting. Keep torso upright and arms pumping. Cover 20-30 meters per set, do 2-3 sets. Teaches proper sprint mechanics and activates the hamstrings.',
     'Intermediate', 'warmup'),

    ('Carioca Drill', 'cardio', 'bodyweight', 'adductors',
     ARRAY['abductors', 'obliques', 'hip_flexors', 'core'],
     'Move laterally by alternating crossing one foot in front of and behind the other. Keep hips facing forward while your legs cross over. Drive the trailing knee high with each crossover step. Stay on the balls of your feet with a slight forward lean. Arms swing naturally to help with rotation. Cover 20-30 meters each direction, do 2 sets. Excellent for hip mobility and coordination.',
     'Beginner', 'warmup'),

    ('Lateral Shuffle', 'cardio', 'bodyweight', 'abductors',
     ARRAY['adductors', 'glutes', 'quadriceps', 'calves'],
     'Assume an athletic stance with knees bent, hips back, and feet shoulder-width apart. Push off the trailing foot and shuffle laterally, keeping feet from touching. Stay low with hips below shoulder level. Keep chest up and arms ready. Cover 10-15 meters each direction, do 2-3 sets. Do not cross your feet. This activates the lateral hip stabilizers essential for all athletic movement.',
     'Beginner', 'warmup'),

    ('Bear Crawl', 'cardio', 'bodyweight', 'core',
     ARRAY['shoulders', 'quadriceps', 'hip_flexors', 'triceps'],
     'Start on hands and feet with knees hovering 1-2 inches off the ground. Move forward by advancing the opposite hand and foot simultaneously (right hand with left foot). Keep hips low and level — do not let them pike up. Maintain a flat back and tight core. Move slowly and deliberately. Cover 10-20 meters forward and backward. Excellent full-body warmup that builds shoulder stability and core strength.',
     'Intermediate', 'warmup'),

    ('World''s Greatest Stretch', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['glutes', 'hamstrings', 'thoracic_spine', 'adductors', 'core'],
     'From a standing position, step your right foot forward into a deep lunge. Place both hands on the floor inside the right foot. Rotate your torso and reach your right arm toward the ceiling, opening the chest. Hold 2-3 seconds. Return the hand to the floor, then straighten the front leg to stretch the hamstring. Step forward and repeat on the left side. Do 5 reps per side. This single drill opens hips, thoracic spine, hamstrings, and groin.',
     'Beginner', 'warmup'),

    ('Hip 90/90 Switch', 'cardio', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'adductors', 'abductors', 'core'],
     'Sit on the floor with both knees bent at 90 degrees: front leg externally rotated, back leg internally rotated. Sit tall with chest up. Rotate both legs simultaneously to switch the position — what was the front leg becomes the back leg. Control the movement with your hips, keeping feet on the floor. Do 10-12 switches per set. This drill dramatically improves hip internal and external rotation.',
     'Beginner', 'warmup'),

    ('Inchworm', 'cardio', 'bodyweight', 'core',
     ARRAY['hamstrings', 'shoulders', 'chest', 'hip_flexors'],
     'Stand with feet together. Hinge at the hips and place hands on the floor, bending knees slightly if needed. Walk your hands forward until you reach a plank position. Hold for 1 second, then walk your feet toward your hands in small steps, keeping legs as straight as possible. Stand up and repeat. Cover 10-15 meters or do 6-8 reps. Warms up the entire posterior chain and shoulder girdle.',
     'Beginner', 'warmup'),

    ('Leg Swing Forward-Backward', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['hamstrings', 'glutes', 'core'],
     'Stand beside a wall or rack for balance. Swing one leg forward and backward in a controlled pendulum motion. Keep the standing leg slightly bent and core tight. Gradually increase the range of motion with each swing. Do not force the range — let momentum build naturally. Perform 15-20 swings per leg. This dynamically mobilizes the hip flexors and hamstrings.',
     'Beginner', 'warmup'),

    ('Leg Swing Lateral', 'cardio', 'bodyweight', 'adductors',
     ARRAY['abductors', 'hip_flexors', 'core'],
     'Face a wall or rack and hold for balance. Swing one leg across the body (adduction) and then out to the side (abduction) in a controlled pendulum motion. Keep torso upright and avoid rotating the hips. Gradually increase range with each rep. Perform 15-20 swings per leg. This opens the groin and outer hip, essential before squats, lunges, and running.',
     'Beginner', 'warmup'),

    ('Walking Knee Hug', 'cardio', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'hamstrings', 'core'],
     'Walk forward and with each step, lift one knee toward your chest and hug it with both hands. Pull the knee gently into your chest while rising onto the toes of the standing foot. Hold 1-2 seconds, release, step forward, and repeat on the other side. Keep torso upright. Do 10-12 reps per leg, covering 20-30 meters. Stretches the glutes and hip extensors dynamically.',
     'Beginner', 'warmup'),

    ('Walking Quad Pull', 'cardio', 'bodyweight', 'quadriceps',
     ARRAY['hip_flexors', 'core'],
     'Walk forward and with each step, grab your ankle behind you and pull your heel toward your glute. Rise onto the toes of the standing foot for balance. Hold 1-2 seconds, feeling a stretch in the quad and hip flexor. Release, step forward, and repeat on the other side. Keep torso tall and core engaged. Do 10-12 reps per leg.',
     'Beginner', 'warmup'),

    ('Butt Kick Run', 'cardio', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'quadriceps', 'core'],
     'Jog forward while kicking your heels up toward your glutes with each stride. Focus on quick ground contact and rapid hamstring contraction. Keep torso upright and arms pumping at 90 degrees. Do not lean forward excessively. Cover 20-30 meters per set, do 2 sets. This activates the hamstrings and prepares them for sprinting and explosive movements.',
     'Beginner', 'warmup'),

    ('High Knee Run', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['calves', 'quadriceps', 'core', 'glutes'],
     'Jog forward while driving each knee up to hip height or above. Land on the balls of your feet with quick ground contact. Pump arms vigorously in opposition to the legs. Keep torso tall and core engaged — do not lean backward. Cover 20-30 meters per set, do 2 sets. This is an excellent warmup drill for sprint preparation and hip flexor activation.',
     'Beginner', 'warmup'),

    ('Frankenstein Walk', 'cardio', 'bodyweight', 'hamstrings',
     ARRAY['hip_flexors', 'quadriceps', 'core'],
     'Walk forward with legs kept straight. With each step, kick one leg up toward the opposite outstretched hand. Reach forward with the opposite arm. Keep the kicking leg straight with toes flexed toward the shin. Maintain an upright torso. Cover 20-30 meters or 10 kicks per leg. Dynamically stretches the hamstrings without bouncing. Also called ''toy soldier walks''.',
     'Beginner', 'warmup'),

    ('Walking Lunge with Rotation', 'cardio', 'bodyweight', 'quadriceps',
     ARRAY['glutes', 'core', 'obliques', 'hip_flexors'],
     'Step forward into a deep lunge. Once in the bottom position, rotate your torso toward the front knee side, reaching with both arms or clasping hands. Return to center, then drive up and step into the next lunge on the opposite side. Keep the front knee tracking over the toes. Do 8-10 per side. Combines lower body activation with thoracic spine mobility.',
     'Beginner', 'warmup'),

    ('Lateral Lunge', 'cardio', 'bodyweight', 'adductors',
     ARRAY['quadriceps', 'glutes', 'hamstrings', 'core'],
     'Stand with feet together. Take a large step to the right, pushing your hips back and bending the right knee while keeping the left leg straight. Reach toward the right foot. Push off the right foot to return to standing. Repeat on the left side. Keep torso upright and heels on the ground. Do 8-10 per side. Opens the groin and activates the inner thigh muscles.',
     'Beginner', 'warmup'),

    ('Reverse Lunge with Overhead Reach', 'cardio', 'bodyweight', 'quadriceps',
     ARRAY['glutes', 'hip_flexors', 'core', 'shoulders'],
     'Step one foot backward into a reverse lunge. As you lower, reach both arms overhead and lean slightly toward the front leg side, creating a stretch through the hip flexor and lateral core of the back leg. Drive up through the front heel to return to standing. Alternate sides. Do 8-10 per leg. Excellent for hip flexor lengthening and core activation.',
     'Beginner', 'warmup'),

    ('Spiderman Lunge', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['adductors', 'glutes', 'core', 'hamstrings'],
     'From a plank position, step your right foot to the outside of your right hand. Drop your hips toward the floor and hold for 2-3 seconds. Step back to plank and repeat on the left side. Keep the back leg straight and core engaged. Do 6-8 per side. This deep lunge opens the hip flexors and groin while maintaining core and upper body engagement.',
     'Intermediate', 'warmup'),

    ('Mountain Climber', 'cardio', 'bodyweight', 'core',
     ARRAY['hip_flexors', 'shoulders', 'quadriceps', 'glutes'],
     'Start in a plank position with hands directly under shoulders. Rapidly drive one knee toward your chest, then switch legs in a running motion. Keep hips level — do not let them pike up or sag down. Core stays tight throughout. Go at a controlled pace for warmup (not max speed). Do 20-30 reps (counting each leg) or 30 seconds. Elevates heart rate quickly while engaging the entire core.',
     'Beginner', 'warmup'),

    ('Jumping Jack', 'cardio', 'bodyweight', 'calves',
     ARRAY['shoulders', 'adductors', 'abductors', 'core'],
     'Stand with feet together and arms at your sides. Jump feet out to wider than shoulder width while simultaneously raising arms overhead. Jump feet back together and lower arms. Land softly on the balls of your feet. Keep a slight bend in the knees throughout. Do 20-30 reps or 30 seconds. Classic warmup exercise that elevates heart rate and warms up the entire body.',
     'Beginner', 'warmup'),

    ('Squat to Stand', 'cardio', 'bodyweight', 'hamstrings',
     ARRAY['glutes', 'quadriceps', 'core', 'hip_flexors'],
     'Stand with feet shoulder-width apart. Bend forward and grab your toes (bend knees if needed). Keeping hold of your toes, drop your hips into a deep squat position. Push your chest up and extend your thoracic spine. Release your toes and stand up straight. Repeat 8-10 times. This bridges the gap between a hamstring stretch and squat mobility work.',
     'Beginner', 'warmup'),

    ('Arm Circle Forward', 'cardio', 'bodyweight', 'shoulders',
     ARRAY['rotator_cuff', 'traps', 'chest'],
     'Stand with feet shoulder-width apart and extend arms straight out to the sides. Make small forward circles, gradually increasing the diameter over 10-15 seconds until making large circles. Keep core engaged and avoid arching the back. Do 15-20 circles forward, then reverse direction. Warms up the shoulder joint and rotator cuff before any upper body work.',
     'Beginner', 'warmup'),

    ('Arm Circle Backward', 'cardio', 'bodyweight', 'shoulders',
     ARRAY['rotator_cuff', 'traps', 'rear_delts'],
     'Stand with feet shoulder-width apart and extend arms straight out to the sides. Make backward circles starting small and gradually increasing to large circles. This direction emphasizes the rear deltoids and upper back. Keep chest up and core tight. Do 15-20 circles. Pair with forward arm circles for complete shoulder warmup.',
     'Beginner', 'warmup'),

    ('Torso Twist', 'cardio', 'bodyweight', 'obliques',
     ARRAY['core', 'lower_back', 'hip_flexors'],
     'Stand with feet shoulder-width apart and arms extended in front or hands on hips. Rotate your torso to the right, then to the left in a controlled motion. Keep hips facing forward — only the upper body rotates. Gradually increase the range of rotation. Do 15-20 twists per side. Warms up the thoracic spine and obliques. Essential before rotational movements like golf, tennis, or throwing.',
     'Beginner', 'warmup'),

    ('Hip Circle', 'cardio', 'bodyweight', 'hip_flexors',
     ARRAY['glutes', 'adductors', 'abductors', 'core'],
     'Stand on one leg (hold a wall for balance if needed). Lift the opposite knee to hip height, then rotate the hip outward in a large circle, opening the knee to the side and bringing it behind you. Reverse the direction. Do 10 circles in each direction per leg. This mobilizes the hip joint through its full range of motion. Essential before squats, lunges, and running.',
     'Beginner', 'warmup'),

    ('Bodyweight Good Morning', 'cardio', 'bodyweight', 'hamstrings',
     ARRAY['glutes', 'lower_back', 'core'],
     'Stand with feet shoulder-width apart and hands behind your head. Hinge at the hips, pushing them back while keeping a flat back and slight knee bend. Lower your torso until it is roughly parallel to the floor. Squeeze glutes and drive hips forward to return to standing. Do 10-12 reps. Excellent for activating the posterior chain before deadlifts or squats.',
     'Beginner', 'warmup'),

    ('Seal Jack', 'cardio', 'bodyweight', 'chest',
     ARRAY['shoulders', 'calves', 'adductors', 'abductors'],
     'Perform a jumping jack but instead of raising arms overhead, extend them straight out to the sides and clap them together in front of your chest as your feet come together. Open arms wide as feet jump apart. Keep a slight knee bend on landing. Do 15-20 reps. This adds a chest and shoulder stretch component to the standard jumping jack.',
     'Beginner', 'warmup')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 9. STATIC STRETCHES (35 exercises) — Timed
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
SELECT val.*
FROM (VALUES
    ('Standing Hamstring Stretch', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'lower_back'],
     'Stand with feet together. Hinge at the hips and reach toward your toes, keeping legs straight or with a very slight knee bend. Let gravity pull you deeper — do not bounce. Breathe deeply and relax into the stretch. You should feel a pull along the back of your thighs and behind the knees. Hold 20-30 seconds per set.',
     'Beginner', 'stretching', TRUE, 30),

    ('Seated Hamstring Stretch', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'lower_back'],
     'Sit on the floor with both legs extended straight in front of you. Sit tall, then hinge forward at the hips reaching toward your toes. Keep your back as flat as possible — avoid rounding excessively. Pull toes toward you for an added calf stretch. Breathe deeply and relax into it. Hold 20-30 seconds.',
     'Beginner', 'stretching', TRUE, 30),

    ('Single Leg Hamstring Stretch', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'hip_flexors'],
     'Sit on the floor with one leg extended and the other bent with the foot against the inner thigh of the straight leg. Hinge forward at the hips and reach toward the toes of the extended leg. Keep the extended leg straight and back as flat as possible. Hold 20-30 seconds per side. This isolates each hamstring individually.',
     'Beginner', 'stretching', TRUE, 30),

    ('Standing Quad Stretch', 'stretching', 'bodyweight', 'quadriceps',
     ARRAY['hip_flexors'],
     'Stand on one foot (hold a wall for balance). Grab the ankle of the opposite leg behind you and pull your heel gently toward your glute. Keep both knees together and push your hips slightly forward to deepen the hip flexor stretch. Stand tall — do not lean forward. Hold 20-30 seconds per side. This stretches the quads and hip flexors simultaneously.',
     'Beginner', 'stretching', TRUE, 30),

    ('Prone Quad Stretch', 'stretching', 'bodyweight', 'quadriceps',
     ARRAY['hip_flexors'],
     'Lie face down on the floor. Reach back with one hand and grab the ankle on the same side. Gently pull the heel toward the glute. Keep hips pressed into the floor throughout. For a deeper stretch, engage the glute on the stretching side. Hold 20-30 seconds per side. Good option for those with balance issues who cannot do the standing version.',
     'Beginner', 'stretching', TRUE, 30),

    ('Kneeling Hip Flexor Stretch', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['quadriceps', 'glutes', 'core'],
     'Kneel on one knee with the other foot flat on the floor in front of you (lunge position). Tuck your pelvis under by squeezing the glute of the kneeling leg. Lean forward slightly until you feel a deep stretch in the front of the hip of the kneeling leg. Keep torso upright. For a deeper stretch, raise the arm on the kneeling side overhead and lean slightly to the opposite side. Hold 30 seconds per side.',
     'Beginner', 'stretching', TRUE, 30),

    ('Pigeon Stretch', 'stretching', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'piriformis', 'adductors'],
     'From a plank or all-fours position, bring your right knee forward and place it behind your right wrist. Extend your left leg straight back. Lower your hips toward the floor. If possible, walk your hands forward and lower your torso toward the floor. Keep hips square to the front. Hold 30-45 seconds per side. Deep hip opener that targets the piriformis and external rotators.',
     'Intermediate', 'stretching', TRUE, 45),

    ('Figure Four Stretch', 'stretching', 'bodyweight', 'glutes',
     ARRAY['piriformis', 'hip_flexors'],
     'Lie on your back. Cross your right ankle over your left knee, creating a ''4'' shape. Reach through and pull your left thigh toward your chest. Keep your right knee pressing gently away from you. Keep head and shoulders on the floor. Hold 20-30 seconds per side. This stretches the deep glute and piriformis. Excellent for sciatic nerve relief.',
     'Beginner', 'stretching', TRUE, 30),

    ('Standing Calf Stretch', 'stretching', 'bodyweight', 'calves',
     ARRAY['achilles_tendon'],
     'Stand facing a wall with hands pressed against it. Step one foot back 2-3 feet, keeping the back heel on the floor and back leg straight. Lean into the wall by bending the front knee until you feel a stretch in the back calf. Keep the back foot pointing forward. Hold 20-30 seconds per side. This primarily stretches the gastrocnemius (upper calf).',
     'Beginner', 'stretching', TRUE, 30),

    ('Soleus Stretch', 'stretching', 'bodyweight', 'calves',
     ARRAY['achilles_tendon'],
     'Stand facing a wall with hands on the wall. Step one foot back about 1 foot. Bend both knees, sinking your hips down and forward. Keep the back heel on the floor. You should feel a stretch in the lower portion of the back calf, near the Achilles tendon. This targets the soleus muscle, which the straight-leg stretch misses. Hold 20-30 seconds per side.',
     'Beginner', 'stretching', TRUE, 30),

    ('Chest Doorway Stretch', 'stretching', 'bodyweight', 'chest',
     ARRAY['front_delts', 'biceps'],
     'Stand in a doorway and place your forearm on the door frame at shoulder height with elbow bent at 90 degrees. Step through the doorway with the same-side foot until you feel a stretch across the chest and front of the shoulder. Keep core engaged and avoid arching the lower back. Hold 20-30 seconds per side. Adjust arm height to stretch different portions of the pec.',
     'Beginner', 'stretching', TRUE, 30),

    ('Cross-Body Shoulder Stretch', 'stretching', 'bodyweight', 'rear_delts',
     ARRAY['traps', 'rhomboids'],
     'Stand or sit tall. Bring one arm across your body at shoulder height. Use the opposite hand to gently press the arm closer to your chest. Keep the shoulder of the stretching arm relaxed and down — do not shrug. You should feel the stretch in the back of the shoulder. Hold 20-30 seconds per side. Important stretch before and after any overhead or pressing work.',
     'Beginner', 'stretching', TRUE, 30),

    ('Overhead Triceps Stretch', 'stretching', 'bodyweight', 'triceps',
     ARRAY['lats', 'shoulders'],
     'Raise one arm overhead and bend the elbow, reaching your hand down behind your head toward the opposite shoulder blade. Use the other hand to gently press the elbow back and down. Keep torso upright and avoid leaning to one side. Hold 20-30 seconds per side. This stretches the long head of the triceps and the lats.',
     'Beginner', 'stretching', TRUE, 30),

    ('Neck Side Bend Stretch', 'stretching', 'bodyweight', 'traps',
     ARRAY['scalenes', 'levator_scapulae'],
     'Sit or stand tall. Gently tilt your head to the right, bringing your ear toward your shoulder. For a deeper stretch, lightly place your right hand on the left side of your head. Keep the opposite shoulder pressed down. Hold 15-20 seconds per side. Do not pull aggressively — gentle pressure only. This releases upper trap and neck tension.',
     'Beginner', 'stretching', TRUE, 20),

    ('Butterfly Stretch', 'stretching', 'bodyweight', 'adductors',
     ARRAY['hip_flexors', 'glutes'],
     'Sit on the floor with the soles of your feet together and knees falling out to the sides. Hold your feet with both hands and sit up tall. Gently press your knees toward the floor using your elbows. Lean forward from the hips for a deeper stretch. Breathe deeply and relax. Hold 30-45 seconds. Excellent for groin and hip adductor flexibility.',
     'Beginner', 'stretching', TRUE, 30),

    ('Seated Straddle Stretch', 'stretching', 'bodyweight', 'adductors',
     ARRAY['hamstrings', 'lower_back'],
     'Sit on the floor with legs spread wide in a V-shape. Keep legs straight with toes pointing up. Sit tall, then hinge forward at the hips, walking your hands forward between your legs. Keep your back flat and chest lifted. Go only as far as comfortable. Hold 30 seconds. You can also reach toward each foot individually. Stretches the adductors and inner hamstrings.',
     'Beginner', 'stretching', TRUE, 30),

    ('Child''s Pose', 'stretching', 'bodyweight', 'lower_back',
     ARRAY['lats', 'shoulders', 'glutes'],
     'Kneel on the floor and sit your hips back onto your heels. Extend your arms forward on the floor and lower your chest toward the ground. Spread your knees wide for a deeper hip stretch or keep them together for more lower back stretch. Rest your forehead on the floor and breathe deeply. Hold 30-60 seconds. One of the most effective resting and recovery positions.',
     'Beginner', 'stretching', TRUE, 45),

    ('Cat-Cow Stretch', 'stretching', 'bodyweight', 'lower_back',
     ARRAY['core', 'thoracic_spine', 'hip_flexors'],
     'Start on all fours with hands under shoulders and knees under hips. For ''cat'': round your back toward the ceiling, tuck your chin and pelvis under. For ''cow'': arch your back, drop your belly toward the floor, and lift your head and tailbone. Alternate slowly between the two positions, coordinating with breath — inhale for cow, exhale for cat. Do 10-15 cycles. Mobilizes the entire spine.',
     'Beginner', 'stretching', TRUE, 30),

    ('Supine Spinal Twist', 'stretching', 'bodyweight', 'obliques',
     ARRAY['lower_back', 'glutes', 'chest'],
     'Lie on your back with arms extended to the sides in a T-position. Bring both knees up to 90 degrees. Slowly lower both knees to the right side while keeping both shoulders on the floor. Turn your head to the left. Hold 20-30 seconds, then switch sides. This rotational stretch releases the lower back, obliques, and chest. Breathe deeply into the stretch.',
     'Beginner', 'stretching', TRUE, 30),

    ('Cobra Stretch', 'stretching', 'bodyweight', 'core',
     ARRAY['hip_flexors', 'chest', 'shoulders'],
     'Lie face down with hands placed under the shoulders. Press through your palms to lift your chest off the floor, extending the spine. Keep hips and legs on the ground. Straighten arms as much as comfort allows. Keep shoulders down and away from ears. Look slightly upward. Hold 15-30 seconds. This opens the chest and hip flexors while gently extending the lumbar spine.',
     'Beginner', 'stretching', TRUE, 30),

    ('Lying Glute Stretch', 'stretching', 'bodyweight', 'glutes',
     ARRAY['piriformis', 'lower_back'],
     'Lie on your back with both knees bent and feet flat on the floor. Cross one ankle over the opposite knee. Reach through and grab the back of the supporting thigh, pulling both legs gently toward your chest. Keep your head and shoulders on the floor. Press the crossed knee gently away to deepen the stretch. Hold 20-30 seconds per side.',
     'Beginner', 'stretching', TRUE, 30),

    ('Seated Forward Fold', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['lower_back', 'calves'],
     'Sit on the floor with legs extended straight in front. Sit tall, then hinge forward from the hips reaching toward your toes. Keep the back as flat as possible for the first half of the range, then allow the spine to round to go deeper. Pull your toes toward your shins for added calf stretch. Breathe deeply. Hold 30 seconds. Stretches the entire posterior chain.',
     'Beginner', 'stretching', TRUE, 30),

    ('Standing Side Bend', 'stretching', 'bodyweight', 'obliques',
     ARRAY['lats', 'intercostals', 'core'],
     'Stand with feet shoulder-width apart. Raise one arm overhead and lean to the opposite side, reaching over. Keep hips stationary and do not rotate — pure lateral flexion. You should feel a stretch along the side of the body from hip to fingertip. Hold 20-30 seconds per side. This stretches the obliques, intercostals, and QL.',
     'Beginner', 'stretching', TRUE, 30),

    ('Lat Stretch Wall', 'stretching', 'bodyweight', 'lats',
     ARRAY['shoulders', 'triceps', 'core'],
     'Stand arm''s length from a wall. Place both hands on the wall at about hip height. Step back and hinge at the hips, pushing your chest toward the floor while keeping arms straight. You should feel a deep stretch through the lats and shoulders. Keep core engaged and do not arch the lower back excessively. Hold 20-30 seconds. Essential before pull-ups, rows, and overhead pressing.',
     'Beginner', 'stretching', TRUE, 30),

    ('Wrist Flexor Stretch', 'stretching', 'bodyweight', 'forearms',
     ARRAY['wrist_flexors'],
     'Extend one arm straight in front of you with palm facing up. Use the other hand to gently pull the fingers down toward the floor. Keep the stretching arm straight. You should feel a stretch on the inner forearm. Hold 15-20 seconds per side. Important for anyone who types frequently, does gymnastics, or performs heavy grip work.',
     'Beginner', 'stretching', TRUE, 20),

    ('Wrist Extensor Stretch', 'stretching', 'bodyweight', 'forearms',
     ARRAY['wrist_extensors'],
     'Extend one arm straight in front of you with palm facing down. Use the other hand to gently press the fingers and hand downward. Keep the stretching arm straight. You should feel a stretch on the outer forearm. Hold 15-20 seconds per side. Helps prevent tennis elbow and wrist pain from repetitive motions.',
     'Beginner', 'stretching', TRUE, 20),

    ('Ankle Dorsiflexion Stretch', 'stretching', 'bodyweight', 'calves',
     ARRAY['achilles_tendon', 'tibialis_anterior'],
     'Stand facing a wall, one foot about 4 inches from it. Bend the front knee and try to touch it to the wall while keeping the heel on the floor. If the knee touches easily, move the foot further back. The goal is to progressively increase ankle dorsiflexion. Hold 15-20 seconds per side or do 10-15 slow reps. Critical for deep squat mobility.',
     'Beginner', 'stretching', TRUE, 20),

    ('IT Band Stretch Standing', 'stretching', 'bodyweight', 'abductors',
     ARRAY['glutes', 'obliques'],
     'Stand with feet crossed, the leg to be stretched in back. Lean your hips away from the back leg side and reach your arm overhead to the same direction. You should feel a stretch along the outer hip and thigh of the back leg. Keep both feet flat on the floor. Hold 20-30 seconds per side. Helps relieve IT band tightness common in runners and cyclists.',
     'Beginner', 'stretching', TRUE, 30),

    ('Doorway Pec Stretch High', 'stretching', 'bodyweight', 'chest',
     ARRAY['front_delts', 'biceps'],
     'Stand in a doorway. Place your forearm on the door frame with elbow at 90 degrees and upper arm at 135 degrees (halfway between shoulder level and overhead). Step through until you feel a deep stretch across the upper chest and front shoulder. Keep core engaged. Hold 20-30 seconds per side. This targets the clavicular head of the pec major.',
     'Beginner', 'stretching', TRUE, 30),

    ('Supine Hamstring Stretch', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'glutes'],
     'Lie on your back with both legs extended. Lift one leg straight up and loop a towel or band around the foot, or grab behind the thigh. Gently pull the leg toward your chest, keeping it straight. Keep the other leg flat on the floor. Flex the toes toward your shin for added calf stretch. Hold 20-30 seconds per side. This is the safest hamstring stretch for those with lower back issues.',
     'Beginner', 'stretching', TRUE, 30),

    ('Seated Neck Rotation Stretch', 'stretching', 'bodyweight', 'traps',
     ARRAY['scalenes', 'sternocleidomastoid'],
     'Sit tall in a chair or on the floor. Slowly turn your head to the right, looking over your right shoulder. Use your right hand to gently add pressure for a deeper stretch. Hold 15-20 seconds, then repeat on the left. Do not force the rotation. This stretches the neck rotators and upper traps. Essential for anyone with desk-job posture.',
     'Beginner', 'stretching', TRUE, 20),

    ('Shoulder Sleeper Stretch', 'stretching', 'bodyweight', 'rear_delts',
     ARRAY['rotator_cuff', 'infraspinatus'],
     'Lie on your side with the bottom arm extended at 90 degrees to your body, elbow bent at 90 degrees. Use your top hand to gently press the bottom hand toward the floor, rotating the shoulder internally. Keep the bottom shoulder on the ground. Hold 20-30 seconds per side. This stretches the posterior capsule and infraspinatus. Important for overhead athletes.',
     'Beginner', 'stretching', TRUE, 30),

    ('Hip Flexor Couch Stretch', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['quadriceps', 'glutes'],
     'Kneel with your back foot propped up against a wall or couch. Place the other foot flat on the floor in front of you in a lunge position. Squeeze the glute of the back leg and push hips forward. Keep torso upright. This is an intense hip flexor and quad stretch. Hold 30-45 seconds per side. Back off if you feel sharp knee pain.',
     'Intermediate', 'stretching', TRUE, 45),

    ('Frog Stretch', 'stretching', 'bodyweight', 'adductors',
     ARRAY['hip_flexors', 'glutes'],
     'Start on all fours. Widen your knees as far apart as comfortable with feet turned out. Keep your ankles in line with your knees. Slowly rock your hips back toward your heels, feeling a deep stretch in the inner thighs. Keep your back flat and chest up. Hold 30-45 seconds. This is one of the deepest adductor stretches possible. Go slowly and do not force range.',
     'Intermediate', 'stretching', TRUE, 45),

    ('Scorpion Stretch', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['obliques', 'chest', 'quadriceps'],
     'Lie face down with arms extended to the sides in a T-position. Lift your right foot and reach it across your body toward your left hand, rotating your hips. Keep your chest and arms on the floor. Hold 15-20 seconds, then switch sides. This combines hip flexor, chest, and oblique stretching in one movement. Excellent for thoracic and hip mobility.',
     'Intermediate', 'stretching', TRUE, 20)

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 10. FOAM ROLLER EXERCISES (12 exercises) — Timed
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
SELECT val.*
FROM (VALUES
    ('Foam Roll IT Band', 'stretching', 'foam_roller', 'abductors',
     ARRAY['quadriceps', 'glutes'],
     'Lie on your side with the foam roller under your outer thigh, between the hip and knee. Support yourself with your hands and top foot on the floor. Slowly roll from just below the hip to just above the knee. Pause on tender spots for 10-20 seconds. Avoid rolling directly on the hip bone or knee joint. Do 30-60 seconds per side. This can be intense — use your top leg to offload pressure if needed.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Quadriceps', 'stretching', 'foam_roller', 'quadriceps',
     ARRAY['hip_flexors'],
     'Lie face down with the foam roller under both thighs, supporting yourself on your forearms in a plank-like position. Slowly roll from just above the kneecap to the hip crease. Rotate slightly inward and outward to target the inner and outer quad. Pause on sore spots for 10-20 seconds. Do 30-60 seconds per leg. Bend the knee to 90 degrees while on a sore spot for deeper release.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Hamstrings', 'stretching', 'foam_roller', 'hamstrings',
     ARRAY['glutes'],
     'Sit on the floor with the foam roller under both thighs. Place hands behind you for support. Slowly roll from just above the knee to the bottom of the glute. Cross one leg over the other for more pressure on a single leg. Rotate slightly inward and outward to target different portions. Pause on tender spots. Do 30-60 seconds per leg.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Calves', 'stretching', 'foam_roller', 'calves',
     ARRAY['achilles_tendon'],
     'Sit on the floor with the foam roller under both calves. Lift your hips off the ground using your hands for support. Slowly roll from the ankle to just below the knee. Cross one leg over the other for deeper pressure. Rotate the foot inward and outward to target the inner and outer calf. Pause on sore spots. Do 30-60 seconds per leg.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Glutes', 'stretching', 'foam_roller', 'glutes',
     ARRAY['piriformis', 'hip_flexors'],
     'Sit on the foam roller with one ankle crossed over the opposite knee (like a figure-4). Lean onto the crossed side and slowly roll around the glute area. Use your hands behind you for support. Shift your weight to target different areas — especially the piriformis in the deep center of the glute. Pause on tender spots for 10-20 seconds. Do 30-60 seconds per side.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Thoracic Spine', 'stretching', 'foam_roller', 'thoracic_spine',
     ARRAY['traps', 'rhomboids', 'lats'],
     'Lie on your back with the foam roller positioned horizontally under your upper back, just below the shoulder blades. Support your head with your hands. Bend your knees with feet flat on the floor. Slowly roll from the mid-back to the upper back. Arch over the roller at each position for a thoracic extension stretch. Do not roll into the lower back or neck. Do 30-60 seconds.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Lats', 'stretching', 'foam_roller', 'lats',
     ARRAY['teres_major', 'rear_delts'],
     'Lie on your side with the foam roller under your armpit area. Extend the bottom arm overhead. Slowly roll from the armpit to the bottom of the rib cage. Slightly rotate your body forward and backward to target different fibers. Pause on sore spots. Do 30-60 seconds per side. Essential for anyone who does pull-ups, rows, or overhead pressing.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Adductors', 'stretching', 'foam_roller', 'adductors',
     ARRAY['hip_flexors'],
     'Lie face down and place the foam roller parallel to your body. Bring one leg out to the side with knee bent at 90 degrees and place the inner thigh on the roller. Support yourself on your forearms. Slowly roll from the inner knee to the groin. Pause on tender spots. Do 30-60 seconds per side. This targets the often-neglected inner thigh muscles.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Hip Flexors', 'stretching', 'foam_roller', 'hip_flexors',
     ARRAY['quadriceps', 'core'],
     'Lie face down with the foam roller positioned just below the front of your hip bone. Support yourself on your forearms. Slowly rock your body side to side and up and down over the hip flexor area. The target is the psoas and iliacus, which sit deep in the front of the hip. Use gentle pressure — this area can be very tender. Do 20-30 seconds per side.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Upper Back', 'stretching', 'foam_roller', 'traps',
     ARRAY['rhomboids', 'rear_delts'],
     'Lie on your back with the foam roller under your upper back at shoulder level. Cross your arms over your chest or give yourself a hug. Lift your hips slightly and slowly roll from the shoulders to the mid-back. Squeeze your shoulder blades together over the roller for trigger point release. Keep core engaged. Do 30-60 seconds.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Peroneals', 'stretching', 'foam_roller', 'calves',
     ARRAY['tibialis_anterior'],
     'Sit on the floor and place the foam roller under the outer portion of your lower leg (between the knee and ankle). This area contains the peroneal muscles that stabilize the ankle. Support yourself with hands behind you. Slowly roll the outer shin area. Pause on sore spots. Do 20-30 seconds per side. Important for runners and those with ankle instability.',
     'Beginner', 'mobility', TRUE, 30),

    ('Foam Roll Pecs', 'stretching', 'foam_roller', 'chest',
     ARRAY['front_delts', 'biceps'],
     'Lie face down with the foam roller positioned vertically under one side of the chest, near the shoulder. Extend the same-side arm out at 90 degrees. Slowly roll from the shoulder toward the sternum. Adjust the arm angle (higher or lower) to target different portions of the pec. Do 20-30 seconds per side. Helps counteract rounded-shoulder posture from desk work.',
     'Beginner', 'mobility', TRUE, 30)

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 11. MOBILITY DRILLS (12 exercises)
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
SELECT val.*
FROM (VALUES
    ('Thread the Needle', 'stretching', 'bodyweight', 'thoracic_spine',
     ARRAY['shoulders', 'lats', 'obliques'],
     'Start on all fours with hands under shoulders and knees under hips. Reach your right arm under your body, threading it through the space between your left hand and left knee. Lower your right shoulder and temple to the floor. Hold 15-20 seconds, then return to all fours and repeat on the other side. Do 5-6 reps per side. This is one of the best thoracic rotation drills available.',
     'Beginner', 'mobility'),

    ('90/90 Hip Stretch', 'stretching', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'adductors', 'abductors'],
     'Sit on the floor with your front leg bent at 90 degrees in front of you (shin parallel to your chest) and your back leg bent at 90 degrees behind you. Sit tall and lean your torso forward over the front shin. You should feel a deep stretch in the front leg glute. Keep both sit bones on the floor if possible. Hold 30-45 seconds per side. Incredible for hip external rotation.',
     'Beginner', 'mobility'),

    ('Thoracic Rotation Quadruped', 'stretching', 'bodyweight', 'thoracic_spine',
     ARRAY['obliques', 'shoulders', 'core'],
     'Start on all fours. Place one hand behind your head. Rotate that elbow down toward the opposite hand, rounding your upper back. Then rotate upward, opening the chest toward the ceiling and following your elbow with your eyes. Move slowly and control the range. Do 8-10 reps per side. This isolates thoracic rotation while the quadruped position stabilizes the lumbar spine.',
     'Beginner', 'mobility'),

    ('Open Book Stretch', 'stretching', 'bodyweight', 'thoracic_spine',
     ARRAY['chest', 'obliques', 'shoulders'],
     'Lie on your side with knees bent at 90 degrees and stacked. Extend both arms in front of you, palms together. Slowly open the top arm like a book, rotating your torso and reaching the arm toward the floor on the other side. Follow the hand with your eyes. Keep knees stacked and together throughout. Hold 5 seconds at the end, then return. Do 8-10 reps per side.',
     'Beginner', 'mobility'),

    ('Wall Slide', 'stretching', 'bodyweight', 'shoulders',
     ARRAY['traps', 'rotator_cuff', 'rhomboids'],
     'Stand with your back, head, and hips flat against a wall. Place your arms against the wall in a ''goal post'' position (elbows at 90 degrees, upper arms at shoulder height). Slowly slide your arms up the wall, straightening them overhead, then slide back down. Keep your wrists, elbows, and back in contact with the wall throughout. Do 10-12 reps. Excellent for shoulder mobility and posture correction.',
     'Beginner', 'mobility'),

    ('Ankle CARs', 'stretching', 'bodyweight', 'calves',
     ARRAY['tibialis_anterior', 'achilles_tendon'],
     'Sit in a chair or stand on one leg. Lift one foot off the ground and slowly draw the largest possible circle with your toes, moving through the full range of ankle motion: point, invert, flex, evert. Complete 10 circles clockwise and 10 counterclockwise per ankle. Move slowly and deliberately, trying to access every degree of range. CARs stands for Controlled Articular Rotations.',
     'Beginner', 'mobility'),

    ('Hip CARs', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['glutes', 'adductors', 'abductors', 'core'],
     'Stand on one leg (hold a wall for balance). Lift the opposite knee up in front of you to 90 degrees. Rotate the knee out to the side, then extend the leg behind you, then bring it back around to the front. The goal is to trace the largest circle possible with your knee/hip without moving the pelvis. Do 5 circles in each direction per leg. Slow and controlled.',
     'Beginner', 'mobility'),

    ('Shoulder CARs', 'stretching', 'bodyweight', 'shoulders',
     ARRAY['rotator_cuff', 'traps', 'lats', 'chest'],
     'Stand tall with one arm at your side. Make a fist and slowly raise your arm forward, then overhead, then behind you, then down to the starting position in a large controlled circle. Maintain tension throughout the entire arm and keep the torso absolutely still. Do 5 circles in each direction per arm. This maps the full usable range of the shoulder joint. Move slowly.',
     'Beginner', 'mobility'),

    ('Prone Scorpion', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['obliques', 'thoracic_spine', 'glutes'],
     'Lie face down with arms extended in a T-position. Lift your right heel toward the ceiling, bend the knee, and reach the foot across toward your left hand. Allow the hip to rotate but keep both arms and chest on the floor. Hold 2-3 seconds at end range, then return. Alternate sides. Do 6-8 per side. Combines hip flexor stretching with thoracic spine rotation.',
     'Intermediate', 'mobility'),

    ('Bretzel Stretch', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['quadriceps', 'thoracic_spine', 'chest', 'glutes'],
     'Lie on your side. Bend your top knee and hold it with your bottom hand, pulling it toward the floor in front of you. Bend your bottom knee and grab that foot with your top hand behind you, pulling the heel toward the glute. Rotate your top shoulder toward the floor behind you. Hold 30-45 seconds per side. One of the most comprehensive full-body stretches — hits hips, quads, thoracic spine, and chest simultaneously.',
     'Intermediate', 'mobility'),

    ('Shinbox Get-Up', 'stretching', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'quadriceps', 'core'],
     'Start in the 90/90 hip position on the floor. Without using your hands, drive through the front foot and back knee to rise to a tall kneeling position. Reverse the movement back to the 90/90 position. Then switch leg positions and repeat. Do 5-6 per side. This builds functional hip mobility under load and strengthens the glutes through a full range of motion.',
     'Intermediate', 'mobility'),

    ('Deep Squat Hold', 'stretching', 'bodyweight', 'quadriceps',
     ARRAY['glutes', 'adductors', 'calves', 'core'],
     'Stand with feet slightly wider than shoulder-width, toes turned out 15-30 degrees. Lower into a full deep squat, keeping heels on the floor and chest up. Use your elbows to push your knees outward. Clasp hands together or hold a light weight at chest height for counterbalance. Breathe deeply and relax into the bottom position. Hold 30-60 seconds. If heels come up, elevate them on a small plate.',
     'Beginner', 'mobility')

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);

-- ============================================
-- 12. YOGA-BASED WARMUPS (10 exercises) — Timed
-- ============================================

INSERT INTO exercise_library (exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
SELECT val.*
FROM (VALUES
    ('Sun Salutation A', 'stretching', 'bodyweight', 'core',
     ARRAY['shoulders', 'hamstrings', 'hip_flexors', 'chest', 'quadriceps'],
     'A flowing sequence: stand tall (mountain pose), inhale and raise arms overhead, exhale and fold forward, inhale and lift halfway, exhale and step or jump back to plank, lower to chaturanga, inhale to upward dog, exhale to downward dog (hold 5 breaths), step forward, fold, rise to standing. One cycle takes about 60-90 seconds. Do 3-5 rounds as a full-body warmup. Coordinate each movement with breath.',
     'Beginner', 'yoga', TRUE, 90),

    ('Downward Facing Dog', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'shoulders', 'lats', 'core'],
     'From plank position, push your hips up and back into an inverted V-shape. Press hands firmly into the floor with fingers spread wide. Push your chest toward your thighs and heels toward the floor (heels do not need to touch). Maintain a flat back — bend knees slightly if needed to keep the spine long. Head hangs between the arms. Hold 30-60 seconds. Stretches the entire posterior chain and builds shoulder stability.',
     'Beginner', 'yoga', TRUE, 45),

    ('Warrior I', 'stretching', 'bodyweight', 'quadriceps',
     ARRAY['hip_flexors', 'shoulders', 'core', 'glutes'],
     'From standing, step one foot back 3-4 feet. Turn the back foot out 45 degrees with the heel grounded. Bend the front knee to 90 degrees, tracking over the ankle. Square your hips toward the front. Raise both arms overhead with palms facing each other. Sink the hips low while reaching the arms high. Keep the back leg straight and strong. Hold 30-45 seconds per side.',
     'Beginner', 'yoga', TRUE, 30),

    ('Warrior II', 'stretching', 'bodyweight', 'quadriceps',
     ARRAY['adductors', 'shoulders', 'core', 'glutes'],
     'From standing, step one foot back 3-4 feet. Turn the back foot to 90 degrees (parallel to the back of your mat). Bend the front knee to 90 degrees. Extend both arms parallel to the floor, gazing over the front fingertips. Open your hips and chest to face the side. Keep torso centered between the legs — do not lean forward. Sink deeper to increase the challenge. Hold 30-45 seconds per side.',
     'Beginner', 'yoga', TRUE, 30),

    ('Pigeon Pose', 'stretching', 'bodyweight', 'glutes',
     ARRAY['hip_flexors', 'piriformis', 'adductors'],
     'From downward dog, bring your right knee forward and place it behind your right wrist. Extend the left leg straight back. Lower your hips toward the floor. The right shin can be at an angle (beginners) or parallel to the front of the mat (advanced). Walk your hands forward and lower your forehead toward the floor for a deeper stretch. Breathe deeply and hold 45-90 seconds per side. Deep hip opener for the piriformis and external rotators.',
     'Intermediate', 'yoga', TRUE, 60),

    ('Cobra Pose', 'stretching', 'bodyweight', 'lower_back',
     ARRAY['core', 'hip_flexors', 'chest', 'shoulders'],
     'Lie face down with hands under the shoulders, elbows hugged into the body. Press the tops of the feet, thighs, and hips firmly into the floor. Inhale and press through the hands to lift the chest, using mostly your back muscles (not pushing hard with arms). Straighten arms only as much as your back allows. Keep shoulders away from ears. Look slightly upward. Hold 15-30 seconds.',
     'Beginner', 'yoga', TRUE, 30),

    ('Upward Facing Dog', 'stretching', 'bodyweight', 'chest',
     ARRAY['hip_flexors', 'core', 'shoulders', 'lower_back'],
     'From a prone position, place hands beside your lower ribs. Inhale and press through the hands to straighten the arms, lifting the torso and thighs completely off the floor. Only your hands and tops of your feet remain on the ground. Roll shoulders back and open the chest. Keep the legs active and engaged. Gaze slightly upward. Hold 15-30 seconds. Deeper backbend than cobra.',
     'Intermediate', 'yoga', TRUE, 30),

    ('Low Lunge (Anjaneyasana)', 'stretching', 'bodyweight', 'hip_flexors',
     ARRAY['quadriceps', 'glutes', 'core', 'shoulders'],
     'From downward dog, step one foot forward between the hands. Lower the back knee to the floor (pad it with a towel if needed). Sink the hips forward and down. Raise both arms overhead with palms facing each other. Gently arch the upper back, opening the chest. Squeeze the glute of the back leg to deepen the hip flexor stretch. Hold 30-45 seconds per side.',
     'Beginner', 'yoga', TRUE, 30),

    ('Triangle Pose (Trikonasana)', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['obliques', 'adductors', 'shoulders', 'core'],
     'Stand with feet 3-4 feet apart. Turn the right foot out 90 degrees and the left foot in slightly. Extend arms parallel to the floor. Hinge at the right hip and reach the right hand down toward the right shin or a block. Extend the left arm toward the ceiling. Stack the shoulders and open the chest. Keep both legs straight. Gaze up at the top hand. Hold 30 seconds per side.',
     'Beginner', 'yoga', TRUE, 30),

    ('Standing Forward Fold (Uttanasana)', 'stretching', 'bodyweight', 'hamstrings',
     ARRAY['calves', 'lower_back', 'glutes'],
     'Stand with feet hip-width apart. Exhale and hinge forward from the hips, folding your torso over your legs. Let your head hang heavy. Grab opposite elbows and sway gently, or place hands on the floor beside your feet. Bend knees slightly if hamstrings are tight. Let gravity deepen the stretch with each exhale. Hold 30-60 seconds. Calms the mind and stretches the entire posterior chain.',
     'Beginner', 'yoga', TRUE, 45)

) AS val(exercise_name, body_part, equipment, target_muscle, secondary_muscles, instructions, difficulty_level, category, is_timed, default_hold_seconds)
WHERE NOT EXISTS (
    SELECT 1 FROM exercise_library WHERE lower(exercise_library.exercise_name) = lower(val.exercise_name)
);


-- ============================================
-- UPDATE VIEWS TO INCLUDE NEW EXERCISES
-- ============================================

-- Drop all dependent views first
DROP VIEW IF EXISTS warmup_stretch_exercises CASCADE;
DROP VIEW IF EXISTS stretch_exercises_cleaned CASCADE;
DROP VIEW IF EXISTS warmup_exercises_cleaned CASCADE;

-- Recreate stretch_exercises_cleaned with UNION for category-based exercises
CREATE VIEW stretch_exercises_cleaned AS
WITH base_stretches AS (
    SELECT
        id,
        TRIM(
            regexp_replace(
                regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                '\s+', ' ', 'g'
            )
        ) as name,
        CASE
            WHEN lower(body_part) IN ('bodyweight', 'resistance') THEN body_part
            ELSE 'Bodyweight'
        END as body_part,
        COALESCE(target_muscle, '') as target_muscle,
        COALESCE(equipment, 'none') as equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM exercise_library
    WHERE lower(exercise_name) LIKE '%stretch%'
      AND video_s3_path IS NOT NULL
),
deduplicated AS (
    SELECT DISTINCT ON (lower(name))
        id,
        name,
        body_part,
        target_muscle,
        equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM base_stretches
    ORDER BY lower(name),
             CASE WHEN target_muscle != '' THEN 0 ELSE 1 END,
             CASE WHEN instructions IS NOT NULL THEN 0 ELSE 1 END
)
SELECT
    id,
    name,
    body_part,
    target_muscle,
    equipment,
    instructions,
    CASE
        WHEN video_s3_path IS NOT NULL
        THEN 'https://fitwiz-videos.s3.us-west-1.amazonaws.com/' || video_s3_path
        ELSE NULL
    END as video_url,
    gif_url,
    CASE
        WHEN image_s3_path IS NOT NULL
        THEN 'https://fitwiz-videos.s3.us-west-1.amazonaws.com/' || image_s3_path
        ELSE NULL
    END as image_url,
    'stretch' as exercise_type
FROM deduplicated

UNION ALL

-- Include new category-based stretch/mobility/yoga exercises (no video required)
SELECT
    el.id,
    el.exercise_name as name,
    el.body_part,
    COALESCE(el.target_muscle, '') as target_muscle,
    COALESCE(el.equipment, 'none') as equipment,
    el.instructions,
    NULL as video_url,
    NULL as gif_url,
    NULL as image_url,
    'stretch' as exercise_type
FROM exercise_library el
WHERE el.category IN ('stretching', 'mobility', 'yoga')
  AND el.video_s3_path IS NULL
  AND lower(el.exercise_name) NOT IN (
      SELECT lower(d.name) FROM (
          SELECT DISTINCT ON (lower(name)) name
          FROM (
              SELECT TRIM(
                  regexp_replace(
                      regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                      '\s+', ' ', 'g'
                  )
              ) as name
              FROM exercise_library
              WHERE lower(exercise_name) LIKE '%stretch%'
                AND video_s3_path IS NOT NULL
          ) sub
          ORDER BY lower(name)
      ) d
  );


-- Recreate warmup_exercises_cleaned with UNION for category-based exercises
CREATE VIEW warmup_exercises_cleaned AS
WITH base_warmups AS (
    SELECT
        id,
        TRIM(
            regexp_replace(
                regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                '\s+', ' ', 'g'
            )
        ) as name,
        CASE
            WHEN lower(body_part) IN ('bodyweight', 'resistance') THEN body_part
            ELSE 'Bodyweight'
        END as body_part,
        COALESCE(target_muscle, '') as target_muscle,
        COALESCE(equipment, 'none') as equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM exercise_library
    WHERE video_s3_path IS NOT NULL
      AND (
          lower(exercise_name) SIMILAR TO '%(circle|swing|rotation|dynamic|march|jog|skip|hop|arm |leg |hip |shoulder |ankle |wrist |neck |torso |twist|raise|reach|windmill|inchworm|lunge walk|high knee|butt kick)%'
          OR lower(exercise_name) SIMILAR TO '%(glute bridge|fire hydrant|bird dog|cat cow|dead bug|mountain climber|jumping jack)%'
      )
      AND lower(exercise_name) NOT SIMILAR TO '%(press|curl|row|squat|deadlift|bench|pull up|chin up|dip|fly|pullover|shrug|barbell|dumbbell|cable|machine|weighted)%'
      AND lower(exercise_name) NOT LIKE '%stretch%'
      AND (lower(body_part) IN ('bodyweight', '') OR body_part IS NULL OR lower(equipment) IN ('none', 'yoga mat', ''))
),
deduplicated AS (
    SELECT DISTINCT ON (lower(name))
        id,
        name,
        body_part,
        target_muscle,
        equipment,
        instructions,
        video_s3_path,
        gif_url,
        image_s3_path
    FROM base_warmups
    ORDER BY lower(name),
             CASE WHEN target_muscle != '' THEN 0 ELSE 1 END,
             CASE WHEN instructions IS NOT NULL THEN 0 ELSE 1 END
)
SELECT
    id,
    name,
    body_part,
    target_muscle,
    equipment,
    instructions,
    CASE
        WHEN video_s3_path IS NOT NULL
        THEN 'https://fitwiz-videos.s3.us-west-1.amazonaws.com/' || video_s3_path
        ELSE NULL
    END as video_url,
    gif_url,
    CASE
        WHEN image_s3_path IS NOT NULL
        THEN 'https://fitwiz-videos.s3.us-west-1.amazonaws.com/' || image_s3_path
        ELSE NULL
    END as image_url,
    'warmup' as exercise_type
FROM deduplicated

UNION ALL

-- Include new category-based warmup/cardio exercises (no video required)
SELECT
    el.id,
    el.exercise_name as name,
    el.body_part,
    COALESCE(el.target_muscle, '') as target_muscle,
    COALESCE(el.equipment, 'none') as equipment,
    el.instructions,
    NULL as video_url,
    NULL as gif_url,
    NULL as image_url,
    'warmup' as exercise_type
FROM exercise_library el
WHERE el.category IN ('warmup', 'cardio')
  AND el.video_s3_path IS NULL
  AND lower(el.exercise_name) NOT IN (
      SELECT lower(d.name) FROM (
          SELECT DISTINCT ON (lower(name)) name
          FROM (
              SELECT TRIM(
                  regexp_replace(
                      regexp_replace(exercise_name, '(_female|_male|_Female|_Male)$', '', 'i'),
                      '\s+', ' ', 'g'
                  )
              ) as name
              FROM exercise_library
              WHERE video_s3_path IS NOT NULL
                AND (
                    lower(exercise_name) SIMILAR TO '%(circle|swing|rotation|dynamic|march|jog|skip|hop|arm |leg |hip |shoulder |ankle |wrist |neck |torso |twist|raise|reach|windmill|inchworm|lunge walk|high knee|butt kick)%'
                    OR lower(exercise_name) SIMILAR TO '%(glute bridge|fire hydrant|bird dog|cat cow|dead bug|mountain climber|jumping jack)%'
                )
                AND lower(exercise_name) NOT SIMILAR TO '%(press|curl|row|squat|deadlift|bench|pull up|chin up|dip|fly|pullover|shrug|barbell|dumbbell|cable|machine|weighted)%'
                AND lower(exercise_name) NOT LIKE '%stretch%'
                AND (lower(body_part) IN ('bodyweight', '') OR body_part IS NULL OR lower(equipment) IN ('none', 'yoga mat', ''))
          ) sub
          ORDER BY lower(name)
      ) d
  );


-- Recreate combined view
CREATE VIEW warmup_stretch_exercises AS
SELECT * FROM stretch_exercises_cleaned
UNION ALL
SELECT * FROM warmup_exercises_cleaned;


-- Grant permissions
GRANT SELECT ON stretch_exercises_cleaned TO authenticated;
GRANT SELECT ON stretch_exercises_cleaned TO anon;
GRANT SELECT ON warmup_exercises_cleaned TO authenticated;
GRANT SELECT ON warmup_exercises_cleaned TO anon;
GRANT SELECT ON warmup_stretch_exercises TO authenticated;
GRANT SELECT ON warmup_stretch_exercises TO anon;


-- ============================================
-- SUMMARY COMMENT
-- ============================================
COMMENT ON TABLE exercise_library IS 'Main exercise database. Migration 234 added ~140 warmup/stretch/mobility/yoga exercises across 12 categories.';
