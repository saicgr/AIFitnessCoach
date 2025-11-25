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
                fitness_level VARCHAR NOT NULL,
                goals VARCHAR NOT NULL,
                equipment VARCHAR NOT NULL,
                preferences VARCHAR DEFAULT '{}',
                active_injuries VARCHAR DEFAULT '[]',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

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
