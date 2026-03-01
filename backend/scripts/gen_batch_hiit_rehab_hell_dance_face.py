#!/usr/bin/env python3
"""Generate programs for Categories 27-31: HIIT, Rehab, Hell Mode, Dance, Face & Jaw."""
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
# CAT 27 - INTERVAL / HIIT
# ========================================================================

def tabata_protocol_wo():
    return wo("Tabata Protocol", "hiit", 25, [
        ex("Burpees", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "advanced", "Explosive jump up, chest to floor, max reps in 20s", "Squat Thrust"),
        ex("Mountain Climbers", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Core", "Hip Flexors", ["Core", "Shoulders", "Quadriceps"], "intermediate", "Drive knees to chest rapidly, maintain plank", "High Knees"),
        ex("Jump Squats", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode up, soft landing", "Air Squat"),
        ex("Push-Up Sprint", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Fast push-ups with good form, max reps", "Knee Push-Up"),
        ex("High Knees", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees up fast, pump arms, stay on balls of feet", "March in Place"),
        ex("Plank Jacks", 8, 1, 10, "20 seconds max effort, 10 seconds rest", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Abductors", "Shoulders"], "intermediate", "Jump feet wide and narrow in plank position", "Plank Hold"),
    ])

def emom_training_wo():
    return wo("EMOM Training", "hiit", 30, [
        ex("Kettlebell Swing", 1, 15, 0, "Every minute on the minute", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip snap, arms float, rest remainder of minute", "Dumbbell Swing"),
        ex("Push-Up", 1, 12, 0, "EMOM - rest remainder of minute", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, complete reps then rest", "Knee Push-Up"),
        ex("Goblet Squat", 1, 12, 0, "EMOM", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Full depth, elbows between knees at bottom", "Air Squat"),
        ex("Pull-Up or Ring Row", 1, 8, 0, "EMOM", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full range, chin over bar, rest remainder", "Band-Assisted Pull-Up"),
        ex("Box Jump", 1, 8, 0, "EMOM", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive jump, soft landing, step down", "Squat Jump"),
        ex("Plank Hold", 1, 1, 0, "45 seconds on, 15 seconds rest", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Tight core, neutral spine, breathe", "Forearm Plank"),
    ])

def amrap_wo():
    return wo("AMRAP Workouts", "hiit", 25, [
        ex("Air Squat", 1, 15, 0, "Max rounds in time cap", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth, chest up, drive through heels", "Half Squat"),
        ex("Push-Up", 1, 10, 0, "Part of AMRAP circuit", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, chest to floor", "Knee Push-Up"),
        ex("Sit-Up", 1, 15, 0, "Part of AMRAP circuit", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Touch toes at top, shoulder blades on floor at bottom", "Crunch"),
        ex("Burpee", 1, 5, 0, "Part of AMRAP circuit", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explosive jump up", "Squat Thrust"),
        ex("Jumping Lunge", 1, 10, 0, "Part of AMRAP circuit", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Alternate legs in air, soft landing", "Walking Lunge"),
        ex("V-Up", 1, 10, 0, "Part of AMRAP circuit", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Hands and feet meet at top, controlled down", "Tuck-Up"),
    ])

def cardio_hiit_fusion_wo():
    return wo("Cardio HIIT Fusion", "hiit", 30, [
        ex("Sprint in Place", 3, 1, 30, "30 seconds max effort", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hip Flexors"], "intermediate", "Pump arms, drive knees, max speed", "High Knees"),
        ex("Burpee", 3, 10, 30, "Explosive pace", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump up, clap overhead", "Squat Thrust"),
        ex("Jump Squat", 3, 15, 30, "Max height each rep", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode up, soft land", "Air Squat"),
        ex("Mountain Climber", 3, 30, 30, "15 each side, fast pace", "Bodyweight", "Core", "Hip Flexors", ["Core", "Shoulders"], "intermediate", "Drive knees to chest alternating rapidly", "Plank Knee Tuck"),
        ex("Lateral Shuffle", 3, 20, 30, "10 each direction", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Low athletic stance, quick feet side to side", "Side Step"),
        ex("Tuck Jump", 3, 8, 30, "Explosive jumps", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Calves"], "advanced", "Jump and pull knees to chest in air", "Squat Jump"),
    ])

def strength_hiit_wo():
    return wo("Strength HIIT", "hiit", 35, [
        ex("Dumbbell Thruster", 4, 10, 30, "Moderate weight, fast pace", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Core", "Triceps"], "intermediate", "Front squat to overhead press in one motion", "Air Squat to Overhead Press"),
        ex("Renegade Row", 3, 10, 30, "5 each arm", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row one arm, alternate", "Bent-Over Row"),
        ex("Dumbbell Swing", 3, 15, 30, "Hip-powered swing", "Dumbbells", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap drives the weight, arms are hooks", "Kettlebell Swing"),
        ex("Devil Press", 3, 8, 45, "Burpee + double dumbbell snatch", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "advanced", "Burpee with DBs, stand and snatch overhead", "Dumbbell Burpee"),
        ex("Dumbbell Lunge", 3, 12, 30, "6 each leg", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step forward, knee to 90, drive back up", "Bodyweight Lunge"),
        ex("Dumbbell Clean and Press", 3, 10, 30, "5 each arm", "Dumbbells", "Full Body", "Deltoids", ["Quadriceps", "Core", "Triceps"], "intermediate", "Clean to shoulder, press overhead, lower", "Dumbbell Push Press"),
    ])

def sprint_intervals_wo():
    return wo("Sprint Intervals", "hiit", 25, [
        ex("Sprint", 8, 1, 60, "30 seconds all-out sprint", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "intermediate", "Max effort 30 seconds, walk/jog recovery 60 seconds", "Fast Run"),
        ex("Hill Sprint", 4, 1, 90, "20 seconds uphill sprint", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Find incline, sprint up, walk down for recovery", "Flat Sprint"),
        ex("Shuttle Sprint", 4, 1, 60, "25 meters and back", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Sprint to cone, touch, sprint back", "Sprint in Place"),
        ex("Stride-Out", 4, 1, 45, "Build to 90% over 50 meters", "Bodyweight", "Legs", "Hamstrings", ["Quadriceps", "Calves"], "beginner", "Gradually accelerate, hold top speed briefly, decelerate", "Light Jog"),
        ex("Recovery Jog", 4, 1, 0, "Easy 90 seconds between sets", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Very easy pace, catch breath, prepare for next sprint", "Walk"),
    ])

def bodyweight_hiit_wo():
    return wo("Bodyweight HIIT", "hiit", 25, [
        ex("Burpee", 4, 10, 20, "Fast pace", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explode up", "Squat Thrust"),
        ex("Jump Squat", 4, 15, 20, "Max height", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explode, soft land", "Air Squat"),
        ex("Push-Up to T-Rotation", 3, 10, 20, "5 each side", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up, rotate, reach to sky, alternate", "Push-Up"),
        ex("Skater Jump", 3, 16, 20, "8 each side", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Hip Abductors"], "intermediate", "Leap side to side, land on one foot", "Lateral Lunge"),
        ex("Plank Up-Down", 3, 10, 20, "Forearm to hand plank", "Bodyweight", "Core", "Triceps", ["Core", "Shoulders"], "intermediate", "Lead with alternating arms, keep hips stable", "Plank Hold"),
        ex("High Knees", 3, 30, 20, "Max speed", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees up fast, pump arms", "March in Place"),
    ])

def kettlebell_hiit_wo():
    return wo("Kettlebell HIIT", "hiit", 30, [
        ex("Kettlebell Swing", 4, 20, 30, "Two-hand swing", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, float the bell, arm tension at top", "Dumbbell Swing"),
        ex("Kettlebell Goblet Squat", 3, 12, 30, "Moderate weight", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Hold at chest, deep squat, elbows inside knees", "Air Squat"),
        ex("Kettlebell Clean and Press", 3, 8, 30, "Each arm", "Kettlebell", "Full Body", "Deltoids", ["Core", "Biceps", "Triceps"], "intermediate", "Clean to rack, press overhead, control down", "Dumbbell Clean and Press"),
        ex("Kettlebell Snatch", 3, 8, 30, "Each arm", "Kettlebell", "Full Body", "Shoulders", ["Glutes", "Core", "Forearms"], "advanced", "One motion floor to overhead, punch through at top", "Kettlebell Swing"),
        ex("Kettlebell Turkish Get-Up", 2, 3, 45, "Each side", "Kettlebell", "Full Body", "Core", ["Shoulders", "Glutes", "Quadriceps"], "advanced", "Floor to standing with KB locked out overhead", "Half Get-Up"),
        ex("Kettlebell Row", 3, 10, 30, "Each arm", "Kettlebell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Hinge position, row to hip, squeeze back", "Dumbbell Row"),
    ])

def boxing_hiit_wo():
    return wo("Boxing HIIT", "hiit", 30, [
        ex("Jab-Cross Combination", 4, 1, 15, "30 seconds max output", "Bodyweight", "Arms", "Deltoids", ["Triceps", "Core", "Chest"], "beginner", "Quick jab, powerful cross, rotate hips, return guard", "Shadow Boxing"),
        ex("Hook-Uppercut Combo", 3, 1, 15, "30 seconds each side lead", "Bodyweight", "Arms", "Deltoids", ["Obliques", "Biceps", "Core"], "intermediate", "Short hook, drive uppercut from legs, rotate hips", "Shadow Boxing"),
        ex("Slip and Counter", 3, 10, 20, "Defensive movement + punch", "Bodyweight", "Core", "Obliques", ["Quadriceps", "Shoulders"], "intermediate", "Slip head side to side, fire counter punch", "Bob and Weave"),
        ex("Speed Bag Simulation", 3, 1, 15, "30 seconds rapid circular punches", "Bodyweight", "Shoulders", "Deltoids", ["Biceps", "Forearms"], "beginner", "Small rapid circles, elbows up, light and fast", "Arm Circles"),
        ex("Sprawl", 3, 8, 20, "Explosive sprawl and return", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Chest", "Hip Flexors"], "intermediate", "Quick drop to sprawl, hips to floor, bounce back up", "Burpee"),
        ex("Round Kick Simulation", 3, 8, 20, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Obliques", "Quadriceps", "Glutes"], "intermediate", "Pivot on plant foot, drive knee up, extend kick", "Knee Drive"),
    ])

def battle_rope_hiit_wo():
    return wo("Battle Rope HIIT", "hiit", 25, [
        ex("Alternating Waves", 4, 1, 30, "30 seconds max effort", "Battle Ropes", "Arms", "Deltoids", ["Core", "Forearms", "Biceps"], "intermediate", "Alternate arms creating wave pattern, athletic stance", "Jumping Jacks"),
        ex("Double Slam", 4, 1, 30, "30 seconds", "Battle Ropes", "Full Body", "Deltoids", ["Core", "Latissimus Dorsi", "Quadriceps"], "intermediate", "Raise both ropes overhead, slam down with power", "Medicine Ball Slam"),
        ex("Side-to-Side Wave", 3, 1, 30, "30 seconds", "Battle Ropes", "Core", "Obliques", ["Shoulders", "Core"], "intermediate", "Swing both ropes side to side together", "Russian Twist"),
        ex("Rope Slam with Squat", 3, 1, 30, "30 seconds", "Battle Ropes", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Squat as you slam, stand as you raise ropes", "Squat to Overhead Press"),
        ex("Alternating Wave with Lunge", 3, 1, 30, "30 seconds", "Battle Ropes", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "advanced", "Alternate lunges while maintaining arm waves", "Walking Lunge"),
        ex("Grappler Throw", 3, 1, 30, "30 seconds", "Battle Ropes", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Flip ropes side to side like throwing motion", "Wood Chop"),
    ])

def staircase_hiit_wo():
    return wo("Staircase HIIT", "hiit", 25, [
        ex("Stair Sprint", 6, 1, 45, "Sprint up 2-3 flights", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Drive knees up, pump arms, every step", "Sprint in Place"),
        ex("Double-Step Stair Climb", 4, 1, 45, "Skip a step each stride", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Hamstrings"], "intermediate", "Take two stairs at a time, push through heels", "Stair Sprint"),
        ex("Stair Lunge", 3, 10, 30, "5 each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Deep lunge on stairs, controlled movement", "Walking Lunge"),
        ex("Stair Calf Raise", 3, 15, 20, "Edge of step", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Heels hang off step, full range raise", "Standing Calf Raise"),
        ex("Stair Push-Up", 3, 10, 20, "Hands on stair", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Incline push-up on stair, full range", "Knee Push-Up"),
    ])

def rowing_hiit_wo():
    return wo("Rowing HIIT", "hiit", 25, [
        ex("500m Row Sprint", 4, 1, 120, "All-out 500m", "Rowing Machine", "Full Body", "Quadriceps", ["Latissimus Dorsi", "Biceps", "Core"], "intermediate", "Legs-back-arms pull sequence, max power", "250m Row"),
        ex("1-Min Power Row", 4, 1, 60, "Max calories in 60 seconds", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core", "Biceps"], "intermediate", "High stroke rate, full extension each pull", "30-Second Row"),
        ex("Pyramid Row", 1, 1, 0, "100m, 200m, 300m, 200m, 100m with equal rest", "Rowing Machine", "Full Body", "Quadriceps", ["Latissimus Dorsi", "Core"], "intermediate", "Increase distance, rest same time as work", "500m Row"),
        ex("Row + Burpee Combo", 3, 1, 30, "250m row then 5 burpees", "Rowing Machine", "Full Body", "Quadriceps", ["Chest", "Core", "Latissimus Dorsi"], "intermediate", "Row fast, jump off, do burpees, repeat", "Row Only"),
        ex("Easy Recovery Row", 2, 1, 0, "2 min easy pace between sets", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Core"], "beginner", "Light pressure, focus on form and breathing", "Walking"),
    ])

def cycle_hiit_wo():
    return wo("Cycle HIIT", "hiit", 30, [
        ex("Sprint Interval", 6, 1, 60, "30 seconds max effort", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "intermediate", "Max RPM, high resistance, seated or standing", "Sprint in Place"),
        ex("Hill Climb", 4, 1, 45, "45 seconds heavy resistance", "Stationary Bike", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "High resistance, low RPM, stand if needed", "Heavy Squat"),
        ex("Tabata Intervals", 8, 1, 10, "20 on / 10 off on bike", "Stationary Bike", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "advanced", "Max effort 20 seconds, coast 10 seconds", "Bodyweight Tabata"),
        ex("Single-Leg Drill", 2, 1, 0, "30 seconds each leg", "Stationary Bike", "Legs", "Quadriceps", ["Hip Flexors", "Hamstrings"], "intermediate", "One foot on pedal, smooth full circle", "Single-Leg Squat"),
        ex("Easy Spin Recovery", 2, 1, 0, "3 minutes easy pace", "Stationary Bike", "Legs", "Quadriceps", ["Calves"], "beginner", "Low resistance, easy spin, recover breathing", "Walking"),
    ])

def jump_rope_hiit_wo():
    return wo("Jump Rope HIIT", "hiit", 25, [
        ex("Basic Jump", 3, 1, 20, "60 seconds steady pace", "Jump Rope", "Full Body", "Calves", ["Quadriceps", "Forearms", "Core"], "beginner", "Light bounce, wrists turn rope, stay on balls of feet", "Jumping Jacks"),
        ex("Double Under", 3, 1, 30, "30 seconds max effort", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core", "Forearms"], "advanced", "Jump higher, spin rope twice per jump, wrist flick", "High Jump"),
        ex("High Knee Jump Rope", 3, 1, 20, "30 seconds", "Jump Rope", "Legs", "Hip Flexors", ["Calves", "Core"], "intermediate", "Drive knees up while jumping rope", "High Knees"),
        ex("Single-Leg Hop", 2, 1, 20, "20 seconds each leg", "Jump Rope", "Legs", "Calves", ["Core", "Ankle Stabilizers"], "intermediate", "Hop on one foot while turning rope", "Single-Leg Balance Hop"),
        ex("Cross-Over Jump", 2, 1, 20, "30 seconds", "Jump Rope", "Full Body", "Forearms", ["Shoulders", "Calves", "Core"], "advanced", "Cross arms in front on downswing, uncross on upswing", "Basic Jump"),
        ex("Sprint Jump", 3, 1, 20, "20 seconds max speed", "Jump Rope", "Full Body", "Calves", ["Quadriceps", "Forearms"], "intermediate", "Maximum rope speed, small jumps, fast turnover", "Basic Jump Fast"),
    ])

def medicine_ball_hiit_wo():
    return wo("Medicine Ball HIIT", "hiit", 25, [
        ex("Medicine Ball Slam", 4, 12, 20, "Max power each slam", "Medicine Ball", "Full Body", "Core", ["Latissimus Dorsi", "Shoulders", "Quadriceps"], "intermediate", "Overhead to floor with force, squat to pick up", "Burpee"),
        ex("Wall Ball", 4, 12, 20, "Hit target on wall", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Squat deep, drive ball to target on wall, catch and repeat", "Thruster"),
        ex("Rotational Throw", 3, 8, 20, "Each side", "Medicine Ball", "Core", "Obliques", ["Hip Rotators", "Shoulders"], "intermediate", "Rotate and throw ball at wall, catch and repeat", "Wood Chop"),
        ex("Chest Pass", 3, 12, 20, "Explosive push", "Medicine Ball", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Two-hand push from chest at wall, catch", "Push-Up"),
        ex("Overhead Throw", 3, 10, 20, "Max height", "Medicine Ball", "Full Body", "Shoulders", ["Core", "Triceps"], "intermediate", "Squat, drive through legs, throw ball up", "Medicine Ball Slam"),
        ex("V-Up with Med Ball", 3, 10, 20, "Hold ball in hands", "Medicine Ball", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Ball goes from hands to feet and back, V-shape", "V-Up"),
    ])

def sandbag_hiit_wo():
    return wo("Sandbag HIIT", "hiit", 30, [
        ex("Sandbag Clean", 4, 10, 30, "Explosive pull to shoulder", "Sandbag", "Full Body", "Quadriceps", ["Glutes", "Biceps", "Core"], "intermediate", "Bear hug or handle grip, deadlift to chest in one motion", "Dumbbell Clean"),
        ex("Sandbag Shouldering", 3, 8, 30, "Alternate shoulders", "Sandbag", "Full Body", "Core", ["Quadriceps", "Biceps", "Shoulders"], "intermediate", "Floor to one shoulder, lower, repeat other side", "Sandbag Clean"),
        ex("Sandbag Front Squat", 3, 12, 30, "Bear hug position", "Sandbag", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Hug bag to chest, squat deep, drive up", "Goblet Squat"),
        ex("Sandbag Drag", 3, 1, 30, "30 seconds per set", "Sandbag", "Full Body", "Glutes", ["Hamstrings", "Core", "Forearms"], "intermediate", "Low stance, drag bag backward, athletic position", "Farmer's Walk"),
        ex("Sandbag Overhead Press", 3, 10, 30, "Bear hug to overhead", "Sandbag", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Clean to chest, press overhead with effort", "Dumbbell Overhead Press"),
        ex("Sandbag Burpee", 3, 8, 30, "With sandbag clean", "Sandbag", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "advanced", "Burpee over bag, clean bag to chest, drop and repeat", "Burpee"),
    ])

def trx_hiit_wo():
    return wo("TRX HIIT", "hiit", 25, [
        ex("TRX Jump Squat", 4, 12, 20, "Use straps for assist", "TRX", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Hold straps, deep squat, explosive jump, soft land", "Jump Squat"),
        ex("TRX Row", 4, 12, 20, "Fast tempo", "TRX", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Lean back, pull chest to hands, squeeze back", "Inverted Row"),
        ex("TRX Push-Up", 3, 10, 20, "Feet in straps", "TRX", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Feet suspended, push-up with core engaged", "Push-Up"),
        ex("TRX Mountain Climber", 3, 20, 20, "Feet in straps", "TRX", "Core", "Hip Flexors", ["Core", "Shoulders"], "intermediate", "Plank with feet in straps, drive knees to chest", "Mountain Climber"),
        ex("TRX Pistol Squat", 3, 8, 20, "Each leg", "TRX", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Hold straps, single-leg squat, use straps for balance", "Assisted Single-Leg Squat"),
        ex("TRX Burpee", 3, 8, 20, "Feet in straps", "TRX", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Plank with feet in straps, push-up, tuck jump", "Burpee"),
    ])

def dumbbell_hiit_wo():
    return wo("Dumbbell HIIT", "hiit", 30, [
        ex("Dumbbell Thruster", 4, 12, 25, "Moderate weight", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps", "Core"], "intermediate", "Front squat to overhead press, fluid motion", "Air Squat to Press"),
        ex("Dumbbell Snatch", 3, 8, 25, "Each arm", "Dumbbells", "Full Body", "Shoulders", ["Glutes", "Core", "Triceps"], "intermediate", "Floor to overhead in one motion, hip drive", "Dumbbell Swing"),
        ex("Man Maker", 3, 6, 30, "Full complex", "Dumbbells", "Full Body", "Quadriceps", ["Chest", "Back", "Shoulders"], "advanced", "Push-up, row each arm, clean, thruster", "Dumbbell Thruster"),
        ex("Dumbbell Reverse Lunge", 3, 12, 25, "6 each leg", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step back, knee to floor, drive up", "Bodyweight Lunge"),
        ex("Dumbbell Push Press", 3, 10, 25, "Use leg drive", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Core", "Quadriceps"], "intermediate", "Slight dip, drive through legs, press overhead", "Overhead Press"),
        ex("Renegade Row", 3, 10, 25, "5 each arm", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank on DBs, row to hip alternating", "Dumbbell Row"),
    ])

# Cat 27 generation
cat27_programs = [
    ("Tabata Protocol", "Interval/HIIT", [1, 2, 4], [3, 4], "Classic 20s on/10s off high-intensity interval training", "High", lambda w,t: [tabata_protocol_wo()]*3),
    ("EMOM Training", "Interval/HIIT", [1, 2, 4, 8], [3, 4], "Every minute on the minute structured interval training", "High", lambda w,t: [emom_training_wo()]*3),
    ("AMRAP Workouts", "Interval/HIIT", [1, 2, 4], [3, 4], "As many reps as possible timed circuits for maximum output", "High", lambda w,t: [amrap_wo()]*3),
    ("Cardio HIIT Fusion", "Interval/HIIT", [2, 4, 8], [3, 4], "Running and bodyweight intervals for cardiovascular fitness", "High", lambda w,t: [cardio_hiit_fusion_wo()]*3),
    ("Strength HIIT", "Interval/HIIT", [2, 4, 8], [3, 4], "Weighted interval training for strength and conditioning", "High", lambda w,t: [strength_hiit_wo()]*3),
    ("Sprint Intervals", "Interval/HIIT", [2, 4], [2, 3], "All-out sprint intervals for speed and anaerobic power", "High", lambda w,t: [sprint_intervals_wo()]*3),
    ("Bodyweight HIIT", "Interval/HIIT", [1, 2, 4], [3, 4], "No-equipment high-intensity interval training", "High", lambda w,t: [bodyweight_hiit_wo()]*3),
    ("Kettlebell HIIT", "Interval/HIIT", [2, 4, 8], [3, 4], "Kettlebell-based HIIT for power and endurance", "High", lambda w,t: [kettlebell_hiit_wo()]*3),
    ("Boxing HIIT", "Interval/HIIT", [2, 4], [3, 4], "Punch and rest interval training for full body conditioning", "High", lambda w,t: [boxing_hiit_wo()]*3),
    ("Battle Rope HIIT", "Interval/HIIT", [2, 4], [3, 4], "Battle rope intervals for upper body and core endurance", "High", lambda w,t: [battle_rope_hiit_wo()]*3),
    ("Staircase HIIT", "Interval/HIIT", [1, 2, 4], [3, 4], "Staircase sprint intervals for leg power and conditioning", "High", lambda w,t: [staircase_hiit_wo()]*3),
    ("Rowing HIIT", "Interval/HIIT", [2, 4], [3, 4], "Rowing machine intervals for total body HIIT", "High", lambda w,t: [rowing_hiit_wo()]*3),
    ("Cycle HIIT", "Interval/HIIT", [2, 4, 8], [3, 4], "Stationary bike intervals for cardiovascular power", "High", lambda w,t: [cycle_hiit_wo()]*3),
    ("Jump Rope HIIT", "Interval/HIIT", [1, 2, 4], [3, 4], "Jump rope interval training for coordination and cardio", "High", lambda w,t: [jump_rope_hiit_wo()]*3),
    ("Medicine Ball HIIT", "Interval/HIIT", [2, 4], [3, 4], "Medicine ball power intervals for explosive strength", "High", lambda w,t: [medicine_ball_hiit_wo()]*3),
    ("Sandbag HIIT", "Interval/HIIT", [2, 4], [3, 4], "Sandbag-based functional HIIT training", "High", lambda w,t: [sandbag_hiit_wo()]*3),
    ("TRX HIIT", "Interval/HIIT", [2, 4], [3, 4], "TRX suspension trainer interval workouts", "High", lambda w,t: [trx_hiit_wo()]*3),
    ("Dumbbell HIIT", "Interval/HIIT", [2, 4, 8], [3, 4], "Dumbbell-based HIIT for strength and metabolic conditioning", "High", lambda w,t: [dumbbell_hiit_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat27_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn intervals, build work capacity"
            elif p <= 0.66: focus = f"Week {w} - Build: increase intensity and reduce rest"
            else: focus = f"Week {w} - Peak: max intensity, minimal rest, full output"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 27 COMPLETE ===\n")

# ========================================================================
# CAT 28 - REHAB & RECOVERY
# ========================================================================

def lower_back_rehab_wo():
    return wo("Lower Back Rehab", "rehab", 25, [
        ex("Pelvic Tilt", 3, 12, 15, "Flatten back to floor", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor"], "beginner", "Lie on back, press lower back flat, hold 5 seconds", "Seated Pelvic Tilt"),
        ex("Bird Dog", 3, 8, 15, "Each side", "Bodyweight", "Core", "Erector Spinae", ["Glutes", "Core"], "beginner", "Opposite arm and leg extend, keep hips level", "Dead Bug"),
        ex("Cat-Cow", 2, 10, 0, "Gentle spinal movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Pain-free range only, breathe deeply", "Seated Cat-Cow"),
        ex("Glute Bridge", 3, 10, 15, "Activate glutes, protect back", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, squeeze glutes at top, protect spine", "Hip Thrust"),
        ex("Dead Bug", 3, 8, 15, "Each side, slow controlled", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Back flat on floor, extend opposite arm and leg slowly", "Pelvic Tilt"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds, breathe into back", "Bodyweight", "Back", "Latissimus Dorsi", ["Lower Back", "Hips"], "beginner", "Knees wide, sink hips back, stretch lower back", "Supine Knee to Chest"),
    ])

def shoulder_rehab_wo():
    return wo("Shoulder Rehab", "rehab", 25, [
        ex("Pendulum Swing", 2, 20, 10, "Each arm, gentle circles", "Bodyweight", "Shoulders", "Rotator Cuff", ["Deltoids"], "beginner", "Lean forward, let arm hang, small circles", "Arm Hang"),
        ex("External Rotation with Band", 3, 12, 15, "Each arm, light resistance", "Resistance Band", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Elbow at side, rotate forearm out against band", "Towel External Rotation"),
        ex("Internal Rotation with Band", 3, 12, 15, "Each arm", "Resistance Band", "Shoulders", "Subscapularis", ["Pectoralis Major"], "beginner", "Elbow at side, rotate forearm in against band", "Towel Internal Rotation"),
        ex("Scapular Retraction", 3, 12, 15, "Squeeze shoulder blades", "Resistance Band", "Back", "Rhomboids", ["Middle Trapezius"], "beginner", "Pull band apart, squeeze shoulder blades together", "Prone Y Raise"),
        ex("Wall Slide", 3, 10, 15, "Back to wall, slide arms up", "Bodyweight", "Shoulders", "Lower Trapezius", ["Serratus Anterior"], "beginner", "Maintain wall contact with back, elbows, wrists", "Floor Angel"),
        ex("Isometric Shoulder Hold", 2, 1, 15, "Hold 10 seconds each direction", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Push into wall in each direction, no movement", "Light Band Press"),
    ])

def knee_rehab_wo():
    return wo("Knee Rehab", "rehab", 25, [
        ex("Quad Set", 3, 12, 10, "Tighten quad, push knee flat", "Bodyweight", "Legs", "Quadriceps", ["VMO"], "beginner", "Press knee into floor, tighten quad, hold 5 seconds", "Straight Leg Raise"),
        ex("Straight Leg Raise", 3, 12, 15, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Tighten quad, raise leg 12 inches, hold 3 seconds", "Short Arc Quad"),
        ex("Terminal Knee Extension", 3, 12, 15, "With band around knee", "Resistance Band", "Legs", "Quadriceps", ["VMO"], "beginner", "Band behind knee, straighten against resistance", "Quad Set"),
        ex("Wall Sit", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Back flat on wall, 90 degrees, pain-free range only", "Quarter Squat"),
        ex("Step-Up", 2, 10, 15, "Each leg, low step", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Low step, drive through whole foot, control descent", "Bodyweight Squat"),
        ex("Calf Raise", 2, 15, 15, "Both legs, controlled", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Full range, slow and controlled", "Seated Calf Raise"),
    ])

def hip_rehab_wo():
    return wo("Hip Rehab", "rehab", 25, [
        ex("Clamshell", 3, 15, 15, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Rotators"], "beginner", "Side-lying, knees bent, open top knee, keep feet together", "Banded Clamshell"),
        ex("Side-Lying Hip Abduction", 3, 12, 15, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["TFL", "Hip Abductors"], "beginner", "Side-lying, lift top leg straight, control down", "Standing Hip Abduction"),
        ex("Glute Bridge", 3, 10, 15, "Squeeze at top", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive through heels, hold top 3 seconds", "Hip Thrust"),
        ex("Supine Hip Flexion", 2, 10, 10, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Core"], "beginner", "Lie on back, slide heel toward glute, return", "Marching"),
        ex("Standing Hip Circle", 2, 8, 10, "Each direction, each leg", "Bodyweight", "Hips", "Hip Rotators", ["Glutes", "Core"], "beginner", "Small controlled circles, stay balanced", "Seated Hip Circle"),
        ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Psoas"], "beginner", "Half kneeling, gentle lean forward, no pain", "Standing Hip Flexor Stretch"),
    ])

def ankle_rehab_wo():
    return wo("Ankle Rehab", "rehab", 20, [
        ex("Ankle Alphabet", 2, 1, 0, "Full alphabet each foot", "Bodyweight", "Legs", "Ankle Joint", ["Tibialis Anterior", "Peroneals"], "beginner", "Draw A-Z with big toe, full range of motion", "Ankle Circles"),
        ex("Towel Scrunches", 3, 15, 10, "Each foot", "Bodyweight", "Feet", "Foot Intrinsics", ["Toe Flexors"], "beginner", "Scrunch towel toward you with toes", "Marble Pickup"),
        ex("Calf Raise", 3, 12, 15, "Both legs, controlled", "Bodyweight", "Legs", "Calves", ["Soleus", "Ankle Stabilizers"], "beginner", "Full range, 3 seconds up, 3 seconds down", "Seated Calf Raise"),
        ex("Single-Leg Balance", 3, 1, 15, "Hold 30 seconds each foot", "Bodyweight", "Legs", "Ankle Stabilizers", ["Calves", "Core"], "beginner", "Stand on one foot, maintain balance, eyes open then closed", "Tandem Stance"),
        ex("Resistance Band Eversion", 2, 15, 10, "Each foot", "Resistance Band", "Legs", "Peroneals", ["Ankle Stabilizers"], "beginner", "Band around foot, push outward against resistance", "Towel Eversion"),
        ex("Resistance Band Inversion", 2, 15, 10, "Each foot", "Resistance Band", "Legs", "Tibialis Posterior", ["Ankle Stabilizers"], "beginner", "Band around foot, pull inward against resistance", "Towel Inversion"),
    ])

def wrist_elbow_rehab_wo():
    return wo("Wrist & Elbow Rehab", "rehab", 20, [
        ex("Wrist Flexion Stretch", 2, 1, 0, "Hold 30 seconds each wrist", "Bodyweight", "Arms", "Wrist Flexors", ["Forearm Flexors"], "beginner", "Arm straight, pull fingers back gently", "Prayer Stretch"),
        ex("Wrist Extension Stretch", 2, 1, 0, "Hold 30 seconds each wrist", "Bodyweight", "Arms", "Wrist Extensors", ["Forearm Extensors"], "beginner", "Arm straight, push fingers toward floor", "Reverse Prayer Stretch"),
        ex("Wrist Curl", 2, 15, 10, "Very light weight", "Dumbbells", "Arms", "Wrist Flexors", ["Forearm Flexors"], "beginner", "Forearm on knee, curl wrist up slowly", "Squeeze Ball"),
        ex("Reverse Wrist Curl", 2, 15, 10, "Very light weight", "Dumbbells", "Arms", "Wrist Extensors", ["Forearm Extensors"], "beginner", "Palm down, extend wrist up slowly", "Rubber Band Extension"),
        ex("Grip Squeeze", 3, 12, 10, "Stress ball or grip trainer", "Bodyweight", "Arms", "Forearm Flexors", ["Hand Muscles"], "beginner", "Squeeze and hold 3 seconds, release", "Towel Squeeze"),
        ex("Pronation/Supination", 2, 12, 10, "Each arm", "Bodyweight", "Arms", "Forearm Pronators", ["Forearm Supinators"], "beginner", "Elbow at side, rotate forearm palm up then palm down", "Hammer Curl Motion"),
    ])

def post_surgery_general_wo():
    return wo("Post-Surgery General", "rehab", 20, [
        ex("Ankle Pump", 3, 20, 10, "Flex and point foot", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Point toes away, then pull toward shin, promote circulation", "Seated Ankle Circle"),
        ex("Gentle Quad Set", 3, 10, 10, "Tighten quad lightly", "Bodyweight", "Legs", "Quadriceps", [], "beginner", "Press knee into bed gently, hold 5 seconds", "Isometric Leg Hold"),
        ex("Shoulder Shrug", 2, 10, 10, "If cleared by doctor", "Bodyweight", "Shoulders", "Trapezius", ["Levator Scapulae"], "beginner", "Shrug shoulders to ears, hold 3 seconds, release", "Neck Rolls"),
        ex("Deep Breathing", 3, 10, 10, "Incentive spirometry style", "Bodyweight", "Core", "Diaphragm", ["Intercostals"], "beginner", "Slow deep inhale, hold 3 seconds, slow exhale", "Belly Breathing"),
        ex("Gentle Marching", 2, 10, 10, "Seated or lying down", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Alternate lifting knees gently, very controlled", "Ankle Pumps"),
        ex("Seated Arm Raise", 2, 8, 10, "If cleared by doctor", "Bodyweight", "Shoulders", "Deltoids", ["Trapezius"], "beginner", "Raise arms to comfortable height, lower slowly", "Shoulder Shrug"),
    ])

def acl_recovery_wo():
    return wo("ACL Recovery", "rehab", 25, [
        ex("Quad Set", 3, 15, 10, "Tighten quad fully", "Bodyweight", "Legs", "Quadriceps", ["VMO"], "beginner", "Press knee flat, hold 5 seconds, full quad activation", "Short Arc Quad"),
        ex("Straight Leg Raise", 3, 12, 15, "Each leg, controlled", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Lock knee straight, raise 12 inches, hold 3 seconds", "Quad Set"),
        ex("Heel Slide", 3, 12, 10, "Affected leg", "Bodyweight", "Legs", "Hamstrings", ["Quadriceps"], "beginner", "Lie on back, slide heel toward glute, slide back", "Seated Knee Flexion"),
        ex("Terminal Knee Extension", 3, 12, 15, "Band behind knee", "Resistance Band", "Legs", "Quadriceps", ["VMO"], "beginner", "Straighten knee against band resistance, hold 3 seconds", "Short Arc Quad"),
        ex("Standing Balance", 3, 1, 15, "30 seconds affected leg", "Bodyweight", "Legs", "Ankle Stabilizers", ["Quadriceps", "Core"], "beginner", "Stand on affected leg, maintain balance, progress eyes closed", "Tandem Stance"),
        ex("Mini Squat", 2, 10, 15, "Quarter depth only", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Small range squat, do not go past 45 degrees initially", "Wall Sit"),
    ])

def rotator_cuff_rehab_wo():
    return wo("Rotator Cuff Rehab", "rehab", 20, [
        ex("Pendulum", 2, 20, 10, "Each arm, small circles", "Bodyweight", "Shoulders", "Rotator Cuff", [], "beginner", "Lean forward, let arm hang, tiny circles using body sway", "Arm Hang"),
        ex("External Rotation at Side", 3, 12, 15, "Light band, each arm", "Resistance Band", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Elbow pinned to side, rotate forearm outward", "Towel External Rotation"),
        ex("Internal Rotation at Side", 3, 12, 15, "Light band, each arm", "Resistance Band", "Shoulders", "Subscapularis", ["Pectoralis Major"], "beginner", "Elbow at side, rotate forearm toward body", "Towel Internal Rotation"),
        ex("Scapular Squeeze", 3, 12, 10, "Retract shoulder blades", "Bodyweight", "Back", "Rhomboids", ["Middle Trapezius"], "beginner", "Squeeze shoulder blades together, hold 5 seconds", "Band Pull-Apart"),
        ex("Prone Y Raise", 2, 10, 15, "Face down, thumbs up", "Bodyweight", "Shoulders", "Lower Trapezius", ["Supraspinatus"], "beginner", "Lie face down, raise arms in Y shape, hold 2 seconds", "Wall Y Raise"),
        ex("Side-Lying External Rotation", 2, 12, 15, "Each side, very light weight", "Dumbbells", "Shoulders", "Infraspinatus", ["Teres Minor"], "beginner", "Side-lying, elbow on hip, rotate forearm up toward ceiling", "Band External Rotation"),
    ])

def sciatica_relief_wo():
    return wo("Sciatica Relief", "rehab", 20, [
        ex("Knee to Chest Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Gluteus Maximus", ["Lower Back", "Piriformis"], "beginner", "On back, hug one knee to chest, keep other leg flat", "Double Knee to Chest"),
        ex("Piriformis Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Figure-4 position on back, pull standing leg to chest", "Seated Figure-4"),
        ex("Sciatic Nerve Glide", 2, 8, 10, "Each leg, gentle", "Bodyweight", "Legs", "Hamstrings", ["Sciatic Nerve"], "beginner", "Seated, extend one leg, flex foot, bend knee, repeat gently", "Seated Hamstring Stretch"),
        ex("Cat-Cow", 2, 10, 0, "Gentle spinal movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Pain-free range, breathe deeply, gentle movement", "Pelvic Tilt"),
        ex("Press-Up (McKenzie)", 2, 8, 15, "Prone press-up", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Lie face down, press up leaving hips on floor, sag into extension", "Cobra Stretch"),
        ex("Supine Twist", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Piriformis"], "beginner", "Gentle rotation, knees to side, stay pain-free", "Seated Twist"),
    ])

def plantar_fasciitis_wo():
    return wo("Plantar Fasciitis Relief", "rehab", 15, [
        ex("Frozen Bottle Roll", 2, 1, 0, "60 seconds each foot", "Bodyweight", "Feet", "Plantar Fascia", ["Foot Intrinsics"], "beginner", "Roll foot over frozen water bottle, gentle pressure", "Tennis Ball Roll"),
        ex("Calf Stretch on Wall", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Calves", ["Soleus", "Achilles"], "beginner", "Straight back leg, heel down, lean into wall", "Step Calf Stretch"),
        ex("Towel Stretch", 2, 1, 0, "Hold 30 seconds each foot", "Bodyweight", "Feet", "Plantar Fascia", ["Calves"], "beginner", "Sit with legs straight, loop towel around toes, pull gently", "Band Foot Stretch"),
        ex("Toe Curl", 3, 15, 10, "Each foot", "Bodyweight", "Feet", "Toe Flexors", ["Foot Intrinsics"], "beginner", "Scrunch towel with toes, release, repeat", "Marble Pickup"),
        ex("Eccentric Calf Lower", 3, 12, 15, "Each side, slow lowering", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Rise on both feet, lower slowly on one foot off step edge", "Double Calf Raise"),
    ])

def hip_back_relief_wo():
    return wo("Hip & Back Relief", "rehab", 25, [
        ex("Supine Knee to Chest", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Glutes", ["Lower Back"], "beginner", "On back, hug knee to chest, breathe deeply", "Double Knee to Chest"),
        ex("Cat-Cow", 2, 10, 0, "Gentle flow", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Pain-free range, synchronized with breath", "Seated Cat-Cow"),
        ex("Figure-4 Stretch", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Ankle on opposite knee, pull toward chest", "Seated Figure-4"),
        ex("Pelvic Tilt", 3, 10, 10, "Flatten back to floor", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Press lower back flat, hold 5 seconds", "Supine March"),
        ex("Clamshell", 3, 12, 10, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Rotators"], "beginner", "Side-lying, open top knee, keep feet together", "Side-Lying Leg Lift"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Lower Back", "Hips"], "beginner", "Knees wide, reach forward, breathe into back", "Puppy Pose"),
    ])

# Cat 28 generation
cat28_programs = [
    ("Lower Back Rehab", "Rehab & Recovery", [2, 4, 8], [4, 5], "Gentle strengthening and mobility for lower back pain relief", "High", lambda w,t: [lower_back_rehab_wo()]*3),
    ("Shoulder Rehab", "Rehab & Recovery", [2, 4, 8], [4, 5], "Rotator cuff rehabilitation and shoulder mobility restoration", "High", lambda w,t: [shoulder_rehab_wo()]*3),
    ("Knee Rehab", "Rehab & Recovery", [2, 4, 8], [4, 5], "Post-injury knee strengthening and stability training", "High", lambda w,t: [knee_rehab_wo()]*3),
    ("Hip Rehab", "Rehab & Recovery", [2, 4, 8], [4, 5], "Hip mobility and strength recovery for pain-free movement", "High", lambda w,t: [hip_rehab_wo()]*3),
    ("Ankle Rehab", "Rehab & Recovery", [2, 4], [5, 6], "Ankle sprain recovery and stability training", "High", lambda w,t: [ankle_rehab_wo()]*3),
    ("Wrist & Elbow Rehab", "Rehab & Recovery", [2, 4], [5, 6], "Wrist and elbow rehabilitation for lifters and desk workers", "High", lambda w,t: [wrist_elbow_rehab_wo()]*3),
    ("Post-Surgery General", "Rehab & Recovery", [4, 8, 12], [3, 4], "General post-surgery return to movement program", "High", lambda w,t: [post_surgery_general_wo()]*3),
    ("ACL Recovery", "Rehab & Recovery", [4, 8, 12], [4, 5], "ACL rehabilitation with progressive quad and stability work", "High", lambda w,t: [acl_recovery_wo()]*3),
    ("Rotator Cuff Rehab", "Rehab & Recovery", [2, 4, 8], [4, 5], "Targeted rotator cuff rehabilitation exercises", "High", lambda w,t: [rotator_cuff_rehab_wo()]*3),
    ("Sciatica Relief", "Rehab & Recovery", [2, 4, 8], [5, 6], "Nerve pain management through targeted movement and stretching", "High", lambda w,t: [sciatica_relief_wo()]*3),
    ("Plantar Fasciitis Relief", "Rehab & Recovery", [2, 4, 8], [5, 6], "Foot pain relief through stretching and strengthening", "High", lambda w,t: [plantar_fasciitis_wo()]*3),
    ("Hip & Back Relief", "Rehab & Recovery", [2, 4, 8], [4, 5], "Combined hip and back pain relief program", "High", lambda w,t: [hip_back_relief_wo()]*3),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat28_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: gentle movements, pain-free range only"
            elif p <= 0.66: focus = f"Week {w} - Build: gradually increase range and resistance"
            else: focus = f"Week {w} - Strengthen: progress toward full function and stability"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 28 COMPLETE ===\n")

helper.close()
print("\n=== CATS 27-28 COMPLETE ===")
