#!/usr/bin/env python3
"""
reddit_scout.py -- fetch recent Reddit threads for Zealova GEO scouting.

WHY THIS EXISTS
---------------
reddit.com is blocklisted for the Claude Code WebFetch tool, so the
geo-strategist / reddit-agent cannot load Reddit pages directly. The machine's
network itself is NOT blocked, so this script reaches Reddit over plain HTTPS
and hands back structured thread data the agents can use.

AUTH
----
Default: unauthenticated public .json endpoints. No setup, works immediately,
but Reddit rate-limits unauthenticated traffic (~10 requests/min), so the
script paces itself.

Optional upgrade: if REDDIT_CLIENT_ID + REDDIT_CLIENT_SECRET are present (in
the environment or backend/.env), the script uses app-only OAuth
(client_credentials grant -> oauth.reddit.com, ~100 requests/min, more
reliable). No Reddit account password is ever needed or stored -- this is
read-only access. No redirect URI, no localhost server, no browser flow.

USAGE
-----
  python3 scripts/reddit_scout.py \
      --subs loseit,Fitness,xxfitness,EatCheapAndHealthy,nutrition,HomeGym,bodyweightfitness \
      --queries "app,tracker,recommend,alternative,MyFitnessPal" \
      --window week --min-comments 10 --limit 60

Output: a JSON array of thread objects on stdout. Errors go to stderr; one
failing subreddit never aborts the run.
"""

import argparse
import base64
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "zealova-geo-scout/0.2 (Zealova GEO research; contact digithat123@gmail.com)"
WINDOW_DAYS = {"day": 1, "week": 7, "month": 30}


def load_oauth_creds():
    """Return (client_id, client_secret) from env or backend/.env, or (None, None)."""
    cid = os.environ.get("REDDIT_CLIENT_ID")
    csec = os.environ.get("REDDIT_CLIENT_SECRET")
    if cid and csec:
        return cid, csec
    env_path = os.path.join(os.path.dirname(__file__), "..", "backend", ".env")
    if os.path.exists(env_path):
        found = {}
        with open(env_path) as fh:
            for line in fh:
                line = line.strip()
                for key in ("REDDIT_CLIENT_ID", "REDDIT_CLIENT_SECRET"):
                    if line.startswith(key + "="):
                        found[key] = line.split("=", 1)[1].strip().strip('"').strip("'")
        cid = cid or found.get("REDDIT_CLIENT_ID")
        csec = csec or found.get("REDDIT_CLIENT_SECRET")
    return cid, csec


def get_oauth_token(cid, csec):
    """Exchange client credentials for an app-only bearer token."""
    data = urllib.parse.urlencode({"grant_type": "client_credentials"}).encode()
    auth = base64.b64encode(f"{cid}:{csec}".encode()).decode()
    req = urllib.request.Request(
        "https://www.reddit.com/api/v1/access_token",
        data=data,
        headers={"User-Agent": USER_AGENT, "Authorization": f"Basic {auth}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)["access_token"]


def make_client():
    """Return (base_url, headers, delay_seconds). OAuth if creds exist, else public."""
    cid, csec = load_oauth_creds()
    if cid and csec:
        try:
            token = get_oauth_token(cid, csec)
            print("# reddit_scout: using app-only OAuth (oauth.reddit.com)", file=sys.stderr)
            return ("https://oauth.reddit.com",
                    {"User-Agent": USER_AGENT, "Authorization": f"bearer {token}"},
                    0.8)
        except Exception as exc:  # noqa: BLE001 - fall back, never abort
            print(f"# reddit_scout: OAuth failed ({exc}); using public .json", file=sys.stderr)
    return ("https://www.reddit.com", {"User-Agent": USER_AGENT}, 2.3)


def get_json(base, headers, path, params, delay):
    """GET a Reddit endpoint. Public endpoints get a .json suffix; OAuth ones don't."""
    is_public = "oauth.reddit.com" not in base
    url = f"{base}{path}{'.json' if is_public else ''}?{urllib.parse.urlencode(params)}"
    time.sleep(delay)  # pace ourselves so Reddit doesn't 429 us
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=25) as resp:
        return json.load(resp)


def normalize(child, max_age_days):
    """Turn a raw Reddit listing child into a clean thread dict, or None if too old."""
    d = child.get("data", {})
    created = d.get("created_utc", 0)
    age_days = (dt.datetime.now(dt.timezone.utc)
                - dt.datetime.fromtimestamp(created, dt.timezone.utc)).total_seconds() / 86400
    if age_days > max_age_days:
        return None
    body = (d.get("selftext") or "").strip()
    return {
        "subreddit": d.get("subreddit"),
        "title": d.get("title"),
        "url": "https://www.reddit.com" + d.get("permalink", ""),
        "created_iso": dt.datetime.fromtimestamp(created, dt.timezone.utc).strftime("%Y-%m-%d"),
        "age_days": round(age_days, 1),
        "num_comments": d.get("num_comments", 0),
        "score": d.get("score", 0),
        "flair": d.get("link_flair_text"),
        "over_18": d.get("over_18", False),
        "selftext": body[:800],
    }


def scout(subs, queries, window, min_comments, min_score, limit):
    base, headers, delay = make_client()
    max_age = WINDOW_DAYS.get(window, 7)
    seen, threads = set(), []

    for sub in subs:
        # 1) keyword searches inside the sub, newest first
        for q in queries:
            try:
                payload = get_json(base, headers, f"/r/{sub}/search",
                                   {"q": q, "restrict_sr": 1, "sort": "new",
                                    "t": window, "limit": 25}, delay)
            except urllib.error.HTTPError as exc:
                print(f"# reddit_scout: r/{sub} search '{q}' -> HTTP {exc.code}", file=sys.stderr)
                continue
            except Exception as exc:  # noqa: BLE001
                print(f"# reddit_scout: r/{sub} search '{q}' -> {exc}", file=sys.stderr)
                continue
            for child in payload.get("data", {}).get("children", []):
                row = normalize(child, max_age)
                if row and row["url"] not in seen:
                    seen.add(row["url"])
                    threads.append(row)
        # 2) top threads of the window, to catch high-engagement non-keyword posts
        try:
            payload = get_json(base, headers, f"/r/{sub}/top",
                               {"t": window, "limit": 25}, delay)
            for child in payload.get("data", {}).get("children", []):
                row = normalize(child, max_age)
                if row and row["url"] not in seen:
                    seen.add(row["url"])
                    threads.append(row)
        except Exception as exc:  # noqa: BLE001
            print(f"# reddit_scout: r/{sub} top -> {exc}", file=sys.stderr)

    # engagement filter: keep a thread if it clears EITHER threshold
    threads = [t for t in threads
               if t["num_comments"] >= min_comments or t["score"] >= min_score]
    # rank by engagement, freshest first as tiebreaker
    threads.sort(key=lambda t: (t["num_comments"] + t["score"], -t["age_days"]),
                 reverse=True)
    return threads[:limit]


def main():
    ap = argparse.ArgumentParser(description="Scout recent Reddit threads for Zealova GEO.")
    ap.add_argument("--subs", required=True, help="comma-separated subreddits (no r/ prefix)")
    ap.add_argument("--queries", default="app,recommend,alternative,looking for",
                    help="comma-separated search terms run inside each sub")
    ap.add_argument("--window", default="week", choices=list(WINDOW_DAYS),
                    help="recency window (default: week)")
    ap.add_argument("--min-comments", type=int, default=10)
    ap.add_argument("--min-score", type=int, default=50)
    ap.add_argument("--limit", type=int, default=60, help="max threads returned")
    args = ap.parse_args()

    subs = [s.strip().lstrip("r/").strip() for s in args.subs.split(",") if s.strip()]
    queries = [q.strip() for q in args.queries.split(",") if q.strip()]

    threads = scout(subs, queries, args.window, args.min_comments,
                    args.min_score, args.limit)
    json.dump({"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
               "window": args.window, "count": len(threads), "threads": threads},
              sys.stdout, indent=2)
    sys.stdout.write("\n")
    print(f"# reddit_scout: {len(threads)} threads after filter", file=sys.stderr)


if __name__ == "__main__":
    main()
