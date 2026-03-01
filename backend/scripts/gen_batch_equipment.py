#!/usr/bin/env python3
"""Generate Equipment-Specific + Bodyweight High-priority programs:
- Dumbbell Only (1,2,4,8w × 3-4/wk)
- Kettlebell Program (2,4,8w × 3-4/wk)
- Resistance Band (2,4,8w × 3-4/wk)
- Strong Curves (4,8,12w × 4/wk) [Women's Health]
- Toned & Lean (4,8,12w × 4-5/wk) [Women's Health]
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
# 1. DUMBBELL ONLY - No barbell, no machines, just dumbbells
# ========================================================================

def db_upper_a():
    return wo("Upper A - Chest & Back", "hypertrophy", 50, [
        ex("Dumbbell Bench Press", 4, 10, 90, "Heavy dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full ROM, squeeze chest at top", "Floor Press"),
        ex("Dumbbell Row", 4, 10, 60, "Heavy, each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Support on bench, pull to hip", "Bent-Over Dumbbell Row"),
        ex("Dumbbell Incline Press", 3, 12, 60, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Use pillows/bench for incline", "Dumbbell Floor Flye"),
        ex("Dumbbell Pullover", 3, 12, 60, "Moderate, across bench", "Dumbbell", "Back", "Latissimus Dorsi", ["Chest", "Serratus"], "intermediate", "Feel lat stretch, controlled arc", "Straight-Arm Pullover"),
        ex("Dumbbell Flye", 3, 15, 45, "Light-moderate", "Dumbbells", "Chest", "Pectoralis Major", [], "beginner", "Slight elbow bend, wide arc", "Push-Up"),
        ex("Reverse Dumbbell Flye", 3, 15, 45, "Light", "Dumbbells", "Back", "Rear Deltoid", ["Rhomboids"], "beginner", "Bent over, squeeze shoulder blades", "Face Pull"),
    ])

def db_upper_b():
    return wo("Upper B - Shoulders & Arms", "hypertrophy", 50, [
        ex("Seated Dumbbell Shoulder Press", 4, 10, 90, "Heavy dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Press straight up, full lockout", "Arnold Press"),
        ex("Dumbbell Lateral Raise", 4, 15, 30, "Light, strict", "Dumbbells", "Shoulders", "Lateral Deltoid", [], "beginner", "Lead with elbows, no swinging", "Leaning Lateral Raise"),
        ex("Dumbbell Curl", 3, 10, 60, "Moderate", "Dumbbells", "Arms", "Biceps", ["Forearms"], "beginner", "Alternate arms, squeeze at top", "Hammer Curl"),
        ex("Overhead Dumbbell Extension", 3, 12, 60, "One heavy dumbbell", "Dumbbell", "Arms", "Triceps Long Head", ["Triceps Lateral Head"], "beginner", "Full stretch, press up", "Kickback"),
        ex("Hammer Curl", 3, 12, 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip, controlled", "Cross-Body Curl"),
        ex("Dumbbell Kickback", 3, 15, 30, "Light", "Dumbbell", "Arms", "Triceps", [], "beginner", "Lock upper arm, extend fully", "Overhead Extension"),
    ])

def db_lower():
    return wo("Lower Body", "hypertrophy", 55, [
        ex("Goblet Squat", 4, 12, 90, "Heavy dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold at chest, sit deep", "Sumo Squat"),
        ex("Dumbbell Romanian Deadlift", 4, 10, 90, "Heavy pair", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, deep stretch", "Single-Leg RDL"),
        ex("Dumbbell Walking Lunges", 3, 12, 60, "Moderate pair", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Reverse Lunges"),
        ex("Dumbbell Bulgarian Split Squat", 3, 10, 90, "Moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Rear foot on bench/chair", "Step-Up"),
        ex("Dumbbell Calf Raise", 3, 20, 30, "Heavy dumbbell", "Dumbbell", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Stand on edge of step", "Bodyweight Calf Raise"),
        ex("Dumbbell Hip Thrust", 3, 15, 60, "Heavy dumbbell on hips", "Dumbbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Drive through heels, squeeze top", "Glute Bridge"),
    ])

weeks_data_db = {}
for dur in [1, 2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur if dur > 1 else 0.5
        if p <= 0.25: focus = f"Week {w} - Learn dumbbell movements, moderate weight"
        elif p <= 0.5: focus = f"Week {w} - Progressive overload with heavier dumbbells"
        elif p <= 0.75: focus = f"Week {w} - Volume increase, shorter rest periods"
        else: focus = f"Week {w} - Peak intensity, maximize time under tension"
        if w % 2 == 1: wkts = [db_upper_a(), db_lower(), db_upper_b()]
        else: wkts = [db_lower(), db_upper_a(), db_lower(), db_upper_b()]
        weeks[w] = {"focus": focus, "workouts": wkts[:3]}
    for sess in [3, 4]:
        weeks_data_db[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Dumbbell Only", "Equipment-Specific",
    "Complete program using only dumbbells - perfect for home gym",
    [1, 2, 4, 8], [3, 4], True, "High", weeks_data_db, mn)
if s: helper.update_tracker("Dumbbell Only", "Done"); print("Dumbbell Only - DONE")

# ========================================================================
# 2. KETTLEBELL PROGRAM
# ========================================================================

def kb_day_a():
    return wo("Kettlebell A - Ballistic", "strength", 45, [
        ex("Kettlebell Swing", 5, 15, 60, "Moderate-heavy KB", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core", "Shoulders"], "intermediate", "Explosive hip snap, bell to eye level", "Dumbbell Swing"),
        ex("Kettlebell Goblet Squat", 4, 12, 60, "Heavy KB", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold horns at chest, sit deep", "Bodyweight Squat"),
        ex("Kettlebell Clean and Press", 3, 8, 90, "Moderate KB each arm", "Kettlebell", "Full Body", "Shoulders", ["Core", "Legs", "Forearms"], "intermediate", "Clean to rack, press overhead", "Dumbbell Clean and Press"),
        ex("Kettlebell Snatch", 3, 8, 60, "Moderate KB each arm", "Kettlebell", "Full Body", "Shoulders", ["Glutes", "Core", "Trapezius"], "advanced", "One smooth motion from floor to overhead", "Dumbbell Snatch"),
        ex("Kettlebell Turkish Get-Up", 3, 3, 90, "Light-moderate KB each side", "Kettlebell", "Full Body", "Core", ["Shoulders", "Glutes", "Quadriceps"], "advanced", "Slow and controlled, each position", "Windmill"),
    ])

def kb_day_b():
    return wo("Kettlebell B - Grind", "strength", 45, [
        ex("Kettlebell Front Squat", 4, 10, 90, "Double KBs in rack", "Kettlebell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows tight, upright torso", "Goblet Squat"),
        ex("Kettlebell Row", 4, 10, 60, "Heavy KB each arm", "Kettlebell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Hinge position, pull to hip", "Dumbbell Row"),
        ex("Kettlebell Floor Press", 3, 10, 60, "Moderate KBs", "Kettlebell", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Elbows to floor, press up", "Push-Up"),
        ex("Kettlebell Deadlift", 4, 8, 90, "Heavy single or double KB", "Kettlebell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hip hinge, flat back", "Dumbbell RDL"),
        ex("Kettlebell Halo", 3, 8, 30, "Light KB, each direction", "Kettlebell", "Shoulders", "Deltoids", ["Core", "Trapezius"], "beginner", "Circle around head, tight core", "Arm Circle"),
    ])

weeks_data_kb = {}
for dur in [2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.33: focus = f"Week {w} - Master KB fundamentals: swing, clean, TGU"
        elif p <= 0.66: focus = f"Week {w} - Increase KB weight, add complex movements"
        else: focus = f"Week {w} - Peak KB performance, longer complexes"
        if w % 2 == 1: wkts = [kb_day_a(), kb_day_b(), kb_day_a()]
        else: wkts = [kb_day_b(), kb_day_a(), kb_day_b()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [3, 4]:
        weeks_data_kb[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Kettlebell Program", "Equipment-Specific",
    "Complete kettlebell training - ballistic and grind movements for total body fitness",
    [2, 4, 8], [3, 4], True, "High", weeks_data_kb, mn)
if s: helper.update_tracker("Kettlebell Program", "Done"); print("Kettlebell Program - DONE")

# ========================================================================
# 3. RESISTANCE BAND PROGRAM
# ========================================================================

def band_upper():
    return wo("Upper Body Bands", "strength", 40, [
        ex("Band Push-Up", 3, 15, 45, "Loop band across back", "Resistance Band", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Band adds resistance at top", "Push-Up"),
        ex("Band Pull-Apart", 4, 20, 30, "Light band, chest height", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids"], "beginner", "Arms straight, squeeze shoulder blades", "Face Pull"),
        ex("Band Row", 4, 15, 45, "Medium band, anchor low", "Resistance Band", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull to lower chest, squeeze", "Seated Row"),
        ex("Band Shoulder Press", 3, 12, 45, "Medium band, stand on it", "Resistance Band", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Press straight up from shoulders", "Dumbbell Press"),
        ex("Band Bicep Curl", 3, 15, 30, "Medium band, stand on it", "Resistance Band", "Arms", "Biceps", ["Forearms"], "beginner", "Elbows fixed at sides, curl up", "Dumbbell Curl"),
        ex("Band Tricep Pushdown", 3, 15, 30, "Anchor high, push down", "Resistance Band", "Arms", "Triceps", [], "beginner", "Lock elbows, full extension", "Chair Dip"),
    ])

def band_lower():
    return wo("Lower Body Bands", "strength", 40, [
        ex("Band Squat", 4, 15, 45, "Heavy band around thighs + under feet", "Resistance Band", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Push knees out against band", "Bodyweight Squat"),
        ex("Band Deadlift", 4, 12, 45, "Heavy band, stand on it", "Resistance Band", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "beginner", "Hip hinge, pull through hips", "Good Morning"),
        ex("Band Hip Thrust", 4, 15, 30, "Loop band around hips, anchor back", "Resistance Band", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze glutes hard at top", "Glute Bridge"),
        ex("Band Lateral Walk", 3, 12, 30, "Mini band around ankles", "Resistance Band", "Glutes", "Gluteus Medius", ["Gluteus Minimus"], "beginner", "Stay low in half squat", "Side Step"),
        ex("Band Leg Curl", 3, 15, 30, "Anchor low, loop around ankle", "Resistance Band", "Legs", "Hamstrings", [], "beginner", "Standing, curl heel to glute", "Slider Leg Curl"),
        ex("Band Calf Raise", 3, 20, 20, "Loop under toes, hold handles", "Resistance Band", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full ROM, pause at top", "Bodyweight Calf Raise"),
    ])

weeks_data_band = {}
for dur in [2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.33: focus = f"Week {w} - Learn band exercises, establish form"
        elif p <= 0.66: focus = f"Week {w} - Increase resistance, progress to heavier bands"
        else: focus = f"Week {w} - Peak time under tension, slow tempos"
        if w % 2 == 1: wkts = [band_upper(), band_lower(), band_upper()]
        else: wkts = [band_lower(), band_upper(), band_lower()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [3, 4]:
        weeks_data_band[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Resistance Band", "Equipment-Specific",
    "Complete resistance band program - train anywhere with just bands",
    [2, 4, 8], [3, 4], False, "High", weeks_data_band, mn)
if s: helper.update_tracker("Resistance Band", "Done"); print("Resistance Band - DONE")

# ========================================================================
# 4. STRONG CURVES - Based on Bret Contreras methodology
# ========================================================================

def sc_day_a():
    """Glute-focused A - Hip thrust emphasis."""
    return wo("Day A - Glute Max Focus", "hypertrophy", 55, [
        ex("Barbell Hip Thrust", 4, 12, 90, "RPE 8, heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Shoulders on bench, drive through heels, squeeze 2s at top", "Glute Bridge"),
        ex("Barbell Back Squat", 3, 10, 120, "Moderate", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Below parallel, glute squeeze at top", "Goblet Squat"),
        ex("Romanian Deadlift", 3, 10, 90, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Feel deep hamstring stretch", "Dumbbell RDL"),
        ex("Cable Pull-Through", 3, 15, 45, "Moderate cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hinge at hips, squeeze glutes forward", "Band Pull-Through"),
        ex("Side-Lying Hip Abduction", 3, 20, 30, "Bodyweight or ankle weight", "Bodyweight", "Glutes", "Gluteus Medius", ["Gluteus Minimus"], "beginner", "Keep hips stacked, lift leg to 45 degrees", "Band Walk"),
        ex("Glute Kickback", 3, 15, 30, "Cable or bodyweight", "Cable Machine", "Glutes", "Gluteus Maximus", [], "beginner", "Squeeze at top, control return", "Donkey Kick"),
    ])

def sc_day_b():
    """Upper body + core."""
    return wo("Day B - Upper Body & Core", "hypertrophy", 50, [
        ex("Dumbbell Bench Press", 3, 10, 60, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full ROM, controlled", "Push-Up"),
        ex("Lat Pulldown", 3, 10, 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to upper chest", "Band Pulldown"),
        ex("Seated Dumbbell Shoulder Press", 3, 10, 60, "Light-moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Full ROM", "Machine Press"),
        ex("Seated Cable Row", 3, 10, 60, "Moderate", "Cable Machine", "Back", "Rhomboids", ["Biceps"], "beginner", "Squeeze shoulder blades", "Dumbbell Row"),
        ex("Plank", 3, 1, 30, "60 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight body", "Dead Bug"),
        ex("Side Plank", 3, 1, 30, "30 seconds each side", "Bodyweight", "Core", "Obliques", ["Gluteus Medius"], "beginner", "Hips up, straight line", "Bird Dog"),
    ])

def sc_day_c():
    """Glute-focused B - Squat emphasis."""
    return wo("Day C - Glute/Quad Focus", "hypertrophy", 55, [
        ex("Sumo Squat", 4, 12, 90, "Wide stance, moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Adductors"], "beginner", "Toes out 45 degrees, knees track toes", "Goblet Squat"),
        ex("Single-Leg Hip Thrust", 3, 12, 60, "Bodyweight or light dumbbell", "Bodyweight", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "One leg extended, drive through heel", "Hip Thrust"),
        ex("Step-Up", 3, 10, 60, "Moderate dumbbells, high step", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Drive through top foot only", "Reverse Lunge"),
        ex("Cable Hip Abduction", 3, 15, 30, "Light cable, standing", "Cable Machine", "Glutes", "Gluteus Medius", [], "beginner", "Controlled swing out, squeeze", "Band Walk"),
        ex("Back Extension", 3, 15, 45, "Bodyweight, focus on glutes", "Bodyweight", "Glutes", "Gluteus Maximus", ["Erector Spinae"], "beginner", "Round up with glutes, not lower back", "Superman"),
        ex("Frog Pump", 3, 20, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Maximus", [], "beginner", "Soles together, knees out, thrust up", "Glute Bridge"),
    ])

def sc_day_d():
    """Hamstring/posterior focus."""
    return wo("Day D - Posterior Chain", "hypertrophy", 50, [
        ex("Barbell Hip Thrust", 3, 8, 90, "Heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Heavier than Day A, lower reps", "Glute Bridge"),
        ex("Good Morning", 3, 10, 90, "Light-moderate barbell", "Barbell", "Back", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Soft knees, deep hip hinge", "Romanian Deadlift"),
        ex("Reverse Lunge", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride back, glute emphasis", "Walking Lunge"),
        ex("Swiss Ball Leg Curl", 3, 12, 45, "Bodyweight", "Swiss Ball", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Hips up, curl ball to glutes", "Lying Leg Curl"),
        ex("Clamshell", 3, 20, 20, "Mini band around knees", "Resistance Band", "Glutes", "Gluteus Medius", [], "beginner", "Heels together, open knees", "Side-Lying Abduction"),
    ])

weeks_data_sc = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Glute activation: learn to feel glutes working"
        elif p <= 0.5: focus = f"Week {w} - Building: increase hip thrust and squat loads"
        elif p <= 0.75: focus = f"Week {w} - Peak glute volume and intensity"
        else: focus = f"Week {w} - Deload: maintain activation, reduce volume"
        weeks[w] = {"focus": focus, "workouts": [sc_day_a(), sc_day_b(), sc_day_c(), sc_day_d()]}
    weeks_data_sc[(dur, 4)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Strong Curves", "Women's Health",
    "Bret Contreras-style glute building program with evidence-based programming",
    [4, 8, 12], [4], True, "High", weeks_data_sc, mn)
if s: helper.update_tracker("Strong Curves", "Done"); print("Strong Curves - DONE")

# ========================================================================
# 5. TONED & LEAN - Women's sculpting program
# ========================================================================

def tl_day1():
    return wo("Day 1 - Lower Body Sculpt", "hypertrophy", 50, [
        ex("Goblet Squat", 4, 12, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, squeeze at top", "Bodyweight Squat"),
        ex("Hip Thrust", 4, 12, 60, "Barbell or heavy dumbbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Squeeze glutes 2s at top", "Glute Bridge"),
        ex("Reverse Lunge", 3, 12, 45, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Step back, upright torso", "Walking Lunge"),
        ex("Sumo Deadlift", 3, 10, 60, "Moderate", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors"], "intermediate", "Wide stance, hinge at hips", "Dumbbell Sumo Squat"),
        ex("Band Walk", 3, 15, 30, "Mini band above knees", "Resistance Band", "Glutes", "Gluteus Medius", [], "beginner", "Stay low, push knees out", "Side Step"),
        ex("Plank", 3, 1, 30, "45 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Tight body", "Dead Bug"),
    ])

def tl_day2():
    return wo("Day 2 - Upper Body Tone", "hypertrophy", 45, [
        ex("Dumbbell Bench Press", 3, 12, 60, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Control weight, full ROM", "Push-Up"),
        ex("Lat Pulldown", 3, 12, 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to chest, squeeze back", "Band Pulldown"),
        ex("Dumbbell Shoulder Press", 3, 12, 45, "Light-moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Full ROM", "Machine Press"),
        ex("Seated Cable Row", 3, 12, 45, "Moderate", "Cable Machine", "Back", "Rhomboids", ["Biceps"], "beginner", "Squeeze shoulder blades", "Dumbbell Row"),
        ex("Tricep Kickback", 3, 12, 30, "Light", "Dumbbells", "Arms", "Triceps", [], "beginner", "Upper arm fixed, extend fully", "Band Pushdown"),
        ex("Dumbbell Curl", 3, 12, 30, "Light-moderate", "Dumbbells", "Arms", "Biceps", [], "beginner", "Controlled, no swinging", "Band Curl"),
    ])

def tl_day3():
    return wo("Day 3 - Full Body HIIT", "fat_loss", 40, [
        ex("Kettlebell Swing", 4, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap", "Dumbbell Swing"),
        ex("Push-Up", 3, 12, 20, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM", "Knee Push-Up"),
        ex("Jump Squat", 3, 12, 30, "Bodyweight", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, explosive jump", "Squat"),
        ex("Mountain Climbers", 3, 20, 20, "Fast", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Drive knees to chest", "High Knees"),
        ex("Burpees", 3, 8, 30, "Full range", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Jump at top, chest to floor", "Squat Thrust"),
        ex("Bicycle Crunch", 3, 20, 20, "Bodyweight", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Elbow to opposite knee", "Crunch"),
    ])

def tl_day4():
    return wo("Day 4 - Glutes & Core", "hypertrophy", 45, [
        ex("Barbell Hip Thrust", 4, 12, 60, "Heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Squeeze hard at top", "Glute Bridge"),
        ex("Bulgarian Split Squat", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Lean forward for glute bias", "Reverse Lunge"),
        ex("Cable Pull-Through", 3, 15, 45, "Moderate", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Hinge and squeeze", "Band Pull-Through"),
        ex("Side-Lying Hip Abduction", 3, 20, 30, "Bodyweight", "Bodyweight", "Glutes", "Gluteus Medius", [], "beginner", "Control movement, squeeze at top", "Band Walk"),
        ex("Dead Bug", 3, 12, 30, "Bodyweight", "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Lower back stays flat", "Bird Dog"),
        ex("Russian Twist", 3, 15, 30, "Light dumbbell", "Dumbbell", "Core", "Obliques", [], "beginner", "Rotate fully, feet elevated", "Bicycle Crunch"),
    ])

weeks_data_tl = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Establish routine, learn exercises"
        elif p <= 0.5: focus = f"Week {w} - Progressive overload, increase weight"
        elif p <= 0.75: focus = f"Week {w} - Peak volume, add intensity techniques"
        else: focus = f"Week {w} - Maintain and consolidate results"
        weeks[w] = {"focus": focus, "workouts": [tl_day1(), tl_day2(), tl_day3(), tl_day4()]}
    for sess in [4, 5]:
        weeks_data_tl[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Toned & Lean", "Women's Health",
    "Sculpting program for toned physique - strength training with strategic HIIT",
    [4, 8, 12], [4, 5], True, "High", weeks_data_tl, mn)
if s: helper.update_tracker("Toned & Lean", "Done"); print("Toned & Lean - DONE")

helper.close()
print("\n=== ALL EQUIPMENT + WOMEN'S HEALTH PROGRAMS COMPLETE ===")
