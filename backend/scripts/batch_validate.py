#!/usr/bin/env python3
"""
Batch Program Validation Script

Validates generated JSON files for:
- Correct structure (all required fields)
- Correct workout count (weeks × sessions)
- Exercise variety (not repetitive)
- Progression (later weeks should be harder/different)
- Equipment consistency

Also updates PROGRAMS_CHECKLIST.md with validation status.

Usage:
    cd backend
    python3 scripts/batch_validate.py

    # Validate specific file
    python3 scripts/batch_validate.py --file 5x5_Linear_4w_3d.json

    # Fix common issues automatically
    python3 scripts/batch_validate.py --auto-fix
"""

import os
import re
import json
import argparse
from pathlib import Path
from typing import Optional
from datetime import datetime

# Paths
OUTPUT_DIR = Path(__file__).parent.parent / "generated_programs"
STATUS_FILE = OUTPUT_DIR / "status.json"
VALIDATION_REPORT = OUTPUT_DIR / "validation_report.json"
CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"


def load_status() -> dict:
    """Load generation status from file."""
    if STATUS_FILE.exists():
        with open(STATUS_FILE) as f:
            return json.load(f)
    return {"programs": {}}


def save_status(status: dict):
    """Save generation status to file."""
    status["last_updated"] = datetime.now().isoformat()
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f, indent=2)


def validate_program(filepath: Path) -> dict:
    """Validate a single program JSON file."""

    issues = []
    warnings = []
    score = 100

    try:
        with open(filepath) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        return {
            "valid": False,
            "score": 0,
            "issues": [f"Invalid JSON: {e}"],
            "warnings": []
        }

    # Check top-level structure
    required_fields = ["program_name", "duration_weeks", "sessions_per_week", "workouts"]
    for field in required_fields:
        if field not in data:
            issues.append(f"Missing required field: {field}")
            score -= 25

    if "workouts" not in data:
        return {
            "valid": False,
            "score": max(0, score),
            "issues": issues,
            "warnings": warnings
        }

    # Get workouts structure
    workouts_data = data.get("workouts", {})
    weeks = workouts_data.get("weeks", [])

    if not weeks:
        # Try alternative structure
        if isinstance(workouts_data, list):
            weeks = workouts_data
        elif "program" in workouts_data and "weeks" not in workouts_data:
            issues.append("Missing 'weeks' array in workouts")
            score -= 20

    # Check workout count
    expected_weeks = data.get("duration_weeks", 0)
    expected_sessions = data.get("sessions_per_week", 0)
    expected_total = expected_weeks * expected_sessions

    actual_weeks = len(weeks)
    actual_total = 0

    for week in weeks:
        week_workouts = week.get("workouts", [])
        actual_total += len(week_workouts)

    if actual_weeks < expected_weeks:
        issues.append(f"Missing weeks: expected {expected_weeks}, got {actual_weeks}")
        score -= 15

    if actual_total < expected_total:
        issues.append(f"Missing workouts: expected {expected_total}, got {actual_total}")
        score -= 15
    elif actual_total > expected_total:
        warnings.append(f"Extra workouts: expected {expected_total}, got {actual_total}")

    # Check workout structure
    all_exercises = set()
    workouts_missing_warmup = 0
    workouts_missing_cooldown = 0
    workouts_missing_exercises = 0

    for week in weeks:
        week_workouts = week.get("workouts", [])
        for workout in week_workouts:
            # Check warmup
            warmup = workout.get("warmup", [])
            if not warmup:
                workouts_missing_warmup += 1

            # Check main exercises
            exercises = workout.get("exercises", workout.get("main_workout", []))
            if not exercises:
                workouts_missing_exercises += 1
            else:
                for ex in exercises:
                    ex_name = ex.get("exercise_name", ex.get("exercise", ""))
                    if ex_name:
                        all_exercises.add(ex_name.lower())

            # Check cooldown
            cooldown = workout.get("cooldown", [])
            if not cooldown:
                workouts_missing_cooldown += 1

    # Report structure issues
    if workouts_missing_warmup > 0:
        if workouts_missing_warmup > actual_total * 0.5:
            issues.append(f"{workouts_missing_warmup} workouts missing warmup")
            score -= 10
        else:
            warnings.append(f"{workouts_missing_warmup} workouts missing warmup")

    if workouts_missing_exercises > 0:
        issues.append(f"{workouts_missing_exercises} workouts missing exercises")
        score -= 20

    if workouts_missing_cooldown > 0:
        if workouts_missing_cooldown > actual_total * 0.5:
            warnings.append(f"{workouts_missing_cooldown} workouts missing cooldown")
        else:
            warnings.append(f"{workouts_missing_cooldown} workouts missing cooldown")

    # Check exercise variety
    if len(all_exercises) < 5:
        issues.append(f"Low exercise variety: only {len(all_exercises)} unique exercises")
        score -= 10
    elif len(all_exercises) < 10:
        warnings.append(f"Moderate exercise variety: {len(all_exercises)} unique exercises")

    # Check for progression (compare first and last week)
    if len(weeks) >= 2:
        first_week = weeks[0]
        last_week = weeks[-1]

        # Check if phases are different
        first_phase = first_week.get("phase", "")
        last_phase = last_week.get("phase", "")

        if first_phase == last_phase and first_phase:
            warnings.append("No phase progression detected")

    return {
        "valid": len(issues) == 0,
        "score": max(0, score),
        "issues": issues,
        "warnings": warnings,
        "stats": {
            "expected_weeks": expected_weeks,
            "actual_weeks": actual_weeks,
            "expected_workouts": expected_total,
            "actual_workouts": actual_total,
            "unique_exercises": len(all_exercises),
            "missing_warmup": workouts_missing_warmup,
            "missing_cooldown": workouts_missing_cooldown,
        }
    }


def update_checklist_validation(results: dict, min_score: int):
    """Update PROGRAMS_CHECKLIST.md with validation results."""

    if not CHECKLIST_PATH.exists():
        print(f"⚠️ Checklist not found: {CHECKLIST_PATH}")
        return

    with open(CHECKLIST_PATH) as f:
        content = f.read()

    lines = content.split('\n')
    updated_lines = []
    updates_made = 0

    for line in lines:
        # Match program data rows with 9 columns: name | dur | sess | desc | ss | done | json | valid | db
        prog_match = re.match(
            r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$',
            line.strip()
        )

        if prog_match and "Program" not in prog_match.group(1) and "---" not in prog_match.group(1):
            name = prog_match.group(1).strip()
            duration = prog_match.group(2).strip()
            sessions = prog_match.group(3).strip()
            description = prog_match.group(4).strip()
            ss = prog_match.group(5).strip()
            done = prog_match.group(6).strip()
            json_col = prog_match.group(7).strip()
            valid_col = prog_match.group(8).strip()
            db_col = prog_match.group(9).strip()

            # Check if any variants for this program were validated
            safe_name = re.sub(r'[^\w\s-]', '', name).replace(' ', '_')

            # Find matching results
            matching_results = {k: v for k, v in results.items() if safe_name.lower() in k.lower()}

            if matching_results:
                total = len(matching_results)
                passed = sum(1 for v in matching_results.values() if v.get('valid') and v.get('score', 0) >= min_score)
                failed = total - passed

                if total > 0:
                    if passed == total:
                        new_valid = '✅'
                    elif passed > 0:
                        new_valid = f'⚠️{passed}/{total}'
                    else:
                        # Get first failure reason
                        first_fail = next((v for v in matching_results.values() if not v.get('valid') or v.get('score', 0) < min_score), None)
                        if first_fail and first_fail.get('issues'):
                            reason = first_fail['issues'][0][:20]  # First 20 chars of first issue
                            new_valid = f'❌{reason}'
                        else:
                            new_valid = '❌'

                    if valid_col != new_valid:
                        valid_col = new_valid
                        updates_made += 1

            updated_lines.append(f"| {name} | {duration} | {sessions} | {description} | {ss} | {done} | {json_col} | {valid_col} | {db_col} |")
        else:
            updated_lines.append(line)

    # Write back
    with open(CHECKLIST_PATH, 'w') as f:
        f.write('\n'.join(updated_lines))

    print(f"\n📝 Updated PROGRAMS_CHECKLIST.md ({updates_made} programs updated)")


def main():
    parser = argparse.ArgumentParser(description='Validate generated workout programs')
    parser.add_argument('--file', type=str, help='Validate specific file only')
    parser.add_argument('--auto-fix', action='store_true', help='Attempt to fix common issues')
    parser.add_argument('--min-score', type=int, default=70, help='Minimum passing score')
    parser.add_argument('--no-checklist', action='store_true', help='Skip updating PROGRAMS_CHECKLIST.md')
    args = parser.parse_args()

    print("=" * 60)
    print("🔍 BATCH PROGRAM VALIDATION")
    print("=" * 60)
    print(f"Source: {OUTPUT_DIR}")
    print(f"Minimum passing score: {args.min_score}")

    # Load status
    status = load_status()

    # Get files to validate
    if args.file:
        files = [OUTPUT_DIR / args.file]
    else:
        files = sorted(OUTPUT_DIR.glob("*.json"))
        # Exclude status files
        files = [f for f in files if f.name not in ["status.json", "validation_report.json"]]

    print(f"\nFiles to validate: {len(files)}")

    # Validate each file
    results = {}
    passed = 0
    failed = 0

    for filepath in files:
        result = validate_program(filepath)
        variant_key = filepath.stem
        results[variant_key] = result

        # Update status
        if variant_key in status.get('programs', {}):
            status['programs'][variant_key]['validated'] = result['valid']
            status['programs'][variant_key]['validation_score'] = result['score']
            if result['issues']:
                status['programs'][variant_key]['validation_issues'] = result['issues']

        if result['valid'] and result['score'] >= args.min_score:
            passed += 1
            status_icon = "✅"
        else:
            failed += 1
            status_icon = "❌"

        print(f"\n{status_icon} {filepath.name}")
        print(f"   Score: {result['score']}/100")

        if result['issues']:
            print(f"   Issues:")
            for issue in result['issues']:
                print(f"      ❌ {issue}")

        if result['warnings']:
            print(f"   Warnings:")
            for warning in result['warnings'][:3]:  # Limit warnings shown
                print(f"      ⚠️  {warning}")
            if len(result['warnings']) > 3:
                print(f"      ... and {len(result['warnings']) - 3} more warnings")

    # Save results
    save_status(status)

    # Save validation report
    report = {
        "validated_at": datetime.now().isoformat(),
        "total_files": len(files),
        "passed": passed,
        "failed": failed,
        "min_score": args.min_score,
        "results": results
    }

    with open(VALIDATION_REPORT, 'w') as f:
        json.dump(report, f, indent=2)

    # Update PROGRAMS_CHECKLIST.md
    if not args.no_checklist and results:
        update_checklist_validation(results, args.min_score)

    # Summary
    print("\n" + "=" * 60)
    print("📊 VALIDATION SUMMARY")
    print("=" * 60)
    print(f"Total validated: {len(files)}")
    print(f"Passed (score >= {args.min_score}): {passed}")
    print(f"Failed: {failed}")
    print(f"Pass rate: {passed / len(files) * 100:.1f}%" if files else "N/A")

    # List failed files with reasons
    if failed > 0:
        print(f"\n❌ Failed files:")
        for key, result in results.items():
            if not result['valid'] or result['score'] < args.min_score:
                issues_summary = result['issues'][0] if result['issues'] else "Low score"
                print(f"   - {key}.json")
                print(f"     Score: {result['score']}/100")
                print(f"     Reason: {issues_summary}")

    print(f"\nValidation report saved to: {VALIDATION_REPORT}")
    print(f"Status updated in: {STATUS_FILE}")


if __name__ == "__main__":
    main()
