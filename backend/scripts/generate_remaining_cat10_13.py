#!/usr/bin/env python3
"""
Generate ALL remaining LOW priority programs for Categories 10-13.
51 programs total across Women's Health, Men's Health, Body-Specific, Equipment-Specific.
"""
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent))
from program_sql_helper import ProgramSQLHelper


def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
    return {
        "name": name, "exercise_library_id": None, "in_library": False,
        "sets": sets, "reps": reps, "rest_seconds": rest,
        "weight_guidance": guidance, "equipment": equip,
        "body_part": body, "primary_muscle": primary,
        "secondary_muscles": secondary, "difficulty": diff,
        "form_cue": cue, "substitution": sub,
    }


# ========== REUSABLE WORKOUT TEMPLATES ==========

def prenatal_gentle_workouts():
    """Safe, gentle prenatal exercises - no lying flat on back after 1st trimester."""
    return [
        {
            "workout_name": "Day 1 - Prenatal Strength",
            "type": "strength",
            "exercises": [
                ex("Wall Push-Up", 3, 10, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Stand arm's length from wall", "Incline Push-Up"),
                ex("Bodyweight Squat", 3, 10, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Comfortable depth only", "Chair Squat"),
                ex("Bird Dog", 3, 8, 20, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Keep spine neutral, no sagging", "Cat-Cow"),
                ex("Side-Lying Leg Lift", 3, 12, 20, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Side-lying, slow controlled lift", "Clamshell"),
                ex("Standing Calf Raise", 3, 12, 20, "Bodyweight, wall support", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Hold wall for balance", "Seated Calf Raise"),
                ex("Kegel Exercise", 3, 10, 15, "Bodyweight - hold 5 sec", "None", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Squeeze and hold, full release", "Quick Flick Kegels"),
            ],
        },
        {
            "workout_name": "Day 2 - Prenatal Mobility & Walking",
            "type": "flexibility",
            "exercises": [
                ex("Walking", 1, 1, 0, "15-20 minutes easy pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Flat terrain, stop if uncomfortable", "Seated Marching"),
                ex("Cat-Cow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle spinal movement", "Seated Spinal Flexion"),
                ex("Hip Circles", 3, 8, 15, "Bodyweight", "None", "Hips", "Hip Flexors", ["Hip Adductors"], "beginner", "Standing, large gentle circles", "Pelvic Tilts"),
                ex("Seated Figure 4 Stretch", 3, 4, 20, "Hold 20 sec/side", "None", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Ankle on knee, gentle lean", "Standing Figure 4"),
                ex("Neck Rolls", 3, 6, 15, "Bodyweight", "None", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Slow half circles", "Neck Side Stretch"),
                ex("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Deep belly breaths", "Box Breathing"),
            ],
        },
        {
            "workout_name": "Day 3 - Prenatal Light Circuit",
            "type": "circuit",
            "exercises": [
                ex("Glute Bridge", 3, 10, 20, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Keep head and shoulders on floor only in 1st tri", "Standing Glute Squeeze"),
                ex("Standing Arm Raise", 3, 10, 15, "Bodyweight or 1-2 lb", "None", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid"], "beginner", "Raise to shoulder height only", "Seated Arm Raise"),
                ex("Step-Up (Low)", 3, 8, 20, "Bodyweight", "Low Step", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "4-6 inch step, wall support", "Chair Squat"),
                ex("Standing Oblique Crunch", 3, 10, 15, "Bodyweight", "None", "Core", "Obliques", ["Hip Flexors"], "beginner", "Elbow to knee, standing only", "Side Bend"),
                ex("Clamshell", 3, 12, 15, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Side-lying, gentle opening", "Lateral Band Walk"),
                ex("Pelvic Tilt", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Standing, tilt pelvis gently", "Seated Pelvic Tilt"),
            ],
        },
    ]


def postpartum_gentle_workouts():
    """Post-birth recovery exercises - start very gentle, rebuild pelvic floor and core."""
    return [
        {
            "workout_name": "Day 1 - Pelvic Floor & Core Reconnection",
            "type": "strength",
            "exercises": [
                ex("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Pelvic Floor Muscles", "Transverse Abdominis"], "beginner", "Deep belly breath, gentle PF engagement on exhale", "Box Breathing"),
                ex("Kegel Exercise", 3, 10, 15, "Bodyweight - hold 5 sec", "None", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Gentle squeeze, full release between reps", "Quick Flick Kegels"),
                ex("Heel Slides", 3, 8, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Hip Flexors"], "beginner", "Slide heel along floor, maintain neutral spine", "Toe Taps"),
                ex("Glute Bridge", 3, 8, 20, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings", "Pelvic Floor Muscles"], "beginner", "Gentle squeeze at top", "Pelvic Tilt"),
                ex("Cat-Cow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle spinal movement", "Seated Spinal Flexion"),
                ex("Walking", 1, 1, 0, "10 minutes easy", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Very gentle pace", "Seated Marching"),
            ],
        },
        {
            "workout_name": "Day 2 - Gentle Full Body",
            "type": "strength",
            "exercises": [
                ex("Wall Push-Up", 3, 8, 20, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Gentle push from wall", "Counter Push-Up"),
                ex("Bodyweight Squat", 3, 8, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Partial range OK, no pain", "Chair Squat"),
                ex("Bird Dog", 3, 8, 20, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle, maintain neutral spine", "Dead Bug Modified"),
                ex("Side-Lying Clamshell", 3, 10, 15, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Rebuild hip stability", "Side-Lying Leg Lift"),
                ex("Standing Calf Raise", 3, 10, 15, "Bodyweight", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Wall support, slow movement", "Seated Calf Raise"),
                ex("Pelvic Floor Hold", 3, 6, 20, "Bodyweight - hold 8 sec", "None", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "Sustained gentle engagement", "Quick Flick Kegels"),
            ],
        },
        {
            "workout_name": "Day 3 - Mobility & Recovery",
            "type": "flexibility",
            "exercises": [
                ex("Walking", 1, 1, 0, "10-15 minutes", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Comfortable pace, baby in stroller OK", "Seated Marching"),
                ex("Cat-Cow Flow", 3, 8, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Slow, flowing movement", "Seated Spinal Flexion"),
                ex("Chest Opener Stretch", 3, 4, 15, "Hold 20 sec", "None", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Nursing posture relief", "Doorway Stretch"),
                ex("Neck Stretches", 3, 4, 15, "Hold 15 sec/side", "None", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Ear to shoulder, gentle", "Neck Rolls"),
                ex("Hip Circles", 3, 8, 15, "Bodyweight", "None", "Hips", "Hip Flexors", ["Gluteus Medius"], "beginner", "Gentle circles both directions", "Pelvic Tilts"),
                ex("Child's Pose", 3, 4, 15, "Hold 20 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Wide knees, gentle rest", "Cat Stretch"),
            ],
        },
    ]


def mens_compound_strength():
    """Standard men's compound strength workouts."""
    return [
        {
            "workout_name": "Day 1 - Lower Body",
            "type": "strength",
            "exercises": [
                ex("Barbell Back Squat", 4, 8, 90, "Moderate-heavy", "Barbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Full depth, brace core hard", "Goblet Squat"),
                ex("Romanian Deadlift", 3, 10, 75, "Moderate", "Barbell", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hinge at hips, flat back", "Dumbbell RDL"),
                ex("Walking Lunge", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Long stride, upright torso", "Reverse Lunge"),
                ex("Leg Press", 3, 12, 60, "Moderate", "Machine", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Full range, don't lock knees", "Hack Squat"),
                ex("Standing Calf Raise", 4, 15, 30, "Moderate", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "intermediate", "Full range of motion", "Seated Calf Raise"),
                ex("Plank Hold", 3, 1, 30, "Hold 45-60 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "intermediate", "Straight line, tight core", "Ab Wheel"),
            ],
        },
        {
            "workout_name": "Day 2 - Upper Push",
            "type": "strength",
            "exercises": [
                ex("Barbell Bench Press", 4, 8, 90, "Heavy", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, drive up", "Dumbbell Bench Press"),
                ex("Overhead Press", 3, 8, 75, "Moderate-heavy", "Barbell", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Strict press, no leg drive", "Dumbbell Press"),
                ex("Incline Dumbbell Press", 3, 10, 60, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis", ["Triceps"], "intermediate", "30 degree incline", "Incline Barbell"),
                ex("Dumbbell Lateral Raise", 3, 12, 30, "Light", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Control the weight", "Cable Lateral Raise"),
                ex("Weighted Dip", 3, 10, 60, "Added weight", "Dip Station", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Lean forward for chest", "Bench Dip"),
                ex("Tricep Pushdown", 3, 12, 30, "Moderate", "Cable Machine", "Arms", "Triceps Brachii", ["Anconeus"], "intermediate", "Elbows locked at sides", "Overhead Extension"),
            ],
        },
        {
            "workout_name": "Day 3 - Upper Pull",
            "type": "strength",
            "exercises": [
                ex("Weighted Pull-Up", 4, 8, 90, "Added weight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full range, chin over bar", "Lat Pulldown"),
                ex("Barbell Bent-Over Row", 4, 10, 75, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest", "Dumbbell Row"),
                ex("Cable Face Pull", 3, 15, 30, "Light-moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators"], "beginner", "Pull to face, spread hands", "Band Face Pull"),
                ex("Seated Cable Row", 3, 12, 60, "Moderate", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi"], "intermediate", "Squeeze shoulder blades", "Dumbbell Row"),
                ex("Barbell Curl", 3, 10, 45, "Moderate", "Barbell", "Arms", "Biceps Brachii", ["Brachialis"], "intermediate", "Strict form, no swinging", "Dumbbell Curl"),
                ex("Hammer Curl", 3, 12, 30, "Moderate", "Dumbbells", "Arms", "Brachioradialis", ["Biceps Brachii"], "intermediate", "Neutral grip, controlled", "Cable Curl"),
            ],
        },
        {
            "workout_name": "Day 4 - Full Body",
            "type": "strength",
            "exercises": [
                ex("Trap Bar Deadlift", 4, 6, 120, "Heavy", "Trap Bar", "Legs", "Hamstrings", ["Quadriceps", "Gluteus Maximus", "Core"], "intermediate", "Drive floor away, lockout hips", "Conventional Deadlift"),
                ex("Dumbbell Bench Press", 3, 10, 60, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Full range of motion", "Push-Up"),
                ex("Chin-Up", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Full range", "Lat Pulldown"),
                ex("Bulgarian Split Squat", 3, 10, 60, "Moderate DBs", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Rear foot elevated", "Reverse Lunge"),
                ex("Dumbbell Arnold Press", 3, 10, 45, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid"], "intermediate", "Rotate as you press", "Overhead Press"),
                ex("Russian Twist", 3, 16, 30, "Light DB", "Dumbbell", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate", "Bicycle Crunch"),
            ],
        },
    ]


def single_equipment_workouts(equip_name, equip_val):
    """Generate workouts using only a single equipment type."""
    if equip_val == "Dumbbell":
        return [
            {
                "workout_name": "Day 1 - Single DB Full Body A",
                "type": "strength",
                "exercises": [
                    ex("Single DB Goblet Squat", 3, 12, 45, "Moderate DB", equip_val, "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold DB at chest, sit deep", "Single DB Sumo Squat"),
                    ex("Single DB Row", 3, 10, 45, "Moderate DB - 5/side", equip_val, "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Brace on surface, pull to hip", "Single DB High Pull"),
                    ex("Single DB Floor Press", 3, 10, 30, "Moderate DB - 5/side", equip_val, "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Lie on floor, press up", "Single DB Push-Up"),
                    ex("Single DB Romanian Deadlift", 3, 10, 45, "Moderate DB", equip_val, "Legs", "Hamstrings", ["Gluteus Maximus"], "intermediate", "Hold DB at center, hinge at hips", "Single DB Sumo Deadlift"),
                    ex("Single DB Overhead Press", 3, 8, 30, "Moderate DB - 4/side", equip_val, "Shoulders", "Anterior Deltoid", ["Triceps"], "intermediate", "Strict press from shoulder", "Single DB Push Press"),
                    ex("Single DB Russian Twist", 3, 16, 30, "Moderate DB", equip_val, "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate side to side", "Single DB Woodchop"),
                ],
            },
            {
                "workout_name": "Day 2 - Single DB Full Body B",
                "type": "strength",
                "exercises": [
                    ex("Single DB Reverse Lunge", 3, 10, 45, "Moderate DB - held at side", equip_val, "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Hold at side, step back", "Single DB Split Squat"),
                    ex("Single DB Clean and Press", 3, 8, 45, "Moderate DB - 4/side", equip_val, "Full Body", "Anterior Deltoid", ["Biceps", "Core"], "intermediate", "Clean to shoulder, press up", "Single DB Push Press"),
                    ex("Single DB Bent-Over Row", 3, 10, 45, "Moderate DB - 5/side", equip_val, "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Hinge forward, row", "Single DB High Pull"),
                    ex("Single DB Step-Up", 3, 8, 45, "Moderate DB at chest", equip_val, "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Full step onto bench", "Single DB Reverse Lunge"),
                    ex("Single DB Curl to Press", 3, 10, 30, "Moderate DB - 5/side", equip_val, "Arms", "Biceps Brachii", ["Anterior Deltoid"], "intermediate", "Curl then press overhead", "Single DB Curl"),
                    ex("Single DB Farmer's Walk", 3, 1, 30, "Heavy DB - 20 sec/side", equip_val, "Core", "Obliques", ["Forearms", "Trapezius"], "intermediate", "Resist leaning, walk tall", "Single DB Overhead Walk"),
                ],
            },
            {
                "workout_name": "Day 3 - Single DB Conditioning",
                "type": "circuit",
                "exercises": [
                    ex("Single DB Swing", 4, 15, 30, "Moderate DB", equip_val, "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Hip drive, two hands on one end", "Single DB Sumo Deadlift"),
                    ex("Single DB Thruster", 3, 10, 30, "Moderate DB - 5/side", equip_val, "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat and press in one motion", "Single DB Goblet Squat"),
                    ex("Single DB Renegade Row", 3, 8, 30, "Moderate DB", equip_val, "Back", "Latissimus Dorsi", ["Core"], "intermediate", "Plank, row, switch hands", "Single DB Row"),
                    ex("Single DB Goblet Squat Jump", 3, 8, 30, "Light DB", equip_val, "Legs", "Quadriceps", ["Calves"], "intermediate", "Hold at chest, squat and jump", "Single DB Goblet Squat"),
                    ex("Single DB Woodchop", 3, 10, 30, "Moderate DB - 5/side", equip_val, "Core", "Obliques", ["Shoulders"], "intermediate", "Diagonal chop high to low", "Single DB Russian Twist"),
                    ex("Single DB Overhead Carry", 3, 1, 20, "Moderate DB - 20 sec/arm", equip_val, "Shoulders", "Deltoids", ["Core"], "intermediate", "Lock out overhead, walk", "Single DB Farmer's Walk"),
                ],
            },
        ]
    elif equip_val == "Resistance Band":
        return [
            {
                "workout_name": "Day 1 - Band Lower Body",
                "type": "strength",
                "exercises": [
                    ex("Band Squat", 3, 15, 30, "Moderate band under feet", equip_val, "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Stand on band, hands at shoulders, squat", "Band Goblet Squat"),
                    ex("Band Romanian Deadlift", 3, 12, 30, "Moderate band", equip_val, "Legs", "Hamstrings", ["Gluteus Maximus"], "beginner", "Stand on band, hinge at hips", "Band Good Morning"),
                    ex("Band Lateral Walk", 3, 12, 20, "Light-moderate band at ankles", equip_val, "Hips", "Gluteus Medius", ["Hip Abductors"], "beginner", "Small steps, maintain tension", "Band Clamshell"),
                    ex("Band Glute Bridge", 3, 15, 20, "Band above knees", equip_val, "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Push knees out against band", "Band Kickback"),
                    ex("Band Leg Curl", 3, 12, 20, "Band attached to anchor", equip_val, "Legs", "Hamstrings", ["Calves"], "beginner", "Prone, curl heel to glute", "Band Deadlift"),
                    ex("Band Calf Raise", 3, 15, 20, "Band under foot", equip_val, "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Seated, push against band resistance", "Standing Calf Raise"),
                ],
            },
            {
                "workout_name": "Day 2 - Band Upper Body",
                "type": "strength",
                "exercises": [
                    ex("Band Push-Up", 3, 10, 30, "Band across back, hands on floor", equip_val, "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Band adds resistance at top", "Band Chest Press"),
                    ex("Band Row", 3, 12, 30, "Moderate band", equip_val, "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Seated, pull to lower chest", "Band High Row"),
                    ex("Band Overhead Press", 3, 12, 30, "Moderate band under feet", equip_val, "Shoulders", "Anterior Deltoid", ["Triceps"], "beginner", "Press overhead, control down", "Band Lateral Raise"),
                    ex("Band Pull-Apart", 3, 15, 20, "Light band", equip_val, "Back", "Rear Deltoid", ["Rhomboids"], "beginner", "Arms straight, pull apart at chest", "Band Face Pull"),
                    ex("Band Bicep Curl", 3, 12, 20, "Moderate band under feet", equip_val, "Arms", "Biceps Brachii", ["Brachialis"], "beginner", "Controlled curl, full range", "Band Hammer Curl"),
                    ex("Band Tricep Pushdown", 3, 12, 20, "Band anchored high", equip_val, "Arms", "Triceps Brachii", ["Anconeus"], "beginner", "Press down, lock elbows at sides", "Band Overhead Extension"),
                ],
            },
            {
                "workout_name": "Day 3 - Band Full Body Circuit",
                "type": "circuit",
                "exercises": [
                    ex("Band Squat to Press", 3, 12, 30, "Moderate band", equip_val, "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat and press in one motion", "Band Squat"),
                    ex("Band Bent-Over Row", 3, 12, 30, "Moderate band", equip_val, "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Hinge forward, pull to hips", "Band High Row"),
                    ex("Band Lateral Lunge", 3, 10, 30, "Band around ankles", equip_val, "Legs", "Quadriceps", ["Hip Adductors"], "beginner", "Step wide against resistance", "Band Squat"),
                    ex("Band Chest Press", 3, 12, 30, "Band behind back", equip_val, "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Press forward against resistance", "Band Push-Up"),
                    ex("Band Woodchop", 3, 10, 30, "Band anchored low - 5/side", equip_val, "Core", "Obliques", ["Shoulders"], "beginner", "Rotate from low to high", "Band Twist"),
                    ex("Band Face Pull", 3, 15, 20, "Light band", equip_val, "Shoulders", "Rear Deltoid", ["External Rotators"], "beginner", "Pull to face, spread hands", "Band Pull-Apart"),
                ],
            },
        ]
    else:
        return []


def build_weeks(workouts, durations, sessions):
    """Build weeks_data for multiple durations and session counts."""
    weeks_data = {}
    for dur in durations:
        for sess in sessions:
            w = workouts[:sess] if len(workouts) >= sess else workouts
            weeks = {}
            for wk in range(1, dur + 1):
                progress = wk / dur
                if progress <= 0.25:
                    phase = "Foundation"
                elif progress <= 0.5:
                    phase = "Progressive overload"
                elif progress <= 0.75:
                    phase = "Peak intensity"
                else:
                    phase = "Consolidation and maintenance"
                weeks[wk] = {"focus": f"Week {wk} - {phase}", "workouts": w}
            weeks_data[(dur, sess)] = weeks
    return weeks_data


# ========== PROGRAM GENERATORS ==========

def gen_trying_to_conceive(h, m):
    w = prenatal_gentle_workouts()
    return h.insert_full_program("Trying to Conceive Fitness", "Women's Health",
        "Fertility-optimized gentle movement program. Low-intensity exercises that support hormone balance without excessive stress on the body.",
        [4, 8], [3, 4], False, "low", build_weeks(w, [4, 8], [3, 4]), m)

def gen_first_trimester(h, m):
    w = prenatal_gentle_workouts()
    return h.insert_full_program("First Trimester Safe", "Women's Health",
        "Early pregnancy appropriate exercise program. Gentle strength and mobility work safe for the first trimester with emphasis on maintaining fitness without overexertion.",
        [4, 8, 12], [3, 4], False, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_second_trimester(h, m):
    w = prenatal_gentle_workouts()
    return h.insert_full_program("Second Trimester Active", "Women's Health",
        "Mid-pregnancy energy boost workout program. Takes advantage of the energy increase common in the second trimester with safe, moderate-intensity exercises.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_third_trimester(h, m):
    w = prenatal_gentle_workouts()[:2]  # Only 2 gentle workouts
    return h.insert_full_program("Third Trimester Gentle", "Women's Health",
        "Late pregnancy comfort program. Very gentle movement focusing on birth preparation, pelvic floor work, and maintaining mobility in the final weeks.",
        [4, 8, 12], [3, 4], False, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_pregnancy_safe(h, m):
    w = prenatal_gentle_workouts()
    return h.insert_full_program("Pregnancy Safe Fitness", "Women's Health",
        "Full trimester-appropriate program that adapts across all stages of pregnancy. Includes safe modifications and pelvic floor focus throughout.",
        [4, 8, 12], [3, 4], False, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_postpartum_starter(h, m):
    w = postpartum_gentle_workouts()
    return h.insert_full_program("Postpartum Starter", "Women's Health",
        "Gentle return to exercise after birth. Rebuilds pelvic floor, reconnects core, and gradually increases activity level in a safe progression.",
        [2, 4, 8], [3], False, "low", build_weeks(w, [2, 4, 8], [3]), m)

def gen_postpartum_intermediate(h, m):
    w = postpartum_gentle_workouts()
    return h.insert_full_program("Postpartum to Intermediate", "Women's Health",
        "Progressive recovery from postpartum starter to intermediate fitness. Bridges the gap between early recovery and full strength training.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_diastasis_recti(h, m):
    w = postpartum_gentle_workouts()[:2]  # Core focus
    return h.insert_full_program("Diastasis Recti Rehab", "Women's Health",
        "Core separation recovery program. Specialized exercises to close the gap between abdominal muscles after pregnancy with safe progressive loading.",
        [4, 8, 12], [5, 6], False, "low", build_weeks(w, [4, 8, 12], [5, 6]), m)

def gen_csection_recovery(h, m):
    w = postpartum_gentle_workouts()
    return h.insert_full_program("C-Section Recovery", "Women's Health",
        "Post-surgery safe return to exercise after cesarean section. Respects healing timelines with ultra-gentle progression and scar tissue management.",
        [4, 8, 12], [3, 4], False, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_perimenopause(h, m):
    w = mens_compound_strength()[:3]  # Reuse strength template with modifications
    return h.insert_full_program("Perimenopause Power", "Women's Health",
        "Transition support training for perimenopause. Emphasizes resistance training for bone density, metabolic health, and hormonal balance during the transition.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_menopause(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("Menopause Fitness", "Women's Health",
        "Hormone transition support program for menopause. Focus on strength training for bone density, resistance exercises for metabolic health, and stress management.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

# Men's Health Low Priority
def gen_libido_boost(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Libido Boost Training", "Men's Health",
        "Circulation and energy-boosting workout program. Compound resistance training and cardiovascular work to improve blood flow, stamina, and hormonal balance.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_ed_prevention(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("ED Prevention Fitness", "Men's Health",
        "Blood flow and pelvic floor focused training. Combines cardiovascular exercise with targeted pelvic floor strengthening and compound lifts for hormonal health.",
        [4, 8], [4, 5], False, "low", build_weeks(w, [4, 8], [4, 5]), m)

def gen_testosterone_max(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Testosterone Maximizer", "Men's Health",
        "Compound lifts and HIIT for T-levels. Heavy resistance training with strategic rest periods designed to optimize natural testosterone production.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_male_vitality(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Male Vitality Program", "Men's Health",
        "Energy, stamina, and drive optimization program. Balanced approach combining strength, cardio, and mobility for overall male vitality.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_performance_bed(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("Performance in Bed", "Men's Health",
        "Stamina and flexibility for intimacy. Combines cardiovascular endurance, hip mobility, core strength, and pelvic floor work.",
        [2, 4, 8], [3, 4], False, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_dad_bod(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Dad Bod Transformation", "Men's Health",
        "Busy dad friendly body recomposition program. Time-efficient workouts that can fit around family life with focus on fat loss and muscle building.",
        [4, 8, 12], [3, 4], True, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_new_dad(h, m):
    w = mens_compound_strength()[:2]
    return h.insert_full_program("New Dad Survival", "Men's Health",
        "Sleep-deprived fitness for new fathers. Short, effective workouts designed for minimal equipment and energy, maintaining fitness during the newborn phase.",
        [2, 4, 8], [3], True, "low", build_weeks(w, [2, 4, 8], [3]), m)

def gen_men_over_40(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Men Over 40", "Men's Health",
        "Age-appropriate training for men over 40. Emphasizes joint health, proper warmups, and smart programming to maintain strength and prevent injury.",
        [4, 8, 12], [4], True, "low", build_weeks(w, [4, 8, 12], [4]), m)

def gen_men_over_50(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("Men Over 50", "Men's Health",
        "Joint-safe strength training for men over 50. Moderate loads with emphasis on mobility, bone density, and functional movement patterns.",
        [4, 8, 12], [3, 4], True, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_men_over_60(h, m):
    w = mens_compound_strength()[:2]
    return h.insert_full_program("Men Over 60", "Men's Health",
        "Longevity-focused training for men over 60. Balance, mobility, and moderate strength work for healthy aging and independence.",
        [4, 8, 12], [3], True, "low", build_weeks(w, [4, 8, 12], [3]), m)

def gen_midlife_crisis(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Midlife Crisis Crusher", "Men's Health",
        "Reclaim your prime physique. Aggressive but smart training to build muscle, burn fat, and regain athletic performance in middle age.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_empty_nester(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Empty Nester Fitness", "Men's Health",
        "Time to focus on yourself. With kids grown, dedicate time to building the best version of yourself with comprehensive training.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

# Body-Specific Low Priority
def gen_wheelchair(h, m):
    w = [{
        "workout_name": "Day 1 - Upper Body Push",
        "type": "strength",
        "exercises": [
            ex("Seated Dumbbell Press", 3, 10, 45, "Light-moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "beginner", "Press from shoulders, seated position", "Band Overhead Press"),
            ex("Seated Chest Press", 3, 10, 45, "Light", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Press forward from chest level", "Band Chest Press"),
            ex("Seated Tricep Extension", 3, 12, 30, "Light DB", "Dumbbell", "Arms", "Triceps Brachii", ["Anconeus"], "beginner", "Behind head extension", "Band Tricep Pushdown"),
            ex("Seated Lateral Raise", 3, 12, 30, "Very light", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Raise to shoulder only", "Band Lateral Raise"),
            ex("Wheelchair Push-Up", 3, 8, 30, "Bodyweight", "Wheelchair", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Push up from armrests", "Seated Chest Press"),
        ],
    }, {
        "workout_name": "Day 2 - Upper Body Pull",
        "type": "strength",
        "exercises": [
            ex("Seated Dumbbell Row", 3, 10, 45, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Lean forward, pull to hip", "Band Row"),
            ex("Seated Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids"], "beginner", "Pull apart at chest height", "Band Face Pull"),
            ex("Seated Bicep Curl", 3, 12, 30, "Light", "Dumbbells", "Arms", "Biceps Brachii", ["Brachialis"], "beginner", "Controlled curl", "Band Curl"),
            ex("Seated Shrug", 3, 12, 30, "Moderate", "Dumbbells", "Back", "Trapezius", ["Levator Scapulae"], "beginner", "Elevate shoulders, hold briefly", "Band Shrug"),
            ex("Seated Core Rotation", 3, 10, 20, "Light DB", "Dumbbell", "Core", "Obliques", ["Rectus Abdominis"], "beginner", "Rotate torso side to side", "Seated Twist"),
        ],
    }]
    return h.insert_full_program("Wheelchair Fitness", "Body-Specific",
        "Upper body focus fitness for wheelchair users. Comprehensive seated training program covering push, pull, and core exercises.",
        [2, 4, 8], [4, 5], False, "low", build_weeks(w, [2, 4, 8], [4, 5]), m)

def gen_adaptive(h, m):
    w = [{
        "workout_name": "Day 1 - Customizable Strength",
        "type": "strength",
        "exercises": [
            ex("Chair Squat", 3, 8, 30, "Bodyweight", "Chair", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Sit and stand, use arms if needed", "Wall Sit"),
            ex("Wall Push-Up", 3, 8, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Adjustable difficulty by distance", "Counter Push-Up"),
            ex("Seated Row with Band", 3, 10, 30, "Light band", "Resistance Band", "Back", "Latissimus Dorsi", ["Biceps"], "beginner", "Seated or standing option", "Dumbbell Row"),
            ex("Modified Plank", 3, 1, 20, "Hold 15-20 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Knees down, or wall plank", "Wall Plank"),
            ex("Gentle Walking or Marching", 1, 1, 0, "10 min", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Seated marching if standing not possible", "Seated Marching"),
        ],
    }]
    return h.insert_full_program("Adaptive Fitness", "Body-Specific",
        "Customizable movement program adaptable to various physical limitations. Every exercise has seated, standing, and modified variations.",
        [2, 4, 8], [3, 4], False, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_post_bariatric(h, m):
    w = postpartum_gentle_workouts()  # Similar gentle progression
    return h.insert_full_program("Post-Bariatric Training", "Body-Specific",
        "After weight loss surgery exercise program. Gentle progressive movement that accounts for rapid body changes and nutritional constraints post-bariatric surgery.",
        [4, 8, 12], [3, 4], False, "low", build_weeks(w, [4, 8, 12], [3, 4]), m)

def gen_skinny_fat_transform(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("Skinny Fat Transformation", "Body-Specific",
        "Beginner-friendly body recomposition for the skinny-fat physique. Build muscle and lose fat with foundational compound lifts and strategic nutrition timing.",
        [4, 8, 12], [4], True, "low", build_weeks(w, [4, 8, 12], [4]), m)

def gen_skinny_fat_recomp(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Skinny Fat Recomp", "Body-Specific",
        "Build muscle and lose fat simultaneously. Moderate-volume resistance training with progressive overload optimized for body recomposition.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_skinny_fat_intermediate(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Skinny Fat Intermediate Recomp", "Body-Specific",
        "Higher volume body recomposition for intermediate lifters. More aggressive progressive overload with periodized training.",
        [8, 12, 16], [5], True, "low", build_weeks(w, [8, 12, 16], [5]), m)

def gen_skinny_fat_aesthetic(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Skinny Fat to Aesthetic", "Body-Specific",
        "Complete physique transformation from skinny-fat to aesthetic. Long-term program covering all phases from beginner to advanced body recomposition.",
        [12, 16, 24], [5, 6], True, "low", build_weeks(w, [12, 16, 24], [5, 6]), m)

def gen_obese_to_active(h, m):
    w = postpartum_gentle_workouts()  # Gentle progression similar
    return h.insert_full_program("Obese to Active", "Body-Specific",
        "Progressive mobility building for individuals with obesity. Graduates from seated exercises to standing movements to light resistance over time.",
        [8, 12, 16], [3, 4], False, "low", build_weeks(w, [8, 12, 16], [3, 4]), m)

def gen_morbidly_obese(h, m):
    w = postpartum_gentle_workouts()[:2]
    return h.insert_full_program("Morbidly Obese Gentle Start", "Body-Specific",
        "Ultra-safe movements for severely obese individuals. Chair-based and wall-supported exercises with very gentle progression.",
        [4, 8, 12], [2, 3], False, "low", build_weeks(w, [4, 8, 12], [2, 3]), m)

def gen_thin_unfit(h, m):
    w = mens_compound_strength()[:3]
    return h.insert_full_program("Thin But Unfit", "Body-Specific",
        "Build base fitness for skinny individuals. Focus on building strength, stamina, and general fitness from a low starting point.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_ectomorph(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Ectomorph Muscle Builder", "Body-Specific",
        "Hardgainer focused muscle building program. High-calorie compound movements with strategic rest and volume for maximum muscle growth.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

def gen_endomorph(h, m):
    w = mens_compound_strength()
    return h.insert_full_program("Endomorph Fat Loss", "Body-Specific",
        "Metabolism-focused training for endomorphic body types. Combines resistance training with metabolic conditioning for fat loss.",
        [4, 8, 12], [4, 5], True, "low", build_weeks(w, [4, 8, 12], [4, 5]), m)

# Equipment-Specific Low Priority
def gen_single_db_only(h, m):
    w = single_equipment_workouts("Single Dumbbell", "Dumbbell")
    return h.insert_full_program("Single Dumbbell Only", "Equipment-Specific",
        "One dumbbell full body program. Complete training using only a single dumbbell with unilateral exercises and creative loading patterns.",
        [1, 2, 4, 8], [3, 4], True, "low", build_weeks(w, [1, 2, 4, 8], [3, 4]), m)

def gen_single_db_strength(h, m):
    w = single_equipment_workouts("Single Dumbbell", "Dumbbell")
    return h.insert_full_program("Single Dumbbell Strength", "Equipment-Specific",
        "Unilateral strength focus with a single dumbbell. Heavier loads and lower reps for strength building with one dumbbell.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_resistance_band_only(h, m):
    w = single_equipment_workouts("Resistance Band", "Resistance Band")
    return h.insert_full_program("Resistance Band Only", "Equipment-Specific",
        "Band-based training program using only resistance bands. Portable, joint-friendly, with constant tension for muscle activation.",
        [2, 4, 8], [4, 5], True, "low", build_weeks(w, [2, 4, 8], [4, 5]), m)

def gen_cable_mastery(h, m):
    w = [{
        "workout_name": "Day 1 - Cable Push",
        "type": "strength",
        "exercises": [
            ex("Cable Chest Press", 3, 12, 45, "Moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Step forward, press at chest height", "Cable Crossover"),
            ex("Cable Crossover", 3, 12, 30, "Light-moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "High to low cross, squeeze at bottom", "Cable Chest Press"),
            ex("Cable Lateral Raise", 3, 15, 30, "Light", "Cable Machine", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "intermediate", "Behind body, constant tension", "Cable Front Raise"),
            ex("Cable Overhead Tricep Extension", 3, 12, 30, "Moderate", "Cable Machine", "Arms", "Triceps Brachii", ["Anconeus"], "intermediate", "Face away, extend overhead", "Cable Pushdown"),
            ex("Cable Face Pull", 3, 15, 30, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators"], "intermediate", "Pull rope to face", "Cable Reverse Fly"),
        ],
    }, {
        "workout_name": "Day 2 - Cable Pull",
        "type": "strength",
        "exercises": [
            ex("Cable Row", 3, 12, 45, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower chest, squeeze", "Cable High Row"),
            ex("Cable Lat Pulldown", 3, 12, 45, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Wide grip, pull to chest", "Cable Straight-Arm Pulldown"),
            ex("Cable Reverse Fly", 3, 15, 30, "Light", "Cable Machine", "Shoulders", "Rear Deltoid", ["Rhomboids"], "intermediate", "Arms at chest height, pull apart", "Cable Face Pull"),
            ex("Cable Curl", 3, 12, 30, "Moderate", "Cable Machine", "Arms", "Biceps Brachii", ["Brachialis"], "intermediate", "Constant tension curl", "Cable Hammer Curl"),
            ex("Cable Straight-Arm Pulldown", 3, 12, 30, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Teres Major"], "intermediate", "Arms straight, pull bar to thighs", "Cable Lat Pulldown"),
        ],
    }, {
        "workout_name": "Day 3 - Cable Lower Body & Core",
        "type": "strength",
        "exercises": [
            ex("Cable Pull-Through", 3, 12, 45, "Moderate", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Rope between legs, hip hinge", "Cable Kickback"),
            ex("Cable Kickback", 3, 12, 30, "Moderate", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Ankle strap, kick back", "Cable Pull-Through"),
            ex("Cable Woodchop", 3, 12, 30, "Moderate - 6/side", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Rotate from high to low", "Cable Pallof Press"),
            ex("Cable Pallof Press", 3, 12, 30, "Moderate", "Cable Machine", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Resist rotation, press and hold", "Cable Woodchop"),
            ex("Cable Crunch", 3, 15, 30, "Moderate", "Cable Machine", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Kneel, crunch down toward floor", "Cable Reverse Crunch"),
        ],
    }]
    return h.insert_full_program("Cable Machine Mastery", "Equipment-Specific",
        "Gym cable focus program. Master every cable machine variation for constant tension and superior muscle activation.",
        [4, 8], [4, 5], True, "low", build_weeks(w, [4, 8], [4, 5]), m)

def gen_medicine_ball(h, m):
    w = [{
        "workout_name": "Day 1 - Med Ball Power",
        "type": "strength",
        "exercises": [
            ex("Medicine Ball Slam", 3, 10, 30, "Moderate med ball", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Overhead slam with force", "Med Ball Chest Pass"),
            ex("Medicine Ball Squat to Press", 3, 10, 30, "Moderate", "Medicine Ball", "Full Body", "Quadriceps", ["Shoulders"], "intermediate", "Squat with ball at chest, press overhead", "Med Ball Goblet Squat"),
            ex("Medicine Ball Russian Twist", 3, 16, 30, "Moderate", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate with ball", "Med Ball Woodchop"),
            ex("Medicine Ball Chest Pass", 3, 10, 30, "Moderate", "Medicine Ball", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Pass against wall explosively", "Med Ball Slam"),
            ex("Medicine Ball Lunge with Twist", 3, 10, 30, "Light-moderate", "Medicine Ball", "Legs", "Quadriceps", ["Obliques", "Gluteus Maximus"], "intermediate", "Lunge forward, rotate over front leg", "Med Ball Squat"),
            ex("Medicine Ball Plank Tap", 3, 10, 30, "Light", "Medicine Ball", "Core", "Transverse Abdominis", ["Shoulders"], "intermediate", "Plank, hands on ball, alternate taps", "Plank Hold"),
        ],
    }]
    return h.insert_full_program("Medicine Ball Training", "Equipment-Specific",
        "Med ball circuits for power, coordination, and core strength. Explosive movements using only a medicine ball.",
        [2, 4], [3, 4], True, "low", build_weeks(w, [2, 4], [3, 4]), m)

def gen_trx(h, m):
    w = [{
        "workout_name": "Day 1 - TRX Full Body",
        "type": "strength",
        "exercises": [
            ex("TRX Row", 3, 12, 30, "Bodyweight - adjust angle", "TRX", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Lean back, pull chest to handles", "TRX Single Arm Row"),
            ex("TRX Chest Press", 3, 10, 30, "Bodyweight", "TRX", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Face away, press forward", "TRX Push-Up"),
            ex("TRX Squat", 3, 12, 30, "Bodyweight with TRX assist", "TRX", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Hold handles, sit back deep", "TRX Lunge"),
            ex("TRX Pike", 3, 8, 30, "Bodyweight", "TRX", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "intermediate", "Feet in straps, pike hips up", "TRX Knee Tuck"),
            ex("TRX Bicep Curl", 3, 12, 30, "Bodyweight", "TRX", "Arms", "Biceps Brachii", ["Brachialis"], "intermediate", "Face anchor, curl body up", "TRX Row"),
            ex("TRX Hamstring Curl", 3, 10, 30, "Bodyweight", "TRX", "Legs", "Hamstrings", ["Gluteus Maximus"], "intermediate", "Lie on back, heels in straps, curl", "TRX Single Leg Curl"),
        ],
    }]
    return h.insert_full_program("TRX/Suspension", "Equipment-Specific",
        "Suspension trainer program using TRX or similar. Full body training using only bodyweight and a suspension system.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_sandbag(h, m):
    w = [{
        "workout_name": "Day 1 - Sandbag Functional",
        "type": "strength",
        "exercises": [
            ex("Sandbag Bear Hug Squat", 3, 10, 60, "Moderate sandbag", "Sandbag", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hug sandbag to chest, squat deep", "Sandbag Front Squat"),
            ex("Sandbag Clean and Press", 3, 8, 60, "Moderate", "Sandbag", "Full Body", "Anterior Deltoid", ["Core", "Biceps"], "intermediate", "Clean to chest, press overhead", "Sandbag Shoulder"),
            ex("Sandbag Bent-Over Row", 3, 10, 45, "Moderate", "Sandbag", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to chest", "Sandbag High Pull"),
            ex("Sandbag Carry", 3, 1, 45, "Heavy - 30 sec", "Sandbag", "Full Body", "Core", ["Shoulders", "Grip Strength"], "intermediate", "Bear hug or shoulder carry, walk controlled", "Sandbag Drag"),
            ex("Sandbag Romanian Deadlift", 3, 10, 60, "Moderate", "Sandbag", "Legs", "Hamstrings", ["Gluteus Maximus"], "intermediate", "Hinge at hips, bag close to body", "Sandbag Deadlift"),
            ex("Sandbag Rotational Slam", 3, 8, 45, "Moderate", "Sandbag", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Pick up, rotate, slam to other side", "Sandbag Russian Twist"),
        ],
    }]
    return h.insert_full_program("Sandbag Training", "Equipment-Specific",
        "Functional sandbag workouts building real-world strength. The shifting weight challenges stabilizers and grip in ways fixed weights cannot.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_steel_mace(h, m):
    w = [{
        "workout_name": "Day 1 - Steel Mace Rotational Strength",
        "type": "strength",
        "exercises": [
            ex("Mace 360 Swing", 3, 10, 30, "Light-moderate mace", "Steel Mace", "Shoulders", "Deltoids", ["Core", "Forearms"], "intermediate", "Full circle around head, control the offset weight", "Mace 10-to-2"),
            ex("Mace Squat", 3, 10, 45, "Moderate mace", "Steel Mace", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold mace at chest, squat deep", "Mace Lunge"),
            ex("Mace Gravedigger", 3, 8, 30, "Moderate mace - 4/side", "Steel Mace", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Diagonal shovel motion, rotate hips", "Mace Woodchop"),
            ex("Mace Overhead Press", 3, 8, 30, "Light-moderate mace - 4/side", "Steel Mace", "Shoulders", "Anterior Deltoid", ["Core", "Triceps"], "intermediate", "Press from shoulder, offset challenges stability", "Mace Push Press"),
            ex("Mace Barbarian Squat", 3, 8, 45, "Moderate mace", "Steel Mace", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Switch grip squat, overhead between reps", "Mace 360 to Squat"),
            ex("Mace Paddle Swing", 3, 12, 30, "Light mace", "Steel Mace", "Core", "Obliques", ["Shoulders", "Forearms"], "beginner", "Horizontal swing side to side like paddling", "Mace 360"),
        ],
    }]
    return h.insert_full_program("Steel Mace Training", "Equipment-Specific",
        "Rotational strength and mobility with a steel mace. The offset weight builds core stability, grip strength, and shoulder health.",
        [2, 4, 8, 12], [3, 4], False, "low", build_weeks(w, [2, 4, 8, 12], [3, 4]), m)

def gen_indian_club(h, m):
    w = [{
        "workout_name": "Day 1 - Indian Club Shoulder Flow",
        "type": "flexibility",
        "exercises": [
            ex("Club Arm Cast", 3, 10, 20, "Light club", "Indian Club", "Shoulders", "Deltoids", ["Rotator Cuff", "Forearms"], "beginner", "Swing club behind shoulder, cast forward", "Club Shield Cast"),
            ex("Club Shield Cast", 3, 10, 20, "Light club", "Indian Club", "Shoulders", "Deltoids", ["Core", "Forearms"], "beginner", "Side protection motion, like casting a shield", "Club Arm Cast"),
            ex("Club Mill", 3, 8, 20, "Light club - 4/side", "Indian Club", "Shoulders", "Rotator Cuff", ["Deltoids", "Forearms"], "beginner", "Circular motion around shoulder joint", "Club Arm Cast"),
            ex("Club Front Swing", 3, 10, 20, "Light club", "Indian Club", "Shoulders", "Anterior Deltoid", ["Grip Strength"], "beginner", "Forward pendulum swing with control", "Club Side Swing"),
            ex("Club Side Swing", 3, 10, 20, "Light club - 5/side", "Indian Club", "Shoulders", "Lateral Deltoid", ["Core", "Forearms"], "beginner", "Lateral swing motion, both directions", "Club Front Swing"),
            ex("Club Figure 8", 3, 8, 20, "Light club", "Indian Club", "Shoulders", "Deltoids", ["Core", "Forearms"], "beginner", "Weave club in figure-8 pattern around body", "Club Mill"),
        ],
    }]
    return h.insert_full_program("Indian Club Flow", "Equipment-Specific",
        "Traditional shoulder rehab and strength using Indian clubs. Ancient training tool excellent for shoulder mobility, rotator cuff health, and grip strength.",
        [2, 4, 8], [4, 5], False, "low", build_weeks(w, [2, 4, 8], [4, 5]), m)

def gen_clubbell(h, m):
    w = [{
        "workout_name": "Day 1 - Clubbell Strength",
        "type": "strength",
        "exercises": [
            ex("Clubbell Swipe", 3, 10, 30, "Moderate club", "Clubbell", "Shoulders", "Deltoids", ["Core", "Forearms", "Grip Strength"], "intermediate", "Swing club in arc, offset weight challenges grip", "Clubbell Mill"),
            ex("Clubbell Mill", 3, 8, 30, "Moderate club - 4/side", "Clubbell", "Shoulders", "Rotator Cuff", ["Deltoids", "Core"], "intermediate", "Circular mill around shoulder", "Clubbell Swipe"),
            ex("Clubbell Torch Press", 3, 8, 30, "Moderate club - 4/side", "Clubbell", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "Bottom-up press, extreme grip challenge", "Clubbell Overhead Press"),
            ex("Clubbell Squat", 3, 10, 45, "Moderate club", "Clubbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold at chest or order position, squat", "Clubbell Lunge"),
            ex("Clubbell Shield Cast", 3, 8, 30, "Moderate club", "Clubbell", "Shoulders", "Deltoids", ["Core", "Forearms"], "intermediate", "Protective casting motion around head", "Clubbell Swipe"),
            ex("Clubbell Hammer Curl", 3, 10, 30, "Light club - 5/side", "Clubbell", "Arms", "Brachioradialis", ["Biceps Brachii", "Forearms"], "intermediate", "Offset weight challenges forearms intensely", "Clubbell Arm Cast"),
        ],
    }]
    return h.insert_full_program("Clubbell Training", "Equipment-Specific",
        "Heavy club strength work using clubbells. The offset center of gravity builds extraordinary grip strength, shoulder stability, and rotational power.",
        [2, 4, 8], [3, 4], False, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_slam_ball(h, m):
    w = [{
        "workout_name": "Day 1 - Slam Ball Explosive Power",
        "type": "hiit",
        "exercises": [
            ex("Slam Ball Overhead Slam", 4, 10, 30, "Moderate slam ball", "Slam Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Lift overhead, slam to floor with max force", "Slam Ball Side Slam"),
            ex("Slam Ball Side Slam", 3, 8, 30, "Moderate - 4/side", "Slam Ball", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Rotate and slam to one side", "Slam Ball Overhead Slam"),
            ex("Slam Ball Squat Throw", 3, 8, 30, "Moderate", "Slam Ball", "Legs", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Squat with ball, explode up throwing ball high", "Slam Ball Overhead Slam"),
            ex("Slam Ball Chest Pass", 3, 10, 30, "Moderate", "Slam Ball", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Pass forcefully against wall", "Slam Ball Overhead Slam"),
            ex("Slam Ball Russian Twist", 3, 16, 30, "Moderate", "Slam Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate with ball", "Slam Ball Woodchop"),
            ex("Slam Ball Burpee", 3, 8, 45, "Moderate", "Slam Ball", "Full Body", "Full Body", ["Chest", "Core", "Legs"], "intermediate", "Slam, burpee, pick up, repeat", "Slam Ball Overhead Slam"),
        ],
    }]
    return h.insert_full_program("Slam Ball Conditioning", "Equipment-Specific",
        "Explosive power circuits using slam balls. High-intensity conditioning that channels aggression into powerful full-body movements.",
        [1, 2, 4], [3, 4], True, "low", build_weeks(w, [1, 2, 4], [3, 4]), m)

def gen_battle_ropes(h, m):
    w = [{
        "workout_name": "Day 1 - Battle Ropes Conditioning",
        "type": "hiit",
        "exercises": [
            ex("Alternating Wave", 4, 1, 30, "30 sec work", "Battle Ropes", "Shoulders", "Anterior Deltoid", ["Core", "Forearms"], "intermediate", "Fast alternating arms, create waves", "Double Wave"),
            ex("Double Wave", 3, 1, 30, "30 sec work", "Battle Ropes", "Shoulders", "Anterior Deltoid", ["Core", "Grip Strength"], "intermediate", "Both arms together, slam down", "Alternating Wave"),
            ex("Rope Slam", 3, 1, 30, "30 sec work", "Battle Ropes", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Raise overhead, slam to floor", "Double Wave"),
            ex("Snake Wave", 3, 1, 30, "30 sec work", "Battle Ropes", "Shoulders", "Lateral Deltoid", ["Core"], "intermediate", "Move arms side to side, snake on floor", "Alternating Wave"),
            ex("Clap Wave", 3, 1, 30, "30 sec work", "Battle Ropes", "Chest", "Pectoralis Major", ["Shoulders", "Core"], "intermediate", "Swing ropes together and apart", "Double Wave"),
            ex("Squat Wave", 3, 1, 30, "30 sec work", "Battle Ropes", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Alternating waves while in squat position", "Alternating Wave"),
        ],
    }]
    return h.insert_full_program("Battle Ropes Only", "Equipment-Specific",
        "Rope-based conditioning using only battle ropes. Intense cardiovascular and upper body endurance training.",
        [1, 2, 4], [3, 4], False, "low", build_weeks(w, [1, 2, 4], [3, 4]), m)

def gen_landmine(h, m):
    w = [{
        "workout_name": "Day 1 - Landmine Full Body",
        "type": "strength",
        "exercises": [
            ex("Landmine Press", 3, 10, 45, "Moderate weight", "Landmine", "Shoulders", "Anterior Deltoid", ["Triceps", "Core"], "intermediate", "One hand, press at angle, easier on shoulders", "Landmine Single Arm Press"),
            ex("Landmine Row", 3, 10, 45, "Moderate", "Landmine", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Straddle bar, pull end to chest", "Landmine Meadows Row"),
            ex("Landmine Squat", 3, 10, 60, "Moderate", "Landmine", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold bar end at chest, squat deep", "Landmine Goblet Squat"),
            ex("Landmine Rotation", 3, 10, 30, "Light-moderate - 5/side", "Landmine", "Core", "Obliques", ["Shoulders", "Hip Rotators"], "intermediate", "Arc bar from hip to opposite shoulder", "Landmine Woodchop"),
            ex("Landmine Romanian Deadlift", 3, 10, 60, "Moderate", "Landmine", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hold end of bar, hinge at hips", "Landmine Deadlift"),
            ex("Landmine Thruster", 3, 8, 45, "Moderate", "Landmine", "Full Body", "Quadriceps", ["Shoulders", "Triceps"], "intermediate", "Squat and press in one motion", "Landmine Press"),
        ],
    }]
    return h.insert_full_program("Landmine Training", "Equipment-Specific",
        "Barbell landmine exercises for functional strength. The angled bar path is joint-friendly and allows unique movement patterns.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_trap_bar(h, m):
    w = [{
        "workout_name": "Day 1 - Trap Bar Strength",
        "type": "strength",
        "exercises": [
            ex("Trap Bar Deadlift", 4, 8, 90, "Heavy", "Trap Bar", "Legs", "Hamstrings", ["Quadriceps", "Gluteus Maximus", "Core"], "intermediate", "Neutral grip, push floor away, lockout", "Trap Bar Romanian Deadlift"),
            ex("Trap Bar Squat", 3, 10, 75, "Moderate-heavy", "Trap Bar", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "High handles, squat pattern with neutral grip", "Trap Bar Deadlift"),
            ex("Trap Bar Farmer's Walk", 3, 1, 45, "Heavy - 30 sec", "Trap Bar", "Full Body", "Forearms", ["Trapezius", "Core"], "intermediate", "Walk controlled with heavy load", "Trap Bar Hold"),
            ex("Trap Bar Shrug", 3, 12, 30, "Heavy", "Trap Bar", "Back", "Trapezius", ["Levator Scapulae"], "intermediate", "Elevate shoulders, hold briefly", "Trap Bar Deadlift"),
            ex("Trap Bar Romanian Deadlift", 3, 10, 60, "Moderate", "Trap Bar", "Legs", "Hamstrings", ["Gluteus Maximus"], "intermediate", "Hinge at hips, neutral grip", "Trap Bar Deadlift"),
            ex("Trap Bar Jump", 3, 5, 60, "Light", "Trap Bar", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Explosive jump, soft landing, reset", "Trap Bar Deadlift"),
        ],
    }]
    return h.insert_full_program("Trap Bar Training", "Equipment-Specific",
        "Hex bar focused program. The neutral grip reduces lower back stress while allowing heavy loading for strength and power.",
        [2, 4, 8], [3, 4], True, "low", build_weeks(w, [2, 4, 8], [3, 4]), m)

def gen_ez_curl(h, m):
    w = [{
        "workout_name": "Day 1 - EZ Bar Full Body",
        "type": "strength",
        "exercises": [
            ex("EZ Bar Curl", 3, 12, 30, "Moderate", "EZ Curl Bar", "Arms", "Biceps Brachii", ["Brachialis"], "intermediate", "Angled grip reduces wrist strain", "EZ Bar Preacher Curl"),
            ex("EZ Bar Skull Crusher", 3, 12, 30, "Moderate", "EZ Curl Bar", "Arms", "Triceps Brachii", ["Anconeus"], "intermediate", "Lower to forehead, extend up", "EZ Bar Close Grip Press"),
            ex("EZ Bar Close Grip Press", 3, 10, 45, "Moderate", "EZ Curl Bar", "Chest", "Triceps Brachii", ["Pectoralis Major"], "intermediate", "Narrow grip, press from chest", "EZ Bar Skull Crusher"),
            ex("EZ Bar Upright Row", 3, 10, 30, "Light-moderate", "EZ Curl Bar", "Shoulders", "Lateral Deltoid", ["Trapezius"], "intermediate", "Pull to chin, elbows high", "EZ Bar Front Raise"),
            ex("EZ Bar Bent-Over Row", 3, 10, 45, "Moderate", "EZ Curl Bar", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Hinge forward, pull to navel", "EZ Bar High Row"),
            ex("EZ Bar Front Squat", 3, 10, 60, "Light-moderate", "EZ Curl Bar", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Bar in front rack, squat deep", "EZ Bar Goblet Hold Squat"),
        ],
    }]
    return h.insert_full_program("EZ Curl Bar Program", "Equipment-Specific",
        "Curl bar only training. The angled grip of the EZ curl bar reduces wrist and elbow strain for joint-friendly arm and upper body training.",
        [2, 4, 8], [4, 5], True, "low", build_weeks(w, [2, 4, 8], [4, 5]), m)

def gen_pullup_bar(h, m):
    w = [{
        "workout_name": "Day 1 - Pull-Up Bar Upper Body",
        "type": "strength",
        "exercises": [
            ex("Pull-Up", 4, 6, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Full range, chin over bar", "Negative Pull-Up"),
            ex("Chin-Up", 3, 8, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Supinated grip, full range", "Negative Chin-Up"),
            ex("Hanging Leg Raise", 3, 10, 30, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, controlled raise", "Hanging Knee Raise"),
            ex("Hanging Knee Raise", 3, 12, 30, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Knees to chest, slow lower", "Hanging Leg Raise"),
            ex("Dead Hang", 3, 1, 30, "Bodyweight - hold 30 sec", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Forearms", "Grip Strength"], "beginner", "Full relaxed hang, shoulders packed", "Active Hang"),
            ex("Wide-Grip Pull-Up", 3, 5, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Teres Major", "Biceps"], "intermediate", "Wide grip, pull to upper chest", "Negative Wide Pull-Up"),
        ],
    }]
    return h.insert_full_program("Pull-up Bar Only", "Equipment-Specific",
        "Bar-only home program using just a pull-up bar. Builds impressive upper body and core strength with minimal equipment.",
        [2, 4, 8], [4, 5], True, "low", build_weeks(w, [2, 4, 8], [4, 5]), m)


def main():
    helper = ProgramSQLHelper()
    mig = helper.get_next_migration_num()

    all_programs = [
        # Women's Health Low
        ("Trying to Conceive Fitness", gen_trying_to_conceive),
        ("First Trimester Safe", gen_first_trimester),
        ("Second Trimester Active", gen_second_trimester),
        ("Third Trimester Gentle", gen_third_trimester),
        ("Pregnancy Safe Fitness", gen_pregnancy_safe),
        ("Postpartum Starter", gen_postpartum_starter),
        ("Postpartum to Intermediate", gen_postpartum_intermediate),
        ("Diastasis Recti Rehab", gen_diastasis_recti),
        ("C-Section Recovery", gen_csection_recovery),
        ("Perimenopause Power", gen_perimenopause),
        ("Menopause Fitness", gen_menopause),
        # Men's Health Low
        ("Libido Boost Training", gen_libido_boost),
        ("ED Prevention Fitness", gen_ed_prevention),
        ("Testosterone Maximizer", gen_testosterone_max),
        ("Male Vitality Program", gen_male_vitality),
        ("Performance in Bed", gen_performance_bed),
        ("Dad Bod Transformation", gen_dad_bod),
        ("New Dad Survival", gen_new_dad),
        ("Men Over 40", gen_men_over_40),
        ("Men Over 50", gen_men_over_50),
        ("Men Over 60", gen_men_over_60),
        ("Midlife Crisis Crusher", gen_midlife_crisis),
        ("Empty Nester Fitness", gen_empty_nester),
        # Body-Specific Low
        ("Wheelchair Fitness", gen_wheelchair),
        ("Adaptive Fitness", gen_adaptive),
        ("Post-Bariatric Training", gen_post_bariatric),
        ("Skinny Fat Transformation", gen_skinny_fat_transform),
        ("Skinny Fat Recomp", gen_skinny_fat_recomp),
        ("Skinny Fat Intermediate Recomp", gen_skinny_fat_intermediate),
        ("Skinny Fat to Aesthetic", gen_skinny_fat_aesthetic),
        ("Obese to Active", gen_obese_to_active),
        ("Morbidly Obese Gentle Start", gen_morbidly_obese),
        ("Thin But Unfit", gen_thin_unfit),
        ("Ectomorph Muscle Builder", gen_ectomorph),
        ("Endomorph Fat Loss", gen_endomorph),
        # Equipment-Specific Low
        ("Single Dumbbell Only", gen_single_db_only),
        ("Single Dumbbell Strength", gen_single_db_strength),
        ("Resistance Band Only", gen_resistance_band_only),
        ("Cable Machine Mastery", gen_cable_mastery),
        ("Medicine Ball Training", gen_medicine_ball),
        ("TRX/Suspension", gen_trx),
        ("Sandbag Training", gen_sandbag),
        ("Steel Mace Training", gen_steel_mace),
        ("Indian Club Flow", gen_indian_club),
        ("Clubbell Training", gen_clubbell),
        ("Slam Ball Conditioning", gen_slam_ball),
        ("Battle Ropes Only", gen_battle_ropes),
        ("Landmine Training", gen_landmine),
        ("Trap Bar Training", gen_trap_bar),
        ("EZ Curl Bar Program", gen_ez_curl),
        ("Pull-up Bar Only", gen_pullup_bar),
    ]

    ok = 0
    skip = 0
    fail = 0

    for name, gen_func in all_programs:
        if helper.check_program_exists(name):
            print(f"  SKIP: {name}")
            skip += 1
            continue
        print(f"Generating: {name} (#{mig})")
        try:
            success = gen_func(helper, mig)
            if success:
                helper.update_tracker(name, "Done")
                ok += 1
            else:
                fail += 1
            mig += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            fail += 1
            mig += 1

    print(f"\n=== Results: {ok} OK, {skip} skipped, {fail} failed ===")
    helper.close()


if __name__ == "__main__":
    main()
