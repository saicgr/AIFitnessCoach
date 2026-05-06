# Marketing — Claude Instructions

This folder holds all of Zealova's social/owned-channel content drafts. Every subfolder has its own CLAUDE.md with platform-specific tactics; this file is the umbrella policy.

## ⚠️ The single most important rule

**Every single time the `social-post-creator` agent is invoked — even if it was invoked 5 minutes ago in the same conversation — it MUST run a fresh batch of WebSearches and append a Research log block (with that day's date and 3+ source URLs) to every post it drafts in `posts.md`.**

No caching. No "I already searched". No "I know the best hashtags for X". Hashtag and algorithm landscapes shift weekly; cached intel is stale by the next session. The Research log is the receipt — its presence on every post is how you (the user) verify fresh research happened.

## Non-negotiable workflow

Before drafting ANY post for ANY platform:

1. **Live research, every session, no cached files.** Run a parallel batch of WebSearches *before writing a single line*. The minimum batch (use the actual current month + year in every query):
   - **Niche keyword trends**: `"AI fitness coach" OR "AI calorie tracker" trending [Month] [Year] indie launch`
   - **Build-in-public sentiment**: `viral build in public post [Month] [Year] indie founder app launch`
   - **Per-platform algorithm rules**: `[platform] algorithm [Month] [Year] reach hooks dwell time`
   - **Per-platform hashtag intel**: `best [platform] hashtags [Month] [Year] AI fitness indie founder`
   - **Per-platform viral examples**: `viral [platform] post [Month] [Year] indie dev launch fitness app`
   - **TikTok / IG Reels only**: also `trending [TikTok|Reels] audio fitness [Month] [Year]`
   - **Reddit only**: also `[chosen subreddit] rules [Year]` and `[chosen subreddit] top posts past month`

   **NEVER cache hashtag sets, trending sounds, or algorithm rules in a static file.** Platforms shift weekly; cached intel is already stale by the next session. The receipts (source URLs) go into the post's research log.
2. **Industry research before claims.** Any stat, rule, or "Google requires X" line must be verified via search. Owning a knowledge gap ("I didn't know") beats inventing facts.
3. **Honesty over hype.** Never claim approvals, milestones, or numbers that haven't happened. "Submitted, waiting" outperforms a fake victory lap on every platform — readers smell embellishment.
4. **One angle per post.** Don't summarize the whole product. Pick: a specific shipping war story, a single feature demo, a single technical insight, or a single metric. Lists die, stories travel.

## File conventions

- Each platform's `posts.md` is dated. Newest at bottom; never overwrite past posts (they're the data we learn from).
- Each draft block must include: **date**, **status** (Drafted / Posted / Result), **plan** (timing, warmup, CTA placement), the **post body**, and after posting a **result** + **postmortem** section.
- If a post tanks, write a 3–5 line postmortem citing the algorithmic / tonal cause. Memory the lesson — don't repeat the failure mode on the next platform.

## Cross-platform rules

| Rule | Why |
|---|---|
| Never copy-paste the same post across platforms | Each platform has different char limits, formatting rules, and audience norms — repurposing requires reshaping, not re-posting. |
| Stagger 3–4 days minimum between platforms | Avoids "content mill" pattern for users who follow you on multiple. |
| Outbound links go in the FIRST COMMENT, not the post body | LinkedIn, X, Instagram, and Reddit all suppress reach when a post links out. The first comment is treated separately. |
| Warm up before posting | 15 min of substantive comments on relevant accounts the same morning. Algorithms reward "active" sessions. |
| First 60–90 minutes after posting decide reach | Reply to every comment within 5 min, pin your own link comment immediately. |
| No more than 2 hashtags on LinkedIn or X | More than 2 = de-rank signal. Instagram is the exception (3–5 niche tags). |
| Engagement-bait CTAs are penalised | "Like if you agree" / "Comment YES" → throttled by NLP detection on LinkedIn and X. Use specific asks ("comment 'checklist' and I'll DM"). |

## Voice for Zealova posts

- First-person, solo founder, vulnerable + tactical. Zealova is "I built", not "we built".
- Numbers > adjectives. "14 days, 15 testers, 1 rule" beats "tough launch journey".
- Stack mentions are fine but not the lede — the lede is the human story.
- Never use the word "AI" as the noun (overused on every platform). Use specifics: "Gemini Vision", "5-agent LangGraph swarm", "Snap a photo, get macros".
- Pricing & roadmap claims must match `project_pricing.md` and `zealova.com/roadmap`.

## What goes where

- `linkedin/` — long-form (1,200–1,500 chars), build-in-public stories, no bullets in week-1 posts after a flop.
- `x/` — threads (4–7 tweets), tactical lessons, `#buildinpublic` ok.
- `reddit/` — community-first; specific subs only (r/IndieHackers, r/flutterdev, r/Fitness, r/loseit, r/PythonProjects). Read sub rules before drafting.
- `instagram_posts/` — Reels-first (7–15 sec), strong visual hook, captions earn the save.
- `instagram_ads/` — paid creative briefs; needs UTM + budget + audience targeting per file.
- `tiktok_videos/` — first 3 seconds is the ad; trending sounds; vertical 9:16 only.

## Memory + feedback files that apply here

- `feedback_dynamic_copy_not_robotic.md` — variant pools, no template-y copy.
- `feedback_share_gallery_viral_templates.md` — 15+ viral formats over 3 polished variations.
- `feedback_design_preferences.md` — rich visuals, industry-researched solutions, not minimal patches.
- `feedback_no_caveats_just_fix.md` — when reviewing a draft and spotting a related issue (wrong claim, weak hook, broken link), fix it inline.

## Definition of done for a post

- [ ] WebSearches run THIS SESSION for current algorithm rules + trending tags + viral hooks (no relying on prior conversation results)
- [ ] Research log appended to the post block in `posts.md` with 3–5 source URLs
- [ ] One specific angle, not a feature dump
- [ ] Angle distinct from the most recent 2 posts on the same platform (verified by reading `posts.md`)
- [ ] First 2 lines pass the "see more" / scroll-stop test
- [ ] No outbound link in body
- [ ] CTA is a specific verb-object ("comment 'checklist'"), not bait
- [ ] Char/length limit verified for the platform
- [ ] Hashtag set chosen from THIS SESSION's research, not memory
- [ ] Posting time matches platform's peak window
- [ ] Warm-up plan + first-hour reply plan written into the draft block

## Required block format in `posts.md`

Every post entry must use this **exact** structure with the `📝 POST CONTENT BELOW` delimiter so the user can scroll straight to the copy-paste-ready body:

```markdown
---

## YYYY-MM-DD — "[short angle name]"

**Status:** Drafted, not yet posted

<details>
<summary>🔬 Research log + plan (click to expand)</summary>

**Research log (YYYY-MM-DD):**
- Algo finding: [1 line — what's working / what changed since last drafting]
- Hashtag finding: [the specific tags chosen + why; volumes if known]
- Trend hook hijack: [any current viral angle being borrowed, or "none — original story"]
- Source links:
  - [URL 1]
  - [URL 2]
  - [URL 3]

**Plan:**
- Day/time: [platform-specific peak window]
- Hashtags: [exact set chosen this session]
- Pre-post warmup: [specific actions]
- First-hour: [specific reply plan]

</details>

### 📝 POST CONTENT BELOW — copy-paste this

[FULL POST BODY VERBATIM]

### 📝 END POST CONTENT
```

The `<details>` collapsible hides the research log + plan by default in any markdown viewer that supports it (GitHub, most IDEs). The `📝 POST CONTENT BELOW` and `📝 END POST CONTENT` markers make the postable section visually obvious even in plain-text editors. **Never put anything outside those markers that isn't research/plan metadata.**
