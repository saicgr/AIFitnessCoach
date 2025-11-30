import asyncio
import os
import json
from dotenv import load_dotenv
import asyncpg

load_dotenv()

async def verify_programs():
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)
    
    try:
        # Load catalog
        with open('/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/all_programs_catalog.json', 'r') as f:
            catalog = json.load(f)
        
        # Get inserted program names
        rows = await conn.fetch('SELECT program_name FROM programs')
        inserted_names = {row['program_name'] for row in rows}
        
        # Find missing programs
        catalog_names = {p['program_name'] for p in catalog}
        missing = catalog_names - inserted_names
        
        print(f"Catalog: {len(catalog_names)} programs")
        print(f"Inserted: {len(inserted_names)} programs")
        print(f"Missing: {len(missing)} programs")
        
        if missing:
            print("\nMissing programs:")
            for name in sorted(missing):
                print(f"  - {name}")
        
        # Show sample program with workouts
        print("\nSample program (Brad Pitt Fight Club):")
        sample = await conn.fetchrow(
            "SELECT workouts FROM programs WHERE program_name = 'Brad Pitt Fight Club Workout'"
        )
        if sample:
            workouts = json.loads(sample['workouts'])
            print(json.dumps(workouts, indent=2)[:1000] + "...")
    
    finally:
        await conn.close()

asyncio.run(verify_programs())
