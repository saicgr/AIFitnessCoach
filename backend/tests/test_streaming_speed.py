"""
Test script to compare streaming vs non-streaming workout generation speed.

This demonstrates that streaming provides faster perceived response time
by showing content immediately rather than waiting for full completion.

Run with: python -m pytest tests/test_streaming_speed.py -v -s
Or directly: python tests/test_streaming_speed.py
"""
import asyncio
import time
import json
import httpx
from typing import Optional

# Configuration
BASE_URL = "http://localhost:8000"
TEST_USER_ID = "ba7f2f00-e6f8-4ac6-97a2-988988af940a"


async def test_non_streaming_generation():
    """Test traditional non-streaming workout generation."""
    print("\n" + "=" * 60)
    print("TEST 1: Non-Streaming Workout Generation")
    print("=" * 60)

    async with httpx.AsyncClient(timeout=120.0) as client:
        request_data = {
            "user_id": TEST_USER_ID,
            "fitness_level": "intermediate",
            "goals": ["muscle_gain"],
            "equipment": ["dumbbells", "barbell"],
            "duration_minutes": 45,
        }

        start_time = time.time()
        print(f"[{time.time() - start_time:.2f}s] Sending request...")

        try:
            response = await client.post(
                f"{BASE_URL}/api/v1/workouts/generate",
                json=request_data,
            )

            end_time = time.time()
            total_time = end_time - start_time

            if response.status_code == 200:
                workout = response.json()
                print(f"[{total_time:.2f}s] Response received!")
                print(f"  Workout: {workout.get('name', 'Unknown')}")
                print(f"  Exercises: {len(workout.get('exercises_json', []))}")
                print(f"\n  TIME TO FIRST CONTENT: {total_time:.2f}s (same as total)")
                print(f"  TOTAL TIME: {total_time:.2f}s")
            else:
                print(f"[{total_time:.2f}s] Error: {response.status_code}")
                print(response.text)

            return total_time

        except Exception as e:
            print(f"Error: {e}")
            return None


async def test_streaming_generation():
    """Test streaming workout generation - shows time to first chunk."""
    print("\n" + "=" * 60)
    print("TEST 2: Streaming Workout Generation")
    print("=" * 60)

    async with httpx.AsyncClient(timeout=120.0) as client:
        request_data = {
            "user_id": TEST_USER_ID,
            "fitness_level": "intermediate",
            "goals": ["muscle_gain"],
            "equipment": ["dumbbells", "barbell"],
            "duration_minutes": 45,
        }

        start_time = time.time()
        first_chunk_time: Optional[float] = None
        chunk_count = 0
        full_content = ""
        final_workout = None

        print(f"[{time.time() - start_time:.2f}s] Sending streaming request...")

        try:
            async with client.stream(
                "POST",
                f"{BASE_URL}/api/v1/workouts/generate-stream",
                json=request_data,
            ) as response:

                async for line in response.aiter_lines():
                    if not line:
                        continue

                    current_time = time.time() - start_time

                    if line.startswith("event:"):
                        event_type = line.split(":", 1)[1].strip()
                    elif line.startswith("data:"):
                        data = line.split(":", 1)[1].strip()

                        if first_chunk_time is None:
                            first_chunk_time = current_time
                            print(f"[{current_time:.2f}s] FIRST CHUNK RECEIVED!")

                        try:
                            parsed = json.loads(data)

                            if "chunk" in parsed:
                                chunk_count += 1
                                chunk_text = parsed["chunk"]
                                full_content += chunk_text

                                # Show preview of content as it arrives
                                if chunk_count <= 5:
                                    preview = chunk_text[:50].replace("\n", " ")
                                    print(f"[{current_time:.2f}s] Chunk {chunk_count}: {preview}...")
                                elif chunk_count == 6:
                                    print(f"[{current_time:.2f}s] ... more chunks arriving ...")

                            elif "id" in parsed:  # Done event with full workout
                                final_workout = parsed
                                print(f"[{current_time:.2f}s] DONE - Full workout received")

                            elif "error" in parsed:
                                print(f"[{current_time:.2f}s] ERROR: {parsed['error']}")

                        except json.JSONDecodeError:
                            pass

            end_time = time.time()
            total_time = end_time - start_time

            print(f"\n  Total chunks received: {chunk_count}")
            if final_workout:
                print(f"  Workout: {final_workout.get('name', 'Unknown')}")

            if first_chunk_time is not None:
                print(f"\n  TIME TO FIRST CONTENT: {first_chunk_time:.2f}s")
            else:
                print(f"\n  TIME TO FIRST CONTENT: N/A (no chunks received)")
            print(f"  TOTAL TIME: {total_time:.2f}s")

            return first_chunk_time, total_time

        except Exception as e:
            print(f"Error: {e}")
            import traceback
            traceback.print_exc()
            return None, None


async def run_comparison():
    """Run both tests and compare results."""
    print("\n" + "=" * 70)
    print("STREAMING vs NON-STREAMING WORKOUT GENERATION COMPARISON")
    print("=" * 70)

    # Test non-streaming first
    non_streaming_time = await test_non_streaming_generation()

    # Wait a bit between tests
    print("\n[Waiting 2 seconds before streaming test...]")
    await asyncio.sleep(2)

    # Test streaming
    first_chunk_time, streaming_total_time = await test_streaming_generation()

    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)

    if non_streaming_time and first_chunk_time:
        improvement = non_streaming_time - first_chunk_time
        improvement_pct = (improvement / non_streaming_time) * 100

        print(f"""
Non-Streaming:
  - Time to see ANY content: {non_streaming_time:.2f}s
  - User stares at loading spinner for: {non_streaming_time:.2f}s

Streaming:
  - Time to see FIRST content: {first_chunk_time:.2f}s
  - Total completion time: {streaming_total_time:.2f}s
  - User sees content appearing after: {first_chunk_time:.2f}s

IMPROVEMENT:
  - User sees content {improvement:.2f}s FASTER ({improvement_pct:.0f}% improvement)
  - Instead of waiting {non_streaming_time:.2f}s for full response,
    user sees content starting at {first_chunk_time:.2f}s
""")
    else:
        print("Could not complete comparison - check if server is running")


if __name__ == "__main__":
    print("Starting streaming speed test...")
    print("Make sure the backend is running on localhost:8000")
    print()
    asyncio.run(run_comparison())
