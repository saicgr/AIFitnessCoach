"""
Script to generate AI instructions for exercises missing them.

Uses GPT-4o-mini for cost efficiency (~$0.02 for 89 exercises).

Usage:
    cd backend
    python scripts/generate_missing_instructions.py
"""

import os
import sys
from typing import List, Dict

# Get script directory and backend directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.dirname(SCRIPT_DIR)

# Add backend directory to path for imports
sys.path.insert(0, BACKEND_DIR)

from openai import OpenAI
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables from backend/.env
env_path = os.path.join(BACKEND_DIR, ".env")
load_dotenv(env_path)

print(f"Loading .env from: {env_path}")

# Initialize clients
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

if not all([SUPABASE_URL, SUPABASE_KEY, OPENAI_API_KEY]):
    print("❌ Missing required environment variables")
    print(f"   SUPABASE_URL: {'✓' if SUPABASE_URL else '✗'}")
    print(f"   SUPABASE_KEY: {'✓' if SUPABASE_KEY else '✗'}")
    print(f"   OPENAI_API_KEY: {'✓' if OPENAI_API_KEY else '✗'}")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
openai_client = OpenAI(api_key=OPENAI_API_KEY)


def get_exercises_missing_instructions() -> List[Dict]:
    """Fetch all exercises that have NULL or empty instructions."""
    result = supabase.table("exercise_library").select("*").or_(
        "instructions.is.null,instructions.eq."
    ).execute()

    return result.data


def generate_instructions(exercise: Dict) -> str:
    """Generate exercise instructions using GPT-4o-mini."""
    exercise_name = exercise.get("exercise_name", "Unknown Exercise")
    body_part = exercise.get("body_part", "")
    equipment = exercise.get("equipment", "")
    target_muscle = exercise.get("target_muscle", "")
    secondary_muscles = exercise.get("secondary_muscles", [])

    prompt = f"""Generate clear, step-by-step exercise instructions for: {exercise_name}

Exercise Details:
- Body Part: {body_part}
- Equipment: {equipment}
- Target Muscle: {target_muscle}
- Secondary Muscles: {', '.join(secondary_muscles) if secondary_muscles else 'None'}

Provide 4-6 numbered steps that are:
1. Clear and concise
2. Focus on proper form
3. Include breathing cues
4. Mention common mistakes to avoid

Format: Just the numbered steps, no headers or extra text."""

    response = openai_client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {
                "role": "system",
                "content": "You are a certified personal trainer. Provide clear, safe exercise instructions."
            },
            {"role": "user", "content": prompt}
        ],
        max_tokens=400,
        temperature=0.7
    )

    return response.choices[0].message.content.strip()


def update_exercise_instructions(exercise_id: int, instructions: str) -> bool:
    """Update the exercise in the database with generated instructions."""
    try:
        supabase.table("exercise_library").update({
            "instructions": instructions
        }).eq("id", exercise_id).execute()
        return True
    except Exception as e:
        print(f"   ❌ Failed to update: {e}")
        return False


def main():
    print("🔍 Fetching exercises missing instructions...")
    exercises = get_exercises_missing_instructions()

    if not exercises:
        print("✅ All exercises have instructions!")
        return

    print(f"📝 Found {len(exercises)} exercises missing instructions")
    print(f"💰 Estimated cost: ~${len(exercises) * 0.00025:.2f} (GPT-4o-mini)")
    print()

    # Process each exercise
    success_count = 0
    error_count = 0

    for i, exercise in enumerate(exercises, 1):
        exercise_id = exercise.get("id")
        exercise_name = exercise.get("exercise_name", "Unknown")

        print(f"[{i}/{len(exercises)}] Generating instructions for: {exercise_name}")

        try:
            # Generate instructions
            instructions = generate_instructions(exercise)

            # Update database
            if update_exercise_instructions(exercise_id, instructions):
                print(f"   ✅ Updated successfully")
                success_count += 1
            else:
                error_count += 1

        except Exception as e:
            print(f"   ❌ Error: {e}")
            error_count += 1

        # Small delay to avoid rate limits
        if i % 10 == 0:
            print(f"   ⏳ Processed {i}/{len(exercises)}...")

    print()
    print("=" * 50)
    print(f"✅ Successfully updated: {success_count}")
    print(f"❌ Failed: {error_count}")
    print("=" * 50)


if __name__ == "__main__":
    main()
