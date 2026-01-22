#!/usr/bin/env python3
"""
Quick quality comparison: Gemini 2.5 Flash vs Flash-Lite
Tests ONE 4-week program variant to compare output quality.
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

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

OUTPUT_DIR = Path(__file__).parent.parent / "generated_programs"
OUTPUT_DIR.mkdir(exist_ok=True)

SYSTEM_PROMPT = """You are a certified personal trainer creating workout programs in JSON format.

RULES:
1. Return ONLY valid JSON - no markdown, no explanations
2. Every workout must have: warmup, main_workout, cooldown
3. Include specific sets, reps, rest periods
4. Progress difficulty across weeks (week 4 harder than week 1)

OUTPUT FORMAT:
{
  "program_name": "string",
  "duration_weeks": number,
  "sessions_per_week": number,
  "workouts": [
    {
      "week": number,
      "day": number,
      "name": "string",
      "focus": "string",
      "warmup": [{"exercise": "string", "duration_seconds": number}],
      "main_workout": [{"exercise": "string", "sets": number, "reps": "string", "rest_seconds": number}],
      "cooldown": [{"exercise": "string", "duration_seconds": number}]
    }
  ]
}"""

USER_PROMPT = """Generate a complete 4-week "5x5 Strength" program (3 sessions/week = 12 total workouts).

Requirements:
- Core lifts: Squat, Bench Press, Deadlift, Overhead Press, Barbell Row
- 5 sets of 5 reps for main lifts
- Alternate Workout A (Squat/Bench/Row) and Workout B (Squat/OHP/Deadlift)
- Include 2-3 accessory exercises per workout
- Week 4 should be a deload week (lighter weights)

Generate ALL 12 workouts. Return ONLY JSON."""


def test_model(model_name: str) -> dict:
    """Test a single model and return results."""
    print(f"\n{'='*50}")
    print(f"🧪 Testing: {model_name}")
    print(f"{'='*50}")

    start = time.time()

    try:
        response = client.models.generate_content(
            model=model_name,
            contents=USER_PROMPT,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT,
                temperature=0.7,
                max_output_tokens=16000,
            )
        )

        elapsed = time.time() - start
        text = response.text.strip()

        # Clean markdown
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        # Parse
        data = json.loads(text)

        # Get token usage
        usage = response.usage_metadata
        input_tokens = usage.prompt_token_count if usage else 0
        output_tokens = usage.candidates_token_count if usage else 0

        # Analyze quality
        workouts = data.get("workouts", [])

        # Quality checks
        quality = {
            "total_workouts": len(workouts),
            "expected_workouts": 12,
            "has_all_workouts": len(workouts) >= 12,
            "all_have_warmup": all(w.get("warmup") for w in workouts),
            "all_have_main": all(w.get("main_workout") for w in workouts),
            "all_have_cooldown": all(w.get("cooldown") for w in workouts),
            "unique_workout_names": len(set(w.get("name", "") for w in workouts)),
        }

        # Check exercise variety
        all_exercises = set()
        for w in workouts:
            for ex in w.get("main_workout", []):
                all_exercises.add(ex.get("exercise", ""))
        quality["unique_exercises"] = len(all_exercises)

        # Check progression (compare week 1 vs week 4 volume)
        week1 = [w for w in workouts if w.get("week") == 1]
        week4 = [w for w in workouts if w.get("week") == 4]
        quality["has_week1"] = len(week1) > 0
        quality["has_week4"] = len(week4) > 0

        # Calculate quality score
        score = 0
        if quality["has_all_workouts"]: score += 25
        if quality["all_have_warmup"]: score += 20
        if quality["all_have_main"]: score += 20
        if quality["all_have_cooldown"]: score += 15
        if quality["unique_exercises"] >= 8: score += 10
        if quality["has_week1"] and quality["has_week4"]: score += 10
        quality["score"] = score

        # Save output
        filename = f"quality_test_{model_name.replace('-', '_').replace('.', '_')}.json"
        with open(OUTPUT_DIR / filename, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"✅ Generated in {elapsed:.1f}s")
        print(f"📊 Workouts: {len(workouts)}/12")
        print(f"📝 Tokens - In: {input_tokens}, Out: {output_tokens}")
        print(f"🎯 Quality Score: {score}/100")
        print(f"💾 Saved: {filename}")

        # Calculate cost
        if "lite" in model_name.lower():
            cost = (input_tokens * 0.075 + output_tokens * 0.30) / 1_000_000
        elif "3-flash" in model_name.lower():
            cost = (input_tokens * 0.50 + output_tokens * 3.00) / 1_000_000
        else:
            cost = (input_tokens * 0.15 + output_tokens * 0.60) / 1_000_000
        print(f"💰 Cost: ${cost:.6f}")

        return {
            "model": model_name,
            "success": True,
            "elapsed": elapsed,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "quality": quality,
            "cost": cost
        }

    except Exception as e:
        print(f"❌ Error: {e}")
        return {
            "model": model_name,
            "success": False,
            "error": str(e)
        }


def main():
    print("🏋️ GEMINI MODEL QUALITY COMPARISON")
    print("Testing 4-week 5x5 program generation\n")

    models = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-3-flash-preview",
    ]

    results = []
    for model in models:
        result = test_model(model)
        results.append(result)
        time.sleep(2)  # Rate limit

    # Summary
    print("\n" + "="*60)
    print("📊 COMPARISON SUMMARY")
    print("="*60)

    print(f"\n{'Model':<40} {'Score':<8} {'Time':<8} {'Cost':<10}")
    print("-"*66)

    for r in results:
        if r["success"]:
            print(f"{r['model']:<40} {r['quality']['score']:<8} {r['elapsed']:.1f}s    ${r['cost']:.6f}")
        else:
            print(f"{r['model']:<40} FAILED   -        -")

    # Recommendation
    print("\n" + "-"*60)
    successful = [r for r in results if r["success"]]
    if len(successful) == 2:
        flash = next(r for r in successful if "lite" not in r["model"].lower())
        lite = next(r for r in successful if "lite" in r["model"].lower())

        score_diff = flash["quality"]["score"] - lite["quality"]["score"]
        cost_diff = flash["cost"] / lite["cost"] if lite["cost"] > 0 else 0

        print(f"\n📈 Flash vs Lite:")
        print(f"   Quality difference: {score_diff:+d} points")
        print(f"   Cost ratio: Flash is {cost_diff:.1f}x more expensive")

        if score_diff <= 5:
            print(f"\n✅ RECOMMENDATION: Use Flash-Lite (similar quality, half the cost)")
        elif score_diff <= 15:
            print(f"\n⚠️ RECOMMENDATION: Consider Flash (noticeably better quality)")
        else:
            print(f"\n🚨 RECOMMENDATION: Use Flash (significantly better quality)")

    print(f"\n📁 Check generated JSONs in: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
