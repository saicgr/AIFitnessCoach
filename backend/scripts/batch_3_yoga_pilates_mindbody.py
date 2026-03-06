#!/usr/bin/env python3
"""
Batch 3: Yoga, Pilates, Mind-Body, Dance, and Martial Arts programs.
55 programs total.
"""
from exercise_lib import *


###############################################################################
# YOGA (17 programs)
###############################################################################

def _yoga_beginners():
    """Yoga for Beginners - gentle intro, basic poses, longer holds."""
    return [
        workout("Gentle Foundation Flow", "flexibility", 40, [
            CAT_COW(),
            DOWNWARD_DOG(),
            STANDING_FORWARD_FOLD(),
            WARRIOR_I(),
            WARRIOR_II(),
            TREE_POSE(),
            COBRA(),
            BRIDGE_POSE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
        workout("Balance & Breath Flow", "flexibility", 35, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            WARRIOR_I(),
            TRIANGLE(),
            TREE_POSE(),
            CHAIR_POSE(),
            CHILDS_POSE(),
            SPHINX_POSE(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
        workout("Stretch & Restore", "flexibility", 30, [
            CAT_COW(),
            PUPPY_POSE(),
            CHILDS_POSE(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            BRIDGE_POSE(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _yoga_athletes():
    """Yoga for Athletes - dynamic poses, strength-focused."""
    return [
        workout("Power Flow", "flexibility", 45, [
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            WARRIOR_III(),
            HALF_MOON(),
            CHAIR_POSE(),
            EAGLE_POSE(),
            CROW_POSE(),
            BOAT_POSE(),
            CAMEL_POSE(),
            PIGEON_POSE(),
            SAVASANA(),
        ]),
        workout("Athlete Recovery", "flexibility", 40, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            PIGEON_POSE(),
            GARLAND_POSE(),
            STANDING_FORWARD_FOLD(),
            TRIANGLE(),
            SIDE_ANGLE(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _hatha_yoga():
    """Hatha Yoga - traditional sequence, longer holds."""
    return [
        workout("Hatha Standing Series", "flexibility", 50, [
            yoga_pose("Mountain Pose (Tadasana)", 30, "Stand tall, weight even, arms at sides, crown lifted", "Standing Meditation"),
            STANDING_FORWARD_FOLD(),
            WARRIOR_I(),
            WARRIOR_II(),
            TRIANGLE(),
            SIDE_ANGLE(),
            REVOLVED_TRIANGLE(),
            TREE_POSE(),
            HALF_MOON(),
            CHAIR_POSE(),
            STANDING_FORWARD_FOLD(),
            SAVASANA(),
        ]),
        workout("Hatha Floor Series", "flexibility", 50, [
            CAT_COW(),
            COBRA(),
            DOWNWARD_DOG(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            BOAT_POSE(),
            BRIDGE_POSE(),
            SHOULDER_STAND(),
            FISH_POSE(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _ashtanga_basics():
    """Ashtanga Basics - Sun Salutation series, flowing."""
    return [
        workout("Sun Salutation A Flow", "flow", 45, [
            yoga_pose("Mountain Pose (Tadasana)", 15, "Stand tall, engage legs, arms at sides", "Standing Meditation"),
            STANDING_FORWARD_FOLD(),
            yoga_pose("Halfway Lift (Ardha Uttanasana)", 10, "Flat back, hands on shins, look forward", "Standing Forward Fold"),
            yoga_pose("Chaturanga Dandasana", 10, "Lower halfway down, elbows at 90 degrees, body straight", "Knee Push-Up"),
            yoga_pose("Upward-Facing Dog (Urdhva Mukha Svanasana)", 15, "Tops of feet on floor, lift chest, straighten arms", "Cobra Pose"),
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            TRIANGLE(),
            STANDING_FORWARD_FOLD(),
            SEATED_FORWARD_FOLD(),
            SAVASANA(),
        ]),
        workout("Sun Salutation B Flow", "flow", 50, [
            CHAIR_POSE(),
            STANDING_FORWARD_FOLD(),
            yoga_pose("Chaturanga Dandasana", 10, "Elbows 90 degrees, plank to low push-up", "Knee Push-Up"),
            yoga_pose("Upward-Facing Dog", 15, "Press through hands, open chest", "Cobra Pose"),
            DOWNWARD_DOG(),
            WARRIOR_I(),
            WARRIOR_II(),
            SIDE_ANGLE(),
            REVOLVED_TRIANGLE(),
            BOAT_POSE(),
            BRIDGE_POSE(),
            SAVASANA(),
        ]),
    ]


def _hot_yoga_style():
    """Hot Yoga Style - Bikram-inspired 26-pose sequence, endurance."""
    return [
        workout("Hot Yoga Standing Series", "flexibility", 45, [
            yoga_pose("Standing Deep Breathing (Pranayama)", 60, "Arms overhead, interlace fingers, inhale-exhale deeply", "Deep Breathing"),
            HALF_MOON(),
            CHAIR_POSE(),
            EAGLE_POSE(),
            yoga_pose("Standing Head to Knee (Dandayamana Janushirasana)", 30, "Balance on one leg, extend other, fold forward", "Tree Pose"),
            yoga_pose("Standing Bow (Dandayamana Dhanurasana)", 30, "Kick back leg up while reaching forward", "Warrior III"),
            WARRIOR_III(),
            TRIANGLE(),
            STANDING_FORWARD_FOLD(),
            TREE_POSE(),
            SAVASANA(),
        ]),
        workout("Hot Yoga Floor Series", "flexibility", 45, [
            COBRA(),
            yoga_pose("Locust Pose (Salabhasana)", 20, "Lie prone, lift arms legs and chest off floor", "Superman"),
            yoga_pose("Full Locust", 20, "Arms overhead, lift everything, squeeze back", "Superman"),
            yoga_pose("Bow Pose (Dhanurasana)", 20, "Grab ankles, kick up and back, lift chest", "Cobra Pose"),
            CAMEL_POSE(),
            SEATED_FORWARD_FOLD(),
            BRIDGE_POSE(),
            RECLINED_TWIST(),
            yoga_pose("Blowing in Firm Pose (Kapalbhati)", 60, "Kneel, forceful exhales, passive inhales", "Breath of Fire"),
            SAVASANA(),
        ]),
    ]


def _yoga_flexibility():
    """Yoga for Flexibility - deep stretches, long holds."""
    return [
        workout("Deep Stretch Flow", "flexibility", 50, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            PIGEON_POSE(),
            yoga_pose("Lizard Pose (Utthan Pristhasana)", 45, "Low lunge, hands inside front foot, sink hips", "Low Lunge"),
            GARLAND_POSE(),
            STANDING_FORWARD_FOLD(),
            TRIANGLE(),
            SIDE_ANGLE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            SAVASANA(),
        ]),
        workout("Yin-Style Deep Hold", "flexibility", 50, [
            yoga_pose("Butterfly Pose (Baddha Konasana)", 60, "Soles together, knees out, fold forward gently", "Seated Straddle"),
            PIGEON_POSE(),
            yoga_pose("Dragon Pose", 60, "Deep low lunge, sink hips, breathe deeply", "Low Lunge"),
            SEATED_FORWARD_FOLD(),
            yoga_pose("Supine Spinal Twist", 60, "Lie back, knees to one side, relax into it", "Reclined Pigeon"),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _kundalini_awakening():
    """Kundalini Awakening - breath-focused, energetic movements."""
    return [
        workout("Kundalini Awakening Flow", "flow", 40, [
            yoga_pose("Breath of Fire", 60, "Rapid rhythmic breathing through nose, pump navel", "Deep Breathing"),
            CAT_COW(),
            yoga_pose("Kundalini Spinal Flex", 45, "Seated, flex spine forward and back with breath", "Cat-Cow"),
            yoga_pose("Sufi Grind", 30, "Seated, circle torso, grinding hips in circles", "Seated Twist"),
            yoga_pose("Ego Eradicator", 30, "Arms at 60 degrees, curl fingers, breath of fire", "Shoulder Stretch"),
            CAMEL_POSE(),
            COBRA(),
            CHILDS_POSE(),
            yoga_pose("Sat Kriya", 45, "Arms overhead, interlace, chant Sat Nam, pump navel", "Seated Meditation"),
            SAVASANA(),
        ]),
        workout("Energy Rising Kriya", "flow", 35, [
            yoga_pose("Long Deep Breathing", 60, "Seated, slow deep inhales and exhales", "Box Breathing"),
            yoga_pose("Kundalini Leg Lifts", 30, "Lie back, alternate lifting legs with breath", "Lying Leg Raise"),
            BRIDGE_POSE(),
            yoga_pose("Shoulder Shrug", 30, "Inhale shrug up, exhale drop, rapidly", "Shoulder Stretch"),
            yoga_pose("Neck Rolls", 30, "Slow neck circles, release tension", "Neck Stretch"),
            SEATED_FORWARD_FOLD(),
            yoga_pose("Meditation in Easy Pose", 120, "Cross-legged, spine tall, eyes closed, breathe", "Savasana"),
            SAVASANA(),
        ]),
    ]


def _aerial_yoga_prep():
    """Aerial Yoga Prep - upper body strength + inversions."""
    return [
        workout("Aerial Prep Strength", "flexibility", 40, [
            DOWNWARD_DOG(),
            yoga_pose("Dolphin Pose", 30, "Forearms down, hips up like downward dog on forearms", "Downward-Facing Dog"),
            PLANK(),
            CROW_POSE(),
            WARRIOR_III(),
            BOAT_POSE(),
            BRIDGE_POSE(),
            SHOULDER_STAND(),
            PLOUGH_POSE(),
            CHILDS_POSE(),
            SAVASANA(),
        ]),
        workout("Aerial Prep Flexibility", "flexibility", 40, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            PIGEON_POSE(),
            CAMEL_POSE(),
            HALF_MOON(),
            yoga_pose("Supported Headstand Prep", 30, "Interlace fingers, crown to floor, forearms support, lift knees", "Dolphin Pose"),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _yoga_nidra():
    """Yoga Nidra - guided relaxation, minimal movement."""
    return [
        workout("Yoga Nidra Session", "flexibility", 45, [
            yoga_pose("Body Scan Relaxation", 120, "Lie back, systematically relax each body part from toes to crown", "Savasana"),
            yoga_pose("Breath Awareness", 120, "Notice natural breath, no forcing, count exhales", "Deep Breathing"),
            yoga_pose("Visualization Practice", 120, "Imagine peaceful scene, engage all senses", "Meditation"),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            yoga_pose("Progressive Muscle Release", 120, "Tense then relax each muscle group systematically", "Body Scan"),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _chair_yoga():
    """Chair Yoga - all seated/supported variations."""
    return [
        workout("Seated Chair Flow", "flexibility", 30, [
            yoga_pose("Seated Cat-Cow", 30, "Sit tall, arch and round spine with breath", "Cat-Cow"),
            yoga_pose("Seated Twist", 30, "Sit tall, twist torso, hand on opposite knee", "Russian Twist"),
            yoga_pose("Seated Forward Fold", 30, "Sit at edge, fold forward over legs, let head hang", "Seated Forward Fold"),
            yoga_pose("Seated Side Bend", 30, "One arm overhead, lean to opposite side, breathe into ribs", "Side Stretch"),
            yoga_pose("Seated Eagle Arms", 30, "Wrap arms, lift elbows, squeeze shoulder blades", "Eagle Pose"),
            yoga_pose("Seated Warrior I", 30, "Turn to side of chair, front knee bent, arms overhead", "Warrior I"),
            yoga_pose("Seated Pigeon", 30, "Ankle on opposite knee, sit tall, gentle forward lean", "Pigeon Pose"),
            yoga_pose("Chair-Supported Tree", 30, "Stand behind chair, one foot on calf, hands on chair", "Tree Pose"),
            yoga_pose("Seated Neck Rolls", 30, "Gentle neck circles, release tension each direction", "Neck Stretch"),
            SAVASANA(),
        ]),
        workout("Standing Chair Support Flow", "flexibility", 30, [
            yoga_pose("Chair-Supported Warrior II", 30, "Side of chair, one leg back, arms wide", "Warrior II"),
            yoga_pose("Chair-Supported Triangle", 30, "Hand on chair seat, other arm up, legs wide", "Triangle Pose"),
            yoga_pose("Chair-Supported Half Moon", 30, "Hand on chair, lift back leg, other arm up", "Half Moon"),
            yoga_pose("Seated Hip Circles", 30, "Sit, circle hips slowly both directions", "Hip Circles"),
            yoga_pose("Chair-Supported Forward Fold", 30, "Stand behind chair, fold forward, hands on seat", "Standing Forward Fold"),
            yoga_pose("Chair Mountain Pose", 30, "Sit tall, feet flat, arms at sides, breathe", "Mountain Pose"),
            yoga_pose("Seated Shoulder Opener", 30, "Interlace hands behind back, lift and squeeze", "Shoulder Stretch"),
            yoga_pose("Chair Savasana", 120, "Sit back, close eyes, hands on thighs, relax completely", "Savasana"),
        ]),
    ]


def _wall_yoga():
    """Wall Yoga - wall-supported variations."""
    return [
        workout("Wall-Supported Flow", "flexibility", 35, [
            yoga_pose("Wall Downward Dog", 45, "Hands on wall at hip height, walk back, flat back", "Downward-Facing Dog"),
            yoga_pose("Wall Warrior I", 30, "Face wall, lunge position, hands on wall for balance", "Warrior I"),
            yoga_pose("Wall Warrior III", 30, "Hands on wall, hinge forward, lift back leg parallel", "Warrior III"),
            yoga_pose("Wall Triangle", 30, "Side to wall, use wall for alignment and support", "Triangle Pose"),
            yoga_pose("Wall Half Moon", 30, "Side to wall, hand on floor, back against wall for balance", "Half Moon"),
            LEGS_UP_WALL(),
            yoga_pose("Wall Shoulder Opener", 45, "Arm on wall, turn body away, open chest", "Doorway Stretch"),
            yoga_pose("Wall Squat Hold", 30, "Back to wall, slide to chair position, hold", "Wall Sit"),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _somatic_yoga():
    """Somatic Yoga - slow, internal awareness, minimal poses."""
    return [
        workout("Somatic Awareness Flow", "flexibility", 40, [
            yoga_pose("Constructive Rest Position", 60, "Lie back, feet flat, knees together, arms relaxed", "Savasana"),
            yoga_pose("Somatic Arch and Curl", 45, "Lie back, gently arch then flatten lower back with breath", "Cat-Cow"),
            yoga_pose("Somatic Side Bend", 45, "Lie on side, slowly lengthen and shorten torso", "Side Stretch"),
            CAT_COW(),
            yoga_pose("Somatic Hip Release", 45, "Lie back, slowly rock knees side to side, minimal effort", "Reclined Twist"),
            CHILDS_POSE(),
            yoga_pose("Somatic Shoulder Release", 45, "Lie back, arms out, slowly roll shoulders in small circles", "Shoulder Stretch"),
            HAPPY_BABY(),
            yoga_pose("Body Scan Integration", 120, "Lie still, scan from feet to head, notice sensations", "Savasana"),
            SAVASANA(),
        ]),
    ]


def _yoga_back_pain():
    """Yoga for Back Pain - spine-friendly poses."""
    return [
        workout("Gentle Back Relief", "flexibility", 35, [
            CAT_COW(),
            CHILDS_POSE(),
            COBRA(),
            SPHINX_POSE(),
            BRIDGE_POSE(),
            BIRD_DOG(),
            RECLINED_TWIST(),
            yoga_pose("Knees to Chest (Apanasana)", 30, "Lie back, hug knees to chest, rock gently", "Happy Baby"),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
        workout("Spinal Mobility Flow", "flexibility", 35, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            yoga_pose("Thread the Needle", 30, "On all fours, thread one arm under body, twist gently", "Seated Twist"),
            PUPPY_POSE(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            RECLINED_TWIST(),
            BRIDGE_POSE(),
            CHILDS_POSE(),
            SAVASANA(),
        ]),
    ]


def _yoga_neck_shoulders():
    """Yoga for Neck & Shoulders - upper body tension release."""
    return [
        workout("Neck & Shoulder Release", "flexibility", 30, [
            yoga_pose("Neck Rolls", 30, "Slow gentle circles, pause on tight spots", "Chin Tuck"),
            yoga_pose("Ear to Shoulder Stretch", 30, "Tilt head to side, opposite hand reaches down, hold", "Neck Stretch"),
            EAGLE_POSE(),
            yoga_pose("Thread the Needle", 30, "On all fours, thread arm under, rest shoulder on floor", "Seated Twist"),
            CAT_COW(),
            yoga_pose("Reverse Prayer Hands", 30, "Hands together behind back, open chest", "Shoulder Stretch"),
            yoga_pose("Cow Face Arms (Gomukhasana)", 30, "One arm over shoulder, other behind back, clasp", "Shoulder Stretch"),
            PUPPY_POSE(),
            CHILDS_POSE(),
            SAVASANA(),
        ]),
    ]


def _yoga_hips():
    """Yoga for Hips - hip openers and deep stretches."""
    return [
        workout("Hip Opener Flow", "flexibility", 40, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            yoga_pose("Lizard Pose", 45, "Low lunge, hands inside front foot, sink hips deep", "Low Lunge"),
            PIGEON_POSE(),
            GARLAND_POSE(),
            yoga_pose("Frog Pose (Mandukasana)", 45, "On all fours, widen knees, hips sink toward floor", "Garland Pose"),
            yoga_pose("Butterfly Pose (Baddha Konasana)", 45, "Soles together, knees out, fold forward gently", "Seated Straddle"),
            HIP_90_90(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
        workout("Deep Hip Release", "flexibility", 40, [
            CAT_COW(),
            yoga_pose("Fire Log Pose (Agnistambhasana)", 45, "Stack shins, one atop other, fold forward", "Seated Cross-Legged"),
            PIGEON_POSE(),
            GARLAND_POSE(),
            LOW_LUNGE(),
            WARRIOR_II(),
            SIDE_ANGLE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _yoga_runners():
    """Yoga for Runners - hip openers, hamstrings, IT band."""
    return [
        workout("Runner's Recovery Flow", "flexibility", 35, [
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            yoga_pose("Runner's Lunge Twist", 30, "Low lunge, twist toward front leg, arm up", "Low Lunge"),
            PIGEON_POSE(),
            STANDING_FORWARD_FOLD(),
            TRIANGLE(),
            GARLAND_POSE(),
            SEATED_FORWARD_FOLD(),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
        workout("Pre-Run Activation", "flexibility", 25, [
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            WARRIOR_I(),
            WARRIOR_II(),
            TRIANGLE(),
            CHAIR_POSE(),
            TREE_POSE(),
            STANDING_FORWARD_FOLD(),
            SAVASANA(),
        ]),
    ]


def _prenatal_yoga():
    """Prenatal Yoga - safe, gentle, modified poses."""
    return [
        workout("Prenatal Gentle Flow", "flexibility", 35, [
            CAT_COW(),
            yoga_pose("Wide-Leg Child's Pose", 45, "Knees wide to make room for belly, arms extended", "Child's Pose"),
            yoga_pose("Prenatal Warrior II", 30, "Wide stance, front knee bent, arms wide, open hips", "Warrior II"),
            TREE_POSE(),
            GARLAND_POSE(),
            yoga_pose("Side-Lying Savasana", 120, "Lie on left side, pillow between knees, relax", "Savasana"),
            yoga_pose("Seated Butterfly", 45, "Soles together, gentle forward lean, open hips", "Butterfly Pose"),
            BRIDGE_POSE(),
            RECLINED_TWIST(),
            yoga_pose("Prenatal Breathing", 60, "Seated, deep belly breaths, relax pelvic floor", "Deep Breathing"),
        ]),
        workout("Prenatal Strength & Stability", "flexibility", 30, [
            CAT_COW(),
            BIRD_DOG(),
            yoga_pose("Prenatal Goddess Squat", 30, "Wide stance, toes out, sink low, arms up", "Sumo Squat"),
            WARRIOR_I(),
            TRIANGLE(),
            BRIDGE_POSE(),
            CHILDS_POSE(),
            yoga_pose("Pelvic Floor Breathwork", 60, "Seated, engage and release pelvic floor with breath", "Deep Breathing"),
            yoga_pose("Side-Lying Relaxation", 120, "Left side, supported, full relaxation", "Savasana"),
        ]),
    ]


###############################################################################
# PILATES (8 programs)
###############################################################################

def _pilates_beginners():
    """Pilates for Beginners - basic mat work."""
    return [
        workout("Mat Pilates Intro", "flexibility", 30, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_LEG_CIRCLES(),
            PILATES_ROLLING_BALL(),
            PILATES_SINGLE_LEG_STRETCH(),
            PILATES_SPINE_STRETCH(),
            PILATES_SWAN(),
            PILATES_SEAL(),
        ]),
        workout("Core Foundations", "strength", 30, [
            PILATES_HUNDRED(),
            PILATES_DOUBLE_LEG_STRETCH(),
            PILATES_SCISSORS(),
            PILATES_SAW(),
            PILATES_SWIMMING(),
            PILATES_SIDE_KICK(),
            BRIDGE_POSE(),
            PILATES_SEAL(),
        ]),
    ]


def _pilates_core_intensive():
    """Pilates Core Intensive - advanced core."""
    return [
        workout("Core Power", "strength", 35, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_DOUBLE_LEG_STRETCH(),
            PILATES_SCISSORS(),
            PILATES_BICYCLE(),
            PILATES_TEASER(),
            PLANK(),
            SIDE_PLANK(),
            BOAT_POSE(),
        ]),
        workout("Deep Core Challenge", "strength", 35, [
            PILATES_HUNDRED(),
            PILATES_TEASER(),
            PILATES_BICYCLE(),
            DEAD_BUG(),
            HANGING_LEG_RAISE(3, 8, 60, "Controlled"),
            PILATES_SWIMMING(),
            PLANK(),
            RUSSIAN_TWIST(),
            PILATES_ROLL_UP(),
        ]),
    ]


def _pilates_reformer_style():
    """Pilates Reformer Style - mat exercises mimicking reformer moves."""
    return [
        workout("Reformer-Inspired Full Body", "strength", 40, [
            PILATES_HUNDRED(),
            ex("Footwork Series", 3, 10, 15, "Controlled tempo", "Bodyweight", "Legs",
               "Quadriceps", ["Calves", "Glutes"], "intermediate",
               "Lie back, press through feet as if on reformer carriage", "Wall Sit"),
            PILATES_LEG_CIRCLES(),
            PILATES_SINGLE_LEG_STRETCH(),
            PILATES_DOUBLE_LEG_STRETCH(),
            ex("Long Stretch Series", 2, 8, 20, "Plank variations", "Bodyweight", "Full Body",
               "Core", ["Shoulders", "Chest"], "intermediate",
               "Plank, pike hips up, return to plank, press back", "Plank"),
            PILATES_SIDE_KICK(),
            PILATES_SWIMMING(),
            PILATES_TEASER(),
        ]),
        workout("Reformer Arms & Back", "strength", 35, [
            ex("Pulling Straps (Mat)", 3, 10, 15, "Lie prone, arms back", "Bodyweight", "Back",
               "Rhomboids", ["Rear Deltoid", "Erector Spinae"], "beginner",
               "Lie face down, pull arms back and squeeze shoulder blades", "Superman"),
            PILATES_SWAN(),
            PUSHUP(3, 10, 45, "Slow Pilates tempo"),
            PILATES_ROLL_UP(),
            PILATES_SAW(),
            PILATES_SPINE_STRETCH(),
            PLANK(),
            PILATES_SEAL(),
        ]),
    ]


def _classical_pilates():
    """Classical Pilates - full Pilates order."""
    return [
        workout("Classical Mat Order A", "strength", 45, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_LEG_CIRCLES(),
            PILATES_ROLLING_BALL(),
            PILATES_SINGLE_LEG_STRETCH(),
            PILATES_DOUBLE_LEG_STRETCH(),
            PILATES_SCISSORS(),
            PILATES_BICYCLE(),
            PILATES_SPINE_STRETCH(),
            PILATES_SAW(),
        ]),
        workout("Classical Mat Order B", "strength", 45, [
            PILATES_SWAN(),
            PILATES_SINGLE_LEG_STRETCH(),
            PILATES_SIDE_KICK(),
            PILATES_TEASER(),
            PILATES_SWIMMING(),
            PILATES_LEG_CIRCLES(),
            ex("Hip Circles", 2, 8, 15, "Per direction", "Bodyweight", "Core",
               "Hip Flexors", ["Obliques", "Core"], "intermediate",
               "Seated, lean back, circle legs", "Bicycle Crunch"),
            PILATES_ROLL_UP(),
            PUSHUP(3, 8, 45, "Pilates push-up: roll down, walk out, push-up, walk back"),
            PILATES_SEAL(),
        ]),
    ]


def _wall_pilates():
    """Wall Pilates - wall-supported exercises."""
    return [
        workout("Wall Pilates Full Body", "strength", 30, [
            PILATES_WALL_SQUAT(),
            PILATES_WALL_PUSH(),
            PILATES_WALL_LEG_LIFT(),
            ex("Wall Roll-Down", 3, 8, 20, "Articulate spine", "Bodyweight", "Core",
               "Rectus Abdominis", ["Erector Spinae"], "beginner",
               "Stand against wall, roll down one vertebra at a time, roll back up", "Roll-Up"),
            ex("Wall Plank", 3, 1, 20, "Hold 30 seconds", "Bodyweight", "Core",
               "Core", ["Shoulders", "Chest"], "beginner",
               "Hands on wall, body angled, hold plank position", "Plank"),
            WALL_SIT(),
            ex("Wall Calf Raise", 3, 15, 20, "Wall for balance", "Bodyweight", "Legs",
               "Calves", ["Tibialis Anterior"], "beginner",
               "Face wall, hands on wall, rise up on toes", "Calf Raise"),
            PILATES_WALL_LEG_LIFT(),
        ]),
        workout("Wall Pilates Lower Body", "strength", 30, [
            PILATES_WALL_SQUAT(),
            ex("Wall Single-Leg Squat", 3, 8, 30, "Per leg", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes", "Core"], "intermediate",
               "Back to wall, one foot lifted, squat on standing leg", "Wall Sit"),
            PILATES_WALL_LEG_LIFT(),
            WALL_SIT(),
            ex("Wall Inner Thigh Squeeze", 3, 15, 20, "Ball between knees", "Bodyweight", "Legs",
               "Adductors", ["Core"], "beginner",
               "Back to wall, ball between knees, squeeze and hold", "Sumo Squat"),
            GLUTE_BRIDGE(),
            PILATES_WALL_PUSH(),
        ]),
    ]


def _pilates_seniors():
    """Pilates for Seniors - gentle, seated and supported."""
    return [
        workout("Gentle Senior Pilates", "flexibility", 25, [
            yoga_pose("Seated Breathing", 60, "Sit tall, deep belly breaths, expand ribs", "Deep Breathing"),
            ex("Seated Spine Twist", 2, 8, 15, "Per side", "Bodyweight", "Core",
               "Obliques", ["Spine"], "beginner",
               "Sit tall, rotate torso gently, hand on opposite knee", "Russian Twist"),
            PILATES_SPINE_STRETCH(),
            PILATES_LEG_CIRCLES(),
            PILATES_SINGLE_LEG_STRETCH(),
            BRIDGE_POSE(),
            PILATES_SWIMMING(),
            CHILDS_POSE(),
        ]),
        workout("Senior Core & Balance", "flexibility", 25, [
            BIRD_DOG(),
            DEAD_BUG(),
            PILATES_ROLLING_BALL(),
            PILATES_SAW(),
            PILATES_SIDE_KICK(),
            BRIDGE_POSE(),
            CAT_COW(),
            SAVASANA(),
        ]),
    ]


def _power_pilates():
    """Power Pilates - high-intensity Pilates with strength focus."""
    return [
        workout("Power Pilates Burn", "strength", 40, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_TEASER(),
            PILATES_BICYCLE(),
            PLANK(),
            PUSHUP(3, 12, 45, "Pilates tempo"),
            PILATES_SWIMMING(),
            SIDE_PLANK(),
            BURPEE(1, 8, 30, "Controlled, Pilates-style"),
            MOUNTAIN_CLIMBER(),
        ]),
        workout("Power Pilates Sculpt", "strength", 40, [
            PILATES_HUNDRED(),
            PILATES_DOUBLE_LEG_STRETCH(),
            PILATES_SCISSORS(),
            PILATES_TEASER(),
            ex("Pilates Push-Up Walk-Out", 3, 8, 30, "Full body", "Bodyweight", "Full Body",
               "Core", ["Chest", "Shoulders"], "intermediate",
               "Roll down, walk hands to plank, push-up, walk back, roll up", "Plank"),
            PILATES_SIDE_KICK(),
            PLANK(),
            JUMP_SQUAT(3, 8, 30, "Explosive"),
            PILATES_ROLL_UP(),
        ]),
    ]


def _pilates_stretch_fusion():
    """Pilates & Stretch Fusion - Pilates flow into deep stretching."""
    return [
        workout("Pilates Into Stretch", "flexibility", 40, [
            PILATES_HUNDRED(),
            PILATES_ROLL_UP(),
            PILATES_SINGLE_LEG_STRETCH(),
            PILATES_SPINE_STRETCH(),
            PILATES_SAW(),
            PIGEON_POSE(),
            SEATED_FORWARD_FOLD(),
            HAPPY_BABY(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
        workout("Stretch & Strengthen", "flexibility", 40, [
            CAT_COW(),
            PILATES_SWIMMING(),
            PILATES_SIDE_KICK(),
            BRIDGE_POSE(),
            PILATES_SWAN(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            PIGEON_POSE(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


###############################################################################
# MIND-BODY (14 programs)
###############################################################################

def _breathwork_basics():
    """Breathwork Basics - foundational breathing techniques."""
    return [
        workout("Breathing Foundations", "flow", 20, [
            yoga_pose("Diaphragmatic Breathing", 60, "Lie back, hand on belly, breathe into hand, belly rises", "Deep Breathing"),
            yoga_pose("4-7-8 Breathing", 60, "Inhale 4 counts, hold 7, exhale 8, repeat", "Box Breathing"),
            yoga_pose("Alternate Nostril Breathing", 60, "Close one nostril, inhale, switch, exhale, repeat", "Deep Breathing"),
            CAT_COW(),
            CHILDS_POSE(),
            yoga_pose("Ocean Breath (Ujjayi)", 60, "Slight throat constriction, audible breath, slow and steady", "Deep Breathing"),
            SEATED_FORWARD_FOLD(),
            SAVASANA(),
        ]),
    ]


def _mindful_movement():
    """Mindful Movement - slow, intentional movement with awareness."""
    return [
        workout("Mindful Movement Practice", "flow", 30, [
            yoga_pose("Standing Body Scan", 60, "Stand tall, scan body from feet to head, notice sensations", "Mountain Pose"),
            CAT_COW(),
            yoga_pose("Mindful Walking in Place", 60, "Slow deliberate steps, feel each phase of foot contact", "March in Place"),
            DOWNWARD_DOG(),
            WARRIOR_I(),
            TREE_POSE(),
            CHILDS_POSE(),
            SEATED_FORWARD_FOLD(),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _stress_relief_movement():
    """Stress Relief Movement - tension release and calming flow."""
    return [
        workout("Stress Relief Flow", "flexibility", 25, [
            yoga_pose("Tension Release Shaking", 60, "Stand, shake out hands, arms, legs, whole body", "Jumping Jacks"),
            yoga_pose("Shoulder Rolls", 30, "Roll shoulders forward then backward, release tension", "Shoulder Stretch"),
            CAT_COW(),
            CHILDS_POSE(),
            DOWNWARD_DOG(),
            STANDING_FORWARD_FOLD(),
            PIGEON_POSE(),
            RECLINED_TWIST(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _meditation_stretch():
    """Meditation + Stretch - seated meditation and gentle stretching."""
    return [
        workout("Meditate & Stretch", "flexibility", 25, [
            yoga_pose("Seated Meditation", 120, "Cross-legged, spine tall, eyes closed, focus on breath", "Savasana"),
            yoga_pose("Seated Neck Stretch", 30, "Tilt head side to side, chin to chest, gentle circles", "Neck Stretch"),
            yoga_pose("Seated Side Bend", 30, "One arm up and over, stretch side body", "Side Stretch"),
            CAT_COW(),
            CHILDS_POSE(),
            SEATED_FORWARD_FOLD(),
            PIGEON_POSE(),
            HAPPY_BABY(),
            SAVASANA(),
        ]),
    ]


def _qigong_basics():
    """Qigong Basics - slow flowing movements with breath."""
    return [
        workout("Qigong Flow", "flow", 30, [
            yoga_pose("Standing Meditation", 60, "Feet shoulder width, knees soft, palms face down, breathe", "Mountain Pose"),
            yoga_pose("Lifting the Sky", 30, "Interlace fingers, push palms up, stretch whole body", "Overhead Stretch"),
            yoga_pose("Parting the Wild Horse's Mane", 30, "Step and shift weight, arms open in arc", "Tai Chi Walk"),
            yoga_pose("Wave Hands Like Clouds", 30, "Shift weight side to side, arms float like clouds", "Standing Sway"),
            yoga_pose("Pushing Mountains", 30, "Push palms forward on exhale, draw back on inhale", "Wall Push-Up"),
            yoga_pose("Golden Rooster Stands on One Leg", 30, "Lift knee, opposite arm rises, balance", "Tree Pose"),
            yoga_pose("Closing Form", 60, "Hands to lower belly, palms stacked, deep breaths", "Standing Meditation"),
            SAVASANA(),
        ]),
    ]


def _box_breathing_training():
    """Box Breathing Training - structured breathing with movement."""
    return [
        workout("Box Breathing Session", "flow", 20, [
            yoga_pose("Box Breathing (4-4-4-4)", 120, "Inhale 4 counts, hold 4, exhale 4, hold 4, repeat", "Deep Breathing"),
            CAT_COW(),
            yoga_pose("Extended Box Breathing (6-6-6-6)", 120, "Inhale 6 counts, hold 6, exhale 6, hold 6", "Box Breathing"),
            CHILDS_POSE(),
            yoga_pose("Rhythmic Breathing Walk", 60, "Walk slowly, inhale 4 steps, exhale 4 steps", "Mindful Walking"),
            SEATED_FORWARD_FOLD(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _wim_hof_breathing():
    """Wim Hof Style Breathing - power breathing and cold prep."""
    return [
        workout("Wim Hof Breathing Protocol", "flow", 25, [
            yoga_pose("Power Breathing Round 1", 90, "30 deep breaths: full inhale, relaxed exhale, then hold after exhale", "Breath of Fire"),
            yoga_pose("Breath Hold Round 1", 60, "After 30 breaths, exhale and hold as long as comfortable", "Deep Breathing"),
            yoga_pose("Recovery Breath 1", 15, "Deep inhale, hold 15 seconds, release", "Deep Breathing"),
            yoga_pose("Power Breathing Round 2", 90, "30 deep breaths again, may feel tingling", "Breath of Fire"),
            yoga_pose("Breath Hold Round 2", 60, "Hold should be longer this round", "Deep Breathing"),
            yoga_pose("Recovery Breath 2", 15, "Deep inhale, hold 15 seconds", "Deep Breathing"),
            yoga_pose("Power Breathing Round 3", 90, "Final round of 30 breaths", "Breath of Fire"),
            yoga_pose("Breath Hold Round 3", 60, "Longest hold, stay relaxed", "Deep Breathing"),
            PUSHUP(1, 20, 0, "Optional: push-ups during breath hold"),
            SAVASANA(),
        ]),
    ]


def _anxiety_relief_movement():
    """Anxiety Relief Movement - grounding and calming exercises."""
    return [
        workout("Anxiety Relief Practice", "flexibility", 20, [
            yoga_pose("5-4-3-2-1 Grounding", 60, "Name 5 things you see, 4 feel, 3 hear, 2 smell, 1 taste", "Body Scan"),
            yoga_pose("Slow Diaphragmatic Breathing", 60, "Long slow breaths, exhale longer than inhale", "4-7-8 Breathing"),
            CAT_COW(),
            CHILDS_POSE(),
            yoga_pose("Butterfly Tapping", 30, "Cross arms on chest, alternate tapping shoulders gently", "Self-Hug"),
            STANDING_FORWARD_FOLD(),
            RECLINED_TWIST(),
            HAPPY_BABY(),
            LEGS_UP_WALL(),
            SAVASANA(),
        ]),
    ]


def _morning_mindfulness():
    """Morning Mindfulness - gentle wake-up flow with breath."""
    return [
        workout("Morning Mindful Flow", "flow", 20, [
            yoga_pose("Morning Gratitude Meditation", 60, "Seated, eyes closed, set intention for the day", "Seated Meditation"),
            CAT_COW(),
            DOWNWARD_DOG(),
            LOW_LUNGE(),
            WARRIOR_I(),
            TREE_POSE(),
            STANDING_FORWARD_FOLD(),
            yoga_pose("Sun Breath", 30, "Inhale arms overhead, exhale fold forward, repeat", "Standing Forward Fold"),
            SAVASANA(),
        ]),
    ]


def _body_scan_stretch():
    """Body Scan & Stretch - systematic body awareness with stretching."""
    return [
        workout("Body Scan & Stretch Session", "flexibility", 30, [
            yoga_pose("Foot & Ankle Scan", 30, "Circle ankles, point and flex, notice sensations", "Ankle Circles"),
            yoga_pose("Calf & Shin Stretch", 30, "Step back, press heel down, hold each side", "Calf Stretch"),
            yoga_pose("Quad & Hip Flexor Scan", 30, "Standing quad stretch, notice tension and release", "Quad Stretch"),
            LOW_LUNGE(),
            PIGEON_POSE(),
            yoga_pose("Torso Scan & Twist", 30, "Seated twist, notice where tension lives in core/back", "Seated Twist"),
            yoga_pose("Shoulder & Chest Scan", 30, "Open arms wide, squeeze back, notice upper body", "Doorway Stretch"),
            yoga_pose("Neck & Head Scan", 30, "Gentle neck rolls, notice jaw tension, soften face", "Neck Stretch"),
            RECLINED_TWIST(),
            SAVASANA(),
        ]),
    ]


def _meditation_movement():
    """Meditation & Movement - dynamic meditation through movement."""
    return [
        workout("Moving Meditation", "flow", 30, [
            yoga_pose("Walking Meditation", 120, "Ultra-slow walking, feel each micro-movement of feet", "Mindful Walking"),
            yoga_pose("Standing Sway", 60, "Feet rooted, gently sway like a tree in wind", "Standing Meditation"),
            CAT_COW(),
            DOWNWARD_DOG(),
            WARRIOR_II(),
            yoga_pose("Moving Breath Flow", 60, "Inhale arms up, exhale fold, inhale rise, repeat slowly", "Sun Salutation"),
            TREE_POSE(),
            CHILDS_POSE(),
            yoga_pose("Seated Stillness", 120, "Sit completely still, observe the body wanting to move", "Seated Meditation"),
            SAVASANA(),
        ]),
    ]


def _box_breathing_workout():
    """Box Breathing Workout - breath-focused with light movement."""
    return [
        workout("Box Breathing + Movement", "flow", 25, [
            yoga_pose("Warm-Up Box Breathing", 90, "4-4-4-4 box breathing seated, establish rhythm", "Deep Breathing"),
            CAT_COW(),
            yoga_pose("Box Breath Walking", 60, "Walk slowly: inhale 4 steps, hold 4, exhale 4, hold 4", "Mindful Walking"),
            DOWNWARD_DOG(),
            WARRIOR_I(),
            yoga_pose("Extended Box (5-5-5-5)", 90, "Progress to 5-count box breathing", "Box Breathing"),
            CHILDS_POSE(),
            STANDING_FORWARD_FOLD(),
            SAVASANA(),
        ]),
    ]


def _nervous_system_reset():
    """Nervous System Reset - vagal toning and regulation."""
    return [
        workout("Nervous System Reset", "flexibility", 25, [
            yoga_pose("Extended Exhale Breathing", 60, "Inhale 4, exhale 8, activate parasympathetic", "4-7-8 Breathing"),
            yoga_pose("Humming Bee Breath (Bhramari)", 60, "Cover ears, hum on exhale, feel vibration", "Deep Breathing"),
            yoga_pose("Cold Water Face Splash", 30, "Splash cold water on face to trigger dive reflex", "Deep Breathing"),
            CAT_COW(),
            CHILDS_POSE(),
            yoga_pose("Gentle Rocking", 45, "Lie on back, hug knees, rock side to side gently", "Happy Baby"),
            RECLINED_TWIST(),
            LEGS_UP_WALL(),
            yoga_pose("Progressive Muscle Relaxation", 120, "Tense each muscle 5 seconds, release, scan body", "Body Scan"),
            SAVASANA(),
        ]),
    ]


def _mindful_strength():
    """Mindful Strength - slow, intentional strength with body awareness."""
    return [
        workout("Mindful Strength Session", "strength", 35, [
            yoga_pose("Intention Setting", 60, "Stand tall, set mindful intention, body awareness scan", "Standing Meditation"),
            BODYWEIGHT_SQUAT(3, 10, 45, "5-second down, 5-second up, full awareness"),
            PUSHUP(3, 8, 60, "4-second down, pause at bottom, 4-second up"),
            PLANK(),
            GLUTE_BRIDGE(),
            BIRD_DOG(),
            DEAD_BUG(),
            WARRIOR_III(),
            CHILDS_POSE(),
            SAVASANA(),
        ]),
    ]


###############################################################################
# DANCE (6 programs)
###############################################################################

def _african_dance():
    """African Dance Workout - high energy rhythmic movement."""
    return [
        workout("African Dance Cardio", "cardio", 40, [
            cardio_ex("African Dance Warm-Up", 60, "March in place with arm swings, feel the rhythm"),
            cardio_ex("Djembe Step", 60, "Step-touch side to side with arm claps, bounce with knees"),
            cardio_ex("African Jump Stomp", 45, "Alternate foot stomps with arms pushing down"),
            cardio_ex("Hip Isolation Circles", 45, "Circle hips in wide arcs, both directions"),
            cardio_ex("Gumboot Kicks", 60, "Kick forward alternating legs, slap boots/shins"),
            cardio_ex("Tribal Arm Waves", 45, "Flowing arm movements overhead and to sides with steps"),
            cardio_ex("Harvest Dance", 60, "Bent-knee bouncing with reaching arms, gathering motion"),
            cardio_ex("West African Shimmy", 45, "Rapid shoulder shimmy with side-step travel"),
            cardio_ex("Celebration Dance", 60, "High knees with overhead clapping, joyful energy"),
            STANDING_FORWARD_FOLD(),
        ]),
    ]


def _contemporary_dance():
    """Contemporary Dance Fitness - fluid, expressive movement."""
    return [
        workout("Contemporary Dance Flow", "cardio", 40, [
            cardio_ex("Plié Warm-Up", 60, "Deep pliés in first and second position with arm flow"),
            cardio_ex("Floor Roll Series", 60, "Roll down to floor and back up using core control"),
            cardio_ex("Reach and Release", 45, "Reach arms high, release and fold, repeat with travel"),
            cardio_ex("Spiral Turn", 45, "Turn through center with arms spiraling"),
            cardio_ex("Contraction and Release", 60, "Graham-style contractions with forward and back motion"),
            cardio_ex("Leap Prep Chassé", 45, "Step-together-step traveling across floor"),
            cardio_ex("Floor Work Sequence", 60, "Fluid transitions between lying, sitting, and standing"),
            cardio_ex("Improvisation Flow", 60, "Free movement, respond to breath and impulse"),
            STANDING_FORWARD_FOLD(),
            CHILDS_POSE(),
        ]),
    ]


def _ballet_fitness():
    """Ballet Fitness - barre-inspired toning and cardio."""
    return [
        workout("Ballet Barre Workout", "cardio", 40, [
            cardio_ex("Plié Series", 60, "First position pliés, second position grand pliés"),
            cardio_ex("Tendu and Dégagé", 60, "Point and extend foot front, side, back from standing"),
            cardio_ex("Relevé Pulses", 45, "Rise to ball of foot, pulse small at top"),
            cardio_ex("Arabesque Lifts", 45, "One leg back, lift and hold, control lowering"),
            cardio_ex("Port de Bras", 30, "Flowing arm positions: first through fifth"),
            cardio_ex("Sauté Jumps", 45, "Small jumps in first position, point toes in air"),
            ex("Ballet Lunge Pulses", 3, 15, 30, "Per side", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes", "Calves"], "beginner",
               "Deep lunge position, pulse low, maintain turnout", "Reverse Lunge"),
            cardio_ex("Grand Battement", 45, "Standing kicks: front, side, back, controlled"),
            cardio_ex("Reverence Stretch", 60, "Classical bow with deep stretch cool-down"),
        ]),
    ]


def _belly_dance():
    """Belly Dance Fitness - core-focused isolation work."""
    return [
        workout("Belly Dance Sculpt", "cardio", 35, [
            cardio_ex("Belly Dance Shimmy", 60, "Rapid alternating knee bends creating hip shimmy"),
            cardio_ex("Hip Drop and Lift", 60, "Isolate one hip, drop and lift sharply"),
            cardio_ex("Figure-8 Hips", 60, "Draw horizontal and vertical figure-8s with hips"),
            cardio_ex("Chest Circles", 45, "Isolate ribcage, circle in both directions"),
            cardio_ex("Undulation", 45, "Wave motion from chest through belly to hips"),
            cardio_ex("Snake Arms", 45, "Flowing wave motion through arms, one at a time"),
            cardio_ex("Turkish Drop", 45, "Deep backbend with controlled descent"),
            cardio_ex("Zar Spin", 60, "Spinning with arms wide, controlled dizziness"),
            STANDING_FORWARD_FOLD(),
        ]),
    ]


def _zumba_style():
    """Zumba Style - Latin dance-inspired cardio party."""
    return [
        workout("Zumba Dance Party", "cardio", 45, [
            cardio_ex("Salsa Basic Step", 60, "Forward-back salsa step with hip motion"),
            cardio_ex("Merengue March", 60, "Marching with hip sway, arms pumping"),
            cardio_ex("Reggaeton Bounce", 60, "Low bounce with attitude, arm movements"),
            cardio_ex("Cumbia Step", 60, "Side-step with diagonal arm reach"),
            cardio_ex("Bachata Side-Step", 60, "Three steps to side with hip pop"),
            cardio_ex("Samba Bounce", 60, "Bouncing knees with Brazilian samba footwork"),
            cardio_ex("Flamenco Arms", 45, "Dramatic overhead arm circles with stomping"),
            cardio_ex("Belly Roll Combo", 45, "Belly dance isolation with Latin steps"),
            HIGH_KNEES(1, 30, 15, "30 seconds: final burst"),
            STANDING_FORWARD_FOLD(),
        ]),
    ]


def _dance_beginners():
    """Dance for Beginners - simple moves, building rhythm."""
    return [
        workout("Beginner Dance Cardio", "cardio", 30, [
            cardio_ex("March in Place", 60, "March with arm swings, find your rhythm"),
            cardio_ex("Side Step Touch", 60, "Step right, tap left, step left, tap right, add arms"),
            cardio_ex("Grapevine", 60, "Step behind, step out, step front, tap, repeat other side"),
            cardio_ex("Box Step", 60, "Step forward-together-forward, back-together-back"),
            cardio_ex("Hip Sway", 45, "Shift weight side to side, let hips follow naturally"),
            cardio_ex("Arm Groove", 45, "Punch up, wave side, roll arms, simple patterns"),
            cardio_ex("Two-Step", 60, "Quick-quick-slow step pattern, add music feel"),
            cardio_ex("Freestyle Combo", 60, "Combine all moves in a simple sequence"),
            STANDING_FORWARD_FOLD(),
            SAVASANA(),
        ]),
    ]


###############################################################################
# MARTIAL ARTS (10 programs)
###############################################################################

def _tai_chi_basics():
    """Tai Chi Basics - slow, meditative movements."""
    return [
        workout("Tai Chi Foundation", "flow", 35, [
            yoga_pose("Tai Chi Opening Form", 60, "Feet shoulder width, slowly raise and lower arms, breathe", "Standing Meditation"),
            yoga_pose("Grasp the Sparrow's Tail", 45, "Ward off, roll back, press, push sequence", "Standing Sway"),
            yoga_pose("Wave Hands Like Clouds", 45, "Shift weight, hands float side to side at chest height", "Standing Sway"),
            yoga_pose("White Crane Spreads Wings", 30, "One hand high, one low, balance on one leg slightly", "Tree Pose"),
            yoga_pose("Brush Knee and Twist Step", 30, "Step forward, brush knee with hand, push with other", "Walking Lunge"),
            yoga_pose("Parting the Wild Horse's Mane", 30, "Step and separate hands, one up one down", "Low Lunge"),
            yoga_pose("Repulse the Monkey", 30, "Step back while pushing forward with palm", "Reverse Lunge"),
            yoga_pose("Single Whip", 30, "Hook hand behind, push palm forward, wide stance", "Warrior II"),
            yoga_pose("Tai Chi Closing Form", 60, "Bring hands to lower belly, stand still, breathe", "Standing Meditation"),
        ]),
    ]


def _tai_chi_seniors():
    """Tai Chi for Seniors - simplified, balance-focused."""
    return [
        workout("Senior Tai Chi Flow", "flow", 30, [
            yoga_pose("Standing Centering", 60, "Feet wide, knees soft, breathe deeply, find center", "Standing Meditation"),
            yoga_pose("Arm Raises with Breath", 30, "Inhale arms float up, exhale float down, slow", "Deep Breathing"),
            yoga_pose("Weight Shift Side to Side", 30, "Shift weight gently left and right, arms follow", "Standing Sway"),
            yoga_pose("Simplified Grasp Sparrow's Tail", 30, "Gentle push and pull motion with weight shift", "Standing Sway"),
            yoga_pose("Cloud Hands Simplified", 30, "Small hand circles at chest, weight shift", "Standing Sway"),
            yoga_pose("Heel-Toe Rock", 30, "Rock weight from heels to toes, arms balance", "Calf Raise"),
            yoga_pose("Gentle Twist", 30, "Arms swing naturally as torso twists side to side", "Standing Twist"),
            yoga_pose("Closing Meditation", 60, "Hands on lower belly, breathe, feel energy settle", "Standing Meditation"),
        ]),
    ]


def _karate_conditioning():
    """Karate Conditioning - strikes, stances, and conditioning."""
    return [
        workout("Karate Conditioning", "conditioning", 40, [
            cardio_ex("Karate Warm-Up Jog", 60, "Light jog in place with arm circles"),
            ex("Front Punch (Oi-Zuki)", 3, 20, 20, "Alternate hands", "Bodyweight", "Arms",
               "Shoulders", ["Triceps", "Core"], "beginner",
               "From guard, rotate hip and extend fist, snap back", "Jab-Cross"),
            ex("Front Kick (Mae Geri)", 3, 12, 20, "Per leg", "Bodyweight", "Legs",
               "Hip Flexors", ["Quadriceps", "Core"], "beginner",
               "Lift knee, snap kick forward, chamber back", "High Knees"),
            ex("Horse Stance Hold (Kiba Dachi)", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs",
               "Quadriceps", ["Adductors", "Core"], "beginner",
               "Wide stance, knees out, thighs parallel, fists at hips", "Wall Sit"),
            ex("Reverse Punch (Gyaku-Zuki)", 3, 20, 20, "Alternate sides", "Bodyweight", "Arms",
               "Core", ["Shoulders", "Hips"], "beginner",
               "Opposite hand to front leg punches, rotate hips", "Cross Punch"),
            ex("Roundhouse Kick (Mawashi Geri)", 3, 10, 25, "Per leg", "Bodyweight", "Legs",
               "Hip Flexors", ["Quadriceps", "Obliques"], "intermediate",
               "Pivot on standing foot, chamber knee, snap kick", "Side Kick"),
            PUSHUP(3, 15, 45, "Karate push-ups on knuckles"),
            BODYWEIGHT_SQUAT(3, 20, 30, "Fast pace"),
            PLANK(),
        ]),
    ]


def _taekwondo_basics():
    """Taekwondo Basics - kicking-focused conditioning."""
    return [
        workout("Taekwondo Kick Training", "conditioning", 40, [
            HIGH_KNEES(1, 30, 15, "Dynamic warm-up"),
            ex("Front Snap Kick (Ap Chagi)", 3, 12, 20, "Per leg", "Bodyweight", "Legs",
               "Quadriceps", ["Hip Flexors", "Core"], "beginner",
               "Lift knee high, snap foot forward, chamber back fast", "Front Kick"),
            ex("Roundhouse Kick (Dollyo Chagi)", 3, 10, 25, "Per leg", "Bodyweight", "Legs",
               "Hip Flexors", ["Obliques", "Quadriceps"], "intermediate",
               "Pivot, chamber knee, extend kick, snap back", "Side Kick"),
            ex("Side Kick (Yeop Chagi)", 3, 10, 25, "Per leg", "Bodyweight", "Legs",
               "Gluteus Medius", ["Quadriceps", "Obliques"], "intermediate",
               "Chamber knee across body, thrust foot sideways, blade of foot", "Lateral Leg Raise"),
            ex("Back Kick (Dwit Chagi)", 3, 8, 30, "Per leg", "Bodyweight", "Legs",
               "Glutes", ["Hamstrings", "Core"], "intermediate",
               "Turn away, look over shoulder, thrust heel back", "Donkey Kick"),
            JUMP_SQUAT(3, 10, 30, "Explosive for kicking power"),
            BODYWEIGHT_SQUAT(3, 15, 30, "Deep squat for stance work"),
            PLANK(),
            STANDING_FORWARD_FOLD(),
        ]),
    ]


def _capoeira_fundamentals():
    """Capoeira Fundamentals - acrobatic martial art dance."""
    return [
        workout("Capoeira Movement", "conditioning", 45, [
            cardio_ex("Ginga", 60, "Basic rocking step: step back, shift weight, arms guard"),
            ex("Queixada (Outside Crescent Kick)", 3, 10, 20, "Per side", "Bodyweight", "Legs",
               "Hip Flexors", ["Adductors", "Core"], "intermediate",
               "Swing leg in an arc from inside to outside", "Roundhouse Kick"),
            ex("Meia Lua de Frente (Front Half Moon)", 3, 10, 20, "Per side", "Bodyweight", "Legs",
               "Hip Flexors", ["Obliques", "Core"], "intermediate",
               "Standing crescent kick from outside to inside", "Crescent Kick"),
            ex("Cocorinha (Crouch Dodge)", 3, 12, 15, "Bodyweight", "Bodyweight", "Legs",
               "Quadriceps", ["Core", "Balance"], "beginner",
               "Drop to deep squat with one hand protecting face", "Bodyweight Squat"),
            ex("Negativa", 3, 8, 20, "Per side", "Bodyweight", "Full Body",
               "Core", ["Triceps", "Hip Flexors"], "intermediate",
               "Sit low, one leg extended, one arm supporting, other guards", "Side Plank"),
            ex("Aú (Cartwheel)", 3, 6, 30, "Controlled", "Bodyweight", "Full Body",
               "Shoulders", ["Core", "Arms"], "intermediate",
               "Hands down one at a time, legs over in cartwheel", "Handstand Kick-Up"),
            PUSHUP(3, 15, 45, "Capoeira push-ups"),
            BODYWEIGHT_SQUAT(3, 20, 30, "Deep squat for ginga"),
            BRIDGE_POSE(),
        ]),
    ]


def _aikido_movement():
    """Aikido Movement - redirecting energy, rolling, and flow."""
    return [
        workout("Aikido Movement Practice", "flow", 35, [
            yoga_pose("Seiza Meditation", 60, "Kneel sitting on heels, spine tall, breathe", "Seated Meditation"),
            ex("Tenkan (Turning Movement)", 3, 10, 15, "Per side", "Bodyweight", "Full Body",
               "Core", ["Hips", "Balance"], "beginner",
               "Pivot 180 degrees on front foot, maintain center", "Standing Twist"),
            ex("Irimi (Entering Step)", 3, 10, 15, "Per side", "Bodyweight", "Full Body",
               "Core", ["Legs", "Balance"], "beginner",
               "Step forward at an angle, blend with partner's energy", "Walking Lunge"),
            ex("Forward Roll (Mae Ukemi)", 3, 6, 20, "Controlled rolling", "Bodyweight", "Full Body",
               "Core", ["Shoulders", "Back"], "intermediate",
               "Tuck chin, round back, roll diagonally over shoulder", "Somersault"),
            ex("Backward Roll (Ushiro Ukemi)", 3, 6, 20, "Controlled", "Bodyweight", "Full Body",
               "Core", ["Back", "Shoulders"], "intermediate",
               "Sit back, round spine, roll over shoulder, stand", "Back Extension"),
            yoga_pose("Aikido Stretching Series", 45, "Wrist stretches, shoulder stretches, hip openers", "Wrist Circles"),
            ex("Shikko (Knee Walking)", 2, 10, 15, "Steps across mat", "Bodyweight", "Full Body",
               "Hip Flexors", ["Core", "Quadriceps"], "beginner",
               "Walk on knees maintaining upright posture and center", "Walking Lunge"),
            SAVASANA(),
        ]),
    ]


def _muay_thai_conditioning():
    """Muay Thai Conditioning - 8 limbs striking with fitness."""
    return [
        workout("Muay Thai Conditioning", "conditioning", 45, [
            JUMP_ROPE(1, 1, 30, "3 minutes warm-up"),
            ex("Jab-Cross Combo", 3, 20, 20, "Per combo", "Bodyweight", "Arms",
               "Shoulders", ["Triceps", "Core"], "beginner",
               "Lead hand jab, rear hand cross, rotate hips", "Punching Bag"),
            ex("Muay Thai Roundhouse Kick", 3, 10, 25, "Per leg", "Bodyweight", "Legs",
               "Hip Flexors", ["Obliques", "Calves"], "intermediate",
               "Step at 45 degrees, rotate hip over, shin makes contact", "Roundhouse Kick"),
            ex("Teep (Push Kick)", 3, 10, 20, "Per leg", "Bodyweight", "Legs",
               "Hip Flexors", ["Quadriceps", "Core"], "beginner",
               "Lift knee, push foot forward to target's midsection", "Front Kick"),
            ex("Knee Strike", 3, 12, 20, "Per leg", "Bodyweight", "Full Body",
               "Hip Flexors", ["Core", "Glutes"], "beginner",
               "Pull guard down, drive knee up explosively", "High Knees"),
            ex("Elbow Strike Combo", 3, 12, 20, "Per side", "Bodyweight", "Arms",
               "Core", ["Shoulders", "Biceps"], "beginner",
               "Horizontal, upward, and downward elbow strikes", "Punch"),
            BURPEE(1, 10, 30, "Fight conditioning"),
            PLANK(),
            BODYWEIGHT_SQUAT(3, 20, 30, "Deep for clinch work"),
        ]),
    ]


def _wing_chun_basics():
    """Wing Chun Basics - close-range techniques and sensitivity."""
    return [
        workout("Wing Chun Training", "conditioning", 35, [
            ex("Siu Nim Tao Form Practice", 1, 1, 30, "Slow, deliberate", "Bodyweight", "Full Body",
               "Forearms", ["Core", "Shoulders"], "beginner",
               "First form: tan sau, pak sau, bong sau, fook sau slowly", "Standing Form"),
            ex("Chain Punches (Lin Wan Kuen)", 3, 30, 20, "Rapid straight punches", "Bodyweight", "Arms",
               "Triceps", ["Shoulders", "Core"], "beginner",
               "Vertical fist, rapid alternating punches along centerline", "Jab-Cross"),
            ex("Tan Sau Drill", 3, 15, 15, "Per side", "Bodyweight", "Arms",
               "Forearms", ["Shoulders", "Core"], "beginner",
               "Palm-up deflection, redirect incoming force outward", "Block Drill"),
            ex("Pak Sau Drill", 3, 15, 15, "Per side", "Bodyweight", "Arms",
               "Forearms", ["Core"], "beginner",
               "Slapping block to the side, quick and snappy", "Block Drill"),
            ex("Wing Chun Stance (Yee Gee Kim Yeung Ma)", 3, 1, 20, "Hold 30 seconds", "Bodyweight", "Legs",
               "Adductors", ["Quadriceps", "Core"], "beginner",
               "Pigeon-toed stance, knees in, weight centered, slight sit", "Horse Stance"),
            WALL_SIT(),
            PUSHUP(3, 12, 45, "Slow and controlled"),
            PLANK(),
        ]),
    ]


def _kushti_wrestling():
    """Kushti Wrestling Fitness - traditional Indian wrestling exercises."""
    return [
        workout("Kushti Wrestling Conditioning", "conditioning", 45, [
            ex("Hindu Squat (Baithak)", 3, 30, 30, "Traditional", "Bodyweight", "Legs",
               "Quadriceps", ["Glutes", "Calves", "Core"], "intermediate",
               "Heels rise, arms swing, squat deep, continuous flow", "Bodyweight Squat"),
            ex("Hindu Push-Up (Dand)", 3, 15, 30, "Flow movement", "Bodyweight", "Full Body",
               "Chest", ["Shoulders", "Triceps", "Core", "Hip Flexors"], "intermediate",
               "Dive from downward dog through low push-up to upward dog", "Pike Push-Up"),
            ex("Rope Climbing", 3, 3, 60, "Climb and descend", "Bodyweight", "Back",
               "Latissimus Dorsi", ["Biceps", "Grip", "Core"], "advanced",
               "Grip rope, pull body up using arms and legs", "Pull-Up"),
            ex("Wrestler Bridge", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Full Body",
               "Neck", ["Glutes", "Erector Spinae"], "intermediate",
               "Bridge on head and feet, strengthen neck and back", "Bridge Pose"),
            BURPEE(1, 10, 30, "Wrestler conditioning"),
            MOUNTAIN_CLIMBER(),
            PLANK(),
            BODYWEIGHT_SQUAT(3, 20, 30, "Fast pace"),
        ]),
    ]


def _mallakhamb_training():
    """Mallakhamb Training - Indian pole gymnastics conditioning."""
    return [
        workout("Mallakhamb Prep Conditioning", "conditioning", 40, [
            PULLUP(3, 8, 90, "Build grip and pull strength"),
            ex("Hanging Leg Raise", 3, 10, 60, "Core strength for pole work", "Bodyweight", "Core",
               "Lower Abs", ["Hip Flexors", "Obliques"], "intermediate",
               "Dead hang, raise legs to parallel or above, controlled", "Lying Leg Raise"),
            ex("L-Sit Hold", 3, 1, 45, "Hold 15-20 seconds", "Bodyweight", "Core",
               "Hip Flexors", ["Rectus Abdominis", "Quadriceps"], "advanced",
               "On parallel bars or floor, lift legs to L position, hold", "Boat Pose"),
            PUSHUP(3, 15, 45, "Full range of motion"),
            PIKE_PUSHUP(3, 8, 60, "Shoulder strength for inversions"),
            ex("Skin the Cat", 3, 5, 60, "Controlled rotation", "Bodyweight", "Full Body",
               "Shoulders", ["Lats", "Core"], "advanced",
               "Hang, tuck knees, rotate body backward under bar, return", "Pull-Up"),
            PLANK(),
            BODYWEIGHT_SQUAT(3, 20, 30, "Leg conditioning"),
            BRIDGE_POSE(),
        ]),
    ]


###############################################################################
# BATCH_WORKOUTS mapping
###############################################################################

BATCH_WORKOUTS = {
    # Yoga (17)
    "Yoga for Beginners": _yoga_beginners,
    "Yoga for Athletes": _yoga_athletes,
    "Hatha Yoga": _hatha_yoga,
    "Ashtanga Basics": _ashtanga_basics,
    "Hot Yoga Style": _hot_yoga_style,
    "Yoga for Flexibility": _yoga_flexibility,
    "Kundalini Awakening": _kundalini_awakening,
    "Aerial Yoga Prep": _aerial_yoga_prep,
    "Yoga Nidra": _yoga_nidra,
    "Chair Yoga": _chair_yoga,
    "Wall Yoga": _wall_yoga,
    "Somatic Yoga": _somatic_yoga,
    "Yoga for Back Pain": _yoga_back_pain,
    "Yoga for Neck & Shoulders": _yoga_neck_shoulders,
    "Yoga for Hips": _yoga_hips,
    "Yoga for Runners": _yoga_runners,
    "Prenatal Yoga": _prenatal_yoga,
    # Pilates (8)
    "Pilates for Beginners": _pilates_beginners,
    "Pilates Core Intensive": _pilates_core_intensive,
    "Pilates Reformer Style": _pilates_reformer_style,
    "Classical Pilates": _classical_pilates,
    "Wall Pilates": _wall_pilates,
    "Pilates for Seniors": _pilates_seniors,
    "Power Pilates": _power_pilates,
    "Pilates & Stretch Fusion": _pilates_stretch_fusion,
    # Mind-Body (14)
    "Breathwork Basics": _breathwork_basics,
    "Mindful Movement": _mindful_movement,
    "Stress Relief Movement": _stress_relief_movement,
    "Meditation + Stretch": _meditation_stretch,
    "Qigong Basics": _qigong_basics,
    "Box Breathing Training": _box_breathing_training,
    "Wim Hof Style Breathing": _wim_hof_breathing,
    "Anxiety Relief Movement": _anxiety_relief_movement,
    "Morning Mindfulness": _morning_mindfulness,
    "Body Scan & Stretch": _body_scan_stretch,
    "Meditation & Movement": _meditation_movement,
    "Box Breathing Workout": _box_breathing_workout,
    "Nervous System Reset": _nervous_system_reset,
    "Mindful Strength": _mindful_strength,
    # Dance (6)
    "African Dance Workout": _african_dance,
    "Contemporary Dance Fitness": _contemporary_dance,
    "Ballet Fitness": _ballet_fitness,
    "Belly Dance Fitness": _belly_dance,
    "Zumba Style": _zumba_style,
    "Dance for Beginners": _dance_beginners,
    # Martial Arts (10)
    "Tai Chi Basics": _tai_chi_basics,
    "Tai Chi for Seniors": _tai_chi_seniors,
    "Karate Conditioning": _karate_conditioning,
    "Taekwondo Basics": _taekwondo_basics,
    "Capoeira Fundamentals": _capoeira_fundamentals,
    "Aikido Movement": _aikido_movement,
    "Muay Thai Conditioning": _muay_thai_conditioning,
    "Wing Chun Basics": _wing_chun_basics,
    "Kushti Wrestling Fitness": _kushti_wrestling,
    "Mallakhamb Training": _mallakhamb_training,
}
