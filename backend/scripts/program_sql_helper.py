#!/usr/bin/env python3
"""
Program SQL Helper
==================
Reusable functions for generating and executing program SQL migrations.
Used by agent swarm to populate branded_programs, program_variants, and program_variant_weeks.

Usage:
    from program_sql_helper import ProgramSQLHelper
    helper = ProgramSQLHelper()
    helper.insert_program(program_data)
"""

import os
import json
import uuid
import psycopg2
from pathlib import Path
from dotenv import load_dotenv

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

MIGRATIONS_DIR = Path(__file__).parent.parent / "migrations"
TRACKER_PATH = Path(__file__).parent.parent.parent / "docs" / "PROGRAMS_GENERATION_TRACKER.md"

# Category mapping from checklist category names to DB category values
CATEGORY_MAP = {
    "Premium": "premium",
    "Strength": "strength",
    "Hypertrophy/Muscle Building": "hypertrophy",
    "Fat Loss": "fat_loss",
    "Flexibility/Stretches": "flexibility",
    "Sports": "sport_specific",
    "Celebrity-Style": "celebrity",
    "Challenges": "challenge",
    "Progressions": "progression",
    "Women's Health": "womens_health",
    "Men's Health": "mens_health",
    "Body-Specific": "body_specific",
    "Equipment-Specific": "equipment_specific",
    "Bodyweight/Home": "bodyweight",
    "Endurance": "endurance",
    "Calisthenics": "calisthenics",
    "Quick Workouts": "quick_workout",
    "Yoga": "yoga",
    "Pilates": "pilates",
    "Martial Arts": "martial_arts",
    "Kids & Youth": "kids_youth",
    "Seniors": "seniors",
    "Mind & Breath": "mind_body",
    "Lift Mobility": "mobility",
    "Warmup & Cooldown": "warmup_cooldown",
    "Targeted Stretching": "stretching",
    "Interval/HIIT": "hiit",
    "Rehab & Recovery": "rehab",
    "Hell Mode": "hell_mode",
    "Dance Fitness": "dance",
    "Face & Jaw Exercises": "face_jaw",
    "Posture Correction": "posture",
    "Sedentary/Couch to Fit": "sedentary",
    "Occupation-Based": "occupation",
    "Cardio & Conditioning": "conditioning",
    "Strongman/Functional": "strongman",
    "Lifestyle/Outdoor Cardio": "outdoor",
    "Longevity & Biohacking": "longevity",
    "GLP-1/Weight Loss Medication": "fat_loss",
    "Balance & Proprioception": "balance",
    "Hybrid Training": "hybrid",
    "Competition/Race Prep": "competition",
    "Social/Community Fitness": "social_fitness",
    "Seasonal/Climate Training": "seasonal",
    "Sleep & Recovery Optimization": "sleep_recovery",
    "Menstrual Cycle Synced": "menstrual_cycle",
    "Medical Condition Specific": "medical",
    "Desk Break Micro-Workouts": "desk_break",
    "Plyometrics & Explosiveness": "plyometrics",
    "Olympic Lifting": "olympic_lifting",
    "Swimming & Aquatic": "swimming",
    "Climbing & Vertical": "climbing",
    "Viral TikTok Programs": "viral",
    "Nervous System & Somatic": "nervous_system",
    "Weighted Accessories": "weighted_accessories",
    "YouTube-Style Home Programs": "home_workout",
    "Content Creator/Influencer Fitness": "influencer",
    "Life Events & Milestones": "life_events",
    "Reddit-Famous Programs": "reddit_famous",
    "Glute & Booty Building": "glute_building",
    "Turn Back Time (Anti-Aging)": "anti_aging",
    "Get to the F***in Gym": "motivational",
    "Fur Baby Friendly Fitness": "pet_friendly",
    "Ninja Mode Home Workouts": "ninja_mode",
    "Mood & Emotion Based": "mood_based",
    "Gen Z Vibes": "gen_z",
    "Gym is Packed (Quick Sessions)": "gym_packed",
    "Post-Meal Movement": "post_meal",
    "Fasted Workouts": "fasted",
    "Quick Hit Sessions": "quick_hit",
    "Mood Quick Hits": "mood_quick",
    "Travel & Hotel Fitness": "travel",
    "Night Shift & Shift Worker": "night_shift",
    "Gamer & Esports Fitness": "gamer",
    "Cruise Ship Fitness": "cruise",
    "Hiking & Trail Fitness": "hiking",
    "Skating Fitness": "skating",
    "Golf Fitness": "golf",
    "Swimming & Open Water": "swimming",
    "Cycling & Biking": "cycling",
}

# Split type inference
SPLIT_INFERENCE = {
    "full_body": ["full body", "total body", "functional", "circuit", "hiit", "bodyweight"],
    "upper_lower": ["upper lower", "upper/lower"],
    "push_pull_legs": ["ppl", "push pull legs", "push/pull/legs"],
    "push_pull": ["push pull", "push/pull"],
    "bro_split": ["bro split", "body part", "bodybuilding"],
    "custom": [],  # default
    "flow": ["yoga", "pilates", "stretch", "mobility", "dance"],
    "circuit": ["circuit", "metabolic", "conditioning", "amrap", "emom"],
    "sport_specific": ["sport", "athletic", "hyrox", "triathlon", "martial"],
    "single_session": ["1 session", "single session"],
}


def infer_split_type(name: str, category: str, description: str = "") -> str:
    """Infer split type from program name and category."""
    combined = f"{name} {category} {description}".lower()
    for split, keywords in SPLIT_INFERENCE.items():
        if any(kw in combined for kw in keywords):
            return split
    return "custom"


def infer_difficulty(name: str, category: str, description: str = "") -> str:
    """Infer difficulty level from program context."""
    combined = f"{name} {category} {description}".lower()
    if any(x in combined for x in ["beginner", "foundation", "starter", "intro", "kids", "senior", "couch"]):
        return "beginner"
    if any(x in combined for x in ["advanced", "elite", "hell", "extreme", "special forces", "competition"]):
        return "advanced"
    if any(x in combined for x in ["intermediate", "mastery", "progression"]):
        return "intermediate"
    return "all_levels"


def determine_phase(week_num: int, total_weeks: int, category: str = "") -> str:
    """Determine training phase based on week number and total duration."""
    if total_weeks <= 1:
        return "Single Session"
    progress = week_num / total_weeks
    if "hyrox" in category.lower():
        if progress <= 0.4:
            return "Blueprint (Aerobic Foundation)"
        elif progress <= 0.75:
            return "Build (Race-Specific)"
        elif progress <= 0.95:
            return "Race (Peak Performance)"
        else:
            return "Taper/Race Week"
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


def determine_goals(name: str, category: str, description: str = "") -> list:
    """Derive goals from program context."""
    combined = f"{name} {category} {description}".lower()
    goals = []
    if any(x in combined for x in ["strength", "powerlifting", "5x5", "5/3/1", "barbell", "squat", "deadlift", "bench"]):
        goals.extend(["Increase maximal strength", "Progressive overload"])
    if any(x in combined for x in ["hypertrophy", "muscle", "bodybuilding", "mass", "size", "bulk"]):
        goals.extend(["Maximize muscle hypertrophy", "Time under tension"])
    if any(x in combined for x in ["fat loss", "shred", "cut", "lean", "burn", "metabolic"]):
        goals.extend(["Maximize calorie burn", "Preserve lean muscle"])
    if any(x in combined for x in ["endurance", "cardio", "running", "marathon", "conditioning"]):
        goals.extend(["Build cardiovascular endurance", "Improve VO2 max"])
    if any(x in combined for x in ["flexibility", "stretch", "mobility", "yoga", "pilates"]):
        goals.extend(["Improve flexibility", "Enhance body awareness"])
    if any(x in combined for x in ["athletic", "sport", "performance", "agility", "speed"]):
        goals.extend(["Improve athletic performance", "Develop explosiveness"])
    if any(x in combined for x in ["home", "bodyweight", "calisthenics"]):
        goals.extend(["Build functional strength", "Improve body control"])
    if any(x in combined for x in ["recovery", "rehab", "deload"]):
        goals.extend(["Promote active recovery", "Reduce injury risk"])
    if not goals:
        goals = ["Improve overall fitness", "Build strength and endurance"]
    return goals[:5]


class ProgramSQLHelper:
    """Helper for generating and executing program SQL."""

    def __init__(self):
        self.conn = None
        self._connect()

    def _connect(self):
        """Connect to Supabase PostgreSQL."""
        host = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
        password = os.environ.get("DATABASE_PASSWORD") or os.environ.get("SUPABASE_DB_PASSWORD")
        if not password:
            raise SystemExit("DATABASE_PASSWORD environment variable is required")
        self.conn = psycopg2.connect(
            host=host, port=5432, dbname="postgres",
            user="postgres", password=password, sslmode="require"
        )

    def close(self):
        if self.conn:
            self.conn.close()

    def insert_full_program(
        self,
        program_name: str,
        category_name: str,
        description: str,
        durations: list[int],
        sessions_per_week: list[int],
        has_supersets: bool,
        priority: str,
        weeks_data: dict,  # {(duration, sessions): {week_num: {"focus": str, "workouts": list}}}
        migration_num: int = None,
        write_sql: bool = True,
    ) -> bool:
        """
        Insert a complete program with all variants and weeks.

        weeks_data format:
        {
            (4, 3): {  # 4 weeks, 3 sessions/week
                1: {
                    "focus": "Foundation - compound movements",
                    "workouts": [
                        {
                            "workout_name": "Day 1 - Full Body A",
                            "type": "strength",
                            "exercises": [
                                {
                                    "name": "Barbell Back Squat",
                                    "sets": 5, "reps": 5,
                                    "rest_seconds": 180,
                                    "weight_guidance": "70% 1RM",
                                    "equipment": "Barbell",
                                    "body_part": "Legs",
                                    "primary_muscle": "Quadriceps",
                                    "secondary_muscles": ["Glutes", "Hamstrings"],
                                    "difficulty": "intermediate",
                                    "form_cue": "Break at hips first",
                                    "substitution": "Goblet Squat"
                                }
                            ]
                        }
                    ]
                },
                2: {...},
            }
        }
        """
        db_category = CATEGORY_MAP.get(category_name, "general_fitness")
        split_type = infer_split_type(program_name, category_name, description)
        difficulty = infer_difficulty(program_name, category_name, description)
        goals = determine_goals(program_name, category_name, description)

        sql_lines = []
        sql_lines.append(f"-- Program: {program_name}")
        sql_lines.append(f"-- Category: {category_name} -> {db_category}")
        sql_lines.append(f"-- Priority: {priority}")
        sql_lines.append(f"-- Durations: {durations}, Sessions: {sessions_per_week}")
        sql_lines.append("")

        # Insert branded program
        max_duration = max(durations)
        max_sessions = max(sessions_per_week)
        requires_gym = not any(x in program_name.lower() for x in
                               ["home", "bodyweight", "no equipment", "hotel", "desk", "ninja"])

        sql_lines.append("-- Insert branded program")
        sql_lines.append(f"""INSERT INTO branded_programs (
    name, description, category, difficulty_level,
    duration_weeks, sessions_per_week, split_type,
    goals, requires_gym, is_active
) VALUES (
    '{self._esc(program_name)}',
    '{self._esc(description)}',
    '{db_category}',
    '{difficulty}',
    {max_duration},
    {max_sessions},
    '{split_type}',
    ARRAY[{', '.join(f"'{self._esc(g)}'" for g in goals)}]::text[],
    {str(requires_gym).lower()},
    true
) ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    difficulty_level = EXCLUDED.difficulty_level,
    duration_weeks = EXCLUDED.duration_weeks,
    sessions_per_week = EXCLUDED.sessions_per_week,
    split_type = EXCLUDED.split_type,
    goals = EXCLUDED.goals,
    requires_gym = EXCLUDED.requires_gym,
    updated_at = NOW();""")
        sql_lines.append("")

        # Insert variants and weeks
        for (duration, sessions), weeks in weeks_data.items():
            variant_name = f"{program_name} - {duration}w {sessions}x/wk"
            intensity = "Medium"
            if any(x in program_name.lower() for x in ["hell", "extreme", "elite", "advanced"]):
                intensity = "Hard"
            elif any(x in program_name.lower() for x in ["beginner", "foundation", "starter", "easy"]):
                intensity = "Easy"

            sql_lines.append(f"-- Variant: {variant_name}")
            sql_lines.append(f"""INSERT INTO program_variants (
    base_program_id,
    intensity_level,
    duration_weeks,
    variant_name,
    program_category,
    sessions_per_week,
    session_duration_minutes,
    goals,
    workouts
) SELECT
    bp.id,
    '{intensity}',
    {duration},
    '{self._esc(variant_name)}',
    '{db_category}',
    {sessions},
    60,
    ARRAY[{', '.join(f"'{self._esc(g)}'" for g in goals)}]::text[],
    '[]'::jsonb
FROM branded_programs bp
WHERE bp.name = '{self._esc(program_name)}'
ON CONFLICT DO NOTHING;""")
            sql_lines.append("")

            # Insert weeks
            for week_num, week_data in sorted(weeks.items()):
                focus = week_data.get("focus", f"Week {week_num}")
                phase = determine_phase(week_num, duration, category_name)
                workouts_json = json.dumps(week_data.get("workouts", []), ensure_ascii=False)
                # Escape single quotes in JSON
                workouts_json_escaped = workouts_json.replace("'", "''")

                sql_lines.append(f"""INSERT INTO program_variant_weeks (
    variant_id, week_number, phase, focus, workouts,
    program_name, variant_name, priority, has_supersets, description, category
) SELECT
    pv.id,
    {week_num},
    '{self._esc(phase)}',
    '{self._esc(focus)}',
    '{workouts_json_escaped}'::jsonb,
    '{self._esc(program_name)}',
    '{self._esc(variant_name)}',
    '{priority}',
    {str(has_supersets).lower()},
    '{self._esc(description)}',
    '{self._esc(category_name)}'
FROM program_variants pv
JOIN branded_programs bp ON bp.id = pv.base_program_id
WHERE bp.name = '{self._esc(program_name)}'
  AND pv.duration_weeks = {duration}
  AND pv.sessions_per_week = {sessions}
ON CONFLICT DO NOTHING;""")
                sql_lines.append("")

        full_sql = "\n".join(sql_lines)

        # Write SQL file
        if write_sql and migration_num:
            safe_name = program_name.lower().replace(" ", "_").replace("/", "_").replace("'", "")
            safe_name = ''.join(c for c in safe_name if c.isalnum() or c == '_')[:40]
            filename = f"{migration_num}_program_{safe_name}.sql"
            filepath = MIGRATIONS_DIR / filename
            with open(filepath, 'w') as f:
                f.write(full_sql)
            print(f"  SQL written: {filename}")

        # Execute against DB
        try:
            with self.conn.cursor() as cur:
                cur.execute(full_sql)
            self.conn.commit()
            print(f"  DB insert OK: {program_name}")
            return True
        except Exception as e:
            self.conn.rollback()
            print(f"  DB error for {program_name}: {e}")
            return False

    def _esc(self, s: str) -> str:
        """Escape single quotes for SQL."""
        if s is None:
            return ""
        return str(s).replace("'", "''")

    def check_program_exists(self, program_name: str) -> bool:
        """Check if a program already has complete data."""
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(DISTINCT pvw.week_number)
                FROM program_variant_weeks pvw
                WHERE pvw.program_name = %s
            """, (program_name,))
            count = cur.fetchone()[0]
        return count > 0

    def get_next_migration_num(self) -> int:
        """Get next available migration number."""
        existing = [f.name for f in MIGRATIONS_DIR.iterdir() if f.suffix == '.sql']
        nums = []
        for name in existing:
            parts = name.split('_')
            if parts[0].isdigit():
                nums.append(int(parts[0]))
        return max(nums) + 1 if nums else 343

    def update_tracker(self, program_name: str, status: str = "Done", sql_file: str = ""):
        """Update tracker file status for a program."""
        try:
            with open(TRACKER_PATH) as f:
                content = f.read()
            # Replace "| Pending |" with "| Done |" for this program
            old = f"| {program_name} |"
            if old in content:
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if old in line and "| Pending |" in line:
                        lines[i] = line.replace("| Pending |", f"| {status} |")
                        if sql_file:
                            lines[i] = lines[i].replace("| |", f"| {sql_file} |", 1)
                        break
                with open(TRACKER_PATH, 'w') as f:
                    f.write('\n'.join(lines))
        except Exception:
            pass  # Non-critical
