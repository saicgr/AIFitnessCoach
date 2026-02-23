#!/usr/bin/env python3
"""
Reusable CLI tool for adding exercises to the FitWiz exercise_library.

Usage:
    python add_exercises.py --interactive
    python add_exercises.py --json exercises.json
    python add_exercises.py --single --name "Dead Hang" --body-part "upper body" ...
    python add_exercises.py --dry-run --json exercises.json
"""

import os
import argparse
import json
import sys

import psycopg2

# ---------------------------------------------------------------------------
# Database credentials (Supabase PostgreSQL)
# ---------------------------------------------------------------------------
DATABASE_HOST = "db.hpbzfahijszqmgsybuor.supabase.co"
DATABASE_PORT = 5432
DATABASE_NAME = "postgres"
DATABASE_USER = "postgres"
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")

# ---------------------------------------------------------------------------
# Valid enum values
# ---------------------------------------------------------------------------
VALID_DIFFICULTIES = ["Beginner", "Intermediate", "Advanced"]
VALID_CATEGORIES = ["cardio", "strength", "stretching", "warmup", "mobility", "yoga"]

# ---------------------------------------------------------------------------
# ANSI colour helpers
# ---------------------------------------------------------------------------
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"


def green(text: str) -> str:
    return f"{GREEN}{text}{RESET}"


def yellow(text: str) -> str:
    return f"{YELLOW}{text}{RESET}"


def red(text: str) -> str:
    return f"{RED}{text}{RESET}"


def cyan(text: str) -> str:
    return f"{CYAN}{text}{RESET}"


def bold(text: str) -> str:
    return f"{BOLD}{text}{RESET}"


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------
def get_connection():
    """Return a psycopg2 connection to the Supabase database."""
    return psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
        sslmode="require",
    )


def check_duplicate(cur, exercise_name: str) -> bool:
    """Return True if an exercise with this name already exists (case-insensitive)."""
    cur.execute(
        "SELECT 1 FROM exercise_library WHERE lower(exercise_name) = lower(%s)",
        (exercise_name,),
    )
    return cur.fetchone() is not None


def insert_exercise(cur, exercise: dict) -> None:
    """Insert a single exercise row."""
    secondary = exercise.get("secondary_muscles") or []
    cur.execute(
        """
        INSERT INTO exercise_library (
            exercise_name, body_part, equipment, target_muscle,
            secondary_muscles, instructions, difficulty_level,
            category, is_timed, default_hold_seconds
        ) VALUES (
            %(exercise_name)s, %(body_part)s, %(equipment)s, %(target_muscle)s,
            %(secondary_muscles)s, %(instructions)s, %(difficulty_level)s,
            %(category)s, %(is_timed)s, %(default_hold_seconds)s
        )
        """,
        {
            "exercise_name": exercise["exercise_name"],
            "body_part": exercise["body_part"],
            "equipment": exercise["equipment"],
            "target_muscle": exercise["target_muscle"],
            "secondary_muscles": secondary,
            "instructions": exercise["instructions"],
            "difficulty_level": exercise["difficulty_level"],
            "category": exercise["category"],
            "is_timed": exercise.get("is_timed", False),
            "default_hold_seconds": exercise.get("default_hold_seconds"),
        },
    )


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
REQUIRED_FIELDS = [
    "exercise_name",
    "body_part",
    "equipment",
    "target_muscle",
    "instructions",
    "difficulty_level",
    "category",
]


def validate_exercise(exercise: dict) -> list[str]:
    """Return a list of validation error strings (empty == valid)."""
    errors: list[str] = []

    # Required fields
    for field in REQUIRED_FIELDS:
        val = exercise.get(field)
        if val is None or (isinstance(val, str) and val.strip() == ""):
            errors.append(f"Missing required field: {field}")

    # Enum: difficulty_level
    diff = exercise.get("difficulty_level", "")
    if diff and diff not in VALID_DIFFICULTIES:
        errors.append(
            f"Invalid difficulty_level '{diff}'. "
            f"Must be one of: {', '.join(VALID_DIFFICULTIES)}"
        )

    # Enum: category
    cat = exercise.get("category", "")
    if cat and cat not in VALID_CATEGORIES:
        errors.append(
            f"Invalid category '{cat}'. "
            f"Must be one of: {', '.join(VALID_CATEGORIES)}"
        )

    # is_timed / hold_seconds consistency
    is_timed = exercise.get("is_timed", False)
    hold_seconds = exercise.get("default_hold_seconds")
    if hold_seconds is not None and not is_timed:
        errors.append(
            "default_hold_seconds is set but is_timed is False. "
            "Set is_timed to True or remove default_hold_seconds."
        )
    if is_timed and hold_seconds is not None:
        if not isinstance(hold_seconds, int) or hold_seconds <= 0:
            errors.append("default_hold_seconds must be a positive integer.")

    return errors


# ---------------------------------------------------------------------------
# Pretty-print helpers
# ---------------------------------------------------------------------------
def print_exercise_summary(exercise: dict) -> None:
    """Print a readable summary of a single exercise dict."""
    secondary = exercise.get("secondary_muscles") or []
    sec_str = ", ".join(secondary) if secondary else "(none)"
    is_timed = exercise.get("is_timed", False)
    hold = exercise.get("default_hold_seconds")

    print(f"  Name:              {bold(exercise.get('exercise_name', ''))}")
    print(f"  Body Part:         {exercise.get('body_part', '')}")
    print(f"  Equipment:         {exercise.get('equipment', '')}")
    print(f"  Target Muscle:     {exercise.get('target_muscle', '')}")
    print(f"  Secondary Muscles: {sec_str}")
    print(f"  Difficulty:        {exercise.get('difficulty_level', '')}")
    print(f"  Category:          {exercise.get('category', '')}")
    print(f"  Is Timed:          {is_timed}")
    if is_timed and hold is not None:
        print(f"  Hold Seconds:      {hold}")
    instructions = exercise.get("instructions", "")
    preview = (instructions[:80] + "...") if len(instructions) > 80 else instructions
    print(f"  Instructions:      {preview}")


# ---------------------------------------------------------------------------
# Processing pipeline
# ---------------------------------------------------------------------------
def process_exercises(
    exercises: list[dict],
    dry_run: bool = False,
    verbose: bool = False,
) -> None:
    """Validate and insert a list of exercises. Handles dry-run mode."""
    inserted = 0
    skipped = 0
    failed = 0

    conn = get_connection()
    try:
        cur = conn.cursor()
        for i, exercise in enumerate(exercises, start=1):
            name = exercise.get("exercise_name", "(unnamed)")
            print(f"\n{'─' * 50}")
            print(f"  [{i}/{len(exercises)}] {bold(name)}")
            print(f"{'─' * 50}")

            if verbose:
                print_exercise_summary(exercise)
                print()

            # Validate
            errors = validate_exercise(exercise)
            if errors:
                for err in errors:
                    print(f"  {red('FAIL')}  {err}")
                failed += 1
                continue

            # Duplicate check
            if check_duplicate(cur, name):
                print(f"  {yellow('SKIP')}  Duplicate exercise: '{name}' already exists.")
                skipped += 1
                continue

            if dry_run:
                print(f"  {cyan('DRY-RUN')}  Would insert '{name}'.")
                if verbose:
                    print_exercise_summary(exercise)
                inserted += 1
                continue

            # Insert
            try:
                insert_exercise(cur, exercise)
                conn.commit()
                print(f"  {green('OK')}  Inserted '{name}'.")
                inserted += 1
            except Exception as exc:
                conn.rollback()
                print(f"  {red('FAIL')}  Insert error: {exc}")
                failed += 1

        cur.close()
    finally:
        conn.close()

    # Summary
    print(f"\n{'=' * 50}")
    label = "DRY-RUN SUMMARY" if dry_run else "SUMMARY"
    print(f"  {bold(label)}")
    print(f"{'=' * 50}")
    print(f"  {green('Inserted:')} {inserted}")
    print(f"  {yellow('Skipped (duplicate):')} {skipped}")
    print(f"  {red('Failed:')} {failed}")
    print(f"  Total processed: {len(exercises)}")
    print()


# ---------------------------------------------------------------------------
# Mode: interactive
# ---------------------------------------------------------------------------
def prompt_value(label: str, required: bool = True, default: str = "") -> str:
    """Prompt the user for a value, optionally with a default."""
    suffix = f" [{default}]" if default else ""
    while True:
        value = input(f"  {label}{suffix}: ").strip()
        if not value and default:
            return default
        if not value and required:
            print(f"  {red('Required field. Please enter a value.')}")
            continue
        return value


def prompt_choice(label: str, choices: list[str]) -> str:
    """Prompt the user to pick from a list of valid choices."""
    choices_str = ", ".join(choices)
    while True:
        value = input(f"  {label} ({choices_str}): ").strip()
        if value in choices:
            return value
        print(f"  {red('Invalid choice.')} Must be one of: {choices_str}")


def prompt_bool(label: str, default: bool = False) -> bool:
    """Prompt for a yes/no value."""
    hint = "Y/n" if default else "y/N"
    value = input(f"  {label} [{hint}]: ").strip().lower()
    if not value:
        return default
    return value in ("y", "yes", "true", "1")


def interactive_mode(dry_run: bool, verbose: bool) -> None:
    """Prompt the user to enter exercises one at a time."""
    exercises: list[dict] = []

    print(f"\n{bold('Interactive Exercise Entry')}")
    print("Enter exercise details. Press Ctrl+C to cancel.\n")

    while True:
        try:
            print(f"\n{cyan('--- New Exercise ---')}")
            name = prompt_value("Exercise Name")
            body_part = prompt_value("Body Part (e.g. upper body, lower body, core)")
            equipment = prompt_value("Equipment (e.g. barbell, dumbbell, bodyweight, pull_up_bar)")
            target_muscle = prompt_value("Target Muscle (e.g. lats, chest, quads)")
            sec_raw = input("  Secondary Muscles (comma-separated, or blank): ").strip()
            secondary = [s.strip() for s in sec_raw.split(",") if s.strip()] if sec_raw else []
            instructions = prompt_value("Instructions")
            difficulty = prompt_choice("Difficulty", VALID_DIFFICULTIES)
            category = prompt_choice("Category", VALID_CATEGORIES)
            is_timed = prompt_bool("Is timed exercise?", default=False)
            hold_seconds = None
            if is_timed:
                hs = prompt_value("Default hold seconds", required=False, default="30")
                try:
                    hold_seconds = int(hs)
                except ValueError:
                    print(f"  {yellow('Invalid number, defaulting to 30.')}")
                    hold_seconds = 30

            exercise = {
                "exercise_name": name,
                "body_part": body_part,
                "equipment": equipment,
                "target_muscle": target_muscle,
                "secondary_muscles": secondary,
                "instructions": instructions,
                "difficulty_level": difficulty,
                "category": category,
                "is_timed": is_timed,
                "default_hold_seconds": hold_seconds,
            }

            print(f"\n{bold('Preview:')}")
            print_exercise_summary(exercise)
            exercises.append(exercise)

            if not prompt_bool("\nAdd another exercise?", default=False):
                break

        except KeyboardInterrupt:
            print(f"\n\n{yellow('Cancelled by user.')}")
            if not exercises:
                return
            break

    if exercises:
        process_exercises(exercises, dry_run=dry_run, verbose=verbose)


# ---------------------------------------------------------------------------
# Mode: json
# ---------------------------------------------------------------------------
def json_mode(filepath: str, dry_run: bool, verbose: bool) -> None:
    """Load exercises from a JSON file and process them."""
    try:
        with open(filepath, "r") as f:
            data = json.load(f)
    except FileNotFoundError:
        print(red(f"File not found: {filepath}"))
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(red(f"Invalid JSON in {filepath}: {exc}"))
        sys.exit(1)

    if not isinstance(data, list):
        print(red("JSON file must contain an array of exercise objects."))
        sys.exit(1)

    print(f"Loaded {bold(str(len(data)))} exercise(s) from {cyan(filepath)}")
    process_exercises(data, dry_run=dry_run, verbose=verbose)


# ---------------------------------------------------------------------------
# Mode: single
# ---------------------------------------------------------------------------
def single_mode(args: argparse.Namespace, dry_run: bool, verbose: bool) -> None:
    """Build a single exercise from CLI flags and process it."""
    secondary = []
    if args.secondary_muscles:
        secondary = [s.strip() for s in args.secondary_muscles.split(",") if s.strip()]

    exercise = {
        "exercise_name": args.name,
        "body_part": args.body_part,
        "equipment": args.equipment,
        "target_muscle": args.target_muscle,
        "secondary_muscles": secondary,
        "instructions": args.instructions,
        "difficulty_level": args.difficulty,
        "category": args.category,
        "is_timed": args.is_timed,
        "default_hold_seconds": args.hold_seconds,
    }

    process_exercises([exercise], dry_run=dry_run, verbose=verbose)


# ---------------------------------------------------------------------------
# CLI argument parser
# ---------------------------------------------------------------------------
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Add exercises to the FitWiz exercise_library.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --interactive
  %(prog)s --json exercises.json
  %(prog)s --single --name "Dead Hang" --body-part "upper body" \\
           --equipment "pull_up_bar" --target-muscle "lats" \\
           --instructions "Grip the bar..." --difficulty "Beginner" \\
           --category "strength" --is-timed --hold-seconds 30
  %(prog)s --dry-run --json exercises.json
        """,
    )

    # Mode selection (mutually exclusive)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--interactive",
        action="store_true",
        help="Interactively prompt for exercise details",
    )
    mode.add_argument(
        "--json",
        metavar="FILE",
        help="Load exercises from a JSON file",
    )
    mode.add_argument(
        "--single",
        action="store_true",
        help="Add a single exercise via CLI flags",
    )

    # Global flags
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate only; do not insert into database",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show extra detail for each exercise",
    )

    # Single-mode fields
    single_grp = parser.add_argument_group("single-mode fields")
    single_grp.add_argument("--name", help="Exercise name (required for --single)")
    single_grp.add_argument("--body-part", help="Body part (required for --single)")
    single_grp.add_argument("--equipment", help="Equipment (required for --single)")
    single_grp.add_argument("--target-muscle", help="Target muscle (required for --single)")
    single_grp.add_argument(
        "--secondary-muscles",
        help="Comma-separated secondary muscles (optional)",
    )
    single_grp.add_argument("--instructions", help="Exercise instructions (required for --single)")
    single_grp.add_argument(
        "--difficulty",
        choices=VALID_DIFFICULTIES,
        help="Difficulty level (required for --single)",
    )
    single_grp.add_argument(
        "--category",
        choices=VALID_CATEGORIES,
        help="Exercise category (required for --single)",
    )
    single_grp.add_argument(
        "--is-timed",
        action="store_true",
        help="Mark as timed exercise (optional)",
    )
    single_grp.add_argument(
        "--hold-seconds",
        type=int,
        help="Default hold seconds for timed exercise (optional)",
    )

    return parser


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    dry_run = args.dry_run
    verbose = args.verbose

    if dry_run:
        print(f"\n{cyan('[DRY-RUN MODE] No data will be inserted.')}\n")

    if args.interactive:
        interactive_mode(dry_run=dry_run, verbose=verbose)
    elif args.json:
        json_mode(args.json, dry_run=dry_run, verbose=verbose)
    elif args.single:
        # Validate that required single-mode fields are present
        missing = []
        for field in ["name", "body_part", "equipment", "target_muscle", "instructions", "difficulty", "category"]:
            if getattr(args, field.replace("-", "_"), None) is None:
                missing.append(f"--{field.replace('_', '-')}")
        if missing:
            parser.error(f"--single mode requires: {', '.join(missing)}")
        single_mode(args, dry_run=dry_run, verbose=verbose)


if __name__ == "__main__":
    main()
