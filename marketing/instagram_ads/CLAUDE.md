# Instagram Ads — Claude Instructions

Read `marketing/CLAUDE.md` and `instagram_posts/CLAUDE.md` first. Paid creative has different rules than organic.

## Paid vs organic — the key differences

- **Hook window is 1.7 seconds**, not 3. The user has explicit intent to skip ads.
- **Skippability** is the metric Meta cares about. Lower CPM, more delivery.
- **Direct CTA in creative** is fine (and required) — unlike organic where it's penalized.
- **Outbound link is the whole point** — every ad goes to a landing page or App Store listing.
- **Multiple variants required** — Meta needs 3–6 creative variants per ad set to optimize.
- **UGC > polished b-roll** in 2026. Authentic creator-style outperforms studio production by 30–60% on CPI for fitness apps.
- **Captions auto-translate** in some regions — keep English copy short and concrete.

## Required brief fields per ad

Every ad in this folder must have a markdown file with:

```markdown
# Ad: [name]

**Status:** Draft | In Review | Live | Paused | Killed
**Created:** YYYY-MM-DD
**Objective:** App Install | Conversions | Engagement
**Audience:** [exact targeting — age, geo, interests, lookalike %, exclusions]
**Daily budget:** $X
**Bid strategy:** Lowest cost | Cost cap | Bid cap
**Placement:** Feed | Reels | Stories | Explore | All
**UTM:** utm_source=ig_ads&utm_campaign=...&utm_content=[ad_name]
**Landing page:** https://zealova.com/[path]

## Creative

**Format:** Reel (9:16) | Carousel | Single image
**Hook (0:00–0:01.7):** [text on frame + visual]
**Body (0:02–0:10):** [script + b-roll]
**CTA card (0:10–0:12):** [exact CTA wording]
**Voiceover script:** [if any]
**On-screen captions:** yes/no
**Music:** [licensed track or trending audio ID]

## Variants

- Variant A: [hook A]
- Variant B: [different hook, same body]
- Variant C: [different visual, same hook]
- Variant D: UGC creator style, raw phone footage

## Headline + primary text

**Headline (40 chars):** [exact]
**Primary text (125 chars before truncation):** [exact]
**Description (30 chars):** [exact]

## Performance targets

- CPI target: $X
- CTR target: X%
- Hook-rate target: X% (3-sec view rate)
- Hold-rate target: X% (15-sec / 95% view rate)
```

## Hook frameworks (paid)

1. **Pain → reveal** — "Tired of typing 'grilled chicken ~6oz' into MyFitnessPal at every meal? [snap → calories logged]"
2. **Specific contradiction** — "I lost 12 lbs without counting a single calorie. Here's how."
3. **Tool comparison** — "MyFitnessPal vs Zealova: same meal, 10× faster."
4. **Creator testimony** — UGC face-to-camera, raw phone, "I've tried every fitness app. This is the only one that..."

## Visual rules

- **Vertical 9:16, 1080×1920**, 30–60 fps.
- **Text safe zone**: keep all important text inside center 70% (Meta crops top + bottom for some placements).
- **Captions hard-coded** for first 3 seconds even on muted.
- **First frame must include the value prop visually** — not a logo, not a black title card.
- **No more than 20% text overlay** historically; 2026 less strict but still a soft signal.

## Anti-patterns

- Studio-polish lookalike video → CPI 2–3× higher than UGC creator content.
- Static images for app installs → outperformed by Reels 4:1 in fitness vertical.
- Hooks that say "Download now" in first second → Meta skip-rate penalty.
- One creative per ad set → no optimization data, fast burnout.
- No UTM → can't attribute, can't kill bad ads.

## When the user asks for an ad

1. Confirm objective + budget + audience first. No creative without targeting.
2. Run a parallel WebSearch batch (THIS SESSION):
   - `top performing Meta ads creative [Month] [Year] fitness app CPI`
   - `Meta ads UGC vs polished CPI [Month] [Year] fitness`
   - `Meta ads health policy [Year] fitness weight loss claims`
3. Draft brief in the format above.
4. Provide 4 variants (A/B/C/D) by default, not one.
5. Append to `instagram_ads/[ad_name].md` — one file per ad, never one file with many ads. Include the research log at the top.

## Compliance checklist

- [ ] No before/after weight loss claims without disclaimer (Meta health policy)
- [ ] No "lose X lbs in Y days" guarantees
- [ ] No body shaming language
- [ ] Health claims must reference "personalized plan" not medical outcomes
- [ ] App Store / Play Store badges used correctly (Apple HIG, Google brand guidelines)
- [ ] All UGC creators have signed usage rights
