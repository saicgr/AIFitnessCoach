"""Service for generating warm-up and cool-down exercises with SCD2 versioning.

Updated to use dictionary-based algorithm instead of Gemini for instant generation.
Performance improvement: 3-5s -> <10ms
"""
from .warmup_stretch_service_helpers import (  # noqa: F401
    WarmupStretchService,
    get_warmup_stretch_service,
)

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from core.config import get_settings
from core.supabase_client import get_supabase
from core.logger import get_logger
from services.warmup_stretch_algorithm import get_warmup_stretch_algorithm

logger = get_logger(__name__)
settings = get_settings()

# Movement type classification for warmup ordering
# Static holds should come EARLY, followed by dynamic movements
# This addresses user feedback: "warm-ups should have static holds early, not intermixed with kinetic moves"
STATIC_EXERCISE_KEYWORDS = [
    "hold", "plank", "wall sit", "dead hang", "isometric", "static",
    "l-sit", "hollow", "bridge hold", "superman hold", "glute bridge hold",
    "hang", "foam roll", "yoga", "pose", "child's pose", "downward dog",
    "warrior", "cobra", "pigeon", "deep squat hold",
]

DYNAMIC_EXERCISE_KEYWORDS = [
    "jumping", "circles", "swings", "jacks", "high knees", "butt kicks",
    "skips", "march", "rotation", "twist", "lunge walk", "inchworm",
    "mountain climber", "bear crawl", "carioca", "shuffle",
    "a-skip", "b-skip", "grapevine", "lateral shuffle", "seal jack",
    "frankenstein", "spiderman", "jump rope", "skip step",
]


def classify_movement_type(exercise_name: str) -> str:
    """Classify an exercise as 'static' or 'dynamic' based on name."""
    name_lower = exercise_name.lower()
    for keyword in STATIC_EXERCISE_KEYWORDS:
        if keyword in name_lower:
            return "static"
    for keyword in DYNAMIC_EXERCISE_KEYWORDS:
        if keyword in name_lower:
            return "dynamic"
    # Default to dynamic for warmups (safer assumption)
    return "dynamic"


def order_warmup_exercises(exercises: list) -> list:
    """
    Order warmup exercises with static holds EARLY, then dynamic movements.

    The user feedback was: "warm-ups should have static holds early, not intermixed
    with kinetic moves, I'm trying to gradually increase my heart rate through movement"

    Order: Static holds first -> Dynamic movements (to build heart rate)
    """
    static_exercises = []
    dynamic_exercises = []

    for ex in exercises:
        name = ex.get("name", "")
        movement_type = classify_movement_type(name)
        if movement_type == "static":
            static_exercises.append(ex)
        else:
            dynamic_exercises.append(ex)

    # Return: static first, then dynamic
    ordered = static_exercises + dynamic_exercises

    logger.info(f"🔄 Ordered warmup: {len(static_exercises)} static exercises first, then {len(dynamic_exercises)} dynamic exercises")

    return ordered


# Muscle group keywords for matching exercises from library
MUSCLE_KEYWORDS = {
    "chest": ["chest", "pectoral", "pec"],
    "back": ["back", "lat", "rhomboid", "trap", "erector"],
    "shoulders": ["shoulder", "deltoid", "delt"],
    "legs": ["leg", "quad", "hamstring", "glute", "calf", "hip"],
    "quadriceps": ["quad", "quadriceps"],
    "hamstrings": ["hamstring"],
    "calves": ["calf", "calves", "gastrocnemius", "soleus"],
    "arms": ["arm", "bicep", "tricep", "forearm"],
    "biceps": ["bicep"],
    "triceps": ["tricep"],
    "core": ["core", "abdominal", "oblique", "abs"],
    "abs": ["abdominal", "abs", "rectus"],
    "glutes": ["glute", "gluteus", "hip"],
    "full body": [""],  # Match all
}

# Muscle group to warm-up mapping (fallback)
WARMUP_BY_MUSCLE = {
    "chest": ["Arm Circle Forward", "Arm Circle Backward", "Seal Jack", "Chest Doorway Stretch"],
    "back": ["Bear Crawl", "Inchworm", "Torso Twist", "Thoracic Rotation Quadruped"],
    "shoulders": ["Arm Circle Forward", "Arm Circle Backward", "Shoulder CARs", "Wall Slide"],
    "legs": ["A-Skip", "B-Skip", "Walking Knee Hug", "Walking Quad Pull", "Squat to Stand"],
    "quadriceps": ["Walking Quad Pull", "A-Skip", "High Knee Run", "Lateral Lunge"],
    "hamstrings": ["B-Skip", "Frankenstein Walk", "Bodyweight Good Morning", "Leg Swing Forward-Backward"],
    "calves": ["Ankle CARs", "Jump Rope Basic Bounce", "A-Skip"],
    "arms": ["Arm Circle Forward", "Arm Circle Backward", "Seal Jack"],
    "biceps": ["Arm Circle Forward", "Arm Circle Backward"],
    "triceps": ["Arm Circle Forward", "Arm Circle Backward", "Seal Jack"],
    "core": ["Torso Twist", "Mountain Climber", "Bear Crawl", "Inchworm"],
    "abs": ["Torso Twist", "Mountain Climber", "Bear Crawl"],
    "glutes": ["Hip Circle", "Walking Knee Hug", "Hip 90/90 Switch", "Lateral Lunge"],
    "full body": ["World's Greatest Stretch", "Inchworm", "Bear Crawl", "Torso Twist", "A-Skip"],
}

# Muscle group to stretch mapping (fallback)
STRETCH_BY_MUSCLE = {
    "chest": ["Chest Doorway Stretch", "Doorway Pec Stretch High"],
    "back": ["Child's Pose", "Cat-Cow Stretch", "Thread the Needle", "Lat Stretch Wall"],
    "shoulders": ["Cross-Body Shoulder Stretch", "Shoulder Sleeper Stretch", "Wall Slide"],
    "legs": ["Standing Quad Stretch", "Standing Hamstring Stretch", "Standing Calf Stretch"],
    "quadriceps": ["Standing Quad Stretch", "Prone Quad Stretch", "Walking Quad Pull"],
    "hamstrings": ["Standing Hamstring Stretch", "Seated Hamstring Stretch", "Supine Hamstring Stretch"],
    "calves": ["Standing Calf Stretch", "Soleus Stretch", "Ankle Dorsiflexion Stretch"],
    "arms": ["Overhead Triceps Stretch", "Wrist Flexor Stretch", "Wrist Extensor Stretch"],
    "biceps": ["Cross-Body Shoulder Stretch", "Chest Doorway Stretch"],
    "triceps": ["Overhead Triceps Stretch"],
    "core": ["Cobra Stretch", "Supine Spinal Twist", "Standing Side Bend"],
    "abs": ["Cobra Stretch", "Supine Spinal Twist"],
    "glutes": ["Pigeon Stretch", "Figure Four Stretch", "Lying Glute Stretch"],
    "full body": ["Child's Pose", "World's Greatest Stretch", "Supine Spinal Twist", "Standing Quad Stretch"],
}


