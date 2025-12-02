"""Service for generating warm-up and cool-down exercises with SCD2 versioning."""

import json
from datetime import datetime
from typing import List, Dict, Any, Optional
from openai import AsyncOpenAI
from core.config import get_settings
from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()

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
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.supabase = get_supabase().client  # Get the actual Supabase client

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
        injuries: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Generate dynamic warm-up based on workout exercises, considering injuries."""
        muscles = self.get_target_muscles(exercises)
        logger.info(f"🔥 Generating warmup for muscles: {muscles}")
        if injuries:
            logger.info(f"⚠️ User has injuries: {injuries} - generating safe warmup")

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

        prompt = f"""Generate a {duration_minutes}-minute dynamic warm-up routine for a workout targeting: {', '.join(muscles)}.
{injury_section}
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
{"- SAFETY FIRST: Only include exercises safe for someone with " + ", ".join(injuries) if injuries else ""}

Return ONLY valid JSON."""

        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=500,
                temperature=0.7,
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)
            warmups = result.get("exercises", [])

            logger.info(f"✅ Generated {len(warmups)} warm-up exercises")
            return warmups

        except Exception as e:
            logger.error(f"❌ Warm-up generation failed: {e}")
            return self._fallback_warmup(muscles)

    async def generate_stretches(
        self,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Generate cool-down stretches based on workout exercises, considering injuries."""
        muscles = self.get_target_muscles(exercises)
        logger.info(f"❄️ Generating stretches for muscles: {muscles}")
        if injuries:
            logger.info(f"⚠️ User has injuries: {injuries} - generating safe stretches")

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

        prompt = f"""Generate a {duration_minutes}-minute cool-down stretching routine for a workout that targeted: {', '.join(muscles)}.
{injury_section}
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
{"- SAFETY FIRST: Only include stretches safe for someone with " + ", ".join(injuries) if injuries else ""}

Return ONLY valid JSON."""

        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=500,
                temperature=0.7,
                response_format={"type": "json_object"}
            )

            result = json.loads(response.choices[0].message.content)
            stretches = result.get("exercises", [])

            logger.info(f"✅ Generated {len(stretches)} cool-down stretches")
            return stretches

        except Exception as e:
            logger.error(f"❌ Stretch generation failed: {e}")
            return self._fallback_stretches(muscles)

    def _fallback_warmup(self, muscles: List[str]) -> List[Dict]:
        """Static fallback warm-ups if AI fails."""
        warmups = []
        added = set()

        for muscle in muscles:
            exercise_list = WARMUP_BY_MUSCLE.get(muscle, WARMUP_BY_MUSCLE["full body"])
            for ex in exercise_list:
                if ex not in added and len(warmups) < 4:
                    warmups.append({
                        "name": ex,
                        "sets": 1,
                        "reps": 15,
                        "duration_seconds": 30,
                        "rest_seconds": 10,
                        "equipment": "none",
                        "muscle_group": muscle,
                        "notes": "Perform controlled movements"
                    })
                    added.add(ex)

        # Ensure at least some warmups
        if not warmups:
            for ex in WARMUP_BY_MUSCLE["full body"]:
                warmups.append({
                    "name": ex,
                    "sets": 1,
                    "reps": 15,
                    "duration_seconds": 30,
                    "rest_seconds": 10,
                    "equipment": "none",
                    "muscle_group": "full body",
                    "notes": "Perform controlled movements"
                })

        return warmups

    def _fallback_stretches(self, muscles: List[str]) -> List[Dict]:
        """Static fallback stretches if AI fails."""
        stretches = []
        added = set()

        for muscle in muscles:
            stretch_list = STRETCH_BY_MUSCLE.get(muscle, STRETCH_BY_MUSCLE["full body"])
            for stretch in stretch_list:
                if stretch not in added and len(stretches) < 5:
                    stretches.append({
                        "name": stretch,
                        "sets": 1,
                        "reps": 1,
                        "duration_seconds": 30,
                        "rest_seconds": 0,
                        "equipment": "none",
                        "muscle_group": muscle,
                        "notes": "Hold and breathe deeply"
                    })
                    added.add(stretch)

        # Ensure at least some stretches
        if not stretches:
            for stretch in STRETCH_BY_MUSCLE["full body"]:
                stretches.append({
                    "name": stretch,
                    "sets": 1,
                    "reps": 1,
                    "duration_seconds": 30,
                    "rest_seconds": 0,
                    "equipment": "none",
                    "muscle_group": "full body",
                    "notes": "Hold and breathe deeply"
                })

        return stretches

    async def create_warmup_for_workout(
        self,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        """Generate and store warmup for a workout with SCD2 versioning."""
        warmup_exercises = await self.generate_warmup(exercises, duration_minutes, injuries)
        now = datetime.utcnow().isoformat()

        try:
            result = self.supabase.table("warmups").insert({
                "workout_id": workout_id,
                "exercises_json": warmup_exercises,
                "duration_minutes": duration_minutes,
                "version_number": 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_warmup_id": None,
                "superseded_by": None
            }).execute()

            logger.info(f"✅ Created warmup for workout {workout_id}")
            return result.data[0] if result.data else None
        except Exception as e:
            logger.error(f"❌ Failed to save warmup: {e}")
            return None

    async def create_stretches_for_workout(
        self,
        workout_id: str,
        exercises: List[Dict],
        duration_minutes: int = 5,
        injuries: Optional[List[str]] = None
    ) -> Optional[Dict[str, Any]]:
        """Generate and store stretches for a workout with SCD2 versioning."""
        stretch_exercises = await self.generate_stretches(exercises, duration_minutes, injuries)
        now = datetime.utcnow().isoformat()

        try:
            result = self.supabase.table("stretches").insert({
                "workout_id": workout_id,
                "exercises_json": stretch_exercises,
                "duration_minutes": duration_minutes,
                "version_number": 1,
                "is_current": True,
                "valid_from": now,
                "valid_to": None,
                "parent_stretch_id": None,
                "superseded_by": None
            }).execute()

            logger.info(f"✅ Created stretches for workout {workout_id}")
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
        stretch_duration: int = 5
    ) -> Dict[str, Any]:
        """Generate and store both warmup and stretches for a workout."""
        warmup = await self.create_warmup_for_workout(workout_id, exercises, warmup_duration)
        stretches = await self.create_stretches_for_workout(workout_id, exercises, stretch_duration)

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
