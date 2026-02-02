"""
Dictionary-based algorithm for warmup and stretch selection.
Replaces Gemini API calls with instant, deterministic selection.

Performance: <10ms vs 3-5s with Gemini
"""

import random
from typing import List, Dict, Any, Optional, Set
from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


# ============================================
# EXERCISE TIMING DATA
# ============================================

# Smart timing: duration for static/cardio, reps for dynamic
EXERCISE_TIMING = {
    # WARMUPS - Dynamic movements
    "jumping jack": {"type": "duration", "default": 30, "unit": "seconds"},
    "arm circle": {"type": "reps", "default": 15, "unit": "reps", "notes": "each direction"},
    "circle elbow arm": {"type": "reps", "default": 15, "unit": "reps", "notes": "each direction"},
    "high knees": {"type": "duration", "default": 30, "unit": "seconds"},
    "butt kicks": {"type": "duration", "default": 30, "unit": "seconds"},
    "butt kicks slow": {"type": "duration", "default": 30, "unit": "seconds"},
    "ankle circles": {"type": "reps", "default": 10, "unit": "reps", "notes": "each direction"},
    "dynamic leg swing": {"type": "reps", "default": 15, "unit": "reps", "notes": "each leg"},
    "air punches march": {"type": "duration", "default": 30, "unit": "seconds"},
    "skipping": {"type": "duration", "default": 30, "unit": "seconds"},
    "jogging": {"type": "duration", "default": 60, "unit": "seconds"},
    "star jump": {"type": "reps", "default": 10, "unit": "reps"},
    "jump rope basic jump": {"type": "duration", "default": 60, "unit": "seconds"},

    # CARDIO WARMUPS
    "treadmill walk": {"type": "duration", "default": 300, "unit": "seconds"},
    "treadmill incline walk": {"type": "duration", "default": 600, "unit": "seconds"},
    "stationary bike easy": {"type": "duration", "default": 300, "unit": "seconds"},
    "rowing machine easy": {"type": "duration", "default": 300, "unit": "seconds"},
    "elliptical easy": {"type": "duration", "default": 300, "unit": "seconds"},

    # STRETCHES - All use duration (static holds)
    "standing hamstring calf stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "standing quadriceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "lying quadriceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "back pec stretch": {"type": "duration", "default": 30, "unit": "seconds"},
    "lying glute stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "calf stretch with hands against wall": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "kneeling hip flexor stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each side"},
    "overhead triceps stretch": {"type": "duration", "default": 30, "unit": "seconds", "notes": "each arm"},
}

# Default timing by exercise type
DEFAULT_TIMING = {
    "warmup_dynamic": {"type": "reps", "default": 15, "unit": "reps"},
    "warmup_cardio": {"type": "duration", "default": 300, "unit": "seconds"},
    "warmup_static": {"type": "duration", "default": 30, "unit": "seconds"},
    "stretch": {"type": "duration", "default": 30, "unit": "seconds"},
}


# ============================================
# WARMUP MAPPINGS BY TRAINING SPLIT
# ============================================

WARMUP_BY_SPLIT = {
    "push": {
        "base": ["Jumping jack", "Arm circle", "Circle elbow arm"],
        "chest_shoulders": ["Air punches march", "Bouncing circle draw"],
    },
    "pull": {
        "base": ["Jumping jack", "Arm circle", "Dynamic Leg Swing"],
        "back": ["Butt kick with row", "Air Swing Side To Side Swing"],
    },
    "legs": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Ankle circles", "Dynamic Leg Swing"],
        "quads": ["Bodyweight knee thrust", "Double knee drive"],
        "glutes_hams": ["Butt kicks slow", "Criss cross jump"],
    },
    "upper": {
        "base": ["Jumping jack", "Arm circle", "Circle elbow arm", "Air punches march"],
    },
    "lower": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Ankle circles", "Dynamic Leg Swing", "Skipping"],
    },
    "full_body": {
        "base": ["Jumping jack", "High knees", "Butt kicks", "Arm circle", "Ankle circles"],
    },
    # Aliases for common split names
    "chest": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm", "Air punches march"]},
    "back": {"base": ["Jumping jack", "Arm circle", "Dynamic Leg Swing"]},
    "shoulders": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm"]},
    "arms": {"base": ["Jumping jack", "Arm circle", "Circle elbow arm"]},
}

# Cardio warmups for higher intensity workouts
CARDIO_WARMUPS = ["Jogging", "Skipping", "Jump Rope basic jump", "Star jump", "180 Jump Turns"]


# ============================================
# STRETCH MAPPINGS BY MUSCLE GROUP
# ============================================

STRETCH_BY_MUSCLE = {
    "chest": [
        "Back pec stretch", "Above head chest stretch", "Arms Behind Back Chest Stretch",
        "Bent arm chest stretch", "Corner wall chest stretch", "Side Chest Stretch On Wall"
    ],
    "pectorals": [
        "Back pec stretch", "Above head chest stretch", "Arms Behind Back Chest Stretch"
    ],
    "back": [
        "Dynamic Back Stretch", "Exercise ball back stretch", "Kneeling lat floor stretch",
        "Middle back rotation stretch", "Pretzel stretch", "Dead hang stretch"
    ],
    "lats": [
        "Kneeling lat floor stretch", "Dead hang stretch", "Dynamic Back Stretch"
    ],
    "shoulders": [
        "Cross Body Shoulder Stretch_Female", "Rear deltoid stretch",
        "back and shoulder stretch", "Extension Of Arms In Vertical Stretch"
    ],
    "delts": [
        "Cross Body Shoulder Stretch_Female", "Rear deltoid stretch"
    ],
    "hamstrings": [
        "Standing hamstring calf stretch with Resistance band", "Runner stretch",
        "Lying Single Leg Extended On Wall Hamstrings Stretch", "Standing Straight-Leg Hamstring Stretch"
    ],
    "quadriceps": [
        "Standing quadriceps stretch", "Lying quadriceps stretch",
        "All fours quad stretch", "Lying side quadriceps stretch"
    ],
    "quads": [
        "Standing quadriceps stretch", "Lying quadriceps stretch"
    ],
    "glutes": [
        "Lying glute stretch", "Lying Knee Pull Glutes Stretch",
        "Seated Figure Four With Twist Glute Stretch"
    ],
    "calves": [
        "Calf stretch with hands against wall", "Standing gastrocnemius stretch",
        "Seated calf stretch", "Calves stretch on stairs"
    ],
    "hip_flexors": [
        "Kneeling hip flexor stretch", "Lying hip flexor stretch",
        "Exercise ball hip flexor stretch", "Crossover kneeling hip flexor stretch"
    ],
    "hips": [
        "Kneeling hip flexor stretch", "Lying hip flexor stretch", "Adductor stretch"
    ],
    "triceps": [
        "Overhead triceps stretch side angle", "Triceps light stretch",
        "Overhand tricep stretching single arm"
    ],
    "biceps": ["Biceps stretch behind the back"],
    "core": [
        "Abdominal stretch", "Lying (prone) abdominal stretch",
        "Standing lateral stretch", "Knee to chest stretch"
    ],
    "abs": [
        "Abdominal stretch", "Lying (prone) abdominal stretch"
    ],
    "lower_back": [
        "Knee to chest stretch", "Lying crossover stretch", "Iron cross stretch",
        "Exercise ball lower back prone stretch"
    ],
    "adductors": [
        "Adductor stretch", "Adductor stretch side standing", "Butterfly yoga flaps"
    ],
    "forearms": [
        "Forearms Stretch On Wall", "Kneeling wrist flexor stretch", "Side wrist pull stretch"
    ],
    "neck": [
        "Half Neck Rolls", "Backward Forward Turn to Side Neck Stretch"
    ],
    "full body": [
        "Standing quadriceps stretch", "Lying glute stretch", "Back pec stretch",
        "Calf stretch with hands against wall", "Dynamic Back Stretch"
    ],
}


# ============================================
# INJURY FILTERS
# ============================================

INJURY_AVOID_WARMUPS = {
    "knee": ["Jumping jack", "High knees", "Star jump", "Criss cross jump", "180 Jump Turns", "Jump Rope basic jump", "Skipping"],
    "shoulder": ["Arm circle", "Circle elbow arm", "Air punches march", "Bouncing circle draw"],
    "back": ["Butt kick with row", "Kettlebell swing"],
    "ankle": ["Jumping jack", "High knees", "Skipping", "Jump Rope basic jump", "Star jump"],
    "hip": ["High knees", "Dynamic Leg Swing", "Criss cross jump", "Double knee drive"],
    "wrist": ["Air punches march", "Bouncing circle draw"],
    "lower_back": ["Butt kick with row", "Criss cross jump"],
}

INJURY_AVOID_STRETCHES = {
    "knee": ["All fours quad stretch", "Kneeling hip flexor stretch", "Kneeling lat floor stretch", "Kneeling wrist flexor stretch"],
    "shoulder": ["Above head chest stretch", "Dead hang stretch", "Extension Of Arms In Vertical Stretch"],
    "back": ["Lying crossover stretch", "Iron cross stretch", "Middle back rotation stretch"],
    "hip": ["Lying hip flexor stretch", "Kneeling hip flexor stretch", "Adductor stretch"],
    "lower_back": ["Lying crossover stretch", "Iron cross stretch"],
    "neck": ["Half Neck Rolls", "Backward Forward Turn to Side Neck Stretch"],
}


# ============================================
# MAIN ALGORITHM CLASS
# ============================================

class WarmupStretchAlgorithm:
    """Algorithm-based warmup/stretch selection without Gemini API calls."""

    def __init__(self):
        self.supabase = get_supabase().client

    def _normalize_split(self, training_split: str) -> str:
        """Normalize training split name to match our mappings."""
        split_lower = training_split.lower().strip()

        # Direct matches
        if split_lower in WARMUP_BY_SPLIT:
            return split_lower

        # Common aliases
        aliases = {
            "push day": "push",
            "pull day": "pull",
            "leg day": "legs",
            "upper body": "upper",
            "lower body": "lower",
            "full body": "full_body",
            "fullbody": "full_body",
            "ppl": "full_body",  # Push-Pull-Legs varies by day
            "phul": "full_body",
            "chest day": "push",
            "back day": "pull",
            "shoulder day": "push",
            "arm day": "arms",
        }

        return aliases.get(split_lower, "full_body")

    def _normalize_muscle(self, muscle: str) -> str:
        """Normalize muscle name to match our mappings."""
        muscle_lower = muscle.lower().strip()

        # Common aliases
        aliases = {
            "pecs": "chest",
            "pectorals": "chest",
            "latissimus dorsi": "lats",
            "deltoids": "shoulders",
            "delts": "shoulders",
            "quads": "quadriceps",
            "hams": "hamstrings",
            "abs": "core",
            "abdominals": "core",
            "glutes": "glutes",
            "gluteus": "glutes",
            "traps": "shoulders",
            "trapezius": "shoulders",
        }

        return aliases.get(muscle_lower, muscle_lower)

    def _filter_by_injuries(
        self,
        exercises: List[str],
        injuries: List[str],
        avoid_map: Dict[str, List[str]]
    ) -> List[str]:
        """Remove exercises that could aggravate injuries."""
        if not injuries:
            return exercises

        # Build set of exercises to avoid
        avoid_exercises: Set[str] = set()
        for injury in injuries:
            injury_lower = injury.lower()
            for key, avoid_list in avoid_map.items():
                if key in injury_lower:
                    avoid_exercises.update(ex.lower() for ex in avoid_list)

        # Filter exercises
        return [ex for ex in exercises if ex.lower() not in avoid_exercises]

    def get_exercise_timing(self, exercise_name: str, exercise_type: str = "warmup") -> Dict[str, Any]:
        """Get smart timing (duration or reps) for an exercise."""
        name_lower = exercise_name.lower()

        # Check specific exercise timing
        if name_lower in EXERCISE_TIMING:
            return EXERCISE_TIMING[name_lower]

        # Default based on exercise type
        if "cardio" in exercise_type.lower() or "treadmill" in name_lower or "bike" in name_lower:
            return DEFAULT_TIMING["warmup_cardio"]
        elif exercise_type.lower() == "stretch":
            return DEFAULT_TIMING["stretch"]
        elif "static" in exercise_type.lower() or "hold" in name_lower:
            return DEFAULT_TIMING["warmup_static"]
        else:
            return DEFAULT_TIMING["warmup_dynamic"]

    async def get_user_preferences(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Fetch user's warmup/stretch preferences from database."""
        try:
            response = self.supabase.table("warmup_stretch_preferences").select("*").eq(
                "user_id", user_id
            ).limit(1).execute()

            if response.data:
                return response.data[0]
            return None
        except Exception as e:
            logger.warning(f"⚠️ Could not fetch warmup preferences for user {user_id}: {e}")
            return None

    async def select_warmups(
        self,
        target_muscles: List[str],
        training_split: str = "full_body",
        equipment: Optional[List[str]] = None,
        injuries: Optional[List[str]] = None,
        intensity: str = "medium",
        user_id: Optional[str] = None,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Select warmup exercises based on workout parameters.

        Returns:
            {
                "pre_workout": [...],      # User's custom pre-workout routine
                "dynamic_warmups": [...],  # Algorithm-selected warmups
            }
        """
        logger.info(f"🔥 Selecting warmups for split={training_split}, muscles={target_muscles}")

        result = {
            "pre_workout": [],
            "dynamic_warmups": [],
        }

        # Get user preferences if available
        user_prefs = None
        if user_id:
            user_prefs = await self.get_user_preferences(user_id)

        # Add pre-workout routine from preferences
        if user_prefs and user_prefs.get("pre_workout_routine"):
            result["pre_workout"] = user_prefs["pre_workout_routine"]
            logger.info(f"📋 Added {len(result['pre_workout'])} pre-workout exercises from preferences")

        # Normalize training split
        split = self._normalize_split(training_split)

        # Get base warmups for this split
        split_warmups = WARMUP_BY_SPLIT.get(split, WARMUP_BY_SPLIT["full_body"])
        selected = list(split_warmups.get("base", []))

        # Add muscle-specific warmups
        for muscle in target_muscles:
            muscle_key = self._normalize_muscle(muscle)
            if muscle_key in split_warmups:
                selected.extend(split_warmups[muscle_key])

        # Add cardio warmup for high intensity
        if intensity.lower() in ["high", "hard", "intense"]:
            selected.extend(random.sample(CARDIO_WARMUPS, min(1, len(CARDIO_WARMUPS))))

        # Filter by injuries
        if injuries:
            selected = self._filter_by_injuries(selected, injuries, INJURY_AVOID_WARMUPS)
            logger.info(f"⚠️ Filtered warmups for injuries: {injuries}")

        # Apply user preferred/avoided warmups
        if user_prefs:
            # Add preferred warmups
            preferred = user_prefs.get("preferred_warmups", [])
            if preferred:
                for pref in preferred:
                    if pref not in selected:
                        selected.insert(0, pref)

            # Remove avoided warmups
            avoided = user_prefs.get("avoided_warmups", [])
            if avoided:
                avoided_lower = [a.lower() for a in avoided]
                selected = [ex for ex in selected if ex.lower() not in avoided_lower]

        # Remove duplicates while preserving order
        seen = set()
        unique_selected = []
        for ex in selected:
            if ex.lower() not in seen:
                seen.add(ex.lower())
                unique_selected.append(ex)

        # Limit to 4-5 warmups
        selected = unique_selected[:5]

        # Shuffle for variety
        random.shuffle(selected)

        # Format exercises with timing
        for ex_name in selected[:4]:  # Max 4 dynamic warmups
            timing = self.get_exercise_timing(ex_name, "warmup")
            exercise = {
                "name": ex_name,
                "sets": 1,
                "duration_seconds": timing.get("default", 30) if timing.get("type") == "duration" else None,
                "reps": timing.get("default", 15) if timing.get("type") == "reps" else None,
                "rest_seconds": 10,
                "equipment": "none",
                "notes": timing.get("notes", "Perform with control"),
            }
            result["dynamic_warmups"].append(exercise)

        logger.info(f"✅ Selected {len(result['dynamic_warmups'])} dynamic warmups")
        return result

    async def select_stretches(
        self,
        worked_muscles: List[str],
        training_split: str = "full_body",
        injuries: Optional[List[str]] = None,
        user_id: Optional[str] = None,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Select stretch exercises based on worked muscles.

        Returns:
            {
                "post_exercise": [...],    # User's custom post-exercise routine
                "stretches": [...],        # Algorithm-selected stretches
            }
        """
        logger.info(f"❄️ Selecting stretches for muscles={worked_muscles}")

        result = {
            "post_exercise": [],
            "stretches": [],
        }

        # Get user preferences if available
        user_prefs = None
        if user_id:
            user_prefs = await self.get_user_preferences(user_id)

        # Add post-exercise routine from preferences
        if user_prefs and user_prefs.get("post_exercise_routine"):
            result["post_exercise"] = user_prefs["post_exercise_routine"]
            logger.info(f"📋 Added {len(result['post_exercise'])} post-exercise from preferences")

        # Collect stretches for each worked muscle
        selected = []
        for muscle in worked_muscles:
            muscle_key = self._normalize_muscle(muscle)
            if muscle_key in STRETCH_BY_MUSCLE:
                # Add 1-2 stretches per muscle group
                muscle_stretches = STRETCH_BY_MUSCLE[muscle_key]
                selected.extend(random.sample(muscle_stretches, min(2, len(muscle_stretches))))

        # Add general full-body stretches if not enough
        if len(selected) < 4:
            full_body = STRETCH_BY_MUSCLE.get("full body", [])
            for stretch in full_body:
                if stretch not in selected:
                    selected.append(stretch)
                if len(selected) >= 5:
                    break

        # Filter by injuries
        if injuries:
            selected = self._filter_by_injuries(selected, injuries, INJURY_AVOID_STRETCHES)
            logger.info(f"⚠️ Filtered stretches for injuries: {injuries}")

        # Apply user preferred/avoided stretches
        if user_prefs:
            # Add preferred stretches
            preferred = user_prefs.get("preferred_stretches", [])
            if preferred:
                for pref in preferred:
                    if pref not in selected:
                        selected.insert(0, pref)

            # Remove avoided stretches
            avoided = user_prefs.get("avoided_stretches", [])
            if avoided:
                avoided_lower = [a.lower() for a in avoided]
                selected = [ex for ex in selected if ex.lower() not in avoided_lower]

        # Remove duplicates while preserving order
        seen = set()
        unique_selected = []
        for ex in selected:
            if ex.lower() not in seen:
                seen.add(ex.lower())
                unique_selected.append(ex)

        # Limit to 5 stretches
        selected = unique_selected[:5]

        # Format exercises with timing
        for ex_name in selected:
            timing = self.get_exercise_timing(ex_name, "stretch")
            exercise = {
                "name": ex_name,
                "sets": 1,
                "reps": 1,
                "duration_seconds": timing.get("default", 30),
                "rest_seconds": 0,
                "equipment": "none",
                "notes": timing.get("notes", "Hold and breathe deeply"),
            }
            result["stretches"].append(exercise)

        logger.info(f"✅ Selected {len(result['stretches'])} stretches")
        return result


# ============================================
# SINGLETON INSTANCE
# ============================================

_algorithm_instance: Optional[WarmupStretchAlgorithm] = None


def get_warmup_stretch_algorithm() -> WarmupStretchAlgorithm:
    """Get singleton instance of the algorithm."""
    global _algorithm_instance
    if _algorithm_instance is None:
        _algorithm_instance = WarmupStretchAlgorithm()
    return _algorithm_instance
