from exercise_lib import *

BATCH_WORKOUTS = {

# ===== STRENGTH / BARBELL / POWERLIFTING =====

"Barbell LP": [
    workout("Day A: Squat/Bench/Row", "strength", 60, [
        BARBELL_SQUAT(s=3, r=5, rest=180, g="Add 5lb each session"),
        BARBELL_BENCH(s=3, r=5, rest=180, g="Add 5lb each session"),
        BARBELL_ROW(s=3, r=5, rest=180, g="Add 5lb each session"),
    ]),
    workout("Day B: Squat/OHP/Deadlift", "strength", 60, [
        BARBELL_SQUAT(s=3, r=5, rest=180, g="Add 5lb each session"),
        BARBELL_OHP(s=3, r=5, rest=180, g="Add 5lb each session"),
        DEADLIFT(s=1, r=5, rest=180, g="Add 10lb each session"),
    ]),
],

"Barbell Mastery": [
    workout("Push Day", "strength", 70, [
        BARBELL_BENCH(s=5, r=5, rest=180),
        BARBELL_OHP(s=4, r=6, rest=120),
        ex("Close-Grip Bench Press", 3, 8, 90, "70% of bench", "Barbell", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands shoulder-width, elbows tucked", "Alternative"),
        ex("Dip", 3, 10, 60, "Weighted if possible", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Lean forward for chest emphasis", "Bodyweight alternative"),
    ]),
    workout("Pull Day", "strength", 70, [
        DEADLIFT(s=5, r=3, rest=180),
        BARBELL_ROW(s=4, r=6, rest=120),
        PULLUP(s=3, r=8, rest=90),
        BARBELL_CURL(s=3, r=10, rest=60),
    ]),
    workout("Leg Day", "strength", 70, [
        BARBELL_SQUAT(s=5, r=5, rest=180),
        FRONT_SQUAT(s=3, r=6, rest=120),
        RDL(s=3, r=8, rest=90),
        ex("Calf Raise", 4, 15, 60, "Heavy", "Machine", "Legs", "Calves", ["Tibialis Anterior"], "beginner", "Full ROM, pause at top", "Alternative"),
    ]),
],

"Barbell Only": [
    workout("Full Body A", "strength", 60, [
        BARBELL_SQUAT(s=4, r=6, rest=150),
        BARBELL_BENCH(s=4, r=6, rest=150),
        BARBELL_ROW(s=4, r=6, rest=120),
        BARBELL_CURL(s=3, r=10, rest=60),
    ]),
    workout("Full Body B", "strength", 60, [
        DEADLIFT(s=3, r=5, rest=180),
        BARBELL_OHP(s=4, r=6, rest=150),
        FRONT_SQUAT(s=3, r=8, rest=120),
        ex("Barbell Skull Crusher", 3, 10, 60, "EZ bar or straight bar", "Barbell", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead, elbows stationary", "Alternative"),
    ]),
],

"Bench Press Builder": [
    workout("Heavy Bench Day", "strength", 70, [
        BARBELL_BENCH(s=5, r=3, rest=180, g="Work up to heavy triple"),
        ex("Paused Bench Press", 3, 5, 150, "80% of max, 2-sec pause", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Full pause on chest, drive explosively", "Alternative"),
        ex("Close-Grip Bench Press", 4, 8, 90, "70% of bench", "Barbell", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Shoulder-width grip", "Bodyweight alternative"),
        ex("Dumbbell Fly", 3, 12, 60, "Moderate weight", "Dumbbell", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Slight bend in elbows, full stretch", "Alternative"),
    ]),
    workout("Volume Bench Day", "strength", 70, [
        BARBELL_BENCH(s=4, r=8, rest=120, g="65-70% of max"),
        ex("Incline Barbell Press", 4, 8, 90, "30-degree angle", "Barbell", "Chest", "Upper Pectoralis", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch upper chest", "Bodyweight alternative"),
        BARBELL_OHP(s=3, r=8, rest=90),
        TRICEP_PUSHDOWN(s=3, r=15, rest=45),
    ]),
],

"Deadlift Specialization": [
    workout("Heavy Deadlift Day", "strength", 75, [
        DEADLIFT(s=5, r=3, rest=180, g="Work up to heavy triple"),
        ex("Deficit Deadlift", 3, 5, 150, "Standing on 2-inch platform", "Barbell", "Full Body", "Posterior Chain", ["Glutes", "Hamstrings"], "advanced", "Same form, increased ROM", "Alternative"),
        BARBELL_ROW(s=4, r=6, rest=120),
        ex("Barbell Shrug", 3, 12, 60, "Heavy", "Barbell", "Back", "Trapezius", ["Rhomboids"], "beginner", "Hold at top 2 seconds", "Bodyweight alternative"),
    ]),
    workout("Volume Deadlift Day", "strength", 75, [
        RDL(s=4, r=8, rest=120),
        ex("Rack Pull", 3, 5, 150, "From knee height", "Barbell", "Back", "Posterior Chain", ["Traps", "Glutes", "Erectors"], "intermediate", "Focus on lockout", "Bodyweight alternative"),
        LEG_CURL(s=3, r=12, rest=60),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Squat Specialization": [
    workout("Heavy Squat Day", "strength", 75, [
        BARBELL_SQUAT(s=5, r=3, rest=180, g="Work up to heavy triple"),
        ex("Pause Squat", 3, 5, 150, "75% of max, 3-sec pause in hole", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Maintain tightness at bottom", "Alternative"),
        LEG_PRESS(s=3, r=10, rest=90),
        ex("Walking Lunge", 3, 12, 60, "Per leg, barbell or dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Alternative"),
    ]),
    workout("Volume Squat Day", "strength", 75, [
        BARBELL_SQUAT(s=4, r=8, rest=120, g="65-70% of max"),
        FRONT_SQUAT(s=3, r=6, rest=120),
        BULGARIAN_SPLIT_SQUAT(s=3, r=10, rest=60),
        LEG_EXT(s=3, r=15, rest=45),
    ]),
],

"Arm Specialization": [
    workout("Arm Day A: Bicep Focus", "strength", 60, [
        BARBELL_CURL(s=4, r=8, rest=90),
        ex("Incline Dumbbell Curl", 3, 10, 60, "30-degree incline", "Dumbbell", "Arms", "Biceps", ["Brachialis"], "intermediate", "Full stretch at bottom", "Bodyweight alternative"),
        ex("Hammer Curl", 3, 12, 60, "Neutral grip", "Dumbbell", "Arms", "Brachialis", ["Biceps", "Forearms"], "beginner", "No swinging", "Bodyweight alternative"),
        TRICEP_PUSHDOWN(s=4, r=12, rest=60),
        ex("Overhead Tricep Extension", 3, 12, 60, "Dumbbell or cable", "Dumbbell", "Arms", "Triceps", ["Long Head"], "beginner", "Full stretch overhead", "Bodyweight alternative"),
    ]),
    workout("Arm Day B: Tricep Focus", "strength", 60, [
        ex("Close-Grip Bench Press", 4, 8, 90, "Shoulder-width grip", "Barbell", "Arms", "Triceps", ["Pectoralis Major"], "intermediate", "Elbows close to body", "Bodyweight alternative"),
        ex("Skull Crusher", 3, 10, 60, "EZ bar", "Barbell", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead", "Bodyweight alternative"),
        TRICEP_PUSHDOWN(s=3, r=15, rest=45),
        ex("Preacher Curl", 3, 10, 60, "EZ bar or dumbbell", "Barbell", "Arms", "Biceps", ["Brachialis"], "beginner", "No swinging, full ROM", "Alternative"),
        ex("Reverse Curl", 3, 12, 45, "EZ bar, overhand grip", "Barbell", "Arms", "Brachioradialis", ["Forearms", "Biceps"], "beginner", "Controlled tempo", "Alternative"),
    ]),
],

"Powerbuilding": [
    workout("Upper Power", "strength", 75, [
        BARBELL_BENCH(s=5, r=3, rest=180),
        BARBELL_ROW(s=5, r=3, rest=180),
        BARBELL_OHP(s=3, r=8, rest=90),
        DB_ROW(s=3, r=10, rest=60),
        DB_LATERAL_RAISE(s=3, r=15, rest=45),
    ]),
    workout("Lower Power", "strength", 75, [
        BARBELL_SQUAT(s=5, r=3, rest=180),
        DEADLIFT(s=3, r=3, rest=180),
        LEG_PRESS(s=3, r=10, rest=90),
        LEG_CURL(s=3, r=12, rest=60),
        ex("Calf Raise", 4, 15, 60, "Standing", "Machine", "Legs", "Calves", [], "beginner", "Full ROM", "Bodyweight alternative"),
    ]),
    workout("Upper Hypertrophy", "hypertrophy", 70, [
        ex("Incline Dumbbell Press", 4, 10, 60, "Moderate weight", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "30-degree angle, full ROM", "Alternative"),
        LAT_PULLDOWN(s=4, r=10, rest=60),
        DB_LATERAL_RAISE(s=4, r=15, rest=45),
        BARBELL_CURL(s=3, r=12, rest=45),
        TRICEP_PUSHDOWN(s=3, r=15, rest=45),
    ]),
    workout("Lower Hypertrophy", "hypertrophy", 70, [
        FRONT_SQUAT(s=4, r=8, rest=120),
        RDL(s=4, r=10, rest=90),
        BULGARIAN_SPLIT_SQUAT(s=3, r=12, rest=60),
        LEG_EXT(s=3, r=15, rest=45),
        LEG_CURL(s=3, r=15, rest=45),
    ]),
],

"Powerlifting Meet Prep": [
    workout("Squat Day", "strength", 90, [
        BARBELL_SQUAT(s=5, r=3, rest=240, g="Competition squat, work to heavy single"),
        ex("Pause Squat", 3, 3, 180, "80% of max", "Barbell", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "3-second pause at bottom", "Bodyweight alternative"),
        LEG_PRESS(s=3, r=8, rest=90),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
    workout("Bench Day", "strength", 90, [
        BARBELL_BENCH(s=5, r=3, rest=240, g="Competition bench, work to heavy single"),
        ex("Paused Bench Press", 3, 3, 180, "80% of max", "Barbell", "Chest", "Pectoralis Major", ["Triceps"], "advanced", "Full pause on chest", "Bodyweight alternative"),
        ex("Close-Grip Bench Press", 3, 6, 120, "75% of bench", "Barbell", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Elbows tucked", "Bodyweight alternative"),
        FACE_PULL(s=3, r=15, rest=45),
    ]),
    workout("Deadlift Day", "strength", 90, [
        DEADLIFT(s=5, r=3, rest=240, g="Competition deadlift, work to heavy single"),
        ex("Block Pull", 3, 3, 180, "From mid-shin", "Barbell", "Back", "Posterior Chain", ["Glutes", "Hamstrings"], "advanced", "Focus on lockout", "Bodyweight alternative"),
        BARBELL_ROW(s=3, r=8, rest=90),
        ex("Barbell Shrug", 3, 12, 60, "Heavy", "Barbell", "Back", "Trapezius", [], "beginner", "Hold at top", "Bodyweight alternative"),
    ]),
],

"6-Week Peaking Program": [
    workout("Heavy Squat + Bench", "strength", 90, [
        BARBELL_SQUAT(s=5, r=2, rest=240, g="85-95% 1RM, peaking phase"),
        BARBELL_BENCH(s=5, r=2, rest=240, g="85-95% 1RM"),
        ex("Good Morning", 3, 6, 90, "Moderate weight", "Barbell", "Legs", "Hamstrings", ["Erectors", "Glutes"], "intermediate", "Hip hinge, bar on back", "Alternative"),
        FACE_PULL(s=3, r=15, rest=45),
    ]),
    workout("Heavy Deadlift + OHP", "strength", 90, [
        DEADLIFT(s=5, r=2, rest=240, g="85-95% 1RM, peaking phase"),
        BARBELL_OHP(s=4, r=3, rest=180, g="85-90% 1RM"),
        PULLUP(s=3, r=6, rest=90),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Mass Builder": [
    workout("Chest & Back", "hypertrophy", 75, [
        BARBELL_BENCH(s=4, r=8, rest=120),
        BARBELL_ROW(s=4, r=8, rest=120),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate-heavy", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Full ROM", "Bodyweight alternative"),
        LAT_PULLDOWN(s=3, r=10, rest=60),
        CABLE_FLY(s=3, r=12, rest=45),
    ]),
    workout("Legs", "hypertrophy", 75, [
        BARBELL_SQUAT(s=4, r=8, rest=150),
        RDL(s=4, r=10, rest=90),
        LEG_PRESS(s=3, r=12, rest=90),
        LEG_CURL(s=3, r=12, rest=60),
        LEG_EXT(s=3, r=15, rest=45),
    ]),
    workout("Shoulders & Arms", "hypertrophy", 65, [
        BARBELL_OHP(s=4, r=8, rest=120),
        DB_LATERAL_RAISE(s=4, r=15, rest=45),
        BARBELL_CURL(s=3, r=10, rest=60),
        TRICEP_PUSHDOWN(s=3, r=12, rest=60),
        FACE_PULL(s=3, r=15, rest=45),
    ]),
],

"Lean Bulk": [
    workout("Upper A: Push Focus", "hypertrophy", 70, [
        BARBELL_BENCH(s=4, r=6, rest=150),
        BARBELL_OHP(s=3, r=8, rest=90),
        ex("Incline Dumbbell Press", 3, 10, 60, "Moderate", "Dumbbell", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "Full stretch", "Bodyweight alternative"),
        DB_LATERAL_RAISE(s=3, r=15, rest=45),
        TRICEP_PUSHDOWN(s=3, r=12, rest=45),
    ]),
    workout("Lower A", "hypertrophy", 70, [
        BARBELL_SQUAT(s=4, r=6, rest=150),
        RDL(s=3, r=8, rest=90),
        BULGARIAN_SPLIT_SQUAT(s=3, r=10, rest=60),
        LEG_CURL(s=3, r=12, rest=60),
    ]),
    workout("Upper B: Pull Focus", "hypertrophy", 70, [
        BARBELL_ROW(s=4, r=6, rest=150),
        PULLUP(s=3, r=8, rest=90),
        DB_ROW(s=3, r=10, rest=60),
        FACE_PULL(s=3, r=15, rest=45),
        BARBELL_CURL(s=3, r=10, rest=60),
    ]),
    workout("Lower B", "hypertrophy", 70, [
        DEADLIFT(s=3, r=5, rest=180),
        FRONT_SQUAT(s=3, r=8, rest=120),
        LEG_PRESS(s=3, r=12, rest=90),
        ex("Calf Raise", 4, 15, 60, "Standing", "Machine", "Legs", "Calves", [], "beginner", "Full ROM", "Bodyweight alternative"),
    ]),
],

"Volume/Intensity Cycling": [
    workout("Volume Phase: Full Body A", "hypertrophy", 70, [
        BARBELL_SQUAT(s=4, r=10, rest=90, g="60% 1RM, volume accumulation"),
        BARBELL_BENCH(s=4, r=10, rest=90, g="60% 1RM"),
        BARBELL_ROW(s=4, r=10, rest=90),
        DB_LATERAL_RAISE(s=3, r=15, rest=45),
    ]),
    workout("Volume Phase: Full Body B", "hypertrophy", 70, [
        DEADLIFT(s=3, r=8, rest=120, g="65% 1RM"),
        BARBELL_OHP(s=4, r=10, rest=90),
        PULLUP(s=3, r=10, rest=60),
        BARBELL_CURL(s=3, r=12, rest=45),
    ]),
    workout("Intensity Phase: Full Body A", "strength", 70, [
        BARBELL_SQUAT(s=5, r=3, rest=180, g="85% 1RM, intensity block"),
        BARBELL_BENCH(s=5, r=3, rest=180, g="85% 1RM"),
        BARBELL_ROW(s=4, r=5, rest=120),
    ]),
    workout("Intensity Phase: Full Body B", "strength", 70, [
        DEADLIFT(s=5, r=2, rest=180, g="90% 1RM"),
        BARBELL_OHP(s=4, r=4, rest=150),
        PULLUP(s=3, r=5, rest=90, g="Weighted"),
    ]),
],

"Strong Foundations": [
    workout("Full Body A", "strength", 55, [
        BARBELL_SQUAT(s=3, r=8, rest=120),
        BARBELL_BENCH(s=3, r=8, rest=120),
        BARBELL_ROW(s=3, r=8, rest=90),
        PLANK(s=3, r=1, rest=30, g="Hold 30-45 seconds"),
    ]),
    workout("Full Body B", "strength", 55, [
        DEADLIFT(s=3, r=5, rest=150),
        BARBELL_OHP(s=3, r=8, rest=120),
        LAT_PULLDOWN(s=3, r=10, rest=60),
        ex("Dumbbell Lunge", 3, 10, 60, "Per leg", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Upright torso", "Bodyweight alternative"),
    ]),
],

"Concurrent Training": [
    workout("Strength + Conditioning A", "strength", 70, [
        BARBELL_SQUAT(s=4, r=5, rest=150),
        BARBELL_BENCH(s=4, r=5, rest=150),
        PULLUP(s=3, r=8, rest=90),
        ex("Rowing Machine", 1, 1, 0, "2000m row for time", "Machine", "Full Body", "Cardiovascular", ["Back", "Legs"], "intermediate", "Maintain 2:00/500m pace", "Bodyweight alternative"),
    ]),
    workout("Strength + Conditioning B", "strength", 70, [
        DEADLIFT(s=3, r=5, rest=180),
        BARBELL_OHP(s=4, r=6, rest=120),
        BARBELL_ROW(s=3, r=8, rest=90),
        ex("Assault Bike Intervals", 1, 10, 0, "30 sec on / 30 sec off x 10", "Machine", "Full Body", "Cardiovascular", ["Legs", "Arms"], "intermediate", "Max effort on intervals", "Bodyweight alternative"),
    ]),
],

# ===== OLYMPIC LIFTING =====

"Olympic Lifting Beginner": [
    workout("Clean Fundamentals", "strength", 60, [
        ex("Hang Power Clean", 5, 3, 120, "Start light, focus on form", "Barbell", "Full Body", "Posterior Chain", ["Traps", "Shoulders", "Quadriceps"], "intermediate", "Triple extension, fast elbows", "Alternative"),
        FRONT_SQUAT(s=4, r=5, rest=120),
        RDL(s=3, r=8, rest=90),
        ex("Barbell Shrug", 3, 10, 60, "Explosive shrug", "Barbell", "Back", "Trapezius", [], "beginner", "Pull shoulders to ears explosively", "Bodyweight alternative"),
    ]),
    workout("Snatch Fundamentals", "strength", 60, [
        ex("Snatch Grip Deadlift", 4, 5, 120, "Wide grip, controlled", "Barbell", "Full Body", "Posterior Chain", ["Upper Back", "Hamstrings"], "intermediate", "Maintain wide grip position", "Alternative"),
        ex("Overhead Squat", 4, 5, 120, "Light weight, mobility focus", "Barbell", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Bar behind head, full depth", "Alternative"),
        BARBELL_OHP(s=3, r=8, rest=90),
        PULLUP(s=3, r=8, rest=60),
    ]),
],

"Olympic Lifting Intermediate": [
    workout("Clean & Jerk Day", "strength", 75, [
        ex("Power Clean", 5, 3, 150, "70-80% 1RM", "Barbell", "Full Body", "Posterior Chain", ["Traps", "Quadriceps", "Shoulders"], "advanced", "Full triple extension, fast turnover", "Alternative"),
        ex("Push Jerk", 4, 3, 120, "From rack", "Barbell", "Full Body", "Shoulders", ["Triceps", "Core", "Legs"], "advanced", "Dip-drive-press, catch in quarter squat", "Alternative"),
        FRONT_SQUAT(s=4, r=4, rest=150),
        ex("Clean Pull", 3, 5, 90, "100% of clean", "Barbell", "Full Body", "Posterior Chain", ["Traps"], "intermediate", "Full extension, shrug hard", "Alternative"),
    ]),
    workout("Snatch Day", "strength", 75, [
        ex("Power Snatch", 5, 3, 150, "70-80% 1RM", "Barbell", "Full Body", "Posterior Chain", ["Shoulders", "Traps"], "advanced", "Wide grip, one fluid motion", "Alternative"),
        ex("Snatch Balance", 3, 3, 120, "Moderate weight", "Barbell", "Full Body", "Shoulders", ["Quadriceps", "Core"], "advanced", "Fast drop under, catch in full squat", "Alternative"),
        ex("Overhead Squat", 3, 5, 120, "Build up slowly", "Barbell", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Keep bar over heels", "Bodyweight alternative"),
        ex("Snatch Pull", 3, 5, 90, "100% of snatch", "Barbell", "Full Body", "Posterior Chain", ["Traps"], "intermediate", "Accelerate through the pull", "Bodyweight alternative"),
    ]),
],

"Olympic Lifting Technique": [
    workout("Technique Session A", "strength", 50, [
        ex("Hang Clean", 6, 3, 90, "50-60% 1RM, technique focus", "Barbell", "Full Body", "Posterior Chain", ["Traps", "Shoulders"], "intermediate", "Slow first pull, explosive second pull", "Alternative"),
        ex("Hang Snatch", 6, 3, 90, "50-60% 1RM", "Barbell", "Full Body", "Posterior Chain", ["Shoulders", "Traps"], "intermediate", "High elbows, fast turnover", "Alternative"),
        FRONT_SQUAT(s=3, r=5, rest=90, g="Moderate weight"),
    ]),
    workout("Technique Session B", "strength", 50, [
        ex("Clean from Blocks", 5, 3, 90, "Knee height, moderate weight", "Barbell", "Full Body", "Posterior Chain", ["Quadriceps", "Traps"], "intermediate", "Focus on second pull timing", "Alternative"),
        ex("Snatch from Blocks", 5, 3, 90, "Knee height", "Barbell", "Full Body", "Posterior Chain", ["Shoulders"], "intermediate", "Accelerate from blocks", "Bodyweight alternative"),
        ex("Overhead Squat", 3, 5, 90, "Light", "Barbell", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Mobility and stability focus", "Bodyweight alternative"),
    ]),
],

"Olympic Lift Accessory": [
    workout("Pulling Accessories", "strength", 55, [
        ex("Clean Pull", 4, 5, 90, "100-110% of clean", "Barbell", "Full Body", "Posterior Chain", ["Traps"], "intermediate", "Full extension", "Bodyweight alternative"),
        RDL(s=3, r=8, rest=90),
        ex("Barbell Shrug", 4, 8, 60, "Heavy, controlled", "Barbell", "Back", "Trapezius", [], "beginner", "2-sec hold at top", "Alternative"),
        PULLUP(s=3, r=8, rest=60),
    ]),
    workout("Squatting Accessories", "strength", 55, [
        FRONT_SQUAT(s=4, r=5, rest=120),
        ex("Overhead Squat", 3, 5, 120, "Light-moderate", "Barbell", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Full depth", "Bodyweight alternative"),
        BULGARIAN_SPLIT_SQUAT(s=3, r=8, rest=60),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Clean & Jerk Basics": [
    workout("Clean Focus", "strength", 60, [
        ex("Muscle Clean", 4, 5, 60, "Very light, feel the path", "Barbell", "Full Body", "Shoulders", ["Biceps", "Traps"], "beginner", "Slow pull, no dip to catch", "Alternative"),
        ex("Hang Power Clean", 5, 3, 120, "Moderate, from above knee", "Barbell", "Full Body", "Posterior Chain", ["Traps", "Shoulders"], "intermediate", "Triple extension, fast elbows", "Alternative"),
        FRONT_SQUAT(s=4, r=5, rest=120),
        RDL(s=3, r=8, rest=90),
    ]),
    workout("Jerk Focus", "strength", 60, [
        ex("Push Press", 4, 5, 120, "Use leg drive", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Dip-drive, full lockout", "Alternative"),
        ex("Push Jerk", 5, 3, 120, "Focus on foot position", "Barbell", "Full Body", "Shoulders", ["Triceps", "Core", "Legs"], "advanced", "Fast feet, catch in quarter squat", "Alternative"),
        BARBELL_OHP(s=3, r=8, rest=90, g="Strict press for strength"),
        ex("Dip Squat", 3, 5, 60, "Just the dip, no press", "Barbell", "Legs", "Quadriceps", ["Core"], "beginner", "Quick dip, upright torso", "Alternative"),
    ]),
],

"Snatch Foundations": [
    workout("Snatch Technique", "strength", 55, [
        ex("Snatch Grip Deadlift", 4, 5, 90, "Wide grip, slow and controlled", "Barbell", "Full Body", "Posterior Chain", ["Upper Back"], "intermediate", "Feel the wide grip position", "Alternative"),
        ex("Hang Power Snatch", 5, 3, 120, "Light weight, technique focus", "Barbell", "Full Body", "Posterior Chain", ["Shoulders", "Traps"], "intermediate", "Keep bar close, fast turnover", "Alternative"),
        ex("Overhead Squat", 4, 5, 120, "Light, build mobility", "Barbell", "Full Body", "Quadriceps", ["Core", "Shoulders"], "advanced", "Bar over heels, full depth", "Alternative"),
        ex("Snatch Balance", 3, 3, 90, "Very light", "Barbell", "Full Body", "Shoulders", ["Quadriceps"], "advanced", "Fast drop under the bar", "Bodyweight alternative"),
    ]),
],

"Power Clean Focus": [
    workout("Power Clean Session", "strength", 65, [
        ex("Power Clean", 6, 3, 150, "Build to moderate weight", "Barbell", "Full Body", "Posterior Chain", ["Traps", "Quadriceps", "Shoulders"], "advanced", "Full triple extension, catch above parallel", "Alternative"),
        ex("Clean Pull", 3, 5, 90, "100-110% of clean", "Barbell", "Full Body", "Posterior Chain", ["Traps"], "intermediate", "Accelerate through the pull", "Bodyweight alternative"),
        FRONT_SQUAT(s=4, r=5, rest=120),
        ex("Barbell Shrug", 3, 10, 60, "Explosive", "Barbell", "Back", "Trapezius", [], "beginner", "Explosive shrug, hold briefly", "Alternative"),
    ]),
],

# ===== CALISTHENICS / PROGRESSIONS =====

"Pull-up Progression": [
    workout("Pull-up Building", "strength", 45, [
        ex("Dead Hang", 3, 1, 60, "Hold 20-30 seconds", "Bodyweight", "Back", "Grip", ["Forearms", "Shoulders"], "beginner", "Full hang, relax shoulders", "Alternative"),
        ex("Band-Assisted Pull-Up", 4, 8, 90, "Use lightest band possible", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "beginner", "Full ROM, chin over bar", "Alternative"),
        ex("Negative Pull-Up", 3, 5, 90, "5-sec lowering phase", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "beginner", "Jump up, lower slowly", "Alternative"),
        ex("Inverted Row", 3, 10, 60, "Under a bar or TRX", "Bodyweight", "Back", "Rhomboids", ["Biceps", "Rear Deltoid"], "beginner", "Body straight, pull chest to bar", "Alternative"),
    ]),
],

"Push-up Progression": [
    workout("Push-up Building", "strength", 40, [
        ex("Incline Push-Up", 3, 12, 60, "Hands on bench or wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Full ROM, body straight", "Alternative"),
        PUSHUP(s=4, r=8, rest=60),
        ex("Diamond Push-Up", 3, 8, 60, "Hands close together", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Elbows close to body", "Bodyweight alternative"),
        ex("Archer Push-Up", 3, 5, 90, "Per side", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "advanced", "One arm does most work", "Bodyweight alternative"),
    ]),
],

"Dip Progression": [
    workout("Dip Building", "strength", 40, [
        ex("Bench Dip", 3, 12, 60, "Feet on floor", "Bodyweight", "Arms", "Triceps", ["Anterior Deltoid", "Pectoralis Major"], "beginner", "Lower until 90 degrees", "Bodyweight alternative"),
        ex("Assisted Dip", 4, 8, 90, "Band or machine assist", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Anterior Deltoid"], "beginner", "Full ROM, lean forward slightly", "Alternative"),
        ex("Negative Dip", 3, 5, 90, "5-sec lowering phase", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Jump up, lower very slowly", "Alternative"),
        PUSHUP(s=3, r=10, rest=60),
    ]),
],

"Handstand Journey": [
    workout("Handstand Practice", "strength", 45, [
        ex("Wall Walk", 3, 5, 60, "Walk hands toward wall", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Walk feet up wall, hands close", "Alternative"),
        ex("Wall Handstand Hold", 5, 1, 60, "Hold 20-30 seconds facing wall", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps", "Trapezius"], "intermediate", "Stack joints, push floor away", "Alternative"),
        ex("Pike Push-Up", 4, 8, 60, "Hips high, head toward floor", "Bodyweight", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Touch head to floor if possible", "Alternative"),
        PLANK(s=3, r=1, rest=30, g="Hold 45 seconds"),
    ]),
],

"Pistol Squat Challenge": [
    workout("Pistol Squat Progression", "strength", 40, [
        ex("Assisted Pistol Squat", 4, 5, 90, "Hold pole or TRX", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Full depth with assistance", "Bodyweight alternative"),
        ex("Box Pistol Squat", 3, 6, 90, "Sit to box, stand on one leg", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Lower box height over time", "Alternative"),
        BODYWEIGHT_SQUAT(s=3, r=15, rest=45),
        ex("Single Leg Calf Raise", 3, 15, 30, "Per leg", "Bodyweight", "Legs", "Calves", [], "beginner", "Full ROM, hold at top", "Alternative"),
    ]),
],

"Bar Athletes": [
    workout("Bar Workout", "strength", 50, [
        PULLUP(s=4, r=8, rest=90),
        ex("Muscle-Up Progression", 3, 3, 120, "Explosive pull-ups or band-assisted", "Bodyweight", "Full Body", "Latissimus Dorsi", ["Triceps", "Core"], "advanced", "Pull high, transition over bar", "Alternative"),
        ex("Hanging Leg Raise", 3, 12, 60, "On bar", "Bodyweight", "Core", "Lower Abs", ["Hip Flexors"], "intermediate", "No swinging", "Bodyweight alternative"),
        ex("Dip", 4, 10, 60, "On parallel bars", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Full ROM", "Bodyweight alternative"),
    ]),
],

"Pike to Handstand Push-up": [
    workout("Pike Handstand Progression", "strength", 45, [
        ex("Pike Push-Up", 4, 10, 60, "Hips high", "Bodyweight", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Head to floor", "Bodyweight alternative"),
        ex("Elevated Pike Push-Up", 3, 8, 90, "Feet on box", "Bodyweight", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "More vertical = harder", "Bodyweight alternative"),
        ex("Wall Handstand Hold", 3, 1, 60, "Hold 30 seconds", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Push floor away, tight body", "Alternative"),
        ex("Handstand Negative", 3, 3, 90, "Lower from handstand slowly", "Bodyweight", "Shoulders", "Deltoids", ["Triceps", "Core"], "advanced", "5-sec lowering, head to floor", "Alternative"),
    ]),
],

"Push-up to Planche": [
    workout("Planche Progression", "strength", 50, [
        ex("Pseudo Planche Push-Up", 4, 8, 90, "Hands by hips, lean forward", "Bodyweight", "Chest", "Anterior Deltoid", ["Pectoralis Major", "Core"], "advanced", "Lean as far forward as possible", "Alternative"),
        ex("Tuck Planche Hold", 5, 1, 90, "Hold 10-20 seconds", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Core", "Triceps"], "advanced", "Round back, knees tucked to chest", "Alternative"),
        ex("Planche Lean", 4, 1, 60, "Hold 15-20 sec on floor or parallettes", "Bodyweight", "Shoulders", "Anterior Deltoid", ["Core", "Chest"], "advanced", "Straight arms, lean forward, hold", "Alternative"),
        PUSHUP(s=3, r=15, rest=45),
    ]),
],

"Dip to Ring Dip": [
    workout("Ring Dip Progression", "strength", 45, [
        ex("Ring Support Hold", 4, 1, 60, "Hold 20-30 seconds", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Rings turned out, arms locked", "Alternative"),
        ex("Dip", 4, 8, 90, "On parallel bars", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major"], "intermediate", "Full depth", "Bodyweight alternative"),
        ex("Ring Negative Dip", 3, 5, 90, "5-sec lowering on rings", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "advanced", "Control the rings, slow descent", "Alternative"),
        ex("Ring Push-Up", 3, 10, 60, "On gymnastics rings", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Rings touch sides of chest", "Bodyweight alternative"),
    ]),
],

"Knee Raise to Dragon Flag": [
    workout("Dragon Flag Progression", "strength", 40, [
        ex("Hanging Knee Raise", 3, 15, 60, "On bar", "Bodyweight", "Core", "Lower Abs", ["Hip Flexors"], "beginner", "Controlled, no swinging", "Alternative"),
        ex("Hanging Leg Raise", 3, 10, 60, "Straight legs", "Bodyweight", "Core", "Lower Abs", ["Hip Flexors", "Obliques"], "intermediate", "Legs parallel to floor", "Bodyweight alternative"),
        ex("Tuck Dragon Flag", 3, 8, 90, "On bench, knees tucked", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "Lower slowly with control", "Alternative"),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Row to Front Lever": [
    workout("Front Lever Progression", "strength", 45, [
        ex("Inverted Row", 4, 10, 60, "Under a bar", "Bodyweight", "Back", "Rhomboids", ["Biceps", "Rear Deltoid"], "beginner", "Body straight", "Bodyweight alternative"),
        ex("Tuck Front Lever Hold", 5, 1, 90, "Hold 10-20 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "advanced", "Knees tucked, body horizontal", "Alternative"),
        ex("Front Lever Negative", 3, 3, 90, "Lower from inverted hang", "Bodyweight", "Back", "Latissimus Dorsi", ["Core"], "advanced", "Slow, controlled descent", "Alternative"),
        PULLUP(s=3, r=8, rest=90),
    ]),
],

"Skills Unlocked": [
    workout("Skills Training A", "strength", 50, [
        ex("L-Sit Hold", 4, 1, 60, "Hold 10-20 seconds", "Bodyweight", "Core", "Hip Flexors", ["Triceps", "Abs"], "intermediate", "Straight legs, push floor away", "Alternative"),
        PULLUP(s=4, r=8, rest=90),
        ex("Handstand Practice", 5, 1, 60, "Wall-assisted, hold 30s", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Stack joints, tight body", "Alternative"),
        PUSHUP(s=3, r=15, rest=45),
    ]),
    workout("Skills Training B", "strength", 50, [
        ex("Muscle-Up Progression", 4, 3, 120, "Explosive or band-assisted", "Bodyweight", "Full Body", "Latissimus Dorsi", ["Triceps", "Core"], "advanced", "High pull, fast transition", "Alternative"),
        ex("Pistol Squat Practice", 3, 5, 90, "Assisted if needed", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "advanced", "Full depth", "Bodyweight alternative"),
        ex("Back Lever Tuck", 3, 1, 90, "Hold 10-15 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Core"], "advanced", "Tuck position, control", "Alternative"),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Jumping Progression": [
    workout("Jump Training", "strength", 45, [
        JUMP_SQUAT(s=4, r=8, rest=90),
        ex("Box Jump", 4, 6, 90, "Start low, increase height", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly, stand fully", "Alternative"),
        ex("Depth Jump", 3, 5, 120, "Step off box, immediately jump", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "advanced", "Minimal ground contact", "Alternative"),
        ex("Broad Jump", 3, 5, 90, "Maximum distance", "Bodyweight", "Legs", "Glutes", ["Quadriceps", "Core"], "intermediate", "Swing arms, extend fully", "Alternative"),
    ]),
],

"Freerunning Foundations": [
    workout("Parkour Conditioning", "strength", 50, [
        ex("Precision Jump", 4, 8, 60, "Jump to specific marks", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "intermediate", "Land quietly, stick the landing", "Alternative"),
        ex("Wall Run Drill", 3, 5, 90, "Run at wall, plant foot, push up", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Core"], "advanced", "Two steps max off wall", "Alternative"),
        ex("Cat Hang", 3, 1, 60, "Hang from ledge, feet on wall, 20s", "Bodyweight", "Back", "Grip", ["Forearms", "Core"], "intermediate", "Feet flat on wall, arms extended", "Alternative"),
        PUSHUP(s=3, r=15, rest=45),
        BODYWEIGHT_SQUAT(s=3, r=20, rest=30),
    ]),
],

"Tricking Basics": [
    workout("Tricking Conditioning", "strength", 50, [
        JUMP_SQUAT(s=3, r=10, rest=60),
        ex("Tuck Jump", 4, 8, 60, "Jump and pull knees to chest", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Flexors"], "intermediate", "Height over speed", "Bodyweight alternative"),
        ex("Cartwheel Drill", 3, 5, 60, "Both sides", "Bodyweight", "Full Body", "Core", ["Shoulders", "Legs"], "beginner", "Hands-feet-feet sequence", "Bodyweight alternative"),
        PUSHUP(s=3, r=15, rest=45),
        PLANK(s=3, r=1, rest=30, g="Hold 45 seconds"),
    ]),
],

# ===== STRONGMAN =====

"Strongman Basics": [
    workout("Strongman Day A", "strength", 75, [
        DEADLIFT(s=5, r=3, rest=180),
        ex("Farmer's Walk", 4, 1, 90, "50m per set, heavy dumbbells/handles", "Dumbbell", "Full Body", "Grip", ["Traps", "Core", "Forearms"], "intermediate", "Stand tall, tight core, fast steps", "Alternative"),
        BARBELL_OHP(s=4, r=5, rest=120),
        ex("Barbell Shrug", 4, 10, 60, "Heavy", "Barbell", "Back", "Trapezius", [], "beginner", "Hold 2 seconds at top", "Bodyweight alternative"),
    ]),
    workout("Strongman Day B", "strength", 75, [
        BARBELL_SQUAT(s=5, r=3, rest=180),
        ex("Yoke Walk", 3, 1, 120, "50m per set, heavy", "Barbell", "Full Body", "Core", ["Traps", "Legs"], "advanced", "Short quick steps, brace hard", "Alternative"),
        BARBELL_ROW(s=4, r=6, rest=120),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Strongman Competition Prep": [
    workout("Event Day A", "strength", 90, [
        DEADLIFT(s=5, r=2, rest=240, g="Competition deadlift, heavy singles"),
        ex("Atlas Stone Load", 4, 3, 180, "Stone to platform", "Other", "Full Body", "Posterior Chain", ["Biceps", "Core"], "advanced", "Lap the stone, extend hips to load", "Alternative"),
        ex("Farmer's Walk", 3, 1, 120, "100m per set, competition weight", "Other", "Full Body", "Grip", ["Traps", "Core"], "advanced", "Fast turnover, don't drop", "Alternative"),
        BARBELL_OHP(s=3, r=5, rest=150, g="Log press if available"),
    ]),
    workout("Event Day B", "strength", 90, [
        BARBELL_SQUAT(s=5, r=3, rest=180),
        ex("Tire Flip", 3, 5, 120, "Drive with hips, flip fast", "Other", "Full Body", "Posterior Chain", ["Chest", "Triceps"], "advanced", "Low hips, drive through", "Alternative"),
        ex("Sandbag Carry", 3, 1, 120, "100m per set", "Other", "Full Body", "Core", ["Legs", "Arms"], "intermediate", "Bear hug grip, fast feet", "Alternative"),
        ex("Sled Push", 3, 1, 90, "50m sprints", "Other", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Low angle, drive with legs", "Alternative"),
    ]),
],

"Atlas Stone Prep": [
    workout("Stone Training", "strength", 60, [
        ex("Atlas Stone Load", 5, 3, 180, "Progressively heavier stones", "Other", "Full Body", "Posterior Chain", ["Biceps", "Core"], "advanced", "Lap stone, extend hips, load to platform", "Alternative"),
        DEADLIFT(s=4, r=5, rest=150),
        BARBELL_ROW(s=3, r=8, rest=90),
        ex("Zercher Squat", 3, 6, 120, "Mimics stone carry", "Barbell", "Full Body", "Quadriceps", ["Core", "Biceps"], "advanced", "Bar in crook of elbows", "Bodyweight alternative"),
    ]),
],

"Yoke Walk Training": [
    workout("Yoke Day", "strength", 60, [
        ex("Yoke Walk", 5, 1, 120, "50m runs, build weight", "Barbell", "Full Body", "Core", ["Traps", "Legs"], "advanced", "Short quick steps, brace hard", "Alternative"),
        BARBELL_SQUAT(s=4, r=5, rest=150, g="Build leg strength for yoke"),
        ex("Farmer's Walk", 3, 1, 90, "50m per set", "Dumbbell", "Full Body", "Grip", ["Traps", "Core"], "intermediate", "Complement yoke work", "Bodyweight alternative"),
        PLANK(s=3, r=1, rest=30, g="Hold 60 seconds, core stability"),
    ]),
],

"Farmer's Walk Mastery": [
    workout("Farmer's Walk Session", "strength", 55, [
        ex("Farmer's Walk", 6, 1, 90, "50m runs, progressive weight", "Dumbbell", "Full Body", "Grip", ["Traps", "Core", "Forearms"], "intermediate", "Stand tall, fast steps", "Alternative"),
        DEADLIFT(s=3, r=5, rest=150, g="Grip strength builder"),
        ex("Barbell Shrug", 4, 10, 60, "Hold at top", "Barbell", "Back", "Trapezius", [], "beginner", "Heavy, controlled", "Alternative"),
        ex("Plate Pinch Hold", 3, 1, 60, "Hold 30 seconds", "Other", "Arms", "Grip", ["Forearms"], "beginner", "Pinch two plates together", "Bodyweight alternative"),
    ]),
],

"Tire Flip Conditioning": [
    workout("Tire Day", "strength", 55, [
        ex("Tire Flip", 5, 5, 120, "Explosive hip drive", "Other", "Full Body", "Posterior Chain", ["Chest", "Triceps", "Core"], "advanced", "Low hips, chest into tire, drive through", "Alternative"),
        DEADLIFT(s=3, r=5, rest=150),
        ex("Sledgehammer Strike", 3, 10, 60, "Per side, on tire", "Other", "Full Body", "Core", ["Shoulders", "Back", "Arms"], "intermediate", "Rotate hips, slam hard", "Alternative"),
        PUSHUP(s=3, r=15, rest=45),
    ]),
],

"Sled Push/Pull": [
    workout("Sled Day", "strength", 50, [
        ex("Sled Push", 5, 1, 90, "40m sprints, build weight", "Other", "Legs", "Quadriceps", ["Glutes", "Core", "Calves"], "intermediate", "Low angle, drive with legs", "Alternative"),
        ex("Sled Pull", 4, 1, 90, "40m pulls, hand-over-hand or harness", "Other", "Full Body", "Back", ["Biceps", "Grip", "Core"], "intermediate", "Stay low, drive hips back", "Alternative"),
        ex("Prowler Push", 3, 1, 90, "40m, high handles", "Other", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Fast feet, lean into it", "Alternative"),
    ]),
],

"Odd Object Training": [
    workout("Odd Object Day", "strength", 60, [
        ex("Sandbag Clean", 4, 6, 90, "Heavy sandbag", "Other", "Full Body", "Posterior Chain", ["Core", "Biceps"], "intermediate", "Lap and stand, bear hug", "Alternative"),
        ex("Stone Carry", 3, 1, 90, "50m per set", "Other", "Full Body", "Core", ["Biceps", "Legs"], "intermediate", "Bear hug, fast steps", "Alternative"),
        ex("Keg Carry", 3, 1, 90, "50m per set", "Other", "Full Body", "Core", ["Biceps", "Forearms"], "intermediate", "Bear hug grip", "Bodyweight alternative"),
        ex("Farmer's Walk", 3, 1, 90, "50m per set", "Dumbbell", "Full Body", "Grip", ["Traps", "Core"], "intermediate", "Stand tall, fast steps", "Alternative"),
    ]),
],

"Grip Strength Specialist": [
    workout("Grip Training", "strength", 45, [
        ex("Dead Hang", 4, 1, 60, "Hold to failure", "Bodyweight", "Back", "Grip", ["Forearms"], "beginner", "Full hang, overhand grip", "Alternative"),
        ex("Plate Pinch Hold", 4, 1, 60, "Hold 30 seconds, two plates", "Other", "Arms", "Grip", ["Forearms"], "beginner", "Pinch grip, don't drop", "Alternative"),
        ex("Towel Pull-Up", 3, 6, 90, "Drape towel over bar", "Bodyweight", "Back", "Grip", ["Latissimus Dorsi", "Biceps"], "advanced", "Crush the towel", "Bodyweight alternative"),
        ex("Farmer's Walk", 3, 1, 60, "30m per set, heavy", "Dumbbell", "Full Body", "Grip", ["Traps", "Core", "Forearms"], "intermediate", "Don't let go", "Alternative"),
        ex("Wrist Curl", 3, 15, 30, "Forearms on bench", "Dumbbell", "Arms", "Forearms", [], "beginner", "Full ROM, controlled", "Alternative"),
    ]),
],

# ===== KETTLEBELL =====

"Single Kettlebell": [
    workout("KB Full Body", "strength", 40, [
        KETTLEBELL_SWING(s=5, r=15, rest=60),
        ex("KB Goblet Squat", 4, 10, 60, "Hold at chest", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat, elbows inside knees", "Alternative"),
        ex("KB Clean & Press", 3, 8, 60, "Per side", "Kettlebell", "Full Body", "Shoulders", ["Core", "Glutes"], "intermediate", "Clean to rack, press overhead", "Alternative"),
        ex("KB Row", 3, 10, 60, "Per side", "Kettlebell", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Stable base, pull to hip", "Alternative"),
        ex("Turkish Get-Up", 2, 3, 60, "Per side, moderate KB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Glutes", "Legs"], "intermediate", "Slow and controlled, lock arm", "Alternative"),
    ]),
],

"Double Kettlebell": [
    workout("Double KB Session", "strength", 50, [
        ex("Double KB Clean", 4, 8, 90, "Both KBs simultaneously", "Kettlebell", "Full Body", "Posterior Chain", ["Core", "Shoulders"], "intermediate", "Sync both bells", "Bodyweight alternative"),
        ex("Double KB Front Squat", 4, 8, 90, "Rack position", "Kettlebell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Upright torso, deep squat", "Alternative"),
        ex("Double KB Press", 4, 6, 90, "Both overhead", "Kettlebell", "Shoulders", "Deltoids", ["Triceps", "Core"], "intermediate", "Full lockout, control descent", "Alternative"),
        ex("Double KB Swing", 3, 12, 60, "Heavy, hip hinge", "Kettlebell", "Full Body", "Glutes", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap", "Alternative"),
    ]),
],

"Kettlebell Strength": [
    workout("KB Strength A", "strength", 50, [
        KETTLEBELL_SWING(s=5, r=15, rest=60),
        ex("KB Goblet Squat", 4, 10, 60, "Heavy KB", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep squat", "Bodyweight alternative"),
        ex("KB Clean & Press", 4, 6, 60, "Per side", "Kettlebell", "Full Body", "Shoulders", ["Core", "Glutes"], "intermediate", "One fluid motion", "Bodyweight alternative"),
        ex("KB Renegade Row", 3, 8, 60, "Per side, in plank position", "Kettlebell", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Anti-rotation, stable hips", "Alternative"),
    ]),
    workout("KB Strength B", "strength", 50, [
        ex("Turkish Get-Up", 3, 3, 60, "Per side, heavy KB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Glutes", "Legs"], "intermediate", "Slow and controlled, lock arm", "Alternative"),
        ex("KB Snatch", 4, 8, 60, "Per side", "Kettlebell", "Full Body", "Shoulders", ["Core", "Glutes"], "advanced", "One motion from floor to overhead", "Bodyweight alternative"),
        ex("KB Windmill", 3, 6, 60, "Per side", "Kettlebell", "Core", "Obliques", ["Shoulders", "Hamstrings"], "intermediate", "Keep eyes on KB, hip hinge", "Alternative"),
        ex("KB Squat", 4, 10, 60, "Front rack position", "Kettlebell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Deep, controlled", "Alternative"),
    ]),
],

# ===== HIIT / CARDIO =====

"HIIT Burner": [
    workout("HIIT Burner", "hiit", 30, [
        BURPEE(s=4, r=10, rest=30),
        JUMP_SQUAT(s=4, r=12, rest=30),
        MOUNTAIN_CLIMBER(s=4, r=20, rest=30),
        HIGH_KNEES(s=4, r=20, rest=30),
        PUSHUP(s=3, r=12, rest=30),
    ]),
],

"HIIT + Strength Combo": [
    workout("HIIT Strength", "hiit", 45, [
        BARBELL_SQUAT(s=4, r=6, rest=90),
        BURPEE(s=3, r=10, rest=30),
        BARBELL_BENCH(s=4, r=6, rest=90),
        MOUNTAIN_CLIMBER(s=3, r=20, rest=30),
        BARBELL_ROW(s=3, r=8, rest=60),
        JUMP_SQUAT(s=3, r=10, rest=30),
    ]),
],

"Burpee Bootcamp": [
    workout("Burpee Bootcamp", "hiit", 30, [
        BURPEE(s=5, r=10, rest=30),
        ex("Burpee Box Jump", 3, 8, 45, "Add box jump at top", "Bodyweight", "Full Body", "Full Body", ["Legs", "Chest", "Core"], "advanced", "Burpee then jump onto box", "Bodyweight alternative"),
        ex("Burpee Pull-Up", 3, 6, 45, "Burpee under pull-up bar, pull-up at top", "Bodyweight", "Full Body", "Full Body", ["Back", "Chest", "Legs"], "advanced", "Full burpee, jump to bar, pull up", "Alternative"),
        PUSHUP(s=3, r=15, rest=30),
        PLANK(s=2, r=1, rest=30, g="Hold 60 seconds"),
    ]),
],

"Cardio Burn Challenge": [
    workout("Cardio Burn", "cardio", 40, [
        HIGH_KNEES(s=4, r=30, rest=20),
        BURPEE(s=4, r=10, rest=30),
        JUMP_SQUAT(s=4, r=15, rest=20),
        MOUNTAIN_CLIMBER(s=4, r=30, rest=20),
        ex("Jumping Jack", 4, 30, 20, "30 seconds", "Bodyweight", "Full Body", "Cardiovascular", ["Shoulders", "Calves"], "beginner", "Full extension", "Bodyweight alternative"),
    ]),
],

"Evening Metabolic Boost": [
    workout("Evening Metabolic", "hiit", 30, [
        KETTLEBELL_SWING(s=4, r=15, rest=30),
        BODYWEIGHT_SQUAT(s=3, r=20, rest=20),
        PUSHUP(s=3, r=15, rest=30),
        MOUNTAIN_CLIMBER(s=3, r=20, rest=20),
        PLANK(s=2, r=1, rest=20, g="Hold 45 seconds"),
    ]),
],

"Metabolic Strength": [
    workout("Metabolic Strength Circuit", "strength", 45, [
        BARBELL_SQUAT(s=4, r=8, rest=60),
        BARBELL_BENCH(s=4, r=8, rest=60),
        BARBELL_ROW(s=4, r=8, rest=60),
        BURPEE(s=3, r=10, rest=30),
        PLANK(s=2, r=1, rest=20, g="Hold 45 seconds"),
    ]),
],

"Cardio Lifting": [
    workout("Cardio + Lifting", "strength", 50, [
        BARBELL_SQUAT(s=3, r=10, rest=60),
        ex("Rowing Machine", 1, 1, 60, "500m row", "Machine", "Full Body", "Cardiovascular", ["Back", "Legs"], "intermediate", "Maintain consistent pace", "Bodyweight alternative"),
        BARBELL_BENCH(s=3, r=10, rest=60),
        BURPEE(s=3, r=10, rest=30),
        DEADLIFT(s=3, r=8, rest=90),
    ]),
],

"Strength + Cardio Hybrid": [
    workout("Hybrid Session", "strength", 55, [
        BARBELL_SQUAT(s=4, r=6, rest=120),
        BARBELL_OHP(s=3, r=8, rest=90),
        ex("Assault Bike", 3, 1, 60, "30 seconds max effort", "Machine", "Full Body", "Cardiovascular", ["Legs", "Arms"], "intermediate", "All out effort", "Bodyweight alternative"),
        BARBELL_ROW(s=3, r=8, rest=90),
        JUMP_SQUAT(s=3, r=10, rest=30),
    ]),
],

"Strength-Endurance Blend": [
    workout("Strength Endurance", "strength", 50, [
        BARBELL_SQUAT(s=3, r=12, rest=60),
        PUSHUP(s=3, r=20, rest=30),
        DEADLIFT(s=3, r=10, rest=60),
        PULLUP(s=3, r=10, rest=60),
        BURPEE(s=2, r=15, rest=30),
    ]),
],

"Low Intensity Steady State": [
    workout("LISS Cardio", "cardio", 45, [
        cardio_ex("Brisk Walk", 1, "20 minutes, moderate pace"),
        cardio_ex("Cycling", 1, "15 minutes, easy pace"),
        cardio_ex("Elliptical", 1, "10 minutes, low resistance"),
    ]),
],

"Zone 2 Training Protocol": [
    workout("Zone 2 Session", "cardio", 50, [
        cardio_ex("Easy Run/Walk", 1, "30-40 minutes at conversational pace, HR 60-70% max"),
        cardio_ex("Cycling", 1, "20-30 minutes at easy pace, can hold conversation"),
    ]),
],

# ===== WARMUP / MOBILITY =====

"Dynamic Warmup Series": [
    workout("Dynamic Warmup", "flexibility", 15, [
        ex("Leg Swing", 2, 15, 15, "Forward and lateral", "Bodyweight", "Legs", "Hip Flexors", ["Hamstrings", "Adductors"], "beginner", "Hold support, controlled swings", "Alternative"),
        ex("Arm Circle", 2, 15, 15, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Progressively larger circles", "Bodyweight alternative"),
        ex("High Knee", 2, 20, 15, "Marching, bring knees high", "Bodyweight", "Legs", "Hip Flexors", ["Core"], "beginner", "Controlled pace", "Alternative"),
        ex("Inchworm", 2, 6, 20, "Walk hands out to plank, walk back", "Bodyweight", "Full Body", "Hamstrings", ["Core", "Shoulders"], "beginner", "Straight legs on walk-back", "Alternative"),
        ex("World's Greatest Stretch", 2, 5, 15, "Per side", "Bodyweight", "Full Body", "Hip Flexors", ["Thoracic Spine", "Hamstrings"], "beginner", "Lunge, rotate, reach", "Alternative"),
    ]),
],

"Front Rack Mobility": [
    workout("Front Rack Mobility", "flexibility", 20, [
        ex("Wrist Flexor Stretch", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Arms", "Forearms", ["Wrists"], "beginner", "Fingers back, gently lean", "Alternative"),
        ex("Lat Stretch", 3, 1, 15, "Hold 30 seconds on rack", "Bodyweight", "Back", "Latissimus Dorsi", ["Triceps"], "beginner", "Hang from bar, sink hips", "Alternative"),
        ex("Tricep Stretch", 3, 1, 15, "Hold 30 seconds", "Bodyweight", "Arms", "Triceps", ["Shoulders"], "beginner", "Elbow overhead, pull gently", "Alternative"),
        ex("Thoracic Extension on Foam Roller", 3, 1, 20, "10 reps, pause at top", "Bodyweight", "Back", "Thoracic Spine", ["Core"], "beginner", "Roll from mid to upper back", "Alternative"),
    ]),
],

"Overhead Squat Mobility": [
    workout("Overhead Squat Mobility", "flexibility", 25, [
        ex("Ankle Mobility Drill", 3, 10, 15, "Knee over toe rocks", "Bodyweight", "Legs", "Ankles", ["Calves"], "beginner", "Keep heel down", "Bodyweight alternative"),
        ex("Thoracic Extension on Foam Roller", 3, 1, 15, "Hold 10 reps", "Bodyweight", "Back", "Thoracic Spine", [], "beginner", "Mid to upper back", "Bodyweight alternative"),
        ex("Wall Slide", 3, 10, 15, "Arms against wall, slide up", "Bodyweight", "Shoulders", "Rotator Cuff", ["Scapular Muscles"], "beginner", "Keep contact with wall", "Alternative"),
        ex("PVC Overhead Squat", 3, 8, 20, "Light stick or PVC pipe", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "beginner", "Go only as deep as you can with arms overhead", "Bodyweight alternative"),
    ]),
],

"Hip & Back Relief": [
    workout("Hip & Back Relief", "flexibility", 25, [
        stretch("90/90 Hip Stretch", 30, "Switch sides, 30 seconds each"),
        stretch("Pigeon Pose", 30, "Each side, hold 30 seconds"),
        stretch("Cat-Cow", 15, "10 reps, slow and controlled"),
        stretch("Child's Pose", 30, "Hold 30-60 seconds, relax"),
        ex("Dead Bug", 3, 10, 30, "Slow and controlled", "Bodyweight", "Core", "Core", ["Hip Flexors"], "beginner", "Press lower back into floor", "Bodyweight alternative"),
    ]),
],

"Heat Adaptation Training": [
    workout("Heat Adaptation", "cardio", 40, [
        cardio_ex("Brisk Walk", 1, "20 minutes, warm environment if possible"),
        BODYWEIGHT_SQUAT(s=3, r=15, rest=45),
        PUSHUP(s=3, r=12, rest=45),
        ex("Jumping Jack", 3, 30, 30, "30 seconds", "Bodyweight", "Full Body", "Cardiovascular", ["Shoulders"], "beginner", "Full extension", "Bodyweight alternative"),
        PLANK(s=2, r=1, rest=30, g="Hold 45 seconds"),
    ]),
],

"Cold Exposure Prep": [
    workout("Cold Exposure Conditioning", "cardio", 35, [
        ex("Wim Hof Breathing", 3, 1, 30, "30 breaths + hold", "Bodyweight", "Full Body", "Respiratory", ["Core", "Mind"], "beginner", "Deep inhale, passive exhale, hold", "Alternative"),
        BODYWEIGHT_SQUAT(s=3, r=15, rest=30),
        PUSHUP(s=3, r=12, rest=30),
        PLANK(s=3, r=1, rest=20, g="Hold 30-45 seconds"),
        ex("Horse Stance Hold", 2, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Core", "Glutes"], "beginner", "Wide stance, sit low", "Alternative"),
    ]),
],

"CrossTraining Essentials": [
    workout("Cross Training A", "strength", 50, [
        BARBELL_SQUAT(s=3, r=8, rest=90),
        PULLUP(s=3, r=8, rest=60),
        KETTLEBELL_SWING(s=3, r=15, rest=45),
        PUSHUP(s=3, r=15, rest=30),
        PLANK(s=2, r=1, rest=30, g="Hold 60 seconds"),
    ]),
    workout("Cross Training B", "strength", 50, [
        DEADLIFT(s=3, r=5, rest=120),
        BARBELL_OHP(s=3, r=8, rest=90),
        ex("Box Jump", 3, 8, 60, "Moderate height", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly", "Bodyweight alternative"),
        BARBELL_ROW(s=3, r=8, rest=60),
        BURPEE(s=2, r=10, rest=30),
    ]),
],

"Functional Strength": [
    workout("Functional Strength A", "strength", 50, [
        DEADLIFT(s=3, r=5, rest=150),
        ex("Farmer's Walk", 3, 1, 60, "40m per set", "Dumbbell", "Full Body", "Grip", ["Traps", "Core"], "intermediate", "Stand tall", "Bodyweight alternative"),
        PULLUP(s=3, r=8, rest=90),
        KETTLEBELL_SWING(s=3, r=15, rest=45),
        PLANK(s=2, r=1, rest=30, g="Hold 60 seconds"),
    ]),
    workout("Functional Strength B", "strength", 50, [
        BARBELL_SQUAT(s=3, r=8, rest=120),
        BARBELL_OHP(s=3, r=8, rest=90),
        ex("Walking Lunge", 3, 10, 60, "Per leg, with dumbbells", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Upright torso", "Alternative"),
        PUSHUP(s=3, r=15, rest=30),
        ex("Hanging Leg Raise", 3, 10, 60, "Core stability", "Bodyweight", "Core", "Lower Abs", ["Hip Flexors"], "intermediate", "No swinging", "Bodyweight alternative"),
    ]),
],

}
