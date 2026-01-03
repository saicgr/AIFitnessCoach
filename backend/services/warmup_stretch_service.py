"""Service for generating warm-up and cool-down exercises with SCD2 versioning."""

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from google import genai
from google.genai import types
from core.config import get_settings
from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

# Initialize Gemini client
client = genai.Client(api_key=settings.gemini_api_key)

# Movement type classification for warmup ordering
# Static holds should come EARLY, followed by dynamic movements
# This addresses user feedback: "warm-ups should have static holds early, not intermixed with kinetic moves"
STATIC_EXERCISE_KEYWORDS = [
    "hold", "plank", "wall sit", "dead hang", "isometric", "static",
    "l-sit", "hollow", "bridge hold", "superman hold", "glute bridge hold"
]

DYNAMIC_EXERCISE_KEYWORDS = [
    "jumping", "circles", "swings", "jacks", "high knees", "butt kicks",
    "skips", "march", "rotation", "twist", "lunge walk", "inchworm",
    "mountain climber", "bear crawl", "carioca", "shuffle"
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
    "chest": ["Arm Circles", "Chest Opener Stretch", "Push-up Plus"],
    "back": ["Cat-Cow Stretch", "Arm Swings", "Thoracic Rotation"],
    "shoulders": ["Arm Circles", "Shoulder Rolls", "Band Pull-Aparts"],
    "legs": ["Leg Swings", "Walking Lunges", "High Knees"],
    "quadriceps": ["Leg Swings", "Walking Lunges", "High Knees"],
    "hamstrings": ["Leg Swings", "Inchworms", "Good Mornings"],
    "calves": ["Ankle Circles", "Calf Raises", "Jump Rope"],
    "arms": ["Arm Circles", "Wrist Rotations", "Arm Swings"],
    "biceps": ["Arm Circles", "Wrist Rotations", "Light Curls"],
    "triceps": ["Arm Circles", "Tricep Stretches", "Arm Swings"],
    "core": ["Torso Twists", "Cat-Cow", "Dead Bug"],
    "abs": ["Torso Twists", "Cat-Cow", "Dead Bug"],
    "glutes": ["Hip Circles", "Glute Bridges", "Fire Hydrants"],
    "full body": ["Jumping Jacks", "Arm Circles", "Leg Swings", "Torso Twists"],
}

# Muscle group to stretch mapping (fallback)
STRETCH_BY_MUSCLE = {
    "chest": ["Doorway Chest Stretch", "Chest Opener", "Supine Chest Stretch"],
    "back": ["Child's Pose", "Cat-Cow Stretch", "Seated Spinal Twist"],
    "shoulders": ["Cross-Body Shoulder Stretch", "Overhead Tricep Stretch", "Thread The Needle"],
    "legs": ["Quad Stretch", "Hamstring Stretch", "Calf Stretch"],
    "quadriceps": ["Standing Quad Stretch", "Lying Quad Stretch", "Kneeling Hip Flexor Stretch"],
    "hamstrings": ["Standing Hamstring Stretch", "Seated Hamstring Stretch", "Lying Hamstring Stretch"],
    "calves": ["Standing Calf Stretch", "Downward Dog", "Wall Calf Stretch"],
    "arms": ["Bicep Wall Stretch", "Tricep Stretch", "Wrist Flexor Stretch"],
    "biceps": ["Bicep Wall Stretch", "Doorway Bicep Stretch", "Behind Back Clasp"],
    "triceps": ["Overhead Tricep Stretch", "Cross-Body Tricep Stretch", "Behind Head Stretch"],
    "core": ["Cobra Stretch", "Supine Twist", "Seated Side Bend"],
    "abs": ["Cobra Stretch", "Supine Twist", "Standing Side Bend"],
    "glutes": ["Pigeon Pose", "Figure-4 Stretch", "Seated Glute Stretch"],
    "full body": ["Child's Pose", "Standing Forward Fold", "Supine Twist", "Quad Stretch"],
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
        use_library: bool = True
    ) -> List[Dict[str, Any]]:
        """Generate dynamic warm-up based on workout exercises, considering injuries and variety.

        Args:
            exercises: List of workout exercises to warmup for
            duration_minutes: Target duration for warmup
            injuries: List of user injuries to avoid aggravating
            avoid_exercises: List of exercise names to avoid for variety
            use_library: If True, try to use exercises from library with videos first
        """
        muscles = self.get_target_muscles(exercises)
        logger.info(f"🔥 Generating warmup for muscles: {muscles}")
        if injuries:
            logger.info(f"⚠️ User has injuries: {injuries} - generating safe warmup")
        if avoid_exercises:
            logger.info(f"🔄 Avoiding {len(avoid_exercises)} recently used warmup exercises for variety")

        # Try to get warmups from library first (with videos!)
        if use_library:
            library_warmups = await self.get_warmup_exercises_from_library(
                target_muscles=muscles,
                avoid_exercises=avoid_exercises,
                limit=4
            )
            if library_warmups and len(library_warmups) >= 3:
                # Order library warmups: static first, then dynamic
                library_warmups = order_warmup_exercises(library_warmups)
                logger.info(f"📹 Using {len(library_warmups)} warmup exercises from library with videos (ordered)")
                return library_warmups
            else:
                logger.info("⚠️ Not enough warmup exercises from library, falling back to AI generation")

        # Fall back to AI generation if library doesn't have enough
        # Build injury awareness section
        injury_section = ""
        if injuries and len(injuries) > 0:
            injury_list = ", ".join(injuries)
            injury_section = f"""
⚠️ CRITICAL - USER HAS INJURIES: {injury_list}
You MUST avoid warmup exercises that could aggravate these conditions:
- For leg/knee issues: NO lunges, squats, jumping, high knees
- For back issues: NO forward folds, twisting under load, hyperextensions
- For shoulder issues: NO overhead movements, arm circles with load
- For wrist issues: NO weight-bearing on hands
- For hip issues: NO deep hip flexion, leg swings with large ROM
Only include gentle, safe warmup movements appropriate for someone with {injury_list}.
"""

        # Build variety section - avoid recently used exercises with stronger variety emphasis
        variety_section = ""
        if avoid_exercises and len(avoid_exercises) > 0:
            avoid_list = ", ".join(avoid_exercises[:15])  # Increased to 15 for better filtering
            variety_section = f"""
🔄 CRITICAL - EXERCISE VARIETY REQUIRED:
You MUST avoid these recently used warmup exercises: {avoid_list}
DO NOT repeat any of the above exercises. Choose COMPLETELY DIFFERENT movements.
Be creative and select alternative warmup exercises that target the same muscle groups.
Examples of good alternatives:
- Instead of Arm Circles → Shoulder Shrugs, Band Pull-Aparts, Wall Angels
- Instead of Leg Swings → Hip Circles, Glute Bridges, Monster Walks
- Instead of High Knees → Butt Kicks, A-Skips, Lateral Shuffles
"""

        prompt = f"""Generate a {duration_minutes}-minute dynamic warm-up routine for a workout targeting: {', '.join(muscles)}.
{injury_section}{variety_section}
IMPORTANT: Create a UNIQUE warmup routine that differs from typical generic warmups.
Return JSON with "exercises" array containing 3-4 warm-up exercises:
{{
  "exercises": [
    {{
      "name": "Exercise Name",
      "sets": 1,
      "reps": 15,
      "duration_seconds": 30,
      "rest_seconds": 10,
      "equipment": "none",
      "muscle_group": "target muscle",
      "notes": "Brief form cue"
    }}
  ]
}}

Focus on:
- Dynamic movements (not static holds)
- Progressively increasing range of motion
- Activating muscles that will be used in the workout
- No equipment needed
- VARIETY: Select exercises you haven't used recently
{"- SAFETY FIRST: Only include exercises safe for someone with " + ", ".join(injuries) if injuries else ""}

Return ONLY valid JSON."""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=3000,  # Increased for thinking models
                    temperature=0.9,  # Higher temperature for more variety
                ),
            )

            content = response.text.strip()
            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            result = json.loads(content.strip())
            warmups = result.get("exercises", [])

            # Order warmups: static holds first, then dynamic movements
            warmups = order_warmup_exercises(warmups)

            logger.info(f"✅ Generated {len(warmups)} warm-up exercises (ordered: static first, dynamic after)")
            return warmups

        except Exception as e:
            logger.error(f"❌ Warm-up generation failed: {e}")
            raise  # No fallback - let errors propagate

    async def generate_stretches(
        self,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None,
        avoid_exercises: Optional[List[str]] = None,
        use_library: bool = True
    ) -> List[Dict[str, Any]]:
        """Generate cool-down stretches based on workout exercises, considering injuries and variety.

        Args:
            exercises: List of workout exercises to stretch after
            duration_minutes: Target duration for stretching
            injuries: List of user injuries to avoid aggravating
            avoid_exercises: List of exercise names to avoid for variety
            use_library: If True, try to use exercises from library with videos first
        """
        muscles = self.get_target_muscles(exercises)
        logger.info(f"❄️ Generating stretches for muscles: {muscles}")
        if injuries:
            logger.info(f"⚠️ User has injuries: {injuries} - generating safe stretches")
        if avoid_exercises:
            logger.info(f"🔄 Avoiding {len(avoid_exercises)} recently used stretch exercises for variety")

        # Try to get stretches from library first (with videos!)
        if use_library:
            library_stretches = await self.get_stretch_exercises_from_library(
                target_muscles=muscles,
                avoid_exercises=avoid_exercises,
                limit=5
            )
            if library_stretches and len(library_stretches) >= 4:
                logger.info(f"📹 Using {len(library_stretches)} stretch exercises from library with videos")
                return library_stretches
            else:
                logger.info("⚠️ Not enough stretch exercises from library, falling back to AI generation")

        # Fall back to AI generation if library doesn't have enough
        # Build injury awareness section
        injury_section = ""
        if injuries and len(injuries) > 0:
            injury_list = ", ".join(injuries)
            injury_section = f"""
⚠️ CRITICAL - USER HAS INJURIES: {injury_list}
You MUST avoid stretches that could aggravate these conditions:
- For leg/knee issues: NO deep squatting stretches, lunging stretches
- For back issues: NO forward folds with straight legs, twisting stretches
- For shoulder issues: NO behind-the-back stretches, overhead reaches
- For wrist issues: NO weight-bearing stretches on hands
- For hip issues: NO deep hip flexor stretches, pigeon pose variations
Only include gentle, safe stretches appropriate for someone with {injury_list}.
"""

        # Build variety section - avoid recently used exercises with stronger variety emphasis
        variety_section = ""
        if avoid_exercises and len(avoid_exercises) > 0:
            avoid_list = ", ".join(avoid_exercises[:15])  # Increased to 15 for better filtering
            variety_section = f"""
🔄 CRITICAL - EXERCISE VARIETY REQUIRED:
You MUST avoid these recently used stretch exercises: {avoid_list}
DO NOT repeat any of the above stretches. Choose COMPLETELY DIFFERENT stretches.
Be creative and select alternative stretches that target the same muscle groups.
Examples of good alternatives:
- Instead of Child's Pose → Cat-Cow, Thread the Needle, Puppy Pose
- Instead of Quad Stretch → Pigeon Pose, Couch Stretch, 90-90 Stretch
- Instead of Hamstring Stretch → RDL Stretch, Good Morning Stretch, Pyramid Pose
"""

        prompt = f"""Generate a {duration_minutes}-minute cool-down stretching routine for a workout that targeted: {', '.join(muscles)}.
{injury_section}{variety_section}
IMPORTANT: Create a UNIQUE stretch routine that differs from typical generic stretching.
Return JSON with "exercises" array containing 4-5 stretches:
{{
  "exercises": [
    {{
      "name": "Stretch Name",
      "sets": 1,
      "reps": 1,
      "duration_seconds": 30,
      "rest_seconds": 0,
      "equipment": "none",
      "muscle_group": "target muscle",
      "notes": "Hold position, breathe deeply"
    }}
  ]
}}

Focus on:
- Static stretches (held positions)
- 20-30 second holds per stretch
- Target all muscles used in the workout
- Promote relaxation and recovery
- VARIETY: Select stretches you haven't used recently
{"- SAFETY FIRST: Only include stretches safe for someone with " + ", ".join(injuries) if injuries else ""}

Return ONLY valid JSON."""

        try:
            response = await client.aio.models.generate_content(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    max_output_tokens=3000,  # Increased for thinking models
                    temperature=0.9,  # Higher temperature for more variety
                ),
            )

            content = response.text.strip()
            # Clean markdown if present
            if content.startswith("```json"):
                content = content[7:]
            elif content.startswith("```"):
                content = content[3:]
            if content.endswith("```"):
                content = content[:-3]

            result = json.loads(content.strip())
            stretches = result.get("exercises", [])

            logger.info(f"✅ Generated {len(stretches)} cool-down stretches")
            return stretches

        except Exception as e:
            logger.error(f"❌ Stretch generation failed: {e}")
            raise  # No fallback - let errors propagate

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
            exercises, duration_minutes, injuries, avoid_exercises
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
            exercises, duration_minutes, injuries, avoid_exercises
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
        duration_minutes: int = 5
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
        warmup_exercises = await self.generate_warmup(exercises, duration_minutes)

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
        duration_minutes: int = 5
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
        stretch_exercises = await self.generate_stretches(exercises, duration_minutes)

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
