#!/usr/bin/env python3
"""
x_scout.py -- fetch recent X (Twitter) posts for Zealova GEO scouting.

WHY THIS EXISTS
---------------
x.com is awkward for the Claude Code WebFetch tool (login walls, JS-rendered
timelines), so the geo-strategist cannot reliably load X search pages. This
script reaches the official X API v2 recent-search endpoint over HTTPS and
hands back structured tweet data the agents can draft replies against. It is
the X-side counterpart to reddit_scout.py.

AUTH
----
Uses an app-only Bearer token. The script reads X_BEARER_TOKEN from the
environment or from backend/.env. Read-only: no user password, no OAuth
browser flow. No token is ever printed.

ACCESS LEVEL CAVEAT
-------------------
The v2 recent-search endpoint (/2/tweets/search/recent) is NOT available on
the X API free tier -- it requires Basic tier or above. If the token is
free-tier, X returns HTTP 403 and the script reports that clearly on stderr
instead of failing silently. Recent search only covers the last 7 days, which
matches the GEO recency requirement anyway.

USAGE
-----
  python3 scripts/x_scout.py \
      --queries "AI workout app,calorie tracking,MyFitnessPal,gym progress" \
      --min-engagement 5 --lang en --limit 60

Output: a JSON object on stdout ({generated, window, count, tweets: [...]}).
Errors go to stderr; one failing query never aborts the run.
"""

import argparse
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "zealova-geo-scout/0.1 (Zealova GEO research; contact digithat123@gmail.com)"
SEARCH_URL = "https://api.twitter.com/2/tweets/search/recent"
# recent search is a fixed 7-day window; --window only narrows it client-side
WINDOW_DAYS = {"day": 1, "week": 7}


def load_bearer():
    """Return the X bearer token from env or backend/.env, or None."""
    token = os.environ.get("X_BEARER_TOKEN")
    if token:
        return token.strip()
    env_path = os.path.join(os.path.dirname(__file__), "..", "backend", ".env")
    if os.path.exists(env_path):
        with open(env_path) as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("X_BEARER_TOKEN="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return None


def search_recent(token, query, next_token=None):
    """Call /2/tweets/search/recent once. Returns the parsed JSON payload."""
    params = {
        "query": query,
        "max_results": 100,  # API max per page
        "tweet.fields": "created_at,public_metrics,author_id,lang,conversation_id",
        "expansions": "author_id",
        "user.fields": "username,name,public_metrics,verified",
        "sort_order": "relevancy",
    }
    if next_token:
        params["next_token"] = next_token
    url = f"{SEARCH_URL}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": USER_AGENT, "Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(req, timeout=25) as resp:
        return json.load(resp)


def normalize(tweet, users_by_id, max_age_days):
    """Turn a raw API tweet into a clean dict, or None if too old / no author."""
    created_raw = tweet.get("created_at")
    if not created_raw:
        return None
    created = dt.datetime.strptime(created_raw, "%Y-%m-%dT%H:%M:%S.%f%z")
    age_days = (dt.datetime.now(dt.timezone.utc) - created).total_seconds() / 86400
    if age_days > max_age_days:
        return None
    author = users_by_id.get(tweet.get("author_id"), {})
    handle = author.get("username")
    if not handle:
        return None
    m = tweet.get("public_metrics", {})
    text = (tweet.get("text") or "").strip()
    return {
        "id": tweet.get("id"),
        "url": f"https://x.com/{handle}/status/{tweet.get('id')}",
        "author": f"@{handle}",
        "author_name": author.get("name"),
        "author_followers": author.get("public_metrics", {}).get("followers_count", 0),
        "author_verified": author.get("verified", False),
        "created_iso": created.strftime("%Y-%m-%d"),
        "age_days": round(age_days, 1),
        "lang": tweet.get("lang"),
        "is_reply": text.startswith("@"),
        "conversation_id": tweet.get("conversation_id"),
        "likes": m.get("like_count", 0),
        "retweets": m.get("retweet_count", 0),
        "replies": m.get("reply_count", 0),
        "quotes": m.get("quote_count", 0),
        "engagement": (m.get("like_count", 0) + m.get("retweet_count", 0)
                       + m.get("reply_count", 0) + m.get("quote_count", 0)),
        "text": text[:600],
    }


def scout(token, queries, window, min_engagement, lang, limit, max_per_query):
    """Run each query against recent search, filter, dedupe, rank."""
    max_age = WINDOW_DAYS.get(window, 7)
    seen, tweets = set(), []

    for raw_q in queries:
        # exclude retweets so we only draft against original tweets; keep it English
        query = f"({raw_q}) -is:retweet"
        if lang:
            query += f" lang:{lang}"
        gathered, next_token, pages = 0, None, 0
        while gathered < max_per_query and pages < 5:
            pages += 1
            try:
                payload = search_recent(token, query, next_token)
            except urllib.error.HTTPError as exc:
                detail = ""
                try:
                    detail = exc.read().decode()[:200]
                except Exception:  # noqa: BLE001
                    pass
                if exc.code == 403:
                    print(f"# x_scout: query '{raw_q}' -> HTTP 403. The recent-search "
                          f"endpoint needs X API Basic tier or above; the current "
                          f"token may be free-tier. {detail}", file=sys.stderr)
                    return tweets[:limit]  # 403 will repeat for every query; stop now
                if exc.code == 429:
                    print(f"# x_scout: query '{raw_q}' -> HTTP 429 rate limit; "
                          f"pausing 60s", file=sys.stderr)
                    time.sleep(60)
                    continue
                print(f"# x_scout: query '{raw_q}' -> HTTP {exc.code} {detail}",
                      file=sys.stderr)
                break
            except Exception as exc:  # noqa: BLE001 - one bad query never aborts
                print(f"# x_scout: query '{raw_q}' -> {exc}", file=sys.stderr)
                break

            users_by_id = {u["id"]: u for u in
                           payload.get("includes", {}).get("users", [])}
            for tweet in payload.get("data", []):
                row = normalize(tweet, users_by_id, max_age)
                if row and row["id"] not in seen:
                    seen.add(row["id"])
                    row["matched_query"] = raw_q
                    tweets.append(row)
                    gathered += 1

            next_token = payload.get("meta", {}).get("next_token")
            if not next_token:
                break
            time.sleep(1.0)  # pace pagination so we don't 429
        time.sleep(1.0)  # pace between queries

    # engagement filter, then rank by engagement with freshness as tiebreaker
    tweets = [t for t in tweets if t["engagement"] >= min_engagement]
    tweets.sort(key=lambda t: (t["engagement"], -t["age_days"]), reverse=True)
    return tweets[:limit]


def main():
    ap = argparse.ArgumentParser(
        description="Scout recent X (Twitter) posts for Zealova GEO.")
    ap.add_argument("--queries", required=True,
                    help="comma-separated search terms; each run as its own search")
    ap.add_argument("--window", default="week", choices=list(WINDOW_DAYS),
                    help="recency window (recent search caps at 7 days)")
    ap.add_argument("--min-engagement", type=int, default=5,
                    help="minimum likes+retweets+replies+quotes to keep a tweet")
    ap.add_argument("--lang", default="en", help="language filter (blank to disable)")
    ap.add_argument("--limit", type=int, default=60, help="max tweets returned")
    ap.add_argument("--max-per-query", type=int, default=80,
                    help="max tweets gathered per query before moving on")
    args = ap.parse_args()

    token = load_bearer()
    if not token:
        print("# x_scout: no X_BEARER_TOKEN in env or backend/.env -- cannot run",
              file=sys.stderr)
        json.dump({"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
                   "window": args.window, "count": 0, "tweets": [],
                   "error": "missing X_BEARER_TOKEN"}, sys.stdout, indent=2)
        sys.stdout.write("\n")
        sys.exit(1)

    queries = [q.strip() for q in args.queries.split(",") if q.strip()]
    tweets = scout(token, queries, args.window, args.min_engagement,
                   args.lang.strip(), args.limit, args.max_per_query)

    json.dump({"generated": dt.datetime.now(dt.timezone.utc).isoformat(),
               "window": args.window, "count": len(tweets), "tweets": tweets},
              sys.stdout, indent=2)
    sys.stdout.write("\n")
    print(f"# x_scout: {len(tweets)} tweets after filter", file=sys.stderr)


if __name__ == "__main__":
    main()
