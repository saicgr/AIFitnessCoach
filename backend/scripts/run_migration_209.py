#!/usr/bin/env python3
"""
Run migration 209: Food Analysis Caching System.

This migration adds:
- food_analysis_cache: Caches Gemini AI food analysis responses (100s -> <2s)
- common_foods: Pre-computed nutrition for ~50 common foods (bypasses AI entirely)
- rag_context_cache: Caches RAG context by user goal hash
- RLS policies for service-only access
- 50+ seeded common foods with accurate nutrition data
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Parse DATABASE_URL (convert from asyncpg format to psycopg2)
DATABASE_URL = os.getenv("DATABASE_URL", "")
DB_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")


def main():
    print("=" * 70)
    print("RUNNING MIGRATION 209: FOOD ANALYSIS CACHING SYSTEM")
    print("=" * 70)
    print()
    print("This migration will dramatically speed up food logging:")
    print("  - First time query: 30-60s (AI analysis)")
    print("  - Repeat query: < 2s (cache hit)")
    print("  - Common foods: < 1s (bypasses AI)")
    print()

    if not DB_URL:
        print("[ERROR] DATABASE_URL not set")
        return 1

    migrations_dir = Path(__file__).parent.parent / "migrations"
    filepath = migrations_dir / "209_food_analysis_caching.sql"

    if not filepath.exists():
        print(f"[ERROR] Migration file not found: {filepath}")
        return 1

    print(f"[INFO] Reading {filepath.name}")

    with open(filepath) as f:
        sql_content = f.read()

    try:
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True
        cursor = conn.cursor()

        # Split by semicolons and execute each statement
        statements = [s.strip() for s in sql_content.split(';') if s.strip()]

        success_count = 0
        skip_count = 0
        error_count = 0

        for i, stmt in enumerate(statements, 1):
            # Skip comment-only statements
            lines = [l for l in stmt.split('\n') if l.strip() and not l.strip().startswith('--')]
            if not lines:
                continue

            try:
                cursor.execute(stmt + ';')
                success_count += 1
                # Show abbreviated statement
                stmt_preview = stmt[:60].replace('\n', ' ') + ('...' if len(stmt) > 60 else '')
                print(f"   [OK] Statement {i}: {stmt_preview}")
            except psycopg2.Error as e:
                error_msg = str(e).lower()
                if "already exists" in error_msg or "duplicate" in error_msg:
                    skip_count += 1
                    print(f"   [SKIP] Statement {i} - already exists (OK)")
                else:
                    error_count += 1
                    print(f"   [ERROR] Statement {i} FAILED: {e}")
                conn.rollback()

        print()
        print("-" * 70)
        print("VERIFICATION")
        print("-" * 70)

        # Verify tables exist
        tables_to_check = ['food_analysis_cache', 'common_foods', 'rag_context_cache']
        for table in tables_to_check:
            cursor.execute(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_name = '{table}'
                );
            """)
            exists = cursor.fetchone()[0]
            status = "✅" if exists else "❌"
            print(f"   {status} Table '{table}' exists: {exists}")

        # Count seeded common foods
        try:
            cursor.execute("SELECT COUNT(*) FROM common_foods;")
            food_count = cursor.fetchone()[0]
            print(f"   📊 Common foods seeded: {food_count}")
        except Exception as e:
            print(f"   ⚠️ Could not count common_foods: {e}")

        # Show a few common foods as sample
        try:
            cursor.execute("""
                SELECT name, calories, protein_g, category
                FROM common_foods
                ORDER BY name
                LIMIT 5;
            """)
            foods = cursor.fetchall()
            if foods:
                print()
                print("   Sample common foods:")
                for food in foods:
                    print(f"      - {food[0]}: {food[1]} cal, {food[2]}g protein ({food[3]})")
        except Exception:
            pass

        # Check indexes
        cursor.execute("""
            SELECT indexname
            FROM pg_indexes
            WHERE tablename IN ('food_analysis_cache', 'common_foods', 'rag_context_cache')
            ORDER BY indexname;
        """)
        indexes = cursor.fetchall()
        print()
        print(f"   📇 Indexes created: {len(indexes)}")
        for idx in indexes:
            print(f"      - {idx[0]}")

        cursor.close()
        conn.close()

        print()
        print("=" * 70)
        print(f"MIGRATION 209 COMPLETE")
        print(f"   Successful: {success_count}")
        print(f"   Skipped: {skip_count}")
        print(f"   Errors: {error_count}")
        print("=" * 70)

        return 0 if error_count == 0 else 1

    except psycopg2.Error as e:
        print(f"\n[ERROR] Database error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
