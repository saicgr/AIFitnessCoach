"""
Export Exercise Popularity Data

Aggregates performance_logs from Supabase to compute exercise popularity scores
for the bundled exercise_popularity.json asset used by the Flutter client.

Score formula: popularity * 0.4 + low_rpe * 0.3 + pr_rate * 0.3
Where:
  - popularity = unique_users / max_unique_users (normalized 0-1)
  - low_rpe = 1 - (avg_rpe / 10) (lower RPE = higher score)
  - pr_rate = pr_count / total_sets (how often users hit PRs)

Usage:
    python scripts/export_exercise_popularity.py

Output:
    ../mobile/flutter/assets/data/exercise_popularity.json
"""
import json
import os
import sys
from collections import defaultdict
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.supabase_client import get_supabase


def export_popularity():
    """Aggregate performance logs and export popularity scores."""
    supabase = get_supabase()

    print("Fetching performance logs...")

    # Fetch performance logs with exercise metadata
    # In production, this would use a Supabase RPC or view for efficiency
    response = supabase.table("performance_logs").select(
        "exercise_name, muscle_group, user_id, rpe, is_pr, goal"
    ).limit(10000).execute()

    if not response.data:
        print("No performance logs found. Using default scores.")
        return

    logs = response.data
    print(f"Processing {len(logs)} logs...")

    # Group by muscle -> goal -> exercise
    # Track: unique_users, rpe_sum, rpe_count, pr_count, total_sets
    stats = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: {
        "users": set(),
        "rpe_sum": 0.0,
        "rpe_count": 0,
        "pr_count": 0,
        "total_sets": 0,
    })))

    for log in logs:
        muscle = (log.get("muscle_group") or "").lower()
        goal = (log.get("goal") or "hypertrophy").lower()
        exercise = (log.get("exercise_name") or "").lower()
        user_id = log.get("user_id", "")
        rpe = log.get("rpe")
        is_pr = log.get("is_pr", False)

        if not muscle or not exercise:
            continue

        entry = stats[muscle][goal][exercise]
        entry["users"].add(user_id)
        entry["total_sets"] += 1
        if rpe is not None:
            entry["rpe_sum"] += float(rpe)
            entry["rpe_count"] += 1
        if is_pr:
            entry["pr_count"] += 1

    # Compute scores
    result = {
        "_source": "Aggregated from anonymized performance logs. Score = popularity*0.4 + low_rpe*0.3 + pr_rate*0.3",
        "_updated": datetime.now().strftime("%Y-%m-%d"),
    }

    for muscle, goals in stats.items():
        result[muscle] = {}
        for goal, exercises in goals.items():
            # Find max unique users for normalization
            max_users = max(
                (len(e["users"]) for e in exercises.values()),
                default=1,
            )

            goal_scores = {}
            for exercise, data in exercises.items():
                popularity = len(data["users"]) / max(max_users, 1)
                avg_rpe = (
                    data["rpe_sum"] / data["rpe_count"]
                    if data["rpe_count"] > 0
                    else 7.0
                )
                low_rpe = 1.0 - (avg_rpe / 10.0)
                pr_rate = (
                    data["pr_count"] / data["total_sets"]
                    if data["total_sets"] > 0
                    else 0.0
                )

                score = popularity * 0.4 + low_rpe * 0.3 + pr_rate * 0.3
                goal_scores[exercise] = round(score, 2)

            # Sort by score descending
            result[muscle][goal] = dict(
                sorted(goal_scores.items(), key=lambda x: x[1], reverse=True)
            )

    # Write output
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "..",
        "mobile",
        "flutter",
        "assets",
        "data",
        "exercise_popularity.json",
    )

    with open(output_path, "w") as f:
        json.dump(result, f, indent=2)

    print(f"Exported to {output_path}")
    print(f"Muscles: {len([k for k in result if not k.startswith('_')])}")
    total_exercises = sum(
        len(exercises)
        for muscle, goals in result.items()
        if not muscle.startswith("_")
        for exercises in goals.values()
    )
    print(f"Total exercise entries: {total_exercises}")


if __name__ == "__main__":
    export_popularity()
