"""
Zealova Backend - Main Entry Point

Local development:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

AWS Lambda deployment:
    Deployed via Terraform with Mangum adapter (see lambda_handler.py)
"""
import os
from typing import Optional
from contextlib import asynccontextmanager
from datetime import datetime
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.gzip import GZipMiddleware
from starlette.types import ASGIApp, Receive, Scope, Send
from slowapi.errors import RateLimitExceeded
from core.rate_limiter import structured_rate_limit_handler
from slowapi.middleware import SlowAPIMiddleware  # noqa: F401  (kept for type/back-compat)
from core.rate_limiter import SafeSlowAPIMiddleware
import asyncio
import logging
import re
import uvicorn
import time
import traceback
import uuid
import json

from core import branding
from core.config import get_settings
from core.logger import get_logger, set_log_context, clear_log_context
from core.rate_limiter import limiter
from core.redis_cache import init_redis, close_redis, ping_redis
from core.metrics import request_metrics as _request_metrics

# Bound function for the metrics middleware hot path — avoids an attribute
# lookup per request.
_record_request_metric = _request_metrics.record
from api.v1 import router as v1_router
from api.v1 import chat as chat_module
# Phase B: multi-day program-template importer router. Mounted explicitly at
# /api/v1/program-templates (kept out of api/v1/__init__.py per the Phase B
# exclusive-file split).
from api.v1.program_templates import router as program_templates_router
from services.gemini_service import GeminiService
from services.rag_service import RAGService
from services.langgraph_service import LangGraphCoachService
from services.exercise_rag_service import get_exercise_rag_service
from services.job_queue_service import get_job_queue_service

settings = get_settings()
logger = get_logger(__name__)


# Suppress Render LB health-check noise from uvicorn's access log.
# Render hits `GET /` from three internal IPs every few seconds; those lines
# (`INFO:  34.x.x.x:0 - "GET / HTTP/1.1" 200 OK`) flood prod logs and bury
# real signal. The structured request logger already silences `/` via
# `_SILENT_GET_PATHS`; this mirrors the same suppression at the uvicorn layer.
class _HealthCheckAccessLogFilter(logging.Filter):
    _PATTERNS = ('"GET / HTTP', '"HEAD / HTTP')

    def filter(self, record: logging.LogRecord) -> bool:
        try:
            msg = record.getMessage()
        except Exception:
            return True
        return not any(p in msg for p in self._PATTERNS)


logging.getLogger("uvicorn.access").addFilter(_HealthCheckAccessLogFilter())

# Dev log dashboard — only available when debug=True
_dev_log_push = None
if settings.debug:
    from api.dev_logs import push_log_entry as _dev_log_push

# Lazy-initialized service holders for non-critical services
_langgraph_service = None


class SecurityHeadersMiddleware:
    """Pure ASGI middleware to add security headers to all responses."""

    HEADERS = [
        (b"x-content-type-options", b"nosniff"),
        (b"x-frame-options", b"DENY"),
        (b"x-xss-protection", b"1; mode=block"),
        (b"strict-transport-security", b"max-age=31536000; includeSubDomains"),
        (b"content-security-policy", b"default-src 'self'"),
        (b"referrer-policy", b"strict-origin-when-cross-origin"),
    ]

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        async def send_with_headers(message):
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.extend(self.HEADERS)
                message = {**message, "headers": headers}
            await send(message)

        await self.app(scope, receive, send_with_headers)


class _PathPrefixDedupMiddleware:
    """Strip accidental `/api/v1/api/v1/...` duplication in request paths.

    A small number of clients (background widget refresh, retried Workmanager
    jobs) produce double-prefixed URLs when Dio's baseUrl + relative-path
    merge double-stamps `/api/v1/`. Rather than chasing every caller, normalize
    at the edge so the route table still matches. Logs each rewrite at INFO so
    the source can still be traced.
    """

    _DUP = "/api/v1/api/v1/"

    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] == "http":
            raw_path = scope.get("raw_path") or scope.get("path", "").encode()
            try:
                path_str = scope.get("path", "")
                if path_str.startswith(self._DUP):
                    fixed = "/api/v1/" + path_str[len(self._DUP):]
                    logger.info(
                        f"[PathDedup] Rewrote doubled prefix: {path_str} -> {fixed}"
                    )
                    scope = {**scope, "path": fixed, "raw_path": fixed.encode()}
            except Exception:
                # Never break the request on a normalisation hiccup.
                pass
        await self.app(scope, receive, send)


class BodySizeLimitMiddleware:
    """Pure ASGI middleware that rejects requests whose Content-Length exceeds `max_bytes`.

    Why ASGI instead of @app.middleware("http"):
      @app.middleware("http") is implemented via Starlette's BaseHTTPMiddleware, which
      runs the downstream app inside an anyio TaskGroup. For StreamingResponse endpoints
      (e.g. POST /api/v1/workouts/generate-stream), a client disconnect mid-stream can
      cancel the task before the response object is yielded, surfacing as
      `RuntimeError: No response returned.` in the logs. A pure-ASGI middleware passes
      send/receive straight through — no TaskGroup, no race.
    """

    def __init__(self, app: ASGIApp, max_bytes: int):
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Content-Length is optional (chunked transfer has none); only enforce when present.
        content_length: Optional[str] = None
        for name, value in scope.get("headers", ()):
            if name == b"content-length":
                content_length = value.decode("latin-1")
                break

        if content_length is not None:
            try:
                if int(content_length) > self.max_bytes:
                    body = json.dumps({"detail": "Request body too large (max 20MB)"}).encode()
                    await send({
                        "type": "http.response.start",
                        "status": 413,
                        "headers": [
                            (b"content-type", b"application/json"),
                            (b"content-length", str(len(body)).encode()),
                        ],
                    })
                    await send({"type": "http.response.body", "body": body})
                    return
            except ValueError:
                # Malformed Content-Length — let the app handle it (will 400 downstream).
                pass

        await self.app(scope, receive, send)


class LoggingMiddleware:
    """Pure ASGI middleware to log all requests and responses with user context.

    Extracts user_id from query parameters and path segments (UUID pattern).
    Sets request_id for tracing a single request through the system.
    """

    # Pre-compiled UUID pattern for extracting user_id from path segments
    _UUID_RE = re.compile(
        r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
        re.IGNORECASE,
    )

    # Paths hit by infra (Render health checks, uptime monitors, browsers
    # requesting icons). Successful GETs on these are suppressed from INFO
    # logs to keep the stream readable; failures still log at WARN/ERROR.
    _SILENT_GET_PATHS = frozenset({
        "/",
        "/health",
        "/favicon.ico",
        "/robots.txt",
        "/apple-touch-icon.png",
        "/apple-touch-icon-precomposed.png",
    })

    # Automated vulnerability scanners constantly probe every public host for
    # exposed secrets/configs (`.env`, `phpinfo.php`, `.git/config`, framework
    # configs, CI/mail-provider keys). We correctly 404 them all, but each probe
    # otherwise emits an INFO + WARNING line — hundreds per scan — drowning real
    # logs. Detect the unambiguous probe shapes and short-circuit with a bare
    # 404, skipping logging AND routing. This is log hygiene only: the security
    # posture is unchanged (these files never existed). Conservative by design —
    # our real API lives under /api/, /dev/, /docs, /static/, and the
    # /.well-known/* deep-link files, none of which match these tokens.
    _SCANNER_PROBE_RE = re.compile(
        r"(?:"
        r"\.env\b|\.env[.~]|/\.env|"          # .env and all its variants
        r"/\.git|/\.aws|/\.ssh|/\.svn|/\.hg|/\.docker|"  # VCS / cloud cred dirs
        r"\.php\b|\.asp\b|\.aspx\b|\.jsp\b|"   # server-script probes
        r"\.py\b|\.rb\b|\.pl\b|\.cgi\b|\.sh\b|"  # other server-script probes
        r"\.bak\b|\.old\b|\.swp\b|\.orig\b|\.save\b|"  # editor/backup leftovers
        r"\.ya?ml\b|\.ini\b|\.conf\b|\.config\b|\.json\b|\.js\b|\.sql\b|"  # config/source probes
        r"/config/|/app/config/|composer|appsettings|docker-compose|parameters|"  # framework configs
        r"phpinfo|wp-config|wp-admin|wp-login|xmlrpc|"  # WordPress/PHP
        r"/server-status|/server-info"        # Apache mod_status
        r")",
        re.IGNORECASE,
    )

    def __init__(self, app: ASGIApp):
        self.app = app

    # Real non-/api endpoints that would otherwise match a probe token
    # (/openapi.json ends in .json but is the live OpenAPI schema).
    _PROBE_ALLOWLIST = frozenset({
        "/openapi.json", "/docs", "/redoc", "/docs/oauth2-redirect",
    })

    @classmethod
    def _is_scanner_probe(cls, path: str) -> bool:
        # Never short-circuit our own surfaces or the API docs.
        if path.startswith(("/api/", "/dev/", "/static/", "/.well-known/")):
            return False
        if path in cls._PROBE_ALLOWLIST:
            return False
        return bool(cls._SCANNER_PROBE_RE.search(path))

    @staticmethod
    async def _send_bare_404(send: Send) -> None:
        await send({
            "type": "http.response.start",
            "status": 404,
            "headers": [(b"content-type", b"application/json")],
        })
        await send({
            "type": "http.response.body",
            "body": b'{"detail":"Not Found"}',
        })

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        start_time = time.time()
        request = Request(scope)
        method = request.method
        path = request.url.path
        query = str(request.query_params) if request.query_params else ""

        # Drop vulnerability-scanner probes silently (404, no log line, no
        # routing). Keeps the log stream readable; security posture unchanged.
        if self._is_scanner_probe(path):
            await self._send_bare_404(send)
            return

        # Generate unique request ID for tracing
        request_id = str(uuid.uuid4())[:8]

        # Extract user_id: prefer query param, fall back to first UUID in path
        raw_user_id = request.query_params.get("user_id")
        if not raw_user_id:
            # Many endpoints use /{user_id}/resource pattern
            match = self._UUID_RE.search(path)
            if match:
                raw_user_id = match.group(0)
        user_id = f"...{raw_user_id[-4:]}" if raw_user_id and len(raw_user_id) > 4 else raw_user_id

        # Set logging context for this request
        set_log_context(user_id=user_id, request_id=request_id)

        # Mirror the logging context into Sentry's isolation scope so any
        # exception raised during this request carries request_id, endpoint,
        # method, query string, and user_id as searchable tags. Without this
        # Sentry only showed the transaction name ("api.v1.foo") — not the
        # parameters that made THIS request fail.
        sentry_set_request_context(
            request_id=request_id,
            method=method,
            path=path,
            query=query,
            user_agent=request.headers.get("user-agent"),
        )
        if raw_user_id:
            sentry_set_user(raw_user_id)

        is_silent = method == "GET" and path in self._SILENT_GET_PATHS

        # Log request
        log_msg = f"{method} {path}"
        if query:
            log_msg += f"?{query}"
        if not is_silent:
            logger.info(log_msg)

        status_code = 500  # default in case send never called

        async def send_with_logging(message):
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                # Inject X-Request-ID header
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode()))
                message = {**message, "headers": headers}
            await send(message)

        try:
            await self.app(scope, receive, send_with_logging)
            duration = (time.time() - start_time) * 1000
            if status_code < 400:
                if not is_silent:
                    logger.info(f"Response: {status_code} ({duration:.0f}ms)")
            elif status_code >= 500:
                logger.error(f"Response: {status_code} ({duration:.0f}ms)")
            else:
                # 4xx (including 404) — surface as WARNING unconditionally.
                # Silent paths (_SILENT_GET_PATHS) only suppress 2xx health-
                # check noise; a 404 anywhere, even on "/", must be visible
                # so misrouted clients and broken deep links don't hide.
                logger.warning(f"Response: {status_code} ({duration:.0f}ms)")
            # Push to dev log dashboard (no-op if not imported)
            if _dev_log_push is not None and not path.startswith("/dev/"):
                _dev_log_push(
                    method=method, path=path, status_code=status_code,
                    duration_ms=duration, user_id=user_id,
                    request_id=request_id, query=query,
                )
        except Exception as e:
            duration = (time.time() - start_time) * 1000
            logger.error(f"Request failed: {type(e).__name__}: {str(e)} ({duration:.0f}ms)", exc_info=True)
            if _dev_log_push is not None and not path.startswith("/dev/"):
                _dev_log_push(
                    method=method, path=path, status_code=500,
                    duration_ms=duration, user_id=user_id,
                    request_id=request_id, query=query,
                    error=f"{type(e).__name__}: {str(e)}",
                )
            raise
        finally:
            clear_log_context()
            sentry_clear_request_context()


class MetricsMiddleware:
    """Pure ASGI middleware that records per-route latency + status (Phase D4).

    Records into the process-wide `request_metrics` registry so the admin
    observability endpoint can surface p50/p95/p99 + request count + error
    rate per endpoint.

    Hot-path cost: one `time.perf_counter()` pair, one deque append and two
    int increments per request — no disk, no network, no blocking.

    Route label = the matched path TEMPLATE (`/api/v1/home/bootstrap`), NOT
    the raw path with ids. Starlette's router writes the matched `APIRoute`
    onto `scope["route"]` during routing; since `scope` is a shared mutable
    dict, it is populated by the time `self.app(...)` returns. Requests that
    match no route (404s, OPTIONS preflight misses, mounted sub-apps) fall
    back to a small set of fixed labels so they cannot explode cardinality.
    """

    # Pure-ASGI middleware is wrapped OUTSIDE the router, so it also sees
    # requests to mounted sub-apps (/mcp, /static) — bucket those coarsely.
    def __init__(self, app: ASGIApp):
        self.app = app

    def _route_label(self, scope: Scope) -> str:
        route = scope.get("route")
        if route is not None:
            # APIRoute / Route expose `.path` = the template with {placeholders}.
            path_format = getattr(route, "path_format", None) or getattr(route, "path", None)
            if path_format:
                return path_format
        # No matched route — Mount sub-apps and 404s land here.
        raw = scope.get("path", "") or ""
        if raw.startswith("/mcp"):
            return "<mcp>"
        if raw.startswith("/static"):
            return "<static>"
        return "<unmatched>"

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        start = time.perf_counter()
        status_code = 500  # default if the app never sends a response.start

        async def send_with_metrics(message):
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
            await send(message)

        try:
            await self.app(scope, receive, send_with_metrics)
        except Exception:
            # Exception escaped downstream — record as a 500 then re-raise so
            # the existing exception handlers still run.
            duration_ms = (time.perf_counter() - start) * 1000
            try:
                _record_request_metric(self._route_label(scope), duration_ms, 500)
            except Exception:
                pass
            raise
        else:
            duration_ms = (time.perf_counter() - start) * 1000
            try:
                _record_request_metric(self._route_label(scope), duration_ms, status_code)
            except Exception:
                # Metrics must never break a request.
                pass


async def _init_rag_service():
    """Initialize RAG service (depends on Gemini service being ready)."""
    logger.info("Initializing RAG service...")
    t = time.time()
    chat_module.rag_service = RAGService(chat_module.gemini_service)
    logger.info(f"RAG service initialized in {time.time() - t:.2f}s")


async def _init_langgraph_service():
    """Initialize LangGraph Coach service."""
    logger.info("Initializing LangGraph Coach service...")
    t = time.time()
    chat_module.langgraph_coach_service = LangGraphCoachService()
    logger.info(f"LangGraph Coach service initialized in {time.time() - t:.2f}s")


async def _init_cache_manager():
    """Initialize Gemini Context Cache Manager."""
    if settings.gemini_cache_enabled:
        logger.info("Initializing Gemini Context Cache Manager...")
        t = time.time()
        try:
            await GeminiService.initialize_cache_manager()
            logger.info(f"Gemini Context Cache Manager ready in {time.time() - t:.2f}s")
        except Exception as e:
            logger.warning(f"Failed to initialize cache manager: {e}", exc_info=True)
            logger.warning("Workout generation will use non-cached mode", exc_info=True)
    else:
        logger.info("Gemini Context Caching disabled (GEMINI_CACHE_ENABLED=false)")


async def _init_equipment_resolver():
    """Pre-load the equipment alias/substitution resolver so the RAG filter
    can use it synchronously. Without this, `EquipmentResolver._instance`
    stays None and `filter_by_equipment(use_substitutions=True)` skips the
    alias chain (e.g. TRX → Suspension Trainer doesn't resolve)."""
    logger.info("Initializing EquipmentResolver (alias + substitution cache)...")
    t = time.time()
    try:
        from services.equipment_resolver import EquipmentResolver
        await EquipmentResolver.get_instance()
        logger.info(f"EquipmentResolver ready in {time.time() - t:.2f}s")
    except Exception as e:
        logger.warning(f"EquipmentResolver init failed (alias path will no-op): {e}", exc_info=True)


async def _warm_workout_rag():
    """Instantiate the WorkoutRAGService singletons at startup.

    Their __init__ does blocking Chroma `count()` calls — in the 2026-05-16
    incident 'Workout RAG initialized: 361 workouts' fired *inside* a
    /workouts/today request, adding ~1s of blocking work to the response.
    Warming them here (off the event loop) keeps that out of the hot path.
    Non-fatal: a warm failure just means the first request pays the cost.
    """
    logger.info("Warming Workout RAG singletons...")
    t = time.time()
    for label, importer in (
        ("workouts.utils", "api.v1.workouts.utils"),
        ("workouts_db_helpers", "api.v1.workouts_db_helpers"),
    ):
        try:
            import importlib
            factory = getattr(importlib.import_module(importer), "get_workout_rag_service")
            await asyncio.to_thread(factory)
        except Exception as e:
            logger.warning(f"Workout RAG warm ({label}) failed: {e}", exc_info=True)
    logger.info(f"Workout RAG warmed in {time.time() - t:.2f}s")


async def _prewarm_chroma_connection():
    """Establish the Chroma Cloud connection/pool with ONE tiny warm-up query.

    The first real AI-coach RAG query (`RAGService.find_similar`) otherwise pays
    the cold-connection cost — TLS handshake + httpx pool setup to Chroma Cloud —
    on top of its own latency. Issuing a single cheap query here, off the hot
    path, primes that connection so the first user query is warm.

    Deliberately CONSERVATIVE: one minimal query (n_results=1, no user data, no
    preload of any dataset), run off the event loop because the underlying
    ChromaHTTPCollection call is blocking httpx. Fire-and-forget and fully
    wrapped in try/except — a warm-up failure must never affect startup or any
    request; the worst case is just that the first real query pays the old cold
    cost. Mirrors the non-fatal pattern of _warm_workout_rag.
    """
    logger.info("Pre-warming Chroma Cloud connection (single ping query)...")
    t = time.time()
    try:
        rag = chat_module.rag_service
        if rag is None:
            logger.warning("Chroma pre-warm skipped: RAG service not initialized")
            return
        # One tiny similarity query just to force the connection/pool to open.
        # No user_id filter, n_results=1 — minimal work on the Chroma side.
        await rag.find_similar(query="warmup", n_results=1)
        logger.info(f"Chroma Cloud connection pre-warmed in {time.time() - t:.2f}s")
    except Exception as e:
        # Non-fatal by design — never raise, never block startup.
        logger.warning(f"Chroma connection pre-warm failed (first query will be cold): {e}", exc_info=True)


async def _check_exercise_rag_index():
    """Check and auto-index exercises for RAG (can run after server starts)."""
    logger.info("Checking Exercise RAG index (Chroma Cloud)...")
    try:
        exercise_rag = get_exercise_rag_service()
        stats = exercise_rag.get_stats()
        indexed_count = stats.get("total_exercises", 0)

        if indexed_count == 0:
            logger.info("No exercises indexed in Chroma Cloud. Starting auto-indexing...")
            indexed = await exercise_rag.index_all_exercises()
            logger.info(f"Auto-indexed {indexed} exercises to Chroma Cloud")
        else:
            logger.info(f"Exercise RAG ready with {indexed_count} exercises in Chroma Cloud")
    except Exception as e:
        logger.error(f"Failed to initialize Exercise RAG: {e}", exc_info=True)
        logger.error("Workouts will fall back to AI-generated exercises", exc_info=True)


async def _check_chromadb_dimensions():
    """Check ChromaDB embedding dimensions and auto-heal mismatches."""
    logger.info("Checking ChromaDB embedding dimensions...")
    try:
        from core.chroma_cloud import get_chroma_cloud_client
        chroma_client = get_chroma_cloud_client()
        dim_check = chroma_client.check_embedding_dimensions(expected_dim=768)

        if dim_check["healthy"]:
            logger.info("ChromaDB embedding dimensions OK (768-dim Gemini embeddings)")
        else:
            logger.warning("ChromaDB dimension mismatch detected — auto-healing...")
            for m in dim_check["mismatches"]:
                name = m["name"]
                logger.warning(f"   Deleting {name} (has {m['actual_dim']} dims, expected {m['expected_dim']})")
                try:
                    chroma_client.delete_collection(name)
                    logger.info(f"   Recreated {name} (will repopulate with 768-dim on next use)")
                except Exception as del_err:
                    logger.error(f"   Failed to delete {name}: {del_err}", exc_info=True)
    except Exception as e:
        logger.warning(f"Could not check ChromaDB dimensions: {e}", exc_info=True)


async def _resume_pending_jobs():
    """Resume pending workout generation jobs (can run after server starts)."""
    logger.info("Checking for pending workout generation jobs...")
    try:
        job_queue = get_job_queue_service()

        # First, cancel any stale jobs (older than 24 hours)
        job_queue.cancel_stale_jobs(older_than_hours=24)

        # Get pending jobs to resume
        pending_jobs = job_queue.get_pending_jobs()

        if pending_jobs:
            logger.info(f"Found {len(pending_jobs)} pending workout generation jobs to resume")

            # Import the background generation function
            from api.v1.workouts_db import _run_background_generation

            for job in pending_jobs:
                job_id = job.get("id")
                user_id = job.get("user_id")
                status = job.get("status")

                truncated_uid = f"...{user_id[-4:]}" if user_id and len(str(user_id)) > 4 else user_id
                logger.info(f"  - Resuming job {job_id} for user {truncated_uid} (status: {status})")

                # Create an async task to resume the job
                _create_safe_task(
                    _run_background_generation(
                        job_id=str(job_id),
                        user_id=str(user_id),
                        month_start_date=str(job.get("month_start_date")),
                        duration_minutes=job.get("duration_minutes", 45),
                        selected_days=job.get("selected_days", [0, 2, 4])
                    ),
                    name=f"resume-job-{job_id}",
                    user_id=truncated_uid,
                )
        else:
            logger.info("No pending workout generation jobs")

    except Exception as e:
        logger.error(f"Failed to check/resume pending jobs: {e}", exc_info=True)
        # Don't fail startup if job recovery fails


async def _resume_pending_media_jobs():
    """Resume pending media analysis jobs on server startup."""
    try:
        from services.media_job_runner import resume_pending_media_jobs
        await resume_pending_media_jobs()
    except Exception as e:
        logger.error(f"Failed to resume pending media jobs: {e}", exc_info=True)


async def _prewarm_inflammation_cache():
    """Pre-warm the ingredient inflammation food_database cache on startup.

    Calls _ensure_food_db_cache() which does a paginated Supabase scan over
    the full food_database table — synchronous network calls inside an async
    coroutine that block the event loop, preventing uvicorn from completing
    its socket bind in local dev (Render Pro is OK because gunicorn pre-binds).
    Set SKIP_INFLAMMATION_PREWARM=1 in local-dev .env to skip.
    """
    if os.environ.get("SKIP_INFLAMMATION_PREWARM") == "1":
        logger.info("Skipping inflammation cache pre-warm (SKIP_INFLAMMATION_PREWARM=1)")
        return
    try:
        from services.ingredient_inflammation.lookup import _ensure_food_db_cache
        # Wrap the sync-DB-heavy loader in to_thread so it doesn't block the
        # event loop while uvicorn is trying to finish lifespan + bind socket.
        cache = await asyncio.to_thread(asyncio.run, _ensure_food_db_cache())
        logger.info(f"Pre-warmed inflammation cache with {len(cache)} entries")
    except Exception as e:
        logger.error(f"Failed to pre-warm inflammation cache: {e}", exc_info=True)


async def _refresh_exercise_library_mv_if_dirty():
    """Reconcile the exercise_library_cleaned MV at startup.

    Calls public.refresh_exercise_library_cleaned() — a no-op when the dirty
    queue is empty, otherwise CONCURRENTLY refreshes both MVs (cleaned + safety).
    Also drops the cached filter-options payload so the next request rebuilds
    against fresh data.

    The Supabase Python client's `.execute()` is a SYNCHRONOUS network call.
    We wrap it in asyncio.to_thread() so it doesn't block the event loop —
    without this, uvicorn's socket bind hangs on local dev (Render Pro is
    fine because gunicorn's UvicornWorker pre-binds before lifespan).
    """
    try:
        from core.db import get_supabase_db
        from api.v1.library.exercises import invalidate_library_filter_options_cache
        db = get_supabase_db()
        result = await asyncio.to_thread(
            lambda: db.client.rpc("refresh_exercise_library_cleaned", {"force": False}).execute()
        )
        if result.data:
            await invalidate_library_filter_options_cache()
            logger.info(f"Refreshed exercise_library_cleaned MV at startup (queued_at={result.data})")
        else:
            logger.info("exercise_library_cleaned MV is up to date (no refresh needed)")
    except Exception as e:
        logger.error(f"Failed to refresh exercise_library_cleaned MV: {e}", exc_info=True)


async def get_langgraph_service() -> LangGraphCoachService:
    """
    Lazy getter for LangGraph service.
    Initializes on first access if not already initialized during startup.
    """
    global _langgraph_service
    if chat_module.langgraph_coach_service is not None:
        return chat_module.langgraph_coach_service
    if _langgraph_service is None:
        logger.info("Lazy-initializing LangGraph Coach service on first request...")
        _langgraph_service = LangGraphCoachService()
        chat_module.langgraph_coach_service = _langgraph_service
    return _langgraph_service


# Strong refs to in-flight background tasks. asyncio only weakly references
# tasks via the event loop, so without this set the GC can collect a still-
# pending task and emit "Task was destroyed but it is pending!".
_background_tasks: set[asyncio.Task] = set()


def _create_safe_task(coro, name: str = None, user_id: str = None):
    """Create an asyncio task with exception logging and log context propagation.

    Args:
        coro: Coroutine to run
        name: Task name for logging
        user_id: Optional user_id to set in the task's log context.
                 If not provided, inherits from the current context (if any).
    """
    # Snapshot the current log context so the task can restore it
    from core.logger import get_log_context
    parent_ctx = get_log_context()
    explicit_user_id = user_id

    async def _wrapped():
        # Restore parent context (or use explicit user_id) inside the new task
        uid = explicit_user_id or parent_ctx.get("user_id")
        rid = parent_ctx.get("request_id")
        if uid or rid:
            set_log_context(user_id=uid, request_id=rid)
        await coro

    task = asyncio.create_task(_wrapped(), name=name)
    _background_tasks.add(task)

    def _on_done(t):
        _background_tasks.discard(t)
        if t.cancelled():
            return
        exc = t.exception()
        if exc:
            logger.error(f"Background task '{name}' failed: {exc}", exc_info=exc)

    task.add_done_callback(_on_done)
    return task


async def _redis_keepalive_loop():
    """Ping Redis every 6 hours to prevent Upstash free-tier archival."""
    while True:
        await asyncio.sleep(6 * 3600)  # 6 hours
        ok = await ping_redis()
        if ok:
            logger.info("Redis keepalive ping OK")
        else:
            logger.warning("Redis keepalive ping failed")


async def _share_media_cleanup_loop():
    """Periodically purge downloaded social-media payloads that have been
    extracted (>30 min completed) and hard-purge rows >30 days old that
    still carry media keys. See jobs/share_media_cleanup_worker.py."""
    from jobs.share_media_cleanup_worker import run as _share_cleanup_tick
    # Stagger the first run so cold-start isn't slammed.
    await asyncio.sleep(120)
    while True:
        try:
            await _share_cleanup_tick()
        except Exception as e:
            logger.warning(f"[ShareMediaCleanup] tick failed: {e}", exc_info=True)
        await asyncio.sleep(30 * 60)  # 30 minutes


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown events.
    Initializes services on startup, cleans up on shutdown.

    Startup is split into 3 phases for faster cold starts:
      Phase 1 (Critical): Gemini service - needed for all AI endpoints
      Phase 2 (Parallel): RAG, LangGraph, Cache - independent, run concurrently
      Phase 3 (Background): Index checks, job resume - run after server starts serving
    """
    startup_start = time.time()
    logger.info(f"Starting {branding.APP_NAME} Backend...")
    logger.info(f"Gemini Model: {settings.gemini_model}")
    logger.info(f"Embedding Model: {settings.gemini_embedding_model}")

    # Confirm Supavisor pooler is in use — direct connections to db.<ref>.supabase.co
    # cap at ~15 server-side and starved the pool under burst load. If the host
    # logged below isn't `*.pooler.supabase.com:6543`, the env var change didn't
    # take effect and search/workout endpoints will time out under any concurrency.
    try:
        from urllib.parse import urlparse
        _parsed = urlparse(settings.database_url.replace("postgresql+asyncpg://", "postgresql://"))
        logger.info(
            f"🗄️  DB host: {_parsed.hostname}:{_parsed.port}  "
            f"pool_size={settings.db_pool_size} max_overflow={settings.db_max_overflow} "
            f"pool_timeout={settings.db_pool_timeout}s"
        )
    except Exception as _e:
        logger.warning(f"Could not parse DATABASE_URL for diagnostic log: {_e}")

    # Re-attach the health-check access filter inside lifespan so it survives
    # gunicorn's UvicornWorker fork — the worker re-initializes uvicorn's
    # access logger after our module-import-time setup_logging() runs, which
    # was wiping the filter and letting Render keep-alive `GET /` lines spam
    # the log stream.
    from core.logger import _HealthCheckAccessFilter
    import logging as _logging
    _hc_filter = _HealthCheckAccessFilter()
    for _name in ("uvicorn.access", "gunicorn.access"):
        _logger = _logging.getLogger(_name)
        if not any(isinstance(f, _HealthCheckAccessFilter) for f in _logger.filters):
            _logger.addFilter(_hc_filter)

    # ── Sized thread-pool for asyncio.to_thread offloading ──
    # Every blocking ChromaDB / DB call is now offloaded via asyncio.to_thread.
    # The default executor is min(32, cpu+4) = 5 threads on a 1-CPU box — far
    # too few. 40 I/O-bound threads is safe: they spend ~all their time
    # awaiting a network socket, not burning CPU.
    import concurrent.futures
    _blocking_executor = concurrent.futures.ThreadPoolExecutor(
        max_workers=40, thread_name_prefix="blocking-io"
    )
    asyncio.get_running_loop().set_default_executor(_blocking_executor)
    logger.info("Installed 40-thread executor for blocking-call offload")

    # ── Phase 1: Critical initialization (must complete before serving) ──
    phase1_start = time.time()
    logger.info("Initializing Redis cache and Gemini service (Phase 1: critical)...")
    await init_redis()
    chat_module.gemini_service = GeminiService()
    logger.info(f"Startup Phase 1 (critical) completed in {time.time() - phase1_start:.2f}s")

    # ── Phase 2: Parallel initialization of independent services ──
    # RAG depends on Gemini (uses gemini_service for embeddings).
    # LangGraph Coach service for AI chat.
    phase2_start = time.time()
    logger.info("Starting Phase 2: parallel service initialization...")
    phase2_results = await asyncio.gather(
        _init_rag_service(),
        _init_langgraph_service(),
        return_exceptions=True,
    )

    # Log any Phase 2 failures (non-fatal)
    phase2_names = ["RAG service", "LangGraph service"]
    for name, result in zip(phase2_names, phase2_results):
        if isinstance(result, Exception):
            logger.error(f"Phase 2 failure - {name}: {result}")

    logger.info(f"Startup Phase 2 (parallel) completed in {time.time() - phase2_start:.2f}s")

    # ── Phase 3: Background tasks (server starts serving immediately) ──
    # These can run after the server is already accepting requests.
    logger.info("Starting Phase 3: background initialization tasks...")
    _create_safe_task(_redis_keepalive_loop(), name="redis-keepalive")
    _create_safe_task(_init_cache_manager(), name="init-cache-manager")
    _create_safe_task(_init_equipment_resolver(), name="init-equipment-resolver")
    _create_safe_task(_warm_workout_rag(), name="warm-workout-rag")
    # Prime the Chroma Cloud connection so the first real coach RAG query is warm.
    # RAG service is ready by now (Phase 2 completed above). Fire-and-forget,
    # non-blocking, self-contained try/except — never affects startup.
    _create_safe_task(_prewarm_chroma_connection(), name="prewarm-chroma-connection")
    _create_safe_task(_check_exercise_rag_index(), name="check-exercise-rag-index")
    _create_safe_task(_check_chromadb_dimensions(), name="check-chromadb-dimensions")
    _create_safe_task(_resume_pending_jobs(), name="resume-pending-jobs")
    _create_safe_task(_resume_pending_media_jobs(), name="resume-pending-media-jobs")
    _create_safe_task(_prewarm_inflammation_cache(), name="prewarm-inflammation-cache")
    _create_safe_task(_refresh_exercise_library_mv_if_dirty(), name="refresh-exercise-library-mv")
    # Imports feature — delete downloaded IG/TikTok media after extraction
    # completes (App Store compliance) + purge any rows >30d old still
    # carrying media. Runs every 30 minutes.
    _create_safe_task(_share_media_cleanup_loop(), name="share-media-cleanup")

    total_startup = time.time() - startup_start
    logger.info(f"Startup complete in {total_startup:.2f}s (server ready, background tasks running)")
    logger.info(f"Server running at http://{settings.host}:{settings.port}")
    logger.info(f"API docs at http://{settings.host}:{settings.port}/docs")

    yield

    # Cleanup on shutdown
    logger.info("Shutting down...")

    # Close Redis connection pool
    logger.info("Closing Redis connection...")
    await close_redis()

    # Shutdown cache manager
    if settings.gemini_cache_enabled:
        logger.info("Shutting down Gemini Cache Manager...")
        await GeminiService.shutdown_cache_manager()


# Sentry init — see core/sentry.py. Silent no-op when SENTRY_DSN is unset.
from core.sentry import (
    init_sentry,
    set_user as sentry_set_user,
    set_request_context as sentry_set_request_context,
    clear_request_context as sentry_clear_request_context,
)
init_sentry(settings)

# PostHog server-side init — see services/posthog_client.py. Silent no-op
# when POSTHOG_API_KEY is unset. Powers lifecycle_push_sent /
# lifecycle_email_sent events fired from push_nudge_cron and email_cron so
# the re-engagement funnel becomes measurable end-to-end.
from services.posthog_client import init_posthog as _init_posthog
_init_posthog()


# Create FastAPI app
# Disable Swagger/OpenAPI docs in production to reduce attack surface
app = FastAPI(
    title=branding.OPENAPI_TITLE,
    description=f"""
    Backend API for the {branding.APP_NAME} mobile app.

    ## Features
    - AI-powered fitness coaching with GPT-4
    - RAG (Retrieval Augmented Generation) for improved responses over time
    - Workout modifications based on natural language

    ## Quick Start
    1. POST /api/v1/chat/send - Send a message to the AI coach
    2. GET /api/v1/chat/rag/stats - Check RAG system status
    3. POST /api/v1/chat/rag/search - Search similar past conversations

    ## Rate Limits
    - Global: 100 requests/minute
    - Chat endpoints: 10 requests/minute
    - AI generation endpoints: 5 requests/minute
    - Authentication endpoints: 5 requests/minute
    """,
    version="1.0.0",
    redirect_slashes=True,
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    openapi_url="/openapi.json" if settings.debug else None,
)

# Attach limiter to app state for endpoint decorators
app.state.limiter = limiter

# Add rate limit exceeded exception handler
app.add_exception_handler(RateLimitExceeded, structured_rate_limit_handler)

# Log validation errors with full details (helps diagnose 422s)
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.warning(
        f"Validation error on {request.method} {request.url.path}: "
        f"{json.dumps(exc.errors(), default=str)}"
    )
    errors = json.loads(json.dumps(exc.errors(), default=str))
    return JSONResponse(status_code=422, content={"detail": errors})

# Send server errors to Discord #alerts (500, 502, 503, 504 + unhandled exceptions)
from services.discord_webhooks import notify_error as _discord_notify_error

# Alert-worthy status codes: 5xx (server errors) only.
# 401 is excluded: stale Supabase sessions are routine user-side state
# (logged out elsewhere, JWT expired) — every reopen of the app fires 20+
# parallel requests so a single stale session storm = 20+ Discord pings,
# which then trip Discord's 429 rate limit and spam our logs.
# 404s are excluded — they're "client asked for something that doesn't exist"
# (deleted resource, missing exercise image, typo in URL), not a backend
# problem worth paging oncall.
# 429 is excluded: every 429 reaching THIS handler is an intentional,
# documented business limit raised via HTTPException (free-tool daily caps,
# feature caps, AI-tool quotas — error envelopes limit_reached /
# capacity_reached / quota_exceeded). They are the product working as designed,
# not a defect. Genuine *abuse* rate-limiting is SlowAPI's RateLimitExceeded,
# which takes a separate path (structured_rate_limit_handler) and never reaches
# here — so dropping 429 loses no abuse signal.
# Sentry's _before_send already filters 4xx out of the error tracker; Discord
# matches by alerting on 5xx only.
_ALERT_STATUS_CODES = {500, 502, 503, 504}

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    if exc.status_code in _ALERT_STATUS_CODES:
        try:
            user_id = getattr(request.state, "user_id", None)
            _create_safe_task(
                _discord_notify_error(
                    error=exc,
                    context=f"HTTP {exc.status_code}: {exc.detail}",
                    endpoint=f"{request.method} {request.url.path}",
                    user_id=user_id,
                ),
                name="discord_notify_http_error",
                user_id=user_id,
            )
        except Exception:
            pass
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    # Benign: starlette.middleware.base.BaseHTTPMiddleware (used by
    # SlowAPIMiddleware) raises this when a client disconnects mid-stream
    # on an SSE endpoint. The response is already partially sent and the
    # connection is closed — there's nothing to recover and no user to
    # page. Log at INFO and return a 499-style placeholder so starlette's
    # contract is satisfied without a Sentry/Discord alert.
    if isinstance(exc, RuntimeError) and str(exc) == "No response returned.":
        logger.info(
            f"Client disconnected mid-stream on {request.method} {request.url.path}"
        )
        return JSONResponse(
            status_code=499, content={"detail": "client_disconnected"}
        )
    logger.error(f"Unhandled exception on {request.method} {request.url.path}: {exc}", exc_info=True)
    try:
        user_id = getattr(request.state, "user_id", None)
        _create_safe_task(
            _discord_notify_error(
                error=exc,
                endpoint=f"{request.method} {request.url.path}",
                user_id=user_id,
            ),
            name="discord_notify_unhandled_error",
            user_id=user_id,
        )
    except Exception:
        pass
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})

# Add GZip compression for responses >= 500 bytes.
# IMPORTANT: GZipMiddleware buffers the response body to compress it, which
# breaks SSE — a streamed `event: done` never reaches the client until the
# whole stream ends. We wrap it so streaming endpoints (SSE) bypass gzip and
# flush each event immediately. SSE routes: paths ending in `-stream` or
# containing `/import-` (recipe imports also stream).
class _SSEAwareGZipMiddleware:
    def __init__(self, app, **kwargs):
        self._plain_app = app
        self._gzip_app = GZipMiddleware(app, **kwargs)

    async def __call__(self, scope, receive, send):
        if scope.get("type") == "http":
            path = scope.get("path", "")
            if path.endswith("-stream") or "/import-" in path:
                # SSE / streaming — skip gzip so each event flushes live
                return await self._plain_app(scope, receive, send)
        return await self._gzip_app(scope, receive, send)

app.add_middleware(_SSEAwareGZipMiddleware, minimum_size=500)

# SECURITY: Reject oversized request bodies to prevent OOM on 512MB Render tier.
# Implemented as pure ASGI (see BodySizeLimitMiddleware) so streaming endpoints
# don't surface `RuntimeError: No response returned.` on client disconnects.
app.add_middleware(BodySizeLimitMiddleware, max_bytes=20 * 1024 * 1024)

# Add CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-User-Timezone", "X-Cron-Secret", "X-Search-Suggestion", "X-Client-Version", "X-Device-Platform"],
    expose_headers=["X-Search-Suggestion"],
)

# Add logging middleware
app.add_middleware(LoggingMiddleware)

# Add security headers middleware
app.add_middleware(SecurityHeadersMiddleware)

# Add SlowAPI middleware for rate limiting
# This MUST be added for rate limiting to work properly.
# SafeSlowAPIMiddleware guards against the slowapi 0.1.9 crash where a swallowed
# storage error leaves request.state.view_rate_limit unset → 500 (see
# core/rate_limiter.py for the full writeup).
app.add_middleware(SafeSlowAPIMiddleware)

# Add per-route metrics middleware (Phase D4 observability).
# Added LAST => it is the OUTERMOST layer, so the latency it records is the
# full server-side time the client experiences (incl. gzip, rate limiting,
# logging). Pure-ASGI => negligible overhead, no TaskGroup, no SSE breakage.
app.add_middleware(MetricsMiddleware)

# Normalise accidental `/api/v1/api/v1/...` doubled prefixes at the very edge
# so the rewrite is visible in LoggingMiddleware and route matching succeeds.
# Added LAST => outermost layer, fires before every other middleware.
app.add_middleware(_PathPrefixDedupMiddleware)

# Include API routes
app.include_router(v1_router, prefix="/api")

# Phase B: program-template importer. Mounted at /api/v1/program-templates.
app.include_router(
    program_templates_router,
    prefix="/api/v1/program-templates",
    tags=["Program Templates"],
)

# Public (no-auth) shareable resources — short links like zealova.com/r/{slug}
from api.public import router as public_router  # noqa: E402
app.include_router(public_router)

# MCP OAuth 2.1 authorization server. Mounted at /mcp/oauth — paired with the
# MCP streamable-HTTP server at /mcp (wired separately in mcp/server.py when
# Phase 2 lands). Gated to yearly subscribers via mcp/subscription.py.
from mcp.auth.oauth_server import router as mcp_oauth_router  # noqa: E402
app.include_router(mcp_oauth_router)
from mcp.consent.router import router as mcp_consent_router  # noqa: E402
app.include_router(mcp_consent_router)

# MCP streamable-HTTP server (Phase 2+). Hosts the tool + resource surface
# that Claude Desktop / ChatGPT / Cursor talk to. Bearer tokens issued by
# the OAuth server above are resolved in mcp/middleware/auth.py.
try:
    from mcp.server import streamable_http_app as _mcp_streamable_http_app  # noqa: E402
    app.mount("/mcp", _mcp_streamable_http_app())
    logger.info("MCP streamable-HTTP server mounted at /mcp")
except Exception as _mcp_mount_err:  # pragma: no cover — never block boot
    logger.error(
        f"Failed to mount MCP server at /mcp: {_mcp_mount_err}", exc_info=True
    )

# Dev log dashboard (only in debug mode)
if settings.debug:
    from api.dev_logs import router as dev_logs_router
    app.include_router(dev_logs_router)

# Serve static assets (logo used in emails, etc.)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
@limiter.exempt
async def root():
    """Root endpoint - basic info.

    Exempt from rate limiting: Render health checks ping this constantly, and
    it carries no abuse risk. Exemption also short-circuits the middleware
    before any header injection, keeping this hot path off the limiter entirely.
    """
    result = {
        "service": f"{branding.APP_NAME} Backend",
        "version": "1.0.0",
        "health": "/health",
    }
    if settings.debug:
        result["docs"] = "/docs"
    return result


@app.get("/robots.txt", include_in_schema=False)
async def robots_txt():
    return PlainTextResponse("User-agent: *\nDisallow: /\n")


@app.get("/health", tags=["health"])
async def health_keep_alive():
    """
    Lightweight health/keep-alive endpoint for external monitoring.

    Pings Redis to keep the Upstash free-tier database active.
    Use this for Render keep-alive pings (prevents free-tier sleep after 15 min).
    """
    redis_ok = await ping_redis()
    return {
        "status": "ok",
        "timestamp": datetime.utcnow().isoformat(),
        "redis": "connected" if redis_ok else "unavailable",
    }


@app.get("/open", include_in_schema=False)
async def open_app(request: Request):
    """
    Deep-link bounce page linked from emails.
    On mobile: immediately redirects to the Zealova app via the fitwiz:// custom scheme.
    On desktop: shows a friendly page with App Store / Play Store links.

    Forwards the inbound query string (utm_source / utm_medium / utm_campaign)
    onto the custom-scheme URL so the Flutter IncomingLinkService can fire
    `lifecycle_email_clicked` with the right campaign. Without this forward,
    the meta-refresh strips the params and we lose attribution.
    """
    qs = request.url.query  # already URL-encoded
    deeplink_target = f"{branding.DEEP_LINK_SCHEME}://"
    if qs:
        deeplink_target = f"{deeplink_target}?{qs}"

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="0;url={deeplink_target}">
<title>Opening {branding.APP_NAME}…</title>
<style>
  *{{margin:0;padding:0;box-sizing:border-box}}
  body{{background:#000;color:#fafafa;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
       display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:24px}}
  img{{width:96px;height:96px;border-radius:22px;margin-bottom:24px}}
  h1{{font-size:28px;font-weight:800;margin-bottom:8px}}
  p{{color:#a1a1aa;margin-bottom:32px;font-size:15px}}
  .btn{{display:inline-block;background:#06b6d4;color:#000;font-weight:700;font-size:15px;
       padding:14px 32px;border-radius:50px;text-decoration:none;margin:6px}}
  .btn-outline{{background:transparent;color:#06b6d4;border:2px solid #06b6d4}}
</style>
</head>
<body>
<img src="/static/logo.png" alt="{branding.APP_NAME}">
<h1>Opening {branding.APP_NAME}…</h1>
<p>If the app doesn't open automatically, tap below.</p>
<a href="{deeplink_target}" class="btn">Open App</a><br>
<a href="https://apps.apple.com/app/{branding.APP_NAME.lower()}/id0000000000" class="btn btn-outline">App Store</a>
<a href="https://play.google.com/store/apps/details?id={branding.PACKAGE_ID_ANDROID}" class="btn btn-outline">Google Play</a>
</body>
</html>"""
    return HTMLResponse(content=html)


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )
