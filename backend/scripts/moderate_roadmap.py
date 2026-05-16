"""Moderate the public /roadmap board — comments and feature suggestions.

The roadmap comment box is public and unauthenticated (honeypot + rate-limit
guarded, but not spam-proof). This script is the operator tool for the
moderation hooks built into migration 2078:
  - roadmap_comments.is_hidden  — hide a comment from public reads
  - roadmap_suggestions.status  — pending / accepted / declined

Run from the backend/ directory:
    .venv/bin/python scripts/moderate_roadmap.py <command> [args]

Commands:
    comments [slug]                 List recent comments (optionally one feature)
    hide      <comment_id>          Hide a comment from the public board
    unhide    <comment_id>          Un-hide a comment
    suggestions [status]            List suggestions (default: pending)
    accept    <suggestion_id>       Mark a suggestion accepted
    decline   <suggestion_id>       Mark a suggestion declined

Examples:
    .venv/bin/python scripts/moderate_roadmap.py comments
    .venv/bin/python scripts/moderate_roadmap.py hide 1a2b3c4d-...
    .venv/bin/python scripts/moderate_roadmap.py suggestions pending
    .venv/bin/python scripts/moderate_roadmap.py accept 9f8e7d6c-...
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

from core.supabase_client import get_supabase  # noqa: E402


def _trunc(text: str, n: int = 70) -> str:
    text = (text or "").replace("\n", " ").strip()
    return text if len(text) <= n else text[: n - 1] + "…"


def cmd_comments(db, slug: str | None) -> int:
    q = db.client.table("roadmap_comments").select(
        "id, feature_slug, author_name, body, is_hidden, created_at"
    )
    if slug:
        q = q.eq("feature_slug", slug)
    rows = q.order("created_at", desc=True).limit(50).execute().data or []
    if not rows:
        print("No comments found.")
        return 0
    print(f"{len(rows)} comment(s) — newest first:\n")
    for r in rows:
        flag = "  [HIDDEN]" if r.get("is_hidden") else ""
        print(f"  {r['id']}{flag}")
        print(f"    {r['feature_slug']} · {r['author_name']} · {r['created_at'][:16]}")
        print(f"    {_trunc(r['body'])}\n")
    return 0


def cmd_set_hidden(db, comment_id: str, hidden: bool) -> int:
    res = (
        db.client.table("roadmap_comments")
        .update({"is_hidden": hidden})
        .eq("id", comment_id)
        .execute()
    )
    if not res.data:
        print(f"No comment with id {comment_id}.")
        return 1
    print(f"Comment {comment_id} {'hidden' if hidden else 'un-hidden'}.")
    return 0


def cmd_suggestions(db, status: str) -> int:
    rows = (
        db.client.table("roadmap_suggestions")
        .select("id, email, title, body, status, created_at")
        .eq("status", status)
        .order("created_at", desc=True)
        .limit(50)
        .execute()
        .data
        or []
    )
    if not rows:
        print(f"No '{status}' suggestions.")
        return 0
    print(f"{len(rows)} '{status}' suggestion(s) — newest first:\n")
    for r in rows:
        print(f"  {r['id']}")
        print(f"    {r['title']}  ({r['email']} · {r['created_at'][:16]})")
        print(f"    {_trunc(r['body'], 90)}\n")
    return 0


def cmd_set_suggestion_status(db, suggestion_id: str, status: str) -> int:
    res = (
        db.client.table("roadmap_suggestions")
        .update({"status": status})
        .eq("id", suggestion_id)
        .execute()
    )
    if not res.data:
        print(f"No suggestion with id {suggestion_id}.")
        return 1
    print(f"Suggestion {suggestion_id} marked {status}.")
    if status == "accepted":
        print("Next: hand-add it to frontend/src/data/roadmap.ts with a new slug.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Moderate the public /roadmap board.",
        usage=__doc__,
    )
    sub = parser.add_subparsers(dest="command")

    p = sub.add_parser("comments")
    p.add_argument("slug", nargs="?", default=None)
    sub.add_parser("hide").add_argument("comment_id")
    sub.add_parser("unhide").add_argument("comment_id")
    p = sub.add_parser("suggestions")
    p.add_argument("status", nargs="?", default="pending",
                   choices=["pending", "accepted", "declined"])
    sub.add_parser("accept").add_argument("suggestion_id")
    sub.add_parser("decline").add_argument("suggestion_id")

    args = parser.parse_args()
    if not args.command:
        print(__doc__)
        return 1

    db = get_supabase()
    if args.command == "comments":
        return cmd_comments(db, args.slug)
    if args.command == "hide":
        return cmd_set_hidden(db, args.comment_id, True)
    if args.command == "unhide":
        return cmd_set_hidden(db, args.comment_id, False)
    if args.command == "suggestions":
        return cmd_suggestions(db, args.status)
    if args.command == "accept":
        return cmd_set_suggestion_status(db, args.suggestion_id, "accepted")
    if args.command == "decline":
        return cmd_set_suggestion_status(db, args.suggestion_id, "declined")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
