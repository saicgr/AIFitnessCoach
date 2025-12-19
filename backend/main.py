"""
AI Fitness Coach Backend - Main Entry Point

Local development:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

AWS Lambda deployment:
    Deployed via Terraform with Mangum adapter (see lambda_handler.py)
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import uvicorn
import time
import traceback

from core.config import get_settings
from core.logger import get_logger
from api.v1 import router as v1_router
from api.v1 import chat as chat_module
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.langgraph_service import LangGraphCoachService
from services.exercise_rag_service import get_exercise_rag_service
from services.job_queue_service import get_job_queue_service

settings = get_settings()
logger = get_logger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log all requests and responses."""

    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        method = request.method
        path = request.url.path
        query = str(request.query_params) if request.query_params else ""

        # Log request
        log_msg = f"Request: {method} {path}"
        if query:
            log_msg += f"?{query}"
        logger.info(log_msg)

        # Process request
        try:
            response = await call_next(request)
            duration = (time.time() - start_time) * 1000

            # Log response
            if response.status_code < 400:
                logger.info(f"Response: {response.status_code} ({duration:.0f}ms)")
            else:
                logger.warning(f"Response: {response.status_code} ({duration:.0f}ms)")

            return response

        except Exception as e:
            duration = (time.time() - start_time) * 1000
            logger.error(f"Request failed: {type(e).__name__}: {str(e)} ({duration:.0f}ms)")
            raise


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown events.
    Initializes services on startup, cleans up on shutdown.
    """
    logger.info("Starting AI Fitness Coach Backend...")
    logger.info(f"🤖 Gemini Model: {settings.gemini_model}")
    logger.info(f"📊 Embedding Model: {settings.gemini_embedding_model}")

    # Initialize services
    logger.info("Initializing Gemini service...")
    chat_module.gemini_service = GeminiService()

    logger.info("Initializing RAG service...")
    chat_module.rag_service = RAGService(chat_module.gemini_service)

    logger.info("Initializing LangGraph Coach service...")
    chat_module.langgraph_coach_service = LangGraphCoachService()

    # Auto-index exercises for RAG if not already indexed
    logger.info("Checking Exercise RAG index (Chroma Cloud)...")
    try:
        exercise_rag = get_exercise_rag_service()
        stats = exercise_rag.get_stats()
        indexed_count = stats.get("total_exercises", 0)

        if indexed_count == 0:
            logger.info("🔄 No exercises indexed in Chroma Cloud. Starting auto-indexing...")
            indexed = await exercise_rag.index_all_exercises()
            logger.info(f"✅ Auto-indexed {indexed} exercises to Chroma Cloud")
        else:
            logger.info(f"✅ Exercise RAG ready with {indexed_count} exercises in Chroma Cloud")
    except Exception as e:
        logger.error(f"⚠️ Failed to initialize Exercise RAG: {e}")
        logger.error("Workouts will fall back to AI-generated exercises")

    logger.info("All services initialized (LangGraph agents ready)")

    # Check for pending workout generation jobs and resume them
    logger.info("Checking for pending workout generation jobs...")
    try:
        job_queue = get_job_queue_service()

        # First, cancel any stale jobs (older than 24 hours)
        job_queue.cancel_stale_jobs(older_than_hours=24)

        # Get pending jobs to resume
        pending_jobs = job_queue.get_pending_jobs()

        if pending_jobs:
            logger.info(f"🔄 Found {len(pending_jobs)} pending workout generation jobs to resume")

            # Import the background generation function
            from api.v1.workouts_db import _run_background_generation
            import asyncio

            for job in pending_jobs:
                job_id = job.get("id")
                user_id = job.get("user_id")
                status = job.get("status")

                logger.info(f"  - Resuming job {job_id} for user {user_id} (status: {status})")

                # Create an async task to resume the job
                asyncio.create_task(
                    _run_background_generation(
                        job_id=str(job_id),
                        user_id=str(user_id),
                        month_start_date=str(job.get("month_start_date")),
                        duration_minutes=job.get("duration_minutes", 45),
                        selected_days=job.get("selected_days", [0, 2, 4]),
                        weeks=job.get("weeks", 11)
                    )
                )
        else:
            logger.info("✅ No pending workout generation jobs")

    except Exception as e:
        logger.error(f"⚠️ Failed to check/resume pending jobs: {e}")
        # Don't fail startup if job recovery fails

    logger.info(f"Server running at http://{settings.host}:{settings.port}")
    logger.info(f"API docs at http://{settings.host}:{settings.port}/docs")

    yield

    # Cleanup on shutdown
    logger.info("Shutting down...")


# Create FastAPI app
app = FastAPI(
    title="AI Fitness Coach API",
    description="""
    Backend API for the AI Fitness Coach mobile app.

    ## Features
    - AI-powered fitness coaching with GPT-4
    - RAG (Retrieval Augmented Generation) for improved responses over time
    - Workout modifications based on natural language

    ## Quick Start
    1. POST /api/v1/chat/send - Send a message to the AI coach
    2. GET /api/v1/chat/rag/stats - Check RAG system status
    3. POST /api/v1/chat/rag/search - Search similar past conversations
    """,
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add logging middleware
app.add_middleware(LoggingMiddleware)

# Include API routes
app.include_router(v1_router, prefix="/api")


@app.get("/")
async def root():
    """Root endpoint - basic info."""
    return {
        "service": "AI Fitness Coach Backend",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/api/v1/health/",
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
