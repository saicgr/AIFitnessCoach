"""
Performance logging API endpoints with DuckDB.

ENDPOINTS:
- POST /api/v1/performance-db/logs - Create performance log
- GET  /api/v1/performance-db/logs - List performance logs
- POST /api/v1/performance-db/workout-logs - Create workout log
- GET  /api/v1/performance-db/workout-logs - List workout logs
- GET  /api/v1/performance-db/strength-records - Get strength records
- GET  /api/v1/performance-db/weekly-volume - Get weekly volume
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime

from core.duckdb_database import get_db
from models.schemas import (
    PerformanceLog, PerformanceLogCreate,
    WorkoutLog, WorkoutLogCreate,
    StrengthRecord, StrengthRecordCreate,
    WeeklyVolume, WeeklyVolumeCreate,
)

router = APIRouter()


# ============ Performance Logs ============

@router.post("/logs", response_model=PerformanceLog)
async def create_performance_log(log: PerformanceLogCreate):
    """Create a performance log entry."""
    try:
        db = get_db()

        result = db.conn.execute("SELECT nextval('performance_logs_id_seq')").fetchone()
        log_id = result[0]

        db.conn.execute("""
            INSERT INTO performance_logs (
                id, workout_log_id, user_id, exercise_id, exercise_name,
                set_number, reps_completed, weight_kg, rpe, rir, tempo,
                is_completed, failed_at_rep, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            log_id, log.workout_log_id, log.user_id, log.exercise_id,
            log.exercise_name, log.set_number, log.reps_completed, log.weight_kg,
            log.rpe, log.rir, log.tempo, log.is_completed, log.failed_at_rep, log.notes,
        ])

        row = db.conn.execute("""
            SELECT id, workout_log_id, user_id, exercise_id, exercise_name,
                   set_number, reps_completed, weight_kg, rpe, rir, tempo,
                   is_completed, failed_at_rep, notes, recorded_at
            FROM performance_logs WHERE id = ?
        """, [log_id]).fetchone()

        return PerformanceLog(
            id=row[0], workout_log_id=row[1], user_id=row[2], exercise_id=row[3],
            exercise_name=row[4], set_number=row[5], reps_completed=row[6],
            weight_kg=row[7], rpe=row[8], rir=row[9], tempo=row[10],
            is_completed=row[11], failed_at_rep=row[12], notes=row[13], recorded_at=row[14],
        )

    except Exception as e:
        print(f"❌ Error creating performance log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs", response_model=List[PerformanceLog])
async def list_performance_logs(
    user_id: int,
    exercise_id: Optional[str] = None,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List performance logs for a user."""
    try:
        db = get_db()

        query = """
            SELECT id, workout_log_id, user_id, exercise_id, exercise_name,
                   set_number, reps_completed, weight_kg, rpe, rir, tempo,
                   is_completed, failed_at_rep, notes, recorded_at
            FROM performance_logs WHERE user_id = ?
        """
        params = [user_id]

        if exercise_id:
            query += " AND exercise_id = ?"
            params.append(exercise_id)

        query += " ORDER BY recorded_at DESC LIMIT ?"
        params.append(limit)

        rows = db.conn.execute(query, params).fetchall()

        return [PerformanceLog(
            id=row[0], workout_log_id=row[1], user_id=row[2], exercise_id=row[3],
            exercise_name=row[4], set_number=row[5], reps_completed=row[6],
            weight_kg=row[7], rpe=row[8], rir=row[9], tempo=row[10],
            is_completed=row[11], failed_at_rep=row[12], notes=row[13], recorded_at=row[14],
        ) for row in rows]

    except Exception as e:
        print(f"❌ Error listing performance logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Workout Logs ============

@router.post("/workout-logs", response_model=WorkoutLog)
async def create_workout_log(log: WorkoutLogCreate):
    """Create a workout log entry."""
    try:
        db = get_db()

        result = db.conn.execute("SELECT nextval('workout_logs_id_seq')").fetchone()
        log_id = result[0]

        db.conn.execute("""
            INSERT INTO workout_logs (id, workout_id, user_id, sets_json, total_time_seconds)
            VALUES (?, ?, ?, ?, ?)
        """, [log_id, log.workout_id, log.user_id, log.sets_json, log.total_time_seconds])

        row = db.conn.execute("""
            SELECT id, workout_id, user_id, sets_json, completed_at, total_time_seconds
            FROM workout_logs WHERE id = ?
        """, [log_id]).fetchone()

        return WorkoutLog(
            id=row[0], workout_id=row[1], user_id=row[2], sets_json=row[3],
            completed_at=row[4], total_time_seconds=row[5],
        )

    except Exception as e:
        print(f"❌ Error creating workout log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/workout-logs", response_model=List[WorkoutLog])
async def list_workout_logs(
    user_id: int,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List workout logs for a user."""
    try:
        db = get_db()

        rows = db.conn.execute("""
            SELECT id, workout_id, user_id, sets_json, completed_at, total_time_seconds
            FROM workout_logs WHERE user_id = ?
            ORDER BY completed_at DESC LIMIT ?
        """, [user_id, limit]).fetchall()

        return [WorkoutLog(
            id=row[0], workout_id=row[1], user_id=row[2], sets_json=row[3],
            completed_at=row[4], total_time_seconds=row[5],
        ) for row in rows]

    except Exception as e:
        print(f"❌ Error listing workout logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Strength Records ============

@router.post("/strength-records", response_model=StrengthRecord)
async def create_strength_record(record: StrengthRecordCreate):
    """Create a strength record entry."""
    try:
        db = get_db()

        result = db.conn.execute("SELECT nextval('strength_records_id_seq')").fetchone()
        record_id = result[0]

        db.conn.execute("""
            INSERT INTO strength_records (
                id, user_id, exercise_id, exercise_name, weight_kg,
                reps, estimated_1rm, rpe, is_pr
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            record_id, record.user_id, record.exercise_id, record.exercise_name,
            record.weight_kg, record.reps, record.estimated_1rm, record.rpe, record.is_pr,
        ])

        row = db.conn.execute("""
            SELECT id, user_id, exercise_id, exercise_name, weight_kg,
                   reps, estimated_1rm, rpe, is_pr, achieved_at
            FROM strength_records WHERE id = ?
        """, [record_id]).fetchone()

        return StrengthRecord(
            id=row[0], user_id=row[1], exercise_id=row[2], exercise_name=row[3],
            weight_kg=row[4], reps=row[5], estimated_1rm=row[6], rpe=row[7],
            is_pr=row[8], achieved_at=row[9],
        )

    except Exception as e:
        print(f"❌ Error creating strength record: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/strength-records", response_model=List[StrengthRecord])
async def list_strength_records(
    user_id: int,
    exercise_id: Optional[str] = None,
    prs_only: bool = False,
    limit: int = Query(default=50, ge=1, le=200),
):
    """List strength records for a user."""
    try:
        db = get_db()

        query = """
            SELECT id, user_id, exercise_id, exercise_name, weight_kg,
                   reps, estimated_1rm, rpe, is_pr, achieved_at
            FROM strength_records WHERE user_id = ?
        """
        params = [user_id]

        if exercise_id:
            query += " AND exercise_id = ?"
            params.append(exercise_id)

        if prs_only:
            query += " AND is_pr = TRUE"

        query += " ORDER BY achieved_at DESC LIMIT ?"
        params.append(limit)

        rows = db.conn.execute(query, params).fetchall()

        return [StrengthRecord(
            id=row[0], user_id=row[1], exercise_id=row[2], exercise_name=row[3],
            weight_kg=row[4], reps=row[5], estimated_1rm=row[6], rpe=row[7],
            is_pr=row[8], achieved_at=row[9],
        ) for row in rows]

    except Exception as e:
        print(f"❌ Error listing strength records: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============ Weekly Volume ============

@router.post("/weekly-volume", response_model=WeeklyVolume)
async def upsert_weekly_volume(volume: WeeklyVolumeCreate):
    """Create or update weekly volume entry."""
    try:
        db = get_db()

        # Check if exists
        existing = db.conn.execute("""
            SELECT id FROM weekly_volumes
            WHERE user_id = ? AND muscle_group = ? AND week_number = ? AND year = ?
        """, [volume.user_id, volume.muscle_group, volume.week_number, volume.year]).fetchone()

        if existing:
            db.conn.execute("""
                UPDATE weekly_volumes SET
                    total_sets = ?, total_reps = ?, total_volume_kg = ?,
                    frequency = ?, target_sets = ?, recovery_status = ?,
                    updated_at = ?
                WHERE id = ?
            """, [
                volume.total_sets, volume.total_reps, volume.total_volume_kg,
                volume.frequency, volume.target_sets, volume.recovery_status,
                datetime.now(), existing[0],
            ])
            volume_id = existing[0]
        else:
            result = db.conn.execute("SELECT nextval('weekly_volumes_id_seq')").fetchone()
            volume_id = result[0]

            db.conn.execute("""
                INSERT INTO weekly_volumes (
                    id, user_id, muscle_group, week_number, year,
                    total_sets, total_reps, total_volume_kg, frequency,
                    target_sets, recovery_status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [
                volume_id, volume.user_id, volume.muscle_group, volume.week_number,
                volume.year, volume.total_sets, volume.total_reps, volume.total_volume_kg,
                volume.frequency, volume.target_sets, volume.recovery_status,
            ])

        row = db.conn.execute("""
            SELECT id, user_id, muscle_group, week_number, year,
                   total_sets, total_reps, total_volume_kg, frequency,
                   target_sets, recovery_status, updated_at
            FROM weekly_volumes WHERE id = ?
        """, [volume_id]).fetchone()

        return WeeklyVolume(
            id=row[0], user_id=row[1], muscle_group=row[2], week_number=row[3],
            year=row[4], total_sets=row[5], total_reps=row[6], total_volume_kg=row[7],
            frequency=row[8], target_sets=row[9], recovery_status=row[10], updated_at=row[11],
        )

    except Exception as e:
        print(f"❌ Error upserting weekly volume: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/weekly-volume", response_model=List[WeeklyVolume])
async def list_weekly_volumes(
    user_id: int,
    week_number: Optional[int] = None,
    year: Optional[int] = None,
):
    """List weekly volumes for a user."""
    try:
        db = get_db()

        query = """
            SELECT id, user_id, muscle_group, week_number, year,
                   total_sets, total_reps, total_volume_kg, frequency,
                   target_sets, recovery_status, updated_at
            FROM weekly_volumes WHERE user_id = ?
        """
        params = [user_id]

        if week_number:
            query += " AND week_number = ?"
            params.append(week_number)
        if year:
            query += " AND year = ?"
            params.append(year)

        query += " ORDER BY year DESC, week_number DESC, muscle_group"

        rows = db.conn.execute(query, params).fetchall()

        return [WeeklyVolume(
            id=row[0], user_id=row[1], muscle_group=row[2], week_number=row[3],
            year=row[4], total_sets=row[5], total_reps=row[6], total_volume_kg=row[7],
            frequency=row[8], target_sets=row[9], recovery_status=row[10], updated_at=row[11],
        ) for row in rows]

    except Exception as e:
        print(f"❌ Error listing weekly volumes: {e}")
        raise HTTPException(status_code=500, detail=str(e))
