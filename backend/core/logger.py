"""
Centralized logging configuration for the backend.

Features:
- Structured JSON logging for easy filtering in Render/log aggregators
- Per-request context (user_id, request_id) automatically included
- Thread-safe context management using contextvars

Usage:
    from core.logger import get_logger, set_log_context
    logger = get_logger(__name__)

    # In middleware, set context for the request
    set_log_context(user_id="abc123", request_id="req-xyz")

    # All subsequent logs automatically include user_id and request_id
    logger.info("User created")  # {"user_id": "abc123", "request_id": "req-xyz", ...}

Filtering logs in Render:
    - Search: "user_id":"abc123"
    - Search: "level":"ERROR"
    - Search: "request_id":"req-xyz"
"""
import logging
import sys
import json
import os
from datetime import datetime
from typing import Any, Optional
from contextvars import ContextVar

# Context variables for request-scoped logging
_user_id_var: ContextVar[Optional[str]] = ContextVar("user_id", default=None)
_request_id_var: ContextVar[Optional[str]] = ContextVar("request_id", default=None)


def set_log_context(
    user_id: Optional[str] = None,
    request_id: Optional[str] = None
) -> None:
    """
    Set logging context for the current request.
    Call this in middleware at the start of each request.
    """
    if user_id is not None:
        _user_id_var.set(user_id)
    if request_id is not None:
        _request_id_var.set(request_id)


def clear_log_context() -> None:
    """Clear logging context at the end of a request."""
    _user_id_var.set(None)
    _request_id_var.set(None)


def get_log_context() -> dict:
    """Get current logging context."""
    ctx = {}
    if _user_id_var.get():
        ctx["user_id"] = _user_id_var.get()
    if _request_id_var.get():
        ctx["request_id"] = _request_id_var.get()
    return ctx


class JSONFormatter(logging.Formatter):
    """
    Formatter that outputs JSON logs for easy parsing and filtering.

    Each log line is a valid JSON object with:
    - timestamp: ISO format timestamp
    - level: Log level (INFO, ERROR, etc.)
    - module: Source module name
    - message: Log message
    - user_id: User ID from context (if set)
    - request_id: Request ID from context (if set)
    - Additional fields passed via extra={}
    """

    def format(self, record: logging.LogRecord) -> str:
        # Base log data
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "module": record.name.split(".")[-1] if "." in record.name else record.name,
            "message": record.getMessage(),
        }

        # Add context from contextvars (user_id, request_id)
        log_data.update(get_log_context())

        # Add any extra fields passed via extra={}
        extras = {k: v for k, v in record.__dict__.items()
                  if k not in logging.LogRecord.__dict__
                  and not k.startswith("_")
                  and k not in ("message", "msg", "args", "name", "levelname",
                               "levelno", "pathname", "filename", "module",
                               "exc_info", "exc_text", "stack_info", "lineno",
                               "funcName", "created", "msecs", "relativeCreated",
                               "thread", "threadName", "processName", "process",
                               "taskName")}

        log_data.update(extras)

        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_data, default=str)


class StructuredFormatter(logging.Formatter):
    """
    Human-readable formatter for local development.
    Falls back to this when JSON is too verbose for console.
    """

    def format(self, record: logging.LogRecord) -> str:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        level = record.levelname
        module = record.name.split(".")[-1] if "." in record.name else record.name

        # Build the base message
        base_msg = f"[{timestamp}] [{level}] [{module}] {record.getMessage()}"

        # Add context
        ctx = get_log_context()
        if ctx:
            ctx_str = " | " + ", ".join(f"{k}={v}" for k, v in ctx.items())
            base_msg += ctx_str

        # Add any extra fields
        extras = {k: v for k, v in record.__dict__.items()
                  if k not in logging.LogRecord.__dict__
                  and not k.startswith("_")
                  and k not in ("message", "msg", "args", "name", "levelname",
                               "levelno", "pathname", "filename", "module",
                               "exc_info", "exc_text", "stack_info", "lineno",
                               "funcName", "created", "msecs", "relativeCreated",
                               "thread", "threadName", "processName", "process",
                               "taskName")}

        if extras:
            extra_str = " | " + ", ".join(f"{k}={v}" for k, v in extras.items())
            base_msg += extra_str

        return base_msg


def setup_logging(level: str = "INFO", use_json: bool = True) -> None:
    """
    Configure root logger.

    Args:
        level: Log level (DEBUG, INFO, WARNING, ERROR)
        use_json: If True, output JSON logs (for production). If False, human-readable.
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper()))

    # Remove existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Add console handler with appropriate formatter
    console_handler = logging.StreamHandler(sys.stdout)
    if use_json:
        console_handler.setFormatter(JSONFormatter())
    else:
        console_handler.setFormatter(StructuredFormatter())
    root_logger.addHandler(console_handler)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger instance for the given module name.

    Args:
        name: Usually __name__ of the calling module

    Returns:
        Configured logger instance
    """
    return logging.getLogger(name)


class LoggerAdapter(logging.LoggerAdapter):
    """Adapter that allows passing extra context with each log call."""

    def process(self, msg: str, kwargs: dict) -> tuple:
        # Merge extra context
        extra = kwargs.get("extra", {})
        extra.update(self.extra)
        kwargs["extra"] = extra
        return msg, kwargs


def get_context_logger(name: str, **context: Any) -> LoggerAdapter:
    """
    Get a logger with persistent context (e.g., for a specific user or operation).

    Args:
        name: Module name
        **context: Key-value pairs to include in every log message

    Returns:
        LoggerAdapter with context
    """
    logger = get_logger(name)
    return LoggerAdapter(logger, context)


# Initialize logging on module import
# Use JSON in production (Render), human-readable locally
_is_production = os.getenv("RENDER", "false").lower() == "true" or os.getenv("ENV", "dev") == "production"
setup_logging(use_json=_is_production)
