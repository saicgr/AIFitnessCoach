#!/usr/bin/env python3
"""
Program Generation Pipeline with Week-by-Week Generation

Generates programs by PRIORITY order (High → Medium → Low).
Large programs are generated week-by-week with immediate Supabase ingestion.

Features:
- Week-by-week generation for large programs (avoids output truncation)
- Previous week context passed to AI for progression continuity
- Immediate ingestion to Supabase (no large JSON files)
- Resume capability if generation fails mid-program

Usage:
    cd backend
    python3 scripts/generate_programs.py --priority high --no-break
    python3 scripts/generate_programs.py --priority medium --no-break
    python3 scripts/generate_programs.py --priority low --no-break
    python3 scripts/generate_programs.py --dry-run
    python3 scripts/generate_programs.py --resume --program "HYROX"
"""

import os
import re
import json
import time
import argparse
from pathlib import Path
from typing import Optional
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

# Rate limiting
REQUESTS_PER_MINUTE = 15
REQUEST_DELAY = 60 / REQUESTS_PER_MINUTE

# Priority order
PRIORITY_ORDER = {'High': 0, 'Med': 1, 'Low': 2, 'Done': 99}

# Maximum workouts per API call before chunking to week-by-week
MAX_WORKOUTS_PER_CALL = 12  # ~4 weeks × 3 sessions or 2 weeks × 6 sessions

# Database table names
TABLE_BRANDED_PROGRAMS = 'branded_programs'
TABLE_PROGRAM_VARIANTS = 'program_variants'
TABLE_VARIANT_WEEKS = 'program_variant_weeks'


# ============================================================================
# SUPABASE CLIENT
# ============================================================================

_supabase_client = None

def get_supabase():
    """Get or create Supabase client."""
    global _supabase_client
    if _supabase_client is None:
        from supabase import create_client
        _supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _supabase_client


# ============================================================================
# COMPLETION CHECK (via Supabase)
# ============================================================================

def get_completed_variants(supabase) -> set:
    """Get set of variant keys that are already complete in Supabase."""
    completed = set()

    # Get all variants with their week counts
    variants_result = supabase.table(TABLE_PROGRAM_VARIANTS).select(
        'id, variant_name, duration_weeks, sessions_per_week'
    ).execute()

    for variant in variants_result.data:
        variant_id = variant['id']
        duration = variant['duration_weeks']

        # Count weeks for this variant
        weeks_result = supabase.table(TABLE_VARIANT_WEEKS).select(
            'week_number', count='exact'
        ).eq('variant_id', variant_id).execute()

        weeks_count = len(weeks_result.data) if weeks_result.data else 0

        # If all weeks are generated, mark as complete
        if weeks_count >= duration:
            # Create variant key from name
            name = variant['variant_name']
            safe_name = re.sub(r'[^\w\s-]', '', name).replace(' ', '_')
            key = f"{safe_name}_{duration}w_{variant['sessions_per_week']}d"
            completed.add(key.lower())

    return completed


# ============================================================================
# CHECKLIST PARSING
# ============================================================================

def parse_checklist() -> list[dict]:
    """Parse PROGRAMS_CHECKLIST.md with Priority column."""
    with open(CHECKLIST_PATH) as f:
        content = f.read()

    programs = []
    current_category = None
    current_category_num = 0

    category_pattern = r'^## (\d+)\. (.+?) \((\d+) programs?\)'
    program_pattern = r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|'

    in_table = False

    for line in content.split('\n'):
        cat_match = re.match(category_pattern, line)
        if cat_match:
            current_category_num = int(cat_match.group(1))
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

                # Skip if already done or JSON complete
                if is_done or json_done or priority == '✅':
                    continue

                durations = parse_durations(durations_str)
                sessions = parse_sessions(sessions_str)

                if durations and sessions:
                    programs.append({
                        "name": name,
                        "priority": priority,
                        "priority_order": PRIORITY_ORDER.get(priority, 99),
                        "category": current_category,
                        "category_num": current_category_num,
                        "description": description,
                        "durations": durations,
                        "sessions": sessions,
                        "has_supersets": has_supersets,
                    })

    programs.sort(key=lambda x: (x['priority_order'], x['category_num']))
    return programs


def parse_durations(s: str) -> list[int]:
    s = s.replace('w', '').replace('W', '')
    durations = []
    for part in s.split(','):
        part = part.strip()
        if part.isdigit():
            durations.append(int(part))
    return durations


def parse_sessions(s: str) -> list[int]:
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
    safe_name = re.sub(r'[^\w\s-]', '', program_name).replace(' ', '_')
    return f"{safe_name}_{duration}w_{sessions}d"


# ============================================================================
# GOALS DETERMINATION
# ============================================================================

def determine_goals(program: dict) -> list[str]:
    """Derive specific goals from program name, category, and description."""
    name = program.get('name', '').lower()
    category = program.get('category', '').lower()
    description = program.get('description', '').lower()

    goals = []

    # Strength goals
    if any(x in name or x in category for x in ['strength', 'powerlifting', '5x5', '5/3/1', 'barbell']):
        goals.extend(['Increase maximal strength', 'Build neural efficiency', 'Progressive overload on compound lifts'])
    if 'squat' in name:
        goals.append('Improve squat 1RM')
    if 'deadlift' in name:
        goals.append('Improve deadlift 1RM')
    if 'bench' in name:
        goals.append('Improve bench press 1RM')

    # Hypertrophy goals
    if any(x in name or x in category for x in ['hypertrophy', 'muscle', 'bodybuilding', 'mass', 'size']):
        goals.extend(['Maximize muscle hypertrophy', 'Time under tension', 'Mind-muscle connection'])
    if 'arm' in name:
        goals.append('Build bigger biceps and triceps')
    if 'chest' in name:
        goals.append('Develop chest size and definition')
    if 'back' in name:
        goals.append('Build a wider, thicker back')
    if 'leg' in name:
        goals.append('Develop leg size and strength')
    if 'glute' in name or 'booty' in name:
        goals.extend(['Build glute size and strength', 'Improve hip extension power'])

    # Fat loss goals
    if any(x in name or x in category for x in ['fat loss', 'shred', 'cut', 'lean', 'hiit', 'burn']):
        goals.extend(['Maximize calorie burn', 'Preserve lean muscle', 'Boost metabolic rate'])

    # Athletic/Performance goals
    if any(x in name or x in category for x in ['athletic', 'sport', 'performance', 'speed', 'agility']):
        goals.extend(['Improve athletic performance', 'Develop power and explosiveness', 'Enhance coordination'])
    if 'hyrox' in name:
        goals.extend(['Build race-specific endurance', 'Improve running economy', 'Master HYROX stations', 'Develop mental toughness'])
    if 'triathlon' in name:
        goals.extend(['Balance swim/bike/run', 'Build aerobic base', 'Improve transition efficiency'])

    # Endurance goals
    if any(x in name or x in category for x in ['endurance', 'cardio', 'running', 'marathon', 'conditioning']):
        goals.extend(['Build cardiovascular endurance', 'Improve VO2 max', 'Develop aerobic capacity'])

    # Flexibility/Mobility goals
    if any(x in name or x in category for x in ['flexibility', 'stretch', 'mobility', 'yoga', 'pilates']):
        goals.extend(['Improve flexibility and range of motion', 'Reduce muscle tension', 'Enhance body awareness'])

    # Home/Bodyweight goals
    if any(x in name or x in category for x in ['home', 'bodyweight', 'calisthenics', 'no equipment']):
        goals.extend(['Build functional strength without equipment', 'Improve body control', 'Develop relative strength'])

    # Recovery goals
    if any(x in name or x in category for x in ['recovery', 'rehab', 'deload']):
        goals.extend(['Promote active recovery', 'Reduce injury risk', 'Restore movement quality'])

    # Tactical/Military goals
    if any(x in name or x in category for x in ['tactical', 'military', 'special forces', 'first responder']):
        goals.extend(['Build occupational fitness', 'Develop work capacity', 'Improve load carriage ability'])

    # Default goals if none matched
    if not goals:
        goals = ['Improve overall fitness', 'Build strength and endurance', 'Enhance movement quality']

    return goals[:5]  # Max 5 goals


# ============================================================================
# PHASE DETERMINATION
# ============================================================================

def determine_phase(week_num: int, total_weeks: int, category: str = "") -> str:
    """Determine the training phase based on week number and total duration."""
    progress = week_num / total_weeks

    # Special handling for HYROX programs
    if "hyrox" in category.lower():
        if progress <= 0.4:
            return "Blueprint (Aerobic Foundation)"
        elif progress <= 0.75:
            return "Build (Race-Specific)"
        elif progress <= 0.95:
            return "Race (Peak Performance)"
        else:
            return "Taper/Race Week"

    # General periodization
    if progress <= 0.25:
        return "Foundation (Base Building)"
    elif progress <= 0.5:
        return "Build (Progressive Overload)"
    elif progress <= 0.75:
        return "Peak (Intensification)"
    elif progress <= 0.9:
        return "Taper (Deload)"
    else:
        return "Test/Maintenance"


# ============================================================================
# WEEK SUMMARY EXTRACTION
# ============================================================================

def extract_week_summary(week_data: dict) -> str:
    """Extract detailed info from week for context in next week's generation."""
    exercises_by_workout = []
    total_sets = 0
    total_reps = 0
    exercise_count = 0

    for workout in week_data.get('workouts', []):
        workout_name = workout.get('workout_name', workout.get('type', 'Workout'))
        workout_exercises = []
        for ex in workout.get('exercises', []):
            ex_name = ex.get('name', '')

            # Get sets - MUST be present
            sets = ex.get('sets')
            if sets is None or sets == 0:
                # Try set_targets as fallback
                set_targets = ex.get('set_targets', [])
                sets = len(set_targets) if set_targets else 3  # Default to 3 if missing

            # Get reps - MUST be present
            reps = ex.get('reps')
            if reps is None or reps == 0:
                # Check if it's a timed exercise
                duration = ex.get('duration_seconds')
                if duration:
                    reps = 1  # Timed exercises count as 1 rep
                else:
                    # Try set_targets as fallback
                    set_targets = ex.get('set_targets', [])
                    if set_targets:
                        for st in set_targets:
                            if st.get('set_type') in ['working', 'amrap', None]:
                                reps = st.get('target_reps', 10)
                                break
                    if not reps:
                        reps = 10  # Default to 10 if missing

            # Convert to integers
            sets_num = int(sets) if isinstance(sets, (int, float)) else 3
            reps_num = int(reps) if isinstance(reps, (int, float)) else 10

            # Get weight guidance for context
            weight_guidance = ex.get('weight_guidance', ex.get('weight', 'Moderate'))

            if ex_name:
                workout_exercises.append(f"{ex_name} ({sets_num}x{reps_num}, {weight_guidance})")
                total_sets += sets_num
                total_reps += reps_num
                exercise_count += 1

        if workout_exercises:
            exercises_by_workout.append(f"  {workout_name}: {', '.join(workout_exercises[:5])}")

    workouts_summary = '\n'.join(exercises_by_workout[:4])  # Max 4 workouts
    avg_sets = total_sets // exercise_count if exercise_count else 3
    avg_reps = total_reps // exercise_count if exercise_count else 10

    return f"""- Phase: {week_data.get('phase', 'Unknown')}
- Focus: {week_data.get('focus', 'General')}
- Workouts:
{workouts_summary}
- Avg per exercise: {avg_sets} sets x {avg_reps} reps"""


# ============================================================================
# PROMPTS
# ============================================================================

def get_system_prompt(program: dict) -> str:
    """Get the system prompt for workout generation."""
    has_supersets = program.get("has_supersets", False)

    base_prompt = """You are a certified personal trainer creating professional workout programs in JSON format.

RULES:
1. Return ONLY valid JSON - no markdown, no explanations
2. Every workout MUST have: warmup, exercises, cooldown
3. Include specific sets, reps, rest periods, and WEIGHT GUIDANCE for every exercise
4. Progress difficulty across weeks (increase weight/reps/sets)
5. Include deload weeks where appropriate (typically every 4th week)
6. Use real, standard exercise names

WEIGHT GUIDANCE FORMAT:
- Use RPE (Rate of Perceived Exertion): "RPE 7", "RPE 8-9"
- OR RIR (Reps in Reserve): "RIR 3", "RIR 1-2", "RIR 0 (failure)"
- OR percentage of 1RM: "70% 1RM", "80% 1RM"
- OR specific weight when known: "20kg/44lb", "Men: 24kg, Women: 16kg"
- OR relative terms: "Bodyweight", "Light", "Moderate", "Heavy"

EXERCISE STRUCTURE (REQUIRED FIELDS - sets and reps MUST be positive integers, NEVER null or 0):
{
  "name": "string (REQUIRED)",
  "sets": integer (REQUIRED, minimum 1, typically 2-5),
  "reps": integer (REQUIRED, minimum 1, typically 5-20. For timed exercises use duration_seconds instead but still set reps to 1),
  "rest_seconds": integer (REQUIRED, typically 30-180),
  "weight_guidance": "string (REQUIRED - e.g., 'RPE 7', '70% 1RM', 'Bodyweight', 'Moderate')",
  "equipment": "string",
  "body_part": "string",
  "primary_muscle": "string",
  "secondary_muscles": ["string"] or null,
  "difficulty": "beginner|intermediate|advanced",
  "tempo": "string or null (e.g., '3-1-2-0')",
  "form_cue": "string (1 key form tip)",
  "breathing_cue": "string",
  "setup": "string (brief setup instruction)",
  "substitution": "string or null",
  "is_unilateral": boolean,
  "hold_seconds": integer or null (for isometric holds),
  "duration_seconds": integer or null (for timed exercises like planks, runs),
  "superset_group": integer or null,
  "superset_order": integer or null,
  "is_drop_set": boolean,
  "is_failure_set": boolean
}

CRITICAL: Every exercise MUST have:
- "sets": positive integer (1-10)
- "reps": positive integer (1-50)
- "weight_guidance": string describing load
Never use null, 0, or omit these fields!

KEEP CUES BRIEF:
- form_cue: Max 10 words
- breathing_cue: Max 8 words
- setup: Max 12 words"""

    if has_supersets:
        base_prompt += """

SUPERSETS:
This program supports supersets. Use superset_group and superset_order fields.
- superset_group: Same number for paired exercises (1, 2, 3...)
- superset_order: 1 for first exercise, 2 for second
- First exercise: rest_seconds = 0
- Second exercise: rest_seconds = 60-90"""

    return base_prompt


def get_week_prompt(program: dict, week_num: int, total_weeks: int,
                    sessions: int, all_previous_summaries: list = None) -> str:
    """Generate prompt for a single week with FULL context from ALL previous weeks."""
    phase = determine_phase(week_num, total_weeks, program.get('category', ''))
    has_supersets = program.get('has_supersets', False)
    goals = determine_goals(program)
    goals_str = '\n'.join([f"  - {g}" for g in goals])

    context = ""
    if all_previous_summaries and len(all_previous_summaries) > 0:
        # Build full context from all previous weeks
        weeks_context = "\n\n".join(all_previous_summaries)
        context = f"""
PREVIOUS WEEKS CONTEXT (Weeks 1-{week_num - 1}):
{weeks_context}

PROGRESSION REQUIREMENTS FOR WEEK {week_num}:
- Build upon the exercises and weights from previous weeks
- Increase weight by 2.5-5% OR add 1-2 reps OR reduce rest by 10-15s
- Keep 3-5 CORE lifts consistent for tracking progress (e.g., squat, bench, deadlift)
- ROTATE 40-60% of accessory exercises to add variety and prevent staleness
- Introduce 2-4 NEW exercise variations this week
- Follow periodization: Phase is now "{phase}"
- Ensure logical progression from Week {week_num - 1} to Week {week_num}
- STAY FOCUSED ON THE PROGRAM GOALS LISTED BELOW
"""

    superset_note = ""
    if has_supersets:
        superset_note = "\n- Include supersets where appropriate (use superset_group/superset_order)"

    return f"""Generate ONLY Week {week_num} of {total_weeks} for "{program['name']}".

PROGRAM CONTEXT:
- Name: {program['name']}
- Category: {program['category']}
- Description: {program['description']}
- Total Duration: {total_weeks} weeks
- Sessions/week: {sessions}
- Current Phase: {phase}
- Week {week_num} of {total_weeks}

PROGRAM GOALS (every workout MUST work toward these):
{goals_str}
{context}
REQUIREMENTS:
- Generate exactly {sessions} workouts for Week {week_num}
- Every exercise must contribute to the PROGRAM GOALS above
- Include warmup, exercises, cooldown for each workout
- Include weight_guidance for EVERY exercise (RPE, % 1RM, or relative terms)

EXERCISE VARIETY RULES:
- Use 15-25 DIFFERENT exercises across the week (not the same 5-6 repeated)
- Vary movement patterns: push, pull, hinge, squat, carry, rotation
- Include compound AND isolation exercises appropriate to goals
- Mix equipment: barbell, dumbbell, cable, bodyweight, machines
- Rotate exercise variations (e.g., don't just do barbell bench - include incline, dumbbell, cable fly)
- Each workout should feel fresh while maintaining goal focus{superset_note}

Return JSON with this exact structure:
{{
  "week": {week_num},
  "phase": "{phase}",
  "focus": "string describing this week's focus",
  "workouts": [
    {{
      "day": 1,
      "workout_name": "string",
      "type": "Strength|Cardio|Hybrid|Recovery",
      "duration_minutes": number,
      "intensity": "Low|Moderate|Hard",
      "warmup": [...],
      "exercises": [...],
      "cooldown": [...],
      "coach_notes": "string"
    }}
  ]
}}

Return ONLY valid JSON. No markdown, no explanations."""


def get_full_program_prompt(program: dict, duration: int, sessions: int) -> str:
    """Get prompt for generating a complete small program in one call."""
    total_workouts = duration * sessions
    has_supersets = program.get('has_supersets', False)
    goals = determine_goals(program)
    goals_str = '\n'.join([f"  - {g}" for g in goals])

    superset_instruction = ""
    if has_supersets:
        superset_instruction = """
- Include supersets where appropriate (pair exercises with superset_group number)
- Use supersets for antagonist muscles (e.g., biceps/triceps) or upper/lower combinations"""

    return f"""Generate a complete {duration}-week "{program['name']}" workout program.

PROGRAM:
- Name: {program['name']}
- Category: {program['category']}
- Description: {program['description']}

PROGRAM GOALS (every workout MUST work toward these):
{goals_str}

DETAILS:
- Duration: {duration} weeks
- Sessions/week: {sessions}
- Total workouts: {total_workouts}

REQUIREMENTS:
- Every exercise MUST contribute to the PROGRAM GOALS above
- Include weight_guidance for EVERY exercise (RPE, % 1RM, or relative terms)
- Progress weights/intensity across weeks to achieve goals

EXERCISE VARIETY RULES:
- Use 30-50+ DIFFERENT exercises across the entire program
- Vary movement patterns each week: push, pull, hinge, squat, carry, rotation
- Include compound AND isolation exercises appropriate to goals
- Mix equipment: barbell, dumbbell, cable, bodyweight, machines
- Rotate exercise variations week-to-week (don't repeat identical workouts)
- Each week should introduce 2-4 new exercise variations while keeping core lifts{superset_instruction}

OUTPUT FORMAT:
{{
  "program_name": "{program['name']}",
  "description": "string",
  "duration_weeks": {duration},
  "sessions_per_week": {sessions},
  "difficulty": "beginner|intermediate|advanced",
  "equipment_required": ["list"],
  "workouts": {{
    "weeks": [
      {{
        "week": number,
        "phase": "string",
        "focus": "string",
        "workouts": [...]
      }}
    ]
  }}
}}

Generate ALL {total_workouts} workouts organized by week.
Return ONLY JSON."""


# ============================================================================
# VALIDATION
# ============================================================================

def validate_week(week_data: dict, expected_sessions: int) -> dict:
    """Validate a single week of workouts. STRICT validation - sets/reps MUST be positive integers."""
    issues = []
    score = 100

    if not week_data.get('week'):
        issues.append("Missing week number")
        score -= 10

    workouts = week_data.get('workouts', [])
    if len(workouts) < expected_sessions:
        issues.append(f"Workouts: {len(workouts)}/{expected_sessions}")
        score -= 15

    exercises_found = 0
    invalid_exercises = 0

    for workout in workouts:
        if not workout.get('warmup'):
            score -= 2
        exercises = workout.get('exercises', [])
        if not exercises:
            issues.append(f"Day {workout.get('day', '?')} missing exercises")
            score -= 10
            continue

        for ex in exercises:
            exercises_found += 1
            ex_name = ex.get('name', 'Unknown')

            # STRICT: sets must be a positive integer
            sets = ex.get('sets')
            if sets is None or sets == 0 or not isinstance(sets, (int, float)) or sets < 1:
                issues.append(f"'{ex_name}' has invalid sets: {sets}")
                invalid_exercises += 1
                score -= 5

            # STRICT: reps must be a positive integer (unless it's a timed exercise)
            reps = ex.get('reps')
            duration = ex.get('duration_seconds')
            if duration and duration > 0:
                # Timed exercise - reps can be 1 or omitted
                pass
            elif reps is None or reps == 0 or not isinstance(reps, (int, float)) or reps < 1:
                issues.append(f"'{ex_name}' has invalid reps: {reps}")
                invalid_exercises += 1
                score -= 5

            # Check for weight_guidance
            if not ex.get('weight_guidance'):
                score -= 1  # Minor deduction

    if exercises_found < expected_sessions * 3:  # At least 3 exercises per workout
        issues.append(f"Low exercise count: {exercises_found}")
        score -= 10

    # FAIL if any exercise has invalid sets/reps
    if invalid_exercises > 0:
        issues.insert(0, f"CRITICAL: {invalid_exercises} exercises have invalid sets/reps")
        score = min(score, 50)  # Cap score at 50 if there are invalid exercises

    return {
        "valid": invalid_exercises == 0 and len(issues) == 0 and score >= 70,
        "score": max(0, score),
        "issues": issues,
        "exercises_found": exercises_found,
        "invalid_exercises": invalid_exercises
    }


def validate_program(data: dict, expected_weeks: int, expected_sessions: int) -> dict:
    """Validate generated program data."""
    issues = []
    score = 100

    required_fields = ["program_name", "duration_weeks", "sessions_per_week", "workouts"]
    for field in required_fields:
        if field not in data:
            issues.append(f"Missing: {field}")
            score -= 25

    if "workouts" not in data:
        return {"valid": False, "score": 0, "issues": issues, "warnings": []}

    workouts_data = data.get("workouts", {})
    weeks = workouts_data.get("weeks", [])

    if not weeks:
        if isinstance(workouts_data, list):
            weeks = workouts_data
        else:
            issues.append("Missing 'weeks' array")
            score -= 20

    expected_total = expected_weeks * expected_sessions
    actual_weeks = len(weeks)
    actual_total = sum(len(w.get("workouts", [])) for w in weeks)

    if actual_weeks < expected_weeks:
        issues.append(f"Weeks: {actual_weeks}/{expected_weeks}")
        score -= 15

    if actual_total < expected_total:
        issues.append(f"Workouts: {actual_total}/{expected_total}")
        score -= 15

    all_exercises = set()
    for week in weeks:
        for workout in week.get("workouts", []):
            exercises = workout.get("exercises", [])
            for ex in exercises:
                name = ex.get("name", ex.get("exercise_name", ""))
                if name:
                    all_exercises.add(name.lower())

    if len(all_exercises) < 5:
        issues.append(f"Low variety: {len(all_exercises)} exercises")
        score -= 10

    return {
        "valid": len(issues) == 0 and score >= 70,
        "score": max(0, score),
        "issues": issues,
        "warnings": [],
        "stats": {
            "expected_workouts": expected_total,
            "actual_workouts": actual_total,
            "unique_exercises": len(all_exercises)
        }
    }


# ============================================================================
# DATABASE OPERATIONS
# ============================================================================

def get_or_create_branded_program(supabase, program: dict) -> Optional[str]:
    """Get existing branded_program or create new one. Returns UUID."""
    base_name = program['name']

    # Check if exists
    result = supabase.table(TABLE_BRANDED_PROGRAMS).select('id, name').ilike(
        'name', f'%{base_name}%'
    ).limit(1).execute()

    if result.data:
        return result.data[0]['id']

    # Determine category
    category = "general_fitness"
    name_lower = base_name.lower()
    if any(x in name_lower for x in ["strength", "powerlifting", "5x5"]):
        category = "strength"
    elif any(x in name_lower for x in ["hypertrophy", "muscle", "bodybuilding"]):
        category = "hypertrophy"
    elif any(x in name_lower for x in ["fat loss", "shred", "hiit"]):
        category = "fat_loss"
    elif any(x in name_lower for x in ["athletic", "hyrox", "functional"]):
        category = "athletic"
    elif any(x in name_lower for x in ["home", "bodyweight", "calisthenics"]):
        category = "bodyweight"

    # Determine difficulty
    difficulty = "intermediate"
    if "beginner" in name_lower:
        difficulty = "beginner"
    elif "advanced" in name_lower or "elite" in name_lower:
        difficulty = "advanced"

    # Determine split type
    split_type = "full_body"
    if "ppl" in name_lower or "push pull" in name_lower:
        split_type = "push_pull_legs"
    elif "upper lower" in name_lower:
        split_type = "upper_lower"

    new_program = {
        "name": base_name,
        "tagline": program.get("description", "")[:100] if program.get("description") else None,
        "description": program.get("description"),
        "category": category,
        "difficulty_level": difficulty,
        "duration_weeks": max(program.get('durations', [8])),
        "sessions_per_week": max(program.get('sessions', [4])),
        "split_type": split_type,
        "goals": [],
        "requires_gym": True,
        "minimum_equipment": [],
        "is_active": True,
        "is_featured": False,
        "is_premium": False,
    }

    try:
        result = supabase.table(TABLE_BRANDED_PROGRAMS).insert(new_program).execute()
        if result.data:
            print(f"      ✨ Created branded_program: {base_name}")
            return result.data[0]['id']
    except Exception as e:
        print(f"      ⚠️ Failed to create branded_program: {e}")

    return None


def create_variant_record(supabase, branded_program_id: str, program: dict,
                          duration: int, sessions: int) -> Optional[str]:
    """Create a program_variants record. Returns variant UUID."""
    variant_name = program['name']

    # Determine intensity
    intensity = "Medium"
    if "easy" in variant_name.lower() or "beginner" in variant_name.lower():
        intensity = "Easy"
    elif "hard" in variant_name.lower() or "advanced" in variant_name.lower():
        intensity = "Hard"

    # Determine category
    category = "General_Fitness"
    name_lower = variant_name.lower()
    if any(x in name_lower for x in ["strength", "powerlifting"]):
        category = "Strength"
    elif any(x in name_lower for x in ["hypertrophy", "muscle"]):
        category = "Hypertrophy"
    elif any(x in name_lower for x in ["athletic", "hyrox"]):
        category = "Athletic"

    variant_record = {
        "base_program_id": branded_program_id,
        "variant_name": variant_name,
        "intensity_level": intensity,
        "duration_weeks": duration,
        "program_category": category,
        "sessions_per_week": sessions,
        "session_duration_minutes": 60,
        "tags": [],
        "goals": [],
        "workouts": {},  # Will be empty - weeks stored separately
        "generation_model": GEMINI_MODEL,
        "generation_cost_usd": 0,
    }

    try:
        result = supabase.table(TABLE_PROGRAM_VARIANTS).insert(variant_record).execute()
        if result.data:
            return result.data[0]['id']
    except Exception as e:
        error_msg = str(e)
        if "duplicate" in error_msg.lower() or "unique" in error_msg.lower():
            # Already exists, find and return it
            existing = supabase.table(TABLE_PROGRAM_VARIANTS).select('id').eq(
                'base_program_id', branded_program_id
            ).eq('duration_weeks', duration).eq('sessions_per_week', sessions).execute()
            if existing.data:
                return existing.data[0]['id']
        print(f"      ⚠️ Failed to create variant: {e}")

    return None


def ingest_week_to_supabase(supabase, variant_id: str, week_num: int,
                             week_data: dict, program_metadata: dict = None) -> bool:
    """Ingest a single week to program_variant_weeks table with checklist metadata."""
    week_record = {
        "variant_id": variant_id,
        "week_number": week_num,
        "phase": week_data.get('phase'),
        "focus": week_data.get('focus'),
        "workouts": week_data.get('workouts', []),
    }

    # Add checklist metadata if provided
    if program_metadata:
        week_record["program_name"] = program_metadata.get('name')
        week_record["variant_name"] = program_metadata.get('variant_name')
        week_record["priority"] = program_metadata.get('priority')
        week_record["has_supersets"] = program_metadata.get('has_supersets', False)
        week_record["description"] = program_metadata.get('description')
        week_record["category"] = program_metadata.get('category')

    try:
        result = supabase.table(TABLE_VARIANT_WEEKS).insert(week_record).execute()
        return bool(result.data)
    except Exception as e:
        error_msg = str(e)
        if "duplicate" in error_msg.lower() or "unique" in error_msg.lower():
            # Already exists, update it
            try:
                update_data = {
                    "phase": week_data.get('phase'),
                    "focus": week_data.get('focus'),
                    "workouts": week_data.get('workouts', []),
                }
                if program_metadata:
                    update_data["program_name"] = program_metadata.get('name')
                    update_data["variant_name"] = program_metadata.get('variant_name')
                    update_data["priority"] = program_metadata.get('priority')
                    update_data["has_supersets"] = program_metadata.get('has_supersets', False)
                    update_data["description"] = program_metadata.get('description')
                    update_data["category"] = program_metadata.get('category')
                supabase.table(TABLE_VARIANT_WEEKS).update(update_data).eq(
                    'variant_id', variant_id
                ).eq('week_number', week_num).execute()
                return True
            except:
                pass
        print(f"         ⚠️ Failed to ingest week {week_num}: {e}")
        return False


def update_variant_cost(supabase, variant_id: str, total_cost: float):
    """Update the generation cost for a variant."""
    try:
        supabase.table(TABLE_PROGRAM_VARIANTS).update({
            "generation_cost_usd": total_cost
        }).eq('id', variant_id).execute()
    except Exception as e:
        print(f"      ⚠️ Failed to update cost: {e}")


def get_existing_weeks(supabase, variant_id: str) -> list[int]:
    """Get list of week numbers already generated for a variant."""
    try:
        result = supabase.table(TABLE_VARIANT_WEEKS).select('week_number').eq(
            'variant_id', variant_id
        ).execute()
        return [r['week_number'] for r in result.data]
    except:
        return []


def get_last_week_data(supabase, variant_id: str, week_num: int) -> Optional[dict]:
    """Get the data for a specific week (for resume context)."""
    try:
        result = supabase.table(TABLE_VARIANT_WEEKS).select('*').eq(
            'variant_id', variant_id
        ).eq('week_number', week_num).execute()
        if result.data:
            return result.data[0]
    except:
        pass
    return None


# ============================================================================
# GENERATION - SINGLE WEEK
# ============================================================================

def generate_single_week(program: dict, week_num: int, total_weeks: int,
                         sessions: int, all_previous_summaries: list,
                         client, dry_run: bool = False) -> dict:
    """Generate a single week of workouts with FULL context from all previous weeks."""
    if dry_run:
        return {
            "success": True,
            "dry_run": True,
            "data": {"week": week_num, "phase": "Test", "focus": "Dry run", "workouts": []},
            "cost": 0
        }

    from google.genai import types

    system_prompt = get_system_prompt(program)
    user_prompt = get_week_prompt(program, week_num, total_weeks, sessions, all_previous_summaries)

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

        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        data = json.loads(text)

        usage = response.usage_metadata
        input_tokens = usage.prompt_token_count if usage else 0
        output_tokens = usage.candidates_token_count if usage else 0
        cost = (input_tokens * 0.15 + output_tokens * 0.60) / 1_000_000

        validation = validate_week(data, sessions)

        if not validation['valid']:
            # Log which exercises failed validation
            print(f"\n         ❌ Validation errors: {', '.join(validation['issues'][:3])}")

        return {
            "success": validation['valid'],
            "data": data,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost": cost,
            "validation": validation,
            "error": f"Validation failed: {', '.join(validation['issues'][:3])}" if not validation['valid'] else None
        }

    except json.JSONDecodeError as e:
        return {
            "success": False,
            "error": f"JSON parse error: {e}",
            "cost": 0,
            "validation": {"valid": False, "score": 0, "issues": [str(e)]}
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "cost": 0,
            "validation": {"valid": False, "score": 0, "issues": [str(e)]}
        }


# ============================================================================
# GENERATION - WEEK BY WEEK WITH IMMEDIATE INGESTION
# ============================================================================

def generate_variant_weekly(program: dict, duration: int, sessions: int,
                            supabase, client, dry_run: bool = False,
                            resume: bool = False) -> dict:
    """Generate program week-by-week, ingesting each week immediately to Supabase."""

    # Handle dry run - skip DB operations
    if dry_run:
        branded_id = "dry-run-branded-id"
        variant_id = "dry-run-variant-id"
    else:
        # Get or create branded program
        branded_id = get_or_create_branded_program(supabase, program)
        if not branded_id:
            return {"success": False, "error": "Failed to create branded_program"}

        # Create variant record
        variant_id = create_variant_record(supabase, branded_id, program, duration, sessions)
        if not variant_id:
            return {"success": False, "error": "Failed to create variant record"}

    # Check for resume - load ALL previous weeks' summaries
    start_week = 1
    all_previous_summaries = []  # List of all previous week summaries
    if resume and not dry_run:
        existing_weeks = get_existing_weeks(supabase, variant_id)
        if existing_weeks:
            start_week = max(existing_weeks) + 1
            # Load ALL previous weeks for full context
            for prev_week_num in sorted(existing_weeks):
                prev_week_data = get_last_week_data(supabase, variant_id, prev_week_num)
                if prev_week_data:
                    summary = f"Week {prev_week_num}:\n{extract_week_summary(prev_week_data)}"
                    all_previous_summaries.append(summary)
            print(f"      📂 Resuming from Week {start_week} ({len(existing_weeks)} weeks loaded as context)")

    total_cost = 0
    weeks_generated = 0

    for week_num in range(start_week, duration + 1):
        print(f"      📅 Week {week_num}/{duration}...", end=" ", flush=True)

        # Generate this week with FULL context from ALL previous weeks
        result = generate_single_week(
            program, week_num, duration, sessions,
            all_previous_summaries, client, dry_run
        )

        if not result['success']:
            print(f"❌ Failed")
            print(f"         {result.get('error', 'Unknown error')}")
            # Partial success - return what we have
            if not dry_run:
                update_variant_cost(supabase, variant_id, total_cost)
            return {
                "success": False,
                "partial": True,
                "variant_id": variant_id,
                "weeks_generated": weeks_generated,
                "weeks_total": duration,
                "cost": total_cost,
                "error": result.get('error')
            }

        # Immediately ingest to Supabase with program metadata
        if not dry_run:
            # Pass checklist metadata for storage
            program_metadata = {
                'name': program.get('name'),
                'variant_name': get_variant_key(program.get('name'), duration, sessions),
                'priority': program.get('priority'),
                'has_supersets': program.get('has_supersets', False),
                'description': program.get('description'),
                'category': program.get('category'),
            }
            ingested = ingest_week_to_supabase(supabase, variant_id, week_num, result['data'], program_metadata)
            if not ingested:
                print(f"⚠️ Ingest failed")
                continue

        # Add this week's summary to context for next week
        week_summary = f"Week {week_num}:\n{extract_week_summary(result['data'])}"
        all_previous_summaries.append(week_summary)

        total_cost += result.get('cost', 0)
        weeks_generated += 1

        print(f"✅ ${result.get('cost', 0):.4f}")

        if not dry_run:
            time.sleep(REQUEST_DELAY)

    # Update total cost
    if not dry_run:
        update_variant_cost(supabase, variant_id, total_cost)

    return {
        "success": True,
        "variant_id": variant_id,
        "weeks_generated": weeks_generated,
        "cost": total_cost,
        "validation": {"valid": True, "score": 100, "issues": []}
    }


# ============================================================================
# GENERATION - SMALL PROGRAMS (SINGLE CALL)
# ============================================================================

def generate_variant_single(program: dict, duration: int, sessions: int,
                            supabase, client, dry_run: bool = False) -> dict:
    """Generate and ingest a small program in a single API call."""
    if dry_run:
        return {
            "success": True,
            "dry_run": True,
            "validation": {"valid": True, "score": 100, "issues": [], "warnings": []}
        }

    from google.genai import types

    system_prompt = get_system_prompt(program)
    user_prompt = get_full_program_prompt(program, duration, sessions)

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

        text = response.text.strip()
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        data = json.loads(text)

        usage = response.usage_metadata
        input_tokens = usage.prompt_token_count if usage else 0
        output_tokens = usage.candidates_token_count if usage else 0
        cost = (input_tokens * 0.15 + output_tokens * 0.60) / 1_000_000

        validation = validate_program(data, duration, sessions)

        if validation['valid']:
            # Ingest to Supabase
            branded_id = get_or_create_branded_program(supabase, program)
            if branded_id:
                variant_id = create_variant_record(supabase, branded_id, program, duration, sessions)
                if variant_id:
                    # Prepare checklist metadata
                    program_metadata = {
                        'name': program.get('name'),
                        'variant_name': get_variant_key(program.get('name'), duration, sessions),
                        'priority': program.get('priority'),
                        'has_supersets': program.get('has_supersets', False),
                        'description': program.get('description'),
                        'category': program.get('category'),
                    }
                    # Ingest each week with metadata
                    weeks = data.get('workouts', {}).get('weeks', [])
                    for week_data in weeks:
                        week_num = week_data.get('week', weeks.index(week_data) + 1)
                        ingest_week_to_supabase(supabase, variant_id, week_num, week_data, program_metadata)
                    update_variant_cost(supabase, variant_id, cost)

        return {
            "success": True,
            "data": data,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost": cost,
            "validation": validation
        }

    except json.JSONDecodeError as e:
        return {
            "success": False,
            "error": f"JSON parse error: {e}",
            "validation": {"valid": False, "score": 0, "issues": [f"Invalid JSON: {e}"], "warnings": []}
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "validation": {"valid": False, "score": 0, "issues": [str(e)], "warnings": []}
        }


# ============================================================================
# MAIN GENERATION ROUTER
# ============================================================================

def generate_variant(program: dict, duration: int, sessions: int,
                     supabase, client, dry_run: bool = False,
                     resume: bool = False) -> dict:
    """Route to appropriate generation method based on program size."""
    total_workouts = duration * sessions

    if total_workouts > MAX_WORKOUTS_PER_CALL:
        # Use week-by-week generation for large programs
        print(f"      📦 Large ({total_workouts} workouts) - week-by-week mode")
        return generate_variant_weekly(program, duration, sessions, supabase, client, dry_run, resume)
    else:
        # Use single call for small programs
        return generate_variant_single(program, duration, sessions, supabase, client, dry_run)


# ============================================================================
# CHECKLIST UPDATE
# ============================================================================

def update_checklist(program_name: str, json_status: str, valid_status: str):
    """Update a single program's JSON and Valid columns.

    Note: This only works when running locally. On Render/server, the checklist
    file may not exist or changes won't persist. The function silently skips
    if the file is not found.
    """
    if not CHECKLIST_PATH.exists():
        # Running on server - checklist not available, skip silently
        return

    try:
        with open(CHECKLIST_PATH) as f:
            content = f.read()

        lines = content.split('\n')
        updated_lines = []

        for line in lines:
            prog_match = re.match(
                r'^\| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$',
                line.strip()
            )

            if prog_match and program_name.lower() in prog_match.group(1).strip().lower():
                name = prog_match.group(1).strip()
                pri = prog_match.group(2).strip()
                duration = prog_match.group(3).strip()
                sessions = prog_match.group(4).strip()
                description = prog_match.group(5).strip()
                ss = prog_match.group(6).strip()
                done = prog_match.group(7).strip()
                db_col = prog_match.group(10).strip()

                updated_lines.append(f"| {name} | {pri} | {duration} | {sessions} | {description} | {ss} | {done} | {json_status} | {valid_status} | {db_col} |")
            else:
                updated_lines.append(line)

        with open(CHECKLIST_PATH, 'w') as f:
            f.write('\n'.join(updated_lines))
    except Exception as e:
        # Don't fail generation if checklist update fails
        print(f"      ⚠️ Could not update checklist: {e}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Generate workout programs with week-by-week ingestion')
    parser.add_argument('--priority', type=str, choices=['high', 'medium', 'low', 'all'], default='all',
                        help='Generate only this priority level')
    parser.add_argument('--category', type=str, help='Generate only this category')
    parser.add_argument('--program', type=str, help='Generate only this program name')
    parser.add_argument('--dry-run', action='store_true', help='No API calls or DB writes')
    parser.add_argument('--no-break', action='store_true', help='Continue even on failures')
    parser.add_argument('--resume', action='store_true', help='Resume partially completed programs')
    parser.add_argument('--limit', type=int, help='Limit number of variants')
    parser.add_argument('--min-score', type=int, default=70, help='Minimum validation score')
    args = parser.parse_args()

    print("=" * 60)
    print("🏋️ PROGRAM GENERATION PIPELINE")
    print("=" * 60)
    print(f"Model: {GEMINI_MODEL}")
    print(f"Mode: Week-by-week with immediate Supabase ingestion")
    print(f"Max workouts/call: {MAX_WORKOUTS_PER_CALL}")
    print(f"Break on failure: {'No' if args.no_break else 'Yes'}")
    print(f"Resume mode: {'Yes' if args.resume else 'No'}")

    if args.dry_run:
        print("\n🔍 DRY RUN MODE - No API calls or DB writes")

    # Initialize clients
    supabase = None
    client = None
    if not args.dry_run:
        from google import genai
        client = genai.Client(api_key=GEMINI_API_KEY)
        supabase = get_supabase()
        print("✅ Connected to Supabase and Gemini")

    # Get completed variants from Supabase
    completed_variants = set()
    if not args.dry_run:
        print("\n📊 Checking completed variants in Supabase...")
        completed_variants = get_completed_variants(supabase)
        print(f"   Found {len(completed_variants)} completed variants")

    # Parse checklist
    print("\n📋 Parsing PROGRAMS_CHECKLIST.md...")
    programs = parse_checklist()

    # Filter by priority
    priority_map = {'high': 'High', 'medium': 'Med', 'low': 'Low'}
    if args.priority != 'all':
        target_pri = priority_map[args.priority]
        programs = [p for p in programs if p['priority'] == target_pri]
        print(f"   Filtered to {args.priority.upper()} priority only")

    if args.category:
        programs = [p for p in programs if args.category.lower() in p['category'].lower()]
        print(f"   Filtered to category '{args.category}'")

    if args.program:
        programs = [p for p in programs if args.program.lower() in p['name'].lower()]
        print(f"   Filtered to program '{args.program}'")

    # Count by priority
    high_count = sum(1 for p in programs if p['priority'] == 'High')
    med_count = sum(1 for p in programs if p['priority'] == 'Med')
    low_count = sum(1 for p in programs if p['priority'] == 'Low')

    total_variants = sum(len(p['durations']) * len(p['sessions']) for p in programs)

    print(f"\n   Programs: {len(programs)} (High:{high_count} Med:{med_count} Low:{low_count})")
    print(f"   Total variants: {total_variants}")

    # Process
    generated = 0
    validated = 0
    failed = 0
    skipped = 0
    total_cost = 0
    should_break = False

    limit = args.limit if args.limit else float('inf')
    current_priority = None

    for program in programs:
        if generated >= limit or should_break:
            break

        # Print priority header when it changes
        if program['priority'] != current_priority:
            current_priority = program['priority']
            pri_name = {'High': 'HIGH', 'Med': 'MEDIUM', 'Low': 'LOW'}.get(current_priority, 'UNKNOWN')
            print(f"\n{'='*60}")
            print(f"[{current_priority}] {pri_name} PRIORITY PROGRAMS")
            print(f"{'='*60}")

        print(f"\n📦 [{program['priority']}] {program['name']} ({program['category']})")

        program_json_count = 0
        program_valid_count = 0
        program_total = len(program['durations']) * len(program['sessions'])

        for duration in program['durations']:
            if generated >= limit or should_break:
                break

            for sessions in program['sessions']:
                if generated >= limit or should_break:
                    break

                variant_key = get_variant_key(program['name'], duration, sessions)

                # Skip if already complete (check Supabase)
                if not args.resume and variant_key.lower() in completed_variants:
                    print(f"   ⏭️  {variant_key} - already complete")
                    skipped += 1
                    program_json_count += 1
                    program_valid_count += 1
                    continue

                print(f"   🎯 {variant_key}")

                result = generate_variant(
                    program, duration, sessions,
                    supabase, client,
                    dry_run=args.dry_run,
                    resume=args.resume
                )

                if result.get('success'):
                    # Full success - data already in Supabase
                    generated += 1
                    program_json_count += 1
                    total_cost += result.get('cost', 0)
                    validated += 1
                    program_valid_count += 1
                    print(f"      ✅ Complete | ${result.get('cost', 0):.4f}")

                elif result.get('partial') and result.get('weeks_generated', 0) > 0:
                    # Partial success - some weeks generated and saved to Supabase
                    generated += 1
                    program_json_count += 1
                    total_cost += result.get('cost', 0)
                    failed += 1
                    print(f"      ⚠️ Partial ({result.get('weeks_generated', 0)} weeks) | {result.get('error', 'Unknown')}")

                    if not args.no_break:
                        print(f"\n🛑 STOPPING - Partial failure (use --no-break to continue)")
                        should_break = True
                else:
                    # Complete failure
                    failed += 1
                    print(f"      ❌ FAILED: {result.get('error', 'Unknown')}")

                    if not args.no_break:
                        print(f"\n🛑 STOPPING - Generation failed!")
                        should_break = True

        # Update checklist for this program
        if program_json_count > 0 and not args.dry_run:
            if program_json_count == program_total:
                json_status = '✅'
            else:
                json_status = f'⚠️{program_json_count}/{program_total}'

            if program_valid_count == program_total:
                valid_status = '✅'
            elif program_valid_count > 0:
                valid_status = f'⚠️{program_valid_count}/{program_total}'
            else:
                valid_status = '❌'

            update_checklist(program['name'], json_status, valid_status)

    # Summary
    print("\n" + "=" * 60)
    print("📊 PIPELINE SUMMARY")
    print("=" * 60)
    print(f"Generated: {generated}")
    print(f"Validated: {validated}")
    print(f"Failed: {failed}")
    print(f"Skipped: {skipped}")
    print(f"Total cost: ${total_cost:.4f}")

    if should_break:
        print(f"\n⚠️ Pipeline stopped due to failure. Use --no-break to continue anyway.")
        print(f"   Use --resume to continue from where you left off.")


if __name__ == "__main__":
    main()
