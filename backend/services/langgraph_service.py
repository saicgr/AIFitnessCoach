"""
LangGraph Coach Service - FastAPI integration wrapper with dedicated domain agents.

This service routes messages to specialized domain agents:
- Nutrition Agent: Food analysis, dietary advice
- Workout Agent: Exercise modifications, workout guidance
- Injury Agent: Injury tracking, recovery advice
- Hydration Agent: Water intake tracking, hydration tips
- Coach Agent: General fitness coaching, app navigation

Performance: Simple messages (greetings, thanks, goodbye) are handled via
a fast-path that skips intent extraction, RAG lookup, and agent execution.
"""
import asyncio
import re
import time
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List, Tuple

from models.chat import ChatRequest, ChatResponse, CoachIntent, AgentType
from services.gemini_service import GeminiService
from services.rag_service import RAGService, WorkoutRAGService

# Import all domain agents
from services.langgraph_agents.nutrition_agent import build_nutrition_agent_graph
from services.langgraph_agents.workout_agent import build_workout_agent_graph
from services.langgraph_agents.injury_agent import build_injury_agent_graph
from services.langgraph_agents.hydration_agent import build_hydration_agent_graph
from services.langgraph_agents.coach_agent import build_coach_agent_graph

from core.logger import get_logger
from core.anonymize import anonymize_user_data
from core.supabase_client import get_supabase
from core.db.facade import get_supabase_db


def _ensure_str(content) -> str:
    """Normalize LangChain AIMessage content to a plain string.

    Newer langchain-google-genai (4.x) with Vertex AI can return content as a
    list of blocks like [{'type': 'text', 'text': '...'}, ...] instead of a
    simple string. This extracts and joins the text parts.
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
            elif isinstance(block, str):
                parts.append(block)
        return "".join(parts) if parts else ""
    return str(content) if content else ""

logger = get_logger(__name__)


# Greeting/thanks/goodbye messages have no retrievable past context worth the
# ChromaDB Cloud round-trip. Anchored regex so "hip pain" doesn't match "hi".
_TRIVIAL_MESSAGE_RE = re.compile(
    r"^\s*("
    r"hi|hello|hey|howdy|yo|sup|hola|"
    r"thanks|thank you|thx|ty|cheers|"
    r"bye|goodbye|cya|see ya|later|"
    r"ok|okay|cool|nice|great|awesome|sweet|"
    r"good morning|good afternoon|good evening|good night|gm|gn"
    r")[\s!.?,]*$",
    re.IGNORECASE,
)


def _is_trivial_message(message: str) -> bool:
    """True if the message is a pure greeting/thanks/goodbye with no question.

    Such messages don't benefit from RAG context — skipping saves the 5-13s
    ChromaDB Cloud cold-query latency. Keep strict: anything with a question
    mark, @mention, or content beyond the greeting must go through RAG.
    """
    if not message or len(message) > 60 or "?" in message or "@" in message:
        return False
    return bool(_TRIVIAL_MESSAGE_RE.match(message))


# ──────────────────────────────────────────────
# @mention patterns for direct agent routing
AGENT_MENTION_PATTERNS = {
    r"@nutrition\b": AgentType.NUTRITION,
    r"@workout\b": AgentType.WORKOUT,
    r"@injury\b": AgentType.INJURY,
    r"@hydration\b": AgentType.HYDRATION,
    r"@coach\b": AgentType.COACH,
}

# Intent to agent mapping
INTENT_TO_AGENT = {
    # Nutrition agent
    CoachIntent.ANALYZE_FOOD: AgentType.NUTRITION,
    CoachIntent.NUTRITION_SUMMARY: AgentType.NUTRITION,
    CoachIntent.RECENT_MEALS: AgentType.NUTRITION,
    CoachIntent.LOG_FOOD: AgentType.NUTRITION,

    # Workout agent
    CoachIntent.ADD_EXERCISE: AgentType.WORKOUT,
    CoachIntent.REMOVE_EXERCISE: AgentType.WORKOUT,
    CoachIntent.SWAP_WORKOUT: AgentType.WORKOUT,
    CoachIntent.MODIFY_INTENSITY: AgentType.WORKOUT,
    CoachIntent.RESCHEDULE: AgentType.WORKOUT,
    CoachIntent.DELETE_WORKOUT: AgentType.WORKOUT,
    CoachIntent.RECOMMEND_WORKOUT_CHANGE: AgentType.WORKOUT,
    CoachIntent.START_WORKOUT: AgentType.WORKOUT,
    CoachIntent.COMPLETE_WORKOUT: AgentType.WORKOUT,
    CoachIntent.GENERATE_QUICK_WORKOUT: AgentType.WORKOUT,

    # Injury agent
    CoachIntent.REPORT_INJURY: AgentType.INJURY,

    # Hydration agent
    CoachIntent.LOG_HYDRATION: AgentType.HYDRATION,

    # Form analysis -> Workout agent
    CoachIntent.CHECK_EXERCISE_FORM: AgentType.WORKOUT,
    CoachIntent.COMPARE_EXERCISE_FORM: AgentType.WORKOUT,

    # Multi-image nutrition intents
    CoachIntent.ANALYZE_MENU: AgentType.NUTRITION,
    CoachIntent.ANALYZE_BUFFET: AgentType.NUTRITION,

    # Coach agent (default for these)
    CoachIntent.QUESTION: AgentType.COACH,
    CoachIntent.CHANGE_SETTING: AgentType.COACH,
    CoachIntent.NAVIGATE: AgentType.COACH,
    CoachIntent.SET_WATER_GOAL: AgentType.COACH,
    CoachIntent.LOG_WEIGHT: AgentType.COACH,
}

# Keyword-based routing for message analysis
DOMAIN_KEYWORDS = {
    AgentType.NUTRITION: [
        "food", "eat", "ate", "meal", "calories", "protein", "carbs", "fat",
        "nutrition", "diet", "macros", "breakfast", "lunch", "dinner", "snack",
        "hungry", "recipe", "cooking", "what should i eat",
        "menu", "buffet", "restaurant", "dishes", "options"
    ],
    AgentType.WORKOUT: [
        "exercise", "workout", "training", "gym", "lift", "squat", "bench",
        "deadlift", "muscle", "strength", "cardio", "hiit", "sets", "reps",
        "form", "technique", "how do i do", "quick", "create workout",
        "generate workout", "make workout", "give me a workout", "new workout",
        "short workout", "form check", "check my form", "rep count",
        "count reps", "posture", "compare form", "form comparison"
    ],
    AgentType.INJURY: [
        "hurt", "pain", "injury", "injured", "sore", "strain", "sprain",
        "recovery", "rehab", "heal", "prevent", "ice", "rest"
    ],
    AgentType.HYDRATION: [
        "water", "hydration", "hydrate", "drink", "thirsty", "dehydrated",
        "glasses", "cups", "fluid"
    ],
}


# ──────────────────────────────────────────────
# Rate-limit / cost-protection constants
MAX_MEDIA_PER_REQUEST = 5       # Max media items in a single request
MAX_IMAGES_PER_REQUEST = 5      # Max images in a single request
MAX_VIDEOS_PER_REQUEST = 3      # Max videos in a single request
DAILY_MEDIA_CAP_FREE = 20       # Free-tier daily media analysis limit
DAILY_MEDIA_CAP_PRO = 100       # Pro-tier daily media analysis limit
_NUTRITION_SEMAPHORE = asyncio.Semaphore(10)  # Limit concurrent vision calls


class LangGraphCoachService:
    """
    LangGraph-based coach service with dedicated domain agents.

    Routes messages to specialized agents based on:
    1. @mentions (explicit routing)
    2. Intent detection (from message analysis)
    3. Keyword matching (fallback)
    """

    def __init__(self):
        """Initialize all domain agents."""
        logger.info("Initializing LangGraph coach service with dedicated agents...")

        # Build all agent graphs
        self.agents = {
            AgentType.NUTRITION: build_nutrition_agent_graph(),
            AgentType.WORKOUT: build_workout_agent_graph(),
            AgentType.INJURY: build_injury_agent_graph(),
            AgentType.HYDRATION: build_hydration_agent_graph(),
            AgentType.COACH: build_coach_agent_graph(),
        }

        # Initialize services for intent extraction
        self.gemini_service = GeminiService()

        logger.info("All domain agents initialized successfully")

    # ── Rate-limit helpers ─────────────────────────

    @staticmethod
    def _validate_media_request(media_refs: Optional[List[Any]]) -> None:
        """Validate per-request media limits.

        Raises ValueError if limits are exceeded.
        """
        if not media_refs:
            return

        total = len(media_refs)
        if total > MAX_MEDIA_PER_REQUEST:
            raise ValueError(
                f"Too many media items ({total}). Maximum is {MAX_MEDIA_PER_REQUEST} per request."
            )

        images = sum(1 for r in media_refs if getattr(r, "media_type", None) == "image")
        videos = sum(1 for r in media_refs if getattr(r, "media_type", None) == "video")

        if images > MAX_IMAGES_PER_REQUEST:
            raise ValueError(
                f"Too many images ({images}). Maximum is {MAX_IMAGES_PER_REQUEST} per request."
            )
        if videos > MAX_VIDEOS_PER_REQUEST:
            raise ValueError(
                f"Too many videos ({videos}). Maximum is {MAX_VIDEOS_PER_REQUEST} per request."
            )

    @staticmethod
    def _trim_conversation_history(history: list, max_total_chars: int = 50_000) -> list:
        """Trim conversation history to fit within a total character budget.

        Keeps the most recent messages, dropping oldest first.
        Prevents excessively large payloads from being sent to Gemini.
        50,000 chars ≈ 12,500 tokens.
        """
        if not history:
            return history
        total_chars = sum(len(msg.get("content", "")) for msg in history)
        if total_chars <= max_total_chars:
            return history
        # Drop oldest messages until within budget
        trimmed = list(history)
        while trimmed and total_chars > max_total_chars:
            removed = trimmed.pop(0)
            total_chars -= len(removed.get("content", ""))
        return trimmed

    @staticmethod
    async def _check_media_usage(user_id: str, media_count: int = 1) -> None:
        """Check daily media usage cap for the user.

        Queries the chat_media_usage table (or falls back gracefully)
        and raises ValueError if the daily cap is exceeded.
        """
        try:
            supabase = get_supabase().client
            today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

            # Get today's usage count
            usage_result = supabase.table("chat_media_usage").select(
                "media_count"
            ).eq("user_id", user_id).eq("usage_date", today_str).maybe_single().execute()

            current_count = 0
            if usage_result and usage_result.data:
                current_count = usage_result.data.get("media_count", 0)

            # Check user tier for cap (default to free tier)
            cap = DAILY_MEDIA_CAP_FREE
            try:
                tier_result = supabase.table("user_settings").select(
                    "subscription_tier"
                ).eq("user_id", user_id).maybe_single().execute()
                if tier_result and tier_result.data:
                    tier = tier_result.data.get("subscription_tier", "free")
                    if tier in ("pro", "premium"):
                        cap = DAILY_MEDIA_CAP_PRO
            except Exception as e:
                logger.warning(f"Failed to fetch subscription tier: {e}", exc_info=True)

            if current_count + media_count > cap:
                raise ValueError(
                    f"Daily media analysis limit reached ({current_count}/{cap}). "
                    f"Please try again tomorrow or upgrade your plan."
                )

            # Increment usage
            if usage_result and usage_result.data:
                supabase.table("chat_media_usage").update(
                    {"media_count": current_count + media_count}
                ).eq("user_id", user_id).eq("usage_date", today_str).execute()
            else:
                supabase.table("chat_media_usage").insert({
                    "user_id": user_id,
                    "usage_date": today_str,
                    "media_count": media_count,
                }).execute()

            logger.info(f"Media usage for {user_id}: {current_count + media_count}/{cap}")

        except ValueError:
            raise  # Re-raise usage limit errors
        except Exception as e:
            # Don't block requests if usage tracking fails
            logger.warning(f"Media usage check failed (non-blocking): {e}", exc_info=True)

    @staticmethod
    def _fast_trivial_reply(message: str) -> str:
        """Canned reply for trivial greetings/thanks/goodbyes. No Gemini call."""
        m = message.strip().lower().rstrip("!.?,")
        if m in {"thanks", "thank you", "thx", "ty", "cheers"}:
            return "Anytime! Let me know what's next 💪"
        if m in {"bye", "goodbye", "cya", "see ya", "later", "good night", "gn"}:
            return "Talk soon — keep showing up. 👋"
        if m in {"good morning", "gm"}:
            return "Morning! Ready to crush today's session?"
        if m in {"good afternoon", "good evening"}:
            return f"Good {m.split()[-1]}! How can I help?"
        if m in {"ok", "okay", "cool", "nice", "great", "awesome", "sweet"}:
            return "👍"
        # default greeting
        return "Hey! What's on your mind today — workout, nutrition, or something else?"

    def _detect_agent_mention(self, message: str) -> Tuple[Optional[AgentType], str]:
        """
        Detect @mention in message and extract agent type.

        Args:
            message: The user's message

        Returns:
            Tuple of (agent_type, cleaned_message)
        """
        for pattern, agent_type in AGENT_MENTION_PATTERNS.items():
            match = re.search(pattern, message, re.IGNORECASE)
            if match:
                cleaned = re.sub(pattern, "", message, flags=re.IGNORECASE).strip()
                logger.info(f"Detected @mention: {agent_type.value}, cleaned message: {cleaned[:50]}...")
                return agent_type, cleaned
        return None, message

    @staticmethod
    def _sanitize_user_message(message: str) -> str:
        """Sanitize user message against prompt injection attacks.

        Strips known injection patterns that attempt to override system prompts
        or manipulate the AI into ignoring its instructions. This is a defense-in-depth
        measure — the AI should also be resilient via its system prompt, but stripping
        obvious attack patterns reduces risk.

        Args:
            message: The user's raw message

        Returns:
            Sanitized message with injection patterns removed

        Notes:
            - EDGE CASE: Legitimate messages like "ignore my previous message" are preserved
              because we only match patterns with "instructions"/"prompts"/"system" context
            - Patterns are case-insensitive
            - This is NOT a complete solution — AI safety also requires output validation
        """
        # Patterns that attempt to override system instructions
        injection_patterns = [
            r'ignore\s+(all\s+)?previous\s+instructions',
            r'ignore\s+(all\s+)?prior\s+instructions',
            r'disregard\s+(all\s+)?previous\s+instructions',
            r'forget\s+(all\s+)?previous\s+instructions',
            r'override\s+(all\s+)?previous\s+instructions',
            r'you\s+are\s+now\s+(?:a\s+)?(?:new|different)',
            r'SYSTEM\s*:\s*',  # Fake system message injection
            r'ASSISTANT\s*:\s*',  # Fake assistant role injection
            r'<\|?(?:system|endoftext|im_start|im_end)\|?>',  # Token injection attempts
            r'###\s*(?:SYSTEM|INSTRUCTION|NEW\s+ROLE)',  # Markdown-style injection
        ]

        sanitized = message
        for pattern in injection_patterns:
            sanitized = re.sub(pattern, '', sanitized, flags=re.IGNORECASE)

        # Collapse multiple spaces from removals
        sanitized = re.sub(r'\s{2,}', ' ', sanitized).strip()

        if sanitized != message:
            logger.warning(f"⚠️ [Security] Prompt injection pattern detected and sanitized for message (length {len(message)})")

        return sanitized or message  # Never return empty string

    def _infer_agent_from_intent(self, intent: CoachIntent) -> AgentType:
        """Infer which agent should handle based on intent."""
        return INTENT_TO_AGENT.get(intent, AgentType.COACH)

    def _infer_agent_from_keywords(self, message: str) -> Optional[AgentType]:
        """
        Fallback: Infer agent from keywords in message.

        Returns None if no clear match (will default to coach).
        Uses word boundary matching to avoid false positives like "ate" in "generate".
        """
        import re
        message_lower = message.lower()

        keyword_counts = {}
        for agent_type, keywords in DOMAIN_KEYWORDS.items():
            # Use word boundary matching to avoid partial matches
            count = sum(1 for kw in keywords if re.search(r'\b' + re.escape(kw) + r'\b', message_lower))
            if count > 0:
                keyword_counts[agent_type] = count

        if keyword_counts:
            best_match = max(keyword_counts, key=keyword_counts.get)
            logger.info(f"Keyword match: {best_match.value} (score: {keyword_counts[best_match]})")
            return best_match

        return None

    async def _extract_intent(self, message: str, user_id: Optional[str] = None) -> Tuple[CoachIntent, Dict[str, Any]]:
        """
        Extract intent and entities from user message.

        Returns:
            Tuple of (intent, extraction_data)
        """
        extraction = await self.gemini_service.extract_intent(message, user_id=user_id)
        return extraction.intent, {
            "exercises": extraction.exercises,
            "muscle_groups": extraction.muscle_groups,
            "modification": extraction.modification,
            "body_part": extraction.body_part,
            "setting_name": extraction.setting_name,
            "setting_value": extraction.setting_value,
            "destination": extraction.destination,
            "hydration_amount": extraction.hydration_amount,
            "water_goal_glasses": extraction.water_goal_glasses,
            "weight_value": extraction.weight_value,
        }

    async def _get_rag_context(self, message: str, user_id: str) -> Tuple[str, bool, list]:
        """Get RAG context for the message, including training settings."""
        context_parts = []
        rag_used = False
        similar_questions = []

        # 1. Get Q&A context (existing behavior)
        try:
            rag_service = RAGService(gemini_service=self.gemini_service)
            similar_docs = await rag_service.find_similar(
                query=message,
                user_id=user_id,
                n_results=3
            )
            formatted = rag_service.format_context(similar_docs)
            if formatted:
                context_parts.append(formatted)
                rag_used = True
            similar_questions = [
                doc.get("metadata", {}).get("question", "")
                for doc in similar_docs[:3]
            ]
        except Exception as e:
            logger.warning(f"Q&A RAG context retrieval failed: {e}", exc_info=True)

        # 2. Get training settings context (1RMs, intensity, etc.)
        try:
            workout_rag = WorkoutRAGService(self.gemini_service)
            training_settings = workout_rag.get_recent_training_settings(
                user_id=user_id,
                days_lookback=30,
                max_results=10
            )
            if training_settings.get("has_settings") and training_settings.get("context_text"):
                # Add training settings as a separate context section
                settings_context = f"\n--- User's Training Settings ---\n{training_settings['context_text']}"
                context_parts.append(settings_context)
                rag_used = True
                logger.info(f"📊 Added training settings to RAG context for user {user_id}")
        except Exception as e:
            logger.warning(f"Training settings RAG retrieval failed: {e}", exc_info=True)

        # Combine all context parts
        combined_context = "\n\n".join(context_parts)
        return combined_context, rag_used, similar_questions

    # Maps media content types to their target agent
    _MEDIA_CONTENT_ROUTING = {
        "exercise_form": AgentType.WORKOUT,
        "food_plate": AgentType.NUTRITION,
        "food_menu": AgentType.NUTRITION,
        "food_buffet": AgentType.NUTRITION,
        "nutrition_label": AgentType.NUTRITION,
        "app_screenshot": AgentType.NUTRITION,
        # Recipes feature: pantry photos and handwritten recipes both go to Nutrition
        "pantry_photo": AgentType.NUTRITION,
        "recipe_handwritten": AgentType.NUTRITION,
        "progress_photo": AgentType.COACH,
        "document": AgentType.COACH,
        "gym_equipment": AgentType.COACH,
    }

    def _select_agent(
        self,
        mentioned_agent: Optional[AgentType],
        intent: CoachIntent,
        message: str,
        has_image: bool,
        has_video: bool = False,
        has_multi_images: bool = False,
        has_multi_videos: bool = False,
        media_content_type: Optional[str] = None,
        agent_override: Optional[str] = None,
    ) -> AgentType:
        """
        Select the appropriate agent based on all available signals.

        Priority:
        0. Explicit `agent_override` from the caller (trusted contextual widgets)
        1. Explicit @mention
        2. Content-aware routing (media_content_type from classifier)
        3. Type-based fallbacks (video->Workout, image->Nutrition) when classifier unavailable
        4. Intent-based routing
        5. Keyword-based routing
        6. Default to Coach
        """
        # 0. Trusted caller override beats every other signal. The Pydantic
        # validator on ChatRequest.agent_override already guarantees the value
        # matches an AgentType member, but we defensively re-validate here in
        # case the function is invoked from a path that bypasses Pydantic.
        if agent_override:
            try:
                forced = AgentType(agent_override.lower().strip())
                logger.info(f"Agent selection: agent_override -> {forced.value}")
                return forced
            except ValueError:
                logger.warning(
                    f"Agent selection: invalid agent_override={agent_override!r}, "
                    "falling through to classifier"
                )

        # 1. Explicit @mention takes priority
        if mentioned_agent:
            logger.info(f"Agent selection: @mention -> {mentioned_agent.value}")
            return mentioned_agent

        # 2. Content-aware routing via media classifier
        if media_content_type and media_content_type != "unknown":
            routed_agent = self._MEDIA_CONTENT_ROUTING.get(media_content_type)
            if routed_agent:
                logger.info(f"Agent selection: media_content_type={media_content_type} -> {routed_agent.value}")
                return routed_agent

        # 3. Type-based fallbacks (when classifier returns None/unknown)
        # 3a. Multi-video -> always Workout agent for form comparison
        if has_multi_videos:
            logger.info("Agent selection: multi-video -> workout (form comparison)")
            return AgentType.WORKOUT

        # 3b. Single video -> Workout agent for form analysis
        if has_video:
            logger.info("Agent selection: video present -> workout (form analysis)")
            return AgentType.WORKOUT

        # 3c. Multi-image -> Nutrition agent for batch food analysis
        if has_multi_images:
            logger.info("Agent selection: multi-image -> nutrition (batch food analysis)")
            return AgentType.NUTRITION

        # 3d. Single image -> check form keywords first, then default to Nutrition
        if has_image:
            form_keywords = ["form", "check", "posture", "technique", "rep", "count"]
            message_lower = message.lower()
            if any(kw in message_lower for kw in form_keywords):
                logger.info("Agent selection: image + form keywords -> workout (form analysis)")
                return AgentType.WORKOUT
            logger.info("Agent selection: image present -> nutrition")
            return AgentType.NUTRITION

        # 4. Intent-based routing
        agent_from_intent = self._infer_agent_from_intent(intent)
        if agent_from_intent != AgentType.COACH:
            logger.info(f"Agent selection: intent {intent.value} -> {agent_from_intent.value}")
            return agent_from_intent

        # 5. Keyword-based routing
        agent_from_keywords = self._infer_agent_from_keywords(message)
        if agent_from_keywords:
            logger.info(f"Agent selection: keywords -> {agent_from_keywords.value}")
            return agent_from_keywords

        # 6. Default to Coach
        logger.info("Agent selection: default -> coach")
        return AgentType.COACH

    async def _classify_media(self, request: ChatRequest) -> Optional[str]:
        """Classify media content for intelligent routing. Returns content type string."""
        try:
            from services.vision_service import VisionService
            vision = VisionService()

            # Direct base64 image
            if request.image_base64:
                return await vision.classify_media_content(image_base64=request.image_base64)

            # S3-stored media references (plural or singular)
            refs = []
            if hasattr(request, "media_refs") and request.media_refs:
                refs = list(request.media_refs)
            elif hasattr(request, "media_ref") and request.media_ref:
                refs = [request.media_ref]

            if refs:
                first_ref = refs[0]

                # For video, extract first keyframe and classify that
                if first_ref.media_type == "video":
                    return await self._classify_video_media(first_ref, vision)

                # For images, classify directly via S3
                return await vision.classify_media_content(
                    s3_key=first_ref.s3_key,
                    mime_type=first_ref.mime_type,
                )

            return None
        except Exception as e:
            logger.warning(f"Media classification failed (falling back to type-based): {e}", exc_info=True)
            return None

    async def _classify_video_media(self, media_ref, vision) -> Optional[str]:
        """Extract first keyframe from video and classify it."""
        try:
            import tempfile
            import os

            # Download video from S3 to temp file
            s3_data = await vision._download_image_from_s3(media_ref.s3_key)
            suffix = ".mp4" if "mp4" in media_ref.mime_type else ".mov"
            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
                tmp.write(s3_data)
                tmp_path = tmp.name

            try:
                from services.keyframe_extractor import extract_key_frames
                frames = await extract_key_frames(tmp_path, num_frames=1)
                if frames:
                    frame_bytes, frame_mime = frames[0]
                    return await vision.classify_media_content(
                        image_data=frame_bytes,
                        mime_type=frame_mime,
                    )
            finally:
                os.unlink(tmp_path)

            return None
        except Exception as e:
            logger.warning(f"Video keyframe classification failed: {e}", exc_info=True)
            return None

    def _enrich_user_profile(self, request) -> Optional[Dict[str, Any]]:
        """Anonymize and enrich user profile with nutrition_preferences targets."""
        if not request.user_profile:
            return None
        user_profile_dict = anonymize_user_data(request.user_profile.model_dump())
        if user_profile_dict:
            try:
                db = get_supabase_db()
                user_profile_dict = db.enrich_user_with_nutrition_targets(user_profile_dict)
            except Exception as e:
                logger.warning(f"Failed to enrich user profile with nutrition targets: {e}", exc_info=True)
        return user_profile_dict

    async def _build_agent_state(
        self,
        agent_type: AgentType,
        request: ChatRequest,
        cleaned_message: str,
        intent: CoachIntent,
        extraction_data: Dict[str, Any],
        rag_context: str,
        rag_used: bool,
        similar_questions: list,
        beast_mode_config: Optional[Dict[str, Any]] = None,
        media_content_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Build the state dictionary for the selected agent."""
        base_state = {
            "user_message": cleaned_message,
            "user_id": request.user_id,
            "user_profile": self._enrich_user_profile(request),
            "conversation_history": self._trim_conversation_history(request.conversation_history),
            "intent": intent,
            "rag_documents": [],
            "rag_context_formatted": rag_context,
            "ai_response": "",
            "final_response": "",
            "action_data": None,
            "rag_context_used": rag_used,
            "similar_questions": similar_questions,
            "error": None,
            # AI personality settings
            "ai_settings": request.ai_settings.model_dump() if request.ai_settings else None,
            # Unified fasting/nutrition/workout context from frontend
            "unified_context": request.unified_context,
            # Media classification from classifier
            "media_content_type": media_content_type,
        }

        # Normalize media_refs from request (combine singular + plural)
        media_refs_dicts = None
        if hasattr(request, "media_refs") and request.media_refs:
            media_refs_dicts = [mr.model_dump() for mr in request.media_refs]
        elif hasattr(request, "media_ref") and request.media_ref:
            # Single media_ref -> wrap in list for backward compatibility
            media_refs_dicts = [request.media_ref.model_dump()]

        # Add agent-specific fields
        if agent_type == AgentType.NUTRITION:
            base_state["image_base64"] = request.image_base64
            base_state["media_refs"] = media_refs_dicts
            base_state["current_workout"] = request.current_workout.model_dump() if request.current_workout else None
            base_state["workout_schedule"] = request.workout_schedule.model_dump() if request.workout_schedule else None

            # Pre-fetch day context in parallel so the agent can reference
            # calorie remainder, workout, and favorites directly in its
            # system prompt — no tool round-trip needed for preset queries.
            # Any individual failure is tolerated via return_exceptions; the
            # `context_partial` flag downstream softens the prompt.
            from services.langgraph_agents.tools.nutrition_context_helpers import (
                fetch_daily_nutrition_context,
                fetch_recent_favorites,
                fetch_todays_workout,
            )
            # `user_profile` arrives as a Pydantic `UserProfile` model from the
            # chat endpoint (no `.get`) OR as a plain dict from internal
            # call-sites. Normalize before reading the timezone — and note that
            # UserProfile doesn't even declare a timezone field today, so this
            # will typically fall through to the "UTC" default until the model
            # is extended.
            _up = request.user_profile
            if hasattr(_up, "model_dump"):
                _up_dict = _up.model_dump()
            elif isinstance(_up, dict):
                _up_dict = _up
            else:
                _up_dict = {}
            user_tz = _up_dict.get("timezone") or "UTC"
            daily_ctx, favs, today_wo = await asyncio.gather(
                fetch_daily_nutrition_context(str(request.user_id), user_tz),
                fetch_recent_favorites(str(request.user_id), limit=5, exclude_days=0),
                fetch_todays_workout(str(request.user_id), user_tz),
                return_exceptions=True,
            )
            base_state["daily_nutrition_context"] = (
                daily_ctx if not isinstance(daily_ctx, Exception) else None
            )
            base_state["recent_favorites"] = (
                favs if not isinstance(favs, Exception) else []
            )
            if base_state["current_workout"] is None and not isinstance(today_wo, Exception):
                base_state["current_workout"] = today_wo
            base_state["context_partial"] = any(
                isinstance(r, Exception) for r in (daily_ctx, favs, today_wo)
            )
            if base_state["context_partial"]:
                for label, val in (("daily_ctx", daily_ctx), ("favs", favs), ("today_wo", today_wo)):
                    if isinstance(val, Exception):
                        logger.warning(
                            f"[NutritionContext] {label} pre-fetch failed: {val}"
                        )

            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.WORKOUT:
            base_state["current_workout"] = request.current_workout.model_dump() if request.current_workout else None
            base_state["workout_schedule"] = request.workout_schedule.model_dump() if request.workout_schedule else None
            base_state["extracted_exercises"] = extraction_data.get("exercises", [])
            base_state["extracted_muscle_groups"] = extraction_data.get("muscle_groups", [])
            base_state["modification"] = extraction_data.get("modification")
            base_state["media_ref"] = request.media_ref.model_dump() if hasattr(request, "media_ref") and request.media_ref else None
            base_state["media_refs"] = media_refs_dicts
            base_state["video_frames"] = getattr(request, "video_frames", None)
            base_state["beast_mode_config"] = beast_mode_config
            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.INJURY:
            base_state["body_part"] = extraction_data.get("body_part")
            base_state["tool_calls"] = []
            base_state["tool_results"] = []
            base_state["tool_messages"] = []
            base_state["messages"] = []

        elif agent_type == AgentType.HYDRATION:
            base_state["hydration_amount"] = extraction_data.get("hydration_amount")

        elif agent_type == AgentType.COACH:
            base_state["current_workout"] = request.current_workout.model_dump() if request.current_workout else None
            base_state["workout_schedule"] = request.workout_schedule.model_dump() if request.workout_schedule else None
            base_state["setting_name"] = extraction_data.get("setting_name")
            base_state["setting_value"] = extraction_data.get("setting_value")
            base_state["destination"] = extraction_data.get("destination")
            base_state["water_goal_glasses"] = extraction_data.get("water_goal_glasses")
            base_state["weight_value"] = extraction_data.get("weight_value")
            base_state["image_base64"] = request.image_base64
            base_state["media_ref"] = request.media_ref.model_dump() if hasattr(request, "media_ref") and request.media_ref else None
            base_state["media_refs"] = media_refs_dicts

        return base_state

    async def process_message(self, request: ChatRequest) -> ChatResponse:
        """
        Process a user message using dedicated domain agents.

        Flow:
        0. Fast-path for simple messages (greetings, thanks, goodbye)
        1. Detect @mention
        2. Extract intent
        3. Get RAG context
        4. Select appropriate agent
        5. Build agent state
        6. Execute agent
        7. Return response
        """
        logger.info(f"Processing message: {request.message[:50]}...")

        try:
            # 0. Validate media limits (per-request)
            all_media = getattr(request, "media_refs", None) or []
            if not all_media and getattr(request, "media_ref", None):
                all_media = [request.media_ref]
            if all_media:
                self._validate_media_request(all_media)
                await self._check_media_usage(request.user_id, len(all_media))

            # 1. Detect @mention and sanitize against prompt injection
            mentioned_agent, cleaned_message = self._detect_agent_mention(request.message)
            cleaned_message = self._sanitize_user_message(cleaned_message)

            # 1a. True fast-path for trivial greetings/thanks/goodbyes — return
            # a canned friendly reply WITHOUT invoking Gemini. Cuts the worst
            # 68s outliers seen in the wild down to <100ms. Only triggers when
            # there's no media and no @mention, so anything substantive still
            # goes through the full pipeline.
            all_media_for_fastpath = (
                getattr(request, "media_refs", None)
                or ([getattr(request, "media_ref", None)] if getattr(request, "media_ref", None) else [])
            )
            if (
                mentioned_agent is None
                and not all_media_for_fastpath
                and not getattr(request, "image_base64", None)
                and not getattr(request, "video_frames", None)
                and _is_trivial_message(cleaned_message)
            ):
                trivial_reply = self._fast_trivial_reply(cleaned_message)
                logger.info(f"Trivial fast-path hit for message: {cleaned_message[:30]!r}")
                return ChatResponse(
                    message=trivial_reply,
                    intent=CoachIntent.QUESTION,
                    agent_type=AgentType.COACH,
                    action_data=None,
                    rag_context_used=False,
                    similar_questions=[],
                )

            # 2. Compute media signals (sync — no I/O)
            has_image = request.image_base64 is not None
            has_video = False
            has_multi_images = False
            has_multi_videos = False

            if hasattr(request, "media_ref") and request.media_ref:
                if request.media_ref.media_type == "video":
                    has_video = True
                elif request.media_ref.media_type == "image":
                    has_image = True

            if hasattr(request, "media_refs") and request.media_refs:
                image_refs = [r for r in request.media_refs if r.media_type == "image"]
                video_refs = [r for r in request.media_refs if r.media_type == "video"]
                if len(image_refs) > 1:
                    has_multi_images = True
                    has_image = True
                if len(video_refs) > 1:
                    has_multi_videos = True
                    has_video = True
                if len(image_refs) == 1:
                    has_image = True
                if len(video_refs) == 1:
                    has_video = True

            # Also treat inline video or pre-extracted frames as video media signals
            if getattr(request, "video_frames", None):
                has_video = True

            has_media = has_image or has_video or has_multi_images or has_multi_videos

            # 3. Run intent extraction and media classification in parallel.
            #    RAG is skipped for media messages — the image/video IS the content;
            #    past Q&A and training settings add latency with no benefit for vision tasks.
            #    RAG is also skipped for trivial greetings/thanks/goodbyes — ChromaDB
            #    Cloud cold queries can take 5-13s with no useful context for "hi".
            skip_rag = has_media or _is_trivial_message(cleaned_message)
            if has_media:
                (intent, extraction_data), media_content_type = await asyncio.gather(
                    self._extract_intent(cleaned_message, user_id=request.user_id),
                    self._classify_media(request),
                )
                rag_context, rag_used, similar_questions = "", False, []
            elif skip_rag:
                intent, extraction_data = await self._extract_intent(
                    cleaned_message, user_id=request.user_id,
                )
                rag_context, rag_used, similar_questions = "", False, []
                media_content_type = None
                logger.info("Skipped RAG for trivial message")
            else:
                (intent, extraction_data), (rag_context, rag_used, similar_questions) = \
                    await asyncio.gather(
                        self._extract_intent(cleaned_message, user_id=request.user_id),
                        self._get_rag_context(cleaned_message, request.user_id),
                    )
                media_content_type = None
            logger.info(f"Extracted intent: {intent.value}")

            selected_agent = self._select_agent(
                mentioned_agent, intent, cleaned_message, has_image,
                has_video=has_video,
                has_multi_images=has_multi_images,
                has_multi_videos=has_multi_videos,
                media_content_type=media_content_type,
                agent_override=request.agent_override,
            )
            logger.info(f"Selected agent: {selected_agent.value}")

            # 4b. Fetch beast mode config from Supabase (if workout agent)
            beast_mode_config = None
            if selected_agent == AgentType.WORKOUT:
                try:
                    supabase = get_supabase().client
                    bm_result = supabase.table("user_settings").select(
                        "beast_mode_config"
                    ).eq("user_id", request.user_id).maybe_single().execute()
                    if bm_result and bm_result.data and bm_result.data.get("beast_mode_config"):
                        beast_mode_config = bm_result.data["beast_mode_config"]
                        logger.info(f"Beast mode config loaded for user {request.user_id}")
                except Exception as bm_err:
                    logger.warning(f"Failed to fetch beast mode config: {bm_err}", exc_info=True)

            # 5. Build agent state
            agent_state = await self._build_agent_state(
                selected_agent,
                request,
                cleaned_message,
                intent,
                extraction_data,
                rag_context,
                rag_used,
                similar_questions,
                beast_mode_config=beast_mode_config,
                media_content_type=media_content_type,
            )

            # 6. Execute agent with retry for thought_signature errors
            # Apply concurrency semaphore for nutrition vision calls
            use_nutrition_semaphore = (
                selected_agent == AgentType.NUTRITION
                and (has_image or has_multi_images)
            )

            agent_graph = self.agents[selected_agent]
            start_time = time.time()

            async def _run_agent():
                return await asyncio.wait_for(
                    agent_graph.ainvoke(agent_state),
                    timeout=120.0,
                )

            try:
                if use_nutrition_semaphore:
                    async with _NUTRITION_SEMAPHORE:
                        final_state = await _run_agent()
                else:
                    final_state = await _run_agent()
            except asyncio.TimeoutError:
                logger.error(f"Agent {selected_agent.value} timed out after 120s", exc_info=True)
                raise Exception(f"AI agent timed out. Please try again.")
            except Exception as agent_error:
                error_msg = str(agent_error).lower()
                if "thought_signature" in error_msg or "function call is missing" in error_msg:
                    logger.warning(f"Thought signature error with {selected_agent.value} agent, retrying with fresh state...", exc_info=True)
                    # Clear any cached message state and retry once
                    if "messages" in agent_state:
                        agent_state["messages"] = []
                    try:
                        if use_nutrition_semaphore:
                            async with _NUTRITION_SEMAPHORE:
                                final_state = await _run_agent()
                        else:
                            final_state = await _run_agent()
                    except asyncio.TimeoutError:
                        logger.error(f"Agent {selected_agent.value} retry timed out after 120s", exc_info=True)
                        raise Exception(f"AI agent timed out on retry. Please try again.")
                    except Exception as retry_error:
                        logger.error(f"Retry also failed: {retry_error}", exc_info=True)
                        raise retry_error
                else:
                    raise
            elapsed = time.time() - start_time
            logger.info(f"Agent {selected_agent.value} completed in {elapsed:.1f}s")

            # 7. Build response
            action_data = final_state.get("action_data")
            logger.info(f"[LangGraph Service] Agent returned action_data: {action_data}")

            raw_response = final_state.get("final_response", "I'm sorry, I couldn't process your request.")
            message_str = _ensure_str(raw_response)
            if not message_str.strip():
                message_str = "I'm sorry, I couldn't generate a response. Could you try rephrasing?"
            response = ChatResponse(
                message=message_str,
                intent=intent,
                agent_type=selected_agent,
                action_data=action_data,
                rag_context_used=final_state.get("rag_context_used", rag_used),
                similar_questions=final_state.get("similar_questions", similar_questions),
            )

            logger.info(f"Response: intent={intent.value}, agent={selected_agent.value}, action_data={action_data is not None}")
            return response

        except Exception as e:
            logger.error(f"Agent execution failed: {e}", exc_info=True)
            raise
