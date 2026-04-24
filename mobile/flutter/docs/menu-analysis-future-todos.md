# Menu Analysis — Future TODOs (not in current sprint)

This file tracks design ideas that are validated but deferred to a later sprint because they require meaningful design + implementation work beyond the current scope.

---

## TODO: Composite "Health Grade" letter + flag row (bigger sprint)

**Idea:** Up top of every dish card, render a single composite **A–E letter grade** (or 0–100 score) summarising the dish's overall health fit for the user. Beneath it, render the existing labeled-pill strip (🔥 Inflammation / 🩸 Blood sugar / 🧡 FODMAP / 🍬 Sugar / 🏭 Ultra-processed) as contextual flags that drove the grade. Tapping the letter opens a breakdown of how each signal contributed.

Inspired by Yuka (100-point composite + detailed component view) and Nutri-Score (A–E letter).

**Why deferred:**
- Requires a weighted-scoring model that adapts to user profile (diabetic → GL weighs more; IBS → FODMAP weighs more; cutting calories → added sugar weighs more). Non-trivial to get right — a bad composite grade is worse than no grade because users trust it.
- Needs UX research: letter vs. 100-point vs. 5-star. Each has different connotations and risks.
- Needs an explainer surface ("Why B+?") that maps each signal's contribution transparently, not as a black-box number.
- Needs to handle personalisation: the same dish should score differently for a bodybuilder vs. a pre-diabetic user.

**What's in the current sprint instead:**
Labeled-pill strip on each dish card — every signal shown with its name + value + color (green/amber/red), horizontally scrollable, each pill tappable for a per-signal explanation. Plus a "Full breakdown →" pill opening a sheet with all signals.

**Pre-requisites before we pick this up:**
1. Ship the current `_HealthStrip` + `HealthBreakdownSheet` + response-schema enforcement so the underlying score data is reliable.
2. Collect a few weeks of logged-dish data to calibrate the weighting.
3. Decide on personalisation axes (diabetes / IBS / goal).
4. User research on letter vs. number vs. star presentation (A/B test in TestFlight).

**Design notes for when we pick this up:**
- Grade should be visible without interaction (top-right of the card, ~32pt).
- Grade color matches the worst-offending signal so a green A never hides a red sub-score.
- Tap the grade → breakdown sheet with a "contribution bar" per signal showing how much it shifted the grade up or down.
- Goal/condition chips ("Showing grade for: Weight loss + Low-FODMAP") at the top of the breakdown so the user sees why this dish's grade is personalised.

**Files likely to change when implemented:**
- `mobile/flutter/lib/data/models/menu_item.dart` — add `compositeGrade` computed getter.
- `mobile/flutter/lib/services/health_grade_service.dart` — NEW, the weighted scoring engine.
- `mobile/flutter/lib/screens/nutrition/widgets/menu_analysis/menu_analysis_item_card.dart` — grade badge top-right.
- `mobile/flutter/lib/screens/nutrition/widgets/health_breakdown_sheet.dart` — contribution bars.
- `backend/api/v1/nutrition/preferences.py` — add user weighting preferences if not already there.

**Ship criteria:**
- Grade must be explainable in one screen.
- Grade must obviously change when user profile changes (demo the before/after).
- A red sub-signal must never be hidden by a green grade.
- Accessibility: letter + color + text label (never color-only).
