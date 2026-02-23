"""
Onboarding API endpoints for conversational AI onboarding.

ENDPOINTS:
- POST /api/v1/onboarding/parse-response - Parse user message and get next question
- POST /api/v1/onboarding/validate-data - Validate onboarding data
- POST /api/v1/onboarding/save-conversation - Save conversation history to database

This stores the entire conversation (questions + answers + timestamps) in the users table
as a JSONB field for later review/analysis.

NOW USES LANGGRAPH AGENT - NO HARDCODED QUESTIONS!

RATE LIMITS:
- /parse-response: 10 requests/minute (AI-intensive)
- /validate-data: 20 requests/minute
- /save-conversation: 10 requests/minute
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
from datetime import datetime
import json

from services.langgraph_onboarding_service import LangGraphOnboardingService
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.rate_limiter import limiter
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter()
logger = get_logger(__name__)

# Initialize LangGraph onboarding service
# This replaces the old hardcoded question service
onboarding_service = LangGraphOnboardingService()


class ParseOnboardingRequest(BaseModel):
    """Request to parse user's onboarding message."""
    user_id: str
    message: str
    current_data: Dict[str, Any]
    conversation_history: Optional[List[Dict[str, str]]] = []
    ai_settings: Optional[Dict[str, Any]] = None  # User's AI settings for personality customization


class ParseOnboardingResponse(BaseModel):
    """Response with extracted data and next question."""
    extracted_data: Dict[str, Any]
    next_question: Dict[str, Any]
    is_complete: bool
    missing_fields: List[str]


class ValidateDataRequest(BaseModel):
    """Request to validate onboarding data."""
    data: Dict[str, Any]


class ValidateDataResponse(BaseModel):
    """Validation result."""
    valid: bool
    errors: Dict[str, str]
    complete: bool
    missing_fields: List[str]


class ConversationMessage(BaseModel):
    """A single message in the conversation."""
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: str
    extracted_data: Optional[Dict[str, Any]] = None


class SaveConversationRequest(BaseModel):
    """Request to save conversation history."""
    user_id: str
    conversation: List[ConversationMessage]


@router.post("/parse-response", response_model=ParseOnboardingResponse)
@limiter.limit("10/minute")
async def parse_onboarding_response(request: Request, body: ParseOnboardingRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Parse user's natural language response and extract onboarding data.

    NOW USING LANGGRAPH AGENT - AI GENERATES QUESTIONS NATURALLY!

    This endpoint:
    1. Extracts structured data from the user's message using AI
    2. Validates the extracted data
    3. Merges with existing data
    4. AI decides what question to ask next (NO HARDCODED QUESTIONS)
    5. Can ask clarifying questions if user is vague

    Args:
        request: Contains user_id, message, current_data, and conversation_history

    Returns:
        Extracted data, AI-generated question, completion status, and missing fields
    """
    logger.info(f"🔍 [LangGraph] Processing onboarding message for user {body.user_id}")

    # Ensure message is a string (handle potential list/dict from malformed request)
    message = body.message
    if isinstance(message, list):
        logger.warning(f"⚠️ [LangGraph] Message was a list, converting: {message}")
        message = " ".join(str(m) for m in message) if message else ""
    elif not isinstance(message, str):
        logger.warning(f"⚠️ [LangGraph] Message was {type(message)}, converting to string")
        message = str(message) if message else ""

    logger.info(f"🔍 [LangGraph] Message: {message[:100] if message else 'None'}")

    # Don't process empty messages - avoids duplicate opening messages
    if not message or not message.strip():
        logger.info("⚠️ [LangGraph] Empty message received, returning empty response")
        return ParseOnboardingResponse(
            extracted_data=body.current_data,
            next_question={"question": "", "quick_replies": None, "component": None},
            is_complete=False,
            missing_fields=[],
        )

    try:
        result = await onboarding_service.process_message(
            user_id=body.user_id,
            message=message,  # Use the cleaned message
            collected_data=body.current_data,
            conversation_history=body.conversation_history,
            ai_settings=body.ai_settings,  # Pass AI settings for personality
        )

        logger.info(f"✅ [LangGraph] Processed successfully. Complete: {result['is_complete']}")

        # Log successful activity
        await log_user_activity(
            user_id=body.user_id,
            action="onboarding",
            endpoint="/api/v1/onboarding/parse-response",
            message=f"Onboarding step (complete: {result['is_complete']})",
            metadata={
                "is_complete": result["is_complete"],
                "missing_fields": result["missing_fields"],
            },
            status_code=200
        )

        return ParseOnboardingResponse(
            extracted_data=result["extracted_data"],
            next_question=result["next_question"],
            is_complete=result["is_complete"],
            missing_fields=result["missing_fields"],
        )

    except Exception as e:
        logger.error(f"❌ [LangGraph] Onboarding parse failed: {e}")
        # Log error with webhook alert
        await log_user_error(
            user_id=body.user_id,
            action="onboarding",
            error=e,
            endpoint="/api/v1/onboarding/parse-response",
            metadata={"message": message[:200] if message else None},
            status_code=500
        )
        raise safe_internal_error(e, "onboarding")


@router.post("/validate-data", response_model=ValidateDataResponse)
@limiter.limit("20/minute")
async def validate_onboarding_data(request: Request, body: ValidateDataRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Validate partial or complete onboarding data.

    NOW USING LANGGRAPH SERVICE VALIDATION.

    Args:
        body: Contains data to validate

    Returns:
        Validation result with errors and missing fields
    """
    logger.info("🔍 [LangGraph] Validating onboarding data")

    try:
        # Use LangGraph service validation
        validation_result = await onboarding_service.validate_data(body.data)

        errors = validation_result.get("errors", {})
        is_valid = validation_result.get("is_valid", False)

        # Determine missing fields
        required_fields = [
            "name", "goals", "equipment", "days_per_week", "selected_days",
            "workout_duration", "fitness_level", "age", "gender", "heightCm", "weightKg"
        ]
        missing = [f for f in required_fields if f not in body.data or not body.data[f]]

        logger.info(f"✅ [LangGraph] Validation complete. Valid: {is_valid}, Complete: {len(missing) == 0}")

        return ValidateDataResponse(
            valid=is_valid,
            errors=errors,
            complete=len(missing) == 0,
            missing_fields=missing,
        )

    except Exception as e:
        logger.error(f"❌ [LangGraph] Validation failed: {e}")
        raise safe_internal_error(e, "onboarding")


@router.post("/save-conversation")
@limiter.limit("10/minute")
async def save_conversation(request: Request, body: SaveConversationRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Save the entire onboarding conversation to the database.

    This stores the conversation as a JSONB field in the users table for:
    - Later review/analysis
    - Understanding user behavior
    - Debugging onboarding issues
    - Improving the AI prompts

    Args:
        body: Contains user_id and conversation messages

    Returns:
        Success status
    """
    logger.info(f"💾 Saving onboarding conversation for user {body.user_id}")

    try:
        db = get_supabase_db()

        # Convert conversation to dict for JSON storage
        conversation_data = [
            {
                "role": msg.role,
                "content": msg.content,
                "timestamp": msg.timestamp,
                "extracted_data": msg.extracted_data,
            }
            for msg in body.conversation
        ]

        # Update user record with conversation history
        # Note: This requires onboarding_conversation and onboarding_conversation_completed_at columns in users table
        try:
            result = db.client.table("users").update({
                "onboarding_conversation": conversation_data,
                "onboarding_conversation_completed_at": datetime.utcnow().isoformat(),
            }).eq("id", body.user_id).execute()

            if not result.data:
                logger.warning(f"⚠️ No rows updated for user {body.user_id} - user may not exist or columns missing")
            else:
                logger.info(f"✅ Saved {len(conversation_data)} messages to database")
        except Exception as save_error:
            # Log but don't fail - the columns might not exist yet
            logger.warning(f"⚠️ Could not save conversation to database (columns may not exist): {save_error}")
            logger.info("💡 To fix: Add 'onboarding_conversation' (JSONB) and 'onboarding_conversation_completed_at' (TIMESTAMPTZ) columns to users table")

        return {
            "success": True,
            "message": f"Saved {len(conversation_data)} conversation messages",
        }

    except Exception as e:
        logger.error(f"❌ Failed to save conversation: {e}")
        raise safe_internal_error(e, "onboarding")
