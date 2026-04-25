"""
User authentication endpoints: Google OAuth, email auth, signup, password management.
"""
from core.db import get_supabase_db
from fastapi import APIRouter, Depends, BackgroundTasks, HTTPException, Request
from core.auth import get_current_user, get_verified_auth_token
from core.exceptions import safe_internal_error
from core.supabase_client import get_supabase
from core.logger import get_logger
from core.rate_limiter import limiter
from core.username_generator import generate_username_sync
from models.schemas import User
from services.admin_service import get_admin_service
from services.email_service import get_email_service
from services.discord_webhooks import notify_signup

from api.v1.users.models import (
    GoogleAuthRequest,
    EmailAuthRequest,
    EmailSignupRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    ChangePasswordRequest,
    row_to_user,
)

router = APIRouter()
logger = get_logger(__name__)


@router.post("/auth/google", response_model=User)
@limiter.limit("5/minute")
async def google_auth(request: Request, body: GoogleAuthRequest,
    background_tasks: BackgroundTasks,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Authenticate with Google OAuth via Supabase.

    - Verifies the access token with Supabase
    - Gets or creates user in our database
    - Returns user object with onboarding status

    Uses get_verified_auth_token (not get_current_user) because new Google
    sign-in users won't have a row in the `users` table yet.
    """
    logger.info("Google OAuth authentication attempt")

    try:
        # Verify token with Supabase and get user info
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.auth_client

        # Get user from Supabase using the access token
        user_response = supabase_client.auth.get_user(body.access_token)

        if not user_response or not user_response.user:
            logger.warning("Invalid or expired access token")
            raise HTTPException(status_code=401, detail="Invalid or expired access token")

        supabase_user = user_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = supabase_user.user_metadata.get("full_name") or supabase_user.user_metadata.get("name", "")

        logger.info(f"Supabase user verified: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Check if user already exists by auth_id (supabase user id)
        existing = db.get_user_by_auth_id(supabase_user_id)

        if existing:
            logger.info(f"Existing user found: id={existing['id']}")
            # Ensure 'fitwiz' is in the apps list
            current_apps = existing.get("apps") or []
            if "fitwiz" not in current_apps:
                db.update_user(existing["id"], {"apps": current_apps + ["fitwiz"]})
            return row_to_user(existing)

        # Create new user
        # Generate unique username from name/email
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin (support@fitwiz.us)
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        # Note: goals and equipment are VARCHAR columns, not JSONB,
        # so we need to pass them as JSON strings
        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name,
            "username": unique_username,  # Auto-generated unique username
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,  # Explicitly set for new users to trigger coach selection
            "paywall_completed": False,  # Explicitly set for new users to trigger paywall flow
            "fitness_level": "beginner",
            "goals": "[]",  # VARCHAR column - needs JSON string
            "equipment": "[]",  # VARCHAR column - needs JSON string
            "equipment_v2": [],  # text[] column - dual-write during migration
            "preferences": {"name": full_name, "email": email},  # JSONB - can be dict
            "active_injuries": [],  # JSONB - can be list
            "apps": ["fitwiz"],  # Track which apps this user uses
        }

        try:
            created = db.create_user(new_user_data)
        except Exception as create_err:
            # Idempotency guard: two in-flight /auth/google requests can both
            # read "no existing user" before either finishes inserting, which
            # used to yield two DB rows for the same auth_id. With the new
            # UNIQUE (auth_id) constraint, the loser of that race throws a
            # unique-violation here. Treat that as success: re-read and
            # return the winning row. Also covers any Postgres code 23505
            # bubbled up through supabase-py as an APIError or ValueError.
            err_str = str(create_err)
            is_unique_violation = (
                "23505" in err_str
                or "duplicate key" in err_str.lower()
                or "users_auth_id_unique" in err_str
                or "users_auth_id_key" in err_str
            )
            if not is_unique_violation:
                raise
            logger.warning(
                "[AUTH-RACE] create_user hit unique(auth_id) collision for "
                f"{supabase_user_id}; returning existing row. err={err_str!r}"
            )
            existing = db.get_user_by_auth_id(supabase_user_id)
            if not existing:
                # Constraint fired but lookup failed — shouldn't happen
                # except under replication lag. Surface as 500 so caller
                # retries rather than getting a bogus empty user.
                raise
            return row_to_user(existing)

        logger.info(f"New user created via Google OAuth: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Send welcome email in background (non-blocking)
        if email:
            background_tasks.add_task(
                get_email_service().send_welcome_email, email, full_name or ""
            )

        # Notify Discord #growth channel
        background_tasks.add_task(
            notify_signup, email=email or "", user_id=created["id"],
            name=full_name, provider="google",
        )

        return row_to_user(created, is_new_user=True, support_friend_added=False)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Google auth failed: {e}", exc_info=True)
        logger.error(f"Full traceback: {full_traceback}", exc_info=True)
        raise safe_internal_error(e, "google_auth")


@router.post("/auth/email", response_model=User)
@limiter.limit("5/minute")
async def email_auth(request: Request, body: EmailAuthRequest,
    background_tasks: BackgroundTasks,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Authenticate with email and password via Supabase.

    - Signs in with Supabase Auth
    - Gets or creates user in our database
    - Returns user object with onboarding status

    Uses get_verified_auth_token (not get_current_user) because new email
    sign-in users won't have a row in the `users` table yet.
    """
    logger.info(f"Email authentication attempt for: ...{str(body.email)[-10:]}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.auth_client

        # Sign in with Supabase Auth — only this block should 401 on credential failure.
        # Downstream failures (user-row creation, DB errors) are 500s, not 401s.
        try:
            auth_response = supabase_client.auth.sign_in_with_password({
                "email": body.email,
                "password": body.password,
            })
        except Exception as auth_err:
            logger.warning(f"Supabase auth rejected credentials for ...{str(body.email)[-10:]}: {auth_err}")
            raise HTTPException(status_code=401, detail="Invalid email or password")

        if not auth_response or not auth_response.user:
            logger.warning(f"Invalid email or password for: ...{str(body.email)[-10:]}")
            raise HTTPException(status_code=401, detail="Invalid email or password")

        supabase_user = auth_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = supabase_user.user_metadata.get("full_name") or supabase_user.user_metadata.get("name", "")

        logger.info(f"Supabase user verified: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Check if user already exists by auth_id
        existing = db.get_user_by_auth_id(supabase_user_id)

        if existing:
            logger.info(f"Existing user found: id={existing['id']}")
            return row_to_user(existing)

        # Create new user (rare case - user exists in Supabase Auth but not in our DB)
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name or "User",
            "username": unique_username,
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,
            "paywall_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",
            "equipment": "[]",
            "equipment_v2": [],  # text[] column - dual-write during migration
            "preferences": {"name": full_name, "email": email},
            "active_injuries": [],
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via email auth: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Send welcome email in background (non-blocking)
        if email:
            background_tasks.add_task(
                get_email_service().send_welcome_email, email, full_name or ""
            )

        return row_to_user(created, is_new_user=True, support_friend_added=False)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Email auth failed (post-credential check): {e}", exc_info=True)
        logger.error(f"Full traceback: {full_traceback}", exc_info=True)
        # Credentials were valid — this is a server-side failure (DB, RLS, etc.), not a 401.
        raise HTTPException(status_code=500, detail="Account setup failed. Please try again or contact support.")


@router.post("/auth/email/signup", response_model=User)
@limiter.limit("5/minute")
async def email_signup(request: Request, body: EmailSignupRequest,
    background_tasks: BackgroundTasks,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Create a new account with email and password via Supabase.

    - Creates user in Supabase Auth
    - Creates user in our database
    - Returns user object

    Uses get_verified_auth_token (not get_current_user) because signup users
    will never have a row in the `users` table yet.
    """
    logger.info(f"Email signup attempt for: ...{str(body.email)[-10:]}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.auth_client

        # Sign up with Supabase Auth
        auth_response = supabase_client.auth.sign_up({
            "email": body.email,
            "password": body.password,
            "options": {
                "data": {
                    "full_name": body.name or "",
                }
            }
        })

        if not auth_response or not auth_response.user:
            logger.warning(f"Signup failed for: ...{str(body.email)[-10:]}")
            raise HTTPException(status_code=400, detail="Signup failed. Please try again.")

        supabase_user = auth_response.user
        supabase_user_id = supabase_user.id
        email = supabase_user.email
        full_name = body.name or ""

        logger.info(f"Supabase user created: id={supabase_user_id}, email={email}")

        db = get_supabase_db()

        # Generate unique username
        unique_username = generate_username_sync(name=full_name, email=email)
        logger.info(f"Generated unique username: {unique_username}")

        # Check if this email should be an admin
        admin_service = get_admin_service()
        is_admin = admin_service.should_be_admin(email)
        is_support = admin_service.should_be_support_user(email)

        new_user_data = {
            "auth_id": supabase_user_id,
            "email": email,
            "name": full_name or "User",
            "username": unique_username,
            "role": "admin" if is_admin else "user",
            "is_support_user": is_support,
            "onboarding_completed": False,
            "coach_selected": False,
            "paywall_completed": False,
            "fitness_level": "beginner",
            "goals": "[]",
            "equipment": "[]",
            "equipment_v2": [],  # text[] column - dual-write during migration
            "preferences": {"name": full_name, "email": email},
            "active_injuries": [],
        }

        created = db.create_user(new_user_data)
        logger.info(f"New user created via email signup: id={created['id']}, email={email}, role={created.get('role', 'user')}")

        # Send welcome email in background (non-blocking)
        if email:
            background_tasks.add_task(
                get_email_service().send_welcome_email, email, full_name or ""
            )

        # Notify Discord #growth channel
        background_tasks.add_task(
            notify_signup, email=email or "", user_id=created["id"],
            name=full_name, provider="email",
        )

        return row_to_user(created, is_new_user=True, support_friend_added=False)

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        full_traceback = traceback.format_exc()
        logger.error(f"Email signup failed: {e}", exc_info=True)
        logger.error(f"Full traceback: {full_traceback}", exc_info=True)
        raise HTTPException(status_code=400, detail="Signup failed. Please try again.")


@router.post("/auth/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(request: Request, body: ForgotPasswordRequest):
    """
    Send password reset email via Supabase.

    No auth required — the user forgot their password and can't authenticate.
    Returns success regardless of whether email exists (security).
    """
    logger.info(f"Password reset requested for: ...{str(body.email)[-10:]}")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.auth_client

        # Request password reset from Supabase
        # Note: Supabase will send an email with a reset link
        supabase_client.auth.reset_password_for_email(body.email)

        logger.info(f"Password reset email sent to: ...{str(body.email)[-10:]}")

        # Always return success for security (don't reveal if email exists)
        return {"message": "If an account exists with this email, a password reset link has been sent."}

    except Exception as e:
        logger.error(f"Password reset failed: {e}", exc_info=True)
        # Still return success for security
        return {"message": "If an account exists with this email, a password reset link has been sent."}


@router.post("/auth/reset-password")
@limiter.limit("5/minute")
async def reset_password(request: Request, body: ResetPasswordRequest,
    verified_token: dict = Depends(get_verified_auth_token),
):
    """
    Reset password using the token from reset email.

    Uses get_verified_auth_token (not get_current_user) because the user
    authenticates with a reset token, not a regular session.
    """
    logger.info("Password reset attempt with token")

    try:
        supabase_manager = get_supabase()
        supabase_client = supabase_manager.auth_client

        # Update the user's password using the access token from the reset link
        # The client should have exchanged the reset link for an access token
        user_response = supabase_client.auth.get_user(body.access_token)

        if not user_response or not user_response.user:
            raise HTTPException(status_code=401, detail="Invalid or expired reset token")

        # Update password
        supabase_client.auth.update_user({
            "password": body.new_password
        })

        logger.info(f"Password reset successful for user: ...{str(user_response.user.email)[-10:]}")
        return {"message": "Password has been reset successfully."}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Password reset failed: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Failed to reset password. Token may be expired.")


@router.post("/auth/change-password")
@limiter.limit("5/minute")
async def change_password(
    request: Request,
    body: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Change password for the currently logged-in user.

    SECURITY: Requires current password for re-authentication before
    allowing password change. This is the in-app alternative to the
    email-based forgot-password flow.

    Args:
        body: Contains current_password and new_password
        current_user: Authenticated user from JWT

    Returns:
        Success message

    Raises:
        HTTPException 401: If current password is wrong
        HTTPException 422: If new password doesn't meet complexity requirements
    """
    try:
        supabase = get_supabase()

        # Step 1: Verify current password by re-authenticating
        try:
            supabase.auth_client.auth.sign_in_with_password({
                "email": current_user["email"],
                "password": body.current_password,
            })
        except Exception:
            raise HTTPException(status_code=401, detail="Current password is incorrect")

        # Step 2: Update to new password
        supabase.auth_client.auth.update_user({"password": body.new_password})
        logger.info(f"Password changed for user: {current_user['id']}")

        return {"message": "Password changed successfully."}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Password change failed for user {current_user['id']}: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail="Failed to change password. Please try again.")
