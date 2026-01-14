"""Check if activity_feed table exists and has the correct columns."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client
from dotenv import load_dotenv
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")

def main():
    print(f"Connecting to Supabase: {SUPABASE_URL}")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Try to select from activity_feed
    print("\n1. Checking activity_feed table...")
    try:
        result = supabase.table("activity_feed").select("*").limit(1).execute()
        print(f"   ✅ Table exists!")
        if result.data:
            print(f"   Sample row columns: {list(result.data[0].keys())}")
        else:
            print("   Table is empty")
    except Exception as e:
        print(f"   ❌ Error: {e}")

    # Check user_connections table
    print("\n2. Checking user_connections table...")
    try:
        result = supabase.table("user_connections").select("*").limit(1).execute()
        print(f"   ✅ Table exists!")
        if result.data:
            print(f"   Sample row columns: {list(result.data[0].keys())}")
        else:
            print("   Table is empty")
    except Exception as e:
        print(f"   ❌ Error: {e}")

    # Try the exact query from the feed endpoint
    print("\n3. Testing feed query for user 1f9ce4be-ca76-4bcc-87bf-fad294fce635...")
    user_id = "1f9ce4be-ca76-4bcc-87bf-fad294fce635"

    try:
        # Get following list
        following_result = supabase.table("user_connections").select("following_id").eq(
            "follower_id", user_id
        ).eq("status", "active").execute()
        print(f"   Following count: {len(following_result.data)}")

        following_ids = [row["following_id"] for row in following_result.data]
        following_ids.append(user_id)
        print(f"   User IDs to query: {following_ids}")

        # Query activity_feed
        result = supabase.table("activity_feed").select(
            "*",
            count="exact"
        ).in_("user_id", following_ids).order("created_at", desc=True).range(0, 19).execute()

        print(f"   ✅ Query succeeded!")
        print(f"   Total activities: {result.count}")
        print(f"   Activities returned: {len(result.data)}")

        if result.data:
            print(f"   First activity: {result.data[0]}")

    except Exception as e:
        print(f"   ❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
