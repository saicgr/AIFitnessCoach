"""
Centralized logging configuration for the backend.

Usage:
    from core.logger import get_logger
    logger = get_logger(__name__)

    logger.info("User created", user_id=1)
    logger.error("Failed to connect", error=str(e))
"""
import logging
import sys
from datetime import datetime
from typing import Any


class StructuredFormatter(logging.Formatter):
    """Custom formatter that outputs structured log messages."""

    def format(self, record: logging.LogRecord) -> str:
        # Base format: [TIMESTAMP] [LEVEL] [MODULE] message
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        level = record.levelname
        module = record.name.split(".")[-1] if "." in record.name else record.name

        # Build the base message
        base_msg = f"[{timestamp}] [{level}] [{module}] {record.getMessage()}"

        # Add any extra fields passed via extra={}
        extras = {k: v for k, v in record.__dict__.items()
                  if k not in logging.LogRecord.__dict__
                  and not k.startswith("_")
                  and k not in ("message", "msg", "args", "name", "levelname",
                               "levelno", "pathname", "filename", "module",
                               "exc_info", "exc_text", "stack_info", "lineno",
                               "funcName", "created", "msecs", "relativeCreated",
                               "thread", "threadName", "processName", "process")}

        if extras:
            extra_str = " | " + ", ".join(f"{k}={v}" for k, v in extras.items())
            base_msg += extra_str

        return base_msg


def setup_logging(level: str = "INFO") -> None:
    """Configure root logger with structured formatting."""
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, level.upper()))

    # Remove existing handlers
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)

    # Add console handler with structured formatter
    console_handler = logging.StreamHandler(sys.stdout)
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
    Get a logger with persistent context (e.g., request_id, user_id).

    Args:
        name: Module name
        **context: Key-value pairs to include in every log message

    Returns:
        LoggerAdapter with context
    """
    logger = get_logger(name)
    return LoggerAdapter(logger, context)


# Initialize logging on module import
setup_logging()
