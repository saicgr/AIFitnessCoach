"""
Add sample features to the feature_requests table for testing the voting system.
"""
import sys
import os
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from supabase import create_client

# Supabase credentials
SUPABASE_URL = "https://hpbzfahijszqmgsybuor.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhwYnpmYWhpanN6cW1nc3lidW9yIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzQ1NjQ1MywiZXhwIjoyMDQ5MDMyNDUzfQ.MWU3r9ZB-9uFQnfM6rB8eaUd1M5gW58sxo8c2K5bfcI"

def main():
    """Insert sample features into the database."""
    client = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Sample features to insert
    features = [
        {
            "title": "Social Workout Sharing",
            "description": "Share your workout summaries with friends and on social media with beautiful recap images",
            "category": "social",
            "status": "planned",
            "vote_count": 42,
            "release_date": (datetime.now() + timedelta(days=3)).isoformat(),
        },
        {
            "title": "Advanced Nutrition Tracking",
            "description": "Track macros, calories, and get AI-powered meal suggestions based on your workout plan",
            "category": "nutrition",
            "status": "voting",
            "vote_count": 28,
        },
        {
            "title": "Apple Watch Integration",
            "description": "Track your workouts directly from your Apple Watch with real-time heart rate and calorie tracking",
            "category": "integration",
            "status": "planned",
            "vote_count": 35,
            "release_date": (datetime.now() + timedelta(days=7)).isoformat(),
        },
        {
            "title": "Custom Exercise Creator",
            "description": "Create and save your own custom exercises with video demos",
            "category": "workout",
            "status": "planned",
            "vote_count": 19,
            "release_date": (datetime.now() + timedelta(days=14)).isoformat(),
        },
    ]

    print(f"Inserting {len(features)} sample features...")

    for feature in features:
        try:
            result = client.table("feature_requests").insert(feature).execute()
            print(f"✅ Inserted: {feature['title']} ({feature['status']})")
            if feature.get('release_date'):
                print(f"   Release date: {feature['release_date']}")
        except Exception as e:
            print(f"❌ Error inserting {feature['title']}: {e}")

    # Verify insertion
    print("\nVerifying features in database...")
    result = client.table("feature_requests").select("id, title, status, vote_count, release_date").execute()
    print(f"\nTotal features in database: {len(result.data)}")
    for f in result.data:
        print(f"  - {f['title']} ({f['status']}, {f['vote_count']} votes)")

if __name__ == "__main__":
    main()
