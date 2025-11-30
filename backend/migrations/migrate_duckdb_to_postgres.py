"""
Migration script to transfer data from DuckDB to Supabase Postgres.

Usage:
    python migrations/migrate_duckdb_to_postgres.py
"""
import asyncio
import duckdb
import json
from pathlib import Path
from sqlalchemy import text
from core.config import get_settings
from core.supabase_client import get_supabase
from core.duckdb_database import DuckDBManager

# UUID mapping to convert integer IDs to UUIDs
uuid_mappings = {
    'users': {},
    'exercises': {},
    'workouts': {},
    'workout_logs': {},
}


async def migrate_users(duck_conn, pg_session):
    """Migrate users table."""
    print("Migrating users...")

    # Get all users from DuckDB
    users = duck_conn.execute("SELECT * FROM users").fetchall()
    columns = [desc[0] for desc in duck_conn.description]

    migrated = 0
    for user_row in users:
        user_dict = dict(zip(columns, user_row))
        old_id = user_dict['id']

        # Parse JSON fields
        preferences = json.loads(user_dict.get('preferences', '{}'))
        active_injuries = json.loads(user_dict.get('active_injuries', '[]'))

        # Insert into Postgres
        query = text("""
            INSERT INTO users (
                username, name, onboarding_completed, fitness_level, goals, equipment,
                preferences, active_injuries, created_at, height_cm, weight_kg,
                target_weight_kg, age, gender, activity_level, waist_circumference_cm,
                hip_circumference_cm, neck_circumference_cm, body_fat_percent,
                resting_heart_rate, blood_pressure_systolic, blood_pressure_diastolic
            ) VALUES (
                :username, :name, :onboarding_completed, :fitness_level, :goals, :equipment,
                :preferences, :active_injuries, :created_at, :height_cm, :weight_kg,
                :target_weight_kg, :age, :gender, :activity_level, :waist_circumference_cm,
                :hip_circumference_cm, :neck_circumference_cm, :body_fat_percent,
                :resting_heart_rate, :blood_pressure_systolic, :blood_pressure_diastolic
            )
            RETURNING id
        """)

        result = await pg_session.execute(query, {
            'username': user_dict.get('username'),
            'name': user_dict.get('name'),
            'onboarding_completed': user_dict.get('onboarding_completed', False),
            'fitness_level': user_dict.get('fitness_level'),
            'goals': user_dict.get('goals'),
            'equipment': user_dict.get('equipment'),
            'preferences': json.dumps(preferences),
            'active_injuries': json.dumps(active_injuries),
            'created_at': user_dict.get('created_at'),
            'height_cm': user_dict.get('height_cm'),
            'weight_kg': user_dict.get('weight_kg'),
            'target_weight_kg': user_dict.get('target_weight_kg'),
            'age': user_dict.get('age'),
            'gender': user_dict.get('gender'),
            'activity_level': user_dict.get('activity_level'),
            'waist_circumference_cm': user_dict.get('waist_circumference_cm'),
            'hip_circumference_cm': user_dict.get('hip_circumference_cm'),
            'neck_circumference_cm': user_dict.get('neck_circumference_cm'),
            'body_fat_percent': user_dict.get('body_fat_percent'),
            'resting_heart_rate': user_dict.get('resting_heart_rate'),
            'blood_pressure_systolic': user_dict.get('blood_pressure_systolic'),
            'blood_pressure_diastolic': user_dict.get('blood_pressure_diastolic'),
        })

        new_id = (await result.fetchone())[0]
        uuid_mappings['users'][old_id] = new_id
        migrated += 1

    await pg_session.commit()
    print(f"✅ Migrated {migrated} users")


async def migrate_exercises(duck_conn, pg_session):
    """Migrate exercises table."""
    print("Migrating exercises...")

    exercises = duck_conn.execute("SELECT * FROM exercises").fetchall()
    columns = [desc[0] for desc in duck_conn.description]

    migrated = 0
    for ex_row in exercises:
        ex_dict = dict(zip(columns, ex_row))
        old_id = ex_dict['id']

        # Parse JSON fields
        secondary_muscles = json.loads(ex_dict.get('secondary_muscles', '[]'))
        equipment_required = json.loads(ex_dict.get('equipment_required', '[]'))
        tips = json.loads(ex_dict.get('tips', '[]'))
        contraindicated_injuries = json.loads(ex_dict.get('contraindicated_injuries', '[]'))
        tags = json.loads(ex_dict.get('tags', '[]'))

        # Map created_by_user_id if it exists
        created_by_user_id = None
        if ex_dict.get('created_by_user_id'):
            created_by_user_id = uuid_mappings['users'].get(ex_dict['created_by_user_id'])

        query = text("""
            INSERT INTO exercises (
                external_id, name, category, subcategory, difficulty_level,
                primary_muscle, secondary_muscles, equipment_required, body_part,
                equipment, target, default_sets, default_reps, default_duration_seconds,
                default_rest_seconds, min_weight_kg, calories_per_minute, instructions,
                tips, contraindicated_injuries, gif_url, video_url, is_compound,
                is_unilateral, tags, is_custom, created_by_user_id, created_at
            ) VALUES (
                :external_id, :name, :category, :subcategory, :difficulty_level,
                :primary_muscle, :secondary_muscles, :equipment_required, :body_part,
                :equipment, :target, :default_sets, :default_reps, :default_duration_seconds,
                :default_rest_seconds, :min_weight_kg, :calories_per_minute, :instructions,
                :tips, :contraindicated_injuries, :gif_url, :video_url, :is_compound,
                :is_unilateral, :tags, :is_custom, :created_by_user_id, :created_at
            )
            RETURNING id
        """)

        result = await pg_session.execute(query, {
            'external_id': ex_dict.get('external_id'),
            'name': ex_dict.get('name'),
            'category': ex_dict.get('category', 'strength'),
            'subcategory': ex_dict.get('subcategory', 'compound'),
            'difficulty_level': ex_dict.get('difficulty_level', 1),
            'primary_muscle': ex_dict.get('primary_muscle'),
            'secondary_muscles': json.dumps(secondary_muscles),
            'equipment_required': json.dumps(equipment_required),
            'body_part': ex_dict.get('body_part'),
            'equipment': ex_dict.get('equipment'),
            'target': ex_dict.get('target'),
            'default_sets': ex_dict.get('default_sets', 3),
            'default_reps': ex_dict.get('default_reps'),
            'default_duration_seconds': ex_dict.get('default_duration_seconds'),
            'default_rest_seconds': ex_dict.get('default_rest_seconds', 60),
            'min_weight_kg': ex_dict.get('min_weight_kg'),
            'calories_per_minute': ex_dict.get('calories_per_minute', 5.0),
            'instructions': ex_dict.get('instructions'),
            'tips': json.dumps(tips),
            'contraindicated_injuries': json.dumps(contraindicated_injuries),
            'gif_url': ex_dict.get('gif_url'),
            'video_url': ex_dict.get('video_url'),
            'is_compound': ex_dict.get('is_compound', True),
            'is_unilateral': ex_dict.get('is_unilateral', False),
            'tags': json.dumps(tags),
            'is_custom': ex_dict.get('is_custom', False),
            'created_by_user_id': created_by_user_id,
            'created_at': ex_dict.get('created_at'),
        })

        new_id = (await result.fetchone())[0]
        uuid_mappings['exercises'][old_id] = new_id
        migrated += 1

    await pg_session.commit()
    print(f"✅ Migrated {migrated} exercises")


async def migrate_workouts(duck_conn, pg_session):
    """Migrate workouts table."""
    print("Migrating workouts...")

    workouts = duck_conn.execute("SELECT * FROM workouts").fetchall()
    columns = [desc[0] for desc in duck_conn.description]

    migrated = 0
    for workout_row in workouts:
        workout_dict = dict(zip(columns, workout_row))
        old_id = workout_dict['id']

        # Map user_id
        user_id = uuid_mappings['users'].get(workout_dict['user_id'])
        if not user_id:
            print(f"⚠️  Skipping workout {old_id}: user not found")
            continue

        # Parse JSON fields
        exercises_json = json.loads(workout_dict.get('exercises_json', '[]'))
        generation_metadata = json.loads(workout_dict.get('generation_metadata', '{}'))
        modification_history = json.loads(workout_dict.get('modification_history', '[]'))

        query = text("""
            INSERT INTO workouts (
                user_id, name, type, difficulty, scheduled_date, is_completed,
                exercises_json, duration_minutes, created_at, generation_method,
                generation_source, generation_metadata, generated_at,
                last_modified_method, last_modified_at, modification_history
            ) VALUES (
                :user_id, :name, :type, :difficulty, :scheduled_date, :is_completed,
                :exercises_json, :duration_minutes, :created_at, :generation_method,
                :generation_source, :generation_metadata, :generated_at,
                :last_modified_method, :last_modified_at, :modification_history
            )
            RETURNING id
        """)

        result = await pg_session.execute(query, {
            'user_id': user_id,
            'name': workout_dict.get('name'),
            'type': workout_dict.get('type'),
            'difficulty': workout_dict.get('difficulty'),
            'scheduled_date': workout_dict.get('scheduled_date'),
            'is_completed': workout_dict.get('is_completed', False),
            'exercises_json': json.dumps(exercises_json),
            'duration_minutes': workout_dict.get('duration_minutes', 45),
            'created_at': workout_dict.get('created_at'),
            'generation_method': workout_dict.get('generation_method', 'algorithm'),
            'generation_source': workout_dict.get('generation_source', 'onboarding'),
            'generation_metadata': json.dumps(generation_metadata),
            'generated_at': workout_dict.get('generated_at'),
            'last_modified_method': workout_dict.get('last_modified_method'),
            'last_modified_at': workout_dict.get('last_modified_at'),
            'modification_history': json.dumps(modification_history),
        })

        new_id = (await result.fetchone())[0]
        uuid_mappings['workouts'][old_id] = new_id
        migrated += 1

    await pg_session.commit()
    print(f"✅ Migrated {migrated} workouts")


async def migrate_all_tables(duck_conn, pg_session):
    """Migrate all tables in order (respecting foreign keys)."""
    await migrate_users(duck_conn, pg_session)
    await migrate_exercises(duck_conn, pg_session)
    await migrate_workouts(duck_conn, pg_session)

    # Add more table migrations here as needed:
    # await migrate_workout_logs(duck_conn, pg_session)
    # await migrate_performance_logs(duck_conn, pg_session)
    # await migrate_strength_records(duck_conn, pg_session)
    # await migrate_chat_history(duck_conn, pg_session)
    # etc...

    print("\n✅ Migration completed successfully!")
    print(f"Migrated {len(uuid_mappings['users'])} users")
    print(f"Migrated {len(uuid_mappings['exercises'])} exercises")
    print(f"Migrated {len(uuid_mappings['workouts'])} workouts")


async def main():
    """Main migration function."""
    settings = get_settings()

    # Check if DuckDB file exists
    duckdb_path = Path(settings.duckdb_path or "./data/fitness_coach.duckdb")
    if not duckdb_path.exists():
        print(f"❌ DuckDB file not found: {duckdb_path}")
        print("No data to migrate. Exiting.")
        return

    print(f"📂 Reading from DuckDB: {duckdb_path}")
    print(f"📤 Migrating to Postgres: {settings.database_url}")
    print()

    # Connect to DuckDB
    duck_conn = duckdb.connect(str(duckdb_path))

    # Get Postgres session
    supabase_manager = get_supabase()
    pg_session = supabase_manager.get_session()

    try:
        await migrate_all_tables(duck_conn, pg_session)
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        await pg_session.rollback()
        raise
    finally:
        duck_conn.close()
        await pg_session.close()


if __name__ == "__main__":
    asyncio.run(main())
