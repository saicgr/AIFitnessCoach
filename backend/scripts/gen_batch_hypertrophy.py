#!/usr/bin/env python3
"""Generate remaining High-priority Hypertrophy programs:
- Classic Bodybuilding (4,8,12,16w × 5-6/wk)
- Body Part Split (1,2,4,8w × 5/wk)
- Mass Builder (8,12,16w × 5-6/wk)
- High Frequency Full Body (4,8w × 5/wk)
- Classic 6-Day Split (4,8,12w × 6/wk)
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
# 1. CLASSIC BODYBUILDING - Traditional bro split, 5-6 days
# Chest / Back / Shoulders / Arms / Legs
# ========================================================================

def classic_bb_chest():
    return wo("Chest Day", "hypertrophy", 60, [
        ex("Barbell Bench Press", 4, 8, 120, "RPE 8", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, arch back, control descent", "Dumbbell Bench Press"),
        ex("Incline Dumbbell Press", 4, 10, 90, "RPE 7-8", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree incline, full stretch at bottom", "Incline Barbell Press"),
        ex("Dumbbell Flye", 3, 12, 60, "Moderate, feel stretch", "Dumbbells", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Slight elbow bend, open arms wide", "Cable Flye"),
        ex("Cable Crossover", 3, 15, 45, "Light-moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Step forward, squeeze at center", "Pec Deck"),
        ex("Decline Bench Press", 3, 10, 90, "Moderate", "Barbell", "Chest", "Lower Pectoralis", ["Triceps"], "intermediate", "15-degree decline, controlled", "Decline Dumbbell Press"),
        ex("Push-Up", 3, 15, 45, "Bodyweight, slow tempo", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM, chest to floor", "Knee Push-Up"),
    ])

def classic_bb_back():
    return wo("Back Day", "hypertrophy", 60, [
        ex("Barbell Bent-Over Row", 4, 8, 120, "RPE 8", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45-degree torso, pull to navel", "T-Bar Row"),
        ex("Weighted Pull-Up", 4, 8, 120, "Add weight as able", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "intermediate", "Full extension, controlled pull", "Lat Pulldown"),
        ex("Seated Cable Row", 3, 10, 90, "Moderate-heavy, V-grip", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "intermediate", "Squeeze shoulder blades 1 sec", "Machine Row"),
        ex("Straight-Arm Pulldown", 3, 12, 60, "Light-moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Slight lean forward, pull to thighs", "Dumbbell Pullover"),
        ex("Dumbbell Row", 3, 10, 60, "Heavy, each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull to hip, squeeze lat", "Machine Row"),
        ex("Hyperextension", 3, 15, 45, "Bodyweight or hold plate", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "beginner", "Controlled, don't hyperextend", "Superman"),
    ])

def classic_bb_shoulders():
    return wo("Shoulders Day", "hypertrophy", 55, [
        ex("Overhead Press", 4, 8, 120, "RPE 8", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Tight core, press straight up", "Dumbbell Shoulder Press"),
        ex("Dumbbell Lateral Raise", 4, 12, 45, "Light, strict", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Lead with elbows, slight pinky-up", "Cable Lateral Raise"),
        ex("Seated Dumbbell Shoulder Press", 3, 10, 90, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Controlled, don't lock out", "Machine Shoulder Press"),
        ex("Reverse Pec Deck", 3, 15, 45, "Light-moderate", "Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Squeeze shoulder blades", "Face Pull"),
        ex("Upright Row", 3, 12, 60, "Moderate, wide grip", "Barbell", "Shoulders", "Lateral Deltoid", ["Trapezius", "Anterior Deltoid"], "intermediate", "Wide grip reduces impingement risk", "Dumbbell Upright Row"),
        ex("Shrugs", 3, 15, 60, "Heavy", "Dumbbells", "Shoulders", "Trapezius", [], "beginner", "Straight up, hold 2 sec at top", "Barbell Shrugs"),
    ])

def classic_bb_arms():
    return wo("Arms Day", "hypertrophy", 55, [
        ex("Barbell Curl", 4, 8, 90, "RPE 8, strict", "Barbell", "Arms", "Biceps", ["Forearms"], "beginner", "No swinging, squeeze at top", "Dumbbell Curl"),
        ex("Skull Crusher", 4, 10, 90, "Moderate EZ bar", "EZ Bar", "Arms", "Triceps", [], "intermediate", "Lower to forehead, elbows fixed", "Overhead Dumbbell Extension"),
        ex("Incline Dumbbell Curl", 3, 10, 60, "Light-moderate", "Dumbbells", "Arms", "Biceps Long Head", ["Forearms"], "beginner", "Arms hang back, full stretch", "Cable Curl"),
        ex("Triceps Pushdown", 3, 12, 60, "Moderate", "Cable Machine", "Arms", "Triceps Lateral Head", [], "beginner", "Lock elbows, full extension", "Band Pushdown"),
        ex("Hammer Curl", 3, 10, 60, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip, controlled", "Cable Hammer Curl"),
        ex("Overhead Triceps Extension", 3, 12, 60, "Moderate cable", "Cable Machine", "Arms", "Triceps Long Head", [], "beginner", "Full stretch overhead", "Dumbbell French Press"),
    ])

def classic_bb_legs():
    return wo("Legs Day", "hypertrophy", 70, [
        ex("Barbell Back Squat", 4, 8, 180, "RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Break at hips, chest up, full depth", "Leg Press"),
        ex("Romanian Deadlift", 4, 10, 120, "RPE 7-8", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Hinge at hips, feel stretch", "Dumbbell RDL"),
        ex("Leg Press", 3, 12, 90, "Heavy, feet shoulder width", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, don't lock knees", "Hack Squat"),
        ex("Walking Lunges", 3, 12, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long strides, upright torso", "Reverse Lunges"),
        ex("Leg Curl", 3, 12, 60, "Moderate", "Machine", "Legs", "Hamstrings", [], "beginner", "Control negative, squeeze at top", "Nordic Curl"),
        ex("Standing Calf Raise", 4, 15, 60, "Heavy, 2-sec pause", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full stretch at bottom", "Seated Calf Raise"),
    ])

# Build Classic Bodybuilding
weeks_data_cb = {}
for dur in [4, 8, 12, 16]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Base volume: moderate weight, establish mind-muscle connection"
        elif p <= 0.5: focus = f"Week {w} - Progressive overload: increase weight 5-10%"
        elif p <= 0.75: focus = f"Week {w} - Peak volume: add drop sets and intensity techniques"
        else: focus = f"Week {w} - Deload/test: reduce volume, showcase gains"
        weeks[w] = {"focus": focus, "workouts": [classic_bb_chest(), classic_bb_back(), classic_bb_shoulders(), classic_bb_arms(), classic_bb_legs()]}
    for sessions in [5, 6]:
        weeks_data_cb[(dur, sessions)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Classic Bodybuilding", "Hypertrophy/Muscle Building",
    "Traditional bodybuilding split - chest, back, shoulders, arms, legs",
    [4, 8, 12, 16], [5, 6], True, "High", weeks_data_cb, mn)
if s: helper.update_tracker("Classic Bodybuilding", "Done"); print("Classic Bodybuilding - DONE")

# ========================================================================
# 2. BODY PART SPLIT - 5 days, one body part per day
# ========================================================================

def bps_chest():
    return wo("Day 1 - Chest", "hypertrophy", 55, [
        ex("Barbell Bench Press", 4, 10, 90, "RPE 8", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Arch back, retract scapula", "Dumbbell Bench Press"),
        ex("Incline Dumbbell Press", 3, 12, 60, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Full stretch at bottom", "Incline Machine Press"),
        ex("Cable Flye", 3, 15, 45, "Light-moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Constant tension, squeeze at peak", "Dumbbell Flye"),
        ex("Dip", 3, 10, 90, "Bodyweight or weighted", "Parallel Bars", "Chest", "Lower Pectoralis", ["Triceps"], "intermediate", "Lean forward for chest emphasis", "Decline Push-Up"),
        ex("Pec Deck", 3, 12, 45, "Moderate", "Machine", "Chest", "Pectoralis Major", [], "beginner", "Squeeze at center, slow negative", "Cable Crossover"),
    ])

def bps_back():
    return wo("Day 2 - Back", "hypertrophy", 55, [
        ex("Pull-Up", 4, 8, 90, "Bodyweight or weighted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full hang, pull to chest", "Lat Pulldown"),
        ex("Barbell Bent-Over Row", 4, 8, 120, "RPE 8", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45-degree angle, pull to navel", "T-Bar Row"),
        ex("Seated Cable Row", 3, 10, 90, "Moderate", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi"], "intermediate", "Squeeze shoulder blades", "Machine Row"),
        ex("Dumbbell Pullover", 3, 12, 60, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Chest", "Serratus"], "intermediate", "Feel lat stretch, controlled arc", "Straight-Arm Pulldown"),
        ex("Hyperextension", 3, 15, 45, "Hold plate at chest", "Bodyweight", "Back", "Erector Spinae", ["Glutes"], "beginner", "Controlled, don't hyperextend", "Superman"),
    ])

def bps_shoulders():
    return wo("Day 3 - Shoulders", "hypertrophy", 50, [
        ex("Seated Dumbbell Shoulder Press", 4, 10, 90, "RPE 8", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Full ROM, don't lock out", "Machine Shoulder Press"),
        ex("Dumbbell Lateral Raise", 4, 15, 45, "Light, strict form", "Dumbbells", "Shoulders", "Lateral Deltoid", [], "beginner", "Lead with elbows, no momentum", "Cable Lateral Raise"),
        ex("Face Pull", 3, 15, 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators"], "beginner", "External rotate at end", "Band Pull-Apart"),
        ex("Arnold Press", 3, 10, 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid"], "intermediate", "Rotate palms during press", "Dumbbell Shoulder Press"),
        ex("Shrugs", 3, 15, 60, "Heavy", "Dumbbells", "Shoulders", "Trapezius", [], "beginner", "Straight up, squeeze at top", "Barbell Shrugs"),
    ])

def bps_arms():
    return wo("Day 4 - Arms", "hypertrophy", 50, [
        ex("Barbell Curl", 3, 10, 60, "RPE 8", "Barbell", "Arms", "Biceps", ["Forearms"], "beginner", "Strict form, no swinging", "Dumbbell Curl"),
        ex("Close-Grip Bench Press", 3, 10, 90, "Moderate", "Barbell", "Arms", "Triceps", ["Chest"], "intermediate", "Elbows tucked, shoulder width grip", "Dip"),
        ex("Hammer Curl", 3, 12, 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps"], "beginner", "Neutral grip, controlled", "Cable Hammer Curl"),
        ex("Skull Crusher", 3, 12, 60, "Moderate", "EZ Bar", "Arms", "Triceps", [], "intermediate", "Lower to forehead slowly", "Overhead Extension"),
        ex("Preacher Curl", 3, 12, 45, "Light-moderate", "EZ Bar", "Arms", "Biceps Short Head", [], "beginner", "Full extension, don't hyperextend", "Machine Curl"),
        ex("Triceps Pushdown", 3, 15, 45, "Moderate", "Cable Machine", "Arms", "Triceps Lateral Head", [], "beginner", "Lock elbows, squeeze", "Band Pushdown"),
    ])

def bps_legs():
    return wo("Day 5 - Legs", "hypertrophy", 65, [
        ex("Barbell Back Squat", 4, 10, 120, "RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, chest up", "Leg Press"),
        ex("Romanian Deadlift", 3, 10, 90, "Moderate-heavy", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Hinge at hips, feel stretch", "Dumbbell RDL"),
        ex("Leg Extension", 3, 12, 60, "Moderate", "Machine", "Legs", "Quadriceps", [], "beginner", "Squeeze at top, controlled", "Sissy Squat"),
        ex("Leg Curl", 3, 12, 60, "Moderate", "Machine", "Legs", "Hamstrings", [], "beginner", "Full ROM, slow negative", "Swiss Ball Curl"),
        ex("Bulgarian Split Squat", 3, 10, 90, "Light-moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Upright torso, drive through front foot", "Reverse Lunge"),
        ex("Calf Raise", 4, 15, 45, "Heavy", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full ROM, pause at stretch", "Seated Calf Raise"),
    ])

weeks_data_bps = {}
for dur in [1, 2, 4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur if dur > 1 else 0.5
        if p <= 0.25: focus = f"Week {w} - Establish baseline with moderate weight"
        elif p <= 0.5: focus = f"Week {w} - Progressive overload, increase 5-10%"
        elif p <= 0.75: focus = f"Week {w} - Intensity techniques: drop sets, rest-pause"
        else: focus = f"Week {w} - Peak intensity, push for PRs"
        weeks[w] = {"focus": focus, "workouts": [bps_chest(), bps_back(), bps_shoulders(), bps_arms(), bps_legs()]}
    weeks_data_bps[(dur, 5)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Body Part Split", "Hypertrophy/Muscle Building",
    "One body part per day - maximum focus on each muscle group",
    [1, 2, 4, 8], [5], True, "High", weeks_data_bps, mn)
if s: helper.update_tracker("Body Part Split", "Done"); print("Body Part Split - DONE")

# ========================================================================
# 3. MASS BUILDER - High volume, heavy compounds, 5-6 days
# ========================================================================

def mb_push():
    return wo("Push Day", "hypertrophy", 65, [
        ex("Barbell Bench Press", 5, 8, 120, "RPE 8-9, heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Max effort, controlled tempo", "Dumbbell Bench Press"),
        ex("Overhead Press", 4, 8, 120, "RPE 8", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Strict press, tight core", "Dumbbell Shoulder Press"),
        ex("Incline Dumbbell Press", 4, 10, 90, "Heavy dumbbells", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Full stretch, explosive press", "Incline Barbell Press"),
        ex("Weighted Dip", 3, 10, 90, "Add 25-45lbs", "Parallel Bars", "Chest", "Lower Pectoralis", ["Triceps"], "intermediate", "Lean forward, full depth", "Machine Dip"),
        ex("Cable Lateral Raise", 4, 15, 30, "Light, constant tension", "Cable Machine", "Shoulders", "Lateral Deltoid", [], "beginner", "Behind body start, raise to shoulder", "Dumbbell Lateral Raise"),
        ex("Skull Crusher", 3, 12, 60, "Moderate-heavy", "EZ Bar", "Arms", "Triceps", [], "intermediate", "Forehead level, elbows fixed", "Overhead Extension"),
    ])

def mb_pull():
    return wo("Pull Day", "hypertrophy", 65, [
        ex("Barbell Deadlift", 4, 6, 180, "RPE 8-9", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Trapezius"], "intermediate", "Flat back, hip hinge, lockout", "Trap Bar Deadlift"),
        ex("Weighted Pull-Up", 4, 8, 120, "Add 25-45lbs", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Full extension, explosive pull", "Lat Pulldown"),
        ex("T-Bar Row", 4, 10, 90, "Heavy", "T-Bar", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "intermediate", "Chest against pad, squeeze back", "Barbell Bent-Over Row"),
        ex("Chest-Supported Row", 3, 10, 60, "Moderate-heavy", "Dumbbells", "Back", "Rhomboids", ["Rear Deltoid"], "intermediate", "Chest on incline bench, pull to ribs", "Seated Cable Row"),
        ex("Barbell Curl", 3, 8, 60, "RPE 8, strict", "Barbell", "Arms", "Biceps", ["Forearms"], "beginner", "No cheating, full ROM", "Dumbbell Curl"),
        ex("Hammer Curl", 3, 10, 45, "Heavy", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip, controlled", "Cable Hammer Curl"),
    ])

def mb_legs():
    return wo("Legs Day", "hypertrophy", 70, [
        ex("Barbell Back Squat", 5, 6, 180, "RPE 9, heavy", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Deep squat, drive hard", "Leg Press"),
        ex("Romanian Deadlift", 4, 8, 120, "RPE 8", "Barbell", "Legs", "Hamstrings", ["Glutes", "Lower Back"], "intermediate", "Deep stretch, control weight", "Dumbbell RDL"),
        ex("Hack Squat", 4, 10, 90, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Full depth, don't lock", "Leg Press"),
        ex("Hip Thrust", 4, 10, 90, "Heavy barbell", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Drive through heels, squeeze top", "Glute Bridge"),
        ex("Leg Extension", 3, 12, 45, "Moderate, squeeze", "Machine", "Legs", "Quadriceps", [], "beginner", "Full contraction at top", "Sissy Squat"),
        ex("Standing Calf Raise", 5, 12, 60, "Heavy", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full stretch, pause at top", "Seated Calf Raise"),
    ])

weeks_data_mb = {}
for dur in [8, 12, 16]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.3: focus = f"Week {w} - Volume accumulation: moderate weight, 3-4 RIR"
        elif p <= 0.6: focus = f"Week {w} - Intensification: increase loads, 1-2 RIR"
        elif p <= 0.8: focus = f"Week {w} - Peak volume block with intensity techniques"
        else: focus = f"Week {w} - Deload: 50% volume, maintain intensity"
        weeks[w] = {"focus": focus, "workouts": [mb_push(), mb_pull(), mb_legs(), mb_push(), mb_pull()]}
    for sessions in [5, 6]:
        weeks_data_mb[(dur, sessions)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Mass Builder", "Hypertrophy/Muscle Building",
    "High volume hypertrophy program for maximum muscle growth",
    [8, 12, 16], [5, 6], True, "High", weeks_data_mb, mn)
if s: helper.update_tracker("Mass Builder", "Done"); print("Mass Builder - DONE")

# ========================================================================
# 4. HIGH FREQUENCY FULL BODY - 5 days full body
# ========================================================================

def hf_day1():
    return wo("Day 1 - Squat Focus", "hypertrophy", 55, [
        ex("Barbell Back Squat", 4, 6, 120, "RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Heavy, compound first", "Leg Press"),
        ex("Dumbbell Bench Press", 3, 10, 60, "RPE 7", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Moderate volume", "Push-Up"),
        ex("Dumbbell Row", 3, 10, 60, "RPE 7", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Each arm, pull to hip", "Cable Row"),
        ex("Dumbbell Lateral Raise", 3, 15, 30, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid", [], "beginner", "Strict form", "Cable Lateral Raise"),
        ex("Dumbbell Curl", 2, 12, 45, "Moderate", "Dumbbells", "Arms", "Biceps", [], "beginner", "Quick pump work", "Band Curl"),
    ])

def hf_day2():
    return wo("Day 2 - Bench Focus", "hypertrophy", 55, [
        ex("Barbell Bench Press", 4, 6, 120, "RPE 8", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Heavy bench day", "Dumbbell Bench Press"),
        ex("Romanian Deadlift", 3, 10, 90, "RPE 7", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Moderate posterior chain", "Dumbbell RDL"),
        ex("Pull-Up", 3, 8, 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM", "Lat Pulldown"),
        ex("Overhead Press", 2, 10, 60, "RPE 6-7", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Light pressing volume", "Machine Press"),
        ex("Triceps Pushdown", 2, 15, 30, "Light", "Cable Machine", "Arms", "Triceps", [], "beginner", "Quick pump", "Band Pushdown"),
    ])

def hf_day3():
    return wo("Day 3 - Deadlift Focus", "hypertrophy", 55, [
        ex("Barbell Deadlift", 4, 5, 180, "RPE 8", "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "intermediate", "Heavy pull day", "Trap Bar Deadlift"),
        ex("Incline Dumbbell Press", 3, 10, 60, "RPE 7", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Moderate pressing", "Incline Machine Press"),
        ex("Goblet Squat", 3, 12, 60, "Light-moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Light squat volume", "Bodyweight Squat"),
        ex("Face Pull", 3, 15, 30, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Prehab work", "Band Pull-Apart"),
        ex("Hammer Curl", 2, 12, 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps"], "beginner", "Quick pump", "Cable Curl"),
    ])

def hf_day4():
    return wo("Day 4 - OHP Focus", "hypertrophy", 55, [
        ex("Overhead Press", 4, 6, 120, "RPE 8", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Heavy press day", "Dumbbell Shoulder Press"),
        ex("Front Squat", 3, 8, 90, "RPE 7", "Barbell", "Legs", "Quadriceps", ["Core"], "intermediate", "Moderate quad work", "Goblet Squat"),
        ex("Chin-Up", 3, 8, 90, "Bodyweight or weighted", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Supinated grip for bicep emphasis", "Supinated Lat Pulldown"),
        ex("Cable Flye", 3, 12, 45, "Light", "Cable Machine", "Chest", "Pectoralis Major", [], "beginner", "Light chest volume", "Dumbbell Flye"),
        ex("Skull Crusher", 2, 12, 45, "Moderate", "EZ Bar", "Arms", "Triceps", [], "intermediate", "Quick tricep pump", "Overhead Extension"),
    ])

def hf_day5():
    return wo("Day 5 - Volume Full Body", "hypertrophy", 55, [
        ex("Leg Press", 3, 12, 60, "Moderate", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "High rep legs", "Goblet Squat"),
        ex("Machine Chest Press", 3, 12, 60, "Moderate", "Machine", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Pump chest work", "Push-Up"),
        ex("Lat Pulldown", 3, 12, 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "High rep back", "Band Pulldown"),
        ex("Machine Shoulder Press", 3, 12, 60, "Light-moderate", "Machine", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Volume pressing", "Dumbbell Press"),
        ex("Barbell Curl", 2, 12, 45, "Light", "Barbell", "Arms", "Biceps", [], "beginner", "Arm pump", "Dumbbell Curl"),
        ex("Calf Raise", 3, 15, 30, "Moderate", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full ROM", "Bodyweight Calf Raise"),
    ])

weeks_data_hf = {}
for dur in [4, 8]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Base volume: establish frequency tolerance"
        elif p <= 0.5: focus = f"Week {w} - Increase loads on primary movements"
        elif p <= 0.75: focus = f"Week {w} - Peak frequency response, push compounds"
        else: focus = f"Week {w} - Consolidate gains, test new maxes"
        weeks[w] = {"focus": focus, "workouts": [hf_day1(), hf_day2(), hf_day3(), hf_day4(), hf_day5()]}
    weeks_data_hf[(dur, 5)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("High Frequency Full Body", "Hypertrophy/Muscle Building",
    "5-day full body program hitting each muscle 5x per week with varied intensity",
    [4, 8], [5], True, "High", weeks_data_hf, mn)
if s: helper.update_tracker("High Frequency Full Body", "Done"); print("High Frequency Full Body - DONE")

# ========================================================================
# 5. CLASSIC 6-DAY SPLIT - Chest/Back, Shoulders/Arms, Legs x2
# ========================================================================

def c6_chest_back():
    return wo("Chest & Back", "hypertrophy", 65, [
        ex("Barbell Bench Press", 4, 8, 120, "RPE 8", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Control descent, explosive press", "Dumbbell Bench Press"),
        ex("Weighted Pull-Up", 4, 8, 120, "Add weight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full extension to chin over bar", "Lat Pulldown"),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "30-degree incline", "Incline Machine Press"),
        ex("Barbell Bent-Over Row", 3, 10, 90, "Moderate-heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45-degree torso, strict", "T-Bar Row"),
        ex("Cable Flye", 3, 15, 30, "Light", "Cable Machine", "Chest", "Pectoralis Major", [], "beginner", "Constant tension", "Dumbbell Flye"),
        ex("Straight-Arm Pulldown", 3, 12, 45, "Light-moderate", "Cable Machine", "Back", "Latissimus Dorsi", [], "beginner", "Lat isolation", "Dumbbell Pullover"),
    ])

def c6_shoulders_arms():
    return wo("Shoulders & Arms", "hypertrophy", 60, [
        ex("Overhead Press", 4, 8, 120, "RPE 8", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Strict press", "Dumbbell Shoulder Press"),
        ex("Barbell Curl", 3, 10, 60, "RPE 8", "Barbell", "Arms", "Biceps", ["Forearms"], "beginner", "No swinging", "Dumbbell Curl"),
        ex("Skull Crusher", 3, 10, 60, "Moderate", "EZ Bar", "Arms", "Triceps", [], "intermediate", "Elbows fixed", "Overhead Extension"),
        ex("Dumbbell Lateral Raise", 4, 15, 30, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid", [], "beginner", "Strict form, lead with elbows", "Cable Lateral Raise"),
        ex("Hammer Curl", 3, 12, 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps"], "beginner", "Neutral grip", "Cable Hammer Curl"),
        ex("Triceps Pushdown", 3, 15, 30, "Moderate", "Cable Machine", "Arms", "Triceps Lateral Head", [], "beginner", "Full extension", "Band Pushdown"),
    ])

def c6_legs():
    return wo("Legs", "hypertrophy", 65, [
        ex("Barbell Back Squat", 4, 8, 180, "RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, drive up", "Leg Press"),
        ex("Romanian Deadlift", 3, 10, 90, "RPE 7-8", "Barbell", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Deep stretch", "Dumbbell RDL"),
        ex("Leg Press", 3, 12, 90, "Moderate-heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full ROM", "Hack Squat"),
        ex("Walking Lunges", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Long strides", "Reverse Lunges"),
        ex("Leg Curl", 3, 12, 45, "Moderate", "Machine", "Legs", "Hamstrings", [], "beginner", "Control negative", "Nordic Curl"),
        ex("Calf Raise", 4, 15, 45, "Heavy", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full ROM, pause", "Seated Calf Raise"),
    ])

weeks_data_c6 = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: focus = f"Week {w} - Volume base: moderate loads, focus on form"
        elif p <= 0.5: focus = f"Week {w} - Overload: increase weight 5-10%"
        elif p <= 0.75: focus = f"Week {w} - Peak: intensity techniques, drop sets"
        else: focus = f"Week {w} - Deload: reduce volume, maintain intensity"
        weeks[w] = {"focus": focus, "workouts": [c6_chest_back(), c6_shoulders_arms(), c6_legs(), c6_chest_back(), c6_shoulders_arms(), c6_legs()]}
    weeks_data_c6[(dur, 6)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Classic 6-Day Split", "Hypertrophy/Muscle Building",
    "Chest/Back, Shoulders/Arms, Legs - each hit twice per week",
    [4, 8, 12], [6], True, "High", weeks_data_c6, mn)
if s: helper.update_tracker("Classic 6-Day Split", "Done"); print("Classic 6-Day Split - DONE")

helper.close()
print("\n=== ALL HYPERTROPHY PROGRAMS COMPLETE ===")
