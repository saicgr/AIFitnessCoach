#!/usr/bin/env python3
"""
Batch 10: Body Composition, Competition, Sports, and Misc Programs
===================================================================
63 programs covering fat loss/aesthetics, competition prep, sports-specific
training, and general athlete/hybrid programs.
"""

from exercise_lib import *


###############################################################################
# BODY COMPOSITION / AESTHETICS
###############################################################################

# 1. Shred Program
def _shred_program():
    return [
        workout("Shred Upper Body", "hiit", 50, [
            BARBELL_BENCH(4, 10, 60, "Moderate weight, keep rest short"),
            BARBELL_ROW(4, 10, 60, "Superset with bench"),
            DB_INCLINE_PRESS(3, 12, 45, "Upper chest burn"),
            PULLUP(3, 10, 60, "Bodyweight"),
            DB_LATERAL_RAISE(3, 15, 20, "Light, burn out"),
            TRICEP_PUSHDOWN(3, 15, 20, "Superset with curls"),
            DB_CURL(3, 15, 20, "Light, high rep"),
        ]),
        workout("Shred Lower Body", "hiit", 50, [
            BARBELL_SQUAT(4, 10, 60, "Moderate weight, short rest"),
            RDL(3, 12, 60, "Feel the stretch"),
            LEG_PRESS(3, 15, 45, "High rep, quad burn"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            JUMP_SQUAT(3, 10, 30, "Explosive, fat burning"),
            CALF_RAISE(4, 20, 20, "High rep calf burn"),
        ]),
        workout("Shred Cardio & Core", "cardio", 40, [
            BURPEE(3, 15, 30, "Full range"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds fast"),
            BATTLE_ROPES(3, 1, 30, "30 seconds each"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
            PLANK(3, 1, 20, "60 seconds hold"),
            BICYCLE_CRUNCH(3, 20, 20, "Controlled"),
            RUSSIAN_TWIST(3, 20, 20, "Optional weight"),
        ]),
    ]


# 2. Extreme Shred
def _extreme_shred():
    return [
        workout("Extreme Shred A: Upper", "hiit", 55, [
            BARBELL_BENCH(4, 12, 45, "Short rest, keep heart rate up"),
            PULLUP(4, 10, 45, "Superset with bench"),
            DB_OHP(3, 12, 30, "No rest before lateral raise"),
            DB_LATERAL_RAISE(3, 15, 30, "Superset with OHP"),
            TRICEP_PUSHDOWN(4, 15, 20, "High rep burnout"),
            DB_CURL(4, 15, 20, "High rep burnout"),
            BURPEE(2, 10, 30, "Finisher"),
        ]),
        workout("Extreme Shred B: Lower", "hiit", 55, [
            BARBELL_SQUAT(4, 12, 45, "Short rest"),
            JUMPING_LUNGE(3, 12, 30, "Plyometric"),
            RDL(3, 12, 45, "Hamstring stretch"),
            LEG_CURL(3, 15, 30, "Superset with leg ext"),
            LEG_EXT(3, 15, 30, "Superset with leg curl"),
            JUMP_SQUAT(3, 12, 30, "Explosive"),
            CALF_RAISE(4, 20, 15, "High rep"),
        ]),
        workout("Extreme Shred C: HIIT Cardio", "cardio", 35, [
            cardio_ex("Sprint Intervals", 20, "20s sprint 10s rest x10", "Bodyweight", "advanced"),
            BATTLE_ROPES(4, 1, 20, "30 seconds max effort"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast"),
            BURPEE(3, 15, 20, "No rest"),
            HIGH_KNEES(3, 30, 15, "Max pace"),
            PLANK(3, 1, 15, "45 seconds"),
        ]),
    ]


# 3. Rapid Fat Loss
def _rapid_fat_loss():
    return [
        workout("Full Body Metabolic A", "hiit", 45, [
            BARBELL_SQUAT(4, 10, 60, "Moderate weight"),
            BARBELL_BENCH(4, 10, 60, "Superset with row"),
            BARBELL_ROW(4, 10, 60, "Superset with bench"),
            DEADLIFT(3, 8, 90, "Moderate weight"),
            BURPEE(2, 10, 30, "Finisher"),
        ]),
        workout("Full Body Metabolic B", "hiit", 45, [
            BARBELL_OHP(4, 10, 60, "Moderate weight"),
            PULLUP(4, 8, 60, "Superset with OHP"),
            GOBLET_SQUAT(4, 15, 45, "Lighter weight, high rep"),
            KETTLEBELL_SWING(3, 20, 45, "Hip hinge power"),
            MOUNTAIN_CLIMBER(2, 30, 20, "Finisher"),
        ]),
        workout("Cardio Fat Burner", "cardio", 40, [
            JUMP_ROPE(5, 1, 30, "60s on 30s off"),
            HIGH_KNEES(4, 30, 15, "30 seconds fast"),
            BURPEE(3, 12, 30, "Full range"),
            JUMPING_JACK(3, 30, 15, "30 seconds"),
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
        ]),
    ]


# 4. Stubborn Fat Loss
def _stubborn_fat_loss():
    return [
        workout("AM Fasted Cardio", "cardio", 35, [
            cardio_ex("Steady State Walking", 1200, "20 min moderate pace, fasted", "Bodyweight", "beginner"),
            MOUNTAIN_CLIMBER(2, 30, 20, "Activate core"),
            HIGH_KNEES(2, 30, 15, "Light warm-up pace"),
            PLANK(3, 1, 20, "45 seconds"),
        ]),
        workout("Resistance Training: Compound Focus", "strength", 55, [
            BARBELL_SQUAT(4, 8, 90, "Moderate weight, full depth"),
            DEADLIFT(3, 6, 120, "Conventional"),
            BARBELL_BENCH(4, 8, 90, "Compound chest"),
            BARBELL_ROW(4, 8, 90, "Back thickness"),
            BARBELL_OHP(3, 8, 90, "Shoulder press"),
            CALF_RAISE(4, 15, 30, "High rep"),
        ]),
        workout("HIIT Finisher", "hiit", 25, [
            BURPEE(4, 10, 30, "Max effort"),
            JUMP_SQUAT(4, 12, 30, "Explosive"),
            BATTLE_ROPES(3, 1, 30, "30s alternating waves"),
            MOUNTAIN_CLIMBER(3, 30, 20, "Fast pace"),
        ]),
    ]


# 5. Sustainable Fat Loss
def _sustainable_fat_loss():
    return [
        workout("Strength Day A", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Progressive overload, moderate weight"),
            BARBELL_BENCH(3, 8, 120, "Moderate weight"),
            BARBELL_ROW(3, 8, 90, "Full ROM"),
            PLANK(3, 1, 30, "45-60 seconds"),
            CALF_RAISE(3, 15, 30, "Full stretch"),
        ]),
        workout("Strength Day B", "strength", 50, [
            DEADLIFT(3, 6, 150, "Moderate weight"),
            BARBELL_OHP(3, 8, 90, "Strict press"),
            PULLUP(3, 8, 90, "Or lat pulldown"),
            HANGING_LEG_RAISE(3, 12, 45, "Core"),
            FACE_PULL(3, 15, 30, "Prehab"),
        ]),
        workout("Active Cardio Session", "cardio", 40, [
            cardio_ex("Brisk Walking or Light Jog", 1800, "30 minutes zone 2 cardio", "Bodyweight", "beginner"),
            PLANK(2, 1, 20, "30 second holds"),
            BICYCLE_CRUNCH(2, 20, 20, "Core finish"),
        ]),
    ]


# 6. Cut & Maintain
def _cut_and_maintain():
    return [
        workout("Upper: Strength Maintain", "strength", 50, [
            BARBELL_BENCH(4, 6, 120, "Maintain strength, moderate weight"),
            BARBELL_ROW(4, 6, 120, "Keep pulling strength"),
            BARBELL_OHP(3, 6, 90, "Maintain overhead"),
            PULLUP(3, 6, 90, "Weighted if needed"),
            DB_LATERAL_RAISE(3, 12, 30, "Light volume"),
            FACE_PULL(3, 15, 20, "Prehab"),
        ]),
        workout("Lower: Strength Maintain", "strength", 50, [
            BARBELL_SQUAT(4, 6, 150, "Maintain squat strength"),
            DEADLIFT(3, 5, 180, "Heavy pull, maintain"),
            LEG_PRESS(3, 10, 90, "Volume work"),
            LEG_CURL(3, 12, 45, "Hamstring work"),
            CALF_RAISE(4, 15, 30, "Calf maintenance"),
        ]),
        workout("Cardio & Conditioning", "cardio", 35, [
            BATTLE_ROPES(3, 1, 30, "30s waves"),
            BURPEE(3, 10, 30, "Full range"),
            JUMP_ROPE(4, 1, 30, "60s moderate pace"),
            PLANK(3, 1, 20, "45 seconds"),
        ]),
    ]


# 7. Full Body Fat Torch
def _full_body_fat_torch():
    return [
        workout("Fat Torch Circuit A", "hiit", 45, [
            BARBELL_SQUAT(3, 10, 45, "Short rest, circuit style"),
            BARBELL_BENCH(3, 10, 45, "Short rest"),
            BARBELL_ROW(3, 10, 45, "Short rest"),
            JUMP_SQUAT(3, 12, 30, "Explosive"),
            BURPEE(3, 10, 20, "Full range"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
        workout("Fat Torch Circuit B", "hiit", 45, [
            DEADLIFT(3, 8, 60, "Short rest"),
            BARBELL_OHP(3, 10, 45, "Short rest"),
            PULLUP(3, 8, 45, "Short rest"),
            JUMPING_LUNGE(3, 12, 30, "Per leg"),
            BATTLE_ROPES(3, 1, 20, "30s alternating"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
        ]),
        workout("Fat Torch Cardio Blast", "cardio", 35, [
            JUMP_ROPE(5, 1, 20, "60s on 20s off"),
            BOX_JUMP(3, 10, 45, "Explosive"),
            BURPEE(4, 10, 20, "Max effort"),
            BATTLE_ROPES(4, 1, 20, "30 seconds"),
        ]),
    ]


# 8. Belly Fat Blaster
def _belly_fat_blaster():
    return [
        workout("Core & Cardio Blast", "hiit", 40, [
            PLANK(4, 1, 20, "60 second holds"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast pace"),
            BICYCLE_CRUNCH(3, 25, 20, "Controlled"),
            HANGING_LEG_RAISE(3, 12, 45, "Full ROM"),
            RUSSIAN_TWIST(3, 25, 20, "Optional weight"),
            BURPEE(3, 12, 30, "Full range"),
            HIGH_KNEES(3, 30, 15, "Max pace"),
        ]),
        workout("Full Body Metabolic", "hiit", 45, [
            BARBELL_SQUAT(4, 10, 60, "Moderate weight"),
            BARBELL_ROW(4, 10, 60, "Back compound"),
            BARBELL_BENCH(3, 10, 60, "Chest"),
            KETTLEBELL_SWING(3, 20, 45, "Hip power"),
            JUMP_SQUAT(3, 12, 30, "Explosive"),
            DEAD_BUG(3, 10, 20, "Per side, core stability"),
        ]),
    ]


# 9. Love Handle Eliminator
def _love_handle_eliminator():
    return [
        workout("Oblique & Core Focus", "hiit", 40, [
            SIDE_PLANK(3, 1, 20, "45 seconds per side"),
            BICYCLE_CRUNCH(4, 25, 20, "Full twist"),
            RUSSIAN_TWIST(4, 25, 20, "Weight optional"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast pace"),
            ex("Woodchop", 3, 12, 30, "Cable or dumbbell, per side",
               "Cable Machine", "Core", "Obliques",
               ["Transverse Abdominis", "Shoulders"], "beginner",
               "Rotate from high to low, brace core", "Russian Twist"),
            PLANK(3, 1, 20, "45 seconds"),
            BURPEE(3, 10, 30, "Full range"),
        ]),
        workout("Full Body Burn", "hiit", 45, [
            BARBELL_SQUAT(3, 12, 60, "Moderate"),
            DEADLIFT(3, 8, 90, "Moderate weight"),
            BATTLE_ROPES(3, 1, 30, "30 seconds alternating"),
            JUMPING_LUNGE(3, 12, 30, "Per leg"),
            HIGH_KNEES(3, 30, 15, "Max pace"),
        ]),
    ]


# 10. Morning Fat Burn
def _morning_fat_burn():
    return [
        workout("AM Bodyweight Burn", "hiit", 30, [
            JUMPING_JACK(2, 30, 15, "Warm-up"),
            BODYWEIGHT_SQUAT(3, 20, 20, "Full depth"),
            PUSHUP(3, 15, 20, "Full ROM"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast pace"),
            JUMP_SQUAT(3, 12, 20, "Explosive"),
            BURPEE(3, 10, 20, "Full range"),
            PLANK(2, 1, 15, "30 seconds"),
        ]),
        workout("AM Weights & Cardio", "hiit", 40, [
            GOBLET_SQUAT(3, 15, 45, "Moderate dumbbell"),
            DB_BENCH(3, 12, 45, "Moderate"),
            DB_ROW(3, 12, 45, "Moderate"),
            KETTLEBELL_SWING(3, 20, 45, "Hip snap"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
            PLANK(3, 1, 15, "30 seconds"),
        ]),
    ]


# 11. Skinny Fat Fix
def _skinny_fat_fix():
    return [
        workout("Full Body Strength A", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Build muscle, moderate weight"),
            BARBELL_BENCH(3, 8, 120, "Build chest"),
            BARBELL_ROW(3, 8, 90, "Build back"),
            DB_CURL(2, 12, 45, "Arms"),
            TRICEP_PUSHDOWN(2, 12, 45, "Arms"),
            PLANK(3, 1, 30, "Core stability"),
        ]),
        workout("Full Body Strength B", "strength", 50, [
            DEADLIFT(3, 6, 150, "Build posterior chain"),
            BARBELL_OHP(3, 8, 90, "Build shoulders"),
            PULLUP(3, 8, 90, "Build lat width"),
            GOBLET_SQUAT(2, 12, 60, "Squat pattern volume"),
            FACE_PULL(3, 15, 20, "Shoulder health"),
            HANGING_LEG_RAISE(3, 12, 45, "Core"),
        ]),
        workout("Cardio: Strategic Fat Loss", "cardio", 35, [
            cardio_ex("Moderate Pace Cardio", 1200, "20 min, zone 2 heart rate, NOT exhausting", "Bodyweight", "beginner"),
            PLANK(2, 1, 20, "30 seconds"),
        ]),
    ]


# 12. Skinny Fat Intermediate
def _skinny_fat_intermediate():
    return [
        workout("Upper Push & Pull", "hypertrophy", 55, [
            BARBELL_BENCH(4, 8, 120, "Progressive overload"),
            BARBELL_ROW(4, 8, 90, "Match bench volume"),
            DB_INCLINE_PRESS(3, 10, 60, "Upper chest"),
            LAT_PULLDOWN(3, 10, 60, "Lat width"),
            DB_LATERAL_RAISE(3, 12, 30, "Shoulder width"),
            FACE_PULL(3, 15, 20, "Rear delt"),
            DB_CURL(3, 12, 45, "Bicep volume"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tricep volume"),
        ]),
        workout("Lower Body Hypertrophy", "hypertrophy", 55, [
            BARBELL_SQUAT(4, 8, 150, "Quad focus"),
            RDL(3, 10, 120, "Hamstring stretch"),
            LEG_PRESS(3, 12, 90, "High rep quad burn"),
            LEG_CURL(3, 12, 60, "Hamstring isolation"),
            HIP_THRUST(3, 12, 90, "Glute focus"),
            CALF_RAISE(4, 15, 30, "Full ROM"),
        ]),
        workout("HIIT Cardio Session", "cardio", 30, [
            JUMP_ROPE(5, 1, 20, "60s on 20s off"),
            BURPEE(3, 10, 30, "Max effort"),
            BATTLE_ROPES(3, 1, 20, "30 seconds"),
        ]),
    ]


# 13. Skinny Fat Advanced
def _skinny_fat_advanced():
    return [
        workout("Push Day", "hypertrophy", 60, [
            BARBELL_BENCH(4, 6, 120, "Heavy compound"),
            DB_INCLINE_PRESS(4, 10, 60, "Upper chest volume"),
            BARBELL_OHP(3, 8, 90, "Shoulder press"),
            CABLE_FLY(3, 12, 45, "Chest isolation"),
            DB_LATERAL_RAISE(4, 15, 20, "Medial delt"),
            TRICEP_PUSHDOWN(3, 12, 45, "Long head"),
            TRICEP_OVERHEAD(3, 12, 45, "Stretch"),
        ]),
        workout("Pull Day", "hypertrophy", 60, [
            DEADLIFT(3, 5, 180, "Heavy hinge"),
            PULLUP(4, 8, 90, "Weighted"),
            BARBELL_ROW(4, 8, 90, "Thickness"),
            LAT_PULLDOWN(3, 10, 60, "Width"),
            CABLE_ROW(3, 12, 60, "Close grip"),
            FACE_PULL(3, 15, 20, "Prehab"),
            DB_CURL(3, 12, 45, "Bicep peak"),
            HAMMER_CURL(3, 12, 45, "Brachialis"),
        ]),
        workout("Legs & Recomp Cardio", "hypertrophy", 65, [
            BARBELL_SQUAT(4, 8, 150, "Heavy"),
            RDL(3, 10, 120, "Hamstrings"),
            LEG_PRESS(3, 12, 90, "Volume"),
            HIP_THRUST(3, 12, 90, "Glutes"),
            LEG_CURL(3, 12, 60, "Isolation"),
            CALF_RAISE(4, 15, 30, "Full ROM"),
            JUMP_ROPE(3, 1, 30, "Cardio finisher, 60s"),
        ]),
    ]


# 14. Model Physique
def _model_physique():
    return [
        workout("Chest & Shoulders", "hypertrophy", 55, [
            DB_INCLINE_PRESS(4, 10, 60, "Upper chest emphasis"),
            BARBELL_BENCH(3, 8, 120, "Full chest"),
            CABLE_FLY(3, 12, 45, "Low to high, upper chest"),
            DB_OHP(4, 10, 60, "Shoulder press"),
            DB_LATERAL_RAISE(4, 15, 20, "Medial delt, strict"),
            FACE_PULL(3, 15, 20, "Rear delt balance"),
        ]),
        workout("Back & Arms", "hypertrophy", 55, [
            PULLUP(4, 10, 90, "Wide grip, V-taper"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip, lat width"),
            CABLE_ROW(3, 12, 60, "Close grip, thickness"),
            BARBELL_CURL(3, 10, 60, "Bicep peak"),
            DB_CURL(3, 12, 45, "Incline, full stretch"),
            TRICEP_PUSHDOWN(3, 12, 45, "Rope, definition"),
            TRICEP_OVERHEAD(3, 12, 45, "Long head"),
        ]),
        workout("Legs: Aesthetic Focus", "hypertrophy", 55, [
            BARBELL_SQUAT(4, 8, 150, "Sweep focus"),
            LEG_PRESS(3, 12, 90, "High and wide"),
            LEG_EXT(4, 15, 45, "Quad isolation"),
            RDL(3, 10, 120, "Hamstring sweep"),
            HIP_THRUST(3, 12, 90, "Glute roundness"),
            CALF_RAISE(5, 15, 30, "Calf size"),
        ]),
    ]


# 15. Photoshoot Ready
def _photoshoot_ready():
    return [
        workout("Peak Week Upper", "hypertrophy", 55, [
            DB_INCLINE_PRESS(4, 12, 45, "Light, pump focused"),
            CABLE_FLY(4, 15, 30, "Squeeze and hold"),
            PULLUP(3, 10, 60, "V-taper"),
            CABLE_ROW(3, 12, 45, "Back detail"),
            DB_LATERAL_RAISE(4, 15, 20, "Shoulder caps"),
            DB_CURL(3, 15, 30, "Bicep pump"),
            TRICEP_PUSHDOWN(3, 15, 30, "Tricep detail"),
        ]),
        workout("Peak Week Lower", "hypertrophy", 50, [
            LEG_PRESS(4, 15, 60, "Pump, not heavy"),
            LEG_EXT(4, 20, 30, "Quad striations"),
            LEG_CURL(3, 15, 30, "Hamstring detail"),
            HIP_THRUST(4, 15, 45, "Glute pump"),
            CALF_RAISE(5, 20, 20, "Calf pump"),
            PLANK(3, 1, 20, "Core bracing"),
        ]),
        workout("Posing & Light Cardio", "cardio", 30, [
            cardio_ex("Posing Practice", 600, "10 minutes posing practice", "Bodyweight", "beginner"),
            cardio_ex("Light Treadmill Walk", 900, "15 minutes, light sweat", "Bodyweight", "beginner"),
            PLANK(2, 1, 15, "30 seconds"),
        ]),
    ]


# 16. Bikini Competition Prep
def _bikini_competition_prep():
    return [
        workout("Glute & Hamstring Focus", "hypertrophy", 60, [
            HIP_THRUST(5, 12, 90, "Barbell, progressive overload"),
            SUMO_DEADLIFT(4, 10, 90, "Glute dominant pull"),
            RDL(3, 12, 90, "Hamstring stretch"),
            CABLE_KICKBACK(4, 15, 30, "Per leg, squeeze glute"),
            LEG_CURL(3, 15, 45, "Hamstring isolation"),
            DONKEY_KICK(3, 15, 20, "Bodyweight finisher"),
            CLAMSHELL(3, 15, 20, "Glute med activation"),
        ]),
        workout("Upper Body Tone", "hypertrophy", 50, [
            DB_BENCH(3, 12, 45, "Light weight, full ROM"),
            CABLE_ROW(3, 12, 45, "Back definition"),
            DB_LATERAL_RAISE(4, 15, 20, "Shoulder caps"),
            FACE_PULL(3, 15, 20, "Rear delt"),
            DB_CURL(3, 15, 30, "Light, toning"),
            TRICEP_PUSHDOWN(3, 15, 30, "Definition"),
            PLANK(3, 1, 20, "45 seconds"),
        ]),
        workout("Competition Cardio & Posing", "cardio", 45, [
            cardio_ex("Stairmaster", 1200, "20 min moderate, glute focused", "Machine", "intermediate"),
            cardio_ex("Posing Practice", 600, "10 min: front, back, side poses", "Bodyweight", "beginner"),
            GLUTE_BRIDGE(3, 20, 20, "Activation"),
            BICYCLE_CRUNCH(3, 25, 20, "Abs"),
        ]),
    ]


# 17. Bikini Body Countdown
def _bikini_body_countdown():
    return [
        workout("Lower Body Sculpt", "hypertrophy", 55, [
            BARBELL_SQUAT(4, 10, 90, "Full depth, glute focused"),
            HIP_THRUST(4, 12, 90, "Glute builder"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Per leg, unilateral"),
            LEG_CURL(3, 15, 45, "Hamstring curl"),
            LATERAL_BAND_WALK(3, 15, 20, "Glute med"),
            CALF_RAISE(4, 20, 20, "High rep"),
        ]),
        workout("Upper Body Sculpt", "hypertrophy", 50, [
            BARBELL_BENCH(3, 10, 60, "Moderate"),
            LAT_PULLDOWN(3, 10, 60, "Wide grip"),
            DB_OHP(3, 12, 45, "Shoulder tone"),
            DB_LATERAL_RAISE(4, 15, 20, "Shoulder caps"),
            DB_CURL(3, 15, 30, "Bicep tone"),
            TRICEP_PUSHDOWN(3, 15, 30, "Tricep tone"),
            PLANK(3, 1, 20, "Core"),
        ]),
        workout("Cardio Countdown", "cardio", 40, [
            JUMP_ROPE(5, 1, 20, "60s on 20s off"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast"),
            JUMP_SQUAT(3, 15, 20, "Plyometric"),
            BURPEE(3, 10, 20, "Full range"),
            cardio_ex("Cool-Down Walk", 600, "10 minute light walk", "Bodyweight", "beginner"),
        ]),
    ]


# 18. Physique Competition Prep
def _physique_competition_prep():
    return [
        workout("Chest & Triceps", "hypertrophy", 65, [
            BARBELL_BENCH(4, 8, 120, "Main builder"),
            DB_INCLINE_PRESS(4, 10, 60, "Upper chest fullness"),
            CABLE_FLY(4, 12, 45, "Detail work"),
            PEC_DECK(3, 15, 30, "Squeeze and hold"),
            DIP(3, 12, 60, "Lower chest detail"),
            TRICEP_PUSHDOWN(4, 12, 45, "Horseshoe"),
            SKULL_CRUSHER(3, 12, 60, "Overhead stretch"),
            TRICEP_OVERHEAD(3, 15, 30, "Long head"),
        ]),
        workout("Back & Biceps", "hypertrophy", 65, [
            DEADLIFT(3, 5, 180, "Thickness"),
            PULLUP(4, 10, 90, "Width"),
            BARBELL_ROW(4, 8, 120, "Middle back"),
            CABLE_ROW(3, 12, 60, "Close grip detail"),
            LAT_PULLDOWN(3, 12, 60, "Lat sweep"),
            BARBELL_CURL(3, 10, 60, "Peak"),
            CONCENTRATION_CURL(3, 12, 30, "Peak contraction"),
            HAMMER_CURL(3, 12, 45, "Brachialis"),
        ]),
        workout("Legs: Stage Worthy", "hypertrophy", 70, [
            BARBELL_SQUAT(4, 8, 180, "Quad sweep"),
            FRONT_SQUAT(3, 8, 120, "VMO focus"),
            LEG_PRESS(4, 12, 90, "Quad volume"),
            LEG_EXT(4, 15, 45, "Quad isolation and striations"),
            RDL(3, 10, 120, "Hamstring tie-in"),
            LEG_CURL(4, 12, 60, "Hamstring curl"),
            HIP_THRUST(3, 15, 90, "Glute roundness"),
            CALF_RAISE(5, 15, 30, "Diamond calves"),
        ]),
    ]


# 19. Bodybuilding Show Prep
def _bodybuilding_show_prep():
    return [
        workout("Show Prep: Chest & Shoulders", "hypertrophy", 70, [
            BARBELL_BENCH(4, 8, 120, "4-2-1 tempo, feel the squeeze"),
            DB_INCLINE_PRESS(4, 10, 60, "Upper chest peak"),
            CABLE_FLY(4, 15, 30, "Constant tension"),
            PEC_DECK(3, 15, 30, "Peak contraction hold"),
            BARBELL_OHP(4, 10, 120, "Shoulder mass"),
            DB_LATERAL_RAISE(5, 15, 20, "Medial delt width"),
            REVERSE_PEC_DECK(4, 15, 20, "Rear delt balance"),
        ]),
        workout("Show Prep: Back & Arms", "hypertrophy", 70, [
            DEADLIFT(3, 6, 180, "Back thickness"),
            PULLUP(4, 10, 90, "Weighted, V-taper"),
            BARBELL_ROW(4, 8, 90, "Middle back detail"),
            LAT_PULLDOWN(3, 12, 60, "Width"),
            BARBELL_CURL(4, 10, 60, "Bicep peak"),
            DB_CURL(3, 12, 45, "Full stretch"),
            CLOSE_GRIP_BENCH(4, 10, 90, "Tricep mass"),
            SKULL_CRUSHER(3, 12, 60, "Long head"),
        ]),
        workout("Show Prep: Legs", "hypertrophy", 75, [
            BARBELL_SQUAT(5, 8, 180, "Quad mass"),
            HACK_SQUAT(4, 10, 90, "Lower quad sweep"),
            LEG_PRESS(4, 15, 90, "Foot placement variety"),
            LEG_EXT(5, 15, 45, "Quad striations"),
            RDL(4, 10, 120, "Hamstring tie-in"),
            LEG_CURL(5, 12, 60, "Bicep femoris"),
            HIP_THRUST(4, 12, 120, "Glute roundness"),
            CALF_RAISE(6, 15, 30, "Diamond calves"),
        ]),
    ]


# 20. Superhero Physique
def _superhero_physique():
    return [
        workout("Superhero Upper: Mass Day", "hypertrophy", 65, [
            BARBELL_BENCH(4, 6, 150, "Heavy compound"),
            BARBELL_OHP(4, 6, 120, "Shoulder boulders"),
            PULLUP(4, 8, 90, "V-taper building"),
            DB_INCLINE_PRESS(3, 10, 60, "Upper chest fullness"),
            DB_LATERAL_RAISE(4, 15, 20, "Shoulder width"),
            BARBELL_CURL(3, 10, 60, "Bicep peak"),
            CLOSE_GRIP_BENCH(3, 10, 90, "Tricep horseshoe"),
        ]),
        workout("Superhero Lower: Power Day", "strength", 65, [
            BARBELL_SQUAT(4, 6, 180, "Heavy legs"),
            DEADLIFT(3, 5, 220, "Maximum posterior chain"),
            LEG_PRESS(3, 10, 120, "Quad volume"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Unilateral"),
            CALF_RAISE(5, 15, 30, "Massive calves"),
        ]),
        workout("Superhero Conditioning", "hiit", 40, [
            SLED_PUSH(3, 1, 90, "40 yards, heavy"),
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
            BOX_JUMP(3, 8, 60, "Explosive"),
            BURPEE(3, 10, 30, "Full range"),
            FARMER_WALK(3, 1, 60, "Heavy, 40 yards"),
        ]),
    ]


# 21. Action Hero Build
def _action_hero_build():
    return [
        workout("Action Hero Upper A", "hypertrophy", 60, [
            BARBELL_BENCH(4, 8, 120, "Chest armor"),
            PULLUP(4, 10, 90, "Back width"),
            BARBELL_OHP(3, 8, 90, "Shoulder caps"),
            DB_LATERAL_RAISE(3, 15, 20, "Medial delt"),
            BARBELL_CURL(3, 10, 60, "Bicep peak"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tricep definition"),
        ]),
        workout("Action Hero Lower A", "strength", 60, [
            BARBELL_SQUAT(4, 6, 180, "Quad mass"),
            DEADLIFT(3, 5, 200, "Full posterior chain"),
            BULGARIAN_SPLIT_SQUAT(3, 10, 60, "Unilateral balance"),
            LEG_CURL(3, 12, 60, "Hamstring"),
            CALF_RAISE(4, 15, 30, "Calf mass"),
        ]),
        workout("Action Hero Conditioning", "hiit", 40, [
            BOX_JUMP(4, 8, 60, "Explosive lower"),
            BATTLE_ROPES(3, 1, 30, "Upper conditioning"),
            BURPEE(3, 12, 30, "Full body"),
            SLED_PUSH(3, 1, 90, "Power"),
            PLANK(3, 1, 20, "60 seconds core"),
        ]),
    ]


# 22. Leading Man Build
def _leading_man_build():
    return [
        workout("Leading Man Upper", "hypertrophy", 60, [
            DB_INCLINE_PRESS(4, 10, 60, "Upper chest, camera-friendly"),
            BARBELL_BENCH(3, 8, 120, "Full chest"),
            PULLUP(4, 10, 90, "V-taper width"),
            DB_OHP(3, 10, 60, "Shoulder definition"),
            DB_LATERAL_RAISE(4, 15, 20, "Shoulder caps"),
            DB_CURL(3, 12, 45, "Defined biceps"),
            TRICEP_OVERHEAD(3, 12, 45, "Defined triceps"),
        ]),
        workout("Leading Man Lower", "hypertrophy", 55, [
            BARBELL_SQUAT(4, 8, 150, "Athletic legs"),
            RDL(3, 10, 120, "Hamstring shape"),
            LEG_PRESS(3, 12, 90, "Quad volume"),
            HIP_THRUST(3, 12, 90, "Glute definition"),
            CALF_RAISE(4, 20, 20, "Defined calves"),
        ]),
        workout("On-Set Conditioning", "cardio", 35, [
            cardio_ex("Treadmill Intervals", 1200, "20 min: 2 min walk, 1 min run alternating", "Machine", "intermediate"),
            PLANK(3, 1, 20, "Core bracing"),
            BICYCLE_CRUNCH(3, 20, 20, "Ab definition"),
        ]),
    ]


# 23. Action Star Conditioning
def _action_star_conditioning():
    return [
        workout("Functional Strength A", "strength", 60, [
            POWER_CLEAN(5, 3, 120, "Explosive power"),
            BARBELL_SQUAT(4, 6, 150, "Lower body power"),
            BARBELL_BENCH(4, 6, 120, "Pushing strength"),
            PULLUP(4, 8, 90, "Pulling strength"),
            FARMER_WALK(3, 1, 60, "Loaded carry 40 yards"),
        ]),
        workout("Stunt Conditioning", "hiit", 50, [
            BURPEE(4, 12, 30, "Full range"),
            BOX_JUMP(4, 8, 60, "Explosive"),
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
            SLED_PUSH(3, 1, 90, "40 yards"),
            JUMP_ROPE(3, 1, 30, "60 seconds"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
        workout("Mobility & Recovery", "mobility", 35, [
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            PIRIFOMIS_STRETCH(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_BACK(),
        ]),
    ]


# 24. Fighter's Body
def _fighters_body():
    return [
        workout("Fighter Strength", "strength", 60, [
            BARBELL_BENCH(4, 6, 150, "Functional pressing power"),
            BARBELL_ROW(4, 6, 120, "Pulling power"),
            BARBELL_SQUAT(4, 6, 180, "Leg drive"),
            DEADLIFT(3, 5, 200, "Total body strength"),
            PLANK(3, 1, 30, "Core stability"),
        ]),
        workout("Fighter Conditioning", "hiit", 50, [
            ex("Shadow Boxing", 5, 1, 30, "3 minutes per round",
               "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Legs", "Cardiovascular"], "intermediate",
               "Stay light on feet, full punching combos, active rest 30s", "Jump Rope",
               duration_seconds=180),
            BURPEE(3, 10, 30, "Full range"),
            JUMP_ROPE(3, 1, 30, "60 seconds"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Fast pace"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
        ]),
        workout("Fighter Mobility & Core", "mobility", 35, [
            HIP_90_90(),
            WORLD_GREATEST_STRETCH(),
            PLANK(3, 1, 20, "60 seconds"),
            SIDE_PLANK(3, 1, 20, "45 seconds per side"),
            DEAD_BUG(3, 10, 20, "Per side"),
            RUSSIAN_TWIST(3, 20, 20, "With weight"),
            BICYCLE_CRUNCH(3, 20, 20, "Controlled"),
        ]),
    ]


# 25. Screen Ready
def _screen_ready():
    return [
        workout("Camera Day Upper", "hypertrophy", 55, [
            DB_INCLINE_PRESS(4, 12, 45, "Pump for upper chest pop"),
            CABLE_FLY(4, 15, 30, "Constant tension, squeeze"),
            PULLUP(3, 10, 60, "V-taper"),
            CABLE_ROW(3, 12, 45, "Back detail"),
            DB_LATERAL_RAISE(5, 15, 20, "Shoulder caps"),
            DB_CURL(3, 15, 30, "Bicep pump"),
            TRICEP_PUSHDOWN(3, 15, 30, "Horseshoe pump"),
        ]),
        workout("Camera Day Lower", "hypertrophy", 50, [
            LEG_PRESS(4, 15, 60, "Quad pump"),
            LEG_EXT(4, 20, 30, "Striations"),
            HIP_THRUST(4, 15, 60, "Glute roundness"),
            LEG_CURL(3, 15, 30, "Hamstring detail"),
            CALF_RAISE(6, 20, 20, "Diamond calves pump"),
            PLANK(3, 1, 20, "Core"),
        ]),
        workout("Light Cardio + Posing", "cardio", 30, [
            cardio_ex("Treadmill Walk", 900, "15 minutes light walk to stay lean", "Machine", "beginner"),
            cardio_ex("Posing Practice", 600, "10 minutes posing for camera", "Bodyweight", "beginner"),
            PLANK(2, 1, 15, "30 seconds bracing"),
        ]),
    ]


###############################################################################
# COMPETITION / RACE PREP
###############################################################################

# 26. CrossFit Open Prep
def _crossfit_open_prep():
    return [
        workout("Open Prep: Strength Skill Day", "strength", 55, [
            BARBELL_SQUAT(4, 5, 180, "Heavy, Open standards"),
            BARBELL_OHP(4, 5, 120, "Strict then push press"),
            DEADLIFT(3, 5, 200, "Heavy pulls"),
            ex("Toes-to-Bar", 3, 10, 60, "Strict toes to bar",
               "Bodyweight", "Core", "Hip Flexors",
               ["Lower Abs", "Lats"], "intermediate",
               "Dead hang, kip or strict, touch bar with toes", "Hanging Leg Raise"),
            PULLUP(3, 10, 60, "Kipping or strict"),
        ]),
        workout("Open Prep: WOD Simulation A", "hiit", 40, [
            ex("Thrusters", 3, 21, 90, "Barbell, squat to overhead",
               "Barbell", "Full Body", "Full Body",
               ["Legs", "Shoulders", "Core"], "advanced",
               "Front squat to push press in one motion, full hip extension", "Goblet Squat to Press"),
            PULLUP(3, 21, 90, "Kipping pull-ups, Fran style"),
            BURPEE(3, 15, 60, "Jumping bar burpee"),
            BARBELL_SQUAT(2, 10, 60, "Moderate weight"),
        ]),
        workout("Open Prep: Engine Builder", "cardio", 45, [
            ROWING(3, 1, 60, "5 minutes moderate pace"),
            ex("Double Unders", 3, 50, 60, "Jump rope double unders, or 3x singles",
               "Jump Rope", "Full Body", "Calves",
               ["Cardiovascular", "Coordination"], "intermediate",
               "Quick wrists, slight jump, timed bounce", "Jump Rope Singles"),
            BURPEE(3, 15, 45, "Consistent pace"),
            ex("Box Step-Overs", 3, 10, 45, "Step or jump over box, per direction",
               "Bodyweight", "Full Body", "Legs",
               ["Cardiovascular", "Coordination"], "intermediate",
               "Controlled landing, alternate direction", "Step-Up"),
        ]),
    ]


# 27. CrossFit Style Training
def _crossfit_style_training():
    return [
        workout("WOD: Strength Primer", "strength", 50, [
            POWER_CLEAN(5, 3, 120, "Work to heavy set of 3"),
            ex("Push Jerk", 4, 5, 90, "Work up to moderate weight",
               "Barbell", "Full Body", "Shoulders",
               ["Legs", "Triceps", "Core"], "advanced",
               "Dip drive, drop under bar, lockout overhead", "Push Press"),
            BARBELL_SQUAT(3, 5, 180, "Heavy back squat"),
        ]),
        workout("WOD: Metcon A - AMRAP", "hiit", 40, [
            BURPEE(1, 10, 0, "Every minute: 10 burpees"),
            ex("Kettlebell Snatch", 3, 10, 60, "Per arm, moderate weight",
               "Kettlebell", "Full Body", "Shoulders",
               ["Glutes", "Hamstrings", "Core"], "advanced",
               "Hip snap, punch through at top, lock out", "Dumbbell Snatch"),
            JUMPING_LUNGE(3, 12, 45, "Box jump alternative"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds"),
        ]),
        workout("WOD: Chipper Style", "hiit", 45, [
            DEADLIFT(1, 21, 0, "Moderate weight, unbroken"),
            PULLUP(1, 21, 0, "Kipping or jumping"),
            BARBELL_OHP(1, 21, 0, "Push press style"),
            BOX_JUMP(1, 21, 0, "24 inch box"),
            BATTLE_ROPES(1, 30, 0, "30 seconds max effort"),
            BURPEE(1, 21, 0, "Full range"),
        ]),
    ]


# 28. Spartan Race Prep
def _spartan_race_prep():
    return [
        workout("Spartan Strength & Carry", "strength", 60, [
            BARBELL_SQUAT(4, 8, 150, "Race day leg power"),
            DEADLIFT(3, 6, 180, "Object carries"),
            FARMER_WALK(4, 1, 60, "Heavy, 40+ yards"),
            BARBELL_OHP(3, 8, 120, "Obstacle overhead strength"),
            PULLUP(4, 10, 90, "Rope climb substitute"),
        ]),
        workout("Spartan Obstacle Sim", "hiit", 55, [
            BURPEE(5, 30, 60, "Spartan penalty burpees, unbroken"),
            PULLUP(4, 10, 60, "Rope climb simulation"),
            ex("Sandbag Carry", 4, 1, 90, "40-50 yards, heavy sandbag or dumbbell",
               "Sandbag", "Full Body", "Full Body",
               ["Legs", "Core", "Grip"], "intermediate",
               "Tight core, controlled steps, heavy load", "Farmer's Walk"),
            BATTLE_ROPES(3, 1, 30, "Grip endurance"),
            BOX_JUMP(3, 10, 45, "Obstacle jump"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds"),
        ]),
        workout("Spartan Endurance Run", "cardio", 50, [
            cardio_ex("Trail Run or Treadmill Incline", 2400, "40 min, simulate terrain", "Bodyweight", "intermediate"),
            BURPEE(2, 10, 30, "Race pace burpees"),
        ]),
    ]


# 29. GoRuck Challenge Prep
def _goruck_challenge_prep():
    return [
        workout("Ruck Strength Prep", "strength", 60, [
            BARBELL_SQUAT(4, 6, 180, "Leg strength for rucking"),
            DEADLIFT(3, 5, 200, "Heavy posterior chain"),
            FARMER_WALK(4, 1, 60, "Heavy loaded carry"),
            BARBELL_OHP(3, 8, 120, "Log press simulation"),
            PULLUP(3, 10, 90, "Upper body pulling"),
            PLANK(3, 1, 30, "60 seconds, core endurance"),
        ]),
        workout("Ruck Conditioning", "cardio", 60, [
            cardio_ex("Weighted Ruck Walk", 2400, "40+ min with 20-30lb pack", "Bodyweight", "intermediate"),
            ex("Overhead Plate Walk", 3, 1, 60, "45-lb plate overhead, 40 yards",
               "Barbell", "Full Body", "Shoulders",
               ["Core", "Grip"], "intermediate",
               "Straight arms, tight core, controlled walk", "Farmer's Walk"),
            BURPEE(2, 10, 30, "GoRuck penalty"),
        ]),
        workout("Team Event Simulation", "hiit", 50, [
            ex("Buddy Carry Simulation", 4, 1, 90, "50% of bodyweight carry, 40 yards",
               "Sandbag", "Full Body", "Full Body",
               ["Legs", "Back", "Core"], "advanced",
               "Bear hug or over shoulder, maintain pace", "Farmer's Walk"),
            SLED_PUSH(3, 1, 90, "Team sled simulation"),
            BURPEE(4, 10, 30, "Penalty sets"),
            PLANK(3, 1, 20, "60 seconds"),
        ]),
    ]


# 30. Deka Fit Training
def _deka_fit_training():
    return [
        workout("Deka Stations Strength", "strength", 55, [
            ROWING(1, 1, 60, "5 min, Zone 2 row"),
            ex("Ski Erg", 3, 1, 60, "2 minutes each",
               "Machine", "Full Body", "Back",
               ["Shoulders", "Core", "Cardiovascular"], "intermediate",
               "Hip hinge with arm pull, explosive drive", "Rowing Machine"),
            SLED_PUSH(4, 1, 60, "40 yards, moderate weight"),
            BURPEE(3, 10, 30, "Full range"),
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
        ]),
        workout("Deka Conditioning Circuit", "hiit", 50, [
            cardio_ex("Air Bike Intervals", 120, "2 min max effort", "Machine", "intermediate"),
            JUMP_ROPE(3, 1, 30, "60 seconds"),
            BOX_JUMP(3, 10, 45, "Plyometric"),
            KETTLEBELL_SWING(3, 15, 45, "Hip power"),
            FARMER_WALK(3, 1, 60, "40 yards"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
    ]


# 31. Warrior Dash Prep
def _warrior_dash_prep():
    return [
        workout("Warrior Strength", "strength", 50, [
            BARBELL_SQUAT(3, 8, 150, "Race leg power"),
            PULLUP(3, 10, 90, "Obstacle climbing"),
            BARBELL_OHP(3, 8, 90, "Overhead obstacles"),
            FARMER_WALK(3, 1, 60, "Carry obstacles"),
            BURPEE(3, 10, 30, "Race pace"),
            PLANK(3, 1, 20, "Core"),
        ]),
        workout("Warrior Run & Obstacles", "cardio", 50, [
            cardio_ex("Run with Obstacle Sim", 1800, "30 min run with obstacle breaks", "Bodyweight", "intermediate"),
            BOX_JUMP(3, 8, 45, "Wall obstacles"),
            BURPEE(3, 10, 30, "Penalty"),
            BATTLE_ROPES(2, 1, 30, "Upper endurance"),
        ]),
    ]


# 32. Ragnar Relay Prep
def _ragnar_relay_prep():
    return [
        workout("Ragnar Run Prep", "cardio", 55, [
            cardio_ex("Long Run", 2400, "40 min continuous, moderate pace", "Bodyweight", "intermediate"),
            cardio_ex("Speed Intervals", 900, "15 min: 1 min fast, 2 min walk x5", "Bodyweight", "intermediate"),
        ]),
        workout("Strength for Runners", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Leg strength to prevent injury"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, stability"),
            CALF_RAISE(4, 20, 20, "Calf endurance"),
            STEP_UP(3, 12, 45, "Per leg"),
            PLANK(3, 1, 20, "Core"),
            BIRD_DOG(3, 10, 20, "Stability"),
        ]),
        workout("Recovery Run", "cardio", 35, [
            cardio_ex("Easy Recovery Run", 1800, "30 min very easy pace", "Bodyweight", "beginner"),
            PLANK(2, 1, 15, "30 seconds"),
        ]),
    ]


# 33. Color Run Training
def _color_run_training():
    return [
        workout("Beginner 5K Training Run", "cardio", 35, [
            cardio_ex("Walk/Run Intervals", 1800, "30 min: 1 min jog, 2 min walk x10", "Bodyweight", "beginner"),
            CALF_RAISE(3, 15, 20, "Calf prep"),
        ]),
        workout("Strength for Fun Run", "strength", 40, [
            BODYWEIGHT_SQUAT(3, 15, 30, "Leg endurance"),
            STEP_UP(3, 10, 45, "Per leg"),
            PUSHUP(3, 12, 30, "Upper body"),
            PLANK(3, 1, 20, "45 seconds core"),
            CALF_RAISE(3, 15, 20, "Calves for running"),
            HIGH_KNEES(2, 30, 15, "Run simulation"),
        ]),
    ]


# 34. Tough Mudder Ready
def _tough_mudder_ready():
    return [
        workout("Mudder Strength & Grip", "strength", 60, [
            DEADLIFT(4, 5, 180, "Posterior chain for obstacles"),
            PULLUP(4, 10, 90, "Monkey bars, rope climbs"),
            BARBELL_SQUAT(3, 8, 150, "Leg power"),
            FARMER_WALK(4, 1, 60, "Grip endurance"),
            ex("Hanging Hold", 3, 1, 60, "30-60 second dead hang",
               "Bodyweight", "Back", "Grip",
               ["Lats", "Forearms"], "beginner",
               "Relax shoulders slightly, breathe, hold", "Farmer's Walk"),
            PLANK(3, 1, 20, "60 seconds"),
        ]),
        workout("Mudder Conditioning", "hiit", 55, [
            cardio_ex("Trail Run Simulation", 1800, "30 min incline treadmill or outdoor", "Bodyweight", "intermediate"),
            BURPEE(4, 10, 30, "Obstacle penalty"),
            BOX_JUMP(3, 10, 45, "Wall jumps"),
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
            SLED_PUSH(3, 1, 90, "Team push"),
        ]),
    ]


# 35. Obstacle Course Ready
def _obstacle_course_ready():
    return [
        workout("OCR Strength", "strength", 55, [
            BARBELL_SQUAT(4, 6, 150, "Explosive leg power"),
            DEADLIFT(3, 5, 180, "Object carry strength"),
            PULLUP(4, 10, 90, "Upper obstacle pulling"),
            FARMER_WALK(3, 1, 60, "Carry simulation"),
            BURPEE(3, 10, 30, "OCR staple"),
            PLANK(3, 1, 20, "Core endurance"),
        ]),
        workout("OCR Endurance", "cardio", 50, [
            cardio_ex("Run with Stops", 2400, "40 min run with 5 strength stops every 8 min", "Bodyweight", "intermediate"),
            PULLUP(2, 8, 60, "At stops"),
            BURPEE(2, 10, 30, "At stops"),
        ]),
    ]


# 36. Local 5K Race Prep
def _local_5k_race_prep():
    return [
        workout("5K Speed Work", "cardio", 40, [
            cardio_ex("Warm-Up Jog", 300, "5 min easy", "Bodyweight", "beginner"),
            cardio_ex("Tempo Intervals", 1200, "4x400m at race pace, 90s rest", "Bodyweight", "intermediate"),
            cardio_ex("Cool-Down Walk", 300, "5 min easy walk", "Bodyweight", "beginner"),
        ]),
        workout("5K Long Run", "cardio", 45, [
            cardio_ex("Easy 4-5 Mile Run", 2400, "40 min easy pace, conversational", "Bodyweight", "intermediate"),
        ]),
        workout("Runner Strength", "strength", 40, [
            BARBELL_SQUAT(3, 10, 90, "Lower body for running economy"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, stability and hamstrings"),
            CALF_RAISE(4, 20, 20, "Plantar flexor endurance"),
            PLANK(3, 1, 20, "Core for running form"),
            BIRD_DOG(3, 10, 20, "Lower back stability"),
        ]),
    ]


# 37. 5K to Half Marathon
def _5k_to_half_marathon():
    return [
        workout("Long Run", "cardio", 75, [
            cardio_ex("Long Slow Distance", 3600, "60+ min, easy conversational pace, build weekly", "Bodyweight", "intermediate"),
        ]),
        workout("Tempo Run", "cardio", 40, [
            cardio_ex("Warm-Up", 300, "5 min easy walk/jog", "Bodyweight", "beginner"),
            cardio_ex("Tempo Run", 1800, "30 min at comfortably hard pace", "Bodyweight", "intermediate"),
            cardio_ex("Cool-Down", 300, "5 min easy", "Bodyweight", "beginner"),
        ]),
        workout("Half Marathon Strength", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Running strength"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg"),
            STEP_UP(3, 12, 45, "Per leg"),
            CALF_RAISE(4, 20, 20, "Endurance calves"),
            PLANK(3, 1, 20, "Core"),
            DEAD_BUG(3, 10, 20, "Lumbar stability"),
        ]),
    ]


# 38. Triathlon Foundation
def _triathlon_foundation():
    return [
        workout("Swim + Bike Brick", "cardio", 75, [
            cardio_ex("Pool Swim", 1800, "30 min continuous swim, focus form", "Bodyweight", "intermediate"),
            cardio_ex("Stationary Bike", 1800, "30 min moderate pace immediately after swim", "Machine", "intermediate"),
        ]),
        workout("Run + Strength", "strength", 60, [
            cardio_ex("Run", 1200, "20 min moderate pace", "Bodyweight", "intermediate"),
            BARBELL_SQUAT(3, 8, 120, "Cycling and run power"),
            DEADLIFT(3, 6, 150, "Posterior chain"),
            PLANK(3, 1, 20, "Core stability"),
            BIRD_DOG(3, 10, 20, "Lower back"),
        ]),
        workout("Triathlon Conditioning", "hiit", 45, [
            ROWING(2, 1, 60, "5 minutes per set"),
            cardio_ex("Cycling Intervals", 1200, "20 min: 1 min hard, 2 min easy x7", "Machine", "intermediate"),
            cardio_ex("Transition Run", 600, "10 min easy run after cycling", "Bodyweight", "intermediate"),
        ]),
    ]


###############################################################################
# SPORTS SPECIFIC
###############################################################################

# 39. Basketball Performance
def _basketball_performance():
    return [
        workout("Vertical Jump & Explosiveness", "strength", 55, [
            BARBELL_SQUAT(4, 5, 180, "Heavy, strength base"),
            JUMP_SQUAT(4, 8, 60, "Explosive, max height"),
            BOX_JUMP(4, 8, 60, "Max box height"),
            SINGLE_LEG_RDL(3, 8, 60, "Per leg, landing mechanics"),
            CALF_RAISE(5, 15, 30, "Jump power"),
            PLANK(3, 1, 20, "Core stability"),
        ]),
        workout("Lateral Agility & Court Speed", "hiit", 50, [
            LATERAL_BAND_WALK(3, 20, 20, "Defensive stance, band above knees"),
            ex("Lateral Shuffle", 4, 1, 30, "30 seconds each direction",
               "Bodyweight", "Legs", "Adductors",
               ["Glutes", "Calves", "Quadriceps"], "intermediate",
               "Low athletic stance, quick shuffle, touch line", "Carioca"),
            HIGH_KNEES(3, 30, 15, "Sprint simulation"),
            JUMPING_LUNGE(3, 10, 30, "Explosive direction change"),
            BURPEE(3, 8, 30, "Full body conditioning"),
        ]),
        workout("Upper Body Court Strength", "strength", 50, [
            BARBELL_BENCH(3, 8, 120, "Pushing power"),
            BARBELL_ROW(3, 8, 90, "Pulling balance"),
            BARBELL_OHP(3, 8, 90, "Shooting and passing power"),
            PULLUP(3, 10, 90, "Upper back"),
            DB_LATERAL_RAISE(3, 12, 30, "Shoulder stability"),
        ]),
    ]


# 40. Soccer Conditioning
def _soccer_conditioning():
    return [
        workout("Soccer Speed & Endurance", "cardio", 55, [
            cardio_ex("Interval Runs", 1800, "30 min: 3 min tempo, 1 min sprint, 1 min walk x6", "Bodyweight", "intermediate"),
            ex("Direction Change Sprints", 4, 1, 60, "30 sec sprint with cuts",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Glutes", "Hamstrings", "Calves"], "intermediate",
               "Sharp cuts, quick acceleration, decelerate safely", "Lateral Shuffle"),
        ]),
        workout("Soccer Strength & Power", "strength", 50, [
            BARBELL_SQUAT(4, 6, 150, "Kicking power"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, hamstring"),
            STEP_UP(3, 10, 45, "Per leg, dynamic"),
            JUMP_SQUAT(3, 10, 45, "Explosive jumping"),
            CALF_RAISE(4, 20, 20, "Running speed"),
            PLANK(3, 1, 20, "Core for kicking"),
        ]),
        workout("Soccer Conditioning Circuit", "hiit", 45, [
            HIGH_KNEES(4, 30, 15, "Sprint simulation"),
            JUMPING_LUNGE(3, 12, 30, "Change of direction"),
            BURPEE(3, 10, 30, "Total conditioning"),
            BOX_JUMP(3, 8, 45, "Header jump training"),
            BATTLE_ROPES(2, 1, 30, "Upper body conditioning"),
        ]),
    ]


# 41. Tennis Agility
def _tennis_agility():
    return [
        workout("Tennis Court Agility", "hiit", 50, [
            ex("Side-to-Side Shuffle", 4, 1, 30, "30 sec, simulate baseline rally",
               "Bodyweight", "Legs", "Adductors",
               ["Glutes", "Calves", "Quadriceps"], "intermediate",
               "Split step, push off outside foot, stay low", "Lateral Band Walk"),
            ex("Forward-Back Sprint", 4, 1, 30, "30 sec, net to baseline",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Glutes", "Calves"], "intermediate",
               "Explosive first step, backpedal with control", "High Knees"),
            JUMP_SQUAT(3, 10, 30, "Explosive jump"),
            JUMPING_LUNGE(3, 10, 30, "Change direction"),
            PLANK(3, 1, 20, "Rotational core base"),
        ]),
        workout("Tennis Strength", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Court power"),
            BARBELL_ROW(3, 8, 90, "Backhand strength"),
            BARBELL_OHP(3, 8, 90, "Serve power"),
            RUSSIAN_TWIST(3, 20, 20, "Rotational core"),
            CALF_RAISE(4, 15, 20, "Quick foot speed"),
            SIDE_PLANK(3, 1, 20, "Lateral stability"),
        ]),
    ]


# 42. Cricket Performance
def _cricket_performance():
    return [
        workout("Bowling Power & Endurance", "strength", 55, [
            BARBELL_OHP(3, 8, 90, "Bowling power"),
            BARBELL_ROW(3, 8, 90, "Pulling balance"),
            BARBELL_SQUAT(3, 8, 150, "Lower body for bowling run-up"),
            RDL(3, 10, 120, "Hamstring for bowling"),
            RUSSIAN_TWIST(3, 20, 20, "Rotational power for spin"),
            PLANK(3, 1, 20, "Core stability"),
        ]),
        workout("Cricket Batting Power", "strength", 50, [
            ex("Rotational Cable Chop", 3, 12, 45, "Per side, low to high",
               "Cable Machine", "Core", "Obliques",
               ["Shoulders", "Hips", "Transverse Abdominis"], "intermediate",
               "Hip rotation, arms follow, mimic batting motion", "Russian Twist"),
            DEADLIFT(3, 5, 180, "Total body power"),
            BARBELL_BENCH(3, 8, 120, "Pushing strength"),
            CALF_RAISE(4, 15, 20, "Quick footwork"),
            SIDE_PLANK(3, 1, 20, "Lateral stability"),
        ]),
        workout("Cricket Fielding Conditioning", "cardio", 40, [
            cardio_ex("Interval Run", 1200, "20 min: 30s sprint, 90s jog x10", "Bodyweight", "intermediate"),
            BOX_JUMP(3, 8, 45, "Leaping catches"),
            ex("Lateral Bound", 3, 10, 45, "Per side, dive field simulation",
               "Bodyweight", "Legs", "Glutes",
               ["Adductors", "Calves"], "intermediate",
               "Push off one leg, bound laterally, soft landing", "Jump Squat"),
        ]),
    ]


# 43. Golf Power & Flexibility
def _golf_power_flexibility():
    return [
        workout("Golf Rotational Power", "strength", 50, [
            ex("Cable Rotation", 3, 15, 30, "Per side, hip to shoulder height",
               "Cable Machine", "Core", "Obliques",
               ["Transverse Abdominis", "Hips", "Shoulders"], "beginner",
               "Rotate from hips, arms extended, mimic swing", "Russian Twist"),
            RUSSIAN_TWIST(3, 20, 20, "Weighted rotational core"),
            DEADLIFT(3, 6, 150, "Hip hinge power for swing"),
            BARBELL_OHP(3, 8, 90, "Follow-through power"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, balance for swing"),
        ]),
        workout("Golf Mobility & Flexibility", "mobility", 40, [
            WORLD_GREATEST_STRETCH(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            CAT_COW(),
            THORACIC_EXTENSION(),
            HIP_90_90(),
            ex("Seated Trunk Rotation", 3, 10, 10, "Per side, gentle",
               "Bodyweight", "Core", "Thoracic Spine",
               ["Obliques"], "beginner",
               "Sit tall, rotate slowly, keep hips still", "Supine Spinal Twist"),
        ]),
    ]


# 44. Swimming Dryland
def _swimming_dryland():
    return [
        workout("Swim Dryland: Pull Strength", "strength", 50, [
            PULLUP(4, 10, 90, "Freestyle and butterfly pull"),
            LAT_PULLDOWN(3, 10, 60, "Lat engagement for freestyle"),
            CABLE_ROW(3, 12, 60, "Pull-through"),
            BARBELL_OHP(3, 10, 90, "Butterfly shoulder strength"),
            FACE_PULL(3, 15, 20, "Shoulder health and rotation"),
            ex("Rotation Band Pull", 3, 15, 20, "Per arm, shoulder external rotation",
               "Resistance Band", "Shoulders", "Rotator Cuff",
               ["Rear Deltoid"], "beginner",
               "Elbow at 90, rotate outward, keep elbow fixed", "Band Pull-Apart"),
        ]),
        workout("Swim Dryland: Core & Kick", "strength", 45, [
            PLANK(4, 1, 20, "Streamline core simulation"),
            DEAD_BUG(3, 10, 20, "Per side"),
            SUPERMAN(3, 12, 20, "Backstroke and butterfly"),
            ex("Flutter Kick", 3, 30, 20, "On back, small rapid kicks",
               "Bodyweight", "Core", "Hip Flexors",
               ["Lower Abs", "Quadriceps"], "beginner",
               "Small amplitude kicks from hip, straight legs", "Lying Leg Raise"),
            BIRD_DOG(3, 10, 20, "Stability"),
            HANGING_LEG_RAISE(3, 12, 45, "Core and hip flexor strength"),
        ]),
    ]


# 45. Running Performance
def _running_performance():
    return [
        workout("Speed Development", "cardio", 45, [
            cardio_ex("Sprint Drills", 600, "10 min: A-skips, B-skips, high knees drills", "Bodyweight", "intermediate"),
            cardio_ex("Track Intervals", 1200, "8x200m at 90% effort, 90s rest", "Bodyweight", "advanced"),
            cardio_ex("Cooldown Jog", 300, "5 min easy", "Bodyweight", "beginner"),
        ]),
        workout("Runner Strength", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Running economy"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, hamstring stability"),
            STEP_UP(3, 12, 45, "Per leg"),
            CALF_RAISE(5, 20, 20, "Plantar flexion power"),
            PLANK(3, 1, 20, "Core for form"),
            DEAD_BUG(3, 10, 20, "Lumbopelvic stability"),
        ]),
        workout("Tempo Run", "cardio", 40, [
            cardio_ex("Warm-Up", 300, "5 min easy jog", "Bodyweight", "beginner"),
            cardio_ex("Tempo Run", 1800, "30 min at threshold pace", "Bodyweight", "intermediate"),
            cardio_ex("Cooldown", 300, "5 min easy", "Bodyweight", "beginner"),
        ]),
    ]


# 46. Cycling Strength
def _cycling_strength():
    return [
        workout("Cycling Power Legs", "strength", 55, [
            BARBELL_SQUAT(4, 6, 180, "Pedal power"),
            LEG_PRESS(4, 10, 120, "Quad dominance like cycling"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, single leg pedal strength"),
            CALF_RAISE(5, 20, 20, "Pedal stroke calves"),
            STEP_UP(3, 12, 60, "Per leg"),
        ]),
        workout("Cyclist Core & Upper", "strength", 45, [
            PLANK(4, 1, 30, "60-90 seconds, aero position core"),
            DEADLIFT(3, 6, 150, "Hip hinge for climbing"),
            BARBELL_ROW(3, 8, 90, "Upper back for posture"),
            FACE_PULL(3, 15, 20, "Shoulder prehab"),
            BIRD_DOG(3, 10, 20, "Lumbar stability"),
        ]),
    ]


# 47. Decathlon Training
def _decathlon_training():
    return [
        workout("Sprint & Jump Events", "strength", 60, [
            POWER_CLEAN(5, 3, 120, "Explosive power for all events"),
            BARBELL_SQUAT(4, 5, 180, "Leg power for jumps and sprints"),
            JUMP_SQUAT(4, 8, 60, "Jump training"),
            BOX_JUMP(3, 8, 60, "Plyometric"),
            ex("Single Leg Bound", 3, 8, 60, "Per leg, long jump prep",
               "Bodyweight", "Legs", "Glutes",
               ["Quadriceps", "Calves"], "intermediate",
               "Push off one leg, bound forward, land on same leg", "Jump Squat"),
        ]),
        workout("Throw & Vault Strength", "strength", 55, [
            BARBELL_OHP(4, 5, 120, "Shot put and javelin"),
            BARBELL_BENCH(3, 5, 150, "Horizontal power"),
            ex("Rotational Throw", 4, 8, 45, "Medicine ball, per side",
               "Medicine Ball", "Core", "Obliques",
               ["Shoulders", "Hips"], "intermediate",
               "Rotate fully, explosively throw ball into wall", "Russian Twist"),
            PULLUP(4, 8, 90, "Pole vault upper body"),
            DEADLIFT(3, 5, 180, "Total body power"),
        ]),
        workout("Middle Distance Endurance", "cardio", 50, [
            cardio_ex("800m/1500m Simulation", 1800, "30 min: intervals with 400m pace work", "Bodyweight", "advanced"),
            cardio_ex("Hurdle Drill Simulation", 600, "10 min: high knee fast legs drill", "Bodyweight", "intermediate"),
        ]),
    ]


# 48. Kickboxing Fitness
def _kickboxing_fitness():
    return [
        workout("Kickboxing Conditioning", "hiit", 50, [
            ex("Shadow Kickboxing", 5, 1, 30, "3 min rounds with 30s rest",
               "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Legs", "Cardiovascular"], "intermediate",
               "Punches, kicks, knees alternating, stay on toes", "Jump Rope",
               duration_seconds=180),
            JUMP_ROPE(4, 1, 30, "60 seconds between rounds"),
            MOUNTAIN_CLIMBER(3, 30, 20, "Core and cardio"),
            BURPEE(3, 10, 20, "Fight conditioning"),
        ]),
        workout("Kickboxing Strength", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Kicking power"),
            DEADLIFT(3, 6, 150, "Hip extension for kicks"),
            BARBELL_OHP(3, 8, 90, "Punching power"),
            BARBELL_ROW(3, 8, 90, "Pulling guard"),
            PLANK(3, 1, 20, "Core rotation base"),
            RUSSIAN_TWIST(3, 20, 20, "Rotational core"),
        ]),
    ]


# 49. Boxing Conditioning
def _boxing_conditioning():
    return [
        workout("Boxing Rounds", "hiit", 50, [
            ex("Heavy Bag Rounds", 6, 1, 30, "3 min round, 30s rest - all combos",
               "Heavy Bag", "Full Body", "Shoulders",
               ["Core", "Legs", "Cardiovascular", "Arms"], "intermediate",
               "Stay on toes, full extension, protect guard, breathe out on punches", "Shadow Boxing",
               duration_seconds=180),
            JUMP_ROPE(4, 1, 30, "60 seconds skipping"),
        ]),
        workout("Boxing Strength", "strength", 55, [
            BARBELL_BENCH(3, 6, 150, "Punching power"),
            BARBELL_ROW(3, 8, 90, "Upper back for guard"),
            BARBELL_SQUAT(3, 8, 150, "Leg drive in punches"),
            ex("Medicine Ball Slam", 3, 12, 45, "Full overhead slam",
               "Medicine Ball", "Full Body", "Shoulders",
               ["Core", "Lats", "Legs"], "intermediate",
               "Overhead, full extension, slam straight down, squat to pick up", "Battle Ropes"),
            PLANK(4, 1, 20, "60 seconds"),
            RUSSIAN_TWIST(3, 25, 20, "Rotational power"),
        ]),
        workout("Boxing Roadwork", "cardio", 45, [
            cardio_ex("Running", 1800, "30 min easy-moderate, classic boxing roadwork", "Bodyweight", "intermediate"),
            ex("Shadow Boxing", 3, 1, 30, "3 min easy rounds",
               "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Legs"], "beginner",
               "Light combos, movement, stay loose", "High Knees",
               duration_seconds=180),
        ]),
    ]


# 50. Combat Conditioning
def _combat_conditioning():
    return [
        workout("Combat Strength Base", "strength", 60, [
            DEADLIFT(4, 5, 200, "Total body power"),
            BARBELL_SQUAT(4, 5, 180, "Lower body dominance"),
            BARBELL_BENCH(4, 6, 150, "Pushing power"),
            PULLUP(4, 8, 90, "Clinch and grappling"),
            FARMER_WALK(3, 1, 60, "Grip strength"),
            PLANK(3, 1, 20, "Core armor"),
        ]),
        workout("Combat Conditioning Circuit", "hiit", 50, [
            BURPEE(5, 10, 30, "GPP conditioning"),
            BATTLE_ROPES(4, 1, 30, "30 seconds max effort"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds fast"),
            ex("Sprawls", 3, 10, 30, "Takedown defense simulation",
               "Bodyweight", "Full Body", "Full Body",
               ["Core", "Shoulders", "Legs"], "intermediate",
               "Jump feet back to sprawl position, push hips to floor, recover", "Burpee"),
            JUMP_SQUAT(3, 10, 30, "Explosive"),
        ]),
    ]


# 51. Judo Fitness
def _judo_fitness():
    return [
        workout("Judo Grip & Throw Strength", "strength", 55, [
            DEADLIFT(4, 5, 180, "Hip power for throws"),
            BARBELL_ROW(4, 8, 90, "Collar-sleeve pull"),
            PULLUP(4, 10, 90, "Grip pulling strength"),
            FARMER_WALK(4, 1, 60, "Grip endurance"),
            ex("Towel Pull-Up", 3, 8, 90, "Use towel for grip training",
               "Bodyweight", "Back", "Grip",
               ["Latissimus Dorsi", "Biceps", "Forearms"], "advanced",
               "Drape towel over bar, grip each end, pull up", "Pull-Up"),
            BARBELL_SQUAT(3, 6, 150, "Seoi-nage and hip throw power"),
        ]),
        workout("Judo Conditioning", "hiit", 45, [
            ex("Uchi-Komi Simulation", 5, 20, 30, "Entry drill practice",
               "Bodyweight", "Full Body", "Hip Flexors",
               ["Core", "Legs", "Back"], "intermediate",
               "Step in for throw, don't finish, rapid entries", "Squat"),
            BURPEE(4, 10, 30, "Randori conditioning"),
            BATTLE_ROPES(3, 1, 30, "30 seconds grip endurance"),
            PLANK(3, 1, 20, "Core stability"),
        ]),
    ]


# 52. Kung Fu Conditioning
def _kung_fu_conditioning():
    return [
        workout("Kung Fu Strength & Balance", "strength", 55, [
            BARBELL_SQUAT(3, 8, 120, "Stance power"),
            SINGLE_LEG_RDL(3, 10, 60, "Per leg, balance"),
            BARBELL_OHP(3, 8, 90, "Strike extension"),
            PULLUP(3, 10, 90, "Upper body control"),
            ex("Horse Stance Hold", 3, 1, 30, "Hold 60 seconds, traditional horse stance",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Core", "Adductors"], "beginner",
               "Wide squat, parallel thighs, upright spine, breathe", "Wall Sit"),
            PLANK(3, 1, 20, "Core stability"),
        ]),
        workout("Kung Fu Flexibility & Flow", "mobility", 40, [
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            PIRIFOMIS_STRETCH(),
            ex("Front Split Hold", 2, 1, 15, "Hold 30 seconds, each side",
               "Bodyweight", "Legs", "Hip Flexors",
               ["Hamstrings", "Adductors"], "intermediate",
               "Gentle progression, don't force, breathe into stretch", "Low Lunge"),
            LOW_LUNGE(),
            DOWNWARD_DOG(),
        ]),
    ]


# 53. Martial Arts Foundation
def _martial_arts_foundation():
    return [
        workout("Martial Arts Strength", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Stance and kick power"),
            DEADLIFT(3, 6, 150, "Hip extension power"),
            BARBELL_OHP(3, 8, 90, "Strike power"),
            PULLUP(3, 8, 90, "Guard and clinch strength"),
            PLANK(3, 1, 20, "Core armor"),
            RUSSIAN_TWIST(3, 20, 20, "Rotational power"),
        ]),
        workout("Martial Arts Conditioning", "hiit", 45, [
            ex("Shadow Fighting", 5, 1, 30, "3 min rounds, all strikes and footwork",
               "Bodyweight", "Full Body", "Shoulders",
               ["Core", "Legs", "Cardiovascular"], "intermediate",
               "Full combinations, footwork, stay light, 30s rest", "Jump Rope",
               duration_seconds=180),
            JUMP_ROPE(3, 1, 30, "60 seconds"),
            HIGH_KNEES(3, 30, 15, "Quick feet"),
            BURPEE(3, 10, 30, "Full conditioning"),
        ]),
        workout("Martial Arts Flexibility", "mobility", 35, [
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            PIRIFOMIS_STRETCH(),
            HIP_90_90(),
            ex("Leg Kick Swings", 2, 10, 10, "Per leg, forward and lateral",
               "Bodyweight", "Legs", "Hip Flexors",
               ["Hamstrings", "Adductors"], "beginner",
               "Controlled momentum swings, progressively higher", "Standing Forward Fold"),
            LOW_LUNGE(),
        ]),
    ]


###############################################################################
# MISC PROGRAMS
###############################################################################

# 54. General Athlete
def _general_athlete():
    return [
        workout("Athlete Upper Body", "strength", 55, [
            BARBELL_BENCH(4, 6, 150, "Pressing power"),
            BARBELL_ROW(4, 6, 120, "Pulling balance"),
            BARBELL_OHP(3, 8, 90, "Overhead power"),
            PULLUP(3, 10, 90, "Back width"),
            DB_LATERAL_RAISE(3, 12, 30, "Shoulder stability"),
            FACE_PULL(3, 15, 20, "Prehab"),
        ]),
        workout("Athlete Lower Body", "strength", 55, [
            BARBELL_SQUAT(4, 6, 180, "Explosive squatting"),
            DEADLIFT(3, 5, 200, "Hinge strength"),
            SINGLE_LEG_RDL(3, 8, 60, "Per leg"),
            BOX_JUMP(3, 8, 60, "Explosive power"),
            CALF_RAISE(4, 15, 30, "Sprint and jump support"),
        ]),
        workout("Athlete Conditioning", "hiit", 40, [
            BATTLE_ROPES(3, 1, 30, "30 seconds"),
            BOX_JUMP(3, 10, 45, "Plyometric"),
            BURPEE(3, 10, 30, "Full body"),
            FARMER_WALK(3, 1, 60, "Loaded carry"),
            PLANK(3, 1, 20, "Core"),
        ]),
    ]


# 55. Sport Hybrid Training
def _sport_hybrid_training():
    return [
        workout("Hybrid Strength-Speed", "strength", 60, [
            POWER_CLEAN(5, 3, 120, "Explosiveness"),
            BARBELL_SQUAT(4, 5, 180, "Strength base"),
            BARBELL_BENCH(3, 6, 150, "Upper power"),
            BOX_JUMP(4, 6, 60, "Plyometric"),
            JUMP_SQUAT(3, 10, 45, "Speed-strength"),
        ]),
        workout("Hybrid Endurance-Strength", "hiit", 55, [
            BARBELL_OHP(3, 8, 90, "Overhead pressing"),
            PULLUP(3, 10, 90, "Back"),
            cardio_ex("Run Intervals", 1200, "20 min: 2 min hard, 1 min walk x7", "Bodyweight", "intermediate"),
            PLANK(3, 1, 20, "Core"),
            BATTLE_ROPES(3, 1, 30, "Upper conditioning"),
        ]),
        workout("Agility & Sport Drills", "hiit", 40, [
            ex("Agility Ladder Drills", 4, 1, 45, "1 min each drill: in/out, lateral, high knees",
               "Agility Ladder", "Full Body", "Calves",
               ["Cardiovascular", "Coordination", "Agility"], "intermediate",
               "Stay light on toes, sharp arm drive, look up", "High Knees"),
            JUMP_SQUAT(3, 10, 30, "Explosive"),
            HIGH_KNEES(3, 30, 15, "Speed"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Conditioning"),
        ]),
    ]


# 56. Strength-Yoga Fusion
def _strength_yoga_fusion():
    return [
        workout("Strength Block", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Functional lower body"),
            BARBELL_ROW(3, 8, 90, "Pulling strength"),
            BARBELL_OHP(3, 8, 90, "Overhead press"),
            DEADLIFT(3, 6, 150, "Hinge pattern"),
            PLANK(3, 1, 20, "Core link"),
        ]),
        workout("Yoga Flow Block", "mobility", 40, [
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            WARRIOR_III(),
            PIGEON_POSE(),
            BRIDGE_POSE(),
            SEATED_FORWARD_FOLD(),
            SAVASANA(),
        ]),
        workout("Fusion Full Body", "hypertrophy", 55, [
            BARBELL_SQUAT(3, 8, 120, "Strength foundation"),
            PULLUP(3, 8, 90, "Back strength"),
            DB_OHP(3, 10, 60, "Shoulder strength"),
            WARRIOR_I(),
            WARRIOR_II(),
            PIGEON_POSE(),
            DOWNWARD_DOG(),
            PLANK(2, 1, 20, "45 seconds"),
        ]),
    ]


# 57. Protein-Priority Training
def _protein_priority_training():
    return [
        workout("High Volume Upper", "hypertrophy", 65, [
            BARBELL_BENCH(4, 10, 90, "Chest volume, maximize protein synthesis"),
            BARBELL_ROW(4, 10, 90, "Back volume"),
            BARBELL_OHP(4, 10, 90, "Shoulder volume"),
            PULLUP(4, 10, 90, "Lat volume"),
            DB_LATERAL_RAISE(4, 15, 30, "Side delt"),
            DB_CURL(4, 15, 45, "Bicep volume"),
            TRICEP_PUSHDOWN(4, 15, 45, "Tricep volume"),
        ]),
        workout("High Volume Lower", "hypertrophy", 65, [
            BARBELL_SQUAT(4, 10, 90, "Quad volume"),
            DEADLIFT(3, 8, 120, "Posterior chain"),
            LEG_PRESS(4, 15, 60, "Leg volume"),
            LEG_EXT(4, 15, 45, "Quad isolation"),
            LEG_CURL(4, 15, 45, "Hamstring isolation"),
            HIP_THRUST(4, 15, 60, "Glute volume"),
            CALF_RAISE(5, 20, 30, "Calf volume"),
        ]),
    ]


# 58. Competition Prep (Generic)
def _competition_prep():
    return [
        workout("Competition Strength Day", "strength", 60, [
            BARBELL_SQUAT(5, 5, 180, "Competition-ready strength"),
            BARBELL_BENCH(5, 5, 150, "Competition-ready pressing"),
            DEADLIFT(4, 5, 200, "Competition-ready pull"),
            BARBELL_OHP(3, 8, 90, "Accessory"),
            FACE_PULL(3, 15, 20, "Shoulder health"),
        ]),
        workout("Competition Conditioning", "hiit", 45, [
            BURPEE(4, 15, 30, "GPP conditioning"),
            BATTLE_ROPES(3, 1, 30, "Upper conditioning"),
            BOX_JUMP(3, 10, 45, "Explosive power"),
            PLANK(3, 1, 20, "Core"),
            FARMER_WALK(3, 1, 60, "Grip and carry"),
        ]),
        workout("Competition Taper & Mobility", "mobility", 35, [
            WORLD_GREATEST_STRETCH(),
            FOAM_ROLL_BACK(),
            FOAM_ROLL_QUAD(),
            HIP_FLEXOR_STRETCH(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            SAVASANA(),
        ]),
    ]


# 59. 30-Day Fat Loss Kickstart
def _30_day_fat_loss_kickstart():
    return [
        workout("Kickstart Day 1: Full Body", "hiit", 40, [
            BODYWEIGHT_SQUAT(3, 20, 20, "Form focus"),
            PUSHUP(3, 15, 20, "Full range"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Core cardio"),
            JUMP_SQUAT(3, 12, 20, "Explosive"),
            PLANK(3, 1, 15, "30 seconds"),
            BURPEE(3, 8, 20, "Full range"),
        ]),
        workout("Kickstart Day 2: Strength", "strength", 45, [
            BARBELL_SQUAT(3, 10, 90, "Lower body compound"),
            BARBELL_BENCH(3, 10, 90, "Upper push"),
            BARBELL_ROW(3, 10, 90, "Upper pull"),
            CALF_RAISE(3, 15, 20, "Calves"),
            PLANK(3, 1, 20, "Core"),
        ]),
        workout("Kickstart Day 3: Cardio Burn", "cardio", 35, [
            JUMP_ROPE(5, 1, 20, "60s on 20s off"),
            HIGH_KNEES(4, 30, 15, "30 seconds"),
            BURPEE(3, 10, 20, "Full range"),
            BATTLE_ROPES(3, 1, 20, "30 seconds"),
        ]),
    ]


# 60. 15-Minute Strength
def _15_minute_strength():
    return [
        workout("15-Min Upper Express", "strength", 15, [
            BARBELL_BENCH(3, 8, 45, "Minimal rest, compound first"),
            PULLUP(3, 8, 45, "Superset"),
            BARBELL_OHP(2, 10, 30, "Short rest"),
        ]),
        workout("15-Min Lower Express", "strength", 15, [
            BARBELL_SQUAT(3, 10, 45, "Fast rest, full depth"),
            RDL(2, 10, 30, "Hamstrings"),
            JUMP_SQUAT(2, 10, 15, "Explosive finisher"),
        ]),
        workout("15-Min Full Body Blast", "hiit", 15, [
            BURPEE(2, 10, 20, "Full range"),
            MOUNTAIN_CLIMBER(2, 30, 15, "30 seconds"),
            JUMPING_JACK(2, 30, 10, "30 seconds"),
            JUMP_SQUAT(2, 10, 15, "Explosive"),
        ]),
    ]


# 61. Sydney Cummings Full Body
def _sydney_cummings_full_body():
    return [
        workout("Full Body Follow-Along A", "hiit", 45, [
            JUMPING_JACK(1, 30, 10, "Warm-up"),
            GOBLET_SQUAT(3, 15, 30, "Moderate dumbbell"),
            DB_BENCH(3, 12, 30, "Push movement"),
            DB_ROW(3, 12, 30, "Pull movement"),
            JUMP_SQUAT(3, 12, 20, "Plyometric"),
            MOUNTAIN_CLIMBER(3, 30, 15, "Core and cardio"),
            GLUTE_BRIDGE(3, 20, 20, "Glute activation"),
            PLANK(3, 1, 20, "Core hold"),
        ]),
        workout("Full Body Follow-Along B", "hiit", 45, [
            HIGH_KNEES(1, 30, 10, "Warm-up"),
            REVERSE_LUNGE(3, 12, 30, "Per leg"),
            DB_OHP(3, 12, 30, "Shoulders"),
            INVERTED_ROW(3, 10, 30, "Back"),
            JUMPING_LUNGE(3, 10, 20, "Plyometric"),
            BURPEE(3, 8, 20, "Full range"),
            DONKEY_KICK(3, 15, 20, "Glutes"),
            BICYCLE_CRUNCH(3, 20, 20, "Core"),
        ]),
        workout("Full Body HIIT Cardio", "cardio", 35, [
            JUMPING_JACK(2, 30, 15, "30 seconds"),
            BURPEE(3, 10, 20, "Full range"),
            HIGH_KNEES(3, 30, 15, "30 seconds"),
            JUMP_SQUAT(3, 12, 20, "Explosive"),
            MOUNTAIN_CLIMBER(3, 30, 15, "30 seconds"),
        ]),
    ]


# 62. Pro Athlete Hybrid
def _pro_athlete_hybrid():
    return [
        workout("Pro Strength Day", "strength", 65, [
            POWER_CLEAN(5, 3, 120, "Power development"),
            BARBELL_SQUAT(4, 5, 200, "Maximal strength"),
            BARBELL_BENCH(4, 6, 160, "Pressing power"),
            PULLUP(4, 8, 90, "Weighted"),
            DEADLIFT(3, 5, 220, "Total body pull"),
        ]),
        workout("Pro Speed-Power Day", "hiit", 55, [
            BOX_JUMP(5, 5, 90, "Max height, reset each rep"),
            JUMP_SQUAT(4, 8, 60, "Loaded plyometric"),
            ex("Broad Jump", 4, 5, 60, "Max horizontal distance",
               "Bodyweight", "Legs", "Glutes",
               ["Quadriceps", "Hamstrings", "Calves"], "advanced",
               "Squat, swing arms, explode forward, soft two-foot landing", "Jump Squat"),
            SLED_PUSH(3, 1, 90, "Heavy, explosive"),
            BATTLE_ROPES(3, 1, 30, "30 seconds max"),
        ]),
        workout("Pro Recovery & Conditioning", "cardio", 45, [
            cardio_ex("Aerobic Base Work", 1800, "30 min zone 2 cardio", "Machine", "intermediate"),
            WORLD_GREATEST_STRETCH(),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_BACK(),
            PIGEON_POSE(),
        ]),
    ]


# 63. Elite Performance Camp
def _elite_performance_camp():
    return [
        workout("Elite Morning Strength", "strength", 70, [
            POWER_CLEAN(5, 3, 130, "Olympic lift for total athleticism"),
            BARBELL_SQUAT(5, 5, 200, "Primary strength lift"),
            BARBELL_BENCH(4, 6, 160, "Horizontal push power"),
            PULLUP(4, 8, 90, "Weighted vertical pull"),
            DEADLIFT(3, 5, 230, "Maximum posterior chain"),
            FARMER_WALK(3, 1, 60, "Loaded carry 40 yards"),
        ]),
        workout("Elite Afternoon Conditioning", "hiit", 60, [
            ex("Sprint Repeats", 8, 1, 90, "100m sprint at 95% effort, 90s rest",
               "Bodyweight", "Full Body", "Quadriceps",
               ["Glutes", "Hamstrings", "Calves", "Cardiovascular"], "advanced",
               "Full sprint, drive knees, pump arms, land midfoot", "High Knees"),
            BOX_JUMP(4, 8, 60, "Max height"),
            SLED_PUSH(4, 1, 90, "Heavy load, 40 yards"),
            BATTLE_ROPES(4, 1, 30, "30 seconds max effort"),
        ]),
        workout("Elite Recovery Session", "mobility", 40, [
            cardio_ex("Easy Bike or Walk", 600, "10 min light movement", "Machine", "beginner"),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_IT_BAND(),
            FOAM_ROLL_BACK(),
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            PIGEON_POSE(),
            SAVASANA(),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS REGISTRY
###############################################################################

BATCH_WORKOUTS = {
    # Body Composition / Aesthetics
    "Shred Program": _shred_program,
    "Extreme Shred": _extreme_shred,
    "Rapid Fat Loss": _rapid_fat_loss,
    "Stubborn Fat Loss": _stubborn_fat_loss,
    "Sustainable Fat Loss": _sustainable_fat_loss,
    "Cut & Maintain": _cut_and_maintain,
    "Full Body Fat Torch": _full_body_fat_torch,
    "Belly Fat Blaster": _belly_fat_blaster,
    "Love Handle Eliminator": _love_handle_eliminator,
    "Morning Fat Burn": _morning_fat_burn,
    "Skinny Fat Fix": _skinny_fat_fix,
    "Skinny Fat Intermediate": _skinny_fat_intermediate,
    "Skinny Fat Advanced": _skinny_fat_advanced,
    "Model Physique": _model_physique,
    "Photoshoot Ready": _photoshoot_ready,
    "Bikini Competition Prep": _bikini_competition_prep,
    "Bikini Body Countdown": _bikini_body_countdown,
    "Physique Competition Prep": _physique_competition_prep,
    "Bodybuilding Show Prep": _bodybuilding_show_prep,
    "Superhero Physique": _superhero_physique,
    "Action Hero Build": _action_hero_build,
    "Leading Man Build": _leading_man_build,
    "Action Star Conditioning": _action_star_conditioning,
    "Fighter's Body": _fighters_body,
    "Screen Ready": _screen_ready,

    # Competition / Race Prep
    "CrossFit Open Prep": _crossfit_open_prep,
    "CrossFit Style Training": _crossfit_style_training,
    "Spartan Race Prep": _spartan_race_prep,
    "GoRuck Challenge Prep": _goruck_challenge_prep,
    "Deka Fit Training": _deka_fit_training,
    "Warrior Dash Prep": _warrior_dash_prep,
    "Ragnar Relay Prep": _ragnar_relay_prep,
    "Color Run Training": _color_run_training,
    "Tough Mudder Ready": _tough_mudder_ready,
    "Obstacle Course Ready": _obstacle_course_ready,
    "Local 5K Race Prep": _local_5k_race_prep,
    "5K to Half Marathon": _5k_to_half_marathon,
    "Triathlon Foundation": _triathlon_foundation,

    # Sports Specific
    "Basketball Performance": _basketball_performance,
    "Soccer Conditioning": _soccer_conditioning,
    "Tennis Agility": _tennis_agility,
    "Cricket Performance": _cricket_performance,
    "Golf Power & Flexibility": _golf_power_flexibility,
    "Swimming Dryland": _swimming_dryland,
    "Running Performance": _running_performance,
    "Cycling Strength": _cycling_strength,
    "Decathlon Training": _decathlon_training,
    "Kickboxing Fitness": _kickboxing_fitness,
    "Boxing Conditioning": _boxing_conditioning,
    "Combat Conditioning": _combat_conditioning,
    "Judo Fitness": _judo_fitness,
    "Kung Fu Conditioning": _kung_fu_conditioning,
    "Martial Arts Foundation": _martial_arts_foundation,

    # Misc
    "General Athlete": _general_athlete,
    "Sport Hybrid Training": _sport_hybrid_training,
    "Strength-Yoga Fusion": _strength_yoga_fusion,
    "Protein-Priority Training": _protein_priority_training,
    "Competition Prep": _competition_prep,
    "30-Day Fat Loss Kickstart": _30_day_fat_loss_kickstart,
    "15-Minute Strength": _15_minute_strength,
    "Sydney Cummings Full Body": _sydney_cummings_full_body,
    "Pro Athlete Hybrid": _pro_athlete_hybrid,
    "Elite Performance Camp": _elite_performance_camp,
}
