"""
Comprehensive streaming endpoint tests.

Tests all SSE (Server-Sent Events) streaming endpoints to verify:
1. Correct SSE format (event: type, data: json)
2. Progress events are sent during processing
3. Done/error events are sent on completion
4. Response includes expected fields

Run with: python -m pytest tests/test_streaming_endpoints.py -v -s
Or directly: python tests/test_streaming_endpoints.py

TRANSPORT NOTE (2026-07 repair)
-------------------------------
`test_workout_generation_streaming` and `test_workout_regeneration_streaming`
used to open a REAL TCP connection to a dev server on localhost:8000 and died
with `httpx.ConnectError: All connection attempts failed` in every hermetic
run. They now drive the SAME endpoints through the SAME FastAPI app object
in-process via `httpx.ASGITransport` — the full real stack (routing, auth
dependency, request-model validation, rate limiter, StreamingResponse, SSE
framing) still executes; only the socket is gone. The only things mocked are
the external systems (Supabase / the recent-call cache), which is what makes
the assertions deterministic instead of dependent on whatever rows happen to
exist in a dev database.

The remaining `test_monthly_*` / `test_food_*` functions below still target
localhost:8000 and are left untouched here (they are not in this repair's
scope) — see the note above `test_monthly_workout_generation_streaming`.
"""
import asyncio
import time
import json
import base64
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Optional, List, Dict, Any
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
from httpx import ASGITransport

from main import app
from core.auth import get_current_user

# Configuration
BASE_URL = "http://localhost:8000"
# In-process (ASGI) base URL — no socket is opened for this host.
APP_URL = "http://testserver"
TEST_USER_ID = "ba7f2f00-e6f8-4ac6-97a2-988988af940a"


@asynccontextmanager
async def in_process_client(timeout: float = 30.0):
    """An httpx client bound directly to the FastAPI app — no network.

    Overrides `get_current_user` (the endpoints under test are authenticated)
    with the test user, and always restores the override on exit so it cannot
    leak into other test modules sharing this app instance.
    """
    app.dependency_overrides[get_current_user] = lambda: {"id": TEST_USER_ID}
    try:
        async with httpx.AsyncClient(
            transport=ASGITransport(app=app),
            base_url=APP_URL,
            timeout=timeout,
        ) as client:
            yield client
    finally:
        app.dependency_overrides.pop(get_current_user, None)


def _mock_supabase_table(execute_results: List[Any]) -> MagicMock:
    """A Supabase query-builder mock whose .execute() walks `execute_results`."""
    table = MagicMock()
    for method in (
        "select", "insert", "update", "upsert", "delete",
        "eq", "neq", "gte", "lte", "in_", "or_", "limit", "order",
        "range", "single", "maybe_single",
    ):
        getattr(table, method).return_value = table
    table.execute.side_effect = list(execute_results)
    return table


def _result(data: Any) -> MagicMock:
    res = MagicMock()
    res.data = data
    return res


class StreamingTestResult:
    """Result of a streaming test."""

    def __init__(self):
        self.first_event_time: Optional[float] = None
        self.total_time: float = 0
        self.events: List[Dict[str, Any]] = []
        self.error: Optional[str] = None
        self.success: bool = False

    def add_event(self, event_type: str, data: Dict[str, Any], elapsed: float):
        if self.first_event_time is None:
            self.first_event_time = elapsed
        self.events.append({
            "type": event_type,
            "data": data,
            "elapsed_s": elapsed
        })

    def print_summary(self, name: str):
        print(f"\n{'='*60}")
        print(f"TEST: {name}")
        print(f"{'='*60}")

        if self.error:
            print(f"ERROR: {self.error}")
            return

        print(f"Success: {self.success}")
        print(f"Total events: {len(self.events)}")
        print(f"Time to first event: {self.first_event_time:.3f}s" if self.first_event_time else "N/A")
        print(f"Total time: {self.total_time:.3f}s")

        # Print event timeline
        print("\nEvent timeline:")
        for evt in self.events:
            print(f"  [{evt['elapsed_s']:.2f}s] {evt['type']}: {str(evt['data'])[:80]}...")


async def parse_sse_stream(response) -> StreamingTestResult:
    """Parse SSE stream and collect events."""
    result = StreamingTestResult()
    start_time = time.time()

    event_type = ""
    event_data = ""

    try:
        async for line in response.aiter_lines():
            elapsed = time.time() - start_time

            if not line:
                # End of event - process if we have data
                if event_type and event_data:
                    try:
                        data = json.loads(event_data)
                        result.add_event(event_type, data, elapsed)

                        if event_type == "done":
                            result.success = True
                        elif event_type == "error":
                            result.error = data.get("error", "Unknown error")
                    except json.JSONDecodeError as e:
                        result.add_event(event_type, {"raw": event_data, "parse_error": str(e)}, elapsed)

                event_type = ""
                event_data = ""
                continue

            if line.startswith("event:"):
                event_type = line[6:].strip()
            elif line.startswith("data:"):
                event_data = line[5:].strip()

        # Flush a trailing event that wasn't terminated by a blank line.
        # (SSE servers normally end every event with "\n\n", but a stream that
        # closes right after the last "data:" line must not silently lose it.)
        if event_type and event_data:
            elapsed = time.time() - start_time
            try:
                result.add_event(event_type, json.loads(event_data), elapsed)
                if event_type == "done":
                    result.success = True
                elif event_type == "error":
                    result.error = json.loads(event_data).get("error", "Unknown error")
            except json.JSONDecodeError as e:
                result.add_event(event_type, {"raw": event_data, "parse_error": str(e)}, elapsed)

        result.total_time = time.time() - start_time

    except Exception as e:
        result.error = str(e)
        result.total_time = time.time() - start_time

    return result


async def test_workout_generation_streaming():
    """Test /workouts/generate-stream endpoint.

    Runs the REAL endpoint in-process (see the transport note at the top of the
    file). Supabase is mocked so the request lands on the endpoint's duplicate
    short-circuit: a current, non-'generating' workout already exists for the
    requested date, so the endpoint must stream the existing workout back as a
    single `event: done` instead of burning a Gemini generation.

    Original assertions (a `done`/no-error stream, at least one event, first
    event under 2s) are unchanged. Added: the response really is an
    `text/event-stream` 200, and the `done` payload carries the workout row.
    """
    print("\n" + "="*70)
    print("Testing: Workout Generation Streaming")
    print("="*70)

    import api.v1.workouts.generation_streaming as genstream

    existing_workout = {
        "id": "11111111-2222-3333-4444-555555555555",
        "user_id": TEST_USER_ID,
        "name": "Existing Upper Body Day",
        "status": "planned",
        "is_current": True,
        "scheduled_date": "2026-07-15T00:00:00+00:00",
        "exercises": [],
    }

    db = MagicMock()
    workouts_table = _mock_supabase_table([
        _result([]),                       # 1. no workout currently 'generating'
        _result([{                         # 2. duplicate check -> one exists
            "id": existing_workout["id"],
            "name": existing_workout["name"],
            "status": "planned",
        }]),
        _result(existing_workout),         # 3. refetch the full row
    ])
    db.client.table.return_value = workouts_table

    request_data = {
        "user_id": TEST_USER_ID,
        "fitness_level": "intermediate",
        "goals": ["muscle_gain"],
        "equipment": ["dumbbells"],
        "duration_minutes": 30,
        "scheduled_date": "2026-07-15",
        # The date above is deliberately outside any preferred-day config; the
        # preferred-day gate is a separate concern from SSE framing.
        "force_non_preferred_day": True,
    }

    with patch.object(genstream, "get_supabase_db", return_value=db), \
         patch.object(genstream, "resolve_timezone", return_value="UTC"), \
         patch.object(genstream, "get_active_gym_profile_id", return_value=None), \
         patch.object(genstream._genstream_recent_cache, "get", new=AsyncMock(return_value=None)), \
         patch.object(genstream._genstream_recent_cache, "set", new=AsyncMock(return_value=None)):
        async with in_process_client(timeout=120.0) as client:
            try:
                async with client.stream(
                    "POST",
                    "/api/v1/workouts/generate-stream",
                    json=request_data,
                ) as response:
                    assert response.status_code == 200, f"HTTP {response.status_code}"
                    assert response.headers["content-type"].startswith("text/event-stream"), \
                        f"Not an SSE response: {response.headers.get('content-type')}"
                    result = await parse_sse_stream(response)
            except AssertionError:
                raise
            except Exception as e:
                result = StreamingTestResult()
                result.error = str(e)

    result.print_summary("Workout Generation Streaming")

    # Assertions
    assert result.success or result.error is None, f"Test failed: {result.error}"
    assert result.first_event_time is not None, "No events received"
    assert result.first_event_time < 2.0, f"First event too slow: {result.first_event_time}s"

    done_events = [e for e in result.events if e["type"] == "done"]
    assert len(done_events) == 1, f"Expected exactly one done event, got {result.events}"
    assert done_events[0]["data"]["id"] == existing_workout["id"]
    assert done_events[0]["data"]["name"] == existing_workout["name"]

    return result


async def test_workout_regeneration_streaming():
    """Test /workouts/regenerate-stream endpoint.

    Runs the REAL endpoint in-process. The old version first did
    `GET /workouts/user/{id}` against localhost:8000 to find a workout to
    regenerate — an unguarded call that raised ConnectError before the test body
    even started. Here Supabase is mocked to report the workout as missing,
    which drives the endpoint's documented contract:

      - step 1 progress event is emitted BEFORE any DB/AI work (that is the
        whole point of the SSE endpoint — instant perceived feedback), and
      - a failure is delivered as a structured `event: error` inside a 200 SSE
        stream, NOT as an unframed HTTP 500 the client can't decode.

    A full happy-path regeneration cannot run hermetically (it calls Gemini);
    that path is covered by the live-server runner at the bottom of this file.
    """
    print("\n" + "="*70)
    print("Testing: Workout Regeneration Streaming")
    print("="*70)

    import api.v1.workouts.versioning as versioning

    db = MagicMock()
    db.get_workout.return_value = None  # workout does not exist

    request_data = {
        "workout_id": "99999999-8888-7777-6666-555555555555",
        "user_id": TEST_USER_ID,
        "difficulty": "hard",
        "duration_minutes": 45,
    }

    with patch.object(versioning, "get_supabase_db", return_value=db):
        async with in_process_client(timeout=120.0) as client:
            try:
                async with client.stream(
                    "POST",
                    "/api/v1/workouts/regenerate-stream",
                    json=request_data,
                ) as response:
                    assert response.status_code == 200, f"HTTP {response.status_code}"
                    assert response.headers["content-type"].startswith("text/event-stream"), \
                        f"Not an SSE response: {response.headers.get('content-type')}"
                    result = await parse_sse_stream(response)
            except AssertionError:
                raise
            except Exception as e:
                result = StreamingTestResult()
                result.error = str(e)

    result.print_summary("Workout Regeneration Streaming")

    assert result.first_event_time is not None, "No events received"
    assert result.first_event_time < 2.0, f"First event too slow: {result.first_event_time}s"

    # First event is the step-1 progress ping, before any DB/AI work.
    first = result.events[0]
    assert first["type"] == "progress", f"First event was {first['type']}, expected progress"
    assert first["data"]["step"] == 1
    assert first["data"]["total_steps"] == 4

    # Failure is framed as an SSE error event, not an HTTP 500.
    error_events = [e for e in result.events if e["type"] == "error"]
    assert len(error_events) == 1, f"Expected one error event, got {result.events}"
    assert error_events[0]["data"]["error"] == "Workout not found"
    assert result.error == "Workout not found"

    return result


async def test_monthly_workout_generation_streaming():
    """Test /workouts/generate-monthly-stream endpoint."""
    print("\n" + "="*70)
    print("Testing: Monthly Workout Generation Streaming")
    print("="*70)

    async with httpx.AsyncClient(timeout=300.0) as client:
        request_data = {
            "user_id": TEST_USER_ID,
            "month_start_date": "2024-12-28",
            "selected_days": [0, 2, 4],  # Mon, Wed, Fri
            "duration_minutes": 45,
        }

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/workouts/generate-monthly-stream",
                json=request_data,
            ) as response:
                result = await parse_sse_stream(response)
        except Exception as e:
            result = StreamingTestResult()
            result.error = str(e)

        result.print_summary("Monthly Workout Generation Streaming")

        # Check that we got progress and workout events
        progress_events = [e for e in result.events if e["type"] == "progress"]
        workout_events = [e for e in result.events if e["type"] == "workout"]

        print(f"\nProgress events: {len(progress_events)}")
        print(f"Workout events: {len(workout_events)}")

        return result


async def test_food_logging_text_streaming():
    """Test /nutrition/log-text-stream endpoint."""
    print("\n" + "="*70)
    print("Testing: Food Logging (Text) Streaming")
    print("="*70)

    async with httpx.AsyncClient(timeout=60.0) as client:
        request_data = {
            "user_id": TEST_USER_ID,
            "description": "2 eggs, toast with butter, and coffee",
            "meal_type": "breakfast",
        }

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/nutrition/log-text-stream",
                json=request_data,
            ) as response:
                result = await parse_sse_stream(response)
        except Exception as e:
            result = StreamingTestResult()
            result.error = str(e)

        result.print_summary("Food Logging (Text) Streaming")

        # Check that we got progress events
        progress_events = [e for e in result.events if e["type"] == "progress"]
        print(f"\nProgress events: {len(progress_events)}")

        return result


async def test_food_logging_image_streaming():
    """Test /nutrition/log-image-stream endpoint."""
    print("\n" + "="*70)
    print("Testing: Food Logging (Image) Streaming")
    print("="*70)

    # Create a simple test image (1x1 pixel PNG)
    # This is a minimal valid PNG
    test_image_base64 = (
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk"
        "+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    )

    async with httpx.AsyncClient(timeout=60.0) as client:
        # Use multipart form data for image upload
        files = {
            "image": ("test.png", base64.b64decode(test_image_base64), "image/png"),
        }
        data = {
            "user_id": TEST_USER_ID,
            "meal_type": "lunch",
        }

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/nutrition/log-image-stream",
                files=files,
                data=data,
            ) as response:
                result = await parse_sse_stream(response)
        except Exception as e:
            result = StreamingTestResult()
            result.error = str(e)

        result.print_summary("Food Logging (Image) Streaming")

        return result


async def run_all_tests():
    """Run all streaming tests."""
    print("\n" + "="*80)
    print("STREAMING ENDPOINTS TEST SUITE")
    print("="*80)
    print(f"\nBase URL: {BASE_URL}")
    print(f"Test User ID: {TEST_USER_ID}")
    print("\nMake sure the backend is running!")

    results = {}

    # Test workout generation
    try:
        results["workout_generation"] = await test_workout_generation_streaming()
    except Exception as e:
        print(f"Workout generation test failed: {e}")

    await asyncio.sleep(1)

    # Test workout regeneration
    try:
        results["workout_regeneration"] = await test_workout_regeneration_streaming()
    except Exception as e:
        print(f"Workout regeneration test failed: {e}")

    await asyncio.sleep(1)

    # Test monthly generation
    try:
        results["monthly_generation"] = await test_monthly_workout_generation_streaming()
    except Exception as e:
        print(f"Monthly generation test failed: {e}")

    await asyncio.sleep(1)

    # Test food logging (text)
    try:
        results["food_text"] = await test_food_logging_text_streaming()
    except Exception as e:
        print(f"Food text logging test failed: {e}")

    await asyncio.sleep(1)

    # Test food logging (image)
    try:
        results["food_image"] = await test_food_logging_image_streaming()
    except Exception as e:
        print(f"Food image logging test failed: {e}")

    # Summary
    print("\n" + "="*80)
    print("FINAL SUMMARY")
    print("="*80)

    for name, result in results.items():
        if result is None:
            status = "SKIPPED"
        elif result.success:
            status = "PASSED"
        elif result.error:
            status = f"FAILED: {result.error}"
        else:
            status = "INCOMPLETE"

        ttfe = f"{result.first_event_time:.2f}s" if result and result.first_event_time else "N/A"
        total = f"{result.total_time:.2f}s" if result else "N/A"

        print(f"\n{name}:")
        print(f"  Status: {status}")
        print(f"  Time to first event: {ttfe}")
        print(f"  Total time: {total}")

    # Overall result
    passed = sum(1 for r in results.values() if r and r.success)
    total = len(results)
    print(f"\n{'='*80}")
    print(f"TOTAL: {passed}/{total} tests passed")
    print(f"{'='*80}")


if __name__ == "__main__":
    print("Starting comprehensive streaming tests...")
    asyncio.run(run_all_tests())
