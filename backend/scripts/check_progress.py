import asyncio
import os
from dotenv import load_dotenv
import asyncpg

load_dotenv()

async def check_progress():
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)
    
    try:
        total = await conn.fetchval('SELECT COUNT(*) FROM programs')
        with_workouts = await conn.fetchval(
            "SELECT COUNT(*) FROM programs WHERE workouts IS NOT NULL AND workouts::text != '{\"workouts\":[]}'"
        )
        
        print(f"Progress: {total} programs inserted ({with_workouts} with workouts)")
        
        if total > 0:
            print("\nMost recent 5 programs:")
            recent = await conn.fetch(
                "SELECT program_name, jsonb_array_length(workouts->'workouts') as workout_count FROM programs ORDER BY created_at DESC LIMIT 5"
            )
            for row in recent:
                print(f"  - {row['program_name']}: {row['workout_count']} workouts")
    
    finally:
        await conn.close()

asyncio.run(check_progress())
