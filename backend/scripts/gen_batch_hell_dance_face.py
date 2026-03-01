#!/usr/bin/env python3
"""Generate programs for Categories 29-31: Hell Mode, Dance Fitness, Face & Jaw."""
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
# CAT 29 - HELL MODE
# ========================================================================

def hell_week_wo():
    return wo("Hell Week", "hell_mode", 60, [
        ex("Burpee", 5, 20, 30, "Max effort every rep", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "advanced", "Chest to floor, explosive jump, no pacing allowed", "Squat Thrust"),
        ex("Barbell Thruster", 5, 15, 30, "Heavy weight, no quitting", "Barbell", "Full Body", "Quadriceps", ["Shoulders", "Triceps", "Core"], "advanced", "Front squat to overhead press, fluid motion, heavy", "Dumbbell Thruster"),
        ex("Pull-Up", 5, 15, 30, "Strict form, no kipping", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full dead hang, chin over bar, controlled down", "Band-Assisted Pull-Up"),
        ex("Box Jump", 5, 20, 30, "High box, explosive", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Explosive jump, full hip extension at top", "Squat Jump"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy carry 40 meters", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core", "Legs"], "advanced", "Heaviest possible, walk fast, grip crushing", "Sandbag Carry"),
        ex("Wall Ball", 5, 30, 30, "20lb ball, 10ft target", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core"], "advanced", "Deep squat, drive ball to target, catch and go", "Thruster"),
        ex("Assault Bike", 3, 1, 60, "Max calories in 60 seconds", "Stationary Bike", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Arms and legs, max output, leave nothing", "Sprint in Place"),
    ])

def three_hundred_challenge_wo():
    return wo("300 Workout Challenge", "hell_mode", 45, [
        ex("Pull-Up", 1, 25, 0, "No rest between exercises", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "25 reps, break into sets if needed, move fast", "Band-Assisted Pull-Up"),
        ex("Deadlift", 1, 50, 0, "135lbs, touch and go", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "advanced", "50 reps at 135, maintain form even when fatigued", "Dumbbell Deadlift"),
        ex("Push-Up", 1, 50, 0, "Chest to floor each rep", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "50 reps, full range, no shortcuts", "Knee Push-Up"),
        ex("Box Jump", 1, 50, 0, "24-inch box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "50 reps, step down to save knees", "Squat Jump"),
        ex("Floor Wiper", 1, 50, 0, "Barbell overhead", "Barbell", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "advanced", "Hold barbell locked out, feet touch plate each side", "Lying Leg Raise"),
        ex("Clean and Press", 1, 50, 0, "36lb kettlebell", "Kettlebell", "Full Body", "Deltoids", ["Quadriceps", "Core"], "advanced", "25 each arm, clean to rack, press overhead", "Dumbbell Clean and Press"),
        ex("Pull-Up", 1, 25, 0, "Finish where you started", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Final 25, dig deep, earn the finish", "Band-Assisted Pull-Up"),
    ])

def thousand_rep_day_wo():
    return wo("1000 Rep Day", "hell_mode", 60, [
        ex("Air Squat", 1, 150, 0, "150 reps, break as needed", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full depth every rep, chest up, no half reps", "Goblet Squat"),
        ex("Push-Up", 1, 150, 0, "150 reps", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Chest to floor, full lockout, partition as needed", "Knee Push-Up"),
        ex("Sit-Up", 1, 150, 0, "150 reps", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Full sit-up, touch toes at top", "Crunch"),
        ex("Lunge", 1, 150, 0, "75 each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Alternate legs, full depth, knee to floor", "Step-Up"),
        ex("Burpee", 1, 100, 0, "100 reps", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Chest to floor, jump up, every single one", "Squat Thrust"),
        ex("Mountain Climber", 1, 200, 0, "100 each side", "Bodyweight", "Core", "Hip Flexors", ["Core", "Shoulders"], "advanced", "Fast pace, drive knees to chest", "Plank Knee Tuck"),
        ex("Jumping Jack", 1, 100, 0, "100 reps to finish", "Bodyweight", "Full Body", "Calves", ["Deltoids"], "beginner", "Full range arms and legs", "Step Jack"),
    ])

def exhaust_full_body_wo():
    return wo("EXHAUST ME - Full Body", "hell_mode", 50, [
        ex("Burpee to Pull-Up", 5, 10, 20, "No breaks between reps", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Quadriceps", "Core"], "advanced", "Burpee under bar, jump to pull-up, drop and repeat", "Burpee"),
        ex("Dumbbell Man Maker", 4, 8, 30, "Moderate-heavy DBs", "Dumbbells", "Full Body", "Quadriceps", ["Chest", "Back", "Shoulders"], "advanced", "Push-up, row each arm, clean, thruster, repeat", "Dumbbell Thruster"),
        ex("Kettlebell Swing", 4, 30, 20, "Heavy bell", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "advanced", "30 unbroken swings, max power each rep", "Dumbbell Swing"),
        ex("Box Jump Over", 4, 15, 20, "Jump over box, turn, repeat", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Jump completely over box, turn around, repeat", "Squat Jump"),
        ex("Assault Bike Sprint", 4, 1, 30, "30 seconds all-out", "Stationary Bike", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Everything you have, max calories", "Sprint in Place"),
        ex("Turkish Get-Up", 3, 5, 30, "Each side, heavy", "Kettlebell", "Full Body", "Core", ["Shoulders", "Glutes", "Quadriceps"], "advanced", "Floor to standing, heavy weight overhead", "Half Get-Up"),
    ])

def exhaust_upper_wo():
    return wo("EXHAUST ME - Upper", "hell_mode", 45, [
        ex("Push-Up Ladder", 1, 55, 0, "1-2-3-4-5-6-7-8-9-10 reps", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Ascending ladder, minimal rest, 55 total reps", "Knee Push-Up"),
        ex("Pull-Up", 5, 10, 30, "50 total reps", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Strict form, no kipping, earn every rep", "Band-Assisted Pull-Up"),
        ex("Dumbbell Shoulder Press", 4, 15, 30, "Moderate weight, high reps", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Core"], "advanced", "Full range, press until failure, push through", "Push Press"),
        ex("Dip", 4, 15, 30, "Add weight if bodyweight is easy", "Dip Bar", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Full depth, lockout at top, controlled", "Bench Dip"),
        ex("Barbell Curl to Press", 4, 12, 30, "Curl then press overhead", "Barbell", "Arms", "Biceps", ["Deltoids", "Triceps"], "advanced", "Curl to shoulders, press overhead, lower", "Dumbbell Curl to Press"),
        ex("Plank to Push-Up", 3, 15, 20, "Alternate leading arm", "Bodyweight", "Core", "Triceps", ["Core", "Shoulders"], "advanced", "Forearm to hand position, keep hips stable", "Plank Hold"),
    ])

def exhaust_lower_wo():
    return wo("EXHAUST ME - Lower", "hell_mode", 45, [
        ex("Barbell Back Squat", 5, 20, 60, "Heavy 20-rep set", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "advanced", "20-rep breathing squat, 3 breaths between reps at top", "Goblet Squat"),
        ex("Walking Lunge", 4, 30, 30, "15 each leg, with dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Deep lunges, knee to floor, no rest at top", "Bodyweight Lunge"),
        ex("Romanian Deadlift", 4, 15, 45, "Heavy, feel the hamstrings burn", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "advanced", "Slow eccentric, stretch at bottom, powerful up", "Dumbbell RDL"),
        ex("Leg Press", 4, 25, 45, "Heavy sled, high reps", "Leg Press", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full range, do not lock knees, constant tension", "Hack Squat"),
        ex("Bulgarian Split Squat", 3, 15, 30, "Each leg, with dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Rear foot elevated, deep stretch, drive up", "Reverse Lunge"),
        ex("Wall Sit", 3, 1, 30, "Hold 90 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "advanced", "90-degree hold, burn through it, do not stand up", "Squat Hold"),
    ])

def exhaust_core_wo():
    return wo("EXHAUST ME - Core", "hell_mode", 35, [
        ex("Hanging Leg Raise", 5, 15, 20, "Toes to bar", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "advanced", "Full range, toes to bar, controlled descent", "Knee Raise"),
        ex("Ab Roller", 4, 15, 20, "Full extension", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Shoulders", "Lats"], "advanced", "Extend all the way out, roll back with abs", "Plank Walkout"),
        ex("Dragon Flag", 3, 8, 30, "Slow eccentric", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "Lower body as one unit, resist gravity, do not bend at hips", "Lying Leg Raise"),
        ex("L-Sit Hold", 4, 1, 20, "Hold 20 seconds", "Dip Bar", "Core", "Hip Flexors", ["Rectus Abdominis", "Quadriceps"], "advanced", "Straight legs, body at L-shape, squeeze everything", "Tuck L-Sit"),
        ex("Weighted Plank", 3, 1, 20, "Hold 60 seconds with plate on back", "Weight Plate", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "advanced", "Plate on back, tight core, breathe through it", "Plank Hold"),
        ex("Russian Twist", 4, 30, 20, "With medicine ball", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "advanced", "Feet off ground, rotate fully each side, 15 per side", "Bicycle Crunch"),
    ])

def iron_will_wo():
    return wo("Iron Will", "hell_mode", 55, [
        ex("Deadlift", 5, 5, 120, "Heavy 5x5, 85% 1RM", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Forearms"], "advanced", "Heavy pulls, reset each rep, max effort", "Trap Bar Deadlift"),
        ex("Barbell Back Squat", 5, 5, 120, "Heavy 5x5, 85% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Deep squats, heavy load, grind through", "Front Squat"),
        ex("Weighted Pull-Up", 5, 5, 90, "Add 25-45lbs", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full range with weight belt, strict form", "Pull-Up"),
        ex("Barbell Overhead Press", 5, 5, 90, "Heavy strict press", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "advanced", "Strict press, no leg drive, lockout overhead", "Dumbbell Press"),
        ex("Barbell Row", 5, 5, 90, "Heavy, controlled", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to lower chest, pause, lower with control", "Dumbbell Row"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy carry 60 meters", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "advanced", "Heaviest possible, walk fast, do not drop early", "Suitcase Carry"),
    ])

def gladiator_training_wo():
    return wo("Gladiator Training", "hell_mode", 50, [
        ex("Sandbag Shouldering", 5, 10, 30, "Alternate shoulders", "Sandbag", "Full Body", "Core", ["Quadriceps", "Biceps", "Shoulders"], "advanced", "Floor to shoulder, drop, repeat other side, max power", "Sandbag Clean"),
        ex("Sled Push", 4, 1, 45, "40 meters heavy", "Sled", "Legs", "Quadriceps", ["Glutes", "Calves", "Core"], "advanced", "Low position, drive with legs, heavy load", "Bear Crawl"),
        ex("Rope Climb", 3, 3, 60, "Full rope, legless if possible", "Climbing Rope", "Back", "Latissimus Dorsi", ["Biceps", "Forearms", "Core"], "advanced", "Climb to top, control descent, arm and grip strength", "Pull-Up"),
        ex("Tire Flip", 4, 8, 45, "Heavy tire", "Tire", "Full Body", "Quadriceps", ["Chest", "Glutes", "Core"], "advanced", "Deadlift position, drive hips, flip tire over", "Deadlift to Push"),
        ex("Battle Rope Slam", 4, 1, 30, "30 seconds max effort", "Battle Ropes", "Full Body", "Deltoids", ["Core", "Lats"], "advanced", "Overhead slam with full body, max power output", "Medicine Ball Slam"),
        ex("Burpee Broad Jump", 3, 10, 30, "Burpee then jump forward", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Glutes"], "advanced", "Burpee, then max distance broad jump forward", "Burpee"),
    ])

def spartan_challenge_wo():
    return wo("Spartan Challenge", "hell_mode", 50, [
        ex("Bear Crawl", 4, 1, 30, "25 meters forward and back", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps", "Hip Flexors"], "advanced", "Hips low, opposite arm and leg, fast crawl", "Mountain Climber"),
        ex("Wall Ball", 5, 20, 30, "20lb ball, 10ft target", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core"], "advanced", "Deep squat, explosive throw, catch and go immediately", "Thruster"),
        ex("Kettlebell Swing", 5, 25, 30, "Heavy bell", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "advanced", "Unbroken sets, max hip power", "Dumbbell Swing"),
        ex("Rope Slam", 4, 1, 30, "30 seconds continuous", "Battle Ropes", "Full Body", "Deltoids", ["Core", "Forearms"], "advanced", "All-out effort, alternating waves to double slams", "Medicine Ball Slam"),
        ex("Box Jump", 4, 15, 30, "30-inch box", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Explosive jump, stick landing, step down", "Squat Jump"),
        ex("Sprint", 6, 1, 30, "200 meter sprint", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "advanced", "All-out 200m, walk back for recovery", "High Knees"),
    ])

def navy_seal_inspired_wo():
    return wo("Navy SEAL Inspired", "hell_mode", 60, [
        ex("Push-Up", 5, 30, 30, "150 total, no excuses", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Perfect form, chest to floor every rep, grind", "Knee Push-Up"),
        ex("Pull-Up", 5, 15, 30, "75 total", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Dead hang start, chin over bar, no kipping", "Band-Assisted Pull-Up"),
        ex("Sit-Up", 5, 30, 20, "150 total", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Full range, touch toes, shoulder blades to floor", "Crunch"),
        ex("Air Squat", 5, 40, 30, "200 total", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Below parallel every rep, full depth", "Half Squat"),
        ex("Flutter Kick", 5, 50, 20, "25 each leg per set", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis"], "advanced", "Hands under glutes, legs 6 inches off ground, kick", "Lying Leg Raise"),
        ex("Run", 1, 1, 0, "1.5 mile run to finish", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "advanced", "Max effort 1.5 mile run, push the pace", "Jog"),
    ])

def prison_yard_wo():
    return wo("Prison Yard", "hell_mode", 45, [
        ex("Burpee", 10, 10, 15, "100 total, partition as needed", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Chest to floor, jump up, count every one", "Squat Thrust"),
        ex("Diamond Push-Up", 5, 20, 20, "Hands together", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "advanced", "Thumbs and index fingers form diamond, chest to hands", "Close-Grip Push-Up"),
        ex("Bodyweight Squat", 5, 50, 20, "250 total", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full depth, chest up, no stopping at top", "Half Squat"),
        ex("Handstand Push-Up", 5, 8, 30, "Against wall", "Bodyweight", "Shoulders", "Deltoids", ["Triceps", "Core", "Trapezius"], "advanced", "Head to floor, press to full lockout", "Pike Push-Up"),
        ex("Pistol Squat", 4, 8, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core", "Hamstrings"], "advanced", "Single leg, full depth, opposite leg straight", "Assisted Pistol"),
        ex("Planche Lean Hold", 4, 1, 30, "Hold 15 seconds", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Core", "Chest"], "advanced", "Lean forward in plank, shift weight to hands", "Plank Lean"),
    ])

def death_by_burpees_wo():
    return wo("Death by Burpees", "hell_mode", 30, [
        ex("Burpee Ladder", 1, 1, 0, "Min 1: 1 rep, Min 2: 2 reps, continue until failure", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "advanced", "Every minute add one rep, continue until you cannot complete reps in the minute", "Squat Thrust"),
        ex("Burpee Broad Jump", 3, 10, 30, "Max distance each jump", "Bodyweight", "Full Body", "Quadriceps", ["Glutes", "Chest", "Core"], "advanced", "Burpee then broad jump forward, cover ground", "Burpee"),
        ex("Burpee Pull-Up", 3, 8, 30, "Under pull-up bar", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Quadriceps", "Core"], "advanced", "Burpee, jump to bar, pull-up, drop, repeat", "Burpee"),
        ex("Lateral Burpee", 3, 10, 30, "5 each side", "Bodyweight", "Full Body", "Quadriceps", ["Obliques", "Chest", "Core"], "advanced", "Burpee, lateral jump over object, repeat", "Burpee"),
        ex("Single-Arm Burpee", 2, 6, 30, "Each arm", "Bodyweight", "Full Body", "Pectoralis Major", ["Triceps", "Core", "Quadriceps"], "advanced", "One-arm push-up position in burpee, alternate arms", "Burpee"),
    ])

def murph_prep_wo():
    return wo("Murph Prep", "hell_mode", 50, [
        ex("Run", 1, 1, 0, "1 mile run", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "advanced", "Pace yourself, you have a lot of work ahead", "Jog"),
        ex("Pull-Up", 10, 10, 0, "100 total, partition into 10x10", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Strict or kipping, get reps done, consistent pace", "Band-Assisted Pull-Up"),
        ex("Push-Up", 10, 20, 0, "200 total, 10x20", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Chest to floor every rep, maintain standards", "Knee Push-Up"),
        ex("Air Squat", 10, 30, 0, "300 total, 10x30", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Below parallel, chest up, arms forward", "Half Squat"),
        ex("Run", 1, 1, 0, "1 mile run to finish", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "advanced", "Push the pace on the final mile, leave it all out there", "Jog"),
    ])

def hundred_rep_challenge_wo():
    return wo("100 Rep Challenge", "hell_mode", 40, [
        ex("Barbell Back Squat", 1, 100, 0, "Light-moderate weight, 100 unbroken if possible", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "100 reps, rest at top position only, do not rack bar", "Goblet Squat"),
        ex("Push-Up", 1, 100, 0, "100 reps, break as needed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Full range, count every one, mental battle", "Knee Push-Up"),
        ex("Kettlebell Swing", 1, 100, 0, "Heavy bell, unbroken goal", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "advanced", "100 swings, Russian-style, grip endurance test", "Dumbbell Swing"),
        ex("Sit-Up", 1, 100, 0, "100 reps", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Touch toes at top, full range, keep moving", "Crunch"),
        ex("Burpee", 1, 100, 0, "100 reps, time yourself", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Chest to floor, jump up, beat your time next session", "Squat Thrust"),
    ])

def aquatic_warrior_wo():
    return wo("Aquatic Warrior", "hell_mode", 50, [
        ex("Pool Sprint", 6, 1, 30, "50m max effort swim", "Bodyweight", "Full Body", "Latissimus Dorsi", ["Shoulders", "Core", "Quadriceps"], "advanced", "All-out 50m freestyle sprint, turn and sprint back", "Sprint in Place"),
        ex("Treading Water", 4, 1, 30, "60 seconds hands-out-of-water treading", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders", "Hip Flexors"], "advanced", "Tread water with arms above surface, eggbeater kick", "Flutter Kick"),
        ex("Underwater Swim", 4, 1, 60, "25m underwater, single breath", "Bodyweight", "Full Body", "Latissimus Dorsi", ["Core", "Legs"], "advanced", "Full breath, dolphin kick underwater, stay calm", "Lap Swim"),
        ex("Pool Edge Push-Up", 4, 20, 20, "Push-ups off pool edge", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Hands on pool edge, push-up with water resistance", "Push-Up"),
        ex("Pool Burpee", 3, 10, 30, "Jump out of pool, burpee, jump back in", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Exit pool, burpee on deck, dive back in", "Burpee"),
        ex("Buddy Carry Swim", 2, 1, 60, "25m carrying partner or weight", "Bodyweight", "Full Body", "Core", ["Shoulders", "Legs"], "advanced", "Rescue swim style, keep partner above water", "Lap Swim"),
    ])

# Cat 29 generation
cat29_programs = [
    ("Hell Week", "Hell Mode", [1], [7], "7 days of extreme training that will break you down and build you up", "High", lambda w,t: [hell_week_wo()]*7),
    ("300 Workout Challenge", "Hell Mode", [1, 2], [6], "Spartan-inspired 300-rep workout of brutality and grit", "High", lambda w,t: [three_hundred_challenge_wo()]*3),
    ("1000 Rep Day", "Hell Mode", [1], [7], "Daily 1000 rep target across multiple movement patterns", "High", lambda w,t: [thousand_rep_day_wo()]*3),
    ("EXHAUST ME - Full Body", "Hell Mode", [1], [6, 7], "Leave absolutely nothing in the tank - full body destruction", "High", lambda w,t: [exhaust_full_body_wo()]*3),
    ("EXHAUST ME - Upper", "Hell Mode", [1], [6, 7], "Your arms will not work tomorrow - upper body annihilation", "High", lambda w,t: [exhaust_upper_wo()]*3),
    ("EXHAUST ME - Lower", "Hell Mode", [1], [6, 7], "Stairs are your enemy now - lower body destruction", "High", lambda w,t: [exhaust_lower_wo()]*3),
    ("EXHAUST ME - Core", "Hell Mode", [1], [6, 7], "Your core will question your life choices", "High", lambda w,t: [exhaust_core_wo()]*3),
    ("Iron Will", "Hell Mode", [1, 2], [6, 7], "Heavy compound lifts pushed to the absolute limit", "High", lambda w,t: [iron_will_wo()]*3),
    ("Gladiator Training", "Hell Mode", [1, 2], [6], "Functional warrior training with unconventional tools", "High", lambda w,t: [gladiator_training_wo()]*3),
    ("Spartan Challenge", "Hell Mode", [1, 2], [6], "Obstacle race-inspired intense conditioning", "High", lambda w,t: [spartan_challenge_wo()]*3),
    ("Navy SEAL Inspired", "Hell Mode", [1, 2], [6, 7], "Military-grade calisthenics and endurance training", "High", lambda w,t: [navy_seal_inspired_wo()]*3),
    ("Prison Yard", "Hell Mode", [1, 2], [6, 7], "Bodyweight-only extreme training, no equipment needed", "High", lambda w,t: [prison_yard_wo()]*3),
    ("Death by Burpees", "Hell Mode", [1, 2], [6, 7], "Progressive burpee challenge that will test your limits", "High", lambda w,t: [death_by_burpees_wo()]*3),
    ("Murph Prep", "Hell Mode", [2, 4], [5, 6], "Build toward completing the full Murph workout", "High", lambda w,t: [murph_prep_wo()]*3),
    ("100 Rep Challenge", "Hell Mode", [1, 2], [5, 6], "100 reps of every major exercise, time yourself", "High", lambda w,t: [hundred_rep_challenge_wo()]*3),
    ("Aquatic Warrior", "Hell Mode", [1, 2], [5, 6], "Pool-based extreme conditioning and combat swimmer prep", "High", lambda w,t: [aquatic_warrior_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat29_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Suffer: establish baseline of pain tolerance"
            elif p <= 0.66: focus = f"Week {w} - Endure: push beyond previous limits"
            else: focus = f"Week {w} - Conquer: break through mental and physical barriers"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 29 COMPLETE ===\n")

# ========================================================================
# CAT 30 - DANCE FITNESS
# ========================================================================

def dance_cardio_basics_wo():
    return wo("Dance Cardio Basics", "dance", 30, [
        ex("March and Clap", 2, 1, 0, "2 minutes rhythmic marching", "Bodyweight", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "March to beat, clap on counts, find the rhythm", "Step Touch"),
        ex("Step Touch", 3, 16, 0, "8 each side", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Core"], "beginner", "Step out, touch together, arms swing naturally", "Side Step"),
        ex("Grapevine", 3, 8, 0, "4 each direction", "Bodyweight", "Legs", "Hip Adductors", ["Calves", "Core"], "beginner", "Step, behind, step, touch - side to side", "Side Step"),
        ex("Arm Wave", 2, 16, 0, "Flowing arm movement", "Bodyweight", "Arms", "Deltoids", ["Biceps", "Forearms"], "beginner", "Sequential arm movement, shoulder to fingertips", "Arm Circles"),
        ex("Box Step", 3, 8, 0, "Forward, side, back, together", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "beginner", "Step in a box pattern, add hip movement", "March in Place"),
        ex("Shimmy", 2, 1, 0, "30 seconds with shoulder shake", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Chest"], "beginner", "Alternate shoulders forward and back rapidly, add bounce", "Shoulder Rolls"),
    ])

def hiphop_dance_wo():
    return wo("Hip-Hop Dance Workout", "dance", 35, [
        ex("Bounce Step", 3, 1, 0, "60 seconds rhythmic bounce", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Knees soft, bounce with the beat, feel the groove", "March in Place"),
        ex("Body Roll", 2, 8, 0, "Head to hips sequential roll", "Bodyweight", "Core", "Rectus Abdominis", ["Erector Spinae", "Hip Flexors"], "intermediate", "Wave through body head-chest-abs-hips, smooth flow", "Cat-Cow Standing"),
        ex("Running Man", 3, 16, 0, "Classic hip-hop move", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Core"], "intermediate", "Slide back foot, drive front knee, alternate fast", "High Knees"),
        ex("Pop and Lock", 2, 8, 0, "Isolate body parts", "Bodyweight", "Full Body", "Core", ["Shoulders", "Arms"], "intermediate", "Sharp stop and start, isolate chest, arms, then head", "Body Roll"),
        ex("Dougie Slide", 3, 8, 0, "Side to side with arm wave", "Bodyweight", "Legs", "Hip Abductors", ["Core", "Shoulders"], "intermediate", "Lean and slide side, wave arm over head", "Grapevine"),
        ex("Hip-Hop Squat Groove", 3, 12, 0, "Squat with bounce and arm patterns", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Low squat with bounce, add arm choreography", "Air Squat"),
    ])

def latin_dance_wo():
    return wo("Latin Dance Fitness", "dance", 35, [
        ex("Salsa Basic Step", 3, 16, 0, "Quick-quick-slow rhythm", "Bodyweight", "Legs", "Calves", ["Hip Flexors", "Core"], "beginner", "Step forward-recover-together, step back-recover-together", "Step Touch"),
        ex("Bachata Side Step", 3, 16, 0, "Step-step-step-tap", "Bodyweight", "Legs", "Hip Adductors", ["Calves", "Core"], "beginner", "Three steps to side, tap on 4, add hip pop", "Side Step"),
        ex("Merengue March", 2, 1, 0, "60 seconds continuous", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Obliques"], "beginner", "March with hip sway, knees lift, arms pump", "March in Place"),
        ex("Cha-Cha Shuffle", 3, 8, 0, "Triple step pattern", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Step-ball-change, quick-quick-slow, hip action", "Grapevine"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Obliques"], "beginner", "Big circles with hips, isolate from upper body", "Standing Hip Sway"),
        ex("Cumbia Step", 3, 8, 0, "Back cross-step pattern", "Bodyweight", "Legs", "Calves", ["Hip Rotators", "Core"], "intermediate", "Cross foot behind, step out, add arm styling", "Grapevine"),
    ])

def dance_hiit_fusion_wo():
    return wo("Dance HIIT Fusion", "dance", 35, [
        ex("High Knee Dance", 3, 1, 20, "30 seconds max effort with rhythm", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "intermediate", "Drive knees up to the beat, pump arms", "High Knees"),
        ex("Squat Pop", 3, 12, 20, "Squat then pop up with arm throw", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explosive pop up, throw arms overhead", "Jump Squat"),
        ex("Shimmy Shuffle Sprint", 3, 1, 20, "30 seconds alternating", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Core"], "intermediate", "Shimmy shoulders 4 counts, shuffle sprint 4 counts", "Sprint in Place"),
        ex("Dance Burpee", 3, 8, 20, "Burpee with spin at top", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Burpee, jump up with 360 spin, land and go", "Burpee"),
        ex("Body Roll to Squat", 3, 10, 20, "Flow into squat from roll", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Glutes"], "intermediate", "Standing body roll, drop into squat, pop up", "Squat"),
        ex("Freestyle Dance Cardio", 2, 1, 0, "60 seconds free movement", "Bodyweight", "Full Body", "Core", ["Legs", "Shoulders"], "beginner", "Move freely, express yourself, keep moving the whole time", "Jumping Jacks"),
    ])

def bollywood_dance_wo():
    return wo("Bollywood Dance Workout", "dance", 35, [
        ex("Bhangra Bounce", 3, 16, 0, "Energetic bounce with arm pumps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Shoulders"], "beginner", "Bouncing step, screw lightbulb hands overhead, high energy", "Jumping Jacks"),
        ex("Mudra Hand Gestures", 2, 8, 0, "Classical hand movements", "Bodyweight", "Arms", "Forearm Flexors", ["Wrist Flexors", "Fingers"], "beginner", "Lotus, deer, peacock hand shapes with arm extension", "Wrist Circles"),
        ex("Jhoomer Step", 3, 8, 0, "Graceful spinning step", "Bodyweight", "Legs", "Calves", ["Core", "Hip Rotators"], "intermediate", "Pivot turn with arm extension, graceful spin", "Grapevine"),
        ex("Thumka Hip Pop", 3, 16, 0, "Sharp hip pop movement", "Bodyweight", "Hips", "Obliques", ["Glutes", "Core"], "beginner", "Sharp hip thrust to one side on beat, alternate", "Hip Circle"),
        ex("Shoulder Shimmy", 2, 1, 0, "30 seconds rapid shimmy", "Bodyweight", "Shoulders", "Deltoids", ["Trapezius", "Core"], "beginner", "Alternate shoulders forward and back, rapid tempo", "Shoulder Rolls"),
        ex("Bollywood Squat Combo", 3, 8, 0, "Squat with arm patterns", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Shoulders"], "beginner", "Squat, stand with namaste arms, add expressions", "Air Squat"),
    ])

def kpop_dance_wo():
    return wo("K-Pop Dance Fitness", "dance", 35, [
        ex("Point Choreography", 3, 8, 0, "Sharp point dance moves", "Bodyweight", "Full Body", "Deltoids", ["Core", "Legs"], "intermediate", "Sharp arm points synced with steps, hit each position hard", "Arm Extension"),
        ex("Wave and Body Roll", 2, 8, 0, "Sequential body wave", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Arm wave flowing into body roll, smooth and controlled", "Body Roll"),
        ex("Pop and Freeze", 3, 8, 0, "Dance then freeze in position", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Move on beat, freeze on accent, hold position cleanly", "March and Stop"),
        ex("Slide Step Combo", 3, 16, 0, "Smooth side slides", "Bodyweight", "Legs", "Calves", ["Hip Adductors", "Core"], "intermediate", "Smooth slide step with sharp arm choreography", "Side Step"),
        ex("Hair Flip Crunch", 3, 8, 0, "Standing crunch with flair", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Neck"], "beginner", "Bend forward sharply, come up with head toss, engage core", "Standing Crunch"),
        ex("Drop Squat", 3, 10, 0, "Fast drop into squat with attitude", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Quick drop into deep squat, pop up with style", "Jump Squat"),
    ])

def african_dance_wo():
    return wo("African Dance Workout", "dance", 35, [
        ex("Djembe Step", 3, 16, 0, "Rhythmic foot pattern", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Step pattern matching drum rhythm, feet close to ground", "March in Place"),
        ex("Harvest Dance Movement", 2, 8, 0, "Reaching and gathering motion", "Bodyweight", "Full Body", "Deltoids", ["Core", "Hamstrings"], "beginner", "Reach overhead, scoop down, rise up, storytelling through movement", "Arm Raises"),
        ex("Hip and Rib Isolation", 3, 8, 0, "Isolate hips then ribs", "Bodyweight", "Core", "Obliques", ["Hip Flexors", "Intercostals"], "intermediate", "Move hips without ribs, then ribs without hips, polyrhythm", "Hip Circle"),
        ex("Jump and Stomp", 3, 12, 0, "Explosive jumps with foot stomps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Jump up, land with powerful stomp, feel the earth", "Jump Squat"),
        ex("Shoulder Isolation", 2, 16, 0, "One shoulder at a time", "Bodyweight", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Pop one shoulder forward, then other, then both", "Shoulder Rolls"),
        ex("Celebration Dance", 2, 1, 0, "60 seconds free expression", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "beginner", "Joyful movement, high energy, celebrate your body", "Freestyle Dance"),
    ])

def contemporary_dance_wo():
    return wo("Contemporary Dance Fitness", "dance", 35, [
        ex("Plie to Releve", 3, 12, 0, "Bend and rise", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "beginner", "Deep plie in second position, rise to toes, use arms", "Squat to Calf Raise"),
        ex("Contract and Release", 3, 8, 0, "Core contraction and extension", "Bodyweight", "Core", "Rectus Abdominis", ["Erector Spinae"], "intermediate", "Round spine forward (contract), arch back open (release)", "Cat-Cow Standing"),
        ex("Floor Roll", 2, 6, 0, "Controlled descent and rise", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Roll down to floor smoothly, reverse to standing", "Squat to Floor"),
        ex("Developpe", 2, 8, 0, "Each leg, controlled extension", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Draw knee up, extend leg slowly, hold, lower with control", "Standing Leg Extension"),
        ex("Spiral Turn", 2, 6, 0, "Controlled spinning turn", "Bodyweight", "Full Body", "Core", ["Calves", "Hip Rotators"], "intermediate", "Spot head, spin on ball of foot, use core for control", "Pivot Turn"),
        ex("Grand Battement", 2, 8, 0, "Each leg, large kick", "Bodyweight", "Legs", "Hip Flexors", ["Hamstrings", "Core"], "intermediate", "Controlled high kick, straight standing leg, point toes", "Leg Swing"),
    ])

def ballet_fitness_wo():
    return wo("Ballet Fitness", "dance", 35, [
        ex("First Position Plie", 3, 12, 0, "Heels together, bend and rise", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Adductors"], "beginner", "Heels together, toes out, bend knees over toes, rise", "Squat"),
        ex("Tendu", 3, 12, 0, "Each leg, extend and return", "Bodyweight", "Legs", "Calves", ["Hip Flexors", "Quadriceps"], "beginner", "Slide foot along floor to full point, draw back to position", "Toe Point"),
        ex("Releve", 3, 15, 0, "Rise to toes and lower", "Bodyweight", "Legs", "Calves", ["Ankle Stabilizers", "Core"], "beginner", "Rise smoothly to balls of feet, hold, lower with control", "Calf Raise"),
        ex("Arabesque", 2, 8, 0, "Each leg, hold balance", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core", "Lower Back"], "intermediate", "Stand on one leg, extend other behind, arms forward", "Single-Leg Balance"),
        ex("Port de Bras", 2, 8, 0, "Arm positions 1-5", "Bodyweight", "Arms", "Deltoids", ["Biceps", "Core"], "beginner", "Smooth arm transitions through all five positions", "Arm Circles"),
        ex("Grand Plie", 3, 8, 0, "Second position deep bend", "Bodyweight", "Legs", "Quadriceps", ["Adductors", "Glutes"], "intermediate", "Wide stance, deep bend, rise with control, arms second", "Sumo Squat"),
    ])

def belly_dance_wo():
    return wo("Belly Dance Fitness", "dance", 30, [
        ex("Hip Drop", 3, 16, 0, "Isolate hip drop each side", "Bodyweight", "Hips", "Obliques", ["Hip Flexors", "Glutes"], "beginner", "Drop one hip sharply, keep other side lifted, alternate", "Hip Circle"),
        ex("Figure 8 Hips", 2, 8, 0, "Horizontal figure 8 pattern", "Bodyweight", "Hips", "Obliques", ["Hip Flexors", "Glutes"], "intermediate", "Draw figure 8 with hips, keep upper body still", "Hip Circle"),
        ex("Shimmy", 3, 1, 0, "30 seconds continuous", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Rapid alternating knee bends creating hip shimmy", "High Knees Slow"),
        ex("Snake Arms", 2, 8, 0, "Flowing sequential arm movement", "Bodyweight", "Arms", "Deltoids", ["Biceps", "Wrist Flexors"], "beginner", "Wave moves through shoulder-elbow-wrist-fingers", "Arm Wave"),
        ex("Chest Circle", 2, 8, 0, "Isolate ribcage circles", "Bodyweight", "Core", "Intercostals", ["Obliques", "Erector Spinae"], "intermediate", "Ribcage circles while keeping hips still", "Torso Rotation"),
        ex("Veil Work Arms", 2, 1, 0, "60 seconds flowing arm movement", "Bodyweight", "Arms", "Deltoids", ["Trapezius", "Core"], "beginner", "Hold arms extended, flowing movements, build endurance", "Arm Circles"),
    ])

def zumba_style_wo():
    return wo("Zumba Style", "dance", 40, [
        ex("Merengue Basic", 3, 1, 0, "60 seconds march and groove", "Bodyweight", "Legs", "Calves", ["Hip Flexors", "Core"], "beginner", "Side-to-side marching with hip movement and arm pumps", "March in Place"),
        ex("Salsa Step", 3, 16, 0, "Front and back salsa pattern", "Bodyweight", "Legs", "Calves", ["Core", "Hip Flexors"], "beginner", "Forward-recover-together, back-recover-together with hips", "Step Touch"),
        ex("Reggaeton Squat Pop", 3, 12, 0, "Drop and pop with attitude", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat drop, explosive pop up, add arm styling", "Jump Squat"),
        ex("Cumbia Shuffle", 3, 16, 0, "Shuffle step with arm circles", "Bodyweight", "Legs", "Calves", ["Shoulders", "Core"], "beginner", "Shuffle feet side to side, circle arms overhead", "Side Step"),
        ex("Samba Bounce", 3, 1, 0, "60 seconds continuous", "Bodyweight", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Triple step bounce with hip movement, knees bend", "Bounce Step"),
        ex("Cool Down Stretch", 1, 1, 0, "3 minutes gentle movement", "Bodyweight", "Full Body", "Hamstrings", ["Shoulders", "Hips"], "beginner", "Slow rhythmic stretching, cool heart rate down", "Standing Stretches"),
    ])

def dance_beginners_wo():
    return wo("Dance for Beginners", "dance", 25, [
        ex("March to Music", 2, 1, 0, "2 minutes easy marching", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Find the beat, march in time, clap if it helps", "Walking"),
        ex("Step Touch", 3, 16, 0, "Side step and touch", "Bodyweight", "Legs", "Hip Abductors", ["Calves"], "beginner", "Step out, touch together, add arm swing", "Side Step"),
        ex("Two-Step", 3, 8, 0, "Simple two-step pattern", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Step right-together, step left-together, simple pattern", "March in Place"),
        ex("Arm Swing", 2, 16, 0, "Coordinated arm movement", "Bodyweight", "Arms", "Deltoids", ["Core"], "beginner", "Swing arms up, down, side to side with steps", "Arm Circles"),
        ex("Gentle Groove", 2, 1, 0, "60 seconds free movement", "Bodyweight", "Full Body", "Core", ["Legs"], "beginner", "Move however feels good, no right or wrong", "March in Place"),
    ])

# Cat 30 generation
cat30_programs = [
    ("Dance Cardio Basics", "Dance Fitness", [1, 2, 4], [3, 4], "Learn dance fitness fundamentals with easy-to-follow moves", "High", lambda w,t: [dance_cardio_basics_wo()]*3),
    ("Hip-Hop Dance Workout", "Dance Fitness", [2, 4, 8], [3, 4], "Urban dance cardio with hip-hop style movements", "High", lambda w,t: [hiphop_dance_wo()]*3),
    ("Latin Dance Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "Salsa, bachata, and merengue inspired cardio workout", "High", lambda w,t: [latin_dance_wo()]*3),
    ("Dance HIIT Fusion", "Dance Fitness", [2, 4, 8], [3, 4], "Dance moves combined with high-intensity interval training", "High", lambda w,t: [dance_hiit_fusion_wo()]*3),
    ("Bollywood Dance Workout", "Dance Fitness", [2, 4, 8], [3, 4], "Indian dance-inspired cardio with Bollywood choreography", "High", lambda w,t: [bollywood_dance_wo()]*3),
    ("K-Pop Dance Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "Korean pop choreography-inspired dance workout", "High", lambda w,t: [kpop_dance_wo()]*3),
    ("African Dance Workout", "Dance Fitness", [2, 4, 8], [3, 4], "African-inspired rhythmic dance movement", "High", lambda w,t: [african_dance_wo()]*3),
    ("Contemporary Dance Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "Modern dance-inspired fitness with fluid movement", "High", lambda w,t: [contemporary_dance_wo()]*3),
    ("Ballet Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "Ballet-inspired toning and cardio workout", "High", lambda w,t: [ballet_fitness_wo()]*3),
    ("Belly Dance Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "Core-focused belly dance movement for fitness", "High", lambda w,t: [belly_dance_wo()]*3),
    ("Zumba Style", "Dance Fitness", [1, 2, 4], [3, 4], "Latin-inspired dance party fitness workout", "High", lambda w,t: [zumba_style_wo()]*3),
    ("Dance for Beginners", "Dance Fitness", [1, 2, 4], [3, 4], "Simple, no-intimidation intro to dance fitness", "High", lambda w,t: [dance_beginners_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat30_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Learn: master basic steps and find your rhythm"
            elif p <= 0.66: focus = f"Week {w} - Flow: link moves together, build stamina"
            else: focus = f"Week {w} - Perform: full routines, add expression and style"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 30 COMPLETE ===\n")

# ========================================================================
# CAT 31 - FACE & JAW EXERCISES
# ========================================================================

def face_yoga_basics_wo():
    return wo("Face Yoga Basics", "face_jaw", 10, [
        ex("Cheek Puff", 3, 10, 10, "Puff cheeks, hold, release", "Bodyweight", "Face", "Buccinator", ["Orbicularis Oris", "Cheek Muscles"], "beginner", "Fill cheeks with air, hold 5 seconds, release slowly", "Cheek Massage"),
        ex("Fish Face", 3, 10, 10, "Suck cheeks in, hold", "Bodyweight", "Face", "Buccinator", ["Zygomaticus", "Cheek Muscles"], "beginner", "Suck cheeks in, try to smile, hold 5 seconds", "Cheek Puff"),
        ex("Wide Smile Hold", 3, 1, 10, "Hold 10 seconds", "Bodyweight", "Face", "Zygomaticus Major", ["Orbicularis Oris", "Risorius"], "beginner", "Smile as wide as possible, hold, relax", "Gentle Smile"),
        ex("Forehead Smoother", 3, 10, 10, "Resist forehead movement", "Bodyweight", "Face", "Frontalis", ["Procerus", "Corrugator"], "beginner", "Place fingers on forehead, try to raise brows against resistance", "Brow Raise"),
        ex("Eye Circle", 2, 5, 10, "Each direction", "Bodyweight", "Face", "Orbicularis Oculi", ["Eye Muscles"], "beginner", "Roll eyes in full circles slowly, each direction", "Blink Exercise"),
        ex("Jaw Release", 2, 8, 10, "Open wide and relax", "Bodyweight", "Face", "Masseter", ["Temporalis", "Pterygoid"], "beginner", "Open mouth wide, hold 5 seconds, close gently", "Jaw Massage"),
    ])

def jawline_definition_wo():
    return wo("Jawline Definition", "face_jaw", 10, [
        ex("Chin Lift", 3, 12, 10, "Tilt head back, push chin forward", "Bodyweight", "Face", "Platysma", ["Mentalis", "Neck Muscles"], "beginner", "Look up, push lower jaw forward, feel stretch under chin", "Neck Extension"),
        ex("Jaw Clench and Release", 3, 10, 10, "Clench teeth, hold, release", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Clench jaw firmly 5 seconds, release fully, repeat", "Jaw Massage"),
        ex("Tongue Press", 3, 10, 10, "Press tongue to roof of mouth", "Bodyweight", "Face", "Mylohyoid", ["Digastric", "Suprahyoid"], "beginner", "Press tongue flat against palate, hold 5 seconds, release", "Tongue Stretch"),
        ex("Neck Curl", 3, 10, 10, "Lying face up", "Bodyweight", "Face", "Platysma", ["Sternocleidomastoid", "Neck Flexors"], "beginner", "Lie on back, tuck chin and lift head slightly off ground, hold", "Chin Tuck"),
        ex("Jaw Slide", 2, 10, 10, "Slide jaw side to side", "Bodyweight", "Face", "Pterygoid", ["Masseter"], "beginner", "Slowly slide lower jaw to one side, return center, other side", "Jaw Circle"),
        ex("Chewing Exercise", 2, 1, 0, "30 seconds focused chewing motion", "Bodyweight", "Face", "Masseter", ["Temporalis", "Buccinator"], "beginner", "Exaggerated chewing motion, open wide, close firmly", "Jaw Clench"),
    ])

def double_chin_reduction_wo():
    return wo("Double Chin Reduction", "face_jaw", 10, [
        ex("Chin Tuck", 3, 12, 10, "Pull chin back creating double chin", "Bodyweight", "Face", "Deep Neck Flexors", ["Sternocleidomastoid"], "beginner", "Pull chin straight back, hold 5 seconds, like making a double chin on purpose", "Neck Retraction"),
        ex("Tongue Stretch", 3, 10, 10, "Stick tongue out and up", "Bodyweight", "Face", "Genioglossus", ["Suprahyoid", "Digastric"], "beginner", "Stick tongue out trying to touch nose, hold 10 seconds", "Tongue Press"),
        ex("Neck Rotation Stretch", 2, 8, 10, "Look over each shoulder", "Bodyweight", "Face", "Sternocleidomastoid", ["Scalenes", "Trapezius"], "beginner", "Turn head fully to each side, hold 10 seconds", "Neck Side Stretch"),
        ex("Platysma Exercise", 3, 10, 10, "Open mouth wide, tense neck", "Bodyweight", "Face", "Platysma", ["Neck Muscles"], "beginner", "Open mouth, pull corners down, tense neck tendons visible", "Neck Tense"),
        ex("Head Tilt Back Kiss", 3, 10, 10, "Tilt back and pucker", "Bodyweight", "Face", "Mentalis", ["Orbicularis Oris", "Platysma"], "beginner", "Tilt head back, pucker lips toward ceiling, hold 5 seconds", "Chin Lift"),
        ex("Ball Squeeze Under Chin", 3, 12, 10, "Place small ball under chin", "Bodyweight", "Face", "Suprahyoid", ["Digastric", "Mylohyoid"], "beginner", "Tennis ball under chin, press chin down, hold 3 seconds", "Chin Tuck"),
    ])

def under_eye_exercises_wo():
    return wo("Under Eye Exercises", "face_jaw", 8, [
        ex("Lower Lid Squeeze", 3, 10, 10, "Squint lower lids only", "Bodyweight", "Face", "Orbicularis Oculi", ["Lower Eye Muscles"], "beginner", "Squint lower lids up while keeping upper lids open, hold 5s", "Eye Squeeze"),
        ex("Eye Press", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Face", "Orbicularis Oculi", ["Temple Muscles"], "beginner", "Gently press fingertips around orbital bone, light pressure", "Eye Massage"),
        ex("Wide Eye Open", 3, 8, 10, "Open eyes very wide, hold", "Bodyweight", "Face", "Levator Palpebrae", ["Frontalis"], "beginner", "Open eyes as wide as possible without raising brows, hold 5s", "Brow Raise"),
        ex("Rapid Blink", 3, 20, 10, "Fast blinking", "Bodyweight", "Face", "Orbicularis Oculi", ["Levator Palpebrae"], "beginner", "Blink rapidly 20 times, then close eyes and relax", "Gentle Blink"),
        ex("Eye Circle", 2, 5, 10, "Full circles each direction", "Bodyweight", "Face", "Eye Muscles", ["Orbicularis Oculi"], "beginner", "Slow full circles looking up-right-down-left, reverse", "Eye Side-to-Side"),
    ])

def forehead_smoothing_wo():
    return wo("Forehead Smoothing", "face_jaw", 8, [
        ex("Forehead Press", 3, 10, 10, "Resist brow raise with fingers", "Bodyweight", "Face", "Frontalis", ["Procerus"], "beginner", "Place fingers across forehead, try to raise brows against resistance", "Brow Raise"),
        ex("Brow Squeeze", 3, 10, 10, "Frown and release", "Bodyweight", "Face", "Corrugator", ["Procerus", "Frontalis"], "beginner", "Squeeze brows together, hold 5 seconds, release and smooth", "Forehead Massage"),
        ex("Scalp Massage", 2, 1, 0, "60 seconds circular massage", "Bodyweight", "Face", "Scalp Muscles", ["Frontalis", "Temporalis"], "beginner", "Fingertips on scalp, circular motions, release tension", "Temple Massage"),
        ex("Surprise Face", 3, 10, 10, "Open eyes and brows wide", "Bodyweight", "Face", "Frontalis", ["Levator Palpebrae"], "beginner", "Raise brows as high as possible, open eyes wide, hold 5s", "Brow Raise"),
        ex("Forehead Tap", 2, 1, 0, "30 seconds light tapping", "Bodyweight", "Face", "Frontalis", ["Procerus"], "beginner", "Tap fingertips across forehead rapidly, stimulate blood flow", "Forehead Massage"),
    ])

def cheek_lifting_wo():
    return wo("Cheek Lifting", "face_jaw", 8, [
        ex("Cheek Lift Smile", 3, 10, 10, "Smile and push cheeks up", "Bodyweight", "Face", "Zygomaticus Major", ["Levator Labii", "Buccinator"], "beginner", "Big smile, use fingers to push cheeks up, hold 10 seconds", "Wide Smile"),
        ex("O-Shape Cheek Sculptor", 3, 10, 10, "Form O with mouth", "Bodyweight", "Face", "Orbicularis Oris", ["Buccinator", "Zygomaticus"], "beginner", "Make O shape, smile with upper lip over teeth, hold", "Fish Face"),
        ex("Cheek Puff Transfer", 3, 10, 10, "Move air cheek to cheek", "Bodyweight", "Face", "Buccinator", ["Orbicularis Oris"], "beginner", "Puff one cheek, transfer air to other, back and forth", "Cheek Puff"),
        ex("Apple Cheek Exercise", 3, 10, 10, "Smile and hold", "Bodyweight", "Face", "Zygomaticus Minor", ["Levator Labii"], "beginner", "Smile to create apple shape in cheeks, hold 10 seconds", "Smile and Hold"),
        ex("Cheek Massage", 2, 1, 0, "60 seconds circular massage", "Bodyweight", "Face", "Buccinator", ["Masseter", "Zygomaticus"], "beginner", "Circular massage on cheeks with fingertips, upward motion", "Face Tap"),
    ])

def neck_firming_wo():
    return wo("Neck Firming", "face_jaw", 10, [
        ex("Neck Curl", 3, 12, 10, "Lying face up", "Bodyweight", "Face", "Platysma", ["Sternocleidomastoid"], "beginner", "Lie on back, tuck chin, lift head 1 inch, hold 5 seconds", "Chin Tuck"),
        ex("Platysma Stretch", 3, 10, 10, "Open mouth, tense neck", "Bodyweight", "Face", "Platysma", ["Neck Muscles"], "beginner", "Open mouth, pull lower lip down, tense neck bands", "Neck Tense"),
        ex("Head Turn Against Resistance", 2, 8, 10, "Each side", "Bodyweight", "Face", "Sternocleidomastoid", ["Scalenes"], "beginner", "Hand on side of head, turn against resistance, hold 5s", "Neck Turn"),
        ex("Neck Side Tilt", 2, 8, 10, "Each side with resistance", "Bodyweight", "Face", "Scalenes", ["Trapezius"], "beginner", "Hand on side of head, tilt against resistance, hold 5s", "Neck Side Stretch"),
        ex("Neck Extension Resistance", 2, 8, 10, "Hand on forehead", "Bodyweight", "Face", "Deep Neck Flexors", ["Sternocleidomastoid"], "beginner", "Push forehead into palm, resist movement, hold 5 seconds", "Chin Tuck"),
        ex("Tongue Roof Press", 3, 10, 10, "Press tongue to palate", "Bodyweight", "Face", "Suprahyoid", ["Mylohyoid"], "beginner", "Press tongue firmly to roof of mouth, hold 10 seconds", "Tongue Stretch"),
    ])

def tmj_relief_wo():
    return wo("TMJ Relief Exercises", "face_jaw", 10, [
        ex("Resisted Mouth Opening", 3, 8, 10, "Open against thumb resistance", "Bodyweight", "Face", "Pterygoid", ["Masseter", "Temporalis"], "beginner", "Place thumb under chin, open mouth against resistance slowly", "Gentle Jaw Open"),
        ex("Jaw Relaxation", 2, 8, 10, "Rest tongue on palate, separate teeth", "Bodyweight", "Face", "Masseter", ["Temporalis", "Pterygoid"], "beginner", "Tongue on roof, teeth apart, relax jaw completely", "Jaw Massage"),
        ex("Goldfish Exercise", 3, 8, 10, "Partial opening with finger support", "Bodyweight", "Face", "Pterygoid", ["Masseter"], "beginner", "One finger on TMJ, one on chin, open halfway, close gently", "Resisted Opening"),
        ex("Chin Tuck", 3, 10, 10, "Pull chin back", "Bodyweight", "Face", "Deep Neck Flexors", ["Sternocleidomastoid"], "beginner", "Pull chin straight back creating double chin, hold 5 seconds", "Neck Retraction"),
        ex("TMJ Massage", 2, 1, 0, "60 seconds circular massage on jaw joint", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Circular massage on TMJ joint area, gentle pressure, relax", "Jaw Release"),
        ex("Side-to-Side Jaw Slide", 2, 8, 10, "Controlled lateral movement", "Bodyweight", "Face", "Pterygoid", ["Masseter"], "beginner", "Slide lower jaw slowly to each side, gentle controlled movement", "Jaw Circle"),
    ])

def facial_symmetry_wo():
    return wo("Facial Symmetry", "face_jaw", 10, [
        ex("Single-Side Smile", 3, 8, 10, "Each side independently", "Bodyweight", "Face", "Zygomaticus Major", ["Buccinator", "Risorius"], "beginner", "Smile on one side only, hold 5 seconds, switch", "Full Smile"),
        ex("Single-Side Cheek Puff", 3, 8, 10, "Each side independently", "Bodyweight", "Face", "Buccinator", ["Orbicularis Oris"], "beginner", "Puff only one cheek, hold 5 seconds, switch", "Full Cheek Puff"),
        ex("Unilateral Eye Squeeze", 3, 8, 10, "Each side", "Bodyweight", "Face", "Orbicularis Oculi", ["Zygomaticus"], "beginner", "Wink firmly with each eye independently, hold 5 seconds", "Eye Squeeze"),
        ex("Asymmetric Brow Raise", 3, 8, 10, "One brow at a time", "Bodyweight", "Face", "Frontalis", ["Corrugator"], "beginner", "Raise one eyebrow while keeping other down, hold 5s", "Both Brow Raise"),
        ex("Unilateral Jaw Clench", 3, 8, 10, "Clench one side at a time", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Clench on one side, hold 5 seconds, switch", "Full Jaw Clench"),
        ex("Mirror Work Balance", 2, 1, 0, "2 minutes in front of mirror", "Bodyweight", "Face", "Full Face", [], "beginner", "Practice making symmetrical expressions in mirror, correct imbalances", "Face Awareness"),
    ])

def mewing_posture_wo():
    return wo("Mewing & Posture", "face_jaw", 10, [
        ex("Tongue Posture Hold", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Face", "Genioglossus", ["Mylohyoid", "Suprahyoid"], "beginner", "Entire tongue flat on roof of mouth, not just tip, breathe through nose", "Tongue Press"),
        ex("Chin Tuck", 3, 12, 10, "Pull chin back, align ears over shoulders", "Bodyweight", "Face", "Deep Neck Flexors", ["Sternocleidomastoid"], "beginner", "Retract chin, ears align over shoulders, hold 5 seconds", "Neck Retraction"),
        ex("Jaw Muscle Activation", 3, 10, 10, "Light clench with mewing position", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Maintain tongue on palate, gently engage jaw muscles, hold 5s", "Jaw Clench"),
        ex("Neck Posture Reset", 2, 8, 10, "Align head over spine", "Bodyweight", "Face", "Scalenes", ["Sternocleidomastoid", "Trapezius"], "beginner", "Pull head back over spine, tuck chin slightly, hold 10s", "Chin Tuck"),
        ex("Nose Breathing Practice", 3, 1, 0, "60 seconds focused nasal breathing", "Bodyweight", "Face", "Nasal Muscles", ["Diaphragm"], "beginner", "Close mouth, breathe only through nose, tongue on palate", "Belly Breathing"),
        ex("Swallow Exercise", 2, 10, 10, "Correct swallowing pattern", "Bodyweight", "Face", "Suprahyoid", ["Genioglossus", "Mylohyoid"], "beginner", "Swallow with tongue pressing up, not pushing teeth forward", "Tongue Press"),
    ])

def facial_gua_sha_wo():
    return wo("Facial Gua Sha Flow", "face_jaw", 10, [
        ex("Neck Drainage", 2, 8, 0, "Downward strokes on neck", "Bodyweight", "Face", "Platysma", ["Lymph Nodes"], "beginner", "Gentle downward strokes on neck to promote lymph drainage", "Neck Massage"),
        ex("Jawline Sculpt", 2, 8, 0, "Stroke along jawline", "Bodyweight", "Face", "Masseter", ["Platysma"], "beginner", "Firm upward strokes from chin to ear along jawline", "Jaw Massage"),
        ex("Cheek Lift Stroke", 2, 8, 0, "Upward strokes on cheeks", "Bodyweight", "Face", "Zygomaticus", ["Buccinator"], "beginner", "Upward and outward strokes from nose to temples", "Cheek Massage"),
        ex("Under-Eye Sweep", 2, 8, 0, "Gentle strokes under eyes", "Bodyweight", "Face", "Orbicularis Oculi", ["Under-Eye Area"], "beginner", "Very gentle outward strokes under eyes, feather light", "Eye Massage"),
        ex("Forehead Sweep", 2, 8, 0, "Outward strokes on forehead", "Bodyweight", "Face", "Frontalis", ["Temporalis"], "beginner", "Stroke outward from center of forehead to temples", "Forehead Massage"),
        ex("Temple Release", 2, 1, 0, "30 seconds circular massage", "Bodyweight", "Face", "Temporalis", ["Temple Muscles"], "beginner", "Small circles at temples with gentle pressure, release tension", "Temple Tap"),
    ])

def complete_face_workout_wo():
    return wo("Complete Face Workout", "face_jaw", 15, [
        ex("Forehead Lift", 3, 10, 10, "Resist brow raise", "Bodyweight", "Face", "Frontalis", ["Procerus"], "beginner", "Fingers on forehead, raise brows against resistance", "Brow Raise"),
        ex("Eye Squeeze", 3, 10, 10, "Close eyes tightly", "Bodyweight", "Face", "Orbicularis Oculi", ["Eye Muscles"], "beginner", "Squeeze eyes shut tight, hold 5 seconds, release", "Gentle Blink"),
        ex("Cheek Sculptor", 3, 10, 10, "Smile and resist", "Bodyweight", "Face", "Zygomaticus Major", ["Buccinator"], "beginner", "Wide smile, push cheeks up with fingers, hold 10 seconds", "Smile Hold"),
        ex("Jawline Definer", 3, 10, 10, "Chin lift and clench", "Bodyweight", "Face", "Masseter", ["Platysma", "Mentalis"], "beginner", "Tilt head back, push jaw forward, clench, hold 5 seconds", "Chin Lift"),
        ex("Neck Firmer", 3, 10, 10, "Head lift from lying", "Bodyweight", "Face", "Platysma", ["Sternocleidomastoid"], "beginner", "Lie on back, lift head 1 inch, tuck chin, hold 5 seconds", "Chin Tuck"),
        ex("Lip Plumper", 3, 10, 10, "Pucker and hold", "Bodyweight", "Face", "Orbicularis Oris", ["Mentalis", "Buccinator"], "beginner", "Pucker lips outward, hold 5 seconds, release and smile", "Fish Face"),
    ])

# Cat 31 generation
cat31_programs = [
    ("Face Yoga Basics", "Face & Jaw Exercises", [1, 2, 4], [7], "Foundation facial exercises for toning and anti-aging", "High", lambda w,t: [face_yoga_basics_wo()]*3),
    ("Jawline Definition", "Face & Jaw Exercises", [1, 2, 4, 8], [7], "Targeted exercises to sharpen and define your jawline", "High", lambda w,t: [jawline_definition_wo()]*3),
    ("Double Chin Reduction", "Face & Jaw Exercises", [1, 2, 4, 8], [7], "Under-chin targeting exercises for a defined profile", "High", lambda w,t: [double_chin_reduction_wo()]*3),
    ("Under Eye Exercises", "Face & Jaw Exercises", [1, 2, 4], [7], "Reduce puffiness and strengthen muscles around the eyes", "High", lambda w,t: [under_eye_exercises_wo()]*3),
    ("Forehead Smoothing", "Face & Jaw Exercises", [1, 2, 4], [7], "Upper face toning to reduce forehead lines", "High", lambda w,t: [forehead_smoothing_wo()]*3),
    ("Cheek Lifting", "Face & Jaw Exercises", [1, 2, 4], [7], "Lift and tone cheeks for a more youthful appearance", "High", lambda w,t: [cheek_lifting_wo()]*3),
    ("Neck Firming", "Face & Jaw Exercises", [1, 2, 4], [7], "Neck and chin exercises for a firmer neckline", "High", lambda w,t: [neck_firming_wo()]*3),
    ("TMJ Relief Exercises", "Face & Jaw Exercises", [1, 2, 4], [7], "Jaw tension and TMJ pain relief through targeted exercises", "High", lambda w,t: [tmj_relief_wo()]*3),
    ("Facial Symmetry", "Face & Jaw Exercises", [2, 4, 8], [7], "Balance facial muscles for improved symmetry", "High", lambda w,t: [facial_symmetry_wo()]*3),
    ("Mewing & Posture", "Face & Jaw Exercises", [2, 4, 8], [7], "Tongue posture training and facial development exercises", "High", lambda w,t: [mewing_posture_wo()]*3),
    ("Facial Gua Sha Flow", "Face & Jaw Exercises", [1, 2, 4], [7], "Gua sha-inspired facial massage flow for sculpting and drainage", "High", lambda w,t: [facial_gua_sha_wo()]*3),
    ("Complete Face Workout", "Face & Jaw Exercises", [2, 4, 8], [7], "Head-to-chin comprehensive facial fitness routine", "High", lambda w,t: [complete_face_workout_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat31_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Learn: master each exercise with proper form"
            elif p <= 0.66: focus = f"Week {w} - Build: increase hold times and repetitions"
            else: focus = f"Week {w} - Refine: add intensity, see visible changes"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 31 COMPLETE ===\n")

helper.close()
print("\n=== ALL CATS 29-31 COMPLETE ===")
