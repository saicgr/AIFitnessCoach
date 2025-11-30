import asyncio
import os
from dotenv import load_dotenv
import asyncpg

load_dotenv()

async def query():
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)
    
    try:
        rows = await conn.fetch("""
            SELECT program_name, celebrity_name, program_category, country
            FROM programs
            WHERE 'India' = ANY(country)
            ORDER BY program_category, program_name
        """)
        
        print(f"Found {len(rows)} programs with India in country:\n")
        
        current_category = None
        for row in rows:
            if row['program_category'] != current_category:
                current_category = row['program_category']
                print(f"\n{current_category}:")
            print(f"  - {row['program_name']}")
            if row['celebrity_name']:
                print(f"    Celebrity: {row['celebrity_name']}")
    
    finally:
        await conn.close()

asyncio.run(query())
