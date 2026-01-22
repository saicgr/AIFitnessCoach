#!/usr/bin/env python3
"""
Batch Program Generation Script using Gemini 2.5 Flash

Features:
- Reads programs from PROGRAMS_CHECKLIST.md
- Generates JSON files for each variant
- Resume capability (skips already generated files)
- Tracks progress in status.json
- Respects rate limits

Usage:
    cd backend
    python3 scripts/batch_generate.py

    # Generate specific category only
    python3 scripts/batch_generate.py --category "Strength"

    # Dry run (no API calls)
    python3 scripts/batch_generate.py --dry-run
"""

import os
import re
import json
import time
import argparse
from pathlib import Path
from datetime import datetime
from typing import Optional
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = "gemini-2.5-flash"  # Using full Flash for quality

# Paths
CHECKLIST_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_CHECKLIST.md"
OUTPUT_DIR = Path(__file__).parent.parent / "generated_programs"
STATUS_FILE = OUTPUT_DIR / "status.json"

OUTPUT_DIR.mkdir(exist_ok=True)

# Rate limiting
REQUESTS_PER_MINUTE = 15
REQUEST_DELAY = 60 / REQUESTS_PER_MINUTE  # 4 seconds between requests


def load_status() -> dict:
    """Load generation status from file."""
    if STATUS_FILE.exists():
        with open(STATUS_FILE) as f:
            return json.load(f)
    return {"programs": {}, "last_updated": None, "total_generated": 0, "total_failed": 0}


def save_status(status: dict):
    """Save generation status to file."""
    status["last_updated"] = datetime.now().isoformat()
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f, indent=2)


def parse_checklist() -> list[dict]:
    """Parse PROGRAMS_CHECKLIST.md and extract all programs with variants."""
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    programs = []
    current_category = None
    current_category_num = 0

    # Regex patterns
    category_pattern = r'^## (\d+)\. (.+?) \((\d+) programs?\)'
    program_pattern = r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'

    in_table = False

    for line in content.split('\n'):
        # Check for category header
        cat_match = re.match(category_pattern, line)
        if cat_match:
            current_category_num = int(cat_match.group(1))
            current_category = cat_match.group(2).strip()
            in_table = False
            continue

        # Check for table header (skip)
        if '|------' in line or '| Program |' in line:
            in_table = True
            continue

        # Parse program row
        if in_table and current_category and line.startswith('|'):
            prog_match = re.match(program_pattern, line)
            if prog_match:
                name = prog_match.group(1).strip()
                durations_str = prog_match.group(2).strip()
                sessions_str = prog_match.group(3).strip()
                description = prog_match.group(4).strip()
                has_supersets = '✅' in prog_match.group(5)
                is_done = '✅' in prog_match.group(6)

                # Skip already done programs
                if is_done:
                    continue

                # Parse durations (e.g., "4, 8, 12w" or "1, 2, 4, 8w")
                durations = parse_durations(durations_str)

                # Parse sessions (e.g., "3/wk" or "4-5/wk")
                sessions = parse_sessions(sessions_str)

                if durations and sessions:
                    programs.append({
                        "name": name,
                        "category": current_category,
                        "category_num": current_category_num,
                        "description": description,
                        "durations": durations,
                        "sessions": sessions,
                        "has_supersets": has_supersets,
                    })

    return programs


def parse_durations(s: str) -> list[int]:
    """Parse duration string like '4, 8, 12w' into [4, 8, 12]."""
    # Remove 'w' and split
    s = s.replace('w', '').replace('W', '')
    durations = []
    for part in s.split(','):
        part = part.strip()
        if part.isdigit():
            durations.append(int(part))
    return durations


def parse_sessions(s: str) -> list[int]:
    """Parse sessions string like '3/wk' or '4-5/wk' into [3] or [4, 5]."""
    # Extract numbers
    s = s.replace('/wk', '').strip()
    sessions = []

    if '-' in s:
        parts = s.split('-')
        try:
            start = int(parts[0].strip())
            end = int(parts[1].strip())
            sessions = list(range(start, end + 1))
        except:
            pass
    else:
        try:
            sessions = [int(s)]
        except:
            pass

    return sessions


def get_variant_key(program_name: str, duration: int, sessions: int) -> str:
    """Generate unique key for a program variant."""
    safe_name = re.sub(r'[^\w\s-]', '', program_name).replace(' ', '_')
    return f"{safe_name}_{duration}w_{sessions}d"


def generate_program(program: dict, duration: int, sessions: int, dry_run: bool = False) -> dict:
    """Generate a single program variant using Gemini."""

    if dry_run:
        return {
            "success": True,
            "dry_run": True,
            "data": {"program_name": program["name"], "duration_weeks": duration}
        }

    from google import genai
    from google.genai import types

    client = genai.Client(api_key=GEMINI_API_KEY)

    system_prompt = get_system_prompt(program)
    user_prompt = get_user_prompt(program, duration, sessions)

    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=user_prompt,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                temperature=0.7,
                max_output_tokens=65536,
            )
        )

        # Parse response
        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        data = json.loads(text)

        # Get token usage
        usage = response.usage_metadata
        input_tokens = usage.prompt_token_count if usage else 0
        output_tokens = usage.candidates_token_count if usage else 0

        return {
            "success": True,
            "data": data,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost": (input_tokens * 0.15 + output_tokens * 0.60) / 1_000_000
        }

    except json.JSONDecodeError as e:
        return {"success": False, "error": f"JSON parse error: {e}"}
    except Exception as e:
        return {"success": False, "error": str(e)}


def get_system_prompt(program: dict) -> str:
    """Generate system prompt based on program category."""

    base_prompt = """You are a certified personal trainer creating professional workout programs in JSON format.

RULES:
1. Return ONLY valid JSON - no markdown, no explanations, no text before or after
2. Every workout MUST have: warmup, exercises (main_workout), cooldown
3. Include specific sets, reps, rest periods for every exercise
4. Progress difficulty across weeks (later weeks should be harder than early weeks)
5. Include deload weeks where appropriate (typically every 4th week)
6. Use real, standard exercise names
7. Be specific with weight guidance (RPE, % 1RM, or specific weights)

OUTPUT FORMAT:
{
  "program_name": "string",
  "description": "string",
  "duration_weeks": number,
  "sessions_per_week": number,
  "difficulty": "beginner|intermediate|advanced",
  "equipment_required": ["list"],
  "workouts": {
    "weeks": [
      {
        "week": number,
        "phase": "string (e.g., Foundation, Build, Peak, Deload)",
        "focus": "string",
        "workouts": [
          {
            "day": number,
            "workout_name": "string",
            "type": "Strength|Cardio|Hybrid|Recovery",
            "duration_minutes": number,
            "intensity": "Low|Moderate|Moderate-Hard|Hard|Very Hard",
            "equipment": ["list"],
            "warmup": [
              {"exercise": "string", "duration": "string or reps", "notes": "string"}
            ],
            "exercises": [
              {
                "exercise_name": "string",
                "sets": number,
                "reps": "number or string like '8-12' or '30 seconds'",
                "rest_seconds": number,
                "notes": "string with weight guidance",
                "equipment": "string (optional)"
              }
            ],
            "cooldown": [
              {"exercise": "string", "duration": "string", "notes": "string"}
            ],
            "coach_notes": "string"
          }
        ]
      }
    ]
  }
}"""

    # Add category-specific guidance
    category_guidance = {
        "Strength": "\n\nSTRENGTH PROGRAM SPECIFICS:\n- Focus on compound lifts (squat, bench, deadlift, OHP, row)\n- Lower rep ranges (3-6 for main lifts)\n- Longer rest periods (2-5 minutes)\n- Progressive overload through weight increase\n- Include proper warm-up sets before working sets",

        "Hypertrophy": "\n\nHYPERTROPHY PROGRAM SPECIFICS:\n- Rep ranges of 8-12 for most exercises\n- Time under tension matters\n- Include isolation exercises for each muscle group\n- Moderate rest periods (60-90 seconds)\n- Volume is key - sufficient total sets per muscle group",

        "Fat Loss": "\n\nFAT LOSS PROGRAM SPECIFICS:\n- Include both resistance training and cardio\n- Circuit-style training with short rest\n- Full body compound movements\n- Keep intensity high to maintain muscle\n- Include HIIT sessions",

        "Calisthenics": "\n\nCALISTHENICS PROGRAM SPECIFICS:\n- Progressive bodyweight exercises\n- Include mobility work\n- Skill progressions (pushup variations, pull-up progressions)\n- Tempo control is important\n- Include isometric holds",
    }

    category = program.get("category", "")
    for key, guidance in category_guidance.items():
        if key.lower() in category.lower():
            base_prompt += guidance
            break

    return base_prompt


def get_user_prompt(program: dict, duration: int, sessions: int) -> str:
    """Generate user prompt for specific program variant."""

    total_workouts = duration * sessions

    return f"""Generate a complete {duration}-week "{program['name']}" workout program.

PROGRAM DETAILS:
- Name: {program['name']}
- Category: {program['category']}
- Description: {program['description']}
- Duration: {duration} weeks
- Sessions per week: {sessions}
- Total workouts needed: {total_workouts}
- Supersets allowed: {"Yes" if program.get('has_supersets') else "No - use straight sets only"}

Generate ALL {total_workouts} workouts organized by week.
Each week should have exactly {sessions} workout days.
Return ONLY the JSON object."""


def main():
    parser = argparse.ArgumentParser(description='Batch generate workout programs using Gemini')
    parser.add_argument('--category', type=str, help='Generate only this category')
    parser.add_argument('--program', type=str, help='Generate only this program name')
    parser.add_argument('--dry-run', action='store_true', help='Parse checklist without API calls')
    parser.add_argument('--limit', type=int, help='Limit number of variants to generate')
    args = parser.parse_args()

    print("=" * 60)
    print("🏋️ BATCH PROGRAM GENERATION")
    print("=" * 60)
    print(f"Model: {GEMINI_MODEL}")
    print(f"Output: {OUTPUT_DIR}")

    # Load status
    status = load_status()

    # Parse checklist
    print("\n📋 Parsing PROGRAMS_CHECKLIST.md...")
    programs = parse_checklist()
    print(f"   Found {len(programs)} programs (excluding completed)")

    # Filter if specified
    if args.category:
        programs = [p for p in programs if args.category.lower() in p['category'].lower()]
        print(f"   Filtered to {len(programs)} programs in category '{args.category}'")

    if args.program:
        programs = [p for p in programs if args.program.lower() in p['name'].lower()]
        print(f"   Filtered to {len(programs)} programs matching '{args.program}'")

    # Calculate total variants
    total_variants = sum(len(p['durations']) * len(p['sessions']) for p in programs)
    print(f"   Total variants to generate: {total_variants}")

    if args.dry_run:
        print("\n🔍 DRY RUN MODE - No API calls will be made")

    # Generate variants
    generated = 0
    skipped = 0
    failed = 0
    total_cost = 0

    limit = args.limit if args.limit else float('inf')

    for program in programs:
        if generated >= limit:
            break

        print(f"\n📦 Program: {program['name']} ({program['category']})")

        for duration in program['durations']:
            if generated >= limit:
                break

            for sessions in program['sessions']:
                if generated >= limit:
                    break

                variant_key = get_variant_key(program['name'], duration, sessions)
                json_path = OUTPUT_DIR / f"{variant_key}.json"

                # Check if already generated
                if json_path.exists():
                    print(f"   ⏭️  {variant_key} - already exists, skipping")
                    skipped += 1
                    continue

                # Check status
                if variant_key in status['programs']:
                    prog_status = status['programs'][variant_key]
                    if prog_status.get('generated'):
                        print(f"   ⏭️  {variant_key} - marked as generated, skipping")
                        skipped += 1
                        continue

                print(f"   🎯 Generating {variant_key}...")

                result = generate_program(program, duration, sessions, dry_run=args.dry_run)

                if result['success']:
                    # Save JSON
                    if not args.dry_run:
                        with open(json_path, 'w') as f:
                            json.dump(result['data'], f, indent=2)

                    # Update status
                    status['programs'][variant_key] = {
                        "generated": True,
                        "validated": False,
                        "ingested": False,
                        "generated_at": datetime.now().isoformat(),
                        "input_tokens": result.get('input_tokens', 0),
                        "output_tokens": result.get('output_tokens', 0),
                        "cost": result.get('cost', 0),
                    }
                    status['total_generated'] = status.get('total_generated', 0) + 1

                    generated += 1
                    total_cost += result.get('cost', 0)

                    print(f"      ✅ Generated (${result.get('cost', 0):.4f})")

                    # Rate limiting
                    if not args.dry_run:
                        time.sleep(REQUEST_DELAY)
                else:
                    # Mark as failed
                    status['programs'][variant_key] = {
                        "generated": False,
                        "error": result.get('error', 'Unknown error'),
                        "failed_at": datetime.now().isoformat(),
                    }
                    status['total_failed'] = status.get('total_failed', 0) + 1

                    failed += 1
                    print(f"      ❌ Failed: {result.get('error', 'Unknown')}")

                # Save status periodically
                if (generated + failed) % 10 == 0:
                    save_status(status)

    # Final save
    save_status(status)

    # Summary
    print("\n" + "=" * 60)
    print("📊 GENERATION SUMMARY")
    print("=" * 60)
    print(f"Generated: {generated}")
    print(f"Skipped (already exist): {skipped}")
    print(f"Failed: {failed}")
    print(f"Total cost: ${total_cost:.4f}")
    print(f"\nStatus saved to: {STATUS_FILE}")
    print(f"JSON files in: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
