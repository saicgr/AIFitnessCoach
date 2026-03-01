#!/usr/bin/env python3
"""
Category 9: Progressions Programs (Medium & Low Priority) - Remaining 18 programs
==================================================================================
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from program_sql_helper import ProgramSQLHelper


def ex(name, sets, reps, rest, wg, equip, bp, pm, sm, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest, "weight_guidance": wg,
            "equipment": equip, "body_part": bp, "primary_muscle": pm,
            "secondary_muscles": sm, "difficulty": diff, "form_cue": cue, "substitution": sub}


def phase_for(p):
    if p <= 0.25: return "Foundation", 3
    elif p <= 0.5: return "Build", 4
    elif p <= 0.75: return "Advance", 4
    else: return "Master", 5


# ==== LUNGE TO PISTOL ====
def lunge_to_pistol(dur, sess):
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        ph, s = phase_for(p)
        wk = []
        wk.append({"workout_name": "Day 1 - Single Leg Skill", "type": "strength", "duration_minutes": 35, "exercises": [
            ex("Assisted Pistol Squat" if p > 0.5 else "Box Pistol Squat" if p > 0.25 else "Deep Lunge", s, "5-6 each leg" if p > 0.5 else "6-8 each leg", 90,
               "Bodyweight", "TRX/Box" if p < 0.75 else "None", "Legs", "Quadriceps", ["Glutes", "Core"],
               "intermediate" if p > 0.25 else "beginner",
               "Hold support, full depth single leg" if p > 0.25 else "Deep lunge, back knee near floor",
               "Bulgarian Split Squat"),
            ex("Bulgarian Split Squat", s, "8-10 each", 60, "Moderate", "Dumbbells" if p > 0.25 else "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot on bench, deep stretch", "Reverse Lunge"),
            ex("Single-Leg Balance (Eyes Closed)", 3, "20-30 seconds each", 30, "Bodyweight", "None", "Legs", "Glute Medius", ["Calves", "Core"], "beginner", "Close eyes to increase proprioception", "Single-Leg Stand"),
            ex("Cossack Squat", 3, "6-8 each side", 60, "Bodyweight", "None", "Legs", "Adductors", ["Quadriceps", "Glutes"], "intermediate", "Wide stance, full shift to one side", "Lateral Lunge"),
            ex("Ankle Mobility Drill", 3, "10 each side", 15, "Bodyweight", "Wall", "Legs", "Tibialis Anterior", ["Calves"], "beginner", "Knee over toe against wall", "Calf Stretch"),
        ]})
        wk.append({"workout_name": "Day 2 - Leg Strength", "type": "strength", "duration_minutes": 35, "exercises": [
            ex("Goblet Squat", s, "10-12", 75, "Moderate-Heavy", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, elbows inside knees", "Bodyweight Squat"),
            ex("Step-Up (High Box)", s, "8-10 each", 60, "Moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Drive through heel, full extension", "Reverse Lunge"),
            ex("Single-Leg Deadlift", 3, "8 each", 60, "Moderate", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge forward, back leg extends", "Romanian Deadlift"),
            ex("Wall Sit (Single Leg)", 3, "15-20 sec each", 30, "Bodyweight", "Wall", "Legs", "Quadriceps", ["Core"], "intermediate", "One leg extended, hold on other", "Two-Leg Wall Sit"),
            ex("Calf Raise", 3, "15-20", 30, "Bodyweight", "Step", "Legs", "Calves", ["Soleus"], "beginner", "Full range, single leg if able", "Seated Calf Raise"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Mobility & Plyometrics", "type": "plyometric", "duration_minutes": 30, "exercises": [
                ex("Squat Jump", 4, "6-8", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, explosive jump", "Bodyweight Squat"),
                ex("Single-Leg Hop", 3, "5-6 each", 60, "Bodyweight", "None", "Legs", "Calves", ["Quadriceps", "Glute Medius"], "intermediate", "Stick each landing", "Squat Jump"),
                ex("Deep Squat Hold", 3, "30-45 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hip Flexors"], "beginner", "Full depth, chest up", "Assisted Squat"),
                ex("Pigeon Stretch", 3, "30 sec each side", 15, "Bodyweight", "None", "Legs", "Glutes", ["Hip Flexors"], "beginner", "Sink into hip stretch", "Figure-4 Stretch"),
                ex("Hip Flexor Stretch", 3, "30 sec each side", 15, "Bodyweight", "None", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Deep lunge, squeeze back glute", "Kneeling Hip Flexor"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Pistol Test & Volume", "type": "strength", "duration_minutes": 30, "exercises": [
                ex("Pistol Squat (Test)" if p > 0.5 else "Box Pistol (Decreasing Height)", 3, "Max attempts each leg" if p > 0.5 else "5-6 each", 120,
                   "Bodyweight", "None" if p > 0.75 else "Box", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced" if p > 0.75 else "intermediate",
                   "Full depth single leg squat, no assistance" if p > 0.75 else "Lower box height each week", "Assisted Pistol"),
                ex("Glute Bridge", 3, "15-20", 30, "Bodyweight", "None", "Legs", "Glutes", ["Hamstrings"], "beginner", "Drive through heels", "Hip Thrust"),
                ex("Reverse Lunge", 3, "10 each", 45, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes"], "beginner", "Step back, controlled descent", "Forward Lunge"),
                ex("Plank", 3, "30-45 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Core stability for balance", "Dead Bug"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== HOLLOW BODY PROGRESSION ====
def hollow_body_prog(dur, sess):
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.3: ph, hold = "Tuck Hollow", "15-20 seconds"
        elif p <= 0.6: ph, hold = "Single Leg Extend", "20-30 seconds"
        elif p <= 0.85: ph, hold = "Full Hollow", "20-30 seconds"
        else: ph, hold = "Hollow Rocks", "30-45 seconds"
        wk = []
        wk.append({"workout_name": "Day 1 - Hollow Body Skill", "type": "core", "duration_minutes": 20, "exercises": [
            ex("Hollow Body Hold" if p > 0.3 else "Tuck Hollow Hold", 5, hold, 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis", "Hip Flexors"], "intermediate" if p > 0.3 else "beginner", "Low back pressed to floor, arms by ears" if p > 0.3 else "Tuck knees, flatten lower back", "Dead Bug"),
            ex("Dead Bug", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Opposite arm/leg extend, low back flat", "Bird Dog"),
            ex("Hollow Body Rock", 3 if p > 0.5 else 0, "10-15" if p > 0.5 else "0", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Rock without breaking hollow shape", "Hollow Hold") if p > 0.5 else ex("Lying Leg Raise", 3, "10-12", 30, "Bodyweight", "None", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "beginner", "Lower back stays down", "Reverse Crunch"),
            ex("Dish Hold (Arms Overhead)", 3, hold, 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "intermediate", "Gymnastics position, shoulders off floor", "Crunch Hold"),
            ex("Plank", 3, "30-45 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Complementary anti-extension work", "Dead Bug"),
        ]})
        wk.append({"workout_name": "Day 2 - Superman & Arch", "type": "core", "duration_minutes": 20, "exercises": [
            ex("Superman Hold", 4, "15-20 seconds", 30, "Bodyweight", "None", "Back", "Erector Spinae", ["Glutes", "Rear Deltoid"], "beginner", "Arms and legs off floor, counterbalance to hollow", "Bird Dog"),
            ex("Arch Body Rock", 3, "10-12", 30, "Bodyweight", "None", "Back", "Erector Spinae", ["Glutes"], "beginner", "Rock in superman position", "Superman Hold"),
            ex("Alternating V-Up", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "intermediate", "Touch opposite hand to foot", "Bicycle Crunch"),
            ex("Side Plank", 3, "20-30 seconds each", 30, "Bodyweight", "None", "Core", "Obliques", ["Glute Medius"], "beginner", "Hips stacked, body straight", "Kneeling Side Plank"),
            ex("Cat-Cow", 3, "10 cycles", 15, "Bodyweight", "None", "Back", "Erector Spinae", ["Rectus Abdominis"], "beginner", "Slow, controlled spinal articulation", "Spinal Wave"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Core Endurance", "type": "core", "duration_minutes": 20, "exercises": [
                ex("Hollow Hold Max Time", 3, "Max hold", 60, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Record your time, beat it next week", "Tuck Hollow"),
                ex("Flutter Kicks", 3, "20 each side", 30, "Bodyweight", "None", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "beginner", "Small quick kicks, low back flat", "Scissor Kicks"),
                ex("V-Up", 3, "10-15", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Arms and legs meet at top", "Crunch"),
                ex("Plank Shoulder Tap", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Shoulders", "Obliques"], "intermediate", "Minimize hip sway", "Plank"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Active Recovery Core", "type": "flexibility", "duration_minutes": 15, "exercises": [
                ex("Yoga Flow", 3, "5 flows", 15, "Bodyweight", "None", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Sun salutation sequence", "Dynamic Stretch"),
                ex("Deep Breathing", 3, "10 breaths", 15, "Bodyweight", "None", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Belly breathing, 4-count in, 6-count out", "Box Breathing"),
                ex("Cobra Stretch", 3, "20 seconds", 15, "Bodyweight", "None", "Core", "Hip Flexors", ["Rectus Abdominis"], "beginner", "Gentle backbend", "Sphinx Stretch"),
            ]})
        if sess >= 5:
            wk.append({"workout_name": "Day 5 - Hollow Variations", "type": "core", "duration_minutes": 20, "exercises": [
                ex("Single-Arm Hollow Hold", 3, "15 sec each arm up", 30, "Bodyweight", "None", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "One arm by ear, other by side, switch", "Hollow Hold"),
                ex("Hanging Knee Raise", 3, "10-12", 30, "Bodyweight", "Pull-Up Bar", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "beginner", "Builds compression strength", "Lying Knee Raise"),
                ex("Hollow Body Hold (Weighted)", 3, "15-20 seconds", 30, "Light", "Ankle Weights", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Add light weight for progression", "Hollow Hold"),
                ex("Reverse Crunch", 3, "12-15", 30, "Bodyweight", "None", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "beginner", "Curl hips off floor", "Lying Leg Raise"),
            ]})
        if sess >= 6:
            wk.append({"workout_name": "Day 6 - Gymnastics Core", "type": "calisthenics", "duration_minutes": 20, "exercises": [
                ex("L-Sit Attempt", 3, "10-15 seconds", 45, "Bodyweight", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "intermediate", "Build from hollow body strength", "Tuck L-Sit"),
                ex("Handstand Hold (Wall)", 3, "15-20 seconds", 45, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Hollow body position inverted", "Pike Hold"),
                ex("Tuck Planche Lean", 3, "10-15 seconds", 45, "Bodyweight", "Floor", "Shoulders", "Anterior Deltoid", ["Core", "Chest"], "intermediate", "Apply hollow body tension", "Plank Lean"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== WALL WALK TO HSPU ====
def wall_walk_hspu(dur, sess):
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: ph = "Wall Walk & Pike Push-Up"
        elif p <= 0.5: ph = "Wall Handstand Hold & Negative"
        elif p <= 0.75: ph = "Partial Range HSPU"
        else: ph = "Full Handstand Push-Up"
        s = 4 if p > 0.25 else 3
        wk = []
        wk.append({"workout_name": "Day 1 - HSPU Skill", "type": "calisthenics", "duration_minutes": 40, "exercises": [
            ex("Wall Walk" if p <= 0.25 else "Wall Handstand Hold" if p <= 0.5 else "Handstand Push-Up (Partial)" if p <= 0.75 else "Handstand Push-Up (Full)",
               5 if p > 0.5 else 4, "3-4 walks" if p <= 0.25 else "20-30 seconds" if p <= 0.5 else "3-5" if p <= 0.75 else "3-5",
               90, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Triceps", "Core", "Traps"],
               "intermediate" if p <= 0.5 else "advanced",
               "Walk hands to wall, descend controlled" if p <= 0.25 else "Belly to wall, straight line" if p <= 0.5 else "Head to mat, push up" if p <= 0.75 else "Full range, head to floor and back",
               "Pike Push-Up"),
            ex("Pike Push-Up (Feet Elevated)", s, "6-10", 75, "Bodyweight", "Bench", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Feet on bench, hips high, head to floor", "Standard Pike Push-Up"),
            ex("Eccentric HSPU (Negative)" if p > 0.25 else "Pike Hold", s, "3-5 negatives" if p > 0.25 else "20-30 seconds", 90 if p > 0.25 else 30,
               "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate",
               "Kick up, lower slowly to floor" if p > 0.25 else "Hips high, weight on shoulders", "Pike Push-Up"),
            ex("Dumbbell Shoulder Press", s, "8-10", 75, "Moderate-Heavy", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Builds overhead pressing strength", "Barbell OHP"),
            ex("Handstand Shoulder Tap" if p > 0.5 else "Plank Shoulder Tap", 3, "4-5 each hand" if p > 0.5 else "8-10 each hand", 60 if p > 0.5 else 30,
               "Bodyweight", "Wall" if p > 0.5 else "None", "Core", "Transverse Abdominis", ["Shoulders", "Obliques"],
               "advanced" if p > 0.5 else "intermediate",
               "In handstand, tap shoulders without falling" if p > 0.5 else "Minimize hip sway", "Plank"),
            ex("Wrist Warm-Up", 3, "30 seconds each position", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Essential for HSPU wrist health", "Wrist Curls"),
        ]})
        wk.append({"workout_name": "Day 2 - Pressing Strength", "type": "strength", "duration_minutes": 35, "exercises": [
            ex("Barbell Overhead Press", s, "6-8", 120, "Moderate-Heavy" if p <= 0.5 else "Heavy", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Strict press, brace core", "Dumbbell Press"),
            ex("Dip", s, "8-12", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Pressing strength supports HSPU", "Bench Dip"),
            ex("Lateral Raise", 3, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder stability", "Cable Lateral Raise"),
            ex("Face Pull", 3, "15-20", 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health balance", "Band Pull-Apart"),
            ex("Hollow Body Hold", 3, "30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Core tension for handstand", "Dead Bug"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Upper Body Balance", "type": "hypertrophy", "duration_minutes": 35, "exercises": [
                ex("Pull-Up", s, "6-10", 75, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Balance pushing with pulling", "Lat Pulldown"),
                ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Endurance pressing", "Knee Push-Up"),
                ex("Dumbbell Row", 3, "8-10 each", 60, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to hip", "Cable Row"),
                ex("EZ Bar Curl", 3, "10-12", 45, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "beginner", "Balance tricep-heavy work", "Dumbbell Curl"),
                ex("Plank", 3, "45-60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Core endurance", "Dead Bug"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Test & Mobility", "type": "calisthenics", "duration_minutes": 30, "exercises": [
                ex("HSPU Max Test" if p > 0.5 else "Wall Walk Max", 3, "Max reps" if p > 0.5 else "3-4 walks", 120,
                   "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "advanced" if p > 0.5 else "intermediate",
                   "Record your max" if p > 0.5 else "Walk as high as possible", "Pike Push-Up"),
                ex("Shoulder CARs", 3, "5 each direction", 15, "Bodyweight", "None", "Shoulders", "Rotator Cuff", ["Traps"], "beginner", "Controlled articular rotation", "Arm Circles"),
                ex("Wrist Mobility", 3, "10 each position", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", [], "beginner", "Wrist care for overhead work", "Wrist Curls"),
                ex("Thoracic Extension", 3, "8-10", 15, "Bodyweight", "Foam Roller", "Back", "Thoracic Erector Spinae", ["Rhomboids"], "beginner", "Open up for overhead position", "Cat-Cow"),
            ]})
        if sess >= 5:
            wk.append({"workout_name": "Day 5 - Volume Pressing", "type": "strength", "duration_minutes": 30, "exercises": [
                ex("Z-Press (Seated Floor Press)", 3, "8-10", 75, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Core", "Triceps"], "intermediate", "Seated on floor, no back support, pure shoulder", "Dumbbell Press"),
                ex("Ring Dip" if p > 0.5 else "Dip", 3, "6-10", 60, "Bodyweight", "Rings" if p > 0.5 else "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Core"], "intermediate", "Turn out at top for ring dip" if p > 0.5 else "Full range", "Bench Dip"),
                ex("Arnold Press", 3, "10-12", 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Rotate palms during press", "Dumbbell Press"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== TUCK TO FULL PLANCHE ====
def tuck_to_planche(dur, sess):
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.2: ph = "Tuck Planche Hold"
        elif p <= 0.4: ph = "Advanced Tuck"
        elif p <= 0.6: ph = "Straddle Planche Entry"
        elif p <= 0.8: ph = "Straddle Planche Hold"
        else: ph = "Full Planche Attempt"
        s = 5 if p > 0.5 else 4
        wk = []
        wk.append({"workout_name": "Day 1 - Planche Skill", "type": "calisthenics", "duration_minutes": 45, "exercises": [
            ex("Tuck Planche Hold" if p <= 0.2 else "Advanced Tuck Planche" if p <= 0.4 else "Straddle Planche Hold" if p <= 0.8 else "Full Planche Attempt",
               5, "10-20 seconds" if p <= 0.4 else "5-15 seconds", 120,
               "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid", ["Core", "Chest", "Wrist Flexors"],
               "intermediate" if p <= 0.4 else "advanced",
               "Knees to chest, round back" if p <= 0.2 else "Hips higher, back flatter" if p <= 0.4 else "Legs wide, full elevation" if p <= 0.8 else "Legs together, body horizontal",
               "Planche Lean"),
            ex("Planche Push-Up (Current Level)", 4, "2-4", 120, "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid", ["Chest", "Triceps", "Core"], "advanced", "Lower and press in current planche position", "Pseudo Planche Push-Up"),
            ex("Planche Lean Hold", 4, "15-25 seconds", 60, "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid", ["Core", "Wrist Flexors"], "intermediate", "Maximum forward lean", "Plank Lean"),
            ex("L-Sit to Planche Transition" if p > 0.4 else "L-Sit Hold", 3, "3-5 transitions" if p > 0.4 else "15-20 seconds", 90,
               "Bodyweight", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Anterior Deltoid"], "advanced" if p > 0.4 else "intermediate",
               "Press from L-sit into planche" if p > 0.4 else "Arms locked, legs parallel to floor", "Tuck L-Sit"),
            ex("Hollow Body Hold", 3, "30-45 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Essential body tension", "Dead Bug"),
            ex("Wrist Conditioning", 3, "30 seconds each", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Critical for planche wrist health", "Wrist Curls"),
        ]})
        wk.append({"workout_name": "Day 2 - Pressing Strength", "type": "strength", "duration_minutes": 40, "exercises": [
            ex("Weighted Dip", s, "5-8", 120, "Heavy", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Add weight progressively", "Bodyweight Dip"),
            ex("Pike Push-Up (Elevated)", s, "6-10", 75, "Bodyweight", "Bench", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Feet elevated, head to floor", "Standard Pike Push-Up"),
            ex("Ring Push-Up", 3, "8-10", 60, "Bodyweight", "Gymnastics Rings", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Turn out at top", "Push-Up"),
            ex("Handstand Hold (Wall)", 3, "20-30 seconds", 45, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Builds shoulder endurance", "Pike Hold"),
            ex("Straight-Arm Strength (Maltese Lean)", 3, "8-12 seconds", 60, "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid", ["Chest", "Biceps"], "advanced", "Wide arm position, lean forward", "Wide Planche Lean"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Pull Balance", "type": "strength", "duration_minutes": 35, "exercises": [
                ex("Pull-Up", s, "6-10", 75, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Balance push-heavy program", "Lat Pulldown"),
                ex("Front Lever Tuck Hold", 3, "10-15 seconds", 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Core"], "intermediate", "Pull body horizontal, knees tucked", "Inverted Row"),
                ex("Inverted Row", 3, "10-12", 45, "Bodyweight", "Barbell", "Back", "Rhomboids", ["Lats", "Biceps"], "beginner", "Pull chest to bar", "TRX Row"),
                ex("Face Pull", 3, "15-20", 30, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health", "Band Pull-Apart"),
                ex("Bicep Curl", 3, "10-12", 45, "Moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Balance pushing volume", "Cable Curl"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Core & Flexibility", "type": "flexibility", "duration_minutes": 30, "exercises": [
                ex("Dragon Flag Negative", 3, "3-5", 60, "Bodyweight", "Bench", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Lower as one rigid unit", "Lying Leg Raise"),
                ex("V-Sit Hold", 3, "10-15 seconds", 45, "Bodyweight", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Higher L-sit with legs angled up", "L-Sit"),
                ex("Straddle Stretch", 3, "45-60 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hamstrings"], "beginner", "Wide legs, lean forward for straddle planche", "Butterfly Stretch"),
                ex("Pike Stretch", 3, "45-60 seconds", 15, "Bodyweight", "None", "Legs", "Hamstrings", ["Calves"], "beginner", "Reach for toes, straight back", "Standing Toe Touch"),
                ex("Shoulder Dislocate", 3, "10-12", 15, "Light", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rotator Cuff"], "beginner", "Wide grip, pass over head", "Arm Circles"),
            ]})
        if sess >= 5:
            wk.append({"workout_name": "Day 5 - Conditioning", "type": "circuit", "duration_minutes": 30, "exercises": [
                ex("Pseudo Planche Push-Up", 3, "8-10", 60, "Bodyweight", "None", "Shoulders", "Anterior Deltoid", ["Chest", "Core"], "intermediate", "Hands by waist, lean forward", "Decline Push-Up"),
                ex("Burpee", 3, "10", 45, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full body conditioning", "Squat Thrust"),
                ex("Plank to Push-Up", 3, "10", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Alternate lead arm", "Plank"),
                ex("Kettlebell Swing", 3, "15", 45, "Moderate", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Conditioning and posterior chain", "Dumbbell Swing"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== GENERIC FLIP/MOVEMENT PROGRESSION ====
def flip_progression(dur, sess, flip_type="backflip"):
    """Generic flip/aerial progression framework."""
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: ph = "Conditioning & Drills"
        elif p <= 0.5: ph = "Trampoline/Soft Surface Practice"
        elif p <= 0.75: ph = "Spotted/Assisted Attempts"
        else: ph = "Independent Practice"
        wk = []
        # D1: Conditioning for flips
        wk.append({"workout_name": f"Day 1 - {flip_type.title()} Conditioning", "type": "plyometric", "duration_minutes": 40, "exercises": [
            ex("Squat Jump (Max Height)", 5, "5-6", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves", "Core"], "intermediate", "Explosive vertical jump, builds flip takeoff power", "Box Jump"),
            ex("Tuck Jump", 4, "6-8", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Pull knees to chest at peak, builds tuck speed", "Squat Jump"),
            ex("Back Extension (GHD)" if "back" in flip_type else "Front Roll Drill", 4, "10-12" if "back" in flip_type else "5-6", 45,
               "Bodyweight", "GHD" if "back" in flip_type else "Soft Mat", "Back" if "back" in flip_type else "Full Body",
               "Erector Spinae" if "back" in flip_type else "Core", ["Glutes"] if "back" in flip_type else ["Shoulders", "Neck"],
               "intermediate", "Builds back strength for arch" if "back" in flip_type else "Tuck and roll forward smoothly", "Superman"),
            ex("Box Jump", 4, "5-6", 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Height and landing control", "Squat Jump"),
            ex("Hollow Body Hold", 3, "20-30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Body tension for air control", "Dead Bug"),
            ex("Bridge Push-Off" if "back" in flip_type else "Handstand Hold (Wall)", 3, "5-6" if "back" in flip_type else "20-30 seconds", 45,
               "Bodyweight", "None" if "back" in flip_type else "Wall", "Back" if "back" in flip_type else "Shoulders",
               "Erector Spinae" if "back" in flip_type else "Anterior Deltoid", ["Glutes", "Shoulders"] if "back" in flip_type else ["Core", "Traps"],
               "intermediate", "Push from bridge to standing" if "back" in flip_type else "Builds inversion comfort", "Bridge Hold"),
        ]})
        # D2: Strength
        wk.append({"workout_name": "Day 2 - Strength for Flips", "type": "strength", "duration_minutes": 40, "exercises": [
            ex("Goblet Squat", 4, "10-12", 75, "Moderate-Heavy", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, builds takeoff power", "Bodyweight Squat"),
            ex("Pull-Up", 4, "6-10", 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Upper body strength for air control", "Lat Pulldown"),
            ex("Dip", 4, "8-10", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Pressing strength for landing control", "Push-Up"),
            ex("Romanian Deadlift", 3, "8-10", 75, "Moderate-Heavy", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Posterior chain power", "Good Morning"),
            ex("Plank", 3, "45-60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Core stability for flips", "Dead Bug"),
            ex("Calf Raise (Explosive)", 3, "15-20", 30, "Bodyweight", "Step", "Legs", "Calves", ["Soleus"], "beginner", "Explosive push for takeoff", "Jump Rope"),
        ]})
        # D3: Skill Practice
        if sess >= 3:
            wk.append({"workout_name": f"Day 3 - {flip_type.title()} Skill Practice", "type": "sport_specific", "duration_minutes": 40, "exercises": [
                ex(f"{flip_type.title()} Drill (Trampoline/Soft Surface)" if p <= 0.5 else f"{flip_type.title()} Attempt (Spotted)" if p <= 0.75 else f"{flip_type.title()} Practice",
                   6, "3-5 attempts", 120, "Bodyweight", "Trampoline/Soft Surface", "Full Body", "Core",
                   ["Legs", "Shoulders", "Back"], "intermediate" if p <= 0.5 else "advanced",
                   "Practice on safe surface with progression" if p <= 0.5 else "With spotter or into foam pit" if p <= 0.75 else "Independent practice, focus on consistency",
                   "Tuck Jump"),
                ex("Cartwheel" if "side" in flip_type else "Safety Roll", 4, "5 each side", 30,
                   "Bodyweight", "Soft Surface", "Full Body", "Core", ["Shoulders", "Obliques"],
                   "beginner", "Movement pattern practice", "Forward Roll"),
                ex("Precision Landing Drill", 4, "6-8", 45, "Bodyweight", "None", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Jump to marked spot, stick the landing", "Box Step-Down"),
                ex("Broad Jump", 3, "5-6", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Max distance, stick landing", "Squat Jump"),
                ex("Flexibility Routine", 1, "5 minutes", 0, "Bodyweight", "None", "Full Body", "Hamstrings", ["Hip Flexors", "Shoulders"], "beginner", "Splits, bridge, pike stretches", "Dynamic Stretching"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Flexibility & Recovery", "type": "flexibility", "duration_minutes": 30, "exercises": [
                ex("Bridge Hold", 3, "15-20 seconds", 30, "Bodyweight", "None", "Back", "Erector Spinae", ["Glutes", "Shoulders", "Hip Flexors"], "intermediate", "Full bridge for back flexibility", "Glute Bridge"),
                ex("Front Splits Stretch", 3, "30 sec each leg", 15, "Bodyweight", "None", "Legs", "Hamstrings", ["Hip Flexors"], "beginner", "Progressive splits work", "Lunge Stretch"),
                ex("Shoulder Dislocate", 3, "10-12", 15, "Light", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rotator Cuff"], "beginner", "Open shoulders for flips", "Arm Circles"),
                ex("Deep Squat Hold", 3, "30-45 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hip Flexors"], "beginner", "Hip mobility", "Assisted Squat Hold"),
                ex("Foam Roll", 1, "5-10 minutes", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Recovery for high-impact training", "Stretching"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== PARKOUR PROGRAMS ====
def parkour_program(dur, sess, level="fundamentals"):
    """Parkour program at different levels."""
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: ph = "Movement Basics"
        elif p <= 0.5: ph = "Vault & Roll Technique"
        elif p <= 0.75: ph = "Flow Combinations"
        else: ph = "Advanced Application"
        wk = []
        wk.append({"workout_name": "Day 1 - Parkour Movement", "type": "circuit", "duration_minutes": 45, "exercises": [
            ex("Precision Jump", 4, "6-8", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Jump to specific spot, stick landing", "Broad Jump"),
            ex("Safety Roll", 4, "5 each side", 30, "Bodyweight", "Soft Mat", "Full Body", "Shoulders", ["Core", "Back"], "beginner", "Diagonal shoulder to hip roll", "Forward Roll"),
            ex("Speed Vault Drill", 4, "5 each side", 45, "Bodyweight", "Low Rail/Box", "Full Body", "Triceps", ["Core", "Shoulders"], "intermediate", "One hand on obstacle, swing legs over", "Box Jump-Over"),
            ex("Cat Hang to Climb-Up" if level != "fundamentals" else "Pull-Up", 4, "4-6" if level != "fundamentals" else "6-10", 75,
               "Bodyweight", "Wall/Bar" if level != "fundamentals" else "Pull-Up Bar", "Back", "Latissimus Dorsi",
               ["Biceps", "Core", "Forearms"], "intermediate",
               "Hang from edge, pull up and over" if level != "fundamentals" else "Full range, essential for parkour", "Band-Assisted Pull-Up"),
            ex("Bear Crawl", 3, "20 meters", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Knees low, controlled movement", "Mountain Climber"),
            ex("Quadrupedal Movement", 3, "15 meters each direction", 30, "Bodyweight", "None", "Full Body", "Core", ["Shoulders", "Hip Flexors"], "beginner", "Forward, backward, lateral on all fours", "Bear Crawl"),
        ]})
        wk.append({"workout_name": "Day 2 - Strength & Conditioning", "type": "strength", "duration_minutes": 40, "exercises": [
            ex("Pistol Squat (Assisted)" if level != "fundamentals" else "Goblet Squat", 4, "5-6 each" if level != "fundamentals" else "10-12", 60,
               "Bodyweight" if level != "fundamentals" else "Moderate-Heavy", "TRX" if level != "fundamentals" else "Kettlebell",
               "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate",
               "Single-leg for parkour" if level != "fundamentals" else "Deep squat for landing strength", "Bulgarian Split Squat"),
            ex("Dip", 4, "8-12", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Vault pressing strength", "Push-Up"),
            ex("Box Jump", 4, "6-8", 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive power for parkour jumps", "Squat Jump"),
            ex("Hanging Leg Raise", 3, "10-12", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Core and grip for wall climbs", "Lying Leg Raise"),
            ex("Lateral Bound", 3, "8 each side", 45, "Bodyweight", "None", "Legs", "Glute Medius", ["Quadriceps", "Calves"], "intermediate", "Lateral power for direction changes", "Lateral Lunge"),
            ex("Calf Raise", 3, "15-20", 30, "Bodyweight", "Step", "Legs", "Calves", ["Soleus"], "beginner", "Landing absorption and takeoff power", "Jump Rope"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Vault & Wall Drills", "type": "plyometric", "duration_minutes": 40, "exercises": [
                ex("Kong Vault Drill" if level != "fundamentals" else "Box Jump-Over", 4, "5-6", 60, "Bodyweight", "Plyo Box", "Full Body", "Shoulders", ["Triceps", "Core", "Hip Flexors"], "intermediate", "Hands on box, dive through" if level != "fundamentals" else "Jump over box, both hands plant", "Speed Vault"),
                ex("Wall Run" if level != "fundamentals" else "Wall Touch (Running)", 4, "4-5 each side", 60, "Bodyweight", "Wall", "Legs", "Calves", ["Quadriceps", "Core"], "intermediate", "Run at wall, plant foot 2-3 feet up" if level != "fundamentals" else "Run at wall, touch as high as possible", "Box Jump"),
                ex("Tic-Tac (Wall Redirect)" if level == "advanced" else "Drop Landing", 3, "5 each side" if level == "advanced" else "6-8", 60,
                   "Bodyweight", "Wall" if level == "advanced" else "Various Heights", "Legs", "Calves" if level == "advanced" else "Quadriceps",
                   ["Glutes", "Core"], "intermediate", "Kick off wall to change direction" if level == "advanced" else "Land softly from increasing heights", "Lateral Bound"),
                ex("Cartwheel", 3, "5 each side", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Obliques"], "beginner", "Fundamental parkour movement", "Lateral Roll"),
                ex("Balance Rail Walk", 3, "15-20 meters", 30, "Bodyweight", "Low Rail", "Legs", "Calves", ["Core", "Glute Medius"], "beginner", "Walk on narrow surface", "Single-Leg Stand"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Flexibility & Recovery", "type": "flexibility", "duration_minutes": 30, "exercises": [
                ex("Deep Squat Hold", 3, "45-60 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hip Flexors", "Calves"], "beginner", "Full depth, chest up", "Assisted Squat"),
                ex("Bridge Hold", 3, "15-20 seconds", 30, "Bodyweight", "None", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Full bridge, push hips up", "Glute Bridge"),
                ex("Splits Stretching", 3, "30 sec each leg", 15, "Bodyweight", "None", "Legs", "Hamstrings", ["Hip Flexors", "Adductors"], "beginner", "Progressive splits for movement range", "Lunge Stretch"),
                ex("Shoulder Mobility", 3, "10 each movement", 15, "Bodyweight", "None", "Shoulders", "Rotator Cuff", ["Traps"], "beginner", "CARs, dislocates, circles", "Arm Circles"),
                ex("Foam Roll", 1, "5-10 minutes", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Recovery for impact training", "Stretching"),
            ]})
        if sess >= 5:
            wk.append({"workout_name": "Day 5 - Flow Practice", "type": "sport_specific", "duration_minutes": 35, "exercises": [
                ex("Parkour Flow Run", 4, "30-60 seconds", 90, "Bodyweight", "Various", "Full Body", "Quadriceps", ["Core", "Shoulders", "Calves"], "intermediate", "String together moves: run, vault, roll, jump", "Circuit Training"),
                ex("Handstand Hold (Wall)", 3, "15-20 seconds", 45, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Inversion for wall skills", "Pike Hold"),
                ex("Sprint Intervals", 3, "30 meters", 60, "Max Effort", "None", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Speed for approach runs", "Shuttle Run"),
                ex("Plank to Push-Up", 3, "10", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Transition strength", "Plank"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# ==== HANDSTAND PROGRAMS ====
def handstand_program(dur, sess, level="mastery"):
    weeks = {}
    for w in range(1, dur + 1):
        p = w / dur
        if p <= 0.25: ph = "Wall Holds & Kick-Ups"
        elif p <= 0.5: ph = "Balance Drills"
        elif p <= 0.75: ph = "Freestanding Holds" if level == "mastery" else "Walking Drills"
        else: ph = "Freestanding Handstand" if level == "mastery" else "Handstand Walking"
        wk = []
        wk.append({"workout_name": "Day 1 - Handstand Skill", "type": "calisthenics", "duration_minutes": 40, "exercises": [
            ex("Wall Handstand Hold (Belly to Wall)" if p <= 0.25 else "Kick-Up to Freestand Attempt" if p <= 0.5 else "Freestanding Handstand Hold" if level == "mastery" else "Handstand Walk Attempt",
               6, "20-30 seconds" if p <= 0.5 else "5-15 seconds" if level == "mastery" else "5-10 steps", 60,
               "Bodyweight", "Wall" if p <= 0.25 else "None", "Shoulders", "Anterior Deltoid",
               ["Core", "Traps", "Forearms"], "intermediate" if p <= 0.5 else "advanced",
               "Belly to wall, straight line" if p <= 0.25 else "Kick up, find balance" if p <= 0.5 else "Hold as long as possible" if level == "mastery" else "Walk forward on hands",
               "Pike Hold"),
            ex("Handstand Shoulder Tap" if p > 0.5 else "Wall Handstand Shift", 4, "4-5 each hand" if p > 0.5 else "8-10 shifts", 60,
               "Bodyweight", "Wall" if p <= 0.5 else "None", "Core", "Transverse Abdominis", ["Shoulders", "Obliques"],
               "advanced" if p > 0.5 else "intermediate",
               "Shift weight to one hand" if p <= 0.5 else "Tap shoulder without falling", "Plank Shoulder Tap"),
            ex("Pike Push-Up", 4, "6-10", 60, "Bodyweight", "Bench", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Build overhead pressing endurance", "Dumbbell Press"),
            ex("Wrist Warm-Up", 3, "30 seconds each position", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Essential for handstand practice", "Wrist Curls"),
            ex("Hollow Body Hold", 3, "30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Handstand body position on floor", "Dead Bug"),
            ex("Handstand Wall Walk", 3, "3-4 walks", 60, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Walk hands to wall and back", "Pike Hold"),
        ]})
        wk.append({"workout_name": "Day 2 - Shoulder Strength", "type": "strength", "duration_minutes": 35, "exercises": [
            ex("Dumbbell Shoulder Press", 4, "8-10", 75, "Moderate-Heavy", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Build overhead pressing base", "Barbell OHP"),
            ex("Lateral Raise", 3, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder stability", "Cable Lateral Raise"),
            ex("Dip", 4, "8-12", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Anterior Deltoid"], "intermediate", "Pressing strength", "Bench Dip"),
            ex("Face Pull", 3, "15-20", 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Shoulder health balance", "Band Pull-Apart"),
            ex("Plank", 3, "45-60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Anti-extension core work", "Dead Bug"),
        ]})
        if sess >= 3:
            wk.append({"workout_name": "Day 3 - Full Body Balance", "type": "hypertrophy", "duration_minutes": 35, "exercises": [
                ex("Pull-Up", 4, "6-10", 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Balance overhead pressing", "Lat Pulldown"),
                ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Horizontal pressing", "Knee Push-Up"),
                ex("Goblet Squat", 3, "10-12", 60, "Moderate", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Lower body base", "Bodyweight Squat"),
                ex("Superman Hold", 3, "15-20 seconds", 30, "Bodyweight", "None", "Back", "Erector Spinae", ["Glutes"], "beginner", "Back strength counterbalance", "Bird Dog"),
                ex("Single-Leg Balance", 3, "30 seconds each", 15, "Bodyweight", "None", "Legs", "Calves", ["Core", "Glute Medius"], "beginner", "Proprioception for handstand balance", "Single-Leg Stand"),
            ]})
        if sess >= 4:
            wk.append({"workout_name": "Day 4 - Handstand Endurance", "type": "calisthenics", "duration_minutes": 30, "exercises": [
                ex("Wall Handstand Accumulation", 5, "Total 3-5 minutes", 30, "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Break into short holds, accumulate time", "Pike Hold"),
                ex("Forearm Stand (Wall)" if p > 0.5 else "Crow Pose", 3, "15-20 seconds", 45, "Bodyweight", "Wall" if p > 0.5 else "None", "Shoulders", "Anterior Deltoid" if p > 0.5 else "Triceps", ["Core", "Traps"] if p > 0.5 else ["Core", "Shoulders"], "intermediate", "Build inversion time" if p > 0.5 else "Arm balance practice", "Headstand"),
                ex("Wrist Strengthening", 3, "10 each position", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Push-ups on backs of hands, finger push-ups", "Wrist Curls"),
                ex("Shoulder CARs", 3, "5 each direction", 15, "Bodyweight", "None", "Shoulders", "Rotator Cuff", ["Traps"], "beginner", "Full range controlled rotation", "Arm Circles"),
            ]})
        for extra in range(4, min(sess, 6)):
            wk.append({"workout_name": f"Day {extra+1} - Extra Handstand Practice", "type": "calisthenics", "duration_minutes": 20, "exercises": [
                ex("Freestanding Handstand Attempts" if p > 0.5 else "Wall Handstand Hold", 5, "5-10 seconds each" if p > 0.5 else "20-30 seconds", 45, "Bodyweight", "None" if p > 0.5 else "Wall", "Shoulders", "Anterior Deltoid", ["Core", "Traps"], "intermediate", "Practice finding balance", "Pike Hold"),
                ex("Pike Push-Up", 3, "6-8", 60, "Bodyweight", "Bench", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Pressing endurance", "Standard Pike Push-Up"),
                ex("Hollow Body Hold", 3, "30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Core tension for handstand", "Dead Bug"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sess]}
    return weeks


# Wrapper functions
def butterfly_kick(d, s): return flip_progression(d, s, "butterfly kick")
def kip_up(d, s): return flip_progression(d, s, "kip-up")
def cartwheel_aerial(d, s): return flip_progression(d, s, "aerial/no-hands cartwheel")


def main():
    helper = ProgramSQLHelper()
    mn = helper.get_next_migration_num()
    ok = fail = 0

    programs = [
        # Med priority
        ("Lunge to Pistol", "Progressions", "Single-leg path from lunges to pistol squats. Builds balance, ankle mobility, and single-leg strength progressively.", [2, 4, 8], [3, 4], False, "Low", lunge_to_pistol),
        ("Hollow Body Progression", "Progressions", "Master the gymnastics hollow body from tuck holds to full hollow rocks. Foundation for all advanced calisthenics.", [1, 2, 4], [5, 6], False, "Low", hollow_body_prog),
        ("Wall Walk to HSPU", "Progressions", "Handstand push-up progression from wall walks to full range HSPU. Builds overhead pressing strength and inversion comfort.", [2, 4, 8], [4, 5], False, "Low", wall_walk_hspu),
        ("Tuck to Full Planche", "Progressions", "Advanced planche progression from tuck holds through straddle to full planche. The ultimate calisthenics pushing skill.", [8, 12, 16], [4, 5], False, "Low", tuck_to_planche),
        # Handstands
        ("Handstand Mastery", "Progressions", "Freestanding handstand journey from wall holds to balance drills to unassisted holds. Includes shoulder strength and wrist conditioning.", [4, 8, 12, 16], [5, 6], False, "Low", lambda d, s: handstand_program(d, s, "mastery")),
        ("Handstand Walking", "Progressions", "Walk on your hands. Builds from wall handstand holds to weight shifting to multi-step handstand walking.", [4, 8, 12], [5, 6], False, "Low", lambda d, s: handstand_program(d, s, "walking")),
        # Flips
        ("Backflip Progression", "Progressions", "Safe backflip journey from conditioning through trampoline drills to standing backflip. Builds explosive power and air awareness.", [8, 12, 16], [3, 4], False, "Low", lambda d, s: flip_progression(d, s, "backflip")),
        ("Front Flip Progression", "Progressions", "Front tuck development from rolls through diving drills to standing front flip. Builds forward rotation control.", [8, 12, 16], [3, 4], False, "Low", lambda d, s: flip_progression(d, s, "front flip")),
        ("Side Flip Progression", "Progressions", "Aerial/side somersault progression. Builds from cartwheel to no-hands aerial with conditioning and flexibility.", [8, 12], [3, 4], False, "Low", lambda d, s: flip_progression(d, s, "side flip")),
        ("Cartwheel to Aerial", "Progressions", "Progress from basic cartwheel to no-hands aerial. Develops spatial awareness, leg power, and sideways rotation.", [4, 8, 12], [4, 5], False, "Low", cartwheel_aerial),
        ("Wall Flip Progression", "Progressions", "Wall-assisted backflip progression. Use the wall to build confidence and technique for wall flips.", [8, 12], [3, 4], False, "Low", lambda d, s: flip_progression(d, s, "wall backflip")),
        # Parkour
        ("Parkour Fundamentals", "Progressions", "Learn vaults, rolls, precision jumps, and wall skills. Build the foundation for parkour movement.", [4, 8, 12], [3, 4], False, "Low", lambda d, s: parkour_program(d, s, "fundamentals")),
        ("Parkour Flow", "Progressions", "Intermediate parkour: link movements together into flowing sequences. Kong vaults, wall runs, and cat leaps.", [8, 12, 16], [4, 5], False, "Low", lambda d, s: parkour_program(d, s, "flow")),
        ("Advanced Parkour Skills", "Progressions", "Advanced parkour: wall runs, laches, advanced vaults, and creative movement at speed.", [12, 16, 24], [4, 5], False, "Low", lambda d, s: parkour_program(d, s, "advanced")),
        # Tricking extras
        ("Butterfly Kick Progression", "Progressions", "Martial arts butterfly kick from basic to advanced. Builds hip flexibility, rotational power, and air awareness.", [4, 8, 12], [3, 4], False, "Low", butterfly_kick),
        ("Kip-up Mastery", "Progressions", "Ground to standing flip-up. Build explosive hip and core power for the kip-up from lying flat to standing.", [2, 4, 8], [4, 5], False, "Low", kip_up),
    ]

    for name, cat, desc, durs, sesss, ss, pri, gen_fn in programs:
        print(f"\n{'='*60}\nProcessing: {name}\n{'='*60}")
        if helper.check_program_exists(name):
            print(f"  SKIP: {name} already exists")
            continue
        weeks_data = {}
        for d in durs:
            for s in sesss:
                weeks_data[(d, s)] = gen_fn(d, s)
        result = helper.insert_full_program(name, cat, desc, durs, sesss, ss, pri, weeks_data, mn, True)
        if result:
            helper.update_tracker(name, "Done")
            ok += 1
        else:
            fail += 1
        mn += 1

    helper.close()
    print(f"\n{'='*60}\nProgressions remaining complete: {ok} OK, {fail} FAIL\n{'='*60}")


if __name__ == "__main__":
    main()
