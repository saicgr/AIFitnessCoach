#!/usr/bin/env python3
"""Daily morning briefing emailer. Run with a slot number 1-8.

Usage: python run.py <slot>
Slot:
  1 = DE Interview & Job-Market Keywords
  2 = Trending Fitness + Nutrition Keywords (Zealova)
  3 = ASO Keywords (Fitness/Health/Nutrition)
  4 = Niche App Idea
  5 = Morning DE Jobs (Remote-US, last 24h)
  6 = Afternoon DE Jobs (Remote-US, last 8h)
  7 = Night DE Jobs (Remote-US, last 8h)
"""
import os
import sys
import json
import urllib.request
import urllib.error
from pathlib import Path

# Load .env
ENV = Path(__file__).resolve().parents[2] / "backend" / ".env"
for line in ENV.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, _, v = line.partition("=")
    os.environ.setdefault(k.strip(), v.strip())

GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]
RESEND_API_KEY = os.environ["RESEND_API_KEY"]
FROM = "Zealova <hello@zealova.com>"
TO = "digithat123@gmail.com"

GEMINI_MODEL = "gemini-2.5-flash"
GEMINI_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/"
    f"{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"
)


SLOTS = {
    1: {
        "subject": "① Morning Briefing — DE Interview & Job-Market Keywords",
        "prompt": """You are writing a daily morning briefing email body (HTML, no <html>/<head>/<body> wrapper, just inline content). Use Google Search to find the LATEST trending Data Engineering interview and job-market keywords from the last 7 days. Output:

<h2>10 Hottest Technical Keywords (Data Engineering)</h2>
<ol>
  <li><b>Keyword</b> — 1-line why it's hot this week</li>
  ... (10 items)
</ol>

<h2>5 Behavioral / System-Design Themes in Recent Interview Loops</h2>
<ol>
  <li><b>Theme</b> — 1-line note + <a href="...">source</a></li>
  ... (5 items)
</ol>

Sources to draw from: LinkedIn talent reports, Indeed Hiring Lab, Levels.fyi, r/dataengineering. Vary picks day to day.

Output ONLY the HTML body, no preamble, no closing.""",
    },
    2: {
        "subject": "② Morning Briefing — 10 Fitness + 10 Nutrition Trending Keywords",
        "prompt": """You are writing a daily morning briefing email body (HTML, no wrapper tags). Use Google Search to find what's trending RIGHT NOW (last 7 days) in fitness and nutrition.

<h2>10 Trending Fitness Keywords</h2>
<ol>
  <li><b>Keyword</b> — 1-line "how Zealova (AI fitness coach app) could use it"</li>
  ... (10 items)
</ol>

<h2>10 Trending Nutrition Keywords</h2>
<ol>
  <li><b>Keyword</b> — 1-line "how Zealova could use it"</li>
  ... (10 items)
</ol>

Sources: TikTok trends, Google Trends rising queries, r/fitness, r/nutrition, Whoop/Strava/MyFitnessPal blogs, Men's/Women's Health. Vary picks day to day.

Output ONLY the HTML body.""",
    },
    3: {
        "subject": "③ Morning Briefing — ASO Keywords for Fitness/Health/Nutrition",
        "prompt": """You are writing a daily morning briefing email body (HTML, no wrapper tags). Use Google Search to find high-traffic / low-competition US App Store + Google Play keywords for fitness/health/nutrition apps right now.

<h2>15 Ranked ASO Keywords for Zealova</h2>
<table border="1" cellpadding="6" cellspacing="0" style="border-collapse:collapse;font-size:14px">
  <tr><th>#</th><th>Keyword</th><th>Traffic</th><th>Competition</th><th>Why it fits Zealova</th></tr>
  <tr><td>1</td><td>...</td><td>High|Med|Low</td><td>High|Med|Low</td><td>...</td></tr>
  ... (15 rows)
</table>

Sources: AppTweak/Sensor Tower public reports, Phiture/MobileAction/AppFollow blogs, competitor titles & subtitles (MyFitnessPal, Noom, Fitbod, Strong, Cronometer, Future, Ladder, Centr). Vary picks day to day.

Output ONLY the HTML body.""",
    },
    4: {
        "subject": "④ Morning Briefing — New Niche App Idea",
        "prompt": """You are writing a daily morning briefing email body (HTML, no wrapper tags). Use Google Search to research and propose ONE original app or product spin (any vertical with a clear niche).

Requirements:
- Underserved niche (not saturated)
- Demonstrable demand: cite Reddit threads, Google Trends rising queries, TikTok hashtags, Product Hunt launches, or recent VC theses (with links)
- Buildable as a mobile app or Zealova feature spin-off
- Plausible monetization angle

Vary the vertical/category each day.

Output structure:
<h2>Idea: [Name]</h2>
<p><b>Pitch:</b> 2-sentence pitch.</p>
<p><b>Target user:</b> ...</p>
<p><b>Evidence of demand:</b></p>
<ul><li>... <a href="...">link</a></li></ul>
<p><b>Monetization:</b> ...</p>
<p><b>Why now:</b> ...</p>
<p><b>Closest competitors and gap:</b></p>
<ul><li>...</li></ul>

Output ONLY the HTML body.""",
    },
    5: {
        "subject": "🌅 Morning Jobs — 25 Fresh REMOTE-US Data Engineering Roles (last 24h)",
        "prompt": _de_jobs_prompt := """You are writing a daily job-listings email body (HTML, no wrapper tags). Use Google Search to find FRESH REMOTE-US Data Engineering roles.

HARD FILTERS:
- Title: Data Engineer, Analytics Engineer, ML Engineer (data-leaning), Data Platform Engineer, ETL/ELT Engineer, Senior/Staff DE
- Employment: BOTH full-time AND contract/W2/C2C — tag each row [FT] or [Contract]
- Location: REMOTE-US ONLY. SKIP hybrid, on-site, Remote-EU, Remote-Canada-only, Remote-LATAM, Remote-Global-excluding-US.
- Posted in the {window}
- Skip 100+ applicant roles

SOURCES (rotate to avoid repeats across runs):
{sources}

DEDUP: never list same Company—Title twice; identity = apply URL.

Output:
<h2>Top {target} Remote-US Data Engineering Jobs</h2>
<ol>
  <li>[FT|Contract] <b>Company</b> — Title — Remote-US — Posted (Xh ago) — Comp (if shown) — <a href="...">Apply</a></li>
  ... (up to {target} items; if fewer qualify, return only those and note the count)
</ol>

Output ONLY the HTML body.""",
    },
    6: {
        "subject": "🌤️ Afternoon Jobs — 25 Fresh REMOTE-US Data Engineering Roles (since this morning)",
        "prompt": _de_jobs_prompt,
    },
    7: {
        "subject": "🌙 Night Jobs — 25 Fresh REMOTE-US Data Engineering Roles (since afternoon)",
        "prompt": _de_jobs_prompt,
    },
}

# Slot-specific job parameters
JOB_PARAMS = {
    5: {
        "window": "LAST 24 HOURS",
        "target": 25,
        "sources": "1. Latest Hacker News 'Who is Hiring' thread\n2. YC Work at a Startup\n3. Wellfound/AngelList\n4. Lever.co + Greenhouse.io direct boards\n5. Otta / Welcome to the Jungle",
    },
    6: {
        "window": "LAST 8 HOURS (since 7am Central)",
        "target": 25,
        "sources": "1. LinkedIn public job search (US, past 24h, sort by date)\n2. BuiltIn\n3. Dice.com (US only)\n4. RemoteOK / WeWorkRemotely / Remotive (US-eligible only)\n5. Ashby / Workday direct postings (US only)",
    },
    7: {
        "window": "LAST 8 HOURS (since 1pm Central)",
        "target": 25,
        "sources": "1. Indeed (US, last 24h, sort by date)\n2. SimplyHired + ZipRecruiter (US, contract)\n3. Talent.com / Glassdoor (US only)\n4. DataYoshi, DataJobs.com, AIJobs.net, ai-jobs.net (US filter)\n5. Robert Half tech / Insight Global / Mondo / Motion Recruitment (US contracts)",
    },
}


def call_gemini(prompt: str) -> str:
    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "tools": [{"google_search": {}}],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 8192},
    }
    req = urllib.request.Request(
        GEMINI_URL,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = json.load(resp)
    parts = data["candidates"][0]["content"]["parts"]
    text = "".join(p.get("text", "") for p in parts)
    if not text.strip():
        raise RuntimeError(f"Empty Gemini response: {json.dumps(data)[:500]}")
    # Strip ```html fences if present
    text = text.strip()
    if text.startswith("```html"):
        text = text[len("```html"):].strip()
    elif text.startswith("```"):
        text = text[3:].strip()
    if text.endswith("```"):
        text = text[:-3].strip()
    return text


def send_resend(subject: str, html: str) -> str:
    body = {"from": FROM, "to": [TO], "subject": subject, "html": html}
    req = urllib.request.Request(
        "https://api.resend.com/emails",
        data=json.dumps(body).encode(),
        headers={
            "Authorization": f"Bearer {RESEND_API_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"Resend HTTP {e.code}: {e.read().decode()}") from e
    return data["id"]


def main():
    if len(sys.argv) != 2:
        print("Usage: run.py <slot 1-7>", file=sys.stderr)
        sys.exit(2)
    slot = int(sys.argv[1])
    spec = SLOTS[slot]
    prompt = spec["prompt"]
    if slot in JOB_PARAMS:
        prompt = prompt.format(**JOB_PARAMS[slot])
    print(f"[slot {slot}] Calling Gemini...", flush=True)
    html = call_gemini(prompt)
    print(f"[slot {slot}] Got {len(html)} chars. Sending via Resend...", flush=True)
    msg_id = send_resend(spec["subject"], html)
    print(f"[slot {slot}] SENT id={msg_id}")


if __name__ == "__main__":
    main()
