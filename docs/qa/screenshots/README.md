# E2E sweep screenshots

Evidence for the findings in `docs/qa/UI_E2E_2026-08-05.md`. Every row in that
table cites a filename from here.

## Why these are gitignored

`docs/qa/screenshots/` is in `.gitignore`. This is deliberate and matches the
precedent set for redesign backups in the root `CLAUDE.md`: several hundred MB
of binary that does not delta-compress would sit in git history permanently, and
the history cost is paid by every future clone.

So these live on disk only. **If you wipe your working copy, they are gone** —
copy the directory elsewhere first if a particular sweep's evidence matters
beyond the life of the fixes. This README *is* tracked, so the pointer survives
even when the images do not.

## Naming

    ui_<lane>_<n>_<what>.png       full resolution, 1170x2532
    ui_<lane>_<n>_<what>_s.png     half size, 585x1266

Both are kept. The half-size images are what the sweep agents actually read
(a full-res 1170px screenshot is unwieldy to reason about), and the table cites
whichever one carried the evidence — so deleting either breaks a citation.

Lanes correspond to the sweep that produced them:

| Lane | Surface |
|---|---|
| `ui_stats_*` | Stats — all tabs, charts, metric cards |
| `ui_settings_*` | Settings — every row and nested screen |
| `ui_library_*` | Exercise Library — browse, search, detail |
| `ui_programs_*` | Programs — library, detail, schedule, variants |
| `ui_nutrition_*` | Nutrition — logging, fasting clock, hydration |
| `ui_home_*` | Home — carousel, coach card, streaks, challenge |
| `ui_coach_*` | Coach — chat, prompts, memory |
| `ui_you_*` | You — overview, profile, rewards |

## Reading one

The images are dark-theme phone screenshots; open them directly, or halve a
full-res one to match what the agent saw:

```bash
python3 -c "from PIL import Image; im=Image.open('X.png'); im.resize((im.width//2, im.height//2)).save('X_s.png')"
```

## Provenance

Captured on a booted iPhone 16e simulator (`E63C5B41-208A-4AED-AC9D-50B82B4CA6F1`)
running a simulator build of `61a495d9`, against the QA account
`zealova.qa.07280102@mailinator.com`. A screenshot alone was never treated as
sufficient evidence for a data claim — table rows pair the image with Supabase
or Render corroboration.
