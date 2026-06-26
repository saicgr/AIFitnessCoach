-- Migration 2289: Link curated programs to branded_programs variant library
--
-- Adds two nullable FK columns to `programs`:
--   variant_base_id       → branded_programs.id   (which branded catalog this program draws variants from)
--   default_variant_id    → program_variants.id    (the pre-selected variant shown on the detail page)
--
-- Mapping rationale (18 curated published programs → 16 mapped, 2 left NULL as inherently-fixed):
--
--   HYROX Race Prep (8w/4)              → NULL  (HYROX-specific; no branded analogue)
--   HYROX Full Simulation (1w/1)        → NULL  (inherently fixed / single-session)
--   HYROX Pro — Elite Race Build (12w/6) → NULL  (HYROX-specific; no branded analogue)
--   30-Day Plank Challenge (5w/6)       → NULL  (inherently fixed / challenge format)
--   Iron Surge — Heavy Compound (12w/4)      → Functional Strength      (strength/full_body, 4×/wk, [4,8,12]w)
--   Anabolic Foundations (12w/4)             → PHUL                      (upper_lower hypertrophy, 4×/wk, [4,8,12]w)
--   Strong & Steady Women's (12w/4)          → Kettlebell for Women      (equipment_specific women's, 4×/wk, [2,4,8,12]w)
--   Postpartum Rebuild (6w/4)                → New Mom Post-Baby         (life_events postpartum, 4×/wk, [2,4,8,12]w)
--   7-Minute Upper Body (2w/5)               → 7-Minute Scientific       (quick_workout, 5×/wk, [1,2,4]w)
--   7-Minute Lower Body (2w/5)               → 7-Minute Scientific       (quick_workout, 5×/wk, [1,2,4]w)
--   Daily Flow — Yoga for Lifters (4w/5)     → Yoga for Lifters          (yoga/full_body, 4×/wk, [2,4,8]w)
--   Beach Body Ready (12w/5)                 → Beach Body Ready branded  (hypertrophy/circuit, 5×/wk, [4,8,12]w)
--   Lean Burn — Fat-Loss Circuit (8w/4)      → HIIT Burner               (fat_loss/full_body, 4×/wk, [1,2,4,6]w)
--   Starting Strength Foundations (12w/3)    → 5x5 Linear Progression    (strength, 3×/wk, [1,2,4,8,12]w)
--   Push / Pull / Legs Hypertrophy (12w/6)   → Reddit PPL                (reddit_famous/push_pull_legs, 6×/wk, [4,8,12,16]w)
--   Hypertrophy 4-Day Split (12w/4)          → PHUL                      (upper_lower, 4×/wk, [4,8,12]w)
--   Beginner Foundations (8w/3)              → Strength Foundations       (strength/full_body, 3×/wk, [2,4,8]w)
--   No-Equipment Home Workout (8w/4)         → No Equipment Needed        (bodyweight/full_body, 4×/wk, [1,2,4,8]w)

-- ── Step 1: Add columns (idempotent) ────────────────────────────────────────

ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS variant_base_id UUID
    REFERENCES branded_programs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS default_variant_id UUID
    REFERENCES program_variants(id) ON DELETE SET NULL;

-- ── Step 2: Apply the mapping ────────────────────────────────────────────────

-- Iron Surge — Heavy Compound Strength (12w/4)
--   Base:    Functional Strength  (1542cb5b-79b5-4ff0-a752-885e0bd52e46) — strength/full_body, 4×/wk, [4,8,12]w
--   Default: 12w / 4×/wk / Medium  (a26ec776-a20d-4c81-b12d-a2160ff6d7e9)
UPDATE programs SET
  variant_base_id    = '1542cb5b-79b5-4ff0-a752-885e0bd52e46',
  default_variant_id = 'a26ec776-a20d-4c81-b12d-a2160ff6d7e9'
WHERE id = 'd98a7ddc-d55b-4b42-939f-e80f75d4e44e';

-- Anabolic Foundations — Free-Weight Mass (12w/4)
--   Base:    PHUL  (bc9f7b4b-c981-4dc7-b9c9-6d257014ad98) — reddit_famous/upper_lower, 4×/wk, [4,8,12]w
--   Default: 12w / 4×/wk / Medium  (163adba1-d8ef-4bfc-9f54-7918b3bc3aa7)
UPDATE programs SET
  variant_base_id    = 'bc9f7b4b-c981-4dc7-b9c9-6d257014ad98',
  default_variant_id = '163adba1-d8ef-4bfc-9f54-7918b3bc3aa7'
WHERE id = 'ed09f728-640c-4898-aaec-81643b1dd83b';

-- Strong & Steady — Women's Full-Body Strength (12w/4)
--   Base:    Kettlebell for Women  (38a54a79-0228-462a-87db-c5604e0613b0) — equipment_specific, 4×/wk, [2,4,8,12]w
--   Default: 12w / 4×/wk / Medium  (491f6464-6821-4c28-8978-79280ee58b4e)
UPDATE programs SET
  variant_base_id    = '38a54a79-0228-462a-87db-c5604e0613b0',
  default_variant_id = '491f6464-6821-4c28-8978-79280ee58b4e'
WHERE id = '76ff820c-163c-44d5-9c9e-f84e7da311d4';

-- Postpartum Rebuild (6w/4)
--   Base:    New Mom Post-Baby  (2c423f68-6ef1-4db7-a144-53351fcdb19a) — life_events/postpartum, [2,4,8,12]w
--   Default: 4w / 4×/wk / Medium  (ec2e5770-ff3b-4414-8fd9-8fc800cc127f)  — closest available to 6w
UPDATE programs SET
  variant_base_id    = '2c423f68-6ef1-4db7-a144-53351fcdb19a',
  default_variant_id = 'ec2e5770-ff3b-4414-8fd9-8fc800cc127f'
WHERE id = '718331e4-0c06-4538-bded-63362031cdb9';

-- 7-Minute Upper Body (2w/5)
--   Base:    7-Minute Scientific  (48d73c47-eb0f-45e8-bac1-80a0ffca9e5e) — quick_workout/full_body, [1,2,4]w
--   Default: 2w / 5×/wk / Medium  (c7b22765-922e-4434-9fb0-575d00850c44)
UPDATE programs SET
  variant_base_id    = '48d73c47-eb0f-45e8-bac1-80a0ffca9e5e',
  default_variant_id = 'c7b22765-922e-4434-9fb0-575d00850c44'
WHERE id = '0f9d9142-be65-4d13-aafc-223c96867d5c';

-- 7-Minute Lower Body (2w/5)
--   Base:    7-Minute Scientific  (48d73c47-eb0f-45e8-bac1-80a0ffca9e5e) — same base, lower emphasis via selector
--   Default: 2w / 5×/wk / Medium  (c7b22765-922e-4434-9fb0-575d00850c44)
UPDATE programs SET
  variant_base_id    = '48d73c47-eb0f-45e8-bac1-80a0ffca9e5e',
  default_variant_id = 'c7b22765-922e-4434-9fb0-575d00850c44'
WHERE id = '5988380c-defa-49a5-b0d8-83edc2f03d09';

-- Daily Flow — Yoga for Lifters (4w/5)
--   Base:    Yoga for Lifters  (60d16d0f-e522-41b4-ab11-86820d44ca17) — yoga/full_body, 4×/wk, [2,4,8]w
--   Default: 4w / 4×/wk / Medium  (aa81c46d-9504-4d0f-9fbc-67950999b1fd) — closest to 4w/5; 4×/wk available
UPDATE programs SET
  variant_base_id    = '60d16d0f-e522-41b4-ab11-86820d44ca17',
  default_variant_id = 'aa81c46d-9504-4d0f-9fbc-67950999b1fd'
WHERE id = '3132f0e1-c235-48da-ba78-52e4b9704442';

-- Beach Body Ready (12w/5)
--   Base:    Beach Body Ready branded  (13b55297-a3f9-4f0f-b262-b9d33b721691) — hypertrophy/circuit, 5×/wk, [4,8,12]w
--   Default: 12w / 5×/wk / Medium  (80313969-4fe7-423b-8bcd-912a373afbdc)
UPDATE programs SET
  variant_base_id    = '13b55297-a3f9-4f0f-b262-b9d33b721691',
  default_variant_id = '80313969-4fe7-423b-8bcd-912a373afbdc'
WHERE id = '52e8f552-52f0-47bb-9e6c-d6f13a4977d9';

-- Lean Burn — Fat-Loss Circuit (8w/4)
--   Base:    HIIT Burner  (94d77380-dc46-43ba-93b6-089d51983227) — fat_loss/full_body, 4×/wk, [1,2,4,6]w
--   Default: 6w / 4×/wk / Medium  (b7a6b0b7-c657-4536-bfd2-abf84a29a235) — closest available to 8w
UPDATE programs SET
  variant_base_id    = '94d77380-dc46-43ba-93b6-089d51983227',
  default_variant_id = 'b7a6b0b7-c657-4536-bfd2-abf84a29a235'
WHERE id = 'ce4e2196-f35d-440c-a425-880e675699bd';

-- Starting Strength Foundations (12w/3)
--   Base:    5x5 Linear Progression  (b7c92fb7-6850-44b6-af99-9a26ae7a0a1a) — strength, 3×/wk, [1,2,4,8,12]w
--   Default: 12w / 3×/wk / Medium  (d422e54c-45b0-4d56-9bec-f62615ef69ad)
UPDATE programs SET
  variant_base_id    = 'b7c92fb7-6850-44b6-af99-9a26ae7a0a1a',
  default_variant_id = 'd422e54c-45b0-4d56-9bec-f62615ef69ad'
WHERE id = '5886bf32-6ee9-4c17-aa5b-f733bfba3aca';

-- Push / Pull / Legs Hypertrophy (12w/6)
--   Base:    Reddit PPL  (8f5d9c75-28f7-40a6-9466-5efadb341bed) — reddit_famous/push_pull_legs, 6×/wk, [4,8,12,16]w
--   Default: 12w / 6×/wk / Medium  (40d5802a-232a-455d-b779-ecf5dc7eb627)
UPDATE programs SET
  variant_base_id    = '8f5d9c75-28f7-40a6-9466-5efadb341bed',
  default_variant_id = '40d5802a-232a-455d-b779-ecf5dc7eb627'
WHERE id = '8572438b-d394-4d01-bf4e-d9596e5cf7f4';

-- Hypertrophy 4-Day Split (12w/4)
--   Base:    PHUL  (bc9f7b4b-c981-4dc7-b9c9-6d257014ad98) — reddit_famous/upper_lower, 4×/wk, [4,8,12]w
--   Default: 12w / 4×/wk / Medium  (163adba1-d8ef-4bfc-9f54-7918b3bc3aa7)
UPDATE programs SET
  variant_base_id    = 'bc9f7b4b-c981-4dc7-b9c9-6d257014ad98',
  default_variant_id = '163adba1-d8ef-4bfc-9f54-7918b3bc3aa7'
WHERE id = 'b0d8bc88-b9be-4c3c-87e9-18100c9f9f87';

-- Beginner Foundations (8w/3)
--   Base:    Strength Foundations  (29bdab39-7aa8-4cc7-90dc-3027d01bfd46) — strength/full_body, 3×/wk, [2,4,8]w
--   Default: 8w / 3×/wk / Easy  (cf240b01-023c-417b-a5d7-8e258d5862c6)  — only intensity available
UPDATE programs SET
  variant_base_id    = '29bdab39-7aa8-4cc7-90dc-3027d01bfd46',
  default_variant_id = 'cf240b01-023c-417b-a5d7-8e258d5862c6'
WHERE id = 'cc56fab8-c9d4-42f0-936a-ea6975c9d064';

-- No-Equipment Home Workout (8w/4)
--   Base:    No Equipment Needed  (8a00d016-b548-4651-9e23-24fdfc6c9c36) — bodyweight/full_body, 4×/wk, [1,2,4,8]w
--   Default: 8w / 4×/wk / Medium  (4ae8a35c-2042-410e-8e39-131c18244f9b)
UPDATE programs SET
  variant_base_id    = '8a00d016-b548-4651-9e23-24fdfc6c9c36',
  default_variant_id = '4ae8a35c-2042-410e-8e39-131c18244f9b'
WHERE id = 'a616a82c-d9be-4b71-a7ef-7b291ec47107';

-- ── Step 3: Inherently-fixed and HYROX slots — explicit NULL (no-op but documents intent) ──

-- HYROX Race Prep: no branded HYROX variant library → leave NULL
UPDATE programs SET variant_base_id = NULL, default_variant_id = NULL
WHERE id = '28509af5-3ae9-4f3b-a4ad-bbf840798a64';

-- HYROX Full Simulation: single-session fixed program → NULL
UPDATE programs SET variant_base_id = NULL, default_variant_id = NULL
WHERE id = '73d9ec23-5845-498f-8015-e961e141cec5';

-- HYROX Pro — Elite Race Build: HYROX-specific → NULL
UPDATE programs SET variant_base_id = NULL, default_variant_id = NULL
WHERE id = '6348ee98-26a1-4eda-9957-e058de835def';

-- 30-Day Plank Challenge: inherently-fixed daily challenge → NULL
UPDATE programs SET variant_base_id = NULL, default_variant_id = NULL
WHERE id = '6e9539c2-feef-497d-9d0b-8c499838d2f8';
