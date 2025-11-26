"""DuckDB database manager for AI Fitness Coach."""

import duckdb
from pathlib import Path
from typing import Optional
import json

# Database file path
DB_PATH = Path(__file__).parent.parent / "data" / "fitness_coach.duckdb"


class DuckDBManager:
    """Singleton manager for DuckDB connections."""

    _instance: Optional["DuckDBManager"] = None
    _conn: Optional[duckdb.DuckDBPyConnection] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if self._conn is None:
            DB_PATH.parent.mkdir(parents=True, exist_ok=True)
            self._conn = duckdb.connect(str(DB_PATH))
            self._init_tables()

    @property
    def conn(self) -> duckdb.DuckDBPyConnection:
        return self._conn

    def _init_tables(self):
        """Initialize all database tables."""
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY,
                username VARCHAR UNIQUE,
                password_hash VARCHAR,
                name VARCHAR,
                onboarding_completed BOOLEAN DEFAULT FALSE,
                fitness_level VARCHAR NOT NULL,
                goals VARCHAR NOT NULL,
                equipment VARCHAR NOT NULL,
                preferences VARCHAR DEFAULT '{}',
                active_injuries VARCHAR DEFAULT '[]',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                -- Extended body measurements (Feature A)
                height_cm DOUBLE,
                weight_kg DOUBLE,
                target_weight_kg DOUBLE,
                age INTEGER,
                gender VARCHAR DEFAULT 'prefer_not_to_say',
                activity_level VARCHAR DEFAULT 'lightly_active',
                waist_circumference_cm DOUBLE,
                hip_circumference_cm DOUBLE,
                neck_circumference_cm DOUBLE,
                body_fat_percent DOUBLE,
                resting_heart_rate INTEGER,
                blood_pressure_systolic INTEGER,
                blood_pressure_diastolic INTEGER
            )
        """)

        # Migration: Add auth columns to existing users table if they don't exist
        self._migrate_users_table()

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS exercises (
                id INTEGER PRIMARY KEY,
                external_id VARCHAR UNIQUE NOT NULL,
                name VARCHAR NOT NULL,
                category VARCHAR DEFAULT 'strength',
                subcategory VARCHAR DEFAULT 'compound',
                difficulty_level INTEGER DEFAULT 1,
                primary_muscle VARCHAR NOT NULL,
                secondary_muscles VARCHAR DEFAULT '[]',
                equipment_required VARCHAR DEFAULT '[]',
                body_part VARCHAR NOT NULL,
                equipment VARCHAR NOT NULL,
                target VARCHAR NOT NULL,
                default_sets INTEGER DEFAULT 3,
                default_reps INTEGER,
                default_duration_seconds INTEGER,
                default_rest_seconds INTEGER DEFAULT 60,
                min_weight_kg DOUBLE,
                calories_per_minute DOUBLE DEFAULT 5.0,
                instructions VARCHAR NOT NULL,
                tips VARCHAR DEFAULT '[]',
                contraindicated_injuries VARCHAR DEFAULT '[]',
                gif_url VARCHAR,
                video_url VARCHAR,
                is_compound BOOLEAN DEFAULT TRUE,
                is_unilateral BOOLEAN DEFAULT FALSE,
                tags VARCHAR DEFAULT '[]',
                is_custom BOOLEAN DEFAULT FALSE,
                created_by_user_id INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS workouts (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                name VARCHAR NOT NULL,
                type VARCHAR NOT NULL,
                difficulty VARCHAR NOT NULL,
                scheduled_date TIMESTAMP NOT NULL,
                is_completed BOOLEAN DEFAULT FALSE,
                exercises_json VARCHAR NOT NULL,
                duration_minutes INTEGER DEFAULT 45,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                generation_method VARCHAR DEFAULT 'algorithm',
                generation_source VARCHAR DEFAULT 'onboarding',
                generation_metadata VARCHAR DEFAULT '{}',
                generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_modified_method VARCHAR,
                last_modified_at TIMESTAMP,
                modification_history VARCHAR DEFAULT '[]',
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        # Migration: Add duration_minutes column to existing workouts table
        self._migrate_workouts_table()

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS workout_logs (
                id INTEGER PRIMARY KEY,
                workout_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                sets_json VARCHAR NOT NULL,
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                total_time_seconds INTEGER NOT NULL,
                FOREIGN KEY (workout_id) REFERENCES workouts(id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS performance_logs (
                id INTEGER PRIMARY KEY,
                workout_log_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                exercise_id VARCHAR NOT NULL,
                exercise_name VARCHAR NOT NULL,
                set_number INTEGER NOT NULL,
                reps_completed INTEGER NOT NULL,
                weight_kg DOUBLE NOT NULL,
                rpe DOUBLE,
                rir INTEGER,
                tempo VARCHAR,
                is_completed BOOLEAN DEFAULT TRUE,
                failed_at_rep INTEGER,
                notes VARCHAR,
                recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (workout_log_id) REFERENCES workout_logs(id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS strength_records (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                exercise_id VARCHAR NOT NULL,
                exercise_name VARCHAR NOT NULL,
                weight_kg DOUBLE NOT NULL,
                reps INTEGER NOT NULL,
                estimated_1rm DOUBLE NOT NULL,
                rpe DOUBLE,
                is_pr BOOLEAN DEFAULT FALSE,
                achieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS weekly_volumes (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                muscle_group VARCHAR NOT NULL,
                week_number INTEGER NOT NULL,
                year INTEGER NOT NULL,
                total_sets INTEGER NOT NULL,
                total_reps INTEGER NOT NULL,
                total_volume_kg DOUBLE NOT NULL,
                frequency INTEGER NOT NULL,
                target_sets INTEGER NOT NULL,
                recovery_status VARCHAR DEFAULT 'recovered',
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                UNIQUE (user_id, muscle_group, week_number, year)
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS chat_history (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                user_message VARCHAR NOT NULL,
                ai_response VARCHAR NOT NULL,
                context_json VARCHAR,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS injuries (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                body_part VARCHAR NOT NULL,
                severity VARCHAR NOT NULL,
                onset_date TIMESTAMP NOT NULL,
                affected_exercises VARCHAR NOT NULL,
                is_active BOOLEAN DEFAULT TRUE,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        # User metrics history table (Feature B - Auto-calculated metrics)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS user_metrics (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                -- Input measurements
                weight_kg DOUBLE,
                waist_cm DOUBLE,
                hip_cm DOUBLE,
                neck_cm DOUBLE,
                body_fat_measured DOUBLE,
                resting_heart_rate INTEGER,
                blood_pressure_systolic INTEGER,
                blood_pressure_diastolic INTEGER,
                -- Calculated metrics
                bmi DOUBLE,
                bmi_category VARCHAR,
                bmr DOUBLE,
                tdee DOUBLE,
                body_fat_calculated DOUBLE,
                lean_body_mass DOUBLE,
                ffmi DOUBLE,
                waist_to_height_ratio DOUBLE,
                waist_to_hip_ratio DOUBLE,
                ideal_body_weight DOUBLE,
                -- Tracking
                notes VARCHAR,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        # Enhanced injury history table (Feature C - Smart Injury Handling)
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS injury_history (
                id INTEGER PRIMARY KEY,
                user_id INTEGER NOT NULL,
                body_part VARCHAR NOT NULL,
                severity VARCHAR DEFAULT 'moderate',
                reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expected_recovery_date TIMESTAMP,
                actual_recovery_date TIMESTAMP,
                duration_planned_weeks INTEGER DEFAULT 3,
                duration_actual_days INTEGER,
                -- Workout modifications tracking
                workouts_modified_count INTEGER DEFAULT 0,
                exercises_removed VARCHAR DEFAULT '[]',
                rehab_exercises_added VARCHAR DEFAULT '[]',
                -- Progress tracking
                pain_level_initial INTEGER,
                pain_level_current INTEGER,
                improvement_notes VARCHAR,
                -- Analysis fields
                ai_recommendations_followed BOOLEAN,
                user_feedback VARCHAR,
                recovery_phase VARCHAR DEFAULT 'acute',
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        # Workout changes audit log for tracking all modifications
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS workout_changes (
                id INTEGER PRIMARY KEY,
                workout_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                change_type VARCHAR NOT NULL,
                field_changed VARCHAR,
                old_value VARCHAR,
                new_value VARCHAR,
                change_source VARCHAR DEFAULT 'api',
                change_reason VARCHAR,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (workout_id) REFERENCES workouts(id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)

        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS users_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS exercises_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS workouts_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS workout_logs_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS performance_logs_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS strength_records_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS weekly_volumes_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS chat_history_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS injuries_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS workout_changes_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS user_metrics_id_seq START 1
        """)
        self._conn.execute("""
            CREATE SEQUENCE IF NOT EXISTS injury_history_id_seq START 1
        """)

    def _migrate_users_table(self):
        """Add authentication columns to users table if they don't exist."""
        # Check if username column exists
        try:
            result = self._conn.execute("""
                SELECT column_name FROM information_schema.columns
                WHERE table_name = 'users' AND column_name = 'username'
            """).fetchone()

            if result is None:
                # Add the new auth columns
                print("Migrating users table: adding auth columns...")
                self._conn.execute("ALTER TABLE users ADD COLUMN username VARCHAR")
                self._conn.execute("ALTER TABLE users ADD COLUMN password_hash VARCHAR")
                self._conn.execute("ALTER TABLE users ADD COLUMN name VARCHAR")
                self._conn.execute("ALTER TABLE users ADD COLUMN onboarding_completed BOOLEAN DEFAULT TRUE")

                # Update existing users to have onboarding_completed = true
                self._conn.execute("UPDATE users SET onboarding_completed = TRUE WHERE onboarding_completed IS NULL")
                print("Migration complete: auth columns added to users table")
        except Exception as e:
            # Table might not exist yet, which is fine
            print(f"Migration check skipped: {e}")

    def _migrate_workouts_table(self):
        """Add duration_minutes column to workouts table if it doesn't exist."""
        try:
            result = self._conn.execute("""
                SELECT column_name FROM information_schema.columns
                WHERE table_name = 'workouts' AND column_name = 'duration_minutes'
            """).fetchone()

            if result is None:
                print("Migrating workouts table: adding duration_minutes column...")
                self._conn.execute("ALTER TABLE workouts ADD COLUMN duration_minutes INTEGER DEFAULT 45")
                print("Migration complete: duration_minutes column added to workouts table")
        except Exception as e:
            print(f"Workouts migration check skipped: {e}")

    def close(self):
        """Close the database connection."""
        if self._conn:
            self._conn.close()
            self._conn = None


# Global database instance
db = DuckDBManager()


def get_db() -> DuckDBManager:
    """Get the database manager instance."""
    return db
