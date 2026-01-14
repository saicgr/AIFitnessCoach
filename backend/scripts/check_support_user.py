"""
Script to check if support user exists and create it if needed.
Also backfills support user as friend to all existing users.
"""
import os
import sys
from datetime import datetime, timezone

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client

# Load environment
from dotenv import load_dotenv
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")

SUPPORT_EMAIL = "support@fitwiz.us"
SUPPORT_NAME = "FitWiz Support"

def main():
    print(f"Connecting to Supabase: {SUPABASE_URL}")
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Check if support user exists
    print(f"\n1. Checking for support user (email: {SUPPORT_EMAIL})...")
    result = supabase.table("users").select("*").eq("email", SUPPORT_EMAIL).execute()

    support_user = None
    if result.data:
        support_user = result.data[0]
        print(f"   ✅ Support user exists: {support_user['id']}")
        print(f"      - Name: {support_user.get('name')}")
        print(f"      - is_support_user: {support_user.get('is_support_user')}")
        print(f"      - role: {support_user.get('role')}")

        # Update if needed
        updates = {}
        if not support_user.get('is_support_user'):
            updates['is_support_user'] = True
        if support_user.get('role') != 'admin':
            updates['role'] = 'admin'
        if support_user.get('name') != SUPPORT_NAME:
            updates['name'] = SUPPORT_NAME

        if updates:
            print(f"\n   Updating support user with: {updates}")
            supabase.table("users").update(updates).eq("id", support_user['id']).execute()
            print("   ✅ Updated")
    else:
        print("   ❌ Support user does NOT exist")
        print("   You need to sign up with support@fitwiz.us first")
        return

    # Check existing connections
    print(f"\n2. Checking support user connections...")
    connections = supabase.table("user_connections").select("*").or_(
        f"follower_id.eq.{support_user['id']},following_id.eq.{support_user['id']}"
    ).execute()
    print(f"   Found {len(connections.data)} connections involving support user")

    # Get all users except support
    print(f"\n3. Getting all users to backfill...")
    all_users = supabase.table("users").select("id, email, name").neq("id", support_user['id']).execute()
    print(f"   Found {len(all_users.data)} users (excluding support)")

    # Backfill connections
    print(f"\n4. Backfilling support user as friend to all users...")
    created_count = 0
    for user in all_users.data:
        user_id = user['id']

        # Check if connection exists (support -> user)
        existing1 = supabase.table("user_connections").select("id").eq(
            "follower_id", support_user['id']
        ).eq("following_id", user_id).execute()

        # Check if connection exists (user -> support)
        existing2 = supabase.table("user_connections").select("id").eq(
            "follower_id", user_id
        ).eq("following_id", support_user['id']).execute()

        now = datetime.now(timezone.utc).isoformat()

        if not existing1.data:
            supabase.table("user_connections").insert({
                "follower_id": support_user['id'],
                "following_id": user_id,
                "connection_type": "friend",
                "status": "active",
                "created_at": now,
            }).execute()
            print(f"   ✅ Created: support -> {user.get('name', user_id)}")
            created_count += 1

        if not existing2.data:
            supabase.table("user_connections").insert({
                "follower_id": user_id,
                "following_id": support_user['id'],
                "connection_type": "friend",
                "status": "active",
                "created_at": now,
            }).execute()
            print(f"   ✅ Created: {user.get('name', user_id)} -> support")
            created_count += 1

    print(f"\n✅ Done! Created {created_count} new connections")

    # Also send welcome messages if needed
    print(f"\n5. Checking for users without welcome messages...")
    for user in all_users.data:
        user_id = user['id']

        # Check if conversation exists
        conv = supabase.table("conversation_participants").select(
            "conversation_id"
        ).eq("user_id", user_id).execute()

        # Check if any of those conversations include support user
        has_support_conv = False
        for c in conv.data:
            participants = supabase.table("conversation_participants").select("user_id").eq(
                "conversation_id", c['conversation_id']
            ).execute()
            participant_ids = [p['user_id'] for p in participants.data]
            if support_user['id'] in participant_ids:
                has_support_conv = True
                break

        if not has_support_conv:
            print(f"   User {user.get('name', user_id)} has no conversation with support - creating...")
            # Create conversation
            conv_insert = supabase.table("conversations").insert({
                "created_at": datetime.now(timezone.utc).isoformat(),
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "last_message_at": datetime.now(timezone.utc).isoformat(),
            }).execute()

            if conv_insert.data:
                conv_id = conv_insert.data[0]['id']

                # Add participants
                supabase.table("conversation_participants").insert([
                    {"conversation_id": conv_id, "user_id": support_user['id']},
                    {"conversation_id": conv_id, "user_id": user_id},
                ]).execute()

                # Send welcome message
                welcome_message = (
                    "Welcome to FitWiz! 🎉\n\n"
                    "I'm here to help you on your fitness journey. "
                    "If you have any questions about the app, need workout tips, "
                    "or just want to chat about your fitness goals, feel free to message me anytime!\n\n"
                    "Let's get started on building a healthier you! 💪"
                )

                supabase.table("direct_messages").insert({
                    "conversation_id": conv_id,
                    "sender_id": support_user['id'],
                    "content": welcome_message,
                    "is_system_message": False,
                    "created_at": datetime.now(timezone.utc).isoformat(),
                }).execute()

                print(f"   ✅ Created conversation and sent welcome message to {user.get('name', user_id)}")

    print("\n✅ All done!")


if __name__ == "__main__":
    main()
