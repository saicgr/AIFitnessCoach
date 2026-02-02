#!/usr/bin/env python3
"""
Run migration 208: Add AI input source tracking to performance_logs.

This migration adds:
- ai_input_source: TEXT column to track original AI input text (e.g., "135*8", "+10", "same")
- Index for analytics queries on AI-created sets
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
    print("=" * 60)
    print("RUNNING MIGRATION 208: AI INPUT SOURCE TRACKING")
    print("=" * 60)

    if not DB_URL:
        print("[ERROR] DATABASE_URL not set")
        return 1

    migrations_dir = Path(__file__).parent.parent / "migrations"
    filepath = migrations_dir / "208_ai_input_source_tracking.sql"

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

        for i, stmt in enumerate(statements, 1):
            # Skip comment-only statements
            lines = [l for l in stmt.split('\n') if l.strip() and not l.strip().startswith('--')]
            if not lines:
                continue

            try:
                cursor.execute(stmt + ';')
                print(f"   [OK] Statement {i} executed successfully")
            except psycopg2.Error as e:
                error_msg = str(e).lower()
                if "already exists" in error_msg or "duplicate" in error_msg:
                    print(f"   [SKIP] Statement {i} - already exists (OK)")
                else:
                    print(f"   [ERROR] Statement {i} FAILED: {e}")
                conn.rollback()

        # Verify the migration worked - check if column exists
        cursor.execute("""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'performance_logs'
            AND column_name = 'ai_input_source';
        """)
        result = cursor.fetchone()
        if result:
            print(f"\n[VERIFY] Column 'ai_input_source' exists:")
            print(f"   - Data type: {result[1]}")
            print(f"   - Nullable: {result[2]}")
        else:
            print("\n[WARNING] Column 'ai_input_source' not found in performance_logs")

        # Check if index exists
        cursor.execute("""
            SELECT indexname
            FROM pg_indexes
            WHERE tablename = 'performance_logs'
            AND indexname = 'idx_performance_logs_ai_input_source';
        """)
        idx_result = cursor.fetchone()
        if idx_result:
            print(f"[VERIFY] Index 'idx_performance_logs_ai_input_source' exists")
        else:
            print("[WARNING] Index 'idx_performance_logs_ai_input_source' not found")

        cursor.close()
        conn.close()

        print("\n" + "=" * 60)
        print("[SUCCESS] MIGRATION 208 COMPLETE")
        print("=" * 60)
        return 0

    except psycopg2.Error as e:
        print(f"\n[ERROR] Database error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
