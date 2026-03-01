#!/usr/bin/env python3
"""Generate Premium + Challenges + Popular programs:
- HYROX Race Prep (8,12,16,24w × 5-6/wk)
- HYROX Home Edition (8,12,16,24w × 4-5/wk)
- Elite Performance Camp (8,12,16w × 5-6/wk)
- Triathlon Foundation (8,12,16w × 5-6/wk)
- 30 Day Shred Challenge (4w × 6/wk)
- 75 Hard Fitness (10w × 7/wk)
- Push-Up Mastery (4,8,12w × 3-4/wk)
- Pull-Up Journey (4,8,12w × 3-4/wk)
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
# 1. HYROX RACE PREP - Competition-specific training
# 8 stations: SkiErg, Sled Push, Sled Pull, Burpee Broad Jump,
# Rowing, Farmers Carry, Sandbag Lunges, Wall Balls
# ========================================================================

def hyrox_run():
    return wo("Running Day", "endurance", 50, [
        ex("Treadmill Interval Run", 1, 1, 0, "Alternate 400m hard / 200m easy, 5-8 rounds", "Treadmill", "Legs", "Quadriceps", ["Calves", "Hamstrings", "Core"], "intermediate", "Hard efforts at race pace, easy at jog", "Outdoor Run"),
        ex("SkiErg", 4, 1, 60, "500m intervals at race pace", "SkiErg", "Full Body", "Latissimus Dorsi", ["Core", "Triceps"], "intermediate", "Long pull, engage core, drive down", "Battle Ropes"),
        ex("Wall Ball", 4, 15, 45, "9kg/6kg ball, 10ft/9ft target", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core", "Glutes"], "intermediate", "Deep squat, explosive throw to target", "Thruster"),
        ex("Burpee Broad Jump", 3, 8, 60, "Bodyweight, max distance", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core", "Glutes"], "advanced", "Chest to floor, jump forward, stick landing", "Burpee"),
    ])

def hyrox_strength():
    return wo("Strength & Station Practice", "conditioning", 60, [
        ex("Sled Push", 4, 1, 90, "Race weight, 50m", "Sled", "Legs", "Quadriceps", ["Glutes", "Core", "Calves"], "intermediate", "Low body position, drive through legs", "Leg Press"),
        ex("Sled Pull", 4, 1, 90, "Race weight, 50m with rope", "Sled", "Back", "Latissimus Dorsi", ["Biceps", "Forearms", "Core"], "intermediate", "Hand over hand, stay low", "Seated Cable Row"),
        ex("Farmer's Carry", 4, 1, 60, "Heavy dumbbells, 200m", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core", "Glutes"], "intermediate", "Tall posture, tight grip, steady pace", "Suitcase Carry"),
        ex("Sandbag Walking Lunges", 4, 1, 60, "Race weight sandbag, 200m", "Sandbag", "Legs", "Quadriceps", ["Glutes", "Core", "Shoulders"], "advanced", "Sandbag on shoulder, long strides", "Dumbbell Walking Lunges"),
        ex("Rowing Machine", 4, 1, 60, "1000m at race pace", "Rowing Machine", "Full Body", "Latissimus Dorsi", ["Legs", "Core"], "intermediate", "Legs-back-arms sequence, powerful drive", "SkiErg"),
    ])

def hyrox_conditioning():
    return wo("Race Simulation / Conditioning", "conditioning", 55, [
        ex("Treadmill Run", 1, 1, 0, "1 mile at race pace", "Treadmill", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Consistent pace, don't start too fast", "Outdoor Run"),
        ex("SkiErg", 1, 1, 30, "1000m", "SkiErg", "Full Body", "Latissimus Dorsi", ["Core", "Triceps"], "intermediate", "Long pulls, rhythm", "Battle Ropes"),
        ex("Wall Ball", 1, 75, 30, "Race weight ball, consecutive", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders", "Core"], "advanced", "Find rhythm, breathe at top", "Thruster"),
        ex("Burpee Broad Jump", 1, 80, 30, "80m total distance", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "advanced", "Pace yourself, consistent jumps", "Burpee"),
        ex("Farmer's Carry", 1, 1, 0, "200m at race weight", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Don't stop, steady pace", "Suitcase Carry"),
    ])

def hyrox_recovery():
    return wo("Active Recovery & Mobility", "recovery", 40, [
        ex("Easy Jog", 1, 1, 0, "20 minutes, conversational pace", "Treadmill", "Legs", "Quadriceps", ["Calves"], "beginner", "Easy pace, heart rate zone 1-2", "Walking"),
        ex("Foam Rolling Quads", 1, 1, 0, "2 minutes each leg", "Foam Roller", "Legs", "Quadriceps", [], "beginner", "Slow rolls, pause on tight spots", "Quad Stretch"),
        ex("Hip Flexor Stretch", 2, 1, 0, "60 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Half kneeling, push hips forward", "Couch Stretch"),
        ex("Thoracic Spine Extension", 2, 10, 0, "Over foam roller", "Foam Roller", "Back", "Thoracic Spine", ["Shoulders"], "beginner", "Extend over roller, open chest", "Cat-Cow"),
        ex("Pigeon Stretch", 2, 1, 0, "60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Lean forward over front leg", "Figure-4 Stretch"),
    ])

weeks_data_hyrox = {}
for dur in [8, 12, 16, 24]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.4:
            focus = f"Week {w} - Blueprint Phase: aerobic base, learn station technique"
            wkts = [hyrox_run(), hyrox_strength(), hyrox_run(), hyrox_conditioning(), hyrox_recovery()]
        elif p <= 0.75:
            focus = f"Week {w} - Build Phase: race-specific intensity, station practice"
            wkts = [hyrox_run(), hyrox_strength(), hyrox_conditioning(), hyrox_run(), hyrox_strength()]
        elif p <= 0.95:
            focus = f"Week {w} - Race Phase: peak performance, full simulations"
            wkts = [hyrox_conditioning(), hyrox_run(), hyrox_strength(), hyrox_conditioning(), hyrox_run()]
        else:
            focus = f"Week {w} - Taper: reduce volume, sharpen race readiness"
            wkts = [hyrox_run(), hyrox_recovery(), hyrox_conditioning(), hyrox_recovery(), hyrox_run()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [5, 6]:
        weeks_data_hyrox[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("HYROX Race Prep", "Premium",
    "Race-date targeted HYROX training with all 8 stations and running intervals",
    [8, 12, 16, 24], [5, 6], True, "High", weeks_data_hyrox, mn)
if s: helper.update_tracker("HYROX Race Prep", "Done"); print("HYROX Race Prep - DONE")

# ========================================================================
# 2. HYROX HOME EDITION
# ========================================================================

def hyrox_home_run():
    return wo("Run + Conditioning", "endurance", 45, [
        ex("Outdoor Run Intervals", 1, 1, 0, "6x 400m hard / 200m jog", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hamstrings"], "intermediate", "Hard efforts at 5K race pace", "Treadmill Run"),
        ex("Battle Ropes", 4, 1, 45, "30 seconds max effort", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Alternating waves, stay low", "Jumping Jacks"),
        ex("Burpee Broad Jump", 4, 8, 45, "Max distance", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full burpee then jump forward", "Burpee"),
        ex("Thruster", 4, 12, 45, "Moderate dumbbells", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Deep squat then press", "Squat to Press"),
    ])

def hyrox_home_strength():
    return wo("Home Strength", "strength", 50, [
        ex("Dumbbell Walking Lunges", 4, 12, 60, "Heavy dumbbells, simulate sandbag lunges", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Long stride, upright torso", "Reverse Lunges"),
        ex("Farmer's Carry", 4, 1, 60, "Heavy dumbbells, 200m", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Tall posture, steady pace", "Suitcase Carry"),
        ex("Push-Up", 4, 15, 30, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM, fast tempo", "Knee Push-Up"),
        ex("Dumbbell Row", 4, 12, 45, "Heavy, each arm", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Pull to hip, squeeze lat", "Band Row"),
        ex("Goblet Squat", 4, 15, 45, "Heavy dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, explode up", "Bodyweight Squat"),
    ])

weeks_data_hh = {}
for dur in [8, 12, 16, 24]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.4: focus = f"Week {w} - Build aerobic base and movement patterns"
        elif p <= 0.75: focus = f"Week {w} - Increase intensity and station simulation"
        elif p <= 0.95: focus = f"Week {w} - Peak conditioning with full simulations"
        else: focus = f"Week {w} - Taper and race prep"
        if w % 2 == 1: wkts = [hyrox_home_run(), hyrox_home_strength(), hyrox_home_run(), hyrox_home_strength()]
        else: wkts = [hyrox_home_strength(), hyrox_home_run(), hyrox_home_strength(), hyrox_home_run()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [4, 5]:
        weeks_data_hh[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("HYROX Home Edition", "Premium",
    "Home equipment version of HYROX prep - dumbbells, battle ropes, and bodyweight",
    [8, 12, 16, 24], [4, 5], True, "High", weeks_data_hh, mn)
if s: helper.update_tracker("HYROX Home Edition", "Done"); print("HYROX Home Edition - DONE")

# ========================================================================
# 3. 30 DAY SHRED CHALLENGE - 4 weeks, 6/wk
# ========================================================================

def shred30_push():
    return wo("Push Day", "fat_loss", 40, [
        ex("Burpees", 4, 12, 20, "Max speed", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full extension, chest to floor", "Squat Thrust"),
        ex("Dumbbell Bench Press", 4, 12, 45, "Moderate, fast tempo", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Explosive press", "Push-Up"),
        ex("Dumbbell Shoulder Press", 3, 12, 30, "Light-moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Fast press, controlled down", "Pike Push-Up"),
        ex("Diamond Push-Up", 3, 12, 20, "Bodyweight", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Hands together, elbows tight", "Knee Diamond Push-Up"),
        ex("Mountain Climbers", 3, 20, 15, "Max speed", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Sprint form, hips low", "High Knees"),
    ])

def shred30_pull():
    return wo("Pull Day", "fat_loss", 40, [
        ex("Pull-Up", 4, 8, 30, "Max effort", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM each rep", "Lat Pulldown"),
        ex("Dumbbell Row", 4, 12, 30, "Heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Fast tempo, squeeze back", "Band Row"),
        ex("Kettlebell Swing", 4, 15, 30, "Moderate-heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
        ex("Renegade Row", 3, 8, 30, "Moderate dumbbells", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core"], "intermediate", "Stable hips, row each side", "Bent-Over Row"),
        ex("Bicycle Crunch", 3, 20, 15, "Bodyweight", "Bodyweight", "Core", "Obliques", [], "beginner", "Elbow to opposite knee", "Crunch"),
    ])

def shred30_legs():
    return wo("Legs Day", "fat_loss", 40, [
        ex("Jump Squat", 4, 12, 30, "Bodyweight, explosive", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Deep squat, max height", "Squat"),
        ex("Goblet Squat", 4, 15, 30, "Moderate", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Deep and fast", "Bodyweight Squat"),
        ex("Walking Lunges", 3, 12, 30, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Fast tempo, long strides", "Reverse Lunges"),
        ex("Kettlebell Swing", 3, 15, 30, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings"], "intermediate", "Hip snap", "Dumbbell Swing"),
        ex("Plank to Push-Up", 3, 10, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps"], "intermediate", "Minimize hip sway", "Plank"),
    ])

def shred30_hiit():
    return wo("HIIT Blast", "hiit", 35, [
        ex("Burpee", 5, 10, 15, "30s on/15s off", "Bodyweight", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "All out effort", "Squat Thrust"),
        ex("Box Jump", 4, 10, 15, "20-24 inch", "Box", "Legs", "Quadriceps", ["Calves", "Glutes"], "intermediate", "Explosive, soft landing", "Squat Jump"),
        ex("Battle Ropes", 4, 1, 15, "30s max effort", "Battle Ropes", "Full Body", "Shoulders", ["Core"], "intermediate", "Alternating waves", "Jumping Jacks"),
        ex("Tuck Jump", 3, 10, 15, "Max height", "Bodyweight", "Legs", "Quadriceps", ["Core"], "intermediate", "Knees to chest at peak", "Squat Jump"),
        ex("V-Up", 3, 15, 15, "Bodyweight", "Bodyweight", "Core", "Rectus Abdominis", [], "intermediate", "Touch toes at top", "Crunch"),
    ])

weeks_data_30 = {}
weeks = {}
for w in range(1, 5):
    if w == 1: focus = "Week 1 - Shock the system: establish high intensity baseline"
    elif w == 2: focus = "Week 2 - Intensify: reduce rest, increase sets"
    elif w == 3: focus = "Week 3 - Peak: maximum intensity and volume"
    else: focus = "Week 4 - Final push: test results, beat week 1 numbers"
    wkts = [shred30_push(), shred30_pull(), shred30_legs(), shred30_hiit(), shred30_push(), shred30_legs()]
    weeks[w] = {"focus": focus, "workouts": wkts}
weeks_data_30[(4, 6)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("30 Day Shred Challenge", "Challenges",
    "30-day intensive shred challenge - 6 days per week of high-intensity training",
    [4], [6], True, "High", weeks_data_30, mn)
if s: helper.update_tracker("30 Day Shred Challenge", "Done"); print("30 Day Shred Challenge - DONE")

# ========================================================================
# 4. PUSH-UP MASTERY - Progression from 0 to 50+
# ========================================================================

def pushup_beginner():
    return wo("Push-Up Progressions", "strength", 30, [
        ex("Wall Push-Up", 3, 15, 45, "Bodyweight against wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Hands on wall, lean in, push back", "Counter Push-Up"),
        ex("Incline Push-Up", 3, 12, 45, "Hands on bench/stairs", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Lower body than wall, build strength", "Knee Push-Up"),
        ex("Knee Push-Up", 3, 10, 60, "Bodyweight", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full ROM from knees", "Incline Push-Up"),
        ex("Negative Push-Up", 3, 5, 90, "Lower slowly 5 seconds", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Slow eccentric from top position", "Push-Up"),
        ex("Plank", 3, 1, 45, "20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Push-up top position, hold", "Dead Bug"),
    ])

def pushup_intermediate():
    return wo("Push-Up Building", "strength", 35, [
        ex("Push-Up", 4, 10, 60, "Full push-up, strict form", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Chest to floor, lock out", "Knee Push-Up"),
        ex("Wide Push-Up", 3, 8, 60, "Hands wider than shoulders", "Bodyweight", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Wider = more chest, controlled", "Push-Up"),
        ex("Diamond Push-Up", 3, 6, 60, "Hands together", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Elbows tight to body", "Close-Grip Push-Up"),
        ex("Decline Push-Up", 3, 8, 60, "Feet on bench/chair", "Bodyweight", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "Feet elevated, harder angle", "Pike Push-Up"),
        ex("Push-Up Hold", 3, 1, 45, "Hold bottom position 10s", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Build bottom position strength", "Plank"),
    ])

def pushup_advanced():
    return wo("Push-Up Mastery", "strength", 40, [
        ex("Push-Up", 5, 15, 45, "High volume sets", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Consistent tempo, no rest at top", "Knee Push-Up"),
        ex("Clap Push-Up", 3, 5, 90, "Explosive, clap in air", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps"], "advanced", "Explosive push, quick clap, soft landing", "Push-Up"),
        ex("Archer Push-Up", 3, 5, 90, "Wide stance, shift to one side", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "Shift weight to working arm", "Wide Push-Up"),
        ex("Deficit Push-Up", 3, 8, 60, "Hands on plates/books for depth", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Extra ROM at bottom, deeper stretch", "Push-Up"),
        ex("Pike Push-Up", 3, 8, 60, "Hips high, vertical press", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Triceps", "Upper Chest"], "intermediate", "Head between hands, press up", "Decline Push-Up"),
    ])

weeks_data_pu = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.33:
            focus = f"Week {w} - Foundation: wall and incline push-ups, build base"
            wkts = [pushup_beginner(), pushup_beginner(), pushup_beginner()]
        elif p <= 0.66:
            focus = f"Week {w} - Building: full push-ups, increasing volume"
            wkts = [pushup_intermediate(), pushup_beginner(), pushup_intermediate()]
        else:
            focus = f"Week {w} - Mastery: variations and high-rep sets"
            wkts = [pushup_advanced(), pushup_intermediate(), pushup_advanced()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [3, 4]:
        weeks_data_pu[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Push-Up Mastery", "Progressions",
    "Progressive push-up program from wall push-ups to advanced variations",
    [4, 8, 12], [3, 4], False, "High", weeks_data_pu, mn)
if s: helper.update_tracker("Push-Up Mastery", "Done"); print("Push-Up Mastery - DONE")

# ========================================================================
# 5. PULL-UP JOURNEY - From 0 to 10+ pull-ups
# ========================================================================

def pullup_beginner():
    return wo("Pull-Up Foundation", "strength", 30, [
        ex("Dead Hang", 3, 1, 60, "Hang 15-30 seconds", "Pull-Up Bar", "Back", "Forearms", ["Latissimus Dorsi", "Shoulders"], "beginner", "Full grip, relax shoulders, breathe", "Farmer's Hold"),
        ex("Scapular Pull-Up", 3, 8, 60, "Hang and retract scapula", "Pull-Up Bar", "Back", "Lower Trapezius", ["Rhomboids", "Latissimus Dorsi"], "beginner", "Shoulders down and back without bending arms", "Band Pull-Apart"),
        ex("Band-Assisted Pull-Up", 3, 5, 90, "Thick band for assistance", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "beginner", "Full ROM, controlled up and down", "Lat Pulldown"),
        ex("Inverted Row", 3, 8, 60, "Body under bar, feet on floor", "Barbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull chest to bar, squeeze back", "Seated Cable Row"),
        ex("Lat Pulldown", 3, 10, 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Build pull strength", "Band Pulldown"),
    ])

def pullup_building():
    return wo("Pull-Up Building", "strength", 35, [
        ex("Negative Pull-Up", 4, 3, 120, "Jump up, lower 5 seconds", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Jump to top, lower as slowly as possible", "Band-Assisted Pull-Up"),
        ex("Band-Assisted Pull-Up", 3, 5, 90, "Medium band", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Full ROM, thinner band over time", "Lat Pulldown"),
        ex("Chin-Up", 3, 3, 120, "Supinated grip, easier than pull-up", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Supinated grip for bicep assist", "Band-Assisted Chin-Up"),
        ex("Inverted Row", 3, 10, 60, "Feet elevated for more difficulty", "Barbell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull chest to bar", "Seated Cable Row"),
        ex("Dumbbell Row", 3, 10, 60, "Heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Build unilateral pull strength", "Cable Row"),
    ])

def pullup_mastery():
    return wo("Pull-Up Mastery", "strength", 40, [
        ex("Pull-Up", 5, 5, 120, "Strict form, add reps each week", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "intermediate", "Dead hang start, chin over bar", "Lat Pulldown"),
        ex("Wide-Grip Pull-Up", 3, 4, 90, "Hands wider than shoulders", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Teres Major"], "advanced", "Wide grip targets lat width", "Wide-Grip Lat Pulldown"),
        ex("Chin-Up", 3, 6, 90, "Supinated grip", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full ROM, controlled", "Supinated Lat Pulldown"),
        ex("Commando Pull-Up", 3, 4, 90, "Perpendicular to bar, alternating sides", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "advanced", "Head to each side of bar", "Pull-Up"),
        ex("L-Sit Pull-Up", 3, 3, 120, "Legs extended in L-sit", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core", "Hip Flexors"], "advanced", "Keep legs parallel to floor", "Pull-Up"),
    ])

weeks_data_pull = {}
for dur in [4, 8, 12]:
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.33:
            focus = f"Week {w} - Foundation: dead hangs, scapular work, assisted pull-ups"
            wkts = [pullup_beginner(), pullup_beginner(), pullup_beginner()]
        elif p <= 0.66:
            focus = f"Week {w} - Building: negatives, fewer assisted reps, first strict reps"
            wkts = [pullup_building(), pullup_beginner(), pullup_building()]
        else:
            focus = f"Week {w} - Mastery: strict pull-ups, variations, volume"
            wkts = [pullup_mastery(), pullup_building(), pullup_mastery()]
        weeks[w] = {"focus": focus, "workouts": wkts}
    for sess in [3, 4]:
        weeks_data_pull[(dur, sess)] = weeks

mn = helper.get_next_migration_num()
s = helper.insert_full_program("Pull-Up Journey", "Progressions",
    "From zero to hero - progressive pull-up program from dead hangs to strict pull-ups",
    [4, 8, 12], [3, 4], False, "High", weeks_data_pull, mn)
if s: helper.update_tracker("Pull-Up Journey", "Done"); print("Pull-Up Journey - DONE")

helper.close()
print("\n=== ALL PREMIUM + CHALLENGES + PROGRESSIONS COMPLETE ===")
