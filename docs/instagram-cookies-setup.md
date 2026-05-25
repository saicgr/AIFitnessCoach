# Free workaround — Instagram / TikTok cookies for the Imports feature

Instagram and TikTok now block unauthenticated server-IP requests. Without
cookies, `/share/fetch-url` returns `stage:"locked"` and the client UI
falls back to "Paste caption instead?" — about 30–60% of public reels
fetch successfully without auth.

This guide sets up cookie-based auth so `/share/fetch-url` succeeds
~95% of the time for URL-only Instagram shares. **Free**, no proxy.

## Trade-offs you should know up front

1. **Use a dedicated account, not your real one.** Instagram will
   eventually flag this account for "automated behavior" and ban it.
   When that happens, repeat the steps below with a fresh throwaway
   account. **Don't lose your real account over this.**
2. **Cookies rotate every 2–4 weeks.** When `/share/fetch-url` starts
   returning `locked=true` again, your session expired. Re-export and
   re-deploy.
3. **Same throwaway, multiple environments.** Local dev `.env` and
   Render can share the same `INSTAGRAM_COOKIES_B64`. No need for two
   accounts.

---

## 1) Create the throwaway Instagram account

- Sign up at https://instagram.com with a separate email (a Gmail "+" alias
  is fine, e.g. `<yourname>+zealova-bot@gmail.com`).
- Username: anything that doesn't tie back to you.
- Profile: leave it blank. Don't follow anyone, don't post.
- **Skip 2FA** — yt-dlp's cookie auth only handles the session cookie,
  not 2FA challenges.

## 2) Export the cookies (browser path — quickest)

Best browser extension:
**"Get cookies.txt LOCALLY"** by Rahul Shaw — works in Chrome and Firefox,
exports the Netscape-format file yt-dlp expects, runs entirely client-side
(no upload, no telemetry).

- Chrome: https://chrome.google.com/webstore/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc
- Firefox: https://addons.mozilla.org/en-US/firefox/addon/get-cookies-txt-locally/

Steps:

1. Open Chrome / Firefox.
2. Open an **incognito / private window** with the extension allowed in
   incognito mode. Doing this in incognito stops your real browser
   session from getting tied to the throwaway account.
3. Log in to **instagram.com** with the throwaway account.
4. Click the extension icon → "Current site" → **Export → cookies.txt**.
5. Save the file as `instagram_cookies.txt` somewhere local.

Verify the file:

```bash
head -2 instagram_cookies.txt
# Should look like:
# Netscape HTTP Cookie File
# .instagram.com    TRUE    /    TRUE    1769750400    sessionid    ...
```

## 3) Base64-encode the file

Single-line, no wrapping (Render env vars hate newlines):

```bash
# macOS / Linux:
base64 < instagram_cookies.txt | tr -d '\n' > instagram_cookies.b64
wc -c instagram_cookies.b64   # ~2–4 KB usually
```

## 4) Set the env var

### Local (backend/.env)

```bash
echo "INSTAGRAM_COOKIES_B64=$(cat instagram_cookies.b64)" >> backend/.env
```

### Render

1. Render dashboard → backend service → **Environment**.
2. Add new env var:
   - Key: `INSTAGRAM_COOKIES_B64`
   - Value: paste the contents of `instagram_cookies.b64` (one long line)
3. Save. Render will rebuild and restart.

## 5) Verify it works

```bash
backend/.venv/bin/python3 -c "
import asyncio
from dotenv import load_dotenv; load_dotenv('backend/.env')
import sys; sys.path.insert(0, 'backend')
from services.url_content_fetcher import fetch
c = asyncio.run(fetch('https://www.instagram.com/reel/C8K9Wj-IQq3/'))
print('source:', c.source)
print('title:', c.title)
print('caption:', (c.caption or '')[:100])
print('locked:', c.locked)
print('error:', c.error)
"
```

Before cookies:   `source=instagram, locked=True, error="Couldn't access..."`
After  cookies:   `source=instagram, locked=False, title='Video by …', caption='…'`

## 6) When cookies expire (every 2–4 weeks)

You'll start seeing:
- Failed share imports tagged `source=instagram` in `shared_items.status='failed'`
- The local verify script returning `locked=true` again

Fix: log into the throwaway account again, re-export, re-encode, re-set the
env var. Whole process takes about 3 minutes.

A small idea for ops sanity: set up a monthly calendar reminder titled
"refresh IG cookies" — you'll thank yourself.

## TikTok

TikTok blocks by IP, not just auth — cookies help ~50% (much less than IG).
Same procedure with `TIKTOK_COOKIES_B64`. Don't expect 95% reliability;
expect maybe 60%. Most TikTok shares will still fall through to the
"Paste caption?" fallback. Acceptable for a free path.

## When this stops being free enough

If your refresh cadence drops below ~2 weeks (cookies dying fast because
the throwaway account is over-used), it's time to either:

- Rotate to a fresh throwaway account every 2 weeks (free, manual)
- Pay $30-100/month for a residential proxy (Bright Data, Smartproxy)

Telemetry: `SELECT count(*) FROM shared_items WHERE source_origin IN
('instagram','tiktok') AND status='failed' AND created_at > NOW() -
INTERVAL '7 days'` — if that number is climbing, refresh cookies.
