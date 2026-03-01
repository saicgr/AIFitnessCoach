#!/usr/bin/env python3
"""Generate Hell Mode (29), Dance Fitness (30), Posture Correction (32), Sedentary/Couch (33), Occupation (34)."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(n, s, r, rest, w, eq, bp, pm, sm, d, cue, sub):
    return {"name": n, "exercise_library_id": None, "in_library": False,
            "sets": s, "reps": r, "rest_seconds": rest, "weight_guidance": w,
            "equipment": eq, "body_part": bp, "primary_muscle": pm,
            "secondary_muscles": sm, "difficulty": d, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ===== HELL MODE =====
def hell_full_body():
    return wo("Hell Mode Full Body", "hell_mode", 60, [
        ex("Burpee", 5, 15, 30, "Maximum effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Chest to floor, explosive jump", "Squat Thrust"),
        ex("Barbell Thruster", 4, 15, 45, "60-70% 1RM", "Barbell", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "advanced", "Front squat to overhead press in one motion", "Dumbbell Thruster"),
        ex("Pull-up", 4, 12, 45, "Add weight if needed", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full dead hang to chin over bar", "Lat Pulldown"),
        ex("Box Jump", 4, 15, 30, "24-30 inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive jump, soft landing", "Squat Jump"),
        ex("Kettlebell Swing", 4, 25, 30, "Heavy KB", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip hinge, snap hips, float KB", "Dumbbell Swing"),
        ex("Battle Rope Slam", 3, 30, 30, "30 seconds", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Back"], "intermediate", "Alternate arms, maximum intensity", "Medicine Ball Slam"),
        ex("Mountain Climber", 3, 40, 20, "Sprint pace", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "intermediate", "Rapid alternating knees", "High Knees"),
        ex("Barbell Row", 4, 12, 45, "70% 1RM", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to lower chest", "Dumbbell Row"),
    ])

def hell_upper():
    return wo("Hell Mode Upper Body", "hell_mode", 55, [
        ex("Push-up", 5, 20, 20, "Non-stop", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full range, no rest at top", "Knee Push-up"),
        ex("Pull-up", 4, 10, 30, "Dead hang start", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM every rep", "Band-Assisted Pull-up"),
        ex("Dumbbell Shoulder Press", 4, 15, 30, "Moderate-heavy", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Press to full lockout, controlled descent", "Pike Push-up"),
        ex("Dip", 4, 15, 30, "Bodyweight or weighted", "Dip Station", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full depth, lean forward slightly", "Bench Dip"),
        ex("Barbell Curl", 3, 15, 20, "Moderate weight", "Barbell", "Arms", "Biceps", ["Forearms"], "intermediate", "No swinging, full squeeze at top", "Dumbbell Curl"),
        ex("Overhead Tricep Extension", 3, 15, 20, "Moderate weight", "Dumbbells", "Arms", "Triceps", ["Shoulders"], "intermediate", "Full stretch at bottom, lockout at top", "Skull Crusher"),
    ])

def hell_lower():
    return wo("Hell Mode Lower Body", "hell_mode", 55, [
        ex("Barbell Back Squat", 5, 15, 60, "65-70% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full depth, push through heels", "Goblet Squat"),
        ex("Walking Lunge", 4, 20, 30, "Moderate DBs", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Long stride, continuous walking", "Reverse Lunge"),
        ex("Romanian Deadlift", 4, 15, 45, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, feel hamstring stretch", "Single-Leg RDL"),
        ex("Leg Press", 4, 20, 30, "Moderate-heavy", "Leg Press", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Full depth, don't lock knees", "Hack Squat"),
        ex("Jump Squat", 3, 15, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves"], "intermediate", "Deep squat, max height jump", "Bodyweight Squat"),
        ex("Calf Raise", 4, 25, 20, "Heavy", "Smith Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full ROM, hold at top", "Seated Calf Raise"),
    ])

def hell_300():
    return wo("300 Workout", "hell_mode", 45, [
        ex("Pull-up", 1, 25, 0, "Strict or kipping", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "25 reps, minimize rest", "Lat Pulldown"),
        ex("Barbell Deadlift", 1, 50, 0, "135 lbs", "Barbell", "Legs", "Glutes", ["Hamstrings", "Lower Back"], "intermediate", "50 reps, fast pace", "Kettlebell Deadlift"),
        ex("Push-up", 1, 50, 0, "Non-stop", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "50 reps, keep form", "Knee Push-up"),
        ex("Box Jump", 1, 50, 0, "24 inch box", "Plyo Box", "Legs", "Quadriceps", ["Calves"], "intermediate", "50 reps, step down", "Squat Jump"),
        ex("Floor Wiper", 1, 50, 0, "135 lbs barbell overhead", "Barbell", "Core", "Obliques", ["Rectus Abdominis"], "advanced", "Bar locked out, legs side to side", "Lying Leg Raise"),
        ex("Clean & Press", 1, 50, 0, "36 lbs KB", "Kettlebell", "Full Body", "Shoulders", ["Glutes", "Core"], "intermediate", "50 reps total, alternate arms", "Dumbbell Clean & Press"),
        ex("Pull-up", 1, 25, 0, "Finish strong", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Final 25 reps", "Lat Pulldown"),
    ])

def hell_1000_rep():
    return wo("1000 Rep Day", "hell_mode", 60, [
        ex("Bodyweight Squat", 1, 100, 0, "Non-stop", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "intermediate", "100 reps, rest-pause if needed", "Chair Squat"),
        ex("Push-up", 1, 100, 0, "Break as needed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "100 reps, maintain form", "Knee Push-up"),
        ex("Jumping Jack", 1, 100, 0, "Quick pace", "Bodyweight", "Full Body", "Calves", ["Shoulders"], "beginner", "100 reps non-stop", "Step Jack"),
        ex("Lunge", 1, 100, 0, "50 each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "intermediate", "100 total, alternating", "Reverse Lunge"),
        ex("Sit-up", 1, 100, 0, "Continuous", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "100 reps, hands across chest", "Crunch"),
        ex("Burpee", 1, 100, 0, "Break as needed", "Bodyweight", "Full Body", "Quadriceps", ["Chest"], "advanced", "100 reps, pace yourself", "Squat Thrust"),
        ex("Mountain Climber", 1, 100, 0, "50 each side", "Bodyweight", "Core", "Hip Flexors", ["Shoulders"], "intermediate", "100 reps alternating", "High Knees"),
        ex("Glute Bridge", 1, 100, 0, "Non-stop", "Bodyweight", "Legs", "Glutes", ["Hamstrings"], "beginner", "100 reps, squeeze at top", "Hip Thrust"),
        ex("Superman", 1, 100, 0, "Rest-pause", "Bodyweight", "Back", "Erector Spinae", ["Glutes"], "beginner", "100 reps", "Bird Dog"),
        ex("Calf Raise", 1, 100, 0, "Bodyweight", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "100 reps standing", "Seated Calf Raise"),
    ])

hell_programs = [
    ("Hell Week", "Hell Mode", [1], [6], "High", "The ultimate 7-day fitness challenge - one brutal week",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper(), hell_lower()]),
    ("300 Workout Challenge", "Hell Mode", [1, 2, 4], [3, 4], "High", "Complete 300 reps as fast as possible - Spartan-inspired",
     lambda w, t: [hell_300(), hell_full_body(), hell_300(), hell_full_body()]),
    ("1000 Rep Day", "Hell Mode", [1, 2], [3, 4], "High", "1000 total reps across 10 exercises - endurance test",
     lambda w, t: [hell_1000_rep(), hell_full_body(), hell_1000_rep(), hell_full_body()]),
    ("Murph Training", "Hell Mode", [4, 8], [4, 5], "Med", "Train for the Murph challenge: 1mi run, 100 pull-ups, 200 push-ups, 300 squats, 1mi run",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper()]),
    ("Death by Burpees", "Hell Mode", [1, 2, 4], [3, 4], "Med", "Progressive burpee challenge: each minute add 1 rep",
     lambda w, t: [hell_full_body(), hell_full_body(), hell_full_body(), hell_full_body()]),
    ("Iron Man Challenge", "Hell Mode", [2, 4, 8], [5, 6], "Med", "Multi-event endurance and strength challenge",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper(), hell_lower()]),
    ("Beast Mode Bootcamp", "Hell Mode", [2, 4, 8], [5, 6], "Med", "Military-style bootcamp at maximum intensity",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper(), hell_lower()]),
    ("Survivor Challenge", "Hell Mode", [2, 4], [5, 6], "Med", "Survive the week - increasingly brutal daily workouts",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper(), hell_lower()]),
    ("No Rest Challenge", "Hell Mode", [1, 2], [4, 5], "Low", "Zero rest between sets - continuous movement",
     lambda w, t: [hell_full_body(), hell_upper(), hell_lower(), hell_full_body(), hell_upper()]),
    ("Double Day Hell", "Hell Mode", [1, 2], [6], "Low", "Two-a-day training at hell mode intensity",
     lambda w, t: [hell_upper(), hell_lower(), hell_full_body(), hell_upper(), hell_lower(), hell_full_body()]),
    ("10K Swing Challenge", "Hell Mode", [4], [5], "Low", "500 KB swings per session, 10,000 total over 4 weeks",
     lambda w, t: [hell_full_body(), hell_lower(), hell_full_body(), hell_lower(), hell_full_body()]),
    ("Century Sets", "Hell Mode", [2, 4], [4, 5], "Low", "100-rep sets on every exercise",
     lambda w, t: [hell_1000_rep(), hell_full_body(), hell_1000_rep(), hell_full_body(), hell_1000_rep()]),
    ("EXHAUST ME - Full Body", "Hell Mode", [1, 2, 4], [4, 5], "High", "Total body exhaustion workout - no muscle spared",
     lambda w, t: [hell_full_body(), hell_full_body(), hell_full_body(), hell_full_body(), hell_full_body()]),
    ("EXHAUST ME - Upper", "Hell Mode", [1, 2, 4], [4, 5], "Low", "Upper body destruction workout",
     lambda w, t: [hell_upper(), hell_upper(), hell_upper(), hell_upper(), hell_upper()]),
    ("EXHAUST ME - Lower", "Hell Mode", [1, 2, 4], [4, 5], "Low", "Lower body annihilation workout",
     lambda w, t: [hell_lower(), hell_lower(), hell_lower(), hell_lower(), hell_lower()]),
    ("EXHAUST ME - Cardio", "Hell Mode", [1, 2, 4], [4, 5], "Low", "Cardio until you can't breathe",
     lambda w, t: [hell_full_body(), hell_full_body(), hell_full_body(), hell_full_body(), hell_full_body()]),
]

# ===== DANCE FITNESS =====
def dance_cardio():
    return wo("Dance Cardio", "dance", 30, [
        ex("Grapevine", 2, 16, 0, "4 counts each direction", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hip Abductors"], "beginner", "Step-behind-step-touch, stay light", "Side Step"),
        ex("Arm Wave", 2, 16, 0, "Flow with music", "Bodyweight", "Arms", "Deltoids", ["Biceps", "Core"], "beginner", "Fluid wave motion through arms", "Arm Circle"),
        ex("Body Roll", 2, 8, 0, "Full body undulation", "Bodyweight", "Core", "Rectus Abdominis", ["Erector Spinae"], "beginner", "Start from chest, roll through hips", "Standing Cat-Cow"),
        ex("Kick Ball Change", 2, 16, 0, "Quick footwork", "Bodyweight", "Legs", "Hip Flexors", ["Calves", "Quadriceps"], "beginner", "Kick forward, ball of foot, change weight", "Step Touch"),
        ex("Shimmy", 2, 16, 0, "Shoulder isolation", "Bodyweight", "Shoulders", "Deltoids", ["Core"], "beginner", "Alternate shoulders forward/back rapidly", "Shoulder Roll"),
        ex("Pivot Turn", 2, 8, 0, "Quarter and half turns", "Bodyweight", "Legs", "Calves", ["Core", "Quadriceps"], "beginner", "Ball of foot pivot, spot with eyes", "Step Turn"),
    ])

dance_programs = [
    ("Dance Cardio Basics", "Dance Fitness", [2, 4, 8], [3, 4], "High", "Introduction to dance cardio for beginners",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Hip-Hop Dance Workout", "Dance Fitness", [2, 4, 8], [3, 4], "High", "Hip-hop inspired cardio dance workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Latin Dance Fitness", "Dance Fitness", [2, 4, 8], [3, 4], "High", "Salsa, merengue, and bachata inspired fitness",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Dance HIIT Fusion", "Dance Fitness", [2, 4, 8], [3, 4], "High", "High intensity dance intervals for maximum calorie burn",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Dance Party Cardio", "Dance Fitness", [2, 4], [3, 4], "Med", "Fun party-style dance workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Afrobeat Dance Fitness", "Dance Fitness", [2, 4], [3, 4], "Med", "Afrobeat music inspired dance workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Bollywood Dance Workout", "Dance Fitness", [2, 4], [3, 4], "Med", "Bollywood-inspired dance fitness routine",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("K-Pop Dance Fitness", "Dance Fitness", [2, 4], [3, 4], "Med", "K-Pop choreography inspired workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Line Dancing Fitness", "Dance Fitness", [2, 4], [3, 4], "Med", "Country line dancing for fitness",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("80s Aerobics Revival", "Dance Fitness", [2, 4], [3, 4], "Low", "Retro 80s aerobics-style dance workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Reggaeton Burn", "Dance Fitness", [2, 4], [3, 4], "Low", "Reggaeton beat driven dance workout",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
    ("Low Impact Dance", "Dance Fitness", [2, 4, 8], [3, 4], "Low", "Low impact dance workout suitable for all levels",
     lambda w, t: [dance_cardio(), dance_cardio(), dance_cardio(), dance_cardio()]),
]

# ===== POSTURE CORRECTION =====
def posture_basic():
    return wo("Posture Correction", "posture", 20, [
        ex("Chin Tuck", 3, 10, 15, "Hold 5 seconds", "Bodyweight", "Neck", "Deep Neck Flexors", ["SCM"], "beginner", "Pull chin straight back, create double chin", "Neck Retraction"),
        ex("Wall Angel", 3, 10, 15, "Slow movement", "Bodyweight", "Shoulders", "Lower Trapezius", ["Rhomboids", "Rear Deltoid"], "beginner", "Back flat on wall, slide arms up and down", "Floor Angel"),
        ex("Band Pull-Apart", 3, 15, 15, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Pull to chest height, squeeze shoulder blades", "Face Pull"),
        ex("Cat-Cow", 2, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Thoracic Extension", 2, 10, 0, "Over foam roller", "Foam Roller", "Back", "Thoracic Spine", ["Erector Spinae"], "beginner", "Place roller at mid-back, extend over it", "Cat-Cow"),
        ex("Dead Bug", 3, 10, 15, "Alternating", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Back flat on floor, slow controlled movement", "Bird Dog"),
    ])

posture_programs = [
    ("Posture Fix Fundamentals", "Posture Correction", [2, 4, 8], [4, 5], "High", "Foundation program for improving overall posture",
     lambda w, t: [posture_basic()] * 5),
    ("Text Neck Reversal", "Posture Correction", [2, 4, 8], [5, 7], "High", "Reverse the effects of looking down at screens all day",
     lambda w, t: [posture_basic()] * 7),
    ("Rounded Shoulders Fix", "Posture Correction", [2, 4, 8], [4, 5], "High", "Open up chest and strengthen upper back for rounded shoulders",
     lambda w, t: [posture_basic()] * 5),
    ("Full Body Alignment", "Posture Correction", [2, 4, 8], [4, 5], "High", "Complete postural alignment from head to toe",
     lambda w, t: [posture_basic()] * 5),
    ("Anterior Pelvic Tilt Fix", "Posture Correction", [2, 4, 8], [4, 5], "Med", "Fix excessive lower back arch and hip tilt",
     lambda w, t: [posture_basic()] * 5),
    ("Kyphosis Correction", "Posture Correction", [2, 4, 8], [4, 5], "Med", "Reduce upper back rounding and improve thoracic extension",
     lambda w, t: [posture_basic()] * 5),
    ("Lordosis Correction", "Posture Correction", [2, 4, 8], [4, 5], "Med", "Reduce excessive lower back curvature",
     lambda w, t: [posture_basic()] * 5),
    ("Scoliosis-Friendly Posture", "Posture Correction", [2, 4, 8], [3, 4], "Med", "Gentle posture work safe for scoliosis",
     lambda w, t: [posture_basic()] * 4),
    ("Computer Worker Posture", "Posture Correction", [1, 2, 4], [5, 7], "Med", "Desk worker posture correction routine",
     lambda w, t: [posture_basic()] * 7),
    ("Standing Desk Posture", "Posture Correction", [1, 2, 4], [5, 7], "Low", "Posture maintenance for standing desk users",
     lambda w, t: [posture_basic()] * 7),
    ("Gamer Posture Fix", "Posture Correction", [2, 4, 8], [5, 7], "Low", "Fix gaming posture issues - neck, shoulders, wrists",
     lambda w, t: [posture_basic()] * 7),
    ("Driver's Posture Recovery", "Posture Correction", [1, 2, 4], [5, 7], "Low", "Recovery routine for those who drive long hours",
     lambda w, t: [posture_basic()] * 7),
]

# ===== SEDENTARY/COUCH TO FIT =====
def couch_starter():
    return wo("Couch Starter", "beginner", 15, [
        ex("Seated Marching", 2, 20, 15, "Seated or standing", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Lift knees alternately, swing arms", "Marching"),
        ex("Wall Push-up", 2, 10, 15, "Against wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range, elbows 45 degrees", "Incline Push-up"),
        ex("Chair Squat", 2, 10, 15, "Sit and stand", "Chair", "Legs", "Quadriceps", ["Glutes"], "beginner", "Touch chair, stand back up", "Assisted Squat"),
        ex("Arm Raise", 2, 10, 15, "Front and side", "Bodyweight", "Shoulders", "Deltoids", [], "beginner", "Raise arms to shoulder height", "Arm Circle"),
        ex("Standing Calf Raise", 2, 15, 15, "Hold wall for balance", "Bodyweight", "Legs", "Calves", ["Soleus"], "beginner", "Rise on toes, lower slowly", "Seated Calf Raise"),
    ])

sedentary_programs = [
    ("Couch to Fitness", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "High", "Gradual progression from sedentary to active lifestyle",
     lambda w, t: [couch_starter()] * 4),
    ("Sedentary to Active", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "High", "Step-by-step program for previously inactive people",
     lambda w, t: [couch_starter()] * 4),
    ("TV Time Workout", "Sedentary/Couch to Fit", [1, 2, 4], [5, 7], "High", "Exercise while watching TV - no excuses",
     lambda w, t: [couch_starter()] * 7),
    ("Zero to Hero Beginner", "Sedentary/Couch to Fit", [4, 8, 12], [3, 4], "High", "Complete beginner transformation program",
     lambda w, t: [couch_starter()] * 4),
    ("5-Minute Couch Workout", "Sedentary/Couch to Fit", [1, 2, 4], [5, 7], "Med", "Ultra-short workout you can do from your couch",
     lambda w, t: [couch_starter()] * 7),
    ("Desk Job Recovery", "Sedentary/Couch to Fit", [1, 2, 4], [5, 7], "Med", "Counter the effects of sitting all day",
     lambda w, t: [couch_starter()] * 7),
    ("WFH Fitness", "Sedentary/Couch to Fit", [1, 2, 4], [5, 7], "Med", "Work from home fitness routine",
     lambda w, t: [couch_starter()] * 7),
    ("Screen Time Balance", "Sedentary/Couch to Fit", [1, 2, 4], [5, 7], "Med", "Balance screen time with movement breaks",
     lambda w, t: [couch_starter()] * 7),
    ("First Steps Fitness", "Sedentary/Couch to Fit", [4, 8], [3, 4], "Low", "Absolute first steps into fitness",
     lambda w, t: [couch_starter()] * 4),
    ("Couch to 5K Style", "Sedentary/Couch to Fit", [8, 12], [3, 4], "Low", "Walk-to-run progression program",
     lambda w, t: [couch_starter()] * 4),
    ("Movement Restart", "Sedentary/Couch to Fit", [2, 4, 8], [3, 4], "Low", "Restart movement after long inactivity",
     lambda w, t: [couch_starter()] * 4),
]

# ===== OCCUPATION-BASED =====
def occupation_general():
    return wo("Occupation-Based Fitness", "strength", 30, [
        ex("Bodyweight Squat", 3, 12, 30, "Functional movement", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, chest up", "Chair Squat"),
        ex("Push-up", 3, 10, 30, "Any variation", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full range of motion", "Wall Push-up"),
        ex("Band Row", 3, 12, 30, "Light-moderate band", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Squeeze shoulder blades together", "Doorway Row"),
        ex("Plank", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight core, neutral spine", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 30, "Squeeze at top", "Bodyweight", "Legs", "Glutes", ["Hamstrings"], "beginner", "Press heels down, lift hips", "Hip Thrust"),
        ex("Shoulder Stretch", 2, 1, 0, "Hold 30 seconds each", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Cross-body stretch, doorway stretch", "Arm Circle"),
    ])

occupation_programs = [
    ("Manual Labor Fitness", "Occupation-Based", [4, 8], [3, 4], "High", "Conditioning for physically demanding jobs",
     lambda w, t: [occupation_general()] * 4),
    ("Hay Bale Conditioning", "Occupation-Based", [4, 8], [3, 4], "High", "Functional strength for farm and agricultural work",
     lambda w, t: [occupation_general()] * 4),
    ("Trucker Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "High", "Fitness program for long-haul truck drivers",
     lambda w, t: [occupation_general()] * 4),
    ("Nurse/Healthcare Worker", "Occupation-Based", [2, 4, 8], [3, 4], "Med", "Recovery and strength for healthcare professionals",
     lambda w, t: [occupation_general()] * 4),
    ("Teacher Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "Med", "Energy and strength for teachers on their feet all day",
     lambda w, t: [occupation_general()] * 4),
    ("Chef/Kitchen Worker", "Occupation-Based", [2, 4, 8], [3, 4], "Med", "Recovery fitness for kitchen workers",
     lambda w, t: [occupation_general()] * 4),
    ("Retail Worker Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "Med", "Standing all day recovery and strength",
     lambda w, t: [occupation_general()] * 4),
    ("Warehouse Worker Strength", "Occupation-Based", [4, 8], [3, 4], "Med", "Functional strength for warehouse work",
     lambda w, t: [occupation_general()] * 4),
    ("Office Worker Fitness", "Occupation-Based", [2, 4, 8], [3, 4], "Low", "Counter desk job effects with targeted exercises",
     lambda w, t: [occupation_general()] * 4),
    ("Remote Worker Movement", "Occupation-Based", [1, 2, 4], [5, 7], "Low", "Movement breaks and fitness for remote workers",
     lambda w, t: [occupation_general()] * 7),
    ("Night Shift Recovery", "Occupation-Based", [2, 4, 8], [3, 4], "Low", "Recovery-focused fitness for night shift workers",
     lambda w, t: [occupation_general()] * 4),
]

# ===== GENERATE ALL =====
all_programs = hell_programs + dance_programs + posture_programs + sedentary_programs + occupation_programs

for prog_name, cat, durs, sessions_list, pri, desc, workout_fn in all_programs:
    if helper.check_program_exists(prog_name):
        print(f"{prog_name} - ALREADY EXISTS, skipping")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: build base and learn movements"
            elif p <= 0.66: focus = f"Week {w} - Development: increase intensity and duration"
            else: focus = f"Week {w} - Peak: maximum effort and mastery"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

helper.close()
print("\n=== HELL + DANCE + POSTURE + SEDENTARY + OCCUPATION COMPLETE ===")
