"""
One-shot script to mint an X (Twitter) OAuth 2.0 refresh token for @chetwitt123.

Run this ONCE locally. It will:
  1. Open your browser to X's authorization page
  2. You click "Authorize"
  3. X redirects to http://127.0.0.1:8080/callback (captured by this script)
  4. Script exchanges the code for an access token + refresh token
  5. Script prints the refresh token

Then copy the refresh token into backend/.env as X_REFRESH_TOKEN. The Render
backend reads that on startup and uses it to mint short-lived access tokens
for posting threads.

Prerequisites:
  - backend/.env contains X_CLIENT_ID and X_CLIENT_SECRET
  - X app dashboard has http://127.0.0.1:8080/callback as a Callback URI
  - X app permissions are "Read and write"

Usage:
  cd backend
  .venv/bin/python scripts/x_oauth_bootstrap.py
"""
from __future__ import annotations

import base64
import hashlib
import http.server
import os
import secrets
import sys
import threading
import urllib.parse
import webbrowser
from pathlib import Path

import httpx
from dotenv import load_dotenv

# Load .env from backend/ regardless of CWD
ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(ENV_PATH)

CLIENT_ID = os.environ.get("X_CLIENT_ID")
CLIENT_SECRET = os.environ.get("X_CLIENT_SECRET")
REDIRECT_URI = "http://127.0.0.1:8080/callback"
SCOPES = "tweet.read tweet.write users.read offline.access"
AUTH_URL = "https://x.com/i/oauth2/authorize"
TOKEN_URL = "https://api.x.com/2/oauth2/token"

if not CLIENT_ID or not CLIENT_SECRET:
    sys.exit(
        f"Missing X_CLIENT_ID or X_CLIENT_SECRET in {ENV_PATH}\n"
        "Add them from your X developer dashboard → Keys and tokens → "
        "OAuth 2.0 Client ID and Client Secret."
    )


def _b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


# PKCE: random verifier + S256-hashed challenge so the code-exchange step
# can't be replayed by a passive observer of the redirect URL.
code_verifier = _b64url(secrets.token_bytes(32))
code_challenge = _b64url(hashlib.sha256(code_verifier.encode()).digest())
state = _b64url(secrets.token_bytes(16))

auth_params = {
    "response_type": "code",
    "client_id": CLIENT_ID,
    "redirect_uri": REDIRECT_URI,
    "scope": SCOPES,
    "state": state,
    "code_challenge": code_challenge,
    "code_challenge_method": "S256",
}
authorize_url = f"{AUTH_URL}?{urllib.parse.urlencode(auth_params)}"

# Container for the captured code (HTTP handler writes, main thread reads).
captured: dict[str, str] = {}


class _CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802 (stdlib API)
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/callback":
            self.send_response(404)
            self.end_headers()
            return

        params = urllib.parse.parse_qs(parsed.query)
        if "error" in params:
            captured["error"] = params["error"][0]
            captured["error_description"] = params.get("error_description", [""])[0]
            self.send_response(400)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(
                b"<h1>X authorization failed.</h1>"
                b"<p>Check the terminal for details. You can close this tab.</p>"
            )
            return

        if params.get("state", [""])[0] != state:
            captured["error"] = "state_mismatch"
            self.send_response(400)
            self.end_headers()
            return

        captured["code"] = params.get("code", [""])[0]
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(
            b"<h1>Authorization captured.</h1>"
            b"<p>You can close this tab and return to the terminal.</p>"
        )

    def log_message(self, *_args, **_kwargs):  # silence default access log
        return


def main() -> None:
    server = http.server.HTTPServer(("127.0.0.1", 8080), _CallbackHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()

    print(f"\nOpening browser to authorize @chetwitt123...")
    print(f"If the browser doesn't open, paste this URL manually:\n{authorize_url}\n")
    webbrowser.open(authorize_url)

    print("Waiting for X to redirect back to http://127.0.0.1:8080/callback ...")
    while "code" not in captured and "error" not in captured:
        thread.join(timeout=0.5)

    server.shutdown()

    if "error" in captured:
        sys.exit(
            f"\nAuthorization failed: {captured['error']}\n"
            f"{captured.get('error_description', '')}"
        )

    print("\nAuthorization code captured. Exchanging for tokens...\n")

    auth_header = base64.b64encode(
        f"{CLIENT_ID}:{CLIENT_SECRET}".encode()
    ).decode()

    response = httpx.post(
        TOKEN_URL,
        data={
            "grant_type": "authorization_code",
            "code": captured["code"],
            "redirect_uri": REDIRECT_URI,
            "code_verifier": code_verifier,
        },
        headers={
            "Authorization": f"Basic {auth_header}",
            "Content-Type": "application/x-www-form-urlencoded",
        },
        timeout=30,
    )

    if response.status_code != 200:
        sys.exit(
            f"Token exchange failed ({response.status_code}):\n{response.text}\n"
            "Common causes: Client Secret wrong, callback URI mismatch in X app, "
            "or the code already used (re-run the script for a fresh code)."
        )

    payload = response.json()
    refresh_token = payload.get("refresh_token")
    access_token = payload.get("access_token")
    expires_in = payload.get("expires_in")

    if not refresh_token:
        sys.exit(
            "No refresh_token in response. Make sure 'offline.access' is in "
            "the requested scopes (it is by default in this script).\n"
            f"Response: {payload}"
        )

    print("Refresh token minted successfully.\n")
    print("=" * 70)
    print("Add this line to backend/.env (replace any existing X_REFRESH_TOKEN):")
    print()
    print(f"X_REFRESH_TOKEN={refresh_token}")
    print()
    print("=" * 70)
    print()
    print(f"Access token (expires in {expires_in}s — script does not save this; "
          "the publisher mints fresh ones from the refresh token on demand):")
    print(f"  {access_token[:24]}...")
    print()
    print("Done. The refresh token is long-lived — do NOT commit it to git.")


if __name__ == "__main__":
    main()
