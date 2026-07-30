"""The single chokepoint for **generating** images anywhere in the backend.

Why this module exists
----------------------
Image generation on Vertex has two independent traps, and every call site that
built its own client got to fall into both of them separately:

1. **Region.** `imagen-*` publisher models are REGIONAL ONLY. The shared Gemini
   client runs at `settings.gcp_location == "global"` (correct, and required,
   for Gemini *text*), so any call site reusing it 404s:
       Publisher model `projects/<p>/locations/global/publishers/google/models/
       imagen-4.0-fast-generate-001` was not found
2. **Model availability.** Pinning a region is not enough — the model still has
   to be enabled for the project. Our production project
   (`gen-lang-client-0702777617`) has **no Imagen model in any region**:
   `us-central1`, `us-east4` and `europe-west4` all answer
       ... was not found or your project does not have access to it
   for `imagen-4.0-fast-generate-001`, `imagen-3.0-fast-generate-001` and
   `imagen-3.0-generate-002` alike. What the project *does* have — verified with
   the production service account — is `gemini-2.5-flash-image`, which serves
   from both `global` and `us-central1` and is the model `share_ai_service`
   already generates with in production.

Trap 1 was patched once at one call site (commit 09569597 pinned the dish-image
client to `us-central1`) and the very next menu scan still 502'd on trap 2. That
is the shape of a bug that must be fixed at a chokepoint, not per call site: the
region and the model belong to ONE owner, and no caller may construct an image
client of its own.

Contract
--------
    from services.image_generation_service import generate_image
    result = generate_image(prompt=..., purpose="dish_image")
    result.data          # bytes
    result.mime_type     # "image/png" — use it, don't assume
    result.model         # what actually served it
    result.location      # where it served from

Errors are typed so callers can degrade *honestly* rather than guessing:

  * ``ImageModelUnavailable`` — the model does not exist for this project /
    region, or the platform refused the request outright. Nothing the user did;
    nothing a retry fixes. The caller should surface "no image", never a
    stand-in picture.
  * ``ImageGenerationBlocked`` — the request was safety-filtered or the model
    returned no image part.
  * ``ImageGenerationError`` — anything else (transport, timeout, quota).

An ``ImageModelUnavailable`` also opens a short-lived circuit breaker for that
model, so a 60-dish menu scan makes ONE doomed call instead of sixty. The
breaker re-raises the same honest error with the same reason — it suppresses
network chatter, never the truth.

Regression gate
---------------
    cd backend && .venv/bin/python -m services.image_generation_service --check

Fails if any backend module other than this one calls `generate_images(...)` or
asks Gemini for `response_modalities=["IMAGE"]` — i.e. if a new call site starts
owning its own model/region again.
"""
from __future__ import annotations

import os
import re
import time
from dataclasses import dataclass
from typing import Any, Dict, Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)


# --------------------------------------------------------------------------- #
# Errors
# --------------------------------------------------------------------------- #
class ImageGenerationError(Exception):
    """Image generation failed. Never returns a placeholder in its place."""


class ImageModelUnavailable(ImageGenerationError):
    """The image model is not available to this project/region at all.

    Distinct from a transient failure: retrying, or asking for a different
    dish, changes nothing. Callers degrade to "no image" and log loudly.
    """


class ImageGenerationBlocked(ImageGenerationError):
    """The model refused (safety filter) or returned no image part."""


# --------------------------------------------------------------------------- #
# Model + region — owned here and nowhere else
# --------------------------------------------------------------------------- #
# Verified available to the production Vertex project with the production
# service account (2026-07-29): generate_content + response_modalities=["IMAGE"]
# at both `global` and `us-central1`. Every `imagen-*` model 404s for this
# project in every region tried, so Imagen is NOT a valid default here.
DEFAULT_IMAGE_MODEL = "gemini-2.5-flash-image"

# The region `imagen-*` falls back to when nothing is configured. `global` is
# never valid for Imagen and is rewritten to this.
DEFAULT_IMAGEN_LOCATION = "us-central1"


def default_image_model() -> str:
    """Model used when a caller does not name one."""
    return os.getenv("IMAGE_GEN_MODEL", DEFAULT_IMAGE_MODEL).strip() or DEFAULT_IMAGE_MODEL


def _is_imagen(model: str) -> bool:
    return model.lower().startswith("imagen")


def resolve_image_location(model: str) -> str:
    """Vertex region for `model`. The ONLY place a region is chosen.

    `imagen-*` is regional-only — `global` 404s — so a `global` setting is
    corrected rather than obeyed. Gemini image models serve from the shared
    location (verified working at `global`).
    """
    configured = (os.getenv("IMAGE_GEN_LOCATION") or "").strip()
    if _is_imagen(model):
        location = configured or DEFAULT_IMAGEN_LOCATION
        if location.lower() == "global":
            logger.warning(
                "[ImageGen] IMAGE_GEN_LOCATION=global is invalid for %s "
                "(Imagen is regional-only) — using %s",
                model,
                DEFAULT_IMAGEN_LOCATION,
            )
            location = DEFAULT_IMAGEN_LOCATION
        return location
    if configured:
        return configured
    from core.config import get_settings

    return get_settings().gcp_location or DEFAULT_IMAGEN_LOCATION


def get_image_client(model: str):
    """google-genai client for image generation, pinned to `model`'s region.

    Mirrors ``core.gemini_client.get_genai_client``'s Vertex/ZDR setup (same
    project, same service account) so image traffic stays on the zero-data-
    retention path, but owns the location. When Vertex is not configured
    (local dev) this defers to the shared client, which raises its own clear
    error rather than inventing credentials.
    """
    from core.config import get_settings

    settings = get_settings()
    if not settings.gcp_project_id:
        from core.gemini_client import get_genai_client

        return get_genai_client()

    from google import genai

    from core.gemini_client import _setup_credentials

    _setup_credentials()
    return genai.Client(
        vertexai=True,
        project=settings.gcp_project_id,
        location=resolve_image_location(model),
    )


# --------------------------------------------------------------------------- #
# Circuit breaker for "this model does not exist for us"
# --------------------------------------------------------------------------- #
_UNAVAILABLE_TTL_S = 15 * 60
_unavailable_until: Dict[str, Tuple[float, str]] = {}


def _note_unavailable(model: str, reason: str) -> None:
    _unavailable_until[model] = (time.monotonic() + _UNAVAILABLE_TTL_S, reason)


def _check_unavailable(model: str) -> None:
    entry = _unavailable_until.get(model)
    if not entry:
        return
    until, reason = entry
    if time.monotonic() >= until:
        _unavailable_until.pop(model, None)
        return
    raise ImageModelUnavailable(reason)


def reset_availability_cache() -> None:
    """Clear the breaker (tests, and after an env/model change)."""
    _unavailable_until.clear()


def _looks_like_missing_model(exc: Exception) -> bool:
    text = str(exc).lower()
    return ("not_found" in text or "404" in text) and (
        "publisher model" in text or "was not found" in text or "does not have access" in text
    )


# --------------------------------------------------------------------------- #
# Result
# --------------------------------------------------------------------------- #
@dataclass(frozen=True)
class GeneratedImage:
    data: bytes
    mime_type: str
    model: str
    location: str

    @property
    def extension(self) -> str:
        """File extension implied by the real mime type (never assumed)."""
        sub = (self.mime_type or "image/png").split("/")[-1].split(";")[0]
        return {"jpeg": "jpg"}.get(sub, sub or "png")


# --------------------------------------------------------------------------- #
# The one call
# --------------------------------------------------------------------------- #
def generate_image(
    *,
    prompt: str,
    purpose: str,
    model: Optional[str] = None,
    aspect_ratio: str = "1:1",
    reference_image: Optional[Tuple[bytes, str]] = None,
    timeout: Optional[float] = 90.0,
) -> GeneratedImage:
    """Generate ONE image. Raises on failure — never returns a placeholder.

    `purpose` is a short tag used in logs (e.g. "dish_image") so cost and
    failure can be attributed per feature.
    `reference_image` is `(bytes, mime_type)` for edit/restyle-style requests;
    only the Gemini image path supports it.
    """
    chosen = (model or default_image_model()).strip()
    _check_unavailable(chosen)
    location = resolve_image_location(chosen)
    client = get_image_client(chosen)

    logger.info("[ImageGen] %s → model=%s location=%s", purpose, chosen, location)
    try:
        if _is_imagen(chosen):
            if reference_image is not None:
                raise ImageGenerationError(
                    f"{chosen} cannot take a reference image; use a gemini-*-image model."
                )
            data, mime = _generate_via_imagen(client, chosen, prompt, aspect_ratio, timeout)
        else:
            data, mime = _generate_via_gemini(
                client, chosen, prompt, aspect_ratio, reference_image, timeout
            )
    except ImageGenerationError:
        raise
    except Exception as exc:  # noqa: BLE001 — classified, then re-raised typed
        if _looks_like_missing_model(exc):
            reason = (
                f"Image model {chosen!r} is not available to this project at "
                f"{location!r}. Enable it in Vertex AI or set IMAGE_GEN_MODEL to a "
                f"model the project has."
            )
            _note_unavailable(chosen, reason)
            logger.error("[ImageGen] %s unavailable: %s (%s)", chosen, reason, exc)
            raise ImageModelUnavailable(reason) from exc
        raise ImageGenerationError(f"Image generation failed: {exc}") from exc

    if not data:
        raise ImageGenerationBlocked(
            "The image model returned no image (possibly safety-blocked)."
        )
    return GeneratedImage(data=data, mime_type=mime or "image/png", model=chosen, location=location)


def _generate_via_imagen(
    client: Any, model: str, prompt: str, aspect_ratio: str, timeout: Optional[float]
) -> Tuple[Optional[bytes], Optional[str]]:
    config: Dict[str, Any] = {"number_of_images": 1, "aspect_ratio": aspect_ratio}
    if timeout:
        # `timeout` is part of this module's contract — honouring it only on the
        # Gemini branch would make it a silent no-op for imagen callers, which is
        # how a request hangs a worker thread for the SDK's default instead.
        config["http_options"] = {"timeout": int(timeout * 1000)}
    resp = client.models.generate_images(
        model=model,
        prompt=prompt,
        config=config,
    )
    images = getattr(resp, "generated_images", None) or []
    if not images:
        return None, None
    image = images[0].image
    return image.image_bytes, getattr(image, "mime_type", None) or "image/png"


def _generate_via_gemini(
    client: Any,
    model: str,
    prompt: str,
    aspect_ratio: str,
    reference_image: Optional[Tuple[bytes, str]],
    timeout: Optional[float],
) -> Tuple[Optional[bytes], Optional[str]]:
    from google.genai import types

    contents: list = []
    if reference_image is not None:
        ref_bytes, ref_mime = reference_image
        contents.append(types.Part.from_bytes(data=ref_bytes, mime_type=ref_mime))
    contents.append(prompt)

    config_kwargs: Dict[str, Any] = {
        "response_modalities": ["IMAGE"],
        "safety_settings": [
            types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="BLOCK_ONLY_HIGH"),
            types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="BLOCK_ONLY_HIGH"),
            types.SafetySetting(
                category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="BLOCK_MEDIUM_AND_ABOVE"
            ),
            types.SafetySetting(
                category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="BLOCK_ONLY_HIGH"
            ),
        ],
    }
    if aspect_ratio and hasattr(types, "ImageConfig"):
        config_kwargs["image_config"] = types.ImageConfig(aspect_ratio=aspect_ratio)

    http_options = None
    if timeout:
        http_options = types.HttpOptions(timeout=int(timeout * 1000))

    resp = client.models.generate_content(
        model=model,
        contents=contents,
        config=types.GenerateContentConfig(
            **config_kwargs,
            **({"http_options": http_options} if http_options is not None else {}),
        ),
    )
    for candidate in getattr(resp, "candidates", None) or []:
        for part in getattr(getattr(candidate, "content", None), "parts", None) or []:
            inline = getattr(part, "inline_data", None)
            if inline and getattr(inline, "data", None):
                return inline.data, getattr(inline, "mime_type", None) or "image/png"
    return None, None


# --------------------------------------------------------------------------- #
# Regression gate — no call site may own model/region again
# --------------------------------------------------------------------------- #
_GATE_ALLOWED = {
    # This module IS the chokepoint.
    "services/image_generation_service.py",
}

# Grandfathered call sites, so the gate fails on NEW drift rather than being
# permanently red. Both still own their own model/region and belong in
# `generate_image()`; remove each entry as it is migrated.
#
#   services/share_ai_service.py — restyle-a-photo. Generates with
#     gemini-2.5-flash-image on the shared (global) client, which happens to be
#     a combination this project *does* have, so it works today. It would break
#     the same way the dish path did the moment SHARE_AI_IMAGE_MODEL is pointed
#     at an imagen-* model. Migration: call
#     generate_image(prompt=..., purpose="share_restyle",
#                    model=restyle_image_model(),
#                    reference_image=(image_bytes, mime_type)).
#
#   scripts/generate_missing_exercise_illustrations.py — offline backfill on the
#     developer API key (imagen-4.0-fast-generate-001 exists there, not on our
#     Vertex project), so it is not currently broken, but it hardcodes the same
#     assumption. Migration: same helper.
_GATE_GRANDFATHERED = {
    "services/share_ai_service.py",
    "scripts/generate_missing_exercise_illustrations.py",
}

# Matched as PATTERNS, not literal strings: the drift this gate exists to catch
# does not have one spelling. `response_modalities=["TEXT", "IMAGE"]` is the form
# most Gemini image samples use, `[types.Modality.IMAGE]` is the typed form, and
# both are the same defect as `["IMAGE"]` — a call site owning its own model and
# region. A literal-string gate silently passed both.
_GATE_REGEXES = (
    re.compile(r"\.models\.generate_images\s*\("),
    # Keyword form (`response_modalities=[...]`) and dict form
    # (`"response_modalities": [...]`) alike.
    re.compile(r"""response_modalities["']?\s*[=:]\s*[\[(][^\]\)]*image""", re.IGNORECASE),
)


def audit_image_call_sites(root: Optional[str] = None) -> list:
    """Return [(relpath, lineno, line)] for image-generation calls outside here."""
    import pathlib

    base = pathlib.Path(root or pathlib.Path(__file__).resolve().parents[1])
    findings = []
    for path in base.rglob("*.py"):
        rel = path.relative_to(base).as_posix()
        if rel.startswith((".venv", "venv", "tests/")) or "/site-packages/" in rel:
            continue
        if rel in _GATE_ALLOWED or rel in _GATE_GRANDFATHERED:
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if not any(rx.search(text) for rx in _GATE_REGEXES):
            continue
        # A modalities list can wrap across lines, so match a 3-line window as
        # well as the line itself: `response_modalities=[\n "TEXT", "IMAGE",\n]`
        # is the same defect and must not slip through.
        lines = text.splitlines()
        hits = {
            i + 1
            for i in range(len(lines))
            for rx in _GATE_REGEXES
            if rx.search(lines[i]) or rx.search(" ".join(lines[i : i + 3]))
        }
        # One wrapped call matches up to three consecutive windows — report it
        # once, at its first line.
        previous = -10
        for line_no in sorted(hits):
            if line_no - previous > 2:
                # Point at the offending call, not at the top of the window.
                anchor = next(
                    (
                        n
                        for n in range(line_no, min(line_no + 3, len(lines) + 1))
                        if "response_modalities" in lines[n - 1]
                        or "generate_images" in lines[n - 1]
                    ),
                    line_no,
                )
                findings.append((rel, anchor, lines[anchor - 1].strip()))
            previous = line_no
    return findings


if __name__ == "__main__":  # pragma: no cover
    import sys

    if "--check" in sys.argv:
        hits = audit_image_call_sites()
        if hits:
            print(
                "Image generation must go through "
                "services.image_generation_service.generate_image().\n"
                "These call sites own their own model/region and will 404 the "
                "moment either changes:\n"
            )
            for rel, line_no, text in hits:
                print(f"  {rel}:{line_no}: {text}")
            sys.exit(1)
        print("OK — every image generation routes through the chokepoint.")
        sys.exit(0)
    print(__doc__)
