#!/usr/bin/env python3
"""Generate Sports HIGH priority programs (Category 6):
- Soccer Conditioning (4, 8, 12w x 4-5/wk)
- Basketball Performance (4, 8w x 4-5/wk)
- Tennis Agility (4, 8w x 4-5/wk)
- Martial Arts Foundation (4, 8w x 4-5/wk)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from program_sql_helper import ProgramSQLHelper


def build_soccer_conditioning():
    weeks_data = {}

    endurance_day = {
        "workout_name": "Day 1 - Aerobic Base & Endurance",
        "type": "conditioning",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Treadmill Tempo Run", "sets": 3, "reps": 5, "rest_seconds": 90, "weight_guidance": "5-minute intervals at 75-80% max heart rate", "equipment": "Treadmill", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Steady pace, controlled breathing", "substitution": "Outdoor Running", "exercise_library_id": None, "in_library": False},
            {"name": "Box Step-Ups", "sets": 3, "reps": 12, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Drive through lead leg, full extension", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Romanian Deadlift", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Balance on one leg, hinge at hip, keep back flat", "substitution": "Romanian Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Copenhagen Plank", "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "Hold 20 seconds each side", "equipment": "Bench", "body_part": "Core", "primary_muscle": "Adductors", "secondary_muscles": ["Obliques", "Core"], "difficulty": "intermediate", "form_cue": "Top foot on bench, bottom leg hangs, hold straight line", "substitution": "Side Plank", "exercise_library_id": None, "in_library": False},
            {"name": "Calf Raises (Slow Eccentric)", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight or light weight, 3-sec lower", "equipment": "None", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Raise fast, lower over 3 seconds", "substitution": "Seated Calf Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 45, "rest_seconds": 30, "weight_guidance": "45-second holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Brace hard, straight line", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
        ]
    }

    agility_day = {
        "workout_name": "Day 2 - Agility & Speed",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Ladder Drills (In-Out)", "sets": 4, "reps": 2, "rest_seconds": 30, "weight_guidance": "2 lengths of ladder, max speed", "equipment": "Agility Ladder", "body_part": "Full Body", "primary_muscle": "Calves", "secondary_muscles": ["Quadriceps", "Hip Flexors", "Core"], "difficulty": "intermediate", "form_cue": "Quick feet, stay on balls of feet", "substitution": "High Knees in Place", "exercise_library_id": None, "in_library": False},
            {"name": "Lateral Shuffle", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 meters each direction", "equipment": "None", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Glutes", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Low stance, quick feet, don't cross feet", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Cone Drills (5-10-5 Shuttle)", "sets": 5, "reps": 1, "rest_seconds": 45, "weight_guidance": "Max effort each rep", "equipment": "Cones", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Touch line, change direction explosively", "substitution": "Shuttle Runs", "exercise_library_id": None, "in_library": False},
            {"name": "Sprint Intervals", "sets": 6, "reps": 30, "rest_seconds": 60, "weight_guidance": "30-meter sprints at 90-95% effort", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Glutes"], "difficulty": "intermediate", "form_cue": "Explosive start, drive arms, high knees", "substitution": "Treadmill Sprints", "exercise_library_id": None, "in_library": False},
            {"name": "Bounding", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Exaggerated running strides", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Long strides, drive knee high, swing arms", "substitution": "Broad Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Deceleration Drills", "sets": 4, "reps": 1, "rest_seconds": 30, "weight_guidance": "Sprint 20m, decelerate in 5m", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Lower center of gravity, chop steps to stop", "substitution": "Backpedal Sprints", "exercise_library_id": None, "in_library": False}
        ]
    }

    strength_day = {
        "workout_name": "Day 3 - Lower Body Strength",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Barbell Back Squat", "sets": 4, "reps": 6, "rest_seconds": 120, "weight_guidance": "Heavy - RPE 8, build leg power", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings", "Core"], "difficulty": "intermediate", "form_cue": "Below parallel, drive through heels", "substitution": "Front Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 90, "weight_guidance": "Heavy - hamstring injury prevention", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge deep, bar slides down thighs", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Rear foot elevated, single leg strength", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, 2 sec squeeze", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Nordic Hamstring Curls", "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Bodyweight - key injury prevention exercise", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "advanced", "form_cue": "Control eccentric, use hands to push back up", "substitution": "Leg Curls", "exercise_library_id": None, "in_library": False},
            {"name": "Pallof Press", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "intermediate", "form_cue": "Anti-rotation, press out and hold", "substitution": "Plank with Shoulder Tap", "exercise_library_id": None, "in_library": False}
        ]
    }

    power_day = {
        "workout_name": "Day 4 - Power & Explosiveness",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Box Jumps", "sets": 4, "reps": 6, "rest_seconds": 60, "weight_guidance": "24-30 inch box, max height", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Reset each rep, maximum height", "substitution": "Jump Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Broad Jumps", "sets": 4, "reps": 5, "rest_seconds": 60, "weight_guidance": "Max distance each rep", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Quadriceps", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Arm swing, drive forward, stick landing", "substitution": "Tuck Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Rotational Throw", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "8-12 lb ball, throw against wall", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Core", "Hips"], "difficulty": "intermediate", "form_cue": "Rotate from hips, release at hip height", "substitution": "Cable Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Hop (Bounding)", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Hop forward on one leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Drive knee, land softly on same leg", "substitution": "Walking Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Hang Clean", "sets": 4, "reps": 5, "rest_seconds": 75, "weight_guidance": "Moderate barbell", "equipment": "Barbell", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Traps", "Shoulders"], "difficulty": "advanced", "form_cue": "Explosive hip extension, catch in front rack", "substitution": "Kettlebell Swings", "exercise_library_id": None, "in_library": False},
            {"name": "Anti-Rotation Press", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Obliques"], "difficulty": "intermediate", "form_cue": "Press cable out, resist rotation", "substitution": "Pallof Press", "exercise_library_id": None, "in_library": False}
        ]
    }

    conditioning_day = {
        "workout_name": "Day 5 - Match Fitness Conditioning",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Fartlek Intervals", "sets": 1, "reps": 20, "rest_seconds": 0, "weight_guidance": "20-min run: alternate 1-min hard, 1-min easy", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Vary pace throughout, simulate match running", "substitution": "Treadmill Intervals", "exercise_library_id": None, "in_library": False},
            {"name": "Sprint-Jog-Sprint", "sets": 6, "reps": 1, "rest_seconds": 30, "weight_guidance": "Sprint 30m, jog 30m, sprint 30m", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "intermediate", "form_cue": "Simulate transition between jog and sprint", "substitution": "Treadmill Sprints", "exercise_library_id": None, "in_library": False},
            {"name": "Lateral Shuffle to Sprint", "sets": 5, "reps": 1, "rest_seconds": 45, "weight_guidance": "Shuffle 10m then sprint 20m", "equipment": "None", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Quadriceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Quick shuffle, explosive transition to sprint", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Backwards Run", "sets": 4, "reps": 30, "rest_seconds": 45, "weight_guidance": "30-meter backpedals", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings"], "difficulty": "beginner", "form_cue": "Stay on toes, short quick steps", "substitution": "High Knees", "exercise_library_id": None, "in_library": False},
            {"name": "Burpees", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight - simulates getting up from ground", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Chest to floor, pop up fast", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Build Aerobic Base & Movement Quality", "workouts": [endurance_day, agility_day, strength_day, power_day]},
        2: {"focus": "Develop Speed & Agility", "workouts": [agility_day, strength_day, power_day, endurance_day]},
        3: {"focus": "Peak Power & Match Fitness", "workouts": [strength_day, power_day, agility_day, endurance_day]},
        4: {"focus": "Match Ready - Game Simulation", "workouts": [power_day, agility_day, endurance_day, strength_day]},
    }

    # 8w x 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Aerobic Foundation", "workouts": [endurance_day, agility_day, strength_day, power_day, conditioning_day]},
        2: {"focus": "Speed Development", "workouts": [agility_day, strength_day, power_day, conditioning_day, endurance_day]},
        3: {"focus": "Strength Building", "workouts": [strength_day, power_day, agility_day, endurance_day, conditioning_day]},
        4: {"focus": "Power Phase", "workouts": [power_day, agility_day, strength_day, conditioning_day, endurance_day]},
        5: {"focus": "Recovery Week", "workouts": [endurance_day, agility_day, strength_day, endurance_day, agility_day]},
        6: {"focus": "Match Fitness Build", "workouts": [conditioning_day, agility_day, strength_day, power_day, endurance_day]},
        7: {"focus": "Peak Performance", "workouts": [power_day, agility_day, conditioning_day, strength_day, endurance_day]},
        8: {"focus": "Game Ready - Final Preparation", "workouts": [conditioning_day, power_day, agility_day, strength_day, endurance_day]},
    }

    # 12w x 5/wk
    w12 = {}
    for wk in range(1, 9):
        w12[wk] = weeks_data[(8, 5)][wk]
    w12[9] = {"focus": "Second Strength Block", "workouts": [strength_day, power_day, agility_day, conditioning_day, endurance_day]}
    w12[10] = {"focus": "Speed & Agility Peak", "workouts": [agility_day, power_day, conditioning_day, strength_day, endurance_day]}
    w12[11] = {"focus": "Taper - Maintain Fitness", "workouts": [endurance_day, agility_day, strength_day, power_day, conditioning_day]}
    w12[12] = {"focus": "Season Ready", "workouts": [conditioning_day, agility_day, power_day, strength_day, endurance_day]}
    weeks_data[(12, 5)] = w12

    return weeks_data


def build_basketball_performance():
    weeks_data = {}

    vertical_day = {
        "workout_name": "Day 1 - Vertical Jump & Explosiveness",
        "type": "conditioning",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Depth Jumps", "sets": 4, "reps": 5, "rest_seconds": 90, "weight_guidance": "Step off 18-24 inch box, immediately jump max height", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Minimal ground contact time, explode up", "substitution": "Box Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Back Squat", "sets": 4, "reps": 5, "rest_seconds": 120, "weight_guidance": "Heavy - RPE 8-9", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Below parallel, explosive drive up", "substitution": "Front Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Trap Bar Deadlift", "sets": 4, "reps": 5, "rest_seconds": 120, "weight_guidance": "Heavy - explosive pull", "equipment": "Trap Bar", "body_part": "Full Body", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings", "Quadriceps", "Traps"], "difficulty": "intermediate", "form_cue": "Drive through floor, fast lockout", "substitution": "Conventional Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Box Jump", "sets": 3, "reps": 5, "rest_seconds": 60, "weight_guidance": "Low box, each leg", "equipment": "Plyo Box", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "advanced", "form_cue": "Single leg takeoff, land on box with both feet", "substitution": "Single Leg Squat Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Calf Raises", "sets": 4, "reps": 12, "rest_seconds": 30, "weight_guidance": "Heavy - build calf power", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, explosive up, slow down", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Hanging Leg Raises", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Lower Abs", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Control the movement", "substitution": "Lying Leg Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    lateral_day = {
        "workout_name": "Day 2 - Lateral Quickness & Defense",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Lateral Shuffle Drill", "sets": 5, "reps": 10, "rest_seconds": 30, "weight_guidance": "10 meters each direction, defensive stance", "equipment": "Cones", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Glutes", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Stay low, quick feet, don't cross feet over", "substitution": "Lateral Band Walks", "exercise_library_id": None, "in_library": False},
            {"name": "Lateral Bounds", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Maximum lateral distance", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Adductors", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Push off one leg, land softly on other", "substitution": "Skater Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Goblet Lateral Squat", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Quadriceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Wide stance, shift weight to one side, sit deep", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Hop (Lateral)", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Hop side to side on one leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Calves", "Core"], "difficulty": "intermediate", "form_cue": "Quick hops, stick each landing 1 sec", "substitution": "Skater Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Defensive Slide Sprint Drill", "sets": 5, "reps": 1, "rest_seconds": 45, "weight_guidance": "Slide 5m, sprint 10m, slide 5m", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Calves"], "difficulty": "intermediate", "form_cue": "Low defensive stance, explosive transition to sprint", "substitution": "Shuttle Runs", "exercise_library_id": None, "in_library": False},
            {"name": "Copenhagen Plank", "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "20-second holds each side", "equipment": "Bench", "body_part": "Core", "primary_muscle": "Adductors", "secondary_muscles": ["Obliques"], "difficulty": "intermediate", "form_cue": "Top foot on bench, hold straight line", "substitution": "Side Plank", "exercise_library_id": None, "in_library": False}
        ]
    }

    upper_body = {
        "workout_name": "Day 3 - Upper Body & Core Strength",
        "type": "strength",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Dumbbell Bench Press", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Dumbbells", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Control negative, explosive press", "substitution": "Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Pull-Ups", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight or weighted", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rear Deltoids"], "difficulty": "intermediate", "form_cue": "Full hang to chin over bar", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Shoulder Press", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate weight", "equipment": "Dumbbells", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps"], "difficulty": "intermediate", "form_cue": "Press overhead, lock out", "substitution": "Pike Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Chest Pass", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "8-12 lb ball, throw against wall", "equipment": "Medicine Ball", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Core"], "difficulty": "intermediate", "form_cue": "Explosive push from chest, catch and repeat", "substitution": "Clap Push-Ups", "exercise_library_id": None, "in_library": False},
            {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 30, "weight_guidance": "10-15 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lean back, rotate fully side to side", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False},
            {"name": "Ab Wheel Rollout", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Ab Wheel", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Shoulders"], "difficulty": "intermediate", "form_cue": "Extend fully, core tight", "substitution": "Plank", "exercise_library_id": None, "in_library": False}
        ]
    }

    court_conditioning = {
        "workout_name": "Day 4 - Court Conditioning",
        "type": "conditioning",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Suicide Drills (17s)", "sets": 5, "reps": 1, "rest_seconds": 60, "weight_guidance": "Baseline to free throw to half court to far free throw to far baseline", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves", "Core"], "difficulty": "intermediate", "form_cue": "Touch each line, change direction quickly", "substitution": "Shuttle Runs", "exercise_library_id": None, "in_library": False},
            {"name": "Full Court Sprints", "sets": 6, "reps": 1, "rest_seconds": 45, "weight_guidance": "Full court and back", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Hamstrings", "Calves"], "difficulty": "intermediate", "form_cue": "Maximum effort, simulate fast break", "substitution": "Treadmill Sprints", "exercise_library_id": None, "in_library": False},
            {"name": "Defensive Slides", "sets": 4, "reps": 30, "rest_seconds": 30, "weight_guidance": "30 seconds per set in defensive stance", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Glutes"], "difficulty": "intermediate", "form_cue": "Stay low, quick feet, hands active", "substitution": "Lateral Shuffle", "exercise_library_id": None, "in_library": False},
            {"name": "Jump Squats", "sets": 4, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight, simulate rebounding", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Max height, immediate rebound on landing", "substitution": "Tuck Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Mountain Climbers", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "Bodyweight - fast", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders", "Hip Flexors"], "difficulty": "beginner", "form_cue": "Drive knees rapidly", "substitution": "High Knees", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 45, "rest_seconds": 20, "weight_guidance": "45-sec holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Straight line, brace hard", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Build Explosive Foundation", "workouts": [vertical_day, lateral_day, upper_body, court_conditioning]},
        2: {"focus": "Speed & Lateral Quickness", "workouts": [lateral_day, vertical_day, court_conditioning, upper_body]},
        3: {"focus": "Peak Power Phase", "workouts": [vertical_day, court_conditioning, upper_body, lateral_day]},
        4: {"focus": "Game Ready - Full Integration", "workouts": [court_conditioning, vertical_day, lateral_day, upper_body]},
    }

    # 8w x 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation - Strength Base", "workouts": [vertical_day, lateral_day, upper_body, court_conditioning, vertical_day]},
        2: {"focus": "Speed Development", "workouts": [lateral_day, vertical_day, upper_body, court_conditioning, lateral_day]},
        3: {"focus": "Explosive Power", "workouts": [vertical_day, court_conditioning, upper_body, lateral_day, vertical_day]},
        4: {"focus": "Agility Peak", "workouts": [court_conditioning, lateral_day, vertical_day, upper_body, court_conditioning]},
        5: {"focus": "Recovery Week", "workouts": [upper_body, lateral_day, vertical_day, upper_body, court_conditioning]},
        6: {"focus": "Second Power Block", "workouts": [vertical_day, lateral_day, court_conditioning, upper_body, vertical_day]},
        7: {"focus": "Peak Performance", "workouts": [court_conditioning, vertical_day, lateral_day, upper_body, court_conditioning]},
        8: {"focus": "Game Time - Maximum Performance", "workouts": [vertical_day, court_conditioning, lateral_day, upper_body, court_conditioning]},
    }

    return weeks_data


def build_tennis_agility():
    weeks_data = {}

    lateral_power = {
        "workout_name": "Day 1 - Lateral Power & First Step",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Lateral Bounds", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "Maximum lateral distance", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Adductors", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Push off, land softly, stick 1 sec", "substitution": "Skater Jumps", "exercise_library_id": None, "in_library": False},
            {"name": "Goblet Lateral Squat", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Adductors", "secondary_muscles": ["Quadriceps", "Glutes"], "difficulty": "intermediate", "form_cue": "Wide stance, shift weight, sit deep", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Split Squat Jump", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Switch legs in air, land in lunge", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Cone Drill (T-Drill)", "sets": 5, "reps": 1, "rest_seconds": 60, "weight_guidance": "Sprint, shuffle left, shuffle right, backpedal", "equipment": "Cones", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Calves"], "difficulty": "intermediate", "form_cue": "Touch each cone, change direction explosively", "substitution": "Shuttle Runs", "exercise_library_id": None, "in_library": False},
            {"name": "Single Leg Romanian Deadlift", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate dumbbell", "equipment": "Dumbbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Core"], "difficulty": "intermediate", "form_cue": "Balance, hinge, feel hamstring stretch", "substitution": "Romanian Deadlift", "exercise_library_id": None, "in_library": False},
            {"name": "Pallof Press", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Core"], "difficulty": "intermediate", "form_cue": "Resist rotation, press out", "substitution": "Plank with Shoulder Tap", "exercise_library_id": None, "in_library": False}
        ]
    }

    rotational_power = {
        "workout_name": "Day 2 - Rotational Power & Shoulder Health",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Medicine Ball Rotational Throw", "sets": 4, "reps": 8, "rest_seconds": 45, "weight_guidance": "8-12 lb ball each side", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Core", "Hips", "Shoulders"], "difficulty": "intermediate", "form_cue": "Rotate from hips, release at hip height against wall", "substitution": "Cable Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Cable Woodchops", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate weight each side", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Core", "Shoulders"], "difficulty": "intermediate", "form_cue": "High to low, rotate from core", "substitution": "Dumbbell Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "External Rotation (Band)", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light band - shoulder prehab", "equipment": "Resistance Band", "body_part": "Shoulders", "primary_muscle": "External Rotators", "secondary_muscles": ["Rear Deltoids"], "difficulty": "beginner", "form_cue": "Elbow at side, rotate forearm out", "substitution": "Dumbbell External Rotation", "exercise_library_id": None, "in_library": False},
            {"name": "Face Pulls", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Light to moderate", "equipment": "Cable Machine", "body_part": "Shoulders", "primary_muscle": "Rear Deltoids", "secondary_muscles": ["Rhomboids"], "difficulty": "beginner", "form_cue": "Pull to face, externally rotate", "substitution": "Band Pull-Aparts", "exercise_library_id": None, "in_library": False},
            {"name": "Dumbbell Row", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate to heavy", "equipment": "Dumbbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps", "Rhomboids"], "difficulty": "intermediate", "form_cue": "Pull to hip, squeeze back", "substitution": "Cable Row", "exercise_library_id": None, "in_library": False},
            {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "10-15 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lean back, rotate fully", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    leg_strength = {
        "workout_name": "Day 3 - Lower Body Strength",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Front Squat", "sets": 4, "reps": 6, "rest_seconds": 90, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Elbows high, sit deep", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge deep, bar along thighs", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 8, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "Single leg strength for court movement", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 3, "reps": 10, "rest_seconds": 60, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Full lockout, squeeze hard", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Calf Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, quick up, slow down", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 45, "rest_seconds": 30, "weight_guidance": "45-sec holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Brace hard, straight line", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
        ]
    }

    court_fitness = {
        "workout_name": "Day 4 - Court Fitness & Endurance",
        "type": "conditioning",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Shuttle Runs (Side-to-Side)", "sets": 6, "reps": 1, "rest_seconds": 45, "weight_guidance": "Simulate baseline to baseline movement", "equipment": "Cones", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Adductors", "Calves"], "difficulty": "intermediate", "form_cue": "Touch line, push off, change direction", "substitution": "Lateral Shuffle", "exercise_library_id": None, "in_library": False},
            {"name": "Sprint Forward, Backpedal Back", "sets": 5, "reps": 1, "rest_seconds": 45, "weight_guidance": "Sprint 20m, backpedal to start", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Calves", "Hamstrings"], "difficulty": "intermediate", "form_cue": "Explosive forward, controlled backward", "substitution": "Shuttle Runs", "exercise_library_id": None, "in_library": False},
            {"name": "Skater Jumps", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Glutes", "secondary_muscles": ["Adductors", "Quadriceps"], "difficulty": "intermediate", "form_cue": "Leap side to side, touch floor", "substitution": "Lateral Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Burpees", "sets": 3, "reps": 8, "rest_seconds": 30, "weight_guidance": "Bodyweight - recover from ground quickly", "equipment": "None", "body_part": "Full Body", "primary_muscle": "Full Body", "secondary_muscles": ["Chest", "Legs", "Core"], "difficulty": "intermediate", "form_cue": "Simulate getting up quickly after a dive", "substitution": "Squat Thrusts", "exercise_library_id": None, "in_library": False},
            {"name": "Rowing Machine", "sets": 3, "reps": 500, "rest_seconds": 60, "weight_guidance": "500m moderate effort intervals", "equipment": "Rowing Machine", "body_part": "Full Body", "primary_muscle": "Back", "secondary_muscles": ["Legs", "Arms"], "difficulty": "intermediate", "form_cue": "Build cardio base for long rallies", "substitution": "Assault Bike", "exercise_library_id": None, "in_library": False},
            {"name": "Dead Bug", "sets": 3, "reps": 12, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Transverse Abdominis", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Lower back pressed down", "substitution": "Bird Dog", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Build Lateral Movement Foundation", "workouts": [lateral_power, rotational_power, leg_strength, court_fitness]},
        2: {"focus": "Develop First Step Speed", "workouts": [rotational_power, lateral_power, court_fitness, leg_strength]},
        3: {"focus": "Peak Agility & Power", "workouts": [lateral_power, leg_strength, rotational_power, court_fitness]},
        4: {"focus": "Match Ready - Full Court Integration", "workouts": [court_fitness, lateral_power, rotational_power, leg_strength]},
    }

    # 8w x 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation - Movement Quality", "workouts": [lateral_power, rotational_power, leg_strength, court_fitness, lateral_power]},
        2: {"focus": "Speed Development", "workouts": [rotational_power, lateral_power, court_fitness, leg_strength, rotational_power]},
        3: {"focus": "Strength Building", "workouts": [leg_strength, lateral_power, rotational_power, court_fitness, leg_strength]},
        4: {"focus": "Power Phase", "workouts": [lateral_power, court_fitness, leg_strength, rotational_power, lateral_power]},
        5: {"focus": "Recovery Week", "workouts": [rotational_power, leg_strength, court_fitness, rotational_power, leg_strength]},
        6: {"focus": "Second Speed Block", "workouts": [lateral_power, rotational_power, court_fitness, leg_strength, lateral_power]},
        7: {"focus": "Peak Performance", "workouts": [court_fitness, lateral_power, rotational_power, leg_strength, court_fitness]},
        8: {"focus": "Tournament Ready", "workouts": [lateral_power, court_fitness, rotational_power, leg_strength, court_fitness]},
    }

    return weeks_data


def build_martial_arts_foundation():
    weeks_data = {}

    kick_power = {
        "workout_name": "Day 1 - Kick Power & Leg Strength",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Front Squat", "sets": 4, "reps": 6, "rest_seconds": 90, "weight_guidance": "Heavy - RPE 8", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Core", "Glutes"], "difficulty": "intermediate", "form_cue": "Deep squat, explosive drive", "substitution": "Goblet Squat", "exercise_library_id": None, "in_library": False},
            {"name": "Romanian Deadlift", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy", "equipment": "Barbell", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Glutes", "Erector Spinae"], "difficulty": "intermediate", "form_cue": "Hinge deep, strong posterior chain", "substitution": "Dumbbell RDL", "exercise_library_id": None, "in_library": False},
            {"name": "Bulgarian Split Squat", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate dumbbells", "equipment": "Dumbbells", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes"], "difficulty": "intermediate", "form_cue": "Single leg kick power", "substitution": "Reverse Lunges", "exercise_library_id": None, "in_library": False},
            {"name": "Hip Thrust", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Heavy barbell", "equipment": "Barbell", "body_part": "Glutes", "primary_muscle": "Glutes", "secondary_muscles": ["Hamstrings"], "difficulty": "intermediate", "form_cue": "Explosive extension for kick power", "substitution": "Glute Bridge", "exercise_library_id": None, "in_library": False},
            {"name": "Jump Squats", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Legs", "primary_muscle": "Quadriceps", "secondary_muscles": ["Glutes", "Calves"], "difficulty": "intermediate", "form_cue": "Explosive, max height", "substitution": "Bodyweight Squats", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Calf Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Moderate weight", "equipment": "Calf Raise Machine", "body_part": "Legs", "primary_muscle": "Gastrocnemius", "secondary_muscles": ["Soleus"], "difficulty": "beginner", "form_cue": "Full range, explosive power for footwork", "substitution": "Single Leg Calf Raises", "exercise_library_id": None, "in_library": False}
        ]
    }

    striking_power = {
        "workout_name": "Day 2 - Striking Power & Upper Body",
        "type": "strength",
        "duration_minutes": 50,
        "exercises": [
            {"name": "Flat Barbell Bench Press", "sets": 4, "reps": 6, "rest_seconds": 90, "weight_guidance": "Heavy - punching power", "equipment": "Barbell", "body_part": "Chest", "primary_muscle": "Pectoralis Major", "secondary_muscles": ["Triceps", "Anterior Deltoid"], "difficulty": "intermediate", "form_cue": "Explosive press, controlled negative", "substitution": "Dumbbell Bench Press", "exercise_library_id": None, "in_library": False},
            {"name": "Barbell Row", "sets": 4, "reps": 8, "rest_seconds": 60, "weight_guidance": "Heavy - pulling power", "equipment": "Barbell", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Rhomboids", "Biceps"], "difficulty": "intermediate", "form_cue": "Flat back, pull to lower chest", "substitution": "Dumbbell Row", "exercise_library_id": None, "in_library": False},
            {"name": "Push Press", "sets": 3, "reps": 6, "rest_seconds": 60, "weight_guidance": "Moderate to heavy", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Deltoids", "secondary_muscles": ["Triceps", "Legs"], "difficulty": "intermediate", "form_cue": "Dip and drive, full body power", "substitution": "Overhead Press", "exercise_library_id": None, "in_library": False},
            {"name": "Medicine Ball Rotational Throw", "sets": 3, "reps": 10, "rest_seconds": 30, "weight_guidance": "8-12 lb ball", "equipment": "Medicine Ball", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Core", "Hips"], "difficulty": "intermediate", "form_cue": "Rotate from hips like a cross punch", "substitution": "Cable Woodchops", "exercise_library_id": None, "in_library": False},
            {"name": "Landmine Press", "sets": 3, "reps": 10, "rest_seconds": 45, "weight_guidance": "Moderate weight each arm", "equipment": "Barbell", "body_part": "Shoulders", "primary_muscle": "Anterior Deltoid", "secondary_muscles": ["Core", "Triceps"], "difficulty": "intermediate", "form_cue": "Press at angle, mimics punching motion", "substitution": "Dumbbell Shoulder Press", "exercise_library_id": None, "in_library": False},
            {"name": "Pull-Ups", "sets": 3, "reps": 8, "rest_seconds": 60, "weight_guidance": "Bodyweight - clinch strength", "equipment": "Pull-Up Bar", "body_part": "Back", "primary_muscle": "Latissimus Dorsi", "secondary_muscles": ["Biceps"], "difficulty": "intermediate", "form_cue": "Full hang, chin over bar, grip strength", "substitution": "Lat Pulldown", "exercise_library_id": None, "in_library": False}
        ]
    }

    flexibility_conditioning = {
        "workout_name": "Day 3 - Flexibility & Conditioning",
        "type": "conditioning",
        "duration_minutes": 45,
        "exercises": [
            {"name": "Hip Flexor Stretch (Kneeling)", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Hip Flexors", "secondary_muscles": ["Psoas"], "difficulty": "beginner", "form_cue": "Half kneeling, push hips forward - essential for kicks", "substitution": "Standing Hip Flexor Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Pigeon Pose", "sets": 2, "reps": 45, "rest_seconds": 10, "weight_guidance": "Hold 45 seconds each side", "equipment": "None", "body_part": "Hips", "primary_muscle": "Glutes", "secondary_muscles": ["Piriformis"], "difficulty": "beginner", "form_cue": "Open hips for high kicks", "substitution": "Figure Four Stretch", "exercise_library_id": None, "in_library": False},
            {"name": "Standing Hamstring Stretch", "sets": 2, "reps": 30, "rest_seconds": 10, "weight_guidance": "Hold 30 seconds each leg", "equipment": "None", "body_part": "Legs", "primary_muscle": "Hamstrings", "secondary_muscles": ["Calves"], "difficulty": "beginner", "form_cue": "Foot elevated, hinge at hips", "substitution": "Seated Forward Fold", "exercise_library_id": None, "in_library": False},
            {"name": "Assault Bike Intervals", "sets": 6, "reps": 15, "rest_seconds": 45, "weight_guidance": "15-cal max effort rounds", "equipment": "Assault Bike", "body_part": "Full Body", "primary_muscle": "Quadriceps", "secondary_muscles": ["Arms", "Core"], "difficulty": "intermediate", "form_cue": "Simulate round intensity (3 min rounds)", "substitution": "Burpees", "exercise_library_id": None, "in_library": False},
            {"name": "Shadow Boxing with Dumbbells", "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "1-3 lb dumbbells, 60-second rounds", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Shoulders", "secondary_muscles": ["Core", "Arms"], "difficulty": "intermediate", "form_cue": "Throw punches with light weights, keep hands up", "substitution": "Shadow Boxing", "exercise_library_id": None, "in_library": False},
            {"name": "V-Ups", "sets": 3, "reps": 15, "rest_seconds": 20, "weight_guidance": "Bodyweight", "equipment": "None", "body_part": "Core", "primary_muscle": "Rectus Abdominis", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Touch toes at top", "substitution": "Crunches", "exercise_library_id": None, "in_library": False}
        ]
    }

    core_grip = {
        "workout_name": "Day 4 - Core & Grip Strength",
        "type": "strength",
        "duration_minutes": 40,
        "exercises": [
            {"name": "Farmer's Walk", "sets": 4, "reps": 40, "rest_seconds": 60, "weight_guidance": "Heavy dumbbells, 40m - grip endurance", "equipment": "Dumbbells", "body_part": "Full Body", "primary_muscle": "Forearms", "secondary_muscles": ["Traps", "Core"], "difficulty": "beginner", "form_cue": "Tall posture, white-knuckle grip", "substitution": "Plate Pinch Hold", "exercise_library_id": None, "in_library": False},
            {"name": "Hanging Knee Raises", "sets": 3, "reps": 15, "rest_seconds": 30, "weight_guidance": "Bodyweight", "equipment": "Pull-Up Bar", "body_part": "Core", "primary_muscle": "Lower Abs", "secondary_muscles": ["Hip Flexors"], "difficulty": "intermediate", "form_cue": "Controlled, no swinging", "substitution": "Lying Knee Raises", "exercise_library_id": None, "in_library": False},
            {"name": "Pallof Press", "sets": 3, "reps": 12, "rest_seconds": 30, "weight_guidance": "Moderate cable", "equipment": "Cable Machine", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Transverse Abdominis"], "difficulty": "intermediate", "form_cue": "Anti-rotation for clinch work", "substitution": "Plank with Shoulder Tap", "exercise_library_id": None, "in_library": False},
            {"name": "Dead Hang", "sets": 3, "reps": 30, "rest_seconds": 45, "weight_guidance": "Hold 30 seconds", "equipment": "Pull-Up Bar", "body_part": "Arms", "primary_muscle": "Forearms", "secondary_muscles": ["Shoulders", "Lats"], "difficulty": "beginner", "form_cue": "Full grip, hang from bar", "substitution": "Towel Hang", "exercise_library_id": None, "in_library": False},
            {"name": "Russian Twists", "sets": 3, "reps": 20, "rest_seconds": 20, "weight_guidance": "10-15 lb weight", "equipment": "Dumbbell", "body_part": "Core", "primary_muscle": "Obliques", "secondary_muscles": ["Rectus Abdominis"], "difficulty": "beginner", "form_cue": "Rotate fully - rotational striking power", "substitution": "Bicycle Crunches", "exercise_library_id": None, "in_library": False},
            {"name": "Plank", "sets": 3, "reps": 60, "rest_seconds": 30, "weight_guidance": "60-second holds", "equipment": "None", "body_part": "Core", "primary_muscle": "Core", "secondary_muscles": ["Shoulders"], "difficulty": "beginner", "form_cue": "Brace hard, protect the body", "substitution": "Dead Bug", "exercise_library_id": None, "in_library": False}
        ]
    }

    # 4w x 4/wk
    weeks_data[(4, 4)] = {
        1: {"focus": "Build Strength Foundation for Martial Arts", "workouts": [kick_power, striking_power, flexibility_conditioning, core_grip]},
        2: {"focus": "Develop Explosive Power", "workouts": [striking_power, kick_power, core_grip, flexibility_conditioning]},
        3: {"focus": "Conditioning & Flexibility Peak", "workouts": [flexibility_conditioning, kick_power, striking_power, core_grip]},
        4: {"focus": "Fight Ready - Full Integration", "workouts": [kick_power, striking_power, flexibility_conditioning, core_grip]},
    }

    # 8w x 5/wk
    weeks_data[(8, 5)] = {
        1: {"focus": "Foundation - Assess & Build", "workouts": [kick_power, striking_power, flexibility_conditioning, core_grip, kick_power]},
        2: {"focus": "Power Development", "workouts": [striking_power, kick_power, core_grip, flexibility_conditioning, striking_power]},
        3: {"focus": "Conditioning Phase", "workouts": [flexibility_conditioning, kick_power, striking_power, core_grip, flexibility_conditioning]},
        4: {"focus": "Strength Peak", "workouts": [kick_power, striking_power, core_grip, flexibility_conditioning, kick_power]},
        5: {"focus": "Recovery - Active Flexibility", "workouts": [flexibility_conditioning, core_grip, kick_power, flexibility_conditioning, core_grip]},
        6: {"focus": "Second Power Block", "workouts": [striking_power, kick_power, core_grip, flexibility_conditioning, striking_power]},
        7: {"focus": "Fight Conditioning", "workouts": [flexibility_conditioning, kick_power, striking_power, core_grip, flexibility_conditioning]},
        8: {"focus": "Ready to Train - Full Integration", "workouts": [kick_power, striking_power, flexibility_conditioning, core_grip, kick_power]},
    }

    return weeks_data


def main():
    helper = ProgramSQLHelper()

    # 1. Soccer Conditioning
    mig = helper.get_next_migration_num()
    print(f"\n1. Generating Soccer Conditioning (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Soccer Conditioning",
        category_name="Sports",
        description="Complete soccer fitness program covering endurance, agility, speed, lower body strength, explosive power, and match-day conditioning. Includes injury prevention exercises like Nordic curls and Copenhagen planks.",
        durations=[4, 8, 12], sessions_per_week=[4, 5, 5],
        has_supersets=True, priority="High",
        weeks_data=build_soccer_conditioning(), migration_num=mig, write_sql=True)
    if success:
        print("   Soccer Conditioning inserted!")
        helper.update_tracker("Soccer Conditioning", "Done")

    # 2. Basketball Performance
    mig = helper.get_next_migration_num()
    print(f"\n2. Generating Basketball Performance (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Basketball Performance",
        category_name="Sports",
        description="Basketball-specific training focusing on vertical jump, lateral quickness, court conditioning, and upper body strength. Features depth jumps, defensive slide drills, and game-simulation conditioning.",
        durations=[4, 8], sessions_per_week=[4, 5],
        has_supersets=True, priority="High",
        weeks_data=build_basketball_performance(), migration_num=mig, write_sql=True)
    if success:
        print("   Basketball Performance inserted!")
        helper.update_tracker("Basketball Performance", "Done")

    # 3. Tennis Agility
    mig = helper.get_next_migration_num()
    print(f"\n3. Generating Tennis Agility (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Tennis Agility",
        category_name="Sports",
        description="Tennis-specific training program emphasizing lateral movement, rotational power, shoulder health, and court endurance. Features first-step speed drills, medicine ball throws, and shoulder prehab work.",
        durations=[4, 8], sessions_per_week=[4, 5],
        has_supersets=True, priority="High",
        weeks_data=build_tennis_agility(), migration_num=mig, write_sql=True)
    if success:
        print("   Tennis Agility inserted!")
        helper.update_tracker("Tennis Agility", "Done")

    # 4. Martial Arts Foundation
    mig = helper.get_next_migration_num()
    print(f"\n4. Generating Martial Arts Foundation (migration #{mig})...")
    success = helper.insert_full_program(
        program_name="Martial Arts Foundation",
        category_name="Sports",
        description="Build the physical foundation for martial arts training. Covers kick power, striking power, flexibility for high kicks, grip strength for grappling, and fight-round conditioning.",
        durations=[4, 8], sessions_per_week=[4, 5],
        has_supersets=True, priority="High",
        weeks_data=build_martial_arts_foundation(), migration_num=mig, write_sql=True)
    if success:
        print("   Martial Arts Foundation inserted!")
        helper.update_tracker("Martial Arts Foundation", "Done")

    helper.close()
    print("\nAll sports programs complete!")


if __name__ == "__main__":
    main()
