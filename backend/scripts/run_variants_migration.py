"""
Run the program_variants table migration
"""
import asyncio
import os
from dotenv import load_dotenv
import asyncpg

load_dotenv()


async def run_migration():
    """Execute the program_variants migration"""

    db_url = os.getenv('DATABASE_URL').replace('postgresql+asyncpg://', 'postgresql://')

    # Read migration SQL
    with open('/Users/saichetangrandhe/AIFitnessCoach/backend/migrations/002_add_program_variants.sql', 'r') as f:
        sql_content = f.read()

    # Connect and execute
    conn = await asyncpg.connect(db_url)

    try:
        print("🔧 Running program_variants table migration...")
        await conn.execute(sql_content)
        print("✅ Migration completed successfully\n")

        # Verify table was created
        rows = await conn.fetch('''
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'program_variants'
            ORDER BY ordinal_position
        ''')

        print("📋 program_variants table columns:")
        for row in rows:
            nullable = "NULL" if row['is_nullable'] == 'YES' else "NOT NULL"
            print(f"   - {row['column_name']:<30} {row['data_type']:<20} {nullable}")

        # Check indexes
        rows = await conn.fetch('''
            SELECT indexname
            FROM pg_indexes
            WHERE tablename = 'program_variants'
        ''')

        print(f"\n📊 Indexes created: {len(rows)}")
        for row in rows:
            print(f"   - {row['indexname']}")

        print("\n✨ Ready to generate 4,554 program variants!\n")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(run_migration())
