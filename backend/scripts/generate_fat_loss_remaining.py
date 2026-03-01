#!/usr/bin/env python3
"""Generate remaining high-priority Fat Loss programs:
- Full Body Fat Torch (2, 4, 8w x 4-5/wk)
- Wedding Ready Shred (4, 6, 8, 12w x 5-6/wk)
- Extreme Shred (4, 6w x 6/wk)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper


def build_full_body_fat_torch():
    """Full Body Fat Torch - Compound movement focus, every session is full body."""
    weeks_data = {}

    fb_a = {
        "workout_name": "Day 1 - Full Body A (Squat Focus)",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy - RPE 7-8", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, chest up, drive through heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Bench Press", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Control the negative, explosive press", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Bent Over Barbell Row", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Flat back, pull to lower chest", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Walking Lunges", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Long stride, upright torso", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Overhead Press", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Brace core, press overhead, lock out", "substitution": "Dumbbell Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Kettlebell Swings", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate KB", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Powerful hip snap", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 45, "rest_seconds": 30, "weight_guidance": "45-second holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Straight line, brace hard", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
        ]
    }

    fb_b = {
        "workout_name": "Day 2 - Full Body B (Hinge Focus)",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, feel hamstring stretch", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Incline Dumbbell Press", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Upper Pectoralis", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "30 degree incline, full range", "substitution": "Incline Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Pull-Ups", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight or assisted", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "intermediate", "form_cue": "Full hang, chin over bar", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, squeeze 2 sec", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Clean and Press", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Legs", "Core", "Traps"], "difficulty": "intermediate", "form_cue": "Clean to shoulders, press overhead", "substitution": "Kettlebell Clean and Press", "exercise_library_id": None, "in_library": False},
            {"name": "Mountain Climbers", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Flexors", "Shoulders"], "difficulty": "beginner", "form_cue": "Drive knees rapidly", "substitution": "High Knees", "exercise_library_id": None, "in_library": False}
        ]
    }

    fb_c = {
        "workout_name": "Day 3 - Full Body C (Push Focus)",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Front Squat", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Elbows high, sit between heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Flat Barbell Bench Press", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Touch chest, drive up", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Seated Cable Row", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Latissimus Dorsi", "Biceps"], "difficulty": "beginner", "form_cue": "Squeeze shoulder blades together", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Rear foot elevated, drop back knee", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Arnold Press", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Rotate as you press", "substitution": "Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Burpees", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump at top", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False}
        ]
    }

    fb_d = {
        "workout_name": "Day 4 - Full Body D (Pull Focus)",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Trap Bar Deadlift", "sets": 4, "reps": 6, "rest_seconds": 75, "weight_guidance": "Heavy - RPE 8", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Quadriceps", "Traps"], "difficulty": "intermediate", "form_cue": "Drive through floor, chest up", "substitution": "Conventional Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Weighted Chin-Ups", "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Add weight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Supinated grip, full range", "substitution": "Chin-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Squeeze Press", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Press DBs together throughout", "substitution": "Close Grip Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Romanian Deadlift", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Hinge on one leg, back flat", "substitution": "Romanian Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Thrusters", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps"], "difficulty": "intermediate", "form_cue": "Squat to overhead press in one motion", "substitution": "Goblet Squat to Press", "exercise_library_id": None, "in_library": False},
            {"name": "V-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Touch toes at top", "substitution": "Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    fb_hiit = {
        "workout_name": "Day 5 - Full Body HIIT",
        "type": "hiit",
        "duration_minutes": 35,
        "exercises": [
            {"name": "Dumbbell Snatch", "sets": 4, "reps": 8, "rest_seconds": 30, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Explosive pull, catch overhead", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Box Jumps", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "20-24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Swing arms, land softly", "substitution": "Step-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Man Makers", "sets": 3, "reps": 6, "rest_seconds": 45, "weight_guidance": "Light to moderate DBs", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Back", "Shoulders", "Legs"], "difficulty": "advanced", "form_cue": "Push-up, row each side, clean, press", "substitution": "Burpee to Press", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Slams", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "15-25 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Max force each slam", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Battle Ropes", "sets": 3, "reps": 30, "rest_seconds": 20, "weight_guidance": "30-second sets", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms"], "difficulty": "intermediate", "form_cue": "Alternating waves", "substitution": "Jumping Jacks", "exercise_library_id": None, "in_library": False},
            {"name": "Bicycle Crunches", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Elbow to opposite knee", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 2 weeks, 4/wk
    weeks_data[(2, 4)] = {
        1: {"focus": "Metabolic Foundation - Full Body Compound Focus", "workouts": [fb_a, fb_b, fb_c, fb_d]},
        2: {"focus": "Intensification - Reduced Rest, Higher Volume", "workouts": [fb_b, fb_d, fb_a, fb_c]},
    }

    # 4 weeks, 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Foundation - Learn Movement Patterns", "workouts": [fb_a, fb_b, fb_c, fb_d]},
        2: {"focus": "Build - Progressive Overload", "workouts": [fb_b, fb_d, fb_a, fb_c]},
        3: {"focus": "Peak - Maximum Training Density", "workouts": [fb_c, fb_a, fb_d, fb_b]},
        4: {"focus": "Final Push - All-Out Effort", "workouts": [fb_d, fb_c, fb_b, fb_a]},
    }

    # 8 weeks, 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation Week", "workouts": [fb_a, fb_b, fb_c, fb_d, fb_hiit]},
        2: {"focus": "Build Week - Increased Load", "workouts": [fb_b, fb_d, fb_a, fb_c, fb_hiit]},
        3: {"focus": "Volume Accumulation", "workouts": [fb_c, fb_a, fb_d, fb_b, fb_hiit]},
        4: {"focus": "Intensification - Shorter Rest", "workouts": [fb_d, fb_c, fb_b, fb_a, fb_hiit]},
        5: {"focus": "Deload - Active Recovery", "workouts": [fb_a, fb_b, fb_c, fb_d, fb_hiit]},
        6: {"focus": "Second Build - New Stimulus", "workouts": [fb_b, fb_d, fb_a, fb_c, fb_hiit]},
        7: {"focus": "Peak Phase - Maximum Output", "workouts": [fb_c, fb_a, fb_d, fb_b, fb_hiit]},
        8: {"focus": "Final Torch - Leave It All Out", "workouts": [fb_d, fb_c, fb_b, fb_a, fb_hiit]},
    }

    return weeks_data


def build_wedding_ready_shred():
    """Wedding Ready Shred - Bride/groom preparation. Tone + posture + aesthetics."""
    weeks_data = {}

    upper_tone = {
        "workout_name": "Day 1 - Upper Body Sculpt",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Dumbbell Bench Press", "sets": 4, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Controlled tempo, feel the muscle working", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Lat Pulldown", "sets": 4, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "beginner", "form_cue": "Wide grip, pull to upper chest, squeeze back", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Lateral Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light weight, strict form", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Upper Trapezius"], "difficulty": "beginner", "form_cue": "Raise to shoulder height, pause 1 sec", "substitution": "Cable Lateral Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Face Pulls", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull to face, open chest", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Tricep Kickbacks", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full extension, squeeze at top", "substitution": "Tricep Pushdowns", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Bicep Curls", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Full range, no swinging", "substitution": "Hammer Curls", "exercise_library_id": None, "in_library": False}
        ]
    }

    lower_tone = {
        "workout_name": "Day 2 - Lower Body Sculpt",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate - RPE 7", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 4, "reps": 12, "rest_seconds": 45, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, squeeze glutes hard", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Rear foot elevated, deep stretch", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Feel the hamstring stretch", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Extensions", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Leg Extension Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Squeeze at top, slow negative", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Calf Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, pause at top", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    hiit_day = {
        "workout_name": "Day 3 - HIIT Cardio Burn",
        "type": "hiit",
        "duration_minutes": 35,
        "exercises": [
            {"name": "Assault Bike Sprints", "sets": 6, "reps": 15, "rest_seconds": 30, "weight_guidance": "15-cal sprints", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "intermediate", "form_cue": "Max effort each round", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
            {"name": "Kettlebell Swings", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate KB", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Hip snap, arms passive", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Jump Squats", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up, soft landing", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Mountain Climbers", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Hip Flexors"], "difficulty": "beginner", "form_cue": "Drive knees rapidly", "substitution": "High Knees", "exercise_library_id": None, "in_library": False},
            {"name": "Burpees", "sets": 3, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, jump at top", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
            {"name": "Plank Jacks", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Hip Abductors"], "difficulty": "beginner", "form_cue": "Plank position, jump feet wide and back", "substitution": "Plank Hold", "exercise_library_id": None, "in_library": False}
        ]
    }

    full_body_circuit = {
        "workout_name": "Day 4 - Full Body Circuit",
        "type": "fat_loss",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Thrusters", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Squat to press in one motion", "substitution": "Goblet Squat to Press", "exercise_library_id": None, "in_library": False},
            {"name": "Renegade Rows", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Core", "Biceps"], "difficulty": "intermediate", "form_cue": "Plank, row alternating, keep hips square", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Walking Lunges", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Long stride, upright torso", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Push-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "beginner", "form_cue": "Full range, straight body", "substitution": "Knee Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Slams", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "15-20 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Full force each slam", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Bicycle Crunches", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Touch elbow to opposite knee", "substitution": "Russian Twists", "exercise_library_id": None, "in_library": False}
        ]
    }

    posture_arms = {
        "workout_name": "Day 5 - Posture & Arms (Photo-Ready)",
        "type": "fat_loss",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Face Pulls", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids", "External Rotators"], "difficulty": "beginner", "form_cue": "Pull to face, open chest, improve posture", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Reverse Flyes", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Hinge over, raise arms to sides", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Lateral Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light weight", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Create that capped shoulder look", "substitution": "Cable Lateral Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Tricep Dips", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Dip Station", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Chest"], "difficulty": "intermediate", "form_cue": "Full range for arm definition", "substitution": "Bench Dips", "exercise_library_id": None, "in_library": False},
            {"name": "Hammer Curls", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Brachialis", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Strict form, no swinging", "substitution": "Dumbbell Curls", "exercise_library_id": None, "in_library": False},
            {"name": "Overhead Tricep Extension", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full stretch, eliminate arm jiggle", "substitution": "Skull Crushers", "exercise_library_id": None, "in_library": False}
        ]
    }

    core_cardio = {
        "workout_name": "Day 6 - Core & Light Cardio",
        "type": "cardio",
        "duration_minutes": 35,
        "exercises": [
            {"name": "Rowing Machine", "sets": 3, "reps": 500, "rest_seconds": 60, "weight_guidance": "Moderate pace 500m", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "beginner", "form_cue": "Smooth strokes", "substitution": "Stationary Bike", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 45, "rest_seconds": 30, "weight_guidance": "45-sec holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Tight core, straight line", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False},
            {"name": "Side Plank", "sets": 3, "reps": 30, "rest_seconds": 30, "weight_guidance": "30-sec holds each side", "equipment": "None", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Hips stacked", "substitution": "Pallof Press", "exercise_library_id": None, "in_library": False},
            {"name": "Ab Wheel Rollout", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Full extension", "substitution": "Plank", "exercise_library_id": None, "in_library": False},
            {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "10-15 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate fully side to side", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 5/wk
    weeks_data[(4, 5)] = {
        1: {"focus": "Wedding Prep Foundation - Build Base", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms]},
        2: {"focus": "Volume Phase - Sculpting Focus", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms]},
        3: {"focus": "Peak Phase - Increased Intensity", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms]},
        4: {"focus": "Final Week - Photo-Ready Refinement", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms]},
    }

    # 6w x 5/wk
    weeks_data[(6, 5)] = {
        1: {"focus": "Foundation - Establish Training Habits", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms]},
        2: {"focus": "Build - Progressive Overload", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms]},
        3: {"focus": "Volume Accumulation", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms]},
        4: {"focus": "Intensification - Peak Training", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms]},
        5: {"focus": "Taper - Reduce Volume, Maintain Tone", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms]},
        6: {"focus": "Wedding Week - Light Pumps Only", "workouts": [posture_arms, lower_tone, hiit_day, upper_tone, core_cardio]},
    }

    # 8w x 6/wk
    weeks_data[(8, 6)] = {
        1: {"focus": "Foundation Phase", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]},
        2: {"focus": "Build Phase", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms, core_cardio]},
        3: {"focus": "Volume Phase", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]},
        4: {"focus": "Intensification", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms, core_cardio]},
        5: {"focus": "Deload - Recovery Week", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]},
        6: {"focus": "Second Build", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms, core_cardio]},
        7: {"focus": "Peak - Maximum Definition", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]},
        8: {"focus": "Wedding Week - Pump & Polish", "workouts": [posture_arms, lower_tone, hiit_day, upper_tone, posture_arms, core_cardio]},
    }

    # 12w x 6/wk
    w12 = {}
    for wk in range(1, 9):
        w12[wk] = weeks_data[(8, 6)][wk]
    w12[9] = {"focus": "Third Build Block", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]}
    w12[10] = {"focus": "Definition Phase", "workouts": [lower_tone, upper_tone, full_body_circuit, hiit_day, posture_arms, core_cardio]}
    w12[11] = {"focus": "Final Taper", "workouts": [upper_tone, lower_tone, hiit_day, full_body_circuit, posture_arms, core_cardio]}
    w12[12] = {"focus": "Wedding Week - Look Your Absolute Best", "workouts": [posture_arms, lower_tone, hiit_day, upper_tone, posture_arms, core_cardio]}
    weeks_data[(12, 6)] = w12

    return weeks_data


def build_extreme_shred():
    """Extreme Shred - 6 days/wk, high intensity. Not for beginners."""
    weeks_data = {}

    day1 = {
        "workout_name": "Day 1 - Push + HIIT",
        "type": "fat_loss",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Flat Barbell Bench Press", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Touch chest, explosive press", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Military Press", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Brace core, press straight up", "substitution": "Dumbbell Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Incline Dumbbell Flyes", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Wide arc, squeeze at top", "substitution": "Cable Flyes", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Lateral Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Constant tension", "substitution": "Dumbbell Lateral Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Tricep Dips", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight or weighted", "equipment": "Dip Station", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Chest"], "difficulty": "intermediate", "form_cue": "Full depth", "substitution": "Close Grip Bench", "exercise_library_id": None, "in_library": False},
            {"name": "Assault Bike Sprints", "sets": 5, "reps": 15, "rest_seconds": 30, "weight_guidance": "15-cal sprints", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "intermediate", "form_cue": "Max effort", "substitution": "Burpees", "exercise_library_id": None, "in_library": False}
        ]
    }

    day2 = {
        "workout_name": "Day 2 - Pull + Conditioning",
        "type": "fat_loss",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Barbell Deadlift", "sets": 4, "reps": 5, "rest_seconds": 90, "weight_guidance": "Heavy - RPE 8-9", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes", "Hamstrings", "Traps"], "difficulty": "intermediate", "form_cue": "Flat back, push floor away", "substitution": "Trap Bar Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Weighted Pull-Ups", "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "Add weight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "advanced", "form_cue": "Full range", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "T-Bar Row", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate to heavy", "equipment": "T-Bar Row Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Pull to chest, squeeze", "substitution": "Barbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Face Pulls", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull to face, externally rotate", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Curl", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Barbell", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Strict form, full range", "substitution": "Dumbbell Curls", "exercise_library_id": None, "in_library": False},
            {"name": "Rowing Machine Intervals", "sets": 5, "reps": 250, "rest_seconds": 45, "weight_guidance": "250m max effort", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "intermediate", "form_cue": "Max power per stroke", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False}
        ]
    }

    day3 = {
        "workout_name": "Day 3 - Legs + Plyometrics",
        "type": "fat_loss",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 4, "reps": 6, "rest_seconds": 90, "weight_guidance": "Heavy - RPE 8-9", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Below parallel, drive hard", "substitution": "Front Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Deep hinge, feel the stretch", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Walking Lunges", "sets": 3, "reps": 14, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "Long stride", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Box Jumps", "sets": 4, "reps": 10, "rest_seconds": 45, "weight_guidance": "24 inch box", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Max height, soft landing", "substitution": "Jump Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Jump Squats", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explode up, land soft", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Hanging Leg Raises", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Lower Abs", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "No swinging", "substitution": "Lying Leg Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    day4 = {
        "workout_name": "Day 4 - Full Body HIIT",
        "type": "hiit",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Thrusters", "sets": 5, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Shoulders", "Triceps"], "difficulty": "intermediate", "form_cue": "Squat to press, no pausing", "substitution": "Dumbbell Thrusters", "exercise_library_id": None, "in_library": False},
            {"name": "Burpees", "sets": 4, "reps": 10, "rest_seconds": 20, "weight_guidance": "Bodyweight - max speed", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Fast transitions", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
            {"name": "Kettlebell Swings", "sets": 4, "reps": 20, "rest_seconds": 20, "weight_guidance": "Heavy KB", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Aggressive hip snap", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Slams", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "20-25 lb ball", "equipment": "Medicine Ball", "body_part": "Full Body", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Max force", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Battle Ropes Double Slam", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Max power", "equipment": "Battle Ropes", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Lats"], "difficulty": "intermediate", "form_cue": "Both arms, slam with hip hinge", "substitution": "Medicine Ball Slams", "exercise_library_id": None, "in_library": False},
            {"name": "Mountain Climbers", "sets": 3, "reps": 30, "rest_seconds": 15, "weight_guidance": "Bodyweight - sprint pace", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "beginner", "form_cue": "As fast as possible", "substitution": "High Knees", "exercise_library_id": None, "in_library": False}
        ]
    }

    day5 = {
        "workout_name": "Day 5 - Upper Body Supersets",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Incline Barbell Bench Press", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Upper Pectoralis", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Touch upper chest", "substitution": "Incline Dumbbell Press", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Row", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Heavy - superset with bench", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Pull to lower chest", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Shoulder Press", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Press overhead, lock out", "substitution": "Pike Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Chin-Ups", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight - superset with press", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Underhand grip, full range", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
            {"name": "Skull Crushers", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Moderate EZ bar", "equipment": "EZ Bar", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend", "substitution": "Tricep Pushdowns", "exercise_library_id": None, "in_library": False},
            {"name": "Hammer Curls", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Moderate - superset with skull crushers", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Brachialis", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Neutral grip, strict form", "substitution": "Dumbbell Curls", "exercise_library_id": None, "in_library": False}
        ]
    }

    day6 = {
        "workout_name": "Day 6 - Legs + Core Finisher",
        "type": "fat_loss",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Front Squat", "sets": 4, "reps": 8, "rest_seconds": 75, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Elbows high, stay upright", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, squeeze hard", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Curls", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate", "equipment": "Leg Curl Machine", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Squeeze at top, slow negative", "substitution": "Nordic Curls", "exercise_library_id": None, "in_library": False},
            {"name": "Sled Push", "sets": 4, "reps": 30, "rest_seconds": 45, "weight_guidance": "Heavy, 30m", "equipment": "Sled", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Low angle, sprint", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Ab Wheel Rollout", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Full extension", "substitution": "Plank", "exercise_library_id": None, "in_library": False},
            {"name": "V-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Touch toes at top", "substitution": "Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4 weeks x 6/wk
    weeks_data[(4, 6)] = {
        1: {"focus": "Shock Week - Establish Extreme Intensity", "workouts": [day1, day2, day3, day4, day5, day6]},
        2: {"focus": "Overreach - Maximum Training Volume", "workouts": [day2, day3, day1, day5, day6, day4]},
        3: {"focus": "Peak Intensity - Shortest Rest, Heaviest Loads", "workouts": [day1, day2, day3, day4, day5, day6]},
        4: {"focus": "Final Shred - Leave Everything on the Floor", "workouts": [day3, day1, day5, day2, day6, day4]},
    }

    # 6 weeks x 6/wk
    weeks_data[(6, 6)] = {
        1: {"focus": "Shock Phase", "workouts": [day1, day2, day3, day4, day5, day6]},
        2: {"focus": "Build Phase", "workouts": [day2, day3, day1, day5, day6, day4]},
        3: {"focus": "Overreach - Max Volume", "workouts": [day1, day2, day3, day4, day5, day6]},
        4: {"focus": "Mini Deload - Reduce Volume 30%", "workouts": [day3, day1, day5, day2, day6, day4]},
        5: {"focus": "Peak Phase - Maximum Intensity", "workouts": [day1, day2, day3, day4, day5, day6]},
        6: {"focus": "Final Extreme Push", "workouts": [day2, day3, day1, day5, day6, day4]},
    }

    return weeks_data


def main():
    helper = ProgramSQLHelper()

    # 1. Full Body Fat Torch
    migration_num = helper.get_next_migration_num()
    print(f"\n1. Generating Full Body Fat Torch (migration #{migration_num})...")
    weeks_data = build_full_body_fat_torch()
    success = helper.insert_full_program(
        program_name="Full Body Fat Torch",
        category_name="Fat Loss",
        description="Every session is a full body workout built around heavy compound movements for maximum calorie burn. Squats, deadlifts, presses, and rows form the backbone with metabolic finishers to amplify fat loss.",
        durations=[2, 4, 8],
        sessions_per_week=[4, 4, 5],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )
    if success:
        print("   Full Body Fat Torch inserted!")
        helper.update_tracker("Full Body Fat Torch", "Done")

    # 2. Wedding Ready Shred
    migration_num = helper.get_next_migration_num()
    print(f"\n2. Generating Wedding Ready Shred (migration #{migration_num})...")
    weeks_data = build_wedding_ready_shred()
    success = helper.insert_full_program(
        program_name="Wedding Ready Shred",
        category_name="Fat Loss",
        description="A comprehensive body transformation program for brides and grooms. Emphasizes posture, toned arms, sculpted legs, and a flat midsection. Includes HIIT for fat loss and targeted isolation work for photo-ready definition.",
        durations=[4, 6, 8, 12],
        sessions_per_week=[5, 5, 6, 6],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )
    if success:
        print("   Wedding Ready Shred inserted!")
        helper.update_tracker("Wedding Ready Shred", "Done")

    # 3. Extreme Shred
    migration_num = helper.get_next_migration_num()
    print(f"\n3. Generating Extreme Shred (migration #{migration_num})...")
    weeks_data = build_extreme_shred()
    success = helper.insert_full_program(
        program_name="Extreme Shred",
        category_name="Fat Loss",
        description="An intense 6-day-per-week fat loss program for experienced lifters. Combines heavy compound strength work with supersets, plyometrics, and HIIT conditioning. Not recommended for beginners.",
        durations=[4, 6],
        sessions_per_week=[6, 6],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )
    if success:
        print("   Extreme Shred inserted!")
        helper.update_tracker("Extreme Shred", "Done")

    helper.close()
    print("\nAll remaining fat loss programs complete!")


if __name__ == "__main__":
    main()
