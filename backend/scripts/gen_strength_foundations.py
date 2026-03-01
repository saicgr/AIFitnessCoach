#!/usr/bin/env python3
"""Generate Strength Foundations - Beginner, 8w, 3x/wk"""
import sys
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()
migration_num = helper.get_next_migration_num()

def ex(name, sets, reps, rest, weight, equip, body, primary, secondary, diff, cue, sub, breathing=None, setup=None):
    e = {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest, "weight_guidance": weight,
        "equipment": equip, "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub
    }
    if breathing: e["breathing_cue"] = breathing
    if setup: e["setup"] = setup
    return e

# ─── 2-week variant (3x/wk) ───
w2 = {
    1: {
        "focus": "Movement pattern introduction - learning proper form on fundamental lifts with light loads",
        "workouts": [
            {
                "workout_name": "Day 1 - Full Body A",
                "type": "strength",
                "duration_minutes": 45,
                "exercises": [
                    ex("Goblet Squat", 3, 10, 90, "Light dumbbell, focus on depth and form", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Chest up, elbows inside knees at bottom, push knees out", "Bodyweight Squat", "Inhale down, exhale up", "Hold dumbbell at chest, feet shoulder width"),
                    ex("Dumbbell Bench Press", 3, 10, 90, "Light dumbbells, control the movement", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Lower to chest level, press straight up, squeeze at top", "Push-Up", "Inhale down, exhale press", "Flat bench, feet flat on floor"),
                    ex("Dumbbell Bent-Over Row", 3, 10, 90, "Light to moderate, feel the back working", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge at hips 45 degrees, pull elbows back, squeeze shoulder blades", "Seated Cable Row", "Exhale on pull, inhale on lower"),
                    ex("Dumbbell Shoulder Press", 3, 10, 75, "Light dumbbells, full range of motion", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Press straight overhead, don't arch back excessively", "Lateral Raise", "Exhale press, inhale lower"),
                    ex("Bodyweight Romanian Deadlift", 3, 10, 60, "Bodyweight only, practice the hip hinge", "None", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Slight knee bend, push hips back, feel hamstring stretch", "Lying Leg Curl"),
                    ex("Plank", 3, "30s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Straight line from head to heels, squeeze glutes and brace core", "Dead Bug")
                ]
            },
            {
                "workout_name": "Day 2 - Full Body B",
                "type": "strength",
                "duration_minutes": 45,
                "exercises": [
                    ex("Bodyweight Squat", 3, 15, 60, "Bodyweight, practice depth", "None", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Sit back, chest up, knees track over toes", "Wall Sit"),
                    ex("Push-Up (Incline if needed)", 3, 10, 75, "Bodyweight, use elevated surface if needed", "None", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Body straight, lower chest to surface, full extension", "Knee Push-Up"),
                    ex("Lat Pulldown", 3, 10, 90, "Light weight, focus on pulling with lats", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoids"], "beginner", "Lean slightly back, pull to upper chest, squeeze lats", "Resistance Band Pulldown"),
                    ex("Dumbbell Lateral Raise", 3, 12, 60, "Very light, control the movement", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "Slight bend in elbows, raise to shoulder height, slow lower", "Cable Lateral Raise"),
                    ex("Dumbbell Step-Up", 3, 10, 75, "Light dumbbells or bodyweight", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Drive through lead foot, full hip extension at top", "Leg Press"),
                    ex("Dead Bug", 3, 10, 45, "Bodyweight, slow and controlled", "None", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Press lower back into floor, extend opposite arm and leg slowly", "Bird Dog")
                ]
            },
            {
                "workout_name": "Day 3 - Full Body C",
                "type": "strength",
                "duration_minutes": 45,
                "exercises": [
                    ex("Dumbbell Sumo Squat", 3, 12, 90, "Light dumbbell, wide stance", "Dumbbell", "Legs", "Quadriceps", ["Adductors", "Glutes"], "beginner", "Wide stance, toes out 45 degrees, keep torso upright", "Goblet Squat"),
                    ex("Dumbbell Floor Press", 3, 10, 90, "Light to moderate dumbbells", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Elbows touch floor, press to lockout, stable shoulders", "Push-Up"),
                    ex("Single-Arm Dumbbell Row", 3, 10, 75, "Light, focus on lat contraction", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "One hand on bench, pull elbow to hip, squeeze at top", "Cable Row"),
                    ex("Dumbbell Curl", 3, 12, 60, "Light, full range of motion", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "beginner", "Keep elbows pinned, full extension and contraction", "Hammer Curl"),
                    ex("Dumbbell Triceps Kickback", 3, 12, 60, "Light, squeeze at extension", "Dumbbells", "Arms", "Triceps", ["Anconeus"], "beginner", "Hinge forward, extend arm fully, pause at top", "Overhead Triceps Extension"),
                    ex("Bird Dog", 3, 10, 45, "Bodyweight, opposite arm and leg", "None", "Core", "Erector Spinae", ["Glutes", "Rectus Abdominis"], "beginner", "Extend opposite arm and leg, keep hips level, hold 2 seconds", "Plank")
                ]
            }
        ]
    },
    2: {
        "focus": "Building confidence with slightly increased loads while maintaining strict form",
        "workouts": [
            {
                "workout_name": "Day 1 - Full Body A",
                "type": "strength",
                "duration_minutes": 50,
                "exercises": [
                    ex("Goblet Squat", 3, 12, 90, "Add 5lbs from Week 1", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Chest up, elbows inside knees, full depth", "Bodyweight Squat"),
                    ex("Dumbbell Bench Press", 3, 12, 90, "Add 2-5lbs from Week 1", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Control the negative, pause at chest, drive up", "Incline Push-Up"),
                    ex("Dumbbell Bent-Over Row", 3, 12, 90, "Add 2-5lbs from Week 1", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to hip, 1-second squeeze at top", "Seated Cable Row"),
                    ex("Dumbbell Shoulder Press", 3, 12, 75, "Add 2-5lbs from Week 1", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Full lockout, controlled lower", "Lateral Raise"),
                    ex("Dumbbell Romanian Deadlift", 3, 12, 75, "Light dumbbells, feel the stretch", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Push hips back, slight knee bend, dumbbells close to legs", "Lying Leg Curl"),
                    ex("Plank", 3, "40s", 45, "Bodyweight, increase hold time", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Squeeze everything, breathe steadily", "Dead Bug")
                ]
            },
            {
                "workout_name": "Day 2 - Full Body B",
                "type": "strength",
                "duration_minutes": 50,
                "exercises": [
                    ex("Dumbbell Split Squat", 3, 10, 90, "Light dumbbells, focus on balance", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Front shin vertical, lower back knee toward floor", "Bodyweight Lunge"),
                    ex("Push-Up", 3, 12, 75, "Bodyweight, full range", "None", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Chest to floor, full lockout, body straight", "Knee Push-Up"),
                    ex("Lat Pulldown", 3, 12, 90, "Add 5lbs from Week 1", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoids"], "beginner", "Pull to upper chest, 1-second squeeze", "Resistance Band Pulldown"),
                    ex("Face Pull", 3, 15, 60, "Light cable, focus on rear delts", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull to face level, externally rotate at end", "Band Pull-Apart"),
                    ex("Dumbbell Step-Up", 3, 12, 75, "Add 2-5lbs from Week 1", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Full hip extension at top, controlled lower", "Leg Press"),
                    ex("Dead Bug", 3, 12, 45, "Bodyweight, slower tempo", "None", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "3 seconds to extend, 1 second back", "Plank")
                ]
            },
            {
                "workout_name": "Day 3 - Full Body C",
                "type": "strength",
                "duration_minutes": 50,
                "exercises": [
                    ex("Dumbbell Sumo Squat", 3, 12, 90, "Add 5lbs from Week 1", "Dumbbell", "Legs", "Quadriceps", ["Adductors", "Glutes"], "beginner", "Wide stance, press knees out, upright torso", "Goblet Squat"),
                    ex("Dumbbell Incline Press", 3, 10, 90, "Light to moderate", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "30-degree incline, lower to upper chest, press to lockout", "Incline Push-Up"),
                    ex("Single-Arm Dumbbell Row", 3, 12, 75, "Add 2-5lbs from Week 1", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull elbow to hip, 1-second hold at top", "Cable Row"),
                    ex("Dumbbell Hammer Curl", 3, 12, 60, "Light, thumbs-up grip", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "beginner", "Elbows stationary, full range", "Concentration Curl"),
                    ex("Overhead Dumbbell Triceps Extension", 3, 12, 60, "Light dumbbell, both hands", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner", "Lower behind head, extend fully, elbows point up", "Triceps Kickback"),
                    ex("Side Plank", 3, "20s", 45, "Bodyweight, each side", "None", "Core", "Obliques", ["Transverse Abdominis", "Glutes"], "beginner", "Stack hips, straight line, squeeze obliques", "Pallof Press")
                ]
            }
        ]
    }
}

# ─── 4-week variant (3x/wk) ───
w4 = {}
# Weeks 1-2 same as w2
w4[1] = w2[1]
w4[2] = w2[2]
w4[3] = {
    "focus": "Introducing barbell movements and increasing training volume with moderate loads",
    "workouts": [
        {
            "workout_name": "Day 1 - Full Body A (Barbell Intro)",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 3, 8, 120, "Empty bar or bar + 10lbs per side, focus on form", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Bar on upper traps, break at hips and knees together, hit parallel", "Goblet Squat", "Inhale down, exhale up", "Bar on upper traps, feet shoulder width"),
                ex("Barbell Bench Press", 3, 8, 120, "Empty bar or bar + 5lbs per side", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Arch upper back, lower to mid-chest, drive feet into floor", "Dumbbell Bench Press", "Inhale lower, exhale press"),
                ex("Barbell Bent-Over Row", 3, 8, 90, "Empty bar or bar + 5lbs per side", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoids"], "beginner", "Hinge at hips, pull to lower chest, squeeze shoulder blades", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 60, "Light, slow controlled reps", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "Slight elbow bend, raise to shoulder height", "Cable Lateral Raise"),
                ex("Leg Press", 3, 12, 90, "Moderate weight, full range", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feet shoulder width, lower until 90 degrees, press through heels", "Goblet Squat"),
                ex("Cable Crunch", 3, 15, 45, "Light to moderate", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Crunch down, exhale and squeeze abs, don't use hip flexors", "Plank")
            ]
        },
        {
            "workout_name": "Day 2 - Full Body B",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Dumbbell Walking Lunge", 3, 12, 90, "Light dumbbells, 12 steps total", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, back knee near floor, upright torso", "Stationary Lunge"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Moderate dumbbells", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "30-degree incline, controlled negative, squeeze at top", "Push-Up"),
                ex("Seated Cable Row", 3, 12, 90, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to lower chest, retract shoulder blades, slow return", "Dumbbell Row"),
                ex("Barbell Overhead Press", 3, 8, 120, "Empty bar or bar + 5lbs per side", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Brace core, press straight overhead, lockout fully", "Dumbbell Shoulder Press"),
                ex("Lying Leg Curl", 3, 12, 75, "Light to moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full range, squeeze at top, slow negative", "Dumbbell Romanian Deadlift"),
                ex("Pallof Press", 3, 10, 60, "Light cable, anti-rotation hold", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis", "Rectus Abdominis"], "beginner", "Press away from body, resist rotation, hold 2 seconds", "Side Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Full Body C",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 3, 10, 120, "Same weight as Day 1, higher reps for practice", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Focus on smooth tempo, pause at bottom", "Goblet Squat"),
                ex("Dumbbell Chest Fly", 3, 12, 75, "Light dumbbells, stretch at bottom", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "beginner", "Slight elbow bend, open wide, squeeze together at top", "Cable Crossover"),
                ex("Lat Pulldown", 3, 12, 90, "Add 5-10lbs from Week 2", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoids"], "beginner", "Wide grip, pull to upper chest, control return", "Resistance Band Pulldown"),
                ex("Dumbbell Curl", 3, 12, 60, "Moderate, strict form", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "No swinging, full range, slow negative", "Cable Curl"),
                ex("Cable Triceps Pushdown", 3, 12, 60, "Light to moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Elbows pinned to sides, full extension, squeeze at bottom", "Dumbbell Kickback"),
                ex("Plank", 3, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Full body tension, breathe steadily", "Dead Bug")
            ]
        }
    ]
}
w4[4] = {
    "focus": "Consolidation week - slightly heavier loads on barbell lifts, testing progress",
    "workouts": [
        {
            "workout_name": "Day 1 - Full Body A (Progress Test)",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 4, 8, 120, "Add 5-10lbs from Week 3", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Maintain form at heavier weight, full depth", "Goblet Squat"),
                ex("Barbell Bench Press", 4, 8, 120, "Add 5lbs from Week 3", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Controlled descent, touch chest, powerful drive", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 8, 90, "Add 5lbs from Week 3", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Strict form, no momentum, pull to lower chest", "Dumbbell Row"),
                ex("Dumbbell Shoulder Press", 3, 10, 75, "Moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout, controlled lower", "Lateral Raise"),
                ex("Leg Press", 3, 12, 90, "Add 10-20lbs from Week 3", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range of motion, don't lock knees", "Goblet Squat"),
                ex("Hanging Knee Raise", 3, 10, 60, "Bodyweight, controlled movement", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "No swinging, raise knees to chest, slow lower", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 2 - Full Body B",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Dumbbell Bulgarian Split Squat", 3, 10, 90, "Light to moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Rear foot on bench, lower until front thigh parallel", "Stationary Lunge"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Add 2-5lbs from Week 3", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Controlled negative, press to lockout", "Incline Push-Up"),
                ex("Single-Arm Dumbbell Row", 3, 12, 75, "Add 2-5lbs from Week 3", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Full stretch at bottom, squeeze at top", "Cable Row"),
                ex("Barbell Overhead Press", 3, 8, 120, "Add 5lbs from Week 3", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Brace hard, strict press, no leg drive", "Dumbbell Shoulder Press"),
                ex("Dumbbell Romanian Deadlift", 3, 12, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Feel the stretch, hip hinge pattern", "Lying Leg Curl"),
                ex("Ab Wheel Rollout (from knees)", 3, 8, 60, "Bodyweight, short range first", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Erector Spinae"], "beginner", "Roll out slowly, don't let hips sag, squeeze back", "Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Full Body C (Week 4 Finale)",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 4, 6, 150, "Heaviest yet - test your progress", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Brace tight, controlled descent, powerful drive up", "Goblet Squat"),
                ex("Barbell Bench Press", 4, 6, 150, "Heaviest yet - test your progress", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Controlled descent, pause on chest, strong press", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 6, 120, "Heaviest yet, strict form", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "No cheating, pull to sternum, squeeze", "Dumbbell Row"),
                ex("Face Pull", 3, 15, 60, "Moderate, finish with a hold", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, externally rotate, 2-second hold", "Band Pull-Apart"),
                ex("Dumbbell Curl", 3, 10, 60, "Moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Strict, no momentum", "Hammer Curl"),
                ex("Cable Triceps Pushdown", 3, 12, 60, "Moderate", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full lockout, slow negative", "Dumbbell Kickback")
            ]
        }
    ]
}

# ─── 8-week variant (3x/wk) ───
w8 = {}
for wk in range(1, 5):
    w8[wk] = w4[wk]

w8[5] = {
    "focus": "Deload week - reduce load by 10-15% to allow recovery before next progression",
    "workouts": [
        {
            "workout_name": "Day 1 - Full Body A (Deload)",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Barbell Back Squat", 3, 8, 90, "Reduce 10-15% from Week 4, focus on perfect form", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Slow controlled reps, perfect depth each rep", "Goblet Squat"),
                ex("Barbell Bench Press", 3, 8, 90, "Reduce 10-15% from Week 4", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Tempo: 3 seconds down, 1 second pause, press up", "Dumbbell Bench Press"),
                ex("Cable Row (Close Grip)", 3, 12, 75, "Moderate, controlled", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to lower chest, retract shoulder blades", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 60, "Light, slow negatives", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "3-second negative on each rep", "Cable Lateral Raise"),
                ex("Leg Extension", 3, 12, 60, "Light, full contraction at top", "Machine", "Legs", "Quadriceps", [], "beginner", "Pause at top, slow 3-second negative", "Goblet Squat"),
                ex("Plank", 3, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Focus on breathing while braced", "Dead Bug")
            ]
        },
        {
            "workout_name": "Day 2 - Full Body B (Deload)",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Goblet Squat", 3, 12, 75, "Moderate dumbbell, perfect reps", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Slow tempo, pause at bottom", "Bodyweight Squat"),
                ex("Push-Up", 3, 15, 60, "Bodyweight, focus on form", "None", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Full range, 2-second lower, 1-second pause at bottom", "Knee Push-Up"),
                ex("Lat Pulldown", 3, 12, 75, "Reduce 10% from recent working weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Focus on mind-muscle connection with lats", "Resistance Band Pulldown"),
                ex("Dumbbell Shoulder Press", 3, 10, 75, "Reduce weight, perfect reps", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full range, controlled movement", "Lateral Raise"),
                ex("Lying Leg Curl", 3, 12, 60, "Light, full range", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Squeeze at top, slow negative", "Dumbbell Romanian Deadlift"),
                ex("Dead Bug", 3, 12, 45, "Bodyweight, 3-second holds", "None", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Press lower back into floor, breathe out on extension", "Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Full Body C (Deload)",
            "type": "strength",
            "duration_minutes": 45,
            "exercises": [
                ex("Dumbbell Romanian Deadlift", 3, 10, 90, "Moderate, focus on hinge pattern", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Slow negative, feel the stretch, drive hips forward", "Lying Leg Curl"),
                ex("Dumbbell Chest Fly", 3, 12, 75, "Light, big stretch at bottom", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "beginner", "Wide arc, squeeze together at top", "Cable Crossover"),
                ex("Single-Arm Dumbbell Row", 3, 10, 75, "Moderate, full range", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Full stretch at bottom, squeeze at top", "Cable Row"),
                ex("Face Pull", 3, 15, 60, "Light cable, focus on rear delts", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, external rotation at end", "Band Pull-Apart"),
                ex("Dumbbell Curl", 3, 12, 60, "Light, slow tempo", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "3-second negative each rep", "Cable Curl"),
                ex("Side Plank", 3, "25s", 45, "Bodyweight, each side", "None", "Core", "Obliques", ["Transverse Abdominis"], "beginner", "Stack hips, straight line, breathe", "Pallof Press")
            ]
        }
    ]
}
w8[6] = {
    "focus": "Returning to heavier loads post-deload, adding barbell deadlift to the rotation",
    "workouts": [
        {
            "workout_name": "Day 1 - Full Body A",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 4, 8, 120, "Return to Week 4 weight or slightly above", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Should feel refreshed - smooth powerful reps", "Goblet Squat"),
                ex("Barbell Bench Press", 4, 8, 120, "Return to Week 4 weight or slightly above", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Controlled descent, powerful drive off chest", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 8, 90, "Return to Week 4 weight", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Strict form, no body English", "Dumbbell Row"),
                ex("Dumbbell Shoulder Press", 3, 10, 75, "Moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full lockout overhead", "Lateral Raise"),
                ex("Leg Press", 3, 12, 90, "Moderate to heavy", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full range, feet shoulder width", "Goblet Squat"),
                ex("Cable Crunch", 3, 15, 45, "Moderate", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Crunch down and exhale fully", "Plank")
            ]
        },
        {
            "workout_name": "Day 2 - Full Body B (Deadlift Day)",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Conventional Deadlift", 3, 5, 150, "Start conservative - bar + 25-35lbs per side max", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "beginner", "Flat back, push floor away, lock hips at top", "Dumbbell Romanian Deadlift", "Brace before each rep, exhale at lockout", "Feet hip width, grip just outside knees"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Moderate", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "30-degree incline, lower to upper chest", "Incline Push-Up"),
                ex("Lat Pulldown", 3, 10, 90, "Add 5lbs from pre-deload weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Full stretch at top, pull to chest", "Resistance Band Pulldown"),
                ex("Barbell Overhead Press", 3, 8, 120, "Return to Week 4 weight", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Brace core, strict press", "Dumbbell Shoulder Press"),
                ex("Dumbbell Hammer Curl", 3, 12, 60, "Moderate", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "beginner", "Thumbs up grip, no swinging", "Cable Curl"),
                ex("Overhead Dumbbell Triceps Extension", 3, 12, 60, "Moderate", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner", "Lower behind head, full extension", "Cable Pushdown")
            ]
        },
        {
            "workout_name": "Day 3 - Full Body C",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 3, 10, 120, "Same weight as Day 1, higher reps", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Volume work, every rep clean", "Goblet Squat"),
                ex("Dumbbell Bench Press", 3, 10, 90, "Moderate", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Full stretch at bottom, squeeze at top", "Push-Up"),
                ex("Seated Cable Row (Wide Grip)", 3, 12, 90, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Rear Deltoids"], "beginner", "Wide grip, pull to sternum, squeeze shoulder blades", "Dumbbell Row"),
                ex("Face Pull", 3, 15, 60, "Light to moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, external rotation hold", "Band Pull-Apart"),
                ex("Dumbbell Walking Lunge", 3, 12, 90, "Light to moderate, 12 total steps", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Long stride, upright torso", "Stationary Lunge"),
                ex("Hanging Knee Raise", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "Controlled, no swinging, knees to chest", "Lying Leg Raise")
            ]
        }
    ]
}
w8[7] = {
    "focus": "Pushing to new personal bests on all major lifts with increased sets and load",
    "workouts": [
        {
            "workout_name": "Day 1 - Full Body A (Heavy)",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Barbell Back Squat", 4, 6, 150, "Add 5-10lbs from Week 6 - new PR territory", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Brace hard, controlled descent, drive through heels", "Goblet Squat"),
                ex("Barbell Bench Press", 4, 6, 150, "Add 5lbs from Week 6 - new PR territory", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Tight setup, controlled lower, strong press", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 6, 120, "Add 5lbs from Week 6", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Strict form even at heavier weight", "Dumbbell Row"),
                ex("Dumbbell Arnold Press", 3, 10, 75, "Moderate dumbbells", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Rotate palms as you press, full lockout", "Dumbbell Shoulder Press"),
                ex("Barbell Romanian Deadlift", 3, 10, 90, "Moderate, focus on hamstring stretch", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Bar close to legs, push hips back", "Dumbbell Romanian Deadlift"),
                ex("Ab Wheel Rollout (from knees)", 3, 10, 60, "Bodyweight, extend further than before", "Ab Wheel", "Core", "Rectus Abdominis", ["Obliques", "Erector Spinae"], "beginner", "Controlled extension and return", "Plank")
            ]
        },
        {
            "workout_name": "Day 2 - Full Body B (Deadlift Heavy)",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Conventional Deadlift", 4, 5, 180, "Add 5-10lbs from Week 6 - new PR territory", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "beginner", "Flat back, brace before every rep, full lockout", "Dumbbell Romanian Deadlift"),
                ex("Dumbbell Incline Press", 4, 10, 90, "Add 2-5lbs from Week 6", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Full stretch, strong press", "Incline Push-Up"),
                ex("Chin-Up (Band Assisted if needed)", 3, 6, 90, "Bodyweight or with assistance band", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull chin over bar, slow 3-second lower", "Lat Pulldown"),
                ex("Barbell Overhead Press", 4, 6, 120, "Add 5lbs from Week 6", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Strict press, no leg drive, full lockout", "Dumbbell Shoulder Press"),
                ex("Dumbbell Bulgarian Split Squat", 3, 10, 90, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Rear foot elevated, deep stretch at bottom", "Stationary Lunge"),
                ex("Pallof Press", 3, 10, 60, "Moderate cable, anti-rotation", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "beginner", "Press out, hold 2 seconds, resist rotation", "Side Plank")
            ]
        },
        {
            "workout_name": "Day 3 - Full Body C (Volume)",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Barbell Back Squat", 3, 10, 120, "Week 6 weight, higher reps - build volume", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Every rep textbook form", "Goblet Squat"),
                ex("Close-Grip Bench Press", 3, 10, 90, "Moderate barbell load, triceps focus", "Barbell", "Chest", "Triceps", ["Pectorals", "Anterior Deltoids"], "beginner", "Hands shoulder width, elbows tucked, lower to lower chest", "Dumbbell Bench Press"),
                ex("Lat Pulldown (Wide Grip)", 3, 12, 90, "Moderate to heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "beginner", "Wide overhand grip, pull to upper chest", "Resistance Band Pulldown"),
                ex("Face Pull", 3, 15, 60, "Moderate", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull high, external rotate, squeeze", "Band Pull-Apart"),
                ex("Dumbbell Curl", 3, 10, 60, "Moderate, strict form", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "No momentum, full range", "Cable Curl"),
                ex("Cable Triceps Pushdown (Rope)", 3, 12, 60, "Moderate, split rope at bottom", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Pull rope apart at bottom for peak contraction", "Dumbbell Kickback")
            ]
        }
    ]
}
w8[8] = {
    "focus": "Final testing week - max effort on core lifts to establish new baselines for future training",
    "workouts": [
        {
            "workout_name": "Day 1 - Squat & Bench Test Day",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Barbell Back Squat", 4, 5, 180, "Work up to heaviest set of 5 - this is your test", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Warmup sets: bar x 5, 50% x 5, 70% x 3, then 2 working sets", "Goblet Squat"),
                ex("Barbell Bench Press", 4, 5, 180, "Work up to heaviest set of 5 - this is your test", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Warmup sets: bar x 5, 50% x 5, 70% x 3, then 2 working sets", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 5, 120, "Heaviest set of 5", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Match your best from Week 7 or beat it", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 60, "Moderate, finish clean", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "Controlled reps, no ego weight", "Cable Lateral Raise"),
                ex("Leg Press", 3, 10, 90, "Heavy, finish strong", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Full depth, strong push", "Goblet Squat"),
                ex("Plank", 3, "60s", 45, "Bodyweight - longest hold yet", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Full body tension for full minute", "Dead Bug")
            ]
        },
        {
            "workout_name": "Day 2 - Deadlift & OHP Test Day",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                ex("Conventional Deadlift", 4, 5, 180, "Work up to heaviest set of 5 - this is your test", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae", "Quadriceps"], "beginner", "Warmup: bar x 5, 50% x 5, 70% x 3, then 2 working sets", "Dumbbell Romanian Deadlift"),
                ex("Barbell Overhead Press", 4, 5, 150, "Work up to heaviest set of 5", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "beginner", "Strict press, no leg drive", "Dumbbell Shoulder Press"),
                ex("Chin-Up (Band Assisted if needed)", 3, "max", 90, "Test your max reps", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Full range, chin over bar, full extension at bottom", "Lat Pulldown"),
                ex("Dumbbell Incline Press", 3, 10, 90, "Moderate to heavy", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Strong controlled reps", "Push-Up"),
                ex("Barbell Romanian Deadlift", 3, 10, 90, "Moderate, hamstring focus", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Big stretch, squeeze glutes at top", "Dumbbell Romanian Deadlift"),
                ex("Hanging Knee Raise", 3, 12, 60, "Bodyweight, controlled", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "beginner", "Slow and controlled, no swinging", "Lying Leg Raise")
            ]
        },
        {
            "workout_name": "Day 3 - Celebration Volume Day",
            "type": "strength",
            "duration_minutes": 55,
            "exercises": [
                ex("Barbell Back Squat", 3, 10, 120, "80% of test weight, clean reps to finish strong", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Every rep perfect - show how far you've come", "Goblet Squat"),
                ex("Dumbbell Bench Press", 3, 10, 90, "Moderate to heavy dumbbells", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Full range, strong squeeze at top", "Push-Up"),
                ex("Seated Cable Row", 3, 12, 90, "Moderate to heavy", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Big squeeze at contraction", "Dumbbell Row"),
                ex("Dumbbell Arnold Press", 3, 10, 75, "Moderate", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Full rotation and press", "Dumbbell Shoulder Press"),
                ex("Dumbbell Curl", 3, 12, 60, "Moderate, slow negatives", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Full range, 3-second negative", "Cable Curl"),
                ex("Cable Triceps Pushdown", 3, 12, 60, "Moderate to heavy", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full lockout, squeeze at bottom", "Dumbbell Kickback")
            ]
        }
    ]
}

weeks_data = {
    (2, 3): w2,
    (4, 3): w4,
    (8, 3): w8,
}

success = helper.insert_full_program(
    program_name="Strength Foundations",
    category_name="Strength",
    description="A comprehensive beginner program teaching fundamental movement patterns and building base strength through progressive compound lifts. Starts with dumbbells and bodyweight, gradually introducing barbell movements.",
    durations=[2, 4, 8],
    sessions_per_week=[3],
    has_supersets=False,
    priority="High",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
print(f"Strength Foundations: {'SUCCESS' if success else 'FAILED'}")
helper.update_tracker("Strength Foundations", "Done" if success else "Failed")
helper.close()
