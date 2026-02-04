#!/usr/bin/env python3
"""
Test script to verify the daily crate JSON fix is working.

This script tests the claim_daily_crate RPC function directly against Supabase
to verify that the flattened JSON response is properly serialized.
"""

import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

import psycopg2
from supabase import create_client

# Database connection (Supabase PostgreSQL)
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = "d2nHU5oLZ1GCz63B"

# Supabase client
SUPABASE_URL = "https://hpbzfahijszqmgsybuor.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMjE1NTkyNywiZXhwIjoyMDQ3NzMxOTI3fQ.NrC6AGu-GEfhPqqL3_bbbHCIbPO_bxLS2YNBXVV9gLQ"


def test_rpc_directly():
    """Test the RPC function directly via psycopg2."""
    print("=" * 60)
    print("TEST 1: Direct PostgreSQL RPC Call")
    print("=" * 60)

    try:
        conn = psycopg2.connect(
            host=DATABASE_HOST,
            port=DATABASE_PORT,
            dbname=DATABASE_NAME,
            user=DATABASE_USER,
            password=DATABASE_PASSWORD,
            sslmode="require"
        )
        print("✅ Connected to database")

        # Get a test user
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM users LIMIT 1")
            result = cur.fetchone()
            if not result:
                print("❌ No users found in database")
                return False
            test_user_id = result[0]
            print(f"📋 Test user ID: {test_user_id}")

            # Reset the user's daily crate for testing
            cur.execute("""
                UPDATE user_daily_crates
                SET selected_crate = NULL, reward = NULL, claimed_at = NULL
                WHERE user_id = %s AND crate_date = CURRENT_DATE
            """, (test_user_id,))
            conn.commit()
            print("🔄 Reset daily crate for testing")

            # Call the RPC function
            cur.execute("""
                SELECT claim_daily_crate(%s, 'daily')
            """, (test_user_id,))
            result = cur.fetchone()[0]

            print(f"\n📦 RPC Response:")
            print(f"   Raw result: {result}")
            print(f"   Type: {type(result)}")

            # Check if response has flat structure
            if isinstance(result, dict):
                has_reward_type = 'reward_type' in result
                has_reward_amount = 'reward_amount' in result
                has_nested_reward = 'reward' in result and isinstance(result.get('reward'), dict)

                print(f"\n🔍 Structure Check:")
                print(f"   Has 'reward_type': {has_reward_type} {'✅' if has_reward_type else '❌'}")
                print(f"   Has 'reward_amount': {has_reward_amount} {'✅' if has_reward_amount else '❌'}")
                print(f"   Has nested 'reward': {has_nested_reward} {'❌ (should be False)' if has_nested_reward else '✅ (correct)'}")

                if has_reward_type and has_reward_amount and not has_nested_reward:
                    print("\n✅ TEST 1 PASSED: RPC returns flat structure")
                    return True
                else:
                    print("\n❌ TEST 1 FAILED: RPC structure is incorrect")
                    return False
            else:
                print(f"\n❌ TEST 1 FAILED: Expected dict, got {type(result)}")
                return False

    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False
    finally:
        if 'conn' in locals():
            conn.close()


def test_supabase_client():
    """Test the RPC function via Supabase Python client."""
    print("\n" + "=" * 60)
    print("TEST 2: Supabase Python Client RPC Call")
    print("=" * 60)

    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        print("✅ Supabase client initialized")

        # Get a test user
        users_result = supabase.table("users").select("id").limit(1).execute()
        if not users_result.data:
            print("❌ No users found")
            return False

        test_user_id = users_result.data[0]["id"]
        print(f"📋 Test user ID: {test_user_id}")

        # Reset daily crate for testing
        supabase.table("user_daily_crates").update({
            "selected_crate": None,
            "reward": None,
            "claimed_at": None
        }).eq("user_id", test_user_id).eq("crate_date", "today").execute()
        print("🔄 Reset daily crate for testing")

        # Call the RPC - this is where the JSON serialization issue occurred
        print("\n🚀 Calling claim_daily_crate RPC via Supabase client...")

        try:
            result = supabase.rpc(
                "claim_daily_crate",
                {"p_user_id": test_user_id, "p_crate_type": "daily"}
            ).execute()

            print(f"\n📦 RPC Response:")
            print(f"   Data: {result.data}")
            print(f"   Type: {type(result.data)}")

            if result.data:
                data = result.data
                has_reward_type = 'reward_type' in data
                has_reward_amount = 'reward_amount' in data
                has_success = data.get('success') == True

                print(f"\n🔍 Response Check:")
                print(f"   success: {data.get('success')} {'✅' if has_success else '❌'}")
                print(f"   reward_type: {data.get('reward_type')} {'✅' if has_reward_type else '❌'}")
                print(f"   reward_amount: {data.get('reward_amount')} {'✅' if has_reward_amount else '❌'}")

                if has_success and has_reward_type and has_reward_amount:
                    print("\n✅ TEST 2 PASSED: Supabase client receives response correctly!")
                    print("   No 'JSON could not be generated' error!")
                    return True
                else:
                    print("\n❌ TEST 2 FAILED: Response missing expected fields")
                    return False
            else:
                print("\n❌ TEST 2 FAILED: No data in response")
                return False

        except Exception as rpc_error:
            error_str = str(rpc_error)
            if "JSON could not be generated" in error_str:
                print(f"\n❌ TEST 2 FAILED: Still getting JSON serialization error!")
                print(f"   Error: {error_str}")
                return False
            else:
                print(f"\n❌ TEST 2 FAILED: Unexpected error: {rpc_error}")
                return False

    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    print("\n" + "=" * 60)
    print("DAILY CRATE JSON FIX VERIFICATION")
    print("=" * 60)
    print()
    print("This test verifies that migration 230 fixed the JSON")
    print("serialization issue with nested JSONB objects.")
    print()

    test1_passed = test_rpc_directly()
    test2_passed = test_supabase_client()

    print("\n" + "=" * 60)
    print("TEST RESULTS SUMMARY")
    print("=" * 60)
    print(f"  Test 1 (Direct PostgreSQL): {'✅ PASSED' if test1_passed else '❌ FAILED'}")
    print(f"  Test 2 (Supabase Client):   {'✅ PASSED' if test2_passed else '❌ FAILED'}")
    print()

    if test1_passed and test2_passed:
        print("🎉 ALL TESTS PASSED! The fix is working correctly.")
        return True
    else:
        print("⚠️  Some tests failed. Please review the output above.")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
