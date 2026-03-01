#!/usr/bin/env python3
"""Fill missing weeks for Plus Size Strength program.
Missing: 8w 3x (weeks 4-8), 8w 4x (weeks 4-8), 12w 3x (all), 12w 4x (weeks 2-12)
Focus: low-impact, joint-friendly, modifications available, progressive overload"""
import sys, json, os
import psycopg2
from pathlib import Path
from dotenv import load_dotenv

sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
load_dotenv(Path(__file__).parent.parent / ".env")
from program_sql_helper import determine_phase

def ex(name, sets, reps, rest, weight, equip, body, primary, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest, "weight_guidance": weight,
        "equipment": equip, "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub
    }

def make_3day_week(wk, total):
    """3 full-body days per week, joint-friendly, beginner-appropriate."""
    if wk <= 3:
        s, r, rest_t, rpe = 3, 10, 75, "RPE 6-7, focus on form"
    elif wk <= 6:
        s, r, rest_t, rpe = 3, 10, 90, "RPE 7-8, add 2-5lbs if form is good"
    elif wk <= 9:
        s, r, rest_t, rpe = 3, 8, 90, "RPE 8, progressive overload"
    else:
        s, r, rest_t, rpe = 3, 8, 90, "RPE 7-8, maintain and test progress"

    # Deload on specific weeks
    if wk in [4, 8]:
        s = max(2, s - 1)
        rpe = "RPE 5-6, recovery week"

    cycle = (wk - 1) % 4

    day1 = {
        "workout_name": "Full Body A",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            [
                ex("Goblet Squat", s, r, rest_t, f"Light to moderate, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Chest up, sit back, keep heels down - use a box/chair for depth reference if needed", "Wall Sit"),
                ex("Leg Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feet shoulder width, press through heels, don't lock knees - great for supporting your body weight", "Goblet Squat"),
                ex("Goblet Squat (to Box)", s, r, rest_t, f"Light, sit to box/bench, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Sit back to box, stand up - builds confidence with squatting depth", "Bodyweight Squat"),
                ex("Sumo Squat (Dumbbell)", s, r, rest_t, f"Moderate, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Adductors", "Glutes"], "beginner", "Wide stance, toes out, hold dumbbell at center - comfortable wide stance", "Goblet Squat"),
            ][cycle],
            [
                ex("Dumbbell Bench Press", s, r, rest_t, f"Light to moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "beginner", "Flat bench, lower to chest, press up - use moderate weight for comfort", "Push-Up (Incline)"),
                ex("Machine Chest Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Chest", "Pectorals", ["Triceps"], "beginner", "Machine supports your back, press forward, controlled return", "Dumbbell Bench Press"),
                ex("Incline Dumbbell Press", s, r, rest_t, f"Light to moderate, {rpe}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "beginner", "30-degree incline for comfort, controlled movement", "Machine Chest Press"),
                ex("Dumbbell Floor Press", s, r, rest_t, f"Moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "beginner", "Lie on floor, press up - floor limits range for comfort and safety", "Dumbbell Bench Press"),
            ][cycle],
            [
                ex("Lat Pulldown (Machine)", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to upper chest, squeeze shoulder blades, control return", "Resistance Band Pulldown"),
                ex("Seated Cable Row", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Pull to lower chest, sit tall, retract shoulder blades", "Dumbbell Row"),
                ex("Lat Pulldown (Close Grip)", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Close neutral grip, pull to chest, feel lats working", "Resistance Band Pulldown"),
                ex("Machine Row", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Machine supports chest, pull back, squeeze", "Seated Cable Row"),
            ][cycle],
            ex("Dumbbell Shoulder Press (Seated)", s, r, 75, f"Light, {rpe}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Seated for back support, press overhead, don't overarch", "Machine Shoulder Press"),
            ex("Dumbbell Curl", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Stand or sit, controlled curls, no swinging", "Cable Curl"),
            ex("Standing Calf Raise (Bodyweight)", 3, 15, 45, "Bodyweight or light", "None", "Legs", "Calves", ["Soleus"], "beginner", "Hold wall for balance, full ROM, builds ankle stability", "Seated Calf Raise"),
        ]
    }

    day2 = {
        "workout_name": "Full Body B",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            [
                ex("Leg Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Machine supports back, press through heels, comfortable position", "Goblet Squat"),
                ex("Goblet Squat", s, r, rest_t, f"Moderate, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Chest up, controlled movement", "Wall Sit"),
                ex("Seated Leg Curl", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full range, squeeze at top, builds posterior chain", "Dumbbell Romanian Deadlift"),
                ex("Leg Press (Wide Stance)", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Glutes", ["Quadriceps", "Adductors"], "beginner", "Wider foot position targets glutes more", "Goblet Sumo Squat"),
            ][cycle],
            [
                ex("Dumbbell Bent-Over Row", s, r, rest_t, f"Light to moderate, {rpe}", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Hinge forward at hips, pull elbows back, squeeze shoulder blades", "Seated Cable Row"),
                ex("Single-Arm Dumbbell Row (Bench Supported)", s, r, rest_t, f"Moderate, each arm, {rpe}", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "One hand on bench for support, pull to hip", "Machine Row"),
                ex("Machine Row", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Back", "Latissimus Dorsi", ["Rhomboids"], "beginner", "Machine supports chest, focus on squeezing back muscles", "Seated Cable Row"),
                ex("Lat Pulldown (Wide Grip)", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Teres Major"], "beginner", "Wide grip overhead, pull to upper chest", "Resistance Band Pulldown"),
            ][cycle],
            [
                ex("Machine Chest Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Chest", "Pectorals", ["Triceps"], "beginner", "Machine provides stability, focus on chest contraction", "Push-Up (Incline)"),
                ex("Dumbbell Chest Fly", s, 12, 75, f"Light, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Anterior Deltoids"], "beginner", "Light weight, wide arc, squeeze together - floor fly if bench is uncomfortable", "Cable Crossover"),
                ex("Push-Up (Incline)", s, r, 60, f"Bodyweight, use elevated surface, {rpe}", "None", "Chest", "Pectorals", ["Triceps", "Core"], "beginner", "Hands on bench/wall, lower chest to surface - adjust height for difficulty", "Knee Push-Up"),
                ex("Dumbbell Bench Press", s, r, rest_t, f"Moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "beginner", "Controlled movement, good stretch", "Machine Chest Press"),
            ][cycle],
            ex("Dumbbell Lateral Raise", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "Slight bend in elbows, raise to shoulder height, slow movement", "Cable Lateral Raise"),
            ex("Cable Triceps Pushdown", s, 12, 60, f"Light to moderate, {rpe}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Elbows pinned, full extension, squeeze at bottom", "Dumbbell Kickback"),
            ex("Plank (or Modified Plank)", 3, "30s", 45, "Bodyweight - from knees if needed", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "beginner", "Start from knees if needed, progress to toes, keep body straight", "Dead Bug"),
        ]
    }

    day3 = {
        "workout_name": "Full Body C",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            [
                ex("Dumbbell Romanian Deadlift", s, r, rest_t, f"Light to moderate, {rpe}", "Dumbbells", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "beginner", "Push hips back, slight knee bend, feel hamstring stretch", "Lying Leg Curl"),
                ex("Dumbbell Step-Up (Low Box)", s, 10, rest_t, f"Light, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Use low 6-8 inch box, drive through lead foot, hold rail if needed", "Leg Press"),
                ex("Sumo Squat (Dumbbell)", s, r, rest_t, f"Moderate, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Adductors", "Glutes"], "beginner", "Wide comfortable stance, toes out, hold dumbbell at center", "Goblet Squat"),
                ex("Seated Leg Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Machine supports back, comfortable position", "Goblet Squat"),
            ][cycle],
            [
                ex("Seated Cable Row", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Sit tall, pull to lower chest, squeeze back", "Dumbbell Row"),
                ex("Lat Pulldown", s, r, rest_t, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Pull to chest, feel lats working", "Resistance Band Pulldown"),
                ex("Dumbbell Bent-Over Row", s, r, rest_t, f"Moderate, {rpe}", "Dumbbells", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Both arms, hinge forward, pull back", "Machine Row"),
                ex("Face Pull", s, 15, 60, f"Light, {rpe}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, external rotate, great for posture", "Band Pull-Apart"),
            ][cycle],
            [
                ex("Dumbbell Floor Press", s, r, rest_t, f"Moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "beginner", "Lie on floor, limited range protects shoulders, controlled press", "Machine Chest Press"),
                ex("Incline Push-Up (Wall or Bench)", s, r, 60, f"Bodyweight, {rpe}", "None", "Chest", "Pectorals", ["Triceps", "Core"], "beginner", "Hands on wall or bench, lower body toward surface, push back", "Knee Push-Up"),
                ex("Dumbbell Bench Press", s, r, rest_t, f"Moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps"], "beginner", "Controlled movement, full ROM", "Machine Chest Press"),
                ex("Machine Chest Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Chest", "Pectorals", ["Triceps"], "beginner", "Comfortable, supported pressing", "Dumbbell Bench Press"),
            ][cycle],
            ex("Machine Shoulder Press", s, r, 75, f"Light, {rpe}", "Machine", "Shoulders", "Deltoids", ["Triceps"], "beginner", "Machine provides stability, press overhead, controlled", "Dumbbell Shoulder Press"),
            ex("Dumbbell Hammer Curl", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "beginner", "Thumbs up grip, no swinging, build grip strength", "Cable Curl"),
            ex("Dead Bug", 3, 10, 45, "Bodyweight, slow and controlled", "None", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "beginner", "Press lower back into floor, extend opposite arm and leg - great for core without crunches", "Bird Dog"),
        ]
    }

    focus_texts = {
        1: "Building movement confidence with machine and dumbbell exercises",
        2: "Establishing consistent training habits with full-body sessions",
        3: "Increasing working weights while maintaining excellent form",
        4: "Recovery week - lighter loads to let your body adapt and get stronger",
        5: "Progressing weights on all major lifts with improved confidence",
        6: "Building noticeable strength gains, focusing on progressive overload",
        7: "Pushing for personal bests with heavier loads and better endurance",
        8: "Recovery week before final push - lighter loads, focus on form",
        9: "Peak strength phase - testing new weights, feeling powerful",
        10: "Continued progression, building toward final assessments",
        11: "Preparing for final week testing, maintaining intensity",
        12: "Final week - celebrate progress, test your new strength levels",
    }

    return {
        "focus": focus_texts.get(wk, f"Week {wk} strength development"),
        "workouts": [day1, day2, day3]
    }


def make_4day_week(wk, total):
    """4-day upper/lower split - more time per muscle group."""
    base_3day = make_3day_week(wk, total)

    if wk <= 3:
        s, r, rest_t, rpe = 3, 10, 75, "RPE 6-7"
    elif wk <= 6:
        s, r, rest_t, rpe = 3, 10, 90, "RPE 7-8"
    elif wk <= 9:
        s, r, rest_t, rpe = 3, 8, 90, "RPE 8"
    else:
        s, r, rest_t, rpe = 3, 8, 90, "RPE 7-8"

    if wk in [4, 8]:
        s = max(2, s - 1)
        rpe = "RPE 5-6, recovery"

    cycle = (wk - 1) % 4

    # Split into Upper A, Lower A, Upper B, Lower B
    day1_upper = {
        "workout_name": "Upper Body A",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": base_3day["workouts"][0]["exercises"][:3] + [
            ex("Face Pull", 3, 15, 60, f"Light, {rpe}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids"], "beginner", "Pull to face, external rotate, posture improvement", "Band Pull-Apart"),
            ex("Dumbbell Curl", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis"], "beginner", "Controlled movement, no swinging", "Cable Curl"),
            ex("Cable Triceps Pushdown", s, 12, 60, f"Light, {rpe}", "Cable Machine", "Arms", "Triceps", ["Anconeus"], "beginner", "Full extension, squeeze", "Dumbbell Kickback"),
        ]
    }

    day2_lower = {
        "workout_name": "Lower Body A",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            base_3day["workouts"][0]["exercises"][0],  # Squat variant
            ex("Leg Press", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Machine supports back, comfortable pressing", "Goblet Squat"),
            ex("Lying Leg Curl", s, r, 75, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full range, squeeze at top", "Dumbbell RDL"),
            ex("Leg Extension", s, 12, 60, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", [], "beginner", "Full extension, slow negative", "Wall Sit"),
            ex("Standing Calf Raise (Bodyweight)", 3, 15, 45, "Hold wall for balance", "None", "Legs", "Calves", ["Soleus"], "beginner", "Full ROM, pause at top", "Seated Calf Raise"),
            ex("Dead Bug", 3, 10, 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Lower back pressed into floor", "Bird Dog"),
        ]
    }

    day3_upper = {
        "workout_name": "Upper Body B",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": base_3day["workouts"][1]["exercises"][:3] + [
            ex("Dumbbell Lateral Raise", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Shoulders", "Lateral Deltoids", ["Upper Trapezius"], "beginner", "Controlled raises, build shoulder caps", "Cable Lateral Raise"),
            ex("Dumbbell Hammer Curl", s, 12, 60, f"Light, {rpe}", "Dumbbells", "Arms", "Biceps", ["Brachialis", "Forearms"], "beginner", "Thumbs up, builds grip too", "Cable Curl"),
            ex("Overhead Dumbbell Extension", s, 12, 60, f"Light, {rpe}", "Dumbbell", "Arms", "Triceps", ["Anconeus"], "beginner", "Both hands, lower behind head, extend", "Cable Pushdown"),
        ]
    }

    day4_lower = {
        "workout_name": "Lower Body B",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            base_3day["workouts"][2]["exercises"][0],  # RDL or step-up variant
            [
                ex("Dumbbell Step-Up (Low Box)", s, 10, rest_t, f"Light, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "beginner", "Low box, hold rail if needed, drive through lead foot", "Leg Press"),
                ex("Leg Press (Narrow Stance)", s, r, rest_t, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "beginner", "Narrow feet for quad emphasis", "Goblet Squat"),
                ex("Goblet Squat", s, r, rest_t, f"Moderate, {rpe}", "Dumbbell", "Legs", "Quadriceps", ["Glutes"], "beginner", "Chest up, sit back, controlled", "Wall Sit"),
                ex("Seated Leg Curl", s, r, 75, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "beginner", "Full contraction at top", "Lying Leg Curl"),
            ][cycle],
            ex("Cable Pull-Through", s, 12, 75, f"Light-moderate, {rpe}", "Cable Machine", "Legs", "Glutes", ["Hamstrings"], "beginner", "Hinge at hips, squeeze glutes at top - great for glute activation", "Bodyweight Hip Thrust"),
            ex("Adductor Machine", s, 12, 60, f"Moderate, {rpe}", "Machine", "Legs", "Adductors", ["Hip Flexors"], "beginner", "Full range, squeeze at contraction", "Sumo Squat"),
            ex("Seated Calf Raise", 3, 15, 45, f"Moderate, {rpe}", "Machine", "Legs", "Soleus", ["Calves"], "beginner", "Full ROM, pause at top", "Standing Calf Raise"),
            ex("Plank (Modified if needed)", 3, "30s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "From knees if needed, straight body, breathe", "Dead Bug"),
        ]
    }

    return {
        "focus": base_3day["focus"],
        "workouts": [day1_upper, day2_lower, day3_upper, day4_lower]
    }


# Connect and insert
password = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
conn = psycopg2.connect(
    host=os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co"),
    port=5432, dbname="postgres", user="postgres", password=password, sslmode="require"
)

cur = conn.cursor()

variants = {}
cur.execute("""
    SELECT pv.id, pv.duration_weeks, pv.sessions_per_week, pv.variant_name
    FROM program_variants pv
    JOIN branded_programs bp ON bp.id = pv.base_program_id
    WHERE bp.name = 'Plus Size Strength'
""")
for r in cur.fetchall():
    variants[(r[1], r[2])] = (r[0], r[3])

inserted = 0
for (dur, sess), (vid, vname) in variants.items():
    cur.execute("SELECT week_number FROM program_variant_weeks WHERE variant_id = %s", (vid,))
    existing = {r[0] for r in cur.fetchall() if r[0] is not None}

    for wk in range(1, dur + 1):
        if wk in existing:
            continue

        if sess == 3:
            week_data = make_3day_week(wk, dur)
        else:
            week_data = make_4day_week(wk, dur)

        phase = determine_phase(wk, dur, "Strength")
        workouts_json = json.dumps(week_data["workouts"], ensure_ascii=False)

        cur.execute("""
            INSERT INTO program_variant_weeks (
                variant_id, week_number, phase, focus, workouts,
                program_name, variant_name, priority, has_supersets, description, category
            ) VALUES (%s, %s, %s, %s, %s::jsonb, %s, %s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (
            vid, wk, phase, week_data["focus"], workouts_json,
            "Plus Size Strength", vname, "Medium", False,
            "Inclusive strength program with joint-friendly modifications for plus-size individuals",
            "Strength"
        ))
        inserted += 1

conn.commit()
print(f"Plus Size Strength: inserted {inserted} missing weeks")

for (dur, sess), (vid, vname) in sorted(variants.items()):
    cur.execute("SELECT COUNT(*) FROM program_variant_weeks WHERE variant_id = %s", (vid,))
    count = cur.fetchone()[0]
    status = "OK" if count == dur else f"INCOMPLETE ({count}/{dur})"
    print(f"  {dur}w x {sess}/wk: {count}/{dur} weeks [{status}]")

conn.close()
