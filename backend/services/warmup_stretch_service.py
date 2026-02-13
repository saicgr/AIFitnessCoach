"""Service for generating warm-up and cool-down exercises with SCD2 versioning.

Updated to use dictionary-based algorithm instead of Gemini for instant generation.
Performance improvement: 3-5s -> <10ms
"""

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


class WarmupStretchService:
    def __init__(self):
        self.model = settings.gemini_model
        self.supabase = get_supabase().client  # Get the actual Supabase client

    async def get_recently_used_warmups(self, user_id: str, days: int = 30) -> List[str]:
        """Get list of warmup exercise names used by user in recent workouts.

        Extended to 30 days (from 7) to ensure better variety across workout cycles.
        """
        try:
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

            # First get workout IDs for this user in the date range
            workouts_response = self.supabase.table("workouts").select(
                "id"
            ).eq("user_id", user_id).gte("scheduled_date", cutoff_date[:10]).execute()

            if not workouts_response.data:
                logger.info(f"🔍 No recent workouts found for user {user_id}")
                return []

            workout_ids = [w["id"] for w in workouts_response.data]

            # Get warmups for these workouts
            warmups_response = self.supabase.table("warmups").select(
                "exercises_json"
            ).in_("workout_id", workout_ids).eq("is_current", True).execute()

            if not warmups_response.data:
                return []

            # Extract unique exercise names from warmups
            exercise_names = set()
            for warmup in warmups_response.data:
                exercises_json = warmup.get("exercises_json", [])
                if isinstance(exercises_json, list):
                    for ex in exercises_json:
                        if isinstance(ex, dict) and ex.get("name"):
                            exercise_names.add(ex["name"].lower())

            logger.info(f"🔍 Found {len(exercise_names)} recently used warmup exercises for user {user_id}")
            return list(exercise_names)

        except Exception as e:
            logger.error(f"❌ Failed to get recent warmups: {e}")
            return []

    async def get_recently_used_stretches(self, user_id: str, days: int = 30) -> List[str]:
        """Get list of stretch exercise names used by user in recent workouts.

        Extended to 30 days (from 7) to ensure better variety across workout cycles.
        """
        try:
            cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()

            # First get workout IDs for this user in the date range
            workouts_response = self.supabase.table("workouts").select(
                "id"
            ).eq("user_id", user_id).gte("scheduled_date", cutoff_date[:10]).execute()

            if not workouts_response.data:
                logger.info(f"🔍 No recent workouts found for user {user_id}")
                return []

            workout_ids = [w["id"] for w in workouts_response.data]

            # Get stretches for these workouts
            stretches_response = self.supabase.table("stretches").select(
                "exercises_json"
            ).in_("workout_id", workout_ids).eq("is_current", True).execute()

            if not stretches_response.data:
                return []

            # Extract unique exercise names from stretches
            exercise_names = set()
            for stretch in stretches_response.data:
                exercises_json = stretch.get("exercises_json", [])
                if isinstance(exercises_json, list):
                    for ex in exercises_json:
                        if isinstance(ex, dict) and ex.get("name"):
                            exercise_names.add(ex["name"].lower())

            logger.info(f"🔍 Found {len(exercise_names)} recently used stretch exercises for user {user_id}")
            return list(exercise_names)

        except Exception as e:
            logger.error(f"❌ Failed to get recent stretches: {e}")
            return []

    async def get_warmup_exercises_from_library(
        self,
        target_muscles: List[str],
        avoid_exercises: Optional[List[str]] = None,
        limit: int = 4
    ) -> List[Dict[str, Any]]:
        """
        Get warmup exercises from the warmup_exercises_cleaned view.
        Returns exercises with videos that target the specified muscle groups.
        """
        try:
            # Fetch all warmup exercises from the view
            response = self.supabase.table("warmup_exercises_cleaned").select(
                "id, name, body_part, target_muscle, equipment, instructions, video_url, gif_url, image_url"
            ).execute()

            if not response.data:
                logger.warning("⚠️ No warmup exercises found in library")
                return []

            exercises = response.data
            avoid_lower = [ex.lower() for ex in (avoid_exercises or [])]

            # Filter by target muscles
            matched = []
            for ex in exercises:
                # Skip if recently used
                if ex.get("name", "").lower() in avoid_lower:
                    continue

                # Check if exercise targets any of our muscles
                target = (ex.get("target_muscle") or "").lower()
                name = (ex.get("name") or "").lower()

                for muscle in target_muscles:
                    keywords = MUSCLE_KEYWORDS.get(muscle.lower(), [muscle.lower()])
                    for keyword in keywords:
                        if keyword and (keyword in target or keyword in name):
                            matched.append(ex)
                            break
                    else:
                        continue
                    break

            # If not enough matches, add some general full-body warmups
            if len(matched) < limit:
                remaining = [ex for ex in exercises
                            if ex not in matched
                            and ex.get("name", "").lower() not in avoid_lower]
                random.shuffle(remaining)
                matched.extend(remaining[:limit - len(matched)])

            # Shuffle and limit
            random.shuffle(matched)
            selected = matched[:limit]

            # Format for storage
            result = []
            for ex in selected:
                result.append({
                    "name": ex.get("name"),
                    "sets": 1,
                    "reps": 15,
                    "duration_seconds": 30,
                    "rest_seconds": 10,
                    "equipment": ex.get("equipment") or "none",
                    "muscle_group": ex.get("target_muscle") or "full body",
                    "notes": (ex.get("instructions") or "Perform controlled movements")[:100],
                    "video_url": ex.get("video_url"),
                    "image_url": ex.get("image_url"),
                    "exercise_id": ex.get("id"),
                })

            logger.info(f"✅ Selected {len(result)} warmup exercises from library")
            return result

        except Exception as e:
            logger.error(f"❌ Failed to get warmup exercises from library: {e}")
            return []

    async def get_stretch_exercises_from_library(
        self,
        target_muscles: List[str],
        avoid_exercises: Optional[List[str]] = None,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Get stretch exercises from the stretch_exercises_cleaned view.
        Returns exercises with videos that target the specified muscle groups.
        """
        try:
            # Fetch all stretch exercises from the view
            response = self.supabase.table("stretch_exercises_cleaned").select(
                "id, name, body_part, target_muscle, equipment, instructions, video_url, gif_url, image_url"
            ).execute()

            if not response.data:
                logger.warning("⚠️ No stretch exercises found in library")
                return []

            exercises = response.data
            avoid_lower = [ex.lower() for ex in (avoid_exercises or [])]

            # Filter by target muscles
            matched = []
            for ex in exercises:
                # Skip if recently used
                if ex.get("name", "").lower() in avoid_lower:
                    continue

                # Check if exercise targets any of our muscles
                target = (ex.get("target_muscle") or "").lower()
                name = (ex.get("name") or "").lower()

                for muscle in target_muscles:
                    keywords = MUSCLE_KEYWORDS.get(muscle.lower(), [muscle.lower()])
                    for keyword in keywords:
                        if keyword and (keyword in target or keyword in name):
                            matched.append(ex)
                            break
                    else:
                        continue
                    break

            # If not enough matches, add some general stretches
            if len(matched) < limit:
                remaining = [ex for ex in exercises
                            if ex not in matched
                            and ex.get("name", "").lower() not in avoid_lower]
                random.shuffle(remaining)
                matched.extend(remaining[:limit - len(matched)])

            # Shuffle and limit
            random.shuffle(matched)
            selected = matched[:limit]

            # Format for storage
            result = []
            for ex in selected:
                result.append({
                    "name": ex.get("name"),
                    "sets": 1,
                    "reps": 1,
                    "duration_seconds": 30,
                    "rest_seconds": 0,
                    "equipment": ex.get("equipment") or "none",
                    "muscle_group": ex.get("target_muscle") or "full body",
                    "notes": (ex.get("instructions") or "Hold and breathe deeply")[:100],
                    "video_url": ex.get("video_url"),
                    "image_url": ex.get("image_url"),
                    "exercise_id": ex.get("id"),
                })

            logger.info(f"✅ Selected {len(result)} stretch exercises from library")
            return result

        except Exception as e:
            logger.error(f"❌ Failed to get stretch exercises from library: {e}")
            return []

    def get_target_muscles(self, exercises: List[Dict]) -> List[str]:
        """Extract unique muscle groups from exercises."""
        muscles = set()
        for ex in exercises:
            # Check various field names that might contain muscle info
            muscle = (
                ex.get("muscle_group", "") or
                ex.get("primary_muscle", "") or
                ex.get("target", "") or
                ex.get("bodyPart", "")
            )
            if isinstance(muscle, str) and muscle:
                muscles.add(muscle.lower())
        return list(muscles) if muscles else ["full body"]

    async def generate_warmup(
        self,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None,
        avoid_exercises: Optional[List[str]] = None,
        use_library: bool = True,
        user_id: Optional[str] = None,
        training_split: str = "full_body",
        equipment: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """Generate dynamic warm-up using dictionary-based algorithm (instant, no Gemini).

        Args:
            exercises: List of workout exercises to warmup for
            duration_minutes: Target duration for warmup
            injuries: List of user injuries to avoid aggravating
            avoid_exercises: List of exercise names to avoid for variety
            use_library: If True, try to get video URLs from library
            user_id: User ID for fetching preferences
            training_split: Training split (push, pull, legs, etc.)
            equipment: List of available equipment for equipment-based warmups
        """
        muscles = self.get_target_muscles(exercises)
        logger.info(f"🔥 [Algorithm] Generating warmup for muscles: {muscles}, split: {training_split}")

        # Use dictionary-based algorithm (instant, no Gemini API call)
        algorithm = get_warmup_stretch_algorithm()
        result = await algorithm.select_warmups(
            target_muscles=muscles,
            training_split=training_split,
            equipment=equipment,
            injuries=injuries,
            intensity="medium",
            user_id=user_id,
        )

        # Inject user's warmup staple exercises
        warmup_staples = []
        if user_id:
            try:
                from api.v1.exercise_preferences import get_user_staples_by_section
                staple_rows = await get_user_staples_by_section(user_id, "warmup")
                for row in staple_rows:
                    # User overrides take priority over library defaults
                    duration = row.get("user_duration_seconds") or row.get("default_duration_seconds") or 300
                    warmup_staples.append({
                        "name": row.get("exercise_name"),
                        "sets": 1,
                        "reps": None,
                        "duration_seconds": duration,
                        "rest_seconds": 0,
                        "equipment": row.get("equipment") or "none",
                        "muscle_group": row.get("muscle_group") or "cardio",
                        "notes": "Staple warmup exercise",
                        "is_pre_workout": True,
                        "is_staple": True,
                        "is_timed": True,
                        "incline_percent": row.get("user_incline_percent") or row.get("default_incline_percent"),
                        "speed_mph": row.get("user_speed_mph") or row.get("default_speed_mph"),
                        "rpm": row.get("user_rpm") or row.get("default_rpm"),
                        "resistance_level": row.get("user_resistance_level") or row.get("default_resistance_level"),
                        "stroke_rate_spm": row.get("user_stroke_rate_spm") or row.get("stroke_rate_spm"),
                    })
                if warmup_staples:
                    logger.info(f"⭐ Injected {len(warmup_staples)} warmup staples for user {user_id}")
            except Exception as e:
                logger.warning(f"⚠️ Could not inject warmup staples: {e}")

        # Combine pre-workout and dynamic warmups
        all_warmups = []

        # First: user's warmup staple exercises (always first)
        all_warmups.extend(warmup_staples)

        # Second: pre-workout routine from preferences (e.g., treadmill walk)
        if result.get("pre_workout"):
            for ex in result["pre_workout"]:
                all_warmups.append({
                    "name": ex.get("name"),
                    "sets": 1,
                    "reps": None,
                    "duration_seconds": ex.get("duration_minutes", 5) * 60,
                    "rest_seconds": 0,
                    "equipment": ex.get("equipment", "none"),
                    "muscle_group": "cardio",
                    "notes": ex.get("notes", "Custom pre-workout routine"),
                    "is_pre_workout": True,
                })

        # Add dynamic warmups
        all_warmups.extend(result.get("dynamic_warmups", []))

        # Try to enrich with video URLs from library
        if use_library and all_warmups:
            all_warmups = await self._enrich_with_library_data(all_warmups, "warmup")

        # Order warmups: static first, then dynamic
        all_warmups = order_warmup_exercises(all_warmups)

        logger.info(f"✅ [Algorithm] Generated {len(all_warmups)} warmup exercises in <10ms")
        return all_warmups

    async def _enrich_with_library_data(
        self,
        exercises: List[Dict],
        exercise_type: str = "warmup"
    ) -> List[Dict]:
        """Enrich algorithm-selected exercises with video URLs from library."""
        try:
            table = "warmup_exercises_cleaned" if exercise_type == "warmup" else "stretch_exercises_cleaned"
            response = self.supabase.table(table).select(
                "name, video_url, gif_url, image_url"
            ).execute()

            if not response.data:
                return exercises

            # Build lookup map (case-insensitive)
            library_map = {ex["name"].lower(): ex for ex in response.data}

            # Enrich exercises
            for ex in exercises:
                name_lower = ex.get("name", "").lower()
                if name_lower in library_map:
                    lib_ex = library_map[name_lower]
                    ex["video_url"] = lib_ex.get("video_url")
                    ex["gif_url"] = lib_ex.get("gif_url")
                    ex["image_url"] = lib_ex.get("image_url")

            # Also fetch cardio metadata from exercise_library
            try:
                exercise_names = [ex.get("name", "") for ex in exercises if not ex.get("is_staple")]
                if exercise_names:
                    metadata_response = self.supabase.table("exercise_library").select(
                        "exercise_name, default_incline_percent, default_speed_mph, default_rpm, "
                        "default_resistance_level, stroke_rate_spm, default_duration_seconds, equipment"
                    ).in_("exercise_name", exercise_names).execute()

                    if metadata_response.data:
                        metadata_map = {r["exercise_name"].lower(): r for r in metadata_response.data}
                        for ex in exercises:
                            if ex.get("is_staple"):
                                continue  # Staples already have metadata
                            name_lower = ex.get("name", "").lower()
                            if name_lower in metadata_map:
                                meta = metadata_map[name_lower]
                                ex["incline_percent"] = meta.get("default_incline_percent")
                                ex["speed_mph"] = meta.get("default_speed_mph")
                                ex["rpm"] = meta.get("default_rpm")
                                ex["resistance_level"] = meta.get("default_resistance_level")
                                ex["stroke_rate_spm"] = meta.get("stroke_rate_spm")
                                if not ex.get("equipment") or ex["equipment"] == "none":
                                    ex["equipment"] = meta.get("equipment") or "none"
            except Exception as e:
                logger.warning(f"⚠️ Could not enrich with cardio metadata: {e}")

            return exercises
        except Exception as e:
            logger.warning(f"⚠️ Could not enrich exercises with library data: {e}")
            return exercises

    async def generate_stretches(
        self,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None,
        avoid_exercises: Optional[List[str]] = None,
        use_library: bool = True,
        user_id: Optional[str] = None,
        training_split: str = "full_body",
    ) -> List[Dict[str, Any]]:
        """Generate cool-down stretches using dictionary-based algorithm (instant, no Gemini).

        Args:
            exercises: List of workout exercises to stretch after
            duration_minutes: Target duration for stretching
            injuries: List of user injuries to avoid aggravating
            avoid_exercises: List of exercise names to avoid for variety
            use_library: If True, try to get video URLs from library
            user_id: User ID for fetching preferences
            training_split: Training split (push, pull, legs, etc.)
        """
        muscles = self.get_target_muscles(exercises)
        logger.info(f"❄️ [Algorithm] Generating stretches for muscles: {muscles}")

        # Use dictionary-based algorithm (instant, no Gemini API call)
        algorithm = get_warmup_stretch_algorithm()
        result = await algorithm.select_stretches(
            worked_muscles=muscles,
            training_split=training_split,
            injuries=injuries,
            user_id=user_id,
        )

        # Inject user's stretch staple exercises
        stretch_staples = []
        if user_id:
            try:
                from api.v1.exercise_preferences import get_user_staples_by_section
                staple_rows = await get_user_staples_by_section(user_id, "stretches")
                for row in staple_rows:
                    # User overrides take priority over library defaults
                    duration = row.get("user_duration_seconds") or row.get("default_duration_seconds") or 300
                    stretch_staples.append({
                        "name": row.get("exercise_name"),
                        "sets": 1,
                        "reps": None,
                        "duration_seconds": duration,
                        "rest_seconds": 0,
                        "equipment": row.get("equipment") or "none",
                        "muscle_group": row.get("muscle_group") or "cardio",
                        "notes": "Staple stretch/cool-down exercise",
                        "is_post_exercise": True,
                        "is_staple": True,
                        "is_timed": True,
                        "incline_percent": row.get("user_incline_percent") or row.get("default_incline_percent"),
                        "speed_mph": row.get("user_speed_mph") or row.get("default_speed_mph"),
                        "rpm": row.get("user_rpm") or row.get("default_rpm"),
                        "resistance_level": row.get("user_resistance_level") or row.get("default_resistance_level"),
                        "stroke_rate_spm": row.get("user_stroke_rate_spm") or row.get("stroke_rate_spm"),
                    })
                if stretch_staples:
                    logger.info(f"⭐ Injected {len(stretch_staples)} stretch staples for user {user_id}")
            except Exception as e:
                logger.warning(f"⚠️ Could not inject stretch staples: {e}")

        # Combine post-exercise and stretches
        all_stretches = []

        # First: user's stretch staple exercises
        all_stretches.extend(stretch_staples)

        # Second: post-exercise routine (e.g., cooldown walk)
        if result.get("post_exercise"):
            for ex in result["post_exercise"]:
                all_stretches.append({
                    "name": ex.get("name"),
                    "sets": 1,
                    "reps": None,
                    "duration_seconds": ex.get("duration_minutes", 5) * 60,
                    "rest_seconds": 0,
                    "equipment": ex.get("equipment", "none"),
                    "muscle_group": "cardio",
                    "notes": ex.get("notes", "Custom post-exercise cooldown"),
                    "is_post_exercise": True,
                })

        # Add stretches
        all_stretches.extend(result.get("stretches", []))

        # Try to enrich with video URLs from library
        if use_library and all_stretches:
            all_stretches = await self._enrich_with_library_data(all_stretches, "stretch")

        logger.info(f"✅ [Algorithm] Generated {len(all_stretches)} stretches in <10ms")
        return all_stretches

    async def create_warmup_for_workout(
        self,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None,
        user_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Generate and store warmup for a workout with SCD2 versioning and variety tracking."""
        # Extract target muscles for logging
        target_muscles = self.get_target_muscles(exercises)
        logger.info(f"🎯 [Warmup Generation] Target muscles from workout: {target_muscles}")

        # Get recently used warmups for variety if user_id provided (30 days for better variety)
        avoid_exercises = None
        if user_id:
            avoid_exercises = await self.get_recently_used_warmups(user_id, days=30)

        warmup_exercises = await self.generate_warmup(
            exercises, duration_minutes, injuries, avoid_exercises,
            user_id=user_id,
        )
        now = datetime.utcnow().isoformat()

        try:
            result = self.supabase.table("warmups").insert({
                "workout_id": workout_id,
                "exercises_json": warmup_exercises,
                "duration_minutes": duration_minutes,
                "target_muscles": target_muscles,  # Store target muscles for visibility
                "version_number": 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_warmup_id": None,
                "superseded_by": None
            }).execute()

            logger.info(f"✅ Created warmup for workout {workout_id} targeting: {target_muscles}")
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"❌ Failed to save warmup: {e}")
            return None

    async def create_stretches_for_workout(
        self,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None,
        user_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Generate and store stretches for a workout with SCD2 versioning and variety tracking."""
        # Extract target muscles for logging
        target_muscles = self.get_target_muscles(exercises)
        logger.info(f"🎯 [Stretch Generation] Target muscles from workout: {target_muscles}")

        # Get recently used stretches for variety if user_id provided (30 days for better variety)
        avoid_exercises = None
        if user_id:
            avoid_exercises = await self.get_recently_used_stretches(user_id, days=30)

        stretch_exercises = await self.generate_stretches(
            exercises, duration_minutes, injuries, avoid_exercises,
            user_id=user_id,
        )
        now = datetime.utcnow().isoformat()

        try:
            result = self.supabase.table("stretches").insert({
                "workout_id": workout_id,
                "exercises_json": stretch_exercises,
                "duration_minutes": duration_minutes,
                "target_muscles": target_muscles,  # Store target muscles for visibility
                "version_number": 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_stretch_id": None,
                "superseded_by": None
            }).execute()

            logger.info(f"✅ Created stretches for workout {workout_id} targeting: {target_muscles}")
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"❌ Failed to save stretches: {e}")
            return None

    def get_warmup_for_workout(self, workout_id: str) -> Optional[Dict[str, Any]]:
        """Get current warmup for a workout (only current version)."""
        try:
            result = self.supabase.table("warmups").select("*").eq(
                "workout_id", workout_id
            ).eq("is_current", True).limit(1).execute()

            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"❌ Failed to get warmup: {e}")
            return None

    def get_stretches_for_workout(self, workout_id: str) -> Optional[Dict[str, Any]]:
        """Get current stretches for a workout (only current version)."""
        try:
            result = self.supabase.table("stretches").select("*").eq(
                "workout_id", workout_id
            ).eq("is_current", True).limit(1).execute()

            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"❌ Failed to get stretches: {e}")
            return None

    def get_warmup_version_history(self, workout_id: str) -> List[Dict[str, Any]]:
        """Get all versions of warmups for a workout (SCD2 history)."""
        try:
            result = self.supabase.table("warmups").select("*").eq(
                "workout_id", workout_id
            ).order("version_number", desc=True).execute()

            return result.data if result.data else []
        except Exception as e:
            logger.error(f"❌ Failed to get warmup history: {e}")
            return []

    def get_stretch_version_history(self, workout_id: str) -> List[Dict[str, Any]]:
        """Get all versions of stretches for a workout (SCD2 history)."""
        try:
            result = self.supabase.table("stretches").select("*").eq(
                "workout_id", workout_id
            ).order("version_number", desc=True).execute()

            return result.data if result.data else []
        except Exception as e:
            logger.error(f"❌ Failed to get stretch history: {e}")
            return []

    async def regenerate_warmup(
        self,
        warmup_id: str,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        user_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Regenerate warmup with SCD2 versioning (creates new version, marks old as superseded)."""
        now = datetime.utcnow().isoformat()

        # Get the current warmup
        try:
            current = self.supabase.table("warmups").select("*").eq(
                "id", warmup_id
            ).single().execute()

            if not current.data:
                logger.error(f"❌ Warmup {warmup_id} not found")
                return None

            old_warmup = current.data
            old_version = old_warmup.get("version_number", 1)
            parent_id = old_warmup.get("parent_warmup_id") or warmup_id
        except Exception as e:
            logger.error(f"❌ Failed to get current warmup: {e}")
            return None

        # Generate new warmup exercises
        warmup_exercises = await self.generate_warmup(
            exercises, duration_minutes, user_id=user_id,
        )

        try:
            # Create new version
            new_warmup = self.supabase.table("warmups").insert({
                "workout_id": workout_id,
                "exercises_json": warmup_exercises,
                "duration_minutes": duration_minutes,
                "version_number": old_version + 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_warmup_id": parent_id,
                "superseded_by": None
            }).execute()

            if not new_warmup.data:
                logger.error("❌ Failed to create new warmup version")
                return None

            new_warmup_id = new_warmup.data[0]["id"]

            # Mark old version as superseded
            self.supabase.table("warmups").update({
                "is_current": False,
                "valid_to": now,
                "superseded_by": new_warmup_id
            }).eq("id", warmup_id).execute()

            logger.info(f"✅ Regenerated warmup: old_id={warmup_id}, new_id={new_warmup_id}, version={old_version + 1}")
            return new_warmup.data[0]
        except Exception as e:
            logger.error(f"❌ Failed to regenerate warmup: {e}")
            return None

    async def regenerate_stretches(
        self,
        stretch_id: str,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        user_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Regenerate stretches with SCD2 versioning (creates new version, marks old as superseded)."""
        now = datetime.utcnow().isoformat()

        # Get the current stretch
        try:
            current = self.supabase.table("stretches").select("*").eq(
                "id", stretch_id
            ).single().execute()

            if not current.data:
                logger.error(f"❌ Stretch {stretch_id} not found")
                return None

            old_stretch = current.data
            old_version = old_stretch.get("version_number", 1)
            parent_id = old_stretch.get("parent_stretch_id") or stretch_id
        except Exception as e:
            logger.error(f"❌ Failed to get current stretch: {e}")
            return None

        # Generate new stretch exercises
        stretch_exercises = await self.generate_stretches(
            exercises, duration_minutes, user_id=user_id,
        )

        try:
            # Create new version
            new_stretch = self.supabase.table("stretches").insert({
                "workout_id": workout_id,
                "exercises_json": stretch_exercises,
                "duration_minutes": duration_minutes,
                "version_number": old_version + 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_stretch_id": parent_id,
                "superseded_by": None
            }).execute()

            if not new_stretch.data:
                logger.error("❌ Failed to create new stretch version")
                return None

            new_stretch_id = new_stretch.data[0]["id"]

            # Mark old version as superseded
            self.supabase.table("stretches").update({
                "is_current": False,
                "valid_to": now,
                "superseded_by": new_stretch_id
            }).eq("id", stretch_id).execute()

            logger.info(f"✅ Regenerated stretch: old_id={stretch_id}, new_id={new_stretch_id}, version={old_version + 1}")
            return new_stretch.data[0]
        except Exception as e:
            logger.error(f"❌ Failed to regenerate stretches: {e}")
            return None

    def soft_delete_warmup(self, warmup_id: str) -> bool:
        """Soft delete warmup (mark as not current with valid_to set)."""
        now = datetime.utcnow().isoformat()
        try:
            self.supabase.table("warmups").update({
                "is_current": False,
                "valid_to": now
            }).eq("id", warmup_id).execute()
            logger.info(f"✅ Soft deleted warmup {warmup_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to soft delete warmup: {e}")
            return False

    def soft_delete_stretches(self, stretch_id: str) -> bool:
        """Soft delete stretches (mark as not current with valid_to set)."""
        now = datetime.utcnow().isoformat()
        try:
            self.supabase.table("stretches").update({
                "is_current": False,
                "valid_to": now
            }).eq("id", stretch_id).execute()
            logger.info(f"✅ Soft deleted stretch {stretch_id}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to soft delete stretch: {e}")
            return False

    async def generate_warmup_and_stretches_for_workout(
        self,
        workout_id: str,
        exercises: List[Dict],
        warmup_duration: int = 5,
        stretch_duration: int = 5,
        injuries: Optional[List[str]] = None,
        user_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Generate and store both warmup and stretches for a workout with variety tracking."""
        warmup = await self.create_warmup_for_workout(
            workout_id, exercises, warmup_duration, injuries, user_id
        )
        stretches = await self.create_stretches_for_workout(
            workout_id, exercises, stretch_duration, injuries, user_id
        )

        return {
            "warmup": warmup,
            "stretches": stretches
        }


# Singleton instance
_warmup_stretch_service: Optional[WarmupStretchService] = None


def get_warmup_stretch_service() -> WarmupStretchService:
    global _warmup_stretch_service
    if _warmup_stretch_service is None:
        _warmup_stretch_service = WarmupStretchService()
    return _warmup_stretch_service
