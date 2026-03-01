#!/usr/bin/env python3
"""
Category 9: Progressions Programs (High Priority)
===================================================
- Pull-up Progression (1,2,4,8w x 3-4/wk) - Dead hang to strict pull-ups
- Box Jump Progression (1,2,4w x 3/wk) - Height + technique
- Push-up to Planche (4,8,12w x 4-5/wk) - Calisthenics path
- Freerunning Foundations (8,12w x 3-4/wk) - Creative movement + flips
- Tricking Basics (8,12,16w x 3-4/wk) - Kicks, twists, combos
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
# PULL-UP PROGRESSION - Dead hang to strict pull-ups
# =============================================================================

def pullup_progression_weeks(duration, sessions):
    """Generate Pull-up Progression: dead hang -> negatives -> band-assisted -> strict."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Hang & Scapular"
            neg_time = "3-5 seconds"
            band = "Heavy band"
        elif progress <= 0.5:
            phase = "Negatives & Assisted"
            neg_time = "5-8 seconds"
            band = "Medium band"
        elif progress <= 0.75:
            phase = "Partial to Full"
            neg_time = "8-10 seconds"
            band = "Light band"
        else:
            phase = "Strict Pull-Ups"
            neg_time = "N/A"
            band = "No band"

        workouts = []

        # Day 1: Pull-Up Specific
        day1_exercises = []
        if progress <= 0.25:
            day1_exercises = [
                make_exercise("Dead Hang", 4, "20-30 seconds", 60,
                              "Bodyweight", "Pull-Up Bar", "Back", "Forearms",
                              ["Lats", "Shoulders"], "beginner",
                              "Full hang, shoulders slightly engaged", "Flexed Arm Hang"),
                make_exercise("Scapular Pull-Up", 4, "8-10", 60,
                              "Bodyweight", "Pull-Up Bar", "Back", "Lower Traps",
                              ["Rhomboids", "Lats"], "beginner",
                              "Hang, retract and depress scapulae without bending elbows", "Band Scapular Pull"),
                make_exercise("Eccentric Pull-Up (Negative)", 4, "3-5", 90,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms"], "beginner",
                              f"Jump to top, lower slowly for {neg_time}", "Band-Assisted Negative"),
                make_exercise("Inverted Row (High Bar)", 4, "8-12", 60,
                              "Bodyweight", "Barbell/Smith Machine", "Back", "Rhomboids",
                              ["Lats", "Biceps", "Rear Deltoid"], "beginner",
                              "Body at 45-degree angle, pull chest to bar", "TRX Row"),
                make_exercise("Lat Pulldown", 3, "10-12", 60,
                              "Moderate", "Cable Machine", "Back", "Latissimus Dorsi",
                              ["Biceps", "Teres Major"], "beginner",
                              "Pull to upper chest, squeeze lats", "Band Pulldown"),
                make_exercise("Bicep Curl", 3, "10-12", 45,
                              "Moderate", "Dumbbells", "Arms", "Biceps",
                              ["Brachialis", "Forearms"], "beginner",
                              "Control the negative, elbows pinned", "Band Curl"),
            ]
        elif progress <= 0.5:
            day1_exercises = [
                make_exercise("Eccentric Pull-Up (Slow Negative)", 5, "3-5", 90,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms", "Core"], "beginner",
                              f"Lower as slowly as possible: {neg_time}", "Band-Assisted Pull-Up"),
                make_exercise("Band-Assisted Pull-Up", 4, "5-8", 90,
                              "Bodyweight + Band", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Teres Major"], "beginner",
                              f"{band}: foot in loop, full range of motion", "Lat Pulldown"),
                make_exercise("Inverted Row (Low Bar)", 4, "8-12", 60,
                              "Bodyweight", "Barbell/Smith Machine", "Back", "Rhomboids",
                              ["Lats", "Biceps", "Rear Deltoid"], "beginner",
                              "Body more horizontal for increased difficulty", "TRX Row"),
                make_exercise("Flexed Arm Hang", 3, "15-20 seconds", 60,
                              "Bodyweight", "Pull-Up Bar", "Back", "Biceps",
                              ["Lats", "Forearms"], "beginner",
                              "Hold chin above bar as long as possible", "Band-Assisted Hold"),
                make_exercise("Straight-Arm Pulldown", 3, "12-15", 60,
                              "Moderate", "Cable Machine", "Back", "Latissimus Dorsi",
                              ["Teres Major", "Triceps Long Head"], "beginner",
                              "Arms straight, squeeze lats at bottom", "Dumbbell Pullover"),
                make_exercise("Hammer Curl", 3, "10-12", 45,
                              "Moderate", "Dumbbells", "Arms", "Brachialis",
                              ["Biceps", "Forearms"], "beginner",
                              "Neutral grip, builds elbow flexor strength", "Cable Curl"),
            ]
        elif progress <= 0.75:
            day1_exercises = [
                make_exercise("Band-Assisted Pull-Up (Light Band)", 5, "5-8", 90,
                              "Bodyweight + Light Band", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Core", "Forearms"], "intermediate",
                              "Minimal assistance, focus on lat engagement", "Lat Pulldown"),
                make_exercise("Pull-Up (Partial Range)", 4, "3-5", 90,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Teres Major"], "intermediate",
                              "Start from halfway, pull chin over bar", "Band-Assisted Pull-Up"),
                make_exercise("Eccentric Pull-Up (10s)", 3, "3", 120,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms"], "intermediate",
                              "Ultra-slow 10 second descent", "5s Eccentric"),
                make_exercise("Inverted Row (Feet Elevated)", 4, "8-10", 60,
                              "Bodyweight", "Barbell/Smith Machine", "Back", "Rhomboids",
                              ["Lats", "Biceps", "Rear Deltoid"], "intermediate",
                              "Feet on bench, body horizontal, pull to chest", "Standard Inverted Row"),
                make_exercise("Face Pull", 3, "15-20", 45,
                              "Light-Moderate", "Cable Machine", "Back", "Rear Deltoid",
                              ["Rhomboids", "External Rotators"], "beginner",
                              "Pull to face, externally rotate at end", "Band Pull-Apart"),
                make_exercise("Chin-Up Attempt", 3, "1-3 or max effort", 120,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms"], "intermediate",
                              "Underhand grip, try for full reps", "Band-Assisted Chin-Up"),
            ]
        else:
            day1_exercises = [
                make_exercise("Strict Pull-Up", 5, "3-5", 120,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Core", "Forearms"], "intermediate",
                              "Full dead hang to chin over bar, no kipping", "Band-Assisted Pull-Up"),
                make_exercise("Chin-Up", 4, "4-6", 90,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms"], "intermediate",
                              "Supinated grip, full range of motion", "Band-Assisted Chin-Up"),
                make_exercise("Wide-Grip Pull-Up", 3, "3-5", 120,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Teres Major", "Biceps"], "intermediate",
                              "Hands wider than shoulders, pull chest to bar", "Wide-Grip Lat Pulldown"),
                make_exercise("Typewriter Pull-Up", 3, "2-3 each side", 120,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Core"], "advanced",
                              "Pull up, shift weight to one side, back to center", "Standard Pull-Up"),
                make_exercise("Weighted Dead Hang", 3, "20-30 seconds", 60,
                              "Light weight", "Pull-Up Bar", "Back", "Forearms",
                              ["Lats", "Shoulders"], "intermediate",
                              "Add a small dumbbell between feet or belt", "Dead Hang"),
                make_exercise("Barbell Curl", 3, "8-10", 60,
                              "Moderate", "Barbell", "Arms", "Biceps",
                              ["Brachialis", "Forearms"], "beginner",
                              "Complement pull-up training with direct bicep work", "Dumbbell Curl"),
            ]

        workouts.append({
            "workout_name": "Day 1 - Pull-Up Skill Work",
            "type": "strength",
            "duration_minutes": 40,
            "exercises": day1_exercises,
        })

        # Day 2: Back & Grip Accessory
        workouts.append({
            "workout_name": "Day 2 - Back & Grip Strength",
            "type": "strength",
            "duration_minutes": 35,
            "exercises": [
                make_exercise("Dumbbell Row", 4, "8-12 each arm", 60,
                              "Moderate-Heavy", "Dumbbell", "Back", "Latissimus Dorsi",
                              ["Rhomboids", "Biceps"], "beginner",
                              "Pull to hip, full stretch at bottom", "Cable Row"),
                make_exercise("Lat Pulldown (Close Grip)", 3, "10-12", 60,
                              "Moderate", "Cable Machine", "Back", "Latissimus Dorsi",
                              ["Biceps", "Teres Major"], "beginner",
                              "V-handle, pull to chest, lean back slightly", "Straight-Arm Pulldown"),
                make_exercise("Seated Cable Row", 3, "10-12", 60,
                              "Moderate", "Cable Machine", "Back", "Rhomboids",
                              ["Lats", "Biceps"], "beginner",
                              "Squeeze shoulder blades at contraction", "Dumbbell Row"),
                make_exercise("Farmer's Walk", 3, "30 meters", 60,
                              "Heavy", "Dumbbells", "Full Body", "Forearms",
                              ["Traps", "Core"], "beginner",
                              "Chest up, grip tight, controlled steps", "Dead Hang for Time"),
                make_exercise("Towel Hang", 3, "15-20 seconds", 60,
                              "Bodyweight", "Pull-Up Bar + Towel", "Arms", "Forearms",
                              ["Lats", "Biceps"], "intermediate",
                              "Drape towel over bar, grip towel ends", "Dead Hang"),
                make_exercise("Band Pull-Apart", 3, "15-20", 30,
                              "Light", "Resistance Band", "Back", "Rear Deltoid",
                              ["Rhomboids", "Traps"], "beginner",
                              "Arms straight, pull band to chest width", "Face Pull"),
            ]
        })

        # Day 3: Upper Body Support
        if sessions >= 3:
            workouts.append({
                "workout_name": "Day 3 - Upper Body Support",
                "type": "hypertrophy",
                "duration_minutes": 35,
                "exercises": [
                    make_exercise("Push-Up", 4, "10-15", 45,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid"], "beginner",
                                  "Balance pulling with pushing", "Knee Push-Up"),
                    make_exercise("Dumbbell Shoulder Press", 3, "8-10", 60,
                                  "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid",
                                  ["Lateral Deltoid", "Triceps"], "beginner",
                                  "Press overhead, elbows at 45 degrees", "Pike Push-Up"),
                    make_exercise("Plank", 3, "30-45 seconds", 30,
                                  "Bodyweight", "None", "Core", "Transverse Abdominis",
                                  ["Rectus Abdominis", "Shoulders"], "beginner",
                                  "Tight core, straight body line", "Kneeling Plank"),
                    make_exercise("Hollow Body Hold", 3, "20-30 seconds", 30,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Transverse Abdominis", "Hip Flexors"], "intermediate",
                                  "Low back pressed to floor, shoulders off ground", "Dead Bug"),
                    make_exercise("Superman Hold", 3, "15-20 seconds", 30,
                                  "Bodyweight", "None", "Back", "Erector Spinae",
                                  ["Glutes", "Rear Deltoid"], "beginner",
                                  "Arms and legs off floor, squeeze back", "Bird Dog"),
                    make_exercise("Wrist Curl", 3, "12-15", 30,
                                  "Light", "Dumbbell", "Arms", "Forearm Flexors",
                                  ["Forearm Extensors"], "beginner",
                                  "Rest forearm on bench, curl wrist up", "Towel Squeeze"),
                ]
            })

        # Day 4: Test & Volume (if 4 sessions)
        if sessions >= 4:
            workouts.append({
                "workout_name": "Day 4 - Test & Volume",
                "type": "strength",
                "duration_minutes": 35,
                "exercises": [
                    make_exercise("Pull-Up / Pull-Up Attempt (Max Test)", 1, "Max reps or attempts", 180,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Core"], "intermediate" if progress > 0.5 else "beginner",
                                  "Record your max, full dead hang start", "Band-Assisted Max Test"),
                    make_exercise("Inverted Row", 4, "10-12", 60,
                                  "Bodyweight", "Barbell/Smith Machine", "Back", "Rhomboids",
                                  ["Lats", "Biceps"], "beginner",
                                  "Keep body rigid, pull chest to bar", "TRX Row"),
                    make_exercise("Lat Pulldown (Wide Grip)", 3, "10-12", 60,
                                  "Moderate", "Cable Machine", "Back", "Latissimus Dorsi",
                                  ["Teres Major", "Biceps"], "beginner",
                                  "Wide grip, pull to upper chest", "Close-Grip Lat Pulldown"),
                    make_exercise("Reverse Grip Barbell Row", 3, "8-10", 60,
                                  "Moderate", "Barbell", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Rhomboids"], "intermediate",
                                  "Underhand grip, pull to lower chest", "Supinated Cable Row"),
                    make_exercise("Hanging Knee Raise", 3, "8-12", 45,
                                  "Bodyweight", "Pull-Up Bar", "Core", "Lower Rectus Abdominis",
                                  ["Hip Flexors"], "beginner",
                                  "No swinging, controlled raise, grip practice", "Lying Knee Raise"),
                    make_exercise("Plate Pinch Hold", 3, "20-30 seconds", 45,
                                  "Moderate", "Weight Plates", "Arms", "Forearms",
                                  [], "beginner",
                                  "Pinch two plates together smooth sides out", "Towel Hang"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# BOX JUMP PROGRESSION - Height + technique
# =============================================================================

def box_jump_progression_weeks(duration, sessions):
    """Generate Box Jump Progression: build explosive power and height."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.3:
            phase = "Landing Mechanics"
            box_height = "12-16 inches"
            jump_reps = "5-6"
        elif progress <= 0.6:
            phase = "Power Development"
            box_height = "16-20 inches"
            jump_reps = "4-5"
        elif progress <= 0.85:
            phase = "Height Increase"
            box_height = "20-24 inches"
            jump_reps = "3-4"
        else:
            phase = "Max Height Test"
            box_height = "24-30+ inches"
            jump_reps = "2-3"

        workouts = []

        # Day 1: Box Jump Skill + Plyometrics
        workouts.append({
            "workout_name": "Day 1 - Box Jump Skill",
            "type": "plyometric",
            "duration_minutes": 35,
            "exercises": [
                make_exercise("Depth Drop (Step Off Box)", 3, "5-6", 60,
                              "Bodyweight", "Plyo Box", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "beginner",
                              "Step off box, absorb landing with soft knees", "Squat Hold Landing"),
                make_exercise("Box Jump", 5, jump_reps, 90,
                              "Bodyweight", f"Plyo Box ({box_height})", "Legs", "Quadriceps",
                              ["Glutes", "Calves", "Core"], "intermediate",
                              "Arm swing, explode up, land softly on box, step down", "Squat Jump"),
                make_exercise("Squat Jump", 4, "6-8", 60,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "beginner",
                              "Quarter squat, explode up, soft landing", "Bodyweight Squat"),
                make_exercise("Tuck Jump", 3, "5-6", 60,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Hip Flexors", "Core", "Calves"], "intermediate",
                              "Jump and pull knees to chest, land soft", "Squat Jump"),
                make_exercise("Single-Leg Box Step-Up (Explosive)", 3, "5-6 each leg", 60,
                              "Bodyweight", "Plyo Box", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "intermediate",
                              "Drive through heel, explosive step-up", "Step-Up"),
                make_exercise("Calf Raise (Explosive)", 3, "12-15", 30,
                              "Bodyweight", "Step", "Legs", "Calves",
                              ["Soleus"], "beginner",
                              "Bounce off the stretch at bottom", "Standard Calf Raise"),
            ]
        })

        # Day 2: Strength for Jump
        workouts.append({
            "workout_name": "Day 2 - Leg Strength for Jumping",
            "type": "strength",
            "duration_minutes": 40,
            "exercises": [
                make_exercise("Goblet Squat", 4, "8-10", 90,
                              "Moderate-Heavy", "Dumbbell/Kettlebell", "Legs", "Quadriceps",
                              ["Glutes", "Core"], "beginner",
                              "Elbows inside knees, upright torso, below parallel", "Bodyweight Squat"),
                make_exercise("Bulgarian Split Squat", 3, "8-10 each leg", 60,
                              "Moderate", "Dumbbells", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Rear foot on bench, lower under control", "Reverse Lunge"),
                make_exercise("Romanian Deadlift", 3, "8-10", 90,
                              "Moderate-Heavy", "Dumbbells", "Legs", "Hamstrings",
                              ["Glutes", "Erector Spinae"], "intermediate",
                              "Hinge at hips, feel hamstring stretch", "Good Morning"),
                make_exercise("Lateral Bound", 3, "6-8 each side", 60,
                              "Bodyweight", "None", "Legs", "Glute Medius",
                              ["Quadriceps", "Calves"], "intermediate",
                              "Bound sideways, stick single-leg landing", "Lateral Lunge"),
                make_exercise("Glute Bridge March", 3, "10 each leg", 45,
                              "Bodyweight", "None", "Legs", "Glutes",
                              ["Hamstrings", "Core"], "beginner",
                              "Bridge position, alternate lifting knees", "Glute Bridge"),
                make_exercise("Plank", 3, "30-45 seconds", 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Rectus Abdominis"], "beginner",
                              "Core stability for jump control", "Dead Bug"),
            ]
        })

        # Day 3: Reactive Power
        if sessions >= 3:
            workouts.append({
                "workout_name": "Day 3 - Reactive Power",
                "type": "plyometric",
                "duration_minutes": 35,
                "exercises": [
                    make_exercise("Depth Jump (Step Off -> Jump Up)", 4, "3-4", 120,
                                  "Bodyweight", "Plyo Box", "Legs", "Quadriceps",
                                  ["Glutes", "Calves", "Core"], "intermediate",
                                  "Step off low box, immediately jump up on landing", "Box Jump"),
                    make_exercise("Broad Jump", 4, "4-5", 90,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Hamstrings", "Calves"], "intermediate",
                                  "Swing arms, jump max distance forward", "Squat Jump"),
                    make_exercise("Vertical Jump (Max Effort)", 4, "3-4", 90,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Calves"], "intermediate",
                                  "Track your reach height, full arm swing", "Squat Jump"),
                    make_exercise("Pogo Jump", 3, "15-20", 45,
                                  "Bodyweight", "None", "Legs", "Calves",
                                  ["Quadriceps", "Core"], "beginner",
                                  "Stiff ankles, bounce using calf/achilles", "Jump Rope"),
                    make_exercise("Kettlebell Swing", 3, "10-12", 60,
                                  "Moderate-Heavy", "Kettlebell", "Full Body", "Glutes",
                                  ["Hamstrings", "Core"], "intermediate",
                                  "Explosive hip hinge, builds posterior chain power", "Dumbbell Swing"),
                    make_exercise("Ankle Mobility Drill", 3, "10 each side", 15,
                                  "Bodyweight", "None", "Legs", "Tibialis Anterior",
                                  ["Calves"], "beginner",
                                  "Knee over toe stretch against wall", "Calf Stretch"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: Target box height {box_height}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# PUSH-UP TO PLANCHE - Calisthenics progression path
# =============================================================================

def pushup_to_planche_weeks(duration, sessions):
    """Generate Push-Up to Planche progression."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.2:
            phase = "Push-Up Mastery"
            planche_level = "Plank holds and pseudo planche leans"
        elif progress <= 0.4:
            phase = "Pseudo Planche"
            planche_level = "Pseudo planche push-ups and lean holds"
        elif progress <= 0.6:
            phase = "Tuck Planche"
            planche_level = "Tuck planche holds and press work"
        elif progress <= 0.8:
            phase = "Advanced Tuck"
            planche_level = "Advanced tuck planche and straddle entries"
        else:
            phase = "Straddle / Full Planche"
            planche_level = "Straddle planche work toward full planche"

        workouts = []

        # Day 1: Planche Skill Work
        day1_exercises = []
        if progress <= 0.2:
            day1_exercises = [
                make_exercise("Planche Lean (Plank Position)", 5, "15-20 seconds", 60,
                              "Bodyweight", "Floor/Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest", "Wrist Flexors"], "beginner",
                              "Push-up position, lean forward shifting weight onto hands", "Plank"),
                make_exercise("Diamond Push-Up", 4, "8-12", 60,
                              "Bodyweight", "None", "Chest", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Hands together, full range", "Close-Grip Push-Up"),
                make_exercise("Pseudo Planche Push-Up (Hands by Waist)", 4, "5-8", 90,
                              "Bodyweight", "None", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Core", "Triceps"], "intermediate",
                              "Hands rotated out, by hips, lean forward and push", "Decline Push-Up"),
                make_exercise("Plank Hold", 3, "45-60 seconds", 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Rectus Abdominis", "Shoulders"], "beginner",
                              "Hollow body position, protract scapulae", "Kneeling Plank"),
                make_exercise("Wrist Warm-Up", 3, "10 each direction", 15,
                              "Bodyweight", "None", "Arms", "Forearm Flexors",
                              ["Forearm Extensors"], "beginner",
                              "Circles, rocks, and stretches - essential for planche", "Wrist Curls"),
                make_exercise("Straight-Arm Plank Protraction", 3, "10-12", 30,
                              "Bodyweight", "None", "Back", "Serratus Anterior",
                              ["Chest", "Core"], "beginner",
                              "Push ground away, rounding upper back at top", "Scapular Push-Up"),
            ]
        elif progress <= 0.4:
            day1_exercises = [
                make_exercise("Pseudo Planche Push-Up", 5, "5-8", 90,
                              "Bodyweight", "None", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Core", "Triceps"], "intermediate",
                              "Hands by waist, lean forward significantly", "Decline Push-Up"),
                make_exercise("Planche Lean Hold", 5, "20-30 seconds", 60,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Wrist Flexors"], "intermediate",
                              "Lean further each week, arms locked", "Plank Lean"),
                make_exercise("Tuck Planche Attempt (Floor)", 4, "5-10 seconds", 90,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest", "Biceps"], "intermediate",
                              "Knees to chest, lift feet off floor on parallettes", "Planche Lean"),
                make_exercise("Hollow Body Hold", 4, "30 seconds", 45,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Transverse Abdominis", "Hip Flexors"], "intermediate",
                              "Low back pressed down, essential for planche body position", "Dead Bug"),
                make_exercise("Dip", 4, "8-10", 60,
                              "Bodyweight", "Dip Station/Parallettes", "Chest", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Lean slightly forward, builds pressing strength", "Bench Dip"),
                make_exercise("Band-Assisted Planche Hold", 3, "10-15 seconds", 60,
                              "Band-Assisted", "Parallettes + Band", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest"], "intermediate",
                              "Band around hips, feel the body position", "Planche Lean"),
            ]
        elif progress <= 0.6:
            day1_exercises = [
                make_exercise("Tuck Planche Hold", 5, "10-20 seconds", 90,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest", "Wrist Flexors"], "intermediate",
                              "Knees tight to chest, round back, arms locked", "Band-Assisted Tuck Planche"),
                make_exercise("Tuck Planche Push-Up", 4, "3-5", 120,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Triceps", "Core"], "advanced",
                              "Hold tuck planche, lower and press", "Pseudo Planche Push-Up"),
                make_exercise("Pseudo Planche Push-Up (Deep Lean)", 4, "5-8", 90,
                              "Bodyweight", "None", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Core"], "intermediate",
                              "Maximum forward lean, hands by belly button", "Decline Push-Up"),
                make_exercise("L-Sit Hold", 4, "15-20 seconds", 60,
                              "Bodyweight", "Parallettes", "Core", "Rectus Abdominis",
                              ["Hip Flexors", "Triceps"], "intermediate",
                              "Arms locked, legs parallel to floor", "Tuck L-Sit"),
                make_exercise("Ring/Parallette Support Hold", 3, "30 seconds", 45,
                              "Bodyweight", "Parallettes/Rings", "Shoulders", "Triceps",
                              ["Anterior Deltoid", "Core"], "intermediate",
                              "Arms locked, slight lean forward", "Dip Top Hold"),
                make_exercise("Wrist Conditioning", 3, "10 each position", 15,
                              "Bodyweight", "None", "Arms", "Forearm Flexors",
                              ["Forearm Extensors"], "beginner",
                              "Weight on hands, various wrist positions", "Wrist Curls"),
            ]
        elif progress <= 0.8:
            day1_exercises = [
                make_exercise("Advanced Tuck Planche Hold", 5, "8-15 seconds", 120,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest", "Wrist Flexors"], "advanced",
                              "Hips higher than tuck, back less rounded", "Tuck Planche"),
                make_exercise("Tuck to Advanced Tuck Transitions", 4, "3-5", 90,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core"], "advanced",
                              "Start tuck, slowly extend to advanced tuck", "Tuck Planche Hold"),
                make_exercise("Straddle Planche Lean", 4, "8-12 seconds", 90,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Adductors"], "advanced",
                              "Legs spread, try to lift with straight arms", "Advanced Tuck Planche"),
                make_exercise("Planche Push-Up (Band-Assisted)", 3, "3-5", 120,
                              "Band-Assisted", "Parallettes + Band", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Triceps", "Core"], "advanced",
                              "Full planche position with band support", "Tuck Planche Push-Up"),
                make_exercise("V-Sit Hold", 3, "10-15 seconds", 60,
                              "Bodyweight", "Parallettes", "Core", "Rectus Abdominis",
                              ["Hip Flexors", "Triceps"], "advanced",
                              "Higher L-sit with legs angled up", "L-Sit Hold"),
                make_exercise("Maltese Lean", 3, "8-10 seconds", 60,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Biceps"], "advanced",
                              "Rings turned out, lean forward with arms wide", "Wide Planche Lean"),
            ]
        else:
            day1_exercises = [
                make_exercise("Straddle Planche Hold", 5, "5-10 seconds", 120,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Adductors", "Wrist Flexors"], "advanced",
                              "Legs wide, fully elevated, straight arms", "Advanced Tuck Planche"),
                make_exercise("Full Planche Attempt", 4, "3-5 seconds", 180,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Chest", "Glutes"], "advanced",
                              "Legs together and straight, full body horizontal", "Straddle Planche"),
                make_exercise("Planche Push-Up (Straddle)", 3, "2-3", 180,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Chest", "Triceps", "Core"], "advanced",
                              "Lower and press in straddle planche", "Tuck Planche Push-Up"),
                make_exercise("Straddle Planche Press", 3, "1-3", 180,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Hip Flexors"], "advanced",
                              "From L-sit, press into straddle planche", "Tuck Planche Press"),
                make_exercise("Handstand Push-Up", 3, "3-5", 120,
                              "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps", "Core"], "advanced",
                              "Wall-assisted, full range overhead pressing strength", "Pike Push-Up"),
                make_exercise("Planche Lean Max Hold", 3, "Max time", 60,
                              "Bodyweight", "Parallettes", "Shoulders", "Anterior Deltoid",
                              ["Core", "Wrist Flexors"], "advanced",
                              "Maximum lean, build time under tension", "Pseudo Planche Push-Up"),
            ]

        workouts.append({
            "workout_name": "Day 1 - Planche Skill",
            "type": "calisthenics",
            "duration_minutes": 45,
            "exercises": day1_exercises,
        })

        # Day 2: Pressing Strength
        workouts.append({
            "workout_name": "Day 2 - Pressing Strength",
            "type": "strength",
            "duration_minutes": 40,
            "exercises": [
                make_exercise("Weighted Dip", 4, "6-8", 120,
                              "Heavy" if progress > 0.5 else "Moderate", "Dip Station", "Chest", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Add weight progressively, lean forward", "Bodyweight Dip"),
                make_exercise("Pike Push-Up (Elevated Feet)", 4, "6-10", 90,
                              "Bodyweight", "Bench", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps"], "intermediate",
                              "Feet elevated, pike position, head to floor", "Standard Pike Push-Up"),
                make_exercise("Ring Push-Up", 3, "8-10", 60,
                              "Bodyweight", "Gymnastics Rings", "Chest", "Pectoralis Major",
                              ["Triceps", "Core", "Stabilizers"], "intermediate",
                              "Rings at chest height, turn out at top", "Push-Up"),
                make_exercise("Straight-Arm Press (Floor)", 3, "5-8", 90,
                              "Bodyweight", "Floor", "Shoulders", "Anterior Deltoid",
                              ["Core", "Serratus Anterior"], "intermediate",
                              "Seated, hands by hips, press body off floor", "L-Sit Attempt"),
                make_exercise("Hollow Body Hold", 3, "30-45 seconds", 30,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Transverse Abdominis", "Hip Flexors"], "intermediate",
                              "Essential core position for planche", "Dead Bug"),
                make_exercise("Wrist Pushup", 3, "8-10", 30,
                              "Bodyweight", "None", "Arms", "Forearm Flexors",
                              ["Forearm Extensors"], "intermediate",
                              "On backs of hands, push up to strengthen wrists", "Wrist Curls"),
            ]
        })

        # Day 3: Pulling Balance + Core
        if sessions >= 3:
            workouts.append({
                "workout_name": "Day 3 - Pull & Core Balance",
                "type": "strength",
                "duration_minutes": 40,
                "exercises": [
                    make_exercise("Pull-Up", 4, "6-10", 90,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Core"], "intermediate",
                                  "Balance pushing with pulling to prevent injury", "Lat Pulldown"),
                    make_exercise("Front Lever Tuck Hold", 3, "10-15 seconds", 60,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Core", "Rear Deltoid"], "intermediate",
                                  "Hang, pull body horizontal with knees tucked", "Inverted Row"),
                    make_exercise("Inverted Row", 3, "10-12", 60,
                                  "Bodyweight", "Barbell/Smith Machine", "Back", "Rhomboids",
                                  ["Lats", "Biceps"], "beginner",
                                  "Pull chest to bar, straight body", "TRX Row"),
                    make_exercise("Dragon Flag Negative", 3, "3-5", 90,
                                  "Bodyweight", "Bench", "Core", "Rectus Abdominis",
                                  ["Obliques", "Hip Flexors"], "advanced",
                                  "Lower body as one unit, very slowly", "Lying Leg Raise"),
                    make_exercise("L-Sit Hold", 3, "15-30 seconds", 60,
                                  "Bodyweight", "Parallettes", "Core", "Rectus Abdominis",
                                  ["Hip Flexors", "Triceps"], "intermediate",
                                  "Build hip flexor and core endurance", "Tuck L-Sit"),
                    make_exercise("Band Shoulder Dislocates", 3, "10-12", 15,
                                  "Light", "Resistance Band", "Shoulders", "Rear Deltoid",
                                  ["Rotator Cuff", "Traps"], "beginner",
                                  "Wide grip, pass band over head and behind body", "Shoulder Circles"),
                ]
            })

        # Day 4: Accessories
        if sessions >= 4:
            workouts.append({
                "workout_name": "Day 4 - Strength Accessories",
                "type": "hypertrophy",
                "duration_minutes": 35,
                "exercises": [
                    make_exercise("Handstand Hold (Wall-Assisted)", 4, "20-30 seconds", 60,
                                  "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid",
                                  ["Core", "Traps", "Forearms"], "intermediate",
                                  "Belly to wall, straight line, builds shoulder endurance", "Pike Hold"),
                    make_exercise("Close-Grip Bench Press", 3, "8-10", 90,
                                  "Moderate-Heavy", "Barbell", "Arms", "Triceps",
                                  ["Chest", "Anterior Deltoid"], "intermediate",
                                  "Hands shoulder width, elbows tucked", "Close-Grip Push-Up"),
                    make_exercise("Face Pull", 3, "15-20", 45,
                                  "Light", "Cable Machine", "Shoulders", "Rear Deltoid",
                                  ["Rhomboids", "External Rotators"], "beginner",
                                  "Essential for shoulder health", "Band Pull-Apart"),
                    make_exercise("Bicep Curl", 3, "10-12", 45,
                                  "Moderate", "Dumbbells", "Arms", "Biceps",
                                  ["Brachialis"], "beginner",
                                  "Balance push-heavy training", "Band Curl"),
                    make_exercise("Planche Lean (Cool-Down)", 3, "Max hold", 30,
                                  "Bodyweight", "Floor", "Shoulders", "Anterior Deltoid",
                                  ["Core"], "intermediate",
                                  "Light lean, accumulate time", "Plank"),
                ]
            })

        # Day 5: Conditioning
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Conditioning & Flexibility",
                "type": "circuit",
                "duration_minutes": 30,
                "exercises": [
                    make_exercise("Burpee", 3, "10-12", 60,
                                  "Bodyweight", "None", "Full Body", "Quadriceps",
                                  ["Chest", "Shoulders", "Core"], "intermediate",
                                  "Full body conditioning", "Squat Thrust"),
                    make_exercise("Pike Stretch", 3, "30-45 seconds", 15,
                                  "Bodyweight", "None", "Legs", "Hamstrings",
                                  ["Calves"], "beginner",
                                  "Seated, reach for toes, flexibility for L-sit/planche", "Standing Toe Touch"),
                    make_exercise("Straddle Stretch", 3, "30-45 seconds", 15,
                                  "Bodyweight", "None", "Legs", "Adductors",
                                  ["Hamstrings"], "beginner",
                                  "Wide legs, lean forward, needed for straddle planche", "Butterfly Stretch"),
                    make_exercise("Wrist Flexibility Routine", 3, "30 seconds each position", 15,
                                  "Bodyweight", "None", "Arms", "Forearm Flexors",
                                  ["Forearm Extensors"], "beginner",
                                  "Essential: prayer, reverse prayer, finger pulls", "Wrist Circles"),
                    make_exercise("Shoulder Stretch (German Hang)", 3, "15-20 seconds", 30,
                                  "Bodyweight", "Pull-Up Bar/Rings", "Shoulders", "Anterior Deltoid",
                                  ["Pectoralis Minor"], "intermediate",
                                  "Hang behind body, gentle shoulder opener", "Doorway Chest Stretch"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {planche_level}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# FREERUNNING FOUNDATIONS - Creative movement + flips
# =============================================================================

def freerunning_foundations_weeks(duration, sessions):
    """Generate Freerunning Foundations: vaults, rolls, basic flips."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Movement Basics"
        elif progress <= 0.5:
            phase = "Vault & Roll Technique"
        elif progress <= 0.75:
            phase = "Combination Flows"
        else:
            phase = "Creative Expression"

        workouts = []

        # Day 1: Conditioning & Landings
        workouts.append({
            "workout_name": "Day 1 - Conditioning & Landing",
            "type": "circuit",
            "duration_minutes": 45,
            "exercises": [
                make_exercise("Precision Jump (Mark to Mark)", 4, "6-8", 60,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Calves", "Core", "Glutes"], "intermediate",
                              "Jump to specific landing spot, stick the landing", "Broad Jump"),
                make_exercise("Safety Roll (Parkour Roll)", 4, "5 each side", 30,
                              "Bodyweight", "Soft Mat", "Full Body", "Shoulders",
                              ["Core", "Back"], "beginner",
                              "Diagonal roll from shoulder to opposite hip, protect head", "Forward Roll"),
                make_exercise("Drop Landing (Increasing Height)", 4, "5-6", 60,
                              "Bodyweight", "Various Heights", "Legs", "Quadriceps",
                              ["Calves", "Glutes", "Core"], "intermediate",
                              "Land on balls of feet, absorb with legs, arms forward", "Box Step-Down"),
                make_exercise("Squat Jump", 4, "8-10", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "beginner",
                              "Deep squat, explode up, soft landing", "Bodyweight Squat"),
                make_exercise("Bear Crawl", 3, "20 meters", 45,
                              "Bodyweight", "None", "Full Body", "Shoulders",
                              ["Core", "Quadriceps", "Hip Flexors"], "beginner",
                              "Hands and feet on floor, knees low, crawl forward", "Mountain Climber"),
                make_exercise("Quadrupedal Movement", 3, "15 meters each direction", 30,
                              "Bodyweight", "None", "Full Body", "Core",
                              ["Shoulders", "Hip Flexors", "Quadriceps"], "beginner",
                              "Move on all fours: forward, backward, lateral", "Bear Crawl"),
            ]
        })

        # Day 2: Upper Body & Vault Prep
        workouts.append({
            "workout_name": "Day 2 - Upper Body & Vault Prep",
            "type": "strength",
            "duration_minutes": 40,
            "exercises": [
                make_exercise("Wall Run Drill", 4, "5-6 each side", 60,
                              "Bodyweight", "Wall", "Legs", "Calves",
                              ["Quadriceps", "Core"], "intermediate",
                              "Run at wall, plant foot 2-3 feet up, push off", "Box Jump"),
                make_exercise("Speed Vault Drill (Low Rail)", 4, "5-6 each side", 45,
                              "Bodyweight", "Low Rail/Box", "Full Body", "Triceps",
                              ["Core", "Shoulders", "Hip Flexors"], "intermediate",
                              "One hand on rail, swing legs over", "Lateral Box Jump-Over"),
                make_exercise("Pull-Up", 4, "6-10", 60,
                              "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Forearms"], "intermediate",
                              "Essential for wall climbs and cat hangs", "Band-Assisted Pull-Up"),
                make_exercise("Dip", 4, "8-10", 60,
                              "Bodyweight", "Dip Station/Parallettes", "Chest", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Pressing strength for vaults", "Push-Up"),
                make_exercise("Cat Hang to Climb-Up", 3, "4-6", 90,
                              "Bodyweight", "Wall/Bar", "Back", "Latissimus Dorsi",
                              ["Biceps", "Core", "Forearms"], "intermediate",
                              "Hang from wall edge, pull yourself up and over", "Pull-Up to Muscle-Up Attempt"),
                make_exercise("Plank to Push-Up", 3, "8-10", 45,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Triceps", "Shoulders"], "beginner",
                              "Transition between plank and push-up position", "Plank"),
            ]
        })

        # Day 3: Plyometrics & Flow
        if sessions >= 3:
            workouts.append({
                "workout_name": "Day 3 - Plyometrics & Flow",
                "type": "plyometric",
                "duration_minutes": 40,
                "exercises": [
                    make_exercise("Kong Vault Drill (Over Box)", 4, "5-6", 60,
                                  "Bodyweight", "Plyo Box", "Full Body", "Shoulders",
                                  ["Triceps", "Core", "Hip Flexors"], "intermediate",
                                  "Hands on box, dive through with feet, both hands plant", "Speed Vault"),
                    make_exercise("Tic-Tac (Wall Kick)", 3, "5 each side", 60,
                                  "Bodyweight", "Wall", "Legs", "Calves",
                                  ["Glutes", "Core", "Hip Flexors"], "intermediate",
                                  "Kick off wall to redirect, change direction", "Lateral Bound"),
                    make_exercise("Running Precision Jump", 4, "5-6", 90,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Calves", "Core"], "intermediate",
                                  "Run, jump to precise landing spot, stick it", "Broad Jump"),
                    make_exercise("Cartwheel", 3, "5 each side", 30,
                                  "Bodyweight", "Soft Surface", "Full Body", "Shoulders",
                                  ["Core", "Obliques", "Arms"], "beginner",
                                  "Hands down one at a time, legs over", "Lateral Roll"),
                    make_exercise("Front Handspring Drill (Wall Walk)", 3, "4-5", 60,
                                  "Bodyweight", "Wall/Soft Surface", "Shoulders", "Anterior Deltoid",
                                  ["Core", "Wrists"], "intermediate",
                                  "Kick up to handstand on wall, controlled walk down", "Handstand Hold"),
                    make_exercise("Pistol Squat (Assisted)", 3, "5 each leg", 60,
                                  "Bodyweight", "Pole/TRX for Balance", "Legs", "Quadriceps",
                                  ["Glutes", "Core"], "intermediate",
                                  "Single leg squat, hold support for balance", "Bulgarian Split Squat"),
                ]
            })

        # Day 4: Flexibility & Balance
        if sessions >= 4:
            workouts.append({
                "workout_name": "Day 4 - Flexibility & Balance",
                "type": "flexibility",
                "duration_minutes": 35,
                "exercises": [
                    make_exercise("Balance Rail Walk", 3, "20 meters", 30,
                                  "Bodyweight", "Low Rail/Beam", "Legs", "Tibialis Anterior",
                                  ["Calves", "Core", "Glute Medius"], "beginner",
                                  "Walk on narrow surface, eyes forward", "Single-Leg Stand"),
                    make_exercise("Deep Squat Hold", 3, "45-60 seconds", 15,
                                  "Bodyweight", "None", "Legs", "Adductors",
                                  ["Hip Flexors", "Calves", "Core"], "beginner",
                                  "Full depth squat, chest up, heels down", "Assisted Squat Hold"),
                    make_exercise("Bridge Hold", 3, "15-20 seconds", 30,
                                  "Bodyweight", "None", "Back", "Erector Spinae",
                                  ["Glutes", "Shoulders", "Hip Flexors"], "intermediate",
                                  "Full bridge, push hips up, essential for flips", "Glute Bridge"),
                    make_exercise("Splits Stretching (Front)", 3, "30 seconds each leg", 15,
                                  "Bodyweight", "None", "Legs", "Hamstrings",
                                  ["Hip Flexors", "Adductors"], "beginner",
                                  "Progressive splits, support with hands", "Lunge Stretch"),
                    make_exercise("Handstand Hold (Wall)", 3, "15-30 seconds", 60,
                                  "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid",
                                  ["Core", "Traps"], "intermediate",
                                  "Belly to wall, straight line, builds inversion comfort", "Pike Hold"),
                    make_exercise("Shoulder Mobility Flow", 3, "10 reps each movement", 15,
                                  "Bodyweight", "None", "Shoulders", "Rotator Cuff",
                                  ["Traps", "Rhomboids"], "beginner",
                                  "Arm circles, band dislocates, shoulder CARs", "Arm Circles"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# TRICKING BASICS - Kicks, twists, combos introduction
# =============================================================================

def tricking_basics_weeks(duration, sessions):
    """Generate Tricking Basics: martial arts kicks, spins, and intro combos."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.2:
            phase = "Kick Foundations"
        elif progress <= 0.4:
            phase = "Spinning Kicks"
        elif progress <= 0.6:
            phase = "Aerial Prep"
        elif progress <= 0.8:
            phase = "Basic Combos"
        else:
            phase = "Flow & Expression"

        workouts = []

        # Day 1: Kick Technique
        workouts.append({
            "workout_name": "Day 1 - Kick Technique",
            "type": "sport_specific",
            "duration_minutes": 45,
            "exercises": [
                make_exercise("Front Kick Drill", 4, "10 each leg", 30,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Hip Flexors", "Core", "Calves"], "beginner",
                              "Chamber knee high, snap foot out, retract", "Knee Raise"),
                make_exercise("Roundhouse Kick Drill", 4, "10 each leg", 30,
                              "Bodyweight", "None", "Legs", "Hip Flexors",
                              ["Obliques", "Quadriceps", "Calves"], "beginner",
                              "Pivot on support foot, hip rotation drives the kick", "Lateral Leg Raise"),
                make_exercise("Side Kick Drill", 3, "8 each leg", 30,
                              "Bodyweight", "None", "Legs", "Glute Medius",
                              ["Quadriceps", "Obliques"], "beginner",
                              "Chamber, extend sideways with heel", "Side Leg Raise"),
                make_exercise("Crescent Kick", 3, "8 each leg", 30,
                              "Bodyweight", "None", "Legs", "Adductors",
                              ["Hip Flexors", "Core"], "intermediate",
                              "Swing leg in crescent arc across body", "Front Kick"),
                make_exercise("Jumping Lunge", 3, "8 each leg", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Calves", "Core"], "intermediate",
                              "Explosive switch, builds kick power", "Reverse Lunge"),
                make_exercise("Hip Flexor Stretch", 3, "30 seconds each side", 15,
                              "Bodyweight", "None", "Legs", "Hip Flexors",
                              ["Quadriceps"], "beginner",
                              "Deep lunge stretch, essential for high kicks", "Kneeling Hip Flexor Stretch"),
            ]
        })

        # Day 2: Spins & Conditioning
        workouts.append({
            "workout_name": "Day 2 - Spins & Conditioning",
            "type": "circuit",
            "duration_minutes": 40,
            "exercises": [
                make_exercise("360 Spin Drill (Standing)", 4, "5 each direction", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Hip Flexors", "Calves"], "beginner",
                              "Spot something, spin 360, refocus on spot", "Pivot Turn"),
                make_exercise("Tornado Kick Drill", 3, "5 each side", 45,
                              "Bodyweight", "None", "Legs", "Hip Flexors",
                              ["Core", "Quadriceps", "Calves"], "intermediate",
                              "Inside crescent into 360 spin into round kick", "Spinning Back Kick"),
                make_exercise("Squat Jump", 4, "8-10", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Calves"], "beginner",
                              "Explosive power for aerial moves", "Bodyweight Squat"),
                make_exercise("Tuck Jump", 3, "6-8", 60,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Hip Flexors", "Core"], "intermediate",
                              "Jump and pull knees to chest", "Squat Jump"),
                make_exercise("Burpee", 3, "8-10", 60,
                              "Bodyweight", "None", "Full Body", "Quadriceps",
                              ["Chest", "Core", "Shoulders"], "intermediate",
                              "Full body conditioning for tricking stamina", "Squat Thrust"),
                make_exercise("Dynamic Hamstring Stretch", 3, "10 each leg", 15,
                              "Bodyweight", "None", "Legs", "Hamstrings",
                              ["Calves"], "beginner",
                              "Standing leg swing: front to back, controlled", "Static Hamstring Stretch"),
            ]
        })

        # Day 3: Strength & Flexibility
        if sessions >= 3:
            workouts.append({
                "workout_name": "Day 3 - Strength & Flexibility",
                "type": "strength",
                "duration_minutes": 40,
                "exercises": [
                    make_exercise("Pistol Squat (Assisted)", 3, "5-6 each leg", 60,
                                  "Bodyweight", "TRX/Pole", "Legs", "Quadriceps",
                                  ["Glutes", "Core"], "intermediate",
                                  "Single-leg strength for kicks and landings", "Bulgarian Split Squat"),
                    make_exercise("Pull-Up", 4, "6-8", 60,
                                  "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi",
                                  ["Biceps", "Core"], "intermediate",
                                  "Upper body strength for aerials", "Lat Pulldown"),
                    make_exercise("Handstand Hold (Wall)", 4, "15-20 seconds", 60,
                                  "Bodyweight", "Wall", "Shoulders", "Anterior Deltoid",
                                  ["Core", "Traps"], "intermediate",
                                  "Build inversion confidence for tricks", "Pike Hold"),
                    make_exercise("Splits Progression (Side)", 3, "30 seconds", 15,
                                  "Bodyweight", "None", "Legs", "Adductors",
                                  ["Hamstrings", "Hip Flexors"], "beginner",
                                  "Work toward side splits for high kicks", "Straddle Stretch"),
                    make_exercise("Bridge Hold", 3, "15-20 seconds", 30,
                                  "Bodyweight", "None", "Back", "Erector Spinae",
                                  ["Glutes", "Shoulders", "Hip Flexors"], "intermediate",
                                  "Full bridge, push through shoulders", "Glute Bridge"),
                    make_exercise("V-Up", 3, "10-12", 30,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Hip Flexors"], "intermediate",
                                  "Strong core for rotational tricks", "Crunch"),
                ]
            })

        # Day 4: Combo Practice
        if sessions >= 4:
            workouts.append({
                "workout_name": "Day 4 - Combo Practice",
                "type": "sport_specific",
                "duration_minutes": 40,
                "exercises": [
                    make_exercise("Butterfly Kick Drill", 4, "4-5", 60,
                                  "Bodyweight", "Soft Surface", "Legs", "Hip Flexors",
                                  ["Core", "Adductors", "Quadriceps"], "intermediate",
                                  "Lean forward, sweep legs in horizontal rotation", "Cartwheel"),
                    make_exercise("Cartwheel to Round Kick", 3, "4-5 each side", 45,
                                  "Bodyweight", "None", "Full Body", "Shoulders",
                                  ["Core", "Obliques", "Hip Flexors"], "intermediate",
                                  "Cartwheel, land and immediately throw roundhouse", "Cartwheel"),
                    make_exercise("Kick Combo: Jab-Cross-Round-Hook Kick", 3, "5 each side", 30,
                                  "Bodyweight", "None", "Full Body", "Shoulders",
                                  ["Core", "Hip Flexors", "Quadriceps"], "intermediate",
                                  "Punch-punch-kick-kick smooth combination", "Shadow Boxing"),
                    make_exercise("Macaco (Monkey Flip) Drill", 3, "3-4 each side", 90,
                                  "Bodyweight", "Soft Surface", "Full Body", "Shoulders",
                                  ["Core", "Back", "Arms"], "intermediate",
                                  "One-handed back walkover from ground", "Bridge Push-Off"),
                    make_exercise("Hollow Body Rock", 3, "15-20", 30,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Transverse Abdominis"], "intermediate",
                                  "Rock in hollow body position, builds air awareness", "Hollow Body Hold"),
                    make_exercise("Cool-Down Stretching", 1, "5 minutes", 0,
                                  "Bodyweight", "None", "Full Body", "Hamstrings",
                                  ["Hip Flexors", "Shoulders", "Back"], "beginner",
                                  "Full body stretch focusing on hips, hamstrings, shoulders", "Yoga Flow"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}",
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
        {
            "name": "Pull-up Progression",
            "category": "Progressions",
            "description": "Go from dead hang to strict pull-ups. Progressive program starting with scapular engagement and negatives, building through band-assisted reps to unassisted strict pull-ups.",
            "durations": [1, 2, 4, 8],
            "sessions": [3, 4],
            "has_supersets": False,
            "priority": "High",
            "generator": pullup_progression_weeks,
        },
        {
            "name": "Box Jump Progression",
            "category": "Progressions",
            "description": "Master box jumps from basic landing mechanics to maximum height. Develop explosive leg power, landing technique, and reactive strength progressively.",
            "durations": [1, 2, 4],
            "sessions": [3],
            "has_supersets": False,
            "priority": "High",
            "generator": box_jump_progression_weeks,
        },
        {
            "name": "Push-up to Planche",
            "category": "Progressions",
            "description": "Ultimate calisthenics pushing progression from push-ups through pseudo planche, tuck planche, advanced tuck, straddle, and toward full planche. Includes pressing strength, core work, and flexibility.",
            "durations": [4, 8, 12],
            "sessions": [4, 5],
            "has_supersets": False,
            "priority": "High",
            "generator": pushup_to_planche_weeks,
        },
        {
            "name": "Freerunning Foundations",
            "category": "Progressions",
            "description": "Learn creative movement fundamentals: precision jumps, safety rolls, vaults, wall runs, and basic aerial skills. Build the conditioning and technique for freerunning.",
            "durations": [8, 12],
            "sessions": [3, 4],
            "has_supersets": False,
            "priority": "High",
            "generator": freerunning_foundations_weeks,
        },
        {
            "name": "Tricking Basics",
            "category": "Progressions",
            "description": "Introduction to martial arts tricking: kicks, spins, butterfly kicks, and basic combos. Develop the flexibility, power, and coordination for flashy movement.",
            "durations": [8, 12, 16],
            "sessions": [3, 4],
            "has_supersets": False,
            "priority": "High",
            "generator": tricking_basics_weeks,
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
    print(f"Progressions HIGH priority complete: {success_count} OK, {fail_count} FAIL")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
