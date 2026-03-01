#!/usr/bin/env python3
"""Generate Fat Loss MEDIUM priority programs: Stubborn Fat Loss, Sustainable Fat Loss,
Cardio Burn Challenge, Morning Fat Burn, Evening Metabolic Boost, Birthday Shred, Post-Baby Shred."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": weight, "equipment": equip, "body_part": body,
            "primary_muscle": muscle, "secondary_muscles": secondary,
            "difficulty": diff, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ========================================================================
# STUBBORN FAT LOSS
# ========================================================================

def stubborn_upper_hiit():
    return wo("Upper Body HIIT Circuit", "fat_loss", 45, [
        ex("Battle Rope Slams", 4, 30, 30, "Max effort 30 seconds", "Battle Ropes", "Arms", "Shoulders", ["Core", "Back"], "intermediate", "Full range slam, absorb with legs", "Rope Waves"),
        ex("Dumbbell Thruster", 4, 12, 30, "Moderate weight", "Dumbbells", "Full Body", "Shoulders", ["Quadriceps", "Triceps"], "intermediate", "Front squat to press in one motion", "Barbell Thruster"),
        ex("Renegade Row", 4, 10, 30, "Moderate dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row one arm at a time", "Bent-Over Row"),
        ex("Burpee to Push-Up", 4, 10, 30, "Bodyweight", "Bodyweight", "Full Body", "Pectoralis Major", ["Shoulders", "Core", "Quadriceps"], "intermediate", "Full burpee with strict push-up at bottom", "Half Burpee"),
        ex("Kettlebell Swing", 4, 20, 30, "Moderate to heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip hinge power, arms are just hooks", "Dumbbell Swing"),
        ex("Mountain Climber", 3, 30, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Rapid alternating knee drives, flat back", "Slow Mountain Climber"),
    ])

def stubborn_lower_hiit():
    return wo("Lower Body HIIT Blast", "fat_loss", 45, [
        ex("Jump Squat", 4, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explode up, soft landing", "Bodyweight Squat"),
        ex("Walking Lunge", 4, 12, 30, "Dumbbells optional", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Reverse Lunge"),
        ex("Romanian Deadlift", 4, 12, 45, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, slight knee bend", "Dumbbell RDL"),
        ex("Box Jump", 4, 10, 30, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing on top, step down", "Step-Up"),
        ex("Sumo Squat Pulse", 3, 20, 30, "Dumbbell or bodyweight", "Dumbbells", "Legs", "Hip Adductors", ["Glutes", "Quadriceps"], "beginner", "Wide stance, pulse at bottom", "Sumo Squat"),
        ex("Sprint Intervals", 4, 30, 30, "30 seconds max effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "All-out sprint then walk recovery", "High Knees"),
    ])

def stubborn_core_cardio():
    return wo("Core-Focused Cardio", "fat_loss", 40, [
        ex("Bicycle Crunch", 4, 20, 20, "Controlled pace", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Elbow to opposite knee, full extension", "Crunch"),
        ex("Plank to Push-Up", 4, 10, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm to hand, maintain hip position", "Forearm Plank"),
        ex("Kettlebell Turkish Get-Up", 3, 5, 45, "Light to moderate", "Kettlebell", "Core", "Core", ["Shoulders", "Glutes", "Quadriceps"], "advanced", "Eyes on bell, smooth transitions", "Half Turkish Get-Up"),
        ex("Med Ball Slam", 4, 12, 20, "10-20 lb ball", "Medicine Ball", "Core", "Rectus Abdominis", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Full overhead, slam with force", "Squat to Press"),
        ex("Dead Bug", 3, 12, 20, "Controlled tempo", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Lower back pressed into floor, opposite arm/leg", "Modified Dead Bug"),
        ex("Bear Crawl", 3, 30, 30, "30 seconds", "Bodyweight", "Core", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Knees just off ground, move forward/backward", "Plank Hold"),
    ])


programs_batch_1 = [
    ("Stubborn Fat Loss", "Fat Loss", [4, 8], [5, 6], "Target problem areas with high-frequency HIIT and metabolic circuits", True, "Med",
     lambda w, t: [stubborn_upper_hiit(), stubborn_lower_hiit(), stubborn_core_cardio(), stubborn_upper_hiit(), stubborn_lower_hiit()]),
]

# ========================================================================
# SUSTAINABLE FAT LOSS
# ========================================================================

def sustainable_full_body_a():
    return wo("Full Body Strength A", "strength", 50, [
        ex("Barbell Back Squat", 4, 8, 90, "65-75% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Depth below parallel, chest up", "Goblet Squat"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate weight", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full range, squeeze at top", "Push-Up"),
        ex("Bent-Over Barbell Row", 3, 10, 60, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45 degree torso angle, pull to navel", "Cable Row"),
        ex("Overhead Press", 3, 8, 60, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive", "Dumbbell Press"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, feel hamstring stretch", "Dumbbell RDL"),
        ex("Plank Hold", 3, 1, 30, "45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, engage everything", "Forearm Plank"),
    ])

def sustainable_full_body_b():
    return wo("Full Body Strength B", "strength", 50, [
        ex("Trap Bar Deadlift", 4, 8, 90, "70-80% 1RM", "Trap Bar", "Legs", "Glutes", ["Hamstrings", "Quadriceps", "Core"], "intermediate", "Push floor away, lockout hips", "Conventional Deadlift"),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate weight", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-45 degree incline, full range", "Incline Push-Up"),
        ex("Lat Pulldown", 3, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "beginner", "Lean slightly back, pull to upper chest", "Assisted Pull-Up"),
        ex("Lateral Raise", 3, 12, 45, "Light weight, control", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Traps"], "beginner", "Slight bend in elbows, raise to parallel", "Cable Lateral Raise"),
        ex("Leg Curl", 3, 12, 45, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Controlled negative, squeeze at top", "Nordic Curl"),
        ex("Russian Twist", 3, 15, 30, "Light med ball", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet elevated, rotate fully each side", "Seated Twist"),
    ])

def sustainable_cardio():
    return wo("Moderate Cardio Session", "cardio", 35, [
        ex("Incline Treadmill Walk", 1, 1, 0, "15 minutes, 10-15% incline", "Treadmill", "Legs", "Glutes", ["Hamstrings", "Calves"], "beginner", "Brisk walk, no holding rails", "Outdoor Uphill Walk"),
        ex("Rowing Machine Intervals", 1, 8, 0, "1 min hard / 1 min easy x 8", "Rowing Machine", "Full Body", "Back", ["Legs", "Core", "Biceps"], "intermediate", "Push with legs first, then pull", "Jump Rope Intervals"),
        ex("Stair Climber", 1, 1, 0, "10 minutes steady pace", "Stair Climber", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Upright posture, full steps", "Step-Ups"),
        ex("Elliptical", 1, 1, 0, "10 minutes moderate resistance", "Elliptical", "Full Body", "Quadriceps", ["Glutes", "Arms"], "beginner", "Keep resistance challenging, push and pull", "Brisk Walking"),
    ])

programs_batch_1.append(
    ("Sustainable Fat Loss", "Fat Loss", [8, 12, 16], [3, 4], "Long-term approach to fat loss with sustainable habits and moderate intensity", True, "Med",
     lambda w, t: [sustainable_full_body_a(), sustainable_full_body_b(), sustainable_cardio()])
)

# ========================================================================
# CARDIO BURN CHALLENGE
# ========================================================================

def cardio_hiit_session():
    return wo("HIIT Cardio Blast", "cardio", 40, [
        ex("Treadmill Sprint", 8, 1, 60, "30 sec sprint / 60 sec walk", "Treadmill", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Max effort sprint, hold rails only to step off", "High Knees"),
        ex("Jump Rope", 4, 1, 30, "1 minute continuous", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Soft bounce, wrists do the work", "Jumping Jacks"),
        ex("Burpee", 4, 10, 30, "Fast pace", "Bodyweight", "Full Body", "Pectoralis Major", ["Quadriceps", "Core", "Shoulders"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
        ex("Box Jump", 3, 12, 30, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Two-foot takeoff and landing", "Step-Up"),
        ex("Kettlebell Swing", 4, 20, 30, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap at top, control the descent", "Dumbbell Swing"),
        ex("Battle Rope Alternating Waves", 3, 30, 30, "30 seconds", "Battle Ropes", "Arms", "Shoulders", ["Core", "Back"], "intermediate", "Alternating wave pattern, athletic stance", "Rope Slam"),
    ])

def cardio_endurance_session():
    return wo("Endurance Cardio", "cardio", 45, [
        ex("Rowing Machine", 1, 1, 0, "20 minutes at 65-75% max HR", "Rowing Machine", "Full Body", "Back", ["Legs", "Core", "Biceps"], "beginner", "Legs-back-arms on drive, arms-back-legs on recovery", "Cycling"),
        ex("Stair Climber", 1, 1, 0, "10 minutes steady", "Stair Climber", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Don't lean on handles, drive through heels", "Step-Ups"),
        ex("Assault Bike Intervals", 6, 1, 60, "30 sec all-out / 60 sec easy", "Assault Bike", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Arms and legs both working, max RPM", "Cycling"),
        ex("Sled Push", 4, 1, 60, "30 yard push", "Sled", "Legs", "Quadriceps", ["Glutes", "Core", "Shoulders"], "intermediate", "Low position, drive through legs", "Farmer Carry"),
    ])

def cardio_bodyweight_burn():
    return wo("Bodyweight Cardio Circuit", "cardio", 35, [
        ex("Jumping Jack", 3, 30, 15, "Fast pace", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Full range of motion, land softly", "Step Jack"),
        ex("Mountain Climber", 3, 30, 15, "Rapid pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Flat back, drive knees to chest", "Slow Mountain Climber"),
        ex("Squat Jump", 3, 15, 20, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, max height jump, soft landing", "Bodyweight Squat"),
        ex("High Knees", 3, 30, 15, "30 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Drive knees above hip level, pump arms", "Marching in Place"),
        ex("Skater Jump", 3, 15, 20, "Side to side", "Bodyweight", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "intermediate", "Land on one foot, reach opposite arm", "Lateral Shuffle"),
        ex("Tuck Jump", 3, 10, 30, "Max height", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Drive knees to chest at peak, soft landing", "Squat Jump"),
    ])

programs_batch_1.append(
    ("Cardio Burn Challenge", "Fat Loss", [2, 4, 8], [5, 6], "Cardio-focused fat loss with progressive intensity and varied equipment", False, "Med",
     lambda w, t: [cardio_hiit_session(), cardio_endurance_session(), cardio_bodyweight_burn(), cardio_hiit_session(), cardio_endurance_session()])
)

# ========================================================================
# MORNING FAT BURN
# ========================================================================

def morning_fasted_circuit():
    return wo("AM Fasted Circuit", "fat_loss", 30, [
        ex("Bodyweight Squat", 3, 15, 20, "Bodyweight, moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth, arms forward for balance", "Wall Sit"),
        ex("Push-Up", 3, 12, 20, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Chest to floor, full lockout", "Incline Push-Up"),
        ex("Reverse Lunge", 3, 10, 20, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, front knee 90 degrees", "Split Squat"),
        ex("Plank Shoulder Tap", 3, 12, 20, "Controlled", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Minimal hip rotation, tap opposite shoulder", "Plank Hold"),
        ex("Jumping Jack", 3, 30, 15, "Fast pace", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Full range, land softly", "Step Jack"),
        ex("Glute Bridge", 3, 15, 20, "Squeeze at top", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "beginner", "Drive through heels, full hip extension", "Single-Leg Bridge"),
    ])

def morning_tabata():
    return wo("AM Tabata Burn", "hiit", 25, [
        ex("High Knees", 4, 1, 10, "20 sec on / 10 sec off", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Pump arms, knees above hips", "Marching"),
        ex("Squat Jump", 4, 1, 10, "20 sec on / 10 sec off", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explode up, soft landing", "Bodyweight Squat"),
        ex("Burpee", 4, 1, 10, "20 sec on / 10 sec off", "Bodyweight", "Full Body", "Pectoralis Major", ["Quadriceps", "Core"], "intermediate", "Full range, chest to floor", "Squat Thrust"),
        ex("Mountain Climber", 4, 1, 10, "20 sec on / 10 sec off", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Sprint pace, flat back", "Plank Hold"),
        ex("Skater Jump", 4, 1, 10, "20 sec on / 10 sec off", "Bodyweight", "Legs", "Glutes", ["Hip Adductors", "Quadriceps"], "intermediate", "Wide lateral bound, stay low", "Lateral Shuffle"),
    ])

programs_batch_1.append(
    ("Morning Fat Burn", "Fat Loss", [1, 2, 4], [5, 6], "Fasted AM workouts designed for maximum fat oxidation before breakfast", True, "Med",
     lambda w, t: [morning_fasted_circuit(), morning_tabata(), morning_fasted_circuit(), morning_tabata(), morning_fasted_circuit()])
)

# ========================================================================
# EVENING METABOLIC BOOST
# ========================================================================

def evening_metabolic_a():
    return wo("PM Metabolic Push", "fat_loss", 40, [
        ex("Barbell Clean and Press", 4, 8, 60, "Moderate weight", "Barbell", "Full Body", "Shoulders", ["Quadriceps", "Glutes", "Core"], "intermediate", "Power clean to strict press, control descent", "Dumbbell Clean and Press"),
        ex("Dumbbell Goblet Squat", 4, 12, 45, "Moderate weight", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, elbows inside knees", "Bodyweight Squat"),
        ex("Bent-Over Row", 3, 10, 45, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to navel, squeeze shoulder blades", "Cable Row"),
        ex("Dumbbell Reverse Lunge", 3, 10, 30, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step back, upright torso", "Bodyweight Lunge"),
        ex("Push Press", 3, 10, 45, "Moderate weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "intermediate", "Quarter dip to drive, use legs", "Dumbbell Press"),
        ex("Hanging Leg Raise", 3, 12, 30, "Controlled", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "No swinging, bring toes to bar", "Lying Leg Raise"),
    ])

def evening_metabolic_b():
    return wo("PM Metabolic Conditioning", "fat_loss", 40, [
        ex("Kettlebell Swing", 4, 20, 30, "Moderate to heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap, bell to eye level", "Dumbbell Swing"),
        ex("Dumbbell Thruster", 4, 10, 30, "Moderate weight", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Deep squat to overhead press", "Barbell Thruster"),
        ex("Renegade Row", 3, 8, 30, "Moderate dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Wide stance for stability, row each side", "Bent-Over Row"),
        ex("Box Jump", 3, 10, 30, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive takeoff, step down", "Squat Jump"),
        ex("Ball Slam", 4, 12, 20, "10-20 lb ball", "Medicine Ball", "Core", "Rectus Abdominis", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Full overhead, slam with intent", "Dumbbell Thruster"),
        ex("Farmer Carry", 3, 1, 30, "Heavy, 40 yard walk", "Dumbbells", "Full Body", "Forearms", ["Core", "Traps", "Shoulders"], "beginner", "Tall posture, tight core, smooth gait", "Suitcase Carry"),
    ])

programs_batch_1.append(
    ("Evening Metabolic Boost", "Fat Loss", [1, 2, 4], [4, 5], "PM metabolism-spiking sessions with compound movements and metabolic finishers", True, "Med",
     lambda w, t: [evening_metabolic_a(), evening_metabolic_b(), evening_metabolic_a(), evening_metabolic_b()])
)

# ========================================================================
# BIRTHDAY SHRED (HIGH priority missed earlier)
# ========================================================================

def birthday_upper_pump():
    return wo("Upper Body Pump", "fat_loss", 45, [
        ex("Incline Dumbbell Press", 4, 12, 45, "Moderate weight", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "Full stretch at bottom, squeeze at top", "Incline Push-Up"),
        ex("Cable Fly", 3, 15, 30, "Light to moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Slight bend in elbows, squeeze at center", "Dumbbell Fly"),
        ex("Lateral Raise", 4, 15, 30, "Light weight", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Traps"], "beginner", "Control the negative, slight lean forward", "Cable Lateral Raise"),
        ex("Tricep Rope Pushdown", 3, 15, 30, "Moderate weight", "Cable Machine", "Arms", "Triceps", ["Forearms"], "beginner", "Spread rope at bottom, lock elbows", "Dumbbell Kickback"),
        ex("Dumbbell Curl", 3, 12, 30, "Moderate weight", "Dumbbells", "Arms", "Biceps", ["Forearms"], "beginner", "No swinging, full range of motion", "Hammer Curl"),
        ex("Face Pull", 3, 15, 30, "Light to moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "Rotator Cuff"], "beginner", "Pull to ears, externally rotate", "Band Pull-Apart"),
    ])

def birthday_lower_burn():
    return wo("Lower Body Burn", "fat_loss", 45, [
        ex("Barbell Hip Thrust", 4, 12, 60, "Heavy weight", "Barbell", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "Full hip extension, squeeze at top", "Glute Bridge"),
        ex("Bulgarian Split Squat", 3, 10, 45, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated, control descent", "Reverse Lunge"),
        ex("Leg Press", 3, 15, 45, "Moderate weight", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full range, don't lock knees", "Goblet Squat"),
        ex("Leg Curl", 3, 12, 30, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Squeeze at top, slow negative", "Nordic Curl"),
        ex("Calf Raise", 4, 15, 30, "Moderate weight", "Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full range, pause at top", "Bodyweight Calf Raise"),
        ex("Hanging Leg Raise", 3, 12, 30, "Controlled", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, bring knees to chest", "Lying Leg Raise"),
    ])

def birthday_full_body_hiit():
    return wo("Full Body HIIT Finisher", "hiit", 30, [
        ex("Burpee", 4, 10, 20, "Max effort", "Bodyweight", "Full Body", "Pectoralis Major", ["Quadriceps", "Core"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
        ex("Kettlebell Swing", 4, 15, 20, "Moderate weight", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, bell to chest height", "Dumbbell Swing"),
        ex("Box Jump", 3, 10, 20, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly, step down", "Squat Jump"),
        ex("Battle Rope Alternating Waves", 3, 30, 20, "30 seconds", "Battle Ropes", "Arms", "Shoulders", ["Core", "Back"], "intermediate", "Fast alternating, athletic stance", "Jumping Jacks"),
        ex("Mountain Climber", 3, 30, 15, "Sprint pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Flat back, fast knee drives", "Plank Hold"),
    ])

programs_batch_1.append(
    ("Birthday Shred", "Fat Loss", [2, 4, 8], [4, 5], "Look your best for your special day with targeted sculpting and fat burning", True, "High",
     lambda w, t: [birthday_upper_pump(), birthday_lower_burn(), birthday_full_body_hiit(), birthday_upper_pump()])
)

# ========================================================================
# POST-BABY SHRED (HIGH priority)
# ========================================================================

def postbaby_core_rehab():
    return wo("Core Rehabilitation", "rehab", 35, [
        ex("Diaphragmatic Breathing", 3, 10, 20, "Deep breaths", "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis", "Pelvic Floor"], "beginner", "Inhale expand belly, exhale draw navel in", "Box Breathing"),
        ex("Pelvic Floor Activation", 3, 10, 15, "Hold 5 seconds each", "Bodyweight", "Core", "Pelvic Floor", ["Transverse Abdominis"], "beginner", "Gentle squeeze and lift, don't hold breath", "Kegel Exercise"),
        ex("Dead Bug", 3, 10, 20, "Slow and controlled", "Bodyweight", "Core", "Rectus Abdominis", ["Transverse Abdominis", "Hip Flexors"], "beginner", "Lower back stays flat, opposite arm and leg", "Modified Dead Bug"),
        ex("Bird Dog", 3, 10, 20, "Each side", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Extend opposite arm/leg, minimal rotation", "Quadruped Hold"),
        ex("Glute Bridge", 3, 12, 20, "Bodyweight", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Pelvic Floor"], "beginner", "Drive through heels, squeeze glutes at top", "Hip Lift"),
        ex("Side-Lying Clam", 3, 15, 15, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Rotators"], "beginner", "Keep feet together, open knees like a clam", "Banded Clam"),
    ])

def postbaby_strength_a():
    return wo("Postnatal Strength A", "strength", 40, [
        ex("Goblet Squat", 3, 10, 45, "Light to moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold weight at chest, sit back and down", "Bodyweight Squat"),
        ex("Incline Push-Up", 3, 10, 30, "Bench or wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands on elevated surface, full range", "Wall Push-Up"),
        ex("Seated Cable Row", 3, 10, 45, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Sit tall, pull to belly, squeeze back", "Band Row"),
        ex("Step-Up", 3, 10, 30, "Bodyweight or light DBs", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Drive through front foot, full extension", "Bodyweight Squat"),
        ex("Pallof Press", 3, 10, 30, "Light cable", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "beginner", "Resist rotation, press straight out", "Band Pallof Press"),
        ex("Wall Sit", 2, 1, 30, "30-45 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Back flat against wall, thighs parallel", "Chair Squat"),
    ])

def postbaby_cardio_recovery():
    return wo("Low-Impact Cardio", "cardio", 30, [
        ex("Brisk Walking", 1, 1, 0, "15 minutes steady", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Arms swing naturally, brisk pace", "Marching in Place"),
        ex("Elliptical", 1, 1, 0, "10 minutes low resistance", "Elliptical", "Full Body", "Quadriceps", ["Glutes", "Arms"], "beginner", "Low impact, moderate effort", "Stationary Bike"),
        ex("Bodyweight Squat", 2, 15, 20, "Moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Full depth, arms forward", "Wall Sit"),
        ex("Modified Burpee", 2, 8, 30, "No jump, step back", "Bodyweight", "Full Body", "Pectoralis Major", ["Quadriceps", "Core"], "beginner", "Step back to plank, step forward, stand", "Squat to Stand"),
    ])

programs_batch_1.append(
    ("Post-Baby Shred", "Fat Loss", [8, 12, 16], [3, 4], "Safe and progressive postpartum recovery and fat loss program", False, "High",
     lambda w, t: [postbaby_core_rehab(), postbaby_strength_a(), postbaby_cardio_recovery()])
)

# ========================================================================
# GENERATE ALL
# ========================================================================

for prog_name, cat, durs, sessions_list, desc, has_ss, pri, workout_fn in programs_batch_1:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.25: focus = f"Week {w} - Foundation: build work capacity and learn movements"
            elif p <= 0.5: focus = f"Week {w} - Build: increase intensity and volume"
            elif p <= 0.75: focus = f"Week {w} - Push: higher intensity, metabolic challenge"
            else: focus = f"Week {w} - Peak: maximum effort, test your limits"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, has_ss, pri, weeks_data, mn)
    if s:
        helper.update_tracker(prog_name, "Done")
        print(f"OK: {prog_name}")

helper.close()
print("\n=== FAT LOSS MED/HIGH PRIORITY BATCH COMPLETE ===")
