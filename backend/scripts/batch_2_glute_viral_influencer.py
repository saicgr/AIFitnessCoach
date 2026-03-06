#!/usr/bin/env python3
"""Batch 2: Glute Building (28) + Viral TikTok (15) + Influencer/Aesthetic (24) programs."""

from exercise_lib import *


###############################################################################
# GLUTE BUILDING (28 programs)
###############################################################################

def booty_basics():
    return [
        workout("Booty Basics A - Bodyweight Glutes", "strength", 30, [
            GLUTE_BRIDGE(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Booty Basics B - Squat & Lunge", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 15, 30),
            SUMO_SQUAT(3, 15, 45),
            REVERSE_LUNGE(3, 10, 45),
            GLUTE_BRIDGE(3, 15, 30),
            DONKEY_KICK(3, 12, 30),
        ]),
        workout("Booty Basics C - Glute Activation", "strength", 30, [
            CLAMSHELL(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            FROG_PUMP(3, 20, 30),
            CURTSY_LUNGE(3, 10, 45),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def glute_building_foundations():
    return [
        workout("Glute Foundations A - Hip Thrust Focus", "strength", 35, [
            HIP_THRUST(3, 12, 90),
            GLUTE_BRIDGE(3, 15, 30),
            SUMO_SQUAT(3, 15, 45),
            DONKEY_KICK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Glute Foundations B - Lunge & Hinge", "strength", 35, [
            DB_RDL(3, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            STEP_UP(3, 10, 60),
            FIRE_HYDRANT(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Glute Foundations C - Total Glute", "strength", 35, [
            HIP_THRUST(3, 10, 90),
            CURTSY_LUNGE(3, 12, 45),
            SUMO_SQUAT(3, 15, 45),
            LATERAL_BAND_WALK(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def at_home_booty_builder():
    return [
        workout("Home Booty A - Floor Work", "strength", 30, [
            GLUTE_BRIDGE(4, 20, 30),
            DONKEY_KICK(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            FROG_PUMP(3, 25, 30),
        ]),
        workout("Home Booty B - Standing", "strength", 30, [
            SUMO_SQUAT(3, 20, 45),
            CURTSY_LUNGE(3, 12, 45),
            REVERSE_LUNGE(3, 12, 45),
            BODYWEIGHT_SQUAT(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Home Booty C - Combo", "strength", 30, [
            GLUTE_BRIDGE(3, 20, 30),
            SUMO_SQUAT(3, 15, 45),
            FIRE_HYDRANT(3, 15, 30),
            STEP_UP(3, 10, 60),
            FROG_PUMP(3, 20, 30),
        ]),
    ]


def resistance_band_glutes():
    return [
        workout("Band Glutes A - Activation", "strength", 30, [
            LATERAL_BAND_WALK(4, 15, 30),
            BANDED_SQUAT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            ex("Banded Glute Bridge", 3, 20, 30, "Band above knees", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Core"], "beginner",
               "Push knees out against band at top", "Glute Bridge"),
            ex("Banded Donkey Kick", 3, 15, 30, "Band around ankles, per leg", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Keep 90-degree knee, drive heel up", "Donkey Kick"),
        ]),
        workout("Band Glutes B - Strength", "strength", 30, [
            BANDED_SQUAT(4, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
            ex("Banded Hip Thrust", 3, 15, 45, "Band above knees", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Adductors"], "beginner",
               "Drive knees out, squeeze glutes at top", "Glute Bridge"),
            ex("Banded Fire Hydrant", 3, 15, 30, "Band above knees, per leg", "Resistance Band", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus"], "beginner",
               "On all fours, lift knee against band resistance", "Fire Hydrant"),
            CLAMSHELL(3, 20, 30),
        ]),
        workout("Band Glutes C - Burnout", "strength", 35, [
            BANDED_SQUAT(3, 20, 30),
            LATERAL_BAND_WALK(3, 20, 30),
            ex("Banded Kickback", 3, 15, 30, "Band around ankles, per leg", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Standing, kick back against band", "Cable Kickback"),
            CLAMSHELL(3, 20, 30),
            ex("Banded Frog Pump", 3, 25, 30, "Band above knees", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Adductors"], "beginner",
               "Soles together, knees out, thrust up", "Frog Pump"),
        ]),
    ]


def advanced_glute_builder():
    return [
        workout("Advanced Glutes A - Heavy Hip Thrust", "strength", 45, [
            HIP_THRUST(4, 8, 120, "Heavy barbell, progressive overload"),
            BARBELL_SQUAT(3, 8, 120),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_KICKBACK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Advanced Glutes B - Deadlift Day", "strength", 45, [
            SUMO_DEADLIFT(4, 5, 180),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90, "Feet high and wide for glute focus"),
            CABLE_PULL_THROUGH(3, 12, 45),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Advanced Glutes C - Volume", "strength", 50, [
            HIP_THRUST(4, 12, 90),
            BULGARIAN_SPLIT_SQUAT(3, 12, 60),
            STEP_UP(3, 12, 60),
            SINGLE_LEG_RDL(3, 10, 45),
            CABLE_KICKBACK(3, 15, 30),
            FROG_PUMP(3, 25, 30),
        ]),
    ]


def science_based_glute_training():
    return [
        workout("Science Glutes A - Horizontal Push", "strength", 45, [
            HIP_THRUST(4, 10, 120, "Peak contraction at top - max glute EMG"),
            GLUTE_BRIDGE(3, 15, 45, "Single leg for balance"),
            CABLE_PULL_THROUGH(3, 12, 45),
            FROG_PUMP(3, 20, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Science Glutes B - Vertical Push", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120, "ATG for max glute stretch"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            STEP_UP(3, 12, 60, "High box for greater hip flexion"),
            LEG_PRESS(3, 12, 90, "Feet high and wide"),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Science Glutes C - Hinge & Abduction", "strength", 45, [
            RDL(3, 10, 90),
            SINGLE_LEG_RDL(3, 10, 45),
            CABLE_KICKBACK(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
    ]


def hip_thrust_specialization():
    return [
        workout("Hip Thrust Spec A - Heavy Singles", "strength", 40, [
            HIP_THRUST(5, 6, 120, "Heavy, progressive overload weekly"),
            GLUTE_BRIDGE(3, 15, 45, "Single leg, bodyweight"),
            CABLE_PULL_THROUGH(3, 12, 45),
            FROG_PUMP(3, 25, 30),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Hip Thrust Spec B - Volume", "strength", 40, [
            HIP_THRUST(4, 12, 90, "Moderate weight, pause at top"),
            ex("Single-Leg Hip Thrust", 3, 10, 60, "Bodyweight, per leg", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate",
               "One foot on floor, drive through heel", "Glute Bridge"),
            SUMO_SQUAT(3, 15, 45),
            DONKEY_KICK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Hip Thrust Spec C - Endurance", "strength", 40, [
            HIP_THRUST(3, 20, 60, "Lighter weight, high reps"),
            GLUTE_BRIDGE(3, 20, 30),
            FROG_PUMP(4, 25, 30),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 20, 30),
        ]),
    ]


def peach_builder():
    return [
        workout("Peach Builder A - Shape & Lift", "strength", 40, [
            HIP_THRUST(4, 12, 90),
            SUMO_SQUAT(3, 15, 45),
            CABLE_KICKBACK(3, 15, 30),
            STEP_UP(3, 12, 60),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Peach Builder B - Round & Full", "strength", 40, [
            BARBELL_SQUAT(3, 10, 120),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            FIRE_HYDRANT(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Peach Builder C - Burnout", "strength", 40, [
            HIP_THRUST(3, 15, 90),
            RDL(3, 10, 90),
            CURTSY_LUNGE(3, 12, 45),
            DONKEY_KICK(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
            CLAMSHELL(3, 20, 30),
        ]),
    ]


def glutes_and_abs_combo():
    return [
        workout("Glutes & Abs A", "strength", 35, [
            HIP_THRUST(3, 12, 90),
            PLANK(3, 1, 30),
            SUMO_SQUAT(3, 15, 45),
            BICYCLE_CRUNCH(3, 20, 30),
            DONKEY_KICK(3, 15, 30),
            DEAD_BUG(3, 10, 30),
        ]),
        workout("Glutes & Abs B", "strength", 35, [
            GLUTE_BRIDGE(3, 20, 30),
            RUSSIAN_TWIST(3, 20, 30),
            CURTSY_LUNGE(3, 12, 45),
            HANGING_LEG_RAISE(3, 10, 60),
            FIRE_HYDRANT(3, 15, 30),
            SIDE_PLANK(2, 1, 30),
        ]),
        workout("Glutes & Abs C", "strength", 35, [
            FROG_PUMP(3, 20, 30),
            CRUNCHES(3, 20, 30),
            LATERAL_BAND_WALK(3, 15, 30),
            MOUNTAIN_CLIMBER(3, 20, 20),
            CLAMSHELL(3, 15, 30),
            PLANK(3, 1, 30),
        ]),
    ]


def lower_body_sculpt():
    return [
        workout("Lower Sculpt A - Quad & Glute", "strength", 40, [
            BARBELL_SQUAT(4, 8, 120),
            LEG_PRESS(3, 12, 90),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_EXT(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
        workout("Lower Sculpt B - Glute & Ham", "strength", 40, [
            HIP_THRUST(4, 10, 90),
            RDL(3, 10, 90),
            LEG_CURL(3, 12, 45),
            CABLE_KICKBACK(3, 15, 30),
            STEP_UP(3, 12, 60),
        ]),
        workout("Lower Sculpt C - Total Lower", "strength", 45, [
            SUMO_DEADLIFT(3, 8, 150),
            LEG_PRESS(3, 12, 90),
            CURTSY_LUNGE(3, 12, 45),
            LEG_CURL(3, 12, 45),
            LATERAL_BAND_WALK(3, 15, 30),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def high_volume_glute_workout():
    return [
        workout("High Vol Glutes A - Thrust & Bridge", "strength", 45, [
            HIP_THRUST(5, 12, 90),
            GLUTE_BRIDGE(4, 20, 30),
            FROG_PUMP(4, 25, 30),
            DONKEY_KICK(3, 20, 30),
            FIRE_HYDRANT(3, 20, 30),
        ]),
        workout("High Vol Glutes B - Squat & Lunge", "strength", 45, [
            BARBELL_SQUAT(4, 10, 120),
            SUMO_SQUAT(4, 15, 45),
            BULGARIAN_SPLIT_SQUAT(3, 12, 60),
            CURTSY_LUNGE(3, 15, 45),
            STEP_UP(3, 12, 60),
        ]),
        workout("High Vol Glutes C - Cable & Band", "strength", 45, [
            CABLE_KICKBACK(4, 15, 30),
            CABLE_PULL_THROUGH(4, 12, 45),
            LATERAL_BAND_WALK(4, 20, 30),
            BANDED_SQUAT(3, 20, 30),
            CLAMSHELL(3, 20, 30),
            FROG_PUMP(3, 25, 30),
        ]),
    ]


def glute_activation_series():
    return [
        workout("Glute Activation A - Wake Up", "strength", 30, [
            CLAMSHELL(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            GLUTE_BRIDGE(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Glute Activation B - Pre-Workout", "strength", 30, [
            LATERAL_BAND_WALK(3, 15, 30),
            BANDED_SQUAT(3, 12, 30),
            DONKEY_KICK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
        workout("Glute Activation C - Mind-Muscle", "strength", 30, [
            FROG_PUMP(3, 25, 30),
            FIRE_HYDRANT(3, 15, 30),
            ex("Single-Leg Glute Bridge", 3, 12, 30, "Per leg, squeeze at top", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Core"], "beginner",
               "One leg extended, drive through heel", "Glute Bridge"),
            CLAMSHELL(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
    ]


def upper_glute_shelf_builder():
    return [
        workout("Upper Glute Shelf A", "strength", 40, [
            ex("Abduction Machine", 4, 15, 45, "Moderate weight", "Machine", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus", "TFL"], "beginner",
               "Controlled tempo, squeeze at open position", "Fire Hydrant"),
            CABLE_KICKBACK(3, 15, 30),
            LATERAL_BAND_WALK(4, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Upper Glute Shelf B", "strength", 40, [
            SUMO_SQUAT(4, 15, 45),
            CURTSY_LUNGE(3, 12, 45),
            ex("Standing Cable Abduction", 3, 15, 30, "Light cable, per leg", "Cable Machine", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus"], "beginner",
               "Standing, lift leg to side against cable", "Lateral Band Walk"),
            FIRE_HYDRANT(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Upper Glute Shelf C", "strength", 40, [
            HIP_THRUST(3, 12, 90, "Feet close together for upper glute bias"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_KICKBACK(3, 15, 30),
            CLAMSHELL(3, 20, 30),
            DONKEY_KICK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
    ]


def glute_ham_developer():
    return [
        workout("Glute-Ham A - Hinge Focus", "strength", 40, [
            RDL(4, 10, 90),
            LEG_CURL(4, 12, 45),
            HIP_THRUST(3, 12, 90),
            SINGLE_LEG_RDL(3, 10, 45),
            GLUTE_BRIDGE(3, 15, 30),
        ]),
        workout("Glute-Ham B - Strength", "strength", 40, [
            SUMO_DEADLIFT(4, 6, 150),
            ex("Nordic Curl", 3, 5, 90, "Eccentric focus, slow lower", "Bodyweight", "Legs",
               "Hamstrings", ["Glutes", "Calves"], "advanced",
               "Kneel, slowly lower body forward, push back up", "Leg Curl"),
            CABLE_PULL_THROUGH(3, 12, 45),
            LEG_CURL(3, 12, 45),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Glute-Ham C - Volume", "strength", 45, [
            DB_RDL(3, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_CURL(3, 15, 45),
            HIP_THRUST(3, 15, 90),
            FIRE_HYDRANT(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
    ]


def glute_lab():
    return [
        workout("Glute Lab A - Heavy Day", "strength", 50, [
            HIP_THRUST(5, 8, 120, "Heavy barbell, Bret Contreras protocol"),
            BARBELL_SQUAT(4, 8, 120),
            CABLE_PULL_THROUGH(3, 12, 45),
            LATERAL_BAND_WALK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Glute Lab B - Unilateral", "strength", 45, [
            BULGARIAN_SPLIT_SQUAT(4, 10, 60),
            SINGLE_LEG_RDL(3, 10, 45),
            CABLE_KICKBACK(3, 15, 30),
            STEP_UP(3, 12, 60),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Glute Lab C - Pump Day", "strength", 45, [
            HIP_THRUST(4, 15, 60, "Moderate weight, high reps"),
            SUMO_SQUAT(3, 20, 45),
            FROG_PUMP(4, 25, 30),
            FIRE_HYDRANT(3, 20, 30),
            DONKEY_KICK(3, 20, 30),
            GLUTE_BRIDGE(3, 25, 30),
        ]),
        workout("Glute Lab D - Hinge & Abduction", "strength", 45, [
            RDL(4, 10, 90),
            LEG_CURL(3, 12, 45),
            CURTSY_LUNGE(3, 12, 45),
            LATERAL_BAND_WALK(4, 15, 30),
            BANDED_SQUAT(3, 15, 30),
        ]),
    ]


def strong_curves_advanced():
    return [
        workout("Strong Curves A - Max Effort Lower", "strength", 50, [
            HIP_THRUST(4, 8, 120, "Heavy barbell"),
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            CABLE_KICKBACK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Strong Curves B - Upper", "strength", 40, [
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_OHP(3, 10, 60),
            LAT_PULLDOWN(3, 10, 60),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Strong Curves C - Glute Accessory", "strength", 45, [
            BULGARIAN_SPLIT_SQUAT(4, 10, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            STEP_UP(3, 12, 60),
            DONKEY_KICK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Strong Curves D - Full Body", "strength", 45, [
            DEADLIFT(1, 5, 300),
            LEG_PRESS(3, 12, 90),
            PUSHUP(3, 12, 45),
            LAT_PULLDOWN(3, 10, 60),
            HIP_THRUST(3, 12, 90),
            PLANK(3, 1, 30),
        ]),
    ]


def peach_plan():
    return [
        workout("Peach Plan A - Glute Max", "strength", 40, [
            HIP_THRUST(4, 12, 90),
            SUMO_SQUAT(3, 15, 45),
            RDL(3, 10, 90),
            CABLE_KICKBACK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Peach Plan B - Glute Med", "strength", 35, [
            LATERAL_BAND_WALK(4, 15, 30),
            CURTSY_LUNGE(3, 12, 45),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            ex("Side-Lying Hip Abduction", 3, 15, 30, "Per leg", "Bodyweight", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus"], "beginner",
               "Lie on side, lift top leg with control", "Fire Hydrant"),
        ]),
        workout("Peach Plan C - Combo", "strength", 40, [
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            GLUTE_BRIDGE(3, 20, 30),
            STEP_UP(3, 12, 60),
            DONKEY_KICK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
    ]


def brazilian_butt_lift_program():
    return [
        workout("BBL Workout A - Lift & Shape", "strength", 40, [
            HIP_THRUST(4, 12, 90),
            SUMO_SQUAT(4, 15, 45),
            CABLE_KICKBACK(3, 15, 30),
            CURTSY_LUNGE(3, 12, 45),
            FROG_PUMP(3, 25, 30),
        ]),
        workout("BBL Workout B - Round & Full", "strength", 40, [
            BARBELL_SQUAT(4, 10, 120),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            DONKEY_KICK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("BBL Workout C - Volume Pump", "strength", 45, [
            HIP_THRUST(3, 15, 60),
            STEP_UP(3, 12, 60),
            RDL(3, 10, 90),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def glute_bridge_mastery():
    return [
        workout("Bridge Mastery A - Basics", "strength", 30, [
            GLUTE_BRIDGE(4, 20, 30),
            ex("Single-Leg Glute Bridge", 3, 12, 30, "Per leg", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Core"], "beginner",
               "One leg extended, drive heel into floor", "Glute Bridge"),
            FROG_PUMP(3, 20, 30),
            CLAMSHELL(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Bridge Mastery B - Loaded", "strength", 35, [
            HIP_THRUST(4, 12, 90),
            GLUTE_BRIDGE(3, 20, 30, "Banded for extra resistance"),
            ex("Marching Glute Bridge", 3, 10, 30, "Alternate lifting feet at top", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Core", "Hamstrings"], "intermediate",
               "Hold bridge position, march feet alternately", "Glute Bridge"),
            FIRE_HYDRANT(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Bridge Mastery C - Endurance", "strength", 30, [
            GLUTE_BRIDGE(3, 30, 30),
            FROG_PUMP(4, 30, 30),
            ex("Elevated Glute Bridge", 3, 15, 30, "Feet on bench", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Feet elevated on bench, drive through heels", "Glute Bridge"),
            CLAMSHELL(3, 20, 30),
            DONKEY_KICK(3, 20, 30),
        ]),
    ]


def booty_band_workout():
    return [
        workout("Booty Band A - Burn", "strength", 30, [
            LATERAL_BAND_WALK(4, 15, 30),
            BANDED_SQUAT(3, 20, 30),
            ex("Banded Glute Bridge", 3, 20, 30, "Band above knees", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Push knees out against band at lockout", "Glute Bridge"),
            CLAMSHELL(3, 20, 30),
            ex("Banded Fire Hydrant", 3, 15, 30, "Band above knees, per leg", "Resistance Band", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus"], "beginner",
               "All fours, lift knee to side against band", "Fire Hydrant"),
        ]),
        workout("Booty Band B - Sculpt", "strength", 30, [
            ex("Banded Sumo Squat", 3, 20, 30, "Band above knees, wide stance", "Resistance Band", "Legs",
               "Adductors", ["Glutes", "Quadriceps"], "beginner",
               "Wide stance, push knees out, chest up", "Sumo Squat"),
            LATERAL_BAND_WALK(3, 15, 30),
            ex("Banded Donkey Kick", 3, 15, 30, "Band around ankles, per leg", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Drive heel up against band resistance", "Donkey Kick"),
            ex("Banded Standing Kickback", 3, 15, 30, "Band around ankles, per leg", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Standing, kick back against band, squeeze at top", "Cable Kickback"),
            CLAMSHELL(3, 20, 30),
        ]),
        workout("Booty Band C - Endurance", "strength", 30, [
            BANDED_SQUAT(4, 25, 30),
            LATERAL_BAND_WALK(3, 20, 30),
            ex("Banded Frog Pump", 3, 25, 30, "Band above knees", "Resistance Band", "Glutes",
               "Gluteus Maximus", ["Adductors"], "beginner",
               "Soles together, drive knees out, thrust up", "Frog Pump"),
            ex("Banded Monster Walk", 3, 15, 30, "Band around ankles, forward steps", "Resistance Band", "Glutes",
               "Gluteus Medius", ["Quadriceps", "TFL"], "beginner",
               "Band around ankles, wide diagonal steps forward", "Lateral Band Walk"),
            CLAMSHELL(3, 25, 30),
        ]),
    ]


def glute_sculpt():
    return [
        workout("Glute Sculpt A - Shaping", "strength", 40, [
            HIP_THRUST(4, 12, 90),
            CABLE_KICKBACK(3, 15, 30),
            SUMO_SQUAT(3, 15, 45),
            CURTSY_LUNGE(3, 12, 45),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Glute Sculpt B - Toning", "strength", 40, [
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            DB_RDL(3, 12, 60),
            STEP_UP(3, 12, 60),
            LATERAL_BAND_WALK(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Glute Sculpt C - Definition", "strength", 40, [
            LEG_PRESS(3, 12, 90, "Feet high and wide"),
            CABLE_PULL_THROUGH(3, 12, 45),
            SINGLE_LEG_RDL(3, 10, 45),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def squat_booty_builder():
    return [
        workout("Squat Booty A - Back Squat Day", "strength", 45, [
            BARBELL_SQUAT(5, 8, 120, "ATG depth for max glute activation"),
            SUMO_SQUAT(3, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            GLUTE_BRIDGE(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Squat Booty B - Front Squat Day", "strength", 45, [
            FRONT_SQUAT(4, 8, 120),
            GOBLET_SQUAT(3, 12, 60),
            STEP_UP(3, 12, 60),
            DONKEY_KICK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Squat Booty C - Machine Day", "strength", 40, [
            LEG_PRESS(4, 12, 90, "Feet high and wide"),
            HACK_SQUAT(3, 10, 90),
            SUMO_SQUAT(3, 15, 45),
            CABLE_KICKBACK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
        ]),
    ]


def glute_and_hamstring_focus():
    return [
        workout("Glute & Ham A - Hinge Day", "strength", 45, [
            RDL(4, 10, 90),
            LEG_CURL(4, 12, 45),
            HIP_THRUST(3, 12, 90),
            SINGLE_LEG_RDL(3, 10, 45),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Glute & Ham B - Compound", "strength", 45, [
            SUMO_DEADLIFT(4, 6, 150),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            LEG_CURL(3, 12, 45),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Glute & Ham C - Accessory", "strength", 40, [
            DB_RDL(3, 12, 60),
            STEP_UP(3, 12, 60),
            ex("Nordic Curl", 3, 5, 90, "Eccentric focus", "Bodyweight", "Legs",
               "Hamstrings", ["Glutes", "Calves"], "advanced",
               "Kneel, slowly lower body forward", "Leg Curl"),
            GLUTE_BRIDGE(3, 20, 30),
            FIRE_HYDRANT(3, 15, 30),
        ]),
    ]


def bubble_butt_challenge():
    return [
        workout("Bubble Butt Day 1 - Foundation", "strength", 35, [
            HIP_THRUST(4, 12, 90),
            SUMO_SQUAT(3, 15, 45),
            GLUTE_BRIDGE(3, 20, 30),
            DONKEY_KICK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Bubble Butt Day 2 - Build", "strength", 35, [
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_KICKBACK(3, 15, 30),
            CURTSY_LUNGE(3, 12, 45),
            FROG_PUMP(3, 25, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Bubble Butt Day 3 - Burn", "strength", 40, [
            BARBELL_SQUAT(4, 10, 120),
            RDL(3, 10, 90),
            STEP_UP(3, 12, 60),
            FIRE_HYDRANT(3, 15, 30),
            GLUTE_BRIDGE(3, 25, 30),
            DONKEY_KICK(3, 20, 30),
        ]),
    ]


def thirty_day_glute_challenge():
    return [
        workout("30-Day Glute W1 - Activation", "strength", 30, [
            GLUTE_BRIDGE(3, 15, 30),
            DONKEY_KICK(3, 12, 30),
            FIRE_HYDRANT(3, 12, 30),
            CLAMSHELL(3, 12, 30),
            FROG_PUMP(3, 15, 30),
        ]),
        workout("30-Day Glute W2 - Build", "strength", 35, [
            HIP_THRUST(3, 12, 90),
            SUMO_SQUAT(3, 15, 45),
            CURTSY_LUNGE(3, 10, 45),
            LATERAL_BAND_WALK(3, 15, 30),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
        workout("30-Day Glute W3 - Strength", "strength", 40, [
            HIP_THRUST(4, 10, 90),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            RDL(3, 10, 90),
            CABLE_KICKBACK(3, 15, 30),
            FROG_PUMP(3, 20, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("30-Day Glute W4 - Peak", "strength", 45, [
            HIP_THRUST(5, 8, 120),
            BARBELL_SQUAT(4, 8, 120),
            STEP_UP(3, 12, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            FIRE_HYDRANT(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
    ]


def stairmaster_glute():
    return [
        workout("Stairmaster Glute A - Climb & Squeeze", "cardio", 35, [
            ex("Stairmaster Climb", 1, 1, 0, "20 min, moderate pace, skip a step for glute focus",
               "Stair Machine", "Legs", "Glutes", ["Quadriceps", "Calves", "Hamstrings"], "beginner",
               "Stand tall, no leaning on rails, squeeze glutes each step", "Incline Treadmill Walk"),
            GLUTE_BRIDGE(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
            CLAMSHELL(3, 15, 30),
        ]),
        workout("Stairmaster Glute B - Intervals", "cardio", 35, [
            ex("Stairmaster Intervals", 1, 1, 0, "25 min: 2 min moderate, 1 min fast, repeat",
               "Stair Machine", "Legs", "Glutes", ["Quadriceps", "Calves"], "intermediate",
               "Increase speed for intervals, maintain posture", "Incline Treadmill Walk"),
            SUMO_SQUAT(3, 15, 45),
            FROG_PUMP(3, 20, 30),
            FIRE_HYDRANT(3, 15, 30),
        ]),
        workout("Stairmaster Glute C - Side Steps", "cardio", 35, [
            ex("Stairmaster Side Steps", 1, 1, 0, "15 min: 5 min forward, 5 min right, 5 min left",
               "Stair Machine", "Legs", "Gluteus Medius", ["Adductors", "Quadriceps"], "intermediate",
               "Face sideways for lateral glute work, hold rail lightly", "Lateral Band Walk"),
            LATERAL_BAND_WALK(3, 15, 30),
            CURTSY_LUNGE(3, 12, 45),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def cable_glute_workout():
    return [
        workout("Cable Glutes A - Kickbacks & Pull-Throughs", "strength", 40, [
            CABLE_KICKBACK(4, 15, 30),
            CABLE_PULL_THROUGH(4, 12, 45),
            ex("Cable Sumo Squat", 3, 15, 45, "Low cable between legs", "Cable Machine", "Legs",
               "Glutes", ["Adductors", "Quadriceps"], "beginner",
               "Wide stance, squat with cable resistance", "Sumo Squat"),
            SUMO_SQUAT(3, 15, 45),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Cable Glutes B - Abduction Focus", "strength", 40, [
            ex("Cable Hip Abduction", 3, 15, 30, "Low cable, per leg", "Cable Machine", "Glutes",
               "Gluteus Medius", ["Gluteus Minimus"], "beginner",
               "Stand sideways to cable, lift leg away", "Lateral Band Walk"),
            CABLE_KICKBACK(3, 15, 30),
            ex("Cable Reverse Lunge", 3, 10, 60, "Per leg, cable on working side", "Cable Machine", "Legs",
               "Glutes", ["Quadriceps", "Hamstrings"], "intermediate",
               "Step back into lunge, cable adds resistance", "Reverse Lunge"),
            LATERAL_BAND_WALK(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
        workout("Cable Glutes C - Total Cable", "strength", 40, [
            CABLE_PULL_THROUGH(4, 12, 45),
            CABLE_KICKBACK(3, 15, 30),
            ex("Cable Romanian Deadlift", 3, 12, 60, "Low cable attachment", "Cable Machine", "Legs",
               "Hamstrings", ["Glutes", "Erector Spinae"], "intermediate",
               "Hip hinge, cable between legs, squeeze at top", "Romanian Deadlift"),
            CLAMSHELL(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
        ]),
    ]


def at_home_glute_builder():
    return [
        workout("Home Glute Builder A - No Equipment", "strength", 30, [
            GLUTE_BRIDGE(4, 20, 30),
            SUMO_SQUAT(3, 20, 45),
            DONKEY_KICK(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            FROG_PUMP(3, 25, 30),
        ]),
        workout("Home Glute Builder B - Bodyweight Circuit", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 20, 30),
            CURTSY_LUNGE(3, 12, 45),
            CLAMSHELL(3, 15, 30),
            REVERSE_LUNGE(3, 12, 45),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
        workout("Home Glute Builder C - Advanced BW", "strength", 35, [
            ex("Single-Leg Glute Bridge", 3, 12, 30, "Per leg", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings", "Core"], "intermediate",
               "One leg extended, drive through planted heel", "Glute Bridge"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Rear foot on chair"),
            SUMO_SQUAT(3, 20, 45),
            DONKEY_KICK(3, 20, 30),
            FIRE_HYDRANT(3, 20, 30),
            FROG_PUMP(3, 25, 30),
        ]),
    ]


###############################################################################
# VIRAL TIKTOK / YOUTUBE (15 programs)
###############################################################################

def treadmill_12_3_30_viral():
    return [
        workout("12-3-30 Treadmill Walk", "cardio", 35, [
            ex("Incline Treadmill Walk", 1, 1, 0, "12% incline, 3.0 mph, 30 min",
               "Treadmill", "Legs", "Glutes", ["Hamstrings", "Calves", "Quadriceps"], "beginner",
               "Stand upright, no holding rails, engage core", "Stairmaster 30 min"),
            ex("Walking Lunge Cooldown", 2, 10, 30, "Bodyweight", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes", "Hamstrings"], "beginner",
               "Long stride, knee to 90 degrees", "Stationary Lunge"),
            CALF_RAISE(2, 15, 30),
        ]),
    ]


def seventy_five_hard_modified_viral():
    return [
        workout("75 Hard - Outdoor Session", "conditioning", 45, [
            ex("Outdoor Walk or Jog", 1, 1, 0, "20 min at moderate pace", "Bodyweight", "Full Body",
               "Cardiovascular", ["Glutes", "Calves", "Core"], "beginner",
               "Maintain conversational pace, upright posture", "Indoor Treadmill Walk"),
            BODYWEIGHT_SQUAT(3, 15, 45),
            PUSHUP(3, 10, 45),
            PLANK(3, 1, 30),
            BURPEE(3, 8, 30),
        ]),
        workout("75 Hard - Indoor Strength", "strength", 45, [
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            GOBLET_SQUAT(3, 12, 60),
            DB_OHP(3, 10, 60),
            DB_RDL(3, 12, 60),
            PLANK(3, 1, 30),
        ]),
    ]


def wall_pilates_viral_program():
    return [
        workout("Wall Pilates - Lower Body", "pilates", 30, [
            PILATES_WALL_SQUAT(),
            ex("Wall Glute Kickback", 3, 12, 30, "Each leg", "Bodyweight", "Glutes",
               "Gluteus Maximus", ["Hamstrings"], "beginner",
               "Face wall, kick back with control, squeeze", "Standing Glute Squeeze"),
            PILATES_WALL_LEG_LIFT(),
            ex("Wall Calf Raise", 3, 15, 30, "Hands on wall for balance", "Bodyweight", "Legs",
               "Calves", ["Tibialis Anterior"], "beginner",
               "Full ROM, pause at top", "Standing Calf Raise"),
            ex("Wall Sit Hold", 3, 1, 30, "Hold 45 seconds", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes", "Core"], "beginner",
               "Back flat against wall, thighs parallel to floor", "Bodyweight Squat"),
        ]),
        workout("Wall Pilates - Upper & Core", "pilates", 30, [
            PILATES_WALL_PUSH(),
            ex("Wall Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core",
               "Rectus Abdominis", ["Obliques", "Shoulders"], "beginner",
               "Hands on wall at angle, straight body line", "Forearm Plank"),
            ex("Wall Angel", 3, 10, 30, "Slow, controlled", "Bodyweight", "Shoulders",
               "Rotator Cuff", ["Scapular Stabilizers"], "beginner",
               "Back to wall, slide arms up keeping contact", "Band Pull-Apart"),
            PILATES_WALL_LEG_LIFT(),
            PILATES_WALL_SQUAT(),
        ]),
    ]


def that_girl_routine_viral():
    return [
        workout("That Girl Morning Routine", "conditioning", 35, [
            ex("Morning Stretch Flow", 1, 1, 0, "5 min gentle full body stretch", "Bodyweight",
               "Full Body", "Hamstrings", ["Quadriceps", "Shoulders", "Back"], "beginner",
               "Breathe deeply, hold each stretch 20 seconds", "Cat-Cow"),
            BODYWEIGHT_SQUAT(3, 15, 30),
            MOUNTAIN_CLIMBER(3, 20, 20),
            REVERSE_LUNGE(3, 10, 30),
            PUSHUP(3, 8, 30),
            BICYCLE_CRUNCH(3, 15, 30),
        ]),
        workout("That Girl Evening Wind Down", "conditioning", 30, [
            GLUTE_BRIDGE(3, 15, 30),
            PLANK(3, 1, 30),
            DEAD_BUG(3, 10, 30),
            CLAMSHELL(3, 15, 30),
            ex("Gentle Forward Fold", 2, 1, 10, "Hold 30 seconds", "Bodyweight", "Full Body",
               "Hamstrings", ["Lower Back"], "beginner",
               "Hinge at hips, let head hang, breathe", "Seated Forward Fold"),
        ]),
    ]


def chloe_ting_style_viral():
    return [
        workout("Chloe Ting HIIT Abs", "hiit", 25, [
            JUMPING_JACK(3, 20, 15),
            BICYCLE_CRUNCH(3, 20, 15),
            JUMP_SQUAT(3, 12, 20),
            ex("Plank to Shoulder Tap", 3, 10, 15, "Alternating", "Bodyweight", "Core",
               "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate",
               "Minimize hip rotation, tap opposite shoulder", "Plank"),
            BURPEE(3, 8, 20),
            HANGING_LEG_RAISE(3, 12, 15),
            HIGH_KNEES(3, 20, 15),
        ]),
        workout("Chloe Ting Flat Tummy", "hiit", 20, [
            CRUNCHES(3, 20, 15),
            MOUNTAIN_CLIMBER(3, 20, 15),
            PLANK(3, 1, 15),
            BICYCLE_CRUNCH(3, 20, 15),
            RUSSIAN_TWIST(3, 20, 15),
            DEAD_BUG(3, 10, 15),
        ]),
    ]


def pamela_reif_style_viral():
    return [
        workout("Pamela Reif No-Rest Full Body", "hiit", 25, [
            ex("Squat Pulse", 3, 15, 10, "Bodyweight, stay low", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes"], "beginner",
               "Stay in bottom of squat, small pulses", "Wall Sit"),
            PUSHUP(3, 10, 10),
            SUMO_SQUAT(3, 15, 10),
            PLANK(2, 1, 10),
            JUMPING_LUNGE(3, 10, 10),
            MOUNTAIN_CLIMBER(3, 20, 10),
        ]),
        workout("Pamela Reif Booty Burn", "hiit", 20, [
            GLUTE_BRIDGE(3, 20, 10),
            DONKEY_KICK(3, 15, 10),
            FIRE_HYDRANT(3, 15, 10),
            SUMO_SQUAT(3, 20, 10),
            FROG_PUMP(3, 20, 10),
            CLAMSHELL(3, 20, 10),
        ]),
    ]


def blogilates_inspired():
    return [
        workout("Blogilates Pop Pilates - Core", "pilates", 30, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_SCISSORS(),
            PILATES_BICYCLE(),
            PILATES_SINGLE_LEG_STRETCH(),
            PLANK(3, 1, 30),
        ]),
        workout("Blogilates Sculpt & Tone", "pilates", 30, [
            PILATES_SWIMMING(),
            PILATES_SIDE_KICK(),
            PILATES_TEASER(),
            PILATES_SWAN(),
            GLUTE_BRIDGE(3, 15, 30),
            PILATES_SAW(),
        ]),
    ]


def daisy_keech_ab_program():
    return [
        workout("Daisy Keech Abs - Hourglass", "strength", 20, [
            BICYCLE_CRUNCH(3, 20, 15),
            ex("Toe Touch Crunch", 3, 15, 15, "Legs straight up, reach for toes", "Bodyweight", "Core",
               "Rectus Abdominis", ["Obliques"], "beginner",
               "Keep legs vertical, curl shoulders up to touch toes", "Crunch"),
            RUSSIAN_TWIST(3, 20, 15),
            PLANK(3, 1, 15),
            ex("Scissor Kicks", 3, 20, 15, "Alternating", "Bodyweight", "Core",
               "Lower Abs", ["Hip Flexors"], "beginner",
               "Lower back pressed to floor, alternate legs up and down", "Lying Leg Raise"),
            DEAD_BUG(3, 10, 15),
        ]),
        workout("Daisy Keech Abs - 10 Min", "strength", 15, [
            CRUNCHES(3, 25, 10),
            MOUNTAIN_CLIMBER(3, 20, 10),
            SIDE_PLANK(2, 1, 10),
            BICYCLE_CRUNCH(3, 20, 10),
            PLANK(2, 1, 10),
        ]),
    ]


def sami_clarke_booty():
    return [
        workout("Sami Clarke Booty Burn", "strength", 35, [
            SUMO_SQUAT(3, 15, 45),
            HIP_THRUST(3, 12, 90),
            CURTSY_LUNGE(3, 12, 45),
            CABLE_KICKBACK(3, 15, 30),
            FIRE_HYDRANT(3, 15, 30),
            FROG_PUMP(3, 20, 30),
        ]),
        workout("Sami Clarke Glute & Legs", "strength", 35, [
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            DB_RDL(3, 12, 60),
            LATERAL_BAND_WALK(3, 15, 30),
            STEP_UP(3, 12, 60),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
    ]


def madfit_quick_hiit():
    return [
        workout("MadFit 15-Min HIIT", "hiit", 15, [
            JUMP_SQUAT(3, 10, 15),
            PUSHUP(3, 8, 15),
            HIGH_KNEES(3, 20, 15),
            MOUNTAIN_CLIMBER(3, 20, 15),
            BURPEE(3, 6, 15),
        ]),
        workout("MadFit Apartment-Friendly", "hiit", 20, [
            BODYWEIGHT_SQUAT(3, 15, 15),
            PLANK(3, 1, 15),
            REVERSE_LUNGE(3, 10, 15),
            DEAD_BUG(3, 10, 15),
            SUMO_SQUAT(3, 15, 15),
            GLUTE_BRIDGE(3, 15, 15),
        ]),
    ]


def caroline_girvan_epic_style():
    return [
        workout("Epic Full Body - Dumbbell", "strength", 50, [
            DB_BENCH(4, 10, 60),
            DB_ROW(4, 10, 60),
            GOBLET_SQUAT(4, 12, 60),
            DB_OHP(3, 10, 60),
            DB_RDL(3, 12, 60),
            DB_CURL(3, 10, 45),
        ]),
        workout("Epic Leg Day", "strength", 50, [
            GOBLET_SQUAT(4, 12, 60),
            DB_RDL(4, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            DB_LUNGE(3, 10, 60),
            SUMO_SQUAT(3, 15, 45),
            GLUTE_BRIDGE(3, 20, 30),
        ]),
        workout("Epic Upper Body", "strength", 45, [
            DB_BENCH(4, 10, 60),
            DB_ROW(4, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            DB_CURL(3, 10, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
    ]


def sydney_cummings_full_body():
    return [
        workout("Sydney Cummings Full Body Strength", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60),
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_LUNGE(3, 10, 60),
            DB_OHP(3, 10, 60),
            PLANK(3, 1, 30),
        ]),
        workout("Sydney Cummings HIIT & Strength", "hiit", 40, [
            JUMP_SQUAT(3, 10, 30),
            DB_BENCH(3, 10, 60),
            BURPEE(3, 8, 30),
            DB_ROW(3, 10, 60),
            HIGH_KNEES(3, 20, 15),
            DB_RDL(3, 10, 60),
        ]),
        workout("Sydney Cummings Lower Body Focus", "strength", 40, [
            GOBLET_SQUAT(4, 12, 60),
            DB_RDL(3, 12, 60),
            DB_LUNGE(3, 10, 60),
            GLUTE_BRIDGE(3, 15, 30),
            STEP_UP(3, 12, 60),
            CALF_RAISE(3, 15, 30),
        ]),
    ]


def jeff_nippard_science():
    return [
        workout("Jeff Nippard Science Push", "strength", 50, [
            BARBELL_BENCH(4, 6, 180),
            INCLINE_BENCH(3, 8, 90),
            BARBELL_OHP(3, 8, 120),
            DB_LATERAL_RAISE(3, 15, 30),
            CABLE_FLY(3, 12, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Jeff Nippard Science Pull", "strength", 50, [
            DEADLIFT(1, 5, 300),
            BARBELL_ROW(4, 8, 120),
            PULLUP(3, 8, 90),
            CABLE_ROW(3, 12, 60),
            FACE_PULL(3, 15, 30),
            BARBELL_CURL(3, 10, 60),
        ]),
        workout("Jeff Nippard Science Legs", "strength", 50, [
            BARBELL_SQUAT(4, 6, 180),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            LEG_EXT(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def athleanx_style():
    return [
        workout("Athlean-X Push & Corrective", "strength", 50, [
            BARBELL_BENCH(4, 8, 120),
            DB_INCLINE_PRESS(3, 10, 60),
            BARBELL_OHP(3, 8, 120),
            FACE_PULL(3, 15, 30),
            BAND_PULL_APART(3, 15, 20),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Athlean-X Pull & Athletic", "strength", 50, [
            DEADLIFT(1, 5, 300),
            PULLUP(4, 8, 90),
            BARBELL_ROW(3, 8, 120),
            FACE_PULL(3, 15, 30),
            CABLE_ROW(3, 12, 60),
            BARBELL_CURL(3, 10, 60),
        ]),
        workout("Athlean-X Legs & Power", "strength", 50, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            BOX_JUMP(3, 8, 60),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def bret_contreras_glute():
    return [
        workout("Bret Contreras Glute A - Heavy", "strength", 50, [
            HIP_THRUST(5, 8, 120, "Heavy, Bret Contreras protocol"),
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            CABLE_KICKBACK(3, 15, 30),
            LATERAL_BAND_WALK(3, 15, 30),
        ]),
        workout("Bret Contreras Glute B - Volume", "strength", 45, [
            HIP_THRUST(4, 15, 60, "Moderate weight, pause reps"),
            BULGARIAN_SPLIT_SQUAT(3, 12, 60),
            CABLE_PULL_THROUGH(3, 12, 45),
            STEP_UP(3, 12, 60),
            FROG_PUMP(3, 25, 30),
        ]),
        workout("Bret Contreras Glute C - Activation", "strength", 40, [
            GLUTE_BRIDGE(3, 20, 30),
            SINGLE_LEG_RDL(3, 10, 45),
            CURTSY_LUNGE(3, 12, 45),
            FIRE_HYDRANT(3, 15, 30),
            CLAMSHELL(3, 15, 30),
            DONKEY_KICK(3, 15, 30),
        ]),
    ]


###############################################################################
# INFLUENCER / AESTHETIC (24 programs)
###############################################################################

def influencer_body_blueprint():
    return [
        workout("Blueprint Push - Chest & Shoulders", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            DB_INCLINE_PRESS(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            CABLE_FLY(3, 12, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Blueprint Pull - Back & Biceps", "strength", 45, [
            PULLUP(4, 8, 90),
            BARBELL_ROW(3, 8, 120),
            CABLE_ROW(3, 12, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 10, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Blueprint Legs", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            LEG_EXT(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def creator_aesthetic_training():
    return [
        workout("Aesthetic Chest & Arms", "strength", 45, [
            DB_BENCH(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            CABLE_FLY(3, 12, 45),
            DB_CURL(3, 10, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Aesthetic Back & Shoulders", "strength", 45, [
            LAT_PULLDOWN(4, 10, 60),
            CABLE_ROW(3, 12, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(4, 15, 30),
            FACE_PULL(3, 15, 30),
            REVERSE_PEC_DECK(3, 15, 30),
        ]),
        workout("Aesthetic Legs & Core", "strength", 45, [
            LEG_PRESS(4, 12, 90),
            RDL(3, 10, 90),
            LEG_EXT(3, 12, 45),
            LEG_CURL(3, 12, 45),
            PLANK(3, 1, 30),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def ring_light_ready():
    return [
        workout("Ring Light Ready - Upper Pump", "strength", 40, [
            DB_BENCH(3, 12, 45),
            DB_LATERAL_RAISE(4, 15, 30),
            CABLE_FLY(3, 12, 45),
            DB_CURL(3, 12, 30),
            TRICEP_PUSHDOWN(3, 12, 30),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Ring Light Ready - Lower Tone", "strength", 40, [
            GOBLET_SQUAT(3, 15, 45),
            DB_RDL(3, 12, 60),
            DB_LUNGE(3, 10, 45),
            GLUTE_BRIDGE(3, 15, 30),
            PLANK(3, 1, 30),
            CALF_RAISE(3, 15, 30),
        ]),
        workout("Ring Light Ready - Full Pump", "strength", 40, [
            PUSHUP(3, 15, 30),
            BODYWEIGHT_SQUAT(3, 20, 30),
            DB_LATERAL_RAISE(3, 15, 30),
            DB_CURL(3, 12, 30),
            SUMO_SQUAT(3, 15, 30),
            PLANK(3, 1, 30),
        ]),
    ]


def camera_confidence_workout():
    return [
        workout("Camera Confidence - Shoulders & Arms", "strength", 40, [
            DB_OHP(4, 10, 60),
            DB_LATERAL_RAISE(4, 15, 30),
            ARNOLD_PRESS(3, 10, 60),
            DB_CURL(3, 12, 45),
            TRICEP_OVERHEAD(3, 12, 45),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Camera Confidence - Chest & Back", "strength", 40, [
            DB_BENCH(4, 10, 60),
            DB_ROW(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            LAT_PULLDOWN(3, 10, 60),
            CABLE_FLY(3, 12, 45),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Camera Confidence - Lower & Core", "strength", 40, [
            GOBLET_SQUAT(4, 12, 60),
            DB_RDL(3, 12, 60),
            DB_LUNGE(3, 10, 60),
            HIP_THRUST(3, 12, 90),
            PLANK(3, 1, 30),
            BICYCLE_CRUNCH(3, 20, 30),
        ]),
    ]


def content_creator_energy():
    return [
        workout("Creator Energy - Full Body HIIT", "hiit", 30, [
            JUMP_SQUAT(3, 10, 30),
            PUSHUP(3, 12, 30),
            MOUNTAIN_CLIMBER(3, 20, 20),
            DB_ROW(3, 10, 45),
            BURPEE(3, 8, 30),
            PLANK(3, 1, 30),
        ]),
        workout("Creator Energy - Strength & Tone", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60),
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_CURL(3, 10, 45),
            GLUTE_BRIDGE(3, 15, 30),
        ]),
    ]


def fitness_influencer_journey():
    return [
        workout("Influencer Journey - Push", "strength", 45, [
            DB_BENCH(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            CABLE_FLY(3, 12, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Influencer Journey - Pull", "strength", 45, [
            LAT_PULLDOWN(4, 10, 60),
            DB_ROW(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 10, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Influencer Journey - Legs", "strength", 45, [
            GOBLET_SQUAT(4, 12, 60),
            DB_RDL(3, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_CURL(3, 12, 45),
            GLUTE_BRIDGE(3, 15, 30),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def posing_and_flexing_mastery():
    return [
        workout("Pose Prep - Upper Body Pump", "strength", 40, [
            DB_BENCH(3, 12, 45),
            DB_LATERAL_RAISE(4, 15, 30),
            CABLE_FLY(3, 12, 30),
            DB_CURL(3, 15, 30),
            TRICEP_PUSHDOWN(3, 15, 30),
            DB_SHRUG(3, 15, 30),
        ]),
        workout("Pose Prep - Lower Body Pump", "strength", 35, [
            LEG_PRESS(3, 15, 60),
            LEG_EXT(3, 15, 30),
            LEG_CURL(3, 15, 30),
            CALF_RAISE(4, 20, 30),
            HIP_THRUST(3, 15, 60),
        ]),
        workout("Pose Prep - Full Body", "strength", 40, [
            PUSHUP(3, 15, 30),
            LAT_PULLDOWN(3, 12, 45),
            GOBLET_SQUAT(3, 15, 45),
            DB_LATERAL_RAISE(3, 15, 30),
            DB_CURL(3, 12, 30),
            PLANK(3, 1, 30),
        ]),
    ]


def live_stream_workout_host():
    return [
        workout("Live Stream - Follow Along Upper", "strength", 30, [
            PUSHUP(3, 12, 30),
            DB_LATERAL_RAISE(3, 12, 30),
            DB_ROW(3, 10, 30),
            DB_CURL(3, 10, 30),
            PLANK(3, 1, 30),
        ]),
        workout("Live Stream - Follow Along Lower", "strength", 30, [
            BODYWEIGHT_SQUAT(3, 15, 30),
            REVERSE_LUNGE(3, 10, 30),
            GLUTE_BRIDGE(3, 15, 30),
            SUMO_SQUAT(3, 15, 30),
            CALF_RAISE(3, 15, 30),
        ]),
        workout("Live Stream - Follow Along HIIT", "hiit", 25, [
            JUMPING_JACK(3, 20, 15),
            MOUNTAIN_CLIMBER(3, 20, 15),
            JUMP_SQUAT(3, 10, 15),
            BURPEE(3, 6, 20),
            HIGH_KNEES(3, 20, 15),
        ]),
    ]


def social_media_body():
    return [
        workout("Social Media Body - Chest & Triceps", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            DB_INCLINE_PRESS(3, 10, 60),
            CABLE_FLY(3, 12, 45),
            DIP(3, 10, 90),
            TRICEP_PUSHDOWN(3, 12, 45),
            SKULL_CRUSHER(3, 10, 60),
        ]),
        workout("Social Media Body - Back & Biceps", "strength", 45, [
            PULLUP(4, 8, 90),
            BARBELL_ROW(3, 8, 120),
            LAT_PULLDOWN(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            BARBELL_CURL(3, 10, 60),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Social Media Body - Shoulders & Legs", "strength", 50, [
            BARBELL_OHP(4, 8, 120),
            DB_LATERAL_RAISE(4, 15, 30),
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_EXT(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def side_hustle_fitness():
    return [
        workout("Side Hustle - Quick Upper", "strength", 30, [
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_CURL(3, 10, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Side Hustle - Quick Lower", "strength", 30, [
            GOBLET_SQUAT(3, 12, 60),
            DB_RDL(3, 12, 60),
            DB_LUNGE(3, 10, 60),
            GLUTE_BRIDGE(3, 15, 30),
            CALF_RAISE(3, 15, 30),
        ]),
        workout("Side Hustle - Express HIIT", "hiit", 20, [
            JUMP_SQUAT(3, 10, 20),
            PUSHUP(3, 12, 20),
            MOUNTAIN_CLIMBER(3, 20, 15),
            BURPEE(3, 6, 20),
            PLANK(2, 1, 15),
        ]),
    ]


def before_and_after_transformation():
    return [
        workout("Transformation Upper A", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            BARBELL_ROW(4, 8, 120),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            DB_CURL(3, 10, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Transformation Lower A", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(4, 15, 30),
            PLANK(3, 1, 30),
        ]),
        workout("Transformation Upper B", "strength", 45, [
            DB_INCLINE_PRESS(4, 10, 60),
            PULLUP(3, 8, 90),
            ARNOLD_PRESS(3, 10, 60),
            CABLE_FLY(3, 12, 45),
            HAMMER_CURL(3, 10, 45),
            TRICEP_OVERHEAD(3, 12, 45),
        ]),
        workout("Transformation Lower B", "strength", 45, [
            DEADLIFT(1, 5, 300),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_PRESS(3, 12, 90),
            LEG_EXT(3, 12, 45),
            HIP_THRUST(3, 12, 90),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def viral_physique_challenge():
    return [
        workout("Viral Physique - Push Day", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            DB_INCLINE_PRESS(3, 10, 60),
            BARBELL_OHP(3, 8, 120),
            DB_LATERAL_RAISE(3, 15, 30),
            TRICEP_PUSHDOWN(3, 12, 45),
            CABLE_FLY(3, 12, 45),
        ]),
        workout("Viral Physique - Pull Day", "strength", 45, [
            DEADLIFT(1, 5, 300),
            PULLUP(4, 8, 90),
            BARBELL_ROW(3, 8, 120),
            FACE_PULL(3, 15, 30),
            BARBELL_CURL(3, 10, 60),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Viral Physique - Leg Day", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            LEG_EXT(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def fitness_influencer_challenge():
    return [
        workout("Influencer Challenge - Day 1 Full Body", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60),
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_OHP(3, 10, 60),
            GLUTE_BRIDGE(3, 15, 30),
            PLANK(3, 1, 30),
        ]),
        workout("Influencer Challenge - Day 2 HIIT", "hiit", 30, [
            JUMP_SQUAT(3, 10, 30),
            PUSHUP(3, 12, 30),
            MOUNTAIN_CLIMBER(3, 20, 20),
            BURPEE(3, 8, 30),
            HIGH_KNEES(3, 20, 15),
            PLANK(3, 1, 30),
        ]),
        workout("Influencer Challenge - Day 3 Lower Focus", "strength", 40, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            HIP_THRUST(3, 12, 90),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def thirty_day_transformation():
    return [
        workout("30-Day Week 1 - Foundations", "strength", 35, [
            BODYWEIGHT_SQUAT(3, 15, 30),
            PUSHUP(3, 10, 30),
            DB_ROW(3, 10, 60),
            PLANK(3, 1, 30),
            GLUTE_BRIDGE(3, 15, 30),
        ]),
        workout("30-Day Week 2 - Build", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60),
            DB_BENCH(3, 10, 60),
            DB_ROW(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_RDL(3, 12, 60),
            PLANK(3, 1, 30),
        ]),
        workout("30-Day Week 3 - Intensify", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            BARBELL_BENCH(3, 8, 120),
            BARBELL_ROW(3, 8, 120),
            DB_LATERAL_RAISE(3, 15, 30),
            RDL(3, 10, 90),
            DB_CURL(3, 10, 45),
        ]),
        workout("30-Day Week 4 - Peak", "strength", 50, [
            BARBELL_SQUAT(4, 6, 180),
            BARBELL_BENCH(4, 6, 180),
            DEADLIFT(1, 5, 300),
            BARBELL_OHP(3, 8, 120),
            PULLUP(3, 8, 90),
            PLANK(3, 1, 30),
        ]),
    ]


def before_and_after_program():
    return [
        workout("Before & After - Upper Push", "strength", 45, [
            DB_BENCH(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Before & After - Upper Pull", "strength", 45, [
            PULLUP(3, 8, 90),
            DB_ROW(4, 10, 60),
            LAT_PULLDOWN(3, 10, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 10, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Before & After - Lower", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            HIP_THRUST(3, 12, 90),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def social_media_shred():
    return [
        workout("Shred Push", "strength", 45, [
            BARBELL_BENCH(4, 10, 90),
            DB_INCLINE_PRESS(3, 12, 60),
            CABLE_FLY(3, 15, 45),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            TRICEP_PUSHDOWN(3, 15, 30),
        ]),
        workout("Shred Pull", "strength", 45, [
            PULLUP(4, 8, 90),
            CABLE_ROW(3, 12, 60),
            LAT_PULLDOWN(3, 12, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 12, 45),
            HAMMER_CURL(3, 12, 45),
        ]),
        workout("Shred Legs", "strength", 45, [
            BARBELL_SQUAT(4, 10, 90),
            RDL(3, 12, 60),
            LEG_PRESS(3, 15, 60),
            LEG_CURL(3, 15, 30),
            LEG_EXT(3, 15, 30),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def instagram_worthy_body():
    return [
        workout("IG Body - Chest & Arms", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            DB_INCLINE_PRESS(3, 10, 60),
            CABLE_FLY(3, 12, 45),
            BARBELL_CURL(3, 10, 60),
            SKULL_CRUSHER(3, 10, 60),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("IG Body - Back & Shoulders", "strength", 45, [
            PULLUP(4, 8, 90),
            BARBELL_ROW(3, 8, 120),
            LAT_PULLDOWN(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(4, 15, 30),
            FACE_PULL(3, 15, 30),
        ]),
        workout("IG Body - Legs & Abs", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            HANGING_LEG_RAISE(3, 10, 60),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def youtube_trainer_program():
    return [
        workout("YouTube Trainer - Full Body A", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            BARBELL_BENCH(4, 8, 120),
            BARBELL_ROW(3, 8, 120),
            DB_OHP(3, 10, 60),
            DB_CURL(3, 10, 45),
            PLANK(3, 1, 30),
        ]),
        workout("YouTube Trainer - Full Body B", "strength", 45, [
            DEADLIFT(1, 5, 300),
            DB_INCLINE_PRESS(3, 10, 60),
            PULLUP(3, 8, 90),
            DB_LATERAL_RAISE(3, 15, 30),
            RDL(3, 10, 90),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("YouTube Trainer - Full Body C", "strength", 45, [
            FRONT_SQUAT(3, 8, 120),
            DB_BENCH(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            ARNOLD_PRESS(3, 10, 60),
            LEG_CURL(3, 12, 45),
            BARBELL_CURL(3, 10, 60),
        ]),
    ]


def podcast_workout():
    return [
        workout("Podcast Workout - Steady State", "cardio", 45, [
            ex("Incline Treadmill Walk", 1, 1, 0, "3.5 mph, 8% incline, 30 min - listen to your podcast",
               "Treadmill", "Legs", "Glutes", ["Quadriceps", "Calves", "Hamstrings"], "beginner",
               "Comfortable pace, upright posture", "Outdoor Walk"),
            DB_LUNGE(2, 10, 45),
            GOBLET_SQUAT(2, 12, 45),
            GLUTE_BRIDGE(2, 15, 30),
        ]),
        workout("Podcast Workout - Machine Circuit", "strength", 45, [
            LEG_PRESS(3, 12, 60),
            CHEST_PRESS_MACHINE(3, 10, 60),
            LAT_PULLDOWN(3, 10, 60),
            SHOULDER_PRESS_MACHINE(3, 10, 60),
            LEG_CURL(3, 12, 45),
            LEG_EXT(3, 12, 45),
        ]),
    ]


def gym_bro_split():
    return [
        workout("Bro Split - Chest Day", "strength", 50, [
            BARBELL_BENCH(5, 5, 180),
            INCLINE_BENCH(3, 8, 90),
            DB_FLY(3, 12, 45),
            CABLE_FLY(3, 12, 45),
            PEC_DECK(3, 12, 45),
            DIP(3, 10, 90),
        ]),
        workout("Bro Split - Back Day", "strength", 50, [
            DEADLIFT(1, 5, 300),
            PULLUP(4, 8, 90),
            BARBELL_ROW(4, 8, 120),
            LAT_PULLDOWN(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            DB_SHRUG(3, 15, 30),
        ]),
        workout("Bro Split - Shoulder Day", "strength", 45, [
            BARBELL_OHP(4, 8, 120),
            DB_LATERAL_RAISE(4, 15, 30),
            ARNOLD_PRESS(3, 10, 60),
            FACE_PULL(3, 15, 30),
            REVERSE_PEC_DECK(3, 15, 30),
            DB_SHRUG(3, 15, 30),
        ]),
        workout("Bro Split - Arm Day", "strength", 40, [
            BARBELL_CURL(4, 10, 60),
            CLOSE_GRIP_BENCH(3, 8, 90),
            HAMMER_CURL(3, 10, 45),
            SKULL_CRUSHER(3, 10, 60),
            CONCENTRATION_CURL(3, 12, 30),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Bro Split - Leg Day", "strength", 50, [
            BARBELL_SQUAT(5, 5, 180),
            LEG_PRESS(4, 12, 90),
            RDL(3, 10, 90),
            LEG_EXT(3, 12, 45),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(5, 15, 30),
        ]),
    ]


def gym_girl_aesthetic():
    return [
        workout("Gym Girl - Glutes & Legs", "strength", 45, [
            HIP_THRUST(4, 12, 90),
            BARBELL_SQUAT(3, 10, 120),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            CABLE_KICKBACK(3, 15, 30),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
        workout("Gym Girl - Upper Body Tone", "strength", 40, [
            LAT_PULLDOWN(3, 10, 60),
            DB_BENCH(3, 10, 60),
            DB_OHP(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Gym Girl - Glute & Abs", "strength", 40, [
            HIP_THRUST(3, 15, 60),
            SUMO_SQUAT(3, 15, 45),
            CABLE_KICKBACK(3, 15, 30),
            HANGING_LEG_RAISE(3, 10, 60),
            BICYCLE_CRUNCH(3, 20, 30),
            PLANK(3, 1, 30),
        ]),
    ]


def tiktok_gym_routine():
    return [
        workout("TikTok Gym - Push", "strength", 40, [
            DB_BENCH(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            CABLE_FLY(3, 12, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("TikTok Gym - Pull", "strength", 40, [
            LAT_PULLDOWN(4, 10, 60),
            CABLE_ROW(3, 12, 60),
            DB_ROW(3, 10, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 10, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("TikTok Gym - Legs", "strength", 40, [
            LEG_PRESS(4, 12, 90),
            DB_RDL(3, 12, 60),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_CURL(3, 12, 45),
            HIP_THRUST(3, 12, 90),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def fitness_vlogger_program():
    return [
        workout("Vlogger - Upper A", "strength", 45, [
            BARBELL_BENCH(4, 8, 120),
            PULLUP(4, 8, 90),
            DB_OHP(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            DB_LATERAL_RAISE(3, 15, 30),
            DB_CURL(3, 10, 45),
        ]),
        workout("Vlogger - Lower A", "strength", 45, [
            BARBELL_SQUAT(4, 8, 120),
            RDL(3, 10, 90),
            LEG_PRESS(3, 12, 90),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(4, 15, 30),
            PLANK(3, 1, 30),
        ]),
        workout("Vlogger - Upper B", "strength", 45, [
            DB_INCLINE_PRESS(4, 10, 60),
            BARBELL_ROW(4, 8, 120),
            ARNOLD_PRESS(3, 10, 60),
            LAT_PULLDOWN(3, 10, 60),
            TRICEP_PUSHDOWN(3, 12, 45),
            FACE_PULL(3, 15, 30),
        ]),
        workout("Vlogger - Lower B", "strength", 45, [
            DEADLIFT(1, 5, 300),
            FRONT_SQUAT(3, 8, 120),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_EXT(3, 12, 45),
            HIP_THRUST(3, 12, 90),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


def content_creator_body():
    return [
        workout("Creator Body - Chest & Delts", "strength", 45, [
            DB_BENCH(4, 10, 60),
            DB_INCLINE_PRESS(3, 10, 60),
            DB_OHP(3, 10, 60),
            DB_LATERAL_RAISE(4, 15, 30),
            CABLE_FLY(3, 12, 45),
            TRICEP_PUSHDOWN(3, 12, 45),
        ]),
        workout("Creator Body - Back & Arms", "strength", 45, [
            LAT_PULLDOWN(4, 10, 60),
            DB_ROW(3, 10, 60),
            CABLE_ROW(3, 12, 60),
            FACE_PULL(3, 15, 30),
            DB_CURL(3, 10, 45),
            HAMMER_CURL(3, 10, 45),
        ]),
        workout("Creator Body - Legs", "strength", 45, [
            GOBLET_SQUAT(4, 12, 60),
            DB_RDL(3, 12, 60),
            LEG_PRESS(3, 12, 90),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60),
            LEG_CURL(3, 12, 45),
            CALF_RAISE(4, 15, 30),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS - maps program name -> function
###############################################################################

BATCH_WORKOUTS = {
    # Glute Building (28)
    "Booty Basics": booty_basics,
    "Glute Building Foundations": glute_building_foundations,
    "At-Home Booty Builder": at_home_booty_builder,
    "Resistance Band Glutes": resistance_band_glutes,
    "Advanced Glute Builder": advanced_glute_builder,
    "Science-Based Glute Training": science_based_glute_training,
    "Hip Thrust Specialization": hip_thrust_specialization,
    "Peach Builder": peach_builder,
    "Glutes & Abs Combo": glutes_and_abs_combo,
    "Lower Body Sculpt": lower_body_sculpt,
    "High Volume Glute Workout": high_volume_glute_workout,
    "Glute Activation Series": glute_activation_series,
    "Upper Glute Shelf Builder": upper_glute_shelf_builder,
    "Glute-Ham Developer": glute_ham_developer,
    "Glute Lab": glute_lab,
    "Strong Curves Advanced": strong_curves_advanced,
    "Peach Plan": peach_plan,
    "Brazilian Butt Lift": brazilian_butt_lift_program,
    "Glute Bridge Mastery": glute_bridge_mastery,
    "Booty Band Workout": booty_band_workout,
    "Glute Sculpt": glute_sculpt,
    "Squat Booty Builder": squat_booty_builder,
    "Glute & Hamstring Focus": glute_and_hamstring_focus,
    "Bubble Butt Challenge": bubble_butt_challenge,
    "30-Day Glute Challenge": thirty_day_glute_challenge,
    "Stairmaster Glute": stairmaster_glute,
    "Cable Glute Workout": cable_glute_workout,
    "At-Home Glute Builder": at_home_glute_builder,

    # Viral TikTok / YouTube (15)
    "12-3-30 Treadmill": treadmill_12_3_30_viral,
    "75 Hard Modified": seventy_five_hard_modified_viral,
    "Wall Pilates Viral": wall_pilates_viral_program,
    "That Girl Routine": that_girl_routine_viral,
    "Chloe Ting Style": chloe_ting_style_viral,
    "Pamela Reif Style": pamela_reif_style_viral,
    "Blogilates Inspired": blogilates_inspired,
    "Daisy Keech Ab Program": daisy_keech_ab_program,
    "Sami Clarke Booty": sami_clarke_booty,
    "Madfit Quick HIIT": madfit_quick_hiit,
    "Caroline Girvan Epic Style": caroline_girvan_epic_style,
    "Sydney Cummings Full Body": sydney_cummings_full_body,
    "Jeff Nippard Science": jeff_nippard_science,
    "Athlean-X Style": athleanx_style,
    "Bret Contreras Glute": bret_contreras_glute,

    # Influencer / Aesthetic (24)
    "Influencer Body Blueprint": influencer_body_blueprint,
    "Creator Aesthetic Training": creator_aesthetic_training,
    "Ring Light Ready": ring_light_ready,
    "Camera Confidence Workout": camera_confidence_workout,
    "Content Creator Energy": content_creator_energy,
    "Fitness Influencer Journey": fitness_influencer_journey,
    "Posing & Flexing Mastery": posing_and_flexing_mastery,
    "Live Stream Workout Host": live_stream_workout_host,
    "Social Media Body": social_media_body,
    "Side Hustle Fitness": side_hustle_fitness,
    "Before & After Transformation": before_and_after_transformation,
    "Viral Physique Challenge": viral_physique_challenge,
    "Fitness Influencer Challenge": fitness_influencer_challenge,
    "30-Day Transformation": thirty_day_transformation,
    "Before & After Program": before_and_after_program,
    "Social Media Shred": social_media_shred,
    "Instagram Worthy Body": instagram_worthy_body,
    "YouTube Trainer Program": youtube_trainer_program,
    "Podcast Workout": podcast_workout,
    "Gym Bro Split": gym_bro_split,
    "Gym Girl Aesthetic": gym_girl_aesthetic,
    "TikTok Gym Routine": tiktok_gym_routine,
    "Fitness Vlogger Program": fitness_vlogger_program,
    "Content Creator Body": content_creator_body,
}
