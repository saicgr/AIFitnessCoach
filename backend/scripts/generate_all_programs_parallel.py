"""
Production Script: Generate 253 Complete Workout Programs with Parallel Processing
Uses Gemini + asyncio for concurrent generation
Fault-tolerant: inserts programs without workouts if generation fails
"""
import asyncio
import os
import json
import time
from dotenv import load_dotenv
import asyncpg
from google import genai
from google.genai import types

load_dotenv()

# Initialize Gemini client
client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
model_name = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash')

# Load all 253 programs from catalog
with open('/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/all_programs_catalog.json', 'r') as f:
    ALL_PROGRAMS = json.load(f)

print(f"📚 Loaded {len(ALL_PROGRAMS)} programs from catalog")


async def generate_workout_for_program(program: dict, available_exercises: list, semaphore: asyncio.Semaphore) -> dict:
    """
    Use Gemini to generate realistic workout plan for a program
    Uses semaphore for rate limiting
    """
    async with semaphore:  # Limit concurrent API calls
        prompt = f"""You are a professional fitness coach creating detailed, realistic workout programs. Return only valid JSON with no markdown formatting.

Generate a complete {program['duration_weeks']}-week workout program with the following specifications:

Program: {program['program_name']}
Category: {program['program_category']} - {program.get('program_subcategory', 'General')}
Difficulty: {program['difficulty_level']}
Duration: {program['duration_weeks']} weeks
Sessions per week: {program['sessions_per_week']}
Session duration: {program['session_duration_minutes']} minutes
Goals: {', '.join(program['goals'])}
Description: {program['description']}

Create a weekly workout plan with {program['sessions_per_week']} distinct workouts. Each workout should include:
- workout_name (descriptive, e.g., "Upper Body Power Day")
- day (1-{program['sessions_per_week']})
- type (Strength/Cardio/HIIT/Yoga/Stretching/Sport-Specific/etc.)
- exercises array with 5-10 exercises per workout:
  - exercise_name (choose from common exercises: bench press, squat, deadlift, lunges, push-ups, pull-ups, rows, shoulder press, bicep curls, tricep dips, planks, burpees, mountain climbers, kettlebell swings, box jumps, running, cycling, yoga poses, stretches, etc.)
  - sets (typically 3-5)
  - reps (e.g., "8-12", "10-15", "20-30 seconds", "30-60 seconds")
  - rest_seconds (30-120 depending on intensity)
  - notes (optional training tips)

IMPORTANT:
- Make workouts varied and appropriate for the difficulty level
- Include warm-up/cool-down guidance in notes
- For yoga/stretching programs, use pose names and hold durations
- For sport-specific programs, include sport-specific drills
- For HIIT programs, use interval format with work/rest periods

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
  "workouts": [
    {{
      "workout_name": "Full Body Strength",
      "day": 1,
      "type": "Strength",
      "exercises": [
        {{"exercise_name": "Barbell Squat", "sets": 4, "reps": "8-10", "rest_seconds": 120, "notes": "Keep chest up"}},
        {{"exercise_name": "Bench Press", "sets": 4, "reps": "8-10", "rest_seconds": 90}},
        {{"exercise_name": "Bent Over Row", "sets": 3, "reps": "10-12", "rest_seconds": 90}},
        {{"exercise_name": "Overhead Press", "sets": 3, "reps": "8-10", "rest_seconds": 90}},
        {{"exercise_name": "Romanian Deadlift", "sets": 3, "reps": "10-12", "rest_seconds": 90}}
      ]
    }}
  ]
}}
"""

        try:
            response = await client.aio.models.generate_content(
                model=model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    temperature=0.7,
                    max_output_tokens=2500,
                ),
            )

            content = response.text.strip()

            # Extract JSON from markdown code blocks if present
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()

            workouts = json.loads(content)

            # Validate structure
            if "workouts" not in workouts or not isinstance(workouts["workouts"], list):
                print(f"⚠️  Invalid structure for {program['program_name']}, returning empty workouts")
                return {"workouts": []}

            return workouts

        except json.JSONDecodeError as e:
            print(f"❌ JSON error for {program['program_name']}: {e}")
            return {"workouts": []}
        except Exception as e:
            print(f"❌ Error generating workout for {program['program_name']}: {e}")
            return {"workouts": []}


async def insert_program_to_db(conn: asyncpg.Connection, program: dict, workouts: dict, index: int, total: int):
    """Insert a single program into the database"""
    try:
        await conn.execute('''
            INSERT INTO programs (
                program_name, program_category, program_subcategory, country, celebrity_name,
                difficulty_level, duration_weeks, sessions_per_week, session_duration_minutes,
                tags, goals, description, short_description, workouts
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
        ''',
            program['program_name'],
            program['program_category'],
            program.get('program_subcategory'),
            program['country'],
            program.get('celebrity_name'),
            program['difficulty_level'],
            program['duration_weeks'],
            program['sessions_per_week'],
            program['session_duration_minutes'],
            program['tags'],
            program['goals'],
            program['description'],
            program['short_description'],
            json.dumps(workouts)
        )

        workout_count = len(workouts.get('workouts', []))
        status = "✅" if workout_count > 0 else "⚠️ "
        print(f"{status} [{index}/{total}] {program['program_name']} - {workout_count} workouts")

    except Exception as e:
        print(f"❌ Database error for {program['program_name']}: {e}")


async def generate_and_insert_program(
    conn: asyncpg.Connection,
    program: dict,
    available_exercises: list,
    semaphore: asyncio.Semaphore,
    index: int,
    total: int
):
    """Generate workout and insert program (all-in-one atomic operation)"""
    # Generate workouts using Gemini
    workouts = await generate_workout_for_program(program, available_exercises, semaphore)

    # Insert to database immediately
    await insert_program_to_db(conn, program, workouts, index, total)

    # Small delay to respect rate limits
    await asyncio.sleep(0.5)


async def main():
    """Main execution: parallel generation of all 253 programs"""

    print("\n" + "="*80)
    print("🏋️  GENERATING 253 COMPLETE WORKOUT PROGRAMS")
    print("="*80 + "\n")

    start_time = time.time()

    # Connect to database
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)

    try:
        # Load exercise names for context (limited sample)
        print("📊 Loading exercise library...")
        exercise_rows = await conn.fetch('SELECT DISTINCT exercise_name FROM exercise_library LIMIT 200')
        available_exercises = [row['exercise_name'] for row in exercise_rows if row['exercise_name']]
        print(f"✅ Loaded {len(available_exercises)} sample exercises\n")

        # Clear existing programs
        print("🗑️  Clearing existing programs...")
        await conn.execute('TRUNCATE TABLE programs CASCADE')
        print("✅ Programs table cleared\n")

        # Create semaphore to limit concurrent API calls (10 at a time)
        semaphore = asyncio.Semaphore(10)

        # Create tasks for all programs
        total_programs = len(ALL_PROGRAMS)
        print(f"🚀 Starting parallel generation of {total_programs} programs...\n")

        tasks = []
        for i, program in enumerate(ALL_PROGRAMS, 1):
            task = generate_and_insert_program(
                conn, program, available_exercises, semaphore, i, total_programs
            )
            tasks.append(task)

        # Execute all tasks concurrently
        await asyncio.gather(*tasks)

        # Summary
        elapsed_time = time.time() - start_time
        programs_with_workouts = await conn.fetchval('SELECT COUNT(*) FROM programs WHERE workouts IS NOT NULL AND workouts::text != \'{"workouts":[]}\'')
        total_inserted = await conn.fetchval('SELECT COUNT(*) FROM programs')

        print("\n" + "="*80)
        print("🎉 GENERATION COMPLETE!")
        print("="*80)
        print(f"⏱️  Time elapsed: {elapsed_time:.1f} seconds ({elapsed_time/60:.1f} minutes)")
        print(f"📊 Programs inserted: {total_inserted}/{total_programs}")
        print(f"✅ Programs with workouts: {programs_with_workouts}")
        print(f"⚠️  Programs without workouts: {total_inserted - programs_with_workouts}")
        print(f"🏋️  Average time per program: {elapsed_time/total_programs:.1f}s")
        print("="*80 + "\n")

        # Sample verification
        print("🔍 Sample programs:")
        samples = await conn.fetch('SELECT program_name, program_category, difficulty_level, jsonb_array_length(workouts->>\'workouts\') as workout_count FROM programs LIMIT 5')
        for row in samples:
            print(f"   • {row['program_name']} ({row['difficulty_level']}) - {row['workout_count']} workouts")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
