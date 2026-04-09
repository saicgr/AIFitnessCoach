"""
Gemini Service Constants - Module-level caches, cost tracking, and shared state.
"""
from google import genai
from core.gemini_client import get_genai_client
from google.genai import types
from typing import Dict, Optional
import asyncio
import logging
import random
import time

from core.config import get_settings
from core.redis_cache import RedisCache

# Keep ResponseCache as an alias for backwards compatibility (used by smart_search.py)
ResponseCache = RedisCache

# Concurrency limiter for Gemini API calls - per-user fairness + global cap
from services.fair_semaphore import FairGeminiSemaphore
_gemini_semaphore = FairGeminiSemaphore(global_limit=10, per_user_limit=3)

# Module-level caches with purpose-tuned TTLs and sizes
_summary_cache = RedisCache(prefix="summary", ttl_seconds=3600, max_size=50)
_intent_cache = RedisCache(prefix="intent", ttl_seconds=600, max_size=100)
_food_text_cache = RedisCache(prefix="food_text", ttl_seconds=1800, max_size=75)
_embedding_cache = RedisCache(prefix="embedding", ttl_seconds=3600, max_size=50)

# Token usage logger for cost tracking
_token_logger = logging.getLogger("token_usage")

settings = get_settings()
logger = logging.getLogger("gemini")

# Initialize the Gemini client
client = get_genai_client()


# ===========================================================================
# In-Memory Cost Tracker for Vertex AI spend visibility
# ===========================================================================

class _CostTracker:
    """Accumulates Vertex AI token usage and estimated costs in-memory.

    Vertex AI pricing (Gemini Flash as of 2025):
        Input:          $0.10 / 1M tokens
        Output:         $0.40 / 1M tokens
        Cached input:   $0.025 / 1M tokens
        Cache storage:  $1.00 / 1M tokens / hour
    """

    # Pricing per token
    INPUT_RATE = 0.10 / 1_000_000
    OUTPUT_RATE = 0.40 / 1_000_000
    CACHED_INPUT_RATE = 0.025 / 1_000_000
    CACHE_STORAGE_RATE = 1.00 / 1_000_000  # per hour

    _MAX_USERS = 500

    def __init__(self):
        self._start_time = time.time()
        # Per-method stats: {method: {calls, input_tokens, output_tokens, cached_tokens, cost_usd}}
        self._by_method: Dict[str, Dict] = {}
        # Per-user stats: {user_id: {calls, total_tokens, cost_usd}}
        self._by_user: Dict[str, Dict] = {}
        # Active caches: {cache_name: {tokens, created_at_ts, prefix}}
        self._active_caches: Dict[str, Dict] = {}

    def _evict_users_if_needed(self) -> None:
        """Evict lowest-cost users when dict exceeds max size."""
        if len(self._by_user) <= self._MAX_USERS:
            return
        sorted_users = sorted(self._by_user.items(), key=lambda x: x[1]["cost_usd"])
        evict_count = len(self._by_user) - (self._MAX_USERS // 2)
        for uid, _ in sorted_users[:evict_count]:
            del self._by_user[uid]

    def record(self, method: str, user_id: str, input_tokens: int, output_tokens: int, cached_tokens: int) -> None:
        """Record a single Gemini API call."""
        billable_input = input_tokens - cached_tokens
        cost = (
            billable_input * self.INPUT_RATE
            + output_tokens * self.OUTPUT_RATE
            + cached_tokens * self.CACHED_INPUT_RATE
        )

        m = self._by_method.setdefault(method, {"calls": 0, "input_tokens": 0, "output_tokens": 0, "cached_tokens": 0, "cost_usd": 0.0})
        m["calls"] += 1
        m["input_tokens"] += input_tokens
        m["output_tokens"] += output_tokens
        m["cached_tokens"] += cached_tokens
        m["cost_usd"] += cost

        u = self._by_user.setdefault(user_id, {"calls": 0, "total_tokens": 0, "cost_usd": 0.0})
        u["calls"] += 1
        u["total_tokens"] += input_tokens + output_tokens
        u["cost_usd"] += cost

        self._evict_users_if_needed()

    def track_cache(self, cache_name: str, prefix: str, token_count: int) -> None:
        """Track an active Vertex AI cache for storage cost computation."""
        self._active_caches[cache_name] = {
            "tokens": token_count,
            "created_at_ts": time.time(),
            "prefix": prefix,
        }

    def remove_cache(self, cache_name: str) -> None:
        """Remove a cache from tracking (e.g. after deletion)."""
        self._active_caches.pop(cache_name, None)

    def snapshot(self) -> Dict:
        """Return a full cost snapshot for the debug endpoint."""
        now = time.time()
        uptime_hours = (now - self._start_time) / 3600

        cache_storage_cost = 0.0
        active_caches_info = {}
        for name, info in self._active_caches.items():
            age_hours = (now - info["created_at_ts"]) / 3600
            hourly_cost = info["tokens"] * self.CACHE_STORAGE_RATE
            storage_cost = hourly_cost * age_hours
            cache_storage_cost += storage_cost
            active_caches_info[name] = {
                "prefix": info["prefix"],
                "tokens_stored": info["tokens"],
                "age_hours": round(age_hours, 2),
                "hourly_storage_cost_usd": round(hourly_cost, 6),
                "total_storage_cost_usd": round(storage_cost, 6),
            }

        total_api_cost = sum(m["cost_usd"] for m in self._by_method.values())

        return {
            "uptime_hours": round(uptime_hours, 2),
            "total_estimated_cost_usd": round(total_api_cost + cache_storage_cost, 6),
            "api_cost_usd": round(total_api_cost, 6),
            "cache_storage_cost_usd": round(cache_storage_cost, 6),
            "by_method": {
                k: {**v, "cost_usd": round(v["cost_usd"], 6)}
                for k, v in sorted(self._by_method.items(), key=lambda x: x[1]["cost_usd"], reverse=True)
            },
            "by_user": {
                k: {**v, "cost_usd": round(v["cost_usd"], 6)}
                for k, v in sorted(self._by_user.items(), key=lambda x: x[1]["cost_usd"], reverse=True)
            },
            "active_caches": active_caches_info,
        }


# Singleton tracker - importable by health.py
cost_tracker = _CostTracker()


def _is_transient_gemini_error(e: Exception) -> bool:
    """Check if a Gemini API error is transient and worth retrying."""
    error_str = str(e).lower()
    return any(kw in error_str for kw in [
        "429", "resource_exhausted", "503", "rate limit",
        "timeout", "unavailable", "deadline exceeded",
    ])


async def gemini_generate_with_retry(
    *,
    model: str,
    contents,
    config,
    user_id: Optional[str] = None,
    max_retries: int = 3,
    timeout: Optional[float] = None,
    method_name: str = "unknown",
):
    """Gemini API call with semaphore concurrency control + exponential backoff retry for transient errors.

    Args:
        model: Gemini model name.
        contents: Prompt contents.
        config: GenerateContentConfig.
        user_id: User ID for per-user semaphore fairness (None = global-only).
        max_retries: Max retry attempts for transient errors.
        timeout: Optional timeout in seconds for each attempt.
        method_name: Name for logging/cost tracking.

    Returns:
        Gemini API response.

    Raises:
        The original exception after all retries are exhausted, or immediately for non-transient errors.
    """
    delays = [2.0, 5.0, 10.0]
    for attempt in range(max_retries + 1):
        try:
            async with _gemini_semaphore(user_id=user_id):
                if timeout:
                    response = await asyncio.wait_for(
                        client.aio.models.generate_content(
                            model=model, contents=contents, config=config,
                        ),
                        timeout=timeout,
                    )
                else:
                    response = await client.aio.models.generate_content(
                        model=model, contents=contents, config=config,
                    )
            _log_token_usage(response, method_name, user_id or "system")
            return response
        except Exception as e:
            if _is_transient_gemini_error(e) and attempt < max_retries:
                delay = delays[min(attempt, len(delays) - 1)] + random.uniform(0, 1)
                logger.warning(
                    f"[{method_name}] Attempt {attempt + 1}/{max_retries + 1} failed (transient), "
                    f"retrying in {delay:.1f}s: {e}"
                )
                await asyncio.sleep(delay)
                continue
            raise


def gemini_generate_with_retry_sync(
    *,
    model: str,
    contents,
    config,
    max_retries: int = 3,
    timeout: Optional[float] = None,
    method_name: str = "unknown",
):
    """Synchronous Gemini API call with retry for transient errors (no semaphore).

    Use for sync call sites that cannot be easily converted to async.
    """
    delays = [2.0, 5.0, 10.0]
    for attempt in range(max_retries + 1):
        try:
            if timeout:
                import signal

                def _timeout_handler(signum, frame):
                    raise TimeoutError(f"Gemini sync call timed out after {timeout}s")

                old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
                signal.alarm(int(timeout))
                try:
                    response = client.models.generate_content(
                        model=model, contents=contents, config=config,
                    )
                finally:
                    signal.alarm(0)
                    signal.signal(signal.SIGALRM, old_handler)
            else:
                response = client.models.generate_content(
                    model=model, contents=contents, config=config,
                )
            _log_token_usage(response, method_name)
            return response
        except Exception as e:
            if _is_transient_gemini_error(e) and attempt < max_retries:
                delay = delays[min(attempt, len(delays) - 1)] + random.uniform(0, 1)
                logger.warning(
                    f"[{method_name}] Sync attempt {attempt + 1}/{max_retries + 1} failed (transient), "
                    f"retrying in {delay:.1f}s: {e}"
                )
                time.sleep(delay)
                continue
            raise


def _log_token_usage(response, method_name: str, user_id: str = "unknown") -> None:
    """Log token usage from a Gemini API response for cost tracking."""
    try:
        if response is None:
            return
        usage = getattr(response, 'usage_metadata', None)
        if usage is None:
            return
        input_tokens = getattr(usage, 'prompt_token_count', 0) or 0
        output_tokens = getattr(usage, 'candidates_token_count', 0) or 0
        cached_tokens = getattr(usage, 'cached_content_token_count', 0) or 0
        _token_logger.info(
            f"[Tokens] user={user_id} method={method_name} "
            f"in={input_tokens} out={output_tokens} cached={cached_tokens}"
        )
        cost_tracker.record(method_name, user_id, input_tokens, output_tokens, cached_tokens)
    except Exception:
        pass  # Never let logging break a request
