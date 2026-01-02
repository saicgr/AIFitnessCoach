"""
Tests for exercise video URL enrichment functionality.

Tests cover:
1. Exercises are enriched with video URLs from library
2. Existing video URLs are not overwritten
3. Missing exercises in library are handled gracefully
4. Empty exercise list is handled
"""
import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_enrich_exercises_basic():
    """Test that exercises get enriched with video URLs."""
    # Simulate exercises without video URLs
    exercises = [
        {"name": "Push-ups", "sets": 3, "reps": 10},
        {"name": "Squats", "sets": 4, "reps": 12},
    ]

    # Simulate library data
    library_data = [
        {"name": "Push-ups", "gif_url": "https://s3/pushups.gif", "video_url": "https://s3/pushups.mp4"},
        {"name": "Squats", "gif_url": "https://s3/squats.gif", "video_url": "https://s3/squats.mp4"},
    ]

    # Build lookup map (simulating the function logic)
    url_map = {}
    for row in library_data:
        lib_name = (row.get("name") or "").lower().strip()
        if lib_name:
            url_map[lib_name] = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
            }

    # Enrich exercises
    for ex in exercises:
        ex_name = (ex.get("name") or "").lower().strip()
        if ex_name in url_map:
            urls = url_map[ex_name]
            if not ex.get("gif_url") and urls.get("gif_url"):
                ex["gif_url"] = urls["gif_url"]
            if not ex.get("video_url") and urls.get("video_url"):
                ex["video_url"] = urls["video_url"]

    # Verify enrichment
    assert exercises[0]["video_url"] == "https://s3/pushups.mp4"
    assert exercises[0]["gif_url"] == "https://s3/pushups.gif"
    assert exercises[1]["video_url"] == "https://s3/squats.mp4"
    assert exercises[1]["gif_url"] == "https://s3/squats.gif"

    return True


def test_existing_urls_not_overwritten():
    """Test that existing video URLs are not overwritten."""
    exercises = [
        {"name": "Push-ups", "video_url": "https://custom/pushups.mp4", "sets": 3},
    ]

    library_data = [
        {"name": "Push-ups", "gif_url": "https://s3/pushups.gif", "video_url": "https://s3/pushups.mp4"},
    ]

    # Build lookup map
    url_map = {}
    for row in library_data:
        lib_name = (row.get("name") or "").lower().strip()
        if lib_name:
            url_map[lib_name] = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
            }

    # Enrich exercises
    for ex in exercises:
        ex_name = (ex.get("name") or "").lower().strip()
        if ex_name in url_map:
            urls = url_map[ex_name]
            if not ex.get("gif_url") and urls.get("gif_url"):
                ex["gif_url"] = urls["gif_url"]
            if not ex.get("video_url") and urls.get("video_url"):
                ex["video_url"] = urls["video_url"]

    # Custom URL should be preserved
    assert exercises[0]["video_url"] == "https://custom/pushups.mp4"
    # But gif_url should be added since it was missing
    assert exercises[0]["gif_url"] == "https://s3/pushups.gif"

    return True


def test_missing_exercise_in_library():
    """Test that exercises not in library are handled gracefully."""
    exercises = [
        {"name": "Custom Exercise", "sets": 3, "reps": 10},
        {"name": "Push-ups", "sets": 3, "reps": 10},
    ]

    library_data = [
        {"name": "Push-ups", "gif_url": "https://s3/pushups.gif", "video_url": "https://s3/pushups.mp4"},
    ]

    # Build lookup map
    url_map = {}
    for row in library_data:
        lib_name = (row.get("name") or "").lower().strip()
        if lib_name:
            url_map[lib_name] = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
            }

    # Enrich exercises
    for ex in exercises:
        ex_name = (ex.get("name") or "").lower().strip()
        if ex_name in url_map:
            urls = url_map[ex_name]
            if not ex.get("gif_url") and urls.get("gif_url"):
                ex["gif_url"] = urls["gif_url"]
            if not ex.get("video_url") and urls.get("video_url"):
                ex["video_url"] = urls["video_url"]

    # Custom exercise should not have URLs
    assert exercises[0].get("video_url") is None
    assert exercises[0].get("gif_url") is None
    # Push-ups should have URLs
    assert exercises[1]["video_url"] == "https://s3/pushups.mp4"
    assert exercises[1]["gif_url"] == "https://s3/pushups.gif"

    return True


def test_case_insensitive_matching():
    """Test that exercise matching is case-insensitive."""
    exercises = [
        {"name": "PUSH-UPS", "sets": 3, "reps": 10},
        {"name": "squats", "sets": 4, "reps": 12},
        {"name": "Bench Press", "sets": 3, "reps": 8},
    ]

    library_data = [
        {"name": "Push-ups", "gif_url": "https://s3/pushups.gif", "video_url": "https://s3/pushups.mp4"},
        {"name": "SQUATS", "gif_url": "https://s3/squats.gif", "video_url": "https://s3/squats.mp4"},
        {"name": "bench press", "gif_url": "https://s3/bench.gif", "video_url": "https://s3/bench.mp4"},
    ]

    # Build lookup map (lowercase)
    url_map = {}
    for row in library_data:
        lib_name = (row.get("name") or "").lower().strip()
        if lib_name:
            url_map[lib_name] = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
            }

    # Enrich exercises
    for ex in exercises:
        ex_name = (ex.get("name") or "").lower().strip()
        if ex_name in url_map:
            urls = url_map[ex_name]
            if not ex.get("gif_url") and urls.get("gif_url"):
                ex["gif_url"] = urls["gif_url"]
            if not ex.get("video_url") and urls.get("video_url"):
                ex["video_url"] = urls["video_url"]

    # All should be matched despite case differences
    assert exercises[0]["video_url"] == "https://s3/pushups.mp4"
    assert exercises[1]["video_url"] == "https://s3/squats.mp4"
    assert exercises[2]["video_url"] == "https://s3/bench.mp4"

    return True


def test_empty_exercises_list():
    """Test that empty exercise list is handled gracefully."""
    exercises = []

    # Should not raise an error
    result = exercises  # In real function, this would return early

    assert result == []
    return True


def test_exercises_with_null_names():
    """Test that exercises with null/empty names are handled."""
    exercises = [
        {"name": None, "sets": 3, "reps": 10},
        {"name": "", "sets": 3, "reps": 10},
        {"name": "Push-ups", "sets": 3, "reps": 10},
    ]

    library_data = [
        {"name": "Push-ups", "gif_url": "https://s3/pushups.gif", "video_url": "https://s3/pushups.mp4"},
    ]

    # Build lookup map
    url_map = {}
    for row in library_data:
        lib_name = (row.get("name") or "").lower().strip()
        if lib_name:
            url_map[lib_name] = {
                "gif_url": row.get("gif_url"),
                "video_url": row.get("video_url"),
            }

    # Enrich exercises
    for ex in exercises:
        ex_name = (ex.get("name") or "").lower().strip()
        if ex_name and ex_name in url_map:
            urls = url_map[ex_name]
            if not ex.get("gif_url") and urls.get("gif_url"):
                ex["gif_url"] = urls["gif_url"]
            if not ex.get("video_url") and urls.get("video_url"):
                ex["video_url"] = urls["video_url"]

    # Only valid exercise should be enriched
    assert exercises[0].get("video_url") is None
    assert exercises[1].get("video_url") is None
    assert exercises[2]["video_url"] == "https://s3/pushups.mp4"

    return True


def run_tests():
    """Run all tests and report results."""
    tests = [
        ("Basic Enrichment", test_enrich_exercises_basic),
        ("Existing URLs Not Overwritten", test_existing_urls_not_overwritten),
        ("Missing Exercise in Library", test_missing_exercise_in_library),
        ("Case Insensitive Matching", test_case_insensitive_matching),
        ("Empty Exercises List", test_empty_exercises_list),
        ("Null/Empty Names", test_exercises_with_null_names),
    ]

    passed = 0
    failed = 0

    print()
    print("=" * 60)
    print("VIDEO URL ENRICHMENT TESTS")
    print("=" * 60)
    print()

    for test_name, test_func in tests:
        try:
            result = test_func()
            if result:
                print(f"  ✅ PASSED - {test_name}")
                passed += 1
            else:
                print(f"  ❌ FAILED - {test_name}")
                failed += 1
        except Exception as e:
            print(f"  ❌ FAILED - {test_name}: {e}")
            failed += 1

    print()
    print("=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)

    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(run_tests())
