#!/usr/bin/env python3
"""Generate Cut & Maintain - Fat Loss Category (High Priority)
Durations: 4, 8, 12w | Sessions: 4-5/wk | Supersets: Yes
Focus: Preserve muscle while cutting - heavier strength work + moderate cardio
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper

def build_weeks_data():
    weeks_data = {}

    # Core workouts - strength-focused with muscle preservation emphasis
    push_day = {
        "workout_name": "Day 1 - Push (Strength Focus)",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Flat Barbell Bench Press", "sets": 4, "reps": 6, "rest_seconds": 120, "weight_guidance": "Heavy - RPE 8-9, preserve strength", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Arch back, drive feet into floor, touch chest", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Overhead Press", "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Triceps", "Upper Chest"], "difficulty": "intermediate", "form_cue": "Brace core, press straight overhead, lock out", "substitution": "Dumbbell Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Incline Dumbbell Press", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Upper Pectoralis", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "30 degree incline, full stretch at bottom", "substitution": "Incline Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Lateral Raises", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Light to moderate", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": ["Upper Trapezius"], "difficulty": "beginner", "form_cue": "Slight bend in elbows, raise to shoulder height", "substitution": "Cable Lateral Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Tricep Dips", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Bodyweight or weighted", "equipment": "Dip Station", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": ["Chest", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Lean slightly forward, lower to 90 degrees", "substitution": "Close Grip Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Tricep Pushdowns", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Elbows pinned, full extension", "substitution": "Overhead Tricep Extension", "exercise_library_id": None, "in_library": False}
        ]
    }

    pull_day = {
        "workout_name": "Day 2 - Pull (Strength Focus)",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Barbell Deadlift", "sets": 4, "reps": 5, "rest_seconds": 150, "weight_guidance": "Heavy - RPE 8-9, maintain pulling strength", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes", "Hamstrings", "Traps"], "difficulty": "intermediate", "form_cue": "Flat back, push floor away, lock out at top", "substitution": "Trap Bar Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Weighted Pull-Ups", "sets": 4, "reps": 6, "rest_seconds": 90, "weight_guidance": "Add weight to maintain intensity", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "advanced", "form_cue": "Full hang to chin over bar", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Row", "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Pull to lower chest, squeeze back", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Face Pulls", "sets": 3, "reps": 15, "rest_seconds": 45, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids", "External Rotators"], "difficulty": "beginner", "form_cue": "Pull to face, externally rotate", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Curl", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Barbell", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Keep elbows at sides, full range", "substitution": "Dumbbell Curls", "exercise_library_id": None, "in_library": False},
            {"name": "Hammer Curls", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Brachialis", "secondary_muscles": ["Biceps", "Forearms"], "difficulty": "beginner", "form_cue": "Neutral grip, no swinging", "substitution": "Reverse Curls", "exercise_library_id": None, "in_library": False}
        ]
    }

    legs_day = {
        "workout_name": "Day 3 - Legs (Strength Focus)",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 4, "reps": 6, "rest_seconds": 150, "weight_guidance": "Heavy - RPE 8-9, maintain squat strength", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Front Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge at hips, feel hamstring stretch", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Press", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Leg Press Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "beginner", "form_cue": "Full depth, press through heels", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Rear foot on bench, deep stretch", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Calf Raises", "sets": 4, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate to heavy", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full stretch, pause at top", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Hanging Leg Raises", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Lower Abs", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Control the movement, no swinging", "substitution": "Lying Leg Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    conditioning_day = {
        "workout_name": "Day 4 - Conditioning & Core",
        "type": "conditioning",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Kettlebell Swings", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate to heavy KB", "equipment": "Kettlebell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Powerful hip snap", "substitution": "Dumbbell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Rowing Machine Intervals", "sets": 5, "reps": 250, "rest_seconds": 60, "weight_guidance": "250m sprints", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Core", "Arms"], "difficulty": "intermediate", "form_cue": "Drive with legs, max effort", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
            {"name": "Farmer's Walk", "sets": 3, "reps": 40, "rest_seconds": 45, "weight_guidance": "Heavy dumbbells, 40m", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Traps", "Core", "Legs"], "difficulty": "beginner", "form_cue": "Tall posture, brisk pace", "substitution": "Suitcase Carry", "exercise_library_id": None, "in_library": False},
            {"name": "Pallof Press", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "intermediate", "form_cue": "Press out, resist rotation", "substitution": "Plank with Shoulder Tap", "exercise_library_id": None, "in_library": False},
            {"name": "Ab Wheel Rollout", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "intermediate", "form_cue": "Extend fully, pull back with abs", "substitution": "Plank", "exercise_library_id": None, "in_library": False},
            {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "10-20 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lean back, rotate side to side", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    upper_hypertrophy = {
        "workout_name": "Day 5 - Upper Body Volume",
        "type": "hypertrophy",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Dumbbell Bench Press", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate - controlled tempo", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Slow negative, explosive press", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Row", "sets": 4, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "beginner", "form_cue": "Squeeze shoulder blades, hold 1 sec", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Arnold Press", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Rotate as you press, full range", "substitution": "Dumbbell Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Lat Pulldown", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "beginner", "form_cue": "Wide grip, pull to upper chest", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Skull Crushers", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate EZ bar", "equipment": "EZ Bar", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "intermediate", "form_cue": "Lower to forehead, extend fully", "substitution": "Tricep Pushdowns", "exercise_library_id": None, "in_library": False},
            {"name": "Incline Dumbbell Curls", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Full stretch at bottom, squeeze at top", "substitution": "Standing Curls", "exercise_library_id": None, "in_library": False}
        ]
    }

    # Progression push day (heavier)
    push_heavy = {
        "workout_name": "Day 1 - Push (Heavy Singles & Triples)",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Flat Barbell Bench Press", "sets": 5, "reps": 3, "rest_seconds": 180, "weight_guidance": "Very heavy - RPE 9, test your strength", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "advanced", "form_cue": "Maximum tension, controlled eccentric, explosive concentric", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Push Press", "sets": 4, "reps": 5, "rest_seconds": 120, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Legs"], "difficulty": "intermediate", "form_cue": "Dip and drive, use legs to initiate", "substitution": "Strict Press", "exercise_library_id": None, "in_library": False},
            {"name": "Weighted Dips", "sets": 3, "reps": 8, "rest_seconds": 90, "weight_guidance": "Add weight belt or DB between legs", "equipment": "Dip Station", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "advanced", "form_cue": "Lean forward, lower to deep stretch", "substitution": "Tricep Dips", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Flyes", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Cable Machine", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Wide arc, squeeze at center", "substitution": "Dumbbell Flyes", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Lateral Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light weight, strict form", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Lateral Deltoid", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Raise to shoulder height, pause at top", "substitution": "Cable Lateral Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Overhead Tricep Extension", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Arms", "primary_muscle": "Triceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Full stretch at bottom", "substitution": "Tricep Pushdowns", "exercise_library_id": None, "in_library": False}
        ]
    }

    pull_heavy = {
        "workout_name": "Day 2 - Pull (Heavy Focus)",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Barbell Deadlift", "sets": 5, "reps": 3, "rest_seconds": 180, "weight_guidance": "Very heavy - RPE 9", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Erector Spinae", "secondary_muscles": ["Glutes", "Hamstrings", "Traps"], "difficulty": "advanced", "form_cue": "Max tension, smooth pull, lock out", "substitution": "Trap Bar Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Weighted Chin-Ups", "sets": 4, "reps": 5, "rest_seconds": 120, "weight_guidance": "Heavy - add significant weight", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "advanced", "form_cue": "Supinated grip, full range", "substitution": "Pull-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Pendlay Row", "sets": 4, "reps": 5, "rest_seconds": 90, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Dead stop on floor, explosive pull", "substitution": "T-Bar Row", "exercise_library_id": None, "in_library": False},
            {"name": "Chest Supported Row", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Back", "primary_muscle": "Rhomboids", "secondary_muscles": ["Rear Deltoids", "Biceps"], "difficulty": "intermediate", "form_cue": "Face down on incline, row to chest", "substitution": "Seated Cable Row", "exercise_library_id": None, "in_library": False},
            {"name": "Reverse Flyes", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Light dumbbells", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Bend over, raise arms to sides", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Preacher Curls", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate EZ bar", "equipment": "EZ Bar", "body_part": "Arms", "primary_muscle": "Biceps", "secondary_muscles": ["Brachialis"], "difficulty": "beginner", "form_cue": "Full stretch, squeeze at top", "substitution": "Concentration Curls", "exercise_library_id": None, "in_library": False}
        ]
    }

    legs_heavy = {
        "workout_name": "Day 3 - Legs (Heavy Focus)",
        "type": "strength",
        "duration_minutes": 55,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 5, "reps": 3, "rest_seconds": 180, "weight_guidance": "Very heavy - RPE 9", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "advanced", "form_cue": "Below parallel, maximum drive", "substitution": "Front Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Hip Thrust", "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Very heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, squeeze 2 seconds", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Hack Squat", "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Hack Squat Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "Full depth, controlled", "substitution": "Leg Press", "exercise_library_id": None, "in_library": False},
            {"name": "Stiff Leg Deadlift", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Straight legs, hinge deep, feel stretch", "substitution": "Romanian Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Leg Extensions", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Leg Extension Machine", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": [], "difficulty": "beginner", "form_cue": "Squeeze at top, slow negative", "substitution": "Sissy Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Seated Calf Raises", "sets": 4, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Soleus", "secondary_muscles": ["Gastrocnemius"], "difficulty": "beginner", "form_cue": "Full range, hold top 2 sec", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    # ========== 4 WEEKS, 4 sessions/week ==========
    weeks_data[(4, 4)] = {
        1: {"focus": "Strength Baseline - Establish Heavy Lifts While Cutting", "workouts": [push_day, pull_day, legs_day, conditioning_day]},
        2: {"focus": "Progressive Overload - Maintain or Increase Loads", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day]},
        3: {"focus": "Volume Phase - Higher Reps, Moderate Weight", "workouts": [push_day, pull_day, legs_day, conditioning_day]},
        4: {"focus": "Peak Test - Prove Strength Maintained", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day]},
    }

    # ========== 8 WEEKS, 5 sessions/week ==========
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation - Establish Training Loads in Deficit", "workouts": [push_day, pull_day, legs_day, conditioning_day, upper_hypertrophy]},
        2: {"focus": "Build - Progressive Overload on Main Lifts", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]},
        3: {"focus": "Volume Phase - Accumulate Work Capacity", "workouts": [push_day, pull_day, legs_day, conditioning_day, upper_hypertrophy]},
        4: {"focus": "Intensification - Heavier Loads, Lower Reps", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]},
        5: {"focus": "Deload - Active Recovery, Reduce Volume 40%", "workouts": [push_day, pull_day, legs_day, conditioning_day, upper_hypertrophy]},
        6: {"focus": "Second Build - Re-Establish Strength After Recovery", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]},
        7: {"focus": "Peak Phase - Maximum Strength Output", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]},
        8: {"focus": "Final Week - Test All Lifts", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]},
    }

    # ========== 12 WEEKS, 5 sessions/week ==========
    w12 = {}
    for wk in range(1, 9):
        w12[wk] = weeks_data[(8, 5)][wk]
    w12[9] = {"focus": "Third Build Block - Renewed Progression", "workouts": [push_day, pull_day, legs_day, conditioning_day, upper_hypertrophy]}
    w12[10] = {"focus": "Peak Intensification - Heavy Triples and Doubles", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]}
    w12[11] = {"focus": "Taper - Reduce Volume, Maintain Intensity", "workouts": [push_day, pull_day, legs_day, conditioning_day, upper_hypertrophy]}
    w12[12] = {"focus": "Final Test Week - Prove Muscle Preserved", "workouts": [push_heavy, pull_heavy, legs_heavy, conditioning_day, upper_hypertrophy]}
    weeks_data[(12, 5)] = w12

    return weeks_data


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()

    print(f"Generating Cut & Maintain (migration #{migration_num})...")

    weeks_data = build_weeks_data()

    success = helper.insert_full_program(
        program_name="Cut & Maintain",
        category_name="Fat Loss",
        description="A strength-focused cutting program designed to preserve muscle mass while losing body fat. Prioritizes heavy compound lifts to maintain strength, with strategic conditioning sessions for calorie burning. Ideal for intermediate to advanced lifters in a caloric deficit.",
        durations=[4, 8, 12],
        sessions_per_week=[4, 5, 5],
        has_supersets=True,
        priority="High",
        weeks_data=weeks_data,
        migration_num=migration_num,
        write_sql=True,
    )

    if success:
        print("Cut & Maintain inserted successfully!")
        helper.update_tracker("Cut & Maintain", "Done")
    else:
        print("Failed to insert Cut & Maintain")

    helper.close()


if __name__ == "__main__":
    main()
