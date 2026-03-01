#!/usr/bin/env python3
"""Fill missing weeks for Cycling Strength program.
Missing: 4w 4x (all 4 weeks), 8w 3x (weeks 2-8), 8w 4x (weeks 2-8)"""
import sys, json, psycopg2, os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent.parent / ".env")

def ex(name, sets, reps, rest, weight, equip, body, primary, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest, "weight_guidance": weight,
        "equipment": equip, "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub
    }

# ──── Cycling Strength Workouts ────
# The program focuses on: single-leg power, posterior chain, core stability, upper body support
# Periodization: Foundation (W1-2) -> Build (W3-5) -> Power (W6-7) -> Taper (W8)

def make_3day_week(wk):
    """Generate 3-day/week variant workouts for cycling strength."""
    if wk <= 2:
        s, r, rest_s, rpe = 3, 10, 90, "RPE 7"
    elif wk <= 5:
        s, r, rest_s, rpe = 3, 8, 105, "RPE 8"
    elif wk <= 7:
        s, r, rest_s, rpe = 4, 6, 120, "RPE 8-9"
    else:
        s, r, rest_s, rpe = 2, 8, 90, "RPE 6 (taper)"

    cycle = (wk - 1) % 4

    day1 = {
        "workout_name": "Lower Body Power & Stability",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            [
                ex("Barbell Back Squat", s, r, 120, f"Add 2.5-5kg from last week, {rpe}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Full depth, drive through midfoot, fast out of the hole", "Goblet Squat"),
                ex("Front Squat", s, r, 120, f"70% back squat, {rpe}", "Barbell", "Legs", "Quadriceps", ["Core", "Glutes"], "intermediate", "Elbows high, upright torso, full depth", "Goblet Squat"),
                ex("Barbell Back Squat", s, r, 120, f"Tempo 3-1-2, {rpe}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "3s down, 1s pause, 2s up - builds pedal power", "Leg Press"),
                ex("Barbell Back Squat", s, r, 120, f"Heavy, {rpe}", "Barbell", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Explosive concentric, controlled descent", "Goblet Squat"),
            ][cycle],
            ex("Romanian Deadlift", s, r, rest_s, f"Moderate-heavy, {rpe}", "Barbell", "Legs", "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate", "Push hips back, bar close to legs, builds pedal-pull strength", "Dumbbell RDL"),
            ex("Bulgarian Split Squat", s, 10, rest_s, f"Moderate, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Single-leg power mirrors pedaling, deep stretch", "Walking Lunge"),
            [
                ex("Step-Up (High Box)", s, 10, rest_s, f"Moderate, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes"], "intermediate", "High box mimics pedal stroke, drive through lead foot", "Walking Lunge"),
                ex("Single-Leg Leg Press", s, 10, rest_s, f"Moderate-heavy, {rpe}", "Machine", "Legs", "Quadriceps", ["Glutes"], "intermediate", "Single leg for balance and pedaling power", "Bulgarian Split Squat"),
                ex("Reverse Lunge", s, 10, rest_s, f"Moderate, each leg, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Step back, lower straight down, drive through front heel", "Walking Lunge"),
                ex("Lateral Lunge", s, 10, rest_s, f"Moderate, each side, {rpe}", "Dumbbells", "Legs", "Adductors", ["Quadriceps", "Glutes"], "intermediate", "Wide step, sit into hip, push back to start", "Goblet Squat"),
            ][cycle],
            ex("Standing Calf Raise", 3, 15, 60, f"Moderate, {rpe}", "Machine", "Legs", "Calves", ["Soleus"], "intermediate", "Full ROM, pause at top - ankle power for pedaling", "Seated Calf Raise"),
            ex("Plank", 3, "45s", 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques", "Transverse Abdominis"], "intermediate", "Core stability transfers directly to cycling posture", "Dead Bug"),
        ]
    }

    day2 = {
        "workout_name": "Upper Body & Core for Cycling",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            [
                ex("Dumbbell Bench Press", s, r, rest_s, f"Moderate, {rpe}", "Dumbbells", "Chest", "Pectorals", ["Triceps", "Anterior Deltoids"], "intermediate", "Chest support for handlebar stability", "Push-Up"),
                ex("Barbell Bench Press", s, r, rest_s, f"Moderate, {rpe}", "Barbell", "Chest", "Pectorals", ["Triceps"], "intermediate", "Upper body support for climbing position", "Dumbbell Bench Press"),
                ex("Push-Up", s, 15, 60, f"Bodyweight, {rpe}", "None", "Chest", "Pectorals", ["Triceps", "Core"], "intermediate", "Builds shoulder stability for aero position", "Dumbbell Bench Press"),
                ex("Dumbbell Incline Press", s, r, rest_s, f"Moderate, {rpe}", "Dumbbells", "Chest", "Upper Pectorals", ["Triceps"], "intermediate", "Upper chest for climbing posture", "Incline Push-Up"),
            ][cycle],
            [
                ex("Barbell Bent-Over Row", s, r, rest_s, f"Moderate, {rpe}", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Strong back supports aero position on bike", "Dumbbell Row"),
                ex("Seated Cable Row", s, r, rest_s, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest, postural muscles for cycling", "Dumbbell Row"),
                ex("Single-Arm Dumbbell Row", s, r, rest_s, f"Moderate, each arm, {rpe}", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Unilateral pulling, shoulder stability", "Cable Row"),
                ex("Lat Pulldown", s, r, rest_s, f"Moderate, {rpe}", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Pull to chest, builds upper back for posture", "Pull-Up"),
            ][cycle],
            ex("Dumbbell Shoulder Press", s, r, 75, f"Moderate, {rpe}", "Dumbbells", "Shoulders", "Deltoids", ["Triceps"], "intermediate", "Shoulder stability for handlebar control", "Lateral Raise"),
            ex("Face Pull", 3, 15, 60, f"Light-moderate, {rpe}", "Cable Machine", "Shoulders", "Rear Deltoids", ["Rhomboids", "External Rotators"], "intermediate", "Counteracts forward-rounded cycling posture", "Band Pull-Apart"),
            ex("Pallof Press", 3, 10, 60, f"Moderate, {rpe}", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Anti-rotation core strength for pedaling stability", "Side Plank"),
            ex("Dead Bug", 3, 10, 45, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "intermediate", "Core stability and hip flexor coordination for cycling", "Bird Dog"),
        ]
    }

    day3 = {
        "workout_name": "Single-Leg Power & Posterior Chain",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            [
                ex("Barbell Hip Thrust", s, r, 120, f"Heavy, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Hip extension power directly translates to pedal stroke", "Dumbbell Hip Thrust"),
                ex("Glute Bridge (Barbell)", s, r, 120, f"Heavy, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Drive hips up, squeeze at top, builds pedal power", "Dumbbell Hip Thrust"),
                ex("Barbell Hip Thrust", s, r, 120, f"Single leg if possible, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings"], "intermediate", "Single leg builds unilateral power for each pedal stroke", "Bodyweight Hip Thrust"),
                ex("Sumo Deadlift", s, r, 120, f"Moderate-heavy, {rpe}", "Barbell", "Legs", "Glutes", ["Hamstrings", "Adductors"], "intermediate", "Wide stance, builds hip power for sprints", "Barbell Hip Thrust"),
            ][cycle],
            ex("Single-Leg Romanian Deadlift", s, 8, rest_s, f"Light-moderate, each leg, {rpe}", "Dumbbell", "Legs", "Hamstrings", ["Glutes", "Core"], "intermediate", "Balance and hamstring strength for pedal recovery phase", "Romanian Deadlift"),
            [
                ex("Box Jump", 3, 5, 90, f"Explosive, {rpe}", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Land softly, step down, builds explosive pedal power", "Jump Squat"),
                ex("Jump Squat", 3, 6, 90, f"Bodyweight, explosive, {rpe}", "None", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Explosive jump, soft landing, cycling sprint power", "Box Jump"),
                ex("Kettlebell Swing", 3, 12, 75, f"Moderate, {rpe}", "Kettlebell", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip hinge power, snap hips forward, pedal stroke mimicry", "Dumbbell Romanian Deadlift"),
                ex("Broad Jump", 3, 5, 90, f"Explosive, {rpe}", "None", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Horizontal power for sprint starts and attacks", "Box Jump"),
            ][cycle],
            ex("Lying Leg Curl", s, 12, 75, f"Moderate, {rpe}", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Hamstring strength for pedal pull phase", "Dumbbell RDL"),
            ex("Leg Extension", s, 12, 60, f"Moderate, {rpe}", "Machine", "Legs", "Quadriceps", [], "intermediate", "Quad isolation for pedal push phase", "Wall Sit"),
            ex("Side Plank", 3, "30s", 45, "Bodyweight, each side", "None", "Core", "Obliques", ["Transverse Abdominis", "Glutes"], "intermediate", "Lateral core stability prevents hip drop while pedaling", "Pallof Press"),
        ]
    }

    focus_texts = {
        1: "Foundation - Learning exercise patterns with cycling-specific emphasis",
        2: "Foundation continued - building base strength for pedaling power",
        3: "Build phase - increasing loads to develop cycling-specific strength",
        4: "Build phase continued - progressive overload on key cycling movements",
        5: "Build peak - highest volume week for maximum strength adaptation",
        6: "Power phase - heavier loads with explosive movements for sprint power",
        7: "Power phase peak - maximum intensity cycling-specific training",
        8: "Taper week - reduced volume to peak for race/event readiness",
    }

    return {
        "focus": focus_texts.get(wk, f"Week {wk} - Cycling strength development"),
        "workouts": [day1, day2, day3]
    }


def make_4day_week(wk):
    """Generate 4-day/week variant. Adds a dedicated power/plyometric day."""
    base = make_3day_week(wk)

    if wk <= 2:
        s, r, rpe = 3, 10, "RPE 7"
    elif wk <= 5:
        s, r, rpe = 3, 8, "RPE 8"
    elif wk <= 7:
        s, r, rpe = 4, 6, "RPE 8-9"
    else:
        s, r, rpe = 2, 8, "RPE 6 (taper)"

    cycle = (wk - 1) % 4

    day4 = {
        "workout_name": "Power & Conditioning",
        "type": "conditioning",
        "duration_minutes": 50,
        "exercises": [
            [
                ex("Box Jump", 4, 5, 90, f"Explosive, {rpe}", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Maximum height, soft landing, step down - sprint power", "Jump Squat"),
                ex("Kettlebell Swing", 4, 12, 75, f"Moderate-heavy, {rpe}", "Kettlebell", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "Hip hinge, snap hips, cycling power", "Dumbbell Romanian Deadlift"),
                ex("Broad Jump", 4, 5, 90, f"Maximum distance, {rpe}", "None", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "intermediate", "Horizontal power for attack/sprint", "Box Jump"),
                ex("Jump Squat (Weighted)", 4, 6, 90, f"Light load, {rpe}", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Light dumbbells, max height, cycling sprint power", "Box Jump"),
            ][cycle],
            ex("Single-Leg Box Jump", 3, 5, 90, f"Each leg, {rpe}", "Plyo Box", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Single-leg power mimics pedal stroke, land softly", "Single-Leg Squat"),
            ex("Medicine Ball Slam", 3, 10, 60, f"Moderate ball, {rpe}", "Medicine Ball", "Core", "Rectus Abdominis", ["Obliques", "Latissimus Dorsi"], "intermediate", "Full body power, core engagement for cycling stability", "Battle Rope Slams"),
            [
                ex("Battle Ropes", 3, "30s", 60, f"Max effort intervals, {rpe}", "Battle Rope", "Full Body", "Deltoids", ["Core", "Forearms"], "intermediate", "Alternating waves, builds upper body endurance for long rides", "Medicine Ball Slam"),
                ex("Sled Push", 3, "20m", 90, f"Heavy, {rpe}", "Sled", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Low body position mimics hill climbing", "Leg Press"),
                ex("Farmer's Walk", 3, "30m", 60, f"Heavy, {rpe}", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Grip and core stability for long rides", "Dumbbell Shrug"),
                ex("Prowler Push", 3, "20m", 90, f"Moderate-heavy, {rpe}", "Sled", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Mimics pedaling under load, builds cycling endurance", "Leg Press"),
            ][cycle],
            ex("Plank to Push-Up", 3, 8, 60, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Triceps", "Obliques"], "intermediate", "Core stability under movement, cycling posture", "Plank"),
            ex("Russian Twist", 3, 15, 45, f"Light medicine ball, {rpe}", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Rotational core for handlebar control in corners", "Bicycle Crunch"),
        ]
    }

    base["workouts"].append(day4)
    return base


# Connect and insert
password = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
conn = psycopg2.connect(
    host=os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co"),
    port=5432, dbname="postgres", user="postgres", password=password, sslmode="require"
)

cur = conn.cursor()

# Get variant IDs
variants = {}
cur.execute("""
    SELECT pv.id, pv.duration_weeks, pv.sessions_per_week, pv.variant_name
    FROM program_variants pv
    JOIN branded_programs bp ON bp.id = pv.base_program_id
    WHERE bp.name = 'Cycling Strength'
""")
for r in cur.fetchall():
    variants[(r[1], r[2])] = (r[0], r[3])

inserted = 0
for (dur, sess), (vid, vname) in variants.items():
    # Check which weeks already exist
    cur.execute("SELECT week_number FROM program_variant_weeks WHERE variant_id = %s", (vid,))
    existing = {r[0] for r in cur.fetchall() if r[0] is not None}

    for wk in range(1, dur + 1):
        if wk in existing:
            continue

        if sess == 3:
            week_data = make_3day_week(wk)
        else:
            week_data = make_4day_week(wk)

        from program_sql_helper import determine_phase
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
            "Cycling Strength", vname, "Medium", False,
            "Strength training program specifically designed for cyclists",
            "Strength"
        ))
        inserted += 1

conn.commit()
print(f"Cycling Strength: inserted {inserted} missing weeks")

# Verify
for (dur, sess), (vid, vname) in variants.items():
    cur.execute("SELECT COUNT(*) FROM program_variant_weeks WHERE variant_id = %s", (vid,))
    count = cur.fetchone()[0]
    print(f"  {dur}w x {sess}/wk: {count}/{dur} weeks")

conn.close()
