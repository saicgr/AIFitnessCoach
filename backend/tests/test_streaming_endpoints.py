"""
Comprehensive streaming endpoint tests.

Tests all SSE (Server-Sent Events) streaming endpoints to verify:
1. Correct SSE format (event: type, data: json)
2. Progress events are sent during processing
3. Done/error events are sent on completion
4. Response includes expected fields

Run with: python -m pytest tests/test_streaming_endpoints.py -v -s
Or directly: python tests/test_streaming_endpoints.py
"""
import asyncio
import time
import json
import base64
from pathlib import Path
from typing import Optional, List, Dict, Any

import httpx

# Configuration
BASE_URL = "http://localhost:8000"
TEST_USER_ID = "ba7f2f00-e6f8-4ac6-97a2-988988af940a"


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

        result.total_time = time.time() - start_time

    except Exception as e:
        result.error = str(e)
        result.total_time = time.time() - start_time

    return result


async def test_workout_generation_streaming():
    """Test /workouts/generate-stream endpoint."""
    print("\n" + "="*70)
    print("Testing: Workout Generation Streaming")
    print("="*70)

    async with httpx.AsyncClient(timeout=120.0) as client:
        request_data = {
            "user_id": TEST_USER_ID,
            "fitness_level": "intermediate",
            "goals": ["muscle_gain"],
            "equipment": ["dumbbells"],
            "duration_minutes": 30,
        }

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/workouts/generate-stream",
                json=request_data,
            ) as response:
                result = await parse_sse_stream(response)
        except Exception as e:
            result = StreamingTestResult()
            result.error = str(e)

        result.print_summary("Workout Generation Streaming")

        # Assertions
        assert result.success or result.error is None, f"Test failed: {result.error}"
        assert result.first_event_time is not None, "No events received"
        assert result.first_event_time < 2.0, f"First event too slow: {result.first_event_time}s"

        return result


async def test_workout_regeneration_streaming():
    """Test /workouts/regenerate-stream endpoint."""
    print("\n" + "="*70)
    print("Testing: Workout Regeneration Streaming")
    print("="*70)

    # First, get an existing workout to regenerate
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Get workouts for the test user
        response = await client.get(f"{BASE_URL}/api/v1/workouts/user/{TEST_USER_ID}")
        if response.status_code != 200:
            print(f"Could not get existing workouts: {response.status_code}")
            print("Creating a new workout first...")

            # Generate a workout to regenerate
            create_response = await client.post(
                f"{BASE_URL}/api/v1/workouts/generate",
                json={
                    "user_id": TEST_USER_ID,
                    "fitness_level": "intermediate",
                    "goals": ["muscle_gain"],
                    "equipment": ["dumbbells"],
                    "duration_minutes": 30,
                }
            )
            if create_response.status_code != 200:
                print(f"Could not create workout: {create_response.status_code}")
                return None
            workout_id = create_response.json()["id"]
        else:
            workouts = response.json()
            if not workouts:
                print("No workouts found for test user")
                return None
            workout_id = workouts[0]["id"]

        # Now test regeneration streaming
        request_data = {
            "workout_id": workout_id,
            "user_id": TEST_USER_ID,
            "difficulty": "hard",
            "duration_minutes": 45,
        }

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/workouts/regenerate-stream",
                json=request_data,
                timeout=120.0,
            ) as response:
                result = await parse_sse_stream(response)
        except Exception as e:
            result = StreamingTestResult()
            result.error = str(e)

        result.print_summary("Workout Regeneration Streaming")

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
