#!/usr/bin/env python3
"""
Category 8: Challenges Programs (Medium & Low Priority)
========================================================
Low: L-Sit Progression (2,4,8w x 5-6/wk), Muscle-up Progression (4,8,12w x 4-5/wk),
     75-Day Discipline Challenge (11w x 7/wk), 75-Day Moderate Challenge (11w x 6/wk),
     75-Day Lifestyle Challenge (11w x 5/wk), Winter Arc Challenge (12,16w x 6/wk)
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


# ==== L-SIT PROGRESSION ====
def lsit_progression(duration, sessions):
    weeks = {}
    for w in range(1, duration + 1):
        p = w / duration
        if p <= 0.25: phase, hold = "Tuck Holds", "10-15 seconds"
        elif p <= 0.5: phase, hold = "Single Leg Extension", "10-20 seconds"
        elif p <= 0.75: phase, hold = "Straddle L-Sit", "10-15 seconds"
        else: phase, hold = "Full L-Sit", "15-30 seconds"
        wk = []
        # D1: L-Sit skill
        wk.append({"workout_name": "Day 1 - L-Sit Skill Work", "type": "calisthenics", "duration_minutes": 30, "exercises": [
            ex("Floor L-Sit Attempt" if p > 0.5 else "Tuck L-Sit Hold", 5, hold, 60,
               "Bodyweight", "Parallettes", "Core", "Rectus Abdominis",
               ["Hip Flexors", "Triceps"], "intermediate" if p > 0.5 else "beginner",
               "Push floor away, compress body, straight arms" if p > 0.5 else "Knees tucked to chest, push through parallettes",
               "Tuck L-Sit" if p > 0.5 else "Seated Knee Raise"),
            ex("Hanging Knee Raise", 4, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "beginner", "Controlled raise, no swinging", "Lying Knee Raise"),
            ex("Seated Leg Lift", 3, "10-12 each leg", 30, "Bodyweight", "Parallettes", "Core", "Hip Flexors", ["Quadriceps", "Rectus Abdominis"], "beginner", "Seated, hands on parallettes, lift one leg at a time", "Lying Leg Raise"),
            ex("Hollow Body Hold", 4, "20-30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Low back pressed to floor, arms by ears", "Dead Bug"),
            ex("Wrist Conditioning", 3, "30 seconds each position", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", ["Forearm Extensors"], "beginner", "Essential for L-sit support", "Wrist Curls"),
        ]})
        # D2: Core Compression
        wk.append({"workout_name": "Day 2 - Core Compression", "type": "core", "duration_minutes": 25, "exercises": [
            ex("V-Up", 4, "10-15", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Hands and feet meet at top", "Crunch"),
            ex("Pike Compression", 4, "10-12", 30, "Bodyweight", "None", "Core", "Hip Flexors", ["Rectus Abdominis"], "intermediate", "Seated, lift legs with straight knees", "Seated Leg Raise"),
            ex("Plank to Pike", 3, "8-10", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "intermediate", "Walk feet to hands, pike position", "Plank"),
            ex("Leg Raise Hold", 3, "15-20 seconds", 30, "Bodyweight", "None", "Core", "Lower Rectus Abdominis", ["Hip Flexors"], "intermediate", "Lying, hold legs at 6 inches off floor", "Dead Bug"),
            ex("Hollow Body Rock", 3, "15-20 reps", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Rock in hollow body position", "Hollow Body Hold"),
        ]})
        # D3: Pressing Strength
        wk.append({"workout_name": "Day 3 - Pressing Support", "type": "strength", "duration_minutes": 30, "exercises": [
            ex("Parallette Support Hold", 4, "20-30 seconds", 45, "Bodyweight", "Parallettes", "Shoulders", "Triceps", ["Anterior Deltoid", "Core"], "beginner", "Lock arms, slight lean forward, shoulders down", "Ring Support Hold"),
            ex("Dip", 4, "8-12", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Pressing strength supports L-sit", "Bench Dip"),
            ex("Pike Push-Up", 3, "8-10", 60, "Bodyweight", "None", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Hips high, head to floor", "Dumbbell Press"),
            ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range", "Knee Push-Up"),
            ex("Straight-Arm Press (Seated)", 4, "8-10", 45, "Bodyweight", "Floor", "Core", "Triceps", ["Rectus Abdominis", "Hip Flexors"], "intermediate", "Hands by hips, try to lift body off floor", "Support Hold"),
        ]})
        # D4: Flexibility
        wk.append({"workout_name": "Day 4 - Hamstring & Hip Flexibility", "type": "flexibility", "duration_minutes": 20, "exercises": [
            ex("Pike Stretch (Seated Forward Fold)", 3, "45-60 seconds", 15, "Bodyweight", "None", "Legs", "Hamstrings", ["Calves"], "beginner", "Reach for toes, straight back", "Standing Toe Touch"),
            ex("Pancake Stretch", 3, "45-60 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hamstrings"], "beginner", "Wide legs, lean forward", "Straddle Stretch"),
            ex("Standing Hamstring Stretch", 3, "30 seconds each leg", 15, "Bodyweight", "None", "Legs", "Hamstrings", [], "beginner", "Foot on elevated surface, hinge forward", "Seated Hamstring Stretch"),
            ex("Hip Flexor Stretch", 3, "30 seconds each side", 15, "Bodyweight", "None", "Legs", "Hip Flexors", ["Quadriceps"], "beginner", "Deep lunge position", "Kneeling Hip Flexor Stretch"),
            ex("Jefferson Curl", 3, "8-10", 30, "Light", "Dumbbell", "Back", "Erector Spinae", ["Hamstrings"], "intermediate", "Very slow segmental flexion, light weight", "Pike Stretch"),
        ]})
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - L-Sit Volume", "type": "calisthenics", "duration_minutes": 25, "exercises": [
                ex("L-Sit Hold Accumulation", 5, "Total 60-90 seconds", 30, "Bodyweight", "Parallettes", "Core", "Rectus Abdominis", ["Hip Flexors", "Triceps"], "intermediate", "Break into short holds, accumulate time", "Tuck L-Sit"),
                ex("Dragon Flag Negative", 3, "3-5", 60, "Bodyweight", "Bench", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Lower as one unit, very slow", "Lying Leg Raise"),
                ex("Ab Wheel Rollout", 3, "8-10", 45, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Full extension", "Plank"),
                ex("Pallof Press", 3, "10 each side", 30, "Light-Moderate", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Resist rotation", "Band Anti-Rotation"),
            ]})
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Active Recovery", "type": "flexibility", "duration_minutes": 15, "exercises": [
                ex("Cat-Cow", 3, "10 cycles", 15, "Bodyweight", "None", "Back", "Erector Spinae", ["Rectus Abdominis"], "beginner", "Slow, controlled", "Spinal Wave"),
                ex("Deep Squat Hold", 3, "30 seconds", 15, "Bodyweight", "None", "Legs", "Adductors", ["Hip Flexors"], "beginner", "Heels down", "Assisted Squat"),
                ex("Wrist Mobility", 3, "10 each direction", 15, "Bodyweight", "None", "Arms", "Forearm Flexors", [], "beginner", "Circles, rocks, stretches", "Wrist Curls"),
                ex("Shoulder CARs", 3, "5 each direction", 15, "Bodyweight", "None", "Shoulders", "Rotator Cuff", ["Traps"], "beginner", "Slow controlled circles", "Arm Circles"),
            ]})
        weeks[w] = {"focus": f"{phase} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== MUSCLE-UP PROGRESSION ====
def muscleup_progression(duration, sessions):
    weeks = {}
    for w in range(1, duration + 1):
        p = w / duration
        if p <= 0.25: phase = "High Pull-Up & Dip Strength"
        elif p <= 0.5: phase = "Explosive Pull & Transition"
        elif p <= 0.75: phase = "Banded Muscle-Up"
        else: phase = "Strict Muscle-Up"
        wk = []
        # D1: Pull Skill
        wk.append({"workout_name": "Day 1 - Explosive Pull", "type": "strength", "duration_minutes": 45, "exercises": [
            ex("High Pull-Up (Chest to Bar)", 5, "3-5", 120, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core", "Forearms"], "intermediate", "Pull explosively, aim for bar at chest level", "Standard Pull-Up"),
            ex("Kipping Pull-Up Drill" if p > 0.25 else "Strict Pull-Up", 4, "5-8" if p > 0.25 else "6-8", 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Controlled kip, build momentum" if p > 0.25 else "Full dead hang to chin over bar", "Band-Assisted Pull-Up"),
            ex("Eccentric Muscle-Up (Slow Negative)", 4, "2-3", 120, "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Triceps", "Core", "Chest"], "advanced", "Jump to top position, lower slowly through transition", "Eccentric Pull-Up"),
            ex("Straight Bar Dip", 4, "5-8", 90, "Bodyweight", "Pull-Up Bar", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "At top of bar, press up and back", "Ring Dip"),
            ex("False Grip Hang", 3, "15-20 seconds", 60, "Bodyweight", "Pull-Up Bar", "Arms", "Forearms", ["Wrist Flexors", "Biceps"], "intermediate", "Wrist over bar, builds transition grip", "Dead Hang"),
            ex("Lat Pulldown (Explosive)", 3, "8-10", 60, "Moderate-Heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "intermediate", "Pull fast and hard to chest", "Standard Lat Pulldown"),
        ]})
        # D2: Push Strength
        wk.append({"workout_name": "Day 2 - Push Strength", "type": "strength", "duration_minutes": 40, "exercises": [
            ex("Weighted Dip", 4, "6-8", 90, "Moderate-Heavy", "Dip Station", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Lean forward, deep stretch", "Bodyweight Dip"),
            ex("Close-Grip Bench Press", 4, "8-10", 90, "Moderate-Heavy", "Barbell", "Arms", "Triceps", ["Chest", "Anterior Deltoid"], "intermediate", "Shoulder-width, elbows tucked", "Close-Grip Push-Up"),
            ex("Pike Push-Up", 3, "8-10", 60, "Bodyweight", "None", "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Hips high, head to floor", "Dumbbell Press"),
            ex("Planche Lean", 3, "15-20 seconds", 45, "Bodyweight", "Floor", "Shoulders", "Anterior Deltoid", ["Core", "Chest"], "intermediate", "Lean forward in push-up position", "Plank"),
            ex("Hollow Body Hold", 3, "30 seconds", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Essential body tension for muscle-up", "Dead Bug"),
        ]})
        # D3: Full Muscle-Up Practice
        wk.append({"workout_name": "Day 3 - Muscle-Up Practice", "type": "calisthenics", "duration_minutes": 40, "exercises": [
            ex("Band-Assisted Muscle-Up" if p > 0.25 else "Muscle-Up Transition Drill", 5 if p > 0.5 else 4, "2-3" if p > 0.5 else "3-5 attempts", 120,
               "Bodyweight + Band" if p <= 0.75 else "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi",
               ["Triceps", "Core", "Chest"], "advanced" if p > 0.5 else "intermediate",
               "Full muscle-up with band assistance" if p > 0.25 else "Practice the transition from pull to push",
               "Explosive Pull-Up"),
            ex("Wide-Grip Pull-Up", 4, "5-8", 90, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Teres Major", "Biceps"], "intermediate", "Wide grip builds lat width for transition", "Standard Pull-Up"),
            ex("Russian Dip", 3, "5-6", 90, "Bodyweight", "Dip Station/Bar", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid", "Forearms"], "advanced", "Lower to forearms then press back up", "Standard Dip"),
            ex("Inverted Row", 3, "10-12", 60, "Bodyweight", "Barbell", "Back", "Rhomboids", ["Lats", "Biceps"], "beginner", "Pull chest to bar, straight body", "TRX Row"),
            ex("Korean Dip", 3, "5-8", 90, "Bodyweight", "Dip Station", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Bar behind body, dip down and press", "Bench Dip"),
        ]})
        # D4: Accessory
        if sessions >= 4:
            wk.append({"workout_name": "Day 4 - Accessory & Volume", "type": "hypertrophy", "duration_minutes": 35, "exercises": [
                ex("Barbell Curl", 3, "8-10", 60, "Moderate", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbow flexor strength for pull phase", "Dumbbell Curl"),
                ex("Skull Crusher", 3, "8-10", 60, "Moderate", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lockout strength for push phase", "Cable Pushdown"),
                ex("Face Pull", 3, "15-20", 45, "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Shoulder health for overhead work", "Band Pull-Apart"),
                ex("Hanging Leg Raise", 3, "10-12", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Core and grip practice", "Lying Leg Raise"),
                ex("Wrist Curl", 3, "12-15", 30, "Light", "Dumbbell", "Arms", "Forearm Flexors", [], "beginner", "Grip and wrist strength", "Towel Hang"),
            ]})
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Conditioning", "type": "circuit", "duration_minutes": 30, "exercises": [
                ex("Pull-Up Ladder (1 to 5)", 1, "1+2+3+4+5", 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Ascending ladder, rest between rungs", "Band Pull-Up Ladder"),
                ex("Dip Ladder (1 to 5)", 1, "1+2+3+4+5", 60, "Bodyweight", "Dip Station", "Chest", "Triceps", ["Chest"], "intermediate", "Match pull-up ladder", "Bench Dip Ladder"),
                ex("Burpee Pull-Up", 3, "5-6", 60, "Bodyweight", "Pull-Up Bar", "Full Body", "Latissimus Dorsi", ["Chest", "Quadriceps", "Core"], "intermediate", "Burpee under bar, jump to pull-up", "Burpee"),
                ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Pressing endurance", "Knee Push-Up"),
            ]})
        weeks[w] = {"focus": f"{phase} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== 75-DAY CHALLENGES (Discipline/Moderate/Lifestyle variants) ====
def seventy_five_day(duration, sessions, intensity="hard"):
    """75-Day style challenge: 2 workouts/day (hard), 1 workout + walk (moderate), 1 workout (lifestyle)."""
    weeks = {}
    for w in range(1, duration + 1):
        p = w / duration
        if p <= 0.25: phase = "Build Habits"
        elif p <= 0.5: phase = "Increase Intensity"
        elif p <= 0.75: phase = "Push Through"
        else: phase = "Final Push"
        ph2, s, mr, hr, wc = (phase, 3 if p <= 0.25 else 4, "10-12", "6-8" if p > 0.5 else "8-10", "Moderate-Heavy" if p > 0.5 else "Moderate")
        wk = []
        # Rotating daily workouts
        day_templates = [
            ("Upper Body Strength", "strength", 50, [
                ex("Barbell Bench Press", s, mr, 90, wc, "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Retract scapula, controlled reps", "Dumbbell Bench Press"),
                ex("Barbell Row", s, mr, 90, wc, "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to navel, squeeze back", "Cable Row"),
                ex("Dumbbell Shoulder Press", s, mr, 75, wc, "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Full lockout", "Barbell OHP"),
                ex("Pull-Up", 3, "8-10", 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full range", "Lat Pulldown"),
                ex("EZ Bar Curl", 3, mr, 45, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbows pinned", "Dumbbell Curl"),
                ex("Tricep Pushdown", 3, "12-15", 45, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full extension", "Bench Dip"),
            ]),
            ("Lower Body Power", "strength", 50, [
                ex("Barbell Back Squat", s, mr, 120, wc, "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Depth to parallel, chest up", "Leg Press"),
                ex("Romanian Deadlift", s, mr, 90, wc, "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips", "Dumbbell RDL"),
                ex("Walking Lunge", 3, "10 each leg", 60, "Moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Long stride", "Reverse Lunge"),
                ex("Leg Press", 3, "12-15", 75, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range", "Hack Squat"),
                ex("Calf Raise", 3, "15-20", 30, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full stretch", "Bodyweight Calf Raise"),
                ex("Plank", 3, "60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Flat back", "Dead Bug"),
            ]),
            ("Full Body HIIT", "circuit", 45, [
                ex("Kettlebell Swing", 4, "15-20", 30, "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
                ex("Dumbbell Thruster", 3, "12", 30, "Moderate", "Dumbbells", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat to press", "Barbell Thruster"),
                ex("Burpee", 3, "10-12", 30, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full range", "Squat Thrust"),
                ex("Mountain Climber", 3, "20 each side", 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Fast pace", "High Knees"),
                ex("Box Jump", 3, "8-10", 45, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing", "Squat Jump"),
                ex("Push-Up", 3, "15-20", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full range", "Knee Push-Up"),
            ]),
            ("Outdoor Cardio", "cardio", 45, [
                ex("Running (Intervals or Steady)", 1, "30-45 minutes", 0, "Moderate", "None", "Full Body", "Quadriceps", ["Hamstrings", "Calves", "Core"], "beginner", "Outdoor run, maintain conversation pace or intervals", "Treadmill"),
                ex("Walking Lunge (Outdoor)", 3, "20 each leg", 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes"], "beginner", "Long strides", "Reverse Lunge"),
                ex("Sprint Intervals", 4, "30 seconds", 60, "Max Effort", "None", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "All-out sprint, walk back", "Shuttle Run"),
                ex("Bodyweight Squat", 3, "20", 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Glutes"], "beginner", "Outdoor, full depth", "Wall Sit"),
                ex("Push-Up", 3, "15", 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Anywhere", "Knee Push-Up"),
            ]),
            ("Core & Abs", "core", 30, [
                ex("Hanging Leg Raise", 4, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "Controlled, no swinging", "Lying Leg Raise"),
                ex("Russian Twist", 3, "15 each side", 30, "Moderate", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet off ground", "Bicycle Crunch"),
                ex("Ab Wheel Rollout", 3, "10-12", 45, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Full extension", "Plank"),
                ex("Plank", 3, "60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Flat back", "Dead Bug"),
                ex("Bicycle Crunch", 3, "15 each side", 30, "Bodyweight", "None", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Slow and controlled", "Cross Crunch"),
            ]),
            ("Active Recovery", "flexibility", 35, [
                ex("Walking", 1, "30-45 minutes", 0, "Light", "None", "Full Body", "Calves", ["Quadriceps", "Core"], "beginner", "Brisk pace, outdoors preferred", "Treadmill Walk"),
                ex("Foam Roll Full Body", 1, "10 minutes", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Slow passes on each muscle", "Stretching"),
                ex("Yoga Sun Salutation", 3, "5 flows", 15, "Bodyweight", "None", "Full Body", "Hamstrings", ["Shoulders", "Core"], "beginner", "Downward dog, cobra, warrior", "Dynamic Stretch"),
                ex("Hip Opener Sequence", 3, "30 sec each position", 15, "Bodyweight", "None", "Legs", "Hip Flexors", ["Adductors", "Glutes"], "beginner", "90/90, pigeon, butterfly", "Hip Stretch"),
                ex("Deep Breathing", 3, "10 breaths", 15, "Bodyweight", "None", "Core", "Diaphragm", [], "beginner", "4 in, 6 out", "Box Breathing"),
            ]),
            ("Push/Pull Supersets", "hypertrophy", 50, [
                ex("Incline Dumbbell Press", s, mr, 75, wc, "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree incline", "Incline Barbell Press"),
                ex("Seated Cable Row", s, mr, 75, wc, "Cable Machine", "Back", "Rhomboids", ["Lats", "Biceps"], "beginner", "Squeeze shoulder blades", "Dumbbell Row"),
                ex("Lateral Raise", 3, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Shoulder height", "Cable Lateral Raise"),
                ex("Face Pull", 3, "15-20", 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Pull to forehead", "Band Pull-Apart"),
                ex("Dumbbell Curl", 3, mr, 45, "Moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Controlled", "Cable Curl"),
                ex("Rope Pushdown", 3, "12-15", 45, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Spread rope at bottom", "Bench Dip"),
            ]),
        ]
        for i in range(min(sessions, 7)):
            name, wtype, dur, exercises = day_templates[i % len(day_templates)]
            wk.append({"workout_name": f"Day {i+1} - {name}", "type": wtype, "duration_minutes": dur, "exercises": exercises})
        weeks[w] = {"focus": f"{phase} - Week {w}", "workouts": wk[:sessions]}
    return weeks


# ==== WINTER ARC CHALLENGE ====
def winter_arc(duration, sessions):
    """Seasonal transformation: progressive program over 12-16 weeks."""
    weeks = {}
    for w in range(1, duration + 1):
        p = w / duration
        if p <= 0.25: phase, s, mr, wc = "Ignition", 3, "10-12", "Moderate"
        elif p <= 0.5: phase, s, mr, wc = "Blaze", 4, "8-10", "Moderate-Heavy"
        elif p <= 0.75: phase, s, mr, wc = "Inferno", 4, "8-10", "Heavy"
        else: phase, s, mr, wc = "Emerge", 4, "6-8", "Heavy"
        hr = "6-8" if p > 0.5 else "8-10"
        wk = []
        wk.append({"workout_name": "Day 1 - Push Day", "type": "hypertrophy", "duration_minutes": 55, "exercises": [
            ex("Barbell Bench Press", s, hr, 120, wc, "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Controlled descent, explosive press", "Dumbbell Bench Press"),
            ex("Incline Dumbbell Press", s, mr, 75, "Moderate-Heavy", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30-degree incline", "Incline Barbell Press"),
            ex("Dumbbell Shoulder Press", s, mr, 75, wc, "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Full lockout", "Barbell OHP"),
            ex("Lateral Raise", 3, "12-15", 45, "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Controlled tempo", "Cable Lateral Raise"),
            ex("Cable Flye", 3, "12-15", 45, "Moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Squeeze at center", "Dumbbell Flye"),
            ex("Tricep Pushdown", 3, "12-15", 45, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full extension", "Bench Dip"),
        ]})
        wk.append({"workout_name": "Day 2 - Pull Day", "type": "hypertrophy", "duration_minutes": 55, "exercises": [
            ex("Deadlift", s, hr, 180, wc, "Barbell", "Back", "Erector Spinae", ["Glutes", "Hamstrings", "Traps"], "intermediate", "Flat back, push floor away", "Trap Bar Deadlift"),
            ex("Weighted Pull-Up", s, hr, 90, wc, "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full dead hang start", "Lat Pulldown"),
            ex("Seated Cable Row", s, mr, 75, wc, "Cable Machine", "Back", "Rhomboids", ["Lats", "Biceps"], "beginner", "Squeeze shoulder blades", "Dumbbell Row"),
            ex("Face Pull", 3, "15-20", 45, "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "External rotation at end", "Band Pull-Apart"),
            ex("EZ Bar Curl", 3, mr, 60, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "beginner", "Elbows pinned", "Dumbbell Curl"),
            ex("Hammer Curl", 3, "10-12", 45, "Moderate", "Dumbbells", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "Neutral grip", "Cable Curl"),
        ]})
        wk.append({"workout_name": "Day 3 - Legs", "type": "strength", "duration_minutes": 55, "exercises": [
            ex("Barbell Back Squat", s, hr, 150, wc, "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "intermediate", "Below parallel, chest up", "Leg Press"),
            ex("Romanian Deadlift", s, mr, 90, wc, "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Hinge at hips", "Dumbbell RDL"),
            ex("Leg Press", s, "10-12", 90, "Heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range", "Hack Squat"),
            ex("Walking Lunge", 3, "10 each leg", 60, "Moderate", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Long stride", "Reverse Lunge"),
            ex("Leg Curl", 3, "10-12", 60, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Slow eccentric", "Nordic Curl"),
            ex("Calf Raise", 4, "15-20", 30, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "beginner", "Full range", "Seated Calf Raise"),
        ]})
        wk.append({"workout_name": "Day 4 - HIIT Conditioning", "type": "circuit", "duration_minutes": 40, "exercises": [
            ex("Kettlebell Swing", 4, "15-20", 30, "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Dumbbell Swing"),
            ex("Battle Rope Slam", 3, "30 seconds", 30, "N/A", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Arms"], "intermediate", "Full power", "Medicine Ball Slam"),
            ex("Box Jump", 3, "8-10", 45, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Soft landing", "Squat Jump"),
            ex("Burpee", 3, "10-12", 30, "Bodyweight", "None", "Full Body", "Quadriceps", ["Chest", "Core"], "intermediate", "Full range", "Squat Thrust"),
            ex("Renegade Row", 3, "8 each side", 30, "Moderate", "Dumbbells", "Full Body", "Latissimus Dorsi", ["Core", "Chest"], "intermediate", "Minimize hip rotation", "Dumbbell Row"),
            ex("Plank", 3, "60 seconds", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Flat back", "Dead Bug"),
        ]})
        if sessions >= 5:
            wk.append({"workout_name": "Day 5 - Upper Body Volume", "type": "hypertrophy", "duration_minutes": 50, "exercises": [
                ex("Dumbbell Bench Press", s, mr, 75, wc, "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full range", "Barbell Bench Press"),
                ex("Lat Pulldown", s, mr, 75, "Moderate-Heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to upper chest", "Pull-Up"),
                ex("Arnold Press", 3, "10-12", 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Rotate palms during press", "Dumbbell Press"),
                ex("Cable Curl", 3, mr, 45, "Moderate", "Cable Machine", "Arms", "Biceps", ["Brachialis"], "beginner", "Constant tension", "Dumbbell Curl"),
                ex("Skull Crusher", 3, mr, 60, "Moderate", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead", "Cable Pushdown"),
                ex("Rear Delt Flye", 3, "12-15", 45, "Light", "Dumbbells", "Shoulders", "Rear Deltoid", ["Rhomboids"], "beginner", "Bent over, squeeze back", "Reverse Pec Deck"),
            ]})
        if sessions >= 6:
            wk.append({"workout_name": "Day 6 - Active Recovery & Core", "type": "core", "duration_minutes": 35, "exercises": [
                ex("Walking/Light Jog", 1, "20-30 minutes", 0, "Light", "None", "Full Body", "Calves", ["Quadriceps"], "beginner", "Easy pace, outdoors", "Treadmill Walk"),
                ex("Hanging Leg Raise", 3, "12-15", 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Controlled", "Lying Leg Raise"),
                ex("Russian Twist", 3, "15 each side", 30, "Moderate", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Feet off ground", "Bicycle Crunch"),
                ex("Dead Bug", 3, "10 each side", 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Low back pressed to floor", "Bird Dog"),
                ex("Foam Roll", 1, "5-10 minutes", 0, "N/A", "Foam Roller", "Full Body", "All Muscles", [], "beginner", "Focus on sore areas", "Stretching"),
            ]})
        weeks[w] = {"focus": f"{phase} - Week {w}", "workouts": wk[:sessions]}
    return weeks


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()
    ok = fail = 0

    programs = [
        ("L-Sit Progression", "Challenges", "Master the L-sit from floor tuck holds to full extended L-sit. Builds core compression, hip flexor strength, and pressing endurance.", [2, 4, 8], [5, 6], False, "Low", lsit_progression),
        ("Muscle-up Progression", "Challenges", "Progress from pull-ups to strict bar muscle-ups. Builds explosive pulling power, transition strength, and straight bar dip technique.", [4, 8, 12], [4, 5], False, "Low", muscleup_progression),
        ("75-Day Discipline Challenge", "Challenges", "The hard version: 2 workouts per day (1 outdoor), strict diet, read 10 pages, drink a gallon of water. No cheat days.", [11], [7], False, "Low", lambda d, s: seventy_five_day(d, s, "hard")),
        ("75-Day Moderate Challenge", "Challenges", "Moderate version: 1 workout plus 30-min outdoor walk, clean eating with 1 free meal/week, read or learn daily.", [11], [6], False, "Low", lambda d, s: seventy_five_day(d, s, "moderate")),
        ("75-Day Lifestyle Challenge", "Challenges", "Soft version: 1 workout per day, balanced nutrition, 20 min reading or podcast, adequate hydration. Sustainable habits.", [11], [5], False, "Low", lambda d, s: seventy_five_day(d, s, "lifestyle")),
        ("Winter Arc Challenge", "Challenges", "Seasonal transformation challenge. 4-phase progressive program: Ignition, Blaze, Inferno, Emerge. Emerge a new person by spring.", [12, 16], [6], True, "Low", winter_arc),
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
    print(f"\n{'='*60}\nChallenges remaining complete: {ok} OK, {fail} FAIL\n{'='*60}")


if __name__ == "__main__":
    main()
