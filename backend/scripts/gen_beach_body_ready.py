#!/usr/bin/env python3
"""Generate Beach Body Ready - Intermediate Hypertrophy, 12w, 5x/wk
Chest/Back, Shoulders/Arms, Legs, Upper, Lower split
Focus: aesthetic muscle building with moderate cardio finishers"""
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

def build_week(wk, total=12):
    """Build workout data for a given week with proper progression."""
    # Determine phase
    if wk <= 3:
        phase = "foundation"
        intensity = "RPE 7-8"
        rep_range_compound = 10
        rep_range_iso = 12
        sets_compound = 3
        sets_iso = 3
    elif wk <= 6:
        phase = "build"
        intensity = "RPE 8"
        rep_range_compound = 8
        rep_range_iso = 12
        sets_compound = 4
        sets_iso = 3
    elif wk <= 9:
        phase = "peak"
        intensity = "RPE 8-9"
        rep_range_compound = 8
        rep_range_iso = 10
        sets_compound = 4
        sets_iso = 4
    else:
        phase = "shred"
        intensity = "RPE 9"
        rep_range_compound = 10
        rep_range_iso = 15
        sets_compound = 4
        sets_iso = 3

    # Deload on weeks 4, 8 (reduce sets by 1, intensity down)
    is_deload = wk in [4, 8]
    if is_deload:
        sets_compound = max(2, sets_compound - 1)
        sets_iso = max(2, sets_iso - 1)
        intensity = "RPE 6-7 (deload)"

    # Vary exercises across weeks for novelty
    cycle = (wk - 1) % 4  # 0,1,2,3

    # DAY 1: CHEST & BACK
    chest_main = [
        ex("Barbell Bench Press", sets_compound, rep_range_compound, 120, f"Progressive overload, {intensity}", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "Arch back, retract scapulae, control descent", "Dumbbell Bench Press"),
        ex("Dumbbell Bench Press", sets_compound, rep_range_compound, 120, f"Heavy dumbbells, {intensity}", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "Lower to chest level, full stretch, squeeze at top", "Barbell Bench Press"),
        ex("Incline Barbell Press", sets_compound, rep_range_compound, 120, f"Progressive overload, {intensity}", "Barbell", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "30-degree incline, lower to upper chest", "Dumbbell Incline Press"),
        ex("Dumbbell Incline Press", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "30-degree incline, full ROM", "Incline Barbell Press"),
    ][cycle]

    chest_secondary = [
        ex("Dumbbell Incline Fly", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Dumbbells", "Chest", "Upper Pectorals", ["Anterior Deltoids"], "intermediate", "Wide arc, deep stretch, squeeze together", "Cable Crossover"),
        ex("Cable Crossover", sets_iso, rep_range_iso, 75, f"Moderate, constant tension, {intensity}", "Cable Machine", "Chest", "Pectorals", ["Anterior Deltoids"], "intermediate", "Slight lean, cross hands at bottom, squeeze", "Dumbbell Fly"),
        ex("Machine Chest Press", sets_iso, rep_range_iso, 75, f"Moderate-heavy, {intensity}", "Machine", "Chest", "Pectorals", ["Triceps"], "intermediate", "Full extension, slow negative", "Push-Up"),
        ex("Dumbbell Chest Fly", sets_iso, rep_range_iso, 75, f"Moderate, big stretch, {intensity}", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "intermediate", "Flat bench, wide arc, squeeze at top", "Cable Crossover"),
    ][cycle]

    back_main = [
        ex("Barbell Bent-Over Row", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "45-degree hinge, pull to lower chest, squeeze", "T-Bar Row"),
        ex("Weighted Pull-Up", sets_compound, rep_range_compound, 120, f"Add weight if possible, {intensity}", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "intermediate", "Dead hang to chin over, full ROM", "Lat Pulldown"),
        ex("T-Bar Row", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "T-Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Chest supported if available, pull to chest", "Barbell Row"),
        ex("Seated Cable Row", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest, retract scapulae, squeeze", "Dumbbell Row"),
    ][cycle]

    back_secondary = [
        ex("Lat Pulldown", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Wide grip, pull to upper chest, control return", "Pull-Up"),
        ex("Single-Arm Dumbbell Row", sets_iso, rep_range_iso, 75, f"Moderate, each arm, {intensity}", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to hip, 1-second squeeze", "Cable Row"),
        ex("Straight-Arm Pulldown", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Teres Major"], "intermediate", "Arms straight, pull bar to thighs, squeeze lats", "Dumbbell Pullover"),
        ex("Chest-Supported Row", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "intermediate", "Incline bench, pull to hips, squeeze", "Seated Cable Row"),
    ][cycle]

    day1 = {
        "workout_name": f"Day 1 - Chest & Back",
        "type": "hypertrophy",
        "duration_minutes": 60,
        "exercises": [
            chest_main, back_main, chest_secondary, back_secondary,
            ex("Dumbbell Pullover", sets_iso, rep_range_iso, 75, f"Moderate, stretch focus, {intensity}", "Dumbbell", "Chest", "Pectorals", ["Latissimus Dorsi", "Serratus Anterior"], "intermediate", "Arms slightly bent, big stretch overhead, squeeze at top", "Cable Pullover"),
            ex("Face Pull", 3, 15, 60, f"Light-moderate, {intensity}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "intermediate", "Pull to face, external rotate, shoulder health", "Band Pull-Apart"),
        ]
    }

    # DAY 2: SHOULDERS & ARMS
    shoulder_main = [
        ex("Barbell Overhead Press", sets_compound, rep_range_compound, 120, f"Progressive overload, {intensity}", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "intermediate", "Brace core, press straight up, full lockout", "Dumbbell Shoulder Press"),
        ex("Seated Dumbbell Press", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "intermediate", "Full ROM, don't lean back excessively", "Machine Shoulder Press"),
        ex("Dumbbell Arnold Press", sets_compound, rep_range_compound, 120, f"Moderate-heavy, {intensity}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "intermediate", "Rotate palms as you press, full lockout", "Seated Dumbbell Press"),
        ex("Machine Shoulder Press", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Machine", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Full lockout, controlled negative", "Barbell Overhead Press"),
    ][cycle]

    lateral = [
        ex("Dumbbell Lateral Raise", sets_iso, rep_range_iso, 60, f"Moderate, slow controlled, {intensity}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "intermediate", "Slight bend in elbows, raise to shoulder height, slow negative", "Cable Lateral Raise"),
        ex("Cable Lateral Raise", sets_iso, rep_range_iso, 60, f"Moderate, constant tension, {intensity}", "Cable Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "intermediate", "Behind body start, raise to shoulder height", "Dumbbell Lateral Raise"),
        ex("Machine Lateral Raise", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "intermediate", "Controlled movement, don't use momentum", "Dumbbell Lateral Raise"),
        ex("Dumbbell Lateral Raise (Leaning)", sets_iso, rep_range_iso, 60, f"Light-moderate, {intensity}", "Dumbbell", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "intermediate", "Hold upright with one hand, lean away, raise dumbbell", "Cable Lateral Raise"),
    ][cycle]

    triceps = [
        ex("Cable Triceps Pushdown (Rope)", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "intermediate", "Elbows pinned, split rope at bottom, squeeze", "Dumbbell Kickback"),
        ex("Overhead Cable Triceps Extension", sets_iso, rep_range_iso, 60, f"Moderate, stretch focus, {intensity}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "intermediate", "Face away, extend overhead, big stretch", "Skull Crusher"),
        ex("Skull Crusher", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "intermediate", "Lower to forehead, extend fully, elbows in", "Cable Pushdown"),
        ex("Dumbbell Overhead Extension", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "intermediate", "Both hands, lower behind head, extend fully", "Cable Pushdown"),
    ][cycle]

    biceps = [
        ex("Barbell Curl", sets_iso, rep_range_iso, 60, f"Moderate, strict, {intensity}", "Barbell", "Arms", "Biceps", ["Brachialis", "Forearms"], "intermediate", "No swinging, full range, controlled negative", "EZ Bar Curl"),
        ex("Dumbbell Hammer Curl", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "intermediate", "Thumbs up, no swinging, full ROM", "Cable Hammer Curl"),
        ex("Incline Dumbbell Curl", sets_iso, rep_range_iso, 60, f"Moderate, stretch focus, {intensity}", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "intermediate", "Incline bench, arms hang, big stretch at bottom", "Preacher Curl"),
        ex("EZ Bar Preacher Curl", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "intermediate", "Full stretch at bottom, squeeze at top, no momentum", "Dumbbell Curl"),
    ][cycle]

    day2 = {
        "workout_name": f"Day 2 - Shoulders & Arms",
        "type": "hypertrophy",
        "duration_minutes": 60,
        "exercises": [shoulder_main, lateral, triceps, biceps,
            ex("Rear Delt Fly (Machine or Dumbbell)", 3, 15, 60, f"Moderate, {intensity}", "Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "intermediate", "Squeeze shoulder blades, controlled movement", "Face Pull"),
            ex("Wrist Curl", 2, 15, 45, f"Light, forearm pump, {intensity}", "Dumbbells", "Arms", "Forearms", ["Wrist Flexors"], "intermediate", "Palms up, curl weight up, controlled", "Reverse Curl"),
        ]
    }

    # DAY 3: LEGS
    quad_main = [
        ex("Barbell Back Squat", sets_compound, rep_range_compound, 150, f"Heavy, {intensity}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, chest up, drive through midfoot", "Leg Press"),
        ex("Front Squat", sets_compound, rep_range_compound, 150, f"Heavy, {intensity}", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, upright torso, full depth", "Goblet Squat"),
        ex("Barbell Back Squat", sets_compound, rep_range_compound, 150, f"Progressive overload, {intensity}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Controlled tempo, pause at bottom", "Leg Press"),
        ex("Hack Squat", sets_compound, rep_range_compound, 150, f"Heavy, {intensity}", "Machine", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Feet low for quad emphasis, full depth", "Leg Press"),
    ][cycle]

    ham_main = [
        ex("Romanian Deadlift", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Push hips back, bar close to legs, big stretch", "Dumbbell RDL"),
        ex("Lying Leg Curl", sets_iso, rep_range_iso, 75, f"Moderate-heavy, {intensity}", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, squeeze at top, slow negative", "Dumbbell RDL"),
        ex("Dumbbell Romanian Deadlift", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Dumbbells", "Legs", "Hamstrings", ["Glutes"], "intermediate", "Neutral grip, push hips back", "Barbell RDL"),
        ex("Seated Leg Curl", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, controlled", "Lying Leg Curl"),
    ][cycle]

    day3 = {
        "workout_name": f"Day 3 - Legs",
        "type": "hypertrophy",
        "duration_minutes": 65,
        "exercises": [
            quad_main, ham_main,
            ex("Leg Press", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, don't lock knees", "Hack Squat"),
            ex("Leg Extension", sets_iso, rep_range_iso, 60, f"Moderate, {intensity}", "Machine", "Legs", "Quadriceps", [], "intermediate", "Full extension, 2-second squeeze at top", "Sissy Squat"),
            ex("Walking Lunge", 3, 12, 90, f"Moderate dumbbells, {intensity}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Long stride, upright torso", "Bulgarian Split Squat"),
            ex("Standing Calf Raise", 4, 12, 60, f"Heavy, {intensity}", "Machine", "Legs", "Calves", ["Soleus"], "intermediate", "Full stretch and contraction, pause at top", "Seated Calf Raise"),
        ]
    }

    # DAY 4: UPPER (Push emphasis)
    day4_push = [
        ex("Incline Dumbbell Press", sets_compound, rep_range_compound, 90, f"Heavy, {intensity}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "30-degree, full stretch, strong press", "Incline Barbell Press"),
        ex("Dumbbell Bench Press", sets_compound, rep_range_compound, 90, f"Heavy, {intensity}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "intermediate", "Full ROM, squeeze at top", "Barbell Bench Press"),
        ex("Incline Barbell Press", sets_compound, rep_range_compound, 90, f"Heavy, {intensity}", "Barbell", "Chest", "Upper Pectorals", ["Triceps"], "intermediate", "30-degree, lower to upper chest", "Dumbbell Incline Press"),
        ex("Machine Chest Press", sets_compound, rep_range_compound, 90, f"Heavy, {intensity}", "Machine", "Chest", "Pectorals", ["Triceps"], "intermediate", "Full extension, controlled negative", "Barbell Bench Press"),
    ][cycle]

    day4_pull = [
        ex("Lat Pulldown (Close Grip)", sets_iso, rep_range_iso, 75, f"Moderate-heavy, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Neutral close grip, pull to chest, squeeze lats", "Pull-Up"),
        ex("Cable Row (Wide Grip)", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Rear Deltoids"], "intermediate", "Wide overhand grip, pull to sternum", "Dumbbell Row"),
        ex("Dumbbell Row", sets_iso, rep_range_iso, 75, f"Moderate-heavy, {intensity}", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "One arm at a time, pull to hip, squeeze", "Cable Row"),
        ex("Lat Pulldown (Wide Grip)", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "intermediate", "Wide overhand, pull to upper chest", "Pull-Up"),
    ][cycle]

    day4 = {
        "workout_name": f"Day 4 - Upper Body",
        "type": "hypertrophy",
        "duration_minutes": 60,
        "exercises": [
            day4_push, day4_pull,
            ex("Dumbbell Lateral Raise", 3, 15, 60, f"Moderate, {intensity}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "intermediate", "Controlled raises, build the caps", "Cable Lateral Raise"),
            ex("Cable Crossover", 3, 12, 60, f"Moderate, {intensity}", "Cable Machine", "Chest", "Pectorals", ["Anterior Deltoids"], "intermediate", "Squeeze at bottom, pump work", "Dumbbell Fly"),
            ex("Dumbbell Curl", 3, 12, 60, f"Moderate, {intensity}", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "intermediate", "Strict, full ROM", "Cable Curl"),
            ex("Cable Triceps Pushdown", 3, 12, 60, f"Moderate, {intensity}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "intermediate", "Full lockout, squeeze", "Dumbbell Kickback"),
        ]
    }

    # DAY 5: LOWER (Glute/Ham emphasis)
    day5_main = [
        ex("Barbell Hip Thrust", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Upper back on bench, full hip extension, squeeze 2 seconds", "Dumbbell Hip Thrust"),
        ex("Sumo Deadlift", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors", "Quadriceps"], "intermediate", "Wide stance, toes out, push knees out, chest up", "Conventional Deadlift"),
        ex("Barbell Hip Thrust", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Drive through heels, full extension, hard squeeze", "Dumbbell Hip Thrust"),
        ex("Romanian Deadlift", sets_compound, rep_range_compound, 120, f"Heavy, {intensity}", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Big stretch, squeeze glutes at top", "Dumbbell RDL"),
    ][cycle]

    day5 = {
        "workout_name": f"Day 5 - Lower (Glute & Ham Focus)",
        "type": "hypertrophy",
        "duration_minutes": 60,
        "exercises": [
            day5_main,
            ex("Bulgarian Split Squat", sets_compound, 10, 90, f"Moderate, {intensity}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Rear foot on bench, deep stretch, drive through front heel", "Walking Lunge"),
            ex("Lying Leg Curl", sets_iso, rep_range_iso, 75, f"Moderate, {intensity}", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, squeeze at top", "Seated Leg Curl"),
            ex("Cable Pull-Through", 3, 12, 60, f"Moderate, {intensity}", "Cable Machine", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Hinge at hips, squeeze glutes at top, cable between legs", "Dumbbell RDL"),
            ex("Leg Extension", 3, rep_range_iso, 60, f"Moderate, {intensity}", "Machine", "Legs", "Quadriceps", [], "intermediate", "Full contraction, slow negative", "Sissy Squat"),
            ex("Seated Calf Raise", 4, 15, 60, f"Moderate, {intensity}", "Machine", "Legs", "Soleus", ["Calves"], "intermediate", "Full ROM, constant tension", "Standing Calf Raise"),
        ]
    }

    focus_map = {
        "foundation": f"Week {wk} - Building base muscle with moderate volume and focus on mind-muscle connection",
        "build": f"Week {wk} - Increasing intensity and training volume, pushing progressive overload",
        "peak": f"Week {wk} - Peak hypertrophy phase with highest training intensity and volume",
        "shred": f"Week {wk} - High-rep metabolic work to sharpen definition while maintaining muscle",
    }
    if is_deload:
        focus = f"Week {wk} - Deload: reduced volume and intensity for recovery and supercompensation"

    return {
        "focus": focus_map.get(phase, f"Week {wk}") if not is_deload else focus,
        "workouts": [day1, day2, day3, day4, day5]
    }

# Build all 12 weeks
w12_data = {}
for wk in range(1, 13):
    w12_data[wk] = build_week(wk, 12)

# Also build shorter variants by subsetting
w4_data = {}
for wk in range(1, 5):
    w4_data[wk] = build_week(wk, 4)

w8_data = {}
for wk in range(1, 9):
    w8_data[wk] = build_week(wk, 8)

weeks_data = {
    (4, 5): w4_data,
    (8, 5): w8_data,
    (12, 5): w12_data,
}

success = helper.insert_full_program(
    program_name="Beach Body Ready",
    category_name="Hypertrophy/Muscle Building",
    description="A 12-week aesthetic hypertrophy program designed to build a lean, muscular beach physique. 5-day split targeting chest/back, shoulders/arms, legs, upper body, and glute/ham emphasis. Includes strategic deload weeks and phases from foundation building to metabolic shredding.",
    durations=[4, 8, 12],
    sessions_per_week=[5],
    has_supersets=False,
    priority="Medium",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
print(f"Beach Body Ready: {'SUCCESS' if success else 'FAILED'}")
helper.update_tracker("Beach Body Ready", "Done" if success else "Failed")
helper.close()
