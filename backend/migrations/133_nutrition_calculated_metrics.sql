-- Migration: 133_nutrition_calculated_metrics.sql
-- Description: Add calculated nutrition metrics for differentiating FitWiz from other apps
-- These metrics are calculated from user quiz data and used in AI/RAG context
-- Created: 2026-01-04

-- ============================================================================
-- PART 1: ADD NEW COLUMNS TO nutrition_preferences
-- ============================================================================

-- Metabolic age (calculated by comparing user's BMR to population averages)
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS metabolic_age INTEGER;

-- Water intake recommendation (liters per day)
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS water_intake_liters DECIMAL(4,2);

-- Maximum safe calorie deficit (MFM formula: 31.4 x fat mass)
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS max_safe_deficit INTEGER;

-- Body composition estimates
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS estimated_body_fat_percent DECIMAL(5,2);

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS lean_mass_kg DECIMAL(5,2);

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS fat_mass_kg DECIMAL(5,2);

-- Protein per kg recommendation
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS protein_per_kg DECIMAL(4,2);

-- Ideal weight range based on height and BMI 18.5-24.9
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS ideal_weight_min_kg DECIMAL(5,2);

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS ideal_weight_max_kg DECIMAL(5,2);

-- Goal timeline
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS goal_date DATE;

ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS weeks_to_goal INTEGER;

-- Timestamp for when metrics were last calculated
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS metrics_calculated_at TIMESTAMPTZ;

-- Meals per day preference (4, 5, or 6)
ALTER TABLE nutrition_preferences
ADD COLUMN IF NOT EXISTS meals_per_day INTEGER DEFAULT 4;

-- ============================================================================
-- PART 2: ADD age AND gender TO users TABLE IF NOT EXISTS
-- ============================================================================

-- These should already exist but let's ensure they do
ALTER TABLE users
ADD COLUMN IF NOT EXISTS age INTEGER;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS gender VARCHAR(10);

-- ============================================================================
-- PART 3: CREATE FUNCTION TO RECALCULATE NUTRITION METRICS
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_nutrition_metrics(
    p_user_id UUID,
    p_weight_kg DECIMAL,
    p_height_cm DECIMAL,
    p_age INTEGER,
    p_gender VARCHAR,
    p_activity_level VARCHAR DEFAULT 'lightly_active',
    p_weight_direction VARCHAR DEFAULT 'maintain',
    p_weight_change_rate VARCHAR DEFAULT 'moderate',
    p_goal_weight_kg DECIMAL DEFAULT NULL,
    p_nutrition_goals TEXT[] DEFAULT NULL,
    p_workout_days_per_week INTEGER DEFAULT 3
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_bmr INTEGER;
    v_tdee INTEGER;
    v_target_calories INTEGER;
    v_activity_multiplier DECIMAL;
    v_goal_adjustment INTEGER;
    v_protein_g INTEGER;
    v_carbs_g INTEGER;
    v_fat_g INTEGER;
    v_metabolic_age INTEGER;
    v_water_liters DECIMAL;
    v_body_fat_percent DECIMAL;
    v_lean_mass DECIMAL;
    v_fat_mass DECIMAL;
    v_max_safe_deficit INTEGER;
    v_protein_per_kg DECIMAL;
    v_ideal_weight_min DECIMAL;
    v_ideal_weight_max DECIMAL;
    v_goal_date DATE;
    v_weeks_to_goal INTEGER;
    v_bmi DECIMAL;
    v_height_m DECIMAL;
    v_weekly_rate DECIMAL;
    v_primary_goal TEXT;
    v_result JSONB;
BEGIN
    -- Validate inputs
    IF p_weight_kg IS NULL OR p_height_cm IS NULL OR p_age IS NULL OR p_gender IS NULL THEN
        RAISE EXCEPTION 'Missing required parameters';
    END IF;

    v_height_m := p_height_cm / 100;

    -- ==========================================
    -- BMR Calculation (Mifflin-St Jeor)
    -- ==========================================
    IF LOWER(p_gender) = 'male' THEN
        v_bmr := ROUND((10 * p_weight_kg) + (6.25 * p_height_cm) - (5 * p_age) + 5);
    ELSE
        v_bmr := ROUND((10 * p_weight_kg) + (6.25 * p_height_cm) - (5 * p_age) - 161);
    END IF;

    -- ==========================================
    -- TDEE Calculation
    -- ==========================================
    v_activity_multiplier := CASE p_activity_level
        WHEN 'sedentary' THEN 1.2
        WHEN 'lightly_active' THEN 1.375
        WHEN 'moderately_active' THEN 1.55
        WHEN 'very_active' THEN 1.725
        WHEN 'extremely_active' THEN 1.9
        ELSE 1.375
    END;
    v_tdee := ROUND(v_bmr * v_activity_multiplier);

    -- ==========================================
    -- Goal Adjustment
    -- ==========================================
    v_goal_adjustment := CASE
        WHEN p_weight_direction = 'lose' THEN
            CASE p_weight_change_rate
                WHEN 'slow' THEN -250
                WHEN 'moderate' THEN -500
                WHEN 'fast' THEN -750
                WHEN 'aggressive' THEN -1000
                ELSE -500
            END
        WHEN p_weight_direction = 'gain' THEN
            CASE p_weight_change_rate
                WHEN 'slow' THEN 250
                WHEN 'moderate' THEN 375
                WHEN 'fast' THEN 500
                ELSE 375
            END
        ELSE 0
    END;

    v_target_calories := GREATEST(
        CASE WHEN LOWER(p_gender) = 'male' THEN 1500 ELSE 1200 END,
        LEAST(4000, v_tdee + v_goal_adjustment)
    );

    -- ==========================================
    -- Macro Distribution
    -- ==========================================
    v_primary_goal := COALESCE(p_nutrition_goals[1], 'maintain');

    -- Calculate macros based on primary goal
    CASE v_primary_goal
        WHEN 'lose_fat' THEN
            v_protein_g := ROUND((v_target_calories * 0.35) / 4);
            v_carbs_g := ROUND((v_target_calories * 0.30) / 4);
            v_fat_g := ROUND((v_target_calories * 0.35) / 9);
        WHEN 'build_muscle' THEN
            v_protein_g := ROUND((v_target_calories * 0.30) / 4);
            v_carbs_g := ROUND((v_target_calories * 0.45) / 4);
            v_fat_g := ROUND((v_target_calories * 0.25) / 9);
        WHEN 'improve_energy' THEN
            v_protein_g := ROUND((v_target_calories * 0.25) / 4);
            v_carbs_g := ROUND((v_target_calories * 0.50) / 4);
            v_fat_g := ROUND((v_target_calories * 0.25) / 9);
        WHEN 'recomposition' THEN
            v_protein_g := ROUND((v_target_calories * 0.35) / 4);
            v_carbs_g := ROUND((v_target_calories * 0.35) / 4);
            v_fat_g := ROUND((v_target_calories * 0.30) / 9);
        ELSE -- maintain, eat_healthier
            v_protein_g := ROUND((v_target_calories * 0.25) / 4);
            v_carbs_g := ROUND((v_target_calories * 0.45) / 4);
            v_fat_g := ROUND((v_target_calories * 0.30) / 9);
    END CASE;

    -- ==========================================
    -- Body Fat Estimate (from BMI)
    -- ==========================================
    v_bmi := p_weight_kg / (v_height_m * v_height_m);
    IF LOWER(p_gender) = 'male' THEN
        v_body_fat_percent := GREATEST(5, LEAST(50, (1.20 * v_bmi) + (0.23 * p_age) - 16.2));
    ELSE
        v_body_fat_percent := GREATEST(5, LEAST(50, (1.20 * v_bmi) + (0.23 * p_age) - 5.4));
    END IF;

    -- ==========================================
    -- Body Composition
    -- ==========================================
    v_fat_mass := ROUND((p_weight_kg * v_body_fat_percent / 100)::DECIMAL, 1);
    v_lean_mass := ROUND((p_weight_kg - v_fat_mass)::DECIMAL, 1);

    -- ==========================================
    -- Maximum Safe Deficit (MFM)
    -- ==========================================
    v_max_safe_deficit := GREATEST(250, LEAST(1500, ROUND(31.4 * v_fat_mass)));

    -- ==========================================
    -- Water Intake
    -- ==========================================
    v_water_liters := ROUND((p_weight_kg * 0.033 + (COALESCE(p_workout_days_per_week, 3) * 0.5 / 7))::DECIMAL, 1);

    -- ==========================================
    -- Metabolic Age
    -- ==========================================
    DECLARE
        v_avg_bmr_for_age INTEGER;
        v_gender_adjusted_avg DECIMAL;
        v_ratio DECIMAL;
    BEGIN
        -- Get average BMR for age (simplified lookup)
        v_avg_bmr_for_age := CASE
            WHEN p_age <= 20 THEN 1660
            WHEN p_age <= 25 THEN 1620
            WHEN p_age <= 30 THEN 1580
            WHEN p_age <= 35 THEN 1540
            WHEN p_age <= 40 THEN 1500
            WHEN p_age <= 45 THEN 1460
            WHEN p_age <= 50 THEN 1420
            WHEN p_age <= 55 THEN 1380
            WHEN p_age <= 60 THEN 1340
            WHEN p_age <= 65 THEN 1300
            WHEN p_age <= 70 THEN 1260
            ELSE 1220
        END;

        v_gender_adjusted_avg := CASE WHEN LOWER(p_gender) = 'male'
            THEN v_avg_bmr_for_age * 1.1
            ELSE v_avg_bmr_for_age * 0.9
        END;

        v_ratio := v_gender_adjusted_avg / v_bmr;
        v_metabolic_age := GREATEST(15, LEAST(90, ROUND(p_age * v_ratio)));
    END;

    -- ==========================================
    -- Protein Per Kg
    -- ==========================================
    v_protein_per_kg := CASE v_primary_goal
        WHEN 'lose_fat' THEN 2.0
        WHEN 'build_muscle' THEN 1.8
        WHEN 'recomposition' THEN 2.2
        WHEN 'improve_energy' THEN 1.4
        WHEN 'eat_healthier' THEN 1.4
        ELSE 1.6
    END;

    -- ==========================================
    -- Ideal Weight Range (BMI 18.5-24.9)
    -- ==========================================
    v_ideal_weight_min := ROUND((18.5 * v_height_m * v_height_m)::DECIMAL, 1);
    v_ideal_weight_max := ROUND((24.9 * v_height_m * v_height_m)::DECIMAL, 1);

    -- ==========================================
    -- Goal Timeline
    -- ==========================================
    IF p_goal_weight_kg IS NOT NULL AND p_weight_direction != 'maintain'
       AND ABS(p_weight_kg - p_goal_weight_kg) >= 0.1 THEN
        v_weekly_rate := CASE
            WHEN p_weight_direction = 'lose' THEN
                CASE p_weight_change_rate
                    WHEN 'slow' THEN 0.25
                    WHEN 'moderate' THEN 0.5
                    WHEN 'fast' THEN 0.75
                    WHEN 'aggressive' THEN 1.0
                    ELSE 0.5
                END
            WHEN p_weight_direction = 'gain' THEN
                CASE p_weight_change_rate
                    WHEN 'slow' THEN 0.25
                    WHEN 'moderate' THEN 0.35
                    WHEN 'fast' THEN 0.5
                    ELSE 0.35
                END
            ELSE 0.5
        END;

        v_weeks_to_goal := CEIL(ABS(p_weight_kg - p_goal_weight_kg) / v_weekly_rate);
        v_goal_date := CURRENT_DATE + (v_weeks_to_goal * 7);
    END IF;

    -- ==========================================
    -- Update nutrition_preferences
    -- ==========================================
    INSERT INTO nutrition_preferences (
        user_id,
        calculated_bmr,
        calculated_tdee,
        target_calories,
        target_protein_g,
        target_carbs_g,
        target_fat_g,
        metabolic_age,
        water_intake_liters,
        max_safe_deficit,
        estimated_body_fat_percent,
        lean_mass_kg,
        fat_mass_kg,
        protein_per_kg,
        ideal_weight_min_kg,
        ideal_weight_max_kg,
        goal_date,
        weeks_to_goal,
        metrics_calculated_at,
        updated_at
    )
    VALUES (
        p_user_id,
        v_bmr,
        v_tdee,
        v_target_calories,
        v_protein_g,
        v_carbs_g,
        v_fat_g,
        v_metabolic_age,
        v_water_liters,
        v_max_safe_deficit,
        v_body_fat_percent,
        v_lean_mass,
        v_fat_mass,
        v_protein_per_kg,
        v_ideal_weight_min,
        v_ideal_weight_max,
        v_goal_date,
        v_weeks_to_goal,
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        calculated_bmr = EXCLUDED.calculated_bmr,
        calculated_tdee = EXCLUDED.calculated_tdee,
        target_calories = EXCLUDED.target_calories,
        target_protein_g = EXCLUDED.target_protein_g,
        target_carbs_g = EXCLUDED.target_carbs_g,
        target_fat_g = EXCLUDED.target_fat_g,
        metabolic_age = EXCLUDED.metabolic_age,
        water_intake_liters = EXCLUDED.water_intake_liters,
        max_safe_deficit = EXCLUDED.max_safe_deficit,
        estimated_body_fat_percent = EXCLUDED.estimated_body_fat_percent,
        lean_mass_kg = EXCLUDED.lean_mass_kg,
        fat_mass_kg = EXCLUDED.fat_mass_kg,
        protein_per_kg = EXCLUDED.protein_per_kg,
        ideal_weight_min_kg = EXCLUDED.ideal_weight_min_kg,
        ideal_weight_max_kg = EXCLUDED.ideal_weight_max_kg,
        goal_date = EXCLUDED.goal_date,
        weeks_to_goal = EXCLUDED.weeks_to_goal,
        metrics_calculated_at = NOW(),
        updated_at = NOW();

    -- Build result JSONB
    v_result := jsonb_build_object(
        'calories', v_target_calories,
        'protein', v_protein_g,
        'carbs', v_carbs_g,
        'fat', v_fat_g,
        'water_liters', v_water_liters,
        'metabolic_age', v_metabolic_age,
        'max_safe_deficit', v_max_safe_deficit,
        'body_fat_percent', v_body_fat_percent,
        'lean_mass', v_lean_mass,
        'fat_mass', v_fat_mass,
        'protein_per_kg', v_protein_per_kg,
        'ideal_weight_min', v_ideal_weight_min,
        'ideal_weight_max', v_ideal_weight_max,
        'goal_date', v_goal_date,
        'weeks_to_goal', v_weeks_to_goal,
        'bmr', v_bmr,
        'tdee', v_tdee
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 4: GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION calculate_nutrition_metrics TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_nutrition_metrics TO service_role;

-- ============================================================================
-- PART 5: ADD COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN nutrition_preferences.metabolic_age IS 'Calculated by comparing BMR to population averages. Lower than actual age = healthier metabolism.';
COMMENT ON COLUMN nutrition_preferences.water_intake_liters IS 'Personalized daily water recommendation based on weight and activity.';
COMMENT ON COLUMN nutrition_preferences.max_safe_deficit IS 'Maximum Fat Metabolism formula: 31.4 x fat mass. Largest safe deficit without muscle loss.';
COMMENT ON COLUMN nutrition_preferences.estimated_body_fat_percent IS 'Body fat estimate calculated from BMI using gender-specific formula.';
COMMENT ON COLUMN nutrition_preferences.lean_mass_kg IS 'Estimated lean mass (muscle, bone, organs) = weight - fat mass.';
COMMENT ON COLUMN nutrition_preferences.fat_mass_kg IS 'Estimated fat mass = weight x body fat percent.';
COMMENT ON COLUMN nutrition_preferences.protein_per_kg IS 'Recommended protein per kg body weight based on nutrition goals.';
COMMENT ON COLUMN nutrition_preferences.ideal_weight_min_kg IS 'Lower end of healthy BMI weight range (18.5).';
COMMENT ON COLUMN nutrition_preferences.ideal_weight_max_kg IS 'Upper end of healthy BMI weight range (24.9).';
COMMENT ON COLUMN nutrition_preferences.goal_date IS 'Projected date to reach goal weight based on selected rate.';
COMMENT ON COLUMN nutrition_preferences.weeks_to_goal IS 'Estimated weeks to reach goal weight.';
COMMENT ON COLUMN nutrition_preferences.metrics_calculated_at IS 'Timestamp when nutrition metrics were last calculated.';
COMMENT ON COLUMN nutrition_preferences.meals_per_day IS 'User preference for number of meals per day (4, 5, or 6).';

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
