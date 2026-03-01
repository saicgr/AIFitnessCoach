#!/usr/bin/env python3
"""
Generate Women's Health HIGH priority programs (Category 10).
Programs: Kegel & Pelvic Floor, Hormone Balance Workout, PCOS Workout Plan,
          Women's Strength Basics, Women's Self-Defense
"""
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent))
from program_sql_helper import ProgramSQLHelper


def generate_kegel_pelvic_floor(helper: ProgramSQLHelper, migration_start: int):
    """Kegel & Pelvic Floor - 1,2,4,8w x 7/wk - Pelvic strength."""

    def make_exercise(name, sets, reps, rest, guidance, body_part, primary, secondary, difficulty, cue, sub, equipment="None"):
        return {
            "name": name,
            "exercise_library_id": None,
            "in_library": False,
            "sets": sets,
            "reps": reps,
            "rest_seconds": rest,
            "weight_guidance": guidance,
            "equipment": equipment,
            "body_part": body_part,
            "primary_muscle": primary,
            "secondary_muscles": secondary,
            "difficulty": difficulty,
            "form_cue": cue,
            "substitution": sub,
        }

    weeks_data = {}

    # --- 1 week x 7/wk ---
    weeks_data[(1, 7)] = {
        1: {
            "focus": "Pelvic floor activation and awareness",
            "workouts": [
                {
                    "workout_name": "Day 1 - Kegel Foundations",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Quick Flick Kegels", 3, 10, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Quick squeeze and release, 1 second each", "Elevator Kegels"),
                        make_exercise("Slow Hold Kegels", 3, 8, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "Squeeze and hold 5 seconds, relax 5 seconds", "Bridge Hold"),
                        make_exercise("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Transverse Abdominis", "Pelvic Floor Muscles"], "beginner", "Inhale belly expands, exhale gently engage pelvic floor", "Box Breathing"),
                        make_exercise("Supine Pelvic Tilts", 3, 12, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles", "Rectus Abdominis"], "beginner", "Flatten lower back to floor by tilting pelvis", "Standing Pelvic Tilt"),
                        make_exercise("Bridge with Kegel", 3, 10, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "beginner", "Squeeze pelvic floor at top of bridge", "Wall Sit with Kegel"),
                    ],
                },
                {
                    "workout_name": "Day 2 - Pelvic Floor Endurance",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Endurance Kegels", 3, 5, 20, "Bodyweight - hold 10 sec each", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Hold squeeze for 10 seconds, rest 10 seconds", "Slow Hold Kegels"),
                        make_exercise("Elevator Kegels", 3, 8, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "Gradually increase squeeze intensity floor by floor, then release slowly", "Slow Hold Kegels"),
                        make_exercise("Cat-Cow with Pelvic Floor", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae", "Pelvic Floor Muscles"], "beginner", "Engage pelvic floor on cow, release on cat", "Seated Pelvic Tilts"),
                        make_exercise("Bird Dog Hold", 3, 8, 20, "Bodyweight - hold 5 sec per side", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Extend opposite arm and leg, keep hips level", "Dead Bug"),
                        make_exercise("Side-Lying Clamshell", 3, 12, 15, "Bodyweight", "Hips", "Gluteus Medius", ["Pelvic Floor Muscles", "Hip External Rotators"], "beginner", "Keep feet together, open knees like a clamshell", "Seated Hip Abduction"),
                    ],
                },
                {
                    "workout_name": "Day 3 - Core-Pelvic Integration",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Quick Flick Kegels", 4, 12, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Quick squeeze and release", "Elevator Kegels"),
                        make_exercise("Dead Bug", 3, 8, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor Muscles"], "beginner", "Lower opposite arm and leg while keeping back flat", "Bird Dog"),
                        make_exercise("Heel Slides", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors", "Pelvic Floor Muscles"], "beginner", "Slide heel along floor while maintaining neutral spine", "Toe Taps"),
                        make_exercise("Wall Sit with Kegel", 3, 6, 30, "Bodyweight - hold 15 sec", "Legs", "Quadriceps", ["Pelvic Floor Muscles", "Gluteus Maximus"], "beginner", "Hold wall sit position while engaging pelvic floor", "Chair Sit Kegel"),
                        make_exercise("Supine Marching", 3, 12, 15, "Bodyweight", "Core", "Hip Flexors", ["Transverse Abdominis", "Pelvic Floor Muscles"], "beginner", "Alternate lifting knees while keeping core engaged", "Heel Slides"),
                    ],
                },
                {
                    "workout_name": "Day 4 - Relaxation & Release",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Diaphragmatic Breathing", 4, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Focus on complete relaxation of pelvic floor on inhale", "Box Breathing"),
                        make_exercise("Happy Baby Stretch", 3, 6, 20, "Bodyweight - hold 20 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles", "Hamstrings"], "beginner", "Grab feet, gently pull knees toward armpits", "Reclined Butterfly"),
                        make_exercise("Child's Pose with Breathing", 3, 5, 20, "Bodyweight - hold 30 sec", "Back", "Erector Spinae", ["Latissimus Dorsi", "Pelvic Floor Muscles"], "beginner", "Breathe into lower back, feel pelvic floor expand on inhale", "Cat Stretch"),
                        make_exercise("Reclined Butterfly", 3, 5, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Soles together, knees fall open, breathe deeply", "Happy Baby Stretch"),
                        make_exercise("Slow Hold Kegels", 3, 8, 20, "Bodyweight - hold 8 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Gentle squeeze, focus on full relaxation between reps", "Elevator Kegels"),
                    ],
                },
                {
                    "workout_name": "Day 5 - Strength Integration",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Bridge with Kegel Hold", 3, 10, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "beginner", "Hold bridge top, pulse kegel 3 times per rep", "Wall Sit Kegel"),
                        make_exercise("Squat with Kegel", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "beginner", "Engage pelvic floor as you stand up from squat", "Wall Sit"),
                        make_exercise("Side-Lying Leg Lift with Kegel", 3, 10, 15, "Bodyweight", "Hips", "Gluteus Medius", ["Pelvic Floor Muscles"], "beginner", "Engage pelvic floor as you lift top leg", "Clamshell"),
                        make_exercise("Standing Pelvic Tilts", 3, 12, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Tilt pelvis forward and back while standing", "Supine Pelvic Tilts"),
                        make_exercise("Endurance Kegels", 3, 6, 20, "Bodyweight - hold 10 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "Hold strong squeeze for 10 sec, full release 10 sec", "Slow Hold Kegels"),
                    ],
                },
                {
                    "workout_name": "Day 6 - Coordination & Control",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Elevator Kegels", 4, 8, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "5 floors up slowly, 5 floors down slowly", "Slow Hold Kegels"),
                        make_exercise("Bird Dog with Kegel", 3, 8, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae", "Pelvic Floor Muscles"], "beginner", "Engage pelvic floor as you extend limbs", "Dead Bug with Kegel"),
                        make_exercise("Clamshell", 3, 12, 15, "Bodyweight", "Hips", "Gluteus Medius", ["Pelvic Floor Muscles", "Hip External Rotators"], "beginner", "Coordinate kegel with each clamshell opening", "Side Lying Leg Lift"),
                        make_exercise("Toe Taps", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors", "Pelvic Floor Muscles"], "beginner", "Alternate tapping toes to floor from tabletop", "Heel Slides"),
                        make_exercise("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae", "Pelvic Floor Muscles"], "beginner", "Sync breath and pelvic floor with movement", "Seated Spinal Flexion"),
                    ],
                },
                {
                    "workout_name": "Day 7 - Active Recovery & Stretch",
                    "type": "pelvic_floor",
                    "exercises": [
                        make_exercise("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Complete relaxation focus", "Box Breathing"),
                        make_exercise("Happy Baby Stretch", 3, 5, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Gentle rocking side to side", "Reclined Butterfly"),
                        make_exercise("Child's Pose", 3, 5, 20, "Bodyweight - hold 30 sec", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Wide knees, breathe into lower back", "Cat Stretch"),
                        make_exercise("Gentle Pelvic Tilts", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Very gentle, focus on awareness not strength", "Seated Pelvic Tilts"),
                        make_exercise("Slow Hold Kegels", 2, 6, 20, "Bodyweight - hold 5 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Light engagement only, recovery day", "Diaphragmatic Breathing"),
                    ],
                },
            ],
        },
    }

    # --- 2 week x 7/wk (week 1 same as above, week 2 progressed) ---
    weeks_data[(2, 7)] = dict(weeks_data[(1, 7)])
    weeks_data[(2, 7)][2] = {
        "focus": "Increased hold times and functional integration",
        "workouts": [
            {
                "workout_name": "Day 1 - Progressive Kegels",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Quick Flick Kegels", 4, 15, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Rapid squeeze-release, build speed", "Elevator Kegels"),
                    make_exercise("Endurance Kegels", 4, 6, 20, "Bodyweight - hold 15 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "beginner", "Longer holds, aim for consistent strength", "Slow Hold Kegels"),
                    make_exercise("Bridge March with Kegel", 3, 10, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "intermediate", "Hold bridge, alternate lifting feet while engaging PF", "Bridge with Kegel"),
                    make_exercise("Dead Bug", 3, 10, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor Muscles"], "beginner", "Coordinate breathing with pelvic floor engagement", "Bird Dog"),
                    make_exercise("Single Leg Bridge with Kegel", 3, 8, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "intermediate", "One leg extended, engage PF at top", "Double Leg Bridge"),
                ],
            },
            {
                "workout_name": "Day 2 - Functional Pelvic Floor",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Elevator Kegels", 4, 10, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "5 floors up, hold top 5 sec, 5 floors down", "Slow Hold Kegels"),
                    make_exercise("Squat with Kegel", 3, 12, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "beginner", "Full engagement on the way up", "Wall Sit Kegel"),
                    make_exercise("Lunge with Pelvic Floor", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Engage PF as you push back up", "Split Squat"),
                    make_exercise("Side Plank Hip Dip", 3, 8, 20, "Bodyweight", "Core", "Obliques", ["Transverse Abdominis", "Pelvic Floor Muscles"], "intermediate", "Maintain PF engagement throughout", "Side Lying Leg Lift"),
                    make_exercise("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Cool down, full relaxation", "Box Breathing"),
                ],
            },
            {
                "workout_name": "Day 3 - Core & Pelvic Power",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Quick Flick Kegels", 4, 15, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Speed focus", "Elevator Kegels"),
                    make_exercise("Bird Dog with Kegel", 3, 10, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae", "Pelvic Floor Muscles"], "beginner", "Hold 3 sec at extension", "Dead Bug"),
                    make_exercise("Glute Bridge Pulse", 3, 15, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles"], "beginner", "Small pulses at top with PF engaged", "Bridge Hold"),
                    make_exercise("Standing March with Kegel", 3, 12, 15, "Bodyweight", "Core", "Hip Flexors", ["Pelvic Floor Muscles", "Transverse Abdominis"], "beginner", "High knees standing, engage PF each lift", "Supine Marching"),
                    make_exercise("Supine Pelvic Tilts", 3, 12, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Deeper engagement, hold 3 sec", "Standing Pelvic Tilt"),
                ],
            },
            {
                "workout_name": "Day 4 - Relaxation & Mobility",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Diaphragmatic Breathing", 4, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "360-degree rib expansion", "Box Breathing"),
                    make_exercise("Happy Baby Stretch", 3, 6, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Rock gently, breathe into pelvic floor", "Reclined Butterfly"),
                    make_exercise("Deep Squat Hold", 3, 5, 20, "Bodyweight - hold 20 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles", "Gluteus Maximus"], "beginner", "Feet wide, breathe and relax PF", "Wall Sit"),
                    make_exercise("Pigeon Stretch", 3, 4, 20, "Bodyweight - hold 30 sec per side", "Hips", "Hip Flexors", ["Gluteus Maximus", "Piriformis"], "beginner", "Breathe deeply, let tension release", "Figure 4 Stretch"),
                    make_exercise("Child's Pose Wide", 3, 5, 20, "Bodyweight - hold 30 sec", "Back", "Erector Spinae", ["Latissimus Dorsi", "Pelvic Floor Muscles"], "beginner", "Knees wide, belly between thighs", "Cat Stretch"),
                ],
            },
            {
                "workout_name": "Day 5 - Strength & Endurance",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Endurance Kegels", 4, 6, 20, "Bodyweight - hold 15 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "Aim for consistent strength throughout hold", "Slow Hold Kegels"),
                    make_exercise("Single Leg Bridge", 3, 8, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "intermediate", "PF engaged throughout", "Double Leg Bridge"),
                    make_exercise("Clamshell with Band", 3, 12, 15, "Light resistance band", "Hips", "Gluteus Medius", ["Pelvic Floor Muscles", "Hip External Rotators"], "intermediate", "Coordinate PF with hip opening", "Clamshell"),
                    make_exercise("Plank with Kegel", 3, 6, 20, "Bodyweight - hold 15 sec", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor Muscles"], "intermediate", "Hold plank, pulse kegel", "Modified Plank"),
                    make_exercise("Wall Sit Kegel Pulse", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Pelvic Floor Muscles", "Gluteus Maximus"], "intermediate", "Wall sit with kegel pulses", "Chair Sit Kegel"),
                ],
            },
            {
                "workout_name": "Day 6 - Coordination Challenge",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Elevator Kegels", 4, 10, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "10 floors, very slow ascent and descent", "Slow Hold Kegels"),
                    make_exercise("Bear Crawl Hold with Kegel", 3, 6, 20, "Bodyweight - hold 15 sec", "Core", "Transverse Abdominis", ["Shoulders", "Pelvic Floor Muscles"], "intermediate", "Knees hover 1 inch, engage PF", "Bird Dog"),
                    make_exercise("Dead Bug Alternating", 3, 10, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor Muscles"], "intermediate", "Opposite arm and leg extension", "Bird Dog"),
                    make_exercise("Step Up with Kegel", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Engage PF as you step up", "Squat with Kegel"),
                    make_exercise("Slow Hold Kegels", 3, 8, 20, "Bodyweight - hold 10 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "intermediate", "Maximum quality squeeze", "Endurance Kegels"),
                ],
            },
            {
                "workout_name": "Day 7 - Active Recovery",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Diaphragmatic Breathing", 4, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Complete relaxation, no effort", "Box Breathing"),
                    make_exercise("Reclined Butterfly", 3, 5, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Gentle opening, full breath", "Happy Baby Stretch"),
                    make_exercise("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle flow, no kegel engagement", "Seated Spinal Flexion"),
                    make_exercise("Gentle Pelvic Circles", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Standing, circle hips gently", "Seated Pelvic Tilts"),
                    make_exercise("Slow Hold Kegels", 2, 5, 20, "Bodyweight - hold 5 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Very light, recovery day", "Diaphragmatic Breathing"),
                ],
            },
        ],
    }

    # --- 4 week x 7/wk: weeks 1-2 from 2-week variant, weeks 3-4 progressed ---
    weeks_data[(4, 7)] = dict(weeks_data[(2, 7)])
    weeks_data[(4, 7)][3] = {
        "focus": "Advanced holds and dynamic integration",
        "workouts": [
            {
                "workout_name": "Day 1 - Power Kegels",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Quick Flick Kegels", 5, 20, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "intermediate", "Maximum speed and precision", "Elevator Kegels"),
                    make_exercise("Endurance Kegels", 4, 6, 20, "Bodyweight - hold 20 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "20-second holds with full relaxation between", "Slow Hold Kegels"),
                    make_exercise("Sumo Squat with Kegel", 3, 12, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Hip Adductors", "Pelvic Floor Muscles"], "intermediate", "Wide stance, engage PF on ascent", "Bodyweight Squat"),
                    make_exercise("Single Leg Deadlift", 3, 10, 20, "Bodyweight", "Legs", "Hamstrings", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Balance challenge with PF engagement", "Romanian Deadlift"),
                    make_exercise("Plank Shoulder Tap with Kegel", 3, 10, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Deltoids", "Pelvic Floor Muscles"], "intermediate", "Tap opposite shoulder, maintain PF", "Modified Plank"),
                ],
            },
            {
                "workout_name": "Day 2 - Dynamic Pelvic Floor",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Elevator Kegels Advanced", 4, 8, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "10 floors up, hold top 10 sec, 10 floors down", "Endurance Kegels"),
                    make_exercise("Jump Squat Kegel", 3, 8, 25, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Engage PF before and during landing", "Squat with Kegel"),
                    make_exercise("Lateral Lunge with Kegel", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Pelvic Floor Muscles"], "intermediate", "Engage PF as you push back to center", "Reverse Lunge"),
                    make_exercise("Mountain Climber Slow", 3, 12, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Hip Flexors", "Pelvic Floor Muscles"], "intermediate", "Slow, controlled, PF engaged throughout", "Dead Bug"),
                    make_exercise("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Cool down", "Box Breathing"),
                ],
            },
            {
                "workout_name": "Day 3 - Strength Complex",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Quick Flick Kegels", 4, 20, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "intermediate", "Speed intervals: 10 fast, 10 slow", "Elevator Kegels"),
                    make_exercise("Bulgarian Split Squat", 3, 10, 20, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Rear foot elevated, PF on ascent", "Reverse Lunge"),
                    make_exercise("Hip Thrust", 3, 12, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "intermediate", "Full extension with PF squeeze", "Glute Bridge"),
                    make_exercise("Side Plank with Leg Lift", 3, 8, 20, "Bodyweight", "Core", "Obliques", ["Gluteus Medius", "Pelvic Floor Muscles"], "intermediate", "Hold side plank, lift top leg", "Side Plank Hold"),
                    make_exercise("Bear Crawl Forward/Back", 3, 8, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Shoulders", "Pelvic Floor Muscles"], "intermediate", "Knees hover, crawl with PF engaged", "Bear Crawl Hold"),
                ],
            },
            {
                "workout_name": "Day 4 - Recovery & Mobility",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Diaphragmatic Breathing", 4, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Inhale 4, hold 4, exhale 6", "Box Breathing"),
                    make_exercise("Deep Squat Hold", 3, 5, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Full relaxation in deep squat", "Wall Sit"),
                    make_exercise("90/90 Hip Switch", 3, 8, 20, "Bodyweight", "Hips", "Hip Rotators", ["Gluteus Medius", "Pelvic Floor Muscles"], "intermediate", "Switch legs maintaining upright posture", "Seated Hip Stretch"),
                    make_exercise("Pigeon Stretch", 3, 4, 20, "Bodyweight - hold 30 sec per side", "Hips", "Hip Flexors", ["Gluteus Maximus"], "beginner", "Deep breathing, full release", "Figure 4 Stretch"),
                    make_exercise("Supine Spinal Twist", 3, 4, 20, "Bodyweight - hold 30 sec per side", "Back", "Obliques", ["Erector Spinae"], "beginner", "Arms wide, knees drop to one side", "Seated Twist"),
                ],
            },
            {
                "workout_name": "Day 5 - Peak Performance",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Endurance Kegels", 4, 5, 25, "Bodyweight - hold 25 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "Maximum duration holds", "Slow Hold Kegels"),
                    make_exercise("Pistol Squat Progression", 3, 6, 25, "Bodyweight", "Legs", "Quadriceps", ["Gluteus Maximus", "Pelvic Floor Muscles"], "intermediate", "Assisted single leg squat with PF", "Single Leg Squat to Bench"),
                    make_exercise("Curtsy Lunge with Kegel", 3, 10, 20, "Bodyweight", "Legs", "Gluteus Maximus", ["Gluteus Medius", "Pelvic Floor Muscles"], "intermediate", "Cross behind, engage PF on return", "Reverse Lunge"),
                    make_exercise("Pallof Press Hold", 3, 8, 20, "Resistance Band", "Core", "Transverse Abdominis", ["Obliques", "Pelvic Floor Muscles"], "intermediate", "Resist rotation with PF engaged", "Bird Dog", "Resistance Band"),
                    make_exercise("Glute Bridge March", 3, 12, 20, "Bodyweight", "Glutes", "Gluteus Maximus", ["Pelvic Floor Muscles", "Hamstrings"], "intermediate", "Hold bridge, alternate lifting feet", "Glute Bridge"),
                ],
            },
            {
                "workout_name": "Day 6 - Full Body Integration",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Elevator Kegels", 4, 10, 20, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Deep Core"], "intermediate", "Full range, smooth control", "Slow Hold Kegels"),
                    make_exercise("Squat to Calf Raise", 3, 12, 20, "Bodyweight", "Legs", "Quadriceps", ["Calves", "Pelvic Floor Muscles"], "intermediate", "PF engaged through entire sequence", "Bodyweight Squat"),
                    make_exercise("Inchworm", 3, 8, 20, "Bodyweight", "Core", "Transverse Abdominis", ["Hamstrings", "Shoulders"], "intermediate", "Walk hands out and back", "Walkout"),
                    make_exercise("Cossack Squat", 3, 8, 20, "Bodyweight", "Legs", "Hip Adductors", ["Quadriceps", "Pelvic Floor Muscles"], "intermediate", "Side to side deep squat", "Lateral Lunge"),
                    make_exercise("Quick Flick Kegels", 4, 20, 15, "Bodyweight", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "intermediate", "Finish strong with speed work", "Elevator Kegels"),
                ],
            },
            {
                "workout_name": "Day 7 - Active Recovery",
                "type": "pelvic_floor",
                "exercises": [
                    make_exercise("Diaphragmatic Breathing", 4, 10, 15, "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Full body relaxation scan", "Box Breathing"),
                    make_exercise("Happy Baby Stretch", 3, 5, 20, "Bodyweight - hold 30 sec", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Gentle rocking", "Reclined Butterfly"),
                    make_exercise("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Flowing movement", "Seated Spinal Flexion"),
                    make_exercise("Gentle Pelvic Circles", 3, 10, 15, "Bodyweight", "Core", "Transverse Abdominis", ["Pelvic Floor Muscles"], "beginner", "Large circles, both directions", "Seated Pelvic Tilts"),
                    make_exercise("Slow Hold Kegels", 2, 5, 20, "Bodyweight - hold 5 sec", "Pelvic Floor", "Pelvic Floor Muscles", ["Transverse Abdominis"], "beginner", "Minimum intensity, awareness only", "Diaphragmatic Breathing"),
                ],
            },
        ],
    }

    # --- 4 week: week 4 same as week 3 with slight description change ---
    weeks_data[(4, 7)][4] = {
        "focus": "Mastery and automaticity of pelvic floor control",
        "workouts": weeks_data[(4, 7)][3]["workouts"],  # same exercises, higher mastery
    }

    # --- 8 week x 7/wk: build on 4-week ---
    weeks_data[(8, 7)] = dict(weeks_data[(4, 7)])
    for wk in [5, 6]:
        weeks_data[(8, 7)][wk] = {
            "focus": "Functional strength with pelvic floor under load",
            "workouts": weeks_data[(4, 7)][3]["workouts"],
        }
    for wk in [7, 8]:
        weeks_data[(8, 7)][wk] = {
            "focus": "Peak pelvic floor endurance and automaticity",
            "workouts": weeks_data[(4, 7)][3]["workouts"],
        }

    result = helper.insert_full_program(
        program_name="Kegel & Pelvic Floor",
        category_name="Women's Health",
        description="Comprehensive pelvic floor strengthening program. Builds awareness, strength, endurance and functional integration of pelvic floor muscles through progressive kegel exercises and core training.",
        durations=[1, 2, 4, 8],
        sessions_per_week=[7],
        has_supersets=False,
        priority="high",
        weeks_data=weeks_data,
        migration_num=migration_start,
    )
    return result


def generate_hormone_balance(helper: ProgramSQLHelper, migration_num: int):
    """Hormone Balance Workout - 4,8,12w x 4-5/wk - Cycle-synced training."""

    def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
        return {
            "name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": guidance, "equipment": equip,
            "body_part": body, "primary_muscle": primary,
            "secondary_muscles": secondary, "difficulty": diff,
            "form_cue": cue, "substitution": sub,
        }

    weeks_data = {}

    # Menstrual phase (Week 1 pattern): Low intensity, mobility, light movement
    menstrual_workouts = [
        {
            "workout_name": "Day 1 - Gentle Flow",
            "type": "mobility",
            "exercises": [
                ex("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle spinal mobilization", "Seated Spinal Flexion"),
                ex("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Deep belly breaths", "Box Breathing"),
                ex("Wall Yoga Squat", 3, 8, 20, "Bodyweight", "None", "Legs", "Quadriceps", ["Hip Adductors"], "beginner", "Supported deep squat against wall", "Bodyweight Squat"),
                ex("Seated Forward Fold", 3, 5, 20, "Bodyweight - hold 30 sec", "None", "Back", "Hamstrings", ["Erector Spinae"], "beginner", "Relax into stretch", "Standing Toe Touch"),
                ex("Side-Lying Clamshell", 3, 12, 15, "Bodyweight", "None", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Gentle hip opening", "Lateral Band Walk"),
                ex("Child's Pose", 3, 5, 20, "Bodyweight - hold 30 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Wide knees, relax", "Cat Stretch"),
            ],
        },
        {
            "workout_name": "Day 2 - Light Strength",
            "type": "strength",
            "exercises": [
                ex("Glute Bridge", 3, 12, 20, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, slow lower", "Hip Thrust"),
                ex("Wall Push-Up", 3, 12, 15, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Lean into wall, push back", "Incline Push-Up"),
                ex("Bird Dog", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Opposite arm and leg", "Dead Bug"),
                ex("Bodyweight Squat", 3, 10, 20, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Slow and controlled", "Wall Sit"),
                ex("Band Pull-Apart", 3, 12, 15, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Squeeze shoulder blades together", "Prone Y Raise"),
                ex("Gentle Walking", 1, 1, 0, "10-15 minutes", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Easy pace, stress reduction", "Gentle Cycling"),
            ],
        },
        {
            "workout_name": "Day 3 - Yoga & Mobility",
            "type": "flexibility",
            "exercises": [
                ex("Sun Salutation Modified", 3, 5, 15, "Bodyweight", "None", "Full Body", "Full Body", ["Core", "Shoulders"], "beginner", "Flow through each position", "Cat-Cow Flow"),
                ex("Pigeon Stretch", 3, 4, 20, "Bodyweight - hold 30 sec/side", "None", "Hips", "Hip Flexors", ["Gluteus Maximus"], "beginner", "Breathe into stretch", "Figure 4 Stretch"),
                ex("Thread the Needle", 3, 8, 15, "Bodyweight", "None", "Back", "Thoracic Spine", ["Rhomboids", "Obliques"], "beginner", "Rotate thoracic spine", "Seated Twist"),
                ex("Supine Spinal Twist", 3, 4, 20, "Bodyweight - hold 30 sec/side", "None", "Back", "Obliques", ["Erector Spinae"], "beginner", "Let gravity pull knees down", "Seated Twist"),
                ex("Happy Baby", 3, 5, 20, "Bodyweight - hold 30 sec", "None", "Hips", "Hip Adductors", ["Pelvic Floor Muscles"], "beginner", "Gentle rocking", "Reclined Butterfly"),
                ex("Legs Up Wall", 1, 1, 0, "5 minutes", "None", "Recovery", "Circulatory System", ["Hamstrings"], "beginner", "Legs elevated, full relaxation", "Reclined Position"),
            ],
        },
        {
            "workout_name": "Day 4 - Walking & Stretching",
            "type": "cardio",
            "exercises": [
                ex("Brisk Walking", 1, 1, 0, "20 minutes moderate pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Maintain conversational pace", "Light Cycling"),
                ex("Hip Circles", 3, 10, 15, "Bodyweight", "None", "Hips", "Hip Flexors", ["Hip Adductors", "Gluteus Medius"], "beginner", "Large circles both directions", "Pelvic Circles"),
                ex("Standing Calf Stretch", 3, 4, 15, "Bodyweight - hold 20 sec/side", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Back heel flat, lean forward", "Seated Calf Stretch"),
                ex("Standing Quad Stretch", 3, 4, 15, "Bodyweight - hold 20 sec/side", "None", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel toward glute", "Prone Quad Stretch"),
                ex("Chest Opener Stretch", 3, 4, 15, "Bodyweight - hold 20 sec", "None", "Chest", "Pectoralis Major", ["Anterior Deltoid"], "beginner", "Arms back, chest forward", "Doorway Stretch"),
                ex("Neck Rolls", 3, 8, 15, "Bodyweight", "None", "Neck", "Trapezius", ["Sternocleidomastoid"], "beginner", "Slow, gentle circles", "Neck Side Stretch"),
            ],
        },
    ]

    # Follicular phase (Week 2 pattern): Increasing energy, ramp up intensity
    follicular_workouts = [
        {
            "workout_name": "Day 1 - Lower Body Strength",
            "type": "strength",
            "exercises": [
                ex("Goblet Squat", 4, 10, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold DB at chest, sit back", "Bodyweight Squat"),
                ex("Romanian Deadlift", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hinge at hips, soft knees", "Good Morning"),
                ex("Walking Lunge", 3, 10, 60, "Bodyweight or light DBs", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Long stride, upright torso", "Reverse Lunge"),
                ex("Clamshell with Band", 3, 15, 30, "Light band", "Resistance Band", "Hips", "Gluteus Medius", ["Hip External Rotators"], "beginner", "Keep feet together", "Side-Lying Leg Lift"),
                ex("Calf Raise", 3, 15, 30, "Bodyweight", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full range, pause at top", "Seated Calf Raise"),
                ex("Plank Hold", 3, 1, 30, "Bodyweight - hold 30 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Straight line head to heels", "Modified Plank"),
            ],
        },
        {
            "workout_name": "Day 2 - Upper Body Strength",
            "type": "strength",
            "exercises": [
                ex("Dumbbell Bench Press", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Lower to chest, press up", "Push-Up"),
                ex("Dumbbell Row", 3, 10, 60, "Moderate dumbbell", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull elbow past torso", "Resistance Band Row"),
                ex("Overhead Press", 3, 10, 60, "Light-moderate dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Press overhead, avoid arching", "Pike Push-Up"),
                ex("Bicep Curl", 3, 12, 45, "Light dumbbells", "Dumbbells", "Arms", "Biceps Brachii", ["Brachialis"], "beginner", "Control the negative", "Resistance Band Curl"),
                ex("Tricep Dip", 3, 10, 45, "Bodyweight", "Bench", "Arms", "Triceps Brachii", ["Pectoralis Major", "Anterior Deltoid"], "intermediate", "Bench dip, elbows back", "Tricep Kickback"),
                ex("Face Pull", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["Rhomboids", "External Rotators"], "beginner", "Pull to face, spread hands", "Band Pull-Apart"),
            ],
        },
        {
            "workout_name": "Day 3 - HIIT & Core",
            "type": "hiit",
            "exercises": [
                ex("Jump Squat", 4, 10, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Soft landing, explode up", "Bodyweight Squat"),
                ex("Mountain Climber", 4, 20, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Fast knees to chest", "High Knees"),
                ex("Burpee", 3, 8, 45, "Bodyweight", "None", "Full Body", "Full Body", ["Chest", "Legs", "Core"], "intermediate", "Chest to floor, jump up", "Squat Thrust"),
                ex("Russian Twist", 3, 20, 30, "Bodyweight or light DB", "None", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate side to side", "Bicycle Crunch"),
                ex("Bicycle Crunch", 3, 20, 30, "Bodyweight", "None", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Opposite elbow to knee", "Dead Bug"),
                ex("Plank to Downward Dog", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Shoulders", "Hamstrings"], "intermediate", "Flow between positions", "Plank Hold"),
            ],
        },
        {
            "workout_name": "Day 4 - Full Body Power",
            "type": "strength",
            "exercises": [
                ex("Sumo Squat", 3, 12, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "intermediate", "Wide stance, toes out", "Goblet Squat"),
                ex("Push-Up", 3, 10, 45, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Full range of motion", "Incline Push-Up"),
                ex("Dumbbell Deadlift", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hinge pattern, flat back", "Kettlebell Deadlift"),
                ex("Dumbbell Lateral Raise", 3, 12, 45, "Light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Arms slightly bent, raise to shoulder height", "Resistance Band Lateral Raise"),
                ex("Hip Thrust", 3, 12, 45, "Bodyweight or DB on hips", "Dumbbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Back on bench, drive hips up", "Glute Bridge"),
                ex("Dead Bug", 3, 12, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Pelvic Floor Muscles"], "beginner", "Opposite arm and leg extend", "Bird Dog"),
            ],
        },
        {
            "workout_name": "Day 5 - Active Recovery",
            "type": "flexibility",
            "exercises": [
                ex("Gentle Walking", 1, 1, 0, "20-30 minutes", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Easy pace outdoors", "Light Cycling"),
                ex("Foam Roll Quads", 3, 1, 15, "Hold 30 sec", "Foam Roller", "Legs", "Quadriceps", ["IT Band"], "beginner", "Roll slowly, pause on tight spots", "Quad Stretch"),
                ex("Foam Roll Upper Back", 3, 1, 15, "Hold 30 sec", "Foam Roller", "Back", "Thoracic Spine", ["Trapezius"], "beginner", "Arms crossed, roll mid-back", "Cat-Cow"),
                ex("World's Greatest Stretch", 3, 6, 20, "Bodyweight", "None", "Full Body", "Hip Flexors", ["Hamstrings", "Thoracic Spine"], "beginner", "Lunge, rotate, reach", "Lunge with Twist"),
                ex("90/90 Hip Stretch", 3, 4, 20, "Bodyweight - hold 30 sec/side", "None", "Hips", "Hip Rotators", ["Gluteus Medius"], "beginner", "Switch between positions", "Pigeon Stretch"),
                ex("Child's Pose", 3, 5, 20, "Bodyweight - hold 30 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Breathe into lower back", "Cat Stretch"),
            ],
        },
    ]

    # Ovulatory phase (Week 3 pattern): Peak energy, highest intensity
    ovulatory_workouts = [
        {
            "workout_name": "Day 1 - Heavy Lower Body",
            "type": "strength",
            "exercises": [
                ex("Barbell Back Squat", 4, 8, 90, "Heavy - 70-80% 1RM", "Barbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Brace core, break at hips and knees", "Goblet Squat"),
                ex("Barbell Hip Thrust", 4, 10, 75, "Heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full hip extension, squeeze at top", "Dumbbell Hip Thrust"),
                ex("Bulgarian Split Squat", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Rear foot elevated", "Reverse Lunge"),
                ex("Leg Curl", 3, 12, 45, "Moderate weight", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, control eccentric", "Nordic Curl Eccentric"),
                ex("Cable Glute Kickback", 3, 12, 45, "Moderate cable", "Cable Machine", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Squeeze at top, controlled", "Donkey Kick"),
                ex("Hanging Leg Raise", 3, 10, 45, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "No swinging, controlled raise", "Lying Leg Raise"),
            ],
        },
        {
            "workout_name": "Day 2 - Upper Body Power",
            "type": "strength",
            "exercises": [
                ex("Barbell Bench Press", 4, 8, 90, "Heavy - 70-80% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, drive up", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 4, 8, 75, "Heavy", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull to lower ribcage", "Dumbbell Row"),
                ex("Overhead Press", 3, 8, 75, "Moderate-heavy dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Strict press, no leg drive", "Pike Push-Up"),
                ex("Chin-Up", 3, 8, 75, "Bodyweight", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Chin over bar, full extension", "Lat Pulldown"),
                ex("Cable Face Pull", 3, 15, 30, "Light-moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators", "Rhomboids"], "beginner", "Pull to face, spread hands", "Band Face Pull"),
                ex("Ab Wheel Rollout", 3, 10, 45, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Extend fully, pull back with core", "Plank"),
            ],
        },
        {
            "workout_name": "Day 3 - Plyometric HIIT",
            "type": "hiit",
            "exercises": [
                ex("Box Jump", 4, 8, 45, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Soft landing, step down", "Jump Squat"),
                ex("Burpee", 4, 10, 30, "Bodyweight", "None", "Full Body", "Full Body", ["Chest", "Legs", "Core"], "intermediate", "Chest to floor, explode up", "Squat Thrust"),
                ex("Kettlebell Swing", 4, 15, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Hip snap, arms are along for the ride", "Dumbbell Swing"),
                ex("Battle Rope Alternating Wave", 3, 30, 30, "Moderate rope", "Battle Ropes", "Shoulders", "Anterior Deltoid", ["Core", "Forearms"], "intermediate", "Alternating arms, fast waves", "Mountain Climber"),
                ex("Sprint Intervals", 4, 1, 60, "Run: 30 sec sprint, 60 sec rest", "None", "Cardio", "Full Body", ["Quadriceps", "Hamstrings", "Calves"], "intermediate", "90% effort sprints", "High Knees"),
                ex("Plank Saw", 3, 12, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Shoulders"], "intermediate", "Rock forward and back in plank", "Plank Hold"),
            ],
        },
        {
            "workout_name": "Day 4 - Full Body Strength",
            "type": "strength",
            "exercises": [
                ex("Trap Bar Deadlift", 4, 8, 90, "Heavy", "Trap Bar", "Legs", "Hamstrings", ["Gluteus Maximus", "Quadriceps", "Erector Spinae"], "intermediate", "Drive through floor, lockout hips", "Barbell Deadlift"),
                ex("Incline Dumbbell Press", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30 degree incline", "Push-Up"),
                ex("Lat Pulldown", 3, 10, 60, "Moderate weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Pull to upper chest", "Chin-Up"),
                ex("Lateral Lunge", 3, 10, 45, "Light dumbbells", "Dumbbells", "Legs", "Hip Adductors", ["Quadriceps", "Gluteus Maximus"], "intermediate", "Wide step, sit back", "Cossack Squat"),
                ex("Dumbbell Arnold Press", 3, 10, 45, "Moderate dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Rotate as you press", "Overhead Press"),
                ex("Pallof Press", 3, 12, 30, "Light-moderate cable", "Cable Machine", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Press and hold, resist rotation", "Plank"),
            ],
        },
        {
            "workout_name": "Day 5 - Active Recovery",
            "type": "flexibility",
            "exercises": [
                ex("Light Jog", 1, 1, 0, "15-20 minutes easy", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Conversational pace", "Walking"),
                ex("Foam Roll Full Body", 1, 1, 0, "10 minutes", "Foam Roller", "Full Body", "Full Body", ["Fascia"], "beginner", "Hit all major muscle groups", "Stretching"),
                ex("World's Greatest Stretch", 3, 6, 20, "Bodyweight", "None", "Full Body", "Hip Flexors", ["Hamstrings", "Thoracic Spine"], "beginner", "Both sides", "Lunge with Twist"),
                ex("Pigeon Stretch", 3, 4, 20, "Bodyweight - hold 30 sec/side", "None", "Hips", "Hip Flexors", ["Gluteus Maximus"], "beginner", "Deep breathing", "Figure 4 Stretch"),
                ex("Cat-Cow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Flow with breath", "Seated Spinal Flexion"),
                ex("Child's Pose", 3, 5, 20, "Hold 30 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Full relaxation", "Cat Stretch"),
            ],
        },
    ]

    # Luteal phase (Week 4 pattern): Decreasing energy, moderate intensity, stress management
    luteal_workouts = [
        {
            "workout_name": "Day 1 - Moderate Lower Body",
            "type": "strength",
            "exercises": [
                ex("Goblet Squat", 3, 12, 60, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Controlled tempo, deep squat", "Bodyweight Squat"),
                ex("Dumbbell Romanian Deadlift", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Slow eccentric, squeeze at top", "Good Morning"),
                ex("Step-Up", 3, 10, 45, "Bodyweight or light DBs", "Bench", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Full step up, controlled step down", "Reverse Lunge"),
                ex("Glute Bridge", 3, 15, 30, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze at top, slow lower", "Hip Thrust"),
                ex("Standing Calf Raise", 3, 15, 30, "Bodyweight", "None", "Legs", "Gastrocnemius", ["Soleus"], "beginner", "Full range of motion", "Seated Calf Raise"),
                ex("Bird Dog", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Anti-rotation focus", "Dead Bug"),
            ],
        },
        {
            "workout_name": "Day 2 - Moderate Upper Body",
            "type": "strength",
            "exercises": [
                ex("Dumbbell Floor Press", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps"], "intermediate", "Elbows touch floor, press up", "Push-Up"),
                ex("Seated Cable Row", 3, 12, 60, "Moderate weight", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "intermediate", "Squeeze shoulder blades", "Dumbbell Row"),
                ex("Dumbbell Lateral Raise", 3, 12, 45, "Light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Controlled raise and lower", "Band Lateral Raise"),
                ex("Hammer Curl", 3, 12, 45, "Light dumbbells", "Dumbbells", "Arms", "Brachioradialis", ["Biceps Brachii"], "beginner", "Neutral grip, control the weight", "Band Curl"),
                ex("Overhead Tricep Extension", 3, 12, 45, "Light dumbbell", "Dumbbell", "Arms", "Triceps Brachii", ["Anconeus"], "beginner", "Lower behind head, extend", "Tricep Kickback"),
                ex("Face Pull", 3, 15, 30, "Light band", "Resistance Band", "Shoulders", "Rear Deltoid", ["External Rotators"], "beginner", "Pull apart at face level", "Band Pull-Apart"),
            ],
        },
        {
            "workout_name": "Day 3 - Steady-State Cardio & Core",
            "type": "cardio",
            "exercises": [
                ex("Brisk Walking or Light Cycling", 1, 1, 0, "25-30 minutes moderate", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Keep heart rate zone 2", "Elliptical"),
                ex("Plank Hold", 3, 1, 30, "Bodyweight - hold 30-45 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Straight line, breathe steadily", "Modified Plank"),
                ex("Side Plank", 3, 1, 30, "Bodyweight - hold 20-30 sec/side", "None", "Core", "Obliques", ["Transverse Abdominis", "Gluteus Medius"], "intermediate", "Hips stacked, straight line", "Side Plank on Knees"),
                ex("Dead Bug", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Slow, controlled movement", "Bird Dog"),
                ex("Pallof Press", 3, 10, 30, "Light band", "Resistance Band", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Resist rotation", "Plank"),
                ex("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Gentle cooldown", "Seated Spinal Flexion"),
            ],
        },
        {
            "workout_name": "Day 4 - Full Body Light",
            "type": "strength",
            "exercises": [
                ex("Bodyweight Squat", 3, 15, 30, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Slow tempo", "Wall Sit"),
                ex("Incline Push-Up", 3, 12, 30, "Bodyweight", "Bench", "Chest", "Pectoralis Major", ["Triceps"], "beginner", "Hands elevated", "Wall Push-Up"),
                ex("Resistance Band Row", 3, 15, 30, "Light-moderate band", "Resistance Band", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Squeeze at peak contraction", "Dumbbell Row"),
                ex("Glute Bridge", 3, 15, 30, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Slow and steady", "Hip Thrust"),
                ex("Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids"], "beginner", "Posture focus", "Face Pull"),
                ex("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "Stress reduction cooldown", "Box Breathing"),
            ],
        },
    ]

    # Build weeks for each duration
    # 4 weeks: 1 cycle (menstrual->follicular->ovulatory->luteal)
    weeks_data[(4, 4)] = {
        1: {"focus": "Menstrual phase - gentle movement, mobility, light exercise", "workouts": menstrual_workouts},
        2: {"focus": "Follicular phase - building energy, increasing strength", "workouts": follicular_workouts},
        3: {"focus": "Ovulatory phase - peak energy, highest intensity training", "workouts": ovulatory_workouts},
        4: {"focus": "Luteal phase - moderate intensity, stress management", "workouts": luteal_workouts},
    }
    weeks_data[(4, 5)] = dict(weeks_data[(4, 4)])

    # 8 weeks: 2 cycles with progression
    weeks_data[(8, 4)] = dict(weeks_data[(4, 4)])
    weeks_data[(8, 4)][5] = {"focus": "Menstrual phase cycle 2 - improved recovery strategies", "workouts": menstrual_workouts}
    weeks_data[(8, 4)][6] = {"focus": "Follicular phase cycle 2 - progressive overload", "workouts": follicular_workouts}
    weeks_data[(8, 4)][7] = {"focus": "Ovulatory phase cycle 2 - peak performance push", "workouts": ovulatory_workouts}
    weeks_data[(8, 4)][8] = {"focus": "Luteal phase cycle 2 - enhanced stress management", "workouts": luteal_workouts}
    weeks_data[(8, 5)] = dict(weeks_data[(8, 4)])

    # 12 weeks: 3 cycles
    weeks_data[(12, 4)] = dict(weeks_data[(8, 4)])
    weeks_data[(12, 4)][9] = {"focus": "Menstrual phase cycle 3 - refined intuitive training", "workouts": menstrual_workouts}
    weeks_data[(12, 4)][10] = {"focus": "Follicular phase cycle 3 - advanced strength focus", "workouts": follicular_workouts}
    weeks_data[(12, 4)][11] = {"focus": "Ovulatory phase cycle 3 - personal records push", "workouts": ovulatory_workouts}
    weeks_data[(12, 4)][12] = {"focus": "Luteal phase cycle 3 - maintenance and recovery mastery", "workouts": luteal_workouts}
    weeks_data[(12, 5)] = dict(weeks_data[(12, 4)])

    return helper.insert_full_program(
        program_name="Hormone Balance Workout",
        category_name="Women's Health",
        description="Cycle-synced training program that adjusts intensity, volume, and exercise selection based on menstrual cycle phases. Optimizes hormonal balance through strategic training periodization aligned with estrogen, progesterone, and energy fluctuations.",
        durations=[4, 8, 12],
        sessions_per_week=[4, 5],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=migration_num,
    )


def generate_pcos_workout(helper: ProgramSQLHelper, migration_num: int):
    """PCOS Workout Plan - 4,8,12w x 4-5/wk - Insulin sensitivity focus."""

    def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
        return {
            "name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": guidance, "equipment": equip,
            "body_part": body, "primary_muscle": primary,
            "secondary_muscles": secondary, "difficulty": diff,
            "form_cue": cue, "substitution": sub,
        }

    # PCOS benefits from: resistance training (insulin sensitivity), moderate cardio (not excessive),
    # stress-reducing movement (cortisol management), anti-inflammatory focus

    strength_lower = [
        {
            "workout_name": "Day 1 - Lower Body Strength (Insulin Sensitivity)",
            "type": "strength",
            "exercises": [
                ex("Barbell Back Squat", 4, 10, 90, "Moderate-heavy", "Barbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings", "Core"], "intermediate", "Full depth, drive through heels", "Goblet Squat"),
                ex("Romanian Deadlift", 3, 12, 75, "Moderate", "Barbell", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hinge at hips, flat back", "Dumbbell RDL"),
                ex("Walking Lunge", 3, 12, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Long stride, knee tracks toe", "Reverse Lunge"),
                ex("Hip Thrust", 3, 12, 60, "Moderate-heavy", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full extension, pause at top", "Glute Bridge"),
                ex("Leg Press", 3, 12, 60, "Moderate", "Machine", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Full range, don't lock knees", "Goblet Squat"),
                ex("Plank Hold", 3, 1, 30, "Hold 45 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Straight line, breathe", "Modified Plank"),
            ],
        },
    ]

    strength_upper = [
        {
            "workout_name": "Day 2 - Upper Body Strength",
            "type": "strength",
            "exercises": [
                ex("Dumbbell Bench Press", 4, 10, 75, "Moderate", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Lower controlled, press explosively", "Push-Up"),
                ex("Dumbbell Row", 4, 10, 60, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Pull elbow past torso", "Cable Row"),
                ex("Overhead Press", 3, 10, 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Strict press overhead", "Pike Push-Up"),
                ex("Lat Pulldown", 3, 12, 60, "Moderate", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "intermediate", "Wide grip, pull to chest", "Band Pulldown"),
                ex("Face Pull", 3, 15, 30, "Light-moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators", "Rhomboids"], "beginner", "Pull to face level, spread hands", "Band Pull-Apart"),
                ex("Dead Bug", 3, 12, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis", "Obliques"], "beginner", "Lower opposite limbs slowly", "Bird Dog"),
            ],
        },
    ]

    moderate_cardio = [
        {
            "workout_name": "Day 3 - Moderate Cardio & Mobility (Cortisol Management)",
            "type": "cardio",
            "exercises": [
                ex("Brisk Walking or Cycling", 1, 1, 0, "25-30 min, zone 2 heart rate", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Maintain conversational pace", "Elliptical"),
                ex("World's Greatest Stretch", 3, 6, 20, "Bodyweight", "None", "Full Body", "Hip Flexors", ["Hamstrings", "Thoracic Spine"], "beginner", "Full range each position", "Lunge with Twist"),
                ex("90/90 Hip Stretch", 3, 4, 20, "Hold 30 sec/side", "None", "Hips", "Hip Rotators", ["Gluteus Medius"], "beginner", "Sit tall, lean forward", "Pigeon Stretch"),
                ex("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Sync with breath", "Seated Spinal Flexion"),
                ex("Thread the Needle", 3, 8, 15, "Bodyweight", "None", "Back", "Thoracic Spine", ["Rhomboids"], "beginner", "Rotate to open chest", "Seated Twist"),
                ex("Diaphragmatic Breathing", 3, 10, 15, "Bodyweight", "None", "Core", "Diaphragm", ["Pelvic Floor Muscles"], "beginner", "4 in, 7 hold, 8 out for cortisol", "Box Breathing"),
            ],
        },
    ]

    full_body_circuit = [
        {
            "workout_name": "Day 4 - Full Body Metabolic Circuit",
            "type": "circuit",
            "exercises": [
                ex("Kettlebell Goblet Squat", 3, 12, 45, "Moderate KB", "Kettlebell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "intermediate", "Hold KB at chest, sit deep", "Goblet Squat"),
                ex("Push-Up", 3, 12, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Full range of motion", "Incline Push-Up"),
                ex("Dumbbell Reverse Lunge", 3, 10, 45, "Light-moderate", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Step back, knee nearly touches floor", "Bodyweight Reverse Lunge"),
                ex("Dumbbell Row", 3, 10, 45, "Moderate", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Squeeze at top", "Band Row"),
                ex("Kettlebell Swing", 3, 15, 45, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Hip snap, not arm pull", "Dumbbell Swing"),
                ex("Russian Twist", 3, 16, 30, "Light DB or bodyweight", "None", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate", "Bicycle Crunch"),
            ],
        },
    ]

    stress_recovery = [
        {
            "workout_name": "Day 5 - Stress-Reducing Movement (Anti-Inflammatory)",
            "type": "flexibility",
            "exercises": [
                ex("Gentle Walking", 1, 1, 0, "20 min easy pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Nature walk if possible", "Light Cycling"),
                ex("Sun Salutation Modified", 3, 5, 15, "Bodyweight", "None", "Full Body", "Full Body", ["Core", "Shoulders"], "beginner", "Slow, mindful flow", "Cat-Cow Flow"),
                ex("Foam Roll Lower Body", 1, 1, 0, "5 minutes", "Foam Roller", "Legs", "Quadriceps", ["IT Band", "Hamstrings", "Calves"], "beginner", "Slow rolling, breathe", "Stretching"),
                ex("Pigeon Stretch", 3, 4, 20, "Hold 45 sec/side", "None", "Hips", "Hip Flexors", ["Gluteus Maximus"], "beginner", "Breathe deeply into hip", "Figure 4 Stretch"),
                ex("Child's Pose", 3, 5, 20, "Hold 45 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Knees wide, belly between thighs", "Cat Stretch"),
                ex("Legs Up Wall", 1, 1, 0, "5 minutes", "None", "Recovery", "Circulatory System", ["Hamstrings"], "beginner", "Full relaxation, deep breathing", "Reclined Position"),
            ],
        },
    ]

    all_workouts = strength_lower + strength_upper + moderate_cardio + full_body_circuit + stress_recovery

    weeks_data = {}
    # 4 weeks
    weeks_data[(4, 4)] = {
        1: {"focus": "Foundation - learn movements, build habit, insulin sensitivity", "workouts": all_workouts[:4]},
        2: {"focus": "Progressive load - slight weight increases, metabolic conditioning", "workouts": all_workouts[:4]},
        3: {"focus": "Volume increase - additional set or reps, anti-inflammatory focus", "workouts": all_workouts[:4]},
        4: {"focus": "Deload - reduce volume 20%, active recovery emphasis", "workouts": all_workouts[:4]},
    }
    weeks_data[(4, 5)] = {
        1: {"focus": "Foundation with recovery - 5 sessions including stress management", "workouts": all_workouts},
        2: {"focus": "Progressive load with full recovery protocol", "workouts": all_workouts},
        3: {"focus": "Volume peak with anti-inflammatory emphasis", "workouts": all_workouts},
        4: {"focus": "Deload with enhanced recovery and mobility", "workouts": all_workouts},
    }

    # 8 weeks
    weeks_data[(8, 4)] = dict(weeks_data[(4, 4)])
    weeks_data[(8, 4)][5] = {"focus": "Cycle 2 foundation - refined movement patterns", "workouts": all_workouts[:4]}
    weeks_data[(8, 4)][6] = {"focus": "Cycle 2 progressive overload - heavier loads", "workouts": all_workouts[:4]}
    weeks_data[(8, 4)][7] = {"focus": "Cycle 2 peak volume - metabolic conditioning", "workouts": all_workouts[:4]}
    weeks_data[(8, 4)][8] = {"focus": "Cycle 2 deload - test improvements, active recovery", "workouts": all_workouts[:4]}
    weeks_data[(8, 5)] = dict(weeks_data[(4, 5)])
    weeks_data[(8, 5)][5] = {"focus": "Cycle 2 foundation with stress management", "workouts": all_workouts}
    weeks_data[(8, 5)][6] = {"focus": "Cycle 2 progressive overload with recovery", "workouts": all_workouts}
    weeks_data[(8, 5)][7] = {"focus": "Cycle 2 peak volume with anti-inflammatory", "workouts": all_workouts}
    weeks_data[(8, 5)][8] = {"focus": "Cycle 2 deload and improvement assessment", "workouts": all_workouts}

    # 12 weeks
    weeks_data[(12, 4)] = dict(weeks_data[(8, 4)])
    weeks_data[(12, 4)][9] = {"focus": "Cycle 3 foundation - advanced patterns", "workouts": all_workouts[:4]}
    weeks_data[(12, 4)][10] = {"focus": "Cycle 3 progressive overload - new PRs", "workouts": all_workouts[:4]}
    weeks_data[(12, 4)][11] = {"focus": "Cycle 3 peak - maximal insulin sensitivity gains", "workouts": all_workouts[:4]}
    weeks_data[(12, 4)][12] = {"focus": "Final deload - long-term maintenance planning", "workouts": all_workouts[:4]}
    weeks_data[(12, 5)] = dict(weeks_data[(8, 5)])
    weeks_data[(12, 5)][9] = {"focus": "Cycle 3 foundation with refined recovery", "workouts": all_workouts}
    weeks_data[(12, 5)][10] = {"focus": "Cycle 3 progressive overload with full protocol", "workouts": all_workouts}
    weeks_data[(12, 5)][11] = {"focus": "Cycle 3 peak performance and metabolic health", "workouts": all_workouts}
    weeks_data[(12, 5)][12] = {"focus": "Final deload - sustainable lifestyle integration", "workouts": all_workouts}

    return helper.insert_full_program(
        program_name="PCOS Workout Plan",
        category_name="Women's Health",
        description="Evidence-based workout program designed for women with PCOS. Focuses on improving insulin sensitivity through resistance training, managing cortisol with moderate cardio, and reducing inflammation through strategic recovery and stress-reducing movement.",
        durations=[4, 8, 12],
        sessions_per_week=[4, 5],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=migration_num,
    )


def generate_womens_strength_basics(helper: ProgramSQLHelper, migration_num: int):
    """Women's Strength Basics - 4,8,12w x 3-4/wk - Confidence building."""

    def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
        return {
            "name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": guidance, "equipment": equip,
            "body_part": body, "primary_muscle": primary,
            "secondary_muscles": secondary, "difficulty": diff,
            "form_cue": cue, "substitution": sub,
        }

    # Foundation weeks: learn movements, build confidence with basic compound lifts
    foundation_3day = [
        {
            "workout_name": "Day 1 - Full Body A",
            "type": "strength",
            "exercises": [
                ex("Goblet Squat", 3, 10, 60, "Light-moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Core"], "beginner", "Hold at chest, sit back and down", "Bodyweight Squat"),
                ex("Dumbbell Bench Press", 3, 10, 60, "Light dumbbells", "Dumbbells", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "beginner", "Lower to chest level, press up", "Incline Push-Up"),
                ex("Dumbbell Row", 3, 10, 60, "Light-moderate dumbbell", "Dumbbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "beginner", "Brace on bench, pull to hip", "Resistance Band Row"),
                ex("Glute Bridge", 3, 12, 45, "Bodyweight", "None", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Squeeze glutes at top", "Hip Thrust"),
                ex("Plank Hold", 3, 1, 30, "Bodyweight - hold 20-30 sec", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Straight line head to heels", "Modified Plank on Knees"),
                ex("Band Pull-Apart", 3, 15, 30, "Light band", "Resistance Band", "Back", "Rear Deltoid", ["Rhomboids", "Trapezius"], "beginner", "Arms straight, pull apart at chest height", "Face Pull"),
            ],
        },
        {
            "workout_name": "Day 2 - Full Body B",
            "type": "strength",
            "exercises": [
                ex("Dumbbell Romanian Deadlift", 3, 10, 60, "Light-moderate dumbbells", "Dumbbells", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "beginner", "Push hips back, slight knee bend, flat back", "Good Morning"),
                ex("Dumbbell Overhead Press", 3, 10, 60, "Light dumbbells", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "beginner", "Press straight up, avoid arching back", "Pike Push-Up"),
                ex("Lat Pulldown", 3, 10, 60, "Light weight", "Cable Machine", "Back", "Latissimus Dorsi", ["Biceps", "Rhomboids"], "beginner", "Pull bar to upper chest, squeeze lats", "Band Pulldown"),
                ex("Step-Up", 3, 10, 45, "Bodyweight or light DBs", "Bench", "Legs", "Quadriceps", ["Gluteus Maximus"], "beginner", "Step fully up, control step down", "Reverse Lunge"),
                ex("Bird Dog", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae", "Gluteus Maximus"], "beginner", "Opposite arm and leg, keep hips level", "Dead Bug"),
                ex("Dumbbell Bicep Curl", 3, 12, 30, "Light dumbbells", "Dumbbells", "Arms", "Biceps Brachii", ["Brachialis"], "beginner", "Controlled movement, no swinging", "Resistance Band Curl"),
            ],
        },
        {
            "workout_name": "Day 3 - Full Body C",
            "type": "strength",
            "exercises": [
                ex("Sumo Squat", 3, 12, 60, "Light dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Hip Adductors", "Gluteus Maximus"], "beginner", "Wide stance, toes out, hold DB at center", "Bodyweight Sumo Squat"),
                ex("Push-Up (Modified)", 3, 8, 45, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Knees down if needed, full range", "Wall Push-Up"),
                ex("Dumbbell Reverse Lunge", 3, 10, 60, "Light dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "beginner", "Step back, lower knee toward floor", "Bodyweight Lunge"),
                ex("Seated Cable Row", 3, 10, 60, "Light weight", "Cable Machine", "Back", "Rhomboids", ["Latissimus Dorsi", "Biceps"], "beginner", "Pull to lower chest, squeeze", "Resistance Band Row"),
                ex("Hip Thrust", 3, 12, 45, "Bodyweight", "Bench", "Glutes", "Gluteus Maximus", ["Hamstrings"], "beginner", "Back on bench edge, drive hips to ceiling", "Glute Bridge"),
                ex("Dead Bug", 3, 10, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Rectus Abdominis"], "beginner", "Opposite arm and leg lower slowly", "Bird Dog"),
            ],
        },
    ]

    foundation_4day = foundation_3day + [
        {
            "workout_name": "Day 4 - Active Recovery & Mobility",
            "type": "flexibility",
            "exercises": [
                ex("Walking", 1, 1, 0, "20-25 minutes easy pace", "None", "Cardio", "Full Body", ["Cardiovascular System"], "beginner", "Comfortable pace", "Light Cycling"),
                ex("World's Greatest Stretch", 3, 6, 20, "Bodyweight", "None", "Full Body", "Hip Flexors", ["Hamstrings", "Thoracic Spine"], "beginner", "Lunge, rotate, reach", "Lunge with Twist"),
                ex("Cat-Cow Flow", 3, 10, 15, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Erector Spinae"], "beginner", "Flow with breath", "Seated Spinal Flexion"),
                ex("Foam Roll Quads", 3, 1, 15, "Hold 30 sec", "Foam Roller", "Legs", "Quadriceps", ["IT Band"], "beginner", "Slow roll, pause on tight spots", "Quad Stretch"),
                ex("90/90 Hip Stretch", 3, 4, 20, "Hold 30 sec/side", "None", "Hips", "Hip Rotators", ["Gluteus Medius"], "beginner", "Sit upright, lean forward", "Pigeon Stretch"),
                ex("Child's Pose", 3, 5, 20, "Hold 30 sec", "None", "Back", "Erector Spinae", ["Latissimus Dorsi"], "beginner", "Breathe deeply", "Cat Stretch"),
            ],
        },
    ]

    # Build phase: increase weight, introduce barbell, more volume
    build_3day = [
        {
            "workout_name": "Day 1 - Lower Body Focus",
            "type": "strength",
            "exercises": [
                ex("Barbell Back Squat", 4, 8, 90, "Moderate - 60-70% 1RM", "Barbell", "Legs", "Quadriceps", ["Gluteus Maximus", "Hamstrings"], "intermediate", "Brace core, full depth", "Goblet Squat"),
                ex("Barbell Romanian Deadlift", 3, 10, 75, "Moderate", "Barbell", "Legs", "Hamstrings", ["Gluteus Maximus", "Erector Spinae"], "intermediate", "Hip hinge, bar close to legs", "Dumbbell RDL"),
                ex("Bulgarian Split Squat", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Rear foot on bench", "Reverse Lunge"),
                ex("Barbell Hip Thrust", 3, 12, 60, "Moderate", "Barbell", "Glutes", "Gluteus Maximus", ["Hamstrings"], "intermediate", "Full hip extension at top", "Dumbbell Hip Thrust"),
                ex("Leg Curl", 3, 12, 45, "Moderate", "Machine", "Legs", "Hamstrings", ["Calves"], "intermediate", "Full range, squeeze at top", "Nordic Curl Eccentric"),
                ex("Hanging Knee Raise", 3, 10, 30, "Bodyweight", "Pull-Up Bar", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Controlled raise and lower", "Lying Leg Raise"),
            ],
        },
        {
            "workout_name": "Day 2 - Upper Body Focus",
            "type": "strength",
            "exercises": [
                ex("Barbell Bench Press", 4, 8, 90, "Moderate - 60-70% 1RM", "Barbell", "Chest", "Pectoralis Major", ["Triceps", "Anterior Deltoid"], "intermediate", "Touch chest, press up", "Dumbbell Bench Press"),
                ex("Barbell Bent-Over Row", 3, 10, 75, "Moderate", "Barbell", "Back", "Latissimus Dorsi", ["Rhomboids", "Biceps"], "intermediate", "Torso at 45 degrees, pull to navel", "Dumbbell Row"),
                ex("Dumbbell Overhead Press", 3, 10, 60, "Moderate", "Dumbbells", "Shoulders", "Anterior Deltoid", ["Lateral Deltoid", "Triceps"], "intermediate", "Strict press, no leg drive", "Arnold Press"),
                ex("Cable Face Pull", 3, 15, 30, "Light-moderate", "Cable Machine", "Shoulders", "Rear Deltoid", ["External Rotators"], "beginner", "Pull rope to face, spread", "Band Face Pull"),
                ex("Dumbbell Lateral Raise", 3, 12, 30, "Light dumbbells", "Dumbbells", "Shoulders", "Lateral Deltoid", ["Anterior Deltoid"], "beginner", "Slight bend in elbows, raise to shoulder", "Band Lateral Raise"),
                ex("Plank to Push-Up", 3, 8, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Triceps", "Shoulders"], "intermediate", "Alternate arms, minimize hip rocking", "Plank Hold"),
            ],
        },
        {
            "workout_name": "Day 3 - Full Body",
            "type": "strength",
            "exercises": [
                ex("Trap Bar Deadlift", 3, 8, 90, "Moderate", "Trap Bar", "Legs", "Hamstrings", ["Quadriceps", "Gluteus Maximus", "Erector Spinae"], "intermediate", "Push floor away, lockout hips", "Barbell Deadlift"),
                ex("Incline Dumbbell Press", 3, 10, 60, "Moderate", "Dumbbells", "Chest", "Upper Pectoralis", ["Anterior Deltoid", "Triceps"], "intermediate", "30 degree incline, full range", "Push-Up"),
                ex("Chin-Up (Assisted)", 3, 8, 60, "Band-assisted or machine", "Pull-Up Bar", "Back", "Latissimus Dorsi", ["Biceps"], "intermediate", "Pull chin over bar, full extension", "Lat Pulldown"),
                ex("Walking Lunge", 3, 10, 60, "Moderate dumbbells", "Dumbbells", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Long strides, upright torso", "Reverse Lunge"),
                ex("Dumbbell Curl to Press", 3, 10, 45, "Light-moderate", "Dumbbells", "Full Body", "Biceps Brachii", ["Anterior Deltoid", "Triceps"], "intermediate", "Curl then press overhead", "Separate Curl and Press"),
                ex("Ab Wheel Rollout", 3, 8, 30, "Bodyweight", "Ab Wheel", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Extend as far as controlled", "Plank"),
            ],
        },
    ]

    build_4day = build_3day + [
        {
            "workout_name": "Day 4 - Conditioning & Core",
            "type": "circuit",
            "exercises": [
                ex("Kettlebell Swing", 4, 15, 30, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Hip snap, arms follow", "Dumbbell Swing"),
                ex("Push-Up", 3, 12, 30, "Bodyweight", "None", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Full range from toes", "Incline Push-Up"),
                ex("Goblet Squat", 3, 12, 45, "Moderate dumbbell", "Dumbbell", "Legs", "Quadriceps", ["Gluteus Maximus"], "intermediate", "Deep squat, upright torso", "Bodyweight Squat"),
                ex("Renegade Row", 3, 8, 45, "Moderate dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row alternating", "Dumbbell Row"),
                ex("Mountain Climber", 3, 20, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Hip Flexors"], "intermediate", "Controlled pace, hips level", "High Knees"),
                ex("Russian Twist", 3, 16, 30, "Light dumbbell", "Dumbbell", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Lean back, rotate side to side", "Bicycle Crunch"),
            ],
        },
    ]

    weeks_data = {}

    # 4 weeks: Foundation (wk1-2) -> Build (wk3-4)
    weeks_data[(4, 3)] = {
        1: {"focus": "Learn movement patterns, light weights, build confidence", "workouts": foundation_3day},
        2: {"focus": "Solidify form, slight weight increase", "workouts": foundation_3day},
        3: {"focus": "Introduce barbell movements, progressive overload", "workouts": build_3day},
        4: {"focus": "Build strength, test improvements", "workouts": build_3day},
    }
    weeks_data[(4, 4)] = {
        1: {"focus": "Learn movement patterns with mobility day", "workouts": foundation_4day},
        2: {"focus": "Solidify form, increase loads slightly", "workouts": foundation_4day},
        3: {"focus": "Introduce barbell + conditioning day", "workouts": build_4day},
        4: {"focus": "Build strength and endurance", "workouts": build_4day},
    }

    # 8 weeks
    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Progressive overload - increase weights", "workouts": build_3day}
    weeks_data[(8, 3)][6] = {"focus": "Volume increase - add reps or sets", "workouts": build_3day}
    weeks_data[(8, 3)][7] = {"focus": "Peak week - highest intensity", "workouts": build_3day}
    weeks_data[(8, 3)][8] = {"focus": "Deload and reassess", "workouts": foundation_3day}
    weeks_data[(8, 4)] = dict(weeks_data[(4, 4)])
    weeks_data[(8, 4)][5] = {"focus": "Progressive overload with conditioning", "workouts": build_4day}
    weeks_data[(8, 4)][6] = {"focus": "Volume peak week", "workouts": build_4day}
    weeks_data[(8, 4)][7] = {"focus": "Intensity peak - test new maxes", "workouts": build_4day}
    weeks_data[(8, 4)][8] = {"focus": "Deload - active recovery focus", "workouts": foundation_4day}

    # 12 weeks
    weeks_data[(12, 3)] = dict(weeks_data[(8, 3)])
    weeks_data[(12, 3)][9] = {"focus": "Cycle 3 foundation rebuild", "workouts": build_3day}
    weeks_data[(12, 3)][10] = {"focus": "Cycle 3 progressive overload", "workouts": build_3day}
    weeks_data[(12, 3)][11] = {"focus": "Cycle 3 peak performance", "workouts": build_3day}
    weeks_data[(12, 3)][12] = {"focus": "Final testing and maintenance planning", "workouts": build_3day}
    weeks_data[(12, 4)] = dict(weeks_data[(8, 4)])
    weeks_data[(12, 4)][9] = {"focus": "Cycle 3 foundation with full conditioning", "workouts": build_4day}
    weeks_data[(12, 4)][10] = {"focus": "Cycle 3 progressive overload", "workouts": build_4day}
    weeks_data[(12, 4)][11] = {"focus": "Cycle 3 peak week", "workouts": build_4day}
    weeks_data[(12, 4)][12] = {"focus": "Final assessment and ongoing plan", "workouts": build_4day}

    return helper.insert_full_program(
        program_name="Women's Strength Basics",
        category_name="Women's Health",
        description="A confidence-building strength program designed for women new to resistance training. Progresses from dumbbell and bodyweight fundamentals to barbell compound lifts with proper form coaching, structured recovery, and progressive overload.",
        durations=[4, 8, 12],
        sessions_per_week=[3, 4],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=migration_num,
    )


def generate_womens_self_defense(helper: ProgramSQLHelper, migration_num: int):
    """Women's Self-Defense - 2,4,8w x 2-3/wk - Safety & empowerment focused."""

    def ex(name, sets, reps, rest, guidance, equip, body, primary, secondary, diff, cue, sub):
        return {
            "name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": guidance, "equipment": equip,
            "body_part": body, "primary_muscle": primary,
            "secondary_muscles": secondary, "difficulty": diff,
            "form_cue": cue, "substitution": sub,
        }

    # Self-defense training: functional strength, explosive power, grip, core stability, cardio endurance
    day1_functional_power = [
        {
            "workout_name": "Day 1 - Functional Power & Explosiveness",
            "type": "strength",
            "exercises": [
                ex("Medicine Ball Slam", 3, 10, 45, "Moderate med ball", "Medicine Ball", "Full Body", "Core", ["Shoulders", "Latissimus Dorsi", "Hip Flexors"], "intermediate", "Lift overhead, slam to floor with force", "Burpee"),
                ex("Kettlebell Swing", 3, 12, 45, "Moderate KB", "Kettlebell", "Posterior Chain", "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate", "Explosive hip snap, strong lockout", "Dumbbell Swing"),
                ex("Push-Up to Sprinter Start", 3, 8, 45, "Bodyweight", "None", "Full Body", "Pectoralis Major", ["Triceps", "Core", "Hip Flexors"], "intermediate", "Push-up then explosively bring one knee forward", "Push-Up"),
                ex("Goblet Squat to Press", 3, 10, 60, "Moderate dumbbell", "Dumbbell", "Full Body", "Quadriceps", ["Gluteus Maximus", "Anterior Deltoid"], "intermediate", "Squat deep, press DB overhead at top", "Goblet Squat"),
                ex("Farmer's Walk", 3, 1, 45, "Heavy dumbbells - walk 30 sec", "Dumbbells", "Full Body", "Forearms", ["Trapezius", "Core", "Grip Strength"], "intermediate", "Tall posture, grip tight, walk controlled", "Dumbbell Hold"),
                ex("Plank with Shoulder Tap", 3, 12, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Deltoids", "Obliques"], "intermediate", "Minimize hip rotation, tap opposite shoulder", "Plank Hold"),
                ex("Broad Jump", 3, 6, 60, "Bodyweight", "None", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Arm swing, explode forward, soft landing", "Jump Squat"),
            ],
        },
    ]

    day2_grip_core = [
        {
            "workout_name": "Day 2 - Grip Strength & Core Stability",
            "type": "strength",
            "exercises": [
                ex("Dead Hang", 3, 1, 45, "Bodyweight - hold 20-30 sec", "Pull-Up Bar", "Arms", "Forearms", ["Grip Strength", "Latissimus Dorsi"], "beginner", "Full hang, shoulders packed, squeeze bar", "Towel Hang"),
                ex("Renegade Row", 3, 8, 60, "Moderate dumbbells", "Dumbbells", "Back", "Latissimus Dorsi", ["Core", "Biceps", "Grip Strength"], "intermediate", "Plank position, row without rotating hips", "Dumbbell Row"),
                ex("Pallof Press", 3, 10, 45, "Moderate band or cable", "Resistance Band", "Core", "Transverse Abdominis", ["Obliques"], "intermediate", "Press and hold, resist rotation force", "Plank"),
                ex("Turkish Get-Up", 3, 3, 60, "Light-moderate KB or DB", "Kettlebell", "Full Body", "Core", ["Shoulders", "Hip Flexors", "Gluteus Maximus"], "intermediate", "Slow controlled rise from floor to standing", "Half Turkish Get-Up"),
                ex("Bear Crawl", 3, 1, 45, "Bodyweight - crawl 30 sec", "None", "Full Body", "Core", ["Shoulders", "Quadriceps", "Hip Flexors"], "intermediate", "Knees hover 1 inch, move controlled", "Mountain Climber"),
                ex("Wrist Curl", 3, 15, 30, "Light dumbbell", "Dumbbell", "Arms", "Forearms", ["Wrist Flexors"], "beginner", "Wrist over edge of bench, curl up", "Towel Wring"),
                ex("Hollow Body Hold", 3, 1, 30, "Bodyweight - hold 20 sec", "None", "Core", "Rectus Abdominis", ["Transverse Abdominis"], "intermediate", "Lower back pressed to floor, arms and legs extended", "Dead Bug"),
            ],
        },
    ]

    day3_cardio_endurance = [
        {
            "workout_name": "Day 3 - Cardio Endurance & Escape Drills",
            "type": "hiit",
            "exercises": [
                ex("Sprint Intervals", 4, 1, 60, "Sprint 20 sec, rest 40 sec", "None", "Cardio", "Full Body", ["Quadriceps", "Hamstrings", "Calves"], "intermediate", "Maximum effort sprints", "High Knees"),
                ex("Burpee", 3, 8, 45, "Bodyweight", "None", "Full Body", "Full Body", ["Chest", "Core", "Legs"], "intermediate", "Chest to floor, jump explosively", "Squat Thrust"),
                ex("Mountain Climber", 4, 20, 30, "Bodyweight", "None", "Core", "Transverse Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Fast and controlled", "High Knees"),
                ex("Box Jump", 3, 8, 45, "Bodyweight", "Plyo Box", "Legs", "Quadriceps", ["Gluteus Maximus", "Calves"], "intermediate", "Soft landing on box, step down", "Jump Squat"),
                ex("Battle Rope Alternating Wave", 3, 30, 30, "Moderate rope", "Battle Ropes", "Shoulders", "Anterior Deltoid", ["Core", "Forearms"], "intermediate", "Fast alternating waves", "Mountain Climber"),
                ex("Lateral Shuffle", 3, 20, 30, "Bodyweight", "None", "Legs", "Hip Abductors", ["Quadriceps", "Calves"], "intermediate", "Low stance, quick feet", "Side Step"),
                ex("Bear Crawl Sprint", 3, 1, 45, "Bodyweight - 15 sec", "None", "Full Body", "Core", ["Shoulders", "Quadriceps"], "intermediate", "As fast as possible with control", "Bear Crawl"),
            ],
        },
    ]

    weeks_data = {}

    # 2 weeks
    weeks_data[(2, 2)] = {
        1: {"focus": "Functional power and grip strength foundation", "workouts": day1_functional_power + day2_grip_core},
        2: {"focus": "Increased intensity and cardio endurance", "workouts": day1_functional_power + day3_cardio_endurance},
    }
    weeks_data[(2, 3)] = {
        1: {"focus": "All-round self-defense fitness foundation", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance},
        2: {"focus": "Progressive intensity across all domains", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance},
    }

    # 4 weeks
    weeks_data[(4, 2)] = dict(weeks_data[(2, 2)])
    weeks_data[(4, 2)][3] = {"focus": "Power development and grip endurance", "workouts": day1_functional_power + day2_grip_core}
    weeks_data[(4, 2)][4] = {"focus": "Peak conditioning and test", "workouts": day1_functional_power + day3_cardio_endurance}
    weeks_data[(4, 3)] = dict(weeks_data[(2, 3)])
    weeks_data[(4, 3)][3] = {"focus": "Increased load and volume", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}
    weeks_data[(4, 3)][4] = {"focus": "Peak week - maximum intensity", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}

    # 8 weeks
    weeks_data[(8, 2)] = dict(weeks_data[(4, 2)])
    weeks_data[(8, 2)][5] = {"focus": "Cycle 2 - advanced power training", "workouts": day1_functional_power + day2_grip_core}
    weeks_data[(8, 2)][6] = {"focus": "Cycle 2 - advanced cardio endurance", "workouts": day1_functional_power + day3_cardio_endurance}
    weeks_data[(8, 2)][7] = {"focus": "Peak performance push", "workouts": day1_functional_power + day2_grip_core}
    weeks_data[(8, 2)][8] = {"focus": "Final test and maintenance plan", "workouts": day1_functional_power + day3_cardio_endurance}
    weeks_data[(8, 3)] = dict(weeks_data[(4, 3)])
    weeks_data[(8, 3)][5] = {"focus": "Cycle 2 - advanced all-round conditioning", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}
    weeks_data[(8, 3)][6] = {"focus": "Cycle 2 - progressive overload", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}
    weeks_data[(8, 3)][7] = {"focus": "Peak week - maximal testing", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}
    weeks_data[(8, 3)][8] = {"focus": "Deload and ongoing maintenance", "workouts": day1_functional_power + day2_grip_core + day3_cardio_endurance}

    return helper.insert_full_program(
        program_name="Women's Self-Defense",
        category_name="Women's Health",
        description="Safety and empowerment focused fitness program building functional strength, explosive power, grip endurance, and cardiovascular conditioning essential for self-defense situations. Includes sprint drills, grip training, core stability, and reactive power exercises.",
        durations=[2, 4, 8],
        sessions_per_week=[2, 3],
        has_supersets=True,
        priority="high",
        weeks_data=weeks_data,
        migration_num=migration_num,
    )


def main():
    helper = ProgramSQLHelper()
    migration_num = helper.get_next_migration_num()

    programs = [
        ("Kegel & Pelvic Floor", generate_kegel_pelvic_floor),
        ("Hormone Balance Workout", generate_hormone_balance),
        ("PCOS Workout Plan", generate_pcos_workout),
        ("Women's Strength Basics", generate_womens_strength_basics),
        ("Women's Self-Defense", generate_womens_self_defense),
    ]

    results = {}
    for name, gen_func in programs:
        if helper.check_program_exists(name):
            print(f"  SKIP (exists): {name}")
            results[name] = "skipped"
            continue
        print(f"\nGenerating: {name} (migration #{migration_num})")
        try:
            success = gen_func(helper, migration_num)
            results[name] = "OK" if success else "FAILED"
            if success:
                helper.update_tracker(name, "Done", f"{migration_num}_program_*.sql")
            migration_num += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            results[name] = f"ERROR: {e}"
            migration_num += 1

    print("\n=== Women's Health Results ===")
    for name, status in results.items():
        print(f"  {name}: {status}")

    helper.close()


if __name__ == "__main__":
    main()
