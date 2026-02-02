#!/usr/bin/env python3
"""
Run migrations 201-204 for warmup/stretch preferences and custom exercises.

Migrations:
- 201: warmup_stretch_preferences table
- 202: custom_exercises table
- 203: cardio machine exercises (~25 exercises)
- 204: weight machine exercises (~37 exercises)
"""

import os
import sys
import re
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2 import sql

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Parse DATABASE_URL (convert from asyncpg format to psycopg2)
DATABASE_URL = os.getenv("DATABASE_URL", "")
# Convert postgresql+asyncpg:// to postgresql://
DB_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

MIGRATIONS = [
    ("201_warmup_stretch_preferences.sql", "Warmup/stretch preferences table"),
    ("202_custom_exercises.sql", "Custom exercises table with view"),
    ("203_cardio_machine_exercises.sql", "Cardio machine exercises (~25)"),
    ("204_weight_machine_exercises.sql", "Weight machine exercises (~37)"),
]


def parse_sql_statements(sql_content: str) -> list:
    """
    Parse SQL into individual statements.
    Handles dollar-quoted strings (for functions) and regular statements.
    """
    statements = []
    current_stmt = []
    in_dollar_quote = False
    dollar_tag = None

    lines = sql_content.split('\n')

    for line in lines:
        stripped = line.strip()

        # Skip pure comment lines when not in a statement
        if not current_stmt and stripped.startswith('--'):
            continue

        # Check for dollar quote start/end
        if not in_dollar_quote:
            # Look for $$ or $tag$ start
            match = re.search(r'\$([a-zA-Z_]*)\$', line)
            if match:
                in_dollar_quote = True
                dollar_tag = match.group()
        elif dollar_tag:
            # Count occurrences of dollar tag in current statement + this line
            full_text = '\n'.join(current_stmt) + '\n' + line
            count = full_text.count(dollar_tag)
            if count >= 2:
                in_dollar_quote = False
                dollar_tag = None

        current_stmt.append(line)

        # If we're not in a dollar quote and line ends with semicolon, end statement
        if not in_dollar_quote and stripped.endswith(';'):
            stmt_text = '\n'.join(current_stmt).strip()
            # Skip if it's only comments
            non_comment_lines = [l for l in stmt_text.split('\n') if l.strip() and not l.strip().startswith('--')]
            if non_comment_lines:
                statements.append(stmt_text)
            current_stmt = []

    # Handle any remaining statement
    if current_stmt:
        stmt_text = '\n'.join(current_stmt).strip()
        non_comment_lines = [l for l in stmt_text.split('\n') if l.strip() and not l.strip().startswith('--')]
        if non_comment_lines:
            statements.append(stmt_text)

    return statements


def run_migration(cursor, sql_content: str, filename: str) -> tuple:
    """Run a migration file and return (success_count, failed_count)."""
    statements = parse_sql_statements(sql_content)
    success = 0
    failed = 0

    print(f"   Found {len(statements)} statements")

    for i, stmt in enumerate(statements, 1):
        try:
            cursor.execute(stmt)
            print(f"   ✅ Statement {i} OK")
            success += 1
        except psycopg2.Error as e:
            error_msg = str(e).lower()
            if "already exists" in error_msg:
                print(f"   ⏭️  Statement {i} - already exists")
                success += 1
            elif "duplicate key" in error_msg:
                print(f"   ⏭️  Statement {i} - duplicate (already inserted)")
                success += 1
            elif "does not exist" in error_msg and ("drop" in stmt.lower()[:20] or "trigger" in error_msg):
                print(f"   ⏭️  Statement {i} - doesn't exist (OK for DROP)")
                success += 1
            else:
                print(f"   ❌ Statement {i} FAILED: {str(e)[:150]}")
                failed += 1
                # Continue to next statement
            # Reset the connection state for next statement
            cursor.connection.rollback()
        except Exception as e:
            print(f"   ❌ Statement {i} FAILED: {str(e)[:150]}")
            failed += 1
            cursor.connection.rollback()

    return success, failed


def main():
    print("=" * 60)
    print("🔄 RUNNING MIGRATIONS 201-204")
    print("=" * 60)
    print(f"Database: {DB_URL[:50]}...")

    if not DB_URL:
        print("❌ DATABASE_URL not set")
        return 1

    migrations_dir = Path(__file__).parent.parent / "migrations"

    total_success = 0
    total_failed = 0

    try:
        # Connect to database
        conn = psycopg2.connect(DB_URL)
        conn.autocommit = True  # Each statement runs independently
        cursor = conn.cursor()

        for filename, description in MIGRATIONS:
            filepath = migrations_dir / filename

            if not filepath.exists():
                print(f"\n⚠️  {filename} - NOT FOUND")
                continue

            print(f"\n📄 {filename}")
            print(f"   {description}")

            with open(filepath) as f:
                sql_content = f.read()

            success, failed = run_migration(cursor, sql_content, filename)
            total_success += success
            total_failed += failed

        cursor.close()
        conn.close()

    except psycopg2.Error as e:
        print(f"\n❌ Database connection failed: {e}")
        return 1

    print("\n" + "=" * 60)
    print(f"✅ MIGRATIONS COMPLETE: {total_success} succeeded, {total_failed} failed")
    print("=" * 60)

    if total_failed > 0:
        print("\n⚠️  Some statements failed. Check the errors above.")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
