"""
Execute programs table SQL script using asyncpg directly
"""
import asyncio
import os
from dotenv import load_dotenv
import asyncpg

load_dotenv()


async def execute_sql_script():
    """Execute the programs table SQL script using asyncpg"""

    # Parse DATABASE_URL to get connection params
    # postgresql+asyncpg://postgres:password@host:port/database
    db_url = os.getenv('DATABASE_URL')
    # Remove the prefix
    db_url = db_url.replace('postgresql+asyncpg://', 'postgresql://')

    with open('/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/create_programs_table.sql', 'r') as f:
        sql_content = f.read()

    # Connect to database
    conn = await asyncpg.connect(db_url)

    try:
        # Execute the entire SQL file
        print("Executing programs table SQL...")
        await conn.execute(sql_content)
        print("\n✅ Programs table created successfully\n")

        # Verify table structure
        rows = await conn.fetch('''
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'programs'
            ORDER BY ordinal_position
        ''')

        print("📋 Programs table columns:")
        for row in rows:
            nullable = "NULL" if row['is_nullable'] == 'YES' else "NOT NULL"
            print(f"   - {row['column_name']:<30} {row['data_type']:<20} {nullable}")

        # Check indexes
        rows = await conn.fetch('''
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE tablename = 'programs'
        ''')

        print("\n📊 Table indexes:")
        for row in rows:
            print(f"   - {row['indexname']}")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(execute_sql_script())
