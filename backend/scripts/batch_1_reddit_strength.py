#!/usr/bin/env python3
"""
Batch 1: Reddit-Famous & Strength Programs
===========================================
27 programs covering barbell LP, bodyweight routines, and popular
Reddit/forum programs.

Programs already defined in generate_correct_workouts.py (NOT duplicated here):
  PHUL, Reddit PPL, Classic 5x5 Beginner, GZCLP, nSuns 5/3/1,
  PHAT, High Volume 5/3/1 Variant, 6-Day PPL Split, Upper-Lower Linear
"""

from exercise_lib import *


###############################################################################
# 1. Basic Barbell Beginner  (3 days, alternating A/B full body)
###############################################################################

def _basic_barbell_beginner():
    """Starting Strength-style 3-day full body, A/B alternating.
    A: Squat/Bench/Row   B: Squat/OHP/Deadlift"""
    return [
        workout("Workout A", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(3, 5, 120, "Add 5lb every session"),
        ]),
        workout("Workout B", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session"),
            BARBELL_OHP(3, 5, 180, "Add 5lb every session"),
            DEADLIFT(1, 5, 300, "Add 10lb every session"),
        ]),
        workout("Workout A (repeat)", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(3, 5, 120, "Add 5lb every session"),
        ]),
    ]


###############################################################################
# 2. Tiered Linear Progression  (4 days, GZCLP-like T1/T2/T3)
###############################################################################

def _tiered_linear_progression():
    """4-day program with GZCLP-style tier system.
    T1 heavy compound, T2 moderate compound, T3 light isolation."""
    return [
        workout("Day 1: T1 Squat", "strength", 55, [
            BARBELL_SQUAT(5, 3, 180, "T1: heavy, progress 5x3 -> 6x2 -> 10x1"),
            BARBELL_BENCH(3, 10, 90, "T2: moderate volume"),
            LAT_PULLDOWN(3, 15, 45, "T3: AMRAP last set"),
            FACE_PULL(3, 15, 30, "T3: prehab"),
        ]),
        workout("Day 2: T1 OHP", "strength", 55, [
            BARBELL_OHP(5, 3, 180, "T1: heavy"),
            DEADLIFT(3, 10, 120, "T2: moderate volume"),
            DB_ROW(3, 15, 45, "T3: AMRAP last set"),
            DB_CURL(3, 15, 30, "T3: light"),
        ]),
        workout("Day 3: T1 Bench", "strength", 55, [
            BARBELL_BENCH(5, 3, 180, "T1: heavy"),
            BARBELL_SQUAT(3, 10, 90, "T2: moderate volume"),
            LAT_PULLDOWN(3, 15, 45, "T3: AMRAP last set"),
            TRICEP_PUSHDOWN(3, 15, 30, "T3: light"),
        ]),
        workout("Day 4: T1 Deadlift", "strength", 55, [
            DEADLIFT(5, 3, 240, "T1: heavy"),
            BARBELL_OHP(3, 10, 90, "T2: moderate volume"),
            DB_ROW(3, 15, 45, "T3: AMRAP last set"),
            FACE_PULL(3, 15, 30, "T3: prehab"),
        ]),
    ]


###############################################################################
# 3. AMRAP Linear Progression  (3 days, last set AMRAP)
###############################################################################

def _amrap_linear_progression():
    """3-day full body, 2 working sets + 1 AMRAP set on main lifts."""
    return [
        workout("Day 1: Squat/Bench/Row", "strength", 50, [
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            BARBELL_BENCH(3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            BARBELL_ROW(3, 5, 120, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Day 2: Squat/OHP/Deadlift", "strength", 50, [
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP"),
            BARBELL_OHP(3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            DEADLIFT(3, 5, 240, "2x5 + 1x5+ AMRAP, add 10lb/session"),
            DB_CURL(3, 12, 45, "Accessory"),
        ]),
        workout("Day 3: Squat/Bench/Row", "strength", 50, [
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP"),
            BARBELL_BENCH(3, 5, 180, "2x5 + 1x5+ AMRAP"),
            BARBELL_ROW(3, 5, 120, "2x5 + 1x5+ AMRAP"),
            TRICEP_PUSHDOWN(3, 12, 45, "Accessory"),
        ]),
    ]


###############################################################################
# 4. Tier System Hypertrophy  (4 days, T1/T2/T3 hypertrophy focus)
###############################################################################

def _tier_system_hypertrophy():
    """GZCL-style tiers tuned for hypertrophy: higher rep T2/T3, more T3 volume."""
    return [
        workout("Day 1: Squat Focus", "hypertrophy", 65, [
            BARBELL_SQUAT(4, 4, 150, "T1: moderate-heavy, linear add"),
            RDL(3, 10, 90, "T2: hamstring volume"),
            LEG_EXT(3, 15, 45, "T3: quad isolation"),
            LEG_CURL(3, 15, 45, "T3: hamstring isolation"),
            CALF_RAISE(4, 15, 30, "T3: calves"),
        ]),
        workout("Day 2: Bench Focus", "hypertrophy", 65, [
            BARBELL_BENCH(4, 4, 150, "T1: moderate-heavy"),
            BARBELL_OHP(3, 10, 90, "T2: overhead volume"),
            DB_FLY(3, 15, 45, "T3: chest isolation"),
            DB_LATERAL_RAISE(3, 15, 30, "T3: lateral delt"),
            TRICEP_PUSHDOWN(3, 15, 30, "T3: tricep isolation"),
        ]),
        workout("Day 3: Deadlift Focus", "hypertrophy", 65, [
            DEADLIFT(4, 4, 180, "T1: moderate-heavy"),
            FRONT_SQUAT(3, 10, 90, "T2: quad volume"),
            LAT_PULLDOWN(3, 15, 45, "T3: lat width"),
            CABLE_ROW(3, 15, 45, "T3: back thickness"),
            DB_CURL(3, 15, 30, "T3: bicep isolation"),
        ]),
        workout("Day 4: OHP Focus", "hypertrophy", 65, [
            BARBELL_OHP(4, 4, 150, "T1: moderate-heavy"),
            INCLINE_BENCH(3, 10, 90, "T2: upper chest volume"),
            DB_LATERAL_RAISE(3, 15, 30, "T3: lateral delt"),
            FACE_PULL(3, 15, 30, "T3: rear delt/prehab"),
            TRICEP_OVERHEAD(3, 15, 30, "T3: long head tricep"),
        ]),
    ]


###############################################################################
# 5. Tier System Peaking  (4 days, heavy singles/doubles for peaking)
###############################################################################

def _tier_system_peaking():
    """GZCL tiers tuned for powerlifting peaking: heavy T1, low T2/T3 volume."""
    return [
        workout("Day 1: Squat Peak", "strength", 60, [
            BARBELL_SQUAT(6, 2, 240, "T1: heavy doubles, 85-92% 1RM"),
            FRONT_SQUAT(3, 5, 120, "T2: specificity, moderate"),
            LEG_CURL(3, 10, 45, "T3: light, prehab"),
        ]),
        workout("Day 2: Bench Peak", "strength", 60, [
            BARBELL_BENCH(6, 2, 240, "T1: heavy doubles, 85-92% 1RM"),
            CLOSE_GRIP_BENCH(3, 5, 120, "T2: tricep overload"),
            FACE_PULL(3, 12, 30, "T3: shoulder prehab"),
        ]),
        workout("Day 3: Deadlift Peak", "strength", 60, [
            DEADLIFT(5, 2, 300, "T1: heavy doubles, 85-92% 1RM"),
            BARBELL_ROW(3, 5, 120, "T2: back strength"),
            HANGING_LEG_RAISE(3, 10, 45, "T3: core stability"),
        ]),
        workout("Day 4: OHP Peak", "strength", 60, [
            BARBELL_OHP(6, 2, 240, "T1: heavy doubles, 85-92% 1RM"),
            BARBELL_BENCH(3, 5, 120, "T2: bench volume, light"),
            DB_LATERAL_RAISE(3, 12, 30, "T3: shoulder health"),
        ]),
    ]


###############################################################################
# 6. Ultra High Frequency Training  (6 days, each lift 3x/week)
###############################################################################

def _ultra_high_frequency():
    """6-day squat/bench/deadlift 3x/week each; rotating heavy/moderate/light."""
    return [
        workout("Day 1: Heavy Squat + Light Bench", "strength", 60, [
            BARBELL_SQUAT(5, 3, 180, "Heavy: 85%+ 1RM"),
            BARBELL_BENCH(3, 8, 90, "Light: 65-70% 1RM, technique work"),
            PULLUP(3, 8, 90, "Upper back volume"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Day 2: Heavy Bench + Light Deadlift", "strength", 60, [
            BARBELL_BENCH(5, 3, 180, "Heavy: 85%+ 1RM"),
            DEADLIFT(3, 5, 120, "Light: 65-70% 1RM, speed pulls"),
            DB_OHP(3, 10, 60, "Shoulder volume"),
            TRICEP_PUSHDOWN(3, 12, 45, "Accessory"),
        ]),
        workout("Day 3: Heavy Deadlift + Light Squat", "strength", 60, [
            DEADLIFT(5, 3, 240, "Heavy: 85%+ 1RM"),
            BARBELL_SQUAT(3, 5, 90, "Light: 65-70% 1RM, pause squats"),
            BARBELL_ROW(3, 8, 90, "Back volume"),
            DB_CURL(3, 12, 45, "Accessory"),
        ]),
        workout("Day 4: Moderate Squat + Moderate Bench", "strength", 60, [
            BARBELL_SQUAT(4, 5, 150, "Moderate: 75-80% 1RM"),
            BARBELL_BENCH(4, 5, 120, "Moderate: 75-80% 1RM"),
            LAT_PULLDOWN(3, 10, 60, "Back volume"),
            DB_LATERAL_RAISE(3, 15, 30, "Accessory"),
        ]),
        workout("Day 5: Moderate Deadlift + Moderate OHP", "strength", 60, [
            DEADLIFT(4, 3, 180, "Moderate: 75-80% 1RM"),
            BARBELL_OHP(4, 5, 120, "Moderate"),
            CABLE_ROW(3, 12, 60, "Back volume"),
            HAMMER_CURL(3, 12, 45, "Accessory"),
        ]),
        workout("Day 6: Light Full Body", "strength", 50, [
            BARBELL_SQUAT(3, 5, 90, "Light: technique, 60-65% 1RM"),
            BARBELL_BENCH(3, 5, 90, "Light: technique, 60-65% 1RM"),
            DEADLIFT(2, 3, 120, "Light: speed, 60-65% 1RM"),
            FACE_PULL(3, 15, 30, "Prehab"),
            PLANK(3, 1, 30, "Core: hold 45 seconds"),
        ]),
    ]


###############################################################################
# 7. 6-Week Powerlifting Peak  (4 days, peaking cycle)
###############################################################################

def _6week_powerlifting_peak():
    """4-day powerlifting peaking cycle: heavy/low volume for meet prep."""
    return [
        workout("Day 1: Heavy Squat", "strength", 60, [
            BARBELL_SQUAT(5, 2, 300, "Work up to heavy doubles, 88-95% 1RM"),
            FRONT_SQUAT(3, 3, 150, "Moderate assistance"),
            LEG_CURL(3, 8, 60, "Light prehab"),
            PLANK(3, 1, 30, "Core: hold 45 seconds"),
        ]),
        workout("Day 2: Heavy Bench", "strength", 60, [
            BARBELL_BENCH(5, 2, 300, "Work up to heavy doubles, 88-95% 1RM"),
            CLOSE_GRIP_BENCH(3, 3, 120, "Tricep overload"),
            DB_ROW(3, 8, 60, "Upper back"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
        ]),
        workout("Day 3: Heavy Deadlift", "strength", 60, [
            DEADLIFT(4, 2, 300, "Work up to heavy doubles, 88-95% 1RM"),
            BARBELL_ROW(3, 5, 120, "Back strength, moderate"),
            RDL(2, 5, 90, "Light hamstring work"),
            HANGING_LEG_RAISE(3, 10, 45, "Core"),
        ]),
        workout("Day 4: Light Technique", "strength", 50, [
            BARBELL_SQUAT(3, 3, 120, "Light: 70% 1RM, perfect form"),
            BARBELL_BENCH(3, 3, 120, "Light: 70% 1RM, pause reps"),
            DEADLIFT(2, 3, 120, "Light: 70% 1RM, speed work"),
            BAND_PULL_APART(3, 15, 20, "Prehab"),
        ]),
    ]


###############################################################################
# 8. Full Body Bodyweight Routine  (3 days, bodyweight only)
###############################################################################

def _full_body_bodyweight():
    """3-day bodyweight program: push-ups, pull-ups, squats, dips, rows."""
    return [
        workout("Full Body A", "strength", 45, [
            PULLUP(3, 8, 90, "Progress to 3x8, then add weight or harder variant"),
            PUSHUP(3, 15, 60, "Full ROM, chest to floor"),
            BODYWEIGHT_SQUAT(3, 20, 60, "Below parallel, controlled"),
            DIP(3, 10, 90, "Parallel bars or bench dips"),
            PLANK(3, 1, 30, "Hold 45-60 seconds"),
        ]),
        workout("Full Body B", "strength", 45, [
            CHINUP(3, 8, 90, "Supinated grip, full ROM"),
            DIAMOND_PUSHUP(3, 12, 60, "Hands together, tricep focus"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Bodyweight, per leg"),
            INVERTED_ROW(3, 12, 60, "Body straight, pull chest to bar"),
            HANGING_LEG_RAISE(3, 10, 45, "Controlled, no swinging"),
        ]),
        workout("Full Body C", "strength", 45, [
            PULLUP(3, 8, 90, "Wide grip"),
            PIKE_PUSHUP(3, 10, 60, "Overhead pressing substitute"),
            BODYWEIGHT_SQUAT(3, 20, 60, "Tempo: 3 sec down, 1 sec up"),
            PUSHUP(3, 15, 60, "Standard"),
            SIDE_PLANK(2, 1, 30, "Hold 30 seconds each side"),
            DEAD_BUG(3, 10, 30, "Per side, core stability"),
        ]),
    ]


###############################################################################
# 9. Bodyweight Primer  (3 days, very basic for beginners)
###############################################################################

def _bodyweight_primer():
    """3-day beginner bodyweight: simplified movements, low volume."""
    return [
        workout("Primer Day 1", "strength", 30, [
            PUSHUP(3, 8, 60, "Knee push-ups if needed, build to full"),
            BODYWEIGHT_SQUAT(3, 12, 45, "Below parallel, controlled"),
            INVERTED_ROW(3, 8, 60, "Feet on floor, incline row"),
            PLANK(3, 1, 30, "Hold 20-30 seconds, build up"),
        ]),
        workout("Primer Day 2", "strength", 30, [
            PUSHUP(3, 8, 60, "Work toward full push-ups"),
            DB_LUNGE(3, 8, 45, "Bodyweight lunges, per leg"),
            DEAD_BUG(3, 8, 30, "Per side, core control"),
            GLUTE_BRIDGE(3, 12, 30, "Squeeze glutes at top"),
        ]),
        workout("Primer Day 3", "strength", 30, [
            PUSHUP(3, 8, 60, "Progressing to more reps"),
            BODYWEIGHT_SQUAT(3, 15, 45, "Deeper depth each week"),
            INVERTED_ROW(3, 8, 60, "Lower angle for progression"),
            BIRD_DOG(3, 8, 30, "Per side, core stability"),
            PLANK(2, 1, 30, "Hold 30 seconds"),
        ]),
    ]


###############################################################################
# 10. Advanced Movement Skills  (3 days: handstands, muscle-ups, etc.)
###############################################################################

def _advanced_movement_skills():
    """3-day advanced calisthenics: handstands, L-sits, muscle-ups, pistol squats."""
    return [
        workout("Skill Day 1: Push + Handstand", "strength", 50, [
            PIKE_PUSHUP(4, 8, 90, "Progress to wall handstand push-up"),
            DIP(4, 10, 90, "Weighted or ring dips, muscle-up progression"),
            DIAMOND_PUSHUP(3, 15, 60, "Planche lean progression"),
            PLANK(3, 1, 30, "L-sit progression: hold 15-30 seconds"),
            ex("Wall Handstand Hold", 5, 1, 60, "Hold 30-60 seconds, free-standing goal",
               "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps", "Traps"],
               "advanced", "Fingers spread, push through shoulders, tight core",
               "Pike Push-Up"),
        ]),
        workout("Skill Day 2: Pull + Muscle-Up", "strength", 50, [
            PULLUP(5, 5, 120, "Explosive pull-ups, chest to bar"),
            CHINUP(3, 8, 90, "Slow negative: 5 sec descent"),
            INVERTED_ROW(3, 12, 60, "Feet elevated, chest to bar"),
            HANGING_LEG_RAISE(4, 10, 60, "Toes to bar progression"),
            ex("Muscle-Up Progression", 5, 3, 120,
               "Start with high pull-ups, progress to transition",
               "Bodyweight", "Full Body", "Latissimus Dorsi",
               ["Chest", "Triceps", "Core"], "advanced",
               "Explosive pull, lean forward over bar, push up",
               "Chest-to-Bar Pull-Up"),
        ]),
        workout("Skill Day 3: Legs + Balance", "strength", 50, [
            ex("Pistol Squat", 3, 5, 90, "Per leg, use box/band assistance if needed",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings", "Balance"], "advanced",
               "Extend one leg forward, full depth single-leg squat",
               "Bulgarian Split Squat"),
            JUMP_SQUAT(3, 10, 60, "Explosive, max height"),
            BODYWEIGHT_SQUAT(3, 20, 45, "Tempo: 4 sec eccentric"),
            ex("L-Sit Hold", 5, 1, 60, "Hold 15-30 seconds, progress duration",
               "Bodyweight", "Core", "Hip Flexors",
               ["Rectus Abdominis", "Triceps"], "advanced",
               "Hands on floor or parallettes, legs straight and parallel",
               "Tuck L-Sit"),
            SIDE_PLANK(3, 1, 30, "Hold 30 seconds each side"),
        ]),
    ]


###############################################################################
# 11. Power Hypertrophy Upper Lower  (alias for PHUL)
###############################################################################

def _power_hypertrophy_upper_lower():
    """PHUL: Power Hypertrophy Upper Lower - 4 days.
    This is the same program as PHUL."""
    return [
        workout("Power Upper", "strength", 60, [
            BARBELL_BENCH(4, 5, 180, "Heavy, 85-90% 1RM"),
            BARBELL_ROW(4, 5, 180, "Match bench weight progression"),
            BARBELL_OHP(3, 6, 120, "Moderate-heavy"),
            BARBELL_CURL(3, 8, 60, "Moderate"),
            SKULL_CRUSHER(3, 8, 60, "EZ-bar"),
        ]),
        workout("Power Lower", "strength", 60, [
            BARBELL_SQUAT(4, 5, 180, "Heavy, 85-90% 1RM"),
            DEADLIFT(3, 5, 240, "Heavy, work up to top set"),
            LEG_PRESS(4, 5, 120, "Heavy"),
            LEG_CURL(3, 8, 60, "Moderate-heavy"),
            CALF_RAISE(4, 8, 45, "Heavy, 6-10 reps"),
        ]),
        workout("Hypertrophy Upper", "hypertrophy", 60, [
            DB_INCLINE_PRESS(3, 12, 60, "Moderate, feel the stretch"),
            CABLE_ROW(3, 12, 60, "Moderate, squeeze back"),
            DB_OHP(3, 12, 60, "Controlled tempo"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict form"),
            DB_CURL(3, 12, 45, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Moderate, full extension"),
        ]),
        workout("Hypertrophy Lower", "hypertrophy", 60, [
            FRONT_SQUAT(3, 10, 90, "Moderate, upright torso"),
            RDL(3, 12, 90, "Moderate, slow eccentric"),
            LEG_EXT(3, 15, 45, "Moderate, squeeze at top"),
            LEG_CURL(3, 15, 45, "Moderate, full ROM"),
            HIP_THRUST(3, 12, 60, "Moderate-heavy"),
            CALF_RAISE(4, 15, 30, "Moderate, full stretch"),
        ]),
    ]


###############################################################################
# 12. Power Hypertrophy Adaptive  (PHUL with RPE autoregulation)
###############################################################################

def _power_hypertrophy_adaptive():
    """PHUL variant with RPE-based autoregulation instead of fixed percentages."""
    return [
        workout("Power Upper (RPE)", "strength", 60, [
            BARBELL_BENCH(4, 5, 180, "RPE 8-9: leave 1-2 reps in reserve"),
            BARBELL_ROW(4, 5, 180, "RPE 8-9: match effort to bench"),
            BARBELL_OHP(3, 6, 120, "RPE 7-8: moderate effort"),
            PULLUP(3, 8, 90, "RPE 7-8: weighted if needed"),
            BARBELL_CURL(3, 10, 60, "RPE 7: moderate"),
            SKULL_CRUSHER(3, 10, 60, "RPE 7: moderate"),
        ]),
        workout("Power Lower (RPE)", "strength", 60, [
            BARBELL_SQUAT(4, 5, 180, "RPE 8-9: leave 1-2 reps in reserve"),
            DEADLIFT(3, 5, 240, "RPE 8-9: top set then back-off"),
            LEG_PRESS(3, 8, 120, "RPE 7-8: moderate"),
            LEG_CURL(3, 10, 60, "RPE 7: moderate"),
            CALF_RAISE(4, 10, 45, "RPE 7-8: moderate-heavy"),
        ]),
        workout("Hypertrophy Upper (RPE)", "hypertrophy", 60, [
            DB_INCLINE_PRESS(3, 12, 60, "RPE 7: controlled, feel stretch"),
            CABLE_ROW(3, 12, 60, "RPE 7: squeeze at contraction"),
            DB_OHP(3, 12, 60, "RPE 7: controlled tempo"),
            DB_LATERAL_RAISE(4, 15, 30, "RPE 7: strict form, no momentum"),
            DB_CURL(3, 12, 45, "RPE 7: moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "RPE 7: full extension"),
        ]),
        workout("Hypertrophy Lower (RPE)", "hypertrophy", 60, [
            FRONT_SQUAT(3, 10, 90, "RPE 7: upright torso"),
            RDL(3, 12, 90, "RPE 7: slow eccentric, hamstring focus"),
            LEG_EXT(3, 15, 45, "RPE 7: squeeze quad at top"),
            LEG_CURL(3, 15, 45, "RPE 7: full ROM"),
            HIP_THRUST(3, 12, 60, "RPE 7-8: moderate-heavy"),
            CALF_RAISE(4, 15, 30, "RPE 7: full stretch at bottom"),
        ]),
    ]


###############################################################################
# 13. Mix & Match Strength  (4 days, customizable template)
###############################################################################

def _mix_match_strength():
    """4-day flexible strength template: upper/lower with variety."""
    return [
        workout("Upper Push Dominant", "strength", 55, [
            BARBELL_BENCH(4, 6, 120, "Primary push, progressive overload"),
            BARBELL_OHP(3, 8, 90, "Secondary press"),
            DB_INCLINE_PRESS(3, 10, 60, "Accessory"),
            TRICEP_PUSHDOWN(3, 12, 45, "Isolation"),
            DB_LATERAL_RAISE(3, 15, 30, "Delt volume"),
        ]),
        workout("Lower Squat Dominant", "strength", 55, [
            BARBELL_SQUAT(4, 6, 180, "Primary squat, progressive overload"),
            RDL(3, 8, 90, "Hamstring assistance"),
            LEG_PRESS(3, 10, 90, "Quad volume"),
            LEG_CURL(3, 12, 60, "Hamstring isolation"),
            CALF_RAISE(4, 15, 30, "Calf work"),
        ]),
        workout("Upper Pull Dominant", "strength", 55, [
            BARBELL_ROW(4, 6, 120, "Primary pull, progressive overload"),
            PULLUP(3, 8, 90, "Vertical pull"),
            CABLE_ROW(3, 10, 60, "Accessory"),
            FACE_PULL(3, 15, 30, "Rear delt / prehab"),
            DB_CURL(3, 12, 45, "Bicep volume"),
            HAMMER_CURL(3, 12, 45, "Brachialis"),
        ]),
        workout("Lower Hinge Dominant", "strength", 55, [
            DEADLIFT(3, 5, 240, "Primary hinge, progressive overload"),
            FRONT_SQUAT(3, 8, 90, "Quad assistance"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Unilateral work"),
            LEG_CURL(3, 12, 60, "Hamstring volume"),
            HANGING_LEG_RAISE(3, 12, 45, "Core"),
        ]),
    ]


###############################################################################
# 14. Comprehensive Hypertrophy  (5 days, bro split with scientific volume)
###############################################################################

def _comprehensive_hypertrophy():
    """5-day bro split: chest, back, shoulders, legs, arms. 15-20 sets/muscle/week."""
    return [
        workout("Chest Day", "hypertrophy", 60, [
            BARBELL_BENCH(4, 8, 120, "Progressive overload, moderate weight"),
            DB_INCLINE_PRESS(3, 10, 60, "Upper chest focus"),
            CABLE_FLY(3, 12, 45, "Low-to-high and high-to-low"),
            PEC_DECK(3, 12, 45, "Squeeze at contraction"),
            DB_PULLOVER(3, 12, 60, "Stretch at bottom"),
        ]),
        workout("Back Day", "hypertrophy", 60, [
            DEADLIFT(3, 6, 180, "Heavy compound, back thickness"),
            PULLUP(4, 8, 90, "Wide grip, lat width"),
            CABLE_ROW(3, 12, 60, "Close grip, squeeze"),
            LAT_PULLDOWN(3, 12, 60, "Behind neck or V-grip"),
            DB_ROW(3, 10, 60, "Single arm, squeeze at top"),
            FACE_PULL(3, 15, 30, "Rear delt, prehab"),
        ]),
        workout("Shoulders & Traps", "hypertrophy", 55, [
            BARBELL_OHP(4, 8, 120, "Main press"),
            ARNOLD_PRESS(3, 10, 60, "Rotational press"),
            DB_LATERAL_RAISE(4, 15, 30, "Strict form, multiple sets"),
            FACE_PULL(3, 15, 30, "Rear delt"),
            REVERSE_PEC_DECK(3, 15, 30, "Rear delt isolation"),
            DB_SHRUG(3, 15, 30, "Heavy, squeeze at top"),
        ]),
        workout("Legs", "hypertrophy", 65, [
            BARBELL_SQUAT(4, 8, 180, "Primary quad builder"),
            RDL(3, 10, 90, "Hamstring stretch"),
            LEG_PRESS(3, 12, 90, "High and narrow foot = quads"),
            LEG_EXT(3, 15, 45, "Quad isolation"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            HIP_THRUST(3, 12, 60, "Glute focus"),
            CALF_RAISE(4, 15, 30, "Full ROM"),
        ]),
        workout("Arms", "hypertrophy", 50, [
            BARBELL_CURL(3, 10, 60, "Heavy bicep work"),
            CLOSE_GRIP_BENCH(3, 10, 90, "Heavy tricep compound"),
            DB_CURL(3, 12, 45, "Incline or preacher variant"),
            SKULL_CRUSHER(3, 12, 60, "EZ-bar, stretch at bottom"),
            HAMMER_CURL(3, 12, 45, "Brachialis and forearm"),
            TRICEP_PUSHDOWN(3, 15, 30, "Rope, full extension"),
            CONCENTRATION_CURL(2, 12, 30, "Peak contraction"),
            TRICEP_OVERHEAD(2, 15, 30, "Long head stretch"),
        ]),
    ]


###############################################################################
# 15. Metallicadpa PPL  (same as Reddit PPL)
###############################################################################

def _metallicadpa_ppl():
    """Metallicadpa's PPL - identical to Reddit PPL."""
    return [
        workout("Push A (Bench Focus)", "strength", 60, [
            BARBELL_BENCH(4, 5, 180, "Linear progression +2.5lb/session"),
            BARBELL_OHP(3, 10, 90, "Volume work"),
            DB_INCLINE_PRESS(3, 10, 60, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Superset with lateral raise"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            TRICEP_OVERHEAD(3, 12, 45, "Cable or dumbbell"),
        ]),
        workout("Pull A (Deadlift Focus)", "strength", 60, [
            DEADLIFT(1, 5, 300, "Linear progression +5lb/session"),
            BARBELL_ROW(3, 10, 90, "Moderate weight"),
            PULLUP(3, 10, 90, "Or lat pulldown"),
            FACE_PULL(5, 20, 30, "Light, high reps for shoulder health"),
            DB_CURL(4, 10, 45, "Moderate"),
            HAMMER_CURL(4, 10, 45, "Moderate"),
        ]),
        workout("Legs A (Squat Focus)", "strength", 60, [
            BARBELL_SQUAT(3, 5, 180, "Linear progression +2.5lb/session"),
            RDL(3, 10, 90, "Moderate, hamstring focus"),
            LEG_PRESS(3, 10, 90, "Heavy"),
            LEG_CURL(3, 10, 60, "Moderate"),
            CALF_RAISE(5, 12, 30, "Moderate, full ROM"),
        ]),
        workout("Push B (OHP Focus)", "strength", 60, [
            BARBELL_OHP(4, 5, 180, "Linear progression +2.5lb/session"),
            BARBELL_BENCH(3, 10, 90, "Volume work"),
            DB_INCLINE_PRESS(3, 10, 60, "Moderate"),
            TRICEP_PUSHDOWN(3, 12, 45, "Superset with lateral raise"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict"),
            TRICEP_OVERHEAD(3, 12, 45, "Cable or dumbbell"),
        ]),
        workout("Pull B (Row Focus)", "strength", 60, [
            BARBELL_ROW(4, 5, 180, "Heavy barbell rows"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip"),
            CABLE_ROW(3, 10, 60, "Close grip, squeeze"),
            FACE_PULL(5, 20, 30, "Light, shoulder health"),
            BARBELL_CURL(4, 10, 45, "Moderate"),
            HAMMER_CURL(4, 10, 45, "Moderate"),
        ]),
        workout("Legs B (Volume)", "strength", 60, [
            BARBELL_SQUAT(3, 5, 180, "Same weight as Legs A"),
            SUMO_DEADLIFT(3, 10, 90, "Moderate, glute focus"),
            LEG_EXT(3, 10, 60, "Moderate, squeeze"),
            LEG_CURL(3, 10, 60, "Moderate"),
            CALF_RAISE(5, 12, 30, "Moderate, full ROM"),
        ]),
    ]


###############################################################################
# 16. Ivysaur 4-4-8  (3 days, A/B alternating, 4x4 and 4x8)
###############################################################################

def _ivysaur_448():
    """Ivysaur 4-4-8: 3-day A/B, compounds at 4x4 (heavy) and 4x8 (volume).
    Each lift alternates between heavy and volume days."""
    return [
        workout("Workout A", "strength", 45, [
            BARBELL_BENCH(4, 4, 180, "Heavy: +2.5lb/session"),
            BARBELL_OHP(4, 8, 90, "Volume: +2.5lb/session"),
            BARBELL_SQUAT(4, 4, 180, "Heavy: +5lb/session"),
            CHINUP(4, 8, 90, "Volume: add weight when hitting 4x8"),
            BARBELL_ROW(4, 4, 120, "Heavy: +5lb/session"),
        ]),
        workout("Workout B", "strength", 45, [
            BARBELL_BENCH(4, 8, 90, "Volume: same weight as heavy day"),
            BARBELL_OHP(4, 4, 180, "Heavy: +2.5lb/session"),
            DEADLIFT(4, 4, 240, "Heavy: +5lb/session"),
            CHINUP(4, 4, 120, "Heavy: add weight when hitting 4x4"),
            BARBELL_ROW(4, 8, 90, "Volume: +5lb/session"),
        ]),
        workout("Workout A (repeat)", "strength", 45, [
            BARBELL_BENCH(4, 4, 180, "Heavy: +2.5lb/session"),
            BARBELL_OHP(4, 8, 90, "Volume: same weight"),
            BARBELL_SQUAT(4, 8, 120, "Volume: +5lb/session"),
            CHINUP(4, 8, 90, "Volume"),
            BARBELL_ROW(4, 4, 120, "Heavy: +5lb/session"),
        ]),
    ]


###############################################################################
# 17. Greyskull LP  (3 days, A/B alternating, AMRAP last set)
###############################################################################

def _greyskull_lp():
    """Greyskull LP: 3 days A/B, 2x5 + 1xAMRAP, OHP/Bench alternate,
    chin-ups/rows alternate, squat every day (or deadlift on B)."""
    return [
        workout("Workout A", "strength", 40, [
            BARBELL_OHP(3, 5, 180, "2x5 + 1x5+ AMRAP, add 2.5lb/session"),
            CHINUP(3, 8, 90, "2x6-8 + 1xAMRAP, add weight at 3x8"),
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session"),
        ]),
        workout("Workout B", "strength", 40, [
            BARBELL_BENCH(3, 5, 180, "2x5 + 1x5+ AMRAP, add 2.5lb/session"),
            BARBELL_ROW(3, 5, 120, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            DEADLIFT(1, 5, 300, "1x5+ AMRAP, add 10lb/session"),
        ]),
        workout("Workout A (repeat)", "strength", 40, [
            BARBELL_OHP(3, 5, 180, "2x5 + 1x5+ AMRAP"),
            CHINUP(3, 8, 90, "2x6-8 + 1xAMRAP"),
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP"),
        ]),
    ]


###############################################################################
# 18. Reddit Beginner Routine  (3 days, full body)
###############################################################################

def _reddit_beginner_routine():
    """r/Fitness Basic Beginner Routine: 3-day full body, linear progression.
    Alternating A/B with main barbell lifts + optional accessories."""
    return [
        workout("Workout A", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            BARBELL_ROW(3, 5, 120, "Add 5lb every session, last set AMRAP"),
            FACE_PULL(3, 15, 30, "Optional accessory"),
        ]),
        workout("Workout B", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            BARBELL_OHP(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            DEADLIFT(1, 5, 300, "Add 10lb every session, AMRAP set"),
            CHINUP(3, 8, 90, "Optional accessory, band-assisted if needed"),
        ]),
        workout("Workout A (repeat)", "strength", 45, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb every session, last set AMRAP"),
            BARBELL_ROW(3, 5, 120, "Add 5lb every session, last set AMRAP"),
            DB_CURL(3, 12, 45, "Optional accessory"),
        ]),
    ]


###############################################################################
# 19. Fierce 5  (3 days, A/B split with compounds + accessories)
###############################################################################

def _fierce_5():
    """Fierce 5: 3-day A/B, 5 exercises per session, compounds + isolations."""
    return [
        workout("Workout A", "strength", 50, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb/session"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb/session"),
            BARBELL_ROW(3, 5, 120, "Add 5lb/session"),
            DB_FLY(2, 10, 45, "Chest accessory"),
            LEG_CURL(2, 10, 45, "Hamstring accessory"),
        ]),
        workout("Workout B", "strength", 50, [
            FRONT_SQUAT(3, 5, 120, "Or BARBELL_SQUAT, add 5lb/session"),
            BARBELL_OHP(3, 5, 180, "Add 5lb/session"),
            DEADLIFT(1, 5, 300, "Add 10lb/session"),
            PULLUP(2, 10, 90, "Or lat pulldown"),
            LEG_EXT(2, 10, 45, "Quad accessory"),
        ]),
        workout("Workout A (repeat)", "strength", 50, [
            BARBELL_SQUAT(3, 5, 180, "Add 5lb/session"),
            BARBELL_BENCH(3, 5, 180, "Add 5lb/session"),
            BARBELL_ROW(3, 5, 120, "Add 5lb/session"),
            DB_FLY(2, 10, 45, "Chest accessory"),
            LEG_CURL(2, 10, 45, "Hamstring accessory"),
        ]),
    ]


###############################################################################
# 20. ICF 5x5 (Ice Cream Fitness)  (3 days, SL5x5 + accessories)
###############################################################################

def _icf_5x5():
    """Ice Cream Fitness 5x5: StrongLifts base + curls, extensions, abs."""
    return [
        workout("Workout A", "strength", 65, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(5, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(5, 5, 120, "Add 5lb every session"),
            DB_SHRUG(3, 8, 60, "Heavy, squeeze at top"),
            SKULL_CRUSHER(3, 8, 60, "EZ-bar"),
            BARBELL_CURL(3, 8, 60, "Straight bar"),
            CABLE_FLY(3, 8, 45, "Or hyperextension"),
            HANGING_LEG_RAISE(3, 10, 45, "Or ab wheel"),
        ]),
        workout("Workout B", "strength", 65, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_OHP(5, 5, 180, "Add 5lb every session"),
            DEADLIFT(1, 5, 300, "Add 10lb every session"),
            BARBELL_ROW(5, 5, 120, "Add 5lb every session"),
            CLOSE_GRIP_BENCH(3, 8, 90, "Tricep focus"),
            BARBELL_CURL(3, 8, 60, "Straight bar"),
            CABLE_FLY(3, 8, 45, "Or hyperextension"),
            HANGING_LEG_RAISE(3, 10, 45, "Or ab wheel"),
        ]),
        workout("Workout A (repeat)", "strength", 65, [
            BARBELL_SQUAT(5, 5, 180, "Add 5lb every session"),
            BARBELL_BENCH(5, 5, 180, "Add 5lb every session"),
            BARBELL_ROW(5, 5, 120, "Add 5lb every session"),
            DB_SHRUG(3, 8, 60, "Heavy, squeeze at top"),
            SKULL_CRUSHER(3, 8, 60, "EZ-bar"),
            BARBELL_CURL(3, 8, 60, "Straight bar"),
            CABLE_FLY(3, 8, 45, "Or hyperextension"),
            HANGING_LEG_RAISE(3, 10, 45, "Or ab wheel"),
        ]),
    ]


###############################################################################
# 21. Candito LP  (4 days, upper/lower linear progression)
###############################################################################

def _candito_lp():
    """Candito Linear Program: 4 days upper/lower, control/power split."""
    return [
        workout("Lower Body Control", "strength", 60, [
            BARBELL_SQUAT(3, 6, 180, "Control day: moderate weight, perfect form"),
            RDL(3, 8, 90, "Hamstring focus, controlled eccentric"),
            LEG_PRESS(3, 10, 90, "Quad volume"),
            LEG_CURL(3, 10, 60, "Hamstring isolation"),
            CALF_RAISE(4, 12, 30, "Moderate weight"),
        ]),
        workout("Upper Body Control", "strength", 60, [
            BARBELL_BENCH(3, 6, 120, "Control day: moderate weight, paused reps"),
            BARBELL_ROW(3, 8, 90, "Upper back volume"),
            BARBELL_OHP(3, 8, 90, "Moderate pressing"),
            PULLUP(3, 8, 90, "Or lat pulldown"),
            DB_CURL(3, 12, 45, "Light accessory"),
            TRICEP_PUSHDOWN(3, 12, 45, "Light accessory"),
        ]),
        workout("Lower Body Power", "strength", 60, [
            BARBELL_SQUAT(4, 3, 240, "Power day: heavy, 85-90% 1RM"),
            DEADLIFT(3, 3, 240, "Heavy pulls"),
            FRONT_SQUAT(3, 5, 120, "Moderate assistance"),
            LEG_CURL(3, 8, 60, "Prehab"),
        ]),
        workout("Upper Body Power", "strength", 60, [
            BARBELL_BENCH(4, 3, 240, "Power day: heavy, 85-90% 1RM"),
            BARBELL_ROW(3, 5, 120, "Heavy rows"),
            BARBELL_OHP(3, 5, 120, "Heavy pressing"),
            PULLUP(3, 5, 120, "Weighted or strict"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
    ]


###############################################################################
# 22. Reddit Bodyweightfitness Recommended Routine (3 days)
###############################################################################

def _reddit_bwf_rr():
    """r/bodyweightfitness Recommended Routine: 3 days, exercise pairs.
    Pair 1: pull-up/squat, Pair 2: dip/hinge, Pair 3: row/push-up."""
    return [
        workout("RR Full Body A", "strength", 55, [
            PULLUP(3, 8, 90, "Progression: negatives -> assisted -> full, 3x5-8"),
            BODYWEIGHT_SQUAT(3, 15, 60, "Progress to pistol squat or weighted"),
            DIP(3, 8, 90, "Progression: bench dip -> parallel bar -> weighted, 3x5-8"),
            SINGLE_LEG_RDL(3, 8, 60, "Hinge pattern, per leg"),
            INVERTED_ROW(3, 8, 60, "Progression: incline -> horizontal -> feet elevated"),
            PUSHUP(3, 12, 60, "Progression: incline -> standard -> diamond -> archer"),
            DEAD_BUG(3, 10, 30, "Core triplet"),
            PLANK(3, 1, 30, "Core triplet: hold 30-60 sec"),
            SIDE_PLANK(2, 1, 30, "Core triplet: hold 30 sec each side"),
        ]),
        workout("RR Full Body B", "strength", 55, [
            PULLUP(3, 8, 90, "Same progression as Day A"),
            BODYWEIGHT_SQUAT(3, 15, 60, "Progress to single-leg variants"),
            DIP(3, 8, 90, "Same progression as Day A"),
            GLUTE_BRIDGE(3, 15, 30, "Single-leg progression, hinge pattern"),
            INVERTED_ROW(3, 8, 60, "Same progression as Day A"),
            DIAMOND_PUSHUP(3, 10, 60, "Push-up progression"),
            BICYCLE_CRUNCH(3, 15, 30, "Core triplet"),
            PLANK(3, 1, 30, "Core triplet: hold 30-60 sec"),
            BIRD_DOG(3, 10, 30, "Core triplet: per side"),
        ]),
        workout("RR Full Body C", "strength", 55, [
            CHINUP(3, 8, 90, "Alternating grip variation"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Bodyweight, per leg"),
            DIP(3, 8, 90, "Ring dips if available"),
            SINGLE_LEG_RDL(3, 8, 60, "Per leg, hinge pattern"),
            INVERTED_ROW(3, 8, 60, "Wide grip variation"),
            PIKE_PUSHUP(3, 8, 60, "Push-up progression toward handstand push-up"),
            HANGING_LEG_RAISE(3, 8, 45, "Core: progress from knee raises"),
            PLANK(3, 1, 30, "Hold 45-60 seconds"),
            RUSSIAN_TWIST(3, 15, 30, "Bodyweight or light weight"),
        ]),
    ]


###############################################################################
# 23. GSLP  (alias for Greyskull LP)
###############################################################################

# Points to the same function as Greyskull LP
_gslp = _greyskull_lp


###############################################################################
# 24. Coolcicada PPL  (6 days, PPL with specific exercise selection)
###############################################################################

def _coolcicada_ppl():
    """Coolcicada PPL: 6-day Push/Pull/Legs with specific exercise picks."""
    return [
        workout("Push A", "strength", 55, [
            BARBELL_BENCH(4, 5, 180, "Linear progression, heavy day"),
            BARBELL_OHP(3, 8, 90, "Standing strict press"),
            DB_INCLINE_PRESS(3, 10, 60, "Upper chest volume"),
            TRICEP_PUSHDOWN(3, 12, 45, "Rope attachment"),
            DB_LATERAL_RAISE(3, 15, 30, "Strict, no momentum"),
            TRICEP_OVERHEAD(3, 12, 45, "Cable or dumbbell"),
        ]),
        workout("Pull A", "strength", 55, [
            DEADLIFT(1, 5, 300, "Heavy single work set"),
            PULLUP(3, 8, 90, "Weighted when possible"),
            CABLE_ROW(3, 10, 60, "Close grip"),
            FACE_PULL(3, 15, 30, "Rear delt / prehab"),
            BARBELL_CURL(3, 10, 60, "Straight bar"),
            HAMMER_CURL(3, 10, 45, "Brachialis focus"),
        ]),
        workout("Legs A", "strength", 60, [
            BARBELL_SQUAT(4, 5, 180, "Linear progression, heavy day"),
            RDL(3, 8, 90, "Hamstring stretch, moderate-heavy"),
            LEG_PRESS(3, 12, 90, "High reps, quad focus"),
            LEG_CURL(3, 12, 60, "Moderate"),
            CALF_RAISE(5, 15, 30, "Full ROM, moderate"),
        ]),
        workout("Push B", "strength", 55, [
            BARBELL_OHP(4, 5, 180, "Linear progression, heavy day"),
            BARBELL_BENCH(3, 8, 90, "Volume work"),
            DB_FLY(3, 12, 45, "Chest isolation"),
            SKULL_CRUSHER(3, 10, 60, "EZ-bar"),
            DB_LATERAL_RAISE(3, 15, 30, "Strict form"),
            CABLE_FLY(3, 12, 45, "Low-to-high for upper chest"),
        ]),
        workout("Pull B", "strength", 55, [
            BARBELL_ROW(4, 5, 180, "Heavy day, strict form"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip, lat focus"),
            DB_ROW(3, 10, 60, "Single arm, squeeze at top"),
            FACE_PULL(3, 15, 30, "Prehab"),
            DB_CURL(3, 12, 45, "Seated incline"),
            CONCENTRATION_CURL(3, 12, 30, "Peak contraction"),
        ]),
        workout("Legs B", "strength", 60, [
            FRONT_SQUAT(4, 6, 120, "Quad dominant"),
            SUMO_DEADLIFT(3, 8, 120, "Glute and adductor focus"),
            LEG_EXT(3, 15, 45, "Quad isolation"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            CALF_RAISE(5, 15, 30, "Full ROM, moderate"),
            HIP_THRUST(3, 12, 60, "Glute finisher"),
        ]),
    ]


###############################################################################
# 25. Lyle McDonald GBR  (4 days, Generic Bulking Routine, upper/lower)
###############################################################################

def _lyle_mcdonald_gbr():
    """Lyle McDonald's Generic Bulking Routine: 4-day upper/lower for hypertrophy.
    Upper: flat bench, row, incline/OHP, pulldown/chin, tricep, bicep.
    Lower: squat, leg curl, RDL/leg press, calf, abs."""
    return [
        workout("Upper Body 1", "hypertrophy", 55, [
            BARBELL_BENCH(3, 8, 120, "Moderate weight, 6-8 reps, progress when hitting 3x8"),
            BARBELL_ROW(3, 8, 90, "Match bench reps, 6-8"),
            DB_INCLINE_PRESS(2, 12, 60, "Higher reps, 10-12"),
            LAT_PULLDOWN(2, 12, 60, "Higher reps, 10-12"),
            TRICEP_PUSHDOWN(1, 12, 45, "1-2 sets, 12-15 reps"),
            BARBELL_CURL(1, 12, 45, "1-2 sets, 12-15 reps"),
        ]),
        workout("Lower Body 1", "hypertrophy", 55, [
            BARBELL_SQUAT(3, 8, 180, "6-8 reps, progressive overload"),
            LEG_CURL(3, 8, 60, "6-8 reps"),
            LEG_PRESS(2, 12, 90, "10-12 reps, or RDL"),
            CALF_RAISE(3, 8, 45, "6-8 reps, heavy"),
            HANGING_LEG_RAISE(3, 15, 45, "Abs, 12-15 reps"),
        ]),
        workout("Upper Body 2", "hypertrophy", 55, [
            BARBELL_OHP(3, 8, 120, "6-8 reps, or flat bench variant"),
            CHINUP(3, 8, 90, "6-8 reps, weighted if possible"),
            DB_BENCH(2, 12, 60, "10-12 reps, chest volume"),
            CABLE_ROW(2, 12, 60, "10-12 reps, close grip"),
            TRICEP_OVERHEAD(1, 12, 45, "1-2 sets, 12-15 reps"),
            HAMMER_CURL(1, 12, 45, "1-2 sets, 12-15 reps"),
        ]),
        workout("Lower Body 2", "hypertrophy", 55, [
            RDL(3, 8, 120, "6-8 reps, hamstring focus"),
            LEG_PRESS(3, 8, 90, "6-8 reps, or front squat"),
            LEG_EXT(2, 12, 45, "10-12 reps, quad isolation"),
            SEATED_CALF_RAISE(3, 8, 45, "6-8 reps, heavy"),
            PLANK(3, 1, 30, "Core work, hold 45-60 seconds"),
        ]),
    ]


###############################################################################
# 26. AlphaDestiny Novice  (3-4 days, focus on neck, traps, back thickness)
###############################################################################

def _alphadestiny_novice():
    """AlphaDestiny Novice: emphasizes trap/neck/back development.
    A/B alternating, 3 days per week."""
    return [
        workout("Workout A", "strength", 55, [
            BARBELL_SQUAT(3, 5, 180, "Linear progression, add 5lb/session"),
            BARBELL_OHP(3, 5, 180, "Linear progression, add 2.5lb/session"),
            CHINUP(3, 8, 90, "Weighted when hitting 3x8"),
            DB_SHRUG(3, 15, 45, "Heavy, 3-sec hold at top, trap emphasis"),
            BARBELL_CURL(2, 10, 60, "Moderate, strict"),
            ex("Neck Curl", 3, 15, 30, "Light plate on forehead, lying on bench",
               "Bodyweight", "Neck", "Sternocleidomastoid",
               ["Deep Neck Flexors"], "beginner",
               "Controlled, full ROM, chin to chest", "Chin Tuck"),
        ]),
        workout("Workout B", "strength", 55, [
            DEADLIFT(3, 5, 240, "Linear progression, add 10lb/session"),
            BARBELL_BENCH(3, 5, 180, "Linear progression, add 2.5lb/session"),
            BARBELL_ROW(3, 8, 90, "Pendlay-style, from floor, back thickness"),
            DB_SHRUG(3, 15, 45, "Heavy, 3-sec hold at top"),
            FACE_PULL(3, 15, 30, "Rear delt and external rotation"),
            ex("Neck Extension", 3, 15, 30, "Light plate on back of head, lying face down",
               "Bodyweight", "Neck", "Trapezius",
               ["Splenius", "Semispinalis"], "beginner",
               "Controlled, full ROM", "Band Neck Extension"),
        ]),
        workout("Workout A (repeat)", "strength", 55, [
            BARBELL_SQUAT(3, 5, 180, "Linear progression"),
            BARBELL_OHP(3, 5, 180, "Linear progression"),
            CHINUP(3, 8, 90, "Weighted when hitting 3x8"),
            DB_SHRUG(3, 15, 45, "Heavy, trap emphasis"),
            BARBELL_CURL(2, 10, 60, "Moderate, strict"),
            FARMER_WALK(3, 1, 60, "Heavy, 40 yards, grip and traps"),
        ]),
    ]


###############################################################################
# 27. Phraks GSLP  (3 days, simplified Greyskull: 3 exercises/day, AMRAP)
###############################################################################

def _phraks_gslp():
    """Phrak's Greyskull LP variant: simplified to 3 exercises per day.
    A: OHP, Chin-Up, Squat.  B: Bench, Row, Deadlift.
    All lifts 2x5 + 1x5+ AMRAP on last set."""
    return [
        workout("Workout A", "strength", 35, [
            BARBELL_OHP(3, 5, 180, "2x5 + 1x5+ AMRAP, add 2.5lb/session"),
            CHINUP(3, 5, 90, "2x5 + 1x5+ AMRAP, add weight at 3x8+"),
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP, add 5lb/session"),
        ]),
        workout("Workout B", "strength", 35, [
            BARBELL_BENCH(3, 5, 180, "2x5 + 1x5+ AMRAP, add 2.5lb/session"),
            BARBELL_ROW(3, 5, 120, "2x5 + 1x5+ AMRAP, add 5lb/session"),
            DEADLIFT(1, 5, 300, "1x5+ AMRAP, add 10lb/session"),
        ]),
        workout("Workout A (repeat)", "strength", 35, [
            BARBELL_OHP(3, 5, 180, "2x5 + 1x5+ AMRAP"),
            CHINUP(3, 5, 90, "2x5 + 1x5+ AMRAP"),
            BARBELL_SQUAT(3, 5, 180, "2x5 + 1x5+ AMRAP"),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS REGISTRY
###############################################################################

BATCH_WORKOUTS = {
    # New programs
    "Basic Barbell Beginner": _basic_barbell_beginner,
    "Tiered Linear Progression": _tiered_linear_progression,
    "AMRAP Linear Progression": _amrap_linear_progression,
    "Tier System Hypertrophy": _tier_system_hypertrophy,
    "Tier System Peaking": _tier_system_peaking,
    "Ultra High Frequency Training": _ultra_high_frequency,
    "6-Week Powerlifting Peak": _6week_powerlifting_peak,
    "Full Body Bodyweight Routine": _full_body_bodyweight,
    "Bodyweight Primer": _bodyweight_primer,
    "Advanced Movement Skills": _advanced_movement_skills,
    "Power Hypertrophy Upper Lower": _power_hypertrophy_upper_lower,
    "Power Hypertrophy Adaptive": _power_hypertrophy_adaptive,
    "Mix & Match Strength": _mix_match_strength,
    "Comprehensive Hypertrophy": _comprehensive_hypertrophy,
    "Metallicadpa PPL": _metallicadpa_ppl,
    "Ivysaur 4-4-8": _ivysaur_448,
    "Greyskull LP": _greyskull_lp,
    "Reddit Beginner Routine": _reddit_beginner_routine,
    "Fierce 5": _fierce_5,
    "ICF 5x5": _icf_5x5,
    "Candito LP": _candito_lp,
    "Reddit bodyweightfitness RR": _reddit_bwf_rr,
    "GSLP": _gslp,
    "Coolcicada PPL": _coolcicada_ppl,
    "Lyle McDonald GBR": _lyle_mcdonald_gbr,
    "AlphaDestiny Novice": _alphadestiny_novice,
    "Phraks GSLP": _phraks_gslp,
}
