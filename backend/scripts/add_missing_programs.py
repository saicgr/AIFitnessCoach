import asyncio
import os
import json
from dotenv import load_dotenv
import asyncpg
from google import genai
from google.genai import types

load_dotenv()

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
model_name = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash')

MISSING_PROGRAMS = [
    "Arthritis-Friendly Movement",
    "Figure Competition Prep Women",
    "PCOS Strength & Insulin Sensitivity",
    "Ultra Marathon 50K Training"
]

async def generate_workout(program: dict) -> dict:
    """Generate workout using Gemini"""
    prompt = f"""You are a professional fitness coach. Return only valid JSON.

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
- workout_name (descriptive)
- day (1-{program['sessions_per_week']})
- type (Strength/Cardio/HIIT/Yoga/Stretching/etc.)
- exercises array with 5-10 exercises per workout

Return ONLY valid JSON:
{{
  "workouts": [
    {{
      "workout_name": "Full Body Strength",
      "day": 1,
      "type": "Strength",
      "exercises": [
        {{"exercise_name": "Barbell Squat", "sets": 4, "reps": "8-10", "rest_seconds": 120, "notes": "Keep chest up"}}
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

        if "```json" in content:
            content = content.split("```json")[1].split("```")[0].strip()
        elif "```" in content:
            content = content.split("```")[1].split("```")[0].strip()

        return json.loads(content)

    except Exception as e:
        print(f"Error: {e}")
        return {"workouts": []}

async def main():
    # Load catalog
    with open('/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/all_programs_catalog.json', 'r') as f:
        catalog = json.load(f)
    
    # Find missing programs in catalog
    programs_to_add = [p for p in catalog if p['program_name'] in MISSING_PROGRAMS]
    
    print(f"Found {len(programs_to_add)} missing programs to add\n")
    
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)
    
    try:
        for i, program in enumerate(programs_to_add, 1):
            print(f"[{i}/{len(programs_to_add)}] Generating {program['program_name']}...")
            
            workouts = await generate_workout(program)
            
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
            print(f"  ✅ Added with {workout_count} workouts\n")
            
            await asyncio.sleep(1)
        
        # Final count
        total = await conn.fetchval('SELECT COUNT(*) FROM programs')
        with_workouts = await conn.fetchval(
            "SELECT COUNT(*) FROM programs WHERE workouts IS NOT NULL AND workouts::text != '{\"workouts\":[]}'"
        )
        
        print(f"✅ Complete! Total: {total} programs ({with_workouts} with workouts)")
        
    finally:
        await conn.close()

asyncio.run(main())
