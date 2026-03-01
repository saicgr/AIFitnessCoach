#!/usr/bin/env python3
"""Generate Quick Workouts (17), Warmup & Cooldown (25), Targeted Stretching (26), and Face & Jaw (31)."""
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

# ========== QUICK WORKOUTS ==========
def seven_min_scientific():
    return wo("7-Minute Scientific Workout", "hiit", 7, [
        ex("Jumping Jacks", 1, 30, 10, "30 seconds", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Full arm extension, land soft", "Step Jacks"),
        ex("Wall Sit", 1, 1, 10, "30 seconds hold", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Thighs parallel, back flat on wall", "Chair Pose"),
        ex("Push-up", 1, 12, 10, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range, elbows 45 degrees", "Knee Push-up"),
        ex("Crunch", 1, 15, 10, "30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Curl shoulders off ground, exhale up", "Dead Bug"),
        ex("Step-up", 1, 12, 10, "30 seconds, alternating", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Drive through top foot fully", "Bodyweight Squat"),
        ex("Bodyweight Squat", 1, 15, 10, "30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, chest up", "Chair Squat"),
        ex("Tricep Dip", 1, 12, 10, "30 seconds", "Chair", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Elbows back, controlled descent", "Close-Grip Push-up"),
        ex("Plank", 1, 1, 10, "30 seconds hold", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line, squeeze everything", "Forearm Plank"),
        ex("High Knees", 1, 30, 10, "30 seconds", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees above hip height", "Marching"),
        ex("Lunge", 1, 12, 10, "30 seconds alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Knee tracks toe, upright torso", "Reverse Lunge"),
        ex("Push-up with Rotation", 1, 10, 10, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Shoulders"], "intermediate", "Push up, rotate to side plank", "Push-up"),
        ex("Side Plank", 1, 1, 0, "15 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders"], "beginner", "Stack feet, lift hips, hold", "Modified Side Plank"),
    ])

def five_min_morning():
    return wo("5-Minute Morning Energizer", "flexibility", 5, [
        ex("Cat-Cow", 1, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("World's Greatest Stretch", 1, 5, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach up", "Spiderman Stretch"),
        ex("Bodyweight Squat", 1, 10, 0, "Wake up legs", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, arms forward", "Chair Squat"),
        ex("Arm Circles", 1, 10, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, get bigger", "Shoulder Roll"),
        ex("Jumping Jacks", 1, 20, 0, "Get heart rate up", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full extension, energetic pace", "Step Jacks"),
    ])

def ten_min_full_body():
    return wo("10-Minute Full Body Blast", "strength", 10, [
        ex("Bodyweight Squat", 2, 15, 15, "Quick tempo", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, chest up", "Chair Squat"),
        ex("Push-up", 2, 10, 15, "Controlled", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range of motion", "Knee Push-up"),
        ex("Reverse Lunge", 2, 10, 15, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Step Back"),
        ex("Plank", 2, 1, 15, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line from head to heels", "Forearm Plank"),
        ex("Mountain Climber", 2, 20, 15, "Quick pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders", "Quadriceps"], "beginner", "Hands under shoulders, drive knees", "Plank Knee Tuck"),
        ex("Superman", 2, 10, 0, "Hold 2 seconds at top", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Lift arms and legs simultaneously", "Bird Dog"),
    ])

def fifteen_min_hiit():
    return wo("15-Minute HIIT", "hiit", 15, [
        ex("Burpee", 3, 8, 30, "40 seconds work, 20 rest", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump up, full extension", "Squat Thrust"),
        ex("Jump Squat", 3, 12, 30, "40 seconds work", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, explode up, soft landing", "Bodyweight Squat"),
        ex("Mountain Climber", 3, 20, 30, "40 seconds work", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "beginner", "Quick alternating knees, hands stable", "High Knees"),
        ex("Push-up to Shoulder Tap", 3, 10, 30, "40 seconds work", "Bodyweight", "Chest", "Pectoralis Major", ["Core", "Triceps"], "intermediate", "Push up, tap opposite shoulder, alternate", "Push-up"),
        ex("Tuck Jump", 3, 8, 30, "40 seconds work", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Jump, tuck knees to chest, land soft", "Jump Squat"),
    ])

def lunch_break():
    return wo("Lunch Break Workout", "strength", 20, [
        ex("Bodyweight Squat", 3, 15, 30, "No equipment needed", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, chest up", "Wall Sit"),
        ex("Push-up", 3, 12, 30, "Standard or desk push-up", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range, controlled", "Incline Push-up"),
        ex("Walking Lunge", 3, 10, 30, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Upright torso, long stride", "Reverse Lunge"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, straight body", "Forearm Plank"),
        ex("Chair Dip", 3, 10, 30, "Use office chair or desk", "Chair", "Arms", "Triceps", ["Anterior Deltoid"], "beginner", "Elbows straight back, controlled", "Diamond Push-up"),
    ])

def express_core():
    return wo("Express Core Blast", "strength", 10, [
        ex("Plank", 2, 1, 15, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Straight line, tight core", "Forearm Plank"),
        ex("Bicycle Crunch", 2, 20, 15, "Alternating", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Elbow to opposite knee, slow", "Crunch"),
        ex("Leg Raise", 2, 12, 15, "Controlled", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Lower legs slowly, don't arch back", "Bent-Knee Leg Raise"),
        ex("Russian Twist", 2, 20, 15, "Alternate sides", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet elevated, rotate from torso", "Seated Twist"),
        ex("Dead Bug", 2, 10, 0, "Alternating", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Lower opposite arm/leg, back flat", "Bird Dog"),
    ])

def quick_cardio():
    return wo("Quick Cardio Blast", "conditioning", 10, [
        ex("Jumping Jacks", 2, 30, 15, "Quick pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension", "Step Jacks"),
        ex("High Knees", 2, 30, 15, "Fast tempo", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "beginner", "Drive knees high", "Marching"),
        ex("Butt Kicks", 2, 30, 15, "Quick pace", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Kick heels to glutes", "Jog in Place"),
        ex("Squat Jump", 2, 10, 15, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, jump, soft landing", "Bodyweight Squat"),
        ex("Burpee", 2, 6, 15, "Full burpee", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, jump up", "Squat Thrust"),
    ])

def busy_parent():
    return wo("Busy Parent Quick Workout", "strength", 15, [
        ex("Bodyweight Squat", 2, 15, 20, "While kids play", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, stay engaged", "Chair Squat"),
        ex("Push-up", 2, 10, 20, "Any surface works", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range of motion", "Wall Push-up"),
        ex("Glute Bridge", 2, 15, 20, "On the floor", "Bodyweight", "Legs", "Glutes", ["Hamstrings"], "beginner", "Squeeze at top, hold 2 sec", "Hip Thrust"),
        ex("Plank", 2, 1, 20, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Keep it simple and effective", "Forearm Plank"),
        ex("Reverse Lunge", 2, 10, 0, "Alternating legs", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Step back, knee hovers", "Step Back"),
    ])

quick_programs = [
    ("7-Minute Scientific", "Quick Workouts", [1, 2, 4], [7], "High", "The research-backed 7-minute high-intensity circuit workout",
     lambda w, t: [seven_min_scientific()] * 7),
    ("5-Minute Morning", "Quick Workouts", [1, 2, 4], [7], "High", "Quick 5-minute morning energizer to start your day right",
     lambda w, t: [five_min_morning()] * 7),
    ("10-Minute Full Body", "Quick Workouts", [1, 2, 4], [5, 6], "High", "Efficient 10-minute full body workout for busy schedules",
     lambda w, t: [ten_min_full_body()] * 6),
    ("15-Minute HIIT", "Quick Workouts", [1, 2, 4], [4, 5], "High", "High intensity interval training in just 15 minutes",
     lambda w, t: [fifteen_min_hiit()] * 5),
    ("Lunch Break Workout", "Quick Workouts", [1, 2, 4], [5], "Med", "20-minute no-equipment workout for your lunch break",
     lambda w, t: [lunch_break()] * 5),
    ("Express Core", "Quick Workouts", [1, 2, 4], [5, 6], "Med", "10-minute focused core strengthening routine",
     lambda w, t: [express_core()] * 6),
    ("Quick Cardio Blast", "Quick Workouts", [1, 2], [5, 6], "Low", "10-minute all-cardio quick session",
     lambda w, t: [quick_cardio()] * 6),
    ("Busy Parent Workout", "Quick Workouts", [1, 2, 4], [3, 4], "Low", "15-minute workout designed for busy parents",
     lambda w, t: [busy_parent()] * 4),
]

# ========== WARMUP & COOLDOWN ==========
def five_min_warmup():
    return wo("5-Min Dynamic Warmup", "warmup", 5, [
        ex("Arm Circles", 1, 10, 0, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, get bigger", "Shoulder Roll"),
        ex("Leg Swing Forward", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings"], "beginner", "Hold support, swing front to back", "Standing Leg Raise"),
        ex("Torso Twist", 1, 10, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Erector Spinae"], "beginner", "Rotate from thoracic spine", "Seated Twist"),
        ex("Bodyweight Squat", 1, 8, 0, "Slow and controlled", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Focus on depth and form", "Half Squat"),
        ex("High Knees", 1, 20, 0, "Moderate pace", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Gradually increase pace", "Marching"),
    ])

def ten_min_warmup():
    return wo("10-Min Full Warmup", "warmup", 10, [
        ex("Jog in Place", 1, 1, 0, "2 minutes", "Bodyweight", "Legs", "Quadriceps", ["Calves"], "beginner", "Light pace, arm swing", "Marching"),
        ex("Arm Circles", 1, 15, 0, "Forward then backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Progressively bigger circles", "Shoulder Roll"),
        ex("Leg Swing Lateral", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Abductors", ["Hip Adductors"], "beginner", "Hold support, swing side to side", "Lateral Lunge"),
        ex("Inchworm", 1, 5, 0, "Walk hands out and back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Keep legs straight as possible", "Forward Fold"),
        ex("World's Greatest Stretch", 1, 4, 0, "Each side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine"], "beginner", "Lunge, elbow to instep, rotate", "Spiderman Stretch"),
        ex("Bodyweight Squat", 1, 10, 0, "Full depth", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Controlled tempo, pause at bottom", "Chair Squat"),
        ex("High Knees", 1, 20, 0, "Building intensity", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Drive knees above hip height", "Marching"),
    ])

def strength_warmup():
    return wo("Strength Training Warmup", "warmup", 10, [
        ex("Band Pull-Apart", 2, 15, 0, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Pull band to chest height, squeeze blades", "Face Pull"),
        ex("Cat-Cow", 1, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Mobilize entire spine", "Seated Cat-Cow"),
        ex("Goblet Squat Hold", 1, 5, 0, "Hold bottom for 5 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors"], "beginner", "Elbows push knees out", "Bodyweight Squat"),
        ex("Glute Bridge", 1, 15, 0, "Activate glutes", "Bodyweight", "Legs", "Glutes", ["Hamstrings"], "beginner", "Squeeze at top, hold 2 seconds", "Hip Thrust"),
        ex("Dead Bug", 1, 10, 0, "Alternate sides", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Back flat on floor throughout", "Bird Dog"),
        ex("Arm Bar", 1, 5, 0, "Each side", "Bodyweight", "Shoulders", "Rotator Cuff", ["Core"], "beginner", "Slow controlled rotation", "Shoulder Circle"),
    ])

def cardio_warmup():
    return wo("Cardio Warmup", "warmup", 8, [
        ex("Marching in Place", 1, 30, 0, "2 minutes easy pace", "Bodyweight", "Legs", "Hip Flexors", ["Calves"], "beginner", "Arms swinging, build pace gradually", "Walking"),
        ex("Side Step", 1, 20, 0, "Each direction", "Bodyweight", "Legs", "Hip Abductors", ["Calves"], "beginner", "Light step side to side", "Lateral Shuffle"),
        ex("Leg Swing Forward", 1, 10, 0, "Each leg", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings"], "beginner", "Progressive range increase", "Standing Leg Raise"),
        ex("Jumping Jacks", 1, 20, 0, "Moderate pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "Full arm extension", "Step Jacks"),
        ex("Butt Kicks", 1, 20, 0, "Building pace", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Kick heels to glutes", "Jog in Place"),
    ])

def cooldown_5min():
    return wo("5-Min Cooldown Stretch", "flexibility", 5, [
        ex("Standing Forward Fold", 1, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold from hips, let head hang", "Ragdoll"),
        ex("Quad Stretch", 1, 1, 0, "30 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, stand tall", "Lying Quad Stretch"),
        ex("Chest Opener", 1, 1, 0, "30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Clasp hands behind, open chest", "Doorway Stretch"),
        ex("Child's Pose", 1, 1, 0, "30 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, reach forward", "Puppy Pose"),
        ex("Deep Breathing", 1, 5, 0, "5 deep breaths", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "4 count in, 6 count out", "Box Breathing"),
    ])

def cooldown_10min():
    return wo("10-Min Recovery Cooldown", "flexibility", 10, [
        ex("Standing Forward Fold", 1, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold from hips, relax head", "Seated Forward Fold"),
        ex("Pigeon Stretch", 1, 1, 0, "45 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Hip Flexors"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Cat-Cow", 1, 10, 0, "Slow flow", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Child's Pose", 1, 1, 0, "60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Wide knees, reach forward", "Puppy Pose"),
        ex("Supine Twist", 1, 1, 0, "45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Knees to side, look opposite", "Seated Twist"),
        ex("Neck Stretch", 1, 1, 0, "30 seconds each side", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder, gentle pull", "Neck Roll"),
        ex("Savasana", 1, 1, 0, "2 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Complete relaxation, deep breathing", "Seated Meditation"),
    ])

warmup_programs = [
    ("5-Min Dynamic Warmup", "Warmup & Cooldown", [1, 2], [7], "High", "Quick 5-minute dynamic warmup for any workout",
     lambda w, t: [five_min_warmup()] * 7),
    ("10-Min Full Warmup", "Warmup & Cooldown", [1, 2], [5, 6, 7], "High", "Comprehensive 10-minute warmup routine",
     lambda w, t: [ten_min_warmup()] * 7),
    ("Strength Training Warmup", "Warmup & Cooldown", [1, 2], [3, 4, 5], "High", "Pre-strength training activation and mobility",
     lambda w, t: [strength_warmup()] * 5),
    ("Cardio Warmup", "Warmup & Cooldown", [1, 2], [5, 6, 7], "Med", "Progressive warmup before cardio sessions",
     lambda w, t: [cardio_warmup()] * 7),
    ("5-Min Cooldown Stretch", "Warmup & Cooldown", [1, 2], [5, 6, 7], "Med", "Quick post-workout cooldown stretching",
     lambda w, t: [cooldown_5min()] * 7),
    ("10-Min Recovery Cooldown", "Warmup & Cooldown", [1, 2], [5, 6, 7], "Med", "Extended recovery cooldown routine",
     lambda w, t: [cooldown_10min()] * 7),
    ("Post-Strength Cooldown", "Warmup & Cooldown", [1, 2], [3, 4, 5], "Med", "Cooldown specifically for after strength training",
     lambda w, t: [cooldown_10min()] * 5),
    ("Sport-Specific Warmup", "Warmup & Cooldown", [1, 2], [4, 5], "Med", "Dynamic warmup tailored for sport performance",
     lambda w, t: [ten_min_warmup()] * 5),
    ("Post-Cardio Cooldown", "Warmup & Cooldown", [1, 2], [5, 6], "Low", "Cooldown routine after cardio sessions",
     lambda w, t: [cooldown_5min()] * 6),
    ("Active Recovery Day", "Warmup & Cooldown", [1, 2, 4], [2, 3], "Low", "Light movement day between intense training",
     lambda w, t: [cooldown_10min()] * 3),
    ("Pre-Game Activation", "Warmup & Cooldown", [1, 2], [3, 4], "Low", "Pre-competition activation and warmup",
     lambda w, t: [ten_min_warmup()] * 4),
    ("Travel Recovery Routine", "Warmup & Cooldown", [1, 2], [5, 7], "Low", "Recovery stretching for travel days",
     lambda w, t: [cooldown_10min()] * 7),
]

# ========== TARGETED STRETCHING ==========
def upper_body_stretch():
    return wo("Upper Body Stretch", "flexibility", 15, [
        ex("Chest Doorway Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm at 90 in doorway, lean through", "Chest Opener"),
        ex("Cross-Body Shoulder Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Rhomboids"], "beginner", "Pull arm across chest, hold gently", "Thread the Needle"),
        ex("Tricep Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Arms", "Triceps", ["Latissimus Dorsi"], "beginner", "Arm overhead, elbow bent, push gently", "Lat Stretch"),
        ex("Wrist Flexor Stretch", 2, 1, 0, "Hold 20 seconds each", "Bodyweight", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Extend arm, pull fingers back", "Wrist Circles"),
        ex("Neck Side Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Neck", "Trapezius", ["Scalenes"], "beginner", "Ear to shoulder, gentle hand pressure", "Neck Roll"),
        ex("Thread the Needle", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Back", "Rhomboids", ["Thoracic Spine"], "beginner", "Reach under body, rotate thoracic", "Cat-Cow"),
    ])

def lower_body_stretch():
    return wo("Lower Body Stretch", "flexibility", 15, [
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to glute, knees together", "Lying Quad Stretch"),
        ex("Standing Hamstring Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on low surface, hinge forward", "Seated Forward Fold"),
        ex("Hip Flexor Lunge Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Half kneeling, push hips forward", "Standing Hip Flexor"),
        ex("Pigeon Stretch", 2, 1, 0, "Hold 45 seconds each", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Square hips, fold forward gently", "Figure-4 Stretch"),
        ex("Calf Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Wall lean, back leg straight, heel down", "Step Calf Stretch"),
        ex("IT Band Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "IT Band", ["Hip Abductors"], "beginner", "Cross legs, lean toward back leg side", "Foam Roll IT Band"),
    ])

def hamstring_deep():
    return wo("Hamstring Deep Stretch", "flexibility", 15, [
        ex("Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold from hips, let gravity pull", "Ragdoll"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Reach for toes, keep back flat initially", "Towel Hamstring Stretch"),
        ex("Single-Leg Forward Fold", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Foot on low surface, hinge from hips", "Standing Hamstring Stretch"),
        ex("Supine Hamstring Stretch", 2, 1, 0, "Hold 45 seconds each", "Bodyweight", "Legs", "Hamstrings", [], "beginner", "Lying down, leg up with strap or hands", "Towel Hamstring Stretch"),
        ex("Downward Dog", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Full Body", "Hamstrings", ["Calves", "Shoulders"], "beginner", "Push floor away, heels toward ground", "Puppy Pose"),
    ])

stretch_programs = [
    ("Upper Body Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "High", "Focused stretching routine for chest, shoulders, arms, and neck",
     lambda w, t: [upper_body_stretch()] * 5),
    ("Lower Body Stretch", "Targeted Stretching", [1, 2, 4], [4, 5], "High", "Complete lower body stretching for quads, hamstrings, hips, and calves",
     lambda w, t: [lower_body_stretch()] * 5),
    ("Hamstring Deep Stretch", "Targeted Stretching", [1, 2, 4], [5, 6], "Med", "Progressive hamstring flexibility work",
     lambda w, t: [hamstring_deep()] * 6),
    ("Hip Flexor Release", "Targeted Stretching", [1, 2, 4], [5, 6], "Med", "Hip flexor stretching for desk workers and runners",
     lambda w, t: [lower_body_stretch()] * 6),
    ("Glute & Piriformis Release", "Targeted Stretching", [1, 2, 4], [4, 5], "Med", "Deep glute and piriformis stretching",
     lambda w, t: [lower_body_stretch()] * 5),
    ("Thoracic Spine Mobility", "Targeted Stretching", [1, 2, 4], [5, 6], "Med", "Thoracic spine rotation and extension mobility",
     lambda w, t: [upper_body_stretch()] * 6),
    ("Shoulder Mobility", "Targeted Stretching", [1, 2, 4], [5, 6], "Med", "Shoulder mobility and flexibility routine",
     lambda w, t: [upper_body_stretch()] * 6),
    ("Ankle Mobility", "Targeted Stretching", [1, 2, 4], [5, 6], "Low", "Ankle dorsiflexion and mobility work",
     lambda w, t: [lower_body_stretch()] * 6),
    ("Wrist & Forearm Mobility", "Targeted Stretching", [1, 2], [5, 6], "Low", "Wrist and forearm stretching for desk workers and lifters",
     lambda w, t: [upper_body_stretch()] * 6),
    ("IT Band & TFL Release", "Targeted Stretching", [1, 2, 4], [4, 5], "Low", "IT band and tensor fasciae latae release",
     lambda w, t: [lower_body_stretch()] * 5),
    ("Neck & Trap Release", "Targeted Stretching", [1, 2], [5, 7], "Low", "Neck and trapezius tension release",
     lambda w, t: [upper_body_stretch()] * 7),
    ("Neck Stretch Series", "Targeted Stretching", [1, 2], [5, 7], "Low", "Comprehensive neck stretching routine",
     lambda w, t: [upper_body_stretch()] * 7),
    ("Jaw & TMJ Relief", "Targeted Stretching", [1, 2], [5, 7], "Low", "Jaw tension and TMJ relief exercises",
     lambda w, t: [upper_body_stretch()] * 7),
]

# ========== FACE & JAW ==========
def face_yoga_basic():
    return wo("Face Yoga Basics", "face_yoga", 10, [
        ex("Forehead Smoother", 2, 10, 0, "Hold 10 seconds", "Bodyweight", "Face", "Frontalis", ["Temporalis"], "beginner", "Place fingers on forehead, raise brows against resistance", "Brow Raise"),
        ex("Cheek Lifter", 2, 10, 0, "Hold 5 seconds each", "Bodyweight", "Face", "Zygomaticus", ["Buccinator"], "beginner", "Smile wide, press fingers on cheeks, lift", "Smile Exercise"),
        ex("Jaw Release", 2, 10, 0, "Hold 5 seconds", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Open mouth wide, move jaw side to side", "Jaw Circle"),
        ex("Lip Puller", 2, 10, 0, "Hold 10 seconds", "Bodyweight", "Face", "Orbicularis Oris", ["Mentalis"], "beginner", "Pull lower lip over upper, tilt chin up", "Fish Face"),
        ex("Neck Firmer", 2, 10, 0, "Hold 10 seconds", "Bodyweight", "Neck", "Platysma", ["SCM"], "beginner", "Tilt head back, press tongue to roof of mouth", "Chin Tuck"),
        ex("Eye Firmer", 2, 10, 0, "Hold 5 seconds", "Bodyweight", "Face", "Orbicularis Oculi", [], "beginner", "Place fingers at outer corners, squint gently", "Eye Circle"),
    ])

def jawline_definition():
    return wo("Jawline Definition", "face_yoga", 10, [
        ex("Chin Lift", 3, 10, 0, "Hold 5 seconds", "Bodyweight", "Face", "Mentalis", ["Platysma"], "beginner", "Tilt head up, push lower jaw forward", "Neck Extension"),
        ex("Jaw Clench", 3, 10, 0, "Hold 5 seconds", "Bodyweight", "Face", "Masseter", ["Temporalis"], "beginner", "Clench jaw firmly, release slowly", "Gum Chewing"),
        ex("Tongue Press", 3, 10, 0, "Hold 10 seconds", "Bodyweight", "Face", "Tongue Muscles", ["Submental"], "beginner", "Press tongue hard against roof of mouth", "Mewing"),
        ex("Neck Resistance", 3, 10, 0, "Hold 5 seconds each direction", "Bodyweight", "Neck", "SCM", ["Trapezius"], "beginner", "Hand on forehead, push head against hand", "Neck Isometric"),
        ex("Fish Face", 3, 10, 0, "Hold 10 seconds", "Bodyweight", "Face", "Buccinator", ["Zygomaticus"], "beginner", "Suck cheeks in, try to smile", "Cheek Puff"),
    ])

def double_chin():
    return wo("Double Chin Reduction", "face_yoga", 10, [
        ex("Chin Tuck", 3, 15, 0, "Hold 5 seconds", "Bodyweight", "Neck", "Deep Neck Flexors", ["SCM"], "beginner", "Pull chin straight back, creating double chin", "Neck Retraction"),
        ex("Tongue Press Ceiling", 3, 10, 0, "Hold 10 seconds", "Bodyweight", "Face", "Suprahyoid", ["Tongue Muscles"], "beginner", "Press tongue to roof, look up", "Tongue Press"),
        ex("Neck Roll", 2, 5, 0, "Each direction", "Bodyweight", "Neck", "SCM", ["Trapezius", "Scalenes"], "beginner", "Slow controlled circles", "Neck Stretch"),
        ex("Jaw Forward Push", 3, 10, 0, "Hold 5 seconds", "Bodyweight", "Face", "Pterygoid", ["Masseter"], "beginner", "Push lower jaw forward, feel stretch under chin", "Chin Lift"),
        ex("Platysma Exercise", 3, 10, 0, "Hold 5 seconds", "Bodyweight", "Neck", "Platysma", ["Mentalis"], "beginner", "Pull corners of mouth down tightly", "Neck Firmer"),
    ])

face_programs = [
    ("Face Yoga Basics", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "High", "Introduction to face yoga for facial toning and relaxation",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Jawline Definition", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "High", "Exercises targeting jawline definition and neck firming",
     lambda w, t: [jawline_definition()] * 7),
    ("Double Chin Reduction", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "High", "Targeted exercises to reduce double chin appearance",
     lambda w, t: [double_chin()] * 7),
    ("Cheek Slimming", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Med", "Exercises for cheek toning and slimming",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Mewing Practice", "Face & Jaw Exercises", [2, 4, 8], [7], "Med", "Proper tongue posture and mewing technique practice",
     lambda w, t: [jawline_definition()] * 7),
    ("Face Lift Exercises", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Med", "Natural face lift exercises for facial muscles",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Neck & Jawline Combo", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Med", "Combined neck and jawline toning routine",
     lambda w, t: [jawline_definition()] * 7),
    ("TMJ Relief Exercises", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Med", "Gentle exercises for TMJ pain and tension relief",
     lambda w, t: [double_chin()] * 7),
    ("Facial Symmetry Training", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Low", "Exercises to improve facial muscle balance",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Eye Area Exercises", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Low", "Under-eye and crow's feet area exercises",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Forehead & Brow Workout", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Low", "Forehead smoothing and brow lifting exercises",
     lambda w, t: [face_yoga_basic()] * 7),
    ("Full Face Workout", "Face & Jaw Exercises", [2, 4, 8], [5, 7], "Low", "Complete facial exercise routine targeting all areas",
     lambda w, t: [face_yoga_basic()] * 7),
]

# ========== GENERATE ALL ==========
all_programs = quick_programs + warmup_programs + stretch_programs + face_programs

for prog_name, cat, durs, sessions_list, pri, desc, workout_fn in all_programs:
    if helper.check_program_exists(prog_name):
        print(f"{prog_name} - ALREADY EXISTS, skipping")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Introduction: learn movements and build habit"
            elif p <= 0.66: focus = f"Week {w} - Development: increase duration and intensity"
            else: focus = f"Week {w} - Mastery: refine technique and maximize benefit"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

helper.close()
print("\n=== QUICK + WARMUP + STRETCH + FACE COMPLETE ===")
