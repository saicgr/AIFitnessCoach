#!/usr/bin/env python3
"""Generate programs for categories 39-42: GLP-1, Balance, Hybrid, Competition."""
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
# CAT 39 - GLP-1/WEIGHT LOSS MEDICATION (10 programs)
# ========================================================================

def glp1_muscle_preservation():
    return wo("GLP-1 Muscle Preservation", "strength", 35, [
        ex("Goblet Squat", 3, 10, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Preserve quad and glute mass during weight loss", "Bodyweight Squat"),
        ex("Dumbbell Chest Press", 3, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Maintain upper body muscle during caloric deficit", "Push-Up"),
        ex("Dumbbell Row", 3, 10, 60, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Back strength preservation", "Band Row"),
        ex("Romanian Deadlift", 3, 10, 60, "Dumbbells, moderate", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Posterior chain muscle preservation", "Good Morning"),
        ex("Dumbbell Shoulder Press", 3, 10, 60, "Seated for safety", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Overhead strength maintenance", "Lateral Raise"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability during body composition change", "Dead Bug"),
    ])

def ozempic_body_recomp():
    return wo("Ozempic Body Recomp", "strength", 40, [
        ex("Back Squat", 3, 8, 90, "Moderate weight", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Heavy compound to signal muscle retention", "Goblet Squat"),
        ex("Bench Press", 3, 8, 90, "Moderate weight", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Maintain chest and arm mass", "Dumbbell Press"),
        ex("Barbell Row", 3, 8, 60, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Back muscle retention during deficit", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Shoulder mass preservation", "Dumbbell Press"),
        ex("Leg Curl", 3, 10, 45, "Machine or band", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Hamstring muscle preservation", "Nordic Curl"),
        ex("Walking Lunge", 3, 8, 30, "Each leg, bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Functional leg strength", "Reverse Lunge"),
    ])

def medication_safe_cardio():
    return wo("Medication-Safe Cardio", "cardio", 30, [
        ex("Brisk Walk", 1, 1, 0, "15 minutes moderate", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Gentle cardio safe with GLP-1 nausea", "March in Place"),
        ex("Step Touch", 3, 1, 30, "1 minute each", "Bodyweight", "Legs", "Hip Abductors", ["Calves"], "beginner", "Low intensity to avoid GI upset", "Side Step"),
        ex("Seated Bicycle", 3, 15, 30, "Seated in chair", "Bodyweight", "Core", "Obliques", ["Hip Flexors"], "beginner", "Core work without nausea triggers", "Standing Bicycle"),
        ex("Standing March", 3, 1, 30, "1 minute each", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Easy heart rate elevation", "Seated March"),
        ex("Gentle Cool Down Stretch", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Hamstrings", ["Quadriceps", "Shoulders"], "beginner", "Gentle stretching to end session", "Standing Stretch"),
    ])

def muscle_recovery_protocol():
    return wo("Muscle Recovery Protocol", "strength", 35, [
        ex("Goblet Squat", 3, 12, 60, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Rebuild lost muscle with compound movement", "Bodyweight Squat"),
        ex("Push-Up", 3, 10, 45, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Upper body muscle rebuilding", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Back muscle recovery", "Band Row"),
        ex("Glute Bridge", 3, 15, 30, "Add dumbbell on hips", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Glute reactivation and rebuilding", "Hip Thrust"),
        ex("Dumbbell Curl", 3, 10, 30, "Moderate", "Dumbbell", "Arms", "Biceps", ["Forearms"], "beginner", "Arm muscle recovery", "Band Curl"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability rebuilding", "Dead Bug"),
    ])

def bone_density_glp1():
    return wo("Bone Density on GLP-1", "strength", 35, [
        ex("Back Squat", 3, 8, 90, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Axial loading for bone density preservation", "Goblet Squat"),
        ex("Deadlift", 3, 6, 90, "Moderate", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Hip and spine bone loading", "Trap Bar Deadlift"),
        ex("Overhead Press", 3, 8, 60, "Standing, moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Upper body bone loading", "Dumbbell Press"),
        ex("Walking Lunge", 3, 8, 30, "Each leg, can add weight", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Impact loading for leg bones", "Reverse Lunge"),
        ex("Calf Raise", 3, 15, 30, "Weighted if possible", "Dumbbell", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Lower leg bone loading", "Seated Calf Raise"),
    ])

def joint_friendly_full_body():
    return wo("Joint-Friendly Full Body", "strength", 30, [
        ex("Goblet Squat", 3, 12, 45, "Light to moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Joint-friendly squat variation, less spinal load", "Bodyweight Squat"),
        ex("Dumbbell Floor Press", 3, 10, 45, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Limits shoulder range to protect joints", "Push-Up"),
        ex("Cable Row", 3, 12, 45, "Moderate, seated", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Smooth resistance, joint-friendly pulling", "Band Row"),
        ex("Leg Press", 3, 12, 45, "Moderate weight", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Machine supports spine while loading legs", "Wall Sit"),
        ex("Lat Pulldown", 3, 12, 45, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Controlled pulling without hanging stress", "Band Pulldown"),
    ])

def post_medication_transition():
    return wo("Post-Medication Transition", "strength", 40, [
        ex("Back Squat", 3, 8, 90, "Progressive loading", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Rebuild strength after medication phase", "Goblet Squat"),
        ex("Bench Press", 3, 8, 90, "Progressive", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Rebuild upper body pushing strength", "Dumbbell Press"),
        ex("Deadlift", 3, 6, 120, "Moderate to heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Posterior chain rebuilding", "Trap Bar Deadlift"),
        ex("Pull-Up", 3, 6, 60, "Assisted if needed", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Upper body pulling strength", "Lat Pulldown"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Metabolic conditioning to maintain weight loss", "Dumbbell Swing"),
    ])

def lean_mass_building():
    return wo("Lean Mass Building", "strength", 40, [
        ex("Back Squat", 4, 8, 90, "Progressive overload", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Primary leg mass builder", "Goblet Squat"),
        ex("Bench Press", 4, 8, 90, "Progressive", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Chest and arm mass building", "Dumbbell Press"),
        ex("Barbell Row", 3, 10, 60, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Back thickness and width", "Dumbbell Row"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Posterior chain development", "Dumbbell RDL"),
        ex("Lateral Raise", 3, 12, 30, "Light to moderate", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder width and cap development", "Band Lateral Raise"),
    ])

def metabolism_rebuild():
    return wo("Metabolism Rebuild", "general", 35, [
        ex("Goblet Squat", 3, 12, 45, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Build metabolically active muscle tissue", "Bodyweight Squat"),
        ex("Push-Up", 3, 12, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Upper body muscle for metabolic rate", "Incline Push-Up"),
        ex("Dumbbell Row", 3, 10, 30, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Back muscle mass for metabolic rate", "Band Row"),
        ex("Walking Lunge", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Leg muscle rebuilding for metabolism", "Reverse Lunge"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Metabolic conditioning burst", "Dumbbell Swing"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability for overall function", "Dead Bug"),
    ])

def sustainable_movement():
    return wo("Sustainable Movement", "general", 30, [
        ex("Bodyweight Squat", 3, 12, 30, "Full range", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Sustainable daily movement pattern", "Chair Squat"),
        ex("Push-Up", 3, 10, 30, "Any variation", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Daily upper body maintenance", "Incline Push-Up"),
        ex("Band Row", 3, 12, 30, "Light resistance", "Resistance Band", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Gentle back strengthening", "Doorway Row"),
        ex("Walking", 1, 1, 0, "10 minutes moderate pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "beginner", "Foundation of sustainable daily movement", "March in Place"),
        ex("Standing Balance", 2, 1, 30, "30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius"], "beginner", "Maintain balance and proprioception", "Tandem Stand"),
    ])

# Generate Cat 39 programs
cat39_programs = [
    ("GLP-1 Muscle Preservation", "GLP-1/Weight Loss Medication", [4, 8, 12, 16], [3, 4], "Prevent muscle loss while on GLP-1 medications like Ozempic", "High", True,
     lambda w, t: [glp1_muscle_preservation(), glp1_muscle_preservation(), glp1_muscle_preservation()]),
    ("Ozempic Body Recomp", "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], "Build muscle while losing fat on Ozempic or Wegovy", "High", True,
     lambda w, t: [ozempic_body_recomp(), ozempic_body_recomp(), ozempic_body_recomp()]),
    ("Medication-Safe Cardio", "GLP-1/Weight Loss Medication", [2, 4, 8], [3, 4], "Gentle cardio that avoids GLP-1 nausea triggers", "Med", False,
     lambda w, t: [medication_safe_cardio(), medication_safe_cardio(), medication_safe_cardio()]),
    ("Muscle Recovery Protocol", "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], "Rebuild muscle mass lost during GLP-1 medication use", "Med", True,
     lambda w, t: [muscle_recovery_protocol(), muscle_recovery_protocol(), muscle_recovery_protocol()]),
    ("Bone Density on GLP-1", "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], "Weight-bearing exercises to preserve bone density on medication", "Med", False,
     lambda w, t: [bone_density_glp1(), bone_density_glp1(), bone_density_glp1()]),
    ("Joint-Friendly Full Body", "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], "Joint-safe full body training for medication users", "Med", True,
     lambda w, t: [joint_friendly_full_body(), joint_friendly_full_body(), joint_friendly_full_body()]),
    ("Post-Medication Transition", "GLP-1/Weight Loss Medication", [8, 12, 16], [4, 5], "Transition training after stopping GLP-1 medications", "High", True,
     lambda w, t: [post_medication_transition(), post_medication_transition(), post_medication_transition()]),
    ("Lean Mass Building", "GLP-1/Weight Loss Medication", [4, 8, 12], [4, 5], "Progressive strength training to rebuild lean body mass", "Med", True,
     lambda w, t: [lean_mass_building(), lean_mass_building(), lean_mass_building()]),
    ("Metabolism Rebuild", "GLP-1/Weight Loss Medication", [4, 8, 12], [4, 5], "Rebuild metabolic rate naturally through muscle building", "Med", True,
     lambda w, t: [metabolism_rebuild(), metabolism_rebuild(), metabolism_rebuild()]),
    ("Sustainable Movement", "GLP-1/Weight Loss Medication", [4, 8, 12], [3, 4], "Long-term sustainable exercise habits for weight maintenance", "Med", False,
     lambda w, t: [sustainable_movement(), sustainable_movement(), sustainable_movement()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat39_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Gentle start: acclimate to training while on medication"
            elif p <= 0.66: focus = f"Week {w} - Build: progressive resistance to preserve muscle mass"
            else: focus = f"Week {w} - Maintain: sustain muscle and bone through continued training"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 39 GLP-1 COMPLETE ===")

# ========================================================================
# CAT 40 - BALANCE & PROPRIOCEPTION (12 programs)
# ========================================================================

def balance_foundation():
    return wo("Balance Foundation", "balance", 25, [
        ex("Single-Leg Stand", 3, 1, 30, "Hold 30 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "beginner", "Stand on one foot, maintain alignment", "Tandem Stand"),
        ex("Tandem Stand", 3, 1, 30, "Hold 30 seconds each lead foot", "Bodyweight", "Legs", "Core", ["Calves", "Ankle Stabilizers"], "beginner", "Heel to toe line, arms out for balance", "Wide Stance Balance"),
        ex("Weight Shift", 3, 10, 30, "Side to side", "Bodyweight", "Legs", "Hip Abductors", ["Core", "Ankle Stabilizers"], "beginner", "Shift weight fully to one foot, pause, shift back", "Step Touch"),
        ex("Heel-to-Toe Walk", 2, 20, 30, "20 steps each set", "Bodyweight", "Legs", "Core", ["Calves", "Tibialis Anterior"], "beginner", "Walk in straight line, heel touching toe", "Tandem Walk"),
        ex("Standing Leg Swing", 2, 10, 0, "Each leg, forward and back", "Bodyweight", "Hips", "Hip Flexors", ["Glutes", "Core"], "beginner", "Hold support, swing leg gently, challenge balance", "Leg Raise"),
    ])

def single_leg_stability():
    return wo("Single-Leg Stability", "balance", 30, [
        ex("Single-Leg Romanian Deadlift", 3, 8, 30, "Each leg, bodyweight", "Bodyweight", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge on one leg, reach toward floor", "Romanian Deadlift"),
        ex("Single-Leg Squat to Box", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Lower to box on one leg, stand back up", "Split Squat"),
        ex("Single-Leg Calf Raise", 3, 12, 30, "Each leg", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus", "Ankle Stabilizers"], "beginner", "Rise on one foot, slow lower, challenge balance", "Double Calf Raise"),
        ex("Single-Leg Hip Hinge", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hinge pattern on one leg with arm reach", "Single-Leg RDL"),
        ex("Single-Leg Hop and Stick", 3, 6, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Hop forward, land on one foot, freeze for 3 seconds", "Single-Leg Balance"),
    ])

def bosu_ball_training():
    return wo("Bosu Ball Training", "balance", 30, [
        ex("Bosu Ball Squat", 3, 12, 30, "Flat side down", "Bosu Ball", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers", "Glutes"], "intermediate", "Stand on dome, squat with balance", "Single-Leg Balance"),
        ex("Bosu Ball Plank", 3, 1, 30, "Hold 30 seconds", "Bosu Ball", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Hands on dome, plank with instability", "Plank"),
        ex("Bosu Ball Push-Up", 3, 10, 30, "Hands on dome", "Bosu Ball", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Push-up on unstable surface", "Push-Up"),
        ex("Bosu Ball Single-Leg Stand", 3, 1, 30, "Hold 20 seconds each leg", "Bosu Ball", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "Stand on dome, lift one foot", "Single-Leg Stand"),
        ex("Bosu Ball Lunge", 3, 8, 30, "Each leg, front foot on dome", "Bosu Ball", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Lunge with front foot on unstable surface", "Split Squat"),
    ])

def balance_board_workout():
    return wo("Balance Board Workout", "balance", 25, [
        ex("Balance Board Stand", 3, 1, 30, "Hold 30 seconds", "Balance Board", "Legs", "Core", ["Ankle Stabilizers", "Gluteus Medius"], "beginner", "Stand centered, find equilibrium, stay level", "Single-Leg Stand"),
        ex("Balance Board Squat", 3, 10, 30, "Small squats on board", "Balance Board", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers"], "intermediate", "Squat while maintaining board level", "Bosu Ball Squat"),
        ex("Balance Board Tilt Control", 3, 10, 30, "Controlled tilts each direction", "Balance Board", "Legs", "Tibialis Anterior", ["Calves", "Core"], "beginner", "Tilt board edge to edge with control", "Ankle Circle"),
        ex("Balance Board Single-Leg", 3, 1, 30, "Hold 15 seconds each leg", "Balance Board", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "One foot centered on board, balance", "Single-Leg Stand"),
    ])

def proprioception_drills():
    return wo("Proprioception Drills", "balance", 25, [
        ex("Eyes-Closed Single-Leg Stand", 3, 1, 30, "Hold 15 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "Close eyes, rely on proprioception only", "Single-Leg Stand"),
        ex("Perturbation Training", 3, 10, 30, "Partner or self-induced", "Bodyweight", "Full Body", "Core", ["Hip Abductors", "Ankle Stabilizers"], "intermediate", "Stand balanced, apply gentle pushes, react to stay upright", "Single-Leg Stand"),
        ex("Joint Position Sense Drill", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Core", ["Ankle Stabilizers"], "intermediate", "Close eyes, move foot to position, check accuracy", "Single-Leg Balance"),
        ex("Tandem Walk Backward", 2, 20, 30, "20 steps", "Bodyweight", "Legs", "Core", ["Calves", "Hip Flexors"], "intermediate", "Walk backward heel-to-toe", "Tandem Walk"),
        ex("Foam Pad Balance", 3, 1, 30, "Hold 30 seconds each leg", "Foam Pad", "Legs", "Core", ["Ankle Stabilizers", "Gluteus Medius"], "beginner", "Stand on unstable foam, eyes open then closed", "Single-Leg Stand"),
    ])

def vestibular_training():
    return wo("Vestibular Training", "balance", 25, [
        ex("Head Turn Balance", 3, 10, 30, "Turn head while standing on one leg", "Bodyweight", "Legs", "Core", ["Vestibular System", "Neck"], "intermediate", "Single-leg stand, slowly turn head left and right", "Single-Leg Stand"),
        ex("Gaze Stabilization", 3, 15, 30, "Hold target, move head", "Bodyweight", "Neck", "Vestibular System", ["Deep Cervical Flexors"], "beginner", "Fix eyes on target, move head side to side", "Head Turn"),
        ex("Marching with Head Turns", 3, 20, 30, "Turn head while marching", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Vestibular System"], "intermediate", "March in place, rotate head slowly", "Standing March"),
        ex("Spinning Recovery Stand", 3, 3, 60, "Spin slowly, then balance", "Bodyweight", "Full Body", "Core", ["Vestibular System"], "intermediate", "Spin 3 times slowly, stop and balance on one foot", "Single-Leg Stand"),
        ex("Head Tilt Walk", 2, 20, 30, "20 steps with head tilted", "Bodyweight", "Legs", "Core", ["Vestibular System", "Neck"], "beginner", "Walk straight line with head tilted to one side", "Tandem Walk"),
    ])

def wobble_board_workout():
    return wo("Wobble Board Workout", "balance", 25, [
        ex("Wobble Board Stand", 3, 1, 30, "Hold 30 seconds", "Wobble Board", "Legs", "Core", ["Ankle Stabilizers"], "beginner", "Stand centered, keep edges off ground", "Balance Board Stand"),
        ex("Wobble Board Squat", 3, 10, 30, "Small squats", "Wobble Board", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers"], "intermediate", "Squat while keeping board from touching floor", "Bosu Ball Squat"),
        ex("Wobble Board Circle", 3, 5, 30, "Each direction", "Wobble Board", "Legs", "Tibialis Anterior", ["Calves", "Core"], "intermediate", "Roll board edge in circular pattern", "Ankle Circle"),
        ex("Wobble Board Eyes Closed", 3, 1, 30, "Hold 15 seconds", "Wobble Board", "Legs", "Core", ["Ankle Stabilizers"], "intermediate", "Balance on board with eyes closed", "Foam Pad Balance"),
    ])

def eyes_closed_training():
    return wo("Eyes-Closed Training", "balance", 20, [
        ex("Eyes-Closed Double-Leg Stand", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Core", ["Ankle Stabilizers"], "beginner", "Stand with eyes closed, feel proprioception", "Standing Balance"),
        ex("Eyes-Closed Single-Leg Stand", 3, 1, 30, "Hold 15 seconds each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "Close eyes, balance on one foot", "Single-Leg Stand"),
        ex("Eyes-Closed Tandem Walk", 2, 10, 30, "10 steps forward", "Bodyweight", "Legs", "Core", ["Calves"], "intermediate", "Heel-to-toe with eyes closed, arms out", "Tandem Walk"),
        ex("Eyes-Closed Weight Shift", 3, 8, 30, "Side to side", "Bodyweight", "Legs", "Hip Abductors", ["Core"], "intermediate", "Shift weight left and right with no vision", "Weight Shift"),
    ])

def dynamic_balance():
    return wo("Dynamic Balance", "balance", 30, [
        ex("Single-Leg Hop Forward", 3, 6, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Hop forward, land stable, hold 2 seconds", "Single-Leg Jump"),
        ex("Lateral Bound", 3, 6, 30, "Side to side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "intermediate", "Jump side to side, land on one foot, stabilize", "Lateral Shuffle"),
        ex("Star Excursion", 3, 5, 30, "Each leg, each direction", "Bodyweight", "Legs", "Core", ["Gluteus Medius", "Ankle Stabilizers"], "intermediate", "Stand on one leg, reach other foot in 8 directions", "Single-Leg Reach"),
        ex("Walking Lunge with Rotation", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Obliques", "Glutes"], "intermediate", "Lunge forward, rotate torso over lead leg", "Walking Lunge"),
        ex("Agility Ladder Quick Feet", 3, 2, 30, "Full ladder", "Agility Ladder", "Legs", "Calves", ["Hip Flexors", "Core"], "intermediate", "Quick feet through ladder, maintain balance", "Quick Feet in Place"),
    ])

def sport_balance():
    return wo("Sport Balance", "balance", 30, [
        ex("Single-Leg Romanian Deadlift", 3, 8, 30, "Each leg, with dumbbell", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Athletic hinge pattern on one leg", "Romanian Deadlift"),
        ex("Lateral Bound and Stick", 3, 6, 30, "Each side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Core"], "intermediate", "Bound sideways, land on outside foot, freeze 3 seconds", "Lateral Lunge"),
        ex("Rotational Single-Leg Balance", 3, 8, 30, "Each leg", "Medicine Ball", "Core", "Obliques", ["Core", "Gluteus Medius"], "intermediate", "Stand on one leg, rotate medicine ball side to side", "Russian Twist"),
        ex("Box Jump and Stick", 3, 6, 45, "Single-leg landing", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Jump onto box, land on one foot, hold 3 seconds", "Squat Jump"),
        ex("Agility T-Drill", 3, 3, 60, "Full T pattern", "Cones", "Legs", "Quadriceps", ["Hip Abductors", "Calves"], "intermediate", "Sprint, shuffle, backpedal in T pattern", "Lateral Shuffle"),
    ])

def senior_balance():
    return wo("Senior Balance", "balance", 20, [
        ex("Chair Stand", 3, 10, 30, "Sit to stand", "Bodyweight", "Legs", "Quadriceps", ["Glutes"], "beginner", "Stand from chair without using hands if possible", "Wall Sit"),
        ex("Heel-to-Toe Walk", 2, 10, 30, "Near wall for safety", "Bodyweight", "Legs", "Core", ["Calves"], "beginner", "Walk heel-to-toe along wall for support", "Tandem Stand"),
        ex("Standing Leg Raise", 2, 10, 30, "Each leg, hold chair", "Bodyweight", "Hips", "Hip Abductors", ["Core"], "beginner", "Lift leg to side, hold briefly", "Seated Leg Raise"),
        ex("Marching in Place", 2, 20, 30, "Hold support nearby", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Lift knees alternating, maintain upright posture", "Seated March"),
        ex("Standing Clock Reach", 2, 8, 30, "Each leg", "Bodyweight", "Legs", "Core", ["Gluteus Medius"], "beginner", "Stand on one leg, reach other to clock positions", "Single-Leg Stand"),
    ])

def surf_balance_training():
    return wo("Surf Balance Training", "balance", 30, [
        ex("Bosu Ball Squat", 3, 12, 30, "Simulate board balance", "Bosu Ball", "Legs", "Quadriceps", ["Core", "Ankle Stabilizers"], "intermediate", "Low stance on dome, weight shifting", "Single-Leg Balance"),
        ex("Indo Board Balance", 3, 1, 30, "Hold 30 seconds", "Balance Board", "Legs", "Core", ["Ankle Stabilizers", "Gluteus Medius"], "intermediate", "Simulate surfboard movement on balance board", "Bosu Ball Stand"),
        ex("Pop-Up Drill", 3, 10, 30, "Lie to stand quickly", "Bodyweight", "Full Body", "Hip Flexors", ["Chest", "Core"], "intermediate", "Lie face down, spring to surf stance", "Burpee"),
        ex("Single-Leg Rotational Reach", 3, 8, 30, "Each leg", "Bodyweight", "Legs", "Core", ["Obliques", "Gluteus Medius"], "intermediate", "On one leg, rotate and reach in multiple directions", "Single-Leg RDL"),
        ex("Lateral Bound", 3, 8, 30, "Side to side", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Calves"], "intermediate", "Side jump, land stable, simulate wave balance", "Lateral Shuffle"),
    ])

# Generate Cat 40 programs
cat40_programs = [
    ("Balance Foundation", "Balance & Proprioception", [2, 4, 8], [4, 5], "Fundamental balance training for all fitness levels", "High", False,
     lambda w, t: [balance_foundation(), balance_foundation(), balance_foundation()]),
    ("Single-Leg Stability", "Balance & Proprioception", [4, 8, 12], [3, 4], "Unilateral balance progression for strong single-leg stability", "High", False,
     lambda w, t: [single_leg_stability(), single_leg_stability(), single_leg_stability()]),
    ("Bosu Ball Training", "Balance & Proprioception", [2, 4, 8], [3, 4], "Unstable surface training on the Bosu ball", "Med", False,
     lambda w, t: [bosu_ball_training(), bosu_ball_training(), bosu_ball_training()]),
    ("Balance Board Workout", "Balance & Proprioception", [2, 4, 8], [4, 5], "Balance board training for ankle and core stability", "Low", False,
     lambda w, t: [balance_board_workout(), balance_board_workout(), balance_board_workout()]),
    ("Proprioception Drills", "Balance & Proprioception", [4, 8], [4, 5], "Body awareness and position sense development", "High", False,
     lambda w, t: [proprioception_drills(), proprioception_drills(), proprioception_drills()]),
    ("Vestibular Training", "Balance & Proprioception", [2, 4, 8], [4, 5], "Inner ear balance system training and development", "Med", False,
     lambda w, t: [vestibular_training(), vestibular_training(), vestibular_training()]),
    ("Wobble Board Workout", "Balance & Proprioception", [2, 4, 8], [4, 5], "Wobble board mastery for ankle proprioception", "Low", False,
     lambda w, t: [wobble_board_workout(), wobble_board_workout(), wobble_board_workout()]),
    ("Eyes-Closed Training", "Balance & Proprioception", [2, 4], [4, 5], "Visual-free proprioception and balance training", "Low", False,
     lambda w, t: [eyes_closed_training(), eyes_closed_training(), eyes_closed_training()]),
    ("Dynamic Balance", "Balance & Proprioception", [2, 4, 8], [3, 4], "Moving balance drills for reactive stability", "Med", False,
     lambda w, t: [dynamic_balance(), dynamic_balance(), dynamic_balance()]),
    ("Sport Balance", "Balance & Proprioception", [4, 8], [3, 4], "Sport-specific balance and stability training", "Med", False,
     lambda w, t: [sport_balance(), sport_balance(), sport_balance()]),
    ("Senior Balance", "Balance & Proprioception", [4, 8, 12], [3, 4], "Fall prevention balance program for older adults", "Low", False,
     lambda w, t: [senior_balance(), senior_balance(), senior_balance()]),
    ("Surf Balance Training", "Balance & Proprioception", [2, 4, 8], [3, 4], "Board-sport balance training for surfers and boarders", "Low", False,
     lambda w, t: [surf_balance_training(), surf_balance_training(), surf_balance_training()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat40_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Awareness: establish balance baseline and proprioception"
            elif p <= 0.66: focus = f"Week {w} - Challenge: add complexity and reduce support"
            else: focus = f"Week {w} - Mastery: eyes closed, single-leg, dynamic challenges"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 40 BALANCE & PROPRIOCEPTION COMPLETE ===")

# ========================================================================
# CAT 41 - HYBRID TRAINING (12 programs)
# ========================================================================

def strength_cardio_hybrid():
    return wo("Strength + Cardio Hybrid", "hybrid", 45, [
        ex("Back Squat", 3, 6, 90, "Heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Heavy compound for strength", "Goblet Squat"),
        ex("Rowing Machine", 1, 1, 60, "500m hard", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps", "Core"], "intermediate", "Cardio burst between lifts", "Burpees"),
        ex("Bench Press", 3, 6, 90, "Heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Upper body strength", "Dumbbell Press"),
        ex("Jump Rope", 1, 1, 60, "2 minutes", "Jump Rope", "Full Body", "Calves", ["Shoulders"], "beginner", "Cardio between strength sets", "High Knees"),
        ex("Deadlift", 3, 5, 120, "Heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Major strength movement", "Trap Bar Deadlift"),
        ex("Assault Bike", 1, 1, 0, "3 minutes moderate", "Stationary Bike", "Full Body", "Quadriceps", ["Hamstrings", "Core"], "intermediate", "Cardio finisher", "High Knees"),
    ])

def run_lift_hybrid():
    return wo("Run + Lift Hybrid", "hybrid", 45, [
        ex("Treadmill Run", 1, 1, 0, "10 minutes moderate", "Treadmill", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Running base followed by lifting", "Outdoor Run"),
        ex("Back Squat", 3, 8, 90, "Moderate", "Barbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Lower body strength after running", "Goblet Squat"),
        ex("Bench Press", 3, 8, 60, "Moderate", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Upper body push", "Dumbbell Press"),
        ex("Pull-Up", 3, 6, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Upper body pull", "Lat Pulldown"),
        ex("Treadmill Sprint", 3, 30, 90, "30 second sprints", "Treadmill", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Sprint intervals post-lifting", "High Knees"),
    ])

def swim_strength():
    return wo("Swim + Strength", "hybrid", 40, [
        ex("Lat Pulldown", 3, 10, 45, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pulling strength for swimming", "Band Pulldown"),
        ex("Dumbbell Shoulder Press", 3, 10, 45, "Moderate", "Dumbbell", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Overhead strength for strokes", "Push-Up"),
        ex("Rotational Medicine Ball Throw", 3, 10, 30, "Each side", "Medicine Ball", "Core", "Obliques", ["Shoulders"], "intermediate", "Rotational power for swimming turns", "Russian Twist"),
        ex("Goblet Squat", 3, 10, 45, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Leg drive for kicks and turns", "Bodyweight Squat"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Core stability for streamline", "Dead Bug"),
    ])

def yoga_strength():
    return wo("Yoga + Strength", "hybrid", 45, [
        ex("Sun Salutation A", 2, 5, 0, "Flow warmup", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Warm up with yoga flow before lifting", "Dynamic Stretch"),
        ex("Goblet Squat", 3, 10, 45, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Strength work with yoga mobility", "Bodyweight Squat"),
        ex("Dumbbell Row", 3, 10, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Back strength between yoga flows", "Band Row"),
        ex("Warrior Flow", 2, 1, 0, "Warrior I-II-III sequence", "Bodyweight", "Legs", "Quadriceps", ["Core", "Shoulders"], "beginner", "Active yoga between strength sets", "Lunge"),
        ex("Push-Up", 3, 10, 30, "Full range", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Strength push integrated with flow", "Chaturanga"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Glutes", ["Hip Flexors"], "beginner", "Cool down stretch after strength", "Figure-4 Stretch"),
    ])

def boxing_strength():
    return wo("Boxing + Strength", "hybrid", 40, [
        ex("Shadow Boxing", 3, 1, 30, "2 minutes each round", "Bodyweight", "Full Body", "Deltoids", ["Core", "Calves"], "intermediate", "Jab, cross, hook, uppercut combinations", "Punching Bag"),
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Chest strength for punching power", "Push-Up"),
        ex("Pull-Up", 3, 6, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Back strength for clinch work", "Lat Pulldown"),
        ex("Medicine Ball Slam", 3, 10, 30, "Explosive", "Medicine Ball", "Full Body", "Deltoids", ["Core"], "intermediate", "Power output for striking", "Battle Rope Slam"),
        ex("Russian Twist", 3, 15, 30, "Rotational power", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Rotational core for hooks and crosses", "Cable Rotation"),
    ])

def cycling_weights():
    return wo("Cycling + Weights", "hybrid", 40, [
        ex("Stationary Bike", 1, 1, 0, "10 minutes moderate", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "beginner", "Warmup on bike before lifting", "Brisk Walk"),
        ex("Back Squat", 3, 8, 90, "Moderate", "Barbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Leg strength for cycling power", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Posterior chain for pedaling", "Dumbbell RDL"),
        ex("Leg Press", 3, 10, 60, "Moderate to heavy", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Quad strength for climbing", "Goblet Squat"),
        ex("Calf Raise", 3, 15, 30, "Heavy", "Calf Raise Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Ankle push for pedaling", "Standing Calf Raise"),
    ])

def hiit_strength():
    return wo("HIIT + Strength", "hybrid", 35, [
        ex("Kettlebell Swing", 3, 15, 30, "Explosive", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Power and cardio combined", "Dumbbell Swing"),
        ex("Dumbbell Bench Press", 3, 8, 60, "Moderate", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Strength between intervals", "Push-Up"),
        ex("Burpee", 3, 8, 30, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "HIIT cardio burst", "Squat Thrust"),
        ex("Dumbbell Row", 3, 8, 45, "Each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Pulling strength", "Band Row"),
        ex("Mountain Climber", 3, 20, 30, "Fast pace", "Bodyweight", "Core", "Hip Flexors", ["Core", "Shoulders"], "intermediate", "Cardio interval", "High Knees"),
        ex("Goblet Squat", 3, 10, 45, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Lower body strength", "Bodyweight Squat"),
    ])

def endurance_power():
    return wo("Endurance + Power", "hybrid", 40, [
        ex("Power Clean", 3, 5, 90, "Moderate", "Barbell", "Full Body", "Glutes", ["Trapezius", "Core"], "intermediate", "Explosive power development", "Hang Clean"),
        ex("Box Jump", 3, 8, 45, "Moderate height", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive leg power", "Squat Jump"),
        ex("Rowing Machine", 1, 1, 60, "1000m moderate", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps"], "intermediate", "Endurance between power sets", "Jump Rope"),
        ex("Push Press", 3, 6, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "intermediate", "Upper body power", "Overhead Press"),
        ex("Assault Bike Sprint", 3, 30, 90, "30 seconds max", "Stationary Bike", "Full Body", "Quadriceps", ["Hamstrings"], "intermediate", "Endurance intervals", "Burpees"),
    ])

def crossfit_hybrid():
    return wo("CrossFit Hybrid", "hybrid", 40, [
        ex("Thruster", 3, 10, 60, "Moderate barbell", "Barbell", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "intermediate", "Front squat to overhead press in one movement", "Dumbbell Thruster"),
        ex("Pull-Up", 3, 8, 45, "Kipping or strict", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "High-rep pulling", "Lat Pulldown"),
        ex("Kettlebell Swing", 3, 15, 30, "Russian or American", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip hinge power", "Dumbbell Swing"),
        ex("Box Jump", 3, 10, 30, "Moderate", "Plyo Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive jumping", "Squat Jump"),
        ex("Burpee", 3, 10, 30, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full body conditioning", "Squat Thrust"),
    ])

def martial_arts_weights():
    return wo("Martial Arts + Weights", "hybrid", 40, [
        ex("Shadow Boxing", 2, 1, 30, "3 minutes", "Bodyweight", "Full Body", "Deltoids", ["Core", "Calves"], "intermediate", "Warm up with combinations", "Punching Bag"),
        ex("Deadlift", 3, 5, 90, "Heavy", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae"], "intermediate", "Hip power for kicks and throws", "Trap Bar Deadlift"),
        ex("Overhead Press", 3, 6, 60, "Moderate", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Shoulder strength for strikes", "Dumbbell Press"),
        ex("Medicine Ball Rotational Throw", 3, 10, 30, "Each side", "Medicine Ball", "Core", "Obliques", ["Shoulders"], "intermediate", "Rotational power for strikes", "Russian Twist"),
        ex("Box Jump", 3, 8, 45, "Explosive", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive power for kicks", "Squat Jump"),
    ])

def calisthenics_weights():
    return wo("Calisthenics + Weights", "hybrid", 40, [
        ex("Pull-Up", 3, 8, 60, "Strict form", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Calisthenics pulling", "Lat Pulldown"),
        ex("Dip", 3, 8, 60, "Parallel bars", "Parallel Bars", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Calisthenics pushing", "Push-Up"),
        ex("Back Squat", 3, 8, 90, "Heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Weighted leg development", "Goblet Squat"),
        ex("Muscle-Up Negative", 3, 3, 60, "Slow eccentric", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Jump to top, lower slowly through transition", "Pull-Up"),
        ex("Dumbbell Lateral Raise", 3, 12, 30, "Light", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder isolation not possible with calisthenics alone", "Band Lateral Raise"),
    ])

def sport_gym():
    return wo("Sport + Gym", "hybrid", 40, [
        ex("Back Squat", 3, 6, 90, "Moderate to heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Leg strength for sport performance", "Goblet Squat"),
        ex("Bench Press", 3, 8, 60, "Moderate", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Upper body pushing power", "Dumbbell Press"),
        ex("Power Clean", 3, 5, 90, "Moderate", "Barbell", "Full Body", "Glutes", ["Trapezius", "Core"], "intermediate", "Explosive power for sports", "Hang Clean"),
        ex("Agility Ladder", 3, 2, 30, "Full ladder", "Agility Ladder", "Legs", "Calves", ["Hip Flexors", "Core"], "intermediate", "Sport-specific footwork", "Quick Feet"),
        ex("Medicine Ball Throw", 3, 10, 30, "Rotational", "Medicine Ball", "Core", "Obliques", ["Shoulders"], "intermediate", "Sport-specific rotational power", "Russian Twist"),
    ])

# Generate Cat 41 programs
cat41_programs = [
    ("Strength + Cardio Hybrid", "Hybrid Training", [4, 8, 12], [4, 5], "Efficient combination of heavy strength with cardio intervals", "High", True,
     lambda w, t: [strength_cardio_hybrid(), strength_cardio_hybrid(), strength_cardio_hybrid()]),
    ("Run + Lift Hybrid", "Hybrid Training", [4, 8, 12], [4, 5], "Combine running and weightlifting in one program", "High", True,
     lambda w, t: [run_lift_hybrid(), run_lift_hybrid(), run_lift_hybrid()]),
    ("Swim + Strength", "Hybrid Training", [4, 8], [4, 5], "Dryland strength training to complement swimming", "Med", True,
     lambda w, t: [swim_strength(), swim_strength(), swim_strength()]),
    ("Yoga + Strength", "Hybrid Training", [4, 8], [4, 5], "Iron and flexibility fusion for balanced fitness", "Low", False,
     lambda w, t: [yoga_strength(), yoga_strength(), yoga_strength()]),
    ("Boxing + Strength", "Hybrid Training", [4, 8, 12], [4, 5], "Combine boxing conditioning with strength training", "Med", True,
     lambda w, t: [boxing_strength(), boxing_strength(), boxing_strength()]),
    ("Cycling + Weights", "Hybrid Training", [4, 8, 12], [4, 5], "Leg-focused strength training for cyclists", "Med", True,
     lambda w, t: [cycling_weights(), cycling_weights(), cycling_weights()]),
    ("HIIT + Strength", "Hybrid Training", [4, 8], [4, 5], "Alternate between HIIT intervals and strength sets", "High", True,
     lambda w, t: [hiit_strength(), hiit_strength(), hiit_strength()]),
    ("Endurance + Power", "Hybrid Training", [4, 8, 12], [4, 5], "Build both endurance and explosive power simultaneously", "Med", True,
     lambda w, t: [endurance_power(), endurance_power(), endurance_power()]),
    ("CrossFit Hybrid", "Hybrid Training", [4, 8, 12], [4, 5], "Functional fitness variety with CrossFit-style programming", "Med", True,
     lambda w, t: [crossfit_hybrid(), crossfit_hybrid(), crossfit_hybrid()]),
    ("Martial Arts + Weights", "Hybrid Training", [4, 8, 12], [4, 5], "Combine martial arts with weight training for combat fitness", "Med", True,
     lambda w, t: [martial_arts_weights(), martial_arts_weights(), martial_arts_weights()]),
    ("Calisthenics + Weights", "Hybrid Training", [4, 8, 12], [4, 5], "Best of both bodyweight and barbell training", "Med", True,
     lambda w, t: [calisthenics_weights(), calisthenics_weights(), calisthenics_weights()]),
    ("Sport + Gym", "Hybrid Training", [4, 8], [4, 5], "Gym strength training paired with sport-specific drills", "Low", True,
     lambda w, t: [sport_gym(), sport_gym(), sport_gym()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat41_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Foundation: establish base in both disciplines"
            elif p <= 0.66: focus = f"Week {w} - Integration: blend modalities with progressive load"
            else: focus = f"Week {w} - Optimize: peak performance in combined training"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 41 HYBRID TRAINING COMPLETE ===")

# ========================================================================
# CAT 42 - COMPETITION/RACE PREP (14 programs)
# ========================================================================

def marathon_prep():
    return wo("Marathon Prep", "endurance", 45, [
        ex("Long Run", 1, 1, 0, "60-90 minutes easy pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "intermediate", "Conversational pace, build aerobic base for 26.2 miles", "Treadmill Run"),
        ex("Tempo Run", 1, 1, 0, "20 minutes at marathon pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Comfortably hard, lactate threshold work", "Moderate Run"),
        ex("Goblet Squat", 3, 10, 45, "Runner strength", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Leg strength for late-race power", "Bodyweight Squat"),
        ex("Single-Leg Calf Raise", 3, 15, 30, "Each leg", "Bodyweight", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Calf endurance for long distances", "Double Calf Raise"),
    ])

def half_marathon_prep():
    return wo("Half Marathon Prep", "endurance", 40, [
        ex("Tempo Run", 1, 1, 0, "20 minutes at half marathon pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Hold pace that is hard but manageable", "Moderate Run"),
        ex("Interval Run", 4, 1, 90, "3 minutes hard, 90 sec easy", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "VO2 max intervals for speed endurance", "Hill Sprint"),
        ex("Lunge", 3, 10, 30, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Leg strength for race day", "Reverse Lunge"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core stability for running form", "Dead Bug"),
    ])

def triathlon_prep():
    return wo("Triathlon Prep", "endurance", 50, [
        ex("Swim Drill (Dryland)", 3, 15, 30, "Arm stroke simulation", "Resistance Band", "Shoulders", "Deltoids", ["Latissimus Dorsi", "Core"], "intermediate", "Simulate swim stroke against resistance", "Band Pull"),
        ex("Stationary Bike", 1, 1, 0, "15 minutes moderate", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Build cycling legs for bike segment", "Bodyweight Squat"),
        ex("Run", 1, 1, 0, "10 minutes at race pace", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Brick run after bike to simulate T2", "Brisk Walk"),
        ex("Goblet Squat", 3, 10, 45, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Overall leg strength for all three sports", "Bodyweight Squat"),
        ex("Pull-Up", 3, 6, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Pulling strength for swimming", "Lat Pulldown"),
    ])

def spartan_race_prep():
    return wo("Spartan Race Prep", "functional", 45, [
        ex("Pull-Up", 4, 6, 60, "Various grips", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Wall climbs and rope climbs", "Lat Pulldown"),
        ex("Burpee", 3, 15, 30, "Penalty burpees practice", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "30 penalty burpees per failed obstacle", "Squat Thrust"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40m", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "intermediate", "Bucket carry simulation", "Suitcase Carry"),
        ex("Box Jump", 3, 10, 30, "Various heights", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Wall and obstacle jumping", "Squat Jump"),
        ex("Bear Crawl", 3, 1, 30, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Barbed wire crawl simulation", "Crawl"),
        ex("Dead Hang", 3, 1, 30, "Hold 30 seconds", "Pull-Up Bar", "Arms", "Forearms", ["Shoulders"], "intermediate", "Multi-rig and monkey bar grip", "Towel Hang"),
    ])

def tough_mudder_prep():
    return wo("Tough Mudder Prep", "functional", 45, [
        ex("Run", 1, 1, 0, "15 minutes moderate", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "10+ mile race requires running base", "Brisk Walk"),
        ex("Pull-Up", 3, 8, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Obstacle climbing strength", "Lat Pulldown"),
        ex("Burpee", 3, 10, 30, "Full burpees", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "General obstacle readiness", "Squat Thrust"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 40m", "Dumbbell", "Full Body", "Forearms", ["Core"], "intermediate", "Carry-based obstacles", "Bucket Carry"),
        ex("Bear Crawl", 3, 1, 30, "20 meters", "Bodyweight", "Full Body", "Shoulders", ["Core"], "intermediate", "Crawl under obstacles", "Crawl"),
    ])

def crossfit_games_prep():
    return wo("CrossFit Games Prep", "functional", 45, [
        ex("Thruster", 3, 10, 60, "Moderate barbell", "Barbell", "Full Body", "Quadriceps", ["Shoulders", "Core"], "advanced", "Signature CrossFit movement", "Dumbbell Thruster"),
        ex("Pull-Up", 3, 15, 45, "Kipping or butterfly", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "High-rep pulling for WODs", "Lat Pulldown"),
        ex("Deadlift", 3, 5, 90, "Heavy", "Barbell", "Back", "Glutes", ["Hamstrings"], "intermediate", "Foundation barbell strength", "Trap Bar Deadlift"),
        ex("Muscle-Up", 3, 3, 60, "Ring or bar", "Rings", "Full Body", "Latissimus Dorsi", ["Chest", "Triceps"], "advanced", "Advanced gymnastics movement", "Pull-Up + Dip"),
        ex("Rowing Machine", 1, 1, 0, "1000m hard", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Quadriceps"], "intermediate", "Cardio engine for competition", "Assault Bike"),
    ])

def powerlifting_meet_prep():
    return wo("Powerlifting Meet Prep", "strength", 60, [
        ex("Back Squat", 5, 3, 180, "Heavy, build to singles", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core", "Erector Spinae"], "advanced", "Competition squat with pause at bottom", "Goblet Squat"),
        ex("Bench Press", 5, 3, 180, "Heavy, competition pause", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Pause on chest, press command simulation", "Dumbbell Press"),
        ex("Deadlift", 4, 2, 240, "Heavy singles approach", "Barbell", "Back", "Glutes", ["Hamstrings", "Erector Spinae", "Quadriceps"], "advanced", "Competition deadlift, lockout and hold", "Trap Bar Deadlift"),
        ex("Accessory Row", 3, 10, 60, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Back strength for all three lifts", "Dumbbell Row"),
    ])

def bodybuilding_show_prep():
    return wo("Bodybuilding Show Prep", "hypertrophy", 60, [
        ex("Incline Dumbbell Press", 4, 12, 60, "Moderate, high rep", "Dumbbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Upper chest development for stage", "Incline Barbell Press"),
        ex("Lat Pulldown", 4, 12, 45, "Wide grip", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Back width for V-taper on stage", "Pull-Up"),
        ex("Lateral Raise", 4, 15, 30, "Light, controlled", "Dumbbell", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder caps for stage presentation", "Band Lateral Raise"),
        ex("Leg Extension", 4, 15, 30, "Squeeze at top", "Machine", "Legs", "Quadriceps", [], "beginner", "Quad detail and separation", "Sissy Squat"),
        ex("Leg Curl", 4, 12, 30, "Squeeze at bottom", "Machine", "Legs", "Hamstrings", [], "beginner", "Hamstring detail for rear poses", "Nordic Curl"),
        ex("Posing Practice", 2, 1, 0, "5 minutes mandatory poses", "Bodyweight", "Full Body", "All Muscles", [], "beginner", "Practice mandatory poses with flex and hold", "Flexing"),
    ])

def boxing_match_prep():
    return wo("Boxing Match Prep", "conditioning", 45, [
        ex("Shadow Boxing", 3, 1, 30, "3 minute rounds", "Bodyweight", "Full Body", "Deltoids", ["Core", "Calves"], "intermediate", "Work combinations, footwork, defense", "Punching Bag"),
        ex("Heavy Bag Work", 3, 1, 60, "3 minute rounds", "Heavy Bag", "Full Body", "Deltoids", ["Pectoralis Major", "Core", "Calves"], "intermediate", "Power punches and combinations", "Shadow Boxing"),
        ex("Sprint Interval", 4, 30, 60, "30 second sprints", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Simulate fight conditioning bursts", "High Knees"),
        ex("Medicine Ball Slam", 3, 15, 30, "Explosive", "Medicine Ball", "Full Body", "Deltoids", ["Core"], "intermediate", "Punching power development", "Battle Rope Slam"),
        ex("Russian Twist", 3, 20, 30, "With medicine ball", "Medicine Ball", "Core", "Obliques", [], "intermediate", "Rotational power for hooks", "Cable Rotation"),
    ])

def mma_fight_prep():
    return wo("MMA Fight Prep", "conditioning", 50, [
        ex("Shadow Boxing", 2, 1, 30, "3 minute rounds", "Bodyweight", "Full Body", "Deltoids", ["Core", "Calves"], "intermediate", "Striking combinations", "Punching Bag"),
        ex("Wrestling Drill", 3, 1, 45, "Sprawl and level change", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Sprawl 5 times, shoot 5 times per set", "Burpee"),
        ex("Pull-Up", 3, 8, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Clinch and grappling strength", "Lat Pulldown"),
        ex("Kettlebell Swing", 3, 15, 30, "Explosive", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip power for takedowns and strikes", "Dumbbell Swing"),
        ex("Neck Bridge", 3, 1, 30, "Hold 15 seconds", "Bodyweight", "Neck", "Neck Flexors", ["Trapezius"], "intermediate", "Neck strength for fighting", "Neck Curl"),
    ])

def wrestling_prep():
    return wo("Wrestling Prep", "conditioning", 45, [
        ex("Sprawl", 3, 10, 30, "Explosive sprawls", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Defend takedowns with explosive hip drop", "Burpee"),
        ex("Pull-Up", 3, 8, 60, "Full range", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Grip and pulling for grappling", "Lat Pulldown"),
        ex("Rope Climb", 3, 2, 90, "Full rope", "Climbing Rope", "Full Body", "Latissimus Dorsi", ["Biceps", "Forearms"], "advanced", "Grip and upper body for scrambles", "Towel Pull-Up"),
        ex("Farmer's Walk", 3, 1, 60, "Heavy, 30m", "Dumbbell", "Full Body", "Forearms", ["Core", "Trapezius"], "intermediate", "Grip endurance for holds", "Suitcase Carry"),
        ex("Bridge", 3, 1, 30, "Hold 20 seconds", "Bodyweight", "Neck", "Neck Extensors", ["Trapezius", "Erector Spinae"], "intermediate", "Wrestling bridge for escape", "Glute Bridge"),
    ])

def track_field_prep():
    return wo("Track and Field Prep", "conditioning", 40, [
        ex("Sprint", 4, 1, 120, "60 meters at 95%", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Glutes"], "advanced", "Competition sprint practice", "High Knees"),
        ex("A-Skip", 3, 20, 30, "20 meters", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Calves"], "intermediate", "Sprint mechanics drill", "High Knees"),
        ex("Box Jump", 3, 8, 60, "Explosive", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive power for jumps and sprints", "Squat Jump"),
        ex("Power Clean", 3, 5, 90, "Moderate to heavy", "Barbell", "Full Body", "Glutes", ["Trapezius", "Quadriceps"], "intermediate", "Triple extension power", "Hang Clean"),
        ex("Back Squat", 3, 5, 120, "Heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Leg strength base", "Goblet Squat"),
    ])

def swimming_meet_prep():
    return wo("Swimming Meet Prep", "conditioning", 40, [
        ex("Lat Pulldown", 4, 10, 45, "Moderate to heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Primary swim pulling strength", "Band Pulldown"),
        ex("Rotational Medicine Ball Throw", 3, 10, 30, "Each side", "Medicine Ball", "Core", "Obliques", ["Shoulders"], "intermediate", "Turn and flip power", "Russian Twist"),
        ex("Jump Squat", 3, 8, 45, "Explosive", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Start and turn explosive power", "Squat Jump"),
        ex("Shoulder External Rotation", 3, 12, 30, "Light band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Rear Deltoids"], "beginner", "Injury prevention for shoulder health", "Cable External Rotation"),
        ex("Streamline Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "beginner", "Arms overhead, tight body line on back", "Plank"),
    ])

def cycling_race_prep():
    return wo("Cycling Race Prep", "conditioning", 40, [
        ex("Leg Press", 3, 10, 60, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Leg power for climbing and sprinting", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 60, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Posterior chain for pedaling power", "Dumbbell RDL"),
        ex("Stationary Bike Interval", 4, 1, 120, "2 min hard, 2 min easy", "Stationary Bike", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Race simulation intervals", "Outdoor Ride"),
        ex("Calf Raise", 3, 15, 30, "Heavy, slow", "Calf Raise Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Ankle push phase of pedaling", "Standing Calf Raise"),
        ex("Plank", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Core for aero position and climbing", "Dead Bug"),
    ])

# Generate Cat 42 programs
cat42_programs = [
    ("Marathon Prep", "Competition/Race Prep", [8, 12, 16], [4, 5], "Complete marathon training with strength and endurance", "High", False,
     lambda w, t: [marathon_prep(), marathon_prep(), marathon_prep()]),
    ("Half Marathon Prep", "Competition/Race Prep", [8, 12], [4, 5], "Half marathon race preparation program", "High", False,
     lambda w, t: [half_marathon_prep(), half_marathon_prep(), half_marathon_prep()]),
    ("Triathlon Prep", "Competition/Race Prep", [8, 12, 16], [5, 6], "Multi-discipline triathlon preparation", "High", False,
     lambda w, t: [triathlon_prep(), triathlon_prep(), triathlon_prep()]),
    ("Spartan Race Prep", "Competition/Race Prep", [8, 12, 16], [5, 6], "Obstacle course race training for Spartan events", "High", True,
     lambda w, t: [spartan_race_prep(), spartan_race_prep(), spartan_race_prep()]),
    ("Tough Mudder Prep", "Competition/Race Prep", [8, 12], [5, 6], "Mud run and obstacle course preparation", "High", True,
     lambda w, t: [tough_mudder_prep(), tough_mudder_prep(), tough_mudder_prep()]),
    ("CrossFit Games Prep", "Competition/Race Prep", [8, 12], [5, 6], "Preparation for CrossFit competition events", "Med", True,
     lambda w, t: [crossfit_games_prep(), crossfit_games_prep(), crossfit_games_prep()]),
    ("Powerlifting Meet Prep", "Competition/Race Prep", [8, 12, 16], [4, 5], "Competition peaking program for powerlifting meets", "Low", False,
     lambda w, t: [powerlifting_meet_prep(), powerlifting_meet_prep(), powerlifting_meet_prep()]),
    ("Bodybuilding Show Prep", "Competition/Race Prep", [12, 16, 20], [5, 6], "Stage-ready physique preparation for bodybuilding", "Low", True,
     lambda w, t: [bodybuilding_show_prep(), bodybuilding_show_prep(), bodybuilding_show_prep()]),
    ("Boxing Match Prep", "Competition/Race Prep", [8, 12], [5, 6], "Fight camp preparation for boxing matches", "Med", True,
     lambda w, t: [boxing_match_prep(), boxing_match_prep(), boxing_match_prep()]),
    ("MMA Fight Prep", "Competition/Race Prep", [8, 12], [5, 6], "Complete fight camp for MMA competitions", "Med", True,
     lambda w, t: [mma_fight_prep(), mma_fight_prep(), mma_fight_prep()]),
    ("Wrestling Prep", "Competition/Race Prep", [8, 12], [5, 6], "Wrestling competition preparation with grappling conditioning", "Med", True,
     lambda w, t: [wrestling_prep(), wrestling_prep(), wrestling_prep()]),
    ("Track & Field Prep", "Competition/Race Prep", [8, 12, 16], [4, 5], "Track and field competition preparation", "Med", False,
     lambda w, t: [track_field_prep(), track_field_prep(), track_field_prep()]),
    ("Swimming Meet Prep", "Competition/Race Prep", [8, 12], [4, 5], "Dryland training for swimming competition", "Low", True,
     lambda w, t: [swimming_meet_prep(), swimming_meet_prep(), swimming_meet_prep()]),
    ("Cycling Race Prep", "Competition/Race Prep", [8, 12, 16], [4, 5], "Strength and interval training for cycling races", "Low", False,
     lambda w, t: [cycling_race_prep(), cycling_race_prep(), cycling_race_prep()]),
]

for prog_name, cat, durs, sessions_list, desc, pri, ss, workout_fn in cat42_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}"); continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur
            if p <= 0.33: focus = f"Week {w} - Base: build aerobic and strength foundation for competition"
            elif p <= 0.66: focus = f"Week {w} - Build: race-specific intensity and skill work"
            elif p <= 0.9: focus = f"Week {w} - Peak: competition simulation and high intensity"
            else: focus = f"Week {w} - Taper: reduce volume, maintain intensity, prepare to compete"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, ss, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"{prog_name} - DONE")

print("\n=== CAT 42 COMPETITION/RACE PREP COMPLETE ===")

helper.close()
print("\n=== PART 3 (CATS 39-42) COMPLETE ===")
