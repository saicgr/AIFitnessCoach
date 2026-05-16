#!/usr/bin/env bash
# Prebuilt deploy for the Zealova marketing site.
#
# Why this script exists:
#   Vercel's cloud build container OOMs on our 99-route Puppeteer SSG crawl
#   (see scripts/prerender-if-local.mjs), so a plain `vercel --prod` ships a
#   client-rendered SPA — the comparison/blog pages render as an empty JS
#   shell, which LLM crawlers (ChatGPT/Perplexity) may never execute. That
#   silently kills the GEO value of every /vs/ and /blog page.
#
#   This script runs SSG locally, then deploys the prebuilt output, so the
#   pages ship as real server-rendered HTML.
#
# Usage:
#   npm run deploy            # production  (prebuilt + SSG)
#   npm run deploy:preview    # preview     (prebuilt + SSG)

set -euo pipefail

# Always run from the frontend/ directory (this script lives in frontend/scripts/).
cd "$(dirname "$0")/.."

TARGET="${1:-preview}"

if [[ "$TARGET" == "prod" || "$TARGET" == "production" ]]; then
  PROD_FLAG="--prod"
  LABEL="PRODUCTION"
else
  PROD_FLAG=""
  LABEL="preview"
fi

# Warn on uncommitted changes — the prebuilt deploy uploads the working tree,
# so this is informational, not a blocker.
if command -v git >/dev/null 2>&1 && ! git diff --quiet 2>/dev/null; then
  echo "⚠️  Uncommitted changes present — they WILL be included in this $LABEL deploy."
fi

echo "▶ Building prebuilt output ($LABEL) with SSG…"
vercel build $PROD_FLAG

echo "▶ Deploying prebuilt output ($LABEL)…"
# --archive=tgz: the repo exceeds Vercel's 15k loose-file upload limit.
vercel deploy --prebuilt $PROD_FLAG --archive=tgz
