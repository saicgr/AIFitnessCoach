#!/usr/bin/env python3
"""
Batch 11: Gender-Specific, GLP-1/Medical, Longevity, and Body-Type Programs
============================================================================
44 programs covering women's-specific, men's-specific, GLP-1/medical,
longevity/health, and body-type/size categories.
"""

from exercise_lib import *


###############################################################################
# WOMEN'S SPECIFIC (10 programs)
###############################################################################

def _womens_strength_basics():
    """3-day full-body strength for women — dumbbell & bodyweight focus."""
    return [
        workout("Day 1: Lower Body Strength", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Start light, focus form"),
            GLUTE_BRIDGE(3, 15, 30, "Bodyweight, squeeze at top"),
            DB_RDL(3, 12, 60, "Light to moderate dumbbells"),
            LATERAL_BAND_WALK(3, 15, 30, "Band above knees"),
            DEAD_BUG(3, 10, 30, "Per side, core stability"),
        ]),
        workout("Day 2: Upper Body Strength", "strength", 40, [
            DB_BENCH(3, 10, 60, "Light to moderate"),
            DB_ROW(3, 10, 60, "Pull shoulder blade, squeeze"),
            DB_OHP(3, 10, 60, "Seated or standing"),
            BAND_PULL_APART(3, 15, 20, "Light band, posture work"),
            PLANK(3, 1, 30, "Hold 30 seconds, build to 60"),
        ]),
        workout("Day 3: Full Body & Core", "strength", 45, [
            REVERSE_LUNGE(3, 10, 60, "Per leg, control the descent"),
            DONKEY_KICK(3, 15, 30, "Per leg, squeeze glute at top"),
            PUSHUP(3, 10, 45, "Knee push-up if needed"),
            CRUNCHES(3, 20, 30, "Exhale on crunch"),
            BICYCLE_CRUNCH(3, 20, 30, "Per side, controlled"),
        ]),
    ]


def _womens_self_defense():
    """Conditioning & strength for self-defense readiness."""
    return [
        workout("Striking Power & Cardio", "hiit", 35, [
            cardio_ex("Shadow Boxing", 60, "Jab-cross combos, stay light on feet", "Bodyweight", "beginner"),
            cardio_ex("Sprawl Drill", 45, "From standing, drop hips to floor, back up", "Bodyweight", "intermediate"),
            PUSHUP(3, 12, 45, "Arm strength for pushing"),
            cardio_ex("Knee Strike Drill", 45, "Grab imaginary opponent, drive knee", "Bodyweight", "beginner"),
            cardio_ex("Elbow Strike Combo", 45, "Short elbow strikes each side", "Bodyweight", "beginner"),
        ]),
        workout("Lower Body Power & Escape", "strength", 40, [
            JUMP_SQUAT(3, 8, 45, "Explosive, ground reaction force"),
            cardio_ex("Front Kick Drill", 45, "Chamber knee, kick forward, alternate legs", "Bodyweight", "beginner"),
            cardio_ex("Side Kick Drill", 45, "Drive heel sideways, chambered knee", "Bodyweight", "intermediate"),
            GLUTE_BRIDGE(3, 15, 30, "Hip escape drill — drive hips in ground fighting"),
            BIRD_DOG(3, 10, 30, "Core stability"),
        ]),
        workout("Core & Full Body Endurance", "hiit", 30, [
            cardio_ex("Burpee with Jump", 40, "Chest to floor, explosive jump", "Bodyweight", "intermediate"),
            MOUNTAIN_CLIMBER(1, 30, 20, "30 seconds fast"),
            SIDE_PLANK(2, 1, 30, "30 sec each side"),
            cardio_ex("Wrist Release Drill", 45, "Practice wrist grab releases", "Bodyweight", "beginner"),
            DEAD_BUG(3, 10, 30, "Per side"),
        ]),
    ]


def _low_impact_womens():
    """Low-impact full body — joint-friendly, no jumping."""
    return [
        workout("Day 1: Low-Impact Lower Body", "strength", 40, [
            GOBLET_SQUAT(3, 15, 45, "Slow tempo, 3 sec down"),
            GLUTE_BRIDGE(3, 20, 30, "Squeeze 2 sec at top"),
            STEP_UP(3, 12, 45, "Per leg, use a sturdy chair if no box"),
            LATERAL_BAND_WALK(3, 15, 30, "Controlled steps"),
            CLAMSHELL(3, 20, 30, "Per side, band optional"),
        ]),
        workout("Day 2: Low-Impact Upper Body", "strength", 35, [
            DB_BENCH(3, 12, 60, "Moderate dumbbells"),
            DB_ROW(3, 12, 60, "Squeeze shoulder blade"),
            DB_LATERAL_RAISE(3, 15, 30, "Light, strict form"),
            BAND_PULL_APART(3, 15, 20, "Posture & rear shoulder"),
            PLANK(3, 1, 30, "30 seconds hold"),
        ]),
        workout("Day 3: Low-Impact Full Body Flow", "cardio", 35, [
            cardio_ex("Marching in Place", 60, "Drive knees up, pump arms", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Slow and controlled"),
            DONKEY_KICK(3, 15, 30, "Per leg"),
            FIRE_HYDRANT(3, 15, 30, "Per leg"),
            BIRD_DOG(3, 10, 30, "Per side"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors", "Half-kneeling, lean forward gently"),
        ]),
    ]


def _kettlebell_for_women():
    """3-day kettlebell-focused program for women."""
    return [
        workout("KB Day 1: Swing & Hinge", "strength", 40, [
            KETTLEBELL_SWING(4, 15, 45, "Hip snap, float to shoulder height"),
            ex("Kettlebell Deadlift", 3, 10, 60, "Moderate kettlebell",
               "Kettlebell", "Full Body", "Posterior Chain",
               ["Glutes", "Hamstrings", "Back"], "beginner",
               "Hip hinge, flat back, squeeze glutes at lockout", "Dumbbell RDL"),
            ex("Kettlebell Goblet Squat", 3, 12, 60, "Hold bell by horns at chest",
               "Kettlebell", "Legs", "Quadriceps",
               ["Glutes", "Core"], "beginner",
               "Elbows track inside knees, sit deep", "Goblet Squat"),
            GLUTE_BRIDGE(3, 15, 30, "Bodyweight or kettlebell on hips"),
        ]),
        workout("KB Day 2: Press & Pull", "strength", 40, [
            ex("Kettlebell Single-Arm Press", 3, 10, 60, "Per arm, moderate weight",
               "Kettlebell", "Shoulders", "Deltoids",
               ["Triceps", "Core"], "intermediate",
               "Stack wrist, brace core, full lockout", "Dumbbell Shoulder Press"),
            ex("Kettlebell Bent-Over Row", 3, 10, 60, "Per arm",
               "Kettlebell", "Back", "Latissimus Dorsi",
               ["Rhomboids", "Biceps"], "beginner",
               "Flat back, pull to hip, squeeze", "Dumbbell Row"),
            DEAD_BUG(3, 10, 30, "Per side"),
            PLANK(3, 1, 30, "30 seconds"),
        ]),
        workout("KB Day 3: Full Body Circuit", "hiit", 35, [
            KETTLEBELL_SWING(3, 15, 45, "Moderate weight"),
            ex("Kettlebell Clean & Press", 3, 8, 60, "Per arm, light-moderate",
               "Kettlebell", "Full Body", "Shoulders",
               ["Glutes", "Core", "Triceps"], "intermediate",
               "Clean to rack, press overhead, lower with control", "Dumbbell Clean"),
            GOBLET_SQUAT(3, 12, 60, "Heavier than usual"),
            BIRD_DOG(3, 10, 30, "Per side"),
        ]),
    ]


def _post_baby_shred():
    """Postpartum-safe progressive program — core rebuild first."""
    return [
        workout("Phase 1: Core Reconnect", "strength", 30, [
            ex("Diaphragmatic Breathing", 3, 10, 15, "360-degree breath, feel ribs expand",
               "Bodyweight", "Core", "Transverse Abdominis",
               ["Pelvic Floor", "Diaphragm"], "beginner",
               "Inhale expand 360, exhale draw belly in gently", "Deep Breathing"),
            DEAD_BUG(3, 8, 30, "Per side — very slow, breathe out on effort"),
            BIRD_DOG(3, 8, 30, "Per side — find neutral spine"),
            GLUTE_BRIDGE(3, 15, 30, "Exhale on lift, squeeze glutes"),
            ex("Heel Slide", 3, 10, 20, "Per side",
               "Bodyweight", "Core", "Transverse Abdominis",
               ["Hip Flexors"], "beginner",
               "Back flat, slide heel out and back, no arch", "Dead Bug"),
        ]),
        workout("Phase 2: Lower Body & Core Stability", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Dumbbell, breathe and brace"),
            REVERSE_LUNGE(3, 10, 60, "Per leg, control descent"),
            GLUTE_BRIDGE(3, 15, 30, "Add weight when comfortable"),
            DEAD_BUG(3, 10, 30, "Per side"),
            CLAMSHELL(3, 15, 30, "Per side"),
        ]),
        workout("Phase 3: Full Body Rebuild", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Progress weight"),
            DB_ROW(3, 10, 60, "Back strength for carrying baby"),
            DB_OHP(3, 10, 60, "Start light"),
            GLUTE_BRIDGE(3, 20, 30, "Or hip thrust with dumbbell"),
            BIRD_DOG(3, 12, 30, "Per side"),
            PLANK(3, 1, 30, "30-second holds"),
        ]),
    ]


def _pcos_workout_plan():
    """PCOS-optimised: insulin sensitivity, hormone balance — moderate intensity."""
    return [
        workout("PCOS Strength A: Full Body", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Stimulates insulin sensitivity"),
            DB_RDL(3, 12, 60, "Hip hinge, moderate weight"),
            DB_BENCH(3, 10, 60, "Moderate dumbbells"),
            DB_ROW(3, 10, 60, "Back strength"),
            PLANK(3, 1, 30, "30 seconds"),
        ]),
        workout("PCOS Cardio: Zone 2 Walk/Cycle", "cardio", 35, [
            cardio_ex("Brisk Walk or Light Cycle", 1200, "Heart rate 60-70% max, conversational pace", "Bodyweight", "beginner"),
            LATERAL_BAND_WALK(3, 15, 30, "Hip activation"),
            GLUTE_BRIDGE(3, 15, 30, "Glute activation"),
            stretch("Seated Hip Stretch", 30, "Hips", "Hip Flexors", "Sit, cross ankle over knee, lean forward"),
        ]),
        workout("PCOS Strength B: Lower Focus", "strength", 45, [
            REVERSE_LUNGE(3, 12, 60, "Per leg, controlled"),
            STEP_UP(3, 12, 45, "Per leg"),
            GLUTE_BRIDGE(3, 20, 30, "Hip thrust if available"),
            CLAMSHELL(3, 20, 30, "Per side with band"),
            DEAD_BUG(3, 10, 30, "Core stability"),
        ]),
    ]


def _pms_relief_movement():
    """Low-intensity, pain-relieving movement for PMS days — no jumping."""
    return [
        workout("PMS Relief: Gentle Flow", "flexibility", 30, [
            CAT_COW(),
            CHILDS_POSE(),
            stretch("Supine Knee-to-Chest", 30, "Lower Back", "Erector Spinae",
                    "Lie back, pull both knees to chest, breathe"),
            PIGEON_POSE(),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            SAVASANA(),
        ]),
        workout("PMS Relief: Light Cardio & Stretch", "cardio", 25, [
            cardio_ex("Gentle Walk", 600, "Easy pace, fresh air if possible", "Bodyweight", "beginner"),
            stretch("Standing Side Stretch", 30, "Core", "Obliques",
                    "Arms overhead, lean to each side, breathe"),
            stretch("Seated Forward Fold", 30, "Legs", "Hamstrings",
                    "Legs extended, gentle fold, relax neck"),
            LEGS_UP_WALL(),
            stretch("Supine Butterfly", 45, "Hips", "Adductors",
                    "Soles together, knees fall out, breathe deeply"),
        ]),
    ]


def _breast_health_posture():
    """Upper back strength and posture work for breast health support."""
    return [
        workout("Posture & Upper Back Strength", "strength", 40, [
            BAND_PULL_APART(3, 15, 20, "Light band — rear shoulder health"),
            FACE_PULL(3, 15, 30, "Cable or band, external rotation"),
            WALL_ANGEL(),
            DB_ROW(3, 12, 60, "Squeeze scapula at top"),
            INVERTED_ROW(3, 10, 60, "Bodyweight, great for upper back"),
            CHIN_TUCK(),
        ]),
        workout("Core & Chest Opening", "flexibility", 30, [
            PUSHUP(3, 10, 45, "Maintain neutral spine"),
            stretch("Doorway Chest Stretch", 30, "Chest", "Pectoralis Major",
                    "Arms on doorway, lean through, breathe"),
            COBRA(),
            THORACIC_EXTENSION(),
            BIRD_DOG(3, 10, 30, "Core stability"),
            stretch("Upper Trap Stretch", 30, "Neck", "Trapezius",
                    "Tilt ear to shoulder, hold gently"),
        ]),
        workout("Full Posture Circuit", "strength", 35, [
            DB_ROW(3, 12, 60, "Moderate weight"),
            FACE_PULL(3, 15, 30, "High cable or band"),
            WALL_ANGEL(),
            BAND_PULL_APART(3, 15, 20, "Superset with wall angel"),
            PLANK(3, 1, 30, "30-second hold, neutral spine"),
            CHIN_TUCK(),
        ]),
    ]


def _kegel_pelvic_floor():
    """Pelvic floor rehab and strengthening — glutes, core, and Kegel exercises."""
    return [
        workout("Pelvic Floor Foundation", "strength", 25, [
            ex("Kegel Hold", 3, 10, 15, "Hold 5-10 seconds each",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Transverse Abdominis"], "beginner",
               "Inhale relax, exhale contract pelvic floor upward, hold 5-10s", "Diaphragmatic Breathing"),
            ex("Quick Flick Kegel", 3, 20, 15, "Fast contractions",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Transverse Abdominis"], "beginner",
               "Rapid contract-release, 1 second each", "Kegel Hold"),
            GLUTE_BRIDGE(3, 15, 30, "Exhale on lift, engage pelvic floor"),
            DEAD_BUG(3, 8, 30, "Per side, breathe out on effort"),
            BIRD_DOG(3, 8, 30, "Per side, neutral pelvis"),
        ]),
        workout("Pelvic Floor + Glute Strength", "strength", 35, [
            ex("Kegel During Squat", 3, 12, 45, "Engage pelvic floor on the way up",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Quadriceps", "Glutes"], "beginner",
               "Exhale and contract pelvic floor as you stand", "Bodyweight Squat"),
            GLUTE_BRIDGE(3, 20, 30, "Focus mind-muscle connection"),
            CLAMSHELL(3, 15, 30, "Per side"),
            REVERSE_LUNGE(3, 10, 60, "Per leg, controlled"),
            DEAD_BUG(3, 10, 30, "Per side"),
        ]),
    ]


def _fertility_support_fitness():
    """Gentle, non-stressful movement to support fertility — avoid overtraining."""
    return [
        workout("Fertility Yoga Flow", "flexibility", 35, [
            CAT_COW(),
            WARRIOR_I(),
            WARRIOR_II(),
            PIGEON_POSE(),
            BRIDGE_POSE(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
        workout("Gentle Strength Circuit", "strength", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate, no breath-holding"),
            GLUTE_BRIDGE(3, 15, 30, "Controlled breathing throughout"),
            DB_ROW(3, 10, 60, "Light to moderate"),
            DEAD_BUG(3, 8, 30, "Per side, pelvic stability"),
            stretch("Reclined Butterfly", 45, "Hips", "Adductors",
                    "Soles together, relax knees out, breathe"),
        ]),
        workout("Zone 2 Walk & Stretch", "cardio", 40, [
            cardio_ex("Brisk Walk", 1800, "30 minutes, conversational pace", "Bodyweight", "beginner"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
                    "Half-kneeling, square hips, lean gently forward"),
            stretch("Seated Spinal Twist", 30, "Back", "Obliques",
                    "Sit tall, twist gently, breathe into the stretch"),
            HAPPY_BABY(),
        ]),
    ]


###############################################################################
# MEN'S SPECIFIC (7 programs)
###############################################################################

def _mens_core_strength():
    """Male-focused core program — anti-rotation, heavy carries, bracing."""
    return [
        workout("Heavy Core & Anti-Rotation", "strength", 40, [
            PLANK(4, 1, 30, "Hold 45-60 seconds, perfect form"),
            SIDE_PLANK(3, 1, 30, "45 sec per side"),
            DEAD_BUG(3, 12, 30, "Per side, slow and controlled"),
            ex("Pallof Press", 3, 12, 45, "Per side, light cable or band",
               "Cable Machine", "Core", "Transverse Abdominis",
               ["Obliques", "Rectus Abdominis"], "intermediate",
               "Stand perpendicular to cable, press out and resist rotation", "Plank"),
            FARMER_WALK(3, 1, 60, "Heavy dumbbells, 40 yards"),
        ]),
        workout("Weighted Core Power", "strength", 45, [
            RUSSIAN_TWIST(3, 20, 30, "Hold weight, rotate fully"),
            HANGING_LEG_RAISE(3, 12, 60, "Controlled, tuck then extend"),
            BICYCLE_CRUNCH(3, 25, 30, "Per side, full rotation"),
            ex("Ab Wheel Rollout", 3, 10, 45, "Slow controlled rollout",
               "Bodyweight", "Core", "Rectus Abdominis",
               ["Latissimus Dorsi", "Shoulder Stabilizers"], "advanced",
               "Brace hard, don't let hips sag, roll to full extension", "Plank"),
            BIRD_DOG(3, 12, 30, "Per side"),
        ]),
        workout("Functional Core Circuit", "hiit", 35, [
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds fast"),
            DEAD_BUG(3, 12, 30, "Per side"),
            PLANK(3, 1, 30, "45-second hold"),
            ex("Suitcase Carry", 3, 1, 60, "40 yards each side, heavy dumbbell",
               "Dumbbell", "Core", "Quadratus Lumborum",
               ["Obliques", "Grip", "Traps"], "intermediate",
               "One heavy dumbbell, resist lateral tilt, tall posture", "Farmer's Walk"),
            SUPERMAN(3, 12, 30, "Squeeze at top"),
        ]),
    ]


def _mens_flexibility_fix():
    """Men's targeted flexibility — hips, hamstrings, thoracic, shoulders."""
    return [
        workout("Hip & Hamstring Unlock", "flexibility", 35, [
            HIP_FLEXOR_STRETCH(),
            stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings",
                    "Fold forward, slight knee bend, relax head down"),
            PIGEON_POSE(),
            HIP_90_90(),
            stretch("Adductor Stretch", 30, "Legs", "Adductors",
                    "Wide stance, shift side to side, lean into stretch"),
            WORLD_GREATEST_STRETCH(),
        ]),
        workout("Thoracic & Shoulder Mobility", "flexibility", 30, [
            THORACIC_EXTENSION(),
            WALL_ANGEL(),
            stretch("Doorway Chest Stretch", 30, "Chest", "Pectoralis Major",
                    "Arms on frame, lean forward, breathe"),
            FOAM_ROLL_BACK(),
            stretch("Cross-Body Shoulder Stretch", 30, "Shoulders", "Posterior Deltoid",
                    "Pull arm across chest gently"),
            CAT_COW(),
        ]),
        workout("Full Body Mobility Flow", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            HIP_FLEXOR_STRETCH(),
            stretch("Figure Four Glute Stretch", 30, "Glutes", "Piriformis",
                    "Lie back, cross ankle over knee, pull toward chest"),
            COBRA(),
            RECLINED_TWIST(),
        ]),
    ]


def _mens_hormone_optimization():
    """Compound-heavy training to naturally support testosterone levels."""
    return [
        workout("Day 1: Squat & Push", "strength", 55, [
            BARBELL_SQUAT(4, 5, 180, "Heavy compound — major T-driver"),
            BARBELL_BENCH(4, 5, 180, "Heavy press"),
            DB_OHP(3, 10, 60, "Moderate shoulder volume"),
            DEAD_BUG(3, 10, 30, "Core"),
        ]),
        workout("Day 2: Hinge & Pull", "strength", 55, [
            DEADLIFT(3, 5, 240, "Heaviest lift of the week"),
            BARBELL_ROW(4, 6, 120, "Heavy pulling"),
            CHINUP(3, 8, 90, "Add weight if needed"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
        ]),
        workout("Day 3: Power & Accessory", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Moderate volume day"),
            BARBELL_OHP(4, 6, 120, "Strict press"),
            PULLUP(3, 8, 90, "Full ROM"),
            DB_CURL(3, 12, 45, "Bicep accessory"),
            TRICEP_OVERHEAD(3, 12, 45, "Tricep accessory"),
        ]),
    ]


def _mens_posture_fix():
    """Forward-head, rounded-shoulder, APT correction for desk workers."""
    return [
        workout("Posture Correction Circuit A", "strength", 40, [
            CHIN_TUCK(),
            WALL_ANGEL(),
            BAND_PULL_APART(3, 20, 15, "Light band daily"),
            FACE_PULL(3, 15, 30, "Primary posture exercise"),
            DB_ROW(3, 12, 60, "Strengthen mid-back"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
                    "Half-kneeling, squeeze glute, lean forward slightly"),
        ]),
        workout("Posture Correction Circuit B", "strength", 40, [
            SUPERMAN(3, 12, 30, "Strengthen erectors"),
            BIRD_DOG(3, 12, 30, "Per side, spinal stability"),
            GLUTE_BRIDGE(3, 20, 30, "Activate inhibited glutes"),
            FOAM_ROLL_BACK(),
            THORACIC_EXTENSION(),
            CHIN_TUCK(),
        ]),
        workout("Yoga for Posture", "flexibility", 35, [
            CAT_COW(),
            COBRA(),
            DOWNWARD_DOG(),
            stretch("Doorway Chest Stretch", 30, "Chest", "Pectoralis Major",
                    "Elbows 90 degrees, lean through doorway"),
            LOW_LUNGE(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _kegel_for_men():
    """Pelvic floor strengthening for men — prostate health and core."""
    return [
        workout("Pelvic Floor Foundation for Men", "strength", 25, [
            ex("Kegel Hold", 3, 10, 15, "Hold 5-10 seconds each",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Transverse Abdominis"], "beginner",
               "Contract as if stopping urine flow, hold 5-10 seconds, release fully", "Diaphragmatic Breathing"),
            ex("Quick Kegel Flicks", 3, 20, 15, "Rapid contract-release",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Transverse Abdominis"], "beginner",
               "Rapid 1-second contractions, 20 reps, relax between sets", "Kegel Hold"),
            GLUTE_BRIDGE(3, 15, 30, "Engage pelvic floor at top of bridge"),
            DEAD_BUG(3, 10, 30, "Per side, breathe out on effort"),
            BIRD_DOG(3, 10, 30, "Pelvic stability"),
        ]),
        workout("Pelvic Floor + Core Stability", "strength", 30, [
            ex("Kegel During Squat", 3, 15, 45, "Contract on way up",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Quadriceps", "Glutes"], "beginner",
               "Exhale and engage pelvic floor as you stand from squat", "Bodyweight Squat"),
            PLANK(3, 1, 30, "30-second holds with pelvic floor engaged"),
            SIDE_PLANK(2, 1, 30, "Per side"),
            SUPERMAN(3, 12, 30, "Back strength"),
        ]),
    ]


def _low_t_combat_workout():
    """Combat low testosterone with heavy compound lifts and recovery focus."""
    return [
        workout("Heavy Lower Body (T Booster)", "strength", 55, [
            BARBELL_SQUAT(5, 5, 180, "Prioritise depth and heavy load"),
            DEADLIFT(3, 5, 240, "Hip hinge, heavy weight"),
            GOBLET_SQUAT(3, 12, 60, "Volume work after main lifts"),
            GLUTE_BRIDGE(3, 15, 45, "Glute activation"),
        ]),
        workout("Heavy Upper Body (T Booster)", "strength", 50, [
            BARBELL_BENCH(5, 5, 180, "Heavy pressing"),
            BARBELL_ROW(4, 6, 120, "Heavy horizontal pull"),
            BARBELL_OHP(3, 8, 90, "Overhead pressing"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
        ]),
        workout("Active Recovery & Mobility", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_BACK(),
            stretch("Doorway Chest Stretch", 30, "Chest", "Pectoralis Major",
                    "Open chest, hold gently"),
            SAVASANA(),
        ]),
    ]


def _prostate_health_workout():
    """Pelvic floor, hip mobility, and circulation for prostate health."""
    return [
        workout("Pelvic Health Circuit", "strength", 30, [
            ex("Kegel Hold", 3, 10, 15, "Hold 5-10 seconds",
               "Bodyweight", "Core", "Pelvic Floor",
               ["Transverse Abdominis"], "beginner",
               "Contract and hold, release fully between reps", "Deep Breathing"),
            GLUTE_BRIDGE(3, 15, 30, "Engage pelvic floor at top"),
            BIRD_DOG(3, 10, 30, "Per side, pelvic stability"),
            HIP_90_90(),
            stretch("Supine Hip Rotation", 30, "Hips", "Hip Rotators",
                    "Lie back, knees bent, let knees fall side to side"),
        ]),
        workout("Hip Mobility & Zone 2 Cardio", "cardio", 40, [
            cardio_ex("Brisk Walk", 1500, "25 minutes, increases pelvic blood flow", "Bodyweight", "beginner"),
            PIGEON_POSE(),
            HIP_FLEXOR_STRETCH(),
            PIRIFOMIS_STRETCH(),
            stretch("Deep Squat Hold", 30, "Hips", "Hip Flexors",
                    "Heels on floor, hands in prayer, hold deep squat"),
        ]),
        workout("Strength & Circulation", "strength", 40, [
            GOBLET_SQUAT(3, 15, 45, "Full depth, core tight"),
            STEP_UP(3, 12, 45, "Per leg"),
            CLAMSHELL(3, 15, 30, "Per side"),
            DEAD_BUG(3, 10, 30, "Core and pelvic stability"),
            PLANK(3, 1, 30, "Hold 30-45 seconds"),
        ]),
    ]


###############################################################################
# GLP-1 / MEDICAL (9 programs)
###############################################################################

def _ozempic_safe_strength():
    """Muscle-preservation strength training while on semaglutide."""
    return [
        workout("Upper Body Preservation", "strength", 40, [
            DB_BENCH(3, 10, 90, "Moderate weight — muscle maintenance focus"),
            DB_ROW(3, 10, 90, "Pull, protect lean mass"),
            DB_OHP(3, 10, 90, "Overhead press"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
            DB_CURL(3, 12, 45, "Bicep maintenance"),
        ]),
        workout("Lower Body Preservation", "strength", 40, [
            GOBLET_SQUAT(3, 12, 90, "Slower tempo, feel the muscle"),
            DB_RDL(3, 12, 90, "Hip hinge, hamstring focus"),
            GLUTE_BRIDGE(3, 15, 30, "Glute activation"),
            STEP_UP(3, 12, 60, "Per leg"),
            CALF_RAISE(3, 15, 30, "Calf maintenance"),
        ]),
        workout("Full Body Light Conditioning", "cardio", 30, [
            cardio_ex("Brisk Walk", 900, "15 min easy — manage energy on GLP-1", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Bodyweight only"),
            PUSHUP(3, 10, 45, "Modify as needed"),
            DEAD_BUG(3, 10, 30, "Core"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors", "Hold 30 seconds"),
        ]),
    ]


def _semaglutide_strength():
    """Progressive resistance for semaglutide users — fight muscle loss."""
    return [
        workout("Sema Strength Day 1: Push", "strength", 45, [
            DB_BENCH(3, 10, 90, "Moderate — progressive overload weekly"),
            DB_OHP(3, 10, 90, "Shoulder press"),
            PUSHUP(3, 12, 45, "Accessory chest"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tricep isolation"),
            PLANK(3, 1, 30, "Core"),
        ]),
        workout("Sema Strength Day 2: Pull + Legs", "strength", 50, [
            DB_ROW(3, 10, 90, "Back strength"),
            LAT_PULLDOWN(3, 10, 60, "Or pull-up negatives"),
            GOBLET_SQUAT(3, 12, 90, "Quad and glute drive"),
            DB_RDL(3, 12, 90, "Posterior chain"),
            DB_CURL(3, 12, 45, "Bicep"),
        ]),
        workout("Sema Active Recovery", "flexibility", 25, [
            cardio_ex("Easy Walk", 600, "10 minutes low intensity", "Bodyweight", "beginner"),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_BACK(),
            DOWNWARD_DOG(),
            CHILDS_POSE(),
            RECLINED_TWIST(),
        ]),
    ]


def _glp1_energy_builder():
    """Boost energy and fight fatigue common with GLP-1 medications."""
    return [
        workout("Energy Activation Circuit", "strength", 35, [
            cardio_ex("Marching in Place", 120, "Wake up the body", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Full depth, energising"),
            PUSHUP(3, 10, 45, "Upper body activation"),
            BIRD_DOG(3, 10, 30, "Per side"),
            GLUTE_BRIDGE(3, 15, 30, "Glute activation"),
        ]),
        workout("Strength + Cardio Combo", "hiit", 35, [
            GOBLET_SQUAT(3, 12, 60, "Moderate weight"),
            DB_ROW(3, 10, 60, "Back strength"),
            cardio_ex("Brisk Walk", 600, "10 minutes moderate pace", "Bodyweight", "beginner"),
            DEAD_BUG(3, 10, 30, "Core"),
            PLANK(2, 1, 30, "30 seconds"),
        ]),
        workout("Zone 2 Cardio + Mobility", "cardio", 40, [
            cardio_ex("Walk or Light Cycle", 1800, "30 min zone 2 for mitochondrial health", "Bodyweight", "beginner"),
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            FOAM_ROLL_BACK(),
            SAVASANA(),
        ]),
    ]


def _glp1_muscle_preservation():
    """Prioritise muscle retention for GLP-1 users losing weight rapidly."""
    return [
        workout("Compound Priority A: Lower", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Moderate-heavy, muscle signal"),
            DEADLIFT(2, 6, 180, "Hip hinge, posterior chain"),
            GOBLET_SQUAT(3, 12, 60, "Volume work"),
            LEG_CURL(3, 12, 45, "Hamstring isolation"),
            CALF_RAISE(3, 15, 30, "Calf preservation"),
        ]),
        workout("Compound Priority B: Upper", "strength", 50, [
            BARBELL_BENCH(3, 8, 120, "Moderate-heavy"),
            BARBELL_ROW(3, 8, 120, "Upper back strength"),
            BARBELL_OHP(3, 8, 90, "Shoulder press"),
            PULLUP(3, 6, 90, "Or lat pulldown"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
        ]),
        workout("Muscle Retention Accessory", "strength", 40, [
            DB_BENCH(3, 10, 60, "Light-moderate isolation"),
            DB_ROW(3, 10, 60, "Unilateral back"),
            DB_CURL(3, 12, 45, "Bicep"),
            TRICEP_PUSHDOWN(3, 12, 45, "Tricep"),
            LEG_EXT(3, 12, 45, "Quad isolation"),
            LEG_CURL(3, 12, 45, "Hamstring isolation"),
        ]),
    ]


def _post_glp1_maintenance():
    """Maintain body composition after discontinuing GLP-1 medication."""
    return [
        workout("Maintenance Strength A", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Maintain strength, progressive load"),
            BARBELL_BENCH(3, 8, 120, "Upper push"),
            DB_ROW(3, 10, 90, "Upper pull"),
            DB_RDL(3, 12, 60, "Posterior chain"),
            PLANK(3, 1, 30, "Core"),
        ]),
        workout("Metabolic Conditioning", "hiit", 35, [
            GOBLET_SQUAT(3, 15, 45, "Higher rep, metabolic"),
            PUSHUP(3, 15, 30, "Moderate pace"),
            KETTLEBELL_SWING(3, 15, 45, "Metabolic driver"),
            MOUNTAIN_CLIMBER(3, 30, 20, "30 seconds"),
            JUMPING_JACK(3, 30, 15, "Cardio"),
        ]),
        workout("Zone 2 Cardio", "cardio", 40, [
            cardio_ex("Walk, Cycle, or Row", 2400, "40 min zone 2 — metabolic health", "Bodyweight", "beginner"),
            stretch("Full Body Stretch Routine", 30, "Full Body", "Multiple",
                    "Target all major muscle groups"),
        ]),
    ]


def _weight_loss_drug_transition():
    """Bridge program for transitioning off weight-loss medications."""
    return [
        workout("Transition Strength Day 1", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Rebuild muscle with volume"),
            DB_BENCH(3, 12, 60, "Moderate volume"),
            DB_ROW(3, 12, 60, "Back strength"),
            GLUTE_BRIDGE(3, 20, 30, "Glute activation"),
            DEAD_BUG(3, 10, 30, "Core stability"),
        ]),
        workout("Transition Cardio & Metabolism", "cardio", 40, [
            cardio_ex("Brisk Walk or Cycle", 1800, "30 min zone 2, caloric awareness", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Muscle activation"),
            PUSHUP(3, 12, 45, "Chest and arms"),
            stretch("Standing Hip Circles", 20, "Hips", "Hip Flexors",
                    "Hands on hips, draw circles with pelvis"),
        ]),
        workout("Transition Strength Day 2", "strength", 45, [
            REVERSE_LUNGE(3, 12, 60, "Per leg"),
            DB_OHP(3, 10, 60, "Shoulder press"),
            PULLUP(3, 6, 90, "Or lat pulldown"),
            CALF_RAISE(3, 15, 30, "Calf"),
            PLANK(3, 1, 30, "Core"),
        ]),
    ]


def _tirzepatide_fitness_plan():
    """Muscle-preserving plan for Tirzepatide (Mounjaro/Zepbound) users."""
    return [
        workout("Tirzepatide Strength A", "strength", 45, [
            GOBLET_SQUAT(3, 12, 90, "Slow tempo, preserve muscle"),
            DB_BENCH(3, 10, 90, "Moderate push"),
            DB_ROW(3, 10, 90, "Back pull"),
            DB_RDL(3, 12, 90, "Posterior chain"),
            PLANK(3, 1, 30, "30 seconds"),
        ]),
        workout("Tirzepatide Strength B", "strength", 45, [
            REVERSE_LUNGE(3, 12, 60, "Per leg, quad & glute"),
            BARBELL_OHP(3, 8, 90, "Or dumbbell press"),
            LAT_PULLDOWN(3, 10, 60, "Back width"),
            GLUTE_BRIDGE(3, 15, 30, "Glute activation"),
            DB_CURL(3, 12, 45, "Bicep"),
        ]),
        workout("Tirzepatide Recovery Walk", "cardio", 35, [
            cardio_ex("Light Walk", 1200, "Easy 20-minute walk — energy conservation", "Bodyweight", "beginner"),
            FOAM_ROLL_QUAD(),
            stretch("Hamstring Stretch", 30, "Legs", "Hamstrings",
                    "Standing or seated fold, gentle hold"),
            CHILDS_POSE(),
        ]),
    ]


def _metabolic_reset_after_meds():
    """Rebuild metabolism post-medication with progressive loading."""
    return [
        workout("Metabolic Reset Strength", "strength", 50, [
            BARBELL_SQUAT(3, 10, 90, "Rebuild base strength"),
            DEADLIFT(2, 8, 120, "Posterior chain"),
            BARBELL_BENCH(3, 10, 90, "Push pattern"),
            BARBELL_ROW(3, 10, 90, "Pull pattern"),
            CALF_RAISE(3, 15, 30, "Often neglected"),
        ]),
        workout("Metabolic Cardio Circuit", "hiit", 35, [
            KETTLEBELL_SWING(3, 15, 45, "Metabolic driver"),
            GOBLET_SQUAT(3, 15, 45, "High rep leg work"),
            PUSHUP(3, 15, 30, "Upper body circuit"),
            cardio_ex("Jump Rope or March", 60, "Cardio burst", "Bodyweight", "beginner"),
            MOUNTAIN_CLIMBER(3, 30, 20, "Core and cardio"),
        ]),
        workout("Zone 2 Metabolic Conditioning", "cardio", 45, [
            cardio_ex("Brisk Walk, Cycle, or Elliptical", 2400, "40 min zone 2, fat-burning zone", "Bodyweight", "beginner"),
            WORLD_GREATEST_STRETCH(),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_BACK(),
        ]),
    ]


def _medication_and_movement():
    """General movement program compatible with various weight-loss medications."""
    return [
        workout("Medication-Compatible Strength", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Listen to energy levels"),
            DB_ROW(3, 10, 60, "Pull strength"),
            DB_BENCH(3, 10, 60, "Push strength"),
            GLUTE_BRIDGE(3, 15, 30, "Glute work"),
            DEAD_BUG(3, 10, 30, "Core stability"),
        ]),
        workout("Medication-Compatible Cardio", "cardio", 30, [
            cardio_ex("Easy Walk", 900, "15-20 min easy — adjust based on how you feel", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 12, 30, "Light activation"),
            BIRD_DOG(3, 10, 30, "Spinal stability"),
            stretch("Full Body Stretch", 30, "Full Body", "Multiple",
                    "Gentle hold all major groups"),
        ]),
        workout("Recovery & Mobility", "flexibility", 30, [
            CAT_COW(),
            DOWNWARD_DOG(),
            CHILDS_POSE(),
            HIP_FLEXOR_STRETCH(),
            RECLINED_TWIST(),
            LEGS_UP_WALL(),
        ]),
    ]


###############################################################################
# LONGEVITY / HEALTH (12 programs)
###############################################################################

def _longevity_fitness():
    """Zone 2 cardio, mobility, grip strength, and functional training for longevity."""
    return [
        workout("Zone 2 Cardio Foundation", "cardio", 45, [
            cardio_ex("Brisk Walk or Cycle", 2400, "40 min zone 2 — most evidence-backed longevity tool", "Bodyweight", "beginner"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors", "Post-cardio"),
            stretch("Calf Stretch", 30, "Legs", "Calves", "Wall calf stretch, both legs"),
        ]),
        workout("Functional Strength & Grip", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Functional squat pattern"),
            FARMER_WALK(3, 1, 60, "Heavy grip — grip strength predicts longevity"),
            DB_ROW(3, 10, 60, "Upper back strength"),
            DEAD_BUG(3, 10, 30, "Core stability"),
            GLUTE_BRIDGE(3, 15, 30, "Hip power and stability"),
        ]),
        workout("Mobility & Balance", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            TREE_POSE(),
            WARRIOR_I(),
            HIP_90_90(),
            FOAM_ROLL_BACK(),
            SAVASANA(),
        ]),
    ]


def _anti_aging_fitness():
    """Reverse biological age markers with resistance, Zone 2, and mobility."""
    return [
        workout("Resistance Training (Anti-Aging)", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Maintain muscle mass — critical for longevity"),
            DEADLIFT(2, 6, 180, "Posterior chain strength"),
            BARBELL_OHP(3, 8, 90, "Upper body strength"),
            PULLUP(3, 6, 90, "Or lat pulldown"),
            FACE_PULL(3, 15, 30, "Shoulder health"),
        ]),
        workout("Aerobic Capacity (VO2 Max)", "cardio", 40, [
            cardio_ex("Zone 2 Walk or Cycle", 1800, "30 min zone 2 base building", "Bodyweight", "beginner"),
            cardio_ex("2x4 Min Zone 4 Intervals", 240, "4 min hard, 4 min easy x2 — VO2 max stimulus", "Bodyweight", "intermediate"),
        ]),
        workout("Flexibility & Balance (Anti-Aging)", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            DOWNWARD_DOG(),
            TREE_POSE(),
            PIGEON_POSE(),
            THORACIC_EXTENSION(),
            SAVASANA(),
        ]),
    ]


def _blue_zone_inspired():
    """Movement patterns inspired by Blue Zone longevity communities."""
    return [
        workout("Blue Zone Daily Movement", "cardio", 40, [
            cardio_ex("Walking", 1800, "30 min non-exercise walking — Blue Zone fundamental", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Functional movement"),
            GLUTE_BRIDGE(3, 15, 30, "Hip health"),
            stretch("Standing Calf Stretch", 30, "Legs", "Calves",
                    "Heel off edge, gentle stretch"),
        ]),
        workout("Blue Zone Functional Strength", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Deep squat, full ROM"),
            FARMER_WALK(3, 1, 60, "Loaded carry"),
            STEP_UP(3, 12, 45, "Step-up simulation"),
            DEAD_BUG(3, 10, 30, "Core"),
            BIRD_DOG(3, 10, 30, "Spinal health"),
        ]),
        workout("Blue Zone Yoga & Breath", "flexibility", 35, [
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            CHILDS_POSE(),
            CAT_COW(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _mitochondrial_health():
    """Optimise mitochondrial function with Zone 2, HIIT, and strength."""
    return [
        workout("Mitochondrial Zone 2 Session", "cardio", 50, [
            cardio_ex("Zone 2 Cycle or Walk", 2700, "45 min — optimal mitochondrial biogenesis zone", "Bodyweight", "beginner"),
            WORLD_GREATEST_STRETCH(),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors", "Post-session"),
        ]),
        workout("HIIT for Mitochondria", "hiit", 30, [
            cardio_ex("High-Intensity Interval Sprints", 30, "20 sec all-out / 40 sec rest x8 — mitochondrial supercompensation", "Bodyweight", "intermediate"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Warm-down squats"),
            DEAD_BUG(3, 10, 30, "Core"),
            stretch("Standing Hamstring Stretch", 30, "Legs", "Hamstrings", "Cool down"),
        ]),
        workout("Strength for Metabolic Health", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Compound for metabolic drive"),
            DEADLIFT(2, 6, 180, "Posterior chain"),
            DB_BENCH(3, 10, 60, "Push"),
            DB_ROW(3, 10, 60, "Pull"),
            FARMER_WALK(3, 1, 60, "Grip and carry"),
        ]),
    ]


def _telomere_friendly_fitness():
    """Moderate aerobic + resistance training to protect telomeres — avoid overtraining."""
    return [
        workout("Telomere-Protective Aerobics", "cardio", 45, [
            cardio_ex("Moderate-Pace Walk or Jog", 1800, "30 min, 65-75% max HR — telomere protection sweet spot", "Bodyweight", "beginner"),
            stretch("Full Body Gentle Stretch", 30, "Full Body", "Multiple",
                    "Post-cardio, hold each 30 seconds"),
        ]),
        workout("Resistance for Telomere Health", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Moderate — avoid overtraining"),
            DB_BENCH(3, 10, 60, "Push pattern"),
            DB_ROW(3, 10, 60, "Pull pattern"),
            GLUTE_BRIDGE(3, 15, 30, "Hip hinge pattern"),
            PLANK(3, 1, 30, "Core stability"),
        ]),
        workout("Recovery & Mindful Movement", "flexibility", 30, [
            CAT_COW(),
            CHILDS_POSE(),
            SEATED_FORWARD_FOLD(),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            SAVASANA(),
        ]),
    ]


def _autophagy_promoting_exercise():
    """Fasted-state compatible moderate exercise to promote cellular autophagy."""
    return [
        workout("Fasted Zone 2 Cardio", "cardio", 45, [
            cardio_ex("Fasted Walk or Cycle", 2400, "40 min moderate, ideally fasted morning — promotes autophagy", "Bodyweight", "beginner"),
            WORLD_GREATEST_STRETCH(),
            stretch("Calf Stretch", 30, "Legs", "Calves", "Wall calf stretch"),
        ]),
        workout("Moderate Resistance (Fasted Compatible)", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Moderate weight, not maximal"),
            DB_ROW(3, 10, 60, "Upper back"),
            DB_BENCH(3, 10, 60, "Push pattern"),
            DEAD_BUG(3, 10, 30, "Core"),
            BIRD_DOG(3, 10, 30, "Stability"),
        ]),
        workout("Yoga & Breathwork for Autophagy", "flexibility", 30, [
            CAT_COW(),
            DOWNWARD_DOG(),
            COBRA(),
            SEATED_FORWARD_FOLD(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _circadian_rhythm_training():
    """Time exercise to support circadian rhythm — morning and evening protocols."""
    return [
        workout("Morning Activation (Circadian)", "strength", 30, [
            cardio_ex("Outdoor Light Exposure Walk", 600, "10 min morning sunlight — anchors circadian rhythm", "Bodyweight", "beginner"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Wake up the legs"),
            PUSHUP(3, 10, 45, "Upper body activation"),
            BIRD_DOG(3, 10, 30, "Spinal activation"),
            GLUTE_BRIDGE(3, 15, 30, "Glute activation"),
        ]),
        workout("Afternoon Peak Performance (Circadian)", "strength", 50, [
            BARBELL_SQUAT(3, 8, 120, "Core temp peaks 3-6pm — best strength window"),
            BARBELL_BENCH(3, 8, 120, "Heavy push"),
            DEADLIFT(2, 6, 180, "Heavy hinge"),
            DB_ROW(3, 10, 60, "Pull pattern"),
            PLANK(3, 1, 30, "Core"),
        ]),
        workout("Evening Wind-Down (Circadian)", "flexibility", 30, [
            CAT_COW(),
            CHILDS_POSE(),
            RECLINED_TWIST(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _grip_to_lifespan_training():
    """Grip strength is #1 predictor of all-cause mortality — train it deliberately."""
    return [
        workout("Grip Strength Day 1", "strength", 45, [
            FARMER_WALK(4, 1, 60, "Very heavy dumbbells — grip focus"),
            ex("Dead Hang", 3, 1, 90, "Hold 30-60 seconds",
               "Bodyweight", "Arms", "Grip",
               ["Forearms", "Latissimus Dorsi", "Core"], "beginner",
               "Hang from bar, full dead hang, relax shoulders", "Flexed Arm Hang",
               duration_seconds=45),
            ex("Towel Pull-Up or Row", 3, 8, 90, "Towel draped over bar",
               "Bodyweight", "Back", "Grip",
               ["Latissimus Dorsi", "Biceps"], "intermediate",
               "Grip towel, perform row or pull-up — extreme grip challenge", "Pull-Up"),
            DB_SHRUG(3, 15, 30, "Heavy, full ROM — traps and grip"),
            HAMMER_CURL(3, 12, 45, "Forearm and brachialis"),
        ]),
        workout("Grip Strength Day 2: Carries & Holds", "strength", 40, [
            ex("Suitcase Deadlift", 3, 10, 60, "One arm at a time, heavy",
               "Dumbbell", "Full Body", "Grip",
               ["Quadratus Lumborum", "Glutes", "Erector Spinae"], "intermediate",
               "Single heavy dumbbell, resist lateral lean, drive through heels", "Conventional Deadlift"),
            ex("Plate Pinch Carry", 3, 1, 60, "30 seconds each hand",
               "Dumbbell", "Arms", "Grip",
               ["Forearms", "Intrinsic Hand Muscles"], "beginner",
               "Pinch two plates together, walk 20 yards", "Farmer's Walk",
               duration_seconds=30),
            FARMER_WALK(3, 1, 60, "Max weight, 30 yards"),
            ex("Dead Hang", 3, 1, 60, "Max time, build endurance",
               "Bodyweight", "Arms", "Grip",
               ["Forearms", "Latissimus Dorsi"], "beginner",
               "Full dead hang, breathe, don't let go early", "Flexed Arm Hang",
               duration_seconds=60),
        ]),
        workout("Full Body Functional Strength", "strength", 45, [
            DEADLIFT(3, 5, 180, "Whole body power and grip"),
            BARBELL_ROW(3, 8, 90, "Back pull with grip demand"),
            PULLUP(3, 6, 90, "Grip plus back"),
            FARMER_WALK(3, 1, 60, "Loaded carry, grip emphasis"),
            DB_SHRUG(3, 15, 30, "Trap and grip"),
        ]),
    ]


def _vo2_max_longevity():
    """VO2 max is the strongest predictor of longevity — systematically improve it."""
    return [
        workout("Zone 2 Base (VO2 Max)", "cardio", 50, [
            cardio_ex("Zone 2 Run, Walk, or Cycle", 2700, "45 min, 65-70% max HR — builds mitochondrial density", "Bodyweight", "beginner"),
            stretch("Post-Cardio Stretch", 30, "Legs", "Multiple",
                    "Hip flexors, calves, hamstrings — 30 sec each"),
        ]),
        workout("Zone 4/5 Intervals (VO2 Max)", "hiit", 35, [
            cardio_ex("4x4 High-Intensity Intervals", 240, "4 min hard (90% max HR), 4 min easy, repeat x4 — proven VO2 max protocol", "Bodyweight", "intermediate"),
            cardio_ex("Warm-Down Jog", 300, "5 min easy", "Bodyweight", "beginner"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors", "Post-intervals"),
        ]),
        workout("Functional Strength for Aerobic Base", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Leg strength supports aerobic capacity"),
            DEADLIFT(2, 6, 150, "Full body strength"),
            PULLUP(3, 6, 90, "Upper body pulling"),
            DB_OHP(3, 8, 60, "Shoulder press"),
            PLANK(3, 1, 30, "Core stability"),
        ]),
    ]


def _brain_health_fitness():
    """BDNF-boosting movement for cognitive longevity."""
    return [
        workout("Aerobic BDNF Session", "cardio", 45, [
            cardio_ex("Moderate-Intensity Run or Bike", 1800, "30 min, 70-80% — peak BDNF release", "Bodyweight", "intermediate"),
            stretch("Hip Stretch", 30, "Hips", "Hip Flexors",
                    "Post-cardio hip openers"),
            stretch("Calf Stretch", 30, "Legs", "Calves",
                    "Wall stretch both sides"),
        ]),
        workout("Coordination & Balance (Neuroplasticity)", "strength", 40, [
            TREE_POSE(),
            WARRIOR_III(),
            ex("Single-Leg Balance Hold", 3, 1, 15, "30 seconds per leg, eyes closed for challenge",
               "Bodyweight", "Legs", "Balance",
               ["Ankle Stabilisers", "Core", "Proprioception"], "beginner",
               "Barefoot, stand on one leg, challenge with eyes closed", "Tree Pose",
               duration_seconds=30),
            SINGLE_LEG_RDL(3, 8, 45, "Per leg, balance challenge"),
            BIRD_DOG(3, 12, 30, "Contralateral coordination"),
        ]),
        workout("Compound Strength for Brain Health", "strength", 45, [
            BARBELL_SQUAT(3, 8, 120, "Increases BDNF and cerebral blood flow"),
            DEADLIFT(2, 6, 150, "Full body neural drive"),
            DB_ROW(3, 10, 60, "Upper back"),
            FARMER_WALK(3, 1, 60, "Grip and focus"),
            DEAD_BUG(3, 10, 30, "Brain-body connection"),
        ]),
    ]


def _bone_density_builder():
    """Weight-bearing and impact exercises to build and maintain bone density."""
    return [
        workout("Weight-Bearing Bone Builder A", "strength", 50, [
            BARBELL_SQUAT(4, 5, 180, "Heavy squats directly load spine and hips — top bone builder"),
            DEADLIFT(3, 5, 240, "Hip and spine loading"),
            BARBELL_OHP(3, 8, 90, "Wrist, shoulder, and spine loading"),
            CALF_RAISE(4, 15, 30, "Load the ankle and lower leg"),
            ex("Jump Rope", 3, 1, 30, "30 seconds — impact loading stimulates bone formation",
               "Jump Rope", "Full Body", "Calves",
               ["Bone Density", "Cardiovascular"], "beginner",
               "Light jumps, land softly, consistent rhythm", "High Knees",
               duration_seconds=30),
        ]),
        workout("Weight-Bearing Bone Builder B", "strength", 50, [
            BARBELL_BENCH(4, 6, 120, "Wrist and forearm loading"),
            BARBELL_ROW(4, 6, 120, "Spine and arm loading"),
            PULLUP(3, 6, 90, "Wrist and elbow loading"),
            BOX_JUMP(3, 8, 60, "Ground reaction force — bone stimulus"),
            STEP_UP(3, 12, 45, "Per leg, step impact"),
        ]),
        workout("Impact Cardio & Core for Bone", "hiit", 35, [
            cardio_ex("Walking or Jogging", 900, "15 min — weight-bearing cardio for femur/spine", "Bodyweight", "beginner"),
            JUMP_SQUAT(3, 8, 45, "Impact loading"),
            JUMPING_JACK(3, 30, 15, "Impact and lateral load"),
            PLANK(3, 1, 30, "Spine loading in plank"),
            SUPERMAN(3, 12, 30, "Posterior chain, spinal extension"),
        ]),
    ]


def _hormone_balance_workout():
    """Balanced training to support hormonal health — not too much, not too little."""
    return [
        workout("Moderate Strength (Hormone Support)", "strength", 45, [
            BARBELL_SQUAT(3, 8, 90, "Moderate load — avoids cortisol spike"),
            DB_BENCH(3, 10, 60, "Push pattern"),
            DB_ROW(3, 10, 60, "Pull pattern"),
            DB_RDL(3, 12, 60, "Posterior chain"),
            PLANK(3, 1, 30, "Core"),
        ]),
        workout("Zone 2 Cardio (Hormone Support)", "cardio", 40, [
            cardio_ex("Walk or Light Cycle", 2400, "40 min zone 2 — lowers cortisol, supports insulin sensitivity", "Bodyweight", "beginner"),
            stretch("Full Body Stretch", 30, "Full Body", "Multiple",
                    "Hold each major muscle group 30 seconds"),
        ]),
        workout("Yoga & Recovery (Hormone Reset)", "flexibility", 35, [
            DOWNWARD_DOG(),
            WARRIOR_I(),
            BRIDGE_POSE(),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


###############################################################################
# BODY TYPE / SIZE (6 programs)
###############################################################################

def _plus_size_beginner():
    """Low-impact, chair-assisted beginner program for plus-size individuals."""
    return [
        workout("Plus Size Beginner: Seated & Standing", "strength", 30, [
            ex("Seated Marching", 3, 20, 20, "Seated in chair, lift knees alternately",
               "Bodyweight", "Legs", "Hip Flexors",
               ["Quadriceps", "Core"], "beginner",
               "Sit tall, drive knee up, controlled pace", "March in Place"),
            ex("Chair Squat", 3, 10, 45, "Stand from chair, sit back slowly",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings"], "beginner",
               "Stand fully, sit back with control, don't drop", "Wall Sit"),
            ex("Wall Push-Up", 3, 10, 30, "Hands on wall, angled push",
               "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps", "Core"], "beginner",
               "Hands shoulder width, lean in, push back, keep body straight", "Knee Push-Up"),
            ex("Seated Leg Raise", 3, 15, 30, "Per leg, seated",
               "Bodyweight", "Legs", "Quadriceps",
               ["Hip Flexors"], "beginner",
               "Sit tall, straighten leg, hold 1 second, lower slowly", "Lying Leg Raise"),
            BIRD_DOG(2, 8, 30, "Per side, supported on chair if needed"),
        ]),
        workout("Plus Size Beginner: Gentle Cardio", "cardio", 25, [
            cardio_ex("Seated March", 120, "In chair, knees up, pump arms", "Bodyweight", "beginner"),
            cardio_ex("Slow Walk", 600, "10 min easy walk, comfortable pace", "Bodyweight", "beginner"),
            stretch("Seated Side Bend", 20, "Core", "Obliques",
                    "Reach arm up and over, hold gently"),
            stretch("Seated Forward Lean", 20, "Back", "Erector Spinae",
                    "Lean forward in chair, breathe into back"),
        ]),
        workout("Plus Size Beginner: Full Body Day", "strength", 30, [
            ex("Chair Squat", 3, 10, 45, "Stand from chair fully, sit back with control",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings"], "beginner",
               "Stand fully, lower slowly, arms can reach forward for balance", "Wall Sit"),
            ex("Wall Push-Up", 3, 12, 30, "Hands on wall, angled push, progress closer to floor",
               "Bodyweight", "Chest", "Pectoralis Major",
               ["Triceps", "Core"], "beginner",
               "Hands shoulder width on wall, lean in, push back, body straight", "Knee Push-Up"),
            GLUTE_BRIDGE(3, 12, 30, "Arms at sides for support"),
            ex("Seated Torso Twist", 3, 15, 20, "Hands on thighs, twist gently",
               "Bodyweight", "Core", "Obliques",
               ["Erector Spinae"], "beginner",
               "Sit tall, rotate shoulders side to side, breathe", "Seated Twist"),
            stretch("Chest Opener", 30, "Chest", "Pectoralis Major",
                    "Arms wide, roll shoulders back, breathe"),
        ]),
    ]


def _plus_size_strength():
    """Progressive resistance training adapted for plus-size individuals."""
    return [
        workout("Plus Size Strength: Lower Body", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Use dumbbell for counterbalance, full depth"),
            GLUTE_BRIDGE(3, 20, 30, "Heavy dumbbell on hips when ready"),
            STEP_UP(3, 10, 45, "Per leg, low box to start"),
            LATERAL_BAND_WALK(3, 15, 30, "Hip abductor activation"),
            CALF_RAISE(3, 15, 30, "Standing or seated"),
        ]),
        workout("Plus Size Strength: Upper Body", "strength", 40, [
            DB_BENCH(3, 10, 60, "Dumbbell bench — back support important"),
            DB_ROW(3, 10, 60, "One-arm row, supported on bench"),
            DB_OHP(3, 10, 60, "Seated for stability"),
            BAND_PULL_APART(3, 15, 20, "Posture and rear shoulder"),
            PLANK(3, 1, 30, "Incline plank on bench if needed"),
        ]),
        workout("Plus Size Full Body Circuit", "strength", 40, [
            GOBLET_SQUAT(3, 12, 60, "Increase weight progressively"),
            DB_BENCH(3, 10, 60, "Moderate push"),
            DB_ROW(3, 10, 60, "Moderate pull"),
            GLUTE_BRIDGE(3, 20, 30, "Loaded bridge"),
            DEAD_BUG(3, 10, 30, "Core stability"),
        ]),
    ]



def _short_person_optimization():
    """Exercises that leverage shorter limb proportions for strength advantage."""
    return [
        workout("Short Lifter Strength A (Leverage Advantage)", "strength", 50, [
            BARBELL_SQUAT(4, 5, 180, "Short limbs = great squat mechanics, go heavy"),
            BARBELL_BENCH(4, 5, 180, "Shorter ROM = strength advantage, exploit it"),
            BARBELL_ROW(3, 8, 90, "Row feels different with short arms — good ROM"),
            DB_LATERAL_RAISE(3, 15, 30, "Deltoid work for proportional width"),
            CALF_RAISE(4, 20, 30, "Calves often need extra volume"),
        ]),
        workout("Short Lifter Strength B (Posterior Chain)", "strength", 50, [
            DEADLIFT(3, 5, 240, "Low floor-to-hip ratio is an advantage"),
            BARBELL_OHP(3, 8, 90, "Shorter ROM = strong press"),
            PULLUP(3, 8, 90, "Add weight early — short limbs are lighter"),
            DB_SHRUG(3, 15, 30, "Trap development"),
            LEG_EXT(3, 12, 45, "Quad sweep for visual proportion"),
        ]),
        workout("Short Physique Aesthetic Accessory", "strength", 40, [
            DB_LATERAL_RAISE(4, 15, 30, "Shoulder width creates proportion"),
            CABLE_ROW(3, 12, 45, "Back thickness"),
            CONCENTRATION_CURL(3, 12, 30, "Bicep peak"),
            TRICEP_OVERHEAD(3, 12, 45, "Tricep length"),
            CALF_RAISE(4, 20, 30, "Calf development"),
        ]),
    ]


def _tall_person_training():
    """Technique and programming adjustments for tall lifters (6ft+)."""
    return [
        workout("Tall Lifter Strength A", "strength", 55, [
            BARBELL_SQUAT(4, 5, 150, "Longer ROM — control descent, don't bounce"),
            BARBELL_BENCH(4, 5, 150, "Longer ROM means more work — use full range"),
            BARBELL_ROW(3, 8, 90, "Great ROM advantage for lat stretch"),
            FACE_PULL(3, 15, 30, "Shoulder health for long lever arms"),
            DEAD_BUG(3, 10, 30, "Core stability — tall people often have lumbar issues"),
        ]),
        workout("Tall Lifter Strength B (Hinge Focus)", "strength", 55, [
            SUMO_DEADLIFT(3, 5, 180, "Sumo often suits tall lifters — shorter torso-to-leg ratio"),
            BARBELL_OHP(3, 8, 90, "Long arms, full lockout, impressive range"),
            PULLUP(3, 6, 90, "Long hang — really stretch the lats"),
            GOBLET_SQUAT(3, 12, 60, "Goblet helps tall squat mechanics"),
            DB_LATERAL_RAISE(3, 15, 30, "Shoulder volume for proportional look"),
        ]),
        workout("Tall Lifter Mobility (Essential)", "flexibility", 35, [
            WORLD_GREATEST_STRETCH(),
            HIP_FLEXOR_STRETCH(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            THORACIC_EXTENSION(),
            stretch("Hamstring Stretch", 30, "Legs", "Hamstrings",
                    "Tall people often have tight hamstrings — hold 45 sec"),
        ]),
    ]


def _large_frame_mobility():
    """Joint-friendly mobility and strength for larger body frames."""
    return [
        workout("Large Frame Mobility Flow", "flexibility", 35, [
            CAT_COW(),
            WORLD_GREATEST_STRETCH(),
            HIP_90_90(),
            FOAM_ROLL_QUAD(),
            FOAM_ROLL_IT_BAND(),
            FOAM_ROLL_BACK(),
            CHILDS_POSE(),
        ]),
        workout("Large Frame Functional Strength", "strength", 45, [
            GOBLET_SQUAT(3, 12, 60, "Dumbbell counterbalance helps large frames squat"),
            STEP_UP(3, 12, 45, "Per leg, lower box, joint-friendly"),
            DB_ROW(3, 10, 60, "Supported row, good for large chests"),
            GLUTE_BRIDGE(3, 15, 30, "Glute strength, lower back relief"),
            DEAD_BUG(3, 10, 30, "Core and lumbar stability"),
        ]),
        workout("Large Frame Low-Impact Cardio", "cardio", 35, [
            cardio_ex("Brisk Walk or Pool Walk", 1500, "25 min — water reduces joint load", "Bodyweight", "beginner"),
            LATERAL_BAND_WALK(3, 15, 30, "Hip abductor strength"),
            CLAMSHELL(3, 15, 30, "Per side"),
            stretch("Hip Flexor Stretch", 30, "Hips", "Hip Flexors",
                    "Hold 30 sec, both sides"),
        ]),
    ]


def _senior_strength():
    """Safe, progressive strength training for 60+ adults."""
    return [
        workout("Senior Strength A: Lower Body", "strength", 40, [
            ex("Chair Stand", 3, 10, 45, "Stand from chair fully, sit back slowly",
               "Bodyweight", "Legs", "Quadriceps",
               ["Glutes", "Hamstrings"], "beginner",
               "Arms crossed, stand fully, lower with control — builds functional independence", "Wall Sit"),
            GLUTE_BRIDGE(3, 15, 30, "Bodyweight, slow tempo"),
            STEP_UP(3, 10, 45, "Per leg, use railing if needed"),
            CALF_RAISE(3, 15, 30, "Hold wall for balance"),
            BIRD_DOG(3, 8, 30, "Per side, spinal stability"),
        ]),
        workout("Senior Strength B: Upper Body", "strength", 40, [
            DB_BENCH(3, 10, 60, "Light dumbbells, full ROM"),
            DB_ROW(3, 10, 60, "One arm, supported on bench"),
            DB_OHP(3, 10, 60, "Seated, light dumbbells"),
            BAND_PULL_APART(3, 15, 20, "Posture and shoulder health"),
            WALL_ANGEL(),
        ]),
        workout("Senior Balance & Core", "flexibility", 35, [
            TREE_POSE(),
            ex("Single-Leg Stand", 3, 1, 15, "Near wall for safety, 20 seconds each leg",
               "Bodyweight", "Legs", "Balance",
               ["Ankle Stabilisers", "Core"], "beginner",
               "Stand near wall, lift one foot, maintain balance, use wall if needed", "Tree Pose",
               duration_seconds=20),
            BIRD_DOG(3, 8, 30, "Per side"),
            DEAD_BUG(3, 8, 30, "Per side"),
            stretch("Seated Hip Stretch", 30, "Hips", "Hip Flexors",
                    "Seated figure-four, lean forward gently"),
            CHILDS_POSE(),
        ]),
    ]


###############################################################################
# BATCH WORKOUTS DICT
###############################################################################

BATCH_WORKOUTS = {
    # Women's Specific
    "Women's Strength Basics": _womens_strength_basics(),
    "Women's Self-Defense": _womens_self_defense(),
    "Low Impact Women's": _low_impact_womens(),
    "Kettlebell for Women": _kettlebell_for_women(),
    "Post-Baby Shred": _post_baby_shred(),
    "PCOS Workout Plan": _pcos_workout_plan(),
    "PMS Relief Movement": _pms_relief_movement(),
    "Breast Health & Posture": _breast_health_posture(),
    "Kegel & Pelvic Floor": _kegel_pelvic_floor(),
    "Fertility Support Fitness": _fertility_support_fitness(),

    # Men's Specific
    "Men's Core Strength": _mens_core_strength(),
    "Men's Flexibility Fix": _mens_flexibility_fix(),
    "Men's Hormone Optimization": _mens_hormone_optimization(),
    "Men's Posture Fix": _mens_posture_fix(),
    "Kegel for Men": _kegel_for_men(),
    "Low T Combat Workout": _low_t_combat_workout(),
    "Prostate Health Workout": _prostate_health_workout(),

    # GLP-1 / Medical
    "Ozempic-Safe Strength": _ozempic_safe_strength(),
    "Semaglutide Strength": _semaglutide_strength(),
    "GLP-1 Energy Builder": _glp1_energy_builder(),
    "GLP-1 Muscle Preservation": _glp1_muscle_preservation(),
    "Post-GLP-1 Maintenance": _post_glp1_maintenance(),
    "Weight Loss Drug Transition": _weight_loss_drug_transition(),
    "Tirzepatide Fitness Plan": _tirzepatide_fitness_plan(),
    "Metabolic Reset After Meds": _metabolic_reset_after_meds(),
    "Medication + Movement": _medication_and_movement(),

    # Longevity / Health
    "Longevity Fitness": _longevity_fitness(),
    "Anti-Aging Fitness": _anti_aging_fitness(),
    "Blue Zone Inspired": _blue_zone_inspired(),
    "Mitochondrial Health": _mitochondrial_health(),
    "Telomere-Friendly Fitness": _telomere_friendly_fitness(),
    "Autophagy-Promoting Exercise": _autophagy_promoting_exercise(),
    "Circadian Rhythm Training": _circadian_rhythm_training(),
    "Grip-to-Lifespan Training": _grip_to_lifespan_training(),
    "VO2 Max Longevity": _vo2_max_longevity(),
    "Brain Health Fitness": _brain_health_fitness(),
    "Bone Density Builder": _bone_density_builder(),
    "Hormone Balance Workout": _hormone_balance_workout(),

    # Body Type / Size
    "Plus Size Beginner": _plus_size_beginner(),
    "Plus Size Strength": _plus_size_strength(),
    "Short Person Optimization": _short_person_optimization(),
    "Tall Person Training": _tall_person_training(),
    "Large Frame Mobility": _large_frame_mobility(),
    "Senior Strength": _senior_strength(),
}
