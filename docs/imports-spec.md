# Zealova Imports — what you can share and where it goes

Zealova registers as a system share target on iOS and Android. Anything
you hit Share on — from Photos, Safari, YouTube, Reddit, X, ChatGPT,
Claude, Perplexity, Notes, Voice Memos, Files, iMessage, WhatsApp,
Mail — lands in the right Zealova feature automatically, and shows up
in **Profile → Imports** with a record of when, where it came from, and
what we did with it.

Sharing **from inside** the Instagram or TikTok app works too — iOS /
Android hands us the video file directly. We don't currently promise
URL-only imports from Instagram or TikTok because Meta and Bytedance
aggressively block third-party fetches; in those cases Zealova falls
back to "Paste the caption?" and routes the pasted text instead.

## What you can share — and where it goes

| Format | What it does |
|---|---|
| 📷 Single photo | Food log / Menu scan / Progress / Nutrition label / Equipment / Recipe card — auto-routed by what's in the photo |
| 🖼️ Multi-photo (up to 10) | Batch progress / multi-meal log / carousel — auto-grouped |
| 🎞️ Video (gallery or social) | Form check (≤60 s) / Workout extraction (long video) / Recipe video / Progress reveal |
| 🎙️ Audio / Voice memo | Workout log via voice / Food log via voice / Trainer tips saved |
| 🔗 URL (anywhere on the web) | Recipe sites · YouTube · Reddit · X — each parsed for what it actually contains. Instagram and TikTok URL-pastes are best-effort; share from inside the app for a reliable result. |
| 📝 Text (ChatGPT, Claude, Perplexity, Notes, iMessage) | Workout plans · Recipes · Macros · Meal plans · Tips |
| 📄 PDF | Recipe cookbooks · Workout programs · Lab results · Nutrition guides |

## Limits

| | Limit |
|---|---|
| Photo | 50 MB |
| Carousel | 10 images / 200 MB |
| Video | 500 MB or 30 min |
| Form check | First 60 s analyzed |
| Workout extraction | Up to 60 min (longer → transcript only) |
| Audio | 100 MB or 10 min |
| PDF | 50 MB |
| Daily URL imports | 25 |
| Daily image imports | 50 |
| Daily audio imports | 20 |
| Daily PDF imports | 10 |

Caps are the same for every Zealova user (single-tier Premium). They
exist to keep the AI cost per import predictable, not to gate features.

## How auto-routing works

1. Zealova classifies what's in your share using vision + transcript +
   caption (whichever apply).
2. If we're confident, you land directly on the right screen with
   everything prefilled, plus a 1.8 s "Imported as workout — Change"
   countdown so you can override before it commits.
3. If we're not sure, you see a chooser sheet: **Log food · Save recipe ·
   Check form · Ask coach** plus context chips, with our best guess
   preselected.
4. After auto-route, the destination screen shows a 5-second "Undo"
   snackbar.
5. Every share — whether it succeeded, failed, or you overrode it — is
   logged in **Profile → Imports** with full tags (category · format ·
   source) and a Retry / Reclassify / Delete action sheet.

## Where shares come from

iOS: Photos · Safari · YouTube · Reddit · X · ChatGPT · Claude ·
Perplexity · Notes · Voice Memos · Files · iMessage · WhatsApp · Mail ·
Drive · Dropbox · Apple Shortcuts · Live Text. Sharing **from inside**
the Instagram or TikTok app also delivers the video file directly to
Zealova; URL pastes from those platforms are best-effort.

Android: Gallery · Chrome · YouTube · Reddit · X · Keep · Files ·
WhatsApp · Gmail · Drive. Same Instagram / TikTok note as iOS — share
from inside the app works; URL paste is best-effort.

Web: drag-and-drop at `zealova.com/share`

## App Store compliance note

The YouTube path uses the official YouTube Data API v3 and
`youtube_transcript_api` only — never yt-dlp. Workout/recipe extraction
runs on transcripts and metadata rather than the video bitstream. The
downloaded media path is reserved for Instagram and TikTok (where no
official API exists) and the downloaded files are deleted post-extraction
by the existing media-cleanup cron. Zealova does not surface the
downloaded media back to the user as a saved file.
