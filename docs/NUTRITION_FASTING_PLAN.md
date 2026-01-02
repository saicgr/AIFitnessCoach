# MacroFactor vs FitWiz: Nutrition Feature Comparison & Analysis

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Feature Comparison Matrix](#feature-comparison-matrix)
3. [Current App Architecture](#current-ai-fitness-coach-nutrition-architecture)
4. [Implementation Plan](#implementation-plan)
5. [NEW: Nutrition Onboarding Flow](#nutrition-onboarding-flow)

---

## Executive Summary

This document compares MacroFactor (a premium nutrition tracking app with 75,000+ subscribers) against the current FitWiz app's nutrition features and Supabase database schema.

---

## MacroFactor Overview

**Company:** Stronger by Science Technologies (founded by Greg Nuckols, Jeff Nippard, and team)
**Launch:** September 2021
**Pricing:** $11.99/month or $71.99/year (no free tier)
**Ratings:** 4.7-4.8/5 stars on both app stores
**Users:** 75,000+ subscribers, 100,000+ downloads

### Core Value Proposition
MacroFactor's key differentiator is its **adaptive expenditure algorithm** that calculates true TDEE from actual intake/weight data rather than generic formulas. It's "adherence-neutral" - no penalties for going over targets.

---

## Feature Comparison Matrix

| Feature | MacroFactor | FitWiz | Gap Analysis |
|---------|-------------|------------------|--------------|
| **Food Logging - Text** | AI Describe (voice/text) | ✅ Gemini text parsing | Parity |
| **Food Logging - Image** | AI Photo recognition (beta) | ✅ Gemini Vision | Parity |
| **Food Logging - Barcode** | Scanner + label fallback | ✅ OpenFacts integration | Parity |
| **Food Database** | 1.15M+ verified foods | OpenFacts (third-party) | Gap: No proprietary verified DB |
| **Macros** | Protein, Carbs, Fat | ✅ P/C/F + Fiber | Parity |
| **Micronutrients** | 40+ with floor/target/ceiling | ✅ 40+ with RDA | Minor gap: 3-tier goal system |
| **Nutrient Contributors** | Shows top foods per nutrient | ✅ `getNutrientContributors()` | Parity |
| **Pinned Nutrients** | Customizable | ✅ Default: D, Ca, Fe, Omega-3 | Parity |
| **Recipes** | Full recipe builder | ✅ `user_recipes` table | Parity |
| **Recipe Sharing** | Share via text/email | Schema supports (`is_public`) | Not implemented in UI |
| **Saved Foods/Favorites** | Quick re-logging | ✅ `saved_foods` table | Parity |
| **AI Coaching/Feedback** | Weekly check-ins, coaching modules | ✅ Real-time chat + `ai_feedback` | **Advantage: Real-time AI** |
| **Adaptive Algorithm** | Dynamic TDEE from weight trends | ❌ Static targets | **Major Gap** |
| **Weight Tracking** | Trend weight smoothing | ❌ Not in nutrition flow | Gap |
| **Weekly Check-ins** | Auto-adjusts macros | ❌ Manual targets only | Gap |
| **Progress Photos** | 3 views + before/after | ❌ Not implemented | Gap |
| **Body Measurements** | 21 body metrics | ❌ Not implemented | Gap |
| **Workout Integration** | Separate app (coming 2026) | ✅ **Integrated workouts** | **Major Advantage** |
| **Desktop/Web** | Not available | Not available | Parity |
| **Timeline vs Meal Buckets** | Timeline-based | Meal-type buckets | Different approach |

---

## Current FitWiz Nutrition Architecture

### Flutter Models (`lib/data/models/`)

| File | Purpose |
|------|---------|
| `nutrition.dart` | FoodItem, FoodLog, DailyNutritionSummary, NutritionTargets, BarcodeProduct, SavedFood |
| `micronutrients.dart` | MicronutrientData (40+ nutrients), NutrientRDA, NutrientProgress, DailyMicronutrientSummary |
| `recipe.dart` | Recipe, RecipeIngredient, RecipeSummary with full nutrition per serving |

### Flutter Screens (`lib/screens/nutrition/`)

| Screen | Features |
|--------|----------|
| `nutrition_screen.dart` | 3 tabs (Daily/Nutrients/Recipes), energy balance card, macro cards, meal sections |
| `nutrient_explorer.dart` | Pinned nutrients, top contributors, category grouping |
| `log_meal_sheet.dart` | Text/Image/Barcode input, streaming AI analysis, save as favorite |
| `recipe_builder_sheet.dart` | Ingredient list, auto-calculated nutrition, categories/tags |

### Supabase Tables

| Table | Key Fields |
|-------|------------|
| `users` | daily_calorie_target, daily_protein/carbs/fat_target_g |
| `food_logs` | meal_type, food_items JSONB, total_macros, ai_feedback, health_score |
| `saved_foods` | name, source_type, nutrition, goal_alignment_percentage, times_logged |
| `user_recipes` | ingredients, nutrition_per_serving, micronutrients_per_serving JSONB |
| `recipe_ingredients` | food_name, amount, unit, full nutrition breakdown |

---

## What MacroFactor Does Better

### 1. Adaptive Expenditure Algorithm (Major Gap)
- Calculates true TDEE from weight trends vs intake data
- Weekly auto-adjusts calories/macros based on actual progress
- ~2x more accurate than static TDEE formulas
- **Recommendation:** Implement weight tracking integration + adaptive target algorithm

### 2. Three-Tier Nutrient Goals
- Floor (minimum to avoid deficiency)
- Target (RDA)
- Ceiling (upper safe limit)
- **Current:** Single RDA target only
- **Recommendation:** Add floor/ceiling thresholds to `NutrientRDA`

### 3. Progress Tracking Suite
- 21 body measurements
- Progress photos (3 views)
- Before/after image generation
- **Recommendation:** Add body metrics table and progress photo integration

### 4. Verified Food Database
- 1.15M+ verified entries (vs user-generated)
- **Current:** Relies on OpenFacts
- **Recommendation:** Consider licensing USDA FoodData Central

### 5. Faster Logging UX
- 10 taps for food search (vs 15+ for competitors)
- Timeline-based (no meal categorization required)
- **Recommendation:** Optimize logging flow, consider timeline approach

---

## What FitWiz Does Better

### 1. Integrated Workouts (Major Advantage)
MacroFactor is nutrition-only; separate workout app coming 2026. FitWiz has **workout generation + tracking built-in**.

### 2. Real-Time AI Coaching
MacroFactor uses weekly automated check-ins. FitWiz has **real-time conversational AI** via Gemini chat.

### 3. Goal-Aligned Scoring
- `goal_alignment_percentage` on every meal
- `health_score` (1-10) with AI reasoning
- `ai_suggestion` for improvements
- **MacroFactor doesn't score individual meals**

### 4. Flexible Pricing Model
MacroFactor has no free tier. FitWiz could offer freemium.

---

## Recommended Feature Additions (Priority Order)

### High Priority
1. **Weight Tracking in Nutrition Flow** - Add weight logging, trend smoothing
2. **Adaptive Calorie Adjustment** - Implement algorithm based on weight trends
3. **Weekly Nutrition Check-ins** - Auto-suggest target adjustments

### Medium Priority
4. **Progress Photos** - Add photo capture with before/after comparison
5. **Body Measurements** - 10-15 key metrics (waist, chest, arms, etc.)
6. **Three-Tier Nutrient Goals** - Floor/target/ceiling for micronutrients

### Lower Priority
7. **Recipe Sharing UI** - Enable `is_public` feature in UI
8. **Timeline-Based Logging** - Alternative to meal buckets
9. **Voice Logging** - Add speech-to-text for food descriptions

---

## Database Schema Additions Needed

```sql
-- Weight tracking
CREATE TABLE weight_logs (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  weight_kg DECIMAL NOT NULL,
  logged_at TIMESTAMP NOT NULL,
  source TEXT DEFAULT 'manual', -- manual, apple_health, etc.
  notes TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Body measurements
CREATE TABLE body_measurements (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  measured_at TIMESTAMP NOT NULL,
  waist_cm DECIMAL,
  chest_cm DECIMAL,
  hips_cm DECIMAL,
  left_arm_cm DECIMAL,
  right_arm_cm DECIMAL,
  left_thigh_cm DECIMAL,
  right_thigh_cm DECIMAL,
  -- ... more fields
  created_at TIMESTAMP DEFAULT now()
);

-- Progress photos
CREATE TABLE progress_photos (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  photo_url TEXT NOT NULL,
  view_type TEXT NOT NULL, -- front, side, back
  taken_at TIMESTAMP NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT now()
);

-- Adaptive targets (calculated weekly)
CREATE TABLE adaptive_nutrition_targets (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  week_start DATE NOT NULL,
  calculated_tdee INTEGER,
  recommended_calories INTEGER,
  recommended_protein_g DECIMAL,
  recommended_carbs_g DECIMAL,
  recommended_fat_g DECIMAL,
  weight_trend_direction TEXT, -- losing, maintaining, gaining
  confidence_score DECIMAL,
  created_at TIMESTAMP DEFAULT now()
);
```

---

---

## Implementation Plan

### Phase 1: Weight Tracking & Trend Analysis (Foundation)

**Goal:** Enable weight logging with trend smoothing - the foundation for adaptive algorithms.

#### 1.1 Database Migration
Create `backend/migrations/XXX_weight_tracking.sql`:
```sql
CREATE TABLE weight_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  weight_kg DECIMAL(5,2) NOT NULL,
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
  source TEXT DEFAULT 'manual',
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_weight_logs_user ON weight_logs(user_id);
CREATE INDEX idx_weight_logs_user_date ON weight_logs(user_id, logged_at DESC);

-- RLS policies
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY weight_logs_user_policy ON weight_logs
  FOR ALL USING (auth.uid() = user_id);
```

#### 1.2 Flutter Model
Create `lib/data/models/weight.dart`:
- `WeightLog` - id, weight_kg, logged_at, source, notes
- `WeightTrend` - calculated trend weight, rate of change, direction

#### 1.3 Flutter Repository
Add to `lib/data/repositories/nutrition_repository.dart`:
- `logWeight(weight_kg, logged_at)`
- `getWeightLogs(startDate, endDate)`
- `getWeightTrend()` - smoothed trend calculation

#### 1.4 Flutter UI
Add to `lib/screens/nutrition/`:
- Weight logging widget (quick entry card)
- Weight history chart (line graph with trend line)
- Integration into nutrition_screen.dart

**Files to modify:**
- `backend/migrations/` - new migration
- `lib/data/models/weight.dart` - new file
- `lib/data/repositories/nutrition_repository.dart`
- `lib/screens/nutrition/nutrition_screen.dart`

---

### Phase 2: Body Measurements & Progress Photos

**Goal:** Track physical progress beyond the scale.

#### 2.1 Database Migration
Create `backend/migrations/XXX_body_metrics.sql`:
```sql
CREATE TABLE body_measurements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  measured_at TIMESTAMP WITH TIME ZONE NOT NULL,
  waist_cm DECIMAL(5,2),
  chest_cm DECIMAL(5,2),
  hips_cm DECIMAL(5,2),
  neck_cm DECIMAL(5,2),
  left_bicep_cm DECIMAL(5,2),
  right_bicep_cm DECIMAL(5,2),
  left_forearm_cm DECIMAL(5,2),
  right_forearm_cm DECIMAL(5,2),
  left_thigh_cm DECIMAL(5,2),
  right_thigh_cm DECIMAL(5,2),
  left_calf_cm DECIMAL(5,2),
  right_calf_cm DECIMAL(5,2),
  shoulders_cm DECIMAL(5,2),
  body_fat_percentage DECIMAL(4,2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE progress_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  view_type TEXT NOT NULL CHECK (view_type IN ('front', 'side', 'back')),
  taken_at TIMESTAMP WITH TIME ZONE NOT NULL,
  measurement_id UUID REFERENCES body_measurements(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

#### 2.2 Flutter Models
Create `lib/data/models/body_metrics.dart`:
- `BodyMeasurement` - all 15 measurements
- `ProgressPhoto` - url, view_type, taken_at
- `BodyMetricComparison` - two dates side-by-side

#### 2.3 Flutter Screens
Create `lib/screens/progress/`:
- `progress_screen.dart` - tabs for Measurements/Photos
- `log_measurement_sheet.dart` - input form
- `take_photo_sheet.dart` - camera integration
- `comparison_view.dart` - before/after generator

**Files to create:**
- `backend/migrations/XXX_body_metrics.sql`
- `lib/data/models/body_metrics.dart`
- `lib/data/repositories/body_metrics_repository.dart`
- `lib/screens/progress/` - new directory with 4 screens

---

### Phase 3: Adaptive TDEE Algorithm

**Goal:** Implement MacroFactor-style adaptive calorie recommendations.

#### 3.1 Algorithm Logic (Backend)
Create `backend/api/v1/adaptive_nutrition.py`:
```python
def calculate_tdee(user_id, days=14):
    """
    TDEE = Calories In - (Weight Change * 7700 kcal/kg)

    Uses trend weight to smooth fluctuations.
    Requires: 6+ days of food logs, 2+ weight entries per week.
    """

    # 1. Get food logs for period
    # 2. Get weight logs, calculate trend weights
    # 3. Calculate average intake
    # 4. Calculate rate of weight change
    # 5. Back-calculate TDEE
    # 6. Apply confidence scoring based on data quality
```

#### 3.2 Database Migration
Create `backend/migrations/XXX_adaptive_targets.sql`:
```sql
CREATE TABLE adaptive_nutrition_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  calculated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  avg_daily_intake INTEGER,
  start_trend_weight_kg DECIMAL(5,2),
  end_trend_weight_kg DECIMAL(5,2),
  calculated_tdee INTEGER,
  data_quality_score DECIMAL(3,2), -- 0-1
  days_logged INTEGER,
  weight_entries INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE weekly_nutrition_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  current_goal TEXT, -- 'lose', 'maintain', 'gain'
  target_rate_per_week DECIMAL(4,2), -- kg per week
  calculated_tdee INTEGER,
  recommended_calories INTEGER,
  recommended_protein_g INTEGER,
  recommended_carbs_g INTEGER,
  recommended_fat_g INTEGER,
  adjustment_reason TEXT,
  user_accepted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

#### 3.3 Weekly Check-In Flow
Create `lib/screens/nutrition/weekly_checkin_sheet.dart`:
- Show progress summary (weight change, avg intake)
- Display calculated TDEE and confidence
- Recommend new targets with reasoning
- Accept/modify/decline options

**Files to create:**
- `backend/api/v1/adaptive_nutrition.py`
- `backend/migrations/XXX_adaptive_targets.sql`
- `lib/data/models/adaptive_targets.dart`
- `lib/screens/nutrition/weekly_checkin_sheet.dart`

---

### Phase 4: Enhanced Micronutrient Goals

**Goal:** Implement floor/target/ceiling for micronutrients.

#### 4.1 Update Model
Modify `lib/data/models/micronutrients.dart`:
```dart
class NutrientGoal {
  final String nutrientId;
  final double floor;      // Minimum to avoid deficiency
  final double target;     // RDA
  final double ceiling;    // Upper safe limit
  final String unit;
}

enum NutrientStatus {
  deficient,    // Below floor
  low,          // Between floor and target
  optimal,      // At or above target, below ceiling
  high,         // Approaching ceiling
  excessive,    // Above ceiling
}
```

#### 4.2 Update Nutrient Explorer
Modify `lib/screens/nutrition/nutrient_explorer.dart`:
- Show 3-tier progress bar (floor → target → ceiling)
- Color coding: red (deficient) → yellow (low) → green (optimal) → orange (high) → red (excessive)
- Tooltip explaining each threshold

**Files to modify:**
- `lib/data/models/micronutrients.dart`
- `lib/screens/nutrition/nutrient_explorer.dart`

---

### Phase 5: Logging UX Improvements

**Goal:** Faster food logging with fewer taps.

#### 5.1 Voice Logging
Add to `lib/screens/nutrition/log_meal_sheet.dart`:
- Microphone button for speech-to-text
- Use device STT → send text to existing Gemini parser

#### 5.2 Quick Add Widget
Create `lib/widgets/nutrition/quick_log_fab.dart`:
- Floating action button on nutrition screen
- Expands to show: Camera, Barcode, Voice, Text
- One-tap access to any logging method

#### 5.3 Timeline Option (Optional)
Create `lib/screens/nutrition/timeline_food_log.dart`:
- Alternative view to meal-type buckets
- Foods shown chronologically with timestamps
- Toggle between views in settings

**Files to modify/create:**
- `lib/screens/nutrition/log_meal_sheet.dart` - add voice
- `lib/widgets/nutrition/quick_log_fab.dart` - new
- `lib/screens/nutrition/timeline_food_log.dart` - new (optional)

---

## Implementation Order

| Phase | Features | Complexity | Dependencies |
|-------|----------|------------|--------------|
| 1 | Weight tracking | Medium | None |
| 2 | Body metrics & photos | Medium | Phase 1 (optional) |
| 3 | Adaptive algorithm | High | Phase 1 required |
| 4 | 3-tier nutrients | Low | None |
| 5 | Logging UX | Medium | None |

**Recommended sequence:** Phase 1 → Phase 3 → Phase 4 → Phase 2 → Phase 5

(Phases 4, 2, 5 can be done in parallel after Phase 1 completes)

---

## Success Metrics

- **Weight tracking:** Users log weight 3+ times/week
- **Adaptive algorithm:** TDEE predictions within 200 kcal of actual
- **Body metrics:** Users track measurements monthly
- **Logging speed:** Average <30 seconds per food log

---

---

## Nutrition Onboarding Flow

### Overview

A **separate nutrition onboarding** triggered when users first access nutrition features. This flow leverages existing user data (height, weight, age, gender, activity level, fitness goals) and collects nutrition-specific information.

### Data Already Available from Main Onboarding

| Field | Source | Use for Nutrition |
|-------|--------|-------------------|
| Height (cm) | `users.height_cm` | BMR calculation |
| Weight (kg) | `users.weight_kg` | BMR/TDEE calculation |
| Age | `users.age` | BMR calculation |
| Gender | `users.gender` | BMR formula selection |
| Activity Level | `users.activity_level` | TDEE multiplier |
| Target Weight | `users.target_weight_kg` | Goal direction |
| Fitness Goals | `users.goals` (JSON) | Protein prioritization |

### New Data to Collect (Nutrition Onboarding)

#### Step 1: Nutrition Goal (Required)
**Question:** "What's your primary nutrition goal?"

| Option | Effect |
|--------|--------|
| Lose fat | 500 kcal deficit, high protein (2g/kg) |
| Build muscle | 300 kcal surplus, high protein (1.8g/kg) |
| Maintain weight | TDEE, moderate protein (1.6g/kg) |
| Improve energy | TDEE, balanced macros |
| Eat healthier | TDEE, focus on food quality |
| Body recomposition | Slight deficit (200 kcal), very high protein (2.2g/kg) |

#### Step 2: Rate of Change (Conditional - if lose/gain)
**Question:** "How quickly do you want to reach your goal?"

| Option | Weekly Change | Daily Adjustment |
|--------|---------------|------------------|
| Slow & steady | 0.25 kg/week | 250 kcal |
| Moderate (recommended) | 0.5 kg/week | 500 kcal |
| Aggressive | 0.75-1 kg/week | 750 kcal |

#### Step 3: Diet Type (Required)
**Question:** "Do you follow a specific diet?"

| Option | Macro Split (C/P/F) |
|--------|---------------------|
| No preference / Balanced | 45/25/30 |
| Low carb | 25/35/40 |
| Keto | 5/25/70 |
| High protein | 35/40/25 |
| Vegetarian | 50/20/30 |
| Vegan | 55/20/25 |
| Mediterranean | 45/20/35 |
| Custom | User sets percentages |

#### Step 4: Allergies & Restrictions (Optional but Recommended)
**Question:** "Any food allergies or restrictions?"

**FDA Big 9 Allergens (multi-select):**
- Milk/Dairy
- Eggs
- Fish
- Shellfish
- Tree nuts
- Peanuts
- Wheat/Gluten
- Soy
- Sesame

**Additional restrictions:**
- Lactose intolerant
- No pork
- No beef
- No alcohol

#### Step 5: Meal Pattern (Optional)
**Question:** "How do you prefer to eat?"

| Option | Effect |
|--------|--------|
| 3 meals | Standard meal logging |
| 3 meals + snacks | Add snack slots |
| Intermittent fasting (16:8) | Condensed eating window |
| Intermittent fasting (18:6) | Shorter eating window |
| 5-6 small meals | Grazing pattern |

#### Step 6: Cooking & Lifestyle (Optional)
**Question:** "About your lifestyle..."

- **Cooking skill:** Beginner / Intermediate / Advanced
- **Time for cooking:** <15 min / 15-30 min / 30-60 min / No limit
- **Budget:** Budget-friendly / Moderate / No constraints

---

### Calorie & Macro Calculation Formulas

#### BMR Calculation (Mifflin-St Jeor - Industry Standard)

```
Male:   BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
Female: BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
```

#### TDEE Calculation

```
TDEE = BMR × Activity_Multiplier

Activity Multipliers:
- Sedentary: 1.2
- Lightly Active: 1.375
- Moderately Active: 1.55
- Very Active: 1.725
- Extra Active: 1.9
```

#### Goal Adjustments

```
Weight Loss:    Target = TDEE - deficit
Maintenance:    Target = TDEE
Weight Gain:    Target = TDEE + surplus

Minimum floors:
- Women: 1,200 kcal
- Men: 1,500 kcal
```

#### Protein Targets by Goal

| Goal | g per kg body weight |
|------|---------------------|
| Sedentary | 0.8 |
| General fitness | 1.2-1.6 |
| Fat loss | 2.0-2.4 |
| Muscle gain | 1.6-2.2 |
| Athletes | 1.6-2.2 |

---

### Database Schema for Nutrition Onboarding

```sql
-- Add to users table or create new nutrition_preferences table
CREATE TABLE nutrition_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Goal settings
  nutrition_goal TEXT NOT NULL, -- 'lose_fat', 'build_muscle', 'maintain', etc.
  rate_of_change TEXT, -- 'slow', 'moderate', 'aggressive'

  -- Calculated targets
  calculated_bmr INTEGER,
  calculated_tdee INTEGER,
  target_calories INTEGER,
  target_protein_g INTEGER,
  target_carbs_g INTEGER,
  target_fat_g INTEGER,
  target_fiber_g INTEGER DEFAULT 25,

  -- Diet type
  diet_type TEXT DEFAULT 'balanced', -- 'balanced', 'low_carb', 'keto', etc.
  custom_carb_percent INTEGER,
  custom_protein_percent INTEGER,
  custom_fat_percent INTEGER,

  -- Restrictions
  allergies TEXT[], -- Array of allergens
  dietary_restrictions TEXT[], -- 'vegetarian', 'vegan', 'halal', etc.
  disliked_foods TEXT[],

  -- Meal patterns
  meal_pattern TEXT DEFAULT '3_meals', -- '3_meals', '3_meals_snacks', 'if_16_8', etc.
  fasting_start_hour INTEGER, -- For IF users
  fasting_end_hour INTEGER,

  -- Lifestyle
  cooking_skill TEXT DEFAULT 'intermediate',
  cooking_time_minutes INTEGER DEFAULT 30,
  budget_level TEXT DEFAULT 'moderate',

  -- Tracking
  nutrition_onboarding_completed BOOLEAN DEFAULT false,
  onboarding_completed_at TIMESTAMP,
  last_recalculated_at TIMESTAMP,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS
ALTER TABLE nutrition_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY nutrition_preferences_user_policy ON nutrition_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Trigger for updated_at
CREATE TRIGGER update_nutrition_preferences_updated_at
  BEFORE UPDATE ON nutrition_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

### Flutter Implementation

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/data/models/nutrition_preferences.dart` | Model for nutrition_preferences table |
| `lib/screens/nutrition/nutrition_onboarding/` | New directory for onboarding screens |
| `nutrition_onboarding_screen.dart` | Main container with step navigation |
| `goal_step.dart` | Step 1: Nutrition goal selection |
| `rate_step.dart` | Step 2: Rate of change |
| `diet_type_step.dart` | Step 3: Diet type selection |
| `allergies_step.dart` | Step 4: Allergies & restrictions |
| `meal_pattern_step.dart` | Step 5: Meal patterns |
| `lifestyle_step.dart` | Step 6: Cooking & lifestyle |
| `summary_step.dart` | Final: Show calculated targets |
| `lib/services/nutrition_calculator.dart` | BMR/TDEE/macro calculation logic |

#### Trigger Point

In `nutrition_screen.dart`, check on load:
```dart
// If nutrition onboarding not completed, redirect
if (!user.nutritionOnboardingCompleted) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => NutritionOnboardingScreen()),
  );
}
```

---

### Competitive Insights from Research

#### What Noom Does Well (Psychology-Based)
- 80-96 screens (!) but high conversion
- Behavioral questions: "Does your motivation ebb and flow?"
- Life event targeting: "Do you have a wedding coming up?"
- Social proof between questions

#### What MacroFactor Does Well (Science-Based)
- Quick onboarding (~5 min)
- Asks for body fat % (optional) for more accurate formula
- Offers "Coached" vs "Manual" mode
- Recalculates after 3-4 weeks of data

#### Our Advantage: AI Chat
Instead of fixed questions, consider a **conversational nutrition setup** using Gemini:
- "Tell me about your eating habits and any dietary restrictions"
- AI extracts: allergies, preferences, patterns
- More natural, less form-filling
- Can ask follow-up questions

---

### Implementation Order

| Priority | Component | Complexity |
|----------|-----------|------------|
| 1 | Database migration | Low |
| 2 | Nutrition calculator service | Medium |
| 3 | Nutrition preferences model | Low |
| 4 | Onboarding screens (Steps 1-6) | Medium |
| 5 | Summary + target display | Low |
| 6 | Integration with nutrition_screen | Low |
| 7 | (Optional) AI conversational setup | High |

---

---

## User Research: Pain Points, Feature Requests & Retention Insights

### Top User Complaints (Ranked by Frequency)

| Rank | Complaint | Impact | Our Solution |
|------|-----------|--------|--------------|
| 1 | **Manual logging is tedious** | 71% quit by month 3 | AI photo + voice logging (already have image, add voice) |
| 2 | **Inaccurate food databases** | Users lose trust | Use Gemini for parsing, not crowdsourced DB |
| 3 | **Aggressive paywalls** | 97% unhappy with MFP pricing | Keep core features free |
| 4 | **Restaurant tracking impossible** | Unknown ingredients, portions | AI "confidence range" estimates |
| 5 | **Batch cooking complexity** | Raw vs cooked weights confusing | Smart recipe portioning tools |
| 6 | **Unrealistic calorie targets** | "Negative 700 cal/day" recommendations | Evidence-based minimums + AI coaching |
| 7 | **Guilt and shame** | Red numbers trigger ED behaviors | Positive framing, no red warnings |
| 8 | **Streak pressure** | Broken streaks = quit | Streak freeze, weekly goals |

---

## Detailed Complaint Solutions

### Complaint #1: Manual Logging is Tedious

**Problem:** Users spend 5-15 minutes daily logging food. Searching databases, selecting portions, logging multi-ingredient meals is exhausting.

**Solutions to Implement:**

| Solution | Implementation | Files to Modify |
|----------|----------------|-----------------|
| **Voice logging** | Add mic button → speech-to-text → Gemini parses | `log_meal_sheet.dart` |
| **Quick favorites bar** | One-tap re-log frequent meals | Already exists - make more prominent |
| **Smart suggestions** | AI suggests "Did you have coffee again?" based on patterns | New: `meal_suggestions_service.dart` |
| **Meal templates** | "Log yesterday's breakfast" shortcut | `nutrition_repository.dart` |
| **Batch logging** | Log multiple items at once via voice/photo | `log_meal_sheet.dart` |

**Voice Logging Implementation:**
```dart
// In log_meal_sheet.dart
class _LogMealSheetState extends State<LogMealSheet> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  Future<void> _startVoiceInput() async {
    if (await _speechToText.initialize()) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            // Send to Gemini for parsing
            _logFoodFromText(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 30),
      );
    }
  }
}
```

**Package to add:** `speech_to_text: ^6.6.0` in pubspec.yaml

---

### Complaint #2: Inaccurate Food Databases

**Problem:** MyFitnessPal has user-generated entries with wrong calories, duplicates, and outdated info.

**Our Advantage:** We use Gemini AI to parse food descriptions - no crowdsourced database!

**Solutions to Implement:**

| Solution | Implementation | Files to Modify |
|----------|----------------|-----------------|
| **AI-verified parsing** | Gemini analyzes food, returns structured nutrition | Already implemented! |
| **Confidence scores** | Show "High/Medium/Low confidence" on AI estimates | `food_log` model, UI |
| **User corrections** | Let users adjust AI estimates, learn from corrections | `food_logs` table |
| **Barcode fallback** | Use OpenFoodFacts for packaged items, Gemini for fresh | Already have barcode! |

**Add confidence display:**
```dart
// In log_meal_sheet.dart result display
Widget _buildConfidenceIndicator(double confidence) {
  final color = confidence > 0.8 ? Colors.green
              : confidence > 0.6 ? Colors.orange
              : Colors.red;
  final label = confidence > 0.8 ? 'High confidence'
              : confidence > 0.6 ? 'Medium confidence'
              : 'Estimate - please verify';

  return Chip(
    label: Text(label),
    backgroundColor: color.withOpacity(0.2),
    labelStyle: TextStyle(color: color),
  );
}
```

---

### Complaint #3: Aggressive Paywalls

**Problem:** MFP paywalled barcode scanning (was free for 10+ years). Users feel betrayed.

**Our Strategy:**

| Feature | Free Tier | Premium |
|---------|-----------|---------|
| Food logging (all methods) | ✅ Unlimited | ✅ |
| AI photo recognition | ✅ Unlimited | ✅ |
| Barcode scanning | ✅ Unlimited | ✅ |
| Macro tracking | ✅ Full | ✅ |
| Micronutrient tracking | ✅ Basic (10 nutrients) | ✅ Full (40+) |
| AI coach chat | ✅ 10 messages/day | ✅ Unlimited |
| Workout generation | ✅ 1 plan/month | ✅ Unlimited |
| Adaptive algorithm | ❌ | ✅ Weekly adjustments |
| Progress photos | ❌ | ✅ |
| Export data | ❌ | ✅ |

**Key principle:** Core logging functionality stays FREE forever.

---

### Complaint #4: Restaurant Tracking Impossible

**Problem:** No reliable way to track meals at non-chain restaurants. Unknown ingredients, cooking methods, portion sizes.

**Solutions to Implement:**

| Solution | Implementation | Files |
|----------|----------------|-------|
| **AI photo estimation** | Take photo → Gemini estimates with confidence range | Already have image logging |
| **"Restaurant mode"** | Special UI showing min/mid/max calorie estimates | New UI component |
| **Common restaurant templates** | Pre-built estimates for "grilled chicken", "pasta dish", etc. | Backend seed data |
| **Portion guides** | Visual reference (palm = 3oz protein, fist = 1 cup) | Help/education section |

**Restaurant Mode UI:**
```dart
class RestaurantEstimateCard extends StatelessWidget {
  final String foodName;
  final int minCalories;
  final int midCalories;  // Most likely
  final int maxCalories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(foodName, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _EstimateColumn('Light\nPortion', minCalories, Colors.green),
              _EstimateColumn('Typical\nPortion', midCalories, Colors.blue),
              _EstimateColumn('Large\nPortion', maxCalories, Colors.orange),
            ],
          ),
          Text(
            'Tap the estimate that best matches your meal',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
```

**Gemini prompt update for restaurants:**
```python
RESTAURANT_PROMPT = """
Analyze this restaurant meal photo. Since restaurant portions and cooking methods vary:

1. Identify the dish and main components
2. Provide THREE estimates:
   - MINIMUM: Light portion, minimal oil/butter
   - TYPICAL: Standard restaurant portion
   - MAXIMUM: Large portion, rich preparation

Return JSON:
{
  "food_name": "Grilled Salmon with Vegetables",
  "estimates": {
    "minimum": {"calories": 450, "protein": 35, "carbs": 20, "fat": 25},
    "typical": {"calories": 650, "protein": 40, "carbs": 30, "fat": 40},
    "maximum": {"calories": 900, "protein": 45, "carbs": 40, "fat": 60}
  },
  "confidence": 0.7,
  "notes": "Salmon appears grilled. Vegetables look sautéed in oil."
}
"""
```

---

### Complaint #5: Batch Cooking Complexity

**Problem:** Raw vs cooked weights differ. Dividing recipes into portions is confusing.

**Solutions to Implement:**

| Solution | Implementation | Files |
|----------|----------------|-------|
| **Cooked weight converter** | "I used 500g raw chicken" → shows cooked equivalent | `nutrition_calculator.dart` |
| **Smart portioning** | "This makes 4 servings" → auto-divides totals | Recipe builder |
| **Leftover tracking** | "I ate 1.5 servings" → easy partial logging | `log_meal_sheet.dart` |
| **Batch prep mode** | "I'm prepping 5 lunches" workflow | New screen |

**Cooking weight conversion data:**
```dart
const Map<String, double> cookingWeightMultipliers = {
  // Protein (shrinks when cooked)
  'chicken_breast': 0.75,  // Loses 25% weight
  'ground_beef': 0.70,     // Loses 30% weight
  'salmon': 0.80,          // Loses 20% weight
  'steak': 0.75,

  // Grains (expands when cooked)
  'rice': 3.0,             // Triples in volume
  'pasta': 2.25,           // More than doubles
  'oatmeal': 2.5,
  'quinoa': 2.75,

  // Vegetables (shrinks)
  'spinach': 0.10,         // Loses 90% volume!
  'mushrooms': 0.50,
  'broccoli': 0.85,
};

class CookingConverter {
  static double rawToCooked(String food, double rawGrams) {
    final multiplier = cookingWeightMultipliers[food] ?? 1.0;
    return rawGrams * multiplier;
  }

  static double cookedToRaw(String food, double cookedGrams) {
    final multiplier = cookingWeightMultipliers[food] ?? 1.0;
    return cookedGrams / multiplier;
  }
}
```

**Recipe portioning UI:**
```dart
class RecipePortioningSheet extends StatefulWidget {
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Total recipe: ${recipe.totalCalories} cal'),

        // Servings slider
        Slider(
          value: _servings.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          label: '$_servings servings',
          onChanged: (v) => setState(() => _servings = v.round()),
        ),

        // Per-serving breakdown
        Text('Per serving: ${recipe.totalCalories ~/ _servings} cal'),

        // How much did you eat?
        Text('How much did you eat?'),
        Row(
          children: [
            _PortionButton('½ serving', 0.5),
            _PortionButton('1 serving', 1.0),
            _PortionButton('1½ servings', 1.5),
            _PortionButton('2 servings', 2.0),
          ],
        ),
      ],
    );
  }
}
```

---

### Complaint #6: Unrealistic Calorie Targets

**Problem:** Apps recommend dangerously low calories. One user got "negative 700 calories/day"!

**Solutions to Implement:**

| Solution | Implementation | Files |
|----------|----------------|-------|
| **Hard minimums** | Never go below 1200 (women) / 1500 (men) | `nutrition_calculator.dart` |
| **Rate limits** | Max 1kg/week loss, warn if aggressive | Onboarding + settings |
| **AI coaching** | If target seems extreme, AI explains and suggests adjustment | Chat integration |
| **Adaptive targets** | Adjust based on actual results, not just formulas | Phase 5 implementation |

**Safe calorie calculation:**
```dart
class NutritionCalculator {
  static const int MIN_CALORIES_FEMALE = 1200;
  static const int MIN_CALORIES_MALE = 1500;
  static const double MAX_WEEKLY_LOSS_KG = 1.0;
  static const double MAX_DEFICIT_PERCENT = 0.25; // 25% max deficit

  static CalorieTarget calculateSafeTarget({
    required double tdee,
    required String gender,
    required String goal,
    required double ratePerWeek,
  }) {
    // Calculate raw deficit
    double deficit = ratePerWeek * 7700 / 7; // kcal per day for desired rate

    // Apply safety limits
    double maxDeficit = tdee * MAX_DEFICIT_PERCENT;
    deficit = min(deficit, maxDeficit);

    double targetCalories = tdee - deficit;

    // Apply hard minimum
    int minimum = gender == 'female' ? MIN_CALORIES_FEMALE : MIN_CALORIES_MALE;

    if (targetCalories < minimum) {
      targetCalories = minimum.toDouble();
      // Calculate actual achievable rate at minimum
      double actualRate = (tdee - targetCalories) * 7 / 7700;

      return CalorieTarget(
        calories: targetCalories.round(),
        wasAdjusted: true,
        adjustmentReason: 'Target adjusted to safe minimum of $minimum calories. '
            'At this level, you can expect ~${actualRate.toStringAsFixed(2)}kg/week loss.',
        achievableRatePerWeek: actualRate,
      );
    }

    return CalorieTarget(
      calories: targetCalories.round(),
      wasAdjusted: false,
    );
  }
}
```

---

### Complaint #7: Guilt and Shame

**Problem:** Red numbers for "over" days trigger anxiety, shame, and disordered eating patterns.

**Solutions to Implement:**

| Solution | Implementation | Files |
|----------|----------------|-------|
| **No red colors** | Use neutral blue/gray for over-target days | Theme + all nutrition UI |
| **Calm mode** | Toggle to hide all numbers, show food quality only | Settings + nutrition screens |
| **Weekly view** | Show weekly averages, not daily perfection | New weekly summary widget |
| **Positive language** | "Great protein today!" not "You exceeded your fat goal" | AI coach prompts |
| **Progress focus** | "You logged 5 days this week!" not "You missed 2 days" | Streak/stats UI |

**Theme changes:**
```dart
// In theme.dart - nutrition-specific colors
class NutritionColors {
  // NEVER use red for "over" - it triggers shame
  static const Color underTarget = Color(0xFF64B5F6);  // Soft blue
  static const Color atTarget = Color(0xFF81C784);     // Soft green
  static const Color overTarget = Color(0xFFFFB74D);   // Soft orange (NOT red)
  static const Color wayOver = Color(0xFFE0E0E0);      // Gray (neutral, not alarming)
}
```

**Calm mode implementation:**
```dart
class NutritionSettings {
  bool calmModeEnabled = false;  // Hide numbers
  bool showWeeklyInsteadOfDaily = false;
  bool positiveOnlyFeedback = true;
}

// In nutrition_screen.dart
Widget _buildCalorieDisplay() {
  if (settings.calmModeEnabled) {
    return Column(
      children: [
        Text('Today\'s meals'),
        _buildFoodQualityIndicator(), // Shows green/yellow based on food choices
        Text('Great choices today!', style: TextStyle(color: Colors.green)),
      ],
    );
  }
  // Normal calorie display
  return _buildNormalCalorieCard();
}
```

**AI coach positive framing:**
```python
# In coach system prompt
POSITIVE_COACHING_RULES = """
NEVER say:
- "You went over your calorie goal"
- "You exceeded your fat limit"
- "You failed to..."
- "You only logged X days"

ALWAYS say:
- "You're making progress! Today's protein was excellent."
- "I noticed you tried a new vegetable - that's great variety!"
- "You logged 5 days this week - that's building a strong habit!"
- "Your weekly average is right on track, even with some variation day-to-day."

If someone goes over calories:
- Focus on what went well (protein? fiber? hydration?)
- Mention weekly average if it's fine
- Suggest, don't criticize: "Tomorrow you might enjoy a lighter lunch to balance out"
"""
```

---

### Complaint #8: Streak Pressure

**Problem:** Users build 100-day streaks, miss one day, lose everything. They quit in frustration.

**Solutions to Implement:**

| Solution | Implementation | Files |
|----------|----------------|-------|
| **Streak freeze** | 1-2 "free passes" per week that don't break streak | New table + logic |
| **Weekly goals** | "Log 5 of 7 days" instead of daily perfection | Settings + streak logic |
| **Longest streak badge** | Even if current breaks, celebrate the record | Achievements system |
| **Gentle recovery** | "Welcome back! Let's pick up where you left off" | Re-engagement flow |

**Database schema:**
```sql
-- Add to users or create nutrition_streaks table
CREATE TABLE nutrition_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Current streak
  current_streak_days INTEGER DEFAULT 0,
  streak_start_date DATE,
  last_logged_date DATE,

  -- Streak freezes
  freezes_available INTEGER DEFAULT 2,  -- Reset weekly
  freezes_used_this_week INTEGER DEFAULT 0,
  week_start_date DATE,

  -- Records
  longest_streak_ever INTEGER DEFAULT 0,
  total_days_logged INTEGER DEFAULT 0,

  -- Weekly goal mode
  weekly_goal_enabled BOOLEAN DEFAULT false,
  weekly_goal_days INTEGER DEFAULT 5,  -- Log 5 of 7 days
  days_logged_this_week INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**Streak logic:**
```dart
class StreakService {
  Future<StreakResult> logDay(String userId, DateTime date) async {
    final streak = await getStreak(userId);
    final daysSinceLastLog = date.difference(streak.lastLoggedDate).inDays;

    if (daysSinceLastLog == 0) {
      // Already logged today
      return StreakResult.alreadyLogged(streak.currentStreakDays);
    }

    if (daysSinceLastLog == 1) {
      // Perfect! Continue streak
      return _incrementStreak(streak);
    }

    if (daysSinceLastLog == 2 && streak.freezesAvailable > 0) {
      // Missed yesterday, but have a freeze!
      await _useFreeze(streak);
      return StreakResult.usedFreeze(
        streak.currentStreakDays,
        streak.freezesAvailable - 1,
      );
    }

    // Streak broken, but be gentle
    final longestEver = max(streak.longestStreakEver, streak.currentStreakDays);
    await _resetStreak(streak, longestEver);

    return StreakResult.streakBroken(
      previousStreak: streak.currentStreakDays,
      longestEver: longestEver,
      encouragement: _getEncouragement(longestEver),
    );
  }

  String _getEncouragement(int longestEver) {
    if (longestEver >= 30) {
      return "You built an amazing $longestEver-day streak before! "
             "That shows real commitment. Let's build another one!";
    }
    return "Every day is a fresh start. Let's begin a new streak today!";
  }
}
```

**Weekly goals alternative:**
```dart
class WeeklyGoalTracker {
  final int targetDays; // e.g., 5 out of 7
  final List<DateTime> loggedDays;

  bool get weeklyGoalMet => loggedDays.length >= targetDays;
  int get daysRemaining => targetDays - loggedDays.length;
  int get daysLeftInWeek => 7 - DateTime.now().weekday;

  String get statusMessage {
    if (weeklyGoalMet) {
      return "🎉 Weekly goal complete! You logged ${loggedDays.length} days!";
    }
    if (daysRemaining <= daysLeftInWeek) {
      return "You need $daysRemaining more days to hit your goal. You've got this!";
    }
    return "Log today to stay on track for your weekly goal!";
  }
}
```

---

## Summary: Complaint Solutions Implementation Order

| Priority | Complaint | Solution | Effort | Impact |
|----------|-----------|----------|--------|--------|
| P0 | #7 Guilt/Shame | Remove red colors, add calm mode | Low | High |
| P0 | #8 Streak pressure | Add streak freeze + weekly goals | Low | High |
| P1 | #1 Tedious logging | Add voice input | Medium | High |
| P1 | #6 Unrealistic targets | Add safety minimums | Low | High |
| P2 | #4 Restaurant tracking | Add confidence ranges | Medium | Medium |
| P2 | #5 Batch cooking | Add weight converters + portioning | Medium | Medium |
| P3 | #2 Inaccurate data | Add confidence display | Low | Medium |
| P3 | #3 Paywalls | Define free tier clearly | Low | Medium |

**Files to create/modify:**
- `lib/screens/nutrition/log_meal_sheet.dart` - voice input, restaurant mode
- `lib/services/nutrition_calculator.dart` - safe targets, weight conversion
- `lib/services/streak_service.dart` - new file for streak logic
- `lib/theme/nutrition_colors.dart` - new file, no red colors
- `backend/migrations/XXX_nutrition_streaks.sql` - streak tracking table
- AI coach system prompts - positive framing

---

## Additional User Requests (From App Reviews)

### Request: Fasting Day Tracking (57.1)

**User said:** "Sometimes I wonder if adding data that takes into account fasting? Marking days that you fast & continue to weigh yourself... if & how that impacts your goals."

**Solution:** Add fasting day marker that:
- Marks full fasting days (vs just IF windows)
- Adjusts weekly calorie averages to account for fasting
- Shows fasting impact on weight trends
- Integrates with adaptive algorithm

**Implementation:**
```sql
-- Add to food_logs or create fasting_logs table
ALTER TABLE food_logs ADD COLUMN is_fasting_day BOOLEAN DEFAULT false;

-- Or separate table for more detail
CREATE TABLE fasting_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  fasting_date DATE NOT NULL,
  fasting_type TEXT, -- 'full_day', '24h', '36h', '48h', 'extended'
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  broke_fast_early BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

**UI Addition:**
```dart
// In nutrition_screen.dart - add "Mark as Fasting Day" button
Widget _buildFastingToggle() {
  return SwitchListTile(
    title: Text('Fasting Day'),
    subtitle: Text('No meals logged today'),
    value: _isFastingDay,
    onChanged: (value) => _toggleFastingDay(value),
    secondary: Icon(Icons.no_food),
  );
}
```

---

### Request: Insulin & Blood Sugar Tracking via Health Connect (57.2)

**User said:** "I would love to track my insulin and blood sugars with this using health connect. Type 1 Diabetic."

**Solution:** Health Connect integration for diabetic users

**Implementation:**

```dart
// Add health_connect package
// pubspec.yaml: health: ^10.0.0

class HealthConnectService {
  final Health _health = Health();

  Future<void> requestPermissions() async {
    final types = [
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.INSULIN_DELIVERY,
    ];
    await _health.requestAuthorization(types);
  }

  Future<List<BloodGlucoseReading>> getBloodGlucose(DateTime start, DateTime end) async {
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.BLOOD_GLUCOSE],
    );
    return data.map((e) => BloodGlucoseReading.fromHealthData(e)).toList();
  }

  Future<List<InsulinDose>> getInsulinDelivery(DateTime start, DateTime end) async {
    final data = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.INSULIN_DELIVERY],
    );
    return data.map((e) => InsulinDose.fromHealthData(e)).toList();
  }
}
```

**Database schema:**
```sql
CREATE TABLE health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  metric_type TEXT NOT NULL, -- 'blood_glucose', 'insulin', 'blood_pressure', etc.
  value DECIMAL NOT NULL,
  unit TEXT NOT NULL, -- 'mg/dL', 'mmol/L', 'units'
  recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
  source TEXT DEFAULT 'health_connect', -- 'manual', 'health_connect', 'apple_health'
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_health_metrics_user_type ON health_metrics(user_id, metric_type, recorded_at);
```

**UI Addition:**
- New "Health Metrics" tab in nutrition screen
- Blood glucose graph overlaid with meals (see food impact)
- Insulin logging for manual entry
- AI coach insights: "Your blood sugar spiked after the pasta. Consider pairing carbs with protein next time."

**Priority:** Medium - significant value for diabetic users, growing market

---

### Request: Disable AI Tips After Logging (57.4)

**User said:** "We need a way to disable the useless (and incorrect) AI food tips after each meal logged"

**Solution:** Add toggle in settings to disable AI feedback on meals

**Implementation:**
```dart
// In nutrition settings
class NutritionSettings {
  bool showAiFeedbackAfterLogging = true;  // Default on, user can disable
  bool calmModeEnabled = false;
  bool showWeeklyInsteadOfDaily = false;
}

// In log_meal_sheet.dart - conditionally show AI feedback
Widget _buildLogResult(FoodLog log) {
  return Column(
    children: [
      _buildNutritionSummary(log),

      // Only show AI feedback if enabled
      if (settings.showAiFeedbackAfterLogging && log.aiFeedback != null)
        _buildAiFeedbackCard(log.aiFeedback),

      _buildActionButtons(),
    ],
  );
}
```

**Settings UI:**
```dart
// In settings screen
SwitchListTile(
  title: Text('AI Meal Feedback'),
  subtitle: Text('Show tips and suggestions after logging meals'),
  value: settings.showAiFeedbackAfterLogging,
  onChanged: (value) => _updateSetting('showAiFeedbackAfterLogging', value),
),
```

**Priority:** P0 - Easy to implement, high user demand

---

### Request: Faster Meal Logging (57.4)

**User said:** "It's too slow and too convoluted to track meals... Even saving common foods as a meal and selecting that every morning feels slower than other apps"

**Solutions Already Planned:**
1. ✅ Voice logging (saves 40-60s)
2. ✅ Quick-add FAB
3. ✅ Better favorites bar

**Additional Speed Improvements:**

```dart
// 1. One-tap "Log Again" for recent meals
class QuickLogWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Quick Log', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentMeals.length,
            itemBuilder: (ctx, i) => _QuickLogChip(
              meal: recentMeals[i],
              onTap: () => _logMealInstantly(recentMeals[i]), // ONE TAP!
            ),
          ),
        ),
      ],
    );
  }
}

// 2. "Same as yesterday" button for each meal type
Widget _buildSameAsYesterdayButton(MealType mealType) {
  final yesterdayMeal = getYesterdayMeal(mealType);
  if (yesterdayMeal == null) return SizedBox.shrink();

  return TextButton.icon(
    icon: Icon(Icons.replay),
    label: Text('Same as yesterday (${yesterdayMeal.totalCalories} cal)'),
    onPressed: () => _logMealInstantly(yesterdayMeal),
  );
}

// 3. Reduce search lag with local caching
class FoodSearchService {
  final _cache = <String, List<FoodItem>>{};
  Timer? _debounce;

  Future<List<FoodItem>> search(String query) async {
    // Check cache first
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    // Debounce API calls
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), () async {
      final results = await _api.searchFoods(query);
      _cache[query] = results;
    });
  }
}
```

**Priority:** P1 - Core UX improvement

---

### Request: Better Barcode Handling (57.3)

**User said:** "Issues when using the scan feature (ex. Scans well known drink, 'Item not found'), I manually search for it and it's the first thing that pops up."

**Solution:** Smarter barcode fallback flow

```dart
class BarcodeService {
  Future<BarcodeResult> scanAndLookup(String barcode) async {
    // 1. Try OpenFoodFacts first
    var result = await _openFoodFacts.lookup(barcode);
    if (result != null) return BarcodeResult.found(result);

    // 2. Try our own database (user-submitted)
    result = await _localDb.lookupBarcode(barcode);
    if (result != null) return BarcodeResult.found(result);

    // 3. Try UPC Database API
    result = await _upcDatabase.lookup(barcode);
    if (result != null) return BarcodeResult.found(result);

    // 4. Extract product name from barcode metadata and auto-search
    final productHint = await _extractProductHint(barcode);
    if (productHint != null) {
      return BarcodeResult.notFoundWithSuggestion(
        barcode: barcode,
        suggestedSearch: productHint,
        message: 'Barcode not in database. Did you mean "$productHint"?',
      );
    }

    // 5. Offer to add manually with AI assist
    return BarcodeResult.notFound(
      barcode: barcode,
      options: [
        'Search for product',
        'Take photo instead',
        'Enter manually',
      ],
    );
  }
}

// Better UX for "not found"
Widget _buildBarcodeNotFound(BarcodeResult result) {
  return Column(
    children: [
      Icon(Icons.search_off, size: 48, color: Colors.orange),
      Text('Product not found in database'),

      if (result.suggestedSearch != null)
        ElevatedButton(
          onPressed: () => _searchFor(result.suggestedSearch),
          child: Text('Search "${result.suggestedSearch}"'),
        ),

      TextButton(
        onPressed: () => _openPhotoMode(),
        child: Text('Take a photo instead'),
      ),

      TextButton(
        onPressed: () => _openManualEntry(barcode: result.barcode),
        child: Text('Enter nutrition manually'),
      ),
    ],
  );
}
```

**Priority:** P1 - Directly addresses user frustration

---

## Summary: Additional Requests Implementation

| Request | Solution | Priority | Effort |
|---------|----------|----------|--------|
| Fasting day tracking | Fasting logs table + UI toggle | P2 | Medium |
| Insulin/blood sugar | Health Connect integration | P2 | High |
| Disable AI tips | Settings toggle | P0 | Low |
| Faster logging | One-tap re-log, caching, "same as yesterday" | P1 | Medium |
| Better barcode flow | Multi-source lookup + smart fallback | P1 | Medium |

**New files to create:**
- `lib/services/health_connect_service.dart` - Health Connect integration
- `lib/data/models/health_metrics.dart` - Blood glucose, insulin models
- `lib/data/models/fasting_log.dart` - Fasting day tracking
- `backend/migrations/XXX_health_metrics.sql` - Health metrics table
- `backend/migrations/XXX_fasting_logs.sql` - Fasting tracking table

### Features Users Want (That Most Apps Lack)

#### High-Impact Features to Add

| Feature | User Demand | Implementation Effort | Priority |
|---------|-------------|----------------------|----------|
| **Voice meal logging** | Very High (saves 40-60s/meal) | Medium | P1 |
| **Food-mood correlation** | High (underserved niche) | Medium | P2 |
| **AI coach that logs food** | High | Already have chat! | P1 |
| **Streak freeze/forgiveness** | High | Low | P1 |
| **Progress photos** | High | Medium | P2 |
| **Social media recipe import** | Medium (TikTok/Instagram) | High | P3 |
| **Grocery list generation** | Medium | High | P3 |
| **Partner/household sync** | Medium (unique differentiator) | Medium | P3 |

#### Mental Health-Aware Design (Critical)

**Research Finding:** ~75% of users with eating disorders reported calorie apps contributed to their disorder.

**Implementation:**
1. **No red/negative numbers** - Use neutral colors for "over" days
2. **Optional calorie hiding** - Focus on food quality, not numbers
3. **Streak forgiveness** - Weekly goals > daily perfection
4. **Gentle AI coach** - Encouragement, not criticism
5. **Progress focus** - Celebrate consistency, not perfection

### Retention Statistics & Solutions

| Metric | Industry Average | Top Apps | Target |
|--------|------------------|----------|--------|
| Day 1 retention | 26-35% | 40%+ | 45% |
| Day 7 retention | ~15% | 25% | 30% |
| Day 30 retention | 3-10% | 24% (MFP) | 20% |
| Day 90 retention | 3% | 24% (MFP) | 15% |

#### What Keeps Users Engaged (Evidence-Based)

| Strategy | Impact | Implementation |
|----------|--------|----------------|
| **7+ day streaks** | 2.3x more likely to engage daily | Add streak system with freeze |
| **AI personalization** | 50% more tracking, 30% better retention | Leverage existing AI coach |
| **Progress visualization** | Photos > scale numbers | Add progress photo feature |
| **Accountability partners** | 65% → 95% success rate | Optional buddy system |
| **Quick wins in week 1** | 80% more likely to stay 6 months | Achievable first-week goals |
| **Saved meal shortcuts** | "80% eat same breakfast" | Already have favorites! |

#### Notification Strategy (Research-Backed)

| Timing | Best Practice |
|--------|---------------|
| **When** | 5-8 PM (non-working hours) |
| **Type** | Actionable prompts > passive insights |
| **Frequency** | User-controlled, not aggressive |
| **Content** | Celebratory > punitive |

---

## Innovative Features from Competitor Research

### Features Our App Should Prioritize

#### Already Have (Leverage Better)
- ✅ AI image recognition for meals
- ✅ Real-time AI chat coaching
- ✅ Saved foods/favorites
- ✅ Micronutrient tracking
- ✅ Recipe builder

#### Must Add (High Priority)
| Feature | Why | Complexity |
|---------|-----|------------|
| Voice meal logging | Saves 40-60s/meal, huge UX win | Medium |
| Streak system with freeze | Drives retention, prevents guilt | Low |
| Progress photos | Visual proof > numbers | Medium |
| Food-mood tracking | Underserved niche, AI can analyze | Medium |
| Weekly goals (not just daily) | Reduces pressure, improves retention | Low |

#### Should Add (Medium Priority)
| Feature | Why | Complexity |
|---------|-----|------------|
| Restaurant "confidence range" | Addresses #4 complaint | Medium |
| Batch cooking calculator | Addresses #5 complaint | Medium |
| Accountability buddies | 95% success rate with check-ins | Medium |
| Positive-only feedback mode | Mental health protection | Low |

#### Nice to Have (Lower Priority)
| Feature | Why | Complexity |
|---------|-----|------------|
| Social media recipe import | Acquisition channel | High |
| Grocery list + Instacart | Conversion driver | High |
| CGM integration | Emerging trend | High |
| Partner meal syncing | Unique differentiator | Medium |

---

## Updated Implementation Roadmap

### Phase 0: Quick Wins (Do First)
**Goal:** Immediate retention improvements with minimal effort

| Task | Effort | Impact |
|------|--------|--------|
| Add streak system with freeze option | Low | High |
| Weekly nutrition goals (not just daily) | Low | High |
| Remove red/negative coloring | Low | Medium |
| Add "calm mode" toggle (hide calories) | Low | Medium |
| Improve AI coach to be more encouraging | Low | High |

### Phase 1: Weight Tracking & Trends (Foundation)
*Already planned - enables adaptive algorithm*

### Phase 2: Voice Logging & UX Improvements
**Goal:** Reduce logging friction (top complaint)

| Task | Files |
|------|-------|
| Add microphone button to log_meal_sheet.dart | `lib/screens/nutrition/log_meal_sheet.dart` |
| Implement speech-to-text → Gemini parsing | `lib/services/` |
| Quick-add FAB with multiple input methods | `lib/widgets/nutrition/quick_log_fab.dart` |

### Phase 3: Progress Photos & Body Metrics
*Already planned*

### Phase 4: Food-Mood Tracking
**Goal:** Unique differentiator, AI-powered insights

| Task | Files |
|------|-------|
| Add mood field to food_logs table | `backend/migrations/XXX_food_mood.sql` |
| Mood selector in log_meal_sheet | `lib/screens/nutrition/log_meal_sheet.dart` |
| AI analysis of food-mood correlations | `backend/api/v1/nutrition_insights.py` |
| Mood trends visualization | `lib/screens/nutrition/mood_insights_screen.dart` |

### Phase 5: Adaptive Algorithm
*Already planned*

### Phase 6: Social & Accountability
**Goal:** Drive retention through community

| Task | Complexity |
|------|------------|
| Accountability partner matching | Medium |
| Optional progress sharing | Low |
| Group challenges | Medium |

---

## Competitive Differentiation Summary

### What Makes Us Different

| Competitor | Their Weakness | Our Advantage |
|------------|----------------|---------------|
| MyFitnessPal | Paywalled features, ads, inaccurate DB | Free core features, AI-verified parsing |
| MacroFactor | No free tier, no workouts | Integrated workouts, real-time AI coach |
| Noom | Expensive ($199/yr), poor support | Affordable, AI-powered coaching |
| Cronometer | Complex UI, limited database | Simple UX, Gemini handles any food |
| Lose It! | Technical glitches, limited AI | Stable, AI-first design |

### Our Unique Value Proposition

> **"The only fitness app with integrated AI coaching for both workouts AND nutrition - with real-time chat, photo meal logging, and adaptive recommendations that actually work."**

Key differentiators:
1. **Integrated** - Workouts + nutrition in one app (MacroFactor is nutrition-only)
2. **AI-First** - Gemini powers food logging, coaching, workout generation
3. **Non-Judgmental** - Positive reinforcement, not guilt and shame
4. **Adaptive** - Learns from your data, adjusts recommendations
5. **Affordable** - Core features free, reasonable premium pricing

---

## Sources

- MacroFactor Official: https://macrofactorapp.com/
- MacroFactor Algorithms: https://macrofactorapp.com/macrofactors-algorithms-and-core-philosophy/
- MacroFactor vs MFP: https://macrofactorapp.com/macrofactor-vs-myfitnesspal-2025/
- MacroFactor 2025 Report: https://macrofactorapp.com/annual-report-2025/
- MyFitnessPal Goal Calculation: https://support.myfitnesspal.com/hc/en-us/articles/360032625391
- Noom Onboarding Analysis: https://www.retention.blog/p/the-longest-onboarding-ever
- ISSN Protein Position Stand: https://pubmed.ncbi.nlm.nih.gov/28642676/
- Mifflin-St Jeor Formula: https://www.inchcalculator.com/mifflin-st-jeor-calculator/
- FDA Big 9 Allergens: https://www.fda.gov/food/nutrition-food-labeling-and-critical-foods/food-allergies
- User Complaints Research: https://www.choosingtherapy.com/myfitnesspal-review/
- Retention Statistics: https://www.businessofapps.com/data/app-retention-rates/
- Gamification Research: https://pmc.ncbi.nlm.nih.gov/articles/PMC11168059/
- Food-Mood Apps: https://www.nourishmate.app/features/mood-tracking
- AI Nutrition Apps: https://www.tribe.ai/applied-ai/ai-nutrition-apps
- Notification Timing: https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0169162
- Eating Disorder Concerns: https://pmc.ncbi.nlm.nih.gov/articles/PMC8485346/
- Codebase exploration: lib/data/models/nutrition.dart, lib/screens/nutrition/, backend/migrations/

---

## Intermittent Fasting & Fasting Plans

### Overview

Comprehensive fasting tracking feature that integrates with the nutrition system. This includes support for multiple IF protocols, fasting timer with metabolic stages visualization, and AI-powered fasting guidance.

---

### Fasting Protocols to Support

#### Time-Restricted Eating (TRE) Protocols

| Protocol | Fasting | Eating | Difficulty | Best For |
|----------|---------|--------|------------|----------|
| **12:12** | 12h | 12h | Beginner | Complete beginners |
| **14:10** | 14h | 10h | Beginner | New to fasting |
| **16:8** | 16h | 8h | Intermediate | Most popular, well-researched |
| **18:6** | 18h | 6h | Intermediate | Experienced fasters |
| **20:4** (Warrior) | 20h | 4h | Advanced | Very experienced only |
| **OMAD (23:1)** | 23h | 1h | Advanced | Not recommended for most |

#### Modified Fasting Protocols

| Protocol | Pattern | Fasting Day Calories | Best For |
|----------|---------|---------------------|----------|
| **5:2 Diet** | 5 normal + 2 fasting days | 500-600 cal | Flexibility seekers |
| **Eat-Stop-Eat** | 1-2 × 24h fasts/week | 0 cal | Occasional longer fasts |
| **Alternate Day Fasting** | Every other day | 500 cal (25% TDEE) | Maximum results (advanced) |
| **Custom** | User-defined | User-defined | Personalized schedules |

#### Extended Fasting (Advanced)

| Duration | Risk Level | Medical Supervision | Notes |
|----------|------------|---------------------|-------|
| **24 hours** | Low-Moderate | Recommended first time | Glycogen depletion, fat burning |
| **36 hours** | Moderate | Recommended | Deep ketosis, enhanced autophagy |
| **48 hours** | Moderate-High | Required | Significant metabolic shift |
| **72+ hours** | High | Mandatory | Medical intervention level |

**Safety Warning:** Fasts over 24 hours require safety acknowledgment. Fasts over 48 hours should prompt medical consultation recommendation.

---

### Fasting Metabolic Stages (Evidence-Based)

| Stage | Hours | Name | What Happens | Color | Evidence |
|-------|-------|------|--------------|-------|----------|
| 1 | 0-4h | Fed State | Digesting food, insulin high | Gray | Strong |
| 2 | 4-8h | Post-Absorptive | Blood sugar normalizing | Light Blue | Strong |
| 3 | 8-12h | Early Fasting | Glycogen depletion begins | Teal | Strong |
| 4 | 12-16h | Fat Burning | Body switches to fat for fuel | Green | Strong |
| 5 | 16-24h | Ketosis | Ketone production, HGH increase | Orange | Strong |
| 6 | 24-48h | Deep Ketosis | Autophagy may begin | Red | Moderate |
| 7 | 48-72h | Extended | Immune regeneration (emerging) | Purple | Limited |

**Individual Variation Factors:**
- Prior diet (keto-adapted enters ketosis 4-6h faster)
- Activity level (exercise accelerates glycogen depletion)
- Age (older adults may have delayed keto-adaptation)
- Gender (different hormonal responses)

**Disclaimer for Autophagy:** "Autophagy timing in humans is not precisely established. Most research is from animal studies."

---

### Fasting Timer Features

#### Core Timer Functionality

```dart
class FastingRecord {
  final String id;
  final String oderId;
  final DateTime startTime;
  final DateTime? endTime;
  final int goalDurationMinutes;
  final int? actualDurationMinutes;
  final String protocol; // "16:8", "18:6", "5:2", "custom"
  final bool completed;
  final bool completedEarly;
  final String? notes;
  final List<FastingZoneEntry>? zonesReached;
  final DateTime createdAt;
}

class FastingZoneEntry {
  final String zoneName;
  final DateTime enteredAt;
  final int minutesInZone;
}

class FastingStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastFastDate;
  final int totalFastsCompleted;
}
```

#### Timer UI Requirements

1. **One-tap start** - Simple, prominent button
2. **Circular progress** - Shows percentage complete with zone colors
3. **Time display** - Elapsed time + remaining time
4. **Current zone indicator** - "You're in Fat Burning mode"
5. **Zone timeline** - Visual preview of upcoming zones
6. **End fast button** - With confirmation if before goal

#### Notifications

| Notification | Timing | Message Example |
|--------------|--------|-----------------|
| Fast Started | On start | "Your fast has begun. Stay hydrated!" |
| Zone Transition | At each zone | "You've entered Fat Burning mode!" |
| Halfway Point | 50% complete | "Halfway there! Keep going." |
| Goal Approaching | 1h before | "Almost done! 1 hour remaining." |
| Goal Reached | At goal | "Congratulations! You completed your fast." |
| Eating Window Ending | 1h before | "Eating window closes in 1 hour." |
| Streak Reminder | If no fast today by 8pm | "Don't forget to start your fast!" |

---

### Fasting + Nutrition Integration

#### Calorie Handling on Fasting Days

**5:2 Diet:**
```dart
class FiveTwoCalculator {
  static int fastingDayCalories(int normalTDEE, String gender) {
    // 500 cal for women, 600 cal for men
    return gender == 'female' ? 500 : 600;
  }

  static int weeklyAverage(int normalTDEE, String gender) {
    int fastingCals = fastingDayCalories(normalTDEE, gender);
    return ((5 * normalTDEE) + (2 * fastingCals)) ~/ 7;
  }
}
```

**Alternate Day Fasting:**
```dart
class ADFCalculator {
  static int fastingDayCalories(int normalTDEE) {
    // 25% of normal TDEE
    return (normalTDEE * 0.25).round();
  }
}
```

**Weekly Averaging Display:**
- Show daily target AND weekly average
- On fasting days, clearly show reduced target
- At week end, show "Weekly calories: X (target: Y)"

#### Protein Considerations

| Fasting Type | Protein Target | Notes |
|--------------|----------------|-------|
| 16:8 / 18:6 | 1.6-2.2 g/kg/day | Distribute across eating window |
| 5:2 (fasting days) | 50-70g minimum | Prioritize protein on fasting days |
| ADF (fasting days) | 50-70g minimum | Muscle preservation critical |
| 24h+ fasts | N/A | Focus on refeeding protocol |

**Protein Pacing:** Recommend 0.4-0.6 g/kg per meal, spaced 3-5 hours apart within eating window.

---

### Who Should NOT Fast (Safety Screening)

#### Absolute Contraindications (Block from using fasting features)

- Pregnant or breastfeeding women
- Under 18 years old
- History of eating disorders (anorexia, bulimia)
- Type 1 diabetes
- Underweight (BMI < 18.5)

#### Relative Contraindications (Show warning, require acknowledgment)

- Type 2 diabetes (especially on insulin)
- On blood pressure medications
- On medications requiring food
- Over 65 years old
- History of gout
- Thyroid disorders

#### Onboarding Safety Questions

```dart
// During fasting feature onboarding
List<SafetyQuestion> fastingSafetyQuestions = [
  SafetyQuestion(
    question: "Are you pregnant or breastfeeding?",
    blockIf: true,
    message: "Fasting is not recommended during pregnancy or breastfeeding.",
  ),
  SafetyQuestion(
    question: "Do you have a history of eating disorders?",
    blockIf: true,
    message: "For your safety, we don't recommend fasting for those with ED history.",
  ),
  SafetyQuestion(
    question: "Do you have Type 1 diabetes?",
    blockIf: true,
    message: "Type 1 diabetics should not fast without strict medical supervision.",
  ),
  SafetyQuestion(
    question: "Are you under 18?",
    blockIf: true,
    message: "Fasting is not recommended for those under 18.",
  ),
  SafetyQuestion(
    question: "Do you take medications that must be taken with food?",
    blockIf: false,
    warnMessage: "Please consult your doctor about adjusting medication timing.",
  ),
];
```

---

### Breaking a Fast

#### Early Fast Termination

- **Never shame users** for ending early
- Log actual duration (partial credit)
- Maintain streak if >80% of goal completed
- Offer option to adjust timestamp if accidental

```dart
class FastEndResult {
  final int actualMinutes;
  final int goalMinutes;
  final double completionPercent;
  final bool streakMaintained;
  final String message;

  String get encouragingMessage {
    if (completionPercent >= 1.0) {
      return "Excellent! You completed your ${goalMinutes ~/ 60}h fast!";
    } else if (completionPercent >= 0.8) {
      return "Great job! You completed ${(completionPercent * 100).round()}% of your goal.";
    } else {
      return "No problem! You fasted for ${actualMinutes ~/ 60}h ${actualMinutes % 60}m. Every fast counts!";
    }
  }
}
```

#### Refeeding Guidelines (Extended Fasts)

**24-hour fast:**
- Break with bone broth or light soup
- Wait 30 min before solid food
- Start with protein + vegetables

**36-48 hour fast:**
- Phase 1 (0-2h): Bone broth only
- Phase 2 (2-6h): Soft proteins, cooked vegetables
- Phase 3 (6-12h): Normal meals, smaller portions

**72+ hour fast:**
- Plan refeeding for half as many days as fasted
- Start with broths, fermented foods
- Gradually increase calories over 2-3 days
- **Warning:** Refeeding syndrome risk - electrolyte monitoring important

---

### Database Schema for Fasting

```sql
-- Fasting records table
CREATE TABLE fasting_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,

  -- Timing
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  goal_duration_minutes INTEGER NOT NULL,
  actual_duration_minutes INTEGER,

  -- Protocol
  protocol TEXT NOT NULL, -- '16:8', '18:6', '5:2', 'custom', etc.
  protocol_type TEXT NOT NULL, -- 'tre', 'modified', 'extended'

  -- Status
  status TEXT DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  completed_goal BOOLEAN DEFAULT false,
  completion_percentage DECIMAL(5,2),

  -- Zones reached (JSON array)
  zones_reached JSONB DEFAULT '[]',

  -- User input
  notes TEXT,
  mood_before TEXT, -- 'great', 'good', 'neutral', 'tired', 'hungry'
  mood_after TEXT,
  energy_level INTEGER, -- 1-5

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX idx_fasting_records_user ON fasting_records(user_id);
CREATE INDEX idx_fasting_records_user_date ON fasting_records(user_id, start_time DESC);

-- Fasting preferences table
CREATE TABLE fasting_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  -- Selected protocol
  default_protocol TEXT DEFAULT '16:8',
  custom_fasting_hours INTEGER,
  custom_eating_hours INTEGER,

  -- Schedule
  typical_fast_start_hour INTEGER DEFAULT 20, -- 8pm
  typical_eating_start_hour INTEGER DEFAULT 12, -- 12pm
  fasting_days TEXT[], -- For 5:2: ['monday', 'thursday']

  -- Notifications
  notifications_enabled BOOLEAN DEFAULT true,
  notify_zone_transitions BOOLEAN DEFAULT true,
  notify_goal_reached BOOLEAN DEFAULT true,
  notify_eating_window_end BOOLEAN DEFAULT true,

  -- Safety acknowledgments
  safety_screening_completed BOOLEAN DEFAULT false,
  safety_warnings_acknowledged TEXT[],

  -- Onboarding
  fasting_onboarding_completed BOOLEAN DEFAULT false,
  onboarding_completed_at TIMESTAMP,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Fasting streaks table
CREATE TABLE fasting_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,

  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_fasts_completed INTEGER DEFAULT 0,
  total_fasting_hours INTEGER DEFAULT 0,

  last_fast_date DATE,
  streak_start_date DATE,

  -- Weekly tracking (for 5:2, ADF)
  fasts_this_week INTEGER DEFAULT 0,
  week_start_date DATE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- RLS Policies
ALTER TABLE fasting_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY fasting_records_user_policy ON fasting_records
  FOR ALL USING (auth.uid() = user_id);

ALTER TABLE fasting_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY fasting_preferences_user_policy ON fasting_preferences
  FOR ALL USING (auth.uid() = user_id);

ALTER TABLE fasting_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY fasting_streaks_user_policy ON fasting_streaks
  FOR ALL USING (auth.uid() = user_id);
```

---

### Flutter Implementation

#### New Files to Create

| File | Purpose |
|------|---------|
| `lib/data/models/fasting.dart` | FastingRecord, FastingPreferences, FastingStreak models |
| `lib/data/repositories/fasting_repository.dart` | Fasting CRUD operations |
| `lib/data/providers/fasting_provider.dart` | Riverpod state management |
| `lib/services/fasting_timer_service.dart` | Background timer, zone calculations |
| `lib/services/fasting_notification_service.dart` | Push notifications |
| `lib/screens/fasting/fasting_screen.dart` | Main fasting tab/screen |
| `lib/screens/fasting/fasting_timer_widget.dart` | Circular timer with zones |
| `lib/screens/fasting/fasting_history_screen.dart` | Past fasts list |
| `lib/screens/fasting/fasting_stats_screen.dart` | Analytics and trends |
| `lib/screens/fasting/fasting_onboarding/` | Safety screening + protocol selection |
| `lib/widgets/fasting/zone_indicator.dart` | Current zone display |
| `lib/widgets/fasting/zone_timeline.dart` | Visual timeline of zones |

#### Fasting Timer Service

```dart
class FastingTimerService {
  // Calculate current zone based on elapsed time
  FastingZone getCurrentZone(int elapsedMinutes, {bool isKetoAdapted = false}) {
    int hours = elapsedMinutes ~/ 60;

    // Adjust timelines for keto-adapted users (enter zones faster)
    int adjustment = isKetoAdapted ? 2 : 0;

    if (hours < 4) return FastingZone.fed;
    if (hours < 8 - adjustment) return FastingZone.postAbsorptive;
    if (hours < 12 - adjustment) return FastingZone.earlyFasting;
    if (hours < 16 - adjustment) return FastingZone.fatBurning;
    if (hours < 24 - adjustment) return FastingZone.ketosis;
    if (hours < 48) return FastingZone.deepKetosis;
    return FastingZone.extended;
  }

  // Get time until next zone
  Duration timeUntilNextZone(int elapsedMinutes, FastingZone currentZone) {
    // Calculate minutes until next zone boundary
  }

  // Start background timer (for notifications even when app closed)
  Future<void> startBackgroundTimer(FastingRecord fast) async {
    // Use workmanager or flutter_background_service
  }
}

enum FastingZone {
  fed(name: 'Fed State', color: Colors.grey, startHour: 0),
  postAbsorptive(name: 'Processing', color: Colors.lightBlue, startHour: 4),
  earlyFasting(name: 'Early Fasting', color: Colors.teal, startHour: 8),
  fatBurning(name: 'Fat Burning', color: Colors.green, startHour: 12),
  ketosis(name: 'Ketosis', color: Colors.orange, startHour: 16),
  deepKetosis(name: 'Deep Ketosis', color: Colors.red, startHour: 24),
  extended(name: 'Extended', color: Colors.purple, startHour: 48);

  final String name;
  final Color color;
  final int startHour;

  const FastingZone({required this.name, required this.color, required this.startHour});
}
```

#### Fasting Timer Widget

```dart
class FastingTimerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fastingState = ref.watch(activeFastingProvider);

    return fastingState.when(
      noActiveFast: () => _buildStartFastButton(),
      activeFast: (fast) => _buildActiveTimer(fast),
    );
  }

  Widget _buildActiveTimer(FastingRecord fast) {
    return Column(
      children: [
        // Circular progress with zone colors
        CircularFastingProgress(
          elapsedMinutes: fast.elapsedMinutes,
          goalMinutes: fast.goalDurationMinutes,
          currentZone: fast.currentZone,
        ),

        // Time display
        Text('${fast.elapsedHours}h ${fast.elapsedMinutes % 60}m'),
        Text('${fast.remainingHours}h ${fast.remainingMinutes % 60}m remaining'),

        // Current zone
        ZoneIndicator(zone: fast.currentZone),

        // Zone timeline
        ZoneTimeline(
          currentMinutes: fast.elapsedMinutes,
          goalMinutes: fast.goalDurationMinutes,
        ),

        // End fast button
        ElevatedButton(
          onPressed: () => _showEndFastDialog(),
          child: Text('End Fast'),
        ),
      ],
    );
  }
}
```

---

### Fasting Onboarding Flow

#### Step 1: Safety Screening
- Ask contraindication questions
- Block or warn based on answers
- Store acknowledgments

#### Step 2: Experience Level
- "Have you tried intermittent fasting before?"
  - Never → Recommend 14:10 or 16:8
  - A few times → Recommend 16:8
  - Regularly → Show all options

#### Step 3: Protocol Selection
- Show protocols appropriate for experience level
- Explain each briefly
- Allow custom protocol creation

#### Step 4: Schedule Setup
- "When do you typically eat your last meal?"
- "When do you want to start eating?"
- Auto-calculate fasting window

#### Step 5: Notification Preferences
- Zone transition alerts
- Goal completion
- Eating window reminders

#### Step 6: Integration Options
- Link with nutrition tracking
- Adjust calorie targets on fasting days (5:2, ADF)

---

### AI Coach Integration

The AI coach should be aware of fasting status and provide contextual guidance:

```python
FASTING_COACH_CONTEXT = """
User's fasting status:
- Currently fasting: {is_fasting}
- Fasting protocol: {protocol}
- Time elapsed: {elapsed_hours}h
- Current zone: {current_zone}
- Time until eating window: {time_until_eating}

Guidelines:
1. If user is fasting and asks about food, gently remind them of their fasting goal
2. Suggest appropriate activities during fasting (walking, light work)
3. Recommend when to workout based on fasting state
4. Provide encouragement at challenging times (hours 12-16)
5. Suggest what to break fast with based on fast duration
"""
```

**Workout + Fasting Recommendations:**
- Light cardio: OK any time during fast
- Strength training: Best in last 2-4 hours of fast or within eating window
- HIIT: Best within eating window (need glycogen)
- Post-workout: If fasted training, prioritize protein at first meal

---

### Competitive Differentiation

**What makes our fasting feature unique:**

1. **AI-Powered Integration** - Coach that understands both fasting AND fitness context
2. **Workout-Fasting Coordination** - Recommends optimal workout timing based on fasting state
3. **Personalized Zone Timing** - Adjusts metabolic stage estimates based on diet and activity
4. **Seamless Nutrition Integration** - Auto-adjusts calorie targets on fasting days
5. **Evidence-Based Disclaimers** - Honest about what science supports vs. what's speculative

---

### Implementation Priority

| Priority | Feature | Complexity | Impact |
|----------|---------|------------|--------|
| P1 | Basic fasting timer (16:8, 18:6) | Medium | High |
| P1 | Zone visualization | Low | High |
| P1 | Safety screening | Low | Critical |
| P1 | Streak tracking | Low | High |
| P2 | All TRE protocols | Low | Medium |
| P2 | 5:2 and ADF support | Medium | Medium |
| P2 | Nutrition integration (calorie adjustment) | Medium | High |
| P2 | Notifications | Medium | High |
| P3 | Extended fasting (24h+) | Medium | Low |
| P3 | AI coach integration | Low | High |
| P3 | Fasting analytics | Medium | Medium |
| P4 | Social/challenges | High | Medium |

---

### Fasting Sources

- NCBI - Physiology, Fasting: https://www.ncbi.nlm.nih.gov/books/NBK534877/
- PMC - Flipping the Metabolic Switch: https://pmc.ncbi.nlm.nih.gov/articles/PMC5783752/
- PMC - Long-Term Fasting-Induced Ketosis: https://pmc.ncbi.nlm.nih.gov/articles/PMC11206495/
- Cleveland Clinic - Autophagy: https://my.clevelandclinic.org/health/articles/24058-autophagy
- Zero Fasting App: https://zerolongevity.com/
- Fastic App: https://fastic.com/en
- LIFE Fasting - 5 Stages: https://lifeapps.io/fasting/the-5-stages-of-intermittent-fasting/
- Harvard Health - IF Side Effects: https://www.health.harvard.edu/staying-healthy/4-intermittent-fasting-side-effects-to-watch-out-for
- PMC - Refeeding Syndrome: https://pmc.ncbi.nlm.nih.gov/articles/PMC2440847/

---

## Unified Fasting + Nutrition + Workout Integration

### Overview

This section describes how to tightly integrate fasting, nutrition, and workout features into a cohesive system. This integration is our **key differentiator** - no competitor offers this level of cross-feature intelligence.

---

### Context-Aware Dashboard State System

The app should understand the user's current state and adapt the UI/recommendations accordingly.

```dart
enum AppState {
  fastingActive,      // Currently in a fast
  eatingWindow,       // Fast completed, eating window open
  preworkout,         // 1-2 hours before scheduled workout
  duringWorkout,      // Active workout session
  postWorkout,        // 0-2 hours after workout completion
  restDay,            // No workout scheduled today
}

class UnifiedStateProvider extends StateNotifier<AppState> {
  // Determines current state based on:
  // 1. Active fasting timer
  // 2. Scheduled workouts
  // 3. Recent workout completions
  // 4. Time of day vs eating window

  AppState calculateCurrentState() {
    if (hasActiveFast) return AppState.fastingActive;
    if (isWithinPostWorkoutWindow) return AppState.postWorkout;
    if (hasWorkoutInNext2Hours) return AppState.preworkout;
    if (hasActiveWorkout) return AppState.duringWorkout;
    if (isEatingWindow) return AppState.eatingWindow;
    return AppState.restDay;
  }
}
```

#### Dashboard Adaptations by State

| State | Dashboard Shows | Quick Actions | AI Coach Focus |
|-------|----------------|---------------|----------------|
| **fastingActive** | Fasting timer prominent, zone progress | "End Fast", "Log Water" | Fasting encouragement, when to workout |
| **eatingWindow** | Calories remaining, meal suggestions | "Log Meal", "Quick Add" | What to eat, meal timing |
| **preworkout** | Pre-workout nutrition, workout preview | "Log Pre-Workout Meal", "Start Workout" | Fuel recommendations |
| **duringWorkout** | Workout tracker, heart rate | "Complete Set", "Rest Timer" | Exercise form, motivation |
| **postWorkout** | Post-workout nutrition, recovery | "Log Post-Workout Meal", "Log Protein Shake" | Recovery nutrition, protein timing |
| **restDay** | Recovery metrics, tomorrow's workout | "Log Meal", "View Progress" | Rest importance, light activity |

---

### Fasted Training Recommendations (Evidence-Based)

Research supports different approaches based on workout type and fasting duration.

#### Workout Type vs Fasting State Matrix

| Workout Type | <12h Fasted | 12-16h Fasted | 16-20h Fasted | 20h+ Fasted |
|--------------|-------------|---------------|---------------|-------------|
| **Light Cardio** | OK | OK | OK | OK with caution |
| **Moderate Cardio** | OK | OK | OK | Caution |
| **HIIT/Sprints** | OK | Caution | Not Recommended | Not Recommended |
| **Strength Training** | OK | OK | OK (may benefit) | Caution |
| **Endurance (>60min)** | OK | Caution | Not Recommended | Not Recommended |

#### Fasted Training Benefits (When Appropriate)

- **Fat oxidation**: 20% higher during fasted low-intensity cardio
- **Growth hormone**: May increase during fasted strength training (12-16h fasted)
- **Insulin sensitivity**: Improved post-fasted exercise
- **Metabolic flexibility**: Training the body to use fat efficiently

#### Fasted Training Risks

- **Muscle breakdown**: Risk increases with high intensity + extended fasts
- **Performance decline**: HIIT performance drops 10-20% when fasted
- **Hypoglycemia risk**: Especially with intense exercise + 16h+ fasts
- **Recovery impairment**: If post-workout nutrition is delayed

---

### Smart Workout Scheduling

```dart
class WorkoutFastingAdvisor {
  WorkoutRecommendation getRecommendation({
    required Workout scheduledWorkout,
    required int hoursFasted,
    required bool isEatingWindowOpen,
    required String userExperience, // 'beginner', 'intermediate', 'advanced'
  }) {
    // HIIT during extended fast - warn
    if (scheduledWorkout.intensity == 'high' && hoursFasted > 14) {
      return WorkoutRecommendation(
        proceed: false,
        warning: "High-intensity workouts aren't recommended after 14+ hours fasted. Consider:"
                 "\n• Moving workout to eating window"
                 "\n• Switching to light cardio"
                 "\n• Having a small pre-workout snack (breaks fast)",
        alternatives: ['light_cardio', 'reschedule', 'eat_first'],
      );
    }

    // Strength training 12-16h fasted - great for experienced users
    if (scheduledWorkout.type == 'strength' && hoursFasted >= 12 && hoursFasted <= 16) {
      return WorkoutRecommendation(
        proceed: true,
        tip: "Good timing! Fasted strength training may boost growth hormone. "
             "Plan a protein-rich meal within 1-2 hours after.",
        postWorkoutReminder: true,
      );
    }

    // Endurance workout during extended fast
    if (scheduledWorkout.duration > 60 && hoursFasted > 12) {
      return WorkoutRecommendation(
        proceed: false,
        warning: "Long workouts need fuel. Options:"
                 "\n• Schedule during eating window"
                 "\n• Have a light pre-workout meal",
        alternatives: ['reschedule', 'eat_first'],
      );
    }

    // Light cardio - always OK
    if (scheduledWorkout.intensity == 'low') {
      return WorkoutRecommendation(
        proceed: true,
        tip: "Light cardio is perfect for fasted training. Great for fat burning!",
      );
    }

    return WorkoutRecommendation(proceed: true);
  }
}
```

---

### Dynamic Nutrition Targets

Calorie and macro targets should adjust based on training status and fasting protocol.

#### Training Day vs Rest Day Adjustments

```dart
class DynamicNutritionTargets {
  NutritionTargets getTargetsForToday({
    required NutritionPreferences basePreferences,
    required Workout? todaysWorkout,
    required FastingProtocol? fastingProtocol,
    required bool isFastingDay, // For 5:2, ADF
  }) {
    int baseCalories = basePreferences.targetCalories;
    int baseProtein = basePreferences.targetProteinG;
    int baseCarbs = basePreferences.targetCarbsG;
    int baseFat = basePreferences.targetFatG;

    // 5:2 or ADF fasting day
    if (isFastingDay && fastingProtocol?.type == 'modified') {
      return NutritionTargets(
        calories: fastingProtocol.fastingDayCalories, // 500-600
        protein: 50, // Minimum for muscle preservation
        carbs: 30,
        fat: 25,
        note: "Fasting day - focus on protein and vegetables",
      );
    }

    // Heavy training day
    if (todaysWorkout != null && todaysWorkout.intensity == 'high') {
      return NutritionTargets(
        calories: baseCalories + 200, // Slight surplus
        protein: (baseProtein * 1.1).round(), // 10% more protein
        carbs: (baseCarbs * 1.2).round(), // 20% more carbs for glycogen
        fat: baseFat,
        note: "Training day - extra fuel for performance and recovery",
      );
    }

    // Moderate training day
    if (todaysWorkout != null && todaysWorkout.intensity == 'moderate') {
      return NutritionTargets(
        calories: baseCalories + 100,
        protein: baseProtein,
        carbs: (baseCarbs * 1.1).round(),
        fat: baseFat,
        note: "Moderate training - slight increase for recovery",
      );
    }

    // Rest day - slight reduction (optional based on user preference)
    if (todaysWorkout == null && basePreferences.adjustForRestDays) {
      return NutritionTargets(
        calories: baseCalories - 100,
        protein: baseProtein, // Keep protein high
        carbs: (baseCarbs * 0.9).round(), // Slightly lower carbs
        fat: baseFat,
        note: "Rest day - focus on recovery and protein",
      );
    }

    return NutritionTargets.fromBase(basePreferences);
  }
}
```

#### Weekly Calorie Averaging (For 5:2, ADF)

```dart
class WeeklyCalorieManager {
  WeeklySummary calculateWeeklyTargets({
    required NutritionPreferences prefs,
    required FastingProtocol protocol,
  }) {
    if (protocol.type == '5:2') {
      int normalDayCals = prefs.targetCalories;
      int fastingDayCals = prefs.gender == 'female' ? 500 : 600;

      int weeklyTotal = (5 * normalDayCals) + (2 * fastingDayCals);
      int dailyAverage = weeklyTotal ~/ 7;

      return WeeklySummary(
        normalDayTarget: normalDayCals,
        fastingDayTarget: fastingDayCals,
        weeklyTotalTarget: weeklyTotal,
        dailyAverageTarget: dailyAverage,
        fastingDays: protocol.fastingDays, // e.g., ['monday', 'thursday']
      );
    }

    if (protocol.type == 'adf') {
      int normalDayCals = prefs.targetCalories;
      int fastingDayCals = (normalDayCals * 0.25).round();

      // Alternate days (3.5 of each per week)
      int weeklyTotal = ((3.5 * normalDayCals) + (3.5 * fastingDayCals)).round();

      return WeeklySummary(
        normalDayTarget: normalDayCals,
        fastingDayTarget: fastingDayCals,
        weeklyTotalTarget: weeklyTotal,
        dailyAverageTarget: weeklyTotal ~/ 7,
      );
    }

    return WeeklySummary.standard(prefs.targetCalories);
  }
}
```

---

### Pre/Post Workout Nutrition Guidance

#### Pre-Workout Nutrition (If Not Fasted)

| Time Before | Meal Type | Example | Macros Focus |
|-------------|-----------|---------|--------------|
| **2-3 hours** | Full meal | Chicken, rice, vegetables | Balanced |
| **1-2 hours** | Medium snack | Greek yogurt + banana | Carbs + protein |
| **30-60 min** | Light snack | Banana, rice cake | Fast carbs |
| **<30 min** | Nothing or liquid | Water, maybe sports drink | Hydration |

#### Post-Workout Nutrition (The "Anabolic Window")

| Time After | Priority | Recommendation |
|------------|----------|----------------|
| **0-30 min** | Optional | Fast protein shake if fasted training |
| **30-60 min** | High | Protein + carbs meal |
| **1-2 hours** | Important | Full balanced meal |
| **Beyond 2h** | Normal | Return to regular eating pattern |

**Key insight from research:** The "anabolic window" is longer than previously thought (4-6 hours), but consuming protein within 2 hours of training optimizes muscle protein synthesis.

```dart
class PostWorkoutNutritionService {
  PostWorkoutGuidance getGuidance({
    required Workout completedWorkout,
    required bool wasFastedTraining,
    required int minutesSinceCompletion,
  }) {
    if (wasFastedTraining && minutesSinceCompletion < 60) {
      return PostWorkoutGuidance(
        urgency: 'high',
        message: "You trained fasted - prioritize protein now!",
        suggestions: [
          MealSuggestion('Protein shake', '25-40g protein'),
          MealSuggestion('Greek yogurt + fruit', '20g protein + carbs'),
          MealSuggestion('Eggs + toast', '18g protein + carbs'),
        ],
        macroTargets: MacroTargets(
          protein: 30, // grams minimum
          carbs: 40,   // for glycogen
          fat: 10,     // moderate
        ),
      );
    }

    if (completedWorkout.type == 'strength') {
      return PostWorkoutGuidance(
        urgency: minutesSinceCompletion < 120 ? 'medium' : 'low',
        message: "Fuel your recovery with protein and carbs",
        macroTargets: MacroTargets(
          protein: 25,
          carbs: 50,
          fat: 15,
        ),
      );
    }

    return PostWorkoutGuidance.standard();
  }
}
```

---

### Fasting + Meal Logging Integration

When users log meals, the system should be aware of fasting context.

```dart
class MealLoggingService {
  Future<MealLogResult> logMeal(FoodLog meal) async {
    final fastingState = await _fastingRepository.getActiveFast();

    // Check if this meal breaks a fast
    if (fastingState != null && meal.totalCalories > 50) {
      // Show confirmation dialog
      final shouldBreakFast = await _showBreakFastDialog(fastingState);

      if (shouldBreakFast) {
        // End the fast
        await _fastingRepository.endFast(
          fastingState.id,
          endedBy: 'meal_logged',
          actualDuration: fastingState.elapsedMinutes,
        );

        // Log the meal
        final result = await _nutritionRepository.logMeal(meal);

        return MealLogResult(
          success: true,
          fastEnded: true,
          fastDuration: fastingState.elapsedMinutes,
          message: "Fast ended after ${fastingState.elapsedHours}h. Meal logged!",
        );
      } else {
        return MealLogResult(success: false, cancelled: true);
      }
    }

    // Normal meal logging (no active fast)
    return await _nutritionRepository.logMeal(meal);
  }

  Future<bool> _showBreakFastDialog(FastingRecord fast) async {
    return await showDialog<bool>(
      builder: (context) => AlertDialog(
        title: Text('End Your Fast?'),
        content: Text(
          'You\'ve been fasting for ${fast.elapsedHours}h ${fast.elapsedMinutes % 60}m.\n\n'
          'Logging this meal will end your fast. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('End Fast & Log Meal'),
          ),
        ],
      ),
    );
  }
}
```

---

### AI Coach Unified Context

The AI coach should have complete awareness of all three domains.

```python
UNIFIED_COACH_CONTEXT = """
## User's Current State

### Fasting Status
- Currently fasting: {is_fasting}
- Protocol: {fasting_protocol}
- Hours fasted: {hours_fasted}
- Current metabolic zone: {current_zone}
- Eating window: {eating_window_start} - {eating_window_end}

### Today's Workout
- Scheduled: {has_workout_today}
- Type: {workout_type}
- Intensity: {workout_intensity}
- Scheduled time: {workout_time}
- Completed: {workout_completed}
- Training fasted: {will_train_fasted}

### Nutrition Today
- Calories consumed: {calories_eaten} / {calorie_target}
- Protein consumed: {protein_eaten}g / {protein_target}g
- Meals logged: {meals_logged}
- Is fasting day (5:2/ADF): {is_fasting_day}

### Training + Fasting Interaction
- Safe to train now: {safe_to_train}
- Recommended workout timing: {recommended_workout_time}
- Post-workout nutrition needed: {needs_post_workout_meal}

## Coaching Guidelines

1. **Workout Timing**:
   - If user plans high-intensity workout and has been fasting 14+ hours, suggest eating first or switching to lighter exercise
   - For strength training at 12-16h fasted, this is optimal for many - encourage!

2. **Meal Suggestions**:
   - If in eating window and workout completed, emphasize protein
   - If pre-workout (1-2h before), suggest carb-focused snack
   - If on 5:2 fasting day, focus on protein-rich low-calorie foods

3. **Fasting Encouragement**:
   - At challenging times (12-16h), offer encouragement and distraction tips
   - Don't push extended fasting on beginners

4. **Conflict Resolution**:
   - If workout conflicts with fasting plan, help user decide priority
   - Never make user feel guilty about either choice
"""
```

---

### Conflict Detection & Resolution

```dart
class ConflictDetector {
  List<Conflict> detectConflicts({
    required FastingPreferences fasting,
    required List<Workout> scheduledWorkouts,
    required NutritionPreferences nutrition,
  }) {
    List<Conflict> conflicts = [];

    // Check each scheduled workout against fasting window
    for (final workout in scheduledWorkouts) {
      final workoutTime = workout.scheduledTime;
      final fastingStart = fasting.typicalFastStartHour;
      final eatingStart = fasting.typicalEatingStartHour;

      // Calculate hours fasted at workout time
      int hoursFastedAtWorkout = _calculateHoursFasted(workoutTime, fastingStart);

      // High intensity during extended fast
      if (workout.intensity == 'high' && hoursFastedAtWorkout > 14) {
        conflicts.add(Conflict(
          type: ConflictType.highIntensityExtendedFast,
          severity: 'high',
          workout: workout,
          hoursFasted: hoursFastedAtWorkout,
          suggestions: [
            'Move workout to eating window',
            'Switch to moderate intensity',
            'Have a pre-workout snack (will break fast)',
          ],
        ));
      }

      // Endurance workout during fast
      if (workout.duration > 60 && hoursFastedAtWorkout > 12) {
        conflicts.add(Conflict(
          type: ConflictType.enduranceDuringFast,
          severity: 'medium',
          workout: workout,
          hoursFasted: hoursFastedAtWorkout,
          suggestions: [
            'Schedule for eating window',
            'Reduce duration',
            'Bring emergency fuel (breaks fast if used)',
          ],
        ));
      }

      // Post-workout falls outside eating window
      final postWorkoutTime = workoutTime.add(Duration(hours: 1));
      if (!_isInEatingWindow(postWorkoutTime, eatingStart, fastingStart)) {
        conflicts.add(Conflict(
          type: ConflictType.postWorkoutOutsideEatingWindow,
          severity: 'low',
          workout: workout,
          suggestions: [
            'Time workout so recovery meal falls in eating window',
            'Have post-workout nutrition before fast starts',
          ],
        ));
      }
    }

    // 5:2 fasting day conflicts with heavy training
    if (fasting.protocol == '5:2') {
      for (final workout in scheduledWorkouts) {
        if (fasting.fastingDays.contains(workout.dayOfWeek) &&
            workout.intensity == 'high') {
          conflicts.add(Conflict(
            type: ConflictType.heavyTrainingOnFastingDay,
            severity: 'medium',
            workout: workout,
            suggestions: [
              'Move intense workouts to normal eating days',
              'Do light cardio on fasting days',
              'Adjust fasting days around workout schedule',
            ],
          ));
        }
      }
    }

    return conflicts;
  }
}
```

---

### Database Schema Additions for Integration

```sql
-- Unified daily state tracking
CREATE TABLE daily_unified_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Fasting
  fasting_protocol TEXT,
  is_fasting_day BOOLEAN DEFAULT false, -- For 5:2, ADF
  fasted_hours INTEGER DEFAULT 0,

  -- Workout
  workout_completed BOOLEAN DEFAULT false,
  workout_type TEXT,
  workout_intensity TEXT,
  trained_fasted BOOLEAN DEFAULT false,

  -- Nutrition
  calorie_target INTEGER,
  calorie_actual INTEGER DEFAULT 0,
  protein_target_g INTEGER,
  protein_actual_g INTEGER DEFAULT 0,
  post_workout_meal_logged BOOLEAN DEFAULT false,

  -- Computed
  target_adjustment_reason TEXT, -- 'training_day', 'rest_day', 'fasting_day'

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  UNIQUE(user_id, date)
);

CREATE INDEX idx_daily_unified_state_user_date ON daily_unified_state(user_id, date DESC);

-- Integration preferences
ALTER TABLE users ADD COLUMN IF NOT EXISTS
  adjust_calories_for_training BOOLEAN DEFAULT true;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  adjust_calories_for_rest BOOLEAN DEFAULT false;

ALTER TABLE users ADD COLUMN IF NOT EXISTS
  show_fasting_workout_warnings BOOLEAN DEFAULT true;
```

---

### Implementation Priority for Integration

| Priority | Feature | Complexity | Impact |
|----------|---------|------------|--------|
| P1 | Context-aware dashboard state | Medium | High |
| P1 | Meal logging detects active fast | Low | High |
| P1 | Fasted training warnings | Low | Critical (safety) |
| P2 | Dynamic calorie targets (training day) | Medium | High |
| P2 | Post-workout nutrition reminders | Low | High |
| P2 | AI coach unified context | Medium | High |
| P2 | Conflict detection | Medium | Medium |
| P3 | Weekly calorie averaging (5:2, ADF) | Medium | Medium |
| P3 | Pre-workout nutrition timing | Low | Medium |
| P3 | Workout scheduling suggestions | Medium | Medium |

---

### Integration Sources

- Fasted Training Research: https://pmc.ncbi.nlm.nih.gov/articles/PMC5371748/
- Protein Timing Meta-Analysis: https://pubmed.ncbi.nlm.nih.gov/24299050/
- Training Periodization & Nutrition: https://www.nsca.com/education/articles/
- Glycogen & Performance: https://pmc.ncbi.nlm.nih.gov/articles/PMC6019055/
- ISSN Position Stand Nutrient Timing: https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0189-4
