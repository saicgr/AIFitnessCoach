 What the user does separately (not Claude's part)

 1. Buy new domain (Namecheap / Cloudflare / etc.)
 2. Update Vercel project domain (Settings → Domains → set new domain as production)
 3. Update Resend verified-from-domain (Resend dashboard → Domains)
 4. Move frontend/public/.well-known/assetlinks.json and apple-app-site-association to new domain (Vercel
 auto-deploys these)
 5. Update Play Console listing fields (App name, website, privacy URL, support email) — manual UI work
 6. Rebuild AAB locally (flutter build appbundle) and upload to Play Console
 7. Wait for Play to re-index (App Links auto-re-verification: days–weeks; silent fallback to browser in interim)