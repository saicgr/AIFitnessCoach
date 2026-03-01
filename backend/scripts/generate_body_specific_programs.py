#!/usr/bin/env python3
"""
Generate Body-Specific HIGH priority programs (Category 12).
Missing programs: Joint-Friendly Full Body, Plus Size HIIT,
                  Skinny Fat Advanced Shred, Obese Beginner Safe Start
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


def generate_joint_friendly_full_body(helper, mig):
    """Joint-Friendly Full Body - 4,8,12w x 3-4/wk - Arthritis/injury safe."""

    day1_lower = [
        {
            "workout_name": "Day 1 - Lower Body (Joint-Friendly)",
            "type": "strength",
            "exercises": [
                ex("Wall Sit", 3, 1, 30, "Bodyweight - hold 20-30 sec", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Back flat against wall, knees at 90 degrees", "Chair Squat"),
                ex("Glute Bridge", 3, 12, 30, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Slow squeeze at top, no spinal extension", "Hip Thrust"),
                ex("Step-Up (Low Box)", 3, 10, 45, "Bodyweight or light DBs", "Low Step", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "6-8 inch step, controlled descent", "Bodyweight Squat"),
                ex("Seated Leg Extension", 3, 12, 30, "Light weight", "Machine", "Legs", "Quadriceps", ["Vastus Medialis"], "beginner", "Partial range if needed, no locking", "Terminal Knee Extension"),
                ex("Standing Calf Raise", 3, 15, 30, "Bodyweight", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Slow up and down", "Seated Calf Raise"),
                ex("Side-Lying Leg Lift", 3, 12, 30, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Tensor Fasciae Latae"], "beginner", "Keep hips stacked, lift slowly", "Clamshell"),
            ],
        },
    ]

    day2_upper = [
        {
            "workout_name": "Day 2 - Upper Body (Joint-Friendly)",
            "type": "strength",
            "exercises": [
                ex("Incline Push-Up", 3, 10, 30, "Bodyweight", "Bench", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Hands elevated, full range at comfortable depth", "Wall Push-Up"),
                ex("Seated Cable Row", 3, 12, 45, "Light-moderate", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Controlled pull, squeeze shoulder blades", "Resistance Band Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 30, "Very light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Slight elbow bend, only to shoulder height", "Band Lateral Raise"),
                ex("Resistance Band Face Pull", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["External Rotators", "Rhomboids"], "beginner", "Pull to face, spread hands apart", "Band Pull-Apart"),
                ex("Hammer Curl", 3, 12, 30, "Light dumbbells", "Dumbbells", "Arms", "Brachioradialis", ["Biceps Brachii"], "beginner", "Neutral grip, controlled", "Resistance Band Curl"),
                ex("Overhead Tricep Extension", 3, 12, 30, "Light dumbbell", "Dumbbell", "Arms", "Triceps Brachii", ["Anconeus"], "beginner", "Both hands on one DB, lower behind head", "Band Tricep Pushdown"),
            ],
        },
    ]

    day3_full = [
        {
            "workout_name": "Day 3 - Full Body Gentle",
            "type": "strength",
            "exercises": [
                ex("Goblet Squat to Box", 3, 10, 45, "Light dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Sit to box/chair, stand up, reduces knee stress", "Chair Squat"),
                ex("Lat Pulldown", 3, 12, 45, "Light-moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Wide grip, pull to upper chest", "Band Pulldown"),
                ex("Leg Press (Limited Range)", 3, 12, 45, "Light-moderate", "Machine", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Partial range to reduce joint stress", "Bodyweight Squat"),
                ex("Cable Chest Press", 3, 12, 45, "Light", "Cable Machine", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Standing, press forward, easier on shoulders", "Incline Push-Up"),
                ex("Prone Y-T-W Raise", 3, 8, 30, "Bodyweight or very light DBs", "None", "Back", "Rear Deltoid", ["Trapezius", "Rhomboids"], "beginner", "Lying face down, arms form Y, T, W shapes", "Band Pull-Apart"),
                ex("Dead Bug", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Spine neutral, opposite arm-leg lower", "Bird Dog"),
            ],
        },
    ]

    day4_mobility = [
        {
            "workout_name": "Day 4 - Mobility & Recovery",
            "type": "flexibility",
            "exercises": [
                ex("Gentle Walking", 1, 1, 0, "15-20 minutes", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Easy pace, flat terrain", "Recumbent Cycling"),
                ex("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle spinal mobilization", "Seated Spinal Flexion"),
                ex("Seated Figure 4 Stretch", 3, 4, 20, "Hold 30 sec/side", "None", "Hips", "Piriformis", ["Gluteus Medius"], "beginner", "Ankle on opposite knee, lean forward", "Supine Figure 4"),
                ex("Wall Chest Stretch", 3, 4, 20, "Hold 30 sec/side", "None", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arm against wall, rotate away", "Doorway Stretch"),
                ex("Seated Hamstring Stretch", 3, 4, 20, "Hold 30 sec/side", "None", "Legs", "Hamstrings", ["Calves"], "beginner", "One leg extended, lean forward gently", "Standing Toe Touch"),
                ex("Neck Stretches", 3, 4, 15, "Hold 20 sec/side", "None", "Neck", "Trapezius", ["Sternocleidomastoid", "Scalenes"], "beginner", "Ear to shoulder, gentle pressure", "Neck Rolls"),
            ],
        },
    ]

    weeks_data = {}
    w3 = day1_lower + day2_upper + day3_full
    w4 = w3 + day4_mobility

    weeks_data[(4, 3)] = {
        1: {"focus": "Foundation - learn joint-safe movement patterns", "workouts": w3},
        2: {"focus": "Build confidence - slight load increase", "workouts": w3},
        3: {"focus": "Progressive volume - extra reps", "workouts": w3},
        4: {"focus": "Consolidation and assessment", "workouts": w3},
    }
    weeks_data[(4, 4)] = {
        1: {"focus": "Foundation with dedicated mobility", "workouts": w4},
        2: {"focus": "Build phase with recovery emphasis", "workouts": w4},
        3: {"focus": "Progressive volume with mobility", "workouts": w4},
        4: {"focus": "Consolidation and recovery week", "workouts": w4},
    }

    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Cycle 2 - increased load capacity", "workouts": w3}
    weeks_data[(8, 3)][6] = {"focus": "Cycle 2 - volume progression", "workouts": w3}
    weeks_data[(8, 3)][7] = {"focus": "Peak comfortable intensity", "workouts": w3}
    weeks_data[(8, 3)][8] = {"focus": "Deload and progress assessment", "workouts": w3}
    weeks_data[(8, 4)] = dict(weeks_data[(4, 4)])
    weeks_data[(8, 4)][5] = {"focus": "Cycle 2 with enhanced mobility", "workouts": w4}
    weeks_data[(8, 4)][6] = {"focus": "Cycle 2 volume progression", "workouts": w4}
    weeks_data[(8, 4)][7] = {"focus": "Peak week with recovery focus", "workouts": w4}
    weeks_data[(8, 4)][8] = {"focus": "Deload and maintenance plan", "workouts": w4}

    weeks_data[(12, 3)] = dict(weeks_data[(8, 3)])
    weeks_data[(12, 3)][9] = {"focus": "Cycle 3 - refined movement quality", "workouts": w3}
    weeks_data[(12, 3)][10] = {"focus": "Cycle 3 - continued progression", "workouts": w3}
    weeks_data[(12, 3)][11] = {"focus": "Cycle 3 - peak sustainable intensity", "workouts": w3}
    weeks_data[(12, 3)][12] = {"focus": "Final assessment, long-term plan", "workouts": w3}
    weeks_data[(12, 4)] = dict(weeks_data[(8, 4)])
    weeks_data[(12, 4)][9] = {"focus": "Cycle 3 with advanced mobility", "workouts": w4}
    weeks_data[(12, 4)][10] = {"focus": "Cycle 3 progressive overload", "workouts": w4}
    weeks_data[(12, 4)][11] = {"focus": "Peak comfortable performance", "workouts": w4}
    weeks_data[(12, 4)][12] = {"focus": "Maintenance and ongoing plan", "workouts": w4}

    return helper.insert_full_program(
        program_name="Joint-Friendly Full Body",
        category_name="Body-Specific",
        description="Full body strength program designed for individuals with arthritis, joint sensitivity, or past injuries. Uses joint-safe exercises with reduced range of motion where needed, machine-assisted movements, and dedicated mobility work.",
        durations=[4, 8, 12],
        sessions_per_week=[3, 4],
        has_supersets=False,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_plus_size_hiit(helper, mig):
    """Plus Size HIIT - 2,4,8w x 3/wk - Modified high intensity."""

    day1 = {
        "workout_name": "Day 1 - Low-Impact HIIT Circuit A",
        "type": "hiit",
        "exercises": [
            ex("March in Place", 3, 1, 30, "30 sec work, 30 sec rest", "None", "Cardio", "Full Body", ["Hip Flexors", "Calves"], "beginner", "High knees, pump arms, stay upright", "Seated Marching"),
            ex("Wall Push-Up", 3, 10, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Lean into wall, push back explosively", "Incline Push-Up"),
            ex("Bodyweight Squat", 3, 10, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Depth as comfortable, no pain", "Chair Squat"),
            ex("Standing Oblique Crunch", 3, 12, 30, "Bodyweight", "None", "Core", "Obliques", ["Hip Flexors"], "beginner", "Elbow to knee, standing", "Seated Twist"),
            ex("Step Touch Side to Side", 3, 1, 30, "30 sec continuous", "None", "Cardio", "Full Body", ["Hip Abductors", "Calves"], "beginner", "Step wide, add arm movement", "Side Step"),
            ex("Glute Bridge Pulse", 3, 12, 30, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Small pulses at top", "Glute Bridge Hold"),
            ex("Seated Boxing Punches", 3, 1, 30, "30 sec continuous", "None", "Arms", "Anterior Deltoid", ["Triceps", "Core"], "beginner", "Sit tall, punch alternating arms fast", "Standing Punches"),
        ],
    }

    day2 = {
        "workout_name": "Day 2 - Low-Impact HIIT Circuit B",
        "type": "hiit",
        "exercises": [
            ex("Modified Jumping Jack (Step Out)", 3, 1, 30, "30 sec work, 30 sec rest", "None", "Cardio", "Full Body", ["Hip Abductors", "Shoulders"], "beginner", "Step one foot out at a time instead of jumping", "March in Place"),
            ex("Incline Push-Up", 3, 8, 30, "Bodyweight", "Bench", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands on bench or counter", "Wall Push-Up"),
            ex("Reverse Lunge (Shallow)", 3, 8, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Small step back, partial depth", "Split Squat Hold"),
            ex("Standing Cat-Cow", 3, 10, 20, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Hands on knees, round and extend spine", "Seated Cat-Cow"),
            ex("Speed Skater (Low Impact)", 3, 1, 30, "30 sec, step instead of hop", "None", "Legs", "Gluteus Medius", ["Quadriceps", "Core"], "beginner", "Wide step side to side, touch floor", "Lateral Step"),
            ex("Bird Dog", 3, 8, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Opposite arm and leg, hold 3 sec", "Dead Bug"),
            ex("Arm Circle Series", 3, 1, 20, "20 sec forward, 20 sec backward", "None", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Small to large circles", "Band Pull-Apart"),
        ],
    }

    day3 = {
        "workout_name": "Day 3 - Low-Impact HIIT Circuit C",
        "type": "hiit",
        "exercises": [
            ex("Boxer Shuffle", 3, 1, 30, "30 sec work, 30 sec rest", "None", "Cardio", "Full Body", ["Calves", "Core"], "beginner", "Light feet, bounce side to side", "March in Place"),
            ex("Sumo Squat Pulse", 3, 10, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "beginner", "Wide stance, small pulses at bottom", "Wall Sit"),
            ex("Standing Knee to Elbow", 3, 10, 30, "Bodyweight", "None", "Core", "Obliques", ["Hip Flexors"], "beginner", "Opposite elbow to knee, standing", "Standing Oblique Crunch"),
            ex("Wall Sit Hold", 3, 1, 30, "Hold 20-30 sec", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Back flat on wall, adjust depth for comfort", "Chair Squat Hold"),
            ex("Clamshell", 3, 12, 20, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Side-lying, keep feet together", "Side-Lying Leg Lift"),
            ex("Plank on Knees", 3, 1, 30, "Hold 15-20 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Straight line from head to knees", "Wall Plank"),
            ex("Cool Down Walk", 1, 1, 0, "3-5 minutes easy pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Slow walk, deep breathing", "Seated Marching"),
        ],
    }

    workouts = [day1, day2, day3]
    weeks_data = {}

    weeks_data[(2, 3)] = {
        1: {"focus": "Introduction to low-impact HIIT, build confidence", "workouts": workouts},
        2: {"focus": "Increased work intervals, reduced rest", "workouts": workouts},
    }
    weeks_data[(4, 3)] = dict(weeks_data[(2, 3)])
    weeks_data[(4, 3)][3] = {"focus": "Extended work periods, added volume", "workouts": workouts}
    weeks_data[(4, 3)][4] = {"focus": "Peak intensity for this phase", "workouts": workouts}

    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Cycle 2 - increased speed and volume", "workouts": workouts}
    weeks_data[(8, 3)][6] = {"focus": "Cycle 2 - longer circuits", "workouts": workouts}
    weeks_data[(8, 3)][7] = {"focus": "Peak conditioning week", "workouts": workouts}
    weeks_data[(8, 3)][8] = {"focus": "Active recovery and assessment", "workouts": workouts}

    return helper.insert_full_program(
        program_name="Plus Size HIIT",
        category_name="Body-Specific",
        description="Modified high-intensity interval training designed for plus-size individuals. All exercises are low-impact with step-based alternatives to jumping. Focus on building cardiovascular fitness, burning calories, and building confidence in a supportive progression.",
        durations=[2, 4, 8],
        sessions_per_week=[3],
        has_supersets=False,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_skinny_fat_advanced_shred(helper, mig):
    """Skinny Fat Advanced Shred - 8,12,16w x 5-6/wk - Aggressive cut with muscle preservation."""

    day1_push = {
        "workout_name": "Day 1 - Push (Chest, Shoulders, Triceps)",
        "type": "strength",
        "exercises": [
            ex("Barbell Bench Press", 4, 8, 90, "Heavy - 75-85% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Arch back slightly, drive feet, explosive press", "Dumbbell Bench Press"),
            ex("Incline Dumbbell Press", 4, 10, 75, "Moderate-heavy", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30 degree incline, full stretch at bottom", "Incline Barbell Press"),
            ex("Overhead Press", 3, 8, 75, "Moderate-heavy", "Barbell", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Strict press, no leg drive", "Dumbbell Overhead Press"),
            ex("Cable Lateral Raise", 3, 15, 30, "Light-moderate cable", "Cable Machine", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "intermediate", "Control the eccentric, constant tension", "Dumbbell Lateral Raise"),
            ex("Weighted Dip", 3, 10, 60, "Added weight belt", "Dip Station", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "advanced", "Lean forward for chest, upright for triceps", "Bench Dip"),
            ex("Cable Tricep Pushdown", 3, 12, 30, "Moderate cable", "Cable Machine", "Arms", "Triceps Brachii", ["Anconeus"], "intermediate", "Elbows locked at sides, full extension", "Overhead Tricep Extension"),
            ex("Incline Walking", 1, 1, 0, "15 min, 12% incline, 3.0 mph", "Treadmill", "Cardio", "Full Body", ["Calves", "Gluteus Maximus"], "beginner", "Fat-burning zone cardio post-workout", "Stairmaster"),
        ],
    }

    day2_pull = {
        "workout_name": "Day 2 - Pull (Back, Biceps)",
        "type": "strength",
        "exercises": [
            ex("Barbell Deadlift", 4, 6, 120, "Heavy - 80-85% 1RM", "Barbell", "Back", "Erector Spinae", ["Gluteus Maximus", "Hamstrings", "Latissimus Dorsi"], "advanced", "Brace hard, push floor away, lockout hips", "Trap Bar Deadlift"),
            ex("Weighted Pull-Up", 4, 8, 90, "Added weight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "advanced", "Full range, chin over bar, controlled descent", "Lat Pulldown"),
            ex("Barbell Bent-Over Row", 3, 10, 75, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate", "45 degree torso, pull to navel", "Dumbbell Row"),
            ex("Cable Face Pull", 3, 15, 30, "Light-moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators", "Rhomboids"], "intermediate", "Pull rope to face, spread hands", "Band Face Pull"),
            ex("Seated Cable Row", 3, 12, 60, "Moderate", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "intermediate", "V-grip, pull to lower chest, squeeze", "Dumbbell Row"),
            ex("Barbell Curl", 3, 10, 45, "Moderate", "Barbell", "Arms", "Biceps Brachii", ["Brachialis"], "intermediate", "Strict form, control the negative", "Dumbbell Curl"),
            ex("Incline Walking", 1, 1, 0, "15 min, 12% incline, 3.0 mph", "Treadmill", "Cardio", "Full Body", ["Calves", "Gluteus Maximus"], "beginner", "Fat-burning zone", "Stairmaster"),
        ],
    }

    day3_legs = {
        "workout_name": "Day 3 - Legs",
        "type": "strength",
        "exercises": [
            ex("Barbell Back Squat", 4, 8, 120, "Heavy - 75-85% 1RM", "Barbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings", "Core"], "advanced", "Full depth, brace hard, drive out of hole", "Front Squat"),
            ex("Barbell Hip Thrust", 4, 10, 75, "Heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full hip extension, squeeze 2 sec at top", "Dumbbell Hip Thrust"),
            ex("Bulgarian Split Squat", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Rear foot elevated, deep stretch", "Reverse Lunge"),
            ex("Leg Curl", 3, 12, 45, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, squeeze at peak", "Nordic Curl"),
            ex("Leg Extension", 3, 12, 45, "Moderate", "Machine", "Legs", "Quadriceps", ["Vastus Medialis"], "intermediate", "Squeeze at top, controlled lower", "Sissy Squat"),
            ex("Standing Calf Raise", 4, 15, 30, "Moderate", "Machine", "Legs", "Gastrocnemius", ["Soleus"], "intermediate", "Full stretch at bottom, full contraction", "Seated Calf Raise"),
            ex("Hanging Leg Raise", 3, 12, 30, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, controlled raise", "Lying Leg Raise"),
        ],
    }

    day4_upper_power = {
        "workout_name": "Day 4 - Upper Body Power",
        "type": "strength",
        "exercises": [
            ex("Close-Grip Bench Press", 4, 8, 75, "Moderate-heavy", "Barbell", "Chest", "Triceps Brachii", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Hands shoulder-width, lower to chest", "Diamond Push-Up"),
            ex("Dumbbell Row", 4, 10, 60, "Heavy dumbbell", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Brace on bench, full range of motion", "Cable Row"),
            ex("Dumbbell Arnold Press", 3, 10, 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Rotate as you press overhead", "Overhead Press"),
            ex("Cable Crossover", 3, 12, 30, "Light-moderate", "Cable Machine", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "intermediate", "Squeeze at the bottom of cross", "Dumbbell Fly"),
            ex("Chin-Up", 3, 10, 60, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Supinated grip, chin over bar", "Lat Pulldown"),
            ex("Hammer Curl", 3, 12, 30, "Moderate dumbbells", "Dumbbells", "Arms", "Brachioradialis", ["Biceps Brachii"], "intermediate", "Neutral grip, controlled tempo", "Rope Curl"),
            ex("Incline Walking", 1, 1, 0, "15 min, 12% incline", "Treadmill", "Cardio", "Full Body", ["Calves"], "beginner", "Post-workout fat burn", "Stairmaster"),
        ],
    }

    day5_hiit = {
        "workout_name": "Day 5 - HIIT Conditioning",
        "type": "hiit",
        "exercises": [
            ex("Kettlebell Swing", 4, 15, 30, "Moderate-heavy KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Powerful hip snap", "Dumbbell Swing"),
            ex("Burpee", 4, 10, 30, "Bodyweight", "None", "Full Body", "Full Body", ["Chest", "Legs", "Core"], "intermediate", "Chest to floor, jump up", "Squat Thrust"),
            ex("Battle Rope Alternating Wave", 3, 30, 30, "Heavy rope", "Battle Ropes", "Shoulders", "Anterior Deltoid", ["Core", "Forearms"], "intermediate", "Fast alternating waves", "Mountain Climber"),
            ex("Box Jump", 3, 10, 45, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Soft landing, step down", "Jump Squat"),
            ex("Mountain Climber", 4, 20, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Hip Flexors"], "intermediate", "Fast and controlled", "High Knees"),
            ex("Sled Push", 3, 1, 60, "Moderate weight - 30 sec", "Sled", "Legs", "Quadriceps", ["Gluteus Maximus", "Core", "Calves"], "intermediate", "Drive through legs, stay low", "Sprint Intervals"),
            ex("Ab Wheel Rollout", 3, 10, 30, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Full extension if possible", "Plank"),
        ],
    }

    day6_active = {
        "workout_name": "Day 6 - Active Recovery & Abs",
        "type": "cardio",
        "exercises": [
            ex("Incline Walking", 1, 1, 0, "30 min, 10% incline, 3.0 mph", "Treadmill", "Cardio", "Full Body", ["Calves", "Gluteus Maximus"], "beginner", "LISS cardio for recovery", "Elliptical"),
            ex("Hanging Leg Raise", 3, 12, 30, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Controlled raise and lower", "Lying Leg Raise"),
            ex("Cable Woodchop", 3, 12, 30, "Moderate cable", "Cable Machine", "Core", "Obliques", ["Transverse Abdominis"], "intermediate", "Rotate from hips, arms straight", "Russian Twist"),
            ex("Plank Hold", 3, 1, 30, "Hold 45-60 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "intermediate", "Straight line, tight core", "Modified Plank"),
            ex("Bicycle Crunch", 3, 20, 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Opposite elbow to knee, full rotation", "Dead Bug"),
            ex("Foam Roll Full Body", 1, 1, 0, "10 minutes", "Foam Roller", "Full Body", "Full Body", ["Fascia"], "beginner", "Hit all major muscle groups", "Stretching"),
        ],
    }

    w5 = [day1_push, day2_pull, day3_legs, day4_upper_power, day5_hiit]
    w6 = w5 + [day6_active]

    weeks_data = {}

    weeks_data[(8, 5)] = {
        1: {"focus": "Establish baseline, learn movements at moderate intensity", "workouts": w5},
        2: {"focus": "Progressive overload - increase working weights", "workouts": w5},
        3: {"focus": "Volume increase - additional working sets", "workouts": w5},
        4: {"focus": "Intensity peak - heaviest weights this cycle", "workouts": w5},
        5: {"focus": "Deload - reduce volume 30%, maintain intensity", "workouts": w5},
        6: {"focus": "Rebuild - new working weight baselines", "workouts": w5},
        7: {"focus": "Peak push - highest volume and intensity", "workouts": w5},
        8: {"focus": "Final assessment - test strength, measure progress", "workouts": w5},
    }
    weeks_data[(8, 6)] = {
        1: {"focus": "Establish baseline with full recovery protocol", "workouts": w6},
        2: {"focus": "Progressive overload with active recovery", "workouts": w6},
        3: {"focus": "Volume increase with ab specialization", "workouts": w6},
        4: {"focus": "Intensity peak with recovery", "workouts": w6},
        5: {"focus": "Deload week with LISS cardio focus", "workouts": w6},
        6: {"focus": "Rebuild with new baselines", "workouts": w6},
        7: {"focus": "Peak week - maximal effort", "workouts": w6},
        8: {"focus": "Final assessment and maintenance", "workouts": w6},
    }

    weeks_data[(12, 5)] = dict(weeks_data[(8, 5)])
    weeks_data[(12, 5)][9] = {"focus": "Cycle 3 - advanced strength focus", "workouts": w5}
    weeks_data[(12, 5)][10] = {"focus": "Cycle 3 - progressive overload", "workouts": w5}
    weeks_data[(12, 5)][11] = {"focus": "Cycle 3 - final peak", "workouts": w5}
    weeks_data[(12, 5)][12] = {"focus": "Reverse diet preparation, maintenance plan", "workouts": w5}
    weeks_data[(12, 6)] = dict(weeks_data[(8, 6)])
    weeks_data[(12, 6)][9] = {"focus": "Cycle 3 with full protocol", "workouts": w6}
    weeks_data[(12, 6)][10] = {"focus": "Cycle 3 progressive overload", "workouts": w6}
    weeks_data[(12, 6)][11] = {"focus": "Cycle 3 final peak", "workouts": w6}
    weeks_data[(12, 6)][12] = {"focus": "Final assessment, reverse diet", "workouts": w6}

    weeks_data[(16, 5)] = dict(weeks_data[(12, 5)])
    weeks_data[(16, 5)][13] = {"focus": "Maintenance phase begins", "workouts": w5}
    weeks_data[(16, 5)][14] = {"focus": "Maintenance with calorie increase", "workouts": w5}
    weeks_data[(16, 5)][15] = {"focus": "Transition to lean bulk", "workouts": w5}
    weeks_data[(16, 5)][16] = {"focus": "Final maintenance assessment", "workouts": w5}
    weeks_data[(16, 6)] = dict(weeks_data[(12, 6)])
    weeks_data[(16, 6)][13] = {"focus": "Maintenance with full recovery", "workouts": w6}
    weeks_data[(16, 6)][14] = {"focus": "Maintenance calorie increase", "workouts": w6}
    weeks_data[(16, 6)][15] = {"focus": "Transition phase", "workouts": w6}
    weeks_data[(16, 6)][16] = {"focus": "Final assessment and plan", "workouts": w6}

    return helper.insert_full_program(
        program_name="Skinny Fat Advanced Shred",
        category_name="Body-Specific",
        description="Aggressive body recomposition program for the skinny-fat physique. Combines heavy compound lifting for muscle preservation with strategic HIIT and LISS cardio for fat loss. Push/Pull/Legs split with upper body power day and conditioning.",
        durations=[8, 12, 16],
        sessions_per_week=[5, 6],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def generate_obese_beginner_safe_start(helper, mig):
    """Obese Beginner Safe Start - 4,8,12,16w x 2-3/wk - Very low-impact entry."""

    day1 = {
        "workout_name": "Day 1 - Seated & Standing Basics",
        "type": "strength",
        "exercises": [
            ex("Seated March", 3, 12, 20, "Bodyweight", "Chair", "Cardio", "Hip Flexors", ["Quadriceps"], "beginner", "Sit tall, alternate lifting knees, pump arms", "Standing March"),
            ex("Chair Squat (Sit-to-Stand)", 3, 8, 30, "Bodyweight", "Chair", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Sit down slowly, stand up using legs not arms", "Wall Sit"),
            ex("Wall Push-Up", 3, 8, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Stand arm's length from wall, lean in and push back", "Counter Push-Up"),
            ex("Seated Arm Raise", 3, 10, 20, "Bodyweight or very light DBs", "Chair", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid"], "beginner", "Raise arms overhead from seated, control", "Standing Arm Raise"),
            ex("Seated Knee Extension", 3, 10, 20, "Bodyweight", "Chair", "Legs", "Quadriceps", ["Vastus Medialis"], "beginner", "Straighten one leg, hold 2 sec, lower", "Seated Leg Raise"),
            ex("Standing Calf Raise (Wall Support)", 3, 12, 20, "Bodyweight", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Hold wall for balance, rise on toes", "Seated Calf Raise"),
            ex("Diaphragmatic Breathing", 3, 8, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Deep belly breaths, 4 in, 4 out", "Box Breathing"),
        ],
    }

    day2 = {
        "workout_name": "Day 2 - Gentle Movement & Mobility",
        "type": "flexibility",
        "exercises": [
            ex("Gentle Walking", 1, 1, 0, "10-15 minutes easy pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Flat terrain, comfortable pace, stop if needed", "Seated Marching"),
            ex("Seated Cat-Cow", 3, 8, 15, "Bodyweight", "Chair", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Sit on edge of chair, round and arch spine", "Standing Cat-Cow"),
            ex("Seated Hip Opener", 3, 4, 20, "Hold 20 sec/side", "Chair", "Hips", "Hip Adductors", ["Gluteus Medius"], "beginner", "Ankle on opposite knee, gentle lean forward", "Standing Figure 4"),
            ex("Neck Rolls", 3, 6, 15, "Bodyweight", "None", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Slow half circles, ear to ear", "Neck Side Stretch"),
            ex("Seated Torso Twist", 3, 8, 15, "Bodyweight", "Chair", "Core", "Obliques", ["Erector Spinae"], "beginner", "Sit tall, rotate gently side to side", "Standing Twist"),
            ex("Ankle Circles", 3, 10, 10, "Bodyweight", "None", "Legs", "Ankle Stabilizers", ["Calves"], "beginner", "Circle each ankle both directions", "Toe Taps"),
            ex("Standing Side Bend", 3, 8, 15, "Bodyweight", "None", "Core", "Obliques", ["Quadratus Lumborum"], "beginner", "Hand slides down thigh, gentle stretch", "Seated Side Bend"),
        ],
    }

    day3 = {
        "workout_name": "Day 3 - Light Circuit",
        "type": "circuit",
        "exercises": [
            ex("March in Place", 3, 1, 20, "30 sec", "None", "Cardio", "Full Body", ["Hip Flexors", "Calves"], "beginner", "Gentle pace, pump arms", "Seated Marching"),
            ex("Wall Push-Up", 3, 8, 20, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Comfortable depth", "Counter Push-Up"),
            ex("Chair Squat", 3, 8, 30, "Bodyweight", "Chair", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Touch chair, stand back up", "Wall Sit"),
            ex("Standing Arm Curl (Light)", 3, 10, 20, "Very light DBs or water bottles", "Dumbbells", "Arms", "Biceps Brachii", ["Brachialis"], "beginner", "Controlled movement", "Resistance Band Curl"),
            ex("Standing Side Step", 3, 1, 20, "20 sec each direction", "None", "Legs", "Hip Abductors", ["Gluteus Medius"], "beginner", "Step to side and back, repeat", "Seated Leg Lift"),
            ex("Glute Bridge", 3, 8, 20, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Slow and controlled, squeeze at top", "Chair Squeeze"),
            ex("Seated Cool Down Breathing", 3, 6, 15, "Bodyweight", "Chair", "Core", "Diaphragm", ["Transverse Abdominis"], "beginner", "Slow deep breaths, celebrate completing workout", "Standing Deep Breaths"),
        ],
    }

    w2 = [day1, day2]
    w3 = [day1, day2, day3]

    weeks_data = {}
    weeks_data[(4, 2)] = {
        1: {"focus": "Absolute basics - seated and standing exercises, build confidence", "workouts": w2},
        2: {"focus": "Increased reps, slightly longer walking", "workouts": w2},
        3: {"focus": "Added standing exercises, gentle progression", "workouts": w2},
        4: {"focus": "Test improvements, celebrate progress", "workouts": w2},
    }
    weeks_data[(4, 3)] = {
        1: {"focus": "Basics with light circuit day", "workouts": w3},
        2: {"focus": "Increased reps and walking duration", "workouts": w3},
        3: {"focus": "Added volume, gentle progression", "workouts": w3},
        4: {"focus": "Assessment and celebration", "workouts": w3},
    }

    weeks_data[(8, 2)] = dict(weeks_data[(4, 2)])
    weeks_data[(8, 2)][5] = {"focus": "Cycle 2 - slightly harder variations", "workouts": w2}
    weeks_data[(8, 2)][6] = {"focus": "Cycle 2 - increased walking time", "workouts": w2}
    weeks_data[(8, 2)][7] = {"focus": "Cycle 2 - peak for this phase", "workouts": w2}
    weeks_data[(8, 2)][8] = {"focus": "Celebrate transformation, plan next steps", "workouts": w2}
    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Cycle 2 - progressed exercises", "workouts": w3}
    weeks_data[(8, 3)][6] = {"focus": "Cycle 2 - increased duration", "workouts": w3}
    weeks_data[(8, 3)][7] = {"focus": "Cycle 2 peak - confidence building", "workouts": w3}
    weeks_data[(8, 3)][8] = {"focus": "Assessment and next phase planning", "workouts": w3}

    weeks_data[(12, 2)] = dict(weeks_data[(8, 2)])
    weeks_data[(12, 2)][9] = {"focus": "Cycle 3 - standing exercises prioritized", "workouts": w2}
    weeks_data[(12, 2)][10] = {"focus": "Cycle 3 - longer sessions", "workouts": w2}
    weeks_data[(12, 2)][11] = {"focus": "Cycle 3 peak fitness", "workouts": w2}
    weeks_data[(12, 2)][12] = {"focus": "Final assessment, transition plan", "workouts": w2}
    weeks_data[(12, 3)] = dict(weeks_data[(8, 3)])
    weeks_data[(12, 3)][9] = {"focus": "Cycle 3 - advanced basics", "workouts": w3}
    weeks_data[(12, 3)][10] = {"focus": "Cycle 3 progression", "workouts": w3}
    weeks_data[(12, 3)][11] = {"focus": "Cycle 3 peak", "workouts": w3}
    weeks_data[(12, 3)][12] = {"focus": "Graduation and transition planning", "workouts": w3}

    weeks_data[(16, 2)] = dict(weeks_data[(12, 2)])
    weeks_data[(16, 2)][13] = {"focus": "Transition phase - new challenges", "workouts": w2}
    weeks_data[(16, 2)][14] = {"focus": "Building toward intermediate", "workouts": w2}
    weeks_data[(16, 2)][15] = {"focus": "Intermediate preview exercises", "workouts": w2}
    weeks_data[(16, 2)][16] = {"focus": "Graduation - ready for next program", "workouts": w2}
    weeks_data[(16, 3)] = dict(weeks_data[(12, 3)])
    weeks_data[(16, 3)][13] = {"focus": "Transition with light circuits", "workouts": w3}
    weeks_data[(16, 3)][14] = {"focus": "Building toward intermediate level", "workouts": w3}
    weeks_data[(16, 3)][15] = {"focus": "Intermediate exercise preview", "workouts": w3}
    weeks_data[(16, 3)][16] = {"focus": "Full graduation assessment", "workouts": w3}

    return helper.insert_full_program(
        program_name="Obese Beginner Safe Start",
        category_name="Body-Specific",
        description="Ultra-safe entry-level program for individuals with obesity. Starts with seated and wall-supported exercises, progressively adding standing movements and light walking. Designed to build confidence, improve mobility, and create sustainable exercise habits without joint stress.",
        durations=[4, 8, 12, 16],
        sessions_per_week=[2, 3],
        has_supersets=False,
        priority="high",
        weeks_data=weeks_data,
        migration_num=mig,
    )


def main():
    helper = ProgramSQLHelper()
    mig = helper.get_next_migration_num()

    programs = [
        ("Joint-Friendly Full Body", generate_joint_friendly_full_body),
        ("Plus Size HIIT", generate_plus_size_hiit),
        ("Skinny Fat Advanced Shred", generate_skinny_fat_advanced_shred),
        ("Obese Beginner Safe Start", generate_obese_beginner_safe_start),
    ]

    results = {}
    for name, gen_func in programs:
        if helper.check_program_exists(name):
            print(f"  SKIP (exists): {name}")
            results[name] = "skipped"
            continue
        print(f"\nGenerating: {name} (migration #{mig})")
        try:
            success = gen_func(helper, mig)
            results[name] = "OK" if success else "FAILED"
            if success:
                helper.update_tracker(name, "Done", f"{mig}_program_*.sql")
            mig += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            results[name] = f"ERROR: {e}"
            mig += 1

    print("\n=== Body-Specific Results ===")
    for name, status in results.items():
        print(f"  {name}: {status}")

    helper.close()


if __name__ == "__main__":
    main()
