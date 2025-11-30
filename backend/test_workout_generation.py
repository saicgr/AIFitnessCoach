#!/usr/bin/env python3
"""
Test script for workout generation with RAG.

Run with: python test_workout_generation.py
"""
import asyncio
import json
import httpx

BASE_URL = "http://localhost:8000/api/v1"


async def test_workout_generation():
    """Test the full workout generation flow."""

    async with httpx.AsyncClient(timeout=120.0) as client:
        print("=" * 60)
        print("🧪 WORKOUT GENERATION TEST")
        print("=" * 60)

        # 1. Check RAG stats
        print("\n1️⃣ Checking Exercise RAG stats...")
        try:
            response = await client.get(f"{BASE_URL}/exercises/rag/stats")
            if response.status_code == 200:
                stats = response.json()
                print(f"   ✅ RAG Stats: {stats}")
                indexed = stats.get("stats", {}).get("total_exercises", 0)
                if indexed == 0:
                    print("   ⚠️  No exercises indexed! RAG will fall back to AI generation.")
            else:
                print(f"   ❌ Failed to get RAG stats: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")

        # 2. Get a test user (first user in database)
        print("\n2️⃣ Getting test user...")
        try:
            response = await client.get(f"{BASE_URL}/users/")
            if response.status_code == 200:
                users = response.json()
                if users:
                    test_user = users[0]
                    user_id = test_user.get("id")
                    print(f"   ✅ Found user: {user_id}")
                    print(f"      Fitness level: {test_user.get('fitness_level')}")
                    print(f"      Goals: {test_user.get('goals')}")
                    print(f"      Equipment: {test_user.get('equipment')}")
                else:
                    print("   ❌ No users found. Please complete onboarding first.")
                    return
            else:
                print(f"   ❌ Failed to get users: {response.status_code}")
                print(f"   Response: {response.text[:300]}")
                return
        except Exception as e:
            print(f"   ❌ Error: {e}")
            return

        # 3. Check existing workouts
        print("\n3️⃣ Checking existing workouts...")
        try:
            response = await client.get(f"{BASE_URL}/workouts-db/", params={"user_id": user_id})
            if response.status_code == 200:
                workouts = response.json()
                print(f"   ✅ Found {len(workouts)} existing workouts")
                if workouts:
                    print(f"      Latest: {workouts[0].get('name')} ({workouts[0].get('scheduled_date')})")
            else:
                print(f"   ❌ Failed to get workouts: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")

        # 4. Test monthly workout generation
        print("\n4️⃣ Testing monthly workout generation...")
        try:
            from datetime import datetime
            today = datetime.now()
            # Start from TODAY (not first of month) to ensure workouts appear in current week
            today_str = today.strftime("%Y-%m-%d")

            request_data = {
                "user_id": user_id,
                "month_start_date": today_str,
                "selected_days": [0, 2, 4],  # Mon, Wed, Fri
                "duration_minutes": 45
            }
            print(f"   Request: {json.dumps(request_data, indent=2)}")

            print("   ⏳ Generating workouts (this may take 30-60 seconds)...")
            response = await client.post(
                f"{BASE_URL}/workouts-db/generate-monthly",
                json=request_data
            )

            if response.status_code == 200:
                result = response.json()
                workouts = result.get("workouts", [])
                total = result.get("total_generated", 0)
                print(f"   ✅ Generated {total} workouts!")

                if workouts:
                    print("\n   Generated workouts:")
                    for i, w in enumerate(workouts[:5]):  # Show first 5
                        exercises = json.loads(w.get("exercises_json", "[]"))
                        print(f"   {i+1}. {w.get('name')} ({w.get('scheduled_date')[:10]})")
                        print(f"      Type: {w.get('type')}, Difficulty: {w.get('difficulty')}")
                        print(f"      Exercises: {len(exercises)}")
                        for ex in exercises[:3]:  # Show first 3 exercises
                            print(f"        - {ex.get('name')} ({ex.get('equipment', 'bodyweight')})")
                        if len(exercises) > 3:
                            print(f"        ... and {len(exercises) - 3} more")
                    if len(workouts) > 5:
                        print(f"   ... and {len(workouts) - 5} more workouts")
            else:
                print(f"   ❌ Failed: {response.status_code}")
                print(f"   Response: {response.text[:500]}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
            import traceback
            traceback.print_exc()

        print("\n" + "=" * 60)
        print("🏁 TEST COMPLETE")
        print("=" * 60)


if __name__ == "__main__":
    asyncio.run(test_workout_generation())
