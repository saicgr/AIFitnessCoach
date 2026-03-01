#!/usr/bin/env python3
"""
Category 7: Celebrity-Style Programs (High Priority)
=====================================================
- Action Hero Build (4,8,12,16w x 5-6/wk) - Hemsworth-inspired functional mass
- Superhero Physique (4,8,12w x 5-6/wk) - V-taper aesthetic, superset-heavy
- Red Carpet Ready (2,4,6,8w x 5-6/wk) - Lean & defined, boxing + bodybuilding
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from program_sql_helper import ProgramSQLHelper


def make_exercise(name, sets, reps, rest, weight_guidance, equipment, body_part,
                  primary_muscle, secondary_muscles, difficulty, form_cue, substitution):
    return {
        "name": name,
        "exercise_library_id": None,
        "in_library": False,
        "sets": sets,
        "reps": reps,
        "rest_seconds": rest,
        "weight_guidance": weight_guidance,
        "equipment": equipment,
        "body_part": body_part,
        "primary_muscle": primary_muscle,
        "secondary_muscles": secondary_muscles,
        "difficulty": difficulty,
        "form_cue": form_cue,
        "substitution": substitution,
    }


# =============================================================================
# ACTION HERO BUILD - Hemsworth-inspired: compound lifts + functional circuits
# Splits: Chest/Back, Legs/Core, Shoulders/Arms, Full-Body Circuit, Legs/Back
# =============================================================================

def action_hero_build_weeks(duration, sessions):
    """Generate Action Hero Build weeks with progressive overload."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        # Progressive overload: increase sets/weight cues over time
        if progress <= 0.25:
            phase = "Foundation"
            base_sets = 3
            rep_range_heavy = "8-10"
            rep_range_moderate = "10-12"
            weight_cue = "Moderate - focus on form"
        elif progress <= 0.5:
            phase = "Build"
            base_sets = 4
            rep_range_heavy = "6-8"
            rep_range_moderate = "8-10"
            weight_cue = "Moderate-Heavy"
        elif progress <= 0.75:
            phase = "Peak"
            base_sets = 4
            rep_range_heavy = "5-6"
            rep_range_moderate = "8-10"
            weight_cue = "Heavy"
        else:
            phase = "Intensification"
            base_sets = 4
            rep_range_heavy = "4-6"
            rep_range_moderate = "6-8"
            weight_cue = "Heavy - push limits"

        workouts = []

        # Day 1: Chest & Back (Push/Pull superset style)
        workouts.append({
            "workout_name": f"Day 1 - Chest & Back",
            "type": "hypertrophy",
            "duration_minutes": 60,
            "exercises": [
                make_exercise("Barbell Bench Press", base_sets, rep_range_heavy, 120,
                              weight_cue, "Barbell", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "Retract scapula, drive feet into floor", "Dumbbell Bench Press"),
                make_exercise("Weighted Pull-Up", base_sets, rep_range_heavy, 120,
                              weight_cue, "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Rear Deltoid"], "intermediate",
                              "Full dead hang to chin over bar", "Lat Pulldown"),
                make_exercise("Incline Dumbbell Press", base_sets, rep_range_moderate, 90,
                              "Moderate-Heavy", "Dumbbells", "Chest", "Upper Pectoralis",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "30-degree incline, squeeze at top", "Incline Barbell Press"),
                make_exercise("Barbell Row", base_sets, rep_range_moderate, 90,
                              weight_cue, "Barbell", "Back", "Latissimus Dorsi",
                              ["Rhomboids", "Biceps"], "intermediate",
                              "Hinge at hips, pull to lower chest", "Seated Cable Row"),
                make_exercise("Cable Flye", 3, "12-15", 60,
                              "Moderate", "Cable Machine", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid"], "beginner",
                              "Slight bend in elbows, squeeze at center", "Dumbbell Flye"),
                make_exercise("Face Pull", 3, "15-20", 60,
                              "Light-Moderate", "Cable Machine", "Back", "Rear Deltoid",
                              ["Rhomboids", "External Rotators"], "beginner",
                              "Pull to forehead, rotate externally", "Band Pull-Apart"),
            ]
        })

        # Day 2: Legs & Core (Quad-dominant)
        workouts.append({
            "workout_name": f"Day 2 - Legs & Core",
            "type": "strength",
            "duration_minutes": 60,
            "exercises": [
                make_exercise("Barbell Back Squat", base_sets, rep_range_heavy, 150,
                              weight_cue, "Barbell", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Break at hips and knees simultaneously, chest up", "Leg Press"),
                make_exercise("Romanian Deadlift", base_sets, rep_range_moderate, 120,
                              weight_cue, "Barbell", "Legs", "Hamstrings",
                              ["Glutes", "Erector Spinae"], "intermediate",
                              "Soft knee bend, hinge until hamstring stretch", "Dumbbell RDL"),
                make_exercise("Walking Lunge", 3, "12 each leg", 90,
                              "Moderate", "Dumbbells", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Long stride, knee tracks over toe", "Reverse Lunge"),
                make_exercise("Leg Curl", 3, "10-12", 60,
                              "Moderate", "Machine", "Legs", "Hamstrings",
                              ["Calves"], "beginner",
                              "Control the eccentric, squeeze at top", "Nordic Curl"),
                make_exercise("Hanging Leg Raise", 3, "12-15", 60,
                              "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis",
                              ["Hip Flexors", "Obliques"], "intermediate",
                              "No swinging, controlled movement", "Captain's Chair Leg Raise"),
                make_exercise("Ab Wheel Rollout", 3, "10-12", 60,
                              "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis",
                              ["Obliques", "Erector Spinae"], "intermediate",
                              "Brace core, extend as far as possible", "Plank"),
            ]
        })

        # Day 3: Shoulders & Arms
        workouts.append({
            "workout_name": f"Day 3 - Shoulders & Arms",
            "type": "hypertrophy",
            "duration_minutes": 55,
            "exercises": [
                make_exercise("Seated Dumbbell Shoulder Press", base_sets, rep_range_moderate, 90,
                              weight_cue, "Dumbbells", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps"], "intermediate",
                              "Press straight up, don't flare elbows", "Barbell Overhead Press"),
                make_exercise("Lateral Raise", base_sets, "12-15", 60,
                              "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid",
                              ["Anterior Deltoid"], "beginner",
                              "Slight bend in elbows, raise to shoulder height", "Cable Lateral Raise"),
                make_exercise("Barbell Curl", base_sets, rep_range_moderate, 60,
                              "Moderate", "Barbell", "Arms", "Biceps",
                              ["Brachialis", "Forearms"], "beginner",
                              "Keep elbows pinned, no swinging", "Dumbbell Curl"),
                make_exercise("Skull Crusher", base_sets, rep_range_moderate, 60,
                              "Moderate", "EZ Bar", "Arms", "Triceps",
                              ["Anconeus"], "intermediate",
                              "Lower to forehead, elbows stationary", "Cable Pushdown"),
                make_exercise("Hammer Curl", 3, "10-12", 60,
                              "Moderate", "Dumbbells", "Arms", "Brachialis",
                              ["Biceps", "Forearms"], "beginner",
                              "Neutral grip, controlled tempo", "Cable Hammer Curl"),
                make_exercise("Overhead Tricep Extension", 3, "12-15", 60,
                              "Moderate", "Dumbbell", "Arms", "Triceps",
                              ["Anconeus"], "beginner",
                              "Keep elbows close to head", "Cable Overhead Extension"),
            ]
        })

        # Day 4: Functional Circuit (Hemsworth signature)
        workouts.append({
            "workout_name": f"Day 4 - Functional Circuit",
            "type": "circuit",
            "duration_minutes": 45,
            "exercises": [
                make_exercise("Kettlebell Swing", 4, "15-20", 45,
                              "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes",
                              ["Hamstrings", "Core", "Shoulders"], "intermediate",
                              "Hip hinge explosively, squeeze glutes at top", "Dumbbell Swing"),
                make_exercise("Battle Rope Slam", 4, "30 seconds", 30,
                              "N/A", "Battle Ropes", "Full Body", "Shoulders",
                              ["Core", "Arms", "Back"], "intermediate",
                              "Full body wave, slam with power", "Medicine Ball Slam"),
                make_exercise("Box Jump", 4, "8-10", 60,
                              "Bodyweight", "Plyo Box", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "intermediate",
                              "Soft landing, step down", "Squat Jump"),
                make_exercise("Medicine Ball Slam", 4, "12-15", 45,
                              "Moderate", "Medicine Ball", "Full Body", "Core",
                              ["Shoulders", "Lats"], "beginner",
                              "Reach overhead fully, slam with force", "Slam Ball"),
                make_exercise("Renegade Row", 3, "8 each side", 60,
                              "Moderate", "Dumbbells", "Full Body", "Latissimus Dorsi",
                              ["Core", "Chest", "Shoulders"], "intermediate",
                              "Minimize hip rotation, brace core", "Single-Arm Dumbbell Row"),
                make_exercise("Burpee", 3, "10-12", 60,
                              "Bodyweight", "None", "Full Body", "Quadriceps",
                              ["Chest", "Shoulders", "Core"], "intermediate",
                              "Chest to floor, explosive jump", "Squat Thrust"),
            ]
        })

        # Day 5: Back & Hamstrings (if 5+ sessions)
        if sessions >= 5:
            workouts.append({
                "workout_name": f"Day 5 - Back & Hamstrings",
                "type": "strength",
                "duration_minutes": 60,
                "exercises": [
                    make_exercise("Deadlift", base_sets, rep_range_heavy, 180,
                                  weight_cue, "Barbell", "Back", "Erector Spinae",
                                  ["Glutes", "Hamstrings", "Traps"], "intermediate",
                                  "Flat back, push floor away", "Trap Bar Deadlift"),
                    make_exercise("Weighted Chin-Up", base_sets, rep_range_heavy, 120,
                                  weight_cue, "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Forearms"], "intermediate",
                                  "Supinated grip, full range of motion", "Lat Pulldown Underhand"),
                    make_exercise("Single-Arm Dumbbell Row", base_sets, rep_range_moderate, 90,
                                  "Moderate-Heavy", "Dumbbell", "Back", "Latissimus Dorsi",
                                  ["Rhomboids", "Biceps"], "intermediate",
                                  "Pull to hip, squeeze shoulder blade", "Cable Row"),
                    make_exercise("Good Morning", 3, "10-12", 90,
                                  "Moderate", "Barbell", "Legs", "Hamstrings",
                                  ["Glutes", "Erector Spinae"], "intermediate",
                                  "Slight knee bend, hinge at hips", "Seated Good Morning"),
                    make_exercise("Glute Ham Raise", 3, "8-10", 90,
                                  "Bodyweight", "GHD", "Legs", "Hamstrings",
                                  ["Glutes", "Calves"], "intermediate",
                                  "Control descent, drive with hamstrings", "Nordic Curl"),
                    make_exercise("Farmer's Carry", 3, "40 meters", 60,
                                  "Heavy", "Dumbbells", "Full Body", "Forearms",
                                  ["Traps", "Core", "Shoulders"], "beginner",
                                  "Chest up, shoulders back, tight core", "Trap Bar Carry"),
                ]
            })

        # Day 6: Arms & Conditioning (if 6 sessions)
        if sessions >= 6:
            workouts.append({
                "workout_name": f"Day 6 - Arms & Conditioning",
                "type": "hypertrophy",
                "duration_minutes": 50,
                "exercises": [
                    make_exercise("Close-Grip Bench Press", base_sets, rep_range_moderate, 90,
                                  weight_cue, "Barbell", "Arms", "Triceps",
                                  ["Chest", "Anterior Deltoid"], "intermediate",
                                  "Hands shoulder-width, elbows tucked", "Dip"),
                    make_exercise("Incline Dumbbell Curl", base_sets, "10-12", 60,
                                  "Moderate", "Dumbbells", "Arms", "Biceps",
                                  ["Brachialis"], "beginner",
                                  "Let arms hang, full stretch at bottom", "Preacher Curl"),
                    make_exercise("Tricep Dip", 3, "10-15", 60,
                                  "Bodyweight", "Dip Station", "Arms", "Triceps",
                                  ["Chest", "Anterior Deltoid"], "intermediate",
                                  "Lean slightly forward, elbows back", "Bench Dip"),
                    make_exercise("Concentration Curl", 3, "10-12 each arm", 45,
                                  "Moderate", "Dumbbell", "Arms", "Biceps",
                                  ["Brachialis"], "beginner",
                                  "Elbow braced on inner thigh, squeeze peak", "Cable Curl"),
                    make_exercise("Sled Push", 3, "30 meters", 90,
                                  "Heavy", "Sled", "Full Body", "Quadriceps",
                                  ["Glutes", "Calves", "Core"], "intermediate",
                                  "Low hand position, drive through legs", "Prowler Push"),
                    make_exercise("Assault Bike Sprint", 3, "30 seconds", 60,
                                  "Max Effort", "Assault Bike", "Full Body", "Quadriceps",
                                  ["Hamstrings", "Core", "Arms"], "intermediate",
                                  "All-out effort, push and pull arms", "Rowing Machine Sprint"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Compound focus' if progress <= 0.5 else 'Intensity & volume'}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# SUPERHERO PHYSIQUE - V-taper aesthetic, superset-heavy (Efron-inspired)
# Focus: Wide back, capped shoulders, lean waist, defined arms
# =============================================================================

def superhero_physique_weeks(duration, sessions):
    """Generate Superhero Physique weeks - V-taper with supersets."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Foundation"
            base_sets = 3
            rep_range = "10-12"
            weight_cue = "Moderate"
        elif progress <= 0.5:
            phase = "Hypertrophy"
            base_sets = 4
            rep_range = "8-12"
            weight_cue = "Moderate-Heavy"
        elif progress <= 0.75:
            phase = "Definition"
            base_sets = 4
            rep_range = "10-15"
            weight_cue = "Moderate - high tempo"
        else:
            phase = "Shred"
            base_sets = 4
            rep_range = "12-15"
            weight_cue = "Moderate - minimal rest"

        workouts = []

        # Day 1: Back & Biceps (V-taper focus)
        workouts.append({
            "workout_name": "Day 1 - Back & Biceps",
            "type": "hypertrophy",
            "duration_minutes": 60,
            "exercises": [
                make_exercise("Wide-Grip Pull-Up", base_sets, "8-12", 90,
                              weight_cue, "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Teres Major", "Biceps"], "intermediate",
                              "Wide grip, pull chest to bar", "Wide-Grip Lat Pulldown"),
                make_exercise("Barbell Row", base_sets, rep_range, 90,
                              weight_cue, "Barbell", "Back", "Latissimus Dorsi",
                              ["Rhomboids", "Biceps", "Rear Deltoid"], "intermediate",
                              "45-degree torso angle, pull to lower chest", "T-Bar Row"),
                make_exercise("Seated Cable Row (Wide Grip)", base_sets, rep_range, 75,
                              "Moderate-Heavy", "Cable Machine", "Back", "Rhomboids",
                              ["Latissimus Dorsi", "Rear Deltoid"], "beginner",
                              "Squeeze shoulder blades together", "Machine Row"),
                make_exercise("Straight-Arm Pulldown", 3, "12-15", 60,
                              "Moderate", "Cable Machine", "Back", "Latissimus Dorsi",
                              ["Teres Major", "Posterior Deltoid"], "beginner",
                              "Slight lean forward, arms straight throughout", "Dumbbell Pullover"),
                make_exercise("Barbell Curl", base_sets, "10-12", 60,
                              "Moderate", "Barbell", "Arms", "Biceps",
                              ["Brachialis", "Forearms"], "beginner",
                              "Elbows pinned to sides, no swing", "EZ Bar Curl"),
                make_exercise("Incline Dumbbell Curl", 3, "10-12", 60,
                              "Moderate", "Dumbbells", "Arms", "Biceps (Long Head)",
                              ["Brachialis"], "beginner",
                              "Arms hang behind torso for full stretch", "Cable Curl"),
                make_exercise("Reverse Curl", 3, "12-15", 45,
                              "Light-Moderate", "EZ Bar", "Arms", "Brachioradialis",
                              ["Biceps", "Forearms"], "beginner",
                              "Overhand grip, control the negative", "Hammer Curl"),
            ]
        })

        # Day 2: Chest, Shoulders & Triceps
        workouts.append({
            "workout_name": "Day 2 - Chest, Shoulders & Triceps",
            "type": "hypertrophy",
            "duration_minutes": 60,
            "exercises": [
                make_exercise("Incline Barbell Bench Press", base_sets, rep_range, 90,
                              weight_cue, "Barbell", "Chest", "Upper Pectoralis",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "30-degree incline, control descent", "Incline Dumbbell Press"),
                make_exercise("Flat Dumbbell Press", base_sets, rep_range, 90,
                              weight_cue, "Dumbbells", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "Full range, squeeze at top", "Barbell Bench Press"),
                make_exercise("Cable Crossover", 3, "12-15", 60,
                              "Moderate", "Cable Machine", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid"], "beginner",
                              "Hands meet below chest, squeeze", "Dumbbell Flye"),
                make_exercise("Dumbbell Lateral Raise", base_sets, "12-15", 60,
                              "Light-Moderate", "Dumbbells", "Shoulders", "Lateral Deltoid",
                              ["Anterior Deltoid", "Traps"], "beginner",
                              "Slight bend in elbows, control the movement", "Cable Lateral Raise"),
                make_exercise("Rear Delt Flye", 3, "15-20", 60,
                              "Light", "Dumbbells", "Shoulders", "Rear Deltoid",
                              ["Rhomboids", "Traps"], "beginner",
                              "Bent over, squeeze shoulder blades", "Reverse Pec Deck"),
                make_exercise("Rope Tricep Pushdown", base_sets, "12-15", 60,
                              "Moderate", "Cable Machine", "Arms", "Triceps",
                              ["Anconeus"], "beginner",
                              "Spread the rope at the bottom", "Straight Bar Pushdown"),
                make_exercise("Overhead Dumbbell Tricep Extension", 3, "10-12", 60,
                              "Moderate", "Dumbbell", "Arms", "Triceps (Long Head)",
                              ["Anconeus"], "beginner",
                              "Keep elbows close to ears", "Cable Overhead Extension"),
            ]
        })

        # Day 3: Legs
        workouts.append({
            "workout_name": "Day 3 - Legs",
            "type": "hypertrophy",
            "duration_minutes": 60,
            "exercises": [
                make_exercise("Barbell Back Squat", base_sets, rep_range, 120,
                              weight_cue, "Barbell", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Depth to parallel, chest up", "Leg Press"),
                make_exercise("Leg Press", base_sets, "10-12", 90,
                              "Heavy", "Machine", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Full range, don't lock knees", "Hack Squat"),
                make_exercise("Romanian Deadlift", base_sets, rep_range, 90,
                              weight_cue, "Barbell", "Legs", "Hamstrings",
                              ["Glutes", "Erector Spinae"], "intermediate",
                              "Hip hinge, bar close to legs", "Dumbbell RDL"),
                make_exercise("Leg Extension", 3, "12-15", 60,
                              "Moderate", "Machine", "Legs", "Quadriceps",
                              [], "beginner",
                              "Pause at top, control descent", "Sissy Squat"),
                make_exercise("Lying Leg Curl", 3, "10-12", 60,
                              "Moderate", "Machine", "Legs", "Hamstrings",
                              ["Calves"], "beginner",
                              "Squeeze at top, slow negative", "Seated Leg Curl"),
                make_exercise("Standing Calf Raise", 4, "15-20", 45,
                              "Heavy", "Machine", "Legs", "Calves",
                              ["Soleus"], "beginner",
                              "Full stretch at bottom, squeeze at top", "Seated Calf Raise"),
                make_exercise("Hanging Leg Raise", 3, "12-15", 60,
                              "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis",
                              ["Hip Flexors", "Obliques"], "intermediate",
                              "Straight legs, no swinging", "Lying Leg Raise"),
            ]
        })

        # Day 4: Shoulders & Arms (superset focus)
        workouts.append({
            "workout_name": "Day 4 - Shoulders & Arms (Supersets)",
            "type": "hypertrophy",
            "duration_minutes": 55,
            "exercises": [
                make_exercise("Standing Barbell Overhead Press", base_sets, rep_range, 90,
                              weight_cue, "Barbell", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps", "Core"], "intermediate",
                              "Brace core, press straight overhead", "Dumbbell Shoulder Press"),
                make_exercise("Arnold Press", 3, "10-12", 75,
                              "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps"], "intermediate",
                              "Rotate palms from facing you to forward", "Dumbbell Shoulder Press"),
                make_exercise("Cable Lateral Raise", 3, "12-15", 60,
                              "Light-Moderate", "Cable Machine", "Shoulders", "Lateral Deltoid",
                              ["Anterior Deltoid"], "beginner",
                              "Constant tension, pause at top", "Dumbbell Lateral Raise"),
                make_exercise("Dumbbell Curl", base_sets, "10-12", 60,
                              "Moderate", "Dumbbells", "Arms", "Biceps",
                              ["Brachialis"], "beginner",
                              "Alternate arms, control the negative", "Cable Curl"),
                make_exercise("Tricep Dip", base_sets, "10-15", 60,
                              "Bodyweight", "Dip Station", "Arms", "Triceps",
                              ["Chest", "Anterior Deltoid"], "intermediate",
                              "Upright torso for tricep focus", "Close-Grip Push-Up"),
                make_exercise("Preacher Curl", 3, "10-12", 60,
                              "Moderate", "EZ Bar", "Arms", "Biceps (Short Head)",
                              ["Brachialis"], "beginner",
                              "Full stretch at bottom, don't hyperextend", "Machine Preacher Curl"),
            ]
        })

        # Day 5: Full Body / HIIT
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Full Body HIIT",
                "type": "circuit",
                "duration_minutes": 45,
                "exercises": [
                    make_exercise("Dumbbell Thruster", 4, "12-15", 45,
                                  "Moderate", "Dumbbells", "Full Body", "Quadriceps",
                                  ["Shoulders", "Triceps", "Core"], "intermediate",
                                  "Squat deep, press overhead explosively", "Barbell Thruster"),
                    make_exercise("Pull-Up", 4, "8-10", 45,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Core"], "intermediate",
                                  "Full dead hang to chin over bar", "Band-Assisted Pull-Up"),
                    make_exercise("Dumbbell Step-Up", 3, "10 each leg", 45,
                                  "Moderate", "Dumbbells", "Legs", "Quadriceps",
                                  ["Glutes", "Hamstrings"], "beginner",
                                  "Drive through heel, full extension at top", "Box Step-Up"),
                    make_exercise("Push-Up to Renegade Row", 3, "8 each side", 60,
                                  "Moderate", "Dumbbells", "Full Body", "Chest",
                                  ["Latissimus Dorsi", "Core", "Triceps"], "intermediate",
                                  "Minimize hip rotation, tight core", "Push-Up + Dumbbell Row"),
                    make_exercise("Kettlebell Goblet Squat", 3, "15", 45,
                                  "Moderate", "Kettlebell", "Legs", "Quadriceps",
                                  ["Glutes", "Core"], "beginner",
                                  "Elbows inside knees, upright torso", "Dumbbell Goblet Squat"),
                    make_exercise("Mountain Climber", 3, "20 each side", 45,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Hip Flexors", "Shoulders"], "beginner",
                                  "Plank position, fast knee drives", "Plank Knee Tuck"),
                ]
            })

        # Day 6: Active Recovery / Accessory
        if sessions >= 6:
            workouts.append({
                "workout_name": "Day 6 - Accessories & Abs",
                "type": "hypertrophy",
                "duration_minutes": 45,
                "exercises": [
                    make_exercise("Face Pull", 4, "15-20", 45,
                                  "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid",
                                  ["Rhomboids", "External Rotators"], "beginner",
                                  "Pull to forehead, squeeze back", "Band Pull-Apart"),
                    make_exercise("Incline Dumbbell Curl", 3, "10-12", 60,
                                  "Moderate", "Dumbbells", "Arms", "Biceps",
                                  ["Brachialis"], "beginner",
                                  "Full stretch at bottom", "Spider Curl"),
                    make_exercise("Cable Kickback", 3, "12-15 each arm", 45,
                                  "Moderate", "Cable Machine", "Arms", "Triceps",
                                  ["Anconeus"], "beginner",
                                  "Full extension, squeeze at top", "Dumbbell Kickback"),
                    make_exercise("Lateral Raise 21s", 3, "21 (7+7+7)", 60,
                                  "Light", "Dumbbells", "Shoulders", "Lateral Deltoid",
                                  ["Anterior Deltoid"], "intermediate",
                                  "Bottom half, top half, full range - 7 each", "Cable Lateral Raise"),
                    make_exercise("Cable Crunch", 3, "15-20", 45,
                                  "Moderate", "Cable Machine", "Core", "Rectus Abdominis",
                                  ["Obliques"], "beginner",
                                  "Crunch down, exhale at bottom", "Weighted Sit-Up"),
                    make_exercise("Plank", 3, "45-60 seconds", 45,
                                  "Bodyweight", "None", "Core", "Transverse Abdominis",
                                  ["Rectus Abdominis", "Obliques"], "beginner",
                                  "Flat back, squeeze glutes and core", "Dead Bug"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Establish base' if progress <= 0.25 else 'Progressive overload' if progress <= 0.5 else 'High-volume supersets' if progress <= 0.75 else 'Peak definition'}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# RED CARPET READY - Fast lean-out (MBJ-inspired: boxing + bodybuilding)
# =============================================================================

def red_carpet_ready_weeks(duration, sessions):
    """Generate Red Carpet Ready weeks - lean & defined, boxing + bodybuilding."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.3:
            phase = "Metabolic Base"
            base_sets = 3
            rep_range = "12-15"
            weight_cue = "Moderate - fast tempo"
        elif progress <= 0.6:
            phase = "Lean Muscle"
            base_sets = 4
            rep_range = "10-12"
            weight_cue = "Moderate-Heavy"
        elif progress <= 0.85:
            phase = "Shred"
            base_sets = 4
            rep_range = "12-15"
            weight_cue = "Moderate - high intensity"
        else:
            phase = "Peak Week"
            base_sets = 3
            rep_range = "15-20"
            weight_cue = "Moderate - pump focus"

        workouts = []

        # Day 1: Chest & Shoulders (Pyramid sets like Calliet)
        workouts.append({
            "workout_name": "Day 1 - Chest & Shoulders",
            "type": "hypertrophy",
            "duration_minutes": 55,
            "exercises": [
                make_exercise("Incline Dumbbell Press", base_sets, "15-12-10-8" if base_sets == 4 else "12-10-8", 75,
                              weight_cue, "Dumbbells", "Chest", "Upper Pectoralis",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "Increase weight each set, 30-degree incline", "Incline Barbell Press"),
                make_exercise("Cable Flye", base_sets, rep_range, 60,
                              "Moderate", "Cable Machine", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid"], "beginner",
                              "Constant tension, squeeze center", "Dumbbell Flye"),
                make_exercise("Push-Up", 3, "15-20", 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid"], "beginner",
                              "Full range, chest to floor", "Knee Push-Up"),
                make_exercise("Seated Dumbbell Shoulder Press", base_sets, rep_range, 75,
                              weight_cue, "Dumbbells", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps"], "intermediate",
                              "Press to full lockout", "Machine Shoulder Press"),
                make_exercise("Front Raise to Lateral Raise Combo", 3, "10 each direction", 60,
                              "Light", "Dumbbells", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid"], "beginner",
                              "Alternate front and lateral, no momentum", "Cable Front Raise"),
                make_exercise("Rope Face Pull", 3, "15-20", 45,
                              "Light-Moderate", "Cable Machine", "Shoulders", "Rear Deltoid",
                              ["Rhomboids", "External Rotators"], "beginner",
                              "High cable, pull to forehead", "Band Pull-Apart"),
            ]
        })

        # Day 2: Back & Arms
        workouts.append({
            "workout_name": "Day 2 - Back & Arms",
            "type": "hypertrophy",
            "duration_minutes": 55,
            "exercises": [
                make_exercise("Lat Pulldown", base_sets, rep_range, 75,
                              weight_cue, "Cable Machine", "Back", "Latissimus Dorsi",
                              ["Biceps", "Rear Deltoid"], "beginner",
                              "Pull to upper chest, lean slightly back", "Pull-Up"),
                make_exercise("Seated Cable Row", base_sets, rep_range, 75,
                              weight_cue, "Cable Machine", "Back", "Rhomboids",
                              ["Latissimus Dorsi", "Biceps"], "beginner",
                              "Squeeze shoulder blades, chest to handle", "Dumbbell Row"),
                make_exercise("Single-Arm Dumbbell Row", 3, "10-12 each arm", 60,
                              "Moderate-Heavy", "Dumbbell", "Back", "Latissimus Dorsi",
                              ["Rhomboids", "Biceps"], "intermediate",
                              "Pull to hip, full stretch at bottom", "Machine Row"),
                make_exercise("EZ Bar Curl", base_sets, rep_range, 60,
                              "Moderate", "EZ Bar", "Arms", "Biceps",
                              ["Brachialis", "Forearms"], "beginner",
                              "Elbows stationary, controlled tempo", "Dumbbell Curl"),
                make_exercise("Rope Pushdown", base_sets, rep_range, 60,
                              "Moderate", "Cable Machine", "Arms", "Triceps",
                              ["Anconeus"], "beginner",
                              "Spread rope at bottom, full squeeze", "Straight Bar Pushdown"),
                make_exercise("Hammer Curl", 3, "10-12", 45,
                              "Moderate", "Dumbbells", "Arms", "Brachialis",
                              ["Biceps", "Forearms"], "beginner",
                              "Neutral grip, no swinging", "Cable Hammer Curl"),
            ]
        })

        # Day 3: Legs
        workouts.append({
            "workout_name": "Day 3 - Legs",
            "type": "hypertrophy",
            "duration_minutes": 55,
            "exercises": [
                make_exercise("Barbell Front Squat", base_sets, rep_range, 120,
                              weight_cue, "Barbell", "Legs", "Quadriceps",
                              ["Glutes", "Core"], "intermediate",
                              "Elbows high, upright torso", "Goblet Squat"),
                make_exercise("Dumbbell Walking Lunge", 3, "12 each leg", 75,
                              "Moderate", "Dumbbells", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Long stride, back knee near floor", "Reverse Lunge"),
                make_exercise("Leg Press", base_sets, "12-15", 90,
                              "Heavy", "Machine", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Wide stance, full depth", "Hack Squat"),
                make_exercise("Romanian Deadlift", base_sets, rep_range, 90,
                              weight_cue, "Dumbbells", "Legs", "Hamstrings",
                              ["Glutes", "Erector Spinae"], "intermediate",
                              "Dumbbells close to legs, hinge at hips", "Barbell RDL"),
                make_exercise("Calf Raise", 4, "15-20", 45,
                              "Heavy", "Machine", "Legs", "Calves",
                              ["Soleus"], "beginner",
                              "Full range of motion, pause at top", "Seated Calf Raise"),
                make_exercise("Leg Curl", 3, "12-15", 60,
                              "Moderate", "Machine", "Legs", "Hamstrings",
                              ["Calves"], "beginner",
                              "Control the negative", "Nordic Curl"),
            ]
        })

        # Day 4: Boxing Cardio & Core (MBJ signature)
        workouts.append({
            "workout_name": "Day 4 - Boxing & Core Circuit",
            "type": "circuit",
            "duration_minutes": 45,
            "exercises": [
                make_exercise("Shadow Boxing", 4, "3 min rounds", 30,
                              "Bodyweight", "None", "Full Body", "Shoulders",
                              ["Core", "Arms", "Calves"], "beginner",
                              "Stay light on feet, full combos", "Jump Rope"),
                make_exercise("Heavy Bag Work", 4, "3 min rounds", 30,
                              "N/A", "Heavy Bag", "Full Body", "Shoulders",
                              ["Core", "Arms", "Chest"], "intermediate",
                              "Mix jab-cross-hook-uppercut combos", "Medicine Ball Slam"),
                make_exercise("Medicine Ball Russian Twist", 3, "20 total", 45,
                              "Moderate", "Medicine Ball", "Core", "Obliques",
                              ["Rectus Abdominis"], "beginner",
                              "Feet off ground, rotate fully each side", "Cable Woodchop"),
                make_exercise("Bicycle Crunch", 3, "20 each side", 45,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Rectus Abdominis", "Hip Flexors"], "beginner",
                              "Slow and controlled, elbow to opposite knee", "Cross-Body Crunch"),
                make_exercise("Plank to Push-Up", 3, "10-12", 45,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Triceps", "Shoulders", "Chest"], "intermediate",
                              "Alternate lead arm each rep", "Plank"),
                make_exercise("Burpee", 3, "10", 60,
                              "Bodyweight", "None", "Full Body", "Quadriceps",
                              ["Chest", "Shoulders", "Core"], "intermediate",
                              "Chest to floor, explosive jump", "Squat Thrust"),
            ]
        })

        # Day 5: Upper Body Pump
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Upper Body Pump",
                "type": "hypertrophy",
                "duration_minutes": 50,
                "exercises": [
                    make_exercise("Dumbbell Bench Press", base_sets, rep_range, 75,
                                  weight_cue, "Dumbbells", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid"], "intermediate",
                                  "Full stretch at bottom, squeeze at top", "Barbell Bench Press"),
                    make_exercise("Pull-Up", base_sets, "8-12", 75,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Core"], "intermediate",
                                  "Full dead hang, chin over bar", "Lat Pulldown"),
                    make_exercise("Arnold Press", 3, "10-12", 60,
                                  "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid",
                                  ["Lateral Deltoid", "Triceps"], "intermediate",
                                  "Rotate palms during press", "Dumbbell Shoulder Press"),
                    make_exercise("Cable Curl (Drop Set)", 3, "10-8-6 drop", 60,
                                  "Moderate to Heavy", "Cable Machine", "Arms", "Biceps",
                                  ["Brachialis"], "intermediate",
                                  "Drop weight twice per set, no rest", "Dumbbell Curl"),
                    make_exercise("Dip", 3, "10-15", 60,
                                  "Bodyweight", "Dip Station", "Arms", "Triceps",
                                  ["Chest", "Anterior Deltoid"], "intermediate",
                                  "Upright for triceps, lean for chest", "Close-Grip Push-Up"),
                    make_exercise("Lateral Raise", 3, "15-20", 45,
                                  "Light", "Dumbbells", "Shoulders", "Lateral Deltoid",
                                  ["Anterior Deltoid"], "beginner",
                                  "Controlled tempo, no momentum", "Cable Lateral Raise"),
                ]
            })

        # Day 6: HIIT Finisher
        if sessions >= 6:
            workouts.append({
                "workout_name": "Day 6 - HIIT Conditioning",
                "type": "circuit",
                "duration_minutes": 40,
                "exercises": [
                    make_exercise("Kettlebell Swing", 4, "20", 30,
                                  "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes",
                                  ["Hamstrings", "Core", "Shoulders"], "intermediate",
                                  "Explosive hip snap, arms are hooks", "Dumbbell Swing"),
                    make_exercise("Box Jump", 4, "10", 30,
                                  "Bodyweight", "Plyo Box", "Legs", "Quadriceps",
                                  ["Glutes", "Calves"], "intermediate",
                                  "Soft landing, reset each rep", "Squat Jump"),
                    make_exercise("Battle Rope Waves", 3, "30 seconds", 30,
                                  "N/A", "Battle Ropes", "Full Body", "Shoulders",
                                  ["Core", "Arms"], "intermediate",
                                  "Alternating waves, full amplitude", "Medicine Ball Slam"),
                    make_exercise("Goblet Squat to Press", 3, "12", 45,
                                  "Moderate", "Kettlebell", "Full Body", "Quadriceps",
                                  ["Shoulders", "Core", "Glutes"], "intermediate",
                                  "Squat deep, press overhead at top", "Dumbbell Thruster"),
                    make_exercise("Sprawl", 3, "10", 45,
                                  "Bodyweight", "None", "Full Body", "Core",
                                  ["Quadriceps", "Shoulders", "Chest"], "intermediate",
                                  "Like a burpee but hips touch floor", "Burpee"),
                    make_exercise("Dead Bug", 3, "12 each side", 30,
                                  "Bodyweight", "None", "Core", "Transverse Abdominis",
                                  ["Rectus Abdominis", "Hip Flexors"], "beginner",
                                  "Low back pressed to floor throughout", "Plank"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Build metabolic base' if progress <= 0.3 else 'Lean muscle development' if progress <= 0.6 else 'Cut and define' if progress <= 0.85 else 'Peak and polish'}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# MAIN EXECUTION
# =============================================================================

def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()
    success_count = 0
    fail_count = 0

    programs = [
        # Action Hero Build
        {
            "name": "Action Hero Build",
            "category": "Celebrity-Style",
            "description": "Functional muscle mass program combining heavy compound lifts with explosive circuit training. Build a versatile, powerful physique with a mix of strength, hypertrophy, and conditioning work.",
            "durations": [4, 8, 12, 16],
            "sessions": [5, 6],
            "has_supersets": True,
            "priority": "High",
            "generator": action_hero_build_weeks,
        },
        # Superhero Physique
        {
            "name": "Superhero Physique",
            "category": "Celebrity-Style",
            "description": "V-taper aesthetic program focused on building wide lats, capped shoulders, and a lean midsection. High-volume superset training for maximum definition and proportion.",
            "durations": [4, 8, 12],
            "sessions": [5, 6],
            "has_supersets": True,
            "priority": "High",
            "generator": superhero_physique_weeks,
        },
        # Red Carpet Ready
        {
            "name": "Red Carpet Ready",
            "category": "Celebrity-Style",
            "description": "Rapid lean-out transformation combining bodybuilding with boxing-inspired cardio. Get camera-ready with high-intensity circuits, pyramid sets, and metabolic conditioning.",
            "durations": [2, 4, 6, 8],
            "sessions": [5, 6],
            "has_supersets": True,
            "priority": "High",
            "generator": red_carpet_ready_weeks,
        },
    ]

    for prog in programs:
        print(f"\n{'='*60}")
        print(f"Processing: {prog['name']}")
        print(f"{'='*60}")

        if helper.check_program_exists(prog["name"]):
            print(f"  SKIP: {prog['name']} already exists")
            continue

        weeks_data = {}
        for dur in prog["durations"]:
            for sess in prog["sessions"]:
                weeks_data[(dur, sess)] = prog["generator"](dur, sess)

        ok = helper.insert_full_program(
            program_name=prog["name"],
            category_name=prog["category"],
            description=prog["description"],
            durations=prog["durations"],
            sessions_per_week=prog["sessions"],
            has_supersets=prog["has_supersets"],
            priority=prog["priority"],
            weeks_data=weeks_data,
            migration_num=migration_num,
            write_sql=True,
        )

        if ok:
            helper.update_tracker(prog["name"], "Done")
            success_count += 1
        else:
            fail_count += 1
        migration_num += 1

    helper.close()
    print(f"\n{'='*60}")
    print(f"Celebrity-Style HIGH priority complete: {success_count} OK, {fail_count} FAIL")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
