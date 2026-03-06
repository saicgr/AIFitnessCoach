#!/usr/bin/env python3
"""
Batch 12: Lifestyle/Life Events, Tactical/Military, and Misc Lifestyle Programs
================================================================================
30 programs covering:
  - Lifestyle/Life Events (14): New Year, Birthday, holidays, seasonal, formal events,
    personal milestones
  - Tactical/Military (5): Tactical fitness, special forces prep, first responder,
    prison-style, tactical hybrid
  - Misc Lifestyle (11): Professional, self-defense, lunch break, seated, hotel,
    playground, backyard, farm, HYROX
"""

from exercise_lib import *


###############################################################################
# LIFE EVENTS
###############################################################################

def _new_year_new_you():
    """New Year fresh start - full body reset with cardio and strength."""
    return [
        workout("New Year Full Body Reset", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Start light, focus on form"),
            PUSHUP(3, 12, 45, "Bodyweight, reset your baseline"),
            DB_ROW(3, 12, 60, "Moderate weight"),
            GLUTE_BRIDGE(3, 15, 30, "Bodyweight or banded"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
            BICYCLE_CRUNCH(3, 20, 30, "Controlled tempo"),
        ]),
        workout("New Year Cardio Kickstart", "cardio", 35, [
            JUMPING_JACK(3, 30, 15, "30 seconds"),
            HIGH_KNEES(3, 30, 20, "30 seconds, drive knees up"),
            BURPEE(3, 10, 30, "Modify as needed"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds fast"),
            JUMP_SQUAT(3, 10, 30, "Explosive, land soft"),
            JUMPING_LUNGE(3, 10, 30, "Alternate legs"),
        ]),
        workout("New Year Strength Foundation", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Learn the movement, light weight"),
            BARBELL_BENCH(3, 8, 90, "Focus on form over weight"),
            DEADLIFT(1, 5, 180, "Hip hinge pattern, start light"),
            BARBELL_OHP(3, 8, 90, "Build that overhead strength"),
            PULLUP(3, 5, 90, "Use band assist if needed"),
            CRUNCHES(3, 20, 30, "Strong core foundation"),
        ]),
    ]


def _birthday_shred():
    """Birthday Shred - look and feel amazing for your special day."""
    return [
        workout("Birthday Upper Body Pump", "strength", 50, [
            DB_BENCH(4, 12, 60, "Moderate weight, full pump"),
            DB_ROW(4, 12, 60, "Each side"),
            DB_OHP(3, 12, 60, "Overhead for shoulder width"),
            DB_LATERAL_RAISE(4, 15, 30, "Light, strict form"),
            DB_CURL(3, 12, 45, "Squeeze at top"),
            TRICEP_PUSHDOWN(3, 15, 30, "Full extension"),
        ]),
        workout("Birthday Lower Body Sculpt", "strength", 50, [
            BARBELL_SQUAT(4, 10, 90, "Heavy-ish, control"),
            RDL(3, 12, 60, "Hip hinge, hamstring stretch"),
            LEG_PRESS(3, 12, 60, "Heavy, full depth"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Per leg, torch the quads"),
            CALF_RAISE(4, 20, 20, "Full range, squeeze at top"),
            GLUTE_BRIDGE(3, 15, 30, "Hold top 2 seconds"),
        ]),
        workout("Birthday Shred Cardio Blast", "hiit", 30, [
            BURPEE(4, 15, 30, "All out effort"),
            JUMP_SQUAT(4, 15, 20, "Explosive"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            JUMPING_LUNGE(4, 12, 30, "Per side"),
        ]),
    ]


def _post_holiday_reset():
    """Post-Holiday Reset - burn off the feast and get back on track."""
    return [
        workout("Holiday Detox Cardio", "cardio", 40, [
            JUMPING_JACK(2, 30, 10, "Warm up"),
            HIGH_KNEES(3, 30, 15, "Elevate heart rate"),
            BURPEE(3, 12, 30, "Full body burn"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Core and cardio"),
            JUMP_SQUAT(3, 12, 20, "Power output"),
            JUMPING_LUNGE(3, 10, 20, "Per side"),
        ]),
        workout("Post-Holiday Full Body Reset", "strength", 45, [
            GOBLET_SQUAT(3, 15, 60, "Light and controlled"),
            PUSHUP(3, 15, 45, "Full ROM"),
            INVERTED_ROW(3, 12, 60, "Pull pattern reset"),
            GLUTE_BRIDGE(3, 20, 30, "Reactivate glutes"),
            DEAD_BUG(3, 10, 30, "Per side, core reset"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
        workout("Reset Strength Session", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Build back up gradually"),
            BARBELL_BENCH(3, 8, 90, "Reset your numbers"),
            BARBELL_ROW(3, 8, 90, "Upper back work"),
            DEADLIFT(1, 5, 180, "Touch and go, moderate"),
            CRUNCHES(3, 20, 30, "Bodyweight core"),
            SIDE_PLANK(2, 1, 20, "30 seconds each side"),
        ]),
    ]


def _spring_break_ready():
    """Spring Break Ready - beach body prep with full body sculpting."""
    return [
        workout("Spring Break Upper Sculpt", "strength", 50, [
            DB_BENCH(4, 12, 60, "Chest pump"),
            DB_INCLINE_PRESS(3, 12, 60, "Upper chest for definition"),
            DB_ROW(4, 12, 60, "Back width"),
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder caps"),
            DB_CURL(3, 12, 45, "Bicep peak"),
            TRICEP_PUSHDOWN(3, 15, 30, "Tricep definition"),
        ]),
        workout("Spring Break Lower Body Tone", "strength", 50, [
            BARBELL_SQUAT(4, 10, 90, "Leg definition"),
            RDL(3, 12, 60, "Hamstring stretch"),
            LEG_EXT(3, 15, 45, "Quad definition"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            CALF_RAISE(4, 20, 20, "Define those calves"),
            DONKEY_KICK(3, 15, 30, "Per leg, glute activation"),
        ]),
        workout("Spring Break HIIT Shred", "hiit", 30, [
            BURPEE(4, 15, 30, "All out"),
            JUMPING_JACK(1, 30, 10, "30 seconds"),
            HIGH_KNEES(3, 30, 20, "30 seconds"),
            JUMP_SQUAT(3, 15, 20, "Explosive lower"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
    ]


def _summer_body_prep():
    """Summer Body Prep - 8-week style program to peak for summer."""
    return [
        workout("Summer Body Full Body A", "strength", 55, [
            BARBELL_SQUAT(4, 10, 90, "Moderate weight, control"),
            BARBELL_BENCH(4, 10, 90, "Full ROM"),
            DEADLIFT(3, 8, 150, "Build power"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder definition"),
            HANGING_LEG_RAISE(3, 12, 60, "Core definition"),
            BICYCLE_CRUNCH(3, 20, 30, "Oblique work"),
        ]),
        workout("Summer Body HIIT Conditioning", "hiit", 35, [
            BURPEE(5, 15, 30, "Max effort"),
            JUMP_SQUAT(4, 15, 20, "Explosive"),
            JUMPING_LUNGE(4, 12, 20, "Per side"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
        ]),
        workout("Summer Body Upper Isolation", "strength", 50, [
            DB_BENCH(4, 12, 60, "Chest pump"),
            DB_INCLINE_PRESS(3, 12, 60, "Upper chest"),
            LAT_PULLDOWN(4, 12, 60, "V-taper"),
            CABLE_ROW(3, 12, 60, "Back thickness"),
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder width"),
            DB_CURL(3, 12, 45, "Arm definition"),
        ]),
        workout("Summer Body Lower Isolation", "strength", 50, [
            LEG_PRESS(4, 12, 90, "Heavy"),
            LEG_EXT(4, 15, 45, "Quad definition"),
            LEG_CURL(4, 15, 45, "Hamstring isolation"),
            HIP_THRUST(4, 15, 60, "Glute building"),
            CALF_RAISE(5, 20, 20, "Calf definition"),
            RUSSIAN_TWIST(3, 20, 30, "Oblique definition"),
        ]),
    ]


def _festival_ready():
    """Festival Ready - dance stamina, toned look, feel confident."""
    return [
        workout("Festival Cardio Dance Prep", "cardio", 40, [
            JUMPING_JACK(2, 30, 10, "Warm up"),
            HIGH_KNEES(3, 30, 15, "Stamina building"),
            BURPEE(3, 10, 30, "Full body"),
            JUMP_SQUAT(3, 12, 20, "Explosive power"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Core endurance"),
            JUMPING_LUNGE(3, 10, 20, "Leg endurance"),
        ]),
        workout("Festival Tone and Tighten", "strength", 45, [
            GOBLET_SQUAT(3, 15, 45, "Full depth"),
            PUSHUP(3, 15, 30, "Chest and arms"),
            GLUTE_BRIDGE(3, 20, 30, "Glute activation"),
            SIDE_PLANK(3, 1, 20, "30 seconds each side"),
            BICYCLE_CRUNCH(3, 20, 30, "Core definition"),
            DONKEY_KICK(3, 15, 20, "Per leg"),
        ]),
        workout("Festival Stamina HIIT", "hiit", 30, [
            HIGH_KNEES(5, 30, 15, "30 seconds max effort"),
            BURPEE(5, 10, 30, "All out"),
            JUMP_SQUAT(5, 10, 20, "Explosive"),
            JUMPING_LUNGE(5, 8, 20, "Per side"),
        ]),
    ]


def _prom_formal_ready():
    """Prom/Formal Ready - look stunning in formalwear."""
    return [
        workout("Prom Upper Body Tone", "strength", 45, [
            DB_OHP(3, 12, 60, "Shoulder definition for strapless looks"),
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder cap definition"),
            PUSHUP(3, 15, 45, "Chest and arm tone"),
            TRICEP_PUSHDOWN(3, 15, 30, "Arm definition"),
            DB_CURL(3, 12, 45, "Bicep tone"),
            PLANK(3, 1, 30, "Hold 45 seconds, posture"),
        ]),
        workout("Prom Lower Body Sculpt", "strength", 45, [
            GOBLET_SQUAT(3, 15, 45, "Quad and glute tone"),
            GLUTE_BRIDGE(4, 20, 30, "Glute activation"),
            DONKEY_KICK(3, 15, 20, "Per leg"),
            CURTSY_LUNGE(3, 12, 45, "Per leg, inner thigh"),
            CALF_RAISE(4, 20, 20, "For heels confidence"),
            BIRD_DOG(3, 10, 20, "Per side, posture"),
        ]),
        workout("Prom Posture and Confidence", "mobility", 30, [
            WALL_ANGEL(),
            CHIN_TUCK(),
            BAND_PULL_APART(3, 15, 20, "Light band"),
            SUPERMAN(3, 12, 20, "Back and posture"),
            DEAD_BUG(3, 10, 20, "Per side"),
            SIDE_PLANK(2, 1, 20, "30 seconds each side"),
        ]),
    ]


def _class_reunion_ready():
    """Class Reunion Ready - look your absolute best for the reunion."""
    return [
        workout("Reunion Shred Full Body", "strength", 55, [
            BARBELL_SQUAT(4, 10, 90, "Build confidence"),
            BARBELL_BENCH(4, 10, 90, "Chest and arms"),
            DEADLIFT(3, 8, 150, "Total body power"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder width"),
            DB_CURL(3, 12, 45, "Arm definition"),
            TRICEP_PUSHDOWN(3, 15, 30, "Tricep definition"),
        ]),
        workout("Reunion Cardio Burn", "hiit", 35, [
            BURPEE(5, 12, 30, "Calorie burn"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            JUMP_SQUAT(4, 12, 20, "Power"),
            JUMPING_LUNGE(4, 10, 20, "Per side"),
        ]),
        workout("Reunion Core Definition", "strength", 30, [
            PLANK(4, 1, 30, "Hold 45-60 seconds"),
            SIDE_PLANK(3, 1, 20, "45 seconds each side"),
            HANGING_LEG_RAISE(3, 15, 60, "Lower abs"),
            BICYCLE_CRUNCH(4, 20, 30, "Obliques"),
            RUSSIAN_TWIST(3, 20, 20, "Rotation"),
            DEAD_BUG(3, 10, 20, "Per side"),
        ]),
    ]


def _red_carpet_ready():
    """Red Carpet Ready - look like a celebrity on your big night."""
    return [
        workout("Red Carpet Upper Body", "strength", 55, [
            DB_INCLINE_PRESS(4, 12, 60, "Upper chest definition"),
            DB_BENCH(4, 12, 60, "Full chest pump"),
            LAT_PULLDOWN(4, 12, 60, "V-taper back"),
            CABLE_ROW(3, 12, 60, "Back definition"),
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder caps"),
            TRICEP_PUSHDOWN(3, 15, 30, "Arm definition"),
        ]),
        workout("Red Carpet Lower Body", "strength", 55, [
            BARBELL_SQUAT(4, 10, 90, "Leg definition"),
            RDL(4, 12, 60, "Hamstrings and glutes"),
            HIP_THRUST(4, 15, 60, "Glute building"),
            LEG_EXT(3, 15, 45, "Quad definition"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            CALF_RAISE(5, 20, 20, "Calf definition"),
        ]),
        workout("Red Carpet HIIT Finale", "hiit", 30, [
            BURPEE(4, 15, 30, "All out effort"),
            JUMP_SQUAT(4, 15, 20, "Explosive"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
        ]),
    ]


def _cruise_ship_ready():
    """Cruise Ship Ready - swimsuit confidence for your vacation."""
    return [
        workout("Cruise Body Full Body", "strength", 50, [
            GOBLET_SQUAT(3, 15, 45, "Leg tone"),
            DB_BENCH(3, 12, 60, "Chest definition"),
            DB_ROW(3, 12, 60, "Back and posture"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder definition"),
            GLUTE_BRIDGE(3, 20, 30, "Glute tone"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
        workout("Cruise Cardio Shred", "cardio", 35, [
            JUMPING_JACK(2, 30, 10, "Warm up"),
            HIGH_KNEES(3, 30, 15, "Cardio burn"),
            BURPEE(3, 12, 30, "Full body"),
            JUMP_SQUAT(3, 12, 20, "Explosive"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Core and cardio"),
            JUMPING_LUNGE(3, 10, 20, "Per side"),
        ]),
        workout("Cruise Core and Arms", "strength", 35, [
            DB_CURL(4, 12, 45, "Arm definition"),
            TRICEP_PUSHDOWN(4, 15, 30, "Arm definition"),
            HANGING_LEG_RAISE(3, 15, 60, "Core definition"),
            BICYCLE_CRUNCH(3, 20, 30, "Obliques"),
            RUSSIAN_TWIST(3, 20, 20, "Rotation"),
            SIDE_PLANK(3, 1, 20, "30 seconds each side"),
        ]),
    ]


def _wedding_ready_shred():
    """Wedding Ready Shred - look incredible on the most important day."""
    return [
        workout("Wedding Upper Body Sculpt", "strength", 55, [
            DB_INCLINE_PRESS(4, 12, 60, "Upper chest and arms"),
            DB_OHP(4, 12, 60, "Shoulder definition"),
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder caps for dress"),
            LAT_PULLDOWN(4, 12, 60, "Back definition"),
            TRICEP_PUSHDOWN(4, 15, 30, "Arm toning"),
            DB_CURL(3, 12, 45, "Arm definition"),
        ]),
        workout("Wedding Lower Body Tone", "strength", 55, [
            BARBELL_SQUAT(4, 10, 90, "Leg and glute tone"),
            RDL(4, 12, 60, "Hamstrings and glutes"),
            HIP_THRUST(5, 15, 60, "Glute building"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Per leg"),
            CURTSY_LUNGE(3, 12, 45, "Per leg, inner thigh"),
            CALF_RAISE(5, 20, 20, "Leg definition"),
        ]),
        workout("Wedding HIIT Fat Burn", "hiit", 30, [
            BURPEE(5, 15, 30, "All out"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            JUMP_SQUAT(4, 15, 20, "Power"),
        ]),
        workout("Wedding Posture and Core", "strength", 35, [
            WALL_ANGEL(),
            BAND_PULL_APART(3, 15, 20, "Light band"),
            PLANK(4, 1, 30, "Hold 60 seconds"),
            SIDE_PLANK(3, 1, 20, "45 seconds each side"),
            DEAD_BUG(3, 10, 20, "Per side"),
            SUPERMAN(3, 12, 20, "Back definition"),
        ]),
    ]


def _post_breakup_glow_up():
    """Post-Breakup Glow Up - channel emotions into transformation."""
    return [
        workout("Breakup Rage Lift", "strength", 55, [
            BARBELL_SQUAT(4, 8, 120, "Heavy, channel that energy"),
            DEADLIFT(3, 5, 180, "Powerful hip hinge"),
            BARBELL_BENCH(4, 8, 90, "Press it out"),
            BARBELL_ROW(4, 8, 90, "Pull yourself together"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder definition"),
            DB_CURL(3, 12, 45, "Build confidence"),
        ]),
        workout("Glow Up Cardio Release", "hiit", 35, [
            BURPEE(5, 15, 30, "Release everything"),
            HIGH_KNEES(5, 30, 15, "30 seconds all out"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            JUMP_SQUAT(4, 15, 20, "Explosive power"),
            JUMPING_LUNGE(4, 12, 20, "Per side, burn it out"),
        ]),
        workout("Confidence Build Lower", "strength", 50, [
            HIP_THRUST(5, 15, 60, "Best version of yourself"),
            BULGARIAN_SPLIT_SQUAT(4, 10, 60, "Per leg"),
            RDL(3, 12, 60, "Hamstring strength"),
            CURTSY_LUNGE(3, 12, 45, "Per leg"),
            GLUTE_BRIDGE(3, 20, 30, "Glute activation"),
            CALF_RAISE(4, 20, 20, "Total definition"),
        ]),
    ]


def _divorce_recovery_fitness():
    """Divorce Recovery - reclaim your body and mental health."""
    return [
        workout("New Chapter Full Body", "strength", 45, [
            GOBLET_SQUAT(3, 15, 60, "Ground yourself"),
            PUSHUP(3, 15, 45, "Build yourself up"),
            DB_ROW(3, 12, 60, "Pull strength"),
            GLUTE_BRIDGE(3, 20, 30, "Core and glutes"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
            DEAD_BUG(3, 10, 20, "Per side, breath and movement"),
        ]),
        workout("Recovery Cardio and Endorphins", "cardio", 40, [
            JUMPING_JACK(2, 30, 10, "Warm up, feel good"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
            BURPEE(3, 10, 30, "Release tension"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
            JUMP_SQUAT(3, 12, 20, "Build power"),
            JUMPING_LUNGE(3, 10, 20, "Per side"),
        ]),
        workout("Strength Rebuild Session", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Rebuild your strength"),
            BARBELL_BENCH(3, 8, 90, "Press forward"),
            DEADLIFT(1, 5, 180, "Lift heavy, feel powerful"),
            LAT_PULLDOWN(3, 12, 60, "Pull for posture"),
            DB_LATERAL_RAISE(3, 15, 30, "Build new confidence"),
            BICYCLE_CRUNCH(3, 20, 30, "Core strength"),
        ]),
    ]


def _new_job_confidence():
    """New Job Confidence - look and feel your best for the new role."""
    return [
        workout("Confidence Strength Session", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Stand tall, feel strong"),
            BARBELL_BENCH(3, 8, 90, "Upper body confidence"),
            BARBELL_ROW(3, 8, 90, "Posture and back"),
            DB_OHP(3, 10, 60, "Shoulder presence"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder definition"),
            PLANK(3, 1, 30, "Hold 45 seconds, core stability"),
        ]),
        workout("New Role Cardio Boost", "cardio", 30, [
            HIGH_KNEES(3, 30, 15, "Energy boost"),
            BURPEE(3, 10, 30, "Full body power"),
            JUMPING_JACK(2, 30, 10, "Warm up or cool down"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
            JUMP_SQUAT(3, 10, 20, "Explosive confidence"),
        ]),
        workout("Posture and Presence", "mobility", 25, [
            WALL_ANGEL(),
            CHIN_TUCK(),
            BAND_PULL_APART(3, 15, 20, "Light band"),
            SUPERMAN(3, 12, 20, "Back extension and posture"),
            BIRD_DOG(3, 10, 20, "Per side"),
            PLANK(3, 1, 30, "Hold 45 seconds"),
        ]),
    ]


###############################################################################
# TACTICAL / MILITARY
###############################################################################

def _tactical_fitness():
    """Tactical Fitness - functional strength and conditioning for operators."""
    return [
        workout("Tactical Strength Day", "strength", 55, [
            DEADLIFT(3, 5, 180, "Functional pulling strength"),
            BARBELL_SQUAT(3, 5, 150, "Lower body power"),
            BARBELL_OHP(3, 5, 120, "Overhead pressing strength"),
            PULLUP(5, 8, 90, "Unweighted, strict"),
            FARMER_WALK(3, 1, 60, "40 yards, heavy dumbbells"),
            PLANK(3, 1, 30, "Hold 60 seconds"),
        ]),
        workout("Tactical Conditioning Run", "cardio", 45, [
            ex("400m Run", 6, 1, 90, "Sprint 400m, 90s rest", "Bodyweight", "Full Body",
               "Cardiovascular", ["Legs", "Core"], "intermediate",
               "Maintain strong form, pump arms", "High Knees", duration_seconds=120),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
            BURPEE(3, 10, 30, "All out effort"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
        workout("Tactical Calisthenics Circuit", "strength", 40, [
            PUSHUP(5, 20, 30, "Max strict form"),
            PULLUP(5, 10, 90, "Strict, dead hang start"),
            BURPEE(4, 15, 45, "Fast and controlled"),
            BODYWEIGHT_SQUAT(4, 20, 30, "Air squats, depth"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
            PLANK(3, 1, 30, "Hold 60 seconds"),
        ]),
    ]


def _tactical_hybrid():
    """Tactical Hybrid - combining heavy lifts with conditioning work."""
    return [
        workout("Hybrid Strength-Conditioning A", "strength", 60, [
            BARBELL_SQUAT(4, 5, 150, "Heavy, then condition"),
            BARBELL_BENCH(4, 5, 120, "Heavy"),
            DEADLIFT(3, 3, 180, "Max strength"),
            BURPEE(3, 15, 45, "Transition to conditioning"),
            HIGH_KNEES(3, 30, 20, "30 seconds"),
        ]),
        workout("Hybrid Pull-Conditioning B", "strength", 55, [
            DEADLIFT(4, 5, 180, "Heavy pulling"),
            BARBELL_ROW(4, 5, 120, "Horizontal pull strength"),
            PULLUP(4, 8, 90, "Vertical pull"),
            JUMP_SQUAT(3, 15, 30, "Plyometric conditioning"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds"),
        ]),
        workout("Hybrid Metcon Session", "hiit", 45, [
            KETTLEBELL_SWING(5, 20, 45, "Ballistic power"),
            BURPEE(5, 15, 30, "Full body conditioning"),
            GOBLET_SQUAT(4, 15, 60, "Strength endurance"),
            JUMPING_LUNGE(4, 12, 30, "Per side"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
        ]),
    ]


def _special_forces_prep():
    """Special Forces Prep - rucking, calisthenics, swimming, and running."""
    return [
        workout("SF Calisthenics and Run", "strength", 60, [
            PUSHUP(6, 20, 30, "Strict, chest to ground"),
            PULLUP(6, 10, 90, "Dead hang, strict"),
            BODYWEIGHT_SQUAT(5, 30, 30, "Air squats, fast"),
            BURPEE(4, 15, 30, "No rest between sets"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
            PLANK(3, 1, 30, "Hold 60 seconds"),
        ]),
        workout("SF Ruck March Simulation", "cardio", 60, [
            ex("Ruck March (weighted backpack)", 1, 1, 0, "45-60 min steady pace with 20-50lb pack",
               "Bodyweight", "Full Body", "Cardiovascular",
               ["Legs", "Core", "Traps"], "intermediate",
               "Upright posture, natural gait, engage core", "Loaded Walk",
               duration_seconds=3600),
            FARMER_WALK(4, 1, 60, "50 yards, heavy dumbbells"),
            PLANK(3, 1, 30, "Hold 60 seconds"),
        ]),
        workout("SF Swim and Strength", "strength", 55, [
            ex("Swimming (Freestyle)", 6, 1, 45, "100m each lap at moderate pace",
               "Bodyweight", "Full Body", "Cardiovascular",
               ["Shoulders", "Back", "Core"], "intermediate",
               "High elbow catch, rotate hips, bilateral breathing", "Battle Ropes",
               duration_seconds=120),
            PUSHUP(4, 20, 30, "Post-swim calisthenics"),
            PULLUP(4, 10, 90, "Upper body pulling"),
            DEAD_BUG(3, 10, 20, "Per side, core stability"),
        ]),
        workout("SF Max Effort Conditioning", "hiit", 50, [
            BURPEE(6, 20, 30, "Max output"),
            JUMP_SQUAT(5, 20, 20, "Explosive"),
            HIGH_KNEES(5, 30, 15, "30 seconds full speed"),
            MOUNTAIN_CLIMBER(5, 30, 15, "30 seconds"),
            JUMPING_LUNGE(4, 15, 20, "Per side"),
        ]),
    ]


def _first_responder_fitness():
    """First Responder Fitness - functional training for firefighters, police, EMTs."""
    return [
        workout("First Responder Strength", "strength", 55, [
            DEADLIFT(4, 5, 180, "Functional lifting from ground"),
            BARBELL_SQUAT(4, 5, 150, "Lower body strength"),
            BARBELL_OHP(3, 8, 90, "Overhead lifting ability"),
            FARMER_WALK(4, 1, 60, "40 yards, heavy - simulate gear carry"),
            PULLUP(4, 8, 90, "Pulling strength"),
            PLANK(3, 1, 30, "Hold 60 seconds"),
        ]),
        workout("First Responder Conditioning", "hiit", 45, [
            BURPEE(5, 15, 30, "All out effort"),
            JUMP_SQUAT(4, 15, 20, "Explosive power"),
            HIGH_KNEES(4, 30, 15, "30 seconds cardio"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds core"),
            FARMER_WALK(3, 1, 60, "30 yards fast"),
        ]),
        workout("First Responder Functional Circuit", "strength", 50, [
            KETTLEBELL_SWING(4, 20, 45, "Hip power and endurance"),
            GOBLET_SQUAT(3, 15, 45, "Loaded squat"),
            PUSHUP(4, 20, 30, "Chest and arm strength"),
            INVERTED_ROW(3, 12, 45, "Horizontal pull"),
            DEAD_BUG(3, 10, 20, "Per side, core stability"),
            SIDE_PLANK(3, 1, 20, "45 seconds each side"),
        ]),
    ]


def _prison_style_workout():
    """Prison Style Workout - pure bodyweight, no equipment needed, high intensity."""
    return [
        workout("Cell Block Push Day", "strength", 40, [
            PUSHUP(5, 25, 30, "Strict form, chest to floor"),
            DIAMOND_PUSHUP(4, 15, 30, "Tricep focus"),
            PIKE_PUSHUP(4, 12, 45, "Shoulder press alternative"),
            BENCH_DIP(4, 20, 30, "Bench or bed"),
            PLANK(4, 1, 20, "Hold 45 seconds"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
        workout("Cell Block Pull and Legs", "strength", 40, [
            PULLUP(5, 10, 90, "Any bar available - door frame, pipe"),
            INVERTED_ROW(4, 15, 60, "Under table or low bar"),
            BODYWEIGHT_SQUAT(5, 30, 30, "Air squats, deep"),
            JUMP_SQUAT(4, 15, 30, "Explosive"),
            GLUTE_BRIDGE(4, 25, 20, "Bodyweight"),
            CRUNCHES(4, 30, 20, "Bodyweight abs"),
        ]),
        workout("Cell Block Full Body Grind", "strength", 45, [
            BURPEE(5, 20, 30, "No equipment needed"),
            PUSHUP(4, 25, 20, "Push strength"),
            BODYWEIGHT_SQUAT(4, 30, 20, "Squat strength"),
            PULLUP(4, 10, 90, "Pull strength"),
            HANGING_LEG_RAISE(3, 15, 60, "Core"),
            PLANK(3, 1, 20, "Hold 60 seconds"),
        ]),
        workout("Cell Block Cardio", "cardio", 30, [
            HIGH_KNEES(5, 30, 10, "30 seconds all out"),
            BURPEE(5, 15, 20, "All out effort"),
            JUMPING_JACK(3, 30, 10, "30 seconds"),
            JUMP_SQUAT(4, 15, 20, "Explosive"),
            MOUNTAIN_CLIMBER(4, 30, 10, "30 seconds"),
        ]),
    ]


###############################################################################
# MISC LIFESTYLE
###############################################################################

def _busy_professional_fitness():
    """Busy Professional Fitness - maximum results in minimal time."""
    return [
        workout("Executive Express Full Body", "strength", 30, [
            GOBLET_SQUAT(3, 12, 45, "No setup time needed"),
            DB_BENCH(3, 10, 45, "Moderate dumbbells"),
            DB_ROW(3, 10, 45, "Each side"),
            DB_OHP(3, 10, 45, "Moderate weight"),
            PLANK(3, 1, 20, "Hold 30-45 seconds"),
        ]),
        workout("Power Hour Strength", "strength", 45, [
            DEADLIFT(3, 5, 150, "Time-efficient compound"),
            BARBELL_BENCH(3, 8, 90, "Upper body"),
            BARBELL_SQUAT(3, 8, 90, "Lower body"),
            PULLUP(3, 8, 60, "Vertical pull"),
            FARMER_WALK(2, 1, 45, "40 yards"),
        ]),
        workout("Office Warrior HIIT", "hiit", 20, [
            BURPEE(4, 10, 30, "Max effort"),
            PUSHUP(4, 15, 20, "Bodyweight"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            BODYWEIGHT_SQUAT(4, 20, 15, "No equipment"),
            MOUNTAIN_CLIMBER(3, 30, 10, "30 seconds"),
        ]),
    ]


def _self_defense_fitness():
    """Self-Defense Fitness - conditioning for real-world protection."""
    return [
        workout("Self-Defense Striking Conditioning", "hiit", 45, [
            ex("Shadow Boxing", 5, 1, 30, "3 minutes per round - jabs, crosses, hooks",
               "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Cardio", "Arms"], "beginner",
               "Stay light on feet, rotate hips with each punch", "High Knees",
               duration_seconds=180),
            BURPEE(4, 12, 30, "Explosive full body"),
            HIGH_KNEES(4, 30, 15, "30 seconds footwork"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds core"),
        ]),
        workout("Self-Defense Functional Strength", "strength", 50, [
            DEADLIFT(4, 5, 150, "Ground-to-stand strength"),
            BARBELL_ROW(4, 8, 90, "Pulling and grappling"),
            BARBELL_OHP(3, 8, 90, "Overhead pushing"),
            PULLUP(4, 8, 90, "Grip and pulling"),
            GOBLET_SQUAT(3, 12, 60, "Functional leg strength"),
            PLANK(3, 1, 30, "Core stability"),
        ]),
        workout("Self-Defense Agility and Awareness", "strength", 40, [
            JUMP_SQUAT(4, 12, 30, "Explosive movement"),
            JUMPING_LUNGE(4, 10, 30, "Per side, quick direction change"),
            ex("Lateral Shuffle", 4, 1, 20, "30 seconds side to side",
               "Bodyweight", "Legs", "Hip Abductors",
               ["Calves", "Agility"], "beginner",
               "Stay low, quick feet, change direction", "Lateral Band Walk",
               duration_seconds=30),
            BURPEE(4, 10, 30, "Get up fast"),
            PUSHUP(4, 15, 30, "Ground fighting strength"),
        ]),
    ]


def _lunch_break_workout():
    """Lunch Break Workout - 20-30 minute bodyweight sessions, no equipment."""
    return [
        workout("Lunch Push Circuit", "strength", 20, [
            PUSHUP(3, 15, 30, "Chest to ground, full ROM"),
            DIAMOND_PUSHUP(3, 10, 30, "Tricep emphasis"),
            PIKE_PUSHUP(3, 10, 30, "Shoulder press"),
            PLANK(3, 1, 20, "Hold 30 seconds"),
            MOUNTAIN_CLIMBER(2, 30, 15, "30 seconds"),
        ]),
        workout("Lunch Full Body Express", "strength", 25, [
            BODYWEIGHT_SQUAT(3, 20, 30, "Deep squats"),
            PUSHUP(3, 15, 30, "Full ROM"),
            GLUTE_BRIDGE(3, 20, 20, "Hip drive"),
            CRUNCHES(3, 20, 20, "Core"),
            HIGH_KNEES(3, 30, 15, "30 seconds cardio"),
        ]),
        workout("Lunch HIIT Blast", "hiit", 20, [
            BURPEE(4, 10, 30, "Max effort"),
            JUMP_SQUAT(4, 10, 20, "Explosive"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
            JUMPING_JACK(2, 30, 10, "Active recovery"),
            HIGH_KNEES(3, 30, 10, "30 seconds"),
        ]),
    ]


def _seated_workout_series():
    """Seated Workout Series - chair-based exercises for mobility-limited users."""
    return [
        workout("Seated Upper Body Strength", "strength", 30, [
            ex("Seated Dumbbell Press", 3, 12, 45, "Light to moderate dumbbells",
               "Dumbbell", "Shoulders", "Deltoids",
               ["Triceps"], "beginner",
               "Sit tall, press overhead from seated position", "Seated Arm Raise"),
            ex("Seated Dumbbell Row", 3, 12, 45, "One arm at a time",
               "Dumbbell", "Back", "Rhomboids",
               ["Biceps", "Latissimus Dorsi"], "beginner",
               "Lean slightly forward, pull elbow back", "Band Row"),
            ex("Seated Bicep Curl", 3, 12, 30, "Light dumbbells",
               "Dumbbell", "Arms", "Biceps",
               ["Brachialis"], "beginner",
               "Curl from fully extended, squeeze at top", "Band Curl"),
            ex("Seated Tricep Extension", 3, 12, 30, "Light dumbbell",
               "Dumbbell", "Arms", "Triceps",
               ["Anconeus"], "beginner",
               "Extend behind head, keep elbows tucked", "Band Pushdown"),
            ex("Seated Lateral Raise", 3, 15, 20, "Very light dumbbells",
               "Dumbbell", "Shoulders", "Lateral Deltoid",
               ["Supraspinatus"], "beginner",
               "Slight lean forward, raise to shoulder height only", "Band Raise"),
        ]),
        workout("Seated Lower Body and Core", "strength", 25, [
            ex("Seated Leg Extension", 3, 15, 30, "Bodyweight or ankle weights",
               "Bodyweight", "Legs", "Quadriceps",
               ["Hip Flexors"], "beginner",
               "Extend knee fully, squeeze quad, lower slowly", "Ankle Weight Extension"),
            ex("Seated Knee Lift", 3, 15, 20, "Bodyweight or ankle weights",
               "Bodyweight", "Core", "Hip Flexors",
               ["Lower Abs"], "beginner",
               "Lift knee toward chest, hold briefly, lower", "Seated March"),
            ex("Seated Torso Rotation", 3, 10, 15, "Per side",
               "Bodyweight", "Core", "Obliques",
               ["Erector Spinae"], "beginner",
               "Rotate slowly side to side, keep hips forward", "Seated Twist"),
            ex("Seated Calf Raise", 4, 20, 15, "Both feet",
               "Bodyweight", "Legs", "Calves",
               ["Tibialis"], "beginner",
               "Lift heels fully, squeeze calves at top", "Ankle Circles"),
            ANKLE_CIRCLES(),
        ]),
        workout("Seated Mobility and Flexibility", "mobility", 25, [
            ex("Seated Neck Rolls", 2, 5, 10, "Each direction slowly",
               "Bodyweight", "Neck", "Cervical Spine",
               ["Upper Trapezius"], "beginner",
               "Gentle slow circles, never force range", "Chin Tuck"),
            ex("Seated Shoulder Circles", 2, 10, 10, "Each direction",
               "Bodyweight", "Shoulders", "Rotator Cuff",
               ["Trapezius"], "beginner",
               "Roll shoulders forward then backward", "Arm Circles"),
            ex("Seated Hip March", 3, 10, 10, "Per side",
               "Bodyweight", "Hips", "Hip Flexors",
               ["Quadriceps"], "beginner",
               "Lift knee high, lower with control", "Seated Leg Lift"),
            ex("Seated Forward Reach", 3, 8, 15, "Hold 5 seconds each",
               "Bodyweight", "Back", "Erector Spinae",
               ["Hamstrings"], "beginner",
               "Reach forward, round back gently, return tall", "Seated Forward Fold"),
            CHIN_TUCK(),
            WRIST_CIRCLES(),
        ]),
    ]


def _hotel_room_fitness():
    """Hotel Room Fitness - complete workouts with zero equipment in small spaces."""
    return [
        workout("Hotel Room Push-Pull", "strength", 30, [
            PUSHUP(4, 20, 30, "Full ROM, chest to floor"),
            INVERTED_ROW(3, 12, 45, "Under desk or table"),
            DIAMOND_PUSHUP(3, 12, 30, "Tricep focus"),
            PIKE_PUSHUP(3, 10, 30, "Shoulder press"),
            PLANK(3, 1, 20, "Hold 45 seconds"),
            SIDE_PLANK(2, 1, 20, "30 seconds each side"),
        ]),
        workout("Hotel Room Leg Day", "strength", 25, [
            BODYWEIGHT_SQUAT(4, 25, 30, "Deep, controlled"),
            JUMP_SQUAT(3, 15, 30, "Explosive, soft landing"),
            GLUTE_BRIDGE(4, 20, 20, "Use hotel bed edge"),
            STEP_UP(3, 10, 45, "Per leg, use bed"),
            WALL_SIT(3, 1, 30, "Hold 45 seconds"),
            CALF_RAISE(4, 20, 15, "Single leg for challenge"),
        ]),
        workout("Hotel Room HIIT", "hiit", 20, [
            BURPEE(4, 12, 30, "No jump if needed for noise"),
            HIGH_KNEES(4, 30, 15, "30 seconds, light feet"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
            PUSHUP(3, 15, 20, "Chest builder"),
            BICYCLE_CRUNCH(3, 20, 20, "Core"),
        ]),
    ]


def _playground_fitness():
    """Playground Fitness - creative workouts using park equipment."""
    return [
        workout("Playground Pull Day", "strength", 40, [
            PULLUP(5, 8, 90, "Monkey bars or swing set bar"),
            CHINUP(4, 8, 90, "Supinated grip on bar"),
            INVERTED_ROW(4, 12, 60, "Under low bar"),
            ex("Playground Hanging Knee Raise", 3, 15, 60, "Hang from bar",
               "Bodyweight", "Core", "Lower Abs",
               ["Hip Flexors", "Obliques"], "intermediate",
               "Dead hang, pull knees to chest, lower controlled", "Lying Leg Raise"),
            HANGING_LEG_RAISE(3, 10, 60, "Monkey bars"),
        ]),
        workout("Playground Full Body", "strength", 45, [
            PULLUP(4, 8, 90, "Bar work"),
            PUSHUP(4, 15, 30, "Ground work"),
            JUMP_SQUAT(3, 15, 30, "Open space"),
            BOX_JUMP(3, 8, 60, "Onto bench or step"),
            STEP_UP(3, 10, 45, "Per leg, onto bench"),
            BURPEE(3, 10, 30, "Open grass area"),
        ]),
        workout("Playground Cardio Circuit", "cardio", 35, [
            ex("Sprint to park bench and back", 8, 1, 45, "~50m sprint",
               "Bodyweight", "Full Body", "Cardiovascular",
               ["Legs", "Core"], "intermediate",
               "Drive knees, pump arms, explosive starts", "High Knees",
               duration_seconds=15),
            BOX_JUMP(4, 10, 60, "Bench jumps"),
            JUMPING_LUNGE(3, 12, 30, "Per side on grass"),
            BURPEE(3, 10, 30, "Open area"),
        ]),
    ]


def _backyard_bootcamp():
    """Backyard Bootcamp - high energy outdoor circuit training."""
    return [
        workout("Backyard Strength Circuit", "strength", 45, [
            PUSHUP(4, 20, 30, "Full ROM"),
            BODYWEIGHT_SQUAT(4, 25, 30, "Deep squats"),
            JUMP_SQUAT(3, 15, 30, "Explosive"),
            BURPEE(3, 15, 30, "Full effort"),
            PLANK(3, 1, 20, "Hold 45 seconds"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
        workout("Backyard HIIT Bootcamp", "hiit", 35, [
            BURPEE(5, 15, 30, "All out effort"),
            JUMP_SQUAT(5, 15, 20, "Explosive"),
            HIGH_KNEES(5, 30, 15, "30 seconds"),
            JUMPING_LUNGE(4, 12, 20, "Per side"),
            MOUNTAIN_CLIMBER(4, 30, 15, "30 seconds"),
        ]),
        workout("Backyard Partner Challenge", "strength", 40, [
            PUSHUP(5, 20, 30, "Race your partner"),
            BODYWEIGHT_SQUAT(5, 25, 30, "Side by side"),
            BURPEE(5, 10, 30, "Who finishes first"),
            PLANK(3, 1, 20, "Last one standing wins"),
            HIGH_KNEES(4, 30, 15, "30 seconds sprint"),
        ]),
    ]


def _functional_farm_fitness():
    """Functional Farm Fitness - using farm tools and natural terrain."""
    return [
        workout("Farm Strength Work", "strength", 50, [
            FARMER_WALK(5, 1, 60, "50 yards - simulate bucket carry"),
            DEADLIFT(4, 5, 180, "Pick up heavy things from ground"),
            ex("Hay Bale Carry (Simulated)", 4, 1, 60, "Bear hug heavy sandbag or dumbbell",
               "Dumbbell", "Full Body", "Core",
               ["Legs", "Back", "Grip"], "intermediate",
               "Tight grip, upright posture, walk distance", "Farmers Walk"),
            ex("Shovel Simulation", 3, 20, 45, "Rotate and lift medicine ball",
               "Bodyweight", "Full Body", "Core",
               ["Obliques", "Shoulders", "Legs"], "beginner",
               "Bend and lift, rotate and place, squat pattern", "Russian Twist"),
            KETTLEBELL_SWING(4, 20, 45, "Hip hinge power"),
        ]),
        workout("Farm Conditioning Circuit", "hiit", 40, [
            ex("Tire Flip Simulation", 4, 10, 60, "Deadlift to overhead press with heavy object",
               "Bodyweight", "Full Body", "Full Body",
               ["Legs", "Back", "Shoulders", "Core"], "advanced",
               "Explosive hip drive, push overhead, athletic stance", "Burpee"),
            FARMER_WALK(4, 1, 45, "40 yards, fast"),
            BURPEE(4, 12, 30, "Open field"),
            BODYWEIGHT_SQUAT(4, 25, 20, "Deep, functional"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
        ]),
        workout("Farm Mobility and Recovery", "mobility", 30, [
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            DOWNWARD_DOG(),
            CHILDS_POSE(),
            COBRA(),
            PIRIFOMIS_STRETCH(),
        ]),
    ]


def _hyrox_home_edition():
    """HYROX Home Edition - mimic HYROX functional fitness with home alternatives."""
    return [
        workout("HYROX Station 1-4 Home", "strength", 50, [
            ex("Ski Erg Simulation (Rope Slams)", 2, 1, 60, "2 min continuous arm pulls with towel or resistance band",
               "Resistance Band", "Full Body", "Shoulders",
               ["Core", "Back", "Arms"], "intermediate",
               "Explosive pull down, hinge at hips, full extension", "Battle Ropes",
               duration_seconds=120),
            ex("Sled Push Simulation (Furniture Push)", 2, 1, 60, "Push heavy furniture or sled 25m",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Glutes", "Core", "Calves"], "intermediate",
               "Low body angle, drive with legs", "Sprint"),
            ex("Sled Pull Simulation (Towel Row)", 2, 1, 60, "Seated towel pull for 25m",
               "Bodyweight", "Back", "Rhomboids",
               ["Biceps", "Core"], "beginner",
               "Slide on smooth floor, pull hand over hand", "Cable Row"),
            ex("Burpee Broad Jumps", 2, 10, 60, "Burpee then jump forward",
               "Bodyweight", "Full Body", "Full Body",
               ["Chest", "Legs", "Core"], "intermediate",
               "Chest to floor, jump explosively forward", "Burpee"),
        ]),
        workout("HYROX Station 5-8 Home", "strength", 55, [
            ex("Rowing Machine", 2, 1, 60, "1000m at moderate pace",
               "Rowing Machine", "Full Body", "Back",
               ["Legs", "Arms", "Core"], "beginner",
               "Legs-back-arms, smooth strokes, 26-28 spm", "Battle Ropes",
               duration_seconds=300),
            ex("Farmers Carry (Dumbbells)", 2, 1, 60, "200m total with heavy dumbbells",
               "Dumbbell", "Full Body", "Grip",
               ["Traps", "Core", "Forearms"], "beginner",
               "Tall posture, tight core, quick steps", "Kettlebell Carry"),
            ex("Sandbag Lunges", 2, 24, 60, "Alternating lunges with sandbag on shoulder",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings", "Core"], "intermediate",
               "Step long, knee tracks toe, upright torso", "Dumbbell Lunge"),
            ex("Wall Ball Shots", 2, 30, 60, "Squat then throw ball at wall target",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Shoulders", "Core", "Calves"], "intermediate",
               "Deep squat, explosive drive, extend fully and catch", "Goblet Squat"),
        ]),
        workout("HYROX Race Simulation", "hiit", 60, [
            ex("1km Run", 1, 1, 0, "Steady effort, part of continuous circuit",
               "Bodyweight", "Full Body", "Cardiovascular",
               ["Legs", "Core"], "intermediate",
               "Maintain aerobic pace, save energy for stations", "High Knees",
               duration_seconds=360),
            ex("Ski Erg or Row (2 min)", 1, 1, 30, "2 min max effort",
               "Bodyweight", "Shoulders", "Cardiovascular",
               ["Core", "Back"], "intermediate",
               "Max intensity for duration", "Battle Ropes",
               duration_seconds=120),
            BURPEE(1, 20, 30, "Burpee broad jumps"),
            FARMER_WALK(2, 1, 30, "50m heavy"),
            ex("Lunge Walk (50m)", 2, 1, 60, "Sandbag or dumbbell lunge walk",
               "Dumbbell", "Legs", "Quadriceps",
               ["Glutes", "Core"], "intermediate",
               "Each step a full lunge, continuous movement", "Bodyweight Lunge"),
            ex("Wall Ball (30 reps)", 2, 30, 60, "Squat to press",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Shoulders", "Core"], "intermediate",
               "Squat deep, explode up, throw to target height", "Goblet Squat"),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS REGISTRY
###############################################################################

BATCH_WORKOUTS = {
    # Lifestyle / Life Events
    "New Year New You": _new_year_new_you,
    "Birthday Shred": _birthday_shred,
    "Post-Holiday Reset": _post_holiday_reset,
    "Spring Break Ready": _spring_break_ready,
    "Summer Body Prep": _summer_body_prep,
    "Festival Ready": _festival_ready,
    "Prom/Formal Ready": _prom_formal_ready,
    "Class Reunion Ready": _class_reunion_ready,
    "Red Carpet Ready": _red_carpet_ready,
    "Cruise Ship Ready": _cruise_ship_ready,
    "Wedding Ready Shred": _wedding_ready_shred,
    "Post-Breakup Glow Up": _post_breakup_glow_up,
    "Divorce Recovery Fitness": _divorce_recovery_fitness,
    "New Job Confidence": _new_job_confidence,

    # Tactical / Military
    "Tactical Fitness": _tactical_fitness,
    "Tactical Hybrid": _tactical_hybrid,
    "Special Forces Prep": _special_forces_prep,
    "First Responder Fitness": _first_responder_fitness,
    "Prison Style Workout": _prison_style_workout,

    # Misc Lifestyle
    "Busy Professional Fitness": _busy_professional_fitness,
    "Self-Defense Fitness": _self_defense_fitness,
    "Lunch Break Workout": _lunch_break_workout,
    "Seated Workout Series": _seated_workout_series,
    "Hotel Room Fitness": _hotel_room_fitness,
    "Playground Fitness": _playground_fitness,
    "Backyard Bootcamp": _backyard_bootcamp,
    "Functional Farm Fitness": _functional_farm_fitness,
    "HYROX Home Edition": _hyrox_home_edition,
}
