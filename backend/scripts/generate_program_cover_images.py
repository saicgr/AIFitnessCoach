"""
Generate cover images for published curated programs whose `programs.image_url`
is NULL, matching the style of the original 18 hand-generated covers
(1080x1350-ish 4:5 photoreal golden-hour fitness photography at
s3://ai-fitness-coach/static/program-covers/).

Pipeline per program (mirrors docs/planning/exercise-images/run_pipeline.py):
  1. SCENE   — gemini-3.5-flash writes a one-scene art direction JSON from the
               program's name/tagline/category/who_for (no hardcoded per-program
               scene table).
  2. GENERATE — gemini-3.1-flash-image renders the 4:5 cover.
  3. VALIDATE — gemini-3.5-flash vision QA (photoreal, no text/watermark, no
               anatomical deformities, subject matches the program, warm
               cinematic tone). Fail -> regenerate, up to MAX_ATTEMPTS.
  4. UPLOAD  — s3://<bucket>/static/program-covers/<slug>.png (public URL, same
               prefix as the existing covers), verify the https URL serves 200.
  5. DB      — UPDATE programs SET image_url = 'https://.../<slug>.png?v=1'.

Idempotent: programs whose image_url is already non-empty are never touched.

Run:
  backend/.venv/bin/python backend/scripts/generate_program_cover_images.py [--dry-run] [--limit N]
"""
from __future__ import annotations

import asyncio
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import asyncpg
import boto3
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")

# ---------- Config ----------
BUCKET = os.getenv("S3_BUCKET_NAME", "ai-fitness-coach")
REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")
GEN_MODEL = "gemini-3.1-flash-image"
TEXT_MODEL = "gemini-3.5-flash"
ASPECT = "4:5"  # existing covers are 1080x1350
MAX_ATTEMPTS = 3
MAX_SPEND_USD = 6.0
S3_PREFIX = "static/program-covers"

TS = time.strftime("%Y%m%d_%H%M%S")
OUT_DIR = BACKEND / "scripts" / "output" / f"program_covers_{TS}"

if not GEMINI_API_KEY or not DATABASE_URL:
    print("ERROR: GEMINI_API_KEY / DATABASE_URL not set; aborting.")
    sys.exit(2)

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    region_name=REGION,
)

COST = {"usd": 0.0}

# Matches the look of the original covers (verified against
# mens-beach-body.png / morning-yoga.png): photoreal, warm golden-hour
# amber light, cinematic shallow depth of field, zero typography.
STYLE = """Photorealistic cinematic fitness photography for a premium fitness app program cover.
- VERTICAL 4:5 PORTRAIT composition framed for a mobile card.
- Warm golden-hour lighting: amber/orange sunlight, soft haze, glowing highlights, deep soft shadows.
- Cinematic look: shallow depth of field, blurred background, crisp athletic subject, realistic sweat/skin detail.
- One athletic subject (or an evocative equipment still-life if specified) captured mid-movement in correct, recognizable form.
- Anatomically correct human: exactly two arms, two legs, natural hands and face.
- ABSOLUTELY NO text, numbers, lettering, watermark, logo, UI, or graphic overlays anywhere in the image.
- No borders, no split panels, no collage — one single full-bleed photograph."""


def slugify(name: str) -> str:
    s = name.lower()
    s = s.replace("&", " and ")
    s = re.sub(r"[—–]", "-", s)
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return re.sub(r"-+", "-", s).strip("-")


def post(model: str, body: dict) -> dict:
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={GEMINI_API_KEY}"
    )
    req = urllib.request.Request(
        url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"}
    )
    last = None
    for attempt in range(4):
        try:
            r = urllib.request.urlopen(req, timeout=180)
            return json.loads(r.read())
        except urllib.error.HTTPError as e:
            last = f"HTTP {e.code}: {e.read().decode()[:200]}"
            if e.code in (429, 500, 503) and attempt < 3:
                time.sleep(6 * (attempt + 1))
                continue
            raise RuntimeError(last)
        except Exception as e:  # timeouts etc.
            last = str(e)
            if attempt < 3:
                time.sleep(5)
                continue
            raise RuntimeError(last)
    raise RuntimeError(last or "unreachable")


def _text_of(data: dict) -> str:
    return "".join(
        p.get("text", "")
        for c in data.get("candidates", [])
        for p in c.get("content", {}).get("parts", [])
    )


def _track_text_cost(data: dict) -> None:
    um = data.get("usageMetadata", {})
    COST["usd"] += (
        um.get("promptTokenCount", 0) * 0.10e-6
        + um.get("candidatesTokenCount", 0) * 0.40e-6
    )


def scene_direction(p: dict) -> dict:
    """One coach/art-director scene per program — derived, not hardcoded."""
    q = (
        "You are the art director for a premium fitness app's program covers. "
        "The house style is photoreal golden-hour fitness photography (no text). "
        f"Program: \"{p['editorial_name']}\"\n"
        f"Tagline: {p.get('tagline') or '-'}\n"
        f"Category: {p.get('program_category') or '-'}\n"
        f"Audience: {p.get('who_for') or 'general'}\n\n"
        "Describe ONE hero photograph that instantly communicates this exact "
        "program (activity, setting, equipment, subject demographic that fits "
        "the audience — e.g. women's-health programs feature a woman, 50+ "
        "programs feature an older adult). Return ONLY JSON: "
        '{"scene": "2-3 precise sentences: subject, action/pose, setting, '
        'camera angle", "must_show": "the single most recognizable prop or '
        'action for this program"}'
    )
    data = post(
        TEXT_MODEL,
        {
            "contents": [{"parts": [{"text": q}]}],
            "generationConfig": {
                "responseModalities": ["TEXT"],
                "responseMimeType": "application/json",
            },
        },
    )
    _track_text_cost(data)
    t = _text_of(data)
    j = json.loads(t[t.find("{"): t.rfind("}") + 1])
    if not j.get("scene"):
        raise RuntimeError("scene model returned no scene")
    return j


def generate(p: dict, scene: dict, path: Path) -> bool:
    prompt = (
        f"{STYLE}\n\n"
        f"PROGRAM: {p['editorial_name']} — {p.get('tagline') or ''}\n"
        f"SCENE TO SHOOT: {scene['scene']}\n"
        f"MUST BE VISIBLE: {scene.get('must_show', '')}\n"
        "Remember: zero text or logos anywhere."
    )
    data = post(
        GEN_MODEL,
        {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseModalities": ["IMAGE"],
                "imageConfig": {"aspectRatio": ASPECT},
            },
        },
    )
    um = data.get("usageMetadata", {})
    img_tok = sum(
        d.get("tokenCount", 0)
        for d in um.get("candidatesTokensDetails", [])
        if d.get("modality") == "IMAGE"
    )
    COST["usd"] += img_tok * 60e-6 + um.get("promptTokenCount", 0) * 0.25e-6
    for cand in data.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            if "inlineData" in part:
                path.write_bytes(base64.b64decode(part["inlineData"]["data"]))
                return True
    return False


HARD = [
    "photorealistic",
    "no_text_or_watermark",
    "no_deformities",
    "matches_program",
    "warm_cinematic_tone",
]


def validate(p: dict, path: Path) -> dict:
    img_b64 = base64.b64encode(path.read_bytes()).decode()
    q = (
        "You are QA for premium fitness-app program cover photos. The image "
        f"should represent the program \"{p['editorial_name']}\" "
        f"({p.get('tagline') or ''}; category {p.get('program_category')}).\n"
        "Return ONLY JSON booleans + notes:\n"
        "{\n"
        '  "photorealistic": bool,        // looks like a real photo, not a cartoon/render\n'
        '  "no_text_or_watermark": bool,  // ZERO letters, numbers, logos, watermarks\n'
        '  "no_deformities": bool,        // correct limbs/hands/face, plausible equipment\n'
        '  "matches_program": bool,       // activity/equipment/subject clearly fit this program\n'
        '  "warm_cinematic_tone": bool,   // golden-hour warm grade, moody/cinematic\n'
        '  "notes": "one short sentence"\n'
        "}"
    )
    data = post(
        TEXT_MODEL,
        {
            "contents": [
                {
                    "parts": [
                        {"inlineData": {"mimeType": "image/png", "data": img_b64}},
                        {"text": q},
                    ]
                }
            ],
            "generationConfig": {
                "responseModalities": ["TEXT"],
                "responseMimeType": "application/json",
            },
        },
    )
    _track_text_cost(data)
    t = _text_of(data)
    try:
        v = json.loads(t[t.find("{"): t.rfind("}") + 1])
    except Exception:
        return {"verdict": "fail", "notes": "unparseable validator output"}
    v["verdict"] = "pass" if all(bool(v.get(k)) for k in HARD) else "fail"
    return v


def upload(slug: str, path: Path) -> str:
    key = f"{S3_PREFIX}/{slug}.png"
    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=path.read_bytes(),
        ContentType="image/png",
        CacheControl="public, max-age=31536000",
    )
    url = f"https://{BUCKET}.s3.{REGION}.amazonaws.com/{key}"
    # The existing covers are publicly readable at this prefix; verify, and if
    # the bucket relies on object ACLs rather than a policy, retry public-read.
    if _head(url) != 200:
        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=path.read_bytes(),
            ContentType="image/png",
            CacheControl="public, max-age=31536000",
            ACL="public-read",
        )
        code = _head(url)
        if code != 200:
            raise RuntimeError(f"uploaded object not publicly readable (HTTP {code})")
    return f"{url}?v=1"


def _head(url: str) -> int:
    req = urllib.request.Request(url, method="HEAD")
    try:
        return urllib.request.urlopen(req, timeout=30).status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return 0


async def main() -> None:
    dry = "--dry-run" in sys.argv
    limit = (
        int(sys.argv[sys.argv.index("--limit") + 1]) if "--limit" in sys.argv else None
    )
    # backend/.env stores an SQLAlchemy-style DSN; asyncpg wants plain postgresql://
    dsn = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://", 1)
    conn = await asyncpg.connect(dsn, statement_cache_size=0)
    rows = await conn.fetch(
        """
        SELECT id, editorial_name, tagline, program_category, who_for
        FROM programs
        WHERE is_published AND (image_url IS NULL OR image_url = '')
        ORDER BY editorial_name
        """
    )
    print(f"{len(rows)} published programs missing covers")
    if dry:
        for r in rows:
            print(f"  - {r['editorial_name']} -> {slugify(r['editorial_name'])}.png")
        await conn.close()
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    results = []
    for i, r in enumerate(rows):
        if limit is not None and i >= limit:
            break
        if COST["usd"] >= MAX_SPEND_USD:
            print(f"SPEND CAP ${MAX_SPEND_USD} hit — stopping.")
            break
        p = dict(r)
        slug = slugify(p["editorial_name"])
        path = OUT_DIR / f"{slug}.png"
        verdict = {"verdict": "fail", "notes": "no attempt"}
        try:
            scene = scene_direction(p)
            for attempt in range(1, MAX_ATTEMPTS + 1):
                if not generate(p, scene, path):
                    verdict = {"verdict": "fail", "notes": "no image returned"}
                    continue
                verdict = validate(p, path)
                if verdict["verdict"] == "pass":
                    break
        except Exception as e:
            verdict = {"verdict": "fail", "notes": f"error: {e}"}
        status = verdict["verdict"]
        if status == "pass":
            try:
                url = upload(slug, path)
                await conn.execute(
                    "UPDATE programs SET image_url = $1, updated_at = now() WHERE id = $2",
                    url,
                    p["id"],
                )
            except Exception as e:
                status = "fail"
                verdict["notes"] = f"upload/db error: {e}"
        results.append({"name": p["editorial_name"], "slug": slug, "status": status,
                        "notes": verdict.get("notes", "")})
        print(
            f"[{i + 1}/{len(rows)}] {p['editorial_name']:<44} -> {status.upper():5} "
            f"(${COST['usd']:.2f}) {verdict.get('notes', '')[:60]}",
            flush=True,
        )
    await conn.close()
    (OUT_DIR / "results.json").write_text(json.dumps(results, indent=2))
    passed = sum(1 for x in results if x["status"] == "pass")
    print(f"DONE: {passed}/{len(results)} covers shipped. Total cost ${COST['usd']:.2f}")
    print(f"Local copies + results.json in {OUT_DIR}")


if __name__ == "__main__":
    asyncio.run(main())
