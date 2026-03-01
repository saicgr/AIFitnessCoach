#!/usr/bin/env python3
"""
Category 8: Challenges Programs (High Priority)
================================================
- 30-Day Ab Challenge (1,2,4w x 6-7/wk)
- Push-up Progression (1,2,4w x 6-7/wk)
- Squat Challenge (1,2,4w x 6-7/wk)
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
# 30-DAY AB CHALLENGE - Core progression from basic to advanced
# =============================================================================

def ab_challenge_weeks(duration, sessions):
    """Generate 30-Day Ab Challenge weeks with daily core progression."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Activation"
            hold_time = "20-30 seconds"
            base_reps = "10-12"
            adv_reps = "8-10"
        elif progress <= 0.5:
            phase = "Endurance"
            hold_time = "30-45 seconds"
            base_reps = "12-15"
            adv_reps = "10-12"
        elif progress <= 0.75:
            phase = "Strength"
            hold_time = "45-60 seconds"
            base_reps = "15-20"
            adv_reps = "12-15"
        else:
            phase = "Peak"
            hold_time = "60 seconds"
            base_reps = "20-25"
            adv_reps = "15-20"

        workouts = []

        # Day 1: Lower Abs
        workouts.append({
            "workout_name": "Day 1 - Lower Abs Focus",
            "type": "core",
            "duration_minutes": 20,
            "exercises": [
                make_exercise("Reverse Crunch", 3, base_reps, 30,
                              "Bodyweight", "None", "Core", "Lower Rectus Abdominis",
                              ["Hip Flexors"], "beginner",
                              "Curl hips off floor, don't swing", "Lying Leg Raise"),
                make_exercise("Lying Leg Raise", 3, base_reps, 30,
                              "Bodyweight", "None", "Core", "Lower Rectus Abdominis",
                              ["Hip Flexors", "Obliques"], "beginner",
                              "Press lower back into floor, legs straight", "Bent Knee Raise"),
                make_exercise("Flutter Kicks", 3, "20 each leg", 30,
                              "Bodyweight", "None", "Core", "Lower Rectus Abdominis",
                              ["Hip Flexors"], "beginner",
                              "Low back on floor, small quick kicks", "Scissor Kicks"),
                make_exercise("Dead Bug", 3, adv_reps, 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Rectus Abdominis", "Hip Flexors"], "beginner",
                              "Low back pressed to floor, opposite arm/leg extend", "Bird Dog"),
                make_exercise("Plank", 3, hold_time, 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Rectus Abdominis", "Obliques"], "beginner",
                              "Flat back, squeeze glutes, engage core", "Kneeling Plank"),
            ]
        })

        # Day 2: Upper Abs
        workouts.append({
            "workout_name": "Day 2 - Upper Abs Focus",
            "type": "core",
            "duration_minutes": 20,
            "exercises": [
                make_exercise("Crunch", 3, base_reps, 30,
                              "Bodyweight", "None", "Core", "Upper Rectus Abdominis",
                              ["Obliques"], "beginner",
                              "Curl shoulders off floor, exhale at top", "Sit-Up"),
                make_exercise("Toe Touch", 3, base_reps, 30,
                              "Bodyweight", "None", "Core", "Upper Rectus Abdominis",
                              [], "beginner",
                              "Legs vertical, reach hands to toes", "V-Up"),
                make_exercise("Long Arm Crunch", 3, adv_reps, 30,
                              "Bodyweight", "None", "Core", "Upper Rectus Abdominis",
                              ["Obliques"], "beginner",
                              "Arms extended overhead, curl up", "Standard Crunch"),
                make_exercise("V-Up", 3, adv_reps, 30,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Hip Flexors"], "intermediate",
                              "Arms and legs meet at top simultaneously", "Crunch"),
                make_exercise("Hollow Body Hold", 3, hold_time, 30,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Transverse Abdominis", "Hip Flexors"], "intermediate",
                              "Low back pressed down, arms by ears", "Dead Bug Hold"),
            ]
        })

        # Day 3: Obliques
        workouts.append({
            "workout_name": "Day 3 - Obliques Focus",
            "type": "core",
            "duration_minutes": 20,
            "exercises": [
                make_exercise("Bicycle Crunch", 3, base_reps + " each side", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Rectus Abdominis", "Hip Flexors"], "beginner",
                              "Slow rotation, elbow to opposite knee", "Cross-Body Crunch"),
                make_exercise("Russian Twist", 3, base_reps + " each side", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Rectus Abdominis"], "beginner",
                              "Lean back slightly, rotate fully each side", "Seated Twist"),
                make_exercise("Side Plank", 3, hold_time + " each side", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Transverse Abdominis", "Glute Medius"], "beginner",
                              "Hips stacked, don't let hip drop", "Kneeling Side Plank"),
                make_exercise("Heel Touch", 3, base_reps + " each side", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Rectus Abdominis"], "beginner",
                              "Shoulders off floor, reach alternating sides", "Oblique Crunch"),
                make_exercise("Woodchop (Bodyweight)", 3, adv_reps + " each side", 30,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Rectus Abdominis", "Hip Flexors"], "beginner",
                              "Rotate from hip, pivot on back foot", "Cable Woodchop"),
            ]
        })

        # Day 4: Full Core Circuit
        workouts.append({
            "workout_name": "Day 4 - Full Core Circuit",
            "type": "circuit",
            "duration_minutes": 20,
            "exercises": [
                make_exercise("Mountain Climber", 3, "20 each side", 20,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Hip Flexors", "Shoulders"], "beginner",
                              "Plank position, fast alternating knee drives", "High Knees"),
                make_exercise("Plank to Push-Up", 3, adv_reps, 30,
                              "Bodyweight", "None", "Core", "Rectus Abdominis",
                              ["Triceps", "Shoulders"], "intermediate",
                              "Alternate lead arm, minimize hip sway", "Plank"),
                make_exercise("Leg Raise to Hip Thrust", 3, adv_reps, 30,
                              "Bodyweight", "None", "Core", "Lower Rectus Abdominis",
                              ["Hip Flexors", "Obliques"], "intermediate",
                              "Raise legs vertical then thrust hips up", "Reverse Crunch"),
                make_exercise("Ab Crunch Pulse", 3, base_reps, 20,
                              "Bodyweight", "None", "Core", "Upper Rectus Abdominis",
                              [], "beginner",
                              "Stay at top of crunch, small pulses", "Crunch"),
                make_exercise("Bear Crawl Hold", 3, hold_time, 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Shoulders", "Quadriceps"], "intermediate",
                              "Knees 1 inch off floor, flat back", "Plank"),
            ]
        })

        # Day 5: Anti-Extension & Stability
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Stability & Anti-Extension",
                "type": "core",
                "duration_minutes": 20,
                "exercises": [
                    make_exercise("Ab Wheel Rollout", 3, adv_reps, 45,
                                  "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis",
                                  ["Obliques", "Shoulders"], "intermediate",
                                  "Brace core, extend as far as controlled", "Stability Ball Rollout"),
                    make_exercise("Pallof Press", 3, adv_reps + " each side", 30,
                                  "Light", "Cable Machine", "Core", "Obliques",
                                  ["Transverse Abdominis"], "intermediate",
                                  "Press out and hold, resist rotation", "Band Anti-Rotation Press"),
                    make_exercise("Stir the Pot", 3, "8 each direction", 30,
                                  "Bodyweight", "Stability Ball", "Core", "Transverse Abdominis",
                                  ["Obliques", "Rectus Abdominis"], "intermediate",
                                  "Small circles on ball in plank position", "Plank Shoulder Tap"),
                    make_exercise("Body Saw Plank", 3, adv_reps, 30,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Transverse Abdominis", "Shoulders"], "intermediate",
                                  "Rock forward and back in plank", "Plank"),
                    make_exercise("Hanging Knee Raise", 3, base_reps, 30,
                                  "Bodyweight", "Pull-Up Bar", "Core", "Lower Rectus Abdominis",
                                  ["Hip Flexors", "Obliques"], "intermediate",
                                  "No swinging, controlled raise", "Captain's Chair Knee Raise"),
                ]
            })

        # Day 6: Power Abs
        if sessions >= 6:
            workouts.append({
                "workout_name": "Day 6 - Power Abs",
                "type": "core",
                "duration_minutes": 20,
                "exercises": [
                    make_exercise("Medicine Ball Slam", 3, "12-15", 30,
                                  "Moderate", "Medicine Ball", "Core", "Rectus Abdominis",
                                  ["Shoulders", "Lats"], "beginner",
                                  "Reach overhead, slam with full force", "Slam Ball"),
                    make_exercise("Medicine Ball Russian Twist", 3, base_reps + " each side", 30,
                                  "Moderate", "Medicine Ball", "Core", "Obliques",
                                  ["Rectus Abdominis"], "beginner",
                                  "Feet off ground, touch ball to floor each side", "Bodyweight Russian Twist"),
                    make_exercise("Tuck Jump", 3, "8-10", 45,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Hip Flexors", "Quadriceps"], "intermediate",
                                  "Jump and pull knees to chest", "Squat Jump"),
                    make_exercise("Dragon Flag Negative", 3, "5-8", 60,
                                  "Bodyweight", "Bench", "Core", "Rectus Abdominis",
                                  ["Obliques", "Hip Flexors"], "advanced",
                                  "Lower body slowly as one rigid unit", "Lying Leg Raise"),
                    make_exercise("L-Sit Hold (Floor)", 3, "10-20 seconds", 45,
                                  "Bodyweight", "Parallettes", "Core", "Rectus Abdominis",
                                  ["Hip Flexors", "Triceps"], "advanced",
                                  "Push floor away, legs parallel to ground", "Tuck L-Sit"),
                ]
            })

        # Day 7: Active Recovery / Stretch
        if sessions >= 7:
            workouts.append({
                "workout_name": "Day 7 - Active Recovery Core",
                "type": "flexibility",
                "duration_minutes": 15,
                "exercises": [
                    make_exercise("Cat-Cow Stretch", 3, "10 cycles", 15,
                                  "Bodyweight", "None", "Core", "Erector Spinae",
                                  ["Rectus Abdominis"], "beginner",
                                  "Slow, controlled movement between positions", "Spinal Wave"),
                    make_exercise("Cobra Stretch", 3, "20 seconds hold", 15,
                                  "Bodyweight", "None", "Core", "Rectus Abdominis",
                                  ["Hip Flexors"], "beginner",
                                  "Gentle backbend, hips on floor", "Sphinx Stretch"),
                    make_exercise("Child's Pose", 3, "30 seconds hold", 15,
                                  "Bodyweight", "None", "Core", "Erector Spinae",
                                  ["Lats"], "beginner",
                                  "Knees wide, reach arms forward", "Prayer Stretch"),
                    make_exercise("Supine Twist", 3, "20 seconds each side", 15,
                                  "Bodyweight", "None", "Core", "Obliques",
                                  ["Erector Spinae"], "beginner",
                                  "Knees to one side, opposite shoulder down", "Seated Twist"),
                    make_exercise("Diaphragmatic Breathing", 3, "10 breaths", 15,
                                  "Bodyweight", "None", "Core", "Diaphragm",
                                  ["Transverse Abdominis"], "beginner",
                                  "Breathe into belly, slow exhale", "Box Breathing"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Core activation and endurance base' if progress <= 0.25 else 'Build muscular endurance' if progress <= 0.5 else 'Core strength development' if progress <= 0.75 else 'Peak performance and test'}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# PUSH-UP PROGRESSION CHALLENGE - 0 to 50+ push-ups
# =============================================================================

def pushup_challenge_weeks(duration, sessions):
    """Generate Push-up Progression weeks: build to 50+ push-ups."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Foundation"
            target_reps = "5-10"
            total_volume = "30-50 total"
            difficulty = "beginner"
        elif progress <= 0.5:
            phase = "Build Volume"
            target_reps = "10-15"
            total_volume = "50-80 total"
            difficulty = "beginner"
        elif progress <= 0.75:
            phase = "Strength"
            target_reps = "15-25"
            total_volume = "80-120 total"
            difficulty = "intermediate"
        else:
            phase = "Peak Test"
            target_reps = "25-40"
            total_volume = "120-200 total"
            difficulty = "intermediate"

        workouts = []

        # Day 1: Max Effort Push-ups
        workouts.append({
            "workout_name": "Day 1 - Push-Up Max Effort",
            "type": "strength",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Standard Push-Up", 5, target_reps, 60,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid", "Core"], difficulty,
                              "Hands shoulder-width, body straight line, chest to floor", "Knee Push-Up"),
                make_exercise("Plank Hold", 3, "30-45 seconds", 30,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Rectus Abdominis", "Shoulders"], "beginner",
                              "Maintain push-up top position", "Kneeling Plank"),
                make_exercise("Scapular Push-Up", 3, "10-12", 30,
                              "Bodyweight", "None", "Back", "Serratus Anterior",
                              ["Rhomboids", "Traps"], "beginner",
                              "Arms locked, only shoulder blades move", "Band Pull-Apart"),
                make_exercise("Eccentric Push-Up (5s Negative)", 3, "5-8", 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid"], difficulty,
                              "5 second lower, push up normally", "Knee Eccentric Push-Up"),
                make_exercise("Isometric Push-Up Hold (Bottom)", 3, "10-15 seconds", 30,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Core"], difficulty,
                              "Hold at bottom position, chest near floor", "Wall Push-Up Hold"),
            ]
        })

        # Day 2: Variation Day
        workouts.append({
            "workout_name": "Day 2 - Push-Up Variations",
            "type": "hypertrophy",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Wide Push-Up", 4, target_reps, 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Anterior Deltoid", "Triceps"], difficulty,
                              "Hands wider than shoulders, targets chest", "Standard Push-Up"),
                make_exercise("Diamond Push-Up", 4, "6-10", 60,
                              "Bodyweight", "None", "Arms", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Hands together forming diamond, elbows back", "Close-Grip Push-Up"),
                make_exercise("Incline Push-Up", 3, "12-15", 30,
                              "Bodyweight", "Bench", "Chest", "Lower Pectoralis",
                              ["Triceps", "Anterior Deltoid"], "beginner",
                              "Hands on elevated surface, easier variation", "Standard Push-Up"),
                make_exercise("Decline Push-Up", 3, "8-12", 45,
                              "Bodyweight", "Bench", "Chest", "Upper Pectoralis",
                              ["Anterior Deltoid", "Triceps"], "intermediate",
                              "Feet elevated on bench, more shoulder involvement", "Standard Push-Up"),
                make_exercise("Spiderman Push-Up", 3, "6-8 each side", 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Obliques", "Hip Flexors", "Triceps"], "intermediate",
                              "Bring knee to elbow during descent", "Standard Push-Up"),
            ]
        })

        # Day 3: Endurance / Density
        workouts.append({
            "workout_name": "Day 3 - Push-Up Density",
            "type": "endurance",
            "duration_minutes": 20,
            "exercises": [
                make_exercise("Push-Up EMOM (Every Minute On the Minute)", 1, total_volume, 60,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid", "Core"], difficulty,
                              "Set target reps per minute, rest remainder", "Knee Push-Up EMOM"),
                make_exercise("Pike Push-Up", 3, "8-10", 45,
                              "Bodyweight", "None", "Shoulders", "Anterior Deltoid",
                              ["Lateral Deltoid", "Triceps"], "intermediate",
                              "Hips high, head toward floor, like downward dog", "Incline Push-Up"),
                make_exercise("Hand Release Push-Up", 3, "8-12", 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid"], difficulty,
                              "Lift hands off floor at bottom, full reset each rep", "Standard Push-Up"),
                make_exercise("Shoulder Tap Push-Up", 3, "6-8 each side", 45,
                              "Bodyweight", "None", "Core", "Transverse Abdominis",
                              ["Chest", "Shoulders", "Triceps"], "intermediate",
                              "Push up, tap opposite shoulder, minimize hip sway", "Plank Shoulder Tap"),
                make_exercise("Tricep Push-Up", 3, "8-12", 45,
                              "Bodyweight", "None", "Arms", "Triceps",
                              ["Pectoralis Major", "Anterior Deltoid"], "intermediate",
                              "Elbows tight to body throughout", "Diamond Push-Up"),
            ]
        })

        # Day 4: Plyometric / Power
        workouts.append({
            "workout_name": "Day 4 - Power Push-Ups",
            "type": "strength",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Explosive Push-Up", 4, "5-8", 60,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Anterior Deltoid"], "intermediate",
                              "Push explosively so hands leave floor", "Standard Push-Up"),
                make_exercise("Tempo Push-Up (3-1-3)", 3, "6-8", 60,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Core"], "intermediate",
                              "3 sec down, 1 sec pause, 3 sec up", "Standard Push-Up"),
                make_exercise("Push-Up with Rotation", 3, "6-8 each side", 45,
                              "Bodyweight", "None", "Core", "Obliques",
                              ["Chest", "Shoulders"], "intermediate",
                              "Push up, rotate to side plank, arm to sky", "Standard Push-Up"),
                make_exercise("Staggered Push-Up", 3, "8-10 each side", 45,
                              "Bodyweight", "None", "Chest", "Pectoralis Major",
                              ["Triceps", "Core"], "intermediate",
                              "One hand forward, one back, switch sides", "Standard Push-Up"),
                make_exercise("Dip (Bench)", 3, "10-15", 45,
                              "Bodyweight", "Bench", "Arms", "Triceps",
                              ["Chest", "Anterior Deltoid"], "beginner",
                              "Elbows back, lower until 90 degrees", "Close-Grip Push-Up"),
            ]
        })

        # Day 5: Volume Day
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Volume Accumulation",
                "type": "endurance",
                "duration_minutes": 25,
                "exercises": [
                    make_exercise("Standard Push-Up (Ladder)", 1, "1-2-3-4-5-4-3-2-1", 30,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid", "Core"], difficulty,
                                  "Go up the ladder, then back down", "Knee Push-Up Ladder"),
                    make_exercise("Archer Push-Up", 3, "5-8 each side", 60,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Triceps", "Core"], "advanced",
                                  "Wide grip, shift weight to one arm", "Wide Push-Up"),
                    make_exercise("Hindu Push-Up", 3, "8-10", 45,
                                  "Bodyweight", "None", "Full Body", "Chest",
                                  ["Shoulders", "Triceps", "Core", "Hip Flexors"], "intermediate",
                                  "Dive bomb motion: downward dog to cobra", "Standard Push-Up"),
                    make_exercise("Push-Up Plus", 3, "10-12", 30,
                                  "Bodyweight", "None", "Back", "Serratus Anterior",
                                  ["Chest", "Triceps"], "beginner",
                                  "At top of push-up, push extra to round upper back", "Standard Push-Up"),
                    make_exercise("Pseudo Planche Push-Up", 3, "5-8", 60,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Anterior Deltoid", "Core"], "advanced",
                                  "Hands by waist, lean forward significantly", "Decline Push-Up"),
                ]
            })

        # Day 6: Test & Recovery
        if sessions >= 6:
            workouts.append({
                "workout_name": "Day 6 - Test & Mobility",
                "type": "strength",
                "duration_minutes": 20,
                "exercises": [
                    make_exercise("Max Push-Up Test", 1, "Max reps unbroken", 120,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid", "Core"], difficulty,
                                  "Record your max, compare to last test", "Knee Push-Up Test"),
                    make_exercise("Band Pull-Apart", 3, "15-20", 30,
                                  "Light", "Resistance Band", "Back", "Rear Deltoid",
                                  ["Rhomboids", "Traps"], "beginner",
                                  "Squeeze shoulder blades together", "Face Pull"),
                    make_exercise("Chest Doorway Stretch", 3, "30 seconds each side", 15,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Anterior Deltoid"], "beginner",
                                  "Arm on doorframe at 90 degrees, lean through", "Floor Chest Stretch"),
                    make_exercise("Thoracic Spine Extension", 3, "10 reps", 15,
                                  "Bodyweight", "Foam Roller", "Back", "Thoracic Erector Spinae",
                                  ["Rhomboids"], "beginner",
                                  "Foam roller at mid back, extend over it gently", "Cat-Cow"),
                    make_exercise("Wrist Circles", 3, "10 each direction", 15,
                                  "Bodyweight", "None", "Arms", "Forearm Flexors",
                                  ["Forearm Extensors"], "beginner",
                                  "Slow circles, both directions", "Wrist Stretches"),
                ]
            })

        # Day 7
        if sessions >= 7:
            workouts.append({
                "workout_name": "Day 7 - Greasing the Groove",
                "type": "endurance",
                "duration_minutes": 15,
                "exercises": [
                    make_exercise("Submaximal Push-Up Sets (Every Hour)", 5, "50% of max", 300,
                                  "Bodyweight", "None", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid"], difficulty,
                                  "Throughout the day, do 50% of your max in fresh sets", "Knee Push-Up"),
                    make_exercise("Plank Variations (30s each)", 3, "4 variations x 30s", 15,
                                  "Bodyweight", "None", "Core", "Transverse Abdominis",
                                  ["Rectus Abdominis", "Obliques"], "beginner",
                                  "Standard, side left, side right, reverse", "Kneeling Plank"),
                    make_exercise("Wall Push-Up (Warm-Up)", 2, "15-20", 15,
                                  "Bodyweight", "Wall", "Chest", "Pectoralis Major",
                                  ["Triceps", "Anterior Deltoid"], "beginner",
                                  "Easy reps to get blood flowing", "Incline Push-Up"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Learn proper form and build base' if progress <= 0.25 else 'Increase volume and variations' if progress <= 0.5 else 'Build pushing strength' if progress <= 0.75 else 'Test your max and peak'}",
            "workouts": workouts[:sessions],
        }

    return weeks


# =============================================================================
# SQUAT CHALLENGE - Lower body progression
# =============================================================================

def squat_challenge_weeks(duration, sessions):
    """Generate Squat Challenge weeks: bodyweight squat mastery."""
    weeks = {}

    for w in range(1, duration + 1):
        progress = w / duration
        if progress <= 0.25:
            phase = "Mobility & Form"
            base_reps = "10-15"
            hold_time = "20-30 seconds"
        elif progress <= 0.5:
            phase = "Volume"
            base_reps = "15-20"
            hold_time = "30-45 seconds"
        elif progress <= 0.75:
            phase = "Strength"
            base_reps = "20-30"
            hold_time = "45-60 seconds"
        else:
            phase = "Peak"
            base_reps = "30-50"
            hold_time = "60 seconds"

        workouts = []

        # Day 1: Standard Squats + Mobility
        workouts.append({
            "workout_name": "Day 1 - Squat Foundation",
            "type": "strength",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Bodyweight Squat", 5, base_reps, 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings", "Core"], "beginner",
                              "Sit back and down, chest up, knees track toes", "Assisted Squat"),
                make_exercise("Wall Sit", 3, hold_time, 30,
                              "Bodyweight", "Wall", "Legs", "Quadriceps",
                              ["Glutes", "Core"], "beginner",
                              "Back flat on wall, thighs parallel to floor", "Chair Squat"),
                make_exercise("Calf Raise", 3, "15-20", 30,
                              "Bodyweight", "None", "Legs", "Calves",
                              ["Soleus"], "beginner",
                              "Full range, squeeze at top", "Seated Calf Raise"),
                make_exercise("Glute Bridge", 3, "15-20", 30,
                              "Bodyweight", "None", "Legs", "Glutes",
                              ["Hamstrings", "Core"], "beginner",
                              "Drive through heels, squeeze glutes at top", "Hip Thrust"),
                make_exercise("Ankle Mobility Circles", 3, "10 each direction", 15,
                              "Bodyweight", "None", "Legs", "Tibialis Anterior",
                              ["Calves"], "beginner",
                              "Slow controlled circles, improve ankle dorsiflexion", "Calf Stretch"),
            ]
        })

        # Day 2: Squat Variations
        workouts.append({
            "workout_name": "Day 2 - Squat Variations",
            "type": "hypertrophy",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Sumo Squat", 4, base_reps, 45,
                              "Bodyweight", "None", "Legs", "Adductors",
                              ["Glutes", "Quadriceps"], "beginner",
                              "Wide stance, toes out 45 degrees, push knees out", "Standard Squat"),
                make_exercise("Narrow Squat", 4, base_reps, 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Core"], "beginner",
                              "Feet together, knees track forward", "Standard Squat"),
                make_exercise("Pulse Squat", 3, "15-20", 30,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Small bounces at bottom of squat", "Standard Squat"),
                make_exercise("1.5 Rep Squat", 3, "8-12", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "intermediate",
                              "Squat down, come halfway up, back down, full up = 1 rep", "Standard Squat"),
                make_exercise("Split Squat", 3, "10-12 each leg", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Staggered stance, lower back knee toward floor", "Reverse Lunge"),
            ]
        })

        # Day 3: Lunge & Single Leg
        workouts.append({
            "workout_name": "Day 3 - Lunge Day",
            "type": "strength",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Forward Lunge", 4, "10-12 each leg", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Long stride, back knee near floor", "Reverse Lunge"),
                make_exercise("Reverse Lunge", 3, "10-12 each leg", 45,
                              "Bodyweight", "None", "Legs", "Glutes",
                              ["Quadriceps", "Hamstrings"], "beginner",
                              "Step back, front knee at 90 degrees", "Forward Lunge"),
                make_exercise("Lateral Lunge", 3, "10-12 each leg", 45,
                              "Bodyweight", "None", "Legs", "Adductors",
                              ["Glutes", "Quadriceps"], "beginner",
                              "Wide step to side, push hips back", "Cossack Squat"),
                make_exercise("Step-Up", 3, "10-12 each leg", 45,
                              "Bodyweight", "Step/Bench", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings"], "beginner",
                              "Drive through heel, full extension at top", "Reverse Lunge"),
                make_exercise("Single-Leg Glute Bridge", 3, "10-12 each leg", 30,
                              "Bodyweight", "None", "Legs", "Glutes",
                              ["Hamstrings", "Core"], "beginner",
                              "One leg extended, drive hips up with planted leg", "Two-Leg Glute Bridge"),
            ]
        })

        # Day 4: Plyometric Squats
        workouts.append({
            "workout_name": "Day 4 - Explosive Legs",
            "type": "circuit",
            "duration_minutes": 25,
            "exercises": [
                make_exercise("Squat Jump", 4, "10-15", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Calves", "Core"], "intermediate",
                              "Deep squat, explode up, soft landing", "Standard Squat"),
                make_exercise("Jump Lunge", 3, "8-10 each leg", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings", "Calves"], "intermediate",
                              "Switch legs mid-air, soft landing", "Reverse Lunge"),
                make_exercise("Broad Jump", 3, "6-8", 60,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Hamstrings", "Calves"], "intermediate",
                              "Swing arms, jump forward for max distance", "Squat Jump"),
                make_exercise("Speed Squat", 3, "20-30 in 30 seconds", 45,
                              "Bodyweight", "None", "Legs", "Quadriceps",
                              ["Glutes", "Core"], "intermediate",
                              "Fast partial squats for speed", "Pulse Squat"),
                make_exercise("Skater Jump", 3, "10-12 each side", 30,
                              "Bodyweight", "None", "Legs", "Glute Medius",
                              ["Quadriceps", "Calves"], "intermediate",
                              "Lateral bound, land softly on one leg", "Lateral Lunge"),
            ]
        })

        # Day 5: Isometric / Hold
        if sessions >= 5:
            workouts.append({
                "workout_name": "Day 5 - Isometric Legs",
                "type": "strength",
                "duration_minutes": 25,
                "exercises": [
                    make_exercise("Wall Sit", 4, hold_time, 45,
                                  "Bodyweight", "Wall", "Legs", "Quadriceps",
                                  ["Glutes", "Core"], "beginner",
                                  "Thighs parallel, hold for time", "Chair Squat Hold"),
                    make_exercise("Single-Leg Wall Sit", 3, "15-20 seconds each leg", 30,
                                  "Bodyweight", "Wall", "Legs", "Quadriceps",
                                  ["Core", "Glutes"], "intermediate",
                                  "Extend one leg, hold other at 90 degrees", "Two-Leg Wall Sit"),
                    make_exercise("Squat Hold (Bottom Position)", 3, "20-30 seconds", 30,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Adductors", "Core"], "beginner",
                                  "Deep squat, chest up, hold position", "Wall Sit"),
                    make_exercise("Lunge Hold", 3, "20-30 seconds each leg", 30,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Hip Flexors"], "beginner",
                                  "Bottom of lunge position, hold steady", "Static Split Squat"),
                    make_exercise("Tempo Squat (4-2-4)", 3, "8-10", 45,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Hamstrings"], "intermediate",
                                  "4 sec down, 2 sec hold, 4 sec up", "Standard Squat"),
                ]
            })

        # Day 6: Total Volume
        if sessions >= 6:
            workouts.append({
                "workout_name": "Day 6 - Volume Ladder",
                "type": "endurance",
                "duration_minutes": 25,
                "exercises": [
                    make_exercise("Squat Ladder (1 to 10)", 1, "1+2+3+...+10 = 55 total", 30,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Glutes", "Hamstrings"], "beginner",
                                  "1 squat, rest, 2 squats, rest... up to 10", "Standard Squat"),
                    make_exercise("Bulgarian Split Squat", 3, "8-10 each leg", 60,
                                  "Bodyweight", "Bench", "Legs", "Quadriceps",
                                  ["Glutes", "Hamstrings"], "intermediate",
                                  "Rear foot on bench, lower until thigh parallel", "Reverse Lunge"),
                    make_exercise("Curtsy Lunge", 3, "10-12 each side", 30,
                                  "Bodyweight", "None", "Legs", "Glute Medius",
                                  ["Quadriceps", "Adductors"], "beginner",
                                  "Step behind and across, like a curtsy", "Reverse Lunge"),
                    make_exercise("Cossack Squat", 3, "6-8 each side", 45,
                                  "Bodyweight", "None", "Legs", "Adductors",
                                  ["Quadriceps", "Hamstrings", "Glutes"], "intermediate",
                                  "Wide stance, shift weight fully to one side", "Lateral Lunge"),
                    make_exercise("Sissy Squat", 3, "6-10", 45,
                                  "Bodyweight", "None", "Legs", "Quadriceps",
                                  ["Core"], "intermediate",
                                  "Lean back, knees forward, hold support if needed", "Leg Extension"),
                ]
            })

        # Day 7
        if sessions >= 7:
            workouts.append({
                "workout_name": "Day 7 - Lower Body Mobility",
                "type": "flexibility",
                "duration_minutes": 15,
                "exercises": [
                    make_exercise("Deep Squat Hold", 3, "30-60 seconds", 15,
                                  "Bodyweight", "None", "Legs", "Adductors",
                                  ["Hip Flexors", "Ankles"], "beginner",
                                  "Third world squat, chest up, heels down", "Assisted Squat Hold"),
                    make_exercise("Pigeon Stretch", 3, "30 seconds each side", 15,
                                  "Bodyweight", "None", "Legs", "Glutes",
                                  ["Hip Flexors"], "beginner",
                                  "Front shin across body, back leg extended", "Figure-4 Stretch"),
                    make_exercise("Hip Flexor Stretch (Couch Stretch)", 3, "30 seconds each side", 15,
                                  "Bodyweight", "None", "Legs", "Hip Flexors",
                                  ["Quadriceps"], "beginner",
                                  "Back foot on wall/couch, squeeze glute", "Kneeling Hip Flexor Stretch"),
                    make_exercise("Standing Hamstring Stretch", 3, "30 seconds each leg", 15,
                                  "Bodyweight", "None", "Legs", "Hamstrings",
                                  ["Calves"], "beginner",
                                  "Foot on elevated surface, hinge forward", "Seated Hamstring Stretch"),
                ]
            })

        weeks[w] = {
            "focus": f"{phase} - Week {w}: {'Build squat form and mobility' if progress <= 0.25 else 'Increase rep volume' if progress <= 0.5 else 'Develop leg strength' if progress <= 0.75 else 'Peak and test your max'}",
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
            "name": "30-Day Ab Challenge",
            "category": "Challenges",
            "description": "Progressive core challenge from basic crunches to advanced dragon flags. Build visible abs with daily targeted core work focusing on lower abs, upper abs, obliques, and anti-extension.",
            "durations": [1, 2, 4],
            "sessions": [6, 7],
            "has_supersets": True,
            "priority": "High",
            "generator": ab_challenge_weeks,
        },
        {
            "name": "Push-up Progression",
            "category": "Challenges",
            "description": "Go from zero to 50+ push-ups with daily progressive training. Includes variations, plyometrics, density work, and weekly max tests to track your improvement.",
            "durations": [1, 2, 4],
            "sessions": [6, 7],
            "has_supersets": False,
            "priority": "High",
            "generator": pushup_challenge_weeks,
        },
        {
            "name": "Squat Challenge",
            "category": "Challenges",
            "description": "Build lower body strength and endurance through bodyweight squat mastery. Progress from basic squats to advanced single-leg variations with plyometrics and isometrics.",
            "durations": [1, 2, 4],
            "sessions": [6, 7],
            "has_supersets": False,
            "priority": "High",
            "generator": squat_challenge_weeks,
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
    print(f"Challenges HIGH priority complete: {success_count} OK, {fail_count} FAIL")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
