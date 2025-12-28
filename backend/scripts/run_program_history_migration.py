#!/usr/bin/env python3
"""
Run the program_history table migration
"""
import os
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from core.supabase_client import get_supabase_client

def run_migration():
    """Execute the program_history table creation"""
    print("🔄 Running program_history table migration...")
    
    # Read SQL file
    sql_file = Path(__file__).parent.parent / "migrations" / "create_program_history_table.sql"
    with open(sql_file, 'r') as f:
        sql = f.read()
    
    # Execute via Supabase
    supabase = get_supabase_client()
    
    try:
        # Execute the SQL
        result = supabase.rpc('exec_sql', {'sql_query': sql}).execute()
        print("✅ program_history table created successfully!")
        print(f"   Result: {result}")
        return True
    except Exception as e:
        # Table might already exist, try direct SQL execution
        print(f"⚠️  RPC failed, trying direct execution: {e}")
        try:
            # Split and execute statements individually
            statements = [s.strip() for s in sql.split(';') if s.strip()]
            for stmt in statements:
                if stmt:
                    supabase.postgrest.rpc('exec_sql', {'sql_query': stmt}).execute()
            print("✅ Migration completed via direct execution")
            return True
        except Exception as e2:
            print(f"❌ Migration failed: {e2}")
            print("\n📋 Please run this SQL manually in Supabase SQL Editor:")
            print("=" * 80)
            print(sql)
            print("=" * 80)
            return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
