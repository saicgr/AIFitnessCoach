"""
Production Script: Generate ALL 4,554 Program Variants (253 × 3 intensities × 6 durations)
Uses AsyncOpenAI + asyncio for parallel processing with rate limiting
Expected runtime: Several hours | Expected cost: ~$900
"""
import asyncio
import os
import json
import time
from datetime import datetime
from dotenv import load_dotenv
import asyncpg
from openai import AsyncOpenAI

load_dotenv()

# Initialize OpenAI client
client = AsyncOpenAI(api_key=os.getenv('OPENAI_API_KEY'))

# Variant configuration
INTENSITY_LEVELS = ['Easy', 'Medium', 'Hard']
DURATION_WEEKS = [2, 3, 4, 6, 8, 12]

# Intensity specifications
INTENSITY_SPECS = {
    'Easy': {
        'sets': 3,
        'reps': '12-15',
        'rest_seconds': 105,  # Average of 90-120
        'description': 'Foundational exercises, higher reps, longer rest periods',
        'exercise_selection': 'basic, low-impact movements'
    },
    'Medium': {
        'sets': 4,
        'reps': '8-12',
        'rest_seconds': 75,  # Average of 60-90
        'description': 'Balanced training with moderate intensity',
        'exercise_selection': 'standard compound and isolation exercises'
    },
    'Hard': {
        'sets': 5,
        'reps': '6-8',
        'rest_seconds': 52,  # Average of 45-60
        'description': 'Advanced exercises, lower reps, shorter rest, includes supersets and drop sets',
        'exercise_selection': 'advanced movements, explosive exercises, complex variations'
    }
}

# Duration specifications
DURATION_SPECS = {
    2: 'Very condensed program - core exercises only, fast progression',
    3: 'Short program - essential exercises, quick results focus',
    4: 'Standard short program - balanced foundation building',
    6: 'Standard program - typical progression and variety',
    8: 'Extended program - more detailed periodization',
    12: 'Long program - full periodization with foundation → intensity → peak phases'
}


async def generate_variant_workout(
    base_program: dict,
    intensity: str,
    duration_weeks: int,
    semaphore: asyncio.Semaphore
) -> dict:
    """
    Generate a workout variant using GPT-4 with specific intensity and duration
    """
    async with semaphore:  # Rate limiting

        intensity_spec = INTENSITY_SPECS[intensity]
        duration_spec = DURATION_SPECS[duration_weeks]

        # Create variant name
        variant_name = f"{base_program['program_name']} ({intensity}, {duration_weeks} weeks)"

        prompt = f"""
Generate a {duration_weeks}-week workout program at {intensity} intensity level:

BASE PROGRAM CONTEXT:
- Name: {base_program['program_name']}
- Category: {base_program['program_category']} - {base_program.get('program_subcategory', 'General')}
- Sessions per week: {base_program['sessions_per_week']}
- Session duration: {base_program['session_duration_minutes']} minutes
- Goals: {', '.join(base_program['goals'])}
- Description: {base_program['description']}

VARIANT REQUIREMENTS:
- Intensity: {intensity} - {intensity_spec['description']}
- Duration: {duration_weeks} weeks - {duration_spec}
- Default sets per exercise: {intensity_spec['sets']}
- Default reps per exercise: {intensity_spec['reps']}
- Default rest between sets: {intensity_spec['rest_seconds']} seconds
- Exercise selection style: {intensity_spec['exercise_selection']}

WORKOUT STRUCTURE:
Create a weekly workout plan with {base_program['sessions_per_week']} distinct workouts.
Each workout should include:
- workout_name (descriptive, e.g., "Upper Body Power Day")
- day (1-{base_program['sessions_per_week']})
- type (Strength/Cardio/HIIT/Yoga/Stretching/Sport-Specific/etc.)
- exercises array with 5-10 exercises per workout:
  - exercise_name (choose from exercises appropriate for {intensity} intensity)
  - sets (typically {intensity_spec['sets']}, can vary by exercise type)
  - reps (typically {intensity_spec['reps']}, adjust for exercise type)
  - rest_seconds (typically {intensity_spec['rest_seconds']}, adjust for intensity)
  - notes (training tips, form cues, intensity techniques)

INTENSITY-SPECIFIC GUIDELINES:

For EASY intensity:
- Use foundational, low-impact exercises
- Higher reps (12-15+) for muscle endurance
- Longer rest periods (90-120s)
- Focus on form and technique
- No advanced techniques (no supersets, drop sets, etc.)
- Examples: Goblet squat instead of barbell squat, push-ups instead of bench press

For MEDIUM intensity:
- Use standard compound and isolation exercises
- Moderate reps (8-12) for hypertrophy
- Standard rest periods (60-90s)
- Balanced approach between strength and endurance
- Can include occasional supersets for accessory work
- Examples: Barbell exercises, dumbbell work, machines

For HARD intensity:
- Use advanced, explosive, and complex variations
- Lower reps (6-8) for strength focus
- Shorter rest periods (45-60s)
- Include supersets, drop sets, and intensity techniques
- Advanced exercise variations
- Examples: Barbell complexes, plyometric variations, heavy compound lifts

DURATION-SPECIFIC GUIDELINES:

For 2-4 weeks (short programs):
- Condensed structure with core exercises only
- Fast progression within the limited timeframe
- Focus on essential movements
- Less exercise variety

For 6-8 weeks (standard programs):
- Standard progression model
- Full exercise variety
- Balanced periodization
- Typical workout complexity

For 12 weeks (long programs):
- Full periodization with distinct phases:
  * Weeks 1-4: Foundation phase (higher volume, moderate intensity)
  * Weeks 5-8: Intensity phase (progressive overload, increasing weights)
  * Weeks 9-12: Peak phase (peak performance, testing limits)
- Maximum exercise variety
- Detailed progression strategy

Return ONLY valid JSON in this exact format (no markdown, no code blocks):
{{
  "workouts": [
    {{
      "workout_name": "Full Body Strength",
      "day": 1,
      "type": "Strength",
      "exercises": [
        {{"exercise_name": "Barbell Squat", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Keep chest up, drive through heels"}},
        {{"exercise_name": "Bench Press", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Control the descent"}},
        {{"exercise_name": "Bent Over Row", "sets": 3, "reps": "10-12", "rest_seconds": 75, "notes": "Squeeze shoulder blades"}}
      ]
    }}
  ]
}}
"""

        try:
            response = await client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": f"You are a professional fitness coach creating a {intensity} intensity, {duration_weeks}-week workout program. Return only valid JSON with no markdown formatting."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=3000,
                timeout=180.0  # 3 minute timeout
            )

            content = response.choices[0].message.content.strip()

            # Extract JSON from markdown code blocks if present
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()

            workouts = json.loads(content)

            # Validate structure
            if "workouts" not in workouts or not isinstance(workouts["workouts"], list):
                print(f"⚠️  Invalid structure for {variant_name}")
                return None

            # Calculate cost (rough estimate: $0.20 per variant)
            tokens_used = response.usage.total_tokens if response.usage else 0

            return {
                'workouts': workouts,
                'variant_name': variant_name,
                'tokens_used': tokens_used
            }

        except json.JSONDecodeError as e:
            print(f"❌ JSON error for {variant_name}: {e}")
            return None
        except Exception as e:
            print(f"❌ Error generating {variant_name}: {e}")
            return None


async def insert_variant_to_db(
    conn: asyncpg.Connection,
    base_program_id: str,
    base_program: dict,
    intensity: str,
    duration_weeks: int,
    workouts_data: dict,
    index: int,
    total: int
):
    """Insert a single variant into the database"""
    try:
        await conn.execute('''
            INSERT INTO program_variants (
                base_program_id,
                intensity_level,
                duration_weeks,
                variant_name,
                program_category,
                program_subcategory,
                sessions_per_week,
                session_duration_minutes,
                tags,
                goals,
                workouts,
                generation_tokens,
                generation_cost_usd
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        ''',
            base_program_id,
            intensity,
            duration_weeks,
            workouts_data['variant_name'],
            base_program['program_category'],
            base_program.get('program_subcategory'),
            base_program['sessions_per_week'],
            base_program['session_duration_minutes'],
            base_program['tags'],
            base_program['goals'],
            json.dumps(workouts_data['workouts']),
            workouts_data['tokens_used'],
            0.20  # Estimated cost per variant
        )

        workout_count = len(workouts_data['workouts'].get('workouts', []))
        print(f"✅ [{index}/{total}] {workouts_data['variant_name']} - {workout_count} workouts")

    except Exception as e:
        print(f"❌ Database error for {workouts_data['variant_name']}: {e}")


async def generate_and_insert_variant(
    conn: asyncpg.Connection,
    base_program_id: str,
    base_program: dict,
    intensity: str,
    duration_weeks: int,
    semaphore: asyncio.Semaphore,
    index: int,
    total: int
):
    """Generate variant and insert (atomic operation)"""

    # Generate workout variant
    workouts_data = await generate_variant_workout(base_program, intensity, duration_weeks, semaphore)

    if workouts_data:
        # Insert to database
        await insert_variant_to_db(
            conn, base_program_id, base_program, intensity, duration_weeks,
            workouts_data, index, total
        )
    else:
        print(f"⚠️  Skipped variant [{index}/{total}]: {base_program['program_name']} ({intensity}, {duration_weeks}w)")

    # Small delay to respect rate limits
    await asyncio.sleep(0.3)


async def main():
    """Main execution: Generate all 4,554 program variants"""

    print("\n" + "="*100)
    print("🏋️  GENERATING ALL 4,554 PROGRAM VARIANTS")
    print("   253 programs × 3 intensities × 6 durations = 4,554 total variants")
    print("="*100 + "\n")

    start_time = time.time()

    # Connect to database
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)

    try:
        # Fetch all base programs from database
        print("📊 Loading base programs from database...")
        base_programs = await conn.fetch('''
            SELECT id, program_name, program_category, program_subcategory,
                   sessions_per_week, session_duration_minutes, tags, goals, description
            FROM programs
            ORDER BY program_name
        ''')

        print(f"✅ Loaded {len(base_programs)} base programs\n")

        # Calculate total variants
        total_variants = len(base_programs) * len(INTENSITY_LEVELS) * len(DURATION_WEEKS)
        print(f"🎯 Target: {total_variants} variants\n")

        # Create semaphore to limit concurrent API calls (8 at a time to avoid rate limits)
        semaphore = asyncio.Semaphore(8)

        # Create tasks for all variants
        print(f"🚀 Starting parallel generation...\n")

        tasks = []
        index = 1

        for base_program in base_programs:
            for intensity in INTENSITY_LEVELS:
                for duration_weeks in DURATION_WEEKS:
                    task = generate_and_insert_variant(
                        conn,
                        base_program['id'],
                        dict(base_program),
                        intensity,
                        duration_weeks,
                        semaphore,
                        index,
                        total_variants
                    )
                    tasks.append(task)
                    index += 1

        # Execute all tasks concurrently
        await asyncio.gather(*tasks)

        # Summary statistics
        elapsed_time = time.time() - start_time
        total_inserted = await conn.fetchval('SELECT COUNT(*) FROM program_variants')
        avg_tokens = await conn.fetchval('SELECT AVG(generation_tokens) FROM program_variants WHERE generation_tokens IS NOT NULL')
        total_cost = await conn.fetchval('SELECT SUM(generation_cost_usd) FROM program_variants')

        print("\n" + "="*100)
        print("🎉 VARIANT GENERATION COMPLETE!")
        print("="*100)
        print(f"⏱️  Total time: {elapsed_time:.1f} seconds ({elapsed_time/60:.1f} minutes / {elapsed_time/3600:.1f} hours)")
        print(f"📊 Variants generated: {total_inserted}/{total_variants}")
        print(f"💰 Estimated total cost: ${total_cost:.2f}")
        print(f"🤖 Average tokens per variant: {avg_tokens:.0f}" if avg_tokens else "🤖 Token data not available")
        print(f"⚡ Average time per variant: {elapsed_time/total_variants:.1f}s")
        print("="*100 + "\n")

        # Breakdown by intensity
        print("📊 Breakdown by intensity:")
        for intensity in INTENSITY_LEVELS:
            count = await conn.fetchval('SELECT COUNT(*) FROM program_variants WHERE intensity_level = $1', intensity)
            print(f"   • {intensity}: {count} variants")

        # Breakdown by duration
        print("\n📊 Breakdown by duration:")
        for duration in DURATION_WEEKS:
            count = await conn.fetchval('SELECT COUNT(*) FROM program_variants WHERE duration_weeks = $1', duration)
            print(f"   • {duration} weeks: {count} variants")

        # Sample verification
        print("\n🔍 Sample variants:")
        samples = await conn.fetch('''
            SELECT variant_name, intensity_level, duration_weeks,
                   jsonb_array_length(workouts->'workouts') as workout_count
            FROM program_variants
            LIMIT 5
        ''')
        for row in samples:
            print(f"   • {row['variant_name']} - {row['workout_count']} workouts")

        print("\n✨ All variants ready to serve via API!\n")

    finally:
        await conn.close()


if __name__ == "__main__":
    print(f"🕐 Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    asyncio.run(main())
    print(f"🕐 Finished at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
