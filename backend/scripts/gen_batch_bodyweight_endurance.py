#!/usr/bin/env python3
"""Generate Bodyweight/Home, Endurance, Calisthenics, and Quick Workout programs."""
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
# CATEGORY 14 - BODYWEIGHT/HOME
# ========================================================================

def no_equip_upper():
    return wo("Upper Body Bodyweight", "strength", 35, [
        ex("Push-Up", 4, 12, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands shoulder-width, lower chest to floor", "Knee Push-Up"),
        ex("Diamond Push-Up", 3, 10, 60, "Bodyweight", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands together under chest forming diamond", "Close-Grip Push-Up"),
        ex("Pike Push-Up", 3, 10, 60, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Hips high, head toward floor between hands", "Incline Push-Up"),
        ex("Tricep Dip (Floor)", 3, 15, 45, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid", "Pectoralis Major"], "beginner", "Hands behind you on floor, bend elbows to lower", "Bench Dip"),
        ex("Plank Shoulder Tap", 3, 20, 45, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "In plank, tap opposite shoulder without rocking hips", "Plank Hold"),
        ex("Superman", 3, 12, 45, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Prone, lift arms and legs simultaneously, squeeze at top", "Bird Dog"),
    ])

def no_equip_lower():
    return wo("Lower Body Bodyweight", "strength", 35, [
        ex("Bodyweight Squat", 4, 15, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feet shoulder-width, sit back and down, chest up", "Wall Sit"),
        ex("Reverse Lunge", 3, 12, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, lower knee toward floor, push through front heel", "Split Squat"),
        ex("Glute Bridge", 4, 15, 45, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive hips up, squeeze glutes at top, slow lower", "Single-Leg Glute Bridge"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot elevated on chair, lower until front thigh parallel", "Stationary Lunge"),
        ex("Calf Raise", 3, 20, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Rise onto toes, squeeze at top, slow descent", "Seated Calf Raise"),
        ex("Wall Sit", 3, 1, 60, "Hold 45 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Back flat against wall, thighs parallel to floor", "Half Squat Hold"),
    ])

def no_equip_full():
    return wo("Full Body Bodyweight", "strength", 40, [
        ex("Burpee", 3, 10, 60, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Shoulders", "Core"], "intermediate", "Drop to push-up, jump back up, full extension at top", "Squat Thrust"),
        ex("Push-Up", 3, 12, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range of motion, core tight", "Knee Push-Up"),
        ex("Jump Squat", 3, 12, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat deep then explode up, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 45, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Plank position, drive knees to chest alternating quickly", "Plank March"),
        ex("Reverse Lunge", 3, 12, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, lower with control, push through front foot", "Split Squat"),
        ex("Plank", 3, 1, 45, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders", "Glutes"], "beginner", "Straight line head to heels, squeeze everything", "Forearm Plank"),
    ])

def no_equip_core():
    return wo("Core Bodyweight", "strength", 25, [
        ex("Dead Bug", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Back flat on floor, extend opposite arm and leg slowly", "Bird Dog"),
        ex("Bicycle Crunch", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "beginner", "Twist elbow to opposite knee, slow and controlled", "Crunch"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, no sagging or piking", "Forearm Plank"),
        ex("Leg Raise", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs straight, lower slowly, dont let back arch", "Bent-Knee Leg Raise"),
        ex("Flutter Kick", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "Small kicks, lower back stays pressed to floor", "Dead Bug"),
    ])

# -- Minimal Equipment --
def minimal_equip_upper():
    return wo("Upper Body - Bands & DBs", "strength", 40, [
        ex("Dumbbell Floor Press", 4, 12, 60, "Moderate dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Lie on floor, press up, elbows touch floor each rep", "Push-Up"),
        ex("Resistance Band Row", 4, 12, 60, "Medium band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Band around feet, pull to waist, squeeze shoulder blades", "Towel Row"),
        ex("Dumbbell Shoulder Press", 3, 12, 60, "Light-moderate dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "beginner", "Press overhead, dont flare elbows excessively", "Band Overhead Press"),
        ex("Dumbbell Curl", 3, 12, 45, "Light dumbbells", "Dumbbells", "Arms", "Biceps", ["Forearms"], "beginner", "No swinging, control the negative", "Band Curl"),
        ex("Resistance Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Arms straight, pull band apart at chest height", "Reverse Fly"),
        ex("Dumbbell Tricep Overhead Extension", 3, 12, 45, "Light dumbbell", "Dumbbells", "Arms", "Triceps", ["Anconeus"], "beginner", "Both hands on one dumbbell overhead, lower behind head", "Band Tricep Pushdown"),
    ])

def minimal_equip_lower():
    return wo("Lower Body - Bands & DBs", "strength", 40, [
        ex("Goblet Squat", 4, 12, 60, "Moderate dumbbell", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold dumbbell at chest, squat deep, elbows inside knees", "Bodyweight Squat"),
        ex("Dumbbell Romanian Deadlift", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, slight knee bend, feel hamstring stretch", "Single-Leg Deadlift"),
        ex("Banded Lateral Walk", 3, 15, 45, "Medium band", "Resistance Band", "Hips", "Gluteus Medius", ["Gluteus Minimus", "Hip Abductors"], "beginner", "Band above knees, stay low, push knees out", "Side Lunge"),
        ex("Dumbbell Step-Up", 3, 10, 60, "Moderate dumbbells per leg", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step onto sturdy surface, drive through heel", "Walking Lunge"),
        ex("Banded Glute Bridge", 4, 15, 45, "Band above knees", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Drive hips up, push knees against band at top", "Glute Bridge"),
        ex("Dumbbell Calf Raise", 3, 20, 30, "Light dumbbells", "Dumbbells", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Rise onto toes holding dumbbells, slow lower", "Bodyweight Calf Raise"),
    ])

def minimal_equip_full():
    return wo("Full Body - Bands & DBs", "strength", 45, [
        ex("Dumbbell Thruster", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Glutes", "Core"], "intermediate", "Front squat to overhead press in one fluid motion", "Goblet Squat + Press"),
        ex("Resistance Band Row", 3, 12, 45, "Medium band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Seated on floor, band around feet, pull to chest", "Dumbbell Row"),
        ex("Dumbbell Floor Press", 3, 12, 45, "Moderate dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Elbows touch floor, press up, squeeze at top", "Push-Up"),
        ex("Goblet Squat", 3, 12, 45, "Moderate dumbbell", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Dumbbell at chest, sit deep, chest up", "Bodyweight Squat"),
        ex("Dumbbell Renegade Row", 3, 8, 60, "Light-moderate dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank on dumbbells, row one at a time, minimize hip rotation", "Plank Row"),
        ex("Banded Good Morning", 3, 12, 45, "Medium band", "Resistance Band", "Back", "Hamstrings", ["Erector Spinae", "Glutes"], "beginner", "Band behind neck and under feet, hinge at hips", "Dumbbell Romanian Deadlift"),
    ])

# -- Park Workout --
def park_upper():
    return wo("Park Upper Body", "strength", 35, [
        ex("Park Bench Push-Up", 4, 12, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands on bench, lower chest to edge, push up", "Incline Push-Up"),
        ex("Inverted Row (Park Bar)", 4, 10, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hang under bar, pull chest to bar, body straight", "Band Row"),
        ex("Park Bench Dip", 3, 12, 60, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid", "Pectoralis Major"], "beginner", "Hands on bench behind you, lower and press", "Floor Dip"),
        ex("Push-Up", 3, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "On grass, full range of motion", "Knee Push-Up"),
        ex("Dead Hang", 3, 1, 60, "Hold 30 seconds", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi", "Shoulders"], "beginner", "Hang from bar with straight arms, relax shoulders", "Band Hang"),
    ])

def park_lower():
    return wo("Park Lower Body", "strength", 35, [
        ex("Park Bench Step-Up", 4, 10, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step onto bench, drive through heel, stand tall", "Box Step-Up"),
        ex("Walking Lunge", 3, 12, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long strides on grass, knee just above ground", "Stationary Lunge"),
        ex("Single-Leg Glute Bridge", 3, 12, 45, "Bodyweight per leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "One foot on bench, drive hips up, squeeze at top", "Glute Bridge"),
        ex("Jump Squat", 3, 10, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat deep, explode up, soft grass landing", "Bodyweight Squat"),
        ex("Calf Raise (Curb)", 3, 20, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Toes on curb edge, rise and lower with full range", "Flat Calf Raise"),
    ])

# -- Garage Gym Basics --
def garage_upper():
    return wo("Garage Upper Body", "strength", 45, [
        ex("Barbell Bench Press", 4, 8, 90, "Moderate weight", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Feet flat, arch back slightly, bar to chest", "Dumbbell Floor Press"),
        ex("Barbell Row", 4, 10, 90, "Moderate weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge at hips, pull bar to lower chest, squeeze back", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 90, "Moderate weight", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Strict press, no leg drive, lockout overhead", "Dumbbell Shoulder Press"),
        ex("Pull-Up", 3, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full hang to chin over bar, controlled descent", "Band-Assisted Pull-Up"),
        ex("Dumbbell Lateral Raise", 3, 15, 45, "Light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Trapezius"], "beginner", "Slight bend in elbows, raise to shoulder height", "Band Lateral Raise"),
    ])

def garage_lower():
    return wo("Garage Lower Body", "strength", 45, [
        ex("Barbell Back Squat", 4, 8, 120, "Moderate weight", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Bar on upper back, sit back and down, depth below parallel", "Goblet Squat"),
        ex("Barbell Deadlift", 4, 5, 120, "Moderate-heavy", "Barbell", "Back", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "intermediate", "Hinge at hips, bar close to legs, lockout with hips", "Dumbbell Deadlift"),
        ex("Dumbbell Lunge", 3, 10, 60, "Moderate dumbbells per leg", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step forward, knee tracks over toes, push back up", "Bodyweight Lunge"),
        ex("Barbell Hip Thrust", 3, 12, 60, "Moderate weight", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Upper back on bench, drive hips up with bar on lap", "Glute Bridge"),
        ex("Dumbbell Calf Raise", 3, 20, 30, "Moderate dumbbells", "Dumbbells", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Toes on plate, rise fully, lower with stretch", "Bodyweight Calf Raise"),
    ])

# -- Prison Style Workout --
def prison_push():
    return wo("Prison Push Day", "strength", 30, [
        ex("Push-Up", 5, 20, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "High reps, strict form, chest to floor every rep", "Knee Push-Up"),
        ex("Diamond Push-Up", 4, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands close together, elbows tight to body", "Close-Grip Push-Up"),
        ex("Pike Push-Up", 4, 12, 60, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Hips high, head between hands, press up", "Incline Push-Up"),
        ex("Dip (Between Two Surfaces)", 4, 15, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Use two chairs or edges, lower and press up", "Floor Dip"),
        ex("Plank", 3, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Elbows under shoulders, body straight, breathe steady", "Forearm Plank"),
    ])

def prison_pull():
    return wo("Prison Pull Day", "strength", 30, [
        ex("Bodyweight Row (Door/Table)", 4, 15, 60, "Bodyweight", "Bodyweight", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Lie under table, pull chest to edge", "Towel Row"),
        ex("Towel Curl", 4, 15, 45, "Isometric resistance", "Bodyweight", "Arms", "Biceps", ["Forearms"], "beginner", "Loop towel around foot, curl against resistance", "Doorframe Curl"),
        ex("Superman", 4, 15, 30, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Lift arms and legs, hold 2 seconds at top", "Bird Dog"),
        ex("Reverse Snow Angel", 3, 12, 30, "Bodyweight", "Bodyweight", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Prone, sweep arms from sides to overhead and back", "Prone Y Raise"),
        ex("Isometric Bicep Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Arms", "Biceps", ["Forearms"], "beginner", "Arms at 90 degrees pushing against door frame", "Towel Curl"),
    ])

def prison_legs():
    return wo("Prison Leg Day", "strength", 30, [
        ex("Squat", 5, 25, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "High rep bodyweight squats, full depth every rep", "Wall Sit"),
        ex("Lunge", 4, 15, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Alternate legs, knee just above floor", "Split Squat"),
        ex("Pistol Squat Progression", 3, 8, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Use wall for balance, work toward full pistol", "Assisted Pistol Squat"),
        ex("Calf Raise", 5, 30, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "High reps, full range, squeeze at top", "Seated Calf Raise"),
        ex("Glute Bridge", 4, 20, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze hard at top for 2 seconds each rep", "Single-Leg Bridge"),
    ])

# -- Backyard Bootcamp --
def backyard_a():
    return wo("Backyard Bootcamp A", "hiit", 40, [
        ex("Burpee", 3, 10, 60, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to ground, jump at top, keep moving", "Squat Thrust"),
        ex("Bear Crawl", 3, 1, 60, "30 seconds", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps", "Hip Flexors"], "beginner", "Hands and feet, knees 2 inches off ground, crawl forward", "Plank Walk"),
        ex("Broad Jump", 3, 8, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Swing arms, explode forward, soft landing", "Jump Squat"),
        ex("Push-Up to T-Rotation", 3, 10, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up then rotate to side plank, alternate sides", "Push-Up"),
        ex("High Knees", 3, 30, 30, "Bodyweight", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core", "Calves"], "beginner", "Drive knees high, pump arms, stay on toes", "March in Place"),
        ex("Plank Up-Down", 3, 10, 45, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm to hand plank, alternating lead arm", "Plank Hold"),
    ])

def backyard_b():
    return wo("Backyard Bootcamp B", "hiit", 40, [
        ex("Tuck Jump", 3, 8, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Jump high, pull knees to chest at peak, soft landing", "Jump Squat"),
        ex("Inch Worm", 3, 8, 45, "Bodyweight", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Walk hands out to plank, walk feet to hands, stand", "Standing Forward Fold"),
        ex("Lateral Shuffle", 3, 1, 45, "30 seconds each direction", "Bodyweight", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "beginner", "Stay low, quick feet, push off outside foot", "Side Step"),
        ex("Decline Push-Up (on step/ledge)", 3, 12, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Triceps"], "intermediate", "Feet elevated on step, more shoulder engagement", "Push-Up"),
        ex("Sprint in Place", 3, 1, 30, "20 seconds all out", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Core", "Hip Flexors"], "beginner", "Pump arms, drive knees, maximum effort", "High Knees"),
        ex("V-Up", 3, 12, 45, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Arms and legs meet at top, lower with control", "Crunch"),
    ])

# -- Playground Fitness --
def playground_a():
    return wo("Playground Circuit A", "strength", 35, [
        ex("Pull-Up (Monkey Bars)", 3, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full hang to chin over bar, squeeze at top", "Band-Assisted Pull-Up"),
        ex("Swing Push-Up", 3, 10, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Hands on swing seat, perform push-up with instability", "Incline Push-Up"),
        ex("Monkey Bar Traverse", 3, 1, 90, "Full length across", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi", "Biceps"], "intermediate", "Swing from bar to bar, maintain momentum", "Dead Hang"),
        ex("Step-Up (Platform)", 3, 12, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step onto platform, drive up, step down controlled", "Walking Lunge"),
        ex("Hanging Knee Raise", 3, 12, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Hang from bar, bring knees to chest, lower slowly", "Lying Knee Raise"),
    ])

def playground_b():
    return wo("Playground Circuit B", "strength", 35, [
        ex("Inverted Row (Low Bar)", 4, 10, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Under low bar, pull chest up, straight body", "Band Row"),
        ex("Bench Dip", 3, 15, 45, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid", "Pectoralis Major"], "beginner", "Hands on bench, lower body, press up", "Floor Dip"),
        ex("Box Jump (Low Platform)", 3, 10, 60, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Swing arms, jump onto platform, step down", "Step-Up"),
        ex("Slide Plank", 3, 1, 45, "Hold 40 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Forearms on slide surface, hold plank", "Plank"),
        ex("Lunge Walk", 3, 12, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Walk forward in lunges across playground", "Stationary Lunge"),
    ])

# -- Hotel Room Fitness --
def hotel_full_a():
    return wo("Hotel Room Full Body A", "strength", 25, [
        ex("Push-Up", 3, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands on floor, full range of motion", "Knee Push-Up"),
        ex("Bodyweight Squat", 3, 15, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Sit back, chest up, full depth", "Wall Sit"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Body straight, breathe steady, dont sag", "Forearm Plank"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Feet on floor, drive hips up, squeeze at top", "Single-Leg Bridge"),
        ex("Tricep Dip (Chair)", 3, 12, 45, "Bodyweight", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Hands on chair edge, lower and press", "Floor Dip"),
        ex("Mountain Climber", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Quick alternating knees to chest in plank", "Plank March"),
    ])

def hotel_full_b():
    return wo("Hotel Room Full Body B", "strength", 25, [
        ex("Reverse Lunge", 3, 12, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, lower knee, push through front foot", "Split Squat"),
        ex("Pike Push-Up", 3, 10, 45, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Hips high, head toward floor", "Incline Push-Up"),
        ex("Single-Leg Glute Bridge", 3, 10, 45, "Bodyweight per leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "One leg extended, drive hips up on working leg", "Glute Bridge"),
        ex("Superman", 3, 12, 30, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Lift arms and legs off floor, hold briefly", "Bird Dog"),
        ex("Bicycle Crunch", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Twist with control, elbow to opposite knee", "Crunch"),
    ])

# ========================================================================
# CATEGORY 15 - ENDURANCE
# ========================================================================

def cardio_base_a():
    return wo("Cardio Base - Steady State", "cardio", 40, [
        ex("Brisk Walking/Jogging", 1, 1, 0, "Zone 2 heart rate (60-70% max HR)", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Hamstrings", "Core"], "beginner", "Maintain conversational pace, 20-30 minutes continuous", "Stationary Bike"),
        ex("Jumping Jack", 3, 30, 30, "Bodyweight", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Hip Abductors"], "beginner", "Full arm extension, land softly, maintain rhythm", "Step Jack"),
        ex("High Knees", 3, 30, 30, "Bodyweight", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Drive knees high, stay on balls of feet", "March in Place"),
        ex("Butt Kick", 3, 30, 30, "Bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Calves", "Quadriceps"], "beginner", "Heel to glute each rep, upright posture", "Jog in Place"),
        ex("Step-Up (Alternating)", 3, 20, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Alternate feet on step, maintain steady pace", "March in Place"),
    ])

def cardio_base_b():
    return wo("Cardio Base - Intervals", "cardio", 35, [
        ex("Run/Walk Interval", 1, 1, 0, "Alternate 2 min jog / 1 min walk x 8", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "beginner", "Jog at easy pace, walk to recover, repeat", "Bike Intervals"),
        ex("Jump Rope (or Imaginary)", 3, 1, 30, "60 seconds", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core", "Forearms"], "beginner", "Light bounces on balls of feet, wrists turn rope", "Jumping Jack"),
        ex("Mountain Climber", 3, 20, 30, "Moderate pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Steady rhythm, drive knees to chest", "Plank March"),
        ex("Squat Jump", 3, 10, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat, explode up, soft landing, repeat", "Bodyweight Squat"),
    ])

def cardio_base_c():
    return wo("Cardio Base - Cross Training", "cardio", 40, [
        ex("Rowing (or Band Row Intervals)", 1, 1, 0, "20 minutes steady state", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core", "Biceps"], "beginner", "Drive with legs, pull with back, arms last", "Band Row"),
        ex("Burpee", 3, 8, 60, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump up, keep consistent pace", "Squat Thrust"),
        ex("Bear Crawl", 3, 1, 45, "30 seconds", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "beginner", "Knees hover, crawl forward and back", "Plank Walk"),
        ex("Skater Jump", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "intermediate", "Lateral jump, land on one foot, absorb impact", "Lateral Lunge"),
    ])

# -- Stamina & Conditioning --
def stamina_circuit():
    return wo("Stamina Circuit", "conditioning", 40, [
        ex("Kettlebell Swing", 4, 15, 60, "Moderate kettlebell", "Kettlebell", "Full Body", "Hamstrings", ["Glutes", "Core", "Shoulders"], "intermediate", "Hinge at hips, snap hips forward, float bell to chest", "Dumbbell Swing"),
        ex("Box Jump", 3, 10, 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Swing arms, jump onto box, stand fully, step down", "Jump Squat"),
        ex("Battle Rope Slam", 3, 1, 45, "30 seconds", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Latissimus Dorsi"], "intermediate", "Slam ropes hard, use hips and core, maintain rhythm", "Mountain Climber"),
        ex("Sled Push (or Bear Crawl)", 3, 1, 60, "30 seconds", "Sled", "Legs", "Quadriceps", ["Glutes", "Core", "Calves"], "intermediate", "Drive through legs, low body angle, powerful steps", "Bear Crawl"),
        ex("Rowing Machine", 3, 1, 60, "500m intervals", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core"], "intermediate", "Powerful leg drive, maintain stroke rate 24-28", "Band Row"),
        ex("Farmer Walk", 3, 1, 45, "30 seconds", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core", "Calves"], "beginner", "Heavy dumbbells at sides, walk with tight core, tall posture", "Suitcase Carry"),
    ])

def stamina_endurance():
    return wo("Stamina Endurance", "conditioning", 45, [
        ex("Assault Bike (or Cycling)", 4, 1, 60, "30 seconds hard / 30 seconds easy", "Stationary Bike", "Full Body", "Quadriceps", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Push and pull handles, drive legs, all-out effort", "Jumping Jack"),
        ex("Thruster", 3, 12, 60, "Light-moderate weight", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "intermediate", "Front squat to overhead press in one motion", "Goblet Squat + Press"),
        ex("Burpee", 3, 10, 45, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explode up, maintain pace", "Squat Thrust"),
        ex("Wall Ball", 3, 15, 45, "14-20 lb medicine ball", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "intermediate", "Squat, throw ball at target, catch, repeat", "Goblet Squat"),
        ex("Jump Rope", 3, 1, 30, "60 seconds", "Jump Rope", "Full Body", "Calves", ["Core", "Shoulders"], "beginner", "Double under attempts or fast singles", "Jumping Jack"),
    ])

# -- Heart Health Cardio --
def heart_health_a():
    return wo("Heart Health - Low Impact", "cardio", 40, [
        ex("Brisk Walking", 1, 1, 0, "30 minutes at 60-70% max HR", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Arms swinging, brisk pace, maintain conversation", "Treadmill Walk"),
        ex("Marching in Place", 3, 1, 30, "60 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Lift knees high, pump arms, upright posture", "Step Touch"),
        ex("Step Touch", 3, 1, 30, "60 seconds", "Bodyweight", "Legs", "Hip Abductors", ["Calves", "Quadriceps"], "beginner", "Step side to side, stay light on feet, add arm reaches", "Lateral Step"),
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Slow tempo, breathe deeply, full range", "Wall Sit"),
        ex("Arm Circle", 2, 15, 15, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Small to large circles, maintain rhythm", "Shoulder Roll"),
    ])

def heart_health_b():
    return wo("Heart Health - Moderate Intensity", "cardio", 35, [
        ex("Cycling (Stationary)", 1, 1, 0, "20 minutes at 65-75% max HR", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Moderate resistance, steady cadence 70-90 RPM", "Brisk Walking"),
        ex("Step-Up", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Alternate legs on step, steady tempo", "March in Place"),
        ex("Jumping Jack", 3, 25, 30, "Bodyweight", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Hip Abductors"], "beginner", "Full extension, light landing, breathe rhythmically", "Step Jack"),
        ex("Walking Lunge", 2, 12, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long steps, controlled movement", "Stationary Lunge"),
    ])

# -- Beginner 5K Running --
def run_5k_wo(week, total):
    p = week / total
    if p <= 0.33:
        return wo(f"Week {week} - Walk/Jog", "cardio", 25, [
            ex("Walk/Jog Interval", 1, 1, 0, f"Alternate 1 min jog / 2 min walk x {5 + week}", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Easy jog pace, walk to fully recover between intervals", "Treadmill Walk/Jog"),
            ex("Bodyweight Squat", 2, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Warm up legs with air squats", "Wall Sit"),
            ex("Calf Raise", 2, 20, 20, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Strengthen calves for running", "Seated Calf Raise"),
        ])
    elif p <= 0.66:
        return wo(f"Week {week} - Building Runs", "cardio", 30, [
            ex("Jog/Walk Interval", 1, 1, 0, f"Alternate 3 min jog / 1 min walk x {4 + week}", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Extend jog intervals, shorter walks, find your pace", "Treadmill Jog"),
            ex("Walking Lunge", 2, 10, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Build running-specific leg strength", "Stationary Lunge"),
            ex("Glute Bridge", 2, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Activate glutes for better running form", "Single-Leg Bridge"),
        ])
    else:
        return wo(f"Week {week} - Continuous Runs", "cardio", 35, [
            ex("Continuous Run", 1, 1, 0, f"Run {15 + (week - 6) * 3} minutes continuously", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "beginner", "Maintain steady pace, focus on breathing rhythm", "Treadmill Run"),
            ex("High Knees", 2, 20, 30, "Bodyweight", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Running form drill, lift knees high", "March in Place"),
            ex("Plank", 2, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Build core for running posture", "Forearm Plank"),
        ])

# -- Beginner 10K Running --
def run_10k_wo(week, total):
    p = week / total
    if p <= 0.33:
        return wo(f"Week {week} - Base Building", "cardio", 35, [
            ex("Easy Run", 1, 1, 0, f"Run {20 + week * 2} minutes at easy pace", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Conversational pace, focus on form", "Treadmill Run"),
            ex("Bodyweight Squat", 2, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Post-run leg conditioning", "Wall Sit"),
            ex("Calf Raise", 2, 20, 20, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Injury prevention for runners", "Seated Calf Raise"),
        ])
    elif p <= 0.66:
        return wo(f"Week {week} - Tempo Runs", "cardio", 45, [
            ex("Tempo Run", 1, 1, 0, f"10 min easy + {10 + week} min tempo + 10 min easy", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Tempo is comfortably hard - can speak short phrases only", "Treadmill Tempo"),
            ex("Walking Lunge", 2, 12, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Build running strength", "Stationary Lunge"),
            ex("Single-Leg Glute Bridge", 2, 10, 30, "Bodyweight per leg", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Single-leg stability for running", "Glute Bridge"),
        ])
    else:
        return wo(f"Week {week} - Long Runs", "cardio", 55, [
            ex("Long Run", 1, 1, 0, f"Run {35 + (week - 8) * 5} minutes at easy pace", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Easy pace, build endurance, walk if needed", "Treadmill Run"),
            ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Lunge stretch after long run", "Standing Quad Stretch"),
            ex("Foam Roll (or Self-Massage)", 1, 1, 0, "5 minutes", "Foam Roller", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "IT Band"], "beginner", "Roll slowly over tight areas, 30 seconds per spot", "Stretching"),
        ])

# -- 5K to Half Marathon --
def half_marathon_wo(week, total):
    p = week / total
    if p <= 0.33:
        return wo(f"Week {week} - Mileage Build", "cardio", 45, [
            ex("Easy Run", 1, 1, 0, f"Run {30 + week * 3} minutes at easy pace", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Zone 2 heart rate, conversational pace throughout", "Treadmill Run"),
            ex("Strides", 4, 1, 60, "20 seconds at 80% effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Accelerate smoothly, hold pace, decelerate", "High Knees"),
            ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Runner leg conditioning", "Wall Sit"),
        ])
    elif p <= 0.66:
        return wo(f"Week {week} - Speed Work", "cardio", 55, [
            ex("Interval Run", 1, 1, 0, f"8 x 400m at 5K pace with 90 sec jog recovery", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Hit target pace each rep, jog to recover", "Treadmill Intervals"),
            ex("Tempo Run", 1, 1, 0, "15 minutes at half marathon pace", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Comfortably hard, practice race pace", "Treadmill Tempo"),
            ex("Plank", 2, 1, 30, "Hold 60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability for running economy", "Forearm Plank"),
        ])
    else:
        return wo(f"Week {week} - Peak/Taper", "cardio", 60, [
            ex("Long Run", 1, 1, 0, f"Run {60 + (week - 8) * 10} minutes at easy pace", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "Build to race distance, practice nutrition strategy", "Treadmill Run"),
            ex("Cool Down Walk", 1, 1, 0, "10 minutes", "Bodyweight", "Full Body", "Calves", ["Hamstrings"], "beginner", "Walk to bring heart rate down gradually", "Standing Stretches"),
            ex("Hip Flexor Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Deep lunge position, open hip flexors", "Standing Quad Stretch"),
        ])

# -- Stair Climbing --
def stair_climb_a():
    return wo("Stair Climbing A", "cardio", 30, [
        ex("Stair Climb (Steady)", 1, 1, 0, "15-20 minutes continuous climbing", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves", "Core"], "beginner", "Every step, push through heel, upright posture", "Step-Up"),
        ex("Stair Sprint", 4, 1, 90, "Sprint up one flight, walk down", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Drive knees, pump arms, take stairs two at a time", "Jump Squat"),
        ex("Step-Up (Single Stair)", 3, 15, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Alternate legs, maintain pace", "March in Place"),
        ex("Calf Raise (Stair Edge)", 3, 20, 30, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full range off stair edge, slow descent", "Flat Calf Raise"),
    ])

def stair_climb_b():
    return wo("Stair Climbing B", "cardio", 30, [
        ex("Stair Lunge", 3, 10, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Take two stairs at once in lunge motion", "Walking Lunge"),
        ex("Stair Lateral Step-Up", 3, 12, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Hip Abductors"], "beginner", "Stand sideways, step up laterally", "Lateral Step-Up"),
        ex("Stair Bear Crawl", 3, 1, 60, "Crawl up one flight", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Hands and feet on stairs, crawl up on all fours", "Bear Crawl"),
        ex("Stair Climb (Continuous)", 1, 1, 0, "10 minutes steady pace", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Consistent pace, rhythmic breathing", "Step-Up"),
    ])

# -- Low Intensity Steady State --
def liss_a():
    return wo("LISS - Cardio A", "cardio", 45, [
        ex("Brisk Walk / Light Jog", 1, 1, 0, "30-40 minutes at 60-70% max HR", "Bodyweight", "Full Body", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Maintain zone 2, should be able to hold conversation", "Treadmill Walk"),
        ex("Cool Down Walk", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Calves", ["Hamstrings"], "beginner", "Gradually slow pace, deep breathing", "Standing Stretches"),
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, stand tall", "Lying Quad Stretch"),
    ])

def liss_b():
    return wo("LISS - Cardio B", "cardio", 45, [
        ex("Cycling (Stationary or Outdoor)", 1, 1, 0, "35-45 minutes at 60-70% max HR", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "beginner", "Moderate resistance, steady cadence 70-85 RPM", "Brisk Walking"),
        ex("Hip Circle", 2, 10, 0, "Each direction", "Bodyweight", "Hips", "Hip Flexors", ["Glutes"], "beginner", "Loosen hips after cycling", "Standing Hip Rotation"),
        ex("Standing Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on low surface, lean forward from hips", "Seated Forward Fold"),
    ])

# ========================================================================
# CATEGORY 16 - CALISTHENICS
# ========================================================================

def cali_fund_push():
    return wo("Calisthenics Push", "strength", 40, [
        ex("Push-Up", 4, 12, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full range, elbows 45 degrees, core tight", "Knee Push-Up"),
        ex("Diamond Push-Up", 3, 8, 60, "Bodyweight", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands form diamond shape, elbows tight to body", "Close-Grip Push-Up"),
        ex("Pike Push-Up", 3, 8, 60, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Hips high, head between hands toward floor", "Incline Push-Up"),
        ex("Pseudo Planche Push-Up", 3, 6, 90, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Biceps"], "advanced", "Hands turned out, lean forward past hands, push up", "Push-Up"),
        ex("Dip (Parallel Bars)", 3, 8, 90, "Bodyweight", "Parallel Bars", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Lean slightly forward, lower until 90 degrees, press up", "Bench Dip"),
    ])

def cali_fund_pull():
    return wo("Calisthenics Pull", "strength", 40, [
        ex("Pull-Up", 4, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Full hang, pull chin over bar, slow lower", "Band-Assisted Pull-Up"),
        ex("Chin-Up", 3, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Biceps", ["Latissimus Dorsi", "Rear Deltoid"], "intermediate", "Supinated grip, pull chin over bar", "Band-Assisted Chin-Up"),
        ex("Inverted Row", 3, 12, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Under low bar, pull chest to bar, body straight", "Band Row"),
        ex("Hanging Knee Raise", 3, 12, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Hang from bar, bring knees to chest without swinging", "Lying Knee Raise"),
        ex("Dead Hang", 3, 1, 60, "Hold 30-45 seconds", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi", "Shoulders"], "beginner", "Relax into full hang, build grip endurance", "Band Hang"),
    ])

def cali_fund_legs():
    return wo("Calisthenics Legs", "strength", 35, [
        ex("Pistol Squat Progression", 3, 6, 90, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Use support initially, work toward freestanding", "Assisted Pistol"),
        ex("Shrimp Squat Progression", 3, 6, 90, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Flexors"], "advanced", "Grab rear foot, squat down on one leg", "Bulgarian Split Squat"),
        ex("Nordic Curl Negative", 3, 5, 90, "Bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Calves"], "advanced", "Kneel, lower body forward slowly with straight hips", "Glute Bridge"),
        ex("Calf Raise", 3, 20, 30, "Bodyweight, single-leg", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "One leg at a time, full range on a step", "Double-Leg Calf Raise"),
        ex("L-Sit Hold", 3, 1, 60, "Hold 15-20 seconds", "Parallel Bars", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "advanced", "Arms locked, legs straight and parallel to floor", "Tucked L-Sit"),
    ])

# -- Calisthenics Strength --
def cali_str_upper():
    return wo("Cali Strength Upper", "strength", 50, [
        ex("Weighted Pull-Up", 4, 6, 120, "Add 10-25 lbs", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "advanced", "Dip belt or backpack with weight, full ROM", "Pull-Up"),
        ex("Ring Dip", 4, 8, 90, "Bodyweight", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Turn rings out at top, slow controlled descent", "Parallel Bar Dip"),
        ex("Archer Push-Up", 3, 6, 90, "Bodyweight per side", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "One arm does the work, other slides out straight", "Wide Push-Up"),
        ex("Typewriter Pull-Up", 3, 5, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "advanced", "Pull up, shift side to side at top, control down", "Wide Pull-Up"),
        ex("Handstand Push-Up (Wall)", 3, 5, 120, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "advanced", "Kick up to wall, lower head to floor, press up", "Pike Push-Up"),
        ex("Front Lever Raise", 3, 6, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core", "Rear Deltoid"], "advanced", "Hang, raise body horizontal using back and core", "Tucked Front Lever"),
    ])

def cali_str_lower():
    return wo("Cali Strength Lower", "strength", 40, [
        ex("Pistol Squat", 4, 5, 90, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Full depth single-leg squat, arms forward for balance", "Assisted Pistol"),
        ex("Nordic Curl", 3, 5, 120, "Bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Calves"], "advanced", "Control the descent fully, push off floor to assist up", "Nordic Curl Negative"),
        ex("Single-Leg Calf Raise", 4, 15, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "intermediate", "Full ROM on step, pause at top", "Double-Leg Calf Raise"),
        ex("Shrimp Squat", 3, 5, 90, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hip Flexors"], "advanced", "Grab rear foot, squat to floor", "Bulgarian Split Squat"),
        ex("Dragon Flag Negative", 3, 4, 90, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "advanced", "Shoulders on bench, lower body slowly staying rigid", "Lying Leg Raise"),
    ])

# -- Street Workout --
def street_push():
    return wo("Street Push", "strength", 45, [
        ex("Muscle-Up Progression", 3, 5, 120, "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps", "Core"], "advanced", "Explosive pull, transition over bar, press out", "High Pull-Up"),
        ex("Dip", 4, 12, 60, "Bodyweight", "Parallel Bars", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Deep dip, lean forward for chest emphasis", "Bench Dip"),
        ex("Decline Push-Up", 3, 15, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid", "Triceps"], "intermediate", "Feet on bar, hands on ground, full ROM", "Push-Up"),
        ex("Planche Lean", 3, 1, 60, "Hold 20 seconds", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Pectoralis Major", "Core"], "advanced", "Locked arms, lean forward, feet still touching", "Pseudo Planche Push-Up"),
        ex("Explosive Push-Up", 3, 8, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Push off floor, clap, land with soft elbows", "Push-Up"),
    ])

def street_pull():
    return wo("Street Pull", "strength", 45, [
        ex("Pull-Up (Various Grips)", 4, 10, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Alternate wide, narrow, and neutral grip sets", "Band-Assisted Pull-Up"),
        ex("Toes-to-Bar", 3, 8, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Latissimus Dorsi"], "advanced", "Hang, kick toes up to touch bar, control down", "Hanging Knee Raise"),
        ex("Commando Pull-Up", 3, 6, 90, "Bodyweight per side", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Obliques"], "advanced", "Side-on to bar, pull head to one side then other", "Chin-Up"),
        ex("Front Lever Hold", 3, 1, 90, "Hold 10-15 seconds", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core", "Rear Deltoid"], "advanced", "Body horizontal while hanging, engage entire posterior", "Tucked Front Lever"),
        ex("Skin the Cat", 3, 5, 90, "Bodyweight", "Pull-Up Bar", "Shoulders", "Latissimus Dorsi", ["Rear Deltoid", "Core"], "advanced", "Hang, pull legs through arms, rotate fully, reverse", "Hanging Knee Raise"),
    ])

# -- Gymnastics Foundations --
def gym_rings():
    return wo("Ring Fundamentals", "strength", 45, [
        ex("Ring Support Hold", 4, 1, 60, "Hold 20-30 seconds", "Gymnastic Rings", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Arms locked, rings turned out, body vertical", "Parallel Bar Hold"),
        ex("Ring Push-Up", 3, 8, 60, "Bodyweight", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Rings at ground level, unstable push-up, squeeze rings", "Push-Up"),
        ex("Ring Row", 3, 12, 60, "Bodyweight", "Gymnastic Rings", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Feet forward, pull chest to rings, body straight", "Inverted Row"),
        ex("Ring Dip", 3, 6, 90, "Bodyweight", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Turn rings out at top, lower with control", "Parallel Bar Dip"),
        ex("Ring L-Sit", 3, 1, 60, "Hold 10-15 seconds", "Gymnastic Rings", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "advanced", "Support on rings, legs straight and horizontal", "Tucked L-Sit"),
        ex("Ring Skin the Cat", 3, 4, 90, "Bodyweight", "Gymnastic Rings", "Shoulders", "Latissimus Dorsi", ["Rear Deltoid", "Core"], "advanced", "Full rotation through the rings", "Hanging Knee Raise"),
    ])

def gym_floor():
    return wo("Floor Skills", "strength", 40, [
        ex("Handstand Hold (Wall)", 4, 1, 90, "Hold 30-45 seconds", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Belly to wall, push floor away, straight line", "Pike Handstand"),
        ex("L-Sit (Floor)", 3, 1, 60, "Hold 15-20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "advanced", "Hands on floor, lift body, legs straight", "Tucked L-Sit"),
        ex("Hollow Body Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Arms overhead, lower back pressed to floor, banana shape", "Bent-Knee Hollow"),
        ex("Arch Body Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "intermediate", "Prone, lift arms and legs, reverse banana shape", "Superman"),
        ex("Cartwheel", 3, 5, 60, "Bodyweight per side", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hip Abductors"], "intermediate", "Hands down one at a time, legs over, land on feet", "Lateral Roll"),
    ])

# -- Calisthenics for Beginners --
def cali_beg_a():
    return wo("Beginner Calisthenics A", "strength", 30, [
        ex("Knee Push-Up", 3, 10, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Knees on floor, lower chest to ground, push up", "Incline Push-Up"),
        ex("Bodyweight Squat", 3, 15, 45, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Sit back, chest up, depth below parallel", "Wall Sit"),
        ex("Dead Hang", 3, 1, 60, "Hold 20 seconds", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi"], "beginner", "Full hang, relax shoulders, build grip", "Band Hang"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight body, squeeze everything, breathe", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Drive hips up, squeeze at top", "Hip Thrust"),
    ])

def cali_beg_b():
    return wo("Beginner Calisthenics B", "strength", 30, [
        ex("Incline Push-Up", 3, 12, 45, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands on elevated surface, full push-up motion", "Knee Push-Up"),
        ex("Inverted Row (Low Bar)", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Under low bar, pull chest up, walk feet closer for harder", "Band Row"),
        ex("Lunge", 3, 10, 45, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Alternate legs, knee tracks over toes", "Split Squat"),
        ex("Superman", 3, 10, 30, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Arms and legs up, hold 2 seconds, lower", "Bird Dog"),
        ex("Dead Bug", 3, 10, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Opposite arm and leg extend, keep back flat", "Bird Dog"),
    ])

# -- Ring Training --
def ring_upper():
    return wo("Ring Upper Body", "strength", 40, [
        ex("Ring Muscle-Up Progression", 3, 4, 120, "Bodyweight", "Gymnastic Rings", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Deep pull, fast transition, press to support", "Ring Pull-Up"),
        ex("Ring Push-Up", 4, 10, 60, "Bodyweight", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Rings low, unstable push-up, control sway", "Push-Up"),
        ex("Ring Dip", 4, 8, 90, "Bodyweight", "Gymnastic Rings", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Turn rings out at lockout, deep descent", "Parallel Bar Dip"),
        ex("Ring Face Pull", 3, 12, 60, "Bodyweight", "Gymnastic Rings", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "intermediate", "Lean back, pull rings to face, squeeze back", "Band Face Pull"),
        ex("Ring Bicep Curl", 3, 10, 45, "Bodyweight", "Gymnastic Rings", "Arms", "Biceps", ["Forearms"], "intermediate", "Lean back, curl body up using arms only", "Chin-Up"),
    ])

def ring_core():
    return wo("Ring Core", "strength", 30, [
        ex("Ring Ab Rollout", 3, 8, 60, "Bodyweight", "Gymnastic Rings", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "advanced", "From knees, extend arms forward on rings, pull back", "Ab Wheel Rollout"),
        ex("Ring L-Sit", 3, 1, 60, "Hold 10-15 seconds", "Gymnastic Rings", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "advanced", "Support position, lift legs to horizontal", "Tucked L-Sit"),
        ex("Ring Knee Tuck", 3, 10, 45, "Bodyweight", "Gymnastic Rings", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Feet in ring straps, tuck knees to chest in plank", "Hanging Knee Raise"),
        ex("Ring Body Saw", 3, 8, 45, "Bodyweight", "Gymnastic Rings", "Core", "Rectus Abdominis", ["Shoulders", "Core"], "advanced", "Forearms in rings, plank position, rock back and forth", "Plank"),
    ])

# -- Bar Athletes --
def bar_pull():
    return wo("Bar Pull Mastery", "strength", 40, [
        ex("Pull-Up", 5, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Overhand grip, full range, chest to bar", "Band-Assisted Pull-Up"),
        ex("Chin-Up", 3, 10, 90, "Bodyweight", "Pull-Up Bar", "Back", "Biceps", ["Latissimus Dorsi", "Rear Deltoid"], "intermediate", "Underhand grip, pull chin well over bar", "Band-Assisted Chin-Up"),
        ex("Wide-Grip Pull-Up", 3, 6, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Teres Major", "Biceps"], "advanced", "Hands wider than shoulders, pull to upper chest", "Regular Pull-Up"),
        ex("Close-Grip Pull-Up", 3, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Hands close together, palms away, full ROM", "Chin-Up"),
        ex("Hanging Leg Raise", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "advanced", "Straight legs, raise to 90 degrees, no swing", "Hanging Knee Raise"),
    ])

def bar_push():
    return wo("Bar Push Mastery", "strength", 40, [
        ex("Dip", 4, 10, 60, "Bodyweight", "Parallel Bars", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Lean forward for chest, upright for triceps", "Bench Dip"),
        ex("Muscle-Up Progression", 3, 4, 120, "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Explosive pull, transition, push to lockout", "High Pull-Up"),
        ex("L-Sit (Parallel Bars)", 3, 1, 60, "Hold 15-20 seconds", "Parallel Bars", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "advanced", "Straight arms, legs horizontal, core engaged", "Tucked L-Sit"),
        ex("Korean Dip", 3, 6, 90, "Bodyweight", "Parallel Bars", "Shoulders", "Rear Deltoid", ["Triceps", "Core"], "advanced", "Bars behind you, lower behind body, press up", "Regular Dip"),
        ex("Straight Bar Dip", 3, 8, 60, "Bodyweight", "Pull-Up Bar", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "advanced", "On top of bar, lean forward, dip and press", "Parallel Bar Dip"),
    ])

# -- Skills Unlocked --
def skills_a():
    return wo("Skill Practice A", "strength", 50, [
        ex("Handstand Wall Walk", 3, 4, 90, "Bodyweight", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Walk feet up wall, walk hands closer, hold at top", "Pike Handstand"),
        ex("Muscle-Up Progression", 4, 3, 120, "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Practice explosive pull and transition separately", "High Pull-Up"),
        ex("Front Lever Tuck Hold", 3, 1, 90, "Hold 15 seconds", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core", "Rear Deltoid"], "advanced", "Hang, tuck knees, lift body horizontal", "Inverted Row"),
        ex("Back Lever Tuck Hold", 3, 1, 90, "Hold 15 seconds", "Pull-Up Bar", "Shoulders", "Rear Deltoid", ["Core", "Biceps"], "advanced", "Skin the cat position, hold body horizontal", "Inverted Hang"),
        ex("Planche Lean", 3, 1, 60, "Hold 20 seconds", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Core", "Pectoralis Major"], "advanced", "Straight arms, lean forward, increase gradually", "Pseudo Planche Push-Up"),
    ])

def skills_b():
    return wo("Skill Practice B", "strength", 50, [
        ex("Freestanding Handstand Practice", 4, 1, 90, "Hold max time", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "advanced", "Kick up, find balance, micro-adjust with fingers", "Wall Handstand"),
        ex("Ring Muscle-Up", 3, 3, 120, "Bodyweight", "Gymnastic Rings", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "False grip, deep pull, fast transition", "Ring Pull-Up"),
        ex("Front Lever (Extended Tuck)", 3, 1, 90, "Hold 15 seconds", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core"], "advanced", "Extend legs slightly from tuck position", "Tucked Front Lever"),
        ex("L-Sit to V-Sit Progression", 3, 1, 60, "Hold max", "Parallel Bars", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Start L-Sit, try to lift legs higher toward V", "L-Sit"),
        ex("Pistol Squat", 3, 5, 60, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Full depth, smooth and controlled", "Assisted Pistol"),
    ])

# ========================================================================
# CATEGORY 17 - QUICK WORKOUTS
# ========================================================================

def seven_min():
    return wo("7-Minute Scientific", "hiit", 7, [
        ex("Jumping Jack", 1, 1, 10, "30 seconds", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Hip Abductors"], "beginner", "Full extension, rhythmic pace, 30 seconds", "Step Jack"),
        ex("Wall Sit", 1, 1, 10, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Back on wall, thighs parallel, hold", "Bodyweight Squat"),
        ex("Push-Up", 1, 1, 10, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Max reps in 30 seconds, good form", "Knee Push-Up"),
        ex("Crunch", 1, 1, 10, "30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Continuous crunches for 30 seconds", "Dead Bug"),
        ex("Step-Up", 1, 1, 10, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Alternate legs on chair, brisk pace", "March in Place"),
        ex("Bodyweight Squat", 1, 1, 10, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Continuous squats for 30 seconds", "Wall Sit"),
        ex("Tricep Dip (Chair)", 1, 1, 10, "30 seconds", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Hands on chair, dip for 30 seconds", "Floor Dip"),
        ex("Plank", 1, 1, 10, "30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Hold solid plank 30 seconds", "Forearm Plank"),
        ex("High Knees", 1, 1, 10, "30 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Run in place with high knees 30 seconds", "March in Place"),
        ex("Lunge", 1, 1, 10, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Alternating lunges 30 seconds", "Split Squat"),
        ex("Push-Up with Rotation", 1, 1, 10, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push-up then rotate to side plank", "Push-Up"),
        ex("Side Plank", 1, 1, 10, "15 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Glutes"], "beginner", "Stack feet, lift hips, hold each side", "Forearm Side Plank"),
    ])

def five_min_morning():
    return wo("5-Minute Morning Energizer", "hiit", 5, [
        ex("Jumping Jack", 1, 1, 0, "45 seconds", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Get blood flowing, full range of motion", "Step Jack"),
        ex("Bodyweight Squat", 1, 1, 0, "45 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Wake up legs, continuous squats", "Wall Sit"),
        ex("Push-Up", 1, 1, 0, "45 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Max reps with good form", "Knee Push-Up"),
        ex("Mountain Climber", 1, 1, 0, "45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Moderate pace, drive knees", "Plank March"),
        ex("Burpee", 1, 1, 0, "45 seconds", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Finish strong, max effort", "Squat Thrust"),
    ])

def ten_min_full():
    return wo("10-Minute Full Body", "hiit", 10, [
        ex("Jumping Jack", 1, 1, 15, "45 seconds", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Hip Abductors"], "beginner", "Full range, rhythmic breathing", "Step Jack"),
        ex("Push-Up", 2, 10, 15, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full ROM, chest to floor", "Knee Push-Up"),
        ex("Bodyweight Squat", 2, 15, 15, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full depth each rep", "Wall Sit"),
        ex("Plank", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, straight body", "Forearm Plank"),
        ex("Reverse Lunge", 2, 10, 15, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Alternate legs, controlled motion", "Split Squat"),
        ex("Burpee", 2, 6, 15, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension at top", "Squat Thrust"),
    ])

def fifteen_min_hiit():
    return wo("15-Minute HIIT", "hiit", 15, [
        ex("Burpee", 3, 10, 30, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Chest to floor, jump high, keep moving", "Squat Thrust"),
        ex("Jump Squat", 3, 10, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat deep, explode up, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Fast feet, hips level, drive knees", "Plank March"),
        ex("High Knees", 3, 30, 30, "Bodyweight", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Sprint in place, max height", "March in Place"),
        ex("Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Keep pace up, full ROM", "Knee Push-Up"),
        ex("Tuck Jump", 3, 8, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Jump high, knees to chest, soft land", "Jump Squat"),
    ])

def lunch_break():
    return wo("Lunch Break Workout", "strength", 15, [
        ex("Desk Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands on desk edge, push-up at incline", "Wall Push-Up"),
        ex("Chair Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stand up from chair, sit back down with control", "Bodyweight Squat"),
        ex("Standing Calf Raise", 3, 20, 15, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Rise on toes, hold at top, lower slowly", "Seated Calf Raise"),
        ex("Plank", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "On office floor, tight body", "Forearm Plank"),
        ex("Walking Lunge", 2, 10, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Walk across room in lunges", "Stationary Lunge"),
    ])

def express_core():
    return wo("Express Core", "strength", 10, [
        ex("Plank", 3, 1, 15, "Hold 30-40 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Straight line, no sagging", "Forearm Plank"),
        ex("Bicycle Crunch", 3, 20, 15, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Twist with control, full extension", "Crunch"),
        ex("Dead Bug", 3, 10, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Opposite arm/leg, back stays flat", "Bird Dog"),
        ex("Flutter Kick", 3, 20, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Small kicks, lower back pressed down", "Dead Bug"),
        ex("Side Plank", 2, 1, 15, "Hold 20 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Glutes"], "beginner", "Stack feet, lift hips, straight line", "Forearm Side Plank"),
    ])

def fifteen_min_strength():
    return wo("15-Minute Strength", "strength", 15, [
        ex("Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Slow descent, explosive up", "Knee Push-Up"),
        ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Below parallel, control tempo", "Wall Sit"),
        ex("Inverted Row (Table)", 3, 10, 30, "Bodyweight", "Bodyweight", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Under sturdy table, pull chest up", "Band Row"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "beginner", "Squeeze at top, slow lower", "Single-Leg Bridge"),
        ex("Plank", 2, 1, 30, "Hold 40 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Finish strong, tight core", "Forearm Plank"),
    ])

def twenty_min_total():
    return wo("20-Minute Total Body", "strength", 20, [
        ex("Squat to Press (Imaginary)", 3, 12, 30, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Shoulders", "Glutes"], "beginner", "Squat, stand, press arms overhead", "Bodyweight Squat"),
        ex("Push-Up", 3, 12, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full ROM, steady pace", "Knee Push-Up"),
        ex("Reverse Lunge", 3, 10, 30, "Bodyweight per leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Alternate legs, controlled movement", "Split Squat"),
        ex("Superman", 3, 12, 30, "Bodyweight", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Lift arms and legs, squeeze at top", "Bird Dog"),
        ex("Mountain Climber", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Steady pace, keep hips level", "Plank March"),
        ex("Glute Bridge", 3, 15, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top", "Single-Leg Bridge"),
        ex("Plank", 2, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner", "Strong finish, hold as long as possible", "Forearm Plank"),
    ])

# Quick Cardio Blast
def quick_cardio():
    return wo("Quick Cardio Blast", "hiit", 10, [
        ex("Jumping Jack", 2, 30, 15, "Bodyweight", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full range, quick pace", "Step Jack"),
        ex("High Knees", 2, 30, 15, "Bodyweight", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Sprint in place, max effort", "March in Place"),
        ex("Burpee", 2, 8, 15, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Keep moving, no rest at bottom", "Squat Thrust"),
        ex("Mountain Climber", 2, 20, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Fast feet, drive knees", "Plank March"),
        ex("Squat Jump", 2, 10, 15, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explode up each rep", "Bodyweight Squat"),
    ])

# Busy Parent Workout
def busy_parent():
    return wo("Busy Parent Workout", "strength", 15, [
        ex("Bodyweight Squat", 3, 15, 20, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Quick pace, full depth", "Wall Sit"),
        ex("Push-Up", 3, 10, 20, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Can be on knees, just keep moving", "Knee Push-Up"),
        ex("Plank", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Quick but effective", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 20, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top", "Hip Thrust"),
        ex("Jumping Jack", 2, 25, 15, "Bodyweight", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Get heart rate up", "Step Jack"),
    ])


# ========================================================================
# GENERATE ALL PROGRAMS
# ========================================================================

print("=" * 60)
print("GENERATING CATEGORIES 14-17")
print("=" * 60)

# ---- CATEGORY 14: BODYWEIGHT/HOME ----

cat14_programs = [
    ("No Equipment Needed", "Bodyweight/Home", [1, 2, 4, 8], [4, 5],
     "Pure bodyweight training requiring zero equipment - effective anywhere",
     "High", lambda w, t: [no_equip_upper(), no_equip_lower(), no_equip_full(), no_equip_core()]),

    ("Minimal Equipment", "Bodyweight/Home", [2, 4, 8], [4, 5],
     "Effective training with just resistance bands and dumbbells",
     "High", lambda w, t: [minimal_equip_upper(), minimal_equip_lower(), minimal_equip_full(), minimal_equip_upper()]),

    ("Park Workout", "Bodyweight/Home", [2, 4, 8], [3, 4],
     "Outdoor calisthenics using park benches and bars",
     "High", lambda w, t: [park_upper(), park_lower(), park_upper()]),

    ("Hotel Room Fitness", "Bodyweight/Home", [1, 2], [4, 5],
     "No-equipment travel workouts that fit in any hotel room",
     "Medium", lambda w, t: [hotel_full_a(), hotel_full_b(), hotel_full_a(), hotel_full_b()]),

    ("Garage Gym Basics", "Bodyweight/Home", [2, 4, 8], [4, 5],
     "Limited equipment home gym training with barbell and dumbbells",
     "High", lambda w, t: [garage_upper(), garage_lower(), garage_upper(), garage_lower()]),

    ("Prison Style Workout", "Bodyweight/Home", [2, 4, 8], [5, 6],
     "High-rep bodyweight training in minimal space - builds raw endurance and strength",
     "Medium", lambda w, t: [prison_push(), prison_pull(), prison_legs(), prison_push(), prison_pull()]),

    ("Backyard Bootcamp", "Bodyweight/Home", [2, 4, 8], [4, 5],
     "Outdoor home training combining cardio and bodyweight strength",
     "Medium", lambda w, t: [backyard_a(), backyard_b(), backyard_a(), backyard_b()]),

    ("Playground Fitness", "Bodyweight/Home", [2, 4, 8], [3, 4],
     "Parent-friendly outdoor workouts using playground equipment",
     "Medium", lambda w, t: [playground_a(), playground_b(), playground_a()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat14_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: master basic movements, build consistency"
            elif p <= 0.66: focus = f"Week {w} - Build: increase reps and intensity"
            else: focus = f"Week {w} - Peak: advanced variations, max effort sets"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"OK: {prog_name}")

print("\n--- Category 14 done ---\n")

# ---- CATEGORY 15: ENDURANCE ----

cat15_programs = [
    ("Cardio Base Builder", "Endurance", [4, 8, 12], [4, 5],
     "Build an aerobic foundation with progressive cardio training",
     "High", lambda w, t: [cardio_base_a(), cardio_base_b(), cardio_base_c(), cardio_base_a()]),

    ("Stamina & Conditioning", "Endurance", [4, 8], [4, 5],
     "Build work capacity and metabolic conditioning",
     "High", lambda w, t: [stamina_circuit(), stamina_endurance(), stamina_circuit(), stamina_endurance()]),

    ("Heart Health Cardio", "Endurance", [4, 8, 12], [4, 5],
     "Cardiovascular-focused program for heart health and longevity",
     "High", lambda w, t: [heart_health_a(), heart_health_b(), heart_health_a(), heart_health_b()]),

    ("Stair Climbing", "Endurance", [2, 4], [3, 4],
     "Vertical cardio using stairs for lower body endurance and conditioning",
     "Medium", lambda w, t: [stair_climb_a(), stair_climb_b(), stair_climb_a()]),

    ("Low Intensity Steady State", "Endurance", [2, 4, 8], [4, 5],
     "Zone 2 training for building aerobic base and fat oxidation",
     "Medium", lambda w, t: [liss_a(), liss_b(), liss_a(), liss_b()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat15_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Base: build aerobic foundation, easy effort"
            elif p <= 0.66: focus = f"Week {w} - Build: increase duration and moderate intensity"
            else: focus = f"Week {w} - Peak: longer sessions, higher intensity intervals"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"OK: {prog_name}")

# Running programs with dynamic workouts
running_programs = [
    ("Beginner 5K Running", "Endurance", [9], [3],
     "Couch to 5K style progressive running program for complete beginners",
     "High", run_5k_wo),

    ("Beginner 10K Running", "Endurance", [12, 14], [4],
     "Extended running program building from 5K to 10K distance",
     "High", run_10k_wo),

    ("5K to Half Marathon", "Endurance", [12], [4, 5],
     "Intermediate running program progressing from 5K to half marathon distance",
     "Medium", half_marathon_wo),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in running_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            wkts = []
            for s_idx in range(max(sessions_list)):
                wkts.append(workout_fn(w, dur))
            weeks[w] = {"focus": f"Week {w}", "workouts": wkts}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"OK: {prog_name}")

print("\n--- Category 15 done ---\n")

# ---- CATEGORY 16: CALISTHENICS ----

cat16_programs = [
    ("Calisthenics Fundamentals", "Calisthenics", [2, 4, 8, 12], [3, 4],
     "Beginner bodyweight mastery - learn push, pull, squat, and core fundamentals",
     "High", lambda w, t: [cali_fund_push(), cali_fund_pull(), cali_fund_legs()]),

    ("Calisthenics Strength", "Calisthenics", [4, 8, 12], [3, 4],
     "Building raw bodyweight strength with progressive calisthenics",
     "High", lambda w, t: [cali_str_upper(), cali_str_lower(), cali_str_upper()]),

    ("Street Workout", "Calisthenics", [4, 8, 12], [4, 5],
     "Park and outdoor calisthenics for impressive bodyweight skills",
     "High", lambda w, t: [street_push(), street_pull(), cali_fund_legs(), street_push()]),

    ("Gymnastics Foundations", "Calisthenics", [4, 8, 12], [4, 5],
     "Gymnastic rings and floor skills for strength and body control",
     "High", lambda w, t: [gym_rings(), gym_floor(), gym_rings(), gym_floor()]),

    ("Calisthenics for Beginners", "Calisthenics", [2, 4, 8], [3],
     "Zero to hero calisthenics for absolute beginners",
     "High", lambda w, t: [cali_beg_a(), cali_beg_b(), cali_beg_a()]),

    ("Ring Training", "Calisthenics", [4, 8], [3, 4],
     "Gymnastic rings focused program for upper body and core mastery",
     "Medium", lambda w, t: [ring_upper(), ring_core(), ring_upper()]),

    ("Bar Athletes", "Calisthenics", [4, 8, 12], [4, 5],
     "Pull-up bar mastery - from basics to advanced bar skills",
     "Medium", lambda w, t: [bar_pull(), bar_push(), bar_pull(), bar_push()]),

    ("Skills Unlocked", "Calisthenics", [4, 8, 12, 16], [4, 5],
     "Unlock advanced skills: muscle-up, handstand, front lever, and more",
     "Medium", lambda w, t: [skills_a(), skills_b(), cali_str_upper(), skills_a()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat16_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: learn movements, build base strength"
            elif p <= 0.66: focus = f"Week {w} - Progression: harder variations, more volume"
            else: focus = f"Week {w} - Mastery: advanced skills, peak performance"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"OK: {prog_name}")

print("\n--- Category 16 done ---\n")

# ---- CATEGORY 17: QUICK WORKOUTS ----

cat17_programs = [
    ("7-Minute Scientific", "Quick Workouts", [1, 2, 4], [5, 6, 7],
     "Original science-backed high-intensity circuit training in just 7 minutes",
     "High", lambda w, t: [seven_min()]),

    ("5-Minute Morning", "Quick Workouts", [1, 2, 4], [7],
     "Quick wake-up energizer to start every day with movement",
     "High", lambda w, t: [five_min_morning()]),

    ("10-Minute Full Body", "Quick Workouts", [1, 2, 4], [5, 6],
     "Quick but complete full body workout covering all major movement patterns",
     "High", lambda w, t: [ten_min_full()]),

    ("15-Minute HIIT", "Quick Workouts", [1, 2, 4], [4, 5],
     "Quick high-intensity interval training for maximum calorie burn",
     "High", lambda w, t: [fifteen_min_hiit()]),

    ("Lunch Break Workout", "Quick Workouts", [1, 2, 4], [5],
     "Office-friendly 15-minute workout perfect for lunch breaks",
     "Medium", lambda w, t: [lunch_break()]),

    ("Express Core", "Quick Workouts", [1, 2], [5, 6],
     "10-minute focused core workout for a stronger midsection",
     "Medium", lambda w, t: [express_core()]),

    ("15-Minute Strength", "Quick Workouts", [1, 2, 4], [4, 5],
     "Brief but effective strength training hitting all major muscle groups",
     "Medium", lambda w, t: [fifteen_min_strength()]),

    ("20-Minute Total Body", "Quick Workouts", [1, 2, 4], [4, 5],
     "Slightly longer option for a thorough full-body training session",
     "Medium", lambda w, t: [twenty_min_total()]),

    ("Quick Cardio Blast", "Quick Workouts", [1, 2], [4, 5],
     "10-minute heart-pumping cardio session for when time is tight",
     "Low", lambda w, t: [quick_cardio()]),

    ("Busy Parent Workout", "Quick Workouts", [1, 2, 4], [4, 5],
     "Naptime-friendly quick fitness for busy parents",
     "Low", lambda w, t: [busy_parent()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in cat17_programs:
    if helper.check_program_exists(prog_name):
        print(f"SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Start: build the habit, learn the format"
            elif p <= 0.66: focus = f"Week {w} - Progress: faster pace, less rest, more reps"
            else: focus = f"Week {w} - Push: maximum effort, beat your personal best"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"OK: {prog_name}")

print("\n--- Category 17 done ---\n")

helper.close()
print("\n=== CATEGORIES 14-17 COMPLETE ===")
