#!/usr/bin/env python3
"""Generate Ultimate Strength - Advanced, 12w, 4x/wk
Periodized: Accumulation (W1-3) -> Intensification (W4-6) -> Realization (W7-9) -> Peak/Test (W10-12)
Upper/Lower split, heavy compound focus with strategic accessories."""
import sys
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()
migration_num = helper.get_next_migration_num()

def ex(name, sets, reps, rest, weight, equip, body, primary, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest, "weight_guidance": weight,
        "equipment": equip, "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub
    }

# ═══════════════════════════════════════════
# PHASE 1: ACCUMULATION (Weeks 1-3) - Volume focus, moderate intensity
# ═══════════════════════════════════════════
w1 = {
    "focus": "Accumulation Phase - High volume, moderate intensity (RPE 7-8) to build work capacity",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Strength",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Bench Press", 5, 6, 180, "75% 1RM, RPE 7", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Arch upper back, retract scapulae, leg drive into floor", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 8, 120, "70% 1RM, RPE 7", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoids"], "advanced", "Hinge at 45 degrees, pull to sternum, squeeze 1 second", "Pendlay Row"),
                ex("Barbell Overhead Press", 4, 6, 150, "70% 1RM, RPE 7", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Brace hard, straight bar path, full lockout", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 6, 120, "Add 10-25lbs, RPE 7", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Dead hang to chin over bar, control the eccentric", "Lat Pulldown"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Moderate-heavy, RPE 8", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "30-degree incline, full stretch, squeeze at top", "Incline Barbell Press"),
                ex("Face Pull", 3, 15, 60, "Moderate, high reps for shoulder health", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "advanced", "Pull to face, external rotate, 2-second hold", "Band Pull-Apart"),
                ex("Barbell Curl", 3, 10, 60, "Moderate, strict form", "Barbell", "Arms", "Biceps", ["Brachialis", "Forearms"], "advanced", "No body English, full range, controlled negative", "Dumbbell Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Strength",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 6, 180, "75% 1RM, RPE 7", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Erector Spinae"], "advanced", "High bar, break at hips and knees, hit depth, drive through midfoot", "Front Squat"),
                ex("Conventional Deadlift", 4, 5, 240, "75% 1RM, RPE 7", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "advanced", "Mixed or hook grip, flat back, push floor away", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 4, 8, 120, "65% deadlift 1RM, RPE 7", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Slow eccentric, big stretch, drive hips forward at top", "Dumbbell Romanian Deadlift"),
                ex("Leg Press", 4, 10, 120, "Moderate-heavy, RPE 8", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full range, feet shoulder width, don't lock knees", "Hack Squat"),
                ex("Walking Lunge", 3, 12, 90, "Moderate dumbbells, 12 total steps", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Long stride, back knee near floor, upright torso", "Bulgarian Split Squat"),
                ex("Calf Raise (Standing)", 4, 12, 60, "Heavy, full range", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full stretch at bottom, peak contraction at top, 2-second hold", "Seated Calf Raise"),
                ex("Hanging Leg Raise", 3, 12, 60, "Bodyweight, straight legs if possible", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "advanced", "Control the swing, legs to 90 degrees minimum", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Volume",
            "type": "strength",
            "duration_minutes": 65,
            "exercises": [
                ex("Close-Grip Bench Press", 4, 8, 120, "65% bench 1RM, RPE 7", "Barbell", "Chest", "Triceps", ["Pectorals", "Anterior Deltoids"], "advanced", "Hands shoulder width, elbows tucked, lower to lower chest", "Dumbbell Close-Grip Press"),
                ex("Pendlay Row", 4, 6, 120, "70% row weight, RPE 7-8, explosive pull", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Dead stop each rep, explosive pull, lower controlled", "T-Bar Row"),
                ex("Seated Dumbbell Press", 4, 8, 90, "Moderate-heavy, RPE 8", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Full range, don't lean back excessively", "Machine Shoulder Press"),
                ex("Chest-Supported Dumbbell Row", 3, 10, 75, "Moderate, squeeze pause at top", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Rear Deltoids"], "advanced", "Chest on incline bench, pull to hips, 1-second squeeze", "Seated Cable Row"),
                ex("Dumbbell Chest Fly", 3, 12, 75, "Moderate, big stretch", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Wide arc, deep stretch, squeeze together", "Cable Crossover"),
                ex("Dumbbell Lateral Raise", 3, 15, 60, "Moderate, controlled", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Slight forward lean, raise to shoulder height", "Cable Lateral Raise"),
                ex("Triceps Dip", 3, 10, 90, "Bodyweight or weighted, RPE 7-8", "Dip Bars", "Arms", "Triceps", ["Pectorals", "Anterior Deltoids"], "advanced", "Upright torso for triceps, full lockout", "Cable Pushdown")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Volume",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Front Squat", 4, 6, 150, "65% back squat 1RM, RPE 7", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes", "Upper Back"], "advanced", "Elbows high, upright torso, break at knees first", "Goblet Squat"),
                ex("Sumo Deadlift", 4, 5, 180, "70% conventional 1RM, RPE 7", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors", "Quadriceps"], "advanced", "Wide stance, toes out, chest up, push knees out", "Conventional Deadlift"),
                ex("Bulgarian Split Squat", 4, 8, 90, "Moderate dumbbells, each leg", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Rear foot elevated, deep stretch, drive through front heel", "Walking Lunge"),
                ex("Glute-Ham Raise", 3, 8, 90, "Bodyweight, control eccentric", "GHD", "Legs", "Hamstrings", ["Glutes", "Calves"], "advanced", "Slow lower, use hamstrings to pull back up", "Nordic Curl"),
                ex("Leg Extension", 3, 12, 60, "Moderate, pause at top", "Machine", "Legs", "Quadriceps", [], "advanced", "Full extension, 2-second squeeze at top", "Sissy Squat"),
                ex("Seated Calf Raise", 4, 15, 60, "Moderate, full range", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Deep stretch at bottom, full contraction at top", "Standing Calf Raise"),
                ex("Ab Wheel Rollout", 3, 12, 60, "Bodyweight, full extension", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Erector Spinae"], "advanced", "Controlled extension, brace core throughout", "Plank")
            ]
        }
    ]
}

w2 = {
    "focus": "Accumulation Phase continued - adding small load increases while maintaining volume",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Strength",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Bench Press", 5, 6, 180, "Add 5lbs from Week 1 (77% 1RM)", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Tighter setup, focus on leg drive and bar path", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 8, 120, "Add 5lbs from Week 1", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Strict form, no body English at heavier weight", "Pendlay Row"),
                ex("Barbell Overhead Press", 4, 6, 150, "Add 2.5-5lbs from Week 1", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Tighter brace, clean bar path", "Seated Dumbbell Press"),
                ex("Weighted Chin-Up", 4, 6, 120, "Add 5lbs from Week 1", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Supinated grip, pull to upper chest", "Lat Pulldown"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Add 2-5lbs from Week 1", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "30-degree incline, controlled eccentric", "Incline Barbell Press"),
                ex("Cable Rear Delt Fly", 3, 15, 60, "Light-moderate, high reps", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Arms straight, squeeze shoulder blades at peak", "Face Pull"),
                ex("Hammer Curl", 3, 10, 60, "Moderate, thumbs up grip", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "advanced", "Controlled movement, no swinging", "Cable Hammer Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Strength",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 6, 180, "Add 5-10lbs from Week 1 (77% 1RM)", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Focus on speed out of the hole", "Front Squat"),
                ex("Conventional Deadlift", 4, 5, 240, "Add 5-10lbs from Week 1", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "advanced", "Maintain flat back as weight increases", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 4, 8, 120, "Add 5lbs from Week 1", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Bar close to body, big hamstring stretch", "Dumbbell Romanian Deadlift"),
                ex("Hack Squat", 4, 10, 120, "Moderate-heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Feet low on platform for quad emphasis, full depth", "Leg Press"),
                ex("Barbell Hip Thrust", 3, 10, 90, "Heavy, glute focus", "Barbell", "Legs", "Glutes", ["Hamstrings"], "advanced", "Upper back on bench, full hip extension, squeeze 2 seconds", "Dumbbell Hip Thrust"),
                ex("Standing Calf Raise", 4, 12, 60, "Heavy, controlled", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full stretch and full contraction each rep", "Seated Calf Raise"),
                ex("Decline Sit-Up", 3, 15, 60, "Bodyweight or holding plate", "Decline Bench", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Controlled movement, exhale on the way up", "Hanging Leg Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Volume",
            "type": "strength",
            "duration_minutes": 65,
            "exercises": [
                ex("Close-Grip Bench Press", 4, 8, 120, "Add 5lbs from Week 1", "Barbell", "Chest", "Triceps", ["Pectorals"], "advanced", "Elbows tucked, powerful press", "Dumbbell Close-Grip Press"),
                ex("T-Bar Row", 4, 8, 120, "Moderate-heavy, chest supported if available", "T-Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Neutral grip, pull to chest, squeeze hard", "Pendlay Row"),
                ex("Seated Dumbbell Press", 4, 8, 90, "Add 2-5lbs from Week 1", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Full range, controlled movement", "Machine Shoulder Press"),
                ex("Single-Arm Cable Row", 3, 10, 75, "Moderate, unilateral focus", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to hip, rotate slightly, squeeze", "Single-Arm Dumbbell Row"),
                ex("Cable Crossover", 3, 12, 75, "Moderate, stretch and squeeze", "Cable Machine", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Slight forward lean, hands meet below chin", "Dumbbell Fly"),
                ex("Dumbbell Lateral Raise", 3, 15, 60, "Moderate, slow negatives", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "3-second negative each rep", "Cable Lateral Raise"),
                ex("Weighted Dip", 3, 8, 90, "Add 10-25lbs", "Dip Bars", "Arms", "Triceps", ["Pectorals"], "advanced", "Upright torso, full lockout, controlled lower", "Close-Grip Bench Press")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Volume",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Front Squat", 4, 6, 150, "Add 5lbs from Week 1", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "advanced", "Elbows high, knees forward", "Goblet Squat"),
                ex("Sumo Deadlift", 4, 5, 180, "Add 5-10lbs from Week 1", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors"], "advanced", "Push knees over toes, chest up", "Conventional Deadlift"),
                ex("Walking Lunge", 4, 10, 90, "Heavy dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Long stride, upright torso", "Bulgarian Split Squat"),
                ex("Lying Leg Curl", 3, 10, 75, "Moderate-heavy, squeeze at top", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Don't lift hips, full contraction", "Nordic Curl"),
                ex("Leg Extension", 3, 12, 60, "Moderate, 2-second pause", "Machine", "Legs", "Quadriceps", [], "advanced", "Full extension, squeeze", "Sissy Squat"),
                ex("Seated Calf Raise", 4, 15, 60, "Moderate, full ROM", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Slow through full range", "Standing Calf Raise"),
                ex("Pallof Press", 3, 10, 60, "Moderate cable", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "advanced", "Press and hold 3 seconds, resist rotation", "Side Plank")
            ]
        }
    ]
}

w3 = {
    "focus": "Accumulation peak - highest volume week before transitioning to heavier loads",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Strength (Volume Peak)",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Bench Press", 5, 6, 180, "Add 5lbs from Week 2 (79% 1RM), RPE 8", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Maximize leg drive and arch, tight setup", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 5, 8, 120, "Add 5lbs from Week 2, extra set", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "5 sets this week - volume peak", "Pendlay Row"),
                ex("Barbell Overhead Press", 4, 6, 150, "Add 2.5lbs from Week 2", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Clean bar path, brace every rep", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 6, 120, "Add 5lbs from Week 2", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Dead hang, full range", "Lat Pulldown"),
                ex("Incline Barbell Press", 3, 8, 90, "Moderate-heavy", "Barbell", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "30-degree incline, lower to upper chest", "Dumbbell Incline Press"),
                ex("Face Pull", 3, 15, 60, "Moderate, prehab work", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "advanced", "High pull, external rotate, squeeze", "Band Pull-Apart"),
                ex("EZ Bar Curl", 3, 10, 60, "Moderate", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "advanced", "Controlled tempo, no swinging", "Dumbbell Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Strength (Volume Peak)",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 6, 180, "Add 5lbs from Week 2 (79% 1RM), RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Speed out of the hole, maintain brace", "Front Squat"),
                ex("Conventional Deadlift", 4, 5, 240, "Add 5-10lbs from Week 2, RPE 8", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Hook grip if possible, wedge into the bar", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 4, 8, 120, "Add 5lbs from Week 2", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Bar paints the thighs, big stretch", "Dumbbell RDL"),
                ex("Leg Press", 4, 10, 120, "Heavier than Week 2", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Full depth, don't lock knees", "Hack Squat"),
                ex("Barbell Hip Thrust", 4, 10, 90, "Add 10lbs from Week 2", "Barbell", "Legs", "Glutes", ["Hamstrings"], "advanced", "Full hip extension, hard squeeze at top", "Dumbbell Hip Thrust"),
                ex("Standing Calf Raise", 4, 12, 60, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM, pause at top and bottom", "Seated Calf Raise"),
                ex("Hanging Leg Raise", 3, 15, 60, "Bodyweight, straight legs", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Toes to bar if possible", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Volume (Peak)",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Close-Grip Bench Press", 4, 8, 120, "Add 5lbs from Week 2", "Barbell", "Chest", "Triceps", ["Pectorals"], "advanced", "Elbows tight, powerful lockout", "Dumbbell Close-Grip Press"),
                ex("Pendlay Row", 5, 6, 120, "Heavier than Week 1, explosive", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Dead stop, explosive pull each rep", "T-Bar Row"),
                ex("Push Press", 4, 6, 120, "Use leg drive to move more weight overhead", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "advanced", "Quick dip, explosive drive, lock overhead", "Seated Dumbbell Press"),
                ex("Chest-Supported Row", 4, 10, 75, "Moderate-heavy", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Chest on incline, pull to hips, pause at top", "Seated Cable Row"),
                ex("Dumbbell Chest Fly", 3, 12, 75, "Moderate, focus on stretch", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Deep stretch, squeeze at top", "Cable Crossover"),
                ex("Cable Lateral Raise", 3, 15, 60, "Light-moderate, constant tension", "Cable Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Behind the body start, raise to shoulder height", "Dumbbell Lateral Raise"),
                ex("Skull Crusher", 3, 10, 75, "Moderate, EZ bar", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "advanced", "Lower to forehead, extend fully", "Cable Overhead Extension")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Volume (Peak)",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Front Squat", 4, 6, 150, "Add 5lbs from Week 2", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "advanced", "High elbows, upright torso, deep", "Goblet Squat"),
                ex("Sumo Deadlift", 4, 5, 180, "Add 5-10lbs from Week 2", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors"], "advanced", "Push knees out, lock hips at top", "Conventional Deadlift"),
                ex("Bulgarian Split Squat", 4, 8, 90, "Heavier dumbbells than Week 1", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Deep stretch, powerful drive up", "Walking Lunge"),
                ex("Glute-Ham Raise", 4, 8, 90, "Bodyweight, add plate if possible", "GHD", "Legs", "Hamstrings", ["Glutes"], "advanced", "Slow eccentric, powerful concentric", "Nordic Curl"),
                ex("Leg Extension", 3, 15, 60, "Moderate, high reps", "Machine", "Legs", "Quadriceps", [], "advanced", "1.5 reps: full, half, full = 1 rep", "Sissy Squat"),
                ex("Seated Calf Raise", 4, 15, 60, "Moderate-heavy", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM, constant tension", "Standing Calf Raise"),
                ex("Cable Woodchop", 3, 12, 60, "Moderate, rotational core", "Cable Machine", "Core", "Obliques", ["Rectus Abdominis", "Transverse Abdominis"], "advanced", "Rotate from hips, arms follow, control return", "Russian Twist")
            ]
        }
    ]
}

# ═══════════════════════════════════════════
# PHASE 2: INTENSIFICATION (Weeks 4-6) - Heavier loads, lower reps
# ═══════════════════════════════════════════
w4 = {
    "focus": "Intensification Phase - Heavier loads (80-85% 1RM), lower reps, building toward peak strength",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Heavy",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Bench Press", 5, 4, 210, "82% 1RM, RPE 8", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Max tension setup, powerful controlled reps", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 6, 150, "77% 1RM, RPE 8", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Strict form, pull to sternum", "Pendlay Row"),
                ex("Barbell Overhead Press", 5, 4, 180, "77% 1RM, RPE 8", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Brace hard, no leg drive, strict press", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 5, 150, "Add 20-35lbs, RPE 8", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Full dead hang, chin well over bar", "Lat Pulldown"),
                ex("Dumbbell Floor Press", 3, 8, 90, "Heavy dumbbells, triceps lockout focus", "Dumbbells", "Chest", "Triceps", ["Pectorals"], "advanced", "Elbows touch floor, pause, powerful press", "Close-Grip Bench Press"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "advanced", "Shoulder health maintenance work", "Band Pull-Apart"),
                ex("Barbell Curl", 3, 8, 75, "Heavier than accumulation phase", "Barbell", "Arms", "Biceps", ["Brachialis"], "advanced", "Strict, no momentum, controlled eccentric", "EZ Bar Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Heavy",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 4, 210, "82% 1RM, RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Brace hard, controlled descent, powerful drive", "Front Squat"),
                ex("Conventional Deadlift", 4, 3, 270, "82% 1RM, RPE 8", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "advanced", "Reset between reps, perfect setup each pull", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 3, 6, 120, "70% deadlift 1RM, RPE 7", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Slower tempo, deep stretch", "Dumbbell RDL"),
                ex("Leg Press", 4, 8, 120, "Heavy, RPE 8-9", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Feet narrow for quad emphasis", "Hack Squat"),
                ex("Walking Lunge", 3, 10, 90, "Heavy dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Heavy and controlled", "Bulgarian Split Squat"),
                ex("Standing Calf Raise", 4, 10, 75, "Heavy, lower reps than accumulation", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM, squeeze hard at top", "Seated Calf Raise"),
                ex("Weighted Plank", 3, "45s", 60, "Plate on back", "Plate", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "advanced", "25-45lb plate, maintain position", "Ab Wheel Rollout")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Supplemental",
            "type": "strength",
            "duration_minutes": 65,
            "exercises": [
                ex("Paused Bench Press", 4, 4, 150, "75% 1RM, 2-second pause on chest", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "2-second pause on chest, no bounce, strong press", "Spoto Press"),
                ex("Pendlay Row", 4, 5, 120, "Heavy, explosive", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Dead stop, maximal effort pull", "T-Bar Row"),
                ex("Push Press", 4, 5, 120, "Heavier than strict press - use leg drive", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "advanced", "Aggressive dip-drive, lock overhead", "Seated Dumbbell Press"),
                ex("Weighted Chin-Up", 4, 5, 120, "Heavier than Week 3", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Full range, supinated grip", "Lat Pulldown"),
                ex("Dumbbell Incline Press", 3, 8, 90, "Heavy dumbbells", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "Controlled movement, heavy and strict", "Incline Barbell Press"),
                ex("Cable Rear Delt Fly", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "High reps for shoulder health", "Face Pull"),
                ex("Weighted Dip", 3, 6, 120, "Add 25-45lbs, RPE 8", "Dip Bars", "Arms", "Triceps", ["Pectorals"], "advanced", "Upright for triceps, deep for chest", "Close-Grip Bench Press")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Supplemental",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Paused Back Squat", 4, 4, 180, "75% 1RM, 2-second pause in the hole", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "2-second pause at parallel, stay tight, drive up", "Front Squat"),
                ex("Deficit Deadlift", 4, 4, 210, "70% 1RM, stand on 1-2 inch platform", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "advanced", "Increases range of motion, builds off-the-floor strength", "Conventional Deadlift"),
                ex("Bulgarian Split Squat", 3, 8, 90, "Heavy dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Deep stretch, powerful drive", "Walking Lunge"),
                ex("Glute-Ham Raise", 4, 8, 90, "Add band or hold plate", "GHD", "Legs", "Hamstrings", ["Glutes"], "advanced", "Controlled eccentric, powerful pull", "Nordic Curl"),
                ex("Leg Extension", 3, 10, 60, "Heavy, controlled", "Machine", "Legs", "Quadriceps", [], "advanced", "Full lockout, 2-second hold", "Sissy Squat"),
                ex("Seated Calf Raise", 4, 12, 60, "Heavy", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM, slow tempo", "Standing Calf Raise"),
                ex("Hanging Leg Raise", 3, 12, 60, "Straight legs, controlled", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "No swinging, squeeze at top", "Lying Leg Raise")
            ]
        }
    ]
}

w5 = {
    "focus": "Intensification continued - pushing loads higher with RPE 8-9",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Heavy",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Bench Press", 5, 3, 240, "85% 1RM, RPE 8-9", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Triple territory - maximize tension, powerful reps", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 5, 150, "80% 1RM, RPE 8-9", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Heavy but strict, no cheating", "Pendlay Row"),
                ex("Barbell Overhead Press", 5, 3, 180, "80% 1RM, RPE 8-9", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Tight brace, strict press, heavy triples", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 4, 150, "Heavy, add 30-40lbs, RPE 8-9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Full range, controlled eccentric", "Lat Pulldown"),
                ex("Board Press / Pin Press", 3, 5, 120, "85-90% bench 1RM, lockout focus", "Barbell", "Chest", "Triceps", ["Pectorals", "Anterior Deltoids"], "advanced", "Reduced ROM to overload lockout", "Close-Grip Bench Press"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Shoulder health, never skip", "Band Pull-Apart"),
                ex("Hammer Curl", 3, 8, 60, "Heavy, strict", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "advanced", "No swinging, controlled tempo", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Heavy",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 3, 240, "85% 1RM, RPE 8-9", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Heavy triples, brace hard, controlled descent", "Front Squat"),
                ex("Conventional Deadlift", 4, 3, 270, "85% 1RM, RPE 8-9", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Reset each rep, perfect setup, full lockout", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 3, 6, 120, "72% deadlift 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Heavier but maintain stretch and form", "Dumbbell RDL"),
                ex("Hack Squat", 4, 8, 120, "Heavy, RPE 9", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Push hard, full depth", "Leg Press"),
                ex("Single-Leg Leg Press", 3, 8, 90, "Moderate-heavy, each leg", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Single leg for balance and weakness correction", "Bulgarian Split Squat"),
                ex("Standing Calf Raise", 4, 10, 75, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Slow tempo, full ROM", "Seated Calf Raise"),
                ex("Ab Wheel Rollout", 3, 10, 60, "Standing if possible, or from knees with full extension", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Erector Spinae"], "advanced", "Full extension, controlled return", "Weighted Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Supplemental",
            "type": "strength",
            "duration_minutes": 65,
            "exercises": [
                ex("Spoto Press", 4, 4, 150, "80% bench 1RM, stop 1 inch off chest", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Lower to 1 inch off chest, hold, press - builds bottom end strength", "Paused Bench Press"),
                ex("Chest-Supported Row", 4, 8, 90, "Heavy dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Strict, no body english, squeeze at top", "Seated Cable Row"),
                ex("Z Press", 4, 5, 120, "Seated on floor, no back support - core demand", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Core"], "advanced", "Sit on floor, legs extended, strict press", "Seated Dumbbell Press"),
                ex("Meadows Row", 3, 8, 75, "Heavy, single arm, landmine setup", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Rear Deltoids"], "advanced", "Staggered stance, pull to hip, squeeze hard", "Single-Arm Dumbbell Row"),
                ex("Incline Barbell Press", 3, 6, 90, "Heavy", "Barbell", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "30-degree incline, controlled and heavy", "Dumbbell Incline Press"),
                ex("Cable Lateral Raise", 3, 12, 60, "Moderate, constant tension", "Cable Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Behind body start for stretch", "Dumbbell Lateral Raise"),
                ex("Skull Crusher", 3, 8, 75, "Heavy EZ bar", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "advanced", "Lower to forehead, extend fully, heavy", "Cable Overhead Extension")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Supplemental",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Safety Bar Squat / High Bar Squat", 4, 5, 150, "75% back squat 1RM, RPE 8", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings", "Core"], "advanced", "High bar or safety bar for quad emphasis and back relief", "Front Squat"),
                ex("Block Pull / Rack Pull", 4, 3, 180, "90% deadlift 1RM, pull from blocks/pins at knee height", "Barbell", "Legs", "Glutes", ["Hamstrings", "Erector Spinae"], "advanced", "Overloads lockout, heavier than full range deadlift", "Conventional Deadlift"),
                ex("Barbell Hip Thrust", 4, 8, 90, "Heavy, RPE 8-9", "Barbell", "Legs", "Glutes", ["Hamstrings"], "advanced", "Full extension, hard 2-second squeeze", "Dumbbell Hip Thrust"),
                ex("Nordic Curl", 3, 6, 90, "Bodyweight, eccentric focus", "None", "Legs", "Hamstrings", ["Calves"], "advanced", "Slow 5-second eccentric, use hands to assist concentric if needed", "Glute-Ham Raise"),
                ex("Leg Extension", 3, 10, 60, "Heavy, controlled", "Machine", "Legs", "Quadriceps", [], "advanced", "Full lockout, slow eccentric", "Sissy Squat"),
                ex("Standing Calf Raise", 4, 10, 75, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM, 1-second holds", "Seated Calf Raise"),
                ex("Dragon Flag", 3, 6, 75, "Bodyweight, advanced core", "Bench", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "Lower body as single lever, don't pike at hips", "Hanging Leg Raise")
            ]
        }
    ]
}

w6 = {
    "focus": "Intensification peak - highest loads before deload, RPE 9",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Heavy (Peak Intensity)",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Bench Press", 5, 3, 240, "87% 1RM, RPE 9 - heaviest accumulation yet", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Everything tight, leave nothing on the table", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 5, 150, "82% 1RM, RPE 9", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Heavy but form stays strict", "Pendlay Row"),
                ex("Barbell Overhead Press", 5, 3, 180, "82% 1RM, RPE 9", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Heavy triples, brace and press", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 4, 150, "Heaviest yet, RPE 9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Full range, heavy and controlled", "Lat Pulldown"),
                ex("Dumbbell Floor Press", 3, 6, 90, "Heavy dumbbells", "Dumbbells", "Chest", "Triceps", ["Pectorals"], "advanced", "Pause on floor, explosive press", "Close-Grip Bench Press"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab, always include", "Band Pull-Apart"),
                ex("EZ Bar Curl", 3, 8, 60, "Heavy, strict", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "advanced", "Heavy curls, no momentum", "Dumbbell Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Heavy (Peak Intensity)",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 5, 3, 240, "87% 1RM, RPE 9", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Heaviest triples yet, stay tight, drive through", "Front Squat"),
                ex("Conventional Deadlift", 4, 2, 300, "87% 1RM, RPE 9, heavy doubles", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Heavy doubles, perfect setup each rep", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 3, 6, 120, "75% deadlift 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes"], "advanced", "Maintain stretch quality at heavier loads", "Dumbbell RDL"),
                ex("Leg Press", 4, 6, 150, "Very heavy, RPE 9", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Heavy and deep, don't cheat ROM", "Hack Squat"),
                ex("Walking Lunge", 3, 10, 90, "Heavy dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Heavy, controlled steps", "Bulgarian Split Squat"),
                ex("Standing Calf Raise", 4, 8, 90, "Very heavy, low reps", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM even at heaviest loads", "Seated Calf Raise"),
                ex("Weighted Plank", 3, "60s", 60, "45-55lb plate on back", "Plate", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Heavy loaded plank, full body tension", "Ab Wheel Rollout")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Supplemental (Peak)",
            "type": "strength",
            "duration_minutes": 65,
            "exercises": [
                ex("Paused Bench Press", 4, 3, 150, "80% 1RM, 3-second pause", "Barbell", "Chest", "Pectorals", ["Triceps"], "advanced", "Longer pause this week, build bottom strength", "Spoto Press"),
                ex("T-Bar Row", 4, 6, 120, "Heavy", "T-Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Chest supported if available, heavy pulls", "Pendlay Row"),
                ex("Push Press", 4, 4, 120, "Heavier than Week 3, aggressive drive", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "advanced", "Quick dip, explosive leg drive, lock out", "Seated Dumbbell Press"),
                ex("Weighted Chin-Up", 4, 4, 120, "Heaviest yet, RPE 9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Full range, heavy", "Lat Pulldown"),
                ex("Cable Crossover", 3, 12, 75, "Moderate, pump work", "Cable Machine", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Squeeze hard at contraction", "Dumbbell Fly"),
                ex("Dumbbell Lateral Raise", 3, 12, 60, "Moderate", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Controlled reps, shoulder health", "Cable Lateral Raise"),
                ex("Weighted Dip", 3, 5, 120, "Heaviest yet, 35-55lbs", "Dip Bars", "Arms", "Triceps", ["Pectorals"], "advanced", "Heavy weighted dips, full lockout", "Close-Grip Bench Press")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Supplemental (Peak)",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Paused Back Squat", 4, 3, 180, "80% 1RM, 3-second pause at depth", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Longer pause, build strength out of the hole", "Front Squat"),
                ex("Deficit Deadlift", 4, 3, 210, "75% 1RM, 2-inch deficit", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Builds off-the-floor speed and strength", "Conventional Deadlift"),
                ex("Barbell Hip Thrust", 4, 6, 90, "Very heavy", "Barbell", "Legs", "Glutes", ["Hamstrings"], "advanced", "Full extension, 3-second squeeze at top", "Dumbbell Hip Thrust"),
                ex("Nordic Curl", 3, 5, 90, "Bodyweight, 5-second eccentric", "None", "Legs", "Hamstrings", ["Calves"], "advanced", "Slow and controlled eccentric, use hands for concentric", "Glute-Ham Raise"),
                ex("Leg Extension", 3, 8, 60, "Heavy, controlled", "Machine", "Legs", "Quadriceps", [], "advanced", "Heavy singles at the top, slow eccentric", "Sissy Squat"),
                ex("Seated Calf Raise", 4, 10, 60, "Heavy", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM, constant tension", "Standing Calf Raise"),
                ex("Hanging Leg Raise", 3, 12, 60, "Toes to bar if possible", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Controlled, no kipping", "Lying Leg Raise")
            ]
        }
    ]
}

# ═══════════════════════════════════════════
# PHASE 3: DELOAD + REALIZATION (Weeks 7-9)
# ═══════════════════════════════════════════
w7 = {
    "focus": "Deload week - reduce volume 40%, reduce intensity 10-15%, active recovery for next push",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Deload",
            "type": "strength",
            "duration_minutes": 50,
            "exercises": [
                ex("Barbell Bench Press", 3, 5, 150, "70% 1RM, easy reps, focus on speed", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Fast, crisp reps, should feel easy", "Dumbbell Bench Press"),
                ex("Barbell Row", 3, 6, 90, "65% 1RM, smooth reps", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Light and controlled, feel the muscle", "Cable Row"),
                ex("Barbell Overhead Press", 3, 5, 120, "65% 1RM, fast reps", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Light and snappy", "Dumbbell Shoulder Press"),
                ex("Pull-Up", 3, 6, 90, "Bodyweight only", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Easy bodyweight reps", "Lat Pulldown"),
                ex("Face Pull", 3, 15, 60, "Light", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab and recovery", "Band Pull-Apart"),
                ex("Dumbbell Curl", 2, 12, 60, "Light, pump work", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Light, get blood flowing", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Deload",
            "type": "strength",
            "duration_minutes": 50,
            "exercises": [
                ex("Barbell Back Squat", 3, 5, 150, "70% 1RM, easy and fast", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Fast out of the hole, crisp reps", "Goblet Squat"),
                ex("Conventional Deadlift", 3, 3, 180, "70% 1RM, speed pulls", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Speed focus, quick off the floor", "Romanian Deadlift"),
                ex("Leg Press", 3, 10, 90, "Moderate, easy", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Light, get blood flowing", "Goblet Squat"),
                ex("Lying Leg Curl", 3, 10, 60, "Light, pump work", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Easy reps, promote recovery", "Dumbbell RDL"),
                ex("Calf Raise", 3, 12, 60, "Moderate", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM, light and easy", "Seated Calf Raise"),
                ex("Plank", 3, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Easy core work", "Dead Bug")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Light",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Dumbbell Bench Press", 3, 10, 75, "Light-moderate", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "advanced", "Pump work, feel the muscle", "Push-Up"),
                ex("Seated Cable Row", 3, 10, 75, "Light-moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Squeeze and stretch, mind-muscle", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 15, 45, "Light", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Light pump, shoulder health", "Cable Lateral Raise"),
                ex("Cable Crossover", 3, 12, 60, "Light", "Cable Machine", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Easy pump work", "Dumbbell Fly"),
                ex("Cable Triceps Pushdown", 2, 15, 60, "Light pump", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "advanced", "Easy reps, blood flow", "Dumbbell Kickback"),
                ex("Dumbbell Hammer Curl", 2, 12, 60, "Light", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Easy, recovery focused", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Light",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Goblet Squat", 3, 12, 75, "Moderate dumbbell, easy", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "advanced", "Light, focus on mobility and depth", "Bodyweight Squat"),
                ex("Dumbbell Romanian Deadlift", 3, 10, 75, "Moderate", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "advanced", "Light, feel the stretch", "Lying Leg Curl"),
                ex("Leg Extension", 3, 12, 60, "Light, pump work", "Machine", "Legs", "Quadriceps", [], "advanced", "Easy, blood flow", "Bodyweight Squat"),
                ex("Lying Leg Curl", 3, 12, 60, "Light", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Easy reps, promote recovery", "Swiss Ball Curl"),
                ex("Seated Calf Raise", 3, 15, 45, "Light", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM, easy", "Standing Calf Raise"),
                ex("Dead Bug", 3, 10, 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Easy core work, recovery focus", "Plank")
            ]
        }
    ]
}

w8 = {
    "focus": "Realization Phase - Moderate volume, heavy singles/doubles practice, building toward peak",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Realization",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Bench Press", 5, 2, 270, "88-90% 1RM, RPE 8-9, heavy doubles", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Work up to heavy doubles, focus on maximal tension", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 5, 150, "80% 1RM, RPE 8", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Heavy and strict", "Pendlay Row"),
                ex("Barbell Overhead Press", 5, 2, 210, "85-87% 1RM, heavy doubles", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Heavy doubles, brace hard", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 4, 3, 150, "Very heavy, RPE 8-9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Heavy triples, full range", "Lat Pulldown"),
                ex("Close-Grip Bench Press", 3, 6, 120, "75% bench 1RM, triceps overload", "Barbell", "Chest", "Triceps", ["Pectorals"], "advanced", "Heavy lockout work", "Dumbbell Close-Grip Press"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Always include for shoulder health", "Band Pull-Apart")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Realization",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Back Squat", 5, 2, 270, "88-90% 1RM, RPE 8-9, heavy doubles", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Work up to heavy doubles, practice being under heavy weight", "Front Squat"),
                ex("Conventional Deadlift", 4, 2, 300, "88-90% 1RM, heavy doubles", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Heavy doubles, reset between reps", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 3, 6, 120, "70% deadlift 1RM, moderate", "Barbell", "Legs", "Hamstrings", ["Glutes"], "advanced", "Keep volume low, maintain posterior chain", "Dumbbell RDL"),
                ex("Leg Press", 3, 8, 120, "Heavy but less volume", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Quality reps, not junk volume", "Hack Squat"),
                ex("Walking Lunge", 3, 8, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Light assistance work", "Bulgarian Split Squat"),
                ex("Calf Raise", 3, 10, 60, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Maintain calf strength", "Seated Calf Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Supplemental",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Paused Bench Press", 4, 3, 150, "82% 1RM, 2-second pause, heavy", "Barbell", "Chest", "Pectorals", ["Triceps"], "advanced", "Heavy paused work, builds competition strength", "Spoto Press"),
                ex("Pendlay Row", 4, 4, 120, "Heavy, explosive", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Heavy, explosive pulls from dead stop", "T-Bar Row"),
                ex("Push Press", 3, 3, 150, "Heavier than strict - use leg drive for overload", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Quadriceps"], "advanced", "Heavy overload work", "Seated Dumbbell Press"),
                ex("Weighted Chin-Up", 3, 4, 120, "Heavy, RPE 8-9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Full ROM, heavy", "Lat Pulldown"),
                ex("Dumbbell Incline Press", 3, 6, 90, "Heavy dumbbells", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "Heavy, strict, controlled", "Incline Barbell Press"),
                ex("Weighted Dip", 3, 5, 120, "Heavy, 35-55lbs", "Dip Bars", "Arms", "Triceps", ["Pectorals"], "advanced", "Heavy lockout work", "Close-Grip Bench Press")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Supplemental",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Front Squat", 4, 3, 180, "75% back squat 1RM, heavy triples", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "advanced", "Heavy front squats, maintain upright", "Goblet Squat"),
                ex("Block Pull", 3, 2, 210, "92-95% deadlift 1RM, supramaximal lockout", "Barbell", "Legs", "Glutes", ["Hamstrings", "Erector Spinae"], "advanced", "Heavier than full deadlift, builds lockout", "Rack Pull"),
                ex("Bulgarian Split Squat", 3, 6, 90, "Moderate-heavy", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "advanced", "Maintain single-leg strength", "Walking Lunge"),
                ex("Glute-Ham Raise", 3, 6, 90, "Bodyweight or light plate", "GHD", "Legs", "Hamstrings", ["Glutes"], "advanced", "Maintain posterior chain", "Nordic Curl"),
                ex("Calf Raise", 3, 10, 60, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full ROM", "Seated Calf Raise"),
                ex("Ab Wheel Rollout", 3, 8, 60, "Standing or kneeling", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Maintain core strength", "Plank")
            ]
        }
    ]
}

w9 = {
    "focus": "Realization continued - practicing heavy singles at 90-93% to prepare for testing week",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper (Heavy Singles Practice)",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Bench Press", 5, 1, 300, "90-93% 1RM, heavy singles x 5 sets, RPE 9", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Practice singles - setup, unrack, descend, press. Competition-style", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 3, 5, 150, "80% 1RM, maintain back strength", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Heavy and strict", "Pendlay Row"),
                ex("Barbell Overhead Press", 4, 1, 240, "90-93% 1RM, heavy singles practice", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Heavy singles, brace maximally", "Seated Dumbbell Press"),
                ex("Weighted Pull-Up", 3, 3, 150, "Heavy, RPE 8-9", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Maintain pulling strength", "Lat Pulldown"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Shoulder health", "Band Pull-Apart"),
                ex("Cable Triceps Pushdown", 3, 10, 60, "Moderate, pump", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "advanced", "Light pump work only", "Dumbbell Kickback")
            ]
        },
        {
            "workout_name": "Day 2 - Lower (Heavy Singles Practice)",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Barbell Back Squat", 5, 1, 300, "90-93% 1RM, heavy singles x 5, RPE 9", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Practice heavy singles, setup and walkout are critical", "Front Squat"),
                ex("Conventional Deadlift", 4, 1, 300, "90-93% 1RM, heavy singles", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Practice heavy pulls, perfect setup each rep", "Sumo Deadlift"),
                ex("Leg Press", 3, 8, 120, "Moderate, assistance work", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Keep quad volume but don't overdo it", "Hack Squat"),
                ex("Lying Leg Curl", 3, 8, 75, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Maintain hamstring strength", "Dumbbell RDL"),
                ex("Calf Raise", 3, 10, 60, "Heavy", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Maintain", "Seated Calf Raise"),
                ex("Hanging Leg Raise", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Controlled, maintain core", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Light",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Close-Grip Bench Press", 3, 6, 120, "72% bench 1RM, lockout work", "Barbell", "Chest", "Triceps", ["Pectorals"], "advanced", "Moderate load, lockout focus", "Dumbbell Close-Grip Press"),
                ex("Seated Cable Row", 3, 10, 90, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Moderate, maintain back mass", "Dumbbell Row"),
                ex("Seated Dumbbell Press", 3, 8, 90, "Moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Moderate volume, don't fatigue before testing", "Machine Shoulder Press"),
                ex("Chest-Supported Row", 3, 10, 75, "Moderate", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Strict, controlled", "Cable Row"),
                ex("Cable Lateral Raise", 3, 12, 60, "Light-moderate", "Cable Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Maintenance work", "Dumbbell Lateral Raise"),
                ex("Dumbbell Curl", 2, 10, 60, "Light-moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Easy pump", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Light",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Front Squat", 3, 4, 150, "70% back squat 1RM, stay sharp", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "advanced", "Keep groove but don't fatigue", "Goblet Squat"),
                ex("Dumbbell Romanian Deadlift", 3, 8, 90, "Moderate", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "advanced", "Maintain posterior chain", "Lying Leg Curl"),
                ex("Leg Extension", 3, 10, 60, "Moderate", "Machine", "Legs", "Quadriceps", [], "advanced", "Light quad work", "Bodyweight Squat"),
                ex("Lying Leg Curl", 3, 10, 60, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Maintain hamstring health", "Swiss Ball Curl"),
                ex("Seated Calf Raise", 3, 12, 60, "Moderate", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM", "Standing Calf Raise"),
                ex("Plank", 3, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Easy core work", "Dead Bug")
            ]
        }
    ]
}

# ═══════════════════════════════════════════
# PHASE 4: PEAK & TEST (Weeks 10-12)
# ═══════════════════════════════════════════
w10 = {
    "focus": "Taper week 1 - further reduce volume, maintain intensity with openers",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper Taper",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Bench Press", 3, 2, 240, "85-88% 1RM, opener practice", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Practice competition-style setup and commands", "Dumbbell Bench Press"),
                ex("Barbell Row", 3, 5, 120, "75% 1RM, maintain", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Moderate, maintain back", "Cable Row"),
                ex("Barbell Overhead Press", 3, 2, 210, "85% 1RM, stay sharp", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Opener practice for OHP", "Dumbbell Shoulder Press"),
                ex("Pull-Up", 3, 5, 90, "Bodyweight, easy", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Easy reps, maintain", "Lat Pulldown"),
                ex("Face Pull", 3, 15, 60, "Light", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab", "Band Pull-Apart"),
                ex("Cable Curl", 2, 12, 60, "Light pump", "Cable Machine", "Arms", "Biceps", ["Brachialis"], "advanced", "Easy, blood flow", "Dumbbell Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower Taper",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 3, 2, 240, "85-88% 1RM, opener practice", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Practice walkout and descent with heavy weight", "Front Squat"),
                ex("Conventional Deadlift", 3, 1, 270, "88-90% 1RM, practice openers", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Practice setup and pull with near-max weight", "Sumo Deadlift"),
                ex("Leg Press", 3, 8, 90, "Moderate, easy", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Light assistance, don't fatigue", "Goblet Squat"),
                ex("Lying Leg Curl", 3, 10, 60, "Light", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Blood flow, recovery", "Dumbbell RDL"),
                ex("Calf Raise", 3, 12, 60, "Moderate", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Maintain", "Seated Calf Raise"),
                ex("Dead Bug", 3, 10, 45, "Bodyweight, easy", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light core, don't fatigue", "Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Upper Light Maintenance",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Dumbbell Bench Press", 3, 8, 75, "Light-moderate, pump", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "advanced", "Easy pump work", "Push-Up"),
                ex("Seated Cable Row", 3, 8, 75, "Light-moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Easy, maintain", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 45, "Light", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Light, shoulder health", "Cable Lateral Raise"),
                ex("Face Pull", 3, 15, 45, "Light", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab", "Band Pull-Apart"),
                ex("Dumbbell Curl", 2, 10, 60, "Light", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Easy pump", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 4 - Lower Light Maintenance",
            "type": "strength",
            "duration_minutes": 40,
            "exercises": [
                ex("Goblet Squat", 3, 10, 75, "Light, mobility work", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "advanced", "Easy, focus on depth and mobility", "Bodyweight Squat"),
                ex("Dumbbell Romanian Deadlift", 3, 8, 75, "Light", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "advanced", "Easy, maintain flexibility", "Lying Leg Curl"),
                ex("Leg Extension", 2, 12, 60, "Light", "Machine", "Legs", "Quadriceps", [], "advanced", "Blood flow", "Bodyweight Squat"),
                ex("Lying Leg Curl", 2, 12, 60, "Light", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Blood flow", "Swiss Ball Curl"),
                ex("Plank", 2, "30s", 45, "Bodyweight, easy", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light, maintain", "Dead Bug")
            ]
        }
    ]
}

w11 = {
    "focus": "Final taper - minimal volume, a few heavy singles to stay primed for max testing",
    "workouts": [
        {
            "workout_name": "Day 1 - Upper (Final Taper)",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Barbell Bench Press", 3, 1, 300, "90-92% 1RM, final heavy singles before test", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "3 singles to stay primed, not to fatigue", "Dumbbell Bench Press"),
                ex("Barbell Overhead Press", 3, 1, 240, "87-90% 1RM, stay sharp", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Few heavy singles, don't grind", "Dumbbell Shoulder Press"),
                ex("Pull-Up", 3, 5, 75, "Bodyweight, easy", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Easy, maintain back", "Lat Pulldown"),
                ex("Face Pull", 2, 15, 60, "Light", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab", "Band Pull-Apart"),
                ex("Dumbbell Curl", 2, 10, 60, "Light pump", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Easy", "Cable Curl")
            ]
        },
        {
            "workout_name": "Day 2 - Lower (Final Taper)",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Barbell Back Squat", 3, 1, 300, "90-92% 1RM, final heavy singles", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Stay primed, not fatigue", "Front Squat"),
                ex("Conventional Deadlift", 2, 1, 300, "88-90% 1RM, 2 singles", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Just enough to stay sharp", "Sumo Deadlift"),
                ex("Leg Press", 2, 8, 90, "Light, blood flow", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Easy", "Goblet Squat"),
                ex("Lying Leg Curl", 2, 10, 60, "Light", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Easy", "Dumbbell RDL"),
                ex("Plank", 2, "30s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light", "Dead Bug")
            ]
        },
        {
            "workout_name": "Day 3 - Rest/Light Mobility",
            "type": "strength",
            "duration_minutes": 30,
            "exercises": [
                ex("Goblet Squat", 2, 8, 60, "Very light, mobility", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "advanced", "Depth practice, light", "Bodyweight Squat"),
                ex("Push-Up", 2, 10, 60, "Bodyweight, easy", "None", "Chest", "Pectorals", ["Triceps"], "advanced", "Blood flow to pressing muscles", "Knee Push-Up"),
                ex("Band Pull-Apart", 2, 15, 45, "Light band", "Resistance Band", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Shoulder health", "Face Pull"),
                ex("Bodyweight Lunge", 2, 10, 60, "Bodyweight only", "None", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Easy, blood flow to legs", "Walking in Place"),
                ex("Dead Bug", 2, 8, 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light core activation", "Plank")
            ]
        },
        {
            "workout_name": "Day 4 - Rest Day (Optional Light Walk)",
            "type": "strength",
            "duration_minutes": 20,
            "exercises": [
                ex("Foam Rolling - Full Body", 1, "5min", 0, "Bodyweight", "Foam Roller", "Full Body", "Fascia", ["All Muscles"], "advanced", "Roll quads, hamstrings, glutes, upper back, lats", "Stretching"),
                ex("Cat-Cow Stretch", 2, 10, 30, "Bodyweight", "None", "Core", "Erector Spinae", ["Rectus Abdominis"], "advanced", "Gentle spinal mobility", "Child's Pose"),
                ex("Hip 90/90 Stretch", 2, "30s", 30, "Bodyweight, each side", "None", "Legs", "Hip Flexors", ["Glutes", "Adductors"], "advanced", "Open hips for squats and deadlifts", "Pigeon Stretch"),
                ex("Band Shoulder Dislocates", 2, 10, 30, "Light band", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids"], "advanced", "Gentle shoulder mobility", "Arm Circles"),
                ex("Deep Breathing / Box Breathing", 1, "3min", 0, "N/A", "None", "Core", "Diaphragm", ["Intercostals"], "advanced", "4 seconds in, 4 hold, 4 out, 4 hold - calm nervous system", "Meditation")
            ]
        }
    ]
}

w12 = {
    "focus": "MAX TESTING WEEK - Attempt new 1RM on all major lifts. Full rest between test days.",
    "workouts": [
        {
            "workout_name": "Day 1 - Squat 1RM Test",
            "type": "strength",
            "duration_minutes": 75,
            "exercises": [
                ex("Barbell Back Squat", 7, 1, 300, "Warmup: bar x5, 50% x3, 65% x2, 77% x1, 85% x1, 92% x1, 100%+ x1 (new 1RM attempt)", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Full warmup pyramid, take 2 attempts at a new max if first attempt succeeds", "Front Squat"),
                ex("Leg Press", 3, 8, 90, "Moderate, backoff work", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Light backoff after max testing, don't push hard", "Goblet Squat"),
                ex("Lying Leg Curl", 3, 10, 60, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Easy assistance work", "Dumbbell RDL"),
                ex("Calf Raise", 3, 12, 60, "Moderate", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Maintain", "Seated Calf Raise"),
                ex("Plank", 2, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light core", "Dead Bug")
            ]
        },
        {
            "workout_name": "Day 2 - Bench & OHP 1RM Test",
            "type": "strength",
            "duration_minutes": 80,
            "exercises": [
                ex("Barbell Bench Press", 7, 1, 300, "Warmup: bar x5, 50% x3, 65% x2, 77% x1, 85% x1, 92% x1, 100%+ x1 (new 1RM attempt)", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Full warmup pyramid, take 2 attempts at new max", "Dumbbell Bench Press"),
                ex("Barbell Overhead Press", 6, 1, 240, "Warmup: bar x5, 50% x3, 65% x2, 80% x1, 90% x1, 100%+ x1 (new 1RM)", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Test OHP after bench, take 2 max attempts", "Seated Dumbbell Press"),
                ex("Lat Pulldown", 3, 10, 75, "Moderate, easy backoff", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Light pulling to balance pressing", "Pull-Up"),
                ex("Face Pull", 3, 15, 60, "Light, shoulder health", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Prehab after heavy pressing", "Band Pull-Apart")
            ]
        },
        {
            "workout_name": "Day 3 - Deadlift 1RM Test",
            "type": "strength",
            "duration_minutes": 70,
            "exercises": [
                ex("Conventional Deadlift", 7, 1, 300, "Warmup: 135x3, 50% x3, 65% x2, 77% x1, 85% x1, 92% x1, 100%+ x1 (new 1RM attempt)", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "advanced", "Full warmup, take 2-3 max attempts, belt up for heavy singles", "Sumo Deadlift"),
                ex("Barbell Romanian Deadlift", 3, 8, 90, "Light backoff, 50% deadlift 1RM", "Barbell", "Legs", "Hamstrings", ["Glutes"], "advanced", "Light, don't push hard after max testing", "Dumbbell RDL"),
                ex("Pull-Up", 3, 8, 75, "Bodyweight, easy", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Light pulling work", "Lat Pulldown"),
                ex("Calf Raise", 3, 12, 60, "Moderate", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Maintain", "Seated Calf Raise"),
                ex("Hanging Leg Raise", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques"], "advanced", "Light core to finish", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 4 - Celebration & Accessory Day",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Weighted Pull-Up", 3, 5, 120, "Test max reps or weighted max", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Fun pull-up test to cap off the program", "Lat Pulldown"),
                ex("Weighted Dip", 3, 5, 120, "Test max reps or weighted max", "Dip Bars", "Chest", "Triceps", ["Pectorals"], "advanced", "Fun dip test", "Close-Grip Bench Press"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Moderate, pump", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "Fun pump work", "Incline Push-Up"),
                ex("Seated Cable Row", 3, 10, 75, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Solid back pump", "Dumbbell Row"),
                ex("Barbell Curl", 3, 10, 60, "Moderate", "Barbell", "Arms", "Biceps", ["Brachialis"], "advanced", "Curl for the girls (or guys)", "Dumbbell Curl"),
                ex("Skull Crusher", 3, 10, 60, "Moderate", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "advanced", "Triceps pump to celebrate", "Cable Pushdown")
            ]
        }
    ]
}

weeks_data = {
    (12, 4): {1: w1, 2: w2, 3: w3, 4: w4, 5: w5, 6: w6, 7: w7, 8: w8, 9: w9, 10: w10, 11: w11, 12: w12}
}

success = helper.insert_full_program(
    program_name="Ultimate Strength",
    category_name="Strength",
    description="An advanced 12-week periodized strength program with 4 distinct phases: Accumulation (volume), Intensification (heavy loads), Realization (heavy singles practice), and Peak Testing (1RM attempts). Uses upper/lower split with competition-style lift preparation.",
    durations=[12],
    sessions_per_week=[4],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
print(f"Ultimate Strength: {'SUCCESS' if success else 'FAILED'}")
helper.update_tracker("Ultimate Strength", "Done" if success else "Failed")
helper.close()
