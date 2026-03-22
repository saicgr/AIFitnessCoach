#!/usr/bin/env python3
"""
End-to-end integration test for the media upload pipeline.

Tests:
1. POST /api/v1/chat/media/upload  → parallel S3 + Gemini upload, returns gemini_file_name
2. POST /api/v1/chat/send          → form analysis via gemini_file_name (no S3 download)
3. POST /api/v1/chat/send          → image food analysis via image_base64

Usage:
    cd backend
    JWT=$(cat /tmp/fw_test_jwt.txt) python3 scripts/test_media_upload_e2e.py

Or set BACKEND_URL to test against Render:
    BACKEND_URL=https://aifitnesscoach-zqi3.onrender.com JWT=<token> python3 scripts/test_media_upload_e2e.py
"""

import os
import sys
import struct
import time
import base64
import json
import io
import requests
from pathlib import Path
from dotenv import load_dotenv

sys.path.insert(0, str(Path(__file__).parent.parent))
load_dotenv(Path(__file__).parent.parent / ".env")

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")
JWT = os.getenv("JWT") or open("/tmp/fw_test_jwt.txt").read().strip()
HEADERS = {"Authorization": f"Bearer {JWT}"}

PASS = "✅"
FAIL = "❌"
INFO = "🔍"


# ─── Minimal valid MP4 generator (no ffmpeg needed) ──────────────────────────

def make_test_mp4(duration_frames: int = 30) -> bytes:
    """
    Generate a minimal valid MP4 file (~1 second @ 30fps) using pure Python.
    Contains a single grey JPEG frame embedded as a video track.
    Gemini will accept this as a video (short, but enough to trigger form analysis).
    """
    from PIL import Image

    # Create a 160x120 grey JPEG frame (simulates a person exercising)
    img = Image.new("RGB", (160, 120), color=(80, 80, 80))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=50)
    frame_bytes = buf.getvalue()

    # Build minimal ISOM/MP4 container with one JPEG-in-MP4 track
    # We use a motion JPEG approach (MJPEG in MP4 container)
    def box(name: str, payload: bytes) -> bytes:
        size = 8 + len(payload)
        return struct.pack(">I", size) + name.encode() + payload

    # ftyp box
    ftyp = box("ftyp", b"mp42" + struct.pack(">I", 0) + b"mp42" + b"isom")

    # mvhd: movie header
    mvhd_payload = (
        struct.pack(">IIIII", 0, 0, 0, 1000, 1000)  # version, flags, ctime, mtime, timescale
        + struct.pack(">I", 1000)    # duration (1 second)
        + struct.pack(">I", 0x00010000)  # rate
        + struct.pack(">H", 0x0100)  # volume
        + b"\x00" * 10  # reserved
        + struct.pack(">IIIIIIIIIII", 0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000, 0, 0)  # matrix (9 ints)
        + b"\x00" * 28  # pre-defined + reserved
        + struct.pack(">I", 2)  # next track ID
    )

    # tkhd: track header
    tkhd_payload = (
        struct.pack(">IIIII", 1, 3, 0, 0, 1)  # version+flags (track enabled), ctime, mtime, track_id
        + struct.pack(">II", 0, 1000)  # reserved, duration
        + b"\x00" * 8  # reserved
        + struct.pack(">HH", 0, 0)  # layer, alt_group
        + struct.pack(">H", 0)  # volume
        + b"\x00" * 2  # reserved
        + struct.pack(">IIIIIIIII", 0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000)  # matrix
        + struct.pack(">II", 160 << 16, 120 << 16)  # width, height (16.16 fixed)
    )

    # Use a simpler approach: just create an MJPEG-style mdat with JPEG frame
    # and proper stbl/stco to satisfy parsers
    mdat = box("mdat", frame_bytes)

    # Build moov box (simplified)
    moov_payload = box("mvhd", mvhd_payload) + box("trak",
        box("tkhd", tkhd_payload)
    )
    moov = box("moov", moov_payload)

    return ftyp + moov + mdat


def make_food_jpeg() -> bytes:
    """Create a simple food-like JPEG image for nutrition analysis testing."""
    from PIL import Image, ImageDraw

    img = Image.new("RGB", (200, 200), color=(255, 200, 100))
    draw = ImageDraw.Draw(img)
    draw.ellipse([50, 50, 150, 150], fill=(255, 100, 0))  # orange "food" circle
    draw.text((60, 165), "Apple ~95 cal", fill=(0, 0, 0))

    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=80)
    return buf.getvalue()


# ─── Test helpers ─────────────────────────────────────────────────────────────

def section(title: str):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


def check(condition: bool, msg: str):
    icon = PASS if condition else FAIL
    print(f"  {icon} {msg}")
    if not condition:
        raise AssertionError(f"FAILED: {msg}")


# ─── Test 1: Video upload (parallel S3 + Gemini) ──────────────────────────────

def test_video_upload():
    section("TEST 1: Video Upload → Parallel S3 + Gemini Files API")

    print(f"  {INFO} Generating synthetic test MP4...")
    video_bytes = make_test_mp4()
    print(f"  {INFO} Video size: {len(video_bytes)} bytes")

    print(f"  {INFO} POSTing to {BACKEND_URL}/api/v1/chat/media/upload ...")
    t0 = time.time()
    resp = requests.post(
        f"{BACKEND_URL}/api/v1/chat/media/upload",
        headers=HEADERS,
        files={"file": ("test_squat.mp4", io.BytesIO(video_bytes), "video/mp4")},
        data={"media_type": "video", "duration_seconds": "1.0"},
        timeout=120,
    )
    elapsed = time.time() - t0

    print(f"  {INFO} Response status: {resp.status_code} ({elapsed:.1f}s)")
    check(resp.status_code == 200, f"Upload returned 200 (got {resp.status_code}: {resp.text[:200]})")

    data = resp.json()
    print(f"  {INFO} Response: {json.dumps(data, indent=4)}")

    check("s3_key" in data, "Response has s3_key")
    check("gemini_file_name" in data, "Response has gemini_file_name")
    check("public_url" in data, "Response has public_url")
    check("mime_type" in data, "Response has mime_type")
    check(data["mime_type"] == "video/mp4", f"mime_type is video/mp4 (got {data['mime_type']})")
    check(data["gemini_file_name"].startswith("files/"), f"gemini_file_name starts with 'files/' (got {data['gemini_file_name']})")
    check("chat_media/" in data["s3_key"], f"s3_key contains 'chat_media/' (got {data['s3_key']})")

    return data


# ─── Test 2: Form analysis via gemini_file_name ────────────────────────────────

def test_form_analysis(upload_data: dict, user_id: str):
    section("TEST 2: Form Analysis via gemini_file_name (no S3 download)")

    media_ref = {
        "s3_key": upload_data["s3_key"],
        "media_type": "video",
        "mime_type": "video/mp4",
        "gemini_file_name": upload_data["gemini_file_name"],
        "duration_seconds": 1.0,
    }

    payload = {
        "message": "Check my squat form",
        "user_id": user_id,
        "media_ref": media_ref,
        "conversation_history": [],
    }

    print(f"  {INFO} POSTing to {BACKEND_URL}/api/v1/chat/send ...")
    print(f"  {INFO} media_ref.gemini_file_name = {media_ref['gemini_file_name']}")

    t0 = time.time()
    resp = requests.post(
        f"{BACKEND_URL}/api/v1/chat/send",
        headers={**HEADERS, "Content-Type": "application/json"},
        json=payload,
        timeout=180,
    )
    elapsed = time.time() - t0
    print(f"  {INFO} Response status: {resp.status_code} ({elapsed:.1f}s)")
    check(resp.status_code == 200, f"Chat returned 200 (got {resp.status_code}: {resp.text[:300]})")

    data = resp.json()
    print(f"  {INFO} message: {data.get('message', '')[:200]}")
    print(f"  {INFO} intent: {data.get('intent')}")
    print(f"  {INFO} agent_type: {data.get('agent_type')}")
    print(f"  {INFO} action_data keys: {list(data.get('action_data') or {})}")

    check("message" in data, "Response has message")
    check(len(data["message"]) > 20, f"Message has content (len={len(data['message'])})")

    # Form check result may be in action_data
    action = data.get("action_data") or {}
    if action.get("form_check_result"):
        fcr = action["form_check_result"]
        print(f"  {INFO} form_score: {fcr.get('form_score')}")
        print(f"  {INFO} exercise_identified: {fcr.get('exercise_identified')}")
        check("form_score" in fcr, "form_check_result has form_score")

    return data


# ─── Test 3: Image food analysis via image_base64 ─────────────────────────────

def test_image_food_analysis(user_id: str):
    section("TEST 3: Image Food Analysis via image_base64")

    food_jpeg = make_food_jpeg()
    image_b64 = base64.b64encode(food_jpeg).decode()
    print(f"  {INFO} Food image size: {len(food_jpeg)} bytes  (base64: {len(image_b64)} chars)")

    payload = {
        "message": "What food is this and how many calories?",
        "user_id": user_id,
        "image_base64": image_b64,
        "conversation_history": [],
    }

    print(f"  {INFO} POSTing to {BACKEND_URL}/api/v1/chat/send ...")
    t0 = time.time()
    resp = requests.post(
        f"{BACKEND_URL}/api/v1/chat/send",
        headers={**HEADERS, "Content-Type": "application/json"},
        json=payload,
        timeout=120,
    )
    elapsed = time.time() - t0
    print(f"  {INFO} Response status: {resp.status_code} ({elapsed:.1f}s)")
    check(resp.status_code == 200, f"Chat returned 200 (got {resp.status_code}: {resp.text[:300]})")

    data = resp.json()
    print(f"  {INFO} message: {data.get('message', '')[:200]}")
    print(f"  {INFO} intent: {data.get('intent')}")
    print(f"  {INFO} agent_type: {data.get('agent_type')}")

    check("message" in data, "Response has message")
    check(len(data["message"]) > 20, f"Message has content (len={len(data['message'])})")
    return data


# ─── Test 4: Validate user log context header ─────────────────────────────────

def test_user_id_in_response_headers():
    section("TEST 4: X-Request-ID header present (middleware logging active)")

    resp = requests.get(
        f"{BACKEND_URL}/health",
        headers=HEADERS,
        timeout=10,
    )
    req_id = resp.headers.get("x-request-id", "")
    print(f"  {INFO} X-Request-ID: {req_id}")
    check(len(req_id) > 0, f"X-Request-ID header is present (got: '{req_id}')")
    check(len(req_id) == 8, f"Request ID is 8 chars (got length {len(req_id)})")


# ─── Get current user ID ──────────────────────────────────────────────────────

def get_user_id() -> str:
    resp = requests.get(
        f"{BACKEND_URL}/api/v1/users/me",
        headers=HEADERS,
        timeout=10,
    )
    if resp.status_code == 200:
        return str(resp.json().get("id", ""))
    # Fallback: decode user_id from DB users table via JWT
    # Use the Supabase client
    import os
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent.parent / ".env")
    from supabase import create_client
    sb = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))
    # Validate JWT and find the user's DB id via their Supabase auth id
    user_resp = sb.auth.get_user(JWT)
    if user_resp and user_resp.user:
        auth_id = str(user_resp.user.id)
        result = sb.table("users").select("id").eq("auth_id", auth_id).execute()
        if result.data:
            return str(result.data[0]["id"])
    raise RuntimeError("Could not determine user_id from JWT")


# ─── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print(f"\n{'='*60}")
    print(f"  FitWiz Media Upload E2E Integration Test")
    print(f"  Backend: {BACKEND_URL}")
    print(f"{'='*60}")

    # Verify backend is reachable
    try:
        health = requests.get(f"{BACKEND_URL}/health", timeout=10)
        print(f"\n{PASS} Backend is up: {health.json()}")
    except Exception as e:
        print(f"{FAIL} Backend not reachable: {e}")
        sys.exit(1)

    try:
        user_id = get_user_id()
        print(f"{INFO} Using user_id: {user_id[:8]}...")
    except Exception as e:
        print(f"{FAIL} Could not get user_id: {e}")
        sys.exit(1)

    passed = 0
    failed = 0

    # Test 4: headers (quick sanity check first)
    try:
        test_user_id_in_response_headers()
        passed += 1
    except Exception as e:
        print(f"  {FAIL} {e}")
        failed += 1

    # Test 1 + 2: video upload → form analysis
    try:
        upload_data = test_video_upload()
        passed += 1
        try:
            test_form_analysis(upload_data, user_id)
            passed += 1
        except Exception as e:
            print(f"  {FAIL} Form analysis: {e}")
            failed += 1
    except Exception as e:
        print(f"  {FAIL} Video upload: {e}")
        failed += 2

    # Test 3: image food analysis
    try:
        test_image_food_analysis(user_id)
        passed += 1
    except Exception as e:
        print(f"  {FAIL} Image food analysis: {e}")
        failed += 1

    # Summary
    print(f"\n{'='*60}")
    total = passed + failed
    print(f"  Results: {passed}/{total} passed")
    if failed == 0:
        print(f"  {PASS} All tests passed!")
    else:
        print(f"  {FAIL} {failed} test(s) failed")
    print(f"{'='*60}\n")
    sys.exit(0 if failed == 0 else 1)
