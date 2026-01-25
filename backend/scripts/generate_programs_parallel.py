#!/usr/bin/env python3
"""
Multithreaded Program Generation Pipeline (for Local Laptop)

Runs multiple program generations in parallel using a thread pool.
Optimized for machines with more RAM/CPU than Render's starter plan.

Features:
- Parallel generation using ThreadPoolExecutor
- Configurable thread count (default: 3)
- All features from generate_programs.py
- Better suited for laptops with 8GB+ RAM

Usage:
    cd backend
    python3 scripts/generate_programs_parallel.py --priority medium --threads 3
    python3 scripts/generate_programs_parallel.py --priority high --threads 4 --no-break
    python3 scripts/generate_programs_parallel.py --dry-run --threads 2
"""

import os
import re
import json
import time
import argparse
from pathlib import Path
from typing import Optional
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_MODEL = "gemini-2.5-flash"

# Paths
CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"

# Rate limiting - conservative to avoid 429 errors
BASE_REQUESTS_PER_MINUTE = 60  # Gemini limit
REQUEST_DELAY = 2.0  # 2 seconds between requests per thread

# Priority order
PRIORITY_ORDER = {'High': 0, 'Med': 1, 'Low': 2, 'Done': 99}

# Maximum workouts per API call before chunking to week-by-week
MAX_WORKOUTS_PER_CALL = 12

# Database table names
TABLE_BRANDED_PROGRAMS = 'branded_programs'
TABLE_PROGRAM_VARIANTS = 'program_variants'
TABLE_VARIANT_WEEKS = 'program_variant_weeks'

# Thread-safe counters
stats_lock = Lock()
stats = {
    'generated': 0,
    'validated': 0,
    'failed': 0,
    'skipped': 0,
    'total_cost': 0.0
}


# ============================================================================
# SUPABASE CLIENT (thread-safe)
# ============================================================================

def get_supabase():
    """Get Supabase client (creates new one per call for thread safety)."""
    from supabase import create_client
    return create_client(SUPABASE_URL, SUPABASE_KEY)


# ============================================================================
# GEMINI CLIENT (thread-safe)
# ============================================================================

def get_gemini_client():
    """Get Gemini client (creates new one per call for thread safety)."""
    from google import genai
    return genai.Client(api_key=GEMINI_API_KEY)


# ============================================================================
# COMPLETION CHECK
# ============================================================================

def get_completed_variants(supabase) -> set:
    """Get set of variant keys that are already complete in Supabase."""
    completed = set()

    variants_result = supabase.table(TABLE_PROGRAM_VARIANTS).select(
        'id, variant_name, duration_weeks, sessions_per_week'
    ).execute()

    for variant in variants_result.data:
        variant_id = variant['id']
        duration = variant['duration_weeks']

        weeks_result = supabase.table(TABLE_VARIANT_WEEKS).select(
            'week_number', count='exact'
        ).eq('variant_id', variant_id).execute()

        weeks_count = len(weeks_result.data) if weeks_result.data else 0

        if weeks_count >= duration:
            name = variant['variant_name']
            safe_name = re.sub(r'[^\w\s-]', '', name).replace(' ', '_')
            key = f"{safe_name}_{duration}w_{variant['sessions_per_week']}d"
            completed.add(key.lower())

    return completed


# ============================================================================
# CHECKLIST PARSING
# ============================================================================

def parse_durations(duration_str: str) -> list[int]:
    """Parse '4, 8, 12w' into [4, 8, 12]."""
    durations = []
    duration_str = duration_str.replace('w', '').replace('W', '')
    for part in duration_str.split(','):
        part = part.strip()
        if part.isdigit():
            durations.append(int(part))
    return durations


def parse_sessions(sessions_str: str) -> list[int]:
    """Parse '3-4/wk' into [3, 4]."""
    sessions = []
    sessions_str = sessions_str.replace('/wk', '').replace('/Wk', '').replace('/WK', '')

    if '-' in sessions_str:
        parts = sessions_str.split('-')
        if len(parts) == 2:
            try:
                start = int(parts[0].strip())
                end = int(parts[1].strip())
                sessions = list(range(start, end + 1))
            except ValueError:
                pass
    else:
        for part in sessions_str.split(','):
            part = part.strip()
            if part.isdigit():
                sessions.append(int(part))

    return sessions


def parse_checklist() -> list[dict]:
    """Parse PROGRAMS_CHECKLIST.md with Priority column."""
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    programs = []
    current_category = None

    category_pattern = r'^## (\d+)\. (.+?) \((\d+) programs?\)'
    program_pattern = r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'

    in_table = False

    for line in content.split('\n'):
        cat_match = re.match(category_pattern, line)
        if cat_match:
            current_category = cat_match.group(2).strip()
            in_table = False
            continue

        if '|------' in line or '| Program |' in line:
            in_table = True
            continue

        if in_table and current_category and line.startswith('|'):
            prog_match = re.match(program_pattern, line)
            if prog_match:
                name = prog_match.group(1).strip()
                priority = prog_match.group(2).strip()
                durations_str = prog_match.group(3).strip()
                sessions_str = prog_match.group(4).strip()
                description = prog_match.group(5).strip()
                has_supersets = '✅' in prog_match.group(6)
                is_done = '✅' in prog_match.group(7)
                json_done = '✅' in prog_match.group(8)

                if is_done or json_done or priority == '✅':
                    continue

                durations = parse_durations(durations_str)
                sessions = parse_sessions(sessions_str)

                if durations and sessions:
                    programs.append({
                        'name': name,
                        'priority': priority,
                        'durations': durations,
                        'sessions': sessions,
                        'description': description,
                        'has_supersets': has_supersets,
                        'category': current_category,
                    })

    return programs


def get_variant_key(name: str, duration: int, sessions: int) -> str:
    """Generate unique variant key."""
    safe_name = re.sub(r'[^\w\s-]', '', name).replace(' ', '_')
    return f"{safe_name}_{duration}w_{sessions}d"


# ============================================================================
# IMPORT GENERATION FUNCTIONS FROM MAIN SCRIPT
# ============================================================================

# Import the heavy lifting from the main script
import sys
sys.path.insert(0, str(Path(__file__).parent))

from generate_programs import (
    get_or_create_branded_program,
    create_variant_record,
    ingest_week_to_supabase,
    generate_variant_weekly,
    generate_variant_single,
)


# ============================================================================
# WORKER FUNCTION (runs in thread)
# ============================================================================

def generate_variant_worker(task: dict, dry_run: bool = False) -> dict:
    """
    Worker function to generate a single variant.
    Runs in its own thread with own DB/API connections.
    """
    program = task['program']
    duration = task['duration']
    sessions = task['sessions']
    variant_key = task['variant_key']

    thread_id = f"[T{hash(variant_key) % 100:02d}]"

    try:
        # Create fresh clients for this thread
        supabase = get_supabase()
        client = get_gemini_client()

        print(f"{thread_id} 🎯 Starting {variant_key}")

        total_workouts = duration * sessions

        # Route to appropriate generation method
        if total_workouts > MAX_WORKOUTS_PER_CALL:
            result = generate_variant_weekly(
                program, duration, sessions,
                supabase, client,
                dry_run=dry_run,
                resume=False
            )
        else:
            result = generate_variant_single(
                program, duration, sessions,
                supabase, client,
                dry_run=dry_run
            )

        # Update thread-safe stats
        with stats_lock:
            if result.get('success'):
                stats['generated'] += 1
                stats['validated'] += 1
                stats['total_cost'] += result.get('cost', 0)
                print(f"{thread_id} ✅ {variant_key} | ${result.get('cost', 0):.4f}")
            elif result.get('partial'):
                stats['generated'] += 1
                stats['failed'] += 1
                stats['total_cost'] += result.get('cost', 0)
                print(f"{thread_id} ⚠️ {variant_key} partial ({result.get('weeks_generated', 0)} weeks)")
            else:
                stats['failed'] += 1
                print(f"{thread_id} ❌ {variant_key} FAILED: {result.get('error', 'Unknown')}")

        # Rate limiting
        time.sleep(REQUEST_DELAY)

        return {
            'variant_key': variant_key,
            'success': result.get('success', False),
            'partial': result.get('partial', False),
            'error': result.get('error'),
            'cost': result.get('cost', 0)
        }

    except Exception as e:
        with stats_lock:
            stats['failed'] += 1
        print(f"{thread_id} ❌ {variant_key} EXCEPTION: {e}")
        return {
            'variant_key': variant_key,
            'success': False,
            'error': str(e)
        }


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Parallel program generation (for laptop)')
    parser.add_argument('--priority', type=str, nargs='+', default=['all'],
                        help='Priority levels to generate (e.g., --priority medium low or --priority high)')
    parser.add_argument('--threads', type=int, default=3,
                        help='Number of parallel threads (default: 3, conservative to avoid rate limits)')
    parser.add_argument('--limit', type=int, default=0,
                        help='Maximum variants to generate (0 = unlimited)')
    parser.add_argument('--dry-run', action='store_true',
                        help='Preview what would be generated without API calls')
    parser.add_argument('--no-break', action='store_true',
                        help='Continue even if generation fails')
    parser.add_argument('--program', type=str,
                        help='Generate only this specific program')
    args = parser.parse_args()

    print("=" * 60)
    print("🚀 PARALLEL PROGRAM GENERATION (Laptop Mode)")
    print("=" * 60)
    print(f"Threads: {args.threads}")
    print(f"Priority: {', '.join(args.priority)}")
    print(f"Limit: {args.limit if args.limit else 'unlimited'}")
    print(f"Dry run: {args.dry_run}")
    print()

    # Parse checklist
    programs = parse_checklist()
    print(f"📋 Found {len(programs)} programs in checklist")

    # Filter by priority (supports multiple: --priority medium low)
    priority_map = {'high': 'High', 'medium': 'Med', 'low': 'Low'}
    priorities = [p.lower() for p in args.priority]

    if 'all' not in priorities:
        target_priorities = [priority_map.get(p) for p in priorities if p in priority_map]
        programs = [p for p in programs if p['priority'] in target_priorities]
        print(f"   Filtered to {len(programs)} programs ({', '.join(priorities)} priority)")

    # Filter by specific program if specified
    if args.program:
        programs = [p for p in programs if args.program.lower() in p['name'].lower()]
        print(f"   Filtered to {len(programs)} matching '{args.program}'")

    if not programs:
        print("❌ No programs to generate")
        return

    # Sort by priority
    programs.sort(key=lambda p: PRIORITY_ORDER.get(p['priority'], 50))

    # Get completed variants
    print("\n🔍 Checking Supabase for completed variants...")
    supabase = get_supabase()
    completed_variants = get_completed_variants(supabase)
    print(f"   Found {len(completed_variants)} completed variants")

    # Build task queue
    tasks = []
    limit = args.limit if args.limit > 0 else float('inf')

    for program in programs:
        if len(tasks) >= limit:
            break

        for duration in program['durations']:
            if len(tasks) >= limit:
                break

            for sessions in program['sessions']:
                if len(tasks) >= limit:
                    break

                variant_key = get_variant_key(program['name'], duration, sessions)

                # Skip if already complete
                if variant_key.lower() in completed_variants:
                    with stats_lock:
                        stats['skipped'] += 1
                    print(f"   ⏭️ {variant_key} - already complete")
                    continue

                tasks.append({
                    'program': program,
                    'duration': duration,
                    'sessions': sessions,
                    'variant_key': variant_key
                })

    print(f"\n📦 {len(tasks)} variants to generate")
    print(f"   (Skipped {stats['skipped']} already complete)")

    if not tasks:
        print("\n✅ All variants already complete!")
        return

    if args.dry_run:
        print("\n🏃 DRY RUN - would generate:")
        for task in tasks[:20]:
            print(f"   - {task['variant_key']}")
        if len(tasks) > 20:
            print(f"   ... and {len(tasks) - 20} more")
        return

    # Run parallel generation
    print(f"\n🏭 Starting {args.threads} worker threads...")
    print("=" * 60)

    failed_variants = []

    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        # Submit all tasks
        future_to_task = {
            executor.submit(generate_variant_worker, task, args.dry_run): task
            for task in tasks
        }

        # Process completed tasks
        for future in as_completed(future_to_task):
            task = future_to_task[future]
            try:
                result = future.result()
                if not result.get('success') and not result.get('partial'):
                    failed_variants.append(result)
                    if not args.no_break and len(failed_variants) >= 3:
                        print("\n🛑 Too many failures, stopping...")
                        executor.shutdown(wait=False, cancel_futures=True)
                        break
            except Exception as e:
                print(f"❌ Task exception for {task['variant_key']}: {e}")
                failed_variants.append({'variant_key': task['variant_key'], 'error': str(e)})

    # Summary
    print("\n" + "=" * 60)
    print("📊 PIPELINE SUMMARY")
    print("=" * 60)
    print(f"Generated: {stats['generated']}")
    print(f"Validated: {stats['validated']}")
    print(f"Failed: {stats['failed']}")
    print(f"Skipped: {stats['skipped']}")
    print(f"Total cost: ${stats['total_cost']:.4f}")

    if failed_variants:
        print(f"\n❌ Failed variants ({len(failed_variants)}):")
        for fv in failed_variants[:10]:
            print(f"   - {fv.get('variant_key')}: {fv.get('error', 'Unknown')}")
        if len(failed_variants) > 10:
            print(f"   ... and {len(failed_variants) - 10} more")


if __name__ == "__main__":
    main()
