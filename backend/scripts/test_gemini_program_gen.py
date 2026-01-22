#!/usr/bin/env python3
"""
Test Gemini API for workout program generation quality.
Generates ONE complete program with all its variants to evaluate output quality.

Usage:
    cd backend
    python3 scripts/test_gemini_program_gen.py
"""

import os
import json
import time
from pathlib import Path
from dotenv import load_dotenv
from google import genai
from google.genai import types

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Configure Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in .env file")

# Initialize client
client = genai.Client(api_key=GEMINI_API_KEY)

# Output directory for generated programs
OUTPUT_DIR = Path(__file__).parent.parent / "generated_programs"
OUTPUT_DIR.mkdir(exist_ok=True)

# Sample program to generate - "5x5 Linear Progression" from Strength Fundamentals
TEST_PROGRAM = {
    "name": "5x5 Linear Progression",
    "category": "Strength Fundamentals",
    "description": "Classic 5 sets of 5 reps strength building program with progressive overload",
    "difficulty": "beginner",
    "requires_gym": True,
    "variants": [
        {"duration_weeks": 4, "sessions_per_week": 3, "intensity": "moderate"},
        {"duration_weeks": 8, "sessions_per_week": 3, "intensity": "moderate"},
        {"duration_weeks": 12, "sessions_per_week": 3, "intensity": "moderate"},
    ]
}

SYSTEM_PROMPT = """You are a certified personal trainer and strength coach creating professional workout programs.

Your task is to generate a complete, day-by-day workout program in JSON format.

IMPORTANT RULES:
1. Return ONLY valid JSON - no markdown, no explanations
2. Every workout must include warm-up, main workout, and cool-down
3. Include specific sets, reps, rest periods, and weight guidance
4. Progress difficulty appropriately across weeks
5. Include proper deload weeks (every 4th week typically)
6. Use standard exercise names that can be found in any exercise database

OUTPUT FORMAT:
{
  "program_name": "string",
  "duration_weeks": number,
  "sessions_per_week": number,
  "total_workouts": number,
  "workouts": [
    {
      "week": number,
      "day": number,
      "day_in_program": number,
      "name": "string",
      "type": "strength|cardio|hybrid|recovery",
      "duration_minutes": number,
      "focus": "string",
      "equipment": ["list of equipment"],
      "warmup": [
        {
          "exercise": "string",
          "duration_seconds": number,
          "reps": number (optional),
          "notes": "string"
        }
      ],
      "main_workout": [
        {
          "exercise": "string",
          "sets": number,
          "reps": "number or range like 8-12",
          "weight_guidance": "string (e.g., '70% 1RM', 'RPE 7', 'bodyweight')",
          "rest_seconds": number,
          "tempo": "string (optional, e.g., '3-1-1-0')",
          "notes": "string"
        }
      ],
      "cooldown": [
        {
          "exercise": "string",
          "duration_seconds": number,
          "notes": "string"
        }
      ],
      "coach_notes": "string"
    }
  ]
}"""


def generate_program_variant(program: dict, variant: dict) -> dict:
    """Generate a complete workout program for one variant using Gemini."""

    user_prompt = f"""Generate a complete {variant['duration_weeks']}-week "{program['name']}" workout program.

PROGRAM DETAILS:
- Name: {program['name']}
- Category: {program['category']}
- Description: {program['description']}
- Duration: {variant['duration_weeks']} weeks
- Sessions per week: {variant['sessions_per_week']}
- Intensity: {variant['intensity']}
- Difficulty: {program['difficulty']}
- Requires Gym: {program['requires_gym']}

SPECIFIC REQUIREMENTS FOR 5x5 LINEAR PROGRESSION:
- Core lifts: Squat, Bench Press, Deadlift, Overhead Press, Barbell Row
- Main sets: 5 sets of 5 reps for compound lifts
- Add weight each session (2.5kg upper body, 5kg lower body)
- Alternate between Workout A (Squat/Bench/Row) and Workout B (Squat/OHP/Deadlift)
- Include accessory work after main lifts
- Deload weeks: reduce weight by 10% every 4th week
- Progressive overload is the key principle

Generate ALL {variant['duration_weeks'] * variant['sessions_per_week']} workouts for this program.
Return ONLY the JSON object, no other text."""

    print(f"\n🎯 Generating {variant['duration_weeks']}-week variant ({variant['sessions_per_week']} sessions/week)...")
    print(f"   Total workouts to generate: {variant['duration_weeks'] * variant['sessions_per_week']}")

    start_time = time.time()

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT,
                temperature=0.7,
                max_output_tokens=65536,
            )
        )

        elapsed = time.time() - start_time

        # Extract JSON from response
        text = response.text.strip()

        # Handle markdown code blocks
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        # Parse JSON
        program_data = json.loads(text)

        # Get actual token usage from response
        usage = response.usage_metadata
        input_tokens = usage.prompt_token_count if usage else len(user_prompt.split()) * 1.3
        output_tokens = usage.candidates_token_count if usage else len(text.split()) * 1.3

        print(f"   ✅ Generated in {elapsed:.1f}s")
        print(f"   📊 Workouts generated: {len(program_data.get('workouts', []))}")
        print(f"   📝 Tokens - Input: {int(input_tokens)}, Output: {int(output_tokens)}")

        return {
            "success": True,
            "data": program_data,
            "elapsed_seconds": elapsed,
            "input_tokens": int(input_tokens),
            "output_tokens": int(output_tokens)
        }

    except json.JSONDecodeError as e:
        print(f"   ❌ JSON parsing error: {e}")
        try:
            print(f"   Raw response (first 500 chars): {response.text[:500]}")
        except:
            pass
        return {
            "success": False,
            "error": f"JSON parsing error: {e}",
        }
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return {
            "success": False,
            "error": str(e)
        }


def analyze_quality(program_data: dict) -> dict:
    """Analyze the quality of generated program data."""

    workouts = program_data.get("workouts", [])

    if not workouts:
        return {"score": 0, "issues": ["No workouts generated"]}

    issues = []
    score = 100

    # Check workout count
    expected = program_data.get("duration_weeks", 0) * program_data.get("sessions_per_week", 0)
    actual = len(workouts)
    if actual < expected:
        issues.append(f"Missing workouts: expected {expected}, got {actual}")
        score -= 20

    # Check workout structure
    required_fields = ["week", "day", "name", "warmup", "main_workout", "cooldown"]
    for i, workout in enumerate(workouts[:5]):  # Check first 5
        missing = [f for f in required_fields if f not in workout]
        if missing:
            issues.append(f"Workout {i+1} missing fields: {missing}")
            score -= 5

    # Check exercise variety
    all_exercises = set()
    for workout in workouts:
        for ex in workout.get("main_workout", []):
            all_exercises.add(ex.get("exercise", ""))

    if len(all_exercises) < 5:
        issues.append(f"Low exercise variety: only {len(all_exercises)} unique exercises")
        score -= 10

    return {
        "score": max(0, score),
        "total_workouts": actual,
        "unique_exercises": len(all_exercises),
        "issues": issues if issues else ["No issues found"],
        "sample_exercises": list(all_exercises)[:10]
    }


def main():
    print("=" * 60)
    print("🏋️ GEMINI PROGRAM GENERATION QUALITY TEST")
    print("=" * 60)
    print(f"\nModel: {GEMINI_MODEL}")
    print(f"Test Program: {TEST_PROGRAM['name']}")
    print(f"Variants to generate: {len(TEST_PROGRAM['variants'])}")

    results = []
    total_input_tokens = 0
    total_output_tokens = 0

    for variant in TEST_PROGRAM["variants"]:
        result = generate_program_variant(TEST_PROGRAM, variant)

        if result["success"]:
            # Analyze quality
            quality = analyze_quality(result["data"])
            result["quality"] = quality

            # Save to file
            filename = f"{TEST_PROGRAM['name'].replace(' ', '_')}_{variant['duration_weeks']}w_{variant['sessions_per_week']}d.json"
            filepath = OUTPUT_DIR / filename
            with open(filepath, 'w') as f:
                json.dump(result["data"], f, indent=2)
            print(f"   💾 Saved to: {filepath.name}")

            total_input_tokens += result.get("input_tokens", 0)
            total_output_tokens += result.get("output_tokens", 0)

        results.append({
            "variant": variant,
            "result": result
        })

        # Rate limiting - wait between requests
        time.sleep(2)

    # Summary
    print("\n" + "=" * 60)
    print("📊 SUMMARY")
    print("=" * 60)

    successful = sum(1 for r in results if r["result"]["success"])
    print(f"\nVariants generated: {successful}/{len(results)}")

    for r in results:
        variant = r["variant"]
        result = r["result"]
        status = "✅" if result["success"] else "❌"
        if result["success"]:
            quality = result.get("quality", {})
            print(f"  {status} {variant['duration_weeks']}w × {variant['sessions_per_week']}d: "
                  f"Score={quality.get('score', 'N/A')}, "
                  f"Workouts={quality.get('total_workouts', 0)}, "
                  f"Exercises={quality.get('unique_exercises', 0)}")
        else:
            print(f"  {status} {variant['duration_weeks']}w × {variant['sessions_per_week']}d: {result.get('error', 'Unknown error')}")

    # Cost estimation
    print("\n" + "-" * 60)
    print("💰 TOKEN USAGE & COST ESTIMATES")
    print("-" * 60)
    print(f"\nTotal tokens for this test:")
    print(f"  Input:  {total_input_tokens:,} tokens")
    print(f"  Output: {total_output_tokens:,} tokens")

    # Cost per million tokens (Jan 2026 pricing)
    pricing = {
        "Gemini 2.5 Flash": {"input": 0.15, "output": 0.60},
        "Gemini 2.5 Flash-Lite": {"input": 0.075, "output": 0.30},
        "Gemini 3 Flash (NEW)": {"input": 0.50, "output": 3.00},
        "GPT-4o mini": {"input": 0.15, "output": 0.60},
        "Claude 3.5 Haiku": {"input": 0.80, "output": 4.00},
    }

    print("\nCost for THIS test run:")
    for model_name, prices in pricing.items():
        cost = (total_input_tokens * prices["input"] / 1_000_000 +
                total_output_tokens * prices["output"] / 1_000_000)
        print(f"  {model_name}: ${cost:.4f}")

    # Extrapolate to full scale (5,424 variants from PROGRAMS_CHECKLIST.md)
    scale_factor = 5424 / len(TEST_PROGRAM["variants"])
    print(f"\n📈 Projected cost for ALL 5,424 variants (× {scale_factor:.0f}):")
    for model_name, prices in pricing.items():
        full_cost = ((total_input_tokens * prices["input"] / 1_000_000 +
                      total_output_tokens * prices["output"] / 1_000_000) * scale_factor)
        print(f"  {model_name}: ${full_cost:.2f}")

    print("\n" + "=" * 60)
    print(f"📁 Generated files saved to: {OUTPUT_DIR}")
    print("=" * 60)


if __name__ == "__main__":
    main()
