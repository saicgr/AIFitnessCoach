import asyncio
import os
import json
from dotenv import load_dotenv
import asyncpg

load_dotenv()

async def show_summary():
    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')
    conn = await asyncpg.connect(db_url)
    
    try:
        # Total counts
        total = await conn.fetchval('SELECT COUNT(*) FROM programs')
        with_workouts = await conn.fetchval(
            "SELECT COUNT(*) FROM programs WHERE workouts IS NOT NULL AND workouts::text != '{\"workouts\":[]}'"
        )
        
        print("="*80)
        print(" "*25 + "PROGRAM GENERATION COMPLETE!")
        print("="*80)
        print(f"\n📊 Total Programs: {total}/253")
        print(f"✅ Programs with Workouts: {with_workouts}")
        print(f"⚠️  Programs without Workouts: {total - with_workouts}\n")
        
        # Category breakdown
        print("="*80)
        print("PROGRAMS BY CATEGORY")
        print("="*80)
        categories = await conn.fetch(
            "SELECT program_category, COUNT(*) as count FROM programs GROUP BY program_category ORDER BY count DESC"
        )
        for row in categories:
            print(f"  {row['program_category']}: {row['count']} programs")
        
        # Sample programs from different categories
        print("\n" + "="*80)
        print("SAMPLE PROGRAMS")
        print("="*80)
        
        samples = await conn.fetch("""
            SELECT program_name, program_category, difficulty_level, 
                   duration_weeks, sessions_per_week,
                   jsonb_array_length(workouts->'workouts') as workout_count
            FROM programs 
            WHERE program_name IN (
                'Brad Pitt Fight Club Workout',
                'Virat Kohli Fitness Regime',
                'Beginner Yoga Fundamentals',
                'PCOS Weight Management',
                'Daily 10-Minute Stretches Easy',
                'Lower Back Pain Relief Foundation',
                'Navy SEAL Conditioning',
                'Astronaut Fitness Training',
                'Parkinsons Disease Movement'
            )
            ORDER BY program_category, program_name
        """)
        
        for row in samples:
            print(f"\n📋 {row['program_name']}")
            print(f"   Category: {row['program_category']}")
            print(f"   Difficulty: {row['difficulty_level']}")
            print(f"   Duration: {row['duration_weeks']} weeks | {row['sessions_per_week']} sessions/week")
            print(f"   Workouts: {row['workout_count']} unique workouts")
        
        print("\n" + "="*80)
        
    finally:
        await conn.close()

asyncio.run(show_summary())
