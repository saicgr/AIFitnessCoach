#!/usr/bin/env python3
"""Generate High-priority Fat Loss programs:
- Shred Program (2,4,6,8,12w × 4-5/wk)
- HIIT Burner (1,2,4,6w × 3-4/wk)
- Metabolic Conditioning (2,4,8w × 4-5/wk)
- Cut & Maintain (4,8,12w × 4-5/wk)
- Full Body Fat Torch (2,4,8w × 4-5/wk)
- Wedding Ready Shred (4,6,8,12w × 5-6/wk)
- Extreme Shred (4,6w × 6/wk)
"""
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
# 1. SHRED PROGRAM - Circuit-style training with strength base
# ========================================================================

def shred_upper_circuit():
    return wo("Upper Body Circuit", "fat_loss", 50, [
        ex("Dumbbell Bench Press", 4, 12, 45, "Moderate, fast tempo", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Explosive press, controlled lower", "Push-Up"),
        ex("Barbell Bent-Over Row", 4, 12, 45, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Strict form, squeeze back", "Dumbbell Row"),
        ex("Dumbbell Shoulder Press", 3, 12, 30, "Light-moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Full ROM, keep tension", "Machine Press"),
        ex("Lat Pulldown", 3, 12, 30, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Wide grip, pull to chest", "Band Pulldown"),
        ex("Dumbbell Curl to Press", 3, 10, 30, "Light", "Dumbbells", "Arms", "Biceps", ["Anterior Deltoid"], "beginner", "Curl then press overhead, one movement", "Band Curl"),
        ex("Mountain Climbers", 3, 20, 30, "Bodyweight, max speed", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Hips low, drive knees to chest", "High Knees"),
    ])

def shred_lower_circuit():
    return wo("Lower Body Circuit", "fat_loss", 50, [
        ex("Goblet Squat", 4, 15, 30, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Fast tempo, deep squat", "Bodyweight Squat"),
        ex("Kettlebell Swing", 4, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Hip snap, don't arm pull", "Dumbbell Swing"),
        ex("Walking Lunges", 3, 12, 30, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Quick tempo, long strides", "Reverse Lunges"),
        ex("Romanian Deadlift", 3, 12, 45, "Moderate", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Feel stretch, explosive up", "Bodyweight Good Morning"),
        ex("Box Jump", 3, 10, 45, "Bodyweight, 20-24 inch box", "Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Soft landing, step down", "Squat Jump"),
        ex("Plank to Push-Up", 3, 10, 30, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Minimize hip sway", "Plank"),
    ])

def shred_hiit_cardio():
    return wo("HIIT Cardio + Core", "fat_loss", 40, [
        ex("Burpees", 4, 10, 30, "Bodyweight, max effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Shoulders"], "intermediate", "Full extension at top, chest to floor", "Squat Thrust"),
        ex("Battle Ropes", 4, 1, 30, "30 seconds max effort", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Alternating waves, stay low", "Jumping Jacks"),
        ex("Rowing Machine", 4, 1, 30, "30 seconds sprint", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Legs", "Core"], "beginner", "Push with legs, pull with arms", "Cycling Sprint"),
        ex("Russian Twist", 3, 20, 30, "Light dumbbell", "Dumbbell", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet elevated, rotate fully", "Bicycle Crunch"),
        ex("Bicycle Crunch", 3, 20, 30, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Elbow to opposite knee", "Oblique Crunch"),
        ex("Dead Bug", 3, 12, 30, "Bodyweight, slow tempo", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Lower back stays flat", "Bird Dog"),
    ])

def shred_full_body():
    return wo("Full Body Metabolic", "fat_loss", 45, [
        ex("Thruster", 4, 10, 45, "Moderate dumbbells", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps", "Core"], "intermediate", "Deep squat then press overhead", "Squat to Press"),
        ex("Renegade Row", 3, 8, 30, "Moderate dumbbells", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row each arm", "Bent-Over Row"),
        ex("Step-Up with Curl", 3, 10, 30, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Biceps", "Glutes"], "beginner", "Step up then curl at top", "Bodyweight Step-Up"),
        ex("Push-Up to Side Plank", 3, 8, 30, "Bodyweight", "Bodyweight", "Full Body", "Pectoralis Major", ["Core", "Obliques"], "intermediate", "Push-up then rotate to side", "Push-Up"),
        ex("Jump Squat", 3, 12, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, explosive jump, soft land", "Squat"),
        ex("Hanging Leg Raise", 3, 12, 30, "Bodyweight", "Pull-Up Bar", "Core", "Lower Abdominals", ["Hip Flexors"], "intermediate", "Control swing, curl pelvis", "Lying Leg Raise"),
    ])

weeks_data = {}
for dur in [2, 4, 6, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Conditioning base: build work capacity"
        elif p <= 0.5: focus = f"Week {w} - Fat burning: increase circuit intensity"
        elif p <= 0.75: focus = f"Week {w} - Peak shred: maximum metabolic stress"
        else: focus = f"Week {w} - Maintain/consolidate: sustain results"
        if w % 4 == 1:
            wkts = [shred_upper_circuit(), shred_lower_circuit(), shred_hiit_cardio(), shred_full_body()]
        elif w % 4 == 2:
            wkts = [shred_lower_circuit(), shred_upper_circuit(), shred_full_body(), shred_hiit_cardio()]
        elif w % 4 == 3:
            wkts = [shred_full_body(), shred_hiit_cardio(), shred_upper_circuit(), shred_lower_circuit()]
        else:
            wkts = [shred_hiit_cardio(), shred_full_body(), shred_lower_circuit(), shred_upper_circuit()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [4, 5]:
        weeks_data[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Shred Program", "Fat Loss",
    "Deficit-optimized circuit training for maximum fat loss while preserving muscle",
    [2, 4, 6, 8, 12], [4, 5], True, "High", weeks_data, mn)
if s: helper.update_tracker("Shred Program", "Done"); print("Shred Program - DONE")

# ========================================================================
# 2. HIIT BURNER - High intensity interval training
# ========================================================================

def hiit_session_a():
    return wo("HIIT Session A - Upper Focus", "hiit", 35, [
        ex("Burpees", 4, 10, 20, "Max effort 30s on / 15s off", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension jump, chest to floor", "Squat Thrust"),
        ex("Dumbbell Thrusters", 4, 10, 20, "Light-moderate", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Deep squat to overhead press", "Bodyweight Squat to Press"),
        ex("Push-Up", 4, 15, 20, "Bodyweight, max speed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM, explosive", "Knee Push-Up"),
        ex("Mountain Climbers", 4, 20, 20, "Max speed, 30s", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Drive knees to chest fast", "High Knees"),
        ex("Jumping Jacks", 3, 30, 15, "Max effort", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Quadriceps"], "beginner", "Arms fully overhead", "Star Jumps"),
    ])

def hiit_session_b():
    return wo("HIIT Session B - Lower Focus", "hiit", 35, [
        ex("Jump Squat", 4, 12, 20, "Bodyweight, explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, max height jump", "Squat"),
        ex("Kettlebell Swing", 4, 15, 20, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap", "Dumbbell Swing"),
        ex("Skater Jump", 4, 12, 20, "Bodyweight, side to side", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly, touch floor", "Lateral Lunge"),
        ex("High Knees", 4, 30, 20, "Max speed, 30s", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core"], "beginner", "Drive knees high, pump arms", "Marching"),
        ex("Plank Jacks", 3, 20, 15, "Bodyweight, fast", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Abductors", "Shoulders"], "beginner", "Jump feet wide and narrow", "Plank"),
    ])

def hiit_session_c():
    return wo("HIIT Session C - Total Body Blast", "hiit", 35, [
        ex("Devil Press", 4, 8, 20, "Light dumbbells", "Dumbbells", "Full Body", "Shoulders", ["Chest", "Legs", "Core"], "advanced", "Burpee with dumbbell snatch overhead", "Burpee"),
        ex("Box Jump", 4, 10, 20, "20-24 inch box", "Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive jump, soft landing", "Squat Jump"),
        ex("Battle Ropes", 4, 1, 20, "30s alternating waves", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Stay low, max intensity", "Jumping Jacks"),
        ex("Tuck Jump", 3, 10, 20, "Bodyweight, max height", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Knees to chest at peak", "Squat Jump"),
        ex("Bear Crawl", 3, 1, 15, "20 yards forward and back", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "Hips low, opposite arm/leg", "Mountain Climbers"),
    ])

weeks_data2 = {}
for dur in [1, 2, 4, 6]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur if dur > 1 else 0.5
        if p <= 0.3: focus = f"Week {w} - Build HIIT tolerance"
        elif p <= 0.6: focus = f"Week {w} - Increase intervals and intensity"
        else: focus = f"Week {w} - Peak intensity, shorter rest periods"
        if w % 3 == 1: wkts = [hiit_session_a(), hiit_session_b(), hiit_session_c()]
        elif w % 3 == 2: wkts = [hiit_session_b(), hiit_session_c(), hiit_session_a()]
        else: wkts = [hiit_session_c(), hiit_session_a(), hiit_session_b()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [3, 4]:
        weeks_data2[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("HIIT Burner", "Fat Loss",
    "High intensity interval training for maximum calorie burn in minimum time",
    [1, 2, 4, 6], [3, 4], True, "High", weeks_data2, mn)
if s: helper.update_tracker("HIIT Burner", "Done"); print("HIIT Burner - DONE")

# ========================================================================
# 3. METABOLIC CONDITIONING - Circuit-based
# ========================================================================

def metcon_a():
    return wo("MetCon A - Strength Circuit", "conditioning", 45, [
        ex("Barbell Clean and Press", 4, 8, 45, "Moderate", "Barbell", "Full Body", "Shoulders", ["Quadriceps", "Glutes", "Trapezius"], "intermediate", "Explosive clean, press overhead", "Dumbbell Clean and Press"),
        ex("Front Squat", 4, 10, 30, "Moderate", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, deep squat", "Goblet Squat"),
        ex("Push-Up", 3, 15, 20, "Bodyweight, fast", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Chest to floor, explosive up", "Knee Push-Up"),
        ex("Dumbbell Row", 3, 12, 30, "Moderate, each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Fast tempo, squeeze", "Band Row"),
        ex("Kettlebell Swing", 3, 15, 20, "Moderate-heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip snap, chest up", "Dumbbell Swing"),
        ex("V-Up", 3, 15, 20, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Touch toes at top", "Crunch"),
    ])

def metcon_b():
    return wo("MetCon B - Cardio Circuit", "conditioning", 45, [
        ex("Rowing Machine", 4, 1, 30, "500m sprint", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Legs", "Core"], "beginner", "Legs first, then lean and pull", "Cycling Sprint"),
        ex("Thruster", 4, 10, 30, "Light-moderate dumbbells", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Deep squat then press", "Bodyweight Squat"),
        ex("Box Step-Up", 3, 12, 20, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Drive through top foot", "Bodyweight Step-Up"),
        ex("Renegade Row", 3, 8, 30, "Moderate dumbbells", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Stable hips, row each side", "Dumbbell Row"),
        ex("Burpees", 3, 8, 20, "Bodyweight", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension at top", "Squat Thrust"),
        ex("Plank", 3, 1, 15, "45-60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Squeeze everything tight", "Dead Bug"),
    ])

weeks_data3 = {}
for dur in [2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.3: focus = f"Week {w} - Build metabolic base, longer rests"
        elif p <= 0.6: focus = f"Week {w} - Reduce rest periods, increase load"
        else: focus = f"Week {w} - Peak conditioning, minimal rest"
        if w % 2 == 1: wkts = [metcon_a(), metcon_b(), metcon_a(), metcon_b()]
        else: wkts = [metcon_b(), metcon_a(), metcon_b(), metcon_a()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [4, 5]:
        weeks_data3[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Metabolic Conditioning", "Fat Loss",
    "Circuit-based metabolic conditioning for fat loss and work capacity",
    [2, 4, 8], [4, 5], True, "High", weeks_data3, mn)
if s: helper.update_tracker("Metabolic Conditioning", "Done"); print("Metabolic Conditioning - DONE")

# ========================================================================
# 4. CUT & MAINTAIN - Muscle-preserving fat loss
# ========================================================================

def cut_upper():
    return wo("Upper Body Strength", "strength", 55, [
        ex("Barbell Bench Press", 4, 6, 120, "85% 1RM, maintain strength", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Heavy but controlled, preserve max strength", "Dumbbell Bench Press"),
        ex("Barbell Bent-Over Row", 4, 6, 120, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Strict form, pull to navel", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 90, "Moderate-heavy", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Maintain pressing strength", "Dumbbell Shoulder Press"),
        ex("Pull-Up", 3, 8, 90, "Bodyweight or weighted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM, chin over bar", "Lat Pulldown"),
        ex("Dumbbell Lateral Raise", 3, 12, 45, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid", [], "beginner", "Maintain shoulder roundness", "Cable Lateral Raise"),
        ex("Barbell Curl", 2, 10, 45, "Moderate", "Barbell", "Arms", "Biceps", [], "beginner", "Quick arm volume", "Dumbbell Curl"),
    ])

def cut_lower():
    return wo("Lower Body Strength", "strength", 55, [
        ex("Barbell Back Squat", 4, 6, 150, "80-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Heavy squats to maintain leg mass", "Leg Press"),
        ex("Romanian Deadlift", 3, 8, 90, "Moderate-heavy", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Maintain posterior chain", "Dumbbell RDL"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Light-moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Unilateral work for balance", "Reverse Lunge"),
        ex("Leg Curl", 3, 12, 45, "Moderate", "Machine", "Legs", "Hamstrings", [], "beginner", "Squeeze at top", "Nordic Curl"),
        ex("Calf Raise", 3, 15, 30, "Moderate", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full ROM", "Seated Calf Raise"),
        ex("Hanging Leg Raise", 3, 12, 30, "Bodyweight", "Pull-Up Bar", "Core", "Lower Abdominals", ["Hip Flexors"], "intermediate", "Control swing", "Lying Leg Raise"),
    ])

def cut_cardio_circuit():
    return wo("Cardio Circuit", "fat_loss", 40, [
        ex("Kettlebell Swing", 4, 15, 20, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap", "Dumbbell Swing"),
        ex("Jump Rope", 4, 1, 20, "60 seconds", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Light feet, wrist action", "Jumping Jacks"),
        ex("Mountain Climbers", 3, 20, 15, "Max speed", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Drive knees to chest", "High Knees"),
        ex("Goblet Squat", 3, 15, 20, "Light", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Fast tempo, light weight", "Bodyweight Squat"),
        ex("Push-Up", 3, 12, 15, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Full ROM", "Knee Push-Up"),
    ])

weeks_data4 = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Moderate deficit, high protein, maintain lifts"
        elif p <= 0.5: focus = f"Week {w} - Increase cardio volume, maintain strength"
        elif p <= 0.75: focus = f"Week {w} - Peak deficit, focus on preserving strength"
        else: focus = f"Week {w} - Reverse diet prep, reduce cardio gradually"
        if w % 3 == 1: wkts = [cut_upper(), cut_lower(), cut_cardio_circuit(), cut_upper()]
        elif w % 3 == 2: wkts = [cut_lower(), cut_upper(), cut_cardio_circuit(), cut_lower()]
        else: wkts = [cut_upper(), cut_cardio_circuit(), cut_lower(), cut_upper()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [4, 5]:
        weeks_data4[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Cut & Maintain", "Fat Loss",
    "Preserve muscle while cutting - heavy compounds + strategic cardio",
    [4, 8, 12], [4, 5], True, "High", weeks_data4, mn)
if s: helper.update_tracker("Cut & Maintain", "Done"); print("Cut & Maintain - DONE")

# ========================================================================
# 5. FULL BODY FAT TORCH - Compound-focused fat loss
# ========================================================================

def torch_a():
    return wo("Fat Torch A - Push Emphasis", "fat_loss", 45, [
        ex("Thruster", 4, 12, 30, "Light-moderate dumbbells", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Deep squat then press", "Squat to Press"),
        ex("Dumbbell Bench Press", 3, 12, 45, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Fast tempo", "Push-Up"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
        ex("Push-Up", 3, 15, 20, "Bodyweight, fast", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM, explosive", "Knee Push-Up"),
        ex("Burpees", 3, 8, 30, "Max effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension at top", "Squat Thrust"),
        ex("Bicycle Crunch", 3, 20, 20, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Touch elbow to knee", "Crunch"),
    ])

def torch_b():
    return wo("Fat Torch B - Pull Emphasis", "fat_loss", 45, [
        ex("Deadlift", 4, 8, 60, "Moderate-heavy", "Barbell", "Full Body", "Erector Spinae", ["Glutes", "Hamstrings"], "intermediate", "Hip hinge, flat back", "Trap Bar Deadlift"),
        ex("Pull-Up", 3, 8, 45, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM", "Lat Pulldown"),
        ex("Goblet Squat", 3, 15, 30, "Light", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Fast tempo", "Bodyweight Squat"),
        ex("Renegade Row", 3, 8, 30, "Moderate dumbbells", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core"], "intermediate", "Stable hips", "Bent-Over Row"),
        ex("Box Jump", 3, 10, 30, "20-24 inch", "Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive, soft landing", "Squat Jump"),
        ex("Russian Twist", 3, 20, 20, "Light dumbbell", "Dumbbell", "Core", "Obliques", [], "beginner", "Rotate fully", "Bicycle Crunch"),
    ])

weeks_data5 = {}
for dur in [2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.3: focus = f"Week {w} - Build conditioning base"
        elif p <= 0.6: focus = f"Week {w} - Increase intensity and density"
        else: focus = f"Week {w} - Maximum metabolic output"
        if w % 2 == 1: wkts = [torch_a(), torch_b(), torch_a(), torch_b()]
        else: wkts = [torch_b(), torch_a(), torch_b(), torch_a()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [4, 5]:
        weeks_data5[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Full Body Fat Torch", "Fat Loss",
    "Compound movement focused fat loss with full body training every session",
    [2, 4, 8], [4, 5], True, "High", weeks_data5, mn)
if s: helper.update_tracker("Full Body Fat Torch", "Done"); print("Full Body Fat Torch - DONE")

# ========================================================================
# 6. EXTREME SHRED - 6 days, aggressive but safe
# ========================================================================

def extreme_am():
    return wo("AM - Fasted Cardio", "fat_loss", 30, [
        ex("Jump Rope", 5, 1, 15, "60s on, 15s off", "Jump Rope", "Full Body", "Calves", ["Shoulders"], "beginner", "Light feet, wrist rotation", "Jumping Jacks"),
        ex("Burpees", 4, 10, 20, "Max effort", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension", "Squat Thrust"),
        ex("Mountain Climbers", 4, 20, 15, "Sprint", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Fast as possible", "High Knees"),
        ex("Kettlebell Swing", 4, 15, 20, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings"], "intermediate", "Explosive hips", "Dumbbell Swing"),
    ])

def extreme_strength():
    return wo("PM - Strength Preservation", "strength", 50, [
        ex("Barbell Back Squat", 4, 5, 120, "80% 1RM", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Heavy, maintain max", "Leg Press"),
        ex("Barbell Bench Press", 4, 5, 120, "80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Maintain pressing power", "Dumbbell Bench Press"),
        ex("Barbell Bent-Over Row", 3, 8, 90, "Moderate-heavy", "Barbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Strict form", "Dumbbell Row"),
        ex("Overhead Press", 3, 8, 90, "Moderate", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Press overhead fully", "Dumbbell Press"),
        ex("Walking Lunges", 3, 12, 60, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Long strides", "Reverse Lunges"),
        ex("Plank", 3, 1, 30, "60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight everything", "Dead Bug"),
    ])

weeks_data6 = {}
for dur in [4, 6]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.3: focus = f"Week {w} - Ramp up: build deficit tolerance"
        elif p <= 0.6: focus = f"Week {w} - Peak shred: maximum calorie burn"
        elif p <= 0.8: focus = f"Week {w} - Maintain intensity, manage fatigue"
        else: focus = f"Week {w} - Final push: last effort before maintenance"
        wkts = [extreme_am(), extreme_strength(), extreme_am(), extreme_strength(), extreme_am(), extreme_strength()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    weeks_data6[(dur, 6)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Extreme Shred", "Fat Loss",
    "High-intensity 6-day fat burning with AM cardio and PM strength to maximize calorie burn",
    [4, 6], [6], True, "High", weeks_data6, mn)
if s: helper.update_tracker("Extreme Shred", "Done"); print("Extreme Shred - DONE")

helper.close()
print("\n=== ALL FAT LOSS HIGH PRIORITY PROGRAMS COMPLETE ===")
