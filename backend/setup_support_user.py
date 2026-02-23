#!/usr/bin/env python3
"""
Set up the support@fitwiz.us admin user in Supabase and the backend database.
This script should be run once to create the admin user.
"""
import os
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

import requests
import psycopg2
from datetime import datetime
import uuid

SUPPORT_EMAIL = "support@fitwiz.us"
SUPPORT_PASSWORD = os.environ.get("SUPPORT_PASSWORD")
if not SUPPORT_PASSWORD:
    raise SystemExit("SUPPORT_PASSWORD environment variable is required")
SUPPORT_NAME = "FitWiz Support"


def setup_support_user():
    """Create the support user in both Supabase Auth and the database."""

    supabase_url = os.getenv("SUPABASE_URL")
    service_role_key = os.getenv("SUPABASE_KEY")  # This should be the service_role key
    db_password = os.getenv("SUPABASE_DB_PASSWORD")

    if not all([supabase_url, service_role_key, db_password]):
        print("Error: Missing required environment variables")
        print("Required: SUPABASE_URL, SUPABASE_KEY (service_role), SUPABASE_DB_PASSWORD")
        sys.exit(1)

    project_ref = supabase_url.replace("https://", "").replace(".supabase.co", "")
    db_host = f"db.{project_ref}.supabase.co"

    # Step 1: Create user in Supabase Auth using Admin API
    print(f"Creating user in Supabase Auth: {SUPPORT_EMAIL}")

    auth_url = f"{supabase_url}/auth/v1/admin/users"
    headers = {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
        "Content-Type": "application/json"
    }

    # Check if user already exists
    list_response = requests.get(
        auth_url,
        headers=headers,
        params={"page": 1, "per_page": 1000}
    )

    if list_response.status_code == 200:
        users = list_response.json().get("users", [])
        existing_user = next((u for u in users if u.get("email") == SUPPORT_EMAIL), None)

        if existing_user:
            print(f"  User already exists in Supabase Auth: {existing_user['id']}")
            supabase_user_id = existing_user['id']

            # Update password for existing user
            print(f"  Updating password for existing user...")
            update_url = f"{supabase_url}/auth/v1/admin/users/{supabase_user_id}"
            update_response = requests.put(
                update_url,
                headers=headers,
                json={
                    "password": SUPPORT_PASSWORD,
                    "email_confirm": True,
                }
            )

            if update_response.status_code == 200:
                print(f"  ✅ Password updated successfully")
            else:
                print(f"  ⚠️  Could not update password: {update_response.status_code}")
                print(f"  Response: {update_response.text}")
        else:
            # Create new user
            create_response = requests.post(
                auth_url,
                headers=headers,
                json={
                    "email": SUPPORT_EMAIL,
                    "password": SUPPORT_PASSWORD,
                    "email_confirm": True,  # Auto-confirm email
                    "user_metadata": {
                        "full_name": SUPPORT_NAME
                    }
                }
            )

            if create_response.status_code in [200, 201]:
                supabase_user_id = create_response.json()["id"]
                print(f"  Created user in Supabase Auth: {supabase_user_id}")
            else:
                print(f"  Error creating user: {create_response.status_code}")
                print(f"  Response: {create_response.text}")
                sys.exit(1)
    else:
        print(f"  Error listing users: {list_response.status_code}")
        print(f"  Response: {list_response.text}")
        sys.exit(1)

    # Step 2: Create/update user in database
    print(f"\nSetting up user in database...")

    try:
        conn = psycopg2.connect(
            host=db_host,
            database="postgres",
            user="postgres",
            password=db_password,
            port=5432,
            sslmode="require"
        )
        conn.autocommit = True
        cursor = conn.cursor()

        # Check if user exists in users table
        cursor.execute("SELECT id FROM users WHERE email = %s", (SUPPORT_EMAIL,))
        result = cursor.fetchone()

        if result:
            user_id = result[0]
            print(f"  User exists in database: {user_id}")

            # Update to ensure admin role, support flag, and auth_id
            cursor.execute("""
                UPDATE users
                SET role = 'admin',
                    is_support_user = true,
                    auth_id = %s,
                    name = %s
                WHERE email = %s
            """, (supabase_user_id, SUPPORT_NAME, SUPPORT_EMAIL))
            print("  Updated user to admin role, support user flag, and auth_id")
        else:
            # Create user in database using Supabase auth ID
            # Note: fitness_level, goals, equipment are NOT NULL columns
            # auth_id is needed for backend to find the user after Supabase auth
            cursor.execute("""
                INSERT INTO users (id, auth_id, email, name, role, is_support_user, fitness_level, goals, equipment, created_at)
                VALUES (%s, %s, %s, %s, 'admin', true, 'advanced', 'stay_active', 'full_gym', NOW())
                ON CONFLICT (id) DO UPDATE SET
                    role = 'admin',
                    is_support_user = true,
                    auth_id = EXCLUDED.auth_id,
                    name = EXCLUDED.name
            """, (supabase_user_id, supabase_user_id, SUPPORT_EMAIL, SUPPORT_NAME))
            print(f"  Created user in database: {supabase_user_id}")

        # Verify the setup
        cursor.execute("""
            SELECT id, email, name, role, is_support_user
            FROM users
            WHERE email = %s
        """, (SUPPORT_EMAIL,))
        user = cursor.fetchone()
        print(f"\n✅ Support user setup complete:")
        print(f"   ID: {user[0]}")
        print(f"   Email: {user[1]}")
        print(f"   Name: {user[2]}")
        print(f"   Role: {user[3]}")
        print(f"   Is Support User: {user[4]}")

        cursor.close()
        conn.close()

        print(f"\n📧 Login credentials:")
        print(f"   Email: {SUPPORT_EMAIL}")
        print(f"   Password: (set via SUPPORT_PASSWORD env var)")
        print(f"\n⚠️  Remember to change the password after first login!")

    except Exception as e:
        print(f"Database error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    setup_support_user()
