"""
User API endpoints with DuckDB.

ENDPOINTS:
- POST /api/v1/users/ - Create a new user
- POST /api/v1/users/signup - Register with username/password
- POST /api/v1/users/login - Login with username/password
- GET  /api/v1/users/{id} - Get user by ID
- PUT  /api/v1/users/{id} - Update user
- DELETE /api/v1/users/{id} - Delete user
- DELETE /api/v1/users/{id}/reset - Full reset (delete all user data)
"""
import json
import hashlib
import secrets
from fastapi import APIRouter, HTTPException
from typing import Optional
from pydantic import BaseModel

from core.duckdb_database import get_db
from core.logger import get_logger
from models.schemas import User, UserCreate, UserUpdate


class SignupRequest(BaseModel):
    """Request body for user signup."""
    username: str
    password: str
    name: Optional[str] = None


class LoginRequest(BaseModel):
    """Request body for user login."""
    username: str
    password: str


def hash_password(password: str) -> str:
    """Hash a password using SHA-256 with salt."""
    salt = secrets.token_hex(16)
    hash_obj = hashlib.sha256((salt + password).encode())
    return f"{salt}:{hash_obj.hexdigest()}"


def verify_password(password: str, password_hash: str) -> bool:
    """Verify a password against its hash."""
    try:
        salt, stored_hash = password_hash.split(":")
        hash_obj = hashlib.sha256((salt + password).encode())
        return hash_obj.hexdigest() == stored_hash
    except (ValueError, AttributeError):
        return False

router = APIRouter()
logger = get_logger(__name__)


@router.post("/signup", response_model=User)
async def signup(request: SignupRequest):
    """
    Register a new user with username and password.
    Creates user with onboarding_completed=False.
    """
    logger.info(f"Signup attempt for username: {request.username}")

    if len(request.username) < 3:
        raise HTTPException(status_code=400, detail="Username must be at least 3 characters")
    if len(request.password) < 4:
        raise HTTPException(status_code=400, detail="Password must be at least 4 characters")

    try:
        db = get_db()

        # Check if username already exists
        existing = db.conn.execute(
            "SELECT id FROM users WHERE username = ?",
            [request.username.lower()]
        ).fetchone()

        if existing:
            logger.warning(f"Username already exists: {request.username}")
            raise HTTPException(status_code=400, detail="Username already taken")

        # Get next ID
        result = db.conn.execute("SELECT nextval('users_id_seq')").fetchone()
        user_id = result[0]

        # Hash password
        password_hash = hash_password(request.password)

        # Create user with minimal data (will complete in onboarding)
        default_goals = json.dumps([])
        default_equipment = json.dumps([])
        default_preferences = json.dumps({"name": request.name or request.username})
        default_injuries = json.dumps([])

        db.conn.execute("""
            INSERT INTO users (id, username, password_hash, name, onboarding_completed,
                             fitness_level, goals, equipment, preferences, active_injuries)
            VALUES (?, ?, ?, ?, FALSE, 'beginner', ?, ?, ?, ?)
        """, [user_id, request.username.lower(), password_hash, request.name or request.username,
              default_goals, default_equipment, default_preferences, default_injuries])

        # Fetch created user
        row = db.conn.execute("""
            SELECT id, username, name, onboarding_completed, fitness_level, goals, equipment,
                   preferences, active_injuries, created_at
            FROM users WHERE id = ?
        """, [user_id]).fetchone()

        logger.info(f"User signed up: id={user_id}, username={request.username}")

        return User(
            id=row[0],
            username=row[1],
            name=row[2],
            onboarding_completed=row[3],
            fitness_level=row[4],
            goals=row[5],
            equipment=row[6],
            preferences=row[7],
            active_injuries=row[8],
            created_at=row[9],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Signup failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/login", response_model=User)
async def login(request: LoginRequest):
    """
    Login with username and password.
    Returns user data if credentials are valid.
    """
    logger.info(f"Login attempt for username: {request.username}")

    try:
        db = get_db()

        # Find user by username
        row = db.conn.execute("""
            SELECT id, username, password_hash, name, onboarding_completed, fitness_level,
                   goals, equipment, preferences, active_injuries, created_at
            FROM users WHERE username = ?
        """, [request.username.lower()]).fetchone()

        if not row:
            logger.warning(f"Login failed - user not found: {request.username}")
            raise HTTPException(status_code=401, detail="Invalid username or password")

        # Verify password (handle case where password_hash might be NULL for legacy users)
        if row[2] is None or not verify_password(request.password, row[2]):
            logger.warning(f"Login failed - wrong password: {request.username}")
            raise HTTPException(status_code=401, detail="Invalid username or password")

        logger.info(f"Login successful: id={row[0]}, username={request.username}")

        return User(
            id=row[0],
            username=row[1],
            name=row[3],
            onboarding_completed=row[4],
            fitness_level=row[5],
            goals=row[6],
            equipment=row[7],
            preferences=row[8],
            active_injuries=row[9],
            created_at=row[10],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def merge_extended_fields_into_preferences(
    base_preferences: str,
    days_per_week: Optional[int],
    workout_duration: Optional[int],
    training_split: Optional[str],
    intensity_preference: Optional[str],
    preferred_time: Optional[str],
) -> str:
    """Merge extended onboarding fields into preferences JSON."""
    try:
        prefs = json.loads(base_preferences or "{}")
    except json.JSONDecodeError:
        prefs = {}

    if days_per_week is not None:
        prefs["days_per_week"] = days_per_week
    if workout_duration is not None:
        prefs["workout_duration"] = workout_duration
    if training_split is not None:
        prefs["training_split"] = training_split
    if intensity_preference is not None:
        prefs["intensity_preference"] = intensity_preference
    if preferred_time is not None:
        prefs["preferred_time"] = preferred_time

    return json.dumps(prefs)


@router.post("/", response_model=User)
async def create_user(user: UserCreate):
    """Create a new user."""
    logger.info(f"Creating user: level={user.fitness_level}")

    try:
        db = get_db()

        # Get next ID
        result = db.conn.execute("SELECT nextval('users_id_seq')").fetchone()
        user_id = result[0]
        logger.debug(f"Assigned user_id={user_id}")

        # Merge extended onboarding fields into preferences
        final_preferences = merge_extended_fields_into_preferences(
            user.preferences,
            user.days_per_week,
            user.workout_duration,
            user.training_split,
            user.intensity_preference,
            user.preferred_time,
        )
        logger.debug(f"User preferences: {final_preferences}")

        # Insert user
        db.conn.execute("""
            INSERT INTO users (id, fitness_level, goals, equipment, preferences, active_injuries)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [user_id, user.fitness_level, user.goals, user.equipment, final_preferences, user.active_injuries])

        # Fetch created user
        row = db.conn.execute("""
            SELECT id, fitness_level, goals, equipment, preferences, active_injuries, created_at
            FROM users WHERE id = ?
        """, [user_id]).fetchone()

        logger.info(f"User created: id={user_id}")

        return User(
            id=row[0],
            fitness_level=row[1],
            goals=row[2],
            equipment=row[3],
            preferences=row[4],
            active_injuries=row[5],
            created_at=row[6],
        )

    except Exception as e:
        logger.error(f"Failed to create user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: int):
    """Get a user by ID."""
    logger.info(f"Fetching user: id={user_id}")
    try:
        db = get_db()

        row = db.conn.execute("""
            SELECT id, username, name, onboarding_completed, fitness_level, goals, equipment,
                   preferences, active_injuries, created_at
            FROM users WHERE id = ?
        """, [user_id]).fetchone()

        if not row:
            logger.warning(f"User not found: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.debug(f"User found: id={user_id}, level={row[4]}")
        return User(
            id=row[0],
            username=row[1],
            name=row[2],
            onboarding_completed=row[3] if row[3] is not None else False,
            fitness_level=row[4],
            goals=row[5],
            equipment=row[6],
            preferences=row[7],
            active_injuries=row[8],
            created_at=row[9],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{user_id}", response_model=User)
async def update_user(user_id: int, user: UserUpdate):
    """Update a user."""
    logger.info(f"Updating user: id={user_id}")
    try:
        db = get_db()

        # Check if user exists
        existing = db.conn.execute("SELECT id FROM users WHERE id = ?", [user_id]).fetchone()
        if not existing:
            logger.warning(f"User not found for update: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Build update query
        updates = []
        values = []

        if user.fitness_level is not None:
            updates.append("fitness_level = ?")
            values.append(user.fitness_level)
        if user.goals is not None:
            updates.append("goals = ?")
            values.append(user.goals)
        if user.equipment is not None:
            updates.append("equipment = ?")
            values.append(user.equipment)
        if user.active_injuries is not None:
            updates.append("active_injuries = ?")
            values.append(user.active_injuries)
        if user.onboarding_completed is not None:
            updates.append("onboarding_completed = ?")
            values.append(user.onboarding_completed)

        # Handle extended onboarding fields - merge into preferences
        has_extended_fields = any([
            user.days_per_week, user.workout_duration, user.training_split,
            user.intensity_preference, user.preferred_time
        ])

        if user.preferences is not None or has_extended_fields:
            # Fetch current preferences to merge
            current_prefs = db.conn.execute(
                "SELECT preferences FROM users WHERE id = ?", [user_id]
            ).fetchone()[0]

            final_preferences = merge_extended_fields_into_preferences(
                user.preferences or current_prefs,
                user.days_per_week,
                user.workout_duration,
                user.training_split,
                user.intensity_preference,
                user.preferred_time,
            )
            updates.append("preferences = ?")
            values.append(final_preferences)

        if updates:
            values.append(user_id)
            db.conn.execute(f"""
                UPDATE users SET {', '.join(updates)} WHERE id = ?
            """, values)
            logger.debug(f"Updated {len(updates)} fields for user {user_id}")

        # Fetch updated user
        row = db.conn.execute("""
            SELECT id, username, name, onboarding_completed, fitness_level, goals, equipment,
                   preferences, active_injuries, created_at
            FROM users WHERE id = ?
        """, [user_id]).fetchone()

        logger.info(f"User updated: id={user_id}")
        return User(
            id=row[0],
            username=row[1],
            name=row[2],
            onboarding_completed=row[3] if row[3] is not None else False,
            fitness_level=row[4],
            goals=row[5],
            equipment=row[6],
            preferences=row[7],
            active_injuries=row[8],
            created_at=row[9],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}")
async def delete_user(user_id: int):
    """Delete a user."""
    logger.info(f"Deleting user: id={user_id}")
    try:
        db = get_db()

        # Check if user exists
        existing = db.conn.execute("SELECT id FROM users WHERE id = ?", [user_id]).fetchone()
        if not existing:
            logger.warning(f"User not found for deletion: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        db.conn.execute("DELETE FROM users WHERE id = ?", [user_id])
        logger.info(f"User deleted: id={user_id}")

        return {"message": "User deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/demo", response_model=User)
async def create_demo_user():
    """
    Create or get a demo user with pre-populated data.
    Demo user always has ID 999 for consistency.
    If already exists, returns existing user.
    """
    DEMO_USER_ID = 999
    logger.info("Creating/getting demo user")

    try:
        db = get_db()

        # Check if demo user already exists
        existing = db.conn.execute(
            "SELECT id, fitness_level, goals, equipment, preferences, active_injuries, created_at FROM users WHERE id = ?",
            [DEMO_USER_ID]
        ).fetchone()

        if existing:
            logger.info(f"Demo user already exists: id={DEMO_USER_ID}")
            return User(
                id=existing[0],
                fitness_level=existing[1],
                goals=existing[2],
                equipment=existing[3],
                preferences=existing[4],
                active_injuries=existing[5],
                created_at=existing[6],
            )

        # Create demo user with rich profile data
        demo_goals = json.dumps(["Build Muscle", "Improve Endurance", "Stay Healthy"])
        demo_equipment = json.dumps(["Dumbbells", "Barbell", "Pull-up Bar", "Bench", "Resistance Bands"])
        demo_preferences = json.dumps({
            "days_per_week": 4,
            "workout_duration": 60,
            "training_split": "push_pull_legs",
            "intensity_preference": "moderate",
            "preferred_time": "morning",
            "selected_days": [0, 1, 3, 4],  # Mon, Tue, Thu, Fri
            "name": "Demo User",
            "workout_variety": "varied"
        })
        demo_injuries = json.dumps([])

        db.conn.execute("""
            INSERT INTO users (id, fitness_level, goals, equipment, preferences, active_injuries)
            VALUES (?, ?, ?, ?, ?, ?)
        """, [DEMO_USER_ID, "intermediate", demo_goals, demo_equipment, demo_preferences, demo_injuries])

        # Fetch created user
        row = db.conn.execute("""
            SELECT id, fitness_level, goals, equipment, preferences, active_injuries, created_at
            FROM users WHERE id = ?
        """, [DEMO_USER_ID]).fetchone()

        logger.info(f"Demo user created: id={DEMO_USER_ID}")

        return User(
            id=row[0],
            fitness_level=row[1],
            goals=row[2],
            equipment=row[3],
            preferences=row[4],
            active_injuries=row[5],
            created_at=row[6],
        )

    except Exception as e:
        logger.error(f"Failed to create demo user: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{user_id}/reset")
async def full_reset(user_id: int):
    """
    Full reset - delete ALL user data and return to fresh state.

    This deletes (in order to respect FK constraints):
    1. performance_logs (via workout_logs)
    2. workout_logs
    3. workout_changes
    4. workouts
    5. strength_records
    6. weekly_volumes
    7. injuries
    8. chat_history
    9. user record itself
    """
    logger.info(f"Full reset for user: id={user_id}")
    try:
        db = get_db()

        # Check if user exists
        existing = db.conn.execute("SELECT id FROM users WHERE id = ?", [user_id]).fetchone()
        if not existing:
            logger.warning(f"User not found for reset: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Delete in order (respecting FK constraints)
        # 1. Delete performance_logs for user's workout_logs
        db.conn.execute("""
            DELETE FROM performance_logs
            WHERE workout_log_id IN (
                SELECT id FROM workout_logs WHERE user_id = ?
            )
        """, [user_id])
        logger.debug(f"Deleted performance_logs for user {user_id}")

        # 2. Delete workout_logs
        db.conn.execute("DELETE FROM workout_logs WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted workout_logs for user {user_id}")

        # 3. Delete workout_changes for user's workouts
        db.conn.execute("""
            DELETE FROM workout_changes
            WHERE workout_id IN (
                SELECT id FROM workouts WHERE user_id = ?
            )
        """, [user_id])
        logger.debug(f"Deleted workout_changes for user {user_id}")

        # 4. Delete workouts
        db.conn.execute("DELETE FROM workouts WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted workouts for user {user_id}")

        # 5. Delete strength_records
        db.conn.execute("DELETE FROM strength_records WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted strength_records for user {user_id}")

        # 6. Delete weekly_volumes
        db.conn.execute("DELETE FROM weekly_volumes WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted weekly_volumes for user {user_id}")

        # 7. Delete injuries
        db.conn.execute("DELETE FROM injuries WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted injuries for user {user_id}")

        # 8. Delete chat_history
        db.conn.execute("DELETE FROM chat_history WHERE user_id = ?", [user_id])
        logger.debug(f"Deleted chat_history for user {user_id}")

        # 9. Delete user record
        db.conn.execute("DELETE FROM users WHERE id = ?", [user_id])
        logger.info(f"Full reset complete for user {user_id}")

        return {
            "message": "Full reset successful. All user data has been deleted.",
            "user_id": user_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to reset user: {e}")
        raise HTTPException(status_code=500, detail=str(e))
