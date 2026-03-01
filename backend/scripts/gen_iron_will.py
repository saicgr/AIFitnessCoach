#!/usr/bin/env python3
"""Generate Iron Will - Advanced Hypertrophy, 16w, 6x/wk
PPL split (Push/Pull/Legs x 2 per week)
Periodized: Accumulation (W1-4), Intensification (W5-8), Specialization (W9-12), Peak/Shred (W13-16)
Deloads at W4, W8, W12"""
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

def build_week(wk, total=16):
    is_deload = wk in [4, 8, 12]
    cycle = (wk - 1) % 4  # for exercise rotation

    if wk <= 4:
        phase, rpe = "accumulation", "RPE 7-8"
        c_sets, c_reps, i_sets, i_reps = 4, 10, 3, 12
    elif wk <= 8:
        phase, rpe = "intensification", "RPE 8-9"
        c_sets, c_reps, i_sets, i_reps = 4, 8, 4, 10
    elif wk <= 12:
        phase, rpe = "specialization", "RPE 8-9"
        c_sets, c_reps, i_sets, i_reps = 5, 8, 4, 12
    else:
        phase, rpe = "peak", "RPE 9-10"
        c_sets, c_reps, i_sets, i_reps = 4, 6, 3, 15

    if is_deload:
        c_sets, i_sets = max(2, c_sets - 2), max(2, i_sets - 1)
        rpe = "RPE 6 (deload)"

    # ── PUSH DAY A (Heavy) ──
    push_a_main = [
        ex("Barbell Bench Press", c_sets, c_reps, 150, f"Progressive overload, {rpe}", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "Arch, retract scapulae, leg drive, controlled descent", "Dumbbell Bench Press"),
        ex("Incline Barbell Press", c_sets, c_reps, 150, f"Progressive overload, {rpe}", "Barbell", "Chest", "Upper Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "30-degree, lower to upper chest, drive hard", "Dumbbell Incline Press"),
        ex("Dumbbell Bench Press", c_sets, c_reps, 120, f"Heavy, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "advanced", "Full stretch at bottom, strong press", "Barbell Bench Press"),
        ex("Barbell Bench Press", c_sets, c_reps, 150, f"Tempo: 3-1-1, {rpe}", "Barbell", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "advanced", "3-sec eccentric, 1-sec pause, explosive concentric", "Dumbbell Bench Press"),
    ][cycle]

    push_a = {
        "workout_name": "Day 1 - Push A (Chest Focus)",
        "type": "hypertrophy",
        "duration_minutes": 65,
        "exercises": [
            push_a_main,
            [
                ex("Dumbbell Incline Press", i_sets, i_reps, 90, f"Moderate-heavy, {rpe}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "30-degree, full ROM, squeeze at top", "Incline Barbell Press"),
                ex("Cable Crossover (High-to-Low)", i_sets, i_reps, 75, f"Moderate, {rpe}", "Cable Machine", "Chest", "Lower Pectorals", ["Anterior Deltoids"], "advanced", "High pulleys, cross at bottom, squeeze", "Decline Dumbbell Fly"),
                ex("Dumbbell Chest Fly", i_sets, i_reps, 75, f"Moderate, big stretch, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "advanced", "Wide arc, deep stretch, squeeze together", "Cable Crossover"),
                ex("Machine Chest Press", i_sets, i_reps, 90, f"Heavy, {rpe}", "Machine", "Chest", "Pectorals", ["Triceps"], "advanced", "Full extension, slow negative", "Dumbbell Press"),
            ][cycle],
            ex("Barbell Overhead Press", c_sets, c_reps, 120, f"Heavy, {rpe}", "Barbell", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Brace core, strict press, full lockout", "Dumbbell Shoulder Press"),
            ex("Dumbbell Lateral Raise", i_sets, 15, 60, f"Moderate, {rpe}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Controlled raises, slight forward lean, slow negative", "Cable Lateral Raise"),
            ex("Skull Crusher", i_sets, i_reps, 75, f"Moderate, {rpe}", "EZ Bar", "Arms", "Triceps", ["Anconeus"], "advanced", "Lower to forehead, extend fully, elbows in", "Cable Overhead Extension"),
            ex("Cable Triceps Pushdown", i_sets, i_reps, 60, f"Moderate, {rpe}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "advanced", "Full lockout, split rope at bottom", "Dumbbell Kickback"),
        ]
    }

    # ── PULL DAY A (Back Width) ──
    pull_a_main = [
        ex("Weighted Pull-Up", c_sets, c_reps, 150, f"Add weight, {rpe}", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Dead hang, full ROM, chin over bar", "Lat Pulldown"),
        ex("Barbell Bent-Over Row", c_sets, c_reps, 120, f"Heavy, {rpe}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "45-degree hinge, pull to sternum, squeeze", "T-Bar Row"),
        ex("Lat Pulldown (Wide Grip)", c_sets, c_reps, 120, f"Heavy, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "advanced", "Wide overhand, pull to upper chest, control return", "Pull-Up"),
        ex("Weighted Chin-Up", c_sets, c_reps, 150, f"Add weight, {rpe}", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Supinated grip, pull to upper chest, slow lower", "Lat Pulldown"),
    ][cycle]

    pull_a = {
        "workout_name": "Day 2 - Pull A (Back Width)",
        "type": "hypertrophy",
        "duration_minutes": 65,
        "exercises": [
            pull_a_main,
            [
                ex("Seated Cable Row", i_sets, i_reps, 90, f"Moderate-heavy, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to lower chest, retract scapulae", "Dumbbell Row"),
                ex("Single-Arm Dumbbell Row", i_sets, i_reps, 75, f"Heavy, each arm, {rpe}", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to hip, squeeze hard at top", "Cable Row"),
                ex("Chest-Supported Row", i_sets, i_reps, 90, f"Moderate-heavy, {rpe}", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Incline bench, pull to hips, no cheating", "Seated Cable Row"),
                ex("T-Bar Row", i_sets, i_reps, 120, f"Heavy, {rpe}", "T-Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to chest, squeeze at top", "Barbell Row"),
            ][cycle],
            ex("Straight-Arm Pulldown", i_sets, i_reps, 75, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Teres Major"], "advanced", "Arms straight, pull to thighs, squeeze lats", "Dumbbell Pullover"),
            ex("Face Pull", 3, 15, 60, f"Moderate, {rpe}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "advanced", "Pull to face, external rotate, squeeze", "Band Pull-Apart"),
            ex("Barbell Curl", i_sets, i_reps, 75, f"Moderate-heavy, strict, {rpe}", "Barbell", "Arms", "Biceps", ["Brachialis", "Forearms"], "advanced", "No swinging, full ROM, controlled negative", "EZ Bar Curl"),
            ex("Incline Dumbbell Curl", i_sets, i_reps, 60, f"Moderate, stretch focus, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "advanced", "Incline bench, arms hang, big stretch at bottom", "Preacher Curl"),
        ]
    }

    # ── LEGS DAY A (Quad Focus) ──
    legs_a_main = [
        ex("Barbell Back Squat", c_sets, c_reps, 180, f"Heavy, {rpe}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "High bar, full depth, drive through midfoot", "Leg Press"),
        ex("Front Squat", c_sets, c_reps, 180, f"Heavy, {rpe}", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "advanced", "Elbows high, upright torso, deep", "Goblet Squat"),
        ex("Barbell Back Squat", c_sets, c_reps, 180, f"Tempo 3-0-1, {rpe}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "3-second eccentric, no pause, explosive up", "Leg Press"),
        ex("Hack Squat", c_sets, c_reps, 150, f"Heavy, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "Feet low for quads, full depth, strong drive", "Leg Press"),
    ][cycle]

    legs_a = {
        "workout_name": "Day 3 - Legs A (Quad Focus)",
        "type": "hypertrophy",
        "duration_minutes": 70,
        "exercises": [
            legs_a_main,
            ex("Leg Press", i_sets, i_reps, 120, f"Heavy, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "advanced", "High and wide for glutes, or narrow and low for quads", "Hack Squat"),
            ex("Leg Extension", i_sets, i_reps, 60, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", [], "advanced", "Full extension, 2-second squeeze, slow negative", "Sissy Squat"),
            ex("Walking Lunge", 3, 12, 90, f"Moderate, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Long stride, upright torso, 12 total steps", "Bulgarian Split Squat"),
            ex("Lying Leg Curl", i_sets, i_reps, 75, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Full ROM, squeeze at top", "Dumbbell RDL"),
            ex("Standing Calf Raise", 4, 12, 60, f"Heavy, {rpe}", "Machine", "Legs", "Calves", ["Soleus"], "advanced", "Full stretch and contraction, pause at top", "Seated Calf Raise"),
            ex("Hanging Leg Raise", 3, 12, 60, "Bodyweight, controlled", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "advanced", "No swinging, toes to bar if possible", "Lying Leg Raise"),
        ]
    }

    # ── PUSH DAY B (Shoulder Focus) ──
    push_b_main = [
        ex("Seated Dumbbell Press", c_sets, c_reps, 120, f"Heavy, {rpe}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps", "Upper Trapezius"], "advanced", "Full ROM, controlled, don't lean back", "Barbell Overhead Press"),
        ex("Barbell Overhead Press", c_sets, c_reps, 120, f"Heavy, {rpe}", "Barbell", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Strict press, brace hard, full lockout", "Dumbbell Shoulder Press"),
        ex("Dumbbell Arnold Press", c_sets, c_reps, 120, f"Moderate-heavy, {rpe}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Rotate palms during press, full ROM", "Seated Dumbbell Press"),
        ex("Machine Shoulder Press", c_sets, c_reps, 120, f"Heavy, {rpe}", "Machine", "Shoulders", "Deltoids", ["Triceps"], "advanced", "Full lockout, controlled negative", "Barbell Overhead Press"),
    ][cycle]

    push_b = {
        "workout_name": "Day 4 - Push B (Shoulder Focus)",
        "type": "hypertrophy",
        "duration_minutes": 60,
        "exercises": [
            push_b_main,
            ex("Incline Dumbbell Press", i_sets, i_reps, 90, f"Moderate, {rpe}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "advanced", "30-degree, full stretch, strong press", "Incline Barbell Press"),
            [
                ex("Cable Lateral Raise", i_sets, 15, 60, f"Moderate, constant tension, {rpe}", "Cable Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Behind body start, raise to shoulder height, slow negative", "Dumbbell Lateral Raise"),
                ex("Dumbbell Lateral Raise (Drop Set)", i_sets, 12, 60, f"Start heavy, drop twice, {rpe}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Heavy x 8, drop 30% x 8, drop 30% x 8", "Cable Lateral Raise"),
                ex("Machine Lateral Raise", i_sets, 15, 60, f"Moderate, {rpe}", "Machine", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Controlled, focus on lateral head", "Dumbbell Lateral Raise"),
                ex("Dumbbell Lateral Raise", i_sets, 15, 60, f"Moderate, 3-sec negative, {rpe}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "advanced", "Slow negatives each rep", "Cable Lateral Raise"),
            ][cycle],
            ex("Rear Delt Fly (Machine)", i_sets, 15, 60, f"Moderate, {rpe}", "Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Squeeze shoulder blades at peak contraction", "Face Pull"),
            ex("Close-Grip Bench Press", i_sets, i_reps, 90, f"Moderate-heavy, {rpe}", "Barbell", "Chest", "Triceps", ["Pectorals"], "advanced", "Hands shoulder width, elbows tucked, lockout focus", "Dumbbell Close-Grip Press"),
            ex("Overhead Cable Triceps Extension", i_sets, i_reps, 60, f"Moderate, {rpe}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "advanced", "Face away, extend overhead, big stretch", "Skull Crusher"),
        ]
    }

    # ── PULL DAY B (Back Thickness) ──
    pull_b_main = [
        ex("Barbell Bent-Over Row", c_sets, c_reps, 120, f"Heavy, {rpe}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoids"], "advanced", "Overhand grip, pull to sternum for thickness", "T-Bar Row"),
        ex("T-Bar Row", c_sets, c_reps, 120, f"Heavy, {rpe}", "T-Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to chest, squeeze hard at top", "Barbell Row"),
        ex("Pendlay Row", c_sets, c_reps, 120, f"Heavy, explosive, {rpe}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Dead stop each rep, explosive pull", "Barbell Bent-Over Row"),
        ex("Meadows Row", c_sets, c_reps, 90, f"Heavy per arm, {rpe}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Rear Deltoids"], "advanced", "Landmine setup, staggered stance, pull to hip", "Single-Arm Dumbbell Row"),
    ][cycle]

    pull_b = {
        "workout_name": "Day 5 - Pull B (Back Thickness)",
        "type": "hypertrophy",
        "duration_minutes": 65,
        "exercises": [
            pull_b_main,
            [
                ex("Lat Pulldown (Neutral Grip)", i_sets, i_reps, 90, f"Moderate-heavy, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "advanced", "Neutral close grip, pull to chest, squeeze", "Pull-Up"),
                ex("Seated Cable Row (Wide Grip)", i_sets, i_reps, 90, f"Moderate, {rpe}", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Rear Deltoids"], "advanced", "Wide grip, pull to sternum, retract hard", "Dumbbell Row"),
                ex("Single-Arm Cable Row", i_sets, i_reps, 75, f"Moderate, each arm, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "advanced", "Pull to hip, slight rotation, squeeze", "Dumbbell Row"),
                ex("Chest-Supported Dumbbell Row", i_sets, i_reps, 90, f"Heavy, {rpe}", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids"], "advanced", "Chest on incline bench, strict pulls", "Seated Cable Row"),
            ][cycle],
            ex("Dumbbell Pullover", i_sets, i_reps, 75, f"Moderate, stretch focus, {rpe}", "Dumbbell", "Back", "Latissimus Dorsi", ["Pectorals", "Serratus Anterior"], "advanced", "Big stretch overhead, pull to chest, squeeze lats", "Cable Pullover"),
            ex("Cable Rear Delt Fly", 3, 15, 60, f"Moderate, {rpe}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "advanced", "Arms straight, squeeze shoulder blades", "Face Pull"),
            ex("Hammer Curl", i_sets, i_reps, 60, f"Moderate-heavy, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "advanced", "Thumbs up, no swinging, full ROM", "Cable Hammer Curl"),
            ex("Preacher Curl", i_sets, i_reps, 60, f"Moderate, {rpe}", "EZ Bar", "Arms", "Biceps", ["Brachialis"], "advanced", "Full stretch at bottom, squeeze at top, no momentum", "Dumbbell Preacher Curl"),
        ]
    }

    # ── LEGS DAY B (Ham/Glute Focus) ──
    legs_b_main = [
        ex("Romanian Deadlift", c_sets, c_reps, 150, f"Heavy, {rpe}", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "Push hips back, bar close to legs, big stretch", "Dumbbell RDL"),
        ex("Barbell Hip Thrust", c_sets, c_reps, 120, f"Heavy, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "advanced", "Upper back on bench, full extension, hard 2-second squeeze", "Dumbbell Hip Thrust"),
        ex("Sumo Deadlift", c_sets, c_reps, 150, f"Heavy, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors", "Quadriceps"], "advanced", "Wide stance, toes out, push knees out", "Conventional Deadlift"),
        ex("Romanian Deadlift", c_sets, c_reps, 150, f"Tempo 3-1-1, {rpe}", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "advanced", "3-second lowering, 1-second stretch, drive up", "Dumbbell RDL"),
    ][cycle]

    legs_b = {
        "workout_name": "Day 6 - Legs B (Ham & Glute Focus)",
        "type": "hypertrophy",
        "duration_minutes": 65,
        "exercises": [
            legs_b_main,
            ex("Bulgarian Split Squat", i_sets, 10, 90, f"Moderate-heavy, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "advanced", "Rear foot on bench, deep stretch, drive through front heel", "Walking Lunge"),
            [
                ex("Lying Leg Curl", i_sets, i_reps, 75, f"Moderate-heavy, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Full ROM, squeeze at top, slow negative", "Seated Leg Curl"),
                ex("Seated Leg Curl", i_sets, i_reps, 75, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "advanced", "Full contraction, controlled eccentric", "Lying Leg Curl"),
                ex("Glute-Ham Raise", i_sets, 8, 90, f"Bodyweight or weighted, {rpe}", "GHD", "Legs", "Hamstrings", ["Glutes"], "advanced", "Slow eccentric, powerful pull", "Nordic Curl"),
                ex("Nordic Curl", i_sets, 6, 90, f"Eccentric focus, {rpe}", "None", "Legs", "Hamstrings", ["Calves"], "advanced", "5-second negative, use hands for concentric", "Lying Leg Curl"),
            ][cycle],
            ex("Cable Pull-Through", 3, 15, 60, f"Moderate, {rpe}", "Cable Machine", "Legs", "Glutes", ["Hamstrings"], "advanced", "Hinge at hips, squeeze glutes hard at top", "Dumbbell RDL"),
            ex("Adductor Machine", 3, 15, 60, f"Moderate, {rpe}", "Machine", "Legs", "Adductors", ["Hip Flexors"], "advanced", "Full range, squeeze at contraction", "Sumo Squat"),
            ex("Seated Calf Raise", 4, 15, 60, f"Moderate, {rpe}", "Machine", "Legs", "Soleus", ["Calves"], "advanced", "Full ROM, constant tension, pause at top and bottom", "Standing Calf Raise"),
        ]
    }

    focus_map = {
        "accumulation": f"Week {wk} - Accumulation: building training volume base with moderate intensity",
        "intensification": f"Week {wk} - Intensification: increasing loads and intensity for strength gains",
        "specialization": f"Week {wk} - Specialization: highest volume phase targeting weak points",
        "peak": f"Week {wk} - Peak: maximum intensity with metabolic finishers for definition",
    }
    if is_deload:
        focus = f"Week {wk} - Strategic Deload: reduced volume/intensity for recovery and supercompensation"
    else:
        focus = focus_map.get(phase, f"Week {wk}")

    return {
        "focus": focus,
        "workouts": [push_a, pull_a, legs_a, push_b, pull_b, legs_b]
    }

# Build 16-week data
w16_data = {wk: build_week(wk, 16) for wk in range(1, 17)}
# Also 8-week and 12-week subsets
w8_data = {wk: build_week(wk, 8) for wk in range(1, 9)}
w12_data = {wk: build_week(wk, 12) for wk in range(1, 13)}

weeks_data = {
    (8, 6): w8_data,
    (12, 6): w12_data,
    (16, 6): w16_data,
}

success = helper.insert_full_program(
    program_name="Iron Will",
    category_name="Hypertrophy/Muscle Building",
    description="An advanced 16-week hypertrophy program using a PPL (Push/Pull/Legs) split trained twice per week. Four distinct phases: Accumulation, Intensification, Specialization, and Peak. Strategic deload weeks at W4, W8, and W12. Designed for experienced lifters seeking maximum muscle growth.",
    durations=[8, 12, 16],
    sessions_per_week=[6],
    has_supersets=False,
    priority="Medium",
    weeks_data=weeks_data,
    migration_num=migration_num,
)
print(f"Iron Will: {'SUCCESS' if success else 'FAILED'}")
helper.update_tracker("Iron Will", "Done" if success else "Failed")
helper.close()
