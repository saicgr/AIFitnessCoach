"""
Gemini Service Cache Management - Vertex AI context cache lifecycle.
"""
import asyncio
import logging
from typing import Optional, Dict
from datetime import datetime, timedelta

from google.genai import types
from core.config import get_settings
from services.gemini.constants import client, cost_tracker, _log_token_usage

logger = logging.getLogger("gemini")


class CacheManagementMixin:
    """Mixin providing cache management methods for GeminiService."""

    @classmethod
    async def initialize_cache_manager(cls):
        """
        Initialize the cache manager on server startup.
        Call this from your FastAPI lifespan or startup event.

        This will:
        1. Clean up DUPLICATE caches (keep one per type, delete extras)
        2. Pre-warm caches by reusing existing server-side caches when possible
        No background refresh — caches refresh on-demand when requests come in.
        """
        if cls._initialized:
            logger.info("[CacheManager] Already initialized")
            return

        cls._initialized = True
        logger.info("[CacheManager] Initializing cache management (demand-driven, no background refresh)...")

        # Clean up duplicate caches (keep one per type)
        await cls._cleanup_old_caches()

        # Pre-warm by adopting existing server-side caches or creating new ones
        await cls._prewarm_cache()

        logger.info("✅ [CacheManager] Cache management initialized (demand-driven)")

    @classmethod
    async def shutdown_cache_manager(cls):
        """
        Shutdown the cache manager gracefully.
        Call this from your FastAPI shutdown event.
        """
        cls._initialized = False
        logger.info("[CacheManager] Cache manager shut down")

    @classmethod
    async def _cleanup_old_caches(cls):
        """Deduplicate caches: keep one per type, delete extras. Adopt surviving caches."""
        try:
            # Group caches by display_name prefix
            cache_groups: Dict[str, list] = {}
            cache_prefixes = ("workout_generation", "form_analysis", "nutrition_analysis")

            for cache in client.caches.list():
                if not cache.display_name:
                    continue
                for prefix in cache_prefixes:
                    if prefix in cache.display_name:
                        cache_groups.setdefault(prefix, []).append(cache)
                        break

            deleted_count = 0
            for prefix, caches in cache_groups.items():
                if len(caches) <= 1:
                    # One or zero caches — adopt it if it exists
                    if caches:
                        cls._adopt_existing_cache(prefix, caches[0])
                    continue

                # Sort by create_time descending (keep newest), fallback to name
                caches.sort(key=lambda c: getattr(c, 'create_time', '') or '', reverse=True)
                keeper = caches[0]
                cls._adopt_existing_cache(prefix, keeper)
                logger.info(f"[CacheManager] Keeping cache {keeper.name} for {prefix}")

                # Delete duplicates
                for dup in caches[1:]:
                    try:
                        client.caches.delete(name=dup.name)
                        cost_tracker.remove_cache(dup.name)
                        deleted_count += 1
                        logger.info(f"[CacheManager] Deleted duplicate cache: {dup.name}")
                    except Exception as e:
                        logger.warning(f"[CacheManager] Failed to delete cache {dup.name}: {e}", exc_info=True)

            if deleted_count > 0:
                logger.info(f"[CacheManager] Cleaned up {deleted_count} duplicate cache(s)")
        except Exception as e:
            logger.warning(f"[CacheManager] Cache cleanup failed: {e}", exc_info=True)

    @classmethod
    def _adopt_existing_cache(cls, prefix: str, cache) -> None:
        """Adopt an existing server-side cache into the in-memory class variables."""
        # Compute real created_at from expire_time (TTL is 3600s) to avoid hiding server-side age
        expire_time = getattr(cache, 'expire_time', None)
        if expire_time:
            created_at = expire_time.replace(tzinfo=None) - timedelta(seconds=3600)
            age_seconds = (datetime.now() - created_at).total_seconds()
            logger.info(f"[CacheManager] Cache expire_time={expire_time}, computed age={age_seconds:.0f}s")
        else:
            created_at = datetime.now()
            age_seconds = 0
            logger.info(f"[CacheManager] No expire_time on cache, using now as created_at")

        # Track cache tokens for cost tracking
        cache_tokens = 0
        cache_usage = getattr(cache, 'usage_metadata', None)
        if cache_usage:
            cache_tokens = getattr(cache_usage, 'total_token_count', 0) or 0

        if prefix == "workout_generation":
            cls._workout_cache = cache.name
            cls._workout_cache_created_at = created_at
            logger.info(f"[CacheManager] Adopted existing workout cache: {cache.name} (age: {age_seconds:.0f}s)")
        elif prefix == "form_analysis":
            cls._form_analysis_cache = cache.name
            cls._form_analysis_cache_created_at = created_at
            logger.info(f"[CacheManager] Adopted existing form analysis cache: {cache.name} (age: {age_seconds:.0f}s)")
        elif prefix == "nutrition_analysis":
            cls._nutrition_analysis_cache = cache.name
            cls._nutrition_analysis_cache_created_at = created_at
            logger.info(f"[CacheManager] Adopted existing nutrition analysis cache: {cache.name} (age: {age_seconds:.0f}s)")

        if cache_tokens > 0:
            cost_tracker.track_cache(cache.name, prefix, cache_tokens)

    @classmethod
    async def _prewarm_cache(cls):
        """Pre-warm caches that weren't already adopted from the server."""
        try:
            service = cls()

            # Only create caches that don't already exist (adopted from cleanup)
            cache_settings = get_settings()
            if not cache_settings.gemini_cache_enabled:
                logger.info("[CacheManager] Context caching disabled (gemini_cache_enabled=False), skipping all cache pre-warm")
                return

            if not cls._workout_cache:
                cache_name = await service._get_or_create_workout_cache()
                if cache_name:
                    logger.info(f"✅ [CacheManager] Workout cache pre-warmed: {cache_name}")
                else:
                    logger.warning("[CacheManager] Workout cache pre-warm failed, will create on first request")
            else:
                logger.info(f"[CacheManager] Workout cache already adopted, skipping pre-warm")

            if getattr(cache_settings, 'form_cache_enabled', True) is not False and cache_settings.gemini_cache_enabled:
                if not cls._form_analysis_cache:
                    form_cache = await service._get_or_create_form_analysis_cache()
                    if form_cache:
                        logger.info(f"✅ [CacheManager] Form analysis cache pre-warmed: {form_cache}")
                else:
                    logger.info(f"[CacheManager] Form analysis cache already adopted, skipping pre-warm")

            if getattr(cache_settings, 'nutrition_cache_enabled', True) is not False and cache_settings.gemini_cache_enabled:
                if not cls._nutrition_analysis_cache:
                    nutrition_cache = await service._get_or_create_nutrition_analysis_cache()
                    if nutrition_cache:
                        logger.info(f"✅ [CacheManager] Nutrition analysis cache pre-warmed: {nutrition_cache}")
                else:
                    logger.info(f"[CacheManager] Nutrition analysis cache already adopted, skipping pre-warm")
        except Exception as e:
            logger.warning(f"[CacheManager] Cache pre-warm failed: {e}", exc_info=True)

    @staticmethod
    def _find_existing_server_cache(display_name_prefix: str):
        """Check Vertex AI for an existing cache with the given display_name prefix."""
        try:
            for cache in client.caches.list():
                if cache.display_name and display_name_prefix in cache.display_name:
                    # Skip caches with <5 min remaining — not worth adopting
                    expire_time = getattr(cache, 'expire_time', None)
                    if expire_time:
                        from datetime import timezone
                        remaining = (expire_time - datetime.now(timezone.utc)).total_seconds()
                        if remaining < 300:
                            logger.info(f"[Cache] Skipping near-expiry cache {cache.name} ({remaining:.0f}s remaining)")
                            continue
                    return cache
        except Exception as e:
            logger.warning(f"[Cache] Failed to list server caches: {e}", exc_info=True)
        return None

    async def _get_or_create_workout_cache(self) -> Optional[str]:
        """
        Get existing workout generation cache or create a new one.
        Checks server-side first to avoid duplicates across workers.

        Returns:
            Cache name (str) if successful, None if caching fails (will fallback to non-cached)
        """
        if not get_settings().gemini_cache_enabled:
            return None
        async with type(self)._cache_lock:
            try:
                # Check in-memory reference first
                if type(self)._workout_cache and type(self)._workout_cache_created_at:
                    age_seconds = (datetime.now() - type(self)._workout_cache_created_at).total_seconds()
                    if age_seconds < 3000:  # 50 minutes
                        logger.debug(f"[Cache] Using existing workout cache (age: {age_seconds:.0f}s)")
                        return type(self)._workout_cache

                    logger.info(f"[Cache] Workout cache expiring (age: {age_seconds:.0f}s), refreshing...")

                # Check server-side for existing cache (prevents cross-worker duplication)
                existing = self._find_existing_server_cache("workout_generation")
                if existing:
                    type(self)._workout_cache = existing.name
                    # Compute real age from expire_time instead of using now()
                    expire_time = getattr(existing, 'expire_time', None)
                    if expire_time:
                        type(self)._workout_cache_created_at = expire_time.replace(tzinfo=None) - timedelta(seconds=3600)
                    else:
                        type(self)._workout_cache_created_at = datetime.now()
                    logger.info(f"[Cache] Reusing existing server-side workout cache: {existing.name}")
                    return existing.name

                # No cache exists anywhere — create a new one
                system_instruction = self._build_workout_cache_system_instruction()
                static_content = self._build_workout_cache_content()

                logger.info(f"[Cache] Creating new workout generation cache...")

                cache = client.caches.create(
                    model=self.model,
                    config=types.CreateCachedContentConfig(
                        display_name="workout_generation_v1",
                        system_instruction=system_instruction,
                        contents=[static_content],
                        ttl="3600s",
                    )
                )

                type(self)._workout_cache = cache.name
                type(self)._workout_cache_created_at = datetime.now()

                logger.info(f"✅ [Cache] Created new workout cache: {cache.name}")
                _log_token_usage(None, "create_workout_cache", user_id="system")
                # Track cache tokens for cost tracking
                cache_usage = getattr(cache, 'usage_metadata', None)
                if cache_usage:
                    ct = getattr(cache_usage, 'total_token_count', 0) or 0
                    if ct > 0:
                        cost_tracker.track_cache(cache.name, "workout_generation", ct)
                return cache.name

            except Exception as e:
                logger.warning(f"⚠️ [Cache] Failed to create workout cache: {e}", exc_info=True)
                return None

    def _build_workout_cache_system_instruction(self) -> str:
        """
        Build the system instruction for workout generation.
        This is static content that applies to ALL workout requests.
        """
        return """You are FitWiz AI, an expert fitness coach that generates personalized workout plans.

## YOUR ROLE
- Generate safe, effective, personalized workout plans
- Include detailed set_targets for every exercise
- Respect user equipment, fitness level, and preferences
- Create varied, engaging workouts with creative names

## OUTPUT FORMAT
Always return valid JSON matching the exact schema provided. No markdown, no explanations.

## EXERCISE SELECTION RULES
1. Match exercises to available equipment — if user has gym equipment, MOST exercises MUST use it
2. Include compound movements first (squat, press, row, deadlift variations), then isolation
3. Balance push/pull for upper body days
4. Include proper warm-up sets at lighter weights
5. Scale difficulty to fitness level
6. NEVER select cardio warm-up moves (jumping jacks, high knees, arm circles, clap jacks) as main workout exercises
7. Every exercise must build strength or muscle — no filler moves that belong in a warm-up
8. When gym equipment is available: use barbell/dumbbell/cable/machine movements with progressive overload potential
9. When bodyweight only: use challenging progressions (push-up variations, pistol squats, pull-ups, dips, L-sits, Nordic curls) — NOT easy cardio moves

## SET TARGET RULES
Every exercise MUST have a "set_targets" array. Each set target includes:
- set_number: 1, 2, 3, etc.
- set_type: "warmup", "working", "drop", "failure", or "amrap"
- target_reps: Number of reps for this set
- target_weight_kg: Weight in kg (0 for bodyweight)
- target_rpe: Rate of Perceived Exertion (1-10)

### Set Type Guidelines:
- WARMUP (W): First 1-2 sets, 50-70% working weight, RPE 4-6
- WORKING: Main sets at target intensity, RPE 7-9
- DROP (D): Reduced weight after working sets, RPE 8-9
- FAILURE (F): Final set to muscular failure, RPE 10
- AMRAP (A): As Many Reps As Possible, RPE 9-10

### Weight Progression Example:
For a 3-set exercise at 20kg working weight:
- Set 1: warmup, 12 reps, 10kg, RPE 5
- Set 2: working, 10 reps, 20kg, RPE 7
- Set 3: working, 10 reps, 20kg, RPE 8

## SAFETY RULES
- Never exceed safe limits for fitness level
- MINIMUM 3 working sets per exercise for ALL fitness levels (never generate 1 or 2 working sets)
- Beginners: 3 sets per exercise, 10-15 reps (isolation up to 15, compounds max 12)
- Intermediate: 3-5 sets per exercise, 8-12 reps (isolation up to 15, compounds max 12)
- Advanced: 4-6 sets per exercise, 6-10 reps (compounds max 12, isolation max 15)
- NEVER generate more than 12 reps for compound exercises (squat, deadlift, press, row, pull-up, lunge, dip, pulldown)
- NEVER generate more than 15 reps for isolation exercises (curl, extension, raise, fly)
- Always include adequate rest (60-180s based on intensity)
- Reduce intensity for seniors (60+)

## EQUIPMENT USAGE (CRITICAL)
When gym equipment is available:
- AT LEAST 4-5 exercises MUST use equipment (NOT bodyweight)
- Maximum 1-2 bodyweight exercises allowed
- For beginners with gym: Use machines & dumbbells
- NEVER generate mostly bodyweight when gym equipment is available"""

    def _build_workout_cache_content(self) -> str:
        """
        Build the static content to cache.
        This includes examples, rules, and guidelines that don't change per request.
        """
        return """## DIFFICULTY SCALING BY FITNESS LEVEL

### Beginner
- Sets per exercise: 3 (MINIMUM 3 working sets - NEVER use 2 sets)
- Rep range: 10-15
- Rest periods: 90-120 seconds
- RPE range: 5-7
- Focus: Form and technique
- Equipment preference: Machines, dumbbells

### Intermediate
- Sets per exercise: 3-4
- Rep range: 8-12
- Rest periods: 60-90 seconds
- RPE range: 7-8
- Focus: Progressive overload
- Equipment preference: Free weights, cables

### Advanced
- Sets per exercise: 4-5
- Rep range: 6-10
- Rest periods: 60-120 seconds (longer for heavy compounds)
- RPE range: 8-10
- Focus: Intensity techniques (drops, failure)
- Equipment preference: Barbells, specialty equipment

## JSON SCHEMA EXAMPLE

```json
{
  "name": "Creative Workout Name",
  "type": "strength",
  "difficulty": "medium",
  "duration_minutes": 45,
  "target_muscles": ["chest", "triceps", "shoulders"],
  "exercises": [
    {
      "name": "Dumbbell Bench Press",
      "sets": 4,
      "reps": 10,
      "rest_seconds": 90,
      "equipment": "dumbbells",
      "muscle_group": "chest",
      "notes": "Keep back flat, full range of motion",
      "set_targets": [
        {"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 10, "target_rpe": 5},
        {"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 7},
        {"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 8},
        {"set_number": 4, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 9}
      ]
    }
  ],
  "notes": "Focus on controlled movements"
}
```

## INTENSITY PREFERENCES

### Easy
- Lower weights, higher reps (12-15)
- Longer rest periods (90-120s)
- RPE 5-7, no failure sets
- Good for: Recovery days, beginners, seniors

### Medium (Default)
- Moderate weights, standard reps (8-12)
- Standard rest periods (60-90s)
- RPE 7-8, occasional failure
- Good for: General fitness, maintenance

### Hard
- Heavier weights, lower reps (6-10)
- Standard rest periods (60-90s)
- RPE 8-9, failure on last sets
- Good for: Building strength, intermediate+

### Hell Mode
- Maximum intensity throughout
- Include drop sets and failure sets
- RPE 9-10, multiple techniques
- Good for: Advanced users only

## DURATION CALCULATION
Calculate estimated_duration_minutes:
- Per exercise: (sets × (reps × 3s + rest_seconds)) / 60
- Add 30s transition between exercises
- Total must not exceed duration_minutes_max

## WORKOUT NAMING
Create engaging, creative names that:
- Reflect the workout focus and target muscles (Push Power, Leg Day Blast, Iron Back)
- Are motivating and memorable
- Avoid generic names like "Workout 1"
- Do NOT use holiday, seasonal, or calendar themes — name should describe the TRAINING, not the date"""

    async def _get_or_create_form_analysis_cache(self) -> Optional[str]:
        """
        Get existing form analysis cache or create a new one.
        Checks server-side first to avoid duplicates across workers.
        """
        if not get_settings().gemini_cache_enabled:
            return None
        async with type(self)._form_cache_lock:
            try:
                if type(self)._form_analysis_cache and type(self)._form_analysis_cache_created_at:
                    age_seconds = (datetime.now() - type(self)._form_analysis_cache_created_at).total_seconds()
                    if age_seconds < 3000:
                        logger.debug(f"[Cache] Using existing form analysis cache (age: {age_seconds:.0f}s)")
                        return type(self)._form_analysis_cache

                    logger.info(f"[Cache] Form analysis cache expiring (age: {age_seconds:.0f}s), refreshing...")

                # Check server-side for existing cache
                existing = self._find_existing_server_cache("form_analysis")
                if existing:
                    type(self)._form_analysis_cache = existing.name
                    expire_time = getattr(existing, 'expire_time', None)
                    if expire_time:
                        type(self)._form_analysis_cache_created_at = expire_time.replace(tzinfo=None) - timedelta(seconds=3600)
                    else:
                        type(self)._form_analysis_cache_created_at = datetime.now()
                    logger.info(f"[Cache] Reusing existing server-side form analysis cache: {existing.name}")
                    return existing.name

                system_instruction = self._build_form_analysis_cache_system_instruction()
                static_content = self._build_form_analysis_cache_content()

                logger.info(f"[Cache] Creating new form analysis cache...")

                cache = client.caches.create(
                    model=self.model,
                    config=types.CreateCachedContentConfig(
                        display_name="form_analysis_v1",
                        system_instruction=system_instruction,
                        contents=[static_content],
                        ttl="3600s",
                    )
                )

                type(self)._form_analysis_cache = cache.name
                type(self)._form_analysis_cache_created_at = datetime.now()

                logger.info(f"✅ [Cache] Created new form analysis cache: {cache.name}")
                _log_token_usage(None, "create_form_cache", user_id="system")
                cache_usage = getattr(cache, 'usage_metadata', None)
                if cache_usage:
                    ct = getattr(cache_usage, 'total_token_count', 0) or 0
                    if ct > 0:
                        cost_tracker.track_cache(cache.name, "form_analysis", ct)
                return cache.name

            except Exception as e:
                logger.warning(f"⚠️ [Cache] Failed to create form analysis cache: {e}", exc_info=True)
                return None

    async def _get_or_create_nutrition_analysis_cache(self) -> Optional[str]:
        """
        Get existing nutrition analysis cache or create a new one.
        Checks server-side first to avoid duplicates across workers.
        """
        if not get_settings().gemini_cache_enabled:
            return None
        async with type(self)._nutrition_cache_lock:
            try:
                if type(self)._nutrition_analysis_cache and type(self)._nutrition_analysis_cache_created_at:
                    age_seconds = (datetime.now() - type(self)._nutrition_analysis_cache_created_at).total_seconds()
                    if age_seconds < 3000:
                        logger.debug(f"[Cache] Using existing nutrition analysis cache (age: {age_seconds:.0f}s)")
                        return type(self)._nutrition_analysis_cache

                    logger.info(f"[Cache] Nutrition analysis cache expiring (age: {age_seconds:.0f}s), refreshing...")

                # Check server-side for an existing v2 cache. Using the exact
                # version string so a pre-existing v1 cache (without the
                # inflammation/UPF rubrics) won't get adopted — v1 callers were
                # dropping inflammation_score for plate mode.
                existing = self._find_existing_server_cache("nutrition_analysis_v2")
                if existing:
                    type(self)._nutrition_analysis_cache = existing.name
                    expire_time = getattr(existing, 'expire_time', None)
                    if expire_time:
                        type(self)._nutrition_analysis_cache_created_at = expire_time.replace(tzinfo=None) - timedelta(seconds=3600)
                    else:
                        type(self)._nutrition_analysis_cache_created_at = datetime.now()
                    logger.info(f"[Cache] Reusing existing server-side nutrition analysis cache: {existing.name}")
                    return existing.name

                system_instruction = self._build_nutrition_analysis_cache_system_instruction()
                static_content = self._build_nutrition_analysis_cache_content()

                logger.info(f"[Cache] Creating new nutrition analysis cache...")

                cache = client.caches.create(
                    model=self.model,
                    config=types.CreateCachedContentConfig(
                        # v2: adds inflammation + is_ultra_processed rubrics so
                        # plate-mode responses carry the fields (2026-04-23).
                        display_name="nutrition_analysis_v2",
                        system_instruction=system_instruction,
                        contents=[static_content],
                        ttl="3600s",
                    )
                )

                type(self)._nutrition_analysis_cache = cache.name
                type(self)._nutrition_analysis_cache_created_at = datetime.now()

                logger.info(f"✅ [Cache] Created new nutrition analysis cache: {cache.name}")
                _log_token_usage(None, "create_nutrition_cache", user_id="system")
                cache_usage = getattr(cache, 'usage_metadata', None)
                if cache_usage:
                    ct = getattr(cache_usage, 'total_token_count', 0) or 0
                    if ct > 0:
                        cost_tracker.track_cache(cache.name, "nutrition_analysis", ct)
                return cache.name

            except Exception as e:
                logger.warning(f"⚠️ [Cache] Failed to create nutrition analysis cache: {e}", exc_info=True)
                return None
