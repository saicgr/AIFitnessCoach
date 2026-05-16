# Marketing agent output standard

**Every marketing agent in this folder (strategy/, research/, content/, community/, outreach/) MUST follow this output format.** No exceptions. If you produce output without the three-section preamble below, the run failed — restart.

The point of this standard: make the agent's *reasoning* visible to the human. Burying WebSearch URLs in a footer doesn't prove the agent engaged the trends — it just proves it searched. This format forces the agent to connect (1) what's trending → (2) why it matters for the specific task → (3) what to generate as a result.

---

## Zealova grounding — read this first, every run

Before drafting anything, **every agent MUST read `.claude/agents/marketing/_ZEALOVA_FACTS.md`** (the canonical facts file: features, pricing, platforms, tech stack, wedges, things-we-don't-do, voice).

The output below must:

1. **Reference actual Zealova features** (multi-agent chat · form video analysis · screenshot calorie OCR · AI workout generation · etc.) — never generic "AI fitness app" placeholder language
2. **Use canonical pricing and platforms** from `_ZEALOVA_FACTS.md` §3 — never invent numbers
3. **Use only the wedges in `_ZEALOVA_FACTS.md` §4** — never claim differentiators Zealova doesn't actually have
4. **Avoid the banned-phrases list** in `_ZEALOVA_FACTS.md` §5 — HIPAA, "replaces your trainer," "guaranteed results," etc.
5. **Match the founder-direct voice** in `_ZEALOVA_FACTS.md` §6 — not corporate fluff

If the facts file conflicts with the agent's cached knowledge, **the facts file wins.** Drafts contradicting the facts file get rejected.

---

## The mandatory three-section preamble

Every output (drafted post, comparison page, blog draft, pitch email, shot list, weekly brief, citation snapshot, etc.) begins with these three sections, in order. The draft / actual output comes AFTER.

### Section 1 — Current trends (live research)

Two layers, both required. Pull live this run; cached knowledge is rejected.

```
### 📊 Current trends — researched live YYYY-MM-DD

**Platform / channel trends (last 7 days)** — relevant to this task's channel
- [<source URL>] — <trend, with metric where possible>
- [<source URL>] — <trend>
- (3-6 sources)

**Fitness industry trends (last 7-30 days)** — what's hot in our niche
- [<source URL>] — <trend>
- [<source URL>] — <trend>
- (3-6 sources)

**Competitor moves (last 30 days)** — what Fitbod / Future / Sculptor / etc. did
- [<source URL>] — <observation>
- (1-3 sources, when relevant)
```

For agent-specific Layer-1 search targets, see each agent's "Live WebSearch" workflow step.

### Section 2 — Why these matter for THIS output

Translate each cited trend into a *decision* for the work in front of you. One trend, one rationale line, one arrow.

```
### 🎯 Why these matter

- <trend from §1>  →  <specific decision this drives, e.g. "use this audio in the TikTok export" / "lead the comparison page with this stat" / "skip this Reddit thread because the angle is now stale">
- <trend>  →  <decision>
- <trend>  →  <decision>
- (one bullet per relevant trend; not every cited trend has to translate — but every decision must trace back to a §1 trend)
```

If you can't connect a trend to a decision, drop it from §1. Padding §1 with irrelevant trends just to look thorough is failure.

### Section 3 — What I'm generating because of the above

State, in 3-7 bullets, what the output below contains and why each piece exists. The reader should be able to read just §3 and know what they're getting without scrolling.

```
### 📝 What I'm generating

- <output piece 1> — because <§2 decision>
- <output piece 2> — because <§2 decision>
- <output piece 3> — because <§2 decision>
- (3-7 bullets total)

### 🎯 Zealova grounding check
- Features referenced (from _ZEALOVA_FACTS.md §2): <list>
- Pricing claims (from §3): <verbatim or "n/a">
- Wedges used (from §4): <list>
- Banned phrases avoided (cross-checked §5): ✅
```

---

## Then the actual draft / output

After the three-section preamble, the agent appends its normal output (the post draft, the comparison page, the pitch email, the shot list, etc.) as specified in that agent's own workflow.

---

## Plain-English voice rule (mandatory, every agent, every output)

The user is the founder, not a Claude Code power user. Every output must read like a friend explaining what to do next — not like a developer-tool log. **Banned words and patterns:**

| ❌ Banned | ✅ Use instead |
|---|---|
| "fire <agent>" / "fire the brief" | **"Type this into Claude Code:"** followed by a copy-paste block |
| "dispatch" / "dispatch instructions" | **"What to type next:"** or **"Next prompt to run:"** |
| "hand-off" / "hand-off to <agent>" | **"Next step:"** with the prompt the user pastes |
| "P1 / P2 / P3" without explaining first | **"Pillar 1 (listicles)" / "Pillar 2 (comparison pages)" / "Pillar 3 (Reddit)"** on first mention each output; P1/P2/P3 OK as shorthand AFTER first explanation |
| "A4 / A5 / etc." without explaining | **"Accelerant 4 (Quora)"** on first mention, then A4 OK |
| "specialist agent" | just **the agent name** in plain text, no `<backticks>` framing the user might mistake for typing literally |
| "queue this" / "out the door" / "ship it" | **"do this next"** / **"send these emails"** / **"publish this"** — concrete verbs |
| "doctrine escalation warranted" | **"This is the rule that says we should consider dropping this tactic if X — here's why now"** — explain, don't reference |
| "per §X of <doc>" | **"per the schedule"** or **"per the GEO plan"** — section numbers only as a parenthetical |
| Agent invocation jargon like "invoke" / "trigger" / "route" | just **"to do this, type:"** |

## The copy-paste block format (UPDATED — no blockquote wrapping)

The user's IDE renders blockquoted lines with a `▎` prefix. That breaks copy-paste. **Use plain fenced code blocks. Never wrap them in `>` blockquotes.**

✅ CORRECT format (renders clean, copies clean):

```
**Next step — copy this into Claude Code:**

[triple-backtick]
Find 3 Reddit threads where users are complaining about MyFitnessPal's barcode-scanner paywall
[triple-backtick]
```

❌ BROKEN format (renders with `▎` prefix, copy includes the `>` chars):

```
> **Next step — copy this into Claude Code:**
> [triple-backtick]
> Find 3 Reddit threads...
> [triple-backtick]
```

This rule applies to **everything** the user is meant to copy and paste somewhere external:
- Prompts they paste into Claude Code → plain fenced code block
- Reddit comment/post drafts they paste into Reddit → plain fenced code block, labeled (e.g. "Reply (paste into Reddit, 87 words):")
- DM drafts they paste into IG / TikTok → plain fenced code block
- Pitch emails they paste into Gmail → plain fenced code block
- App Store / Play Store copy they paste into the console → plain fenced code block
- Ad copy variants they paste into Ads Manager → plain fenced code block

Multiple options → numbered headers with one-line rationale before each, each followed by its own plain fenced code block.

## Voice spec — write like Sai writes (binding, all drafted content)

Sai's actual writing style is short, direct, no fancy punctuation. The agents are drafting content the user will copy and post AS THEMSELVES. If it doesn't sound like them, it gets rewritten by the user (waste) or feels off when posted (worse).

**Hard-banned punctuation in any drafted user-facing content** (Reddit comments, DMs, Quora answers, X tweets, pitch emails, ad copy, blog body):

- ❌ **Em dashes (—)** — Sai doesn't use them. Replace with: a period, a comma, or "and"
- ❌ **En dashes (–)** in body prose
- ❌ **Scare quotes around regular words** (e.g. "progress" cards, "AI-native") — just write the word without quotes
- ❌ **Ellipses for dramatic effect** (...) — period instead
- ❌ **Triple-asterisk bolded clauses** in body prose (\*\*\*like this\*\*\*)
- ❌ **Semicolons** in casual platforms (Reddit, DM, X) — split into two sentences

**Allowed:** periods, commas, question marks, regular dashes (- as a list marker only), parentheses sparingly.

**Sentence length:** average 10-18 words. Maximum 25. If a sentence runs longer, split it.

**Tone markers:**
- Casual contractions: "isn't" / "you're" / "I've" / "doesn't" / "won't"
- Lowercase opening OK on TikTok DMs and casual subs (r/IndieHackers, r/SideProject)
- No corporate verbs: leverage, synergy, unlock, empower, revolutionize, transform, elevate, optimize (verb form)
- No essay-voice openers: "The pattern you're describing has a pretty consistent cause at growth-stage companies" → rewrite as "Yeah this is super common at growth-stage apps."
- Concrete examples over abstract patterns
- One emoji max in any drafted user-content, usually zero

## Length spec by content type (binding)

| Content type | Length target | Hard max |
|---|---|---|
| Reddit comment | 50-120 words | 150 |
| Reddit top-level post | 200-450 words | 600 |
| Reddit Saturday self-promo | 100-200 words | 250 |
| IG / TikTok DM | 40-90 words | 110 |
| Quora answer | 150-280 words | 350 |
| X tweet | 1-3 sentences | 280 chars |
| X thread (per tweet) | same as above × N | — |
| LinkedIn post | 80-180 words | 250 |
| Pitch email (listicle/review) | 60-130 words | 150 |
| Ad copy (caption) | 15-50 words | 90 |
| App Store subtitle | ≤30 chars | hard |
| App Store description (long) | 700-1500 chars | 4000 |
| Blog post body | 1500-2500 words | 3500 (different format, voice still applies) |

If a draft exceeds the target, the agent must cut it before showing the user. Tell the user "trimmed from 187 to 95 words for r/loseit voice match."

## Worked rewrite — bad vs good (your actual MFP draft)

❌ **BAD (LLM voice, 187 words, em dashes, scare quotes):**

> The pattern you're describing has a pretty consistent cause at growth-stage companies: the team optimizing for new-user activation and the team serving existing power users usually aren't the same people, and the activation team's metrics win because they're tied directly to subscriber growth numbers.
>
> MFP's diary was built for people who log every meal every day. The Today tab redesign reads like it was designed for someone opening the app for the first time — visible "progress" cards, big visual prompts to log, that sort of thing.

✅ **GOOD (Sai-voice, 90 words, no em dashes, no scare quotes, shorter sentences):**

```text
Yeah this is super common at growth-stage apps. The team trying to get new users to sign up isn't the same team serving people who've been logging daily for years, and the new-user team usually wins because their numbers tie straight to subscriber growth.

MFP's diary was built for daily power users. The new Today tab looks like it was designed for someone opening the app for the first time. Useful for week-one. Friction if you've been logging three years.

For alternatives, MacroFactor is the honest pick for pure macro tracking. Their algorithm actually adjusts based on your real results. Cronometer if micros matter. Both are tracker-only though.

I'm building Zealova and added a screenshot feature for exactly this. You photograph your MFP diary page and it pulls the foods and macros automatically. So you don't have to re-enter years of data if you want to switch.
```

Differences:
- 90 words instead of 187
- Zero em dashes (replaced with periods and commas)
- No scare quotes
- "super common at growth-stage apps" instead of "pretty consistent cause at growth-stage companies"
- Sentences split where they ran long
- Same information, conversational delivery

## Worked example — bad vs good

❌ **BAD (jargon, no prompt — user has to translate):**
> Most leveraged thing you could do today (≤30 min): dispatch reddit-agent in scout mode to find 3 MFP-frustration threads. That window closes fast; the Google Health one (P2 comparison frame) can wait 1-2 days.

✅ **GOOD (plain English + literal copy-paste prompt right there):**
> **Most leveraged thing today (≤30 min): find 3 Reddit threads where users are complaining about MyFitnessPal's barcode-scanner paywall. The complaint window closes fast — replies posted within 24-48h of the original thread get ~10× the upvotes of late replies.**
>
> **To do it, copy this into Claude Code:**
> ```
> Find 3 Reddit threads where users are complaining about MyFitnessPal's barcode-scanner paywall
> ```
>
> The Google Health Connect angle (which would become a comparison-page topic) can wait 1-2 days. For that one later, the prompt would be:
> ```
> Profile Google Fit / Health Connect as a competitor wedge
> ```

❌ **BAD:** Recommended next move: fire the weekly brief to get the first P1 listicle dispatch out the door.

✅ **GOOD:**
> **Next step — to get a full week-plan, copy this into Claude Code:**
> ```
> Run the weekly GEO cadence
> ```
> That returns 3-5 specific copy-paste prompts (listicle pitches, next comparison page, Reddit threads).

---

## ⚠️ Source traceability rule (binding, all agents)

Every actionable item in your output must answer THREE questions, not two:

1. **WHAT** — what is the action?
2. **WHERE** — the specific URL / profile / file path / screenshot / thread / article / sound / DB row this refers to. **Live-verified this run via WebFetch / WebSearch / file read.** Not a hypothetical.
3. **HOW** — the literal copy-paste prompt that triggers it.

If you can't supply WHERE, you cannot draft the WHAT. You must either:
- **(a)** Run a scout/search first this same run to find the WHERE, return real candidates with URLs, and ask the user to pick — OR
- **(b)** Stop and tell the user "I need a specific URL / profile / file before drafting — paste it and re-run."

**Never draft a reply to a hypothetical thread, a pitch to a hypothetical writer, an answer to a hypothetical Quora question, a DM referencing a hypothetical post, a Reel using hypothetical trending audio, or an ASO change to a hypothetical screenshot.** Hallucinated targets produce drafts the user can't act on.

### Per-agent "WHERE" examples (what counts as a valid identifier)

| Agent | WHERE means |
|---|---|
| `reddit-agent` (write) | Live thread URL (WebFetched this run) + post date + OP author handle + first 2-3 existing top comments |
| `reddit-analyzer` | User-pasted text/screenshot/URL — agent never invents threads |
| `outreach-agent` (listicle) | Article URL + writer's full name + writer's email (verified pattern + Hunter.io check) + 1 specific recent piece by that writer |
| `outreach-agent` (review) | Same — staff writer's name + email + recent article URL |
| `creator-outreach` (DMs) | Creator handle + platform + follower count (verified via profile fetch) + URL to specific recent post being referenced |
| `competitor-intel` | Competitor homepage URL + pricing page URL + App/Play Store listing URL + 1-2 recent Reddit/review URLs, each with verification date |
| `comparison-page-writer` | All claims about competitor cite a source URL from `competitor-intel` profile + verification date |
| `blog-writer` | Every stat cites a source URL (study, article, dataset); every competitor claim → source URL |
| `quora-and-forum-agent` | Question URL + question view count + top existing answer summary |
| `reels-producer` (shot list) | Trending audio name + URL (TikTok Creative Center / IG / tokboard) + use-count past 7 days |
| `reels-producer` (repurpose) | Source clip ID from posted-log + URL/path to the original; trending audio URL per platform |
| `aso-optimizer` (audit) | Live App Store + Play Store listing URLs + screenshot of current state + competitor listing URLs being compared against |
| `aso-optimizer` (refresh) | Specific file path or App Store Connect field being rewritten; current text shown as "before" |
| `ad-creator` (variant) | Source organic clip URL from reels posted-log; platform-specific trending audio URL; targeting parameters verified against current platform docs |
| `keyword-researcher` | Every volume estimate cites the source tool (Ahrefs free / SE Ranking / Keyword Tool / Reddit thread count) with date |
| `citation-tracker` | Every score cites the query run + screenshot or text excerpt of the result |
| `social-post-creator` | Every trending hashtag cites where it's trending; every algorithm claim cites a 2026 source |
| `geo-strategist` | Every recommended action's copy-paste prompt includes specifics drawn from real data found this run (e.g. specific competitor name, specific thread URL the user can verify) |

### Worked example — what the reddit-agent bug should have produced

**❌ What happened (no thread URL, hallucinated target):**
> Draft (187 words, ready to copy):
> "The pattern you're describing has a pretty consistent cause at growth-stage companies..."
> Before posting (2 min check): open the thread, scan existing comments...

User reaction: "but idk which post do I reply to? do I need to search it myself?" ← the bug

**✅ What should have happened (scout-first fallback, real URLs):**
> No specific thread URL was provided, so I ran scout mode first this run. Here are 3 live MyFitnessPal-frustration threads (verified <date>) ranked by reply leverage:
>
> 1. **r/loseit — "MFP put barcode scanner behind paywall, what now?"** — 240 comments, posted 2026-05-12, [URL]. Promo rules: answer-only sub, no link allowed but mentions OK.
> 2. **r/Fitness — "Anyone else canceling MFP Premium?"** — 87 comments, posted 2026-05-13, [URL]. Saturday self-promo thread only; mention OK in comments without link.
> 3. **r/xxfitness — "Best free MFP alternative?"** — 32 comments, posted 2026-05-11, [URL]. NEVER link the app; answer-only.
>
> **To draft a reply to thread #1, copy this into Claude Code:**
> ```
> Reply to this thread for me: https://reddit.com/r/loseit/comments/abc123/mfp_put_barcode_scanner_behind_paywall
> ```

That's the difference. Real URLs you can click, verify, and act on.

---

## ⚠️ MANDATORY pre-submit checklist (run this BEFORE finalizing output)

Before you finalize output, scan your draft and confirm EACH item below. If any one fails, restart that section.

**Source traceability (most important):**
- [ ] **Every actionable item has a WHERE** — a real URL / profile / file path / screenshot / identifier, verified live this run. No hypothetical targets.
- [ ] **Every URL cited is from this run's WebFetch / WebSearch / file read** — not invented, not from training data.
- [ ] **If I couldn't find a real WHERE for an action**, I either ran a scout-first fallback (returned real candidates and asked user to pick) or stopped and asked the user for the missing identifier. I did NOT draft for a hypothetical target.

**Dates (NEW — required on every claim):**
- [ ] **Every claim about a competitor move / launch / article / trend / Reddit thread / news event has its actual date inline**, in format `(published YYYY-MM-DD)` or `(launched YYYY-MM-DD)` or `(posted YYYY-MM-DD)`.
- [ ] **For news/launches/articles found via WebSearch, I verified the publish date** (WebFetched the page if WebSearch didn't surface a date, or checked the article header). I did NOT assume "recent" because the result came back today.
- [ ] **For Reddit threads, the post date AND age in days** are shown — "posted 2026-05-11, 3d ago".
- [ ] **For competitor features, the launch date** is shown — distinguishing genuinely-new moves (within the past 14 days) from old features I happened to learn about today. A feature launched 3+ months ago that the agent only just discovered is NOT a this-week move — it goes in the sustained-ongoing context section, not the urgent-this-week section.
- [ ] **The "Biggest moves this week" section excludes anything older than 14 days** unless it's a sustained ongoing story (in which case label it "ongoing since YYYY-MM-DD").
- [ ] **Trending audio / hashtags / formats** are labeled with when they started trending — "rising since YYYY-MM-DD" or "peaked YYYY-MM-DD".

**Plain-English (existing):**
- [ ] **No banned words appear**: "fire", "dispatch", "hand-off", "specialist agent", "invoke", "trigger" (the verb, not the noun), "queue this", "out the door"
- [ ] **Every time you mention another agent's name** (e.g. "reddit-agent", "outreach-agent"), the SAME line or the next line includes a literal copy-paste prompt block
- [ ] **Every "next step" / "recommended action" / "do this" / "most leveraged thing" closes with a copy-paste prompt block** — no abstract advice
- [ ] **First mention of any pillar (P1/P2/P3) or accelerant (A4-A10)** is preceded by its plain-English meaning
- [ ] **The copy-paste prompts are complete and standalone, with specifics** (e.g. `Reply to this thread for me: https://reddit.com/r/loseit/comments/abc123`, NOT `Run reddit-agent in scout mode`)
- [ ] **The output ends with a "What to do next" section** that lists 1-3 prompts numbered, each with a one-line rationale

If ANY checkbox fails, the user has to translate your output OR do their own search — that's a failed run. Rewrite.

**Voice + length (NEW — applies to all drafted user-content):**
- [ ] **Zero em dashes (—)** in any drafted Reddit/DM/Quora/X/LinkedIn/pitch/ad content. Search the draft for `—` and replace with periods/commas before submitting.
- [ ] **Zero scare quotes** around regular words (e.g. "progress" cards, "AI-native"). Quotes only allowed for actual user quotes.
- [ ] **No ellipses** in drafts (... → period)
- [ ] **No corporate verbs**: leverage, synergy, unlock, empower, revolutionize, transform, elevate, optimize (verb)
- [ ] **Sentence length avg 10-18 words**, max 25. Long ones split.
- [ ] **Length within target** for the content type (see length spec table). Drafts that exceed target are trimmed before showing user — tell user the trim count ("trimmed from 187 to 95 words").

**Copy-paste rendering (NEW — formatting):**
- [ ] **Every copy-paste block uses a plain fenced code block** (triple-backtick), NOT a `>` blockquote. Blockquoted code renders with `▎` prefix in the user's IDE and the prefix gets included when they copy.
- [ ] **The fenced code block contains only the content the user pastes elsewhere** — no surrounding commentary, no "..." truncation. Full pasteable text.
- [ ] **A label precedes each code block** in plain text (not blockquoted), e.g. `**Reply (paste into r/loseit, 87 words):**` followed by the code block on the next line.

If ANY of these fail, rewrite.

---

## Hand-off / "what to do next" note (always last)

Every output ends with a "what to do next" section, in plain English. Format:

```
### What to do next

**Option 1 — <plain-English description of the action>** (recommended)
Copy this into Claude Code:
```
<exact prompt the user pastes>
```
<one-line rationale>

**Option 2 — <if applicable, alternative action>**
Copy this into Claude Code:
```
<exact prompt>
```
<one-line rationale>

**Files updated this run:**
- `docs/planning/marketing/<area>/<file>.md`
- `<frontend path if applicable>`
```

Never leave the user with abstract advice. Always end with a copy-paste prompt block.

---

## Why this standard exists

1. **Forces real reasoning, not URL dumps.** A "Research log" footer can be done with five `WebSearch` calls and zero engagement. The §1 → §2 → §3 chain can't be faked — if §2 is empty or §3 doesn't trace back to §1, the agent didn't think.
2. **Lets the human sanity-check in 10 seconds.** Reading §1-§3 reveals whether the output matches current reality. If TikTok's hot audio this week is X but the agent's TikTok caption uses Y from last month, the human catches it before posting.
3. **Compounds across agents.** When `competitor-intel` flags Fitbod's price hike, `comparison-page-writer` reads the intel block, sees the §1 trend, and §2 connects "Fitbod raised to $X → highlight Zealova's price wedge in TL;DR table." Output quality improves run over run.
4. **Future-proofs against model drift.** Even when underlying model knowledge gets stale, the §1 trends scan re-anchors every run on live reality.

## What this DOES NOT replace

- Each agent's own non-negotiable workflow steps (load context, sub-rules check, scout vs write mode, etc.)
- Each agent's hard rules / anti-patterns
- The per-agent output template (table structure, schema embeds, etc.) — those still apply; the three-section preamble is *added on top*

## When the standard relaxes

- **Spot-check / quick-status calls** (e.g., `geo-strategist`'s daily 5-min ritual, `citation-tracker` spot checks): one combined section with all three layers in 5-10 total bullets is fine. The discipline still holds; the volume relaxes.
- **Pure rules-mode calls** (e.g., `reddit-agent` checking sub promo rules): §1 layer-1 only (the source page), §2 ("rule says X → can/can't post"), §3 (file updated). Skip layer-2 fitness-industry scan since it's not relevant.

Otherwise: full three-section preamble, every run.

---

**Version:** 1.0 — 2026-05-12
**Applies to:** all 12 agents in `.claude/agents/marketing/{strategy,research,content,community,outreach}/`
