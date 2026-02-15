"""
Gemini Service - Handles all Gemini AI API interactions.

EASY TO MODIFY:
- Change model: Update GEMINI_MODEL in .env
- Adjust prompts: Modify the prompt strings below
- Add new methods: Follow the pattern of existing methods

Uses the new google-genai SDK (unified SDK for Gemini API).
"""
from google import genai
from core.gemini_client import get_genai_client
from google.genai import types
from typing import List, Dict, Optional
import json
import logging
import asyncio
import time
from core.config import get_settings
from models.chat import IntentExtraction, CoachIntent
from models.gemini_schemas import (
    IntentExtractionResponse,
    ExerciseListResponse,
    GeneratedWorkoutResponse,
    WorkoutNamesResponse,
    WorkoutNamingResponse,
    ExerciseReasoningResponse,
    FoodAnalysisResponse,
    InflammationAnalysisGeminiResponse,
    DailyMealPlanResponse,
    MealSuggestionsResponse,
    SnackSuggestionsResponse,
    ParseWorkoutInputResponse,
    ParseWorkoutInputV2Response,
)
import re as regex_module  # For weight parsing
import hashlib
from datetime import datetime, timedelta

# Import split descriptions for rich AI context
from services.split_descriptions import SPLIT_DESCRIPTIONS, get_split_context
from core.anonymize import age_to_bracket

# Import centralized AI response parser
from core.ai_response_parser import parse_ai_json

settings = get_settings()
logger = logging.getLogger("gemini")


# ===========================================================================
# In-Memory Response Cache for Repeated Gemini API Queries
# ===========================================================================

class ResponseCache:
    """Simple TTL cache for Gemini API responses to avoid redundant calls."""

    def __init__(self, ttl_seconds: int = 300, max_size: int = 200):
        self._cache: dict = {}
        self._ttl = timedelta(seconds=ttl_seconds)
        self._max_size = max_size

    def get(self, key: str):
        """Get a cached value if it exists and hasn't expired."""
        if key in self._cache:
            cached_at, value = self._cache[key]
            if datetime.now() - cached_at < self._ttl:
                return value
            # Expired - remove it
            del self._cache[key]
        return None

    def set(self, key: str, value):
        """Store a value in the cache, evicting oldest if at capacity."""
        # Evict oldest entry if at capacity
        if len(self._cache) >= self._max_size:
            oldest_key = min(self._cache, key=lambda k: self._cache[k][0])
            del self._cache[oldest_key]
        self._cache[key] = (datetime.now(), value)

    @staticmethod
    def make_key(*args) -> str:
        """Create a deterministic cache key from arguments."""
        return hashlib.md5(
            json.dumps(args, sort_keys=True, default=str).encode()
        ).hexdigest()


# Module-level caches with purpose-tuned TTLs and sizes
_summary_cache = ResponseCache(ttl_seconds=3600, max_size=100)   # 1hr for workout summaries
_intent_cache = ResponseCache(ttl_seconds=600, max_size=200)     # 10min for intent extraction
_food_text_cache = ResponseCache(ttl_seconds=1800, max_size=150) # 30min for food text analysis
_embedding_cache = ResponseCache(ttl_seconds=3600, max_size=500) # 1hr for embedding vectors


def safe_join_list(items, default: str = "") -> str:
    """
    Safely join a list of items that might contain strings or dicts.

    This handles the case where goals, equipment, etc. might be stored as
    dictionaries instead of strings (e.g., [{"name": "weight_loss"}]).

    Args:
        items: List of strings or dicts to join
        default: Default value if items is empty or None

    Returns:
        Comma-separated string of items
    """
    if not items:
        return default

    result = []
    for item in items:
        if isinstance(item, str):
            if item.strip():
                result.append(item.strip())
        elif isinstance(item, dict):
            # Try common keys for name
            name = (
                item.get("name") or
                item.get("goal") or
                item.get("title") or
                item.get("value") or
                item.get("id") or
                str(item)
            )
            if name and isinstance(name, str):
                result.append(name.strip())
        else:
            result.append(str(item))

    return ", ".join(result) if result else default


def infer_set_type(exercise: Dict, set_target: Dict, set_index: int, total_sets: int) -> str:
    """
    Infer set_type from context when Gemini omits it (safety net).

    Inference rules based on prompt guidelines:
    1. RPE 10 or RIR 0 → failure
    2. Exercise marked is_failure_set and last set → failure
    3. Exercise marked is_drop_set and one of last N sets → drop
    4. First set of weighted exercise → warmup
    5. Default → working
    """
    target_rpe = set_target.get('target_rpe')
    target_rir = set_target.get('target_rir')
    target_weight = set_target.get('target_weight_kg')
    set_num = set_target.get('set_number', set_index + 1)

    # Failure indicators: RPE 10 or RIR 0
    if target_rpe == 10 or target_rir == 0:
        return "failure"

    # Exercise marked as failure set and this is the last set
    if exercise.get('is_failure_set') and set_index == total_sets - 1:
        return "failure"

    # Drop set detection: last N sets where N = drop_set_count
    if exercise.get('is_drop_set'):
        drop_count = exercise.get('drop_set_count', 2)
        if set_index >= total_sets - drop_count:
            return "drop"

    # First set of weighted exercise = warmup
    if set_num == 1 and target_weight and target_weight > 0:
        return "warmup"

    # Default to working
    return "working"


def validate_set_targets_strict(exercises: List[Dict], user_context: Dict = None) -> List[Dict]:
    """
    STRICTLY validates that every exercise has set_targets array from Gemini.
    FAILS (raises exception) if any exercise is missing set_targets - NO FALLBACK DATA.

    Also validates set_type values (W=warmup, D=drop, F=failure, A=amrap, or working).

    Args:
        exercises: List of exercise dictionaries from Gemini
        user_context: Optional dict with user info for logging (user_id, fitness_level, etc.)

    Returns:
        List of exercises if all valid

    Raises:
        ValueError: If any exercise is missing set_targets or has invalid set types
    """
    # Log user context for debugging
    if user_context:
        logger.info(f"🔍 [set_targets] Validating for user context:")
        logger.info(f"   - user_id: {user_context.get('user_id', 'unknown')}")
        logger.info(f"   - fitness_level: {user_context.get('fitness_level', 'unknown')}")
        logger.info(f"   - difficulty: {user_context.get('difficulty', 'unknown')}")
        logger.info(f"   - goals: {user_context.get('goals', [])}")
        logger.info(f"   - equipment: {user_context.get('equipment', [])}")

    missing_targets = []
    invalid_set_types = []
    valid_set_types = {'warmup', 'working', 'drop', 'failure', 'amrap'}

    # Count set types across all exercises
    set_type_counts = {'warmup': 0, 'working': 0, 'drop': 0, 'failure': 0, 'amrap': 0}
    total_sets = 0

    for exercise in exercises:
        # Ensure exercise is a dict (could be a string from malformed Gemini response)
        if isinstance(exercise, str):
            try:
                exercise = json.loads(exercise)
            except (json.JSONDecodeError, ValueError):
                logger.error(f"❌ [set_targets] Exercise is an unparseable string: {exercise[:100]}")
                continue
        if not isinstance(exercise, dict):
            logger.error(f"❌ [set_targets] Exercise is not a dict: type={type(exercise).__name__}")
            continue

        ex_name = exercise.get('name', 'Unknown')
        set_targets = exercise.get("set_targets")

        # Handle set_targets being a JSON string instead of a list
        if isinstance(set_targets, str):
            try:
                set_targets = json.loads(set_targets)
                exercise["set_targets"] = set_targets
            except (json.JSONDecodeError, ValueError):
                logger.error(f"❌ [set_targets] set_targets is an unparseable string for '{ex_name}'")
                set_targets = None

        if not set_targets:
            missing_targets.append(ex_name)
            logger.error(f"❌ [set_targets] MISSING for '{ex_name}' - Gemini FAILED to generate!")
            continue

        # Ensure set_targets is a list
        if not isinstance(set_targets, list):
            missing_targets.append(ex_name)
            logger.error(f"❌ [set_targets] set_targets is not a list for '{ex_name}': type={type(set_targets).__name__}")
            continue

        # Validate each set target has proper set_type (W, D, F, A indicators)
        logger.info(f"✅ [set_targets] '{ex_name}' has {len(set_targets)} targets:")
        for idx, st in enumerate(set_targets):
            # Ensure each set target is a dict (could be a string)
            if isinstance(st, str):
                try:
                    st = json.loads(st)
                    set_targets[idx] = st
                except (json.JSONDecodeError, ValueError):
                    logger.warning(f"⚠️ [set_targets] Skipping unparseable set_target string for '{ex_name}' set {idx + 1}")
                    continue
            if not isinstance(st, dict):
                logger.warning(f"⚠️ [set_targets] Skipping non-dict set_target for '{ex_name}' set {idx + 1}: type={type(st).__name__}")
                continue

            total_sets += 1
            set_num = st.get('set_number', idx + 1)
            set_type = st.get('set_type')
            target_reps = st.get('target_reps', 0)
            target_weight = st.get('target_weight_kg')
            target_rpe = st.get('target_rpe')

            # Auto-fill missing set_type using smart inference (safety net)
            if not set_type:
                set_type = infer_set_type(exercise, st, idx, len(set_targets))
                st['set_type'] = set_type  # Mutate the dict to add the inferred value
                logger.warning(f"⚠️ [set_type] Auto-inferred '{set_type}' for '{ex_name}' set {set_num}")

            set_type_lower = set_type.lower()

            # Validate set_type is valid
            if set_type_lower not in valid_set_types:
                invalid_set_types.append(f"{ex_name} set {set_num}: '{set_type}'")
                logger.error(f"❌ [set_type] Invalid '{set_type}' for '{ex_name}' set {set_num} - must be W/D/F/A or working")
            else:
                # Count valid set types
                set_type_counts[set_type_lower] += 1

            # Log each set target with type indicator
            type_indicator = {
                'warmup': 'W',
                'working': str(set_num),
                'drop': 'D',
                'failure': 'F',
                'amrap': 'A'
            }.get(set_type_lower, '?')

            weight_str = f"{target_weight}kg" if target_weight else "BW"
            rpe_str = f"RPE {target_rpe}" if target_rpe else ""
            logger.info(f"   [{type_indicator}] Set {set_num}: {set_type.upper()} - {weight_str} × {target_reps} {rpe_str}")

    # FAIL if any targets are missing
    if missing_targets:
        error_msg = f"Gemini FAILED to generate set_targets for {len(missing_targets)} exercises: {missing_targets}"
        logger.error(f"❌ [FATAL] {error_msg}")
        raise ValueError(error_msg)

    # FAIL if any set_type is invalid (after auto-fill, this should rarely happen)
    if invalid_set_types:
        error_msg = f"Gemini generated invalid set_type for {len(invalid_set_types)} sets: {invalid_set_types}"
        logger.error(f"❌ [FATAL] {error_msg}")
        raise ValueError(error_msg)

    # Log summary of set types found
    logger.info(f"📊 [set_targets] Summary ({total_sets} total sets):")
    logger.info(f"   W (warmup): {set_type_counts['warmup']}")
    logger.info(f"   Working: {set_type_counts['working']}")
    logger.info(f"   D (drop): {set_type_counts['drop']}")
    logger.info(f"   F (failure): {set_type_counts['failure']}")
    logger.info(f"   A (amrap): {set_type_counts['amrap']}")

    logger.info(f"✅ [set_targets] All {len(exercises)} exercises have valid set_targets with proper set_type!")
    return exercises


# Keep old function name as alias for backwards compatibility with generation.py imports
ensure_set_targets = validate_set_targets_strict

# Initialize the Gemini client
client = get_genai_client()


class GeminiService:
    """
    Wrapper for Gemini API calls using the new google-genai SDK.

    Usage:
        service = GeminiService()
        response = await service.chat("Hello!")
    """

    # Class-level cache storage (shared across all instances)
    _workout_cache = None
    _workout_cache_created_at = None
    _cache_lock = None  # Will be initialized as asyncio.Lock()
    _cache_refresh_task = None  # Background refresh task
    _initialized = False

    def __init__(self):
        self.model = settings.gemini_model
        self.embedding_model = settings.gemini_embedding_model
        # Initialize the async lock if not already done
        if GeminiService._cache_lock is None:
            GeminiService._cache_lock = asyncio.Lock()

    @classmethod
    async def initialize_cache_manager(cls):
        """
        Initialize the cache manager on server startup.
        Call this from your FastAPI lifespan or startup event.

        This will:
        1. Clean up any orphaned caches from previous server runs
        2. Pre-warm the cache so first request is fast
        3. Start background refresh task
        """
        if cls._initialized:
            logger.info("[CacheManager] Already initialized")
            return

        cls._initialized = True
        logger.info("[CacheManager] Initializing automatic cache management...")

        # Clean up old caches first
        await cls._cleanup_old_caches()

        # Pre-warm the cache
        await cls._prewarm_cache()

        # Start background refresh task
        cls._cache_refresh_task = asyncio.create_task(cls._background_cache_refresh())
        logger.info("✅ [CacheManager] Automatic cache management started")

    @classmethod
    async def shutdown_cache_manager(cls):
        """
        Shutdown the cache manager gracefully.
        Call this from your FastAPI shutdown event.
        """
        if cls._cache_refresh_task:
            cls._cache_refresh_task.cancel()
            try:
                await cls._cache_refresh_task
            except asyncio.CancelledError:
                pass
            cls._cache_refresh_task = None
        logger.info("[CacheManager] Cache manager shut down")

    @classmethod
    async def _cleanup_old_caches(cls):
        """Clean up orphaned workout caches from previous server runs."""
        try:
            deleted_count = 0
            for cache in client.caches.list():
                # Only delete our workout caches
                if cache.display_name and "workout_generation" in cache.display_name:
                    try:
                        client.caches.delete(name=cache.name)
                        deleted_count += 1
                        logger.info(f"[CacheManager] Cleaned up old cache: {cache.name}")
                    except Exception as e:
                        logger.warning(f"[CacheManager] Failed to delete cache {cache.name}: {e}")

            if deleted_count > 0:
                logger.info(f"[CacheManager] Cleaned up {deleted_count} old cache(s)")
        except Exception as e:
            logger.warning(f"[CacheManager] Cache cleanup failed: {e}")

    @classmethod
    async def _prewarm_cache(cls):
        """Pre-warm the cache on server startup so first request is fast."""
        try:
            service = cls()
            cache_name = await service._get_or_create_workout_cache()
            if cache_name:
                logger.info(f"✅ [CacheManager] Cache pre-warmed: {cache_name}")
            else:
                logger.warning("[CacheManager] Cache pre-warm failed, will retry on first request")
        except Exception as e:
            logger.warning(f"[CacheManager] Cache pre-warm failed: {e}")

    @classmethod
    async def _background_cache_refresh(cls):
        """
        Background task that proactively refreshes the cache before expiry.
        Runs every 45 minutes to ensure cache is always fresh.
        """
        refresh_interval = 45 * 60  # 45 minutes

        while True:
            try:
                await asyncio.sleep(refresh_interval)

                # Check if cache needs refresh
                if cls._workout_cache and cls._workout_cache_created_at:
                    age_seconds = (datetime.now() - cls._workout_cache_created_at).total_seconds()

                    if age_seconds >= 2700:  # 45 minutes - proactively refresh
                        logger.info(f"[CacheManager] Proactively refreshing cache (age: {age_seconds:.0f}s)")

                        # Create new cache
                        service = cls()

                        # Force refresh by clearing old cache reference
                        old_cache = cls._workout_cache
                        cls._workout_cache = None
                        cls._workout_cache_created_at = None

                        # Create new cache
                        new_cache = await service._get_or_create_workout_cache()

                        if new_cache:
                            logger.info(f"✅ [CacheManager] Cache refreshed: {new_cache}")

                            # Delete old cache from Google's servers
                            if old_cache:
                                try:
                                    client.caches.delete(name=old_cache)
                                    logger.info(f"[CacheManager] Deleted old cache: {old_cache}")
                                except Exception:
                                    pass  # Old cache may have already expired
                        else:
                            # Restore old cache if refresh failed
                            cls._workout_cache = old_cache
                            logger.warning("[CacheManager] Cache refresh failed, keeping old cache")
                else:
                    # No cache exists, create one
                    logger.info("[CacheManager] No cache exists, creating...")
                    service = cls()
                    await service._get_or_create_workout_cache()

            except asyncio.CancelledError:
                logger.info("[CacheManager] Background refresh task cancelled")
                break
            except Exception as e:
                logger.error(f"[CacheManager] Background refresh error: {e}")
                await asyncio.sleep(60)  # Wait a minute before retrying

    async def _get_or_create_workout_cache(self) -> Optional[str]:
        """
        Get existing workout generation cache or create a new one.

        The cache contains static content that's identical for every workout request:
        - System instructions for workout generation
        - Exercise generation rules and guidelines
        - Set target examples and schema

        Returns:
            Cache name (str) if successful, None if caching fails (will fallback to non-cached)
        """
        async with GeminiService._cache_lock:
            try:
                # Check if cache exists and is valid (< 50 minutes old to refresh before 1-hour expiry)
                if GeminiService._workout_cache and GeminiService._workout_cache_created_at:
                    age_seconds = (datetime.now() - GeminiService._workout_cache_created_at).total_seconds()
                    if age_seconds < 3000:  # 50 minutes
                        logger.debug(f"[Cache] Using existing workout cache (age: {age_seconds:.0f}s)")
                        return GeminiService._workout_cache

                    # Cache is expiring soon, try to refresh
                    logger.info(f"[Cache] Workout cache expiring (age: {age_seconds:.0f}s), refreshing...")

                # Build static system instruction for workout generation
                system_instruction = self._build_workout_cache_system_instruction()

                # Build static content to cache (rules, examples, guidelines)
                static_content = self._build_workout_cache_content()

                logger.info(f"[Cache] Creating new workout generation cache...")
                logger.info(f"[Cache] System instruction length: {len(system_instruction)} chars")
                logger.info(f"[Cache] Static content length: {len(static_content)} chars")

                # Create the cache
                cache = client.caches.create(
                    model=self.model,
                    config=types.CreateCachedContentConfig(
                        display_name="workout_generation_v1",
                        system_instruction=system_instruction,
                        contents=[static_content],
                        ttl="3600s",  # 1 hour cache TTL
                    )
                )

                # Store cache reference
                GeminiService._workout_cache = cache.name
                GeminiService._workout_cache_created_at = datetime.now()

                logger.info(f"✅ [Cache] Created new workout cache: {cache.name}")
                return cache.name

            except Exception as e:
                logger.warning(f"⚠️ [Cache] Failed to create workout cache: {e}")
                logger.warning(f"[Cache] Falling back to non-cached generation")
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
1. Match exercises to available equipment
2. Include compound movements first, then isolation
3. Balance push/pull for upper body days
4. Include proper warm-up sets at lighter weights
5. Scale difficulty to fitness level

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
- Beginners: max 4 sets per exercise, max 20 reps
- Intermediate: max 5 sets per exercise, max 15 reps
- Advanced: max 6 sets per exercise, max 12 reps
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
- Sets per exercise: 2-3
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
- Reflect the workout focus (Push Power, Leg Day Blast)
- Can include theme if date is special (holiday themes)
- Are motivating and memorable
- Avoid generic names like "Workout 1\""""

    def _try_recover_truncated_json(self, content: str) -> Optional[Dict]:
        """
        Attempt to recover a truncated JSON response by closing open structures.
        Returns parsed dict if successful, None otherwise.
        """
        if not content:
            return None

        # Count open brackets/braces
        open_braces = content.count('{') - content.count('}')
        open_brackets = content.count('[') - content.count(']')

        # If severely truncated (missing many closers), give up
        if open_braces > 5 or open_brackets > 5:
            logger.warning(f"JSON too severely truncated to recover: {open_braces} braces, {open_brackets} brackets open")
            return None

        recovered = content

        # Try to find a reasonable truncation point (end of a complete field)
        # Look for last complete string or number value
        last_comma = recovered.rfind(',')
        last_colon = recovered.rfind(':')

        if last_comma > last_colon:
            # Truncated after a complete value, remove trailing comma
            recovered = recovered[:last_comma]
        elif last_colon > last_comma:
            # Truncated mid-value, remove incomplete field
            last_good_comma = recovered.rfind(',', 0, last_colon)
            if last_good_comma > 0:
                recovered = recovered[:last_good_comma]

        # Close open structures
        recovered += ']' * open_brackets
        recovered += '}' * open_braces

        try:
            result = json.loads(recovered)
            logger.info("Successfully recovered truncated JSON")
            return result
        except json.JSONDecodeError:
            # Try more aggressive recovery - cut to last complete object
            try:
                # Find the last complete array element or object
                brace_depth = 0
                bracket_depth = 0
                last_complete = -1

                for i, char in enumerate(content):
                    if char == '{':
                        brace_depth += 1
                    elif char == '}':
                        brace_depth -= 1
                        if brace_depth == 0:
                            last_complete = i
                    elif char == '[':
                        bracket_depth += 1
                    elif char == ']':
                        bracket_depth -= 1

                if last_complete > 0:
                    recovered = content[:last_complete + 1]
                    # Close any remaining brackets
                    open_brackets = recovered.count('[') - recovered.count(']')
                    recovered += ']' * open_brackets
                    return json.loads(recovered)
            except json.JSONDecodeError:
                pass

            logger.warning("Failed to recover truncated JSON")
            return None

    def _fix_trailing_commas(self, json_str: str) -> str:
        """
        Fix trailing commas in JSON which are invalid but commonly returned by LLMs.
        Handles cases like: {"a": 1,} or [1, 2,]
        """
        import re
        # Remove trailing commas before closing braces/brackets
        # Handles: ,} ,] with optional whitespace/newlines between
        fixed = re.sub(r',(\s*[}\]])', r'\1', json_str)
        return fixed

    def _parse_weight_from_amount(self, amount: str) -> tuple[float, str]:
        """
        Parse weight in grams from amount string.
        Returns (weight_g, weight_source) where weight_source is 'exact' or 'estimated'.

        Examples:
            "59 grams" -> (59.0, "exact")
            "150g" -> (150.0, "exact")
            "1 cup" -> (240.0, "estimated")
            "handful" -> (30.0, "estimated")
        """
        if not amount:
            return (100.0, "estimated")  # Default to 100g

        amount_lower = amount.lower().strip()

        # Try to extract explicit gram weight
        gram_patterns = [
            r'(\d+(?:\.\d+)?)\s*(?:g|grams?|gram)\b',  # "59g", "59 grams", "59.5 grams"
            r'(\d+(?:\.\d+)?)\s*(?:gr)\b',  # "59gr"
        ]
        for pattern in gram_patterns:
            match = regex_module.search(pattern, amount_lower)
            if match:
                return (float(match.group(1)), "exact")

        # Convert common measurements to grams (estimates)
        conversion_estimates = {
            # Cups
            'cup': 240.0,
            'cups': 240.0,
            '1/2 cup': 120.0,
            'half cup': 120.0,
            '1/4 cup': 60.0,
            'quarter cup': 60.0,
            # Spoons
            'tablespoon': 15.0,
            'tbsp': 15.0,
            'teaspoon': 5.0,
            'tsp': 5.0,
            # Informal
            'handful': 30.0,
            'small handful': 20.0,
            'large handful': 45.0,
            # Portions
            'small': 100.0,
            'medium': 150.0,
            'large': 200.0,
            'small bowl': 150.0,
            'medium bowl': 250.0,
            'large bowl': 350.0,
            # Slices
            'slice': 30.0,
            'slices': 60.0,
            '1 slice': 30.0,
            '2 slices': 60.0,
            # Pieces
            'piece': 50.0,
            '1 piece': 50.0,
            '2 pieces': 100.0,
        }

        for term, grams in conversion_estimates.items():
            if term in amount_lower:
                return (grams, "estimated")

        # Try to extract oz/ounces and convert
        oz_match = regex_module.search(r'(\d+(?:\.\d+)?)\s*(?:oz|ounce|ounces)\b', amount_lower)
        if oz_match:
            oz = float(oz_match.group(1))
            return (oz * 28.35, "exact")  # 1 oz = 28.35g

        # Try to extract numeric value (assume grams if unit unclear)
        numeric_match = regex_module.search(r'^(\d+(?:\.\d+)?)\s*$', amount_lower)
        if numeric_match:
            return (float(numeric_match.group(1)), "estimated")

        # Default fallback
        return (100.0, "estimated")

    def _is_good_usda_match(self, query: str, usda_description: str) -> bool:
        """
        Check if the USDA result is a good match for the query.
        Avoids using wrong products (e.g., "Cinnabon Pudding" for "Cinnabon Delights").
        """
        query_lower = query.lower().strip()
        desc_lower = usda_description.lower().strip()

        # List of restaurant/fast food brands - USDA doesn't have their menu items
        restaurant_brands = [
            'taco bell', 'mcdonalds', "mcdonald's", 'burger king', 'wendys', "wendy's",
            'chick-fil-a', 'chickfila', 'subway', 'chipotle', 'five guys', 'in-n-out',
            'popeyes', 'kfc', 'pizza hut', 'dominos', "domino's", 'papa johns',
            'starbucks', 'dunkin', 'panda express', 'chilis', "chili's", 'applebees',
            "applebee's", 'olive garden', 'red lobster', 'outback', 'ihop', "denny's",
            'sonic', 'arby', "arby's", 'jack in the box', 'carl', "carl's jr",
            'hardee', "hardee's", 'del taco', 'qdoba', 'panera', 'noodles',
            'wingstop', 'buffalo wild wings', 'hooters', 'zaxbys', "zaxby's",
        ]

        # If query mentions a restaurant brand, USDA probably doesn't have the right item
        for brand in restaurant_brands:
            if brand in query_lower:
                logger.info(f"[USDA] Skipping match - '{query}' is a restaurant item (USDA doesn't have restaurant menus)")
                return False

        # Check if key words from query appear in USDA description
        # Split query into significant words (3+ chars)
        query_words = [w for w in query_lower.split() if len(w) >= 3]

        # Count how many query words appear in the description
        matches = sum(1 for word in query_words if word in desc_lower)
        match_ratio = matches / len(query_words) if query_words else 0

        # Require at least 50% of words to match for a good match
        if match_ratio < 0.5:
            logger.info(f"[USDA] Poor match - query='{query}' vs result='{usda_description}' (match_ratio={match_ratio:.0%})")
            return False

        return True

    async def _lookup_single_usda(self, usda_service, food_name: str) -> Optional[Dict]:
        """Look up a single food in USDA database. Returns usda_data dict or None."""
        if not usda_service or not food_name:
            return None
        try:
            search_result = await usda_service.search_foods(
                query=food_name,
                page_size=1,  # Just need top match
            )
            if search_result.foods:
                top_food = search_result.foods[0]

                # Check if this is actually a good match
                if not self._is_good_usda_match(food_name, top_food.description):
                    print(f"⚠️ [USDA] Skipping poor match for '{food_name}' - keeping AI estimate")
                    return None

                nutrients = top_food.nutrients
                print(f"✅ [USDA] Found '{top_food.description}' for '{food_name}' ({nutrients.calories_per_100g} cal/100g)")
                return {
                    'fdc_id': top_food.fdc_id,
                    'calories_per_100g': nutrients.calories_per_100g,
                    'protein_per_100g': nutrients.protein_per_100g,
                    'carbs_per_100g': nutrients.carbs_per_100g,
                    'fat_per_100g': nutrients.fat_per_100g,
                    'fiber_per_100g': nutrients.fiber_per_100g,
                }
        except Exception as e:
            logger.warning(f"USDA lookup failed for '{food_name}': {e}")
        return None

    async def _enhance_food_items_with_usda(self, food_items: List[Dict]) -> List[Dict]:
        """
        Enhance food items with USDA per-100g nutrition data for accurate scaling.
        Uses parallel lookups for faster performance.

        For each food item:
        1. Look up in USDA database (in parallel)
        2. If found: Add usda_data with per-100g values
        3. If not found: Calculate ai_per_gram from AI's estimate
        """
        try:
            from services.usda_food_service import get_usda_food_service
            usda_service = get_usda_food_service()
        except Exception as e:
            logger.warning(f"Could not initialize USDA service: {e}")
            usda_service = None

        # Parse weights first (synchronous, fast)
        # Use Gemini's weight_g if provided, otherwise parse from amount string
        parsed_items = []
        for item in food_items:
            enhanced_item = dict(item)

            # First check if Gemini provided a valid weight_g
            gemini_weight = item.get('weight_g')
            if gemini_weight and gemini_weight > 0:
                enhanced_item['weight_g'] = float(gemini_weight)
                enhanced_item['weight_source'] = 'gemini'
            else:
                # Fall back to parsing the amount string
                amount = item.get('amount', '')
                weight_g, weight_source = self._parse_weight_from_amount(amount)
                enhanced_item['weight_g'] = weight_g
                enhanced_item['weight_source'] = weight_source

            parsed_items.append(enhanced_item)

        # Run all USDA lookups in parallel (async)
        food_names = [item.get('name', '') for item in food_items]
        print(f"🔍 [USDA] Looking up {len(food_names)} items in parallel...")

        usda_results = await asyncio.gather(
            *[self._lookup_single_usda(usda_service, name) for name in food_names],
            return_exceptions=True  # Don't fail if one lookup fails
        )

        # Process results
        enhanced_items = []
        for i, (item, usda_data) in enumerate(zip(parsed_items, usda_results)):
            # Handle exceptions from gather
            if isinstance(usda_data, Exception):
                logger.warning(f"USDA lookup exception for '{food_names[i]}': {usda_data}")
                usda_data = None

            weight_g = item['weight_g']

            if usda_data:
                # Check if USDA data has valid calories (non-zero)
                usda_calories_per_100g = usda_data.get('calories_per_100g', 0)

                if usda_calories_per_100g > 0 and weight_g > 0:
                    # Use USDA data - it has valid nutritional info
                    item['usda_data'] = usda_data
                    item['ai_per_gram'] = None

                    multiplier = weight_g / 100.0
                    item['calories'] = round(usda_calories_per_100g * multiplier)
                    item['protein_g'] = round(usda_data['protein_per_100g'] * multiplier, 1)
                    item['carbs_g'] = round(usda_data['carbs_per_100g'] * multiplier, 1)
                    item['fat_g'] = round(usda_data['fat_per_100g'] * multiplier, 1)
                    item['fiber_g'] = round(usda_data['fiber_per_100g'] * multiplier, 1)
                    logger.info(f"[USDA] Using USDA data for '{food_names[i]}' | calories={item['calories']} | usda_cal/100g={usda_calories_per_100g}")
                else:
                    # USDA match found but has 0 calories - fall back to AI values
                    logger.warning(f"[USDA] Found match for '{food_names[i]}' but calories=0, keeping AI estimate | ai_calories={item.get('calories', 0)}")
                    item['usda_data'] = None  # Mark as no valid USDA data
                    item['ai_per_gram'] = None
            elif usda_data is None:
                # Fallback: Calculate per-gram from AI estimate
                item['usda_data'] = None
                original_item = food_items[i]
                ai_calories = original_item.get('calories', 0)
                ai_protein = original_item.get('protein_g', 0)
                ai_carbs = original_item.get('carbs_g', 0)
                ai_fat = original_item.get('fat_g', 0)
                ai_fiber = original_item.get('fiber_g', 0)

                if weight_g > 0:
                    item['ai_per_gram'] = {
                        'calories': round(ai_calories / weight_g, 3),
                        'protein': round(ai_protein / weight_g, 4),
                        'carbs': round(ai_carbs / weight_g, 4),
                        'fat': round(ai_fat / weight_g, 4),
                        'fiber': round(ai_fiber / weight_g, 4) if ai_fiber else 0,
                    }
                    print(f"⚠️ [USDA] No match for '{food_names[i]}', using AI per-gram estimate")
                else:
                    item['ai_per_gram'] = None

            enhanced_items.append(item)

        return enhanced_items

    async def chat(
        self,
        user_message: str,
        system_prompt: Optional[str] = None,
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """
        Send a chat message to Gemini and get a response.

        Args:
            user_message: The user's message
            system_prompt: Optional system prompt for context
            conversation_history: List of previous messages

        Returns:
            AI response string
        """
        contents = []

        # Add conversation history
        if conversation_history:
            for msg in conversation_history:
                role = "user" if msg["role"] == "user" else "model"
                contents.append(types.Content(role=role, parts=[types.Part.from_text(text=msg["content"])]))

        # Add current message
        contents.append(types.Content(role="user", parts=[types.Part.from_text(text=user_message)]))

        # Relaxed safety settings for chat — users may vent or use profanity,
        # and the coach personas are designed to handle it in-character.
        # Block only BLOCK_ONLY_HIGH to avoid false positives on fitness content.
        chat_safety_settings = [
            types.SafetySetting(
                category="HARM_CATEGORY_HARASSMENT",
                threshold="BLOCK_ONLY_HIGH",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_HATE_SPEECH",
                threshold="BLOCK_ONLY_HIGH",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                threshold="BLOCK_MEDIUM_AND_ABOVE",
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_DANGEROUS_CONTENT",
                threshold="BLOCK_ONLY_HIGH",
            ),
        ]

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        system_instruction=system_prompt,
                        max_output_tokens=settings.gemini_max_tokens,
                        temperature=settings.gemini_temperature,
                        safety_settings=chat_safety_settings,
                    ),
                ),
                timeout=60,  # 60s for chat responses
            )
        except asyncio.TimeoutError:
            logger.error("[Chat] Gemini API timed out after 60s")
            raise Exception("AI response timed out. Please try again.")

        return response.text

    async def extract_intent(self, user_message: str) -> IntentExtraction:
        """
        Extract structured intent from user message using AI.

        MODIFY THIS to change how intents are detected.
        """
        extraction_prompt = '''You are a fitness app intent extraction system. Analyze the user message and extract structured data.

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{
  "intent": "add_exercise|remove_exercise|swap_workout|modify_intensity|reschedule|report_injury|change_setting|navigate|start_workout|complete_workout|log_hydration|generate_quick_workout|question",
  "exercises": ["exercise name 1", "exercise name 2"],
  "muscle_groups": ["chest", "back", "shoulders", "biceps", "triceps", "legs", "core", "glutes"],
  "modification": "easier|harder|shorter|longer",
  "body_part": "shoulder|back|knee|ankle|wrist|elbow|hip|neck",
  "setting_name": "dark_mode|notifications",
  "setting_value": true,
  "destination": "home|library|profile|achievements|hydration|nutrition|summaries",
  "hydration_amount": 8
}

INTENT DEFINITIONS:
- add_exercise: User wants to ADD an exercise (e.g., "add pull-ups", "include bench press")
- remove_exercise: User wants to REMOVE an exercise (e.g., "remove squats", "take out lunges")
- swap_workout: User wants a DIFFERENT workout type (e.g., "not in mood for leg day")
- modify_intensity: User wants to change difficulty/duration (e.g., "make it easier", "too hard")
- reschedule: User wants to change workout timing (e.g., "move to tomorrow")
- report_injury: User mentions pain/injury (e.g., "my shoulder hurts")
- change_setting: User wants to change app settings (e.g., "turn on dark mode", "enable dark theme", "switch to light mode")
- navigate: User wants to go to a specific screen (e.g., "show my achievements", "open nutrition", "go to profile")
- start_workout: User wants to START their workout NOW (e.g., "start my workout", "let's go", "begin workout", "I'm ready")
- complete_workout: User wants to FINISH/COMPLETE their workout (e.g., "I'm done", "finished", "completed my workout", "mark as done")
- log_hydration: User wants to LOG water intake (e.g., "log 8 glasses of water", "I drank 3 cups", "track my water")
- generate_quick_workout: User wants to CREATE/GENERATE a new workout (e.g., "give me a quick workout", "create a 15-minute workout", "make me a cardio workout", "I need a short workout", "new workout please")
- question: General fitness question or unclear intent

SETTING EXTRACTION:
- For dark mode requests: setting_name="dark_mode", setting_value=true
- For light mode requests: setting_name="dark_mode", setting_value=false
- For notification toggles: setting_name="notifications", setting_value=true/false

NAVIGATION EXTRACTION:
- "show achievements" / "my badges" -> destination="achievements"
- "hydration" / "water intake" -> destination="hydration"
- "nutrition" / "my meals" / "calories" -> destination="nutrition"
- "weekly summary" / "my progress" -> destination="summaries"
- "go home" / "main screen" -> destination="home"
- "exercise library" / "browse exercises" -> destination="library"
- "my profile" / "settings" -> destination="profile"

WORKOUT ACTION EXTRACTION:
- "start my workout" / "let's go" / "begin" / "I'm ready" / "start training" -> intent="start_workout"
- "I'm done" / "finished" / "completed" / "mark as done" / "workout complete" -> intent="complete_workout"

HYDRATION EXTRACTION:
- Extract the NUMBER of glasses/cups from the message
- "log 8 glasses of water" -> hydration_amount=8
- "I drank 3 cups" -> hydration_amount=3
- "track 2 glasses" -> hydration_amount=2
- If no number specified, default to hydration_amount=1

User message: "''' + user_message + '"'

        # Check intent cache first (common intents like greetings hit this often)
        try:
            cache_key = _intent_cache.make_key("intent", user_message.strip().lower())
            cached_result = _intent_cache.get(cache_key)
            if cached_result is not None:
                logger.info(f"[IntentCache] Cache HIT for message: '{user_message[:50]}...'")
                return cached_result
        except Exception as cache_err:
            logger.warning(f"[IntentCache] Cache lookup error (falling through): {cache_err}")

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=extraction_prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=IntentExtractionResponse,
                        max_output_tokens=2000,  # Increased for thinking models
                        temperature=0.1,  # Low temp for consistent extraction
                    ),
                ),
                timeout=15,  # Intent extraction should be fast
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty intent extraction response")

            result = IntentExtraction(
                intent=CoachIntent(data.intent or "question"),
                exercises=[e.lower() for e in (data.exercises or [])],
                muscle_groups=[m.lower() for m in (data.muscle_groups or [])],
                modification=data.modification,
                body_part=data.body_part,
                setting_name=data.setting_name,
                setting_value=data.setting_value,
                destination=data.destination,
                hydration_amount=data.hydration_amount,
            )

            # Cache the result
            try:
                _intent_cache.set(cache_key, result)
                logger.info(f"[IntentCache] Cache MISS - stored result for: '{user_message[:50]}...'")
            except Exception as cache_err:
                logger.warning(f"[IntentCache] Failed to store result: {cache_err}")

            return result

        except asyncio.TimeoutError:
            logger.error(f"[Intent] Gemini API timed out after 15s for intent extraction")
            return IntentExtraction(intent=CoachIntent.QUESTION)
        except Exception as e:
            print(f"Intent extraction failed: {e}")
            return IntentExtraction(intent=CoachIntent.QUESTION)

    async def extract_exercises_from_response(self, ai_response: str) -> Optional[List[str]]:
        """
        Extract exercise names from the AI's response.

        This is used to ensure the exercises we add/remove match what the AI
        actually mentioned in its response, not just what the user asked for.
        """
        extraction_prompt = f'''Extract ALL exercise names mentioned in this fitness coach response.

Response: "{ai_response}"

Return a JSON object with an "exercises" array containing the exercise names:
{{"exercises": ["Exercise 1", "Exercise 2", ...]}}

IMPORTANT:
- Include ALL exercises mentioned, including compound names like "Cable Woodchoppers"
- Keep the exact exercise names as written
- If no exercises are mentioned, return: {{"exercises": []}}'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=extraction_prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=ExerciseListResponse,
                        max_output_tokens=2000,  # Increased for thinking models
                        temperature=0.1,
                    ),
                ),
                timeout=15,  # 15s for simple extraction
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            data = response.parsed
            if not data:
                return None
            exercises = data.exercises or []

            if isinstance(exercises, list) and len(exercises) > 0:
                return exercises
            return None

        except asyncio.TimeoutError:
            logger.error("[ExerciseExtraction] Gemini API timed out after 15s")
            return None
        except Exception as e:
            print(f"Exercise extraction from response failed: {e}")
            return None

    async def parse_workout_input(
        self,
        input_text: Optional[str] = None,
        image_base64: Optional[str] = None,
        voice_transcript: Optional[str] = None,
        user_unit_preference: str = "lbs",
    ) -> Dict:
        """
        Parse natural language workout input into structured exercises.

        Supports text, image, or voice transcript input. Uses Gemini to extract
        exercise names, sets, reps, and weights from free-form input like:
        - "3x10 deadlift at 135, 5x5 squat at 140"
        - "bench press 4 sets of 8 at 80"
        - Image of a workout log or whiteboard

        Args:
            input_text: Natural language text input
            image_base64: Base64 encoded image of workout notes
            voice_transcript: Transcribed voice input
            user_unit_preference: User's preferred weight unit ('kg' or 'lbs')

        Returns:
            Dictionary with 'exercises', 'summary', and 'warnings'
        """
        logger.info(f"🤖 [ParseWorkout] Parsing input: text={bool(input_text)}, image={bool(image_base64)}, voice={bool(voice_transcript)}")

        # Combine input sources
        combined_input = ""
        if input_text:
            combined_input += input_text
        if voice_transcript:
            combined_input += f" {voice_transcript}" if combined_input else voice_transcript

        if not combined_input and not image_base64:
            logger.warning("❌ [ParseWorkout] No input provided")
            return {
                "exercises": [],
                "summary": "No input provided",
                "warnings": ["Please provide text, image, or voice input"]
            }

        parse_prompt = f'''Parse workout exercises from the input. Extract each exercise with:
- name: Standard gym exercise name (e.g., "Bench Press", "Back Squat", "Deadlift")
- sets: Number of sets (the number before 'x' or after "sets")
- reps: Number of reps (the number after 'x' or after "reps")
- weight_value: Weight number if specified
- weight_unit: "{user_unit_preference}" unless explicitly stated otherwise (kg/lbs)
- rest_seconds: Rest period if mentioned, otherwise default to 60
- original_text: The exact text segment that was parsed for this exercise
- confidence: Your confidence in the parsing (0.0-1.0)
- notes: Any additional notes or form cues mentioned

PARSING RULES:
1. "3x10" means 3 sets of 10 reps
2. "4 sets of 8" means 4 sets of 8 reps
3. "at 135" or "@135" means 135 {user_unit_preference}
4. "100kg" or "100 kg" means 100 kilograms
5. "225lbs" or "225 lbs" means 225 pounds
6. If no weight specified, leave weight_value as null
7. Use standard exercise names (capitalize properly)

EXAMPLES:
- "3x10 deadlift at 135" → name="Deadlift", sets=3, reps=10, weight=135
- "bench 5x5 @ 225" → name="Bench Press", sets=5, reps=5, weight=225
- "4 sets of squats" → name="Back Squat", sets=4, reps=10 (default)
- "pull-ups 3x12" → name="Pull-ups", sets=3, reps=12, weight=null

INPUT TO PARSE:
"{combined_input or 'See image below'}"

Return a summary describing what was found and any warnings about unclear parsing.'''

        try:
            # Build content list
            contents = [parse_prompt]

            # Add image if provided
            if image_base64:
                import base64
                contents.append(types.Part.from_bytes(
                    data=base64.b64decode(image_base64),
                    mime_type="image/jpeg"
                ))

            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=ParseWorkoutInputResponse,
                        max_output_tokens=4000,
                        temperature=0.2,  # Low for consistent parsing
                    ),
                ),
                timeout=30,  # 30s for workout input parsing
            )

            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty parse response")

            exercises = []
            for ex in data.exercises:
                exercise_dict = {
                    "name": ex.name,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "weight_value": ex.weight_value,
                    "weight_unit": ex.weight_unit,
                    "rest_seconds": ex.rest_seconds,
                    "original_text": ex.original_text,
                    "confidence": ex.confidence,
                    "notes": ex.notes,
                }
                # Convert weight to both units for convenience
                if ex.weight_value is not None:
                    if ex.weight_unit.lower() == "kg":
                        exercise_dict["weight_kg"] = ex.weight_value
                        exercise_dict["weight_lbs"] = round(ex.weight_value * 2.20462, 1)
                    else:
                        exercise_dict["weight_lbs"] = ex.weight_value
                        exercise_dict["weight_kg"] = round(ex.weight_value / 2.20462, 1)
                else:
                    exercise_dict["weight_kg"] = None
                    exercise_dict["weight_lbs"] = None

                exercises.append(exercise_dict)

            result = {
                "exercises": exercises,
                "summary": data.summary,
                "warnings": data.warnings or [],
            }

            logger.info(f"✅ [ParseWorkout] Parsed {len(exercises)} exercises: {[e['name'] for e in exercises]}")
            return result

        except Exception as e:
            logger.error(f"❌ [ParseWorkout] Failed to parse workout input: {e}")
            return {
                "exercises": [],
                "summary": f"Failed to parse input: {str(e)}",
                "warnings": ["Parsing failed. Please try rephrasing your input."]
            }

    async def parse_workout_input_v2(
        self,
        input_text: Optional[str] = None,
        image_base64: Optional[str] = None,
        voice_transcript: Optional[str] = None,
        user_unit_preference: str = "lbs",
        current_exercise_name: Optional[str] = None,
        last_set_weight: Optional[float] = None,
        last_set_reps: Optional[int] = None,
    ) -> Dict:
        """
        Parse workout input with dual-mode support.

        Supports TWO use cases simultaneously:
        1. Set logging: "135*8, 145*6" -> logs sets for CURRENT exercise
        2. Add exercise: "3x10 deadlift at 135" -> adds NEW exercise

        Smart shortcuts:
        - "+10" -> add 10 to last weight, keep same reps
        - "-10" -> subtract 10 from last weight
        - "same" -> repeat last set exactly
        - "drop" -> 10% weight reduction
        - "up" -> +5 progression

        Args:
            input_text: Natural language text input
            image_base64: Base64 encoded image
            voice_transcript: Transcribed voice input
            user_unit_preference: User's preferred weight unit
            current_exercise_name: Name of current exercise (for set logging context)
            last_set_weight: Weight from last set (for shortcuts)
            last_set_reps: Reps from last set (for shortcuts)

        Returns:
            Dictionary with 'sets_to_log', 'exercises_to_add', 'summary', 'warnings'
        """
        logger.info(
            f"🤖 [ParseWorkoutV2] Parsing: exercise={current_exercise_name}, "
            f"text={bool(input_text)}, image={bool(image_base64)}"
        )

        # Combine input sources
        combined_input = ""
        if input_text:
            combined_input += input_text
        if voice_transcript:
            combined_input += f" {voice_transcript}" if combined_input else voice_transcript

        if not combined_input and not image_base64:
            logger.warning("❌ [ParseWorkoutV2] No input provided")
            return {
                "sets_to_log": [],
                "exercises_to_add": [],
                "summary": "No input provided",
                "warnings": ["Please provide text, image, or voice input"]
            }

        # Build context for smart shortcuts
        last_set_context = ""
        if last_set_weight is not None and last_set_reps is not None:
            last_set_context = f"Last logged set: {last_set_weight} {user_unit_preference} × {last_set_reps} reps"
        else:
            last_set_context = "No previous set logged yet"

        current_ex_context = current_exercise_name or "Unknown Exercise"

        # Build smart shortcuts section based on available last set data
        if last_set_weight is not None:
            smart_shortcuts_section = f'''- "+10" -> {last_set_weight + 10} x {last_set_reps or "N/A"} reps (add 10 to last weight)
- "-10" -> {last_set_weight - 10} x {last_set_reps or "N/A"} reps (subtract 10)
- "+10*6" -> {last_set_weight + 10} x 6 reps (add 10, override reps)
- "same" -> {last_set_weight} x {last_set_reps or "N/A"} (repeat last set exactly)
- "same*10" -> {last_set_weight} x 10 (same weight, different reps)
- "drop" -> {round(last_set_weight * 0.9, 1)} x {last_set_reps or "N/A"} (10% drop)
- "drop 20" -> {last_set_weight - 20} x {last_set_reps or "N/A"} (subtract 20)
- "up" -> {last_set_weight + 5} x {last_set_reps or "N/A"} (standard +5 progression)'''
        else:
            smart_shortcuts_section = "Shortcuts not available - no previous set data"

        # Build the comprehensive prompt
        parse_prompt = f'''You are a workout input parser. Parse the user's input and determine their intent.

CONTEXT:
- Current exercise: "{current_ex_context}"
- User's preferred unit: {user_unit_preference} (use this when unit not specified)
- {last_set_context}

YOUR TASK: Categorize each line/segment as either:
1. SET LOG - Numbers only (no exercise name) → applies to current exercise "{current_ex_context}"
2. NEW EXERCISE - Contains exercise name → adds new exercise to workout

═══════════════════════════════════════════════════════════════
SET LOGGING PATTERNS (for current exercise: "{current_ex_context}")
═══════════════════════════════════════════════════════════════

Recognize these formats for WEIGHT × REPS:
- "135*8" or "135x8" or "135X8" or "135×8" → 135 {user_unit_preference} × 8 reps
- "135 * 8" or "135 x 8" → same with spaces
- "135, 8" or "135 8" → weight then reps (comma or space separator)
- "135lbs*8" or "135 lbs x 8" → 135 lbs × 8 (explicit unit overrides preference)
- "60kg*10" or "60 kg x 10" → 60 kg × 10 (explicit metric)
- "135#*8" → 135 lbs × 8 (# symbol means pounds)

BODYWEIGHT indicators (weight = 0, is_bodyweight = true):
- "bw*12" or "BW*12" or "bodyweight*12" → 0 × 12 reps (bodyweight)
- "0*12" or "-*12" → 0 × 12 reps (bodyweight)

DECIMAL weights:
- "135.5*8" → 135.5 {user_unit_preference} × 8 reps
- "60.5kg*10" → 60.5 kg × 10 reps

SPECIAL reps (is_failure = true):
- "135*AMRAP" or "135*max" or "135*F" → 135 × 0 reps with is_failure=true
- "135*8-10" → 135 × 8 reps (use lower bound of range)

SMART SHORTCUTS (ONLY when last set data is available):
{smart_shortcuts_section}

MULTIPLE sets on one line:
- "135*8, 145*6, 155*5" → 3 separate sets (comma-separated)
- "135*8; 145*6; 155*5" → 3 separate sets (semicolon-separated)

LABELED formats (strip labels, just parse numbers):
- "Set 1: 135*8" → parse as 135*8
- "1. 135*8" or "- 135*8" → parse as 135*8

═══════════════════════════════════════════════════════════════
NEW EXERCISE PATTERNS (adds to workout)
═══════════════════════════════════════════════════════════════

If input contains an exercise NAME, it's a NEW EXERCISE.

Formats:
- "3x10 deadlift at 135" → Deadlift: 3 sets × 10 reps @ 135 {user_unit_preference}
- "3*10 deadlift at 135" → same (star works too)
- "deadlift 3x10 at 135" → name first also works
- "deadlift 3x10 @ 135" → @ symbol for "at"
- "deadlift 3x10 135" → no preposition needed
- "deadlift 3x10 135lbs" → explicit unit
- "deadlift 135*8" → single set: 1 × 8 @ 135
- "bench 5x5 225" → Bench Press: 5×5 @ 225

ABBREVIATIONS to expand to full names:
- bench, bp → Bench Press
- squat, sq → Back Squat
- deadlift, dl → Deadlift
- ohp, press → Overhead Press
- row, br → Barbell Row
- pullups, pull-ups → Pull-ups
- dips → Dips
- rdl → Romanian Deadlift
- lat, pulldown → Lat Pulldown
- curl, bc → Bicep Curl
- tri, tricep → Tricep Extension
- leg press, lp → Leg Press

BODYWEIGHT exercises (is_bodyweight = true, no weight needed):
- "pull-ups 3x10" → Pull-ups: 3×10 @ bodyweight
- "dips 3x12" → Dips: 3×12 @ bodyweight
- "push-ups 3x15" → Push-ups: 3×15 @ bodyweight
- "weighted dips 3x8 +45" → Dips: 3×8 @ 45 lbs added weight

PLATE MATH (only if user says "plates"):
- "1 plate" = 135 lbs OR 60 kg (bar + 2×45lb plates)
- "2 plates" = 225 lbs OR 100 kg
- "bar only" = 45 lbs OR 20 kg

═══════════════════════════════════════════════════════════════
IMAGE ANALYSIS (if image provided)
═══════════════════════════════════════════════════════════════

Analyze the image for workout data:
1. Handwritten/printed text: exercise names, sets, reps, weights
2. App screenshots: extract exercise data from other fitness apps
3. Gym whiteboards: parse WOD/workout of the day
4. Weight plates on barbell: count plates, calculate total weight
   - 45lb plates (red/blue), 25lb (green), 10lb (yellow), 5lb, 2.5lb
   - Bar = 45 lbs / 20 kg
5. Cardio machine displays: distance, time, calories

═══════════════════════════════════════════════════════════════
OUTPUT FORMAT
═══════════════════════════════════════════════════════════════

Return JSON with this structure:
{{
  "sets_to_log": [
    {{
      "weight": 135.0,
      "reps": 8,
      "unit": "{user_unit_preference}",
      "is_bodyweight": false,
      "is_failure": false,
      "is_warmup": false,
      "original_input": "135*8",
      "notes": null
    }}
  ],
  "exercises_to_add": [
    {{
      "name": "Deadlift",
      "sets": 3,
      "reps": 10,
      "weight_kg": 61.2,
      "weight_lbs": 135.0,
      "rest_seconds": 60,
      "is_bodyweight": false,
      "original_text": "3x10 deadlift at 135",
      "confidence": 1.0,
      "notes": null
    }}
  ],
  "summary": "Log 1 set for {current_ex_context}, Add Deadlift",
  "warnings": []
}}

IMPORTANT RULES:
1. If NO exercise name → goes to sets_to_log
2. If HAS exercise name → goes to exercises_to_add
3. Both can be non-empty for mixed input
4. Expand abbreviations to full exercise names
5. Always provide both weight_kg and weight_lbs for exercises_to_add
6. Use is_bodyweight=true for bodyweight exercises

═══════════════════════════════════════════════════════════════
INPUT TO PARSE:
═══════════════════════════════════════════════════════════════
{combined_input or "See image below"}
'''

        try:
            # Build content list
            contents = [parse_prompt]

            # Add image if provided
            if image_base64:
                import base64
                contents.append(types.Part.from_bytes(
                    data=base64.b64decode(image_base64),
                    mime_type="image/jpeg"
                ))

            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=contents,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=ParseWorkoutInputV2Response,
                        max_output_tokens=4000,
                        temperature=0.2,  # Low for consistent parsing
                    ),
                ),
                timeout=30,  # 30s for workout input parsing
            )

            data = response.parsed
            if not data:
                raise ValueError("Gemini returned empty parse response")

            # Convert to dict format
            sets_to_log = []
            for s in data.sets_to_log:
                sets_to_log.append({
                    "weight": s.weight,
                    "reps": s.reps,
                    "unit": s.unit,
                    "is_bodyweight": s.is_bodyweight,
                    "is_failure": s.is_failure,
                    "is_warmup": s.is_warmup,
                    "original_input": s.original_input,
                    "notes": s.notes,
                })

            exercises_to_add = []
            for ex in data.exercises_to_add:
                exercises_to_add.append({
                    "name": ex.name,
                    "sets": ex.sets,
                    "reps": ex.reps,
                    "weight_kg": ex.weight_kg,
                    "weight_lbs": ex.weight_lbs,
                    "rest_seconds": ex.rest_seconds,
                    "is_bodyweight": ex.is_bodyweight,
                    "original_text": ex.original_text,
                    "confidence": ex.confidence,
                    "notes": ex.notes,
                })

            result = {
                "sets_to_log": sets_to_log,
                "exercises_to_add": exercises_to_add,
                "summary": data.summary,
                "warnings": data.warnings or [],
            }

            logger.info(
                f"✅ [ParseWorkoutV2] Parsed {len(sets_to_log)} sets, "
                f"{len(exercises_to_add)} exercises"
            )
            return result

        except Exception as e:
            logger.error(f"❌ [ParseWorkoutV2] Failed to parse: {e}")
            return {
                "sets_to_log": [],
                "exercises_to_add": [],
                "summary": f"Failed to parse input: {str(e)}",
                "warnings": ["Parsing failed. Please try rephrasing your input."]
            }

    def get_embedding(self, text: str) -> List[float]:
        """
        Get embedding vector for text (used for RAG).
        Uses local cache to avoid redundant embedding API calls.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        # Check embedding cache first
        try:
            cache_key = _embedding_cache.make_key("emb", text.strip().lower())
            cached = _embedding_cache.get(cache_key)
            if cached is not None:
                logger.debug(f"[EmbeddingCache] Cache HIT for: '{text[:40]}...'")
                return cached
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Cache lookup error (falling through): {cache_err}")

        result = client.models.embed_content(
            model=self.embedding_model,
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=768),
        )
        embedding = result.embeddings[0].values

        # Cache the result
        try:
            _embedding_cache.set(cache_key, embedding)
            logger.debug(f"[EmbeddingCache] Cache MISS - stored embedding for: '{text[:40]}...'")
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Failed to store embedding: {cache_err}")

        return embedding

    async def get_embedding_async(self, text: str) -> List[float]:
        """
        Get embedding vector for text asynchronously.
        Uses local cache to avoid redundant embedding API calls.

        Args:
            text: Text to embed

        Returns:
            Embedding vector as list of floats
        """
        # Check embedding cache first
        try:
            cache_key = _embedding_cache.make_key("emb", text.strip().lower())
            cached = _embedding_cache.get(cache_key)
            if cached is not None:
                logger.debug(f"[EmbeddingCache] Cache HIT (async) for: '{text[:40]}...'")
                return cached
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Cache lookup error (falling through): {cache_err}")

        result = await client.aio.models.embed_content(
            model=self.embedding_model,
            contents=text,
            config=types.EmbedContentConfig(output_dimensionality=768),
        )
        embedding = result.embeddings[0].values

        # Cache the result
        try:
            _embedding_cache.set(cache_key, embedding)
            logger.debug(f"[EmbeddingCache] Cache MISS (async) - stored embedding for: '{text[:40]}...'")
        except Exception as cache_err:
            logger.warning(f"[EmbeddingCache] Failed to store embedding: {cache_err}")

        return embedding

    def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts."""
        return [self.get_embedding(text) for text in texts]

    async def get_embeddings_batch_async(self, texts: List[str]) -> List[List[float]]:
        """Get embeddings for multiple texts asynchronously."""
        embeddings = []
        for text in texts:
            emb = await self.get_embedding_async(text)
            embeddings.append(emb)
        return embeddings

    # ============================================
    # Food Analysis Methods
    # ============================================

    async def analyze_food_image(
        self,
        image_base64: str,
        mime_type: str = "image/jpeg",
        request_id: str = None,
    ) -> Dict:
        """
        Analyze a food image and extract nutrition information using Gemini Vision.

        Args:
            image_base64: Base64 encoded image data
            mime_type: Image MIME type (e.g., 'image/jpeg', 'image/png')
            request_id: Unique request ID for log traceability

        Returns:
            Dictionary with food_items, total_calories, protein_g, carbs_g, fat_g, fiber_g, feedback
            On error, returns dict with 'error', 'error_code', and 'error_details' keys
        """
        req_id = request_id or f"img_{int(time.time() * 1000)}"
        image_size_kb = len(image_base64) * 3 // 4 // 1024  # Approximate decoded size

        logger.info(f"[IMAGE-ANALYSIS:{req_id}] Starting food image analysis | mime={mime_type} | size_kb={image_size_kb}")

        # Prompt with weight/count fields for portion editing (like text describe feature)
        prompt = '''Analyze this food image and identify the foods with their nutrition.

Return ONLY valid JSON (no markdown):
{
  "food_items": [
    {"name": "Food name", "amount": "portion size", "calories": 150, "protein_g": 10.0, "carbs_g": 15.0, "fat_g": 5.0, "fiber_g": 2.0, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null}
  ],
  "total_calories": 450,
  "protein_g": 25.0,
  "carbs_g": 40.0,
  "fat_g": 15.0,
  "fiber_g": 5.0,
  "feedback": "Brief nutritional feedback"
}

CRITICAL RULES:
- Identify ALL visible food items specifically (max 10 items)
- Be SPECIFIC with dish names: "Butter Chicken" not "Indian Curry", "Chicken Tikka Masala" not "Curry"
- For Indian food: identify specific dishes (dal makhani, paneer butter masala, chicken curry, biryani, etc.)
- RESTAURANT PORTIONS are large! Use realistic weights:
  - Naan bread: 80-100g EACH
  - Bowl of curry: 200-300g per bowl
  - Rice portion: 150-250g
  - Pakoras/samosas: 40-50g each
  - Roti/chapati: 40-50g each

WEIGHT/COUNT FIELDS (required for portion editing):
- weight_g: Total weight in grams for this item (be realistic for restaurant portions!)
- unit: "g" (solids), "ml" (liquids), "oz", "cups", "tsp", "tbsp"
- For COUNTABLE items (eggs, cookies, nuggets, slices, pieces, naan, roti):
  - count: Number of pieces visible
  - weight_per_unit_g: Weight of ONE piece (e.g., naan=90g, roti=45g, pakora=45g, samosa=80g)
  - weight_g = count × weight_per_unit_g
- For non-countable items (curry, rice, dal): count=null, weight_per_unit_g=null'''

        # Timeout for image analysis - needs to be generous for complex images
        IMAGE_ANALYSIS_TIMEOUT = 60  # 60 seconds for images with many food items
        start_time = time.time()

        try:
            # Create image part from base64
            try:
                image_part = types.Part.from_bytes(
                    data=__import__('base64').b64decode(image_base64),
                    mime_type=mime_type
                )
                logger.info(f"[IMAGE-ANALYSIS:{req_id}] Image decoded successfully")
            except Exception as decode_err:
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] FAILED to decode base64 image | error={decode_err}")
                return {
                    "error": "Failed to decode image",
                    "error_code": "IMAGE_DECODE_FAILED",
                    "error_details": str(decode_err),
                    "request_id": req_id,
                }

            # Add timeout to prevent hanging on slow Gemini responses
            logger.info(f"[IMAGE-ANALYSIS:{req_id}] Sending to Gemini API | model={self.model} | timeout={IMAGE_ANALYSIS_TIMEOUT}s")
            try:
                response = await asyncio.wait_for(
                    client.aio.models.generate_content(
                        model=self.model,
                        contents=[prompt, image_part],
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            response_schema=FoodAnalysisResponse,
                            max_output_tokens=8192,  # High limit to prevent truncation with micronutrients
                            temperature=0.3,
                        ),
                    ),
                    timeout=IMAGE_ANALYSIS_TIMEOUT
                )
                elapsed = time.time() - start_time
                logger.info(f"[IMAGE-ANALYSIS:{req_id}] Gemini API responded | elapsed={elapsed:.2f}s")
            except asyncio.TimeoutError:
                elapsed = time.time() - start_time
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] TIMEOUT after {elapsed:.2f}s (limit={IMAGE_ANALYSIS_TIMEOUT}s)")
                return {
                    "error": f"Image analysis timed out after {IMAGE_ANALYSIS_TIMEOUT} seconds. Please try again.",
                    "error_code": "GEMINI_TIMEOUT",
                    "error_details": f"Gemini API did not respond within {IMAGE_ANALYSIS_TIMEOUT}s",
                    "request_id": req_id,
                    "elapsed_seconds": elapsed,
                }

            # Check for blocked/filtered response
            if hasattr(response, 'prompt_feedback') and response.prompt_feedback:
                feedback = response.prompt_feedback
                if hasattr(feedback, 'block_reason') and feedback.block_reason:
                    logger.error(f"[IMAGE-ANALYSIS:{req_id}] BLOCKED by safety filter | reason={feedback.block_reason}")
                    return {
                        "error": "Image was blocked by content safety filter. Please try a different image.",
                        "error_code": "SAFETY_FILTER_BLOCKED",
                        "error_details": f"Block reason: {feedback.block_reason}",
                        "request_id": req_id,
                    }

            # Check if response has candidates
            if not response.candidates:
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] NO CANDIDATES in response | response={response}")
                return {
                    "error": "No analysis results returned from AI",
                    "error_code": "NO_CANDIDATES",
                    "error_details": "Gemini returned empty candidates array",
                    "request_id": req_id,
                }

            # Check candidate finish reason
            candidate = response.candidates[0]
            if hasattr(candidate, 'finish_reason'):
                finish_reason = str(candidate.finish_reason)
                if 'SAFETY' in finish_reason.upper():
                    logger.error(f"[IMAGE-ANALYSIS:{req_id}] SAFETY block on candidate | finish_reason={finish_reason}")
                    return {
                        "error": "Analysis blocked by content filter. Please try a different image.",
                        "error_code": "CANDIDATE_SAFETY_BLOCKED",
                        "error_details": f"Finish reason: {finish_reason}",
                        "request_id": req_id,
                    }

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                # Log raw response for debugging
                raw_text = response.text if hasattr(response, 'text') else 'N/A'
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] PARSING FAILED | raw_response_preview={raw_text[:500] if raw_text else 'empty'}")
                return {
                    "error": "Could not parse AI response. Please try again.",
                    "error_code": "PARSE_FAILED",
                    "error_details": f"Raw response preview: {raw_text[:200] if raw_text else 'empty'}",
                    "request_id": req_id,
                }
            result = parsed.model_dump()
            logger.info(f"[IMAGE-ANALYSIS:{req_id}] Parsed successfully | food_items_count={len(result.get('food_items', []))}")

            # Debug: Log raw Gemini values BEFORE USDA enhancement
            logger.info(
                f"[IMAGE-ANALYSIS:{req_id}] RAW GEMINI VALUES | "
                f"total_calories={result.get('total_calories')} | "
                f"protein_g={result.get('protein_g')} | "
                f"carbs_g={result.get('carbs_g')} | "
                f"fat_g={result.get('fat_g')}"
            )
            for idx, item in enumerate(result.get('food_items', [])):
                logger.info(
                    f"[IMAGE-ANALYSIS:{req_id}] RAW ITEM[{idx}] | "
                    f"name={item.get('name')} | "
                    f"calories={item.get('calories')} | "
                    f"protein_g={item.get('protein_g')} | "
                    f"carbs_g={item.get('carbs_g')} | "
                    f"fat_g={item.get('fat_g')} | "
                    f"weight_g={item.get('weight_g')}"
                )

            # Validation: Check for items with 0 calories (suspicious)
            zero_cal_items = [item.get('name') for item in result.get('food_items', []) if item.get('calories', 0) == 0]
            if zero_cal_items:
                logger.warning(f"[IMAGE-ANALYSIS:{req_id}] SUSPICIOUS: Gemini returned 0 calories for: {zero_cal_items}")

            # Enhance food items with USDA per-100g data for accurate scaling
            if result and result.get('food_items'):
                try:
                    enhanced_items = await self._enhance_food_items_with_usda(result['food_items'])
                    result['food_items'] = enhanced_items

                    # Recalculate totals based on enhanced items
                    total_calories = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                    total_protein = sum(item.get('protein_g', 0) or 0 for item in enhanced_items)
                    total_carbs = sum(item.get('carbs_g', 0) or 0 for item in enhanced_items)
                    total_fat = sum(item.get('fat_g', 0) or 0 for item in enhanced_items)
                    total_fiber = sum(item.get('fiber_g', 0) or 0 for item in enhanced_items)

                    result['total_calories'] = total_calories
                    result['protein_g'] = round(total_protein, 1)
                    result['carbs_g'] = round(total_carbs, 1)
                    result['fat_g'] = round(total_fat, 1)
                    result['fiber_g'] = round(total_fiber, 1)

                    logger.info(f"[IMAGE-ANALYSIS:{req_id}] USDA enhanced {len(enhanced_items)} items | total_calories={total_calories}")

                    # Debug: Log values AFTER USDA enhancement
                    for idx, item in enumerate(enhanced_items):
                        logger.info(
                            f"[IMAGE-ANALYSIS:{req_id}] ENHANCED ITEM[{idx}] | "
                            f"name={item.get('name')} | "
                            f"calories={item.get('calories')} | "
                            f"protein_g={item.get('protein_g')} | "
                            f"weight_g={item.get('weight_g')} | "
                            f"usda_data={'YES' if item.get('usda_data') else 'NO'}"
                        )
                except Exception as e:
                    logger.warning(f"[IMAGE-ANALYSIS:{req_id}] USDA enhancement failed, using AI estimates | error={e}")

            # Check if we got empty food items
            if not result.get('food_items'):
                logger.error(f"[IMAGE-ANALYSIS:{req_id}] NO FOOD ITEMS detected in image")
                return {
                    "error": "Could not identify any food items in the image. Please try a clearer photo.",
                    "error_code": "NO_FOOD_DETECTED",
                    "error_details": "Gemini returned empty food_items array",
                    "request_id": req_id,
                }

            # Success - log final summary
            total_elapsed = time.time() - start_time
            logger.info(
                f"[IMAGE-ANALYSIS:{req_id}] SUCCESS | "
                f"items={len(result.get('food_items', []))} | "
                f"calories={result.get('total_calories', 0)} | "
                f"elapsed={total_elapsed:.2f}s"
            )

            # Add request_id to result for traceability
            result['request_id'] = req_id
            return result

        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(
                f"[IMAGE-ANALYSIS:{req_id}] UNEXPECTED ERROR | "
                f"error_type={type(e).__name__} | "
                f"error={str(e)} | "
                f"elapsed={elapsed:.2f}s"
            )
            logger.exception(f"[IMAGE-ANALYSIS:{req_id}] Full traceback:")
            return {
                "error": "An unexpected error occurred during image analysis. Please try again.",
                "error_code": "UNEXPECTED_ERROR",
                "error_details": f"{type(e).__name__}: {str(e)}",
                "request_id": req_id,
            }

    async def parse_food_description(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None
    ) -> Optional[Dict]:
        """
        Parse a text description of food and extract nutrition information with goal-based rankings.

        Args:
            description: Natural language description of food
                        (e.g., "2 eggs, toast with butter, and orange juice")
            user_goals: List of user fitness goals (e.g., ["build_muscle", "lose_weight"])
            nutrition_targets: Dict with daily_calorie_target, daily_protein_target_g, etc.
            rag_context: Optional RAG context from ChromaDB for personalized feedback

        Returns:
            Dictionary with food_items (with rankings), total_calories, macros, ai_suggestion, etc.
        """
        # Check food text cache first (same food description returns same analysis)
        try:
            cache_key = _food_text_cache.make_key(
                "food_text", description.strip().lower(), user_goals, nutrition_targets
            )
            cached_result = _food_text_cache.get(cache_key)
            if cached_result is not None:
                logger.info(f"[FoodTextCache] Cache HIT for: '{description[:60]}...'")
                return cached_result
        except Exception as cache_err:
            logger.warning(f"[FoodTextCache] Cache lookup error (falling through): {cache_err}")

        # Build user context section for goal-based scoring
        user_context = ""
        if user_goals or nutrition_targets:
            user_context = "\nUSER FITNESS CONTEXT:\n"
            if user_goals:
                user_context += f"- Fitness Goals: {safe_join_list(user_goals, 'General fitness')}\n"
            if nutrition_targets:
                if nutrition_targets.get('daily_calorie_target'):
                    user_context += f"- Daily Calorie Target: {nutrition_targets['daily_calorie_target']} kcal\n"
                if nutrition_targets.get('daily_protein_target_g'):
                    user_context += f"- Daily Protein Target: {nutrition_targets['daily_protein_target_g']}g\n"
                if nutrition_targets.get('daily_carbs_target_g'):
                    user_context += f"- Daily Carbs Target: {nutrition_targets['daily_carbs_target_g']}g\n"
                if nutrition_targets.get('daily_fat_target_g'):
                    user_context += f"- Daily Fat Target: {nutrition_targets['daily_fat_target_g']}g\n"

        # Add RAG context if available
        rag_section = ""
        if rag_context:
            rag_section = f"\nNUTRITION KNOWLEDGE CONTEXT:\n{rag_context}\n"

        # Build scoring criteria based on goals - simplified for speed
        scoring_criteria = """
SCORING (1-10): Be strict. Restaurant/fast food: 4-6. Whole foods: 7-8. Score 9-10 is rare.
- Muscle goals: Need >25g protein for score >7
- Weight loss: Penalize >500 cal, need fiber for score >7
- Fried foods: -2 points. High sodium/sugar: -1 point each."""

        # Response format with micronutrients for complete nutrient tracking
        # Added count, weight_per_unit_g for countable items, and unit for measurement type
        if user_goals or nutrition_targets:
            response_format = '''{{
  "food_items": [
    {{"name": "Food name", "amount": "portion", "calories": 150, "protein_g": 10, "carbs_g": 15, "fat_g": 5, "fiber_g": 2, "goal_score": 7, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null}}
  ],
  "total_calories": 450,
  "protein_g": 25,
  "carbs_g": 40,
  "fat_g": 15,
  "fiber_g": 5,
  "sugar_g": 8,
  "sodium_mg": 500,
  "cholesterol_mg": 50,
  "vitamin_a_ug": 150,
  "vitamin_c_mg": 10,
  "vitamin_d_iu": 40,
  "calcium_mg": 100,
  "iron_mg": 2,
  "potassium_mg": 300,
  "overall_meal_score": 7,
  "encouragements": ["What's good about this meal for their goals"],
  "warnings": ["Any concerns - skip if none"],
  "ai_suggestion": "Next time: specific actionable tip",
  "recommended_swap": "Healthier alternative if applicable"
}}'''
        else:
            response_format = '''{{
  "food_items": [
    {{"name": "Food name", "amount": "portion", "calories": 150, "protein_g": 10, "carbs_g": 15, "fat_g": 5, "fiber_g": 2, "weight_g": 100, "unit": "g", "count": null, "weight_per_unit_g": null}}
  ],
  "total_calories": 450,
  "protein_g": 25,
  "carbs_g": 40,
  "fat_g": 15,
  "fiber_g": 5,
  "sugar_g": 8,
  "sodium_mg": 500,
  "cholesterol_mg": 50,
  "vitamin_a_ug": 150,
  "vitamin_c_mg": 10,
  "vitamin_d_iu": 40,
  "calcium_mg": 100,
  "iron_mg": 2,
  "potassium_mg": 300,
  "encouragements": ["What's good about this meal"],
  "warnings": ["Any concerns - skip if none"],
  "ai_suggestion": "Next time: specific actionable tip",
  "recommended_swap": "Healthier alternative if applicable"
}}'''

        # Build actionable tip guidance based on user goals
        tip_guidance = ""
        if user_goals or nutrition_targets:
            tip_guidance = """
COACH TIP STRUCTURE - Use these fields:
- encouragements: 1-2 short points on what's GOOD for their goals (e.g., "Great protein source for muscle building")
- warnings: Only if there are real concerns (high sodium, low fiber, etc.) - skip if meal is fine
- ai_suggestion: Start with "Next time:" then give ONE specific actionable tip (e.g., "Next time: Add spinach for iron and fiber")
- recommended_swap: Only if there's a clear healthier swap (e.g., "Swap white rice for brown rice +3g fiber")"""

        prompt = f'''Parse food and return nutrition JSON. Be fast and accurate.

Food: "{description}"
{user_context}{rag_section}{scoring_criteria if user_goals else ""}{tip_guidance}

Return ONLY JSON (no markdown):
{response_format}

CRITICAL PORTION SIZE RULES:
- If no size/portion specified, ALWAYS assume MEDIUM/REGULAR serving (not large)
- For restaurant foods without size: use their "regular" or "medium" option
- For packaged foods: use single serving from nutrition label
- For homemade: use standard single serving
- Movie popcorn (AMC/Regal/etc) without size = medium (~600-730 cal with butter, NOT large 1000+)
- Coffee drinks without size = medium (16oz)
- Fast food without size = regular/medium combo
- Pizza without count = assume 2 slices

COUNTABLE ITEMS - For foods naturally counted as pieces/units (NOT by weight):
- ALWAYS include "count" (number of pieces) and "weight_per_unit_g" (weight of ONE piece)
- Examples: tater tots (~8g each), cookies (~15g each), chicken nuggets (~18g each), eggs (~50g each), slices of pizza (~100g each), meatballs (~30g each)
- weight_g = count × weight_per_unit_g
- If user mentions count (e.g., "18 tater tots"), use that count
- If user just says "tater tots" without count, estimate reasonable serving (e.g., 10-12 pieces)

MEASUREMENT UNITS - Use "unit" field to specify the most natural unit:
- "g" = grams (default for solid foods: chicken, rice, bread)
- "ml" = milliliters (liquids: shakes, smoothies, milk, juice, soup)
- "oz" = fluid ounces (US drinks: coffee, soda)
- "cups" = cups (cooking: "2 cups of strawberry milkshake")
- "tsp" = teaspoons (small amounts: sugar, oil)
- "tbsp" = tablespoons (sauces, dressings, peanut butter)
- For liquids, weight_g should be the ml equivalent (1ml ≈ 1g for water-based drinks)
- Examples: protein shake → unit: "ml", 2 cups milkshake → unit: "cups", 1 tbsp peanut butter → unit: "tbsp"

Rules: Use USDA data. Sum totals from items. Account for prep methods (fried adds fat).

IMPORTANT - ALWAYS identify foods:
- For ANY food description, ALWAYS return valid food items with estimated nutrition
- If you don't recognize the exact item (e.g., "Cinnamon Delights from Taco Bell"), estimate based on similar foods (e.g., fried dough with cinnamon sugar)
- Fast food items without exact data: estimate based on ingredients and similar menu items
- NEVER return empty food_items - always make your best estimate'''

        # Retry logic for intermittent Gemini failures
        max_retries = 2
        last_error = None
        content = ""

        # Timeout for food analysis (20 seconds per attempt)
        FOOD_ANALYSIS_TIMEOUT = 20

        for attempt in range(max_retries):
            try:
                print(f"🔍 [Gemini] Parsing food description (attempt {attempt + 1}/{max_retries}): {description[:100]}...")

                # Add timeout to prevent hanging on slow Gemini responses
                try:
                    response = await asyncio.wait_for(
                        client.aio.models.generate_content(
                            model=self.model,
                            contents=prompt,
                            config=types.GenerateContentConfig(
                                response_mime_type="application/json",
                                response_schema=FoodAnalysisResponse,
                                max_output_tokens=8192,  # High limit to prevent truncation (MAX_TOKENS causes parsed=None)
                                temperature=0.2,  # Lower = faster, more deterministic
                            ),
                        ),
                        timeout=FOOD_ANALYSIS_TIMEOUT
                    )
                except asyncio.TimeoutError:
                    print(f"⚠️ [Gemini] Request timed out after {FOOD_ANALYSIS_TIMEOUT}s (attempt {attempt + 1})")
                    last_error = f"Timeout after {FOOD_ANALYSIS_TIMEOUT}s"
                    continue

                # Use response.parsed for structured output - SDK handles JSON parsing
                parsed = response.parsed
                result = None

                if parsed:
                    result = parsed.model_dump()
                else:
                    # Log details about why structured parsing failed
                    print(f"⚠️ [Gemini] Structured parsing returned None (attempt {attempt + 1})")
                    raw_text = response.text if response.text else ""
                    print(f"🔍 [Gemini] Raw response text: {raw_text[:500] if raw_text else 'None'}")

                    # Check for safety/blocking issues
                    if hasattr(response, 'candidates') and response.candidates:
                        for i, candidate in enumerate(response.candidates):
                            if hasattr(candidate, 'finish_reason'):
                                print(f"🔍 [Gemini] Candidate {i} finish_reason: {candidate.finish_reason}")
                            if hasattr(candidate, 'safety_ratings'):
                                print(f"🔍 [Gemini] Candidate {i} safety_ratings: {candidate.safety_ratings}")

                    # Try to parse raw text as JSON fallback
                    if raw_text:
                        print(f"🔍 [Gemini] Attempting fallback JSON parsing from raw text...")
                        result = self._extract_json_robust(raw_text)
                        if result:
                            print(f"✅ [Gemini] Fallback JSON parsing succeeded")
                        else:
                            print(f"⚠️ [Gemini] Fallback JSON parsing also failed")

                    if not result:
                        last_error = "Empty response - structured and fallback parsing failed"
                        continue

                print(f"🔍 [Gemini] Parsed response with {len(result.get('food_items', []))} items")

                if result and result.get('food_items'):
                    print(f"✅ [Gemini] Parsed {len(result.get('food_items', []))} food items")

                    # Enhance food items with USDA per-100g data for accurate scaling
                    try:
                        enhanced_items = await self._enhance_food_items_with_usda(result['food_items'])
                        result['food_items'] = enhanced_items

                        # Recalculate totals based on enhanced items
                        total_calories = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                        total_protein = sum(item.get('protein_g', 0) or 0 for item in enhanced_items)
                        total_carbs = sum(item.get('carbs_g', 0) or 0 for item in enhanced_items)
                        total_fat = sum(item.get('fat_g', 0) or 0 for item in enhanced_items)
                        total_fiber = sum(item.get('fiber_g', 0) or 0 for item in enhanced_items)

                        result['total_calories'] = total_calories
                        result['protein_g'] = round(total_protein, 1)
                        result['carbs_g'] = round(total_carbs, 1)
                        result['fat_g'] = round(total_fat, 1)
                        result['fiber_g'] = round(total_fiber, 1)

                        print(f"✅ [USDA] Enhanced {len(enhanced_items)} items, total: {total_calories} cal")
                    except Exception as e:
                        logger.warning(f"USDA enhancement failed, using AI estimates: {e}")
                        # Continue with original AI estimates if enhancement fails

                    # Cache the successful result
                    try:
                        _food_text_cache.set(cache_key, result)
                        logger.info(f"[FoodTextCache] Cache MISS - stored result for: '{description[:60]}...'")
                    except Exception as cache_err:
                        logger.warning(f"[FoodTextCache] Failed to store result: {cache_err}")

                    return result
                else:
                    print(f"⚠️ [Gemini] Failed to extract valid JSON with food_items (attempt {attempt + 1})")
                    last_error = "No food_items in response"
                    continue

            except Exception as e:
                print(f"⚠️ [Gemini] Food description parsing failed (attempt {attempt + 1}): {e}")
                last_error = str(e)
                continue

        # All retries exhausted with structured output - try one more time without schema
        print(f"⚠️ [Gemini] Structured output failed after {max_retries} attempts. Trying unstructured fallback...")

        try:
            # Try without response_schema - just ask for JSON
            fallback_response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        max_output_tokens=4096,
                        temperature=0.2,
                    ),
                ),
                timeout=FOOD_ANALYSIS_TIMEOUT
            )

            if fallback_response.text:
                print(f"🔍 [Gemini] Unstructured fallback response: {fallback_response.text[:500]}")
                result = self._extract_json_robust(fallback_response.text)
                if result and result.get('food_items'):
                    print(f"✅ [Gemini] Unstructured fallback succeeded with {len(result['food_items'])} items")

                    # Enhance with USDA data
                    try:
                        enhanced_items = await self._enhance_food_items_with_usda(result['food_items'])
                        result['food_items'] = enhanced_items
                        result['total_calories'] = sum(item.get('calories', 0) or 0 for item in enhanced_items)
                        result['protein_g'] = round(sum(item.get('protein_g', 0) or 0 for item in enhanced_items), 1)
                        result['carbs_g'] = round(sum(item.get('carbs_g', 0) or 0 for item in enhanced_items), 1)
                        result['fat_g'] = round(sum(item.get('fat_g', 0) or 0 for item in enhanced_items), 1)
                        result['fiber_g'] = round(sum(item.get('fiber_g', 0) or 0 for item in enhanced_items), 1)
                    except Exception as e:
                        logger.warning(f"USDA enhancement failed in fallback: {e}")

                    # Cache the fallback result too
                    try:
                        _food_text_cache.set(cache_key, result)
                        logger.info(f"[FoodTextCache] Cache MISS (fallback) - stored result for: '{description[:60]}...'")
                    except Exception as cache_err:
                        logger.warning(f"[FoodTextCache] Failed to store fallback result: {cache_err}")

                    return result
        except Exception as e:
            print(f"❌ [Gemini] Unstructured fallback also failed: {e}")

        print(f"❌ [Gemini] All {max_retries} attempts + fallback failed. Last error: {last_error}")
        print(f"❌ [Gemini] Last content was: {content[:500] if content else 'empty'}")
        return None

    def _extract_json_robust(self, content: str) -> Optional[Dict]:
        """
        Robustly extract and parse JSON from Gemini response.

        Uses the centralized AI response parser for general JSON parsing,
        with food-specific regex extraction as a specialized fallback.
        """
        import re

        if not content:
            return None

        original_content = content

        # Step 1: Use the centralized AI response parser
        # This handles: markdown extraction, boundary detection, trailing commas,
        # control characters, truncation repair, and AST fallback
        parse_result = parse_ai_json(content, context="gemini_service")

        if parse_result.success:
            if parse_result.was_repaired:
                print(f"✅ [Gemini] JSON repaired using {parse_result.strategy_used.value}: {parse_result.repair_steps}")
            return parse_result.data

        # Step 2: Food-specific regex extraction as specialized fallback
        # This handles truncated food analysis responses that the general parser can't recover
        print(f"⚠️ [Gemini] Central parser failed, attempting food-specific regex recovery...")

        try:
            # Try to extract food_items array - handle both complete and truncated responses
            # First try complete array with closing bracket
            food_items_match = re.search(r'"food_items"\s*:\s*\[(.*?)\]', content, re.DOTALL)
            if not food_items_match:
                # Try to find truncated food_items array (no closing bracket)
                food_items_start = re.search(r'"food_items"\s*:\s*\[', content)
                if food_items_start:
                    items_str = content[food_items_start.end():]
                    print(f"🔍 [Gemini] Found truncated food_items array, attempting recovery...")
                else:
                    items_str = None
            else:
                items_str = food_items_match.group(1)

            if items_str:
                # Extract individual food objects - look for complete objects with required fields
                food_objects = []
                # Match complete objects that have at minimum: name, calories, amount
                obj_pattern = r'\{\s*"name"\s*:\s*"[^"]+"\s*,\s*"amount"\s*:\s*"[^"]+"\s*,\s*"calories"\s*:\s*\d+[^{}]*\}'
                for obj_match in re.finditer(obj_pattern, items_str):
                    try:
                        obj = json.loads(obj_match.group())
                        food_objects.append(obj)
                    except json.JSONDecodeError:
                        # Try to fix the individual object
                        obj_str = obj_match.group()
                        obj_str = re.sub(r',\s*([}\]])', r'\1', obj_str)
                        try:
                            obj = json.loads(obj_str)
                            food_objects.append(obj)
                        except:
                            pass

                # If structured pattern failed, try simpler pattern for complete objects
                if not food_objects:
                    print(f"🔍 [Gemini] Trying simple pattern for complete objects...")
                    simple_pattern = r'\{[^{}]+\}'
                    for obj_match in re.finditer(simple_pattern, items_str):
                        try:
                            obj = json.loads(obj_match.group())
                            if 'name' in obj and 'calories' in obj:
                                food_objects.append(obj)
                                print(f"✅ [Gemini] Simple pattern matched: {obj.get('name')}")
                        except json.JSONDecodeError:
                            obj_str = obj_match.group()
                            obj_str = re.sub(r',\s*([}\]])', r'\1', obj_str)
                            try:
                                obj = json.loads(obj_str)
                                if 'name' in obj and 'calories' in obj:
                                    food_objects.append(obj)
                                    print(f"✅ [Gemini] Simple pattern (fixed) matched: {obj.get('name')}")
                            except:
                                pass

                # Try to recover truncated objects by extracting key-value pairs
                if not food_objects:
                    print(f"🔍 [Gemini] Attempting field-by-field recovery for truncated objects...")
                    # Find all objects that start but may not end
                    obj_starts = list(re.finditer(r'\{', items_str))
                    for i, start_match in enumerate(obj_starts):
                        start_pos = start_match.start()
                        # Find the next object start or end of string
                        if i + 1 < len(obj_starts):
                            end_pos = obj_starts[i + 1].start()
                        else:
                            end_pos = len(items_str)

                        obj_str = items_str[start_pos:end_pos]

                        # Extract fields using regex - flexible order
                        name_match = re.search(r'"name"\s*:\s*"([^"]+)"', obj_str)
                        amount_match = re.search(r'"amount"\s*:\s*"([^"]+)"', obj_str)
                        calories_match = re.search(r'"calories"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        protein_match = re.search(r'"protein_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        carbs_match = re.search(r'"carbs_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        fat_match = re.search(r'"fat_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)
                        fiber_match = re.search(r'"fiber_g"\s*:\s*(\d+(?:\.\d+)?)', obj_str)

                        # Must have at least name and calories
                        if name_match and calories_match:
                            recovered_obj = {
                                "name": name_match.group(1),
                                "amount": amount_match.group(1) if amount_match else "1 serving",
                                "calories": float(calories_match.group(1)),
                                "protein_g": float(protein_match.group(1)) if protein_match else 0,
                                "carbs_g": float(carbs_match.group(1)) if carbs_match else 0,
                                "fat_g": float(fat_match.group(1)) if fat_match else 0,
                                "fiber_g": float(fiber_match.group(1)) if fiber_match else 0,
                            }
                            food_objects.append(recovered_obj)
                            print(f"✅ [Gemini] Recovered truncated item: {recovered_obj['name']}")

                if food_objects:
                    # Calculate totals from individual items
                    total_calories = sum(item.get('calories', 0) for item in food_objects)
                    total_protein = sum(item.get('protein_g', 0) for item in food_objects)
                    total_carbs = sum(item.get('carbs_g', 0) for item in food_objects)
                    total_fat = sum(item.get('fat_g', 0) for item in food_objects)
                    total_fiber = sum(item.get('fiber_g', 0) for item in food_objects)

                    recovered_result = {
                        "food_items": food_objects,
                        "total_calories": total_calories,
                        "protein_g": total_protein,
                        "carbs_g": total_carbs,
                        "fat_g": total_fat,
                        "fiber_g": total_fiber,
                        "health_score": 5,  # Default neutral score
                        "ai_suggestion": f"Logged {len(food_objects)} item(s): ~{total_calories} cal, {total_protein}g protein. Values are estimates - adjust if needed."
                    }
                    print(f"✅ [Gemini] Recovered {len(food_objects)} food items via regex extraction")
                    return recovered_result
        except Exception as e:
            print(f"⚠️ [Gemini] Food-specific regex recovery failed: {e}")

        print(f"❌ [Gemini] All JSON parsing attempts failed. Content preview: {original_content[:200]}")
        return None

    async def analyze_ingredient_inflammation(
        self,
        ingredients_text: str,
        product_name: Optional[str] = None,
    ) -> Optional[Dict]:
        """
        Analyze ingredients for inflammatory properties using Gemini AI.

        Args:
            ingredients_text: Raw ingredients list from Open Food Facts
            product_name: Optional product name for context

        Returns:
            Dictionary with overall_score, category, ingredient_analyses, etc.
        """
        product_context = f"Product: {product_name}\n" if product_name else ""

        prompt = f'''You are a nutrition scientist specializing in inflammation and food science. Analyze the following ingredients list and determine the inflammatory properties of each ingredient and the product overall.

{product_context}Ingredients: {ingredients_text}

INFLAMMATION SCORING CRITERIA (1 = lowest inflammation/healthiest, 10 = highest inflammation/unhealthiest):

EXCELLENT - LOW INFLAMMATION (Score 1-2):
- Pure water, mineral water, sparkling water (essential for hydration, zero inflammatory properties)
- Turmeric/curcumin
- Omega-3 rich foods (fish oil, flaxseed)
- Green leafy vegetables
- Berries (blueberries, strawberries)
- Ginger, garlic
- Green tea extract

GOOD - ANTI-INFLAMMATORY (Score 3-4):
- Whole grains (oats, quinoa, brown rice)
- Legumes, beans
- Many vegetables and fruits
- Olive oil, avocado oil
- Nuts and seeds
- Natural herbs and spices

NEUTRAL (Score 5-6):
- Salt in moderate amounts
- Natural flavors (depends on source)
- Many starches
- Unprocessed ingredients with no known inflammatory effect

POOR - MODERATELY INFLAMMATORY (Score 7-8):
- Excessive saturated fats from processed meats
- Refined grains (some white rice, white bread ingredients)
- Excessive sodium compounds
- Some preservatives (sodium benzoate, potassium sorbate)
- Conventional dairy in excess

VERY POOR - HIGHLY INFLAMMATORY (Score 9-10):
- Refined sugars, high-fructose corn syrup
- Trans fats, partially hydrogenated oils
- Heavily processed seed/vegetable oils (soybean oil, corn oil, canola oil)
- Artificial sweeteners (aspartame, sucralose)
- MSG, artificial colors, artificial preservatives
- Refined carbohydrates, white flour

Return ONLY valid JSON in this exact format (no markdown, no explanation):
{{
  "overall_score": 5,
  "overall_category": "neutral",
  "summary": "Plain language summary of the product's inflammatory profile in 1-2 sentences.",
  "recommendation": "Brief actionable recommendation for the consumer.",
  "analysis_confidence": 0.85,
  "ingredient_analyses": [
    {{
      "name": "ingredient name",
      "category": "inflammatory|anti_inflammatory|neutral|additive|unknown",
      "score": 5,
      "reason": "Brief explanation why this ingredient has this score",
      "is_inflammatory": false,
      "is_additive": false,
      "scientific_notes": null
    }}
  ],
  "inflammatory_ingredients": ["ingredient1", "ingredient2"],
  "anti_inflammatory_ingredients": ["ingredient3", "ingredient4"],
  "additives_found": ["additive1", "additive2"]
}}

IMPORTANT RULES:
1. Score each ingredient individually from 1-10 (1=healthiest/lowest inflammation, 10=unhealthiest/highest inflammation)
2. Calculate overall_score as a weighted average (inflammatory ingredients weigh more heavily)
3. overall_category must be one of: highly_inflammatory, moderately_inflammatory, neutral, anti_inflammatory, highly_anti_inflammatory
4. is_inflammatory = true if score >= 7
5. is_additive = true for preservatives, colorings, emulsifiers, stabilizers
6. Keep the summary consumer-friendly, avoid jargon
7. If you cannot identify an ingredient, use category "unknown" with score 5
8. List ALL inflammatory ingredients (score 7-10) in inflammatory_ingredients
9. List ALL anti-inflammatory ingredients (score 1-4) in anti_inflammatory_ingredients
10. List ALL additives/preservatives in additives_found'''

        try:
            print(f"🔍 [Gemini] Analyzing ingredient inflammation for: {product_name or 'Unknown product'}")
            try:
                response = await asyncio.wait_for(
                    client.aio.models.generate_content(
                        model=self.model,
                        contents=prompt,
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            response_schema=InflammationAnalysisGeminiResponse,
                            max_output_tokens=4000,
                            temperature=0.2,  # Low temperature for consistent classification
                        ),
                    ),
                    timeout=30,  # 30s for inflammation analysis
                )
            except asyncio.TimeoutError:
                logger.error("[Inflammation] Gemini API timed out after 30s")
                return None

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                print("⚠️ [Gemini] Empty response from inflammation analysis")
                return None

            result = parsed.model_dump()

            # Validate and fix overall_category
            valid_categories = [
                "highly_inflammatory", "moderately_inflammatory",
                "neutral", "anti_inflammatory", "highly_anti_inflammatory"
            ]
            if result.get("overall_category") not in valid_categories:
                # Derive from score (1=healthiest, 10=most inflammatory)
                score = result.get("overall_score", 5)
                if score <= 2:
                    result["overall_category"] = "highly_anti_inflammatory"
                elif score <= 4:
                    result["overall_category"] = "anti_inflammatory"
                elif score <= 6:
                    result["overall_category"] = "neutral"
                elif score <= 8:
                    result["overall_category"] = "moderately_inflammatory"
                else:
                    result["overall_category"] = "highly_inflammatory"

            # Ensure required fields exist
            result.setdefault("ingredient_analyses", [])
            result.setdefault("inflammatory_ingredients", [])
            result.setdefault("anti_inflammatory_ingredients", [])
            result.setdefault("additives_found", [])
            result.setdefault("summary", "Analysis complete.")
            result.setdefault("recommendation", None)
            result.setdefault("analysis_confidence", 0.8)

            print(f"✅ [Gemini] Inflammation analysis complete: score={result.get('overall_score')}, category={result.get('overall_category')}")
            return result

        except Exception as e:
            print(f"❌ [Gemini] Ingredient inflammation analysis failed: {e}")
            logger.exception("Full traceback:")
            return None

    def _get_holiday_theme(self, workout_date: Optional[str] = None) -> Optional[str]:
        """
        Check if workout date is near a holiday and return themed naming suggestions.
        Returns None if no holiday nearby.
        """
        from datetime import datetime, timedelta

        if not workout_date:
            check_date = datetime.now()
        else:
            try:
                check_date = datetime.fromisoformat(workout_date.replace('Z', '+00:00'))
            except:
                check_date = datetime.now()

        month, day = check_date.month, check_date.day

        # Define holidays with a 7-day window before/after
        holidays = {
            # US Holidays
            (1, 1): ("New Year", "Fresh Start, Resolution, New Year, Midnight"),
            (2, 14): ("Valentine's Day", "Heart, Love, Cupid, Valentine"),
            (3, 17): ("St Patrick's Day", "Lucky, Shamrock, Irish, Green"),
            (7, 4): ("Independence Day", "Freedom, Firework, Liberty, Patriot"),
            (10, 31): ("Halloween", "Monster, Spooky, Beast, Phantom"),
            (11, 11): ("Veterans Day", "Warrior, Honor, Hero, Valor"),
            (12, 25): ("Christmas", "Blitzen, Reindeer, Jolly, Frost"),
            (12, 31): ("New Year's Eve", "Countdown, Finale, Midnight, Resolution"),
        }

        # Check for Thanksgiving week (Nov 20-28)
        if month == 11 and 20 <= day <= 28:
            return "🦃 THANKSGIVING WEEK! Consider festive names like: 'Turkey Burn Legs', 'Grateful Grind Core', 'Feast Mode Arms', 'Pilgrim Power Back'"

        # Check each holiday with 7-day window
        for (h_month, h_day), (holiday_name, words) in holidays.items():
            holiday_date = check_date.replace(month=h_month, day=h_day)
            days_diff = abs((check_date - holiday_date).days)

            if days_diff <= 7:
                return f"🎉 {holiday_name.upper()} WEEK! Consider festive themed words: {words}. Example: '{words.split(', ')[0]} Power Legs'"

        return None

    def _build_coach_naming_context(
        self,
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        workout_date: Optional[str] = None,
    ) -> str:
        """
        Build dynamic workout naming instructions based on coach personality and date context.

        Each coach style gets unique naming themes that match their personality.
        Holiday/occasion context is also incorporated when relevant.
        """
        from datetime import datetime

        # Coach style influences naming theme - each style has unique flavor
        style_naming = {
            "drill-sergeant": "INTENSE military-style name (e.g., 'Operation Quad Strike', 'Code Red Chest', 'Tactical Arms Assault', 'Delta Force Legs', 'Bravo Company Back')",
            "zen-master": "Peaceful, nature-inspired name (e.g., 'Flowing River Legs', 'Mountain Peak Chest', 'Lotus Core Flow', 'Bamboo Strength Arms', 'Ocean Wave Back')",
            "hype-beast": "HYPED explosive name with energy (e.g., 'INSANE Leg Destroyer', 'CRAZY Arms Pump', 'LEGENDARY Chest Blast', 'UNREAL Core Crusher', 'EPIC Back Attack')",
            "scientist": "Scientific/technical name (e.g., 'Quadriceps Protocol', 'Pectoral Synthesis', 'Deltoid Optimization', 'Gluteal Activation Study', 'Bicep Hypertrophy Lab')",
            "comedian": "Fun punny name (e.g., 'Leg Day or Leg Night', 'Armed and Dangerous', 'Chest Quest Comedy', 'Core Blimey', 'Back to the Future')",
            "old-school": "Classic bodybuilding name (e.g., 'Golden Era Legs', 'Pumping Iron Chest', 'Old School Arms', 'Classic Physique Back', 'Bronze Age Core')",
            "pirate": "Nautical adventure name (e.g., 'Treasure Hunt Legs', 'Cannonball Chest', 'Anchor Arms Ahoy', 'Seven Seas Core', 'Kraken Back Attack')",
            "anime": "Epic anime-style name (e.g., 'PLUS ULTRA Legs', 'Final Form Chest', 'Power Level Arms', 'Spirit Bomb Core', 'Dragon Fist Back')",
            "motivational": "Inspiring power name (e.g., 'Champion Legs Rise', 'Victory Chest Surge', 'Warrior Arms Awakening', 'Unstoppable Core', 'Conqueror Back')",
            "professional": "Clean professional name (e.g., 'Precision Leg Training', 'Elite Chest Session', 'Performance Arms', 'Core Excellence', 'Back Mastery')",
            "friendly": "Warm encouraging name (e.g., 'Happy Legs Day', 'Chest Fest Fun', 'Arms Adventure', 'Core Journey', 'Back Bonanza')",
            "tough-love": "Direct intense name (e.g., 'No Excuses Legs', 'Earn Your Chest', 'Prove It Arms', 'Grind Core', 'Pain Equals Gain Back')",
            "college-coach": "Athletic sports name (e.g., 'Championship Legs', 'Varsity Chest Press', 'All-Star Arms', 'MVP Core', 'Starting Lineup Back')",
        }

        # Tone can add extra flavor
        tone_modifiers = {
            "gen-z": " (no cap, this hits different)",
            "sarcastic": " (with a side of sass)",
            "roast-mode": " (time to get roasted into shape)",
            "pirate": " (arrr matey!)",
            "british": " (quite proper, old sport)",
            "surfer": " (totally gnarly vibes)",
            "anime": " (PLUS ULTRA energy!)",
        }

        # Default naming for styles not in the map
        default_naming = "EXCITING unique name (e.g., 'Thunder Legs', 'Phoenix Push', 'Iron Core', 'Beast Mode Arms', 'Storm Shoulders', 'Venom Back', 'Primal Chest')"

        base_instruction = style_naming.get(coach_style, default_naming)

        # Add tone modifier if applicable
        tone_suffix = tone_modifiers.get(coach_tone, "")

        # Get holiday/occasion context
        holiday_context = self._get_holiday_theme(workout_date)

        # Also check day of week for non-holiday days
        day_theme = None
        if not holiday_context and workout_date:
            try:
                date = datetime.fromisoformat(workout_date.replace('Z', '+00:00'))
                weekday = date.strftime("%A")
                day_themes = {
                    "Monday": "Monday Motivation",
                    "Wednesday": "Midweek Momentum",
                    "Friday": "Friday Finisher",
                    "Saturday": "Weekend Warrior",
                    "Sunday": "Sunday Strength",
                }
                day_theme = day_themes.get(weekday)
            except Exception:
                pass

        # Build the final instruction
        if holiday_context:
            # Holiday takes priority - extract the theme words
            final_instruction = f"Generate a {base_instruction}{tone_suffix}. {holiday_context}"
        elif day_theme:
            final_instruction = f"Generate a {day_theme}-themed {base_instruction}{tone_suffix}"
        else:
            final_instruction = f"Generate a {base_instruction}{tone_suffix}"

        return f"{final_instruction}. NEVER use bland generic words like Foundation, Basic, Total, Simple, Standard, Beginner, General, Routine, Session, Program."

    async def generate_workout_plan(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        custom_exercises: Optional[List[Dict]] = None,
        workout_environment: Optional[str] = None,
        equipment_details: Optional[List[Dict]] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[dict]] = None,
        comeback_context: Optional[str] = None,
        progression_philosophy: Optional[str] = None,
        workout_patterns_context: Optional[str] = None,
        favorite_workouts_context: Optional[str] = None,
        neat_context: Optional[str] = None,
        set_type_context: Optional[str] = None,
        primary_goal: Optional[str] = None,
        muscle_focus_points: Optional[Dict[str, int]] = None,
        training_split: Optional[str] = None,
        # Fitness Assessment fields - for smarter workout personalization
        pushup_capacity: Optional[str] = None,
        pullup_capacity: Optional[str] = None,
        plank_capacity: Optional[str] = None,
        squat_capacity: Optional[str] = None,
        cardio_capacity: Optional[str] = None,
    ) -> Dict:
        """
        Generate a personalized workout plan using AI.

        Args:
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            equipment: List of available equipment
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Optional list of words to avoid in the workout name (for variety)
            workout_date: Optional date for the workout (ISO format) to enable holiday theming
            age: Optional user's age for age-appropriate exercise selection
            activity_level: Optional activity level (sedentary, lightly_active, moderately_active, very_active)
            intensity_preference: Optional intensity preference (easy, medium, hard) - overrides fitness_level for difficulty
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX", "Improve box jump height")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed) - affects exercise selection
            custom_exercises: Optional list of user's custom exercises to potentially include
            workout_environment: Optional workout environment (commercial_gym, home_gym, home, outdoors, hotel, etc.)
            equipment_details: Optional detailed equipment info with quantities and weights
                               [{"name": "dumbbells", "quantity": 2, "weights": [15, 25, 40], "weight_unit": "lbs"}]
            avoided_exercises: Optional list of exercise names the user wants to avoid (e.g., injuries, preferences)
            avoided_muscles: Optional dict with 'avoid' (completely skip) and 'reduce' (minimize) muscle groups
            staple_exercises: Optional list of dicts with name, reason, muscle_group for user's staple exercises
            comeback_context: Optional context string for users returning from extended breaks (includes specific
                            adjustments for volume, intensity, rest periods, and age-specific modifications)
            progression_philosophy: Optional progression philosophy prompt section for leverage-based progressions
                                  and user rep preferences. Built by build_progression_philosophy_prompt().
            workout_patterns_context: Optional context string with user's historical workout patterns including
                                     set/rep limits and exercise-specific averages. Built by get_user_workout_patterns().
            neat_context: Optional NEAT (Non-Exercise Activity Thermogenesis) context string with user's daily
                         activity patterns, step goals, streaks, and sedentary habits. Built by
                         user_context_service.get_neat_context_for_ai().
            set_type_context: Optional context string with user's historical set type preferences (drop sets,
                            failure sets, AMRAP) and acceptance rates. Built by build_set_type_context().
            primary_goal: Optional primary training goal ('muscle_hypertrophy', 'muscle_strength', or
                         'strength_hypertrophy'). Affects rep ranges and exercise selection.
            muscle_focus_points: Optional dict mapping muscle groups to focus points (1-5).
                                Example: {"triceps": 2, "lats": 1, "obliques": 2}
                                Muscles with more points get emphasized more in workouts.
            training_split: Optional training split identifier (full_body, push_pull_legs, pplul, etc.)
                           Used to provide rich context about the split's schedule, hypertrophy score,
                           and scientific rationale to the AI.
            pushup_capacity: Optional fitness assessment - push-up capacity
                            (e.g., 'none', '1-10', '11-25', '26-40', '40+')
            pullup_capacity: Optional fitness assessment - pull-up capacity
                            (e.g., 'none', 'assisted', '1-5', '6-10', '10+')
            plank_capacity: Optional fitness assessment - plank hold duration
                           (e.g., '<15sec', '15-30sec', '31-60sec', '1-2min', '2+min')
            squat_capacity: Optional fitness assessment - bodyweight squat capacity
                           (e.g., '0-10', '11-25', '26-40', '40+')
            cardio_capacity: Optional fitness assessment - cardio endurance
                            (e.g., '<5min', '5-15min', '15-30min', '30+min')

        Returns:
            Dict with workout structure including name, type, difficulty, exercises
        """
        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hell":
                print(f"🔥 [Gemini] WARNING: Beginner fitness level with HELL intensity - this is extremely challenging!")
            elif fitness_level == "beginner" and intensity_preference == "hard":
                print(f"⚠️ [Gemini] WARNING: Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hell":
                print(f"🔥 [Gemini] Note: Intermediate fitness level with HELL intensity - maximum challenge mode")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                print(f"🔍 [Gemini] Note: Intermediate fitness level with hard intensity - will challenge the user")
            elif intensity_preference == "hell":
                print(f"🔥 [Gemini] HELL MODE ACTIVATED - generating maximum intensity workout")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction if provided
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ IMPORTANT: Do NOT use these words in the workout name (they've been used recently): {', '.join(avoid_name_words)}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Build age and activity level context
        # Import senior-specific prompt additions from adaptive_workout_service
        from services.adaptive_workout_service import get_senior_workout_prompt_additions

        age_activity_context = ""
        senior_critical_instruction = ""  # For seniors 60+, this adds critical limits
        if age:
            bracket = age_to_bracket(age)
            if age < 30:
                age_activity_context += f"\n- Age group: {bracket} (can handle higher intensity, explosive movements, max 25 reps/exercise)"
            elif age < 45:
                age_activity_context += f"\n- Age group: {bracket} (balanced approach to intensity, max 20 reps/exercise)"
            elif age < 60:
                age_activity_context += f"\n- Age group: {bracket} (focus on joint-friendly exercises, longer warm-ups, max 16 reps/exercise)"
            else:
                # Senior users (60+) - get detailed safety instructions
                senior_prompt_data = get_senior_workout_prompt_additions(age)
                if senior_prompt_data:
                    age_activity_context += f"\n- Age group: {bracket} ({senior_prompt_data['age_bracket']} - REDUCED INTENSITY REQUIRED)"
                    # Add critical senior instructions to the prompt
                    senior_critical_instruction = senior_prompt_data["critical_instructions"]
                    # Also append movement guidance
                    movements_to_avoid = ", ".join(senior_prompt_data.get("movements_to_avoid", [])[:5])
                    movement_priorities = ", ".join(senior_prompt_data.get("movement_priorities", [])[:5])
                    senior_critical_instruction += f"\n- PRIORITIZE: {movement_priorities}"
                    senior_critical_instruction += f"\n- AVOID: {movements_to_avoid}"
                else:
                    age_activity_context += f"\n- Age group: {bracket} (prioritize low-impact, balance exercises, max 12 reps/exercise)"

        if activity_level:
            activity_descriptions = {
                'sedentary': 'sedentary (new to exercise - start slow, more rest periods)',
                'lightly_active': 'lightly active (exercises 1-3 days/week - moderate intensity)',
                'moderately_active': 'moderately active (exercises 3-5 days/week - can handle challenging workouts)',
                'very_active': 'very active (exercises 6-7 days/week - high intensity appropriate)'
            }
            activity_desc = activity_descriptions.get(activity_level, activity_level)
            age_activity_context += f"\n- Activity Level: {activity_desc}"

        # Add safety instruction if there's a mismatch between fitness level and intensity
        # Also add special instructions for HELL mode workouts
        safety_instruction = ""
        if difficulty == "hell":
            safety_instruction = """

🔥 HELL MODE - MAXIMUM INTENSITY WORKOUT:
This is an EXTREME intensity workout. You MUST:
1. Use heavier weights than normal (increase by 20-30% from typical recommendations)
2. Minimize rest periods (30-45 seconds max between sets)
3. Include advanced techniques: drop sets, supersets, AMRAP sets, tempo training
4. Push rep ranges to near-failure (aim for RPE 9-10)
5. Include explosive and compound movements
6. Add intensity boosters like pause reps, 1.5 reps, or slow eccentrics
7. This workout should be BRUTAL - make users feel accomplished for finishing
8. Include challenging exercise variations (see HELL MODE EXERCISES below)
9. Higher volume: more sets per exercise (4-5 sets minimum)

🏋️ HELL MODE EXERCISES - USE THESE HARD VARIATIONS:
LEGS (choose from these):
- Barbell Back Squat (heavy), Front Squat, Pause Squat, Bulgarian Split Squat
- Romanian Deadlift, Stiff-Leg Deadlift, Sumo Deadlift
- Walking Lunges (weighted), Reverse Lunges, Jump Lunges
- Leg Press (heavy), Hack Squat, Sissy Squat
- Box Jumps, Jump Squats, Pistol Squats

CHEST (choose from these):
- Barbell Bench Press (heavy), Incline Barbell Press, Decline Press
- Dumbbell Bench Press (heavy), Incline Dumbbell Press
- Weighted Dips, Deficit Push-Ups, Clap Push-Ups
- Cable Flyes (heavy), Dumbbell Flyes

BACK (choose from these):
- Deadlift (conventional or sumo), Rack Pulls
- Barbell Row (heavy), Pendlay Row, T-Bar Row
- Weighted Pull-Ups, Weighted Chin-Ups, Muscle-Ups
- Lat Pulldown (heavy), Seated Cable Row (heavy)

SHOULDERS (choose from these):
- Overhead Press (barbell), Push Press, Arnold Press
- Dumbbell Shoulder Press (heavy), Z-Press
- Lateral Raise (heavy), Cable Lateral Raise
- Face Pulls (heavy), Rear Delt Flyes, Upright Row

ARMS (choose from these):
- Barbell Curl (heavy), Preacher Curl, Spider Curl
- Skull Crushers, Close-Grip Bench Press, Overhead Tricep Extension
- Weighted Dips (tricep focus), Diamond Push-Ups

⛔ DO NOT USE THESE EASY EXERCISES IN HELL MODE:
- Bodyweight squats (use barbell squats instead)
- Regular push-ups (use weighted/deficit/clap variations)
- Dumbbell curls with light weight (use barbell or heavy dumbbells)
- Machine exercises when free weights are available
- Any exercise without added resistance/weight

HELL MODE NAMING: Use intense, aggressive names like "Inferno", "Apocalypse", "Devastation", "Annihilation", "Carnage", "Rampage"."""
            if fitness_level == "beginner":
                safety_instruction += "\n\n⚠️ BEGINNER IN HELL MODE: Scale weights appropriately but maintain high intensity. Focus on form while pushing limits. Include extra rest if needed for safety."
            elif fitness_level == "intermediate":
                safety_instruction += "\n\n💪 INTERMEDIATE IN HELL MODE: Push to your limits with challenging weights and minimal rest. You can handle this - make it count!"
        elif fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Choose challenging exercises but ensure proper form is achievable. Include more rest periods and focus on compound movements with moderate weights rather than advanced techniques."

        # Add difficulty-based rep/weight scaling
        difficulty_scaling_instruction = ""
        if difficulty == "easy":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - EASY MODE:
- Sets: 3 sets per exercise (MINIMUM 3 sets - never use 2 sets)
- Reps: 10-12 reps (higher rep range, lighter load)
- Weights: Use 60-70% of typical recommendations
- Rest: 90-120 seconds between sets
- RPE Target: 5-6 (comfortable, could do 4+ more reps)
- Focus: Form and technique over intensity
- set_targets: Generate 3 set targets for each exercise (all working sets)"""
        elif difficulty == "medium" or difficulty == "moderate":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - MODERATE MODE:
- Sets: 3-4 sets per exercise
- Reps: 8-12 reps (standard hypertrophy range)
- Weights: Use typical recommended weights for fitness level
- Rest: 60-90 seconds between sets
- RPE Target: 7-8 (challenging but sustainable)
- Focus: Balance of form and progressive overload
- set_targets: Generate 3-4 set targets for each exercise (all working sets)"""
        elif difficulty == "challenging" or difficulty == "hard":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - CHALLENGING MODE:
- Sets: 3-4 sets per exercise (compound: 4 sets)
- Reps: 6-10 reps (slightly lower reps, heavier weights)
- Weights: Increase typical recommendations by 10-15%
- Rest: 60-75 seconds between sets (shorter rest)
- RPE Target: 8-9 (pushing limits, 1-2 reps in reserve)
- Include: 1-2 exercises with failure on last set
- Focus: Progressive overload and intensity
- set_targets: Generate 3-4 set targets for each exercise (include failure sets)"""
        elif difficulty == "hell" or difficulty == "extreme":
            difficulty_scaling_instruction = """

📊 DIFFICULTY SCALING - HELL MODE:
- Sets: 4-5 sets per exercise (MINIMUM 4 sets, preferably 5)
- Reps: 6-8 for compounds, 8-10 for isolation, AMRAP on final sets
- Weights: Increase typical recommendations by 20-30% (use HEAVY weights)
- Rest: 30-45 seconds between sets (minimal rest, NO 60s+ rest periods)
- RPE Target: 9-10 (near failure or failure on every working set)
- Include: At least 2 drop set exercises, 1 superset pair, AMRAP finisher
- Volume: 6-8 exercises minimum, high total volume
- Exercise Selection: ONLY use advanced/compound exercises - NO basic bodyweight moves
- Focus: Maximum intensity, muscle breakdown, mental toughness
- Mark is_failure_set: true on at least 2 exercises
- Mark is_drop_set: true on at least 1 isolation exercise
- set_targets: Generate 4-5 set targets for each exercise (include warmup, working, drop, failure sets)"""

        safety_instruction += difficulty_scaling_instruction

        # Determine workout type (strength, cardio, or mixed)
        # Addresses competitor feedback: "I hate how you can't pick cardio for one of your workouts"
        workout_type = workout_type_preference if workout_type_preference else "strength"
        workout_type_instruction = ""
        if workout_type == "cardio":
            workout_type_instruction = """

🏃 CARDIO WORKOUT TYPE:
This is a CARDIO-focused workout. You MUST:
1. Include time-based exercises (running, cycling, rowing, jump rope)
2. Use duration_seconds instead of reps for cardio exercises (e.g., "30 seconds jump rope")
3. Focus on heart rate elevation and endurance
4. Include intervals if appropriate (e.g., 30s work / 15s rest)
5. Minimize rest periods between exercises (30-45 seconds max)
6. For cardio exercises, use sets=1 and reps=1, with duration_seconds for the work period

CARDIO EXERCISE EXAMPLES:
- Jumping Jacks: 45 duration_seconds, sets=1, reps=1
- High Knees: 30 duration_seconds, sets=3
- Burpees: 20 duration_seconds, sets=4
- Mountain Climbers: 30 duration_seconds, sets=3
- Running in Place: 60 duration_seconds, sets=1
- Jump Rope: 45 duration_seconds, sets=4"""
        elif workout_type == "mixed":
            workout_type_instruction = """

🔥 MIXED WORKOUT TYPE:
This is a MIXED workout combining strength AND cardio. You MUST:
1. Alternate between strength and cardio exercises
2. Include 2-3 cardio bursts between strength sets
3. Use circuit-style training where possible
4. Keep rest periods shorter than pure strength workouts (45-60 seconds)
5. Include both weighted exercises AND time-based cardio movements

STRUCTURE SUGGESTION:
- Start with compound strength movement
- Follow with cardio burst (30-45 seconds)
- Repeat pattern for full workout"""
        elif workout_type == "mobility":
            workout_type_instruction = """

🧘 MOBILITY WORKOUT TYPE:
This is a MOBILITY/FLEXIBILITY-focused workout. You MUST:
1. Focus on stretching, yoga poses, and mobility drills
2. Use hold_seconds for static stretches (typically 30-60 seconds)
3. Include dynamic mobility movements with controlled tempo
4. Emphasize joint range of motion and flexibility
5. Keep rest minimal (15-30 seconds) - these are low-intensity movements
6. Include unilateral (single-side) exercises for balance work

MOBILITY EXERCISE CATEGORIES TO INCLUDE:
- Static stretches: Hip flexor stretch, Hamstring stretch, Pigeon pose (hold_seconds: 30-60)
- Dynamic mobility: Leg swings, Arm circles, Cat-cow (sets: 2-3, reps: 10-15)
- Yoga poses: Downward dog, Cobra, Child's pose, Warrior poses (hold_seconds: 30-45)
- Joint circles: Ankle circles, Wrist circles, Neck rotations (sets: 2, reps: 10 each direction)
- Foam rolling/Self-myofascial release: IT band roll, Quad roll (hold_seconds: 30-45 per area)

STRUCTURE FOR MOBILITY:
- Start with joint circles and dynamic warm-up (5 min)
- Progress to deeper stretches and yoga poses (15-20 min)
- Include balance and stability work (5 min)
- End with relaxation poses and breathing (5 min)

MOBILITY-SPECIFIC JSON FIELDS:
- Use "hold_seconds" for static holds instead of reps
- Set reps=1 for held positions
- Include "is_unilateral": true for single-side exercises
- Add detailed notes about proper form and breathing"""
        elif workout_type == "recovery":
            workout_type_instruction = """

💆 RECOVERY WORKOUT TYPE:
This is a RECOVERY/ACTIVE REST workout. You MUST:
1. Keep intensity very low (RPE 3-4 out of 10)
2. Focus on blood flow and gentle movement
3. Include light stretching and mobility work
4. Use longer holds and slower tempos
5. Emphasize breathing and relaxation
6. NO heavy weights or intense cardio

RECOVERY EXERCISE CATEGORIES:
- Light cardio: Walking, slow cycling, easy swimming (duration_seconds: 300-600)
- Gentle stretches: All major muscle groups with 45-60 second holds
- Foam rolling: Full body self-massage (30-60 seconds per muscle group)
- Breathing exercises: Box breathing, diaphragmatic breathing (duration_seconds: 120-180)
- Yoga flow: Gentle sun salutations, restorative poses
- Light mobility: Joint circles, gentle twists, easy hip openers

STRUCTURE FOR RECOVERY:
- Start with 5-10 min light cardio (walking, easy cycling)
- Gentle full-body stretching (15-20 min)
- Foam rolling/self-massage (5-10 min)
- End with breathing and relaxation (5 min)

RECOVERY-SPECIFIC NOTES:
- This is NOT a challenging workout - it should feel restorative
- Perfect for rest days or after intense training
- Focus on areas that feel tight or sore
- Encourage slow, controlled breathing throughout"""

        # Build custom program instruction if user has specified a custom training goal
        custom_program_instruction = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_instruction = f"""

🎯 CRITICAL - CUSTOM TRAINING PROGRAM:
The user has specified a custom training goal: "{custom_program_description}"

This is the user's PRIMARY training focus. You MUST:
1. Select exercises that directly support this goal
2. Structure sets/reps/rest to match this training style
3. Include skill-specific progressions where applicable
4. Name the workout to reflect this training focus

Examples:
- "Train for HYROX" → Include sled-style pushes, farmer carries, rowing, running intervals
- "Improve box jump height" → Plyometrics, power movements, explosive leg work
- "Prepare for marathon" → Running-focused, leg endurance, core stability
- "Get better at pull-ups" → Back strengthening, lat work, grip training, assisted progressions"""

        # Build custom exercises instruction if user has custom exercises
        custom_exercises_instruction = ""
        if custom_exercises and len(custom_exercises) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(custom_exercises)} custom exercises in prompt")
            exercise_list = []
            for ex in custom_exercises:
                name = ex.get("name", "")
                muscle = ex.get("primary_muscle", "")
                equip = ex.get("equipment", "")
                sets = ex.get("default_sets", 3)
                reps = ex.get("default_reps", 10)
                exercise_list.append(f"  - {name} (targets: {muscle}, equipment: {equip}, default: {sets}x{reps})")
                logger.info(f"🏋️ [Gemini Service] Custom exercise: {name} - {muscle}/{equip}")
            custom_exercises_instruction = f"""

🏋️ USER'S CUSTOM EXERCISES:
The user has created these custom exercises. You SHOULD include 1-2 of them if they match the workout focus:
{chr(10).join(exercise_list)}

When including custom exercises, use the user's default sets/reps as a starting point."""
        else:
            logger.info(f"🏋️ [Gemini Service] No custom exercises to include in prompt")

        # Build workout environment instruction if provided
        environment_instruction = ""
        if workout_environment:
            env_descriptions = {
                'commercial_gym': ('🏢 COMMERCIAL GYM', 'Full access to machines, cables, and free weights. Can use any equipment.'),
                'home_gym': ('🏠 HOME GYM', 'Dedicated home gym setup. Focus on free weights and basic equipment available.'),
                'home': ('🏡 HOME (MINIMAL)', 'Limited equipment at home. Prefer bodyweight exercises and minimal equipment.'),
                'outdoors': ('🌳 OUTDOORS', 'Outdoor workout (park, trail). Use bodyweight exercises, running, outdoor-friendly movements.'),
                'hotel': ('🧳 HOTEL/TRAVEL', 'Hotel gym with limited equipment. Focus on bodyweight and dumbbells.'),
                'apartment_gym': ('🏬 APARTMENT GYM', 'Basic apartment building gym. Focus on machines and basic weights.'),
                'office_gym': ('💼 OFFICE GYM', 'Workplace fitness center. Use machines and basic equipment.'),
                'custom': ('⚙️ CUSTOM SETUP', 'User has specific equipment they selected. Use only the equipment listed.'),
            }
            env_name, env_desc = env_descriptions.get(workout_environment, ('', workout_environment))
            if env_name:
                environment_instruction = f"\n- Workout Environment: {env_name} - {env_desc}"

        # Build detailed equipment instruction if provided
        equipment_details_instruction = ""
        if equipment_details and len(equipment_details) > 0:
            logger.info(f"🏋️ [Gemini Service] Including {len(equipment_details)} detailed equipment items in prompt")
            equip_list = []
            for item in equipment_details:
                name = item.get("name", "unknown")
                quantity = item.get("quantity", 1)
                weights = item.get("weights", [])
                unit = item.get("weight_unit", "lbs")
                notes = item.get("notes", "")

                if weights:
                    weights_str = f", weights: {', '.join(str(w) for w in weights)} {unit}"
                else:
                    weights_str = ""

                notes_str = f" ({notes})" if notes else ""
                equip_list.append(f"  - {name}: qty {quantity}{weights_str}{notes_str}")

            equipment_details_instruction = f"""

🏋️ DETAILED EQUIPMENT AVAILABLE:
The user has specified exact equipment with quantities and weights. Use ONLY these items and recommend weights from this list:
{chr(10).join(equip_list)}

When recommending weights for exercises, select from the user's available weights listed above.
If user has multiple weight options, pick appropriate weights based on fitness level and exercise type."""

        # Build user preference constraints (avoided exercises, avoided muscles, staple exercises)
        preference_constraints_instruction = ""

        # Avoided exercises - CRITICAL constraint
        if avoided_exercises and len(avoided_exercises) > 0:
            logger.info(f"🚫 [Gemini Service] User has {len(avoided_exercises)} avoided exercises: {avoided_exercises[:5]}...")
            preference_constraints_instruction += f"""

🚫 CRITICAL - EXERCISES TO AVOID:
The user has EXPLICITLY requested to avoid these exercises. Do NOT include ANY of them:
{chr(10).join(f'  - {ex}' for ex in avoided_exercises)}

This is a HARD CONSTRAINT. If you include any of these exercises, the workout will be rejected.
Find suitable alternatives that work the same muscle groups."""

        # Avoided muscles - CRITICAL constraint
        if avoided_muscles:
            avoid_completely = avoided_muscles.get("avoid", [])
            reduce_usage = avoided_muscles.get("reduce", [])

            if avoid_completely:
                logger.info(f"🚫 [Gemini Service] User avoiding muscles: {avoid_completely}")
                preference_constraints_instruction += f"""

🚫 CRITICAL - MUSCLE GROUPS TO AVOID:
The user has requested to COMPLETELY AVOID these muscle groups (e.g., due to injury):
{chr(10).join(f'  - {muscle}' for muscle in avoid_completely)}

Do NOT include exercises that primarily target these muscles.
If the workout focus conflicts with this (e.g., "chest day" but avoiding chest), prioritize safety and adjust."""

            if reduce_usage:
                logger.info(f"⚠️ [Gemini Service] User reducing muscles: {reduce_usage}")
                preference_constraints_instruction += f"""

⚠️ MUSCLE GROUPS TO MINIMIZE:
The user prefers to minimize exercises for these muscle groups:
{chr(10).join(f'  - {muscle}' for muscle in reduce_usage)}

Include at most 1 exercise targeting these muscles, and prefer compound movements over isolation."""

        # Staple exercises - exercises user wants to ALWAYS include in every workout
        if staple_exercises and len(staple_exercises) > 0:
            staple_names = [s.get("name", s) if isinstance(s, dict) else s for s in staple_exercises]
            logger.info(f"⭐ [Gemini Service] User has {len(staple_exercises)} MANDATORY staple exercises: {staple_names}")

            preference_constraints_instruction += f"""

⭐ USER'S STAPLE EXERCISES - MANDATORY INCLUSION:
The user has marked these exercises as STAPLES. You MUST include ALL of them in EVERY workout:
{chr(10).join(f'  - {name}' for name in staple_names)}

CRITICAL: Staple exercises are NON-NEGOTIABLE. Include every staple exercise listed above, regardless of the workout's target muscle group or training split."""

        # Build comeback instruction for users returning from extended breaks
        comeback_instruction = ""
        if comeback_context and comeback_context.strip():
            logger.info(f"🔄 [Gemini Service] User is in comeback mode - applying reduced intensity instructions")
            comeback_instruction = f"""

{comeback_context}

🔄 COMEBACK WORKOUT REQUIREMENTS:
Based on the comeback context above, you MUST:
1. REDUCE the number of sets compared to normal (typically 2-3 sets max)
2. REDUCE the number of reps per set
3. INCREASE rest periods between sets
4. AVOID explosive or high-intensity movements
5. INCLUDE joint mobility exercises where appropriate
6. Focus on controlled movements and proper form
7. Keep the workout SHORTER than normal duration

This is a RETURN-TO-TRAINING workout - safety and gradual progression are CRITICAL."""

        # Build progression philosophy instruction for leverage-based progressions
        progression_philosophy_instruction = ""
        if progression_philosophy and progression_philosophy.strip():
            logger.info(f"[Gemini Service] Including progression philosophy context for leverage-based progressions")
            progression_philosophy_instruction = progression_philosophy

        # Build workout patterns context with historical data and set/rep limits
        workout_patterns_instruction = ""
        if workout_patterns_context and workout_patterns_context.strip():
            logger.info(f"[Gemini Service] Including workout patterns context with set/rep limits and historical data")
            workout_patterns_instruction = workout_patterns_context

        # Build favorite workouts context for inspiration
        favorite_workouts_instruction = ""
        if favorite_workouts_context and favorite_workouts_context.strip():
            logger.info(f"[Gemini Service] Including favorite workouts context for personalized generation")
            favorite_workouts_instruction = "\n\n" + favorite_workouts_context

        # Build set type context with user's historical preferences for advanced set types
        set_type_context_str = ""
        if set_type_context and set_type_context.strip():
            logger.info(f"[Gemini Service] Including set type context for personalized drop/failure set recommendations")
            set_type_context_str = set_type_context

        # Build primary training goal instruction (hypertrophy vs strength vs both)
        primary_goal_instruction = ""
        if primary_goal:
            logger.info(f"🎯 [Gemini Service] User has primary training goal: {primary_goal}")
            goal_mappings = {
                'muscle_hypertrophy': """
🎯 PRIMARY TRAINING FOCUS: MUSCLE HYPERTROPHY (Muscle Size)
The user's primary goal is to BUILD MUSCLE SIZE. You MUST:
- Use moderate weights with higher rep ranges (8-12 reps for compounds, 12-15 for isolation)
- Focus on time under tension - slower eccentric (3-4 seconds)
- Include more isolation exercises to target individual muscles
- Moderate rest periods (60-90 seconds)
- Include techniques like drop sets for advanced users
- RPE typically 7-9 (leave 1-3 reps in reserve)""",
                'muscle_strength': """
🎯 PRIMARY TRAINING FOCUS: MUSCLE STRENGTH (Maximal Strength)
The user's primary goal is to GET STRONGER. You MUST:
- Use heavier weights with lower rep ranges (3-6 reps for compounds, 6-8 for accessory)
- Prioritize compound movements (squat, deadlift, bench, overhead press)
- Longer rest periods (2-4 minutes) for full recovery between heavy sets
- Focus on progressive overload with weight increases
- Fewer total exercises but more sets (4-5 sets per movement)
- RPE typically 8-10 (close to or at failure on heavy sets)""",
                'strength_hypertrophy': """
🎯 PRIMARY TRAINING FOCUS: STRENGTH & HYPERTROPHY (Balanced)
The user wants BOTH strength AND muscle size. You MUST:
- Vary rep ranges within the workout (6-10 reps most common)
- Start with heavy compound movements (5-6 reps, strength focus)
- Finish with moderate isolation work (10-12 reps, hypertrophy focus)
- Moderate rest periods (90-120 seconds)
- Mix of compound and isolation exercises
- Include both strength techniques (heavy singles/doubles) and hypertrophy techniques (drop sets)
- RPE varies: 8-9 for compounds, 7-8 for isolation""",
            }
            primary_goal_instruction = goal_mappings.get(primary_goal, "")

        # Build muscle focus points instruction (priority muscles)
        muscle_focus_instruction = ""
        if muscle_focus_points and len(muscle_focus_points) > 0:
            total_points = sum(muscle_focus_points.values())
            logger.info(f"🏋️ [Gemini Service] User has {total_points} muscle focus points allocated: {muscle_focus_points}")
            # Sort by points descending
            sorted_muscles = sorted(muscle_focus_points.items(), key=lambda x: x[1], reverse=True)
            muscle_list = "\n".join([f"  - {muscle.replace('_', ' ').title()}: {points} point{'s' if points > 1 else ''}" for muscle, points in sorted_muscles])
            muscle_focus_instruction = f"""

🏋️ MUSCLE PRIORITY - USER HAS ALLOCATED FOCUS POINTS:
The user wants EXTRA emphasis on these specific muscle groups:
{muscle_list}

REQUIREMENTS:
- Include at least ONE exercise specifically targeting each high-priority muscle (2+ points)
- For muscles with 3+ points, include TWO exercises targeting that muscle
- Place priority muscle exercises earlier in the workout (when energy is highest)
- Use slightly higher volume (extra set) for priority muscles
- These preferences should COMPLEMENT the workout focus, not replace it"""

        # Build focus area instruction based on the training split/focus
        focus_instruction = ""
        if focus_areas and len(focus_areas) > 0:
            focus = focus_areas[0].lower()
            logger.info(f"🎯 [Gemini Service] Workout focus area: {focus}")
            # Map focus areas to strict exercise selection guidelines
            focus_mapping = {
                'push': '🎯 PUSH FOCUS: Select exercises that target chest, shoulders, and triceps. Include bench press variations, shoulder press, push-ups, dips, tricep extensions.',
                'pull': '🎯 PULL FOCUS: Select exercises that target back and biceps. Include rows, pull-ups/lat pulldowns, deadlifts, curls, face pulls.',
                'legs': '🎯 LEG FOCUS: Select exercises that target quads, hamstrings, glutes, and calves. Include squats, lunges, leg press, deadlifts, calf raises.',
                'upper': '🎯 UPPER BODY: Select exercises for chest, back, shoulders, and arms. Mix pushing and pulling movements.',
                'lower': '🎯 LOWER BODY: Select exercises for quads, hamstrings, glutes, and calves. Focus on compound leg movements.',
                'chest': '🎯 CHEST FOCUS: At least 70% of exercises must target chest. Include bench press, flyes, push-ups, cable crossovers.',
                'back': '🎯 BACK FOCUS: At least 70% of exercises must target back. Include rows, pull-ups, lat pulldowns, deadlifts.',
                'shoulders': '🎯 SHOULDER FOCUS: At least 70% of exercises must target shoulders. Include overhead press, lateral raises, front raises, rear delts.',
                'arms': '🎯 ARMS FOCUS: At least 70% of exercises must target biceps and triceps. Include curls, extensions, dips, hammer curls.',
                'core': '🎯 CORE FOCUS: At least 70% of exercises must target abs and obliques. Include planks, crunches, leg raises, russian twists.',
                'glutes': '🎯 GLUTE FOCUS: At least 70% of exercises must target glutes. Include hip thrusts, glute bridges, lunges, deadlifts.',
                'full_body': '🎯 FULL BODY: Include at least one exercise for each major muscle group: chest, back, shoulders, legs, core.',
                'full_body_push': '🎯 FULL BODY with PUSH EMPHASIS: Include exercises for all major muscle groups, but prioritize chest, shoulders, and triceps (at least 50% pushing movements).',
                'full_body_pull': '🎯 FULL BODY with PULL EMPHASIS: Include exercises for all major muscle groups, but prioritize back and biceps (at least 50% pulling movements).',
                'full_body_legs': '🎯 FULL BODY with LEG EMPHASIS: Include exercises for all major muscle groups, but prioritize legs and glutes (at least 50% lower body movements).',
                'full_body_core': '🎯 FULL BODY with CORE EMPHASIS: Include exercises for all major muscle groups, but prioritize core/abs (at least 40% core movements).',
                'full_body_upper': '🎯 FULL BODY with UPPER EMPHASIS: Include exercises for all major muscle groups, but prioritize upper body (at least 60% upper body movements).',
                'full_body_lower': '🎯 FULL BODY with LOWER EMPHASIS: Include exercises for all major muscle groups, but prioritize lower body (at least 60% lower body movements).',
                'full_body_power': '🎯 FULL BODY POWER: Focus on explosive, compound movements across all muscle groups. Include power cleans, box jumps, kettlebell swings.',
                'upper_power': '🎯 UPPER BODY POWER: Heavy compound upper body movements. Lower reps (4-6), higher weight. Include bench press, overhead press, rows.',
                'lower_power': '🎯 LOWER BODY POWER: Heavy compound leg movements. Lower reps (4-6), higher weight. Include squats, deadlifts, leg press.',
                'upper_hypertrophy': '🎯 UPPER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for chest, back, shoulders, arms.',
                'lower_hypertrophy': '🎯 LOWER BODY HYPERTROPHY: Moderate weight, higher reps (8-12). Focus on time under tension for quads, hamstrings, glutes.',
            }
            focus_instruction = focus_mapping.get(focus, f'🎯 FOCUS: {focus.upper()} - Select exercises primarily targeting this area.')

        # Build duration text - use range if both min and max provided
        if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
            duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
        else:
            duration_text = str(duration_minutes)

        # Build training split context with scientific rationale
        training_split_instruction = ""
        if training_split:
            split_context = get_split_context(training_split)
            training_split_instruction = f"""

📊 TRAINING SPLIT CONTEXT (Research-Backed):
{split_context}

Use this split information to guide exercise selection and workout structure."""

        # Build fitness assessment instruction for smarter workout personalization
        fitness_assessment_instruction = ""
        assessment_fields = []
        if pushup_capacity:
            assessment_fields.append(f"Push-ups: {pushup_capacity}")
        if pullup_capacity:
            assessment_fields.append(f"Pull-ups: {pullup_capacity}")
        if plank_capacity:
            assessment_fields.append(f"Plank hold: {plank_capacity}")
        if squat_capacity:
            assessment_fields.append(f"Bodyweight squats: {squat_capacity}")
        if cardio_capacity:
            assessment_fields.append(f"Cardio endurance: {cardio_capacity}")

        if assessment_fields:
            logger.info(f"💪 [Gemini Service] Including fitness assessment data: {assessment_fields}")
            fitness_assessment_instruction = f"""

💪 USER FITNESS ASSESSMENT (Use for Personalization):
The user completed a fitness assessment with the following results:
{chr(10).join(f'  - {field}' for field in assessment_fields)}

CRITICAL - USE THIS DATA TO PERSONALIZE THE WORKOUT:
1. SET APPROPRIATE REP RANGES:
   - User with 1-10 push-ups → prescribe 6-8 reps for pressing exercises
   - User with 11-25 push-ups → prescribe 8-12 reps for pressing exercises
   - User with 26-40+ push-ups → prescribe 10-15 reps for pressing exercises

2. CHOOSE EXERCISE DIFFICULTY:
   - User with 'none' or 'assisted' pull-ups → use lat pulldowns, assisted pull-ups, band-assisted variations
   - User with 1-5 pull-ups → include 1-2 pull-up sets with low reps, supplement with rows
   - User with 6+ pull-ups → include weighted pull-ups or higher volume

3. SCALE CORE EXERCISES:
   - User with <15sec or 15-30sec plank → shorter hold times (15-20 sec), include easier core variations
   - User with 31-60sec plank → moderate holds (30-45 sec), standard core exercises
   - User with 1-2min+ plank → longer holds (45-60+ sec), advanced core variations

4. ADJUST LEG EXERCISES:
   - User with 0-10 squats → lighter loads, focus on form, maybe assisted squats
   - User with 11-25 squats → moderate loads and volume
   - User with 26-40+ squats → higher volume, heavier loads, advanced variations

5. SET REST PERIODS:
   - Lower capacity users → longer rest periods (90-120 sec)
   - Higher capacity users → standard rest periods (60-90 sec)

6. CARDIO COMPONENTS:
   - <5min cardio capacity → very short cardio bursts (30-60 sec), more rest
   - 5-15min → moderate cardio intervals (1-2 min work periods)
   - 15-30min+ → longer cardio segments if workout type requires it

This assessment data reflects the user's ACTUAL capabilities - use it to create a workout that challenges them appropriately without being too easy or impossibly hard."""

        prompt = f"""Generate a {duration_text}-minute workout plan for a user with:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(goals, 'General fitness')}
- Available Equipment: {safe_join_list(equipment, 'Bodyweight only')}
- Focus Areas: {safe_join_list(focus_areas, 'Full body')}
- Workout Type: {workout_type}{environment_instruction}{age_activity_context}{training_split_instruction}{fitness_assessment_instruction}{safety_instruction}{workout_type_instruction}{custom_program_instruction}{custom_exercises_instruction}{equipment_details_instruction}{preference_constraints_instruction}{comeback_instruction}{progression_philosophy_instruction}{workout_patterns_instruction}{favorite_workouts_instruction}{primary_goal_instruction}{muscle_focus_instruction}

⚠️ CRITICAL - MUSCLE GROUP TARGETING:
{focus_instruction if focus_instruction else 'Select a balanced mix of exercises.'}
You MUST follow this focus area strictly. Do NOT give random exercises that don't match the focus.
EXAMPLE: If focus is LEGS, you MUST include squats, lunges, leg press - NOT push-ups or bench press!
If focus is PUSH, include chest/shoulder/tricep exercises - NOT squats or rows!
{senior_critical_instruction}

Return a valid JSON object with this exact structure:
{{
  "name": "A CREATIVE, UNIQUE workout name ENDING with body part focus (e.g., 'Thunder Legs', 'Phoenix Chest', 'Cobra Back')",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "duration_minutes_min": {duration_minutes_min or 'null'},
  "duration_minutes_max": {duration_minutes_max or 'null'},
  "estimated_duration_minutes": null,
  "target_muscles": ["Primary muscle 1", "Primary muscle 2"],
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": 12,
      "weight_kg": 10,
      "rest_seconds": 60,
      "duration_seconds": null,
      "hold_seconds": null,
      "equipment": "equipment used or bodyweight",
      "muscle_group": "primary muscle targeted",
      "is_unilateral": false,
      "is_drop_set": false,
      "is_failure_set": false,
      "drop_set_count": null,
      "drop_set_percentage": null,
      "notes": "Form tips or modifications",
      "set_targets": [
        {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 5, "target_rpe": 5, "target_rir": null}},
        {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 10, "target_rpe": 7, "target_rir": 3}},
        {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 10, "target_rpe": 8, "target_rir": 2}},
        {{"set_number": 4, "set_type": "failure", "target_reps": 8, "target_weight_kg": 10, "target_rpe": 10, "target_rir": 0}}
      ]
    }}
  ],
  "notes": "Overall workout tips including warm-up and cool-down recommendations"
}}

⏱️ ESTIMATED DURATION CALCULATION (CRITICAL):
After generating the workout, you MUST calculate the actual estimated duration and set "estimated_duration_minutes".
Calculate it as: SUM of (each exercise's sets × (reps × 3 seconds + rest_seconds)) / 60
Include time for transitions between exercises (add ~30 seconds per exercise).
Round to nearest integer.

🚨 DURATION CONSTRAINT (MANDATORY):
- If duration_minutes_max is provided, the calculated estimated_duration_minutes MUST be ≤ duration_minutes_max
- If duration_minutes_min is provided, aim for estimated_duration_minutes to be ≥ duration_minutes_min
- If range is 30-45 min, aim for 35-42 min (comfortably within range)
- Adjust number of exercises or sets to fit within the time constraint
- NEVER exceed the maximum duration - users have limited time!

Example calculation for 4 exercises:
- Exercise 1: 4 sets × (10 reps × 3s + 60s rest) = 4 × 90s = 360s
- Exercise 2: 3 sets × (12 reps × 3s + 60s rest) = 3 × 96s = 288s
- Exercise 3: 3 sets × (8 reps × 3s + 90s rest) = 3 × 114s = 342s
- Exercise 4: 3 sets × (12 reps × 3s + 45s rest) = 3 × 81s = 243s
- Transitions: 4 exercises × 30s = 120s
- Total: (360 + 288 + 342 + 243 + 120) / 60 = 22.55 ≈ 23 minutes
Set "estimated_duration_minutes": 23

🚨🚨🚨 SET TARGETS - ABSOLUTELY REQUIRED (DO NOT SKIP) 🚨🚨🚨
This is the MOST IMPORTANT field in the entire response!
For EVERY exercise without exception, you MUST include a "set_targets" array.
NEVER leave set_targets empty or null - the app will break without it!

Each set_targets entry must include:
- set_number: 1-indexed set number
- set_type: One of "warmup", "working", "drop", "failure", "amrap"
- target_reps: Specific rep target for this set
- target_weight_kg: Specific weight target for this set (reduces for drop sets)
- target_rpe: Target Rate of Perceived Exertion (1-10, where 10 is max effort)
- target_rir: Target Reps in Reserve (0-5, where 0 means failure)

SET TYPE GUIDELINES:
- Include 1 warmup set at 50% weight for compound exercises
- Working sets should increase RPE progressively (7, 8, 9)
- Drop sets: Each drop reduces weight by 20-25% with same reps
- Failure/AMRAP sets: RPE 10, RIR 0

EXAMPLE for a 4-set exercise with 2 drop sets:
"set_targets": [
  {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 20, "target_rpe": 5, "target_rir": null}},
  {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 40, "target_rpe": 8, "target_rir": 2}},
  {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 40, "target_rpe": 9, "target_rir": 1}},
  {{"set_number": 4, "set_type": "drop", "target_reps": 10, "target_weight_kg": 30, "target_rpe": 9, "target_rir": 1}},
  {{"set_number": 5, "set_type": "drop", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 10, "target_rir": 0}}
]

NOTE: For cardio exercises, use duration_seconds (e.g., 30) instead of reps (set reps to 1).
For strength exercises, set duration_seconds to null and use reps normally.
For mobility/stretching exercises, use hold_seconds (e.g., 30-60) for static holds instead of reps.
For unilateral exercises (single-arm, single-leg), set is_unilateral: true.

For ISOMETRIC/TIME-BASED exercises (planks, wall sits, dead hangs, L-sits, hollow holds, static holds):
- Set hold_seconds to the BASE time (e.g., 30)
- Use target_hold_seconds in set_targets for PROGRESSIVE hold times per set
- Set reps to 1 for each set (since it's time-based, not rep-based)

EXAMPLE for progressive plank (15s -> 30s -> 45s):
{{
  "name": "Forearm Plank",
  "sets": 3,
  "reps": 1,
  "hold_seconds": 30,
  "rest_seconds": 60,
  "set_targets": [
    {{"set_number": 1, "set_type": "warmup", "target_reps": 1, "target_hold_seconds": 15}},
    {{"set_number": 2, "set_type": "working", "target_reps": 1, "target_hold_seconds": 30}},
    {{"set_number": 3, "set_type": "working", "target_reps": 1, "target_hold_seconds": 45}}
  ]
}}
{set_type_context_str}
🚨🚨🚨 MANDATORY ADVANCED TECHNIQUES (NON-NEGOTIABLE FOR NON-BEGINNERS) 🚨🚨🚨

FOR INTERMEDIATE FITNESS LEVEL - YOU MUST INCLUDE:
- At least 1 exercise with is_failure_set: true (final isolation exercise)
- The failure set exercise MUST have notes containing "AMRAP" or "to failure"

FOR ADVANCED FITNESS LEVEL - YOU MUST INCLUDE:
- At least 2 exercises with is_failure_set: true
- At least 1 exercise with is_drop_set: true (on an isolation exercise)
- When is_drop_set: true, ALSO set drop_set_count: 2 and drop_set_percentage: 20

FOR BEGINNER FITNESS LEVEL:
- NO failure sets (is_failure_set: false for all)
- NO drop sets (is_drop_set: false for all)

FAILURE SET RULES (is_failure_set: true):
- Apply to the LAST isolation exercise in the workout
- Set notes to include "AMRAP" or "Final set to failure"
- Example exercises: Bicep Curl, Lateral Raise, Tricep Extension, Leg Curl

DROP SET RULES (is_drop_set: true):
- Apply to isolation exercises ONLY (never compounds)
- MUST also set: drop_set_count: 2, drop_set_percentage: 20
- Set notes to include "Drop set: reduce weight 20% twice"

EXAMPLE INTERMEDIATE WORKOUT (notice failure set on last exercise):
Exercise 5: {{"name": "Bicep Curl", "sets": 3, "reps": 12, "is_failure_set": true, "is_drop_set": false, "notes": "Final set: AMRAP"}}

EXAMPLE ADVANCED WORKOUT (notice both failure AND drop set):
Exercise 6: {{"name": "Lateral Raise", "sets": 3, "reps": 15, "is_failure_set": true, "is_drop_set": true, "drop_set_count": 2, "drop_set_percentage": 20, "notes": "AMRAP then drop 20% twice"}}

⚠️ CRITICAL - REALISTIC WEIGHT RECOMMENDATIONS:
For each exercise, include a starting weight_kg that follows industry-standard equipment increments:
- Dumbbell exercises: Use weights in 2.5kg (5lb) increments (2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20...)
- Barbell exercises: Use weights in 2.5kg (5lb) increments
- Machine exercises: Use weights in 5kg (10lb) increments (5, 10, 15, 20, 25...)
- Kettlebell exercises: Use weights in 4kg (8lb) increments (4, 8, 12, 16, 20, 24...)
- Bodyweight exercises: Use weight_kg: 0

Starting weight guidelines by fitness level:
- Beginner: Compound exercises 5-10kg, Isolation exercises 2.5-5kg
- Intermediate: Compound exercises 15-25kg, Isolation exercises 7.5-12.5kg
- Advanced: Compound exercises 30-50kg, Isolation exercises 15-20kg

NEVER recommend unrealistic increments like 2.5 lbs for dumbbells - the minimum is 5 lbs (2.5 kg)!

🏋️ PERIODIZATION - VARY SETS/REPS BY EXERCISE TYPE (MANDATORY):

❌ DO NOT use 3x10 for every exercise! This is lazy and ineffective programming.

COMPOUND EXERCISES (Squat, Deadlift, Bench Press, Row, Overhead Press, Pull-Up):
- Sets: 4-5
- Reps: 5-8 (heavier weight, lower reps for strength)
- Example: Barbell Squat 4x6, Bench Press 5x5, Deadlift 4x5

ISOLATION EXERCISES (Curls, Extensions, Raises, Flyes, Kickbacks):
- Sets: 3
- Reps: 12-15 (lighter weight, higher reps for hypertrophy)
- Example: Bicep Curl 3x12, Lateral Raise 3x15, Tricep Extension 3x15

MACHINE/CABLE EXERCISES:
- Sets: 3-4
- Reps: 10-12
- Example: Leg Press 3x12, Cable Fly 3x12, Lat Pulldown 4x10

BODYWEIGHT EXERCISES:
- Beginner: 3x8-10 (or to near failure)
- Intermediate: 3x12-15
- Advanced: 4x15+ or add weight

SMALL MUSCLE GROUPS (Calves, Forearms, Rear Delts):
- Sets: 3-4
- Reps: 15-20 (higher reps for endurance muscles)
- Example: Calf Raise 4x20, Wrist Curl 3x15

⚠️ REST TIME VARIATION (VARY BY EXERCISE):
- Compound Heavy (Squat, Deadlift, Bench): rest_seconds: 120-180
- Compound Moderate (Row, Lunge, Press): rest_seconds: 90-120
- Isolation (Curls, Extensions, Raises): rest_seconds: 60-90
- Bodyweight/Machine: rest_seconds: 60-75

EXAMPLE GOOD LEG WORKOUT (VARIED SETS/REPS):
1. Barbell Squat: 4x6, rest: 150s (compound - low reps, long rest)
2. Romanian Deadlift: 4x8, rest: 120s (compound - moderate)
3. Leg Press: 3x12, rest: 90s (machine - higher reps)
4. Leg Curl: 3x15, rest: 60s (isolation - high reps, short rest)
5. Calf Raise: 4x20, rest: 45s (small muscle - endurance)

EXAMPLE BAD WORKOUT (REJECTED - DO NOT DO THIS):
❌ Squat 3x10, RDL 3x10, Leg Press 3x10, Leg Curl 3x10, Calf Raise 3x10 (all same!)

🎯 WORKOUT NAME - BE EXTREMELY CREATIVE:
Create a name that makes users PUMPED to work out! Use diverse vocabulary:

ACTION WORDS (pick creatively):
- Power: Blitz, Surge, Blast, Strike, Rush, Bolt, Flash, Charge, Jolt, Spark
- Intensity: Inferno, Blaze, Scorch, Burn, Fire, Flame, Heat, Ember, Torch, Ignite
- Nature: Storm, Thunder, Lightning, Hurricane, Tornado, Avalanche, Earthquake, Tsunami, Cyclone, Tempest
- Force: Crush, Smash, Shatter, Break, Demolish, Destroy, Wreck, Obliterate, Annihilate, Pulverize
- Speed: Sprint, Dash, Zoom, Rocket, Jet, Turbo, Hyper, Sonic, Rapid, Swift
- Combat: Warrior, Gladiator, Viking, Spartan, Samurai, Ninja, Knight, Conqueror, Champion, Fighter
- Animal: Wolf, Lion, Tiger, Bear, Hawk, Eagle, Dragon, Phoenix, Panther, Cobra
- Mythic: Titan, Atlas, Zeus, Thor, Hercules, Apollo, Odin, Valkyrie, Olympus, Valhalla

⚠️ CRITICAL NAMING RULES:
1. Name MUST be 3-4 words
2. Name MUST end with the body part/muscle focus
3. Be creative and motivating!

EXAMPLES OF GOOD 3-4 WORD NAMES:
- "Savage Wolf Legs" ✓ (3 words, ends with body part)
- "Iron Phoenix Chest" ✓ (3 words, ends with body part)
- "Thunder Strike Back" ✓ (3 words, ends with body part)
- "Mighty Storm Core" ✓ (3 words, ends with body part)
- "Ultimate Power Shoulders" ✓ (3 words, ends with body part)
- "Blazing Beast Glutes" ✓ (3 words, ends with body part)

BAD EXAMPLES:
- "Thunder Legs" ✗ (only 2 words!)
- "Blitz Panther Pounce" ✗ (no body part!)
- "Wolf" ✗ (too short, no body part!)

BODY PARTS TO END WITH:
- Upper: Chest, Back, Shoulders, Arms, Biceps, Triceps
- Core: Core, Abs, Obliques
- Lower: Legs, Quads, Glutes, Hamstrings, Calves
- Full: Full Body, Total Body

FORMAT: [Adjective/Action] + [Animal/Mythic/Theme] + [Body Part]
- "Raging Bull Legs", "Silent Ninja Back", "Golden Phoenix Chest"
- "Explosive Tiger Core", "Relentless Warrior Arms", "Primal Beast Shoulders"
{holiday_instruction}{avoid_instruction}

Requirements:
- MUST include AT LEAST 5 exercises (minimum 5, ideally 6-8) appropriate for {fitness_level} fitness level
- EVERY exercise MUST match the focus area - do NOT include exercises for other muscle groups!
- ONLY use equipment from this list: {safe_join_list(equipment, 'bodyweight')}

🚨🚨🚨 ABSOLUTE CRITICAL RULE - EQUIPMENT USAGE 🚨🚨🚨
Available equipment: {safe_join_list(equipment, 'bodyweight only')}

IF THE USER HAS GYM EQUIPMENT, YOU **MUST** USE IT! This is NON-NEGOTIABLE.
- If "full_gym" OR "dumbbells" OR "barbell" OR "cable_machine" OR "machines" is in the equipment list:
  → AT LEAST 4-5 exercises (out of 6-8 total) MUST use that equipment
  → Maximum 1-2 bodyweight exercises allowed
  → NEVER generate a mostly bodyweight workout when gym equipment is available!

MANDATORY EQUIPMENT-BASED EXERCISES (include these when equipment is available):
- full_gym/commercial_gym: Barbell Squat, Bench Press, Lat Pulldown, Cable Row, Leg Press, Dumbbell Rows
- dumbbells: Dumbbell Bench Press, Dumbbell Rows, Dumbbell Lunges, Dumbbell Shoulder Press, Goblet Squats, Dumbbell Curls
- barbell: Barbell Squat, Deadlift, Bench Press, Barbell Row, Overhead Press
- cable_machine: Cable Fly, Face Pull, Tricep Pushdown, Cable Row, Lat Pulldown
- machines: Leg Press, Chest Press Machine, Lat Pulldown, Leg Curl, Shoulder Press Machine
- kettlebell/kettlebells: Kettlebell Swings, Goblet Squats, KB Clean & Press, KB Turkish Get-up, KB Deadlift, KB Snatch

🔔 KETTLEBELL RULE: If "kettlebell" or "kettlebells" is in the equipment list:
- Include AT LEAST 1 kettlebell exercise in every workout!
- Kettlebells are excellent for: full body power, core stability, conditioning
- Don't ignore this equipment - users specifically added it!

FOR BEGINNERS WITH GYM ACCESS - THIS IS CRITICAL:
Beginners benefit MORE from weighted exercises than bodyweight! Use machines and dumbbells for:
- Better muscle activation with controlled resistance
- Easier to maintain proper form than advanced calisthenics
- Measurable progressive overload
EXAMPLE BEGINNER GYM WORKOUT (LEGS): Leg Press, Goblet Squat, Dumbbell Romanian Deadlift, Leg Extension Machine, Lying Leg Curl, Calf Raises on Machine
EXAMPLE BEGINNER GYM WORKOUT (PUSH): Dumbbell Bench Press, Machine Shoulder Press, Cable Fly, Dumbbell Lateral Raise, Tricep Pushdown
NOT: Push-ups, Planks, Bodyweight Squats (these are for home/no-equipment only!)

⚠️ CRITICAL FOR BEGINNERS: Do NOT include advanced/elite calisthenics movements like planche push-ups, front levers, muscle-ups, handstand push-ups, one-arm pull-ups, pistol squats, human flags, or L-sits. These require YEARS of training.

- For intermediate: balanced challenge, mix of compound and isolation movements
- For advanced: higher intensity, complex movements, advanced techniques, less rest
- For HELL difficulty: MAXIMUM intensity! Supersets, drop sets, minimal rest (30-45s), heavy weights, near-failure reps. This should be the hardest workout possible. Include at least 7-8 exercises with 4-5 sets each.
- Align exercise selection with goals: {', '.join(goals) if goals else 'general fitness'}

🚨 CRITICAL EXERCISE VARIETY RULES - MUST FOLLOW:
- Each exercise MUST be a DIFFERENT movement pattern
- NEVER include multiple variations of the same exercise type:
  * NO: 2+ push-up variations (push-ups, diamond push-ups, decline push-ups, explosive push-ups)
  * NO: 2+ curl variations (bicep curls, hammer curls, preacher curls)
  * NO: 2+ squat variations (goblet squats, front squats, back squats, jump squats)
  * NO: 2+ row variations (bent-over rows, cable rows, dumbbell rows)
- Instead, vary movement patterns across the workout:
  * Horizontal push (bench press, push-ups, fly)
  * Vertical push (overhead press, lateral raise)
  * Horizontal pull (rows)
  * Vertical pull (pull-ups, pulldowns)
  * Squat pattern (squats)
  * Hinge pattern (deadlifts, RDLs)
  * Lunge pattern (lunges, step-ups)
  * Core work
- Example GOOD chest workout: Bench Press, Cable Fly, Dips, Incline Dumbbell Press, Push-ups (only 1 push-up), Face Pulls
- Example BAD chest workout: Push-ups, Diamond Push-ups, Decline Push-ups, Wide Push-ups, Explosive Push-ups (REJECTED - all same pattern!)

- Each exercise should have helpful form notes

🚨 FINAL VALIDATION CHECKLIST (You MUST verify before responding):
1. ✅ Focus area check: ALL exercises match the focus area (legs/push/pull/etc.)
2. ✅ Equipment check: If gym equipment available, AT LEAST 4-5 exercises use weights/machines
3. ✅ Beginner check: If beginner + gym, mostly machine/dumbbell exercises (NOT bodyweight)
4. ✅ No advanced calisthenics for beginners
5. ✅ VARIETY CHECK: No more than 2 exercises per movement pattern (no 3+ push-ups, no 3+ curls)
6. ✅ PERIODIZATION CHECK: Sets/reps MUST vary by exercise type (NOT all 3x10!)
7. ✅ REST TIME CHECK: Rest times MUST vary (compounds: 120-180s, isolation: 60-90s)
8. ✅ ADVANCED TECHNIQUES (MANDATORY for intermediate/advanced):
   - INTERMEDIATE: Last exercise MUST have is_failure_set: true, notes: "AMRAP"
   - ADVANCED: 2 exercises with is_failure_set: true, 1 with is_drop_set: true
   - BEGINNER: ALL exercises have is_failure_set: false, is_drop_set: false

If focus is "legs" - every exercise should target quads, hamstrings, glutes, or calves.
If focus is "push" - every exercise should target chest, shoulders, or triceps.
If focus is "pull" - every exercise should target back or biceps.
If user has gym equipment - most exercises MUST use that equipment!"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_plan]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, equipment={equipment}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Age: {age}, Activity level: {activity_level}")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        response_mime_type="application/json",
                        response_schema=GeneratedWorkoutResponse,
                        temperature=0.7,  # Higher creativity for unique workout names
                        max_output_tokens=8000  # Increased for detailed workout plans with set_targets
                    ),
                ),
                timeout=90,  # 90s for full workout generation (large prompt + response)
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            parsed = response.parsed
            if not parsed:
                # Debug: log raw response details
                logger.error(f"[DEBUG] response.parsed is None!")
                logger.error(f"[DEBUG] response.text exists: {bool(response.text)}")
                if response.text:
                    logger.error(f"[DEBUG] response.text (first 500): {response.text[:500]}")
                if hasattr(response, 'candidates') and response.candidates:
                    for i, cand in enumerate(response.candidates):
                        logger.error(f"[DEBUG] candidate {i} finish_reason: {cand.finish_reason}")
                raise ValueError("Gemini returned empty workout response")

            # Handle case where parsed may be a Pydantic model or raw data
            if hasattr(parsed, 'model_dump'):
                workout_data = parsed.model_dump()
            elif isinstance(parsed, dict):
                workout_data = parsed
            elif isinstance(parsed, str):
                # SDK sometimes returns raw string instead of parsed model
                try:
                    workout_data = json.loads(parsed)
                except (json.JSONDecodeError, ValueError):
                    raise ValueError(f"Gemini returned unparseable string response: {parsed[:200]}")
            else:
                raise ValueError(f"Unexpected parsed type from Gemini: {type(parsed).__name__}")

            if not isinstance(workout_data, dict):
                raise ValueError(f"workout_data is not a dict after parsing: type={type(workout_data).__name__}")

            # Validate required fields
            if "exercises" not in workout_data or not workout_data["exercises"]:
                raise ValueError("AI response missing exercises")

            # CRITICAL: Validate set_targets - FAIL if missing (no fallback)
            user_context = {
                "fitness_level": fitness_level,
                "difficulty": intensity_preference or "medium",
                "goals": goals,
                "equipment": equipment,
                "generation_source": "gemini_generate_workout_plan",
            }
            workout_data["exercises"] = validate_set_targets_strict(workout_data["exercises"], user_context)

            return workout_data

        except Exception as e:
            print(f"Workout generation failed: {e}")
            raise

    async def generate_workout_plan_streaming(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_prompt_override: Optional[str] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[str]] = None,
        progression_philosophy: Optional[str] = None,
        exercise_count: int = 6,
        # Coach personality parameters for personalized workout naming
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        scheduled_date: Optional[str] = None,
    ):
        """
        Generate a workout plan using streaming for faster perceived response.

        Yields chunks of JSON as they're generated, allowing the client to
        display exercises incrementally.

        Args:
            custom_prompt_override: If provided, use this prompt instead of
                                    building the default workout prompt.
            progression_philosophy: Optional progression philosophy prompt for leverage-based progressions.

        Yields:
            str: JSON chunks as they arrive from Gemini
        """
        # If custom prompt provided, use it directly
        if custom_prompt_override:
            prompt = custom_prompt_override
            logger.info(f"[Streaming] Using custom prompt override for {fitness_level} user")
        else:
            # Use intensity_preference if provided, otherwise derive from fitness_level
            if intensity_preference:
                difficulty = intensity_preference
            else:
                difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

            avoid_instruction = ""
            if avoid_name_words and len(avoid_name_words) > 0:
                avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words)}"

            holiday_theme = self._get_holiday_theme(workout_date)
            holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

            # Import senior-specific prompt additions
            from services.adaptive_workout_service import get_senior_workout_prompt_additions

            age_activity_context = ""
            senior_instruction = ""  # For seniors 60+, this adds critical limits
            if age:
                if age < 30:
                    age_activity_context += f"\n- Age: {age} (young adult, max 25 reps)"
                elif age < 45:
                    age_activity_context += f"\n- Age: {age} (adult, max 20 reps)"
                elif age < 60:
                    age_activity_context += f"\n- Age: {age} (middle-aged - joint-friendly, max 16 reps)"
                else:
                    # Senior users (60+) - get detailed safety instructions
                    senior_prompt_data = get_senior_workout_prompt_additions(age)
                    if senior_prompt_data:
                        age_activity_context += f"\n- Age: {age} ({senior_prompt_data['age_bracket']} - REDUCED INTENSITY)"
                        senior_instruction = f"\n\n🧓 SENIOR SAFETY (age {age}): Max {senior_prompt_data['max_reps']} reps, Max {senior_prompt_data['max_sets']} sets, {senior_prompt_data['extra_rest_percent']}% more rest. AVOID high-impact/explosive moves."
                    else:
                        age_activity_context += f"\n- Age: {age} (senior - low-impact, max 12 reps)"

            if activity_level:
                activity_descriptions = {
                    'sedentary': 'sedentary (start slow)',
                    'lightly_active': 'lightly active (moderate intensity)',
                    'moderately_active': 'moderately active (challenging workouts)',
                    'very_active': 'very active (high intensity)'
                }
                activity_desc = activity_descriptions.get(activity_level, activity_level)
                age_activity_context += f"\n- Activity Level: {activity_desc}"

            # Build preference constraints for streaming
            preference_constraints = ""

            if avoided_exercises and len(avoided_exercises) > 0:
                logger.info(f"🚫 [Streaming] User has {len(avoided_exercises)} avoided exercises")
                preference_constraints += f"\n\n🚫 EXERCISES TO AVOID (CRITICAL - DO NOT INCLUDE): {', '.join(avoided_exercises[:10])}"

            if avoided_muscles:
                avoid_completely = avoided_muscles.get("avoid", [])
                reduce_usage = avoided_muscles.get("reduce", [])
                if avoid_completely:
                    logger.info(f"🚫 [Streaming] User avoiding muscles: {avoid_completely}")
                    preference_constraints += f"\n🚫 MUSCLES TO AVOID (injury/preference): {', '.join(avoid_completely)}"
                if reduce_usage:
                    preference_constraints += f"\n⚠️ MUSCLES TO MINIMIZE: {', '.join(reduce_usage)}"

            if staple_exercises and len(staple_exercises) > 0:
                logger.info(f"⭐ [Streaming] User has {len(staple_exercises)} MANDATORY staple exercises")
                preference_constraints += f"\n⭐ MANDATORY STAPLE EXERCISES - MUST include ALL: {', '.join(staple_exercises)}"

            # Add progression philosophy if provided
            progression_instruction = ""
            if progression_philosophy and progression_philosophy.strip():
                logger.info(f"[Streaming] Including progression philosophy for leverage-based progressions")
                progression_instruction = progression_philosophy

            # Build duration text - use range if both min and max provided
            if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
                duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
            else:
                duration_text = str(duration_minutes)

            # Build coach-personalized naming context
            # Use scheduled_date if provided, otherwise fall back to workout_date
            naming_date = scheduled_date or workout_date
            naming_context = self._build_coach_naming_context(
                coach_style=coach_style,
                coach_tone=coach_tone,
                workout_date=naming_date,
            )
            logger.info(f"🎨 [Streaming] Coach naming context: style={coach_style}, tone={coach_tone}, date={naming_date}")

            prompt = f"""Generate a {duration_text}-minute workout for:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(goals, 'General fitness')}
- Equipment: {safe_join_list(equipment, 'Bodyweight only')}
- Focus: {safe_join_list(focus_areas, 'Full body')}{age_activity_context}{preference_constraints}

Return ONLY valid JSON (no markdown):
{{
  "name": "{naming_context}",
  "type": "strength",
  "difficulty": "{difficulty}",
  "duration_minutes": {duration_minutes},
  "duration_minutes_min": {duration_minutes_min or 'null'},
  "duration_minutes_max": {duration_minutes_max or 'null'},
  "estimated_duration_minutes": null,
  "target_muscles": ["muscle1", "muscle2"],
  "exercises": [
    {{
      "name": "Exercise Name",
      "sets": 3,
      "reps": 10,
      "rest_seconds": 60,
      "equipment": "equipment used",
      "muscle_group": "primary muscle",
      "notes": "Form tips",
      "set_targets": [
        {{"set_number": 1, "set_type": "warmup", "target_reps": 12, "target_weight_kg": 10, "target_rpe": 5}},
        {{"set_number": 2, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 7}},
        {{"set_number": 3, "set_type": "working", "target_reps": 10, "target_weight_kg": 20, "target_rpe": 8}}
      ]
    }}
  ],
  "notes": "Overall tips"
}}

⏱️ DURATION CALCULATION (MANDATORY):
Calculate "estimated_duration_minutes" = SUM of (sets × (reps × 3s + rest)) / 60 + (exercises × 30s) / 60
MUST be ≤ duration_minutes_max if provided. Adjust exercises/sets to fit time constraint!

CRITICAL: Every exercise MUST include "set_targets" array with set_number, set_type (warmup/working/drop/failure/amrap), target_reps, target_weight_kg, and target_rpe for each set.

Include exactly {exercise_count} exercises for {fitness_level} level using only: {safe_join_list(equipment, 'bodyweight')}

🚨🚨 ABSOLUTE REQUIREMENT - EQUIPMENT USAGE 🚨🚨
If user has gym equipment (full_gym, barbell, dumbbells, cable_machine, machines):
- AT LEAST 4-5 exercises MUST use that equipment (NOT bodyweight!)
- Maximum 1-2 bodyweight exercises allowed
- For beginners with gym: USE machines & dumbbells (Leg Press, Dumbbell Press, Cable Rows) - NOT just push-ups/squats!
- NEVER generate mostly bodyweight when gym equipment is available!
{senior_instruction}{holiday_instruction}{avoid_instruction}{progression_instruction}"""

            logger.info(f"[Streaming] Starting workout generation for {fitness_level} user")

        try:
            logger.info(f"[Streaming] Calling Gemini API with model={self.model}, prompt length={len(prompt)}")
            stream = await client.aio.models.generate_content_stream(
                model=self.model,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=GeneratedWorkoutResponse,
                    temperature=0.7,
                    max_output_tokens=16384  # Increased to prevent truncation with detailed workouts
                ),
            )

            if stream is None:
                logger.error(f"❌ [Streaming] Gemini returned None stream - API may be unavailable or prompt rejected")
                raise ValueError("Gemini streaming returned None - check API key and prompt")

            logger.info(f"[Streaming] Stream created successfully, type={type(stream).__name__}")

            chunk_count = 0
            total_chars = 0
            async for chunk in stream:
                chunk_count += 1
                logger.debug(f"[Streaming] Received chunk {chunk_count}, type={type(chunk).__name__}")

                # Check for blocked content or safety issues
                if hasattr(chunk, 'candidates') and chunk.candidates:
                    candidate = chunk.candidates[0]
                    if hasattr(candidate, 'finish_reason') and candidate.finish_reason:
                        finish_reason = str(candidate.finish_reason)
                        if finish_reason in ['MAX_TOKENS', 'FinishReason.MAX_TOKENS', '2']:
                            logger.warning(f"⚠️ [Streaming] Response truncated (MAX_TOKENS) at {total_chars} chars - increase max_output_tokens")
                        elif finish_reason not in ['STOP', 'FinishReason.STOP', '1']:
                            logger.warning(f"⚠️ [Streaming] Unexpected finish reason: {finish_reason}")
                    if hasattr(candidate, 'safety_ratings') and candidate.safety_ratings:
                        for rating in candidate.safety_ratings:
                            if hasattr(rating, 'blocked') and rating.blocked:
                                logger.error(f"🚫 [Streaming] Content blocked by safety filter: {rating}")

                if chunk.text:
                    total_chars += len(chunk.text)
                    yield chunk.text

            logger.info(f"✅ [Gemini Streaming] Complete: {chunk_count} chunks, {total_chars} chars")
            if total_chars < 500:
                logger.warning(f"⚠️ [Gemini Streaming] Response seems short ({total_chars} chars) - may be incomplete")

        except Exception as e:
            import traceback
            logger.error(f"Streaming workout generation failed: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            raise

    async def generate_workout_plan_streaming_cached(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int = 45,
        duration_minutes_min: Optional[int] = None,
        duration_minutes_max: Optional[int] = None,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        avoided_exercises: Optional[List[str]] = None,
        avoided_muscles: Optional[Dict] = None,
        staple_exercises: Optional[List[str]] = None,
        progression_philosophy: Optional[str] = None,
        exercise_count: int = 6,
        coach_style: Optional[str] = None,
        coach_tone: Optional[str] = None,
        scheduled_date: Optional[str] = None,
        strength_history: Optional[Dict] = None,
    ):
        """
        FAST workout generation using Gemini context caching.

        This method caches the static workout generation context (rules, examples,
        system instructions) and only sends user-specific data per request.

        Benefits:
        - 5-10x faster generation (~5-8s vs ~28s)
        - 75% cost reduction on cached input tokens
        - Same AI quality and output

        Falls back to non-cached generation if caching fails.

        Args:
            Same as generate_workout_plan_streaming, plus:
            strength_history: Optional dict of user's exercise history for weight recommendations

        Yields:
            str: JSON chunks as they arrive from Gemini
        """
        start_time = datetime.now()

        # Try to get or create cache
        cache_name = await self._get_or_create_workout_cache()

        if not cache_name:
            # Fallback to non-cached generation
            logger.warning("[CachedStreaming] Cache unavailable, falling back to non-cached generation")
            async for chunk in self.generate_workout_plan_streaming(
                fitness_level=fitness_level,
                goals=goals,
                equipment=equipment,
                duration_minutes=duration_minutes,
                duration_minutes_min=duration_minutes_min,
                duration_minutes_max=duration_minutes_max,
                focus_areas=focus_areas,
                avoid_name_words=avoid_name_words,
                workout_date=workout_date,
                age=age,
                activity_level=activity_level,
                intensity_preference=intensity_preference,
                avoided_exercises=avoided_exercises,
                avoided_muscles=avoided_muscles,
                staple_exercises=staple_exercises,
                progression_philosophy=progression_philosophy,
                exercise_count=exercise_count,
                coach_style=coach_style,
                coach_tone=coach_tone,
                scheduled_date=scheduled_date,
            ):
                yield chunk
            return

        # Build ONLY user-specific prompt (much smaller than full prompt)
        user_prompt = self._build_cached_user_prompt(
            fitness_level=fitness_level,
            goals=goals,
            equipment=equipment,
            duration_minutes=duration_minutes,
            duration_minutes_min=duration_minutes_min,
            duration_minutes_max=duration_minutes_max,
            focus_areas=focus_areas,
            avoid_name_words=avoid_name_words,
            workout_date=workout_date,
            age=age,
            activity_level=activity_level,
            intensity_preference=intensity_preference,
            avoided_exercises=avoided_exercises,
            avoided_muscles=avoided_muscles,
            staple_exercises=staple_exercises,
            progression_philosophy=progression_philosophy,
            exercise_count=exercise_count,
            coach_style=coach_style,
            coach_tone=coach_tone,
            scheduled_date=scheduled_date,
            strength_history=strength_history,
        )

        try:
            logger.info(f"[CachedStreaming] Using cache: {cache_name}")
            logger.info(f"[CachedStreaming] User prompt length: {len(user_prompt)} chars (vs ~15000 non-cached)")

            stream = await client.aio.models.generate_content_stream(
                model=self.model,
                contents=user_prompt,
                config=types.GenerateContentConfig(
                    cached_content=cache_name,  # USE THE CACHE!
                    response_mime_type="application/json",
                    response_schema=GeneratedWorkoutResponse,
                    temperature=0.7,
                    max_output_tokens=16384,  # Must match non-cached - workouts with set_targets can exceed 4000 tokens
                ),
            )

            if stream is None:
                logger.error(f"❌ [CachedStreaming] Gemini returned None stream")
                raise ValueError("Gemini streaming returned None")

            chunk_count = 0
            total_chars = 0
            async for chunk in stream:
                chunk_count += 1

                # Check for blocked content or safety issues
                if hasattr(chunk, 'candidates') and chunk.candidates:
                    candidate = chunk.candidates[0]
                    if hasattr(candidate, 'finish_reason') and candidate.finish_reason:
                        finish_reason = str(candidate.finish_reason)
                        if finish_reason in ['MAX_TOKENS', 'FinishReason.MAX_TOKENS', '2']:
                            logger.warning(f"⚠️ [CachedStreaming] Response truncated (MAX_TOKENS) at {total_chars} chars - increase max_output_tokens")
                        elif finish_reason not in ['STOP', 'FinishReason.STOP', '1']:
                            logger.warning(f"⚠️ [CachedStreaming] Unexpected finish reason: {finish_reason}")

                if chunk.text:
                    total_chars += len(chunk.text)
                    yield chunk.text

            elapsed = (datetime.now() - start_time).total_seconds()
            logger.info(f"✅ [CachedStreaming] Complete: {chunk_count} chunks, {total_chars} chars in {elapsed:.1f}s")

        except Exception as e:
            import traceback
            logger.error(f"[CachedStreaming] Failed: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")

            # Fallback to non-cached generation
            logger.warning("[CachedStreaming] Falling back to non-cached generation")
            async for chunk in self.generate_workout_plan_streaming(
                fitness_level=fitness_level,
                goals=goals,
                equipment=equipment,
                duration_minutes=duration_minutes,
                duration_minutes_min=duration_minutes_min,
                duration_minutes_max=duration_minutes_max,
                focus_areas=focus_areas,
                avoid_name_words=avoid_name_words,
                workout_date=workout_date,
                age=age,
                activity_level=activity_level,
                intensity_preference=intensity_preference,
                avoided_exercises=avoided_exercises,
                avoided_muscles=avoided_muscles,
                staple_exercises=staple_exercises,
                progression_philosophy=progression_philosophy,
                exercise_count=exercise_count,
                coach_style=coach_style,
                coach_tone=coach_tone,
                scheduled_date=scheduled_date,
            ):
                yield chunk

    def _build_cached_user_prompt(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration_minutes: int,
        duration_minutes_min: Optional[int],
        duration_minutes_max: Optional[int],
        focus_areas: Optional[List[str]],
        avoid_name_words: Optional[List[str]],
        workout_date: Optional[str],
        age: Optional[int],
        activity_level: Optional[str],
        intensity_preference: Optional[str],
        avoided_exercises: Optional[List[str]],
        avoided_muscles: Optional[Dict],
        staple_exercises: Optional[List[str]],
        progression_philosophy: Optional[str],
        exercise_count: int,
        coach_style: Optional[str],
        coach_tone: Optional[str],
        scheduled_date: Optional[str],
        strength_history: Optional[Dict],
    ) -> str:
        """
        Build the user-specific prompt for cached generation.

        This prompt is MUCH smaller than the full prompt because the cache
        already contains all the static rules, examples, and guidelines.
        """
        # Determine difficulty
        if intensity_preference:
            difficulty = intensity_preference
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build duration text
        if duration_minutes_min and duration_minutes_max and duration_minutes_min != duration_minutes_max:
            duration_text = f"{duration_minutes_min}-{duration_minutes_max}"
        else:
            duration_text = str(duration_minutes)

        # Build user context section
        user_context_parts = [
            f"Generate a {duration_text}-minute {safe_join_list(focus_areas, 'full body')} workout.",
            "",
            "## USER PROFILE",
            f"- Fitness Level: {fitness_level}",
            f"- Goals: {safe_join_list(goals, 'General fitness')}",
            f"- Equipment: {safe_join_list(equipment, 'Bodyweight only')}",
            f"- Intensity: {difficulty}",
        ]

        if age:
            user_context_parts.append(f"- Age: {age}")
        if activity_level:
            user_context_parts.append(f"- Activity Level: {activity_level}")

        # User preferences section
        user_context_parts.append("")
        user_context_parts.append("## USER PREFERENCES")

        if avoided_exercises and len(avoided_exercises) > 0:
            user_context_parts.append(f"🚫 AVOID these exercises: {', '.join(avoided_exercises[:10])}")

        if avoided_muscles:
            avoid_completely = avoided_muscles.get("avoid", [])
            reduce_usage = avoided_muscles.get("reduce", [])
            if avoid_completely:
                user_context_parts.append(f"🚫 AVOID muscles (injury/preference): {', '.join(avoid_completely)}")
            if reduce_usage:
                user_context_parts.append(f"⚠️ MINIMIZE muscles: {', '.join(reduce_usage)}")

        if staple_exercises and len(staple_exercises) > 0:
            user_context_parts.append(f"⭐ MUST INCLUDE these staple exercises: {', '.join(staple_exercises)}")

        # Strength history for weight recommendations
        if strength_history:
            user_context_parts.append("")
            user_context_parts.append("## STRENGTH HISTORY (for weight recommendations)")
            history_summary = self._format_strength_history(strength_history)
            if history_summary:
                user_context_parts.append(history_summary)
            else:
                user_context_parts.append("No history - use beginner-appropriate weights")
        else:
            user_context_parts.append("")
            user_context_parts.append("## STRENGTH HISTORY")
            user_context_parts.append("No history available - use beginner-appropriate weights")

        # Progression philosophy if provided
        if progression_philosophy and progression_philosophy.strip():
            user_context_parts.append("")
            user_context_parts.append("## PROGRESSION CONTEXT")
            user_context_parts.append(progression_philosophy)

        # Naming context
        naming_date = scheduled_date or workout_date
        naming_context = self._build_coach_naming_context(
            coach_style=coach_style,
            coach_tone=coach_tone,
            workout_date=naming_date,
        )

        # Holiday theme if applicable
        holiday_theme = self._get_holiday_theme(workout_date)
        if holiday_theme:
            user_context_parts.append("")
            user_context_parts.append(f"## THEME: {holiday_theme}")

        # Words to avoid in name
        if avoid_name_words and len(avoid_name_words) > 0:
            user_context_parts.append("")
            user_context_parts.append(f"⚠️ Do NOT use these words in workout name: {', '.join(avoid_name_words)}")

        # Final instructions
        user_context_parts.append("")
        user_context_parts.append("## GENERATION REQUEST")
        user_context_parts.append(f"Generate exactly {exercise_count} exercises with complete set_targets.")
        user_context_parts.append(f"Workout name style: {naming_context}")
        user_context_parts.append("Return valid JSON only, no markdown.")

        return "\n".join(user_context_parts)

    def _format_strength_history(self, strength_history: Dict) -> str:
        """Format strength history for the prompt."""
        if not strength_history:
            return ""

        lines = []
        for exercise_name, data in list(strength_history.items())[:10]:  # Limit to 10 exercises
            if isinstance(data, dict):
                weight = data.get("weight_kg") or data.get("max_weight")
                reps = data.get("reps") or data.get("max_reps")
                if weight:
                    lines.append(f"- {exercise_name}: {weight}kg × {reps or '?'} reps")
            elif isinstance(data, (int, float)):
                lines.append(f"- {exercise_name}: {data}kg")

        return "\n".join(lines) if lines else ""

    async def generate_workout_from_library(
        self,
        exercises: List[Dict],
        fitness_level: str,
        goals: List[str],
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
        avoid_name_words: Optional[List[str]] = None,
        workout_date: Optional[str] = None,
        age: Optional[int] = None,
        activity_level: Optional[str] = None,
        intensity_preference: Optional[str] = None,
        custom_program_description: Optional[str] = None,
        workout_type_preference: Optional[str] = None,
        comeback_context: Optional[str] = None,
        strength_history: Optional[Dict[str, Dict]] = None,
        personal_bests: Optional[Dict[str, Dict]] = None,
    ) -> Dict:
        """
        Generate a workout plan using exercises from the exercise library.

        Instead of having AI invent exercises, this method takes pre-selected
        exercises from the library and asks AI to create a creative workout
        name and organize them appropriately.

        Args:
            exercises: List of exercises from the exercise library
            fitness_level: beginner, intermediate, or advanced
            goals: List of fitness goals
            duration_minutes: Target workout duration
            focus_areas: Optional specific areas to focus on
            avoid_name_words: Words to avoid in workout name
            workout_date: Optional date for holiday theming
            age: Optional user's age for age-appropriate adjustments
            activity_level: Optional activity level
            intensity_preference: Optional intensity preference (easy, medium, hard)
            custom_program_description: Optional user's custom program description (e.g., "Train for HYROX")
            workout_type_preference: Optional workout type preference (strength, cardio, mixed)
            comeback_context: Optional context string for users returning from extended breaks
            strength_history: Optional dict of exercise performance history (last weight, max weight, reps)
            personal_bests: Optional dict of user's personal records per exercise

        Returns:
            Dict with workout structure
        """
        if not exercises:
            raise ValueError("No exercises provided")

        # Use intensity_preference if provided, otherwise derive from fitness_level
        if intensity_preference:
            difficulty = intensity_preference

            # Warn about potentially dangerous combinations
            if fitness_level == "beginner" and intensity_preference == "hell":
                print(f"🔥 [Gemini] WARNING: Beginner fitness level with HELL intensity - this is extremely challenging!")
            elif fitness_level == "beginner" and intensity_preference == "hard":
                print(f"⚠️ [Gemini] WARNING: Beginner fitness level with hard intensity preference - ensure exercises are scaled appropriately")
            elif fitness_level == "intermediate" and intensity_preference == "hell":
                print(f"🔥 [Gemini] Note: Intermediate fitness level with HELL intensity - maximum challenge mode")
            elif fitness_level == "intermediate" and intensity_preference == "hard":
                print(f"🔍 [Gemini] Note: Intermediate fitness level with hard intensity - will challenge the user")
            elif intensity_preference == "hell":
                print(f"🔥 [Gemini] HELL MODE ACTIVATED - generating maximum intensity workout from library")
        else:
            difficulty = "easy" if fitness_level == "beginner" else ("hard" if fitness_level == "advanced" else "medium")

        # Build avoid words instruction
        avoid_instruction = ""
        if avoid_name_words and len(avoid_name_words) > 0:
            avoid_instruction = f"\n\n⚠️ Do NOT use these words in the workout name: {', '.join(avoid_name_words[:15])}"

        # Check for holiday theming
        holiday_theme = self._get_holiday_theme(workout_date)
        holiday_instruction = f"\n\n{holiday_theme}" if holiday_theme else ""

        # Add safety instruction if there's a mismatch between fitness level and intensity
        safety_instruction = ""
        if fitness_level == "beginner" and difficulty == "hard":
            safety_instruction = "\n\n⚠️ SAFETY NOTE: User is a beginner but wants hard intensity. Structure exercises with more rest periods and ensure reps/sets are achievable with proper form. Focus on compound movements rather than advanced techniques."

        # Build custom program context if user has specified a custom training goal
        custom_program_context = ""
        if custom_program_description and custom_program_description.strip():
            custom_program_context = f"\n- Custom Training Goal: {custom_program_description}"

        # Add age context for appropriate naming and notes
        age_context = ""
        if age:
            if age >= 75:
                age_context = f"\n- Age: {age} (elderly - focus on gentle, supportive movements)"
            elif age >= 60:
                age_context = f"\n- Age: {age} (senior - prioritize low-impact, balance-focused exercises)"
            elif age >= 45:
                age_context = f"\n- Age: {age} (middle-aged - joint-friendly approach)"
            else:
                age_context = f"\n- Age: {age}"

        # Determine workout type
        workout_type = workout_type_preference if workout_type_preference else "strength"

        # Build comeback instruction
        comeback_instruction = ""
        if comeback_context and comeback_context.strip():
            logger.info(f"🔄 [Gemini Service] Library workout - user in comeback mode")
            comeback_instruction = f"\n\n🔄 COMEBACK NOTE: User is returning from an extended break. Include comeback/return-to-training themes in the name (e.g., 'Comeback', 'Return', 'Fresh Start')."

        # Build performance context from strength history and personal bests
        performance_context = ""
        if strength_history or personal_bests:
            from api.v1.workouts.utils import format_performance_context
            performance_context = format_performance_context(
                exercises, strength_history or {}, personal_bests or {}
            )
            if performance_context:
                performance_context = f"\n\n{performance_context}"
                logger.info(f"[Gemini Service] Added performance context for {len([ex for ex in exercises if strength_history.get(ex.get('name')) or personal_bests.get(ex.get('name'))])} exercises")

        # Format exercises for the prompt
        exercise_list = "\n".join([
            f"- {ex.get('name', 'Unknown')}: targets {ex.get('muscle_group', 'unknown')}, equipment: {ex.get('equipment', 'bodyweight')}"
            for ex in exercises
        ])

        # Difficulty-aware naming hints
        difficulty_naming = ""
        if difficulty in ("hell", "extreme"):
            difficulty_naming = "\nThis is HELL MODE. Name MUST reflect EXTREME intensity (Inferno, Destroyer, Savage, Beast, Annihilation)."
        elif difficulty == "hard":
            difficulty_naming = "\nThis is a hard workout. Name should reflect high intensity and challenge."
        elif difficulty == "easy":
            difficulty_naming = "\nThis is an easy/recovery workout. Name should be approachable and light."

        prompt = f"""I have selected these exercises for a {duration_minutes}-minute {focus_areas[0] if focus_areas else 'full body'} workout:

{exercise_list}

User profile:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}{age_context}{custom_program_context}{performance_context}{safety_instruction}
{difficulty_naming}
Create a CREATIVE and MOTIVATING workout name (3-4 words) that reflects the user's training focus.

Examples of good names:
- "Thunder Strike Legs"
- "Phoenix Power Chest"
- "Savage Wolf Back"
- "Iron Storm Arms"
{holiday_instruction}{avoid_instruction}{comeback_instruction}

Return a JSON object with:
{{
  "name": "Your creative workout name here",
  "type": "{workout_type}",
  "difficulty": "{difficulty}",
  "notes": "A personalized tip for this workout based on the user's performance history (1-2 sentences). Reference their progress towards PRs or recent improvements if available."
}}"""

        # Log the full prompt for debugging
        logger.info("=" * 80)
        logger.info("[GEMINI PROMPT - generate_workout_from_library]")
        logger.info(f"Parameters: fitness_level={fitness_level}, goals={goals}, duration={duration_minutes}min")
        logger.info(f"Focus areas: {focus_areas}, intensity_preference={intensity_preference}")
        logger.info(f"Custom program description: {custom_program_description}")
        logger.info(f"Exercise count: {len(exercises)}")
        logger.info(f"Exercise names: {[ex.get('name') for ex in exercises]}")
        logger.info(f"Strength history: {len(strength_history) if strength_history else 0} exercises")
        logger.info(f"Personal bests: {len(personal_bests) if personal_bests else 0} exercises")
        logger.info("-" * 40)
        logger.info(f"FULL PROMPT:\n{prompt}")
        logger.info("=" * 80)

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        system_instruction="You are a creative fitness coach. Generate motivating workout names. Return ONLY valid JSON.",
                        response_mime_type="application/json",
                        response_schema=WorkoutNamingResponse,
                        temperature=0.8,
                        max_output_tokens=2000  # Increased for thinking models
                    ),
                ),
                timeout=30,  # 30s for workout naming (small response)
            )

            # Use response.parsed for structured output - SDK handles JSON parsing
            ai_response = response.parsed
            if not ai_response:
                raise ValueError("Gemini returned empty workout naming response")

            # Combine AI response with our exercises
            return {
                "name": ai_response.name or "Power Workout",
                "type": ai_response.type or "strength",
                "difficulty": difficulty,
                "duration_minutes": duration_minutes,
                "target_muscles": list(set([ex.get('muscle_group', '') for ex in exercises if ex.get('muscle_group')])),
                "exercises": exercises,
                "notes": ai_response.notes or "Focus on proper form and controlled movements."
            }

        except Exception as e:
            print(f"Error generating workout name: {e}")
            raise  # No fallback - let errors propagate

    async def generate_workout_summary(
        self,
        workout_name: str,
        exercises: List[Dict],
        target_muscles: List[str],
        user_goals: List[str],
        fitness_level: str,
        workout_id: str = None,
        duration_minutes: int = 45,
        workout_type: str = None,
        difficulty: str = None
    ) -> str:
        """
        Generate an AI summary/description of a workout using the Workout Insights agent.

        Args:
            workout_name: Name of the workout
            exercises: List of exercises with their details
            target_muscles: Target muscle groups
            user_goals: User's fitness goals
            fitness_level: User's fitness level
            workout_id: Optional workout ID
            duration_minutes: Workout duration in minutes
            workout_type: Type of workout (strength, cardio, etc.)
            difficulty: Difficulty level

        Returns:
            Plain-text workout summary (2-3 sentences, no markdown)
        """
        # Check summary cache first (same workout data should return same summary)
        try:
            # Build cache key from workout content (exercises define the workout)
            exercise_names = [ex.get("name", "") for ex in exercises] if exercises else []
            cache_key = _summary_cache.make_key(
                "summary", workout_name, exercise_names, target_muscles,
                user_goals, fitness_level, duration_minutes, workout_type, difficulty
            )
            cached_result = _summary_cache.get(cache_key)
            if cached_result is not None:
                logger.info(f"[SummaryCache] Cache HIT for workout: '{workout_name}'")
                return cached_result
        except Exception as cache_err:
            logger.warning(f"[SummaryCache] Cache lookup error (falling through): {cache_err}")

        try:
            # Use the Workout Insights LangGraph agent
            from services.langgraph_agents.workout_insights.graph import generate_workout_insights

            summary = await generate_workout_insights(
                workout_id=workout_id or "unknown",
                workout_name=workout_name,
                exercises=exercises,
                duration_minutes=duration_minutes,
                workout_type=workout_type,
                difficulty=difficulty,
                user_goals=user_goals,
                fitness_level=fitness_level,
            )

            # Cache the result
            try:
                _summary_cache.set(cache_key, summary)
                logger.info(f"[SummaryCache] Cache MISS - stored summary for: '{workout_name}'")
            except Exception as cache_err:
                logger.warning(f"[SummaryCache] Failed to store result: {cache_err}")

            return summary

        except Exception as e:
            print(f"Error generating workout summary with agent: {e}")
            raise  # No fallback - let errors propagate

    async def generate_exercise_reasoning(
        self,
        workout_name: str,
        exercises: List[Dict],
        user_profile: Dict,
        program_preferences: Dict,
        workout_type: str = "strength",
        difficulty: str = "intermediate",
    ) -> Dict:
        """
        Generate AI-powered reasoning for why each exercise was selected.

        Args:
            workout_name: Name of the workout
            exercises: List of exercises with their details
            user_profile: User's profile (goals, fitness_level, equipment, injuries)
            program_preferences: Program preferences (training_split, focus_areas)
            workout_type: Type of workout
            difficulty: Difficulty level

        Returns:
            Dict with 'workout_reasoning' (str) and 'exercise_reasoning' (list of dicts)
        """
        try:
            # Extract relevant data
            exercise_list = []
            for ex in exercises[:8]:  # Limit to 8 exercises for token efficiency
                exercise_list.append({
                    "name": ex.get("name", "Unknown"),
                    "muscle": ex.get("muscle_group") or ex.get("primary_muscle") or "general",
                    "equipment": ex.get("equipment", "bodyweight"),
                    "sets": ex.get("sets", 3),
                    "reps": ex.get("reps", "8-12"),
                })

            user_goals = user_profile.get("goals", [])
            fitness_level = user_profile.get("fitness_level", "intermediate")
            user_equipment = user_profile.get("equipment", [])
            injuries = user_profile.get("injuries", [])
            training_split = program_preferences.get("training_split", "full_body")
            focus_areas = program_preferences.get("focus_areas", [])

            # Get rich split context with scientific rationale
            split_context = get_split_context(training_split)

            prompt = f"""You are a certified personal trainer explaining workout design to a client.

WORKOUT: {workout_name}
TYPE: {workout_type}
DIFFICULTY: {difficulty}

{split_context}

USER PROFILE:
- Fitness Level: {fitness_level}
- Goals: {safe_join_list(user_goals, 'general fitness')}
- Equipment Available: {safe_join_list(user_equipment, 'various')}
- Injuries/Limitations: {safe_join_list(injuries, 'none noted')}
- Focus Areas: {safe_join_list(focus_areas, 'balanced')}

EXERCISES:
{chr(10).join([f"- {ex['name']} ({ex['muscle']}, {ex['sets']}x{ex['reps']}, {ex['equipment']})" for ex in exercise_list])}

Generate personalized reasoning. Return ONLY valid JSON:

{{
    "workout_reasoning": "1-2 sentences explaining the overall workout design philosophy and how it matches the user's goals",
    "exercise_reasoning": [
        {{
            "exercise_name": "exact exercise name",
            "reasoning": "1 sentence explaining why THIS exercise was chosen for THIS user (mention specific goals, equipment match, or how it fits their level)"
        }}
    ]
}}

RULES:
1. Be specific - mention actual goals, equipment, or fitness level
2. Each exercise reasoning should be unique and personal
3. Reference the training split/focus if relevant
4. Keep each reasoning to ONE focused sentence
5. Avoid generic phrases like "great exercise" or "builds strength"
"""

            # Retry logic for intermittent failures
            max_retries = 2
            last_error = None
            content = ""

            for attempt in range(max_retries + 1):
                try:
                    response = await asyncio.wait_for(
                        client.aio.models.generate_content(
                            model=self.model,
                            contents=prompt,
                            config=types.GenerateContentConfig(
                                response_mime_type="application/json",
                                response_schema=ExerciseReasoningResponse,
                                temperature=0.7,
                                max_output_tokens=4000,  # Increased to prevent truncation
                            ),
                        ),
                        timeout=30,  # 30s for exercise reasoning
                    )

                    # Use response.parsed for structured output - SDK handles JSON parsing
                    parsed = response.parsed
                    if not parsed:
                        print(f"⚠️ [Exercise Reasoning] Empty response (attempt {attempt + 1})")
                        last_error = "Empty response from Gemini"
                        continue

                    result = parsed.model_dump()

                    if result.get("workout_reasoning") and result.get("exercise_reasoning"):
                        return {
                            "workout_reasoning": result.get("workout_reasoning", ""),
                            "exercise_reasoning": result.get("exercise_reasoning", []),
                        }
                    else:
                        print(f"⚠️ [Exercise Reasoning] Incomplete result (attempt {attempt + 1})")
                        last_error = "Incomplete result from Gemini"
                        continue

                except Exception as e:
                    print(f"⚠️ [Exercise Reasoning] Failed (attempt {attempt + 1}): {e}")
                    last_error = str(e)
                    continue

            print(f"❌ [Exercise Reasoning] All {max_retries + 1} attempts failed. Last error: {last_error}")
            return {
                "workout_reasoning": "",
                "exercise_reasoning": [],
            }

        except Exception as e:
            print(f"Error generating exercise reasoning: {e}")
            # Return empty result - caller should use fallback
            return {
                "workout_reasoning": "",
                "exercise_reasoning": [],
            }

    async def generate_weekly_holistic_plan(
        self,
        user_profile: Dict,
        workout_days: List[int],
        fasting_protocol: str,
        nutrition_strategy: str,
        nutrition_targets: Dict,
        week_start_date: str,
        preferred_workout_time: str = "17:00",
    ) -> Dict:
        """
        Generate a complete weekly holistic plan integrating workouts, nutrition, and fasting.

        Args:
            user_profile: User's fitness profile (level, goals, equipment, age, restrictions)
            workout_days: Days of week for training (0=Monday, 6=Sunday)
            fasting_protocol: Fasting protocol (16:8, 18:6, OMAD, etc.)
            nutrition_strategy: Strategy (workout_aware, static, cutting, bulking, maintenance)
            nutrition_targets: Base nutrition targets (calories, protein_g, carbs_g, fat_g)
            week_start_date: Start date of the week (YYYY-MM-DD)
            preferred_workout_time: Preferred workout time (HH:MM)

        Returns:
            Dict with weekly plan structure including daily entries
        """
        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        workout_day_names = [day_names[d] for d in workout_days if 0 <= d < 7]

        prompt = f'''Generate a complete weekly holistic fitness plan coordinating workouts, nutrition, and fasting.

USER PROFILE:
- Fitness Level: {user_profile.get('fitness_level', 'intermediate')}
- Goals: {', '.join(user_profile.get('goals', ['general fitness']))}
- Equipment: {', '.join(user_profile.get('equipment', ['dumbbells', 'bodyweight']))}
- Age group: {age_to_bracket(user_profile['age']) if isinstance(user_profile.get('age'), (int, float)) else user_profile.get('age_bracket', 'adult')}
- Dietary Restrictions: {', '.join(user_profile.get('dietary_restrictions', []))}

WORKOUT SCHEDULE:
- Training Days: {workout_day_names} (indices: {workout_days})
- Preferred Workout Time: {preferred_workout_time}
- Week Starting: {week_start_date}

NUTRITION TARGETS (base):
- Daily Calories: {nutrition_targets.get('calories', 2000)}
- Protein: {nutrition_targets.get('protein_g', 150)}g
- Carbs: {nutrition_targets.get('carbs_g', 200)}g
- Fat: {nutrition_targets.get('fat_g', 65)}g

NUTRITION STRATEGY: {nutrition_strategy}
- If workout_aware: Increase calories by 200-400 on training days, boost protein +20-30g, boost carbs +30-50g
- If cutting: Reduce rest day calories by 200-300
- If bulking: Increase all days by 300-500 calories
- If maintenance/static: Keep targets consistent

FASTING PROTOCOL: {fasting_protocol}
- 16:8: 16 hour fast, 8 hour eating window (typical: 12pm-8pm)
- 18:6: 18 hour fast, 6 hour eating window (typical: 12pm-6pm)
- OMAD: One meal a day, 1-2 hour eating window
- None: No fasting restrictions

COORDINATION RULES:
1. On training days, ensure eating window includes time for pre-workout and post-workout meals
2. Pre-workout meal should be 2-3 hours before workout
3. Post-workout meal should be within 1-2 hours after workout
4. If workout falls during fasting period, note this as a warning
5. If OMAD or extended fasting with intense workout, suggest BCAA supplementation

Return ONLY valid JSON (no markdown, no explanation) in this exact format:
{{
  "daily_entries": [
    {{
      "day_index": 0,
      "day_name": "Monday",
      "day_type": "training",
      "workout_time": "17:00",
      "workout_focus": "Upper Body Push",
      "workout_duration_minutes": 45,
      "calorie_target": 2400,
      "protein_target_g": 180,
      "carbs_target_g": 250,
      "fat_target_g": 70,
      "fiber_target_g": 30,
      "eating_window_start": "11:00",
      "eating_window_end": "19:00",
      "fasting_start_time": "19:00",
      "fasting_duration_hours": 16,
      "meal_suggestions": [
        {{
          "meal_type": "pre_workout",
          "suggested_time": "14:00",
          "foods": [
            {{"name": "Oatmeal with banana", "amount": "1 bowl", "calories": 350, "protein_g": 12, "carbs_g": 60, "fat_g": 8}}
          ],
          "notes": "Light carbs for energy"
        }},
        {{
          "meal_type": "post_workout",
          "suggested_time": "18:30",
          "foods": [
            {{"name": "Grilled chicken breast", "amount": "200g", "calories": 330, "protein_g": 62, "carbs_g": 0, "fat_g": 7}},
            {{"name": "Brown rice", "amount": "1 cup", "calories": 215, "protein_g": 5, "carbs_g": 45, "fat_g": 2}}
          ],
          "notes": "High protein for muscle recovery"
        }}
      ],
      "coordination_notes": []
    }},
    {{
      "day_index": 1,
      "day_name": "Tuesday",
      "day_type": "rest",
      "workout_time": null,
      "workout_focus": null,
      "workout_duration_minutes": 0,
      "calorie_target": 2000,
      "protein_target_g": 150,
      "carbs_target_g": 180,
      "fat_target_g": 65,
      "fiber_target_g": 30,
      "eating_window_start": "12:00",
      "eating_window_end": "20:00",
      "fasting_start_time": "20:00",
      "fasting_duration_hours": 16,
      "meal_suggestions": [
        {{
          "meal_type": "lunch",
          "suggested_time": "12:30",
          "foods": [...],
          "notes": "..."
        }}
      ],
      "coordination_notes": []
    }}
  ],
  "weekly_summary": {{
    "total_training_days": 4,
    "total_rest_days": 3,
    "avg_daily_calories": 2200,
    "weekly_protein_total": 1120,
    "focus_areas": ["Upper Body", "Lower Body", "Core"],
    "notes": "Balanced week with adequate recovery"
  }}
}}

Generate entries for ALL 7 days of the week (Monday through Sunday).
Ensure meal suggestions total approximately match the daily calorie/macro targets.
Include 2-4 meals per day that fit within the eating window.
Add coordination_notes array with warnings if any conflicts exist (e.g., workout during fast).
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a fitness and nutrition planning AI. Return only valid JSON.",
                        max_output_tokens=8000,
                        temperature=0.7,
                    ),
                ),
                timeout=90,  # 90s for large weekly plan generation
            )

            # Extract JSON from response
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[WeeklyPlan] Gemini API timed out after 90s")
            raise Exception("Weekly plan generation timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error generating weekly holistic plan: {e}")
            raise

    async def generate_daily_meal_plan(
        self,
        nutrition_targets: Dict,
        eating_window_start: str,
        eating_window_end: str,
        workout_time: Optional[str],
        day_type: str,
        dietary_restrictions: List[str],
        preferences: Dict,
    ) -> List[Dict]:
        """
        Generate AI meal suggestions for a specific day.

        Args:
            nutrition_targets: Daily nutrition targets (calories, protein_g, carbs_g, fat_g)
            eating_window_start: Start of eating window (HH:MM)
            eating_window_end: End of eating window (HH:MM)
            workout_time: Workout time if training day (HH:MM or None)
            day_type: Type of day (training, rest, active_recovery)
            dietary_restrictions: User's dietary restrictions
            preferences: User's food preferences (cuisine, dislikes, etc.)

        Returns:
            List of meal suggestions with foods and macros
        """
        workout_context = ""
        if day_type == "training" and workout_time:
            workout_context = f"""
WORKOUT TIMING:
- Workout at: {workout_time}
- Include a pre-workout meal 2-3 hours before
- Include a post-workout meal within 1-2 hours after
- Pre-workout: Moderate carbs, some protein, low fat
- Post-workout: High protein (30-40g), fast-digesting carbs
"""

        restrictions_text = ", ".join(dietary_restrictions) if dietary_restrictions else "None"
        cuisine_pref = preferences.get("preferred_cuisines", ["varied"])
        dislikes = preferences.get("dislikes", [])

        prompt = f'''Generate a practical daily meal plan for the following requirements:

NUTRITION TARGETS:
- Calories: {nutrition_targets.get('calories', 2000)}
- Protein: {nutrition_targets.get('protein_g', 150)}g
- Carbs: {nutrition_targets.get('carbs_g', 200)}g
- Fat: {nutrition_targets.get('fat_g', 65)}g

EATING WINDOW:
- Start: {eating_window_start}
- End: {eating_window_end}

DAY TYPE: {day_type}
{workout_context}

DIETARY RESTRICTIONS: {restrictions_text}
PREFERRED CUISINES: {', '.join(cuisine_pref)}
DISLIKES: {', '.join(dislikes) if dislikes else 'None specified'}

Generate 3-4 meals that:
1. Fit within the eating window times
2. Total approximately the target macros
3. Are practical and easy to prepare
4. Respect dietary restrictions
5. Include pre/post workout meals if training day

Return ONLY valid JSON (no markdown) as an array:
[
  {{
    "meal_type": "breakfast|lunch|dinner|snack|pre_workout|post_workout",
    "suggested_time": "HH:MM",
    "foods": [
      {{"name": "Food name", "amount": "serving size", "calories": 300, "protein_g": 25, "carbs_g": 30, "fat_g": 10}}
    ],
    "total_calories": 450,
    "total_protein_g": 35,
    "total_carbs_g": 45,
    "total_fat_g": 15,
    "prep_time_minutes": 15,
    "notes": "Quick and high protein"
  }}
]
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a nutrition planning AI. Generate practical, healthy meal suggestions. Return only valid JSON.",
                        max_output_tokens=4000,
                        temperature=0.7,
                    ),
                ),
                timeout=60,  # 60s for daily meal plan
            )

            # Extract JSON from response
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[MealPlan] Gemini API timed out after 60s")
            raise Exception("Meal plan generation timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error generating daily meal plan: {e}")
            raise

    async def regenerate_meal_for_day(
        self,
        meal_type: str,
        current_day_totals: Dict,
        remaining_targets: Dict,
        eating_window_end: str,
        dietary_restrictions: List[str],
        reason: str = "user_request",
    ) -> Dict:
        """
        Regenerate a single meal while maintaining macro balance.

        Args:
            meal_type: Type of meal to regenerate (lunch, dinner, etc.)
            current_day_totals: What's already been consumed/planned
            remaining_targets: Remaining macros to hit
            eating_window_end: When eating window ends
            dietary_restrictions: User's dietary restrictions
            reason: Why regenerating (user_request, dislike, variety)

        Returns:
            Single meal suggestion dict
        """
        prompt = f'''Generate a replacement {meal_type} meal.

REMAINING NUTRITION TARGETS (what this meal should approximately hit):
- Calories: {remaining_targets.get('calories', 500)}
- Protein: {remaining_targets.get('protein_g', 40)}g
- Carbs: {remaining_targets.get('carbs_g', 50)}g
- Fat: {remaining_targets.get('fat_g', 20)}g

ALREADY CONSUMED TODAY:
- Calories: {current_day_totals.get('calories', 0)}
- Protein: {current_day_totals.get('protein_g', 0)}g

CONSTRAINTS:
- Must finish by: {eating_window_end}
- Dietary restrictions: {', '.join(dietary_restrictions) if dietary_restrictions else 'None'}
- Reason for regeneration: {reason}

Generate a single meal that helps hit the remaining targets.

Return ONLY valid JSON (no markdown):
{{
  "meal_type": "{meal_type}",
  "suggested_time": "HH:MM",
  "foods": [
    {{"name": "Food name", "amount": "serving size", "calories": 300, "protein_g": 25, "carbs_g": 30, "fat_g": 10}}
  ],
  "total_calories": 500,
  "total_protein_g": 40,
  "total_carbs_g": 50,
  "total_fat_g": 20,
  "prep_time_minutes": 20,
  "notes": "High protein dinner option"
}}
'''

        try:
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self.model,
                    contents=[types.Content(role="user", parts=[types.Part.from_text(text=prompt)])],
                    config=types.GenerateContentConfig(
                        system_instruction="You are a nutrition planning AI. Return only valid JSON.",
                        max_output_tokens=2000,
                        temperature=0.8,
                    ),
                ),
                timeout=30,  # 30s for single meal regeneration
            )

            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return json.loads(text.strip())

        except asyncio.TimeoutError:
            logger.error("[MealRegenerate] Gemini API timed out after 30s")
            raise Exception("Meal regeneration timed out. Please try again.")
        except Exception as e:
            logger.error(f"Error regenerating meal: {e}")
            raise

    def get_agent_personality(self, agent_type: str = "coach") -> dict:
        """
        Get agent-specific personality settings.

        Returns dict with:
        - name: Agent display name
        - emoji: Agent emoji
        - greeting: How the agent greets users
        - personality: Core personality traits
        - expertise: What the agent specializes in
        """
        agents = {
            "coach": {
                "name": "AI Coach",
                "emoji": "🏋️",
                "greeting": "Hey there! I'm your FitWiz.",
                "personality": "motivating, supportive, and knowledgeable about all aspects of fitness",
                "expertise": "workout planning, exercise form, fitness motivation, and overall wellness",
                "color": "cyan",
            },
            "nutrition": {
                "name": "Nutrition Expert",
                "emoji": "🥗",
                "greeting": "Hi! I'm your Nutrition Expert.",
                "personality": "friendly, health-conscious, and passionate about balanced eating",
                "expertise": "meal planning, macros, pre/post workout nutrition, healthy recipes, and dietary advice",
                "color": "green",
            },
            "workout": {
                "name": "Workout Specialist",
                "emoji": "💪",
                "greeting": "What's up! I'm your Workout Specialist.",
                "personality": "energetic, technical, and focused on proper form and technique",
                "expertise": "exercise selection, workout modifications, muscle targeting, and training techniques",
                "color": "orange",
            },
            "injury": {
                "name": "Recovery Advisor",
                "emoji": "🏥",
                "greeting": "Hello! I'm your Recovery Advisor.",
                "personality": "caring, cautious, and focused on safe recovery and injury prevention",
                "expertise": "injury prevention, recovery exercises, stretching, mobility work, and safe modifications",
                "color": "pink",
            },
            "hydration": {
                "name": "Hydration Coach",
                "emoji": "💧",
                "greeting": "Hey! I'm your Hydration Coach.",
                "personality": "refreshing, encouraging, and focused on optimal hydration",
                "expertise": "water intake tracking, hydration timing, electrolytes, and performance hydration",
                "color": "blue",
            },
        }
        return agents.get(agent_type, agents["coach"])

    def get_coach_system_prompt(self, context: str = "", intent: str = None, action_context: dict = None, agent_type: str = "coach") -> str:
        """
        Get the system prompt for the AI coach.

        MODIFY THIS to change the coach's personality/behavior.

        Args:
            context: Current context information
            intent: Detected intent for action acknowledgment
            action_context: Context for the action taken
            agent_type: Type of agent (coach, nutrition, workout, injury, hydration)
        """
        # Get agent-specific personality
        agent = self.get_agent_personality(agent_type)

        # Build action acknowledgment based on intent
        action_acknowledgment = ""
        if intent and action_context:
            if intent == "change_setting":
                setting = action_context.get("setting_name", "")
                value = action_context.get("setting_value", True)
                if setting == "dark_mode":
                    mode = "dark mode" if value else "light mode"
                    action_acknowledgment = f"\n\nACTION TAKEN: You have just switched the app to {mode}. Acknowledge this change naturally and confirm it's done."
            elif intent == "navigate":
                dest = action_context.get("destination", "")
                dest_names = {
                    "home": "home screen",
                    "library": "exercise library",
                    "profile": "profile",
                    "achievements": "achievements",
                    "hydration": "hydration tracker",
                    "nutrition": "nutrition tracker",
                    "summaries": "workout summaries"
                }
                dest_name = dest_names.get(dest, dest)
                action_acknowledgment = f"\n\nACTION TAKEN: You are navigating the user to {dest_name}. Acknowledge this naturally."
            elif intent == "start_workout":
                action_acknowledgment = "\n\nACTION TAKEN: You are starting the user's workout. Motivate them and wish them a great session!"
            elif intent == "complete_workout":
                action_acknowledgment = "\n\nACTION TAKEN: You have marked the user's workout as complete. Congratulate them on finishing!"
            elif intent == "log_hydration":
                amount = action_context.get("hydration_amount", 1)
                action_acknowledgment = f"\n\nACTION TAKEN: You have logged {amount} glass(es) of water for the user. Acknowledge this and encourage good hydration habits."

        # Agent-specific introduction
        agent_intro = f'''{agent["emoji"]} YOU ARE: {agent["name"]}
Your personality is {agent["personality"]}.
You specialize in {agent["expertise"]}.

When greeting users or introducing yourself, say something like: "{agent["greeting"]}"
'''

        return f'''{agent_intro}

You are an expert AI fitness coach. Your role is to:

1. Help users with their fitness journey
2. Modify workouts based on their needs instantly
3. Understand and remember injuries and adjust exercises accordingly
4. Be empathetic, supportive, and motivating
5. Respond naturally in conversation, never output raw JSON

APP CONTROL CAPABILITIES:
You CAN control the app! When users ask you to:
- Change to dark/light mode: You will change it automatically
- Navigate to screens (achievements, hydration, nutrition, etc.): You will navigate them there
- Start their workout: You will begin the workout session
- Complete/finish their workout: You will mark it as done
- Log water intake: You will track their hydration

Always acknowledge when you've taken an action. Don't say you can't do something if it's in your capabilities.
{action_acknowledgment}

CURRENT CONTEXT:
{context}

RESPONSE FORMAT:
- Always respond in natural, conversational language
- Be concise and actionable
- Show empathy and understanding
- When making workout changes, explain what you're doing and why
- Never output raw JSON or technical data to the user
- IMPORTANT: When mentioning workout dates, ALWAYS include the day of the week (e.g., "Friday, November 28th" or "this Friday (Nov 28)"), not just the raw date format

Remember: You're a supportive coach, not a robot. Be human, be helpful, be motivating!'''


# ============================================================================
# HORMONAL HEALTH PROMPTS
# Specialized prompts for hormone-supportive workout and nutrition recommendations
# ============================================================================

class HormonalHealthPrompts:
    """
    Prompts for hormonal health-aware AI coaching.

    Provides context-aware prompts for:
    - Menstrual cycle phase-based workout adjustments
    - Testosterone optimization recommendations
    - Estrogen balance support
    - PCOS and menopause-friendly modifications
    - Gender-specific exercise and nutrition guidance
    """

    @staticmethod
    def get_cycle_phase_prompt(phase: str) -> str:
        """Get coaching prompt for specific menstrual cycle phase."""
        phase_prompts = {
            "menstrual": """The user is in their MENSTRUAL phase (days 1-5):
- Energy levels are typically lower due to hormone dip
- Focus on gentle, restorative movements
- Recommend: yoga, walking, light stretching, swimming
- Avoid: high-intensity intervals, heavy lifting, inversions
- Nutrition focus: iron-rich foods (spinach, lentils), anti-inflammatory foods (turmeric, ginger)
- Be extra supportive and understanding about energy fluctuations
- Suggest reducing workout intensity by 20-30% if they're feeling fatigued""",

            "follicular": """The user is in their FOLLICULAR phase (days 6-13):
- Estrogen is rising, energy and mood typically improving
- Great time for challenging workouts and trying new exercises
- Recommend: strength training, HIIT, new skill work, group classes
- Can push harder and increase intensity
- Nutrition focus: light, fresh foods, fermented foods, lean proteins
- Encourage them to take on challenging goals and PR attempts
- Body can handle more stress and recover faster""",

            "ovulation": """The user is in their OVULATION phase (days 14-16):
- Peak energy and strength - estrogen and testosterone at highest
- Optimal time for personal records and competitions
- Recommend: high-intensity workouts, PR attempts, challenging exercises
- Social energy is high - great for group workouts
- Nutrition focus: fiber-rich foods, antioxidants, raw vegetables
- Encourage maximum effort and celebrate achievements
- Be aware of slightly increased injury risk due to ligament laxity""",

            "luteal": """The user is in their LUTEAL phase (days 17-28):
- Progesterone rises then both hormones drop, may experience PMS
- Focus on maintenance rather than PRs
- Recommend: moderate cardio, pilates, strength maintenance, recovery work
- Avoid: extreme endurance, new max attempts
- Nutrition focus: complex carbs (serotonin support), magnesium, B vitamins
- Be patient and understanding about mood fluctuations
- Body temperature is slightly elevated - may fatigue faster"""
        }
        return phase_prompts.get(phase.lower(), "")

    @staticmethod
    def get_hormone_goal_prompt(goal: str) -> str:
        """Get coaching prompt for specific hormone optimization goal."""
        goal_prompts = {
            "optimize_testosterone": """The user's goal is TESTOSTERONE OPTIMIZATION:
- Prioritize compound movements: squats, deadlifts, bench press, rows
- Recommend higher intensity with adequate rest (2-3 min between heavy sets)
- Include exercises that engage large muscle groups
- Suggest adequate sleep (7-9 hours) for hormone production
- Nutrition focus: zinc (oysters, beef), vitamin D, healthy fats, adequate protein
- Foods: eggs, tuna, pomegranate, garlic, ginger
- Avoid: excessive cardio, overtraining, alcohol
- Stress management is crucial for testosterone levels""",

            "balance_estrogen": """The user's goal is ESTROGEN BALANCE:
- Include a mix of strength and cardio for overall hormonal health
- Recommend exercises that support liver health (estrogen metabolism)
- Nutrition focus: cruciferous vegetables (broccoli, cauliflower, kale)
- Foods: flaxseeds (lignans), berries (antioxidants), turmeric
- Include fiber for healthy estrogen elimination
- Avoid: excessive alcohol, processed foods, environmental estrogens
- Stress reduction is important for hormonal balance""",

            "pcos_management": """The user has PCOS (Polycystic Ovary Syndrome):
- Prioritize insulin sensitivity: strength training + moderate cardio
- Recommend lower-intensity, consistent exercise over sporadic intense workouts
- Include resistance training 3-4x per week
- Nutrition focus: low glycemic foods, anti-inflammatory diet
- Foods: salmon (omega-3s), leafy greens, nuts, cinnamon, olive oil
- Avoid: refined carbs, sugar spikes, excessive high-intensity exercise
- Weight management through sustainable exercise is key
- Be supportive about symptoms like fatigue and mood changes""",

            "menopause_support": """The user is managing MENOPAUSE symptoms:
- Focus on bone health: weight-bearing exercises, resistance training
- Include exercises for balance and fall prevention
- Moderate intensity is usually better than high intensity
- Nutrition focus: phytoestrogens (moderate soy), calcium, vitamin D
- Foods: chickpeas, whole grains, leafy greens
- Be aware of hot flashes - suggest workout timing and cooling strategies
- Strength training helps with metabolism changes
- Include flexibility and mobility work for joint health""",

            "improve_fertility": """The user's goal is FERTILITY support:
- Moderate, consistent exercise is best - avoid overtraining
- Recommend stress-reducing activities: yoga, walking, swimming
- Avoid: excessive high-intensity exercise, very low body fat
- Nutrition focus: folate (spinach, citrus), antioxidants, omega-3s
- Foods: leafy greens, berries, fatty fish, sweet potatoes
- Adequate rest and recovery are essential
- Support overall hormonal balance without extreme measures""",

            "energy_optimization": """The user wants to OPTIMIZE ENERGY through hormonal support:
- Balance between strength training and recovery
- Include morning workouts when cortisol is naturally higher
- Nutrition focus: B vitamins, iron, adaptogens
- Foods: whole grains, lean proteins, leafy greens
- Prioritize sleep quality and consistent sleep schedule
- Manage stress through exercise without overtraining
- Include both active recovery and complete rest days""",

            "libido_enhancement": """The user wants to support healthy LIBIDO:
- Include strength training for testosterone/hormone support
- Cardiovascular health supports blood flow
- Nutrition focus: zinc, vitamin D, healthy fats, omega-3s
- Foods: oysters, dark chocolate, watermelon, nuts
- Stress reduction is crucial
- Adequate sleep for hormone production
- Avoid: overtraining, excessive alcohol, chronic stress"""
        }
        return goal_prompts.get(goal.lower(), "")

    @staticmethod
    def build_hormonal_context_prompt(
        hormonal_context: Dict,
        include_food_recommendations: bool = True
    ) -> str:
        """
        Build a comprehensive hormonal context prompt from user data.

        Args:
            hormonal_context: Dict with user's hormonal profile data
            include_food_recommendations: Whether to include food suggestions

        Returns:
            Formatted prompt string for AI context
        """
        prompts = []

        # Add cycle phase context if tracking
        if hormonal_context.get("cycle_phase"):
            phase_prompt = HormonalHealthPrompts.get_cycle_phase_prompt(
                hormonal_context["cycle_phase"]
            )
            if phase_prompt:
                prompts.append(phase_prompt)
                if hormonal_context.get("cycle_day"):
                    prompts.append(f"Current cycle day: {hormonal_context['cycle_day']}")

        # Add hormone goal contexts
        hormone_goals = hormonal_context.get("hormone_goals", [])
        for goal in hormone_goals:
            goal_prompt = HormonalHealthPrompts.get_hormone_goal_prompt(goal)
            if goal_prompt:
                prompts.append(goal_prompt)

        # Add symptom awareness if present
        symptoms = hormonal_context.get("symptoms", [])
        if symptoms:
            symptom_str = ", ".join(symptoms[:5])  # Limit to top 5
            prompts.append(
                f"User is currently experiencing: {symptom_str}. "
                f"Be mindful of these symptoms when making exercise recommendations."
            )

        # Add energy level context
        energy_level = hormonal_context.get("energy_level")
        if energy_level is not None:
            if energy_level <= 3:
                prompts.append(
                    "User reported LOW ENERGY today. Suggest lighter workouts, "
                    "shorter duration, or active recovery."
                )
            elif energy_level >= 8:
                prompts.append(
                    "User reported HIGH ENERGY today. They may be ready for a "
                    "challenging workout or PR attempt."
                )

        # Add kegel context if enabled
        if hormonal_context.get("kegels_enabled"):
            kegel_placement = []
            if hormonal_context.get("include_kegels_in_warmup"):
                kegel_placement.append("warmup")
            if hormonal_context.get("include_kegels_in_cooldown"):
                kegel_placement.append("cooldown")

            if kegel_placement:
                prompts.append(
                    f"User has pelvic floor exercises (kegels) enabled. "
                    f"Include them in: {', '.join(kegel_placement)}. "
                    f"Level: {hormonal_context.get('kegel_current_level', 'beginner')}."
                )

        # Add food context if enabled
        if include_food_recommendations and hormonal_context.get("hormonal_diet_enabled"):
            prompts.append(
                "User has hormone-supportive nutrition enabled. "
                "Include relevant food recommendations based on their hormonal goals."
            )

        return "\n\n".join(prompts) if prompts else ""

    @staticmethod
    def get_hormonal_food_prompt(
        hormone_goals: List[str],
        cycle_phase: Optional[str] = None,
        dietary_restrictions: Optional[List[str]] = None
    ) -> str:
        """
        Get AI prompt for hormone-supportive food recommendations.

        Args:
            hormone_goals: List of hormone optimization goals
            cycle_phase: Current menstrual cycle phase (if tracking)
            dietary_restrictions: User's dietary restrictions

        Returns:
            Formatted prompt for food recommendations
        """
        prompt_parts = [
            "Suggest hormone-supportive foods based on the following context:",
            ""
        ]

        if hormone_goals:
            prompt_parts.append(f"Hormone Goals: {', '.join(hormone_goals)}")

        if cycle_phase:
            prompt_parts.append(f"Current Cycle Phase: {cycle_phase}")

        if dietary_restrictions:
            prompt_parts.append(f"Dietary Restrictions: {', '.join(dietary_restrictions)}")

        prompt_parts.extend([
            "",
            "Provide specific food recommendations that:",
            "1. Support the user's hormone optimization goals",
            "2. Are appropriate for their current cycle phase (if applicable)",
            "3. Respect their dietary restrictions",
            "4. Include practical meal and snack ideas",
            "5. Explain WHY each food supports their hormonal health"
        ])

        return "\n".join(prompt_parts)

    @staticmethod
    def get_kegel_coaching_prompt(
        level: str = "beginner",
        focus_area: str = "general"
    ) -> str:
        """Get coaching prompt for kegel/pelvic floor exercises."""
        focus_descriptions = {
            "general": "balanced pelvic floor strengthening",
            "male_specific": "male pelvic floor anatomy, prostate support, and urinary control",
            "female_specific": "female pelvic floor anatomy, vaginal health, and bladder control",
            "postpartum": "gentle postpartum pelvic floor recovery",
            "prostate_health": "prostate health and urinary function support"
        }

        return f"""When discussing pelvic floor exercises with this user:
- Their current level is: {level}
- Their focus area is: {focus_descriptions.get(focus_area, focus_area)}

Key coaching points for {level} level:
{'- Start with basic holds (5-10 seconds)' if level == 'beginner' else ''}
{'- Focus on mind-muscle connection' if level == 'beginner' else ''}
{'- Progress to longer holds and more reps' if level == 'intermediate' else ''}
{'- Include quick flick exercises' if level == 'intermediate' else ''}
{'- Advanced holds with functional integration' if level == 'advanced' else ''}
{'- Combine with breath work and core exercises' if level == 'advanced' else ''}

Be encouraging and normalize pelvic floor health as an important part of overall fitness."""


# Backward compatibility alias
OpenAIService = GeminiService


# Singleton instance for services that need it
_gemini_service_instance: Optional[GeminiService] = None


def get_gemini_service() -> GeminiService:
    """Get or create singleton GeminiService instance."""
    global _gemini_service_instance
    if _gemini_service_instance is None:
        _gemini_service_instance = GeminiService()
    return _gemini_service_instance


# Module-level singleton for backward compatibility
gemini_service = GeminiService()
