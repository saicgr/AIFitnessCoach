#!/usr/bin/env python3
"""
Category 7: Celebrity-Style Programs (Medium & Low Priority)
=============================================================
Med: Fighter's Body (4,8,12w x 5-6/wk)
Low: Gladiator Training (8,12w x 5-6/wk), Spy Fitness (4,8w x 5-6/wk),
     Thunder God Build (8,12w x 6/wk), Shield Soldier Training (8,12w x 5-6/wk),
     Kryptonian Physique (8,12w x 5-6/wk), Dark Knight Protocol (8,12,14w x 6/wk),
     Aquatic Warrior (8,12w x 5-6/wk), Mutant Recovery (8,12w x 5-6/wk),
     Amazonian Strength (8,12w x 5-6/wk), Merc with a Mouth (8w x 5-6/wk)
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


def phase_params(progress):
    if progress <= 0.25:
        return "Foundation", 3, "10-12", "8-10", "Moderate"
    elif progress <= 0.5:
        return "Build", 4, "8-10", "6-8", "Moderate-Heavy"
    elif progress <= 0.75:
        return "Peak", 4, "8-10", "5-6", "Heavy"
    else:
        return "Intensification", 4, "6-8", "4-6", "Heavy"


# ==== Fighter's Body: MMA/Boxing conditioning + lean muscle ====
def fighters_body(duration, sessions):
    weeks = {}
    for w in range(1, duration + 1):
        ph, s, mr, hr, wc = phase_params(w / duration)
        wk = []
        # D1: Upper Body Strength
        wk.append({"workout_name": "Day 1 - Upper Body Power", "type": "strength", "duration_minutes": 55, "exercises": [
            ex("Barbell Bench Press", s, hr, 120, wc, "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Drive feet into floor, retract scapula", "Dumbbell Bench Press"),
            ex("Weighted Pull-Up", s, hr, 120, wc, "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full range, no kipping", "Lat Pulldown"),
            ex("Landmine Press", s, mr, 90, "Moderate-Heavy", "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Single arm, core braced, press at angle", "Dumbbell Shoulder Press"),
            ex("Dumbbell Row", s, mr, 75, wc, "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, squeeze back", "Cable Row"),
            ex("Dip", 3, "10-12", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Lean forward slightly for chest emphasis", "Close-Grip Push-Up"),
            ex("Face Pull", 3, "15-20", 45, "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Pull to forehead, externally rotate", "Band Pull-Apart"),
        ]})
        # D2: Lower Body Explosiveness
        wk.append({"workout_name": "Day 2 - Lower Body Explosive", "type": "strength", "duration_minutes": 55, "exercises": [
            ex("Trap Bar Deadlift", s, hr, 150, wc, "Trap Bar", "Legs", "Glutes", ["Hamstrings", "Quadriceps", "Core"], "intermediate", "Drive through floor, chest up", "Barbell Deadlift"),
            ex("Box Jump", 4, "5-6", 90, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive hip extension, soft landing", "Squat Jump"),
            ex("Bulgarian Split Squat", s, "8-10 each", 75, "Moderate-Heavy", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot on bench, deep stretch", "Reverse Lunge"),
            ex("Kettlebell Swing", 4, "15-20", 45, "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip hinge", "Dumbbell Swing"),
            ex("Hanging Leg Raise", 3, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "No swinging, controlled", "Lying Leg Raise"),
            ex("Calf Raise", 3, "15-20", 30, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full range, pause at top", "Bodyweight Calf Raise"),
        ]})
        # D3: Boxing/MMA Conditioning
        wk.append({"workout_name": "Day 3 - Combat Conditioning", "type": "circuit", "duration_minutes": 45, "exercises": [
            ex("Shadow Boxing (Rounds)", 5, "3 min rounds", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Arms", "Calves"], "intermediate", "Jab-cross-hook-uppercut combinations", "Jump Rope"),
            ex("Heavy Bag Work", 4, "3 min rounds", 30, "N/A", "Heavy Bag", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Mix power shots with combinations", "Medicine Ball Slam"),
            ex("Sprawl", 4, "10-12", 30, "Bodyweight", "None", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Hips to floor quickly, pop back up", "Burpee"),
            ex("Medicine Ball Rotational Throw", 3, "8 each side", 45, "Moderate", "Medicine Ball", "Core", "Obliques", ["Shoulders", "Hips"], "intermediate", "Rotate from hips, throw with power", "Cable Woodchop"),
            ex("Battle Rope", 3, "30 seconds", 30, "N/A", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Alternating waves, max intensity", "Mountain Climber"),
            ex("Plank Body Saw", 3, "12-15", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "intermediate", "Rock forward and back in plank", "Plank"),
        ]})
        # D4: Shoulders & Arms
        wk.append({"workout_name": "Day 4 - Shoulders & Arms", "type": "hypertrophy", "duration_minutes": 50, "exercises": [
            ex("Standing Dumbbell Press", s, mr, 90, wc, "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Press overhead, core braced", "Barbell OHP"),
            ex("Lateral Raise", s, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Controlled tempo, shoulder height", "Cable Lateral Raise"),
            ex("EZ Bar Curl", s, mr, 60, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbows pinned, no swing", "Dumbbell Curl"),
            ex("Skull Crusher", s, mr, 60, "Moderate", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead, elbows still", "Cable Pushdown"),
            ex("Hammer Curl", 3, "10-12", 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip", "Cable Rope Curl"),
            ex("Overhead Tricep Extension", 3, "12-15", 45, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full stretch at bottom", "Dumbbell Overhead Extension"),
        ]})
        # D5: Conditioning Circuit
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Metabolic Circuit", "type": "circuit", "duration_minutes": 40, "exercises": [
                ex("Dumbbell Thruster", 4, "12-15", 30, "Moderate", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps", "Core"], "intermediate", "Squat to press in one motion", "Barbell Thruster"),
                ex("Renegade Row", 4, "8 each side", 30, "Moderate", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Chest"], "intermediate", "Minimize hip rotation", "Single-Arm Row"),
                ex("Jump Lunge", 3, "10 each leg", 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Switch legs mid-air, land softly", "Reverse Lunge"),
                ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Chest to floor, full range", "Knee Push-Up"),
                ex("Burpee", 3, "10-12", 45, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Chest to floor, explosive jump", "Squat Thrust"),
                ex("Ab Wheel Rollout", 3, "10-12", 30, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Extend as far as controlled", "Plank"),
            ]})
        # D6: Active Recovery
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Active Recovery", "type": "flexibility", "duration_minutes": 35, "exercises": [
                ex("Jump Rope", 3, "3 min rounds", 30, "Bodyweight", "Jump Rope", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Light pace, stay loose", "High Knees"),
                ex("Foam Roll Full Body", 1, "10 min", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Slow passes on each muscle group", "Stretching"),
                ex("Yoga Flow (Sun Salutation)", 3, "5 flows", 15, "Bodyweight", "None", "Full Body", "Hamstrings", ["Shoulders", "Core", "Hip Flexors"], "beginner", "Downward dog, cobra, warrior sequence", "Dynamic Stretching"),
                ex("Hip 90/90 Stretch", 3, "30 sec each side", 15, "Bodyweight", "None", "Legs", "Hip Rotators", ["Glutes", "Adductors"], "beginner", "Switch between internal and external rotation", "Pigeon Stretch"),
                ex("Deep Breathing", 3, "10 breaths", 15, "Bodyweight", "None", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "4 count inhale, 6 count exhale", "Box Breathing"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== Gladiator Training: Ancient warrior style, heavy compound + conditioning ====
def gladiator_training(duration, sessions):
    weeks = {}
    for w in range(1, duration + 1):
        ph, s, mr, hr, wc = phase_params(w / duration)
        wk = []
        wk.append({"workout_name": "Day 1 - Gladiator Strength", "type": "strength", "duration_minutes": 60, "exercises": [
            ex("Barbell Back Squat", s, hr, 150, wc, "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Deep squat, chest up, drive through heels", "Leg Press"),
            ex("Barbell Overhead Press", s, hr, 120, wc, "Barbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Strict press, no leg drive", "Dumbbell Press"),
            ex("Weighted Chin-Up", s, hr, 120, wc, "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Forearms"], "intermediate", "Full range, supinated grip", "Lat Pulldown"),
            ex("Farmer's Walk", 4, "40 meters", 60, "Heavy", "Dumbbells", "Full Body", "Forearms", ["Traps", "Core"], "beginner", "Chest up, tight core, steady pace", "Trap Bar Carry"),
            ex("Barbell Row", s, mr, 90, wc, "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to navel", "Cable Row"),
            ex("Hanging Leg Raise", 3, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Controlled, no swinging", "Lying Leg Raise"),
        ]})
        wk.append({"workout_name": "Day 2 - Arena Conditioning", "type": "circuit", "duration_minutes": 45, "exercises": [
            ex("Sled Push", 4, "30 meters", 60, "Heavy", "Sled", "Full Body", "Quadriceps", ["Glutes", "Core", "Calves"], "intermediate", "Low position, drive through legs", "Prowler Push"),
            ex("Sandbag Carry", 3, "40 meters", 60, "Heavy", "Sandbag", "Full Body", "Core", ["Shoulders", "Back", "Legs"], "intermediate", "Bear hug carry, chest up", "Farmer's Walk"),
            ex("Battle Rope Slam", 4, "30 seconds", 30, "N/A", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Full body slam with power", "Medicine Ball Slam"),
            ex("Tire Flip", 3, "6-8", 90, "Heavy", "Tire", "Full Body", "Glutes", ["Quadriceps", "Back", "Shoulders"], "intermediate", "Deadlift to chest push, drive through", "Trap Bar Deadlift"),
            ex("Sledgehammer Swing", 3, "10 each side", 45, "Moderate", "Sledgehammer + Tire", "Core", "Obliques", ["Shoulders", "Forearms", "Lats"], "intermediate", "Full rotation, controlled strike", "Medicine Ball Slam"),
            ex("Bear Crawl", 3, "20 meters", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Knees low, controlled movement", "Mountain Climber"),
        ]})
        wk.append({"workout_name": "Day 3 - Chest & Back", "type": "hypertrophy", "duration_minutes": 55, "exercises": [
            ex("Barbell Bench Press", s, mr, 90, wc, "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Controlled descent, explosive press", "Dumbbell Bench Press"),
            ex("Weighted Pull-Up", s, mr, 90, wc, "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full dead hang to chin over bar", "Lat Pulldown"),
            ex("Incline Dumbbell Press", s, mr, 75, "Moderate-Heavy", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree angle, squeeze at top", "Incline Barbell Press"),
            ex("Cable Row", s, mr, 75, "Moderate-Heavy", "Cable Machine", "Back", "Rhomboids", ["Lats", "Biceps"], "beginner", "Squeeze shoulder blades together", "Dumbbell Row"),
            ex("Dumbbell Flye", 3, "12-15", 60, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Slight bend in elbows, wide arc", "Cable Flye"),
            ex("Straight-Arm Pulldown", 3, "12-15", 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Teres Major"], "beginner", "Arms straight throughout", "Dumbbell Pullover"),
        ]})
        wk.append({"workout_name": "Day 4 - Legs & Core", "type": "strength", "duration_minutes": 55, "exercises": [
            ex("Deadlift", s, hr, 180, wc, "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Traps"], "intermediate", "Hip hinge, flat back, push floor away", "Trap Bar Deadlift"),
            ex("Walking Lunge", s, "10 each leg", 75, "Moderate-Heavy", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long strides, upright torso", "Reverse Lunge"),
            ex("Romanian Deadlift", s, mr, 90, wc, "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips, bar close to legs", "Dumbbell RDL"),
            ex("Leg Press", 3, "12-15", 75, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range, don't lock knees", "Hack Squat"),
            ex("Ab Wheel Rollout", 3, "10-12", 45, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Full extension, brace core", "Plank"),
            ex("Pallof Press", 3, "10 each side", 30, "Light-Moderate", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Press out, resist rotation", "Band Anti-Rotation"),
        ]})
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Arms & Shoulders", "type": "hypertrophy", "duration_minutes": 50, "exercises": [
                ex("Dumbbell Shoulder Press", s, mr, 75, wc, "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Full lockout overhead", "Barbell OHP"),
                ex("Lateral Raise", s, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Raise to shoulder height, controlled", "Cable Lateral Raise"),
                ex("Barbell Curl", s, mr, 60, "Moderate", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbows pinned, no swinging", "Dumbbell Curl"),
                ex("Close-Grip Bench Press", s, mr, 75, "Moderate-Heavy", "Barbell", "Arms", "Triceps", ["Chest"], "intermediate", "Shoulder-width grip, elbows tucked", "Dip"),
                ex("Hammer Curl", 3, "10-12", 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip", "Cable Curl"),
                ex("Tricep Pushdown", 3, "12-15", 45, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full extension, squeeze at bottom", "Bench Dip"),
            ]})
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Gladiator Circuit", "type": "circuit", "duration_minutes": 40, "exercises": [
                ex("Kettlebell Clean & Press", 4, "8 each arm", 45, "Moderate-Heavy", "Kettlebell", "Full Body", "Shoulders", ["Core", "Glutes", "Arms"], "intermediate", "Clean to rack, press overhead", "Dumbbell Clean & Press"),
                ex("Box Jump", 4, "6-8", 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing, step down", "Squat Jump"),
                ex("Medicine Ball Slam", 3, "12-15", 30, "Moderate", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Lats"], "beginner", "Reach overhead, slam with force", "Slam Ball"),
                ex("Burpee", 3, "10-12", 45, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full range, chest to floor", "Squat Thrust"),
                ex("Plank Hold", 3, "60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Flat back, engage everything", "Dead Bug"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== Generic celebrity template with configurable flavor ====
def celebrity_generic(duration, sessions, style_config):
    """Generic template that adapts based on style_config dict."""
    weeks = {}
    d1 = style_config.get("day1", [])
    d2 = style_config.get("day2", [])
    d3 = style_config.get("day3", [])
    d4 = style_config.get("day4", [])
    d5 = style_config.get("day5", [])
    d6 = style_config.get("day6", [])
    for w in range(1, duration + 1):
        ph, s, mr, hr, wc = phase_params(w / duration)
        wk_list = []
        for i, (day_name, day_type, day_dur, exercises_fn) in enumerate([d1, d2, d3, d4, d5, d6]):
            if i >= sessions:
                break
            wk_list.append({
                "workout_name": day_name,
                "type": day_type,
                "duration_minutes": day_dur,
                "exercises": exercises_fn(s, mr, hr, wc),
            })
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk_list}
    return weeks


# Quick builder patterns for remaining programs
def spy_fitness(duration, sessions):
    """Agile + strong: bodyweight, speed, agility."""
    weeks = {}
    for w in range(1, duration + 1):
        ph, s, mr, hr, wc = phase_params(w / duration)
        wk = []
        wk.append({"workout_name": "Day 1 - Agility & Speed", "type": "circuit", "duration_minutes": 45, "exercises": [
            ex("Sprint Intervals (30m)", 6, "30 meters", 45, "Max Effort", "None", "Legs", "Quadriceps", ["Hamstrings", "Calves", "Core"], "intermediate", "All-out 30m sprint, walk back", "Shuttle Run"),
            ex("Lateral Shuffle", 4, "20 meters each way", 30, "Bodyweight", "None", "Legs", "Glute Medius", ["Quadriceps", "Calves"], "beginner", "Low stance, quick feet", "Lateral Lunge"),
            ex("Agility Ladder Drills", 4, "30 seconds", 30, "Bodyweight", "Agility Ladder", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Quick feet, various patterns", "High Knees"),
            ex("Broad Jump", 4, "5-6", 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Max distance, stick landing", "Squat Jump"),
            ex("Burpee", 3, "10-12", 45, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Fast transitions", "Squat Thrust"),
            ex("Bear Crawl", 3, "20 meters", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Stay low, controlled", "Mountain Climber"),
        ]})
        wk.append({"workout_name": "Day 2 - Upper Body Functional", "type": "strength", "duration_minutes": 50, "exercises": [
            ex("Pull-Up", s, "8-12", 75, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full range of motion", "Lat Pulldown"),
            ex("Push-Up Variations", s, "15-20", 45, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Mix standard, wide, diamond", "Knee Push-Up"),
            ex("Dumbbell Row", s, mr, 60, "Moderate-Heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip", "Cable Row"),
            ex("Pike Push-Up", 3, "8-10", 60, "Bodyweight", "None", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Hips high, head to floor", "Dumbbell Press"),
            ex("Renegade Row", 3, "8 each side", 45, "Moderate", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Chest"], "intermediate", "Minimize hip rotation", "Single-Arm Row"),
            ex("Plank Reach", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Shoulders", "Obliques"], "beginner", "Extend arm, keep hips level", "Plank"),
        ]})
        wk.append({"workout_name": "Day 3 - Lower Body Power", "type": "strength", "duration_minutes": 50, "exercises": [
            ex("Pistol Squat (Assisted)", s, "5-6 each leg", 75, "Bodyweight", "TRX", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Full depth single leg", "Bulgarian Split Squat"),
            ex("Single-Leg Deadlift", s, "8 each leg", 60, "Moderate", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Hinge forward, back leg extends", "Romanian Deadlift"),
            ex("Box Jump", 4, "6-8", 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive jump, soft landing", "Squat Jump"),
            ex("Goblet Squat", s, mr, 60, "Moderate-Heavy", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, elbows inside knees", "Bodyweight Squat"),
            ex("Lateral Bound", 3, "8 each side", 45, "Bodyweight", "None", "Legs", "Glute Medius", ["Quadriceps", "Calves"], "intermediate", "Stick the landing", "Lateral Lunge"),
            ex("Calf Raise", 3, "15-20", 30, "Bodyweight", "Step", "Legs", "Calves", ["Soleus"], "beginner", "Full range", "Seated Calf Raise"),
        ]})
        wk.append({"workout_name": "Day 4 - Combat & Core", "type": "circuit", "duration_minutes": 40, "exercises": [
            ex("Shadow Boxing", 4, "3 min rounds", 30, "Bodyweight", "None", "Full Body", "Shoulders", ["Core", "Arms"], "beginner", "Varied combinations", "Jump Rope"),
            ex("Medicine Ball Slam", 3, "12-15", 30, "Moderate", "Medicine Ball", "Full Body", "Core", ["Shoulders"], "beginner", "Full force each slam", "Slam Ball"),
            ex("Russian Twist", 3, "15 each side", 30, "Moderate", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet off ground", "Cable Woodchop"),
            ex("Mountain Climber", 3, "20 each side", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "beginner", "Fast knee drives", "High Knees"),
            ex("V-Up", 3, "12-15", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Arms and legs meet at top", "Crunch"),
            ex("Dead Bug", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Low back pressed to floor", "Bird Dog"),
        ]})
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Full Body HIIT", "type": "circuit", "duration_minutes": 35, "exercises": [
                ex("Kettlebell Swing", 4, "15-20", 30, "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
                ex("Push-Up to Renegade Row", 3, "8 each side", 45, "Moderate", "Dumbbells", "Full Body", "Chest", ["Lats", "Core"], "intermediate", "Minimize hip rotation", "Push-Up + Row"),
                ex("Squat Jump", 3, "10-12", 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Deep squat, full extension", "Bodyweight Squat"),
                ex("Dumbbell Thruster", 3, "12", 30, "Moderate", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat to press", "Barbell Thruster"),
                ex("Plank to Push-Up", 3, "10", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Alternate lead arm", "Plank"),
            ]})
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Mobility & Recovery", "type": "flexibility", "duration_minutes": 30, "exercises": [
                ex("Foam Roll", 1, "10 min", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Slow passes, focus on tight areas", "Stretching"),
                ex("Hip CARs", 3, "5 each direction each leg", 15, "Bodyweight", "None", "Legs", "Hip Rotators", ["Glutes"], "beginner", "Controlled articular rotation", "Hip Circles"),
                ex("Thoracic Rotation", 3, "8 each side", 15, "Bodyweight", "None", "Back", "Thoracic Spine", ["Obliques"], "beginner", "Open up through mid back", "Cat-Cow"),
                ex("Deep Squat Hold", 3, "45 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hip Flexors"], "beginner", "Heels down, chest up", "Assisted Squat"),
                ex("Pigeon Stretch", 3, "30 sec each side", 15, "Bodyweight", "None", "Legs", "Glutes", ["Hip Flexors"], "beginner", "Sink into stretch", "Figure-4 Stretch"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== Simple template for similar programs ====
def heavy_compound_split(duration, sessions, program_flavor="general"):
    """Heavy compound focus with configurable flavor for thunder god, kryptonian, etc."""
    weeks = {}
    for w in range(1, duration + 1):
        ph, s, mr, hr, wc = phase_params(w / duration)
        wk = []
        # D1: Chest & Back
        wk.append({"workout_name": "Day 1 - Chest & Back", "type": "hypertrophy", "duration_minutes": 60, "exercises": [
            ex("Barbell Bench Press", s+1, hr, 150, wc, "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, leg drive", "Dumbbell Bench Press"),
            ex("Weighted Pull-Up", s, hr, 120, wc, "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full dead hang start", "Lat Pulldown"),
            ex("Incline Dumbbell Press", s, mr, 90, "Moderate-Heavy", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree incline", "Incline Barbell Press"),
            ex("Barbell Row", s, mr, 90, wc, "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest", "Cable Row"),
            ex("Cable Flye", 3, "12-15", 60, "Moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Squeeze at center", "Dumbbell Flye"),
            ex("Face Pull", 3, "15-20", 45, "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Pull to forehead", "Band Pull-Apart"),
        ]})
        # D2: Legs (Quad Dominant)
        wk.append({"workout_name": "Day 2 - Legs (Quad Focus)", "type": "strength", "duration_minutes": 60, "exercises": [
            ex("Barbell Back Squat", s+1, hr, 180, wc, "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Depth to parallel or below", "Leg Press"),
            ex("Walking Lunge", s, "10 each leg", 75, "Moderate-Heavy", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Reverse Lunge"),
            ex("Leg Press", s, "10-12", 90, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range, don't lock knees", "Hack Squat"),
            ex("Leg Extension", 3, "12-15", 60, "Moderate", "Machine", "Legs", "Quadriceps", [], "beginner", "Pause at top", "Sissy Squat"),
            ex("Standing Calf Raise", 4, "15-20", 45, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full stretch and squeeze", "Seated Calf Raise"),
            ex("Hanging Leg Raise", 3, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Controlled, no swinging", "Lying Leg Raise"),
        ]})
        # D3: Shoulders & Arms
        wk.append({"workout_name": "Day 3 - Shoulders & Arms", "type": "hypertrophy", "duration_minutes": 55, "exercises": [
            ex("Barbell Overhead Press", s, hr, 120, wc, "Barbell", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps", "Core"], "intermediate", "Strict press, brace core", "Dumbbell Press"),
            ex("Lateral Raise", s, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Controlled tempo", "Cable Lateral Raise"),
            ex("EZ Bar Curl", s, mr, 60, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbows pinned", "Dumbbell Curl"),
            ex("Skull Crusher", s, mr, 60, "Moderate", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead", "Cable Pushdown"),
            ex("Hammer Curl", 3, "10-12", 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps"], "beginner", "Neutral grip", "Cable Curl"),
            ex("Overhead Tricep Extension", 3, "12-15", 45, "Moderate", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner", "Full stretch at bottom", "Cable Extension"),
        ]})
        # D4: Back & Hamstrings
        wk.append({"workout_name": "Day 4 - Back & Hamstrings", "type": "strength", "duration_minutes": 60, "exercises": [
            ex("Deadlift", s+1, hr, 180, wc, "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Traps"], "intermediate", "Flat back, push floor away", "Trap Bar Deadlift"),
            ex("Single-Arm Dumbbell Row", s, mr, 75, "Heavy", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, full stretch", "Cable Row"),
            ex("Romanian Deadlift", s, mr, 90, wc, "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Bar close to legs, hinge at hips", "Dumbbell RDL"),
            ex("Lat Pulldown", s, mr, 75, "Moderate-Heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "beginner", "Pull to upper chest", "Pull-Up"),
            ex("Leg Curl", 3, "10-12", 60, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Control the eccentric", "Nordic Curl"),
            ex("Good Morning", 3, "10-12", 75, "Moderate", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Slight knee bend, hinge at hips", "Romanian Deadlift"),
        ]})
        # D5: Functional Circuit
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Functional Circuit", "type": "circuit", "duration_minutes": 45, "exercises": [
                ex("Kettlebell Swing", 4, "15-20", 30, "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
                ex("Box Jump", 4, "6-8", 60, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing", "Squat Jump"),
                ex("Dumbbell Thruster", 3, "12", 30, "Moderate", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat to press", "Barbell Thruster"),
                ex("Battle Rope Slam", 3, "30 seconds", 30, "N/A", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Full power", "Medicine Ball Slam"),
                ex("Renegade Row", 3, "8 each side", 45, "Moderate", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Chest"], "intermediate", "Minimize hip rotation", "Dumbbell Row"),
                ex("Plank", 3, "60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Flat back, tight everything", "Dead Bug"),
            ]})
        # D6: Accessories
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Accessories & Conditioning", "type": "hypertrophy", "duration_minutes": 45, "exercises": [
                ex("Incline Dumbbell Curl", 3, "10-12", 60, "Moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Full stretch at bottom", "Preacher Curl"),
                ex("Tricep Dip", 3, "10-15", 60, "Bodyweight", "Dip Station", "Arms", "Triceps", ["Chest"], "intermediate", "Upright torso", "Close-Grip Push-Up"),
                ex("Arnold Press", 3, "10-12", 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Rotate palms during press", "Dumbbell Press"),
                ex("Cable Crunch", 3, "15-20", 30, "Moderate", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Crunch down, exhale", "Weighted Sit-Up"),
                ex("Farmer's Walk", 3, "40 meters", 60, "Heavy", "Dumbbells", "Full Body", "Forearms", ["Traps", "Core"], "beginner", "Chest up, tight core", "Dead Hang"),
                ex("Assault Bike", 3, "30 seconds", 60, "Max Effort", "Assault Bike", "Full Body", "Quadriceps", ["Core", "Arms"], "intermediate", "All-out sprint", "Rowing Sprint"),
            ]})
        weeks[w] = {"focus": f"{ph} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# Wrapper functions for each remaining program
def thunder_god_build(d, s): return heavy_compound_split(d, s, "thunder")
def shield_soldier(d, s): return heavy_compound_split(d, s, "shield")
def kryptonian_physique(d, s): return heavy_compound_split(d, s, "kryptonian")
def dark_knight(d, s): return heavy_compound_split(d, s, "dark_knight")
def aquatic_warrior(d, s): return heavy_compound_split(d, s, "aquatic")
def mutant_recovery(d, s): return heavy_compound_split(d, s, "mutant")
def amazonian_strength(d, s): return heavy_compound_split(d, s, "amazonian")
def merc_with_mouth(d, s): return heavy_compound_split(d, s, "merc")


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()
    ok = 0
    fail = 0

    programs = [
        ("Fighter's Body", "Celebrity-Style", "Athletic and conditioned physique combining MMA-style training with bodybuilding. Boxing rounds, explosive lifting, and metabolic conditioning.", [4, 8, 12], [5, 6], True, "Med", fighters_body),
        ("Gladiator Training", "Celebrity-Style", "Ancient warrior-inspired training with heavy compounds, strongman implements, and brutal conditioning circuits.", [8, 12], [5, 6], True, "Low", gladiator_training),
        ("Spy Fitness", "Celebrity-Style", "Agile and strong: bodyweight mastery, speed, agility drills, and functional combat conditioning for peak versatility.", [4, 8], [5, 6], False, "Low", spy_fitness),
        ("Thunder God Build", "Celebrity-Style", "Heavy compound lifting with high volume for maximum size. Push/pull/legs split emphasizing overhead pressing and deadlifts.", [8, 12], [6], True, "Low", thunder_god_build),
        ("Shield Soldier Training", "Celebrity-Style", "Functional strength and calisthenics blend. Heavy compounds paired with bodyweight movements and conditioning.", [8, 12], [5, 6], False, "Low", shield_soldier),
        ("Kryptonian Physique", "Celebrity-Style", "Power and conditioning program balancing heavy lifting with athletic performance work.", [8, 12], [5, 6], True, "Low", kryptonian_physique),
        ("Dark Knight Protocol", "Celebrity-Style", "3-phase training: bulk, lean, define. Heavy strength base transitioning to metabolic conditioning.", [8, 12, 14], [6], True, "Low", dark_knight),
        ("Aquatic Warrior", "Celebrity-Style", "Functional mass with conditioning emphasis. Build a powerful, athletic physique that can perform.", [8, 12], [5, 6], True, "Low", aquatic_warrior),
        ("Mutant Recovery", "Celebrity-Style", "High volume training with emphasis on recovery and progressive overload. Push the limits of muscle growth.", [8, 12], [5, 6], True, "Low", mutant_recovery),
        ("Amazonian Strength", "Celebrity-Style", "Women's functional power program combining strength training with athletic conditioning and flexibility.", [8, 12], [5, 6], True, "Low", amazonian_strength),
        ("Merc with a Mouth", "Celebrity-Style", "High intensity circuits with zero rest. Non-stop movement combining strength and cardio for maximum fat burn.", [8], [5, 6], True, "Low", merc_with_mouth),
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
        result = helper.insert_full_program(name, cat, desc, durs, sesss, ss, pri, weeks_data, migration_num, True)
        if result:
            helper.update_tracker(name, "Done")
            ok += 1
        else:
            fail += 1
        migration_num += 1

    helper.close()
    print(f"\n{'='*60}\nCelebrity Med/Low complete: {ok} OK, {fail} FAIL\n{'='*60}")


if __name__ == "__main__":
    main()
