"""
Async circuit breaker for database calls (Zealova — Phase D DB-RESILIENCE).

When the database (Supabase / Supavisor) goes down or slows to a crawl, every
incoming request otherwise piles up on the dead downstream — each one waiting
out its own timeout. That turns a downstream blip into a backend-wide stall.

This breaker fails fast instead. After a run of consecutive failures it OPENs:
subsequent calls are rejected immediately (HTTP 503) for a cooldown window,
giving the downstream room to recover. After the cooldown a single probe is
allowed through (HALF-OPEN); success closes the breaker, failure re-opens it.

States:
    CLOSED    — normal operation, calls flow through, failures are counted.
    OPEN      — fail fast immediately; no calls reach the DB until cooldown ends.
    HALF_OPEN — one probe call allowed through to test recovery.

The breaker is async-safe: all state transitions happen under an asyncio.Lock,
so it is correct under high concurrency on a single event loop.
"""
from contextlib import asynccontextmanager
from enum import Enum
from typing import Optional
import asyncio
import logging
import time

from fastapi import HTTPException

logger = logging.getLogger(__name__)

# ── Tunable thresholds (sane defaults) ──────────────────────────────────────
# Consecutive failures in CLOSED state before the breaker trips to OPEN.
FAILURE_THRESHOLD = 5
# Seconds to stay OPEN (fail-fast everything) before allowing a probe.
COOLDOWN_SECONDS = 15.0
# Consecutive successes required while HALF_OPEN to fully close again.
HALF_OPEN_SUCCESS_THRESHOLD = 1
# Retry-After header value (seconds) sent on a breaker-open 503.
RETRY_AFTER_SECONDS = 15


class CircuitState(str, Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreakerOpenError(HTTPException):
    """503 raised when the breaker is OPEN — clean, FastAPI-friendly."""

    def __init__(self, retry_after: int = RETRY_AFTER_SECONDS):
        super().__init__(
            status_code=503,
            detail="Database temporarily unavailable (circuit breaker open). Retry shortly.",
            headers={"Retry-After": str(retry_after)},
        )


class AsyncCircuitBreaker:
    """A simple async, thread/event-loop-safe circuit breaker.

    Usage as a context manager:

        async with db_breaker.guard():
            ... do DB work ...

    Failures are anything that raises out of the guarded block EXCEPT
    HTTPException (those are deliberate app-level responses, not downstream
    faults — counting them would trip the breaker on ordinary 4xx flows).
    """

    def __init__(
        self,
        name: str = "db",
        failure_threshold: int = FAILURE_THRESHOLD,
        cooldown_seconds: float = COOLDOWN_SECONDS,
        half_open_success_threshold: int = HALF_OPEN_SUCCESS_THRESHOLD,
        retry_after_seconds: int = RETRY_AFTER_SECONDS,
    ):
        self.name = name
        self._failure_threshold = failure_threshold
        self._cooldown_seconds = cooldown_seconds
        self._half_open_success_threshold = half_open_success_threshold
        self._retry_after_seconds = retry_after_seconds

        self._state = CircuitState.CLOSED
        self._consecutive_failures = 0
        self._half_open_successes = 0
        self._opened_at: float = 0.0
        # Only one probe allowed through in HALF_OPEN.
        self._probe_in_flight = False
        self._lock = asyncio.Lock()

    @property
    def state(self) -> CircuitState:
        return self._state

    async def _allow_call(self) -> None:
        """Decide whether a call may proceed; raise 503 if the breaker blocks it.

        Mutates state for the OPEN→HALF_OPEN transition. Runs under the lock.
        """
        if self._state == CircuitState.CLOSED:
            return

        if self._state == CircuitState.OPEN:
            elapsed = time.monotonic() - self._opened_at
            if elapsed < self._cooldown_seconds:
                # Still cooling down — fail fast.
                raise CircuitBreakerOpenError(self._retry_after_seconds)
            # Cooldown elapsed → move to HALF_OPEN and let THIS call probe.
            self._state = CircuitState.HALF_OPEN
            self._half_open_successes = 0
            self._probe_in_flight = True
            logger.warning("⚠️ [CircuitBreaker:%s] cooldown elapsed → HALF_OPEN (probing)", self.name)
            return

        # HALF_OPEN: allow only a single probe; reject the rest fast.
        if self._probe_in_flight:
            raise CircuitBreakerOpenError(self._retry_after_seconds)
        self._probe_in_flight = True

    async def _on_success(self) -> None:
        async with self._lock:
            if self._state == CircuitState.HALF_OPEN:
                self._half_open_successes += 1
                self._probe_in_flight = False
                if self._half_open_successes >= self._half_open_success_threshold:
                    self._state = CircuitState.CLOSED
                    self._consecutive_failures = 0
                    self._half_open_successes = 0
                    logger.info("✅ [CircuitBreaker:%s] probe succeeded → CLOSED", self.name)
            elif self._state == CircuitState.CLOSED:
                # Healthy path — reset any partial failure streak.
                self._consecutive_failures = 0

    async def _on_failure(self) -> None:
        async with self._lock:
            if self._state == CircuitState.HALF_OPEN:
                # Probe failed — re-open immediately for another cooldown.
                self._state = CircuitState.OPEN
                self._opened_at = time.monotonic()
                self._probe_in_flight = False
                logger.warning("❌ [CircuitBreaker:%s] probe failed → OPEN", self.name)
                return

            self._consecutive_failures += 1
            if (
                self._state == CircuitState.CLOSED
                and self._consecutive_failures >= self._failure_threshold
            ):
                self._state = CircuitState.OPEN
                self._opened_at = time.monotonic()
                logger.error(
                    "❌ [CircuitBreaker:%s] %d consecutive DB failures → OPEN for %.0fs",
                    self.name, self._consecutive_failures, self._cooldown_seconds,
                )

    @asynccontextmanager
    async def guard(self):
        """Async context manager wrapping a DB-call path.

        Fails fast with 503 when OPEN. Counts downstream faults; HTTPExceptions
        raised inside the block are treated as deliberate app responses and do
        NOT count as failures (and do not trip the breaker).
        """
        async with self._lock:
            await self._allow_call()
        try:
            yield
        except HTTPException:
            # Deliberate app-level response (incl. our own 503s) — not a
            # downstream fault. Release the probe slot but don't penalize.
            async with self._lock:
                if self._state == CircuitState.HALF_OPEN:
                    self._probe_in_flight = False
            raise
        except BaseException:
            # Any real error/timeout from the DB path counts against us.
            await self._on_failure()
            raise
        else:
            await self._on_success()


# Process-wide breaker shared by all DB calls.
_db_breaker: Optional[AsyncCircuitBreaker] = None


def get_db_breaker() -> AsyncCircuitBreaker:
    """Get the global DB circuit breaker (lazy singleton)."""
    global _db_breaker
    if _db_breaker is None:
        _db_breaker = AsyncCircuitBreaker(name="db")
    return _db_breaker
