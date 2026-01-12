-- Migration 144: Fix View Security
-- Remove SECURITY DEFINER from weekly_adherence_summary view
-- This ensures the view uses the permissions of the querying user, not the view creator

-- Drop and recreate the view without SECURITY DEFINER
DROP VIEW IF EXISTS weekly_adherence_summary;

CREATE VIEW weekly_adherence_summary
WITH (security_invoker = true) AS
SELECT
    user_id,
    DATE_TRUNC('week', log_date)::DATE AS week_start,
    (DATE_TRUNC('week', log_date) + INTERVAL '6 days')::DATE AS week_end,
    COUNT(*)::INTEGER AS days_logged,
    7 AS days_in_week,

    -- Average adherence percentages
    AVG(calorie_adherence_pct)::DECIMAL(5,2) AS avg_calorie_adherence,
    AVG(protein_adherence_pct)::DECIMAL(5,2) AS avg_protein_adherence,
    AVG(carbs_adherence_pct)::DECIMAL(5,2) AS avg_carbs_adherence,
    AVG(fat_adherence_pct)::DECIMAL(5,2) AS avg_fat_adherence,
    AVG(overall_adherence_pct)::DECIMAL(5,2) AS avg_overall_adherence,

    -- Variance (consistency metric)
    COALESCE(VARIANCE(overall_adherence_pct), 0)::DECIMAL(8,2) AS adherence_variance,

    -- Days hitting targets (>95% adherence)
    SUM(CASE WHEN calorie_adherence_pct >= 95 THEN 1 ELSE 0 END)::INTEGER AS days_on_target_calories,
    SUM(CASE WHEN protein_adherence_pct >= 95 THEN 1 ELSE 0 END)::INTEGER AS days_on_target_protein,

    -- Direction counts
    SUM(CASE WHEN calories_over THEN 1 ELSE 0 END)::INTEGER AS days_over_calories,
    SUM(CASE WHEN protein_over THEN 1 ELSE 0 END)::INTEGER AS days_over_protein,

    -- Total meals logged
    SUM(meals_logged)::INTEGER AS total_meals_logged

FROM daily_adherence_logs
GROUP BY user_id, DATE_TRUNC('week', log_date);

-- Grant permissions on the view
GRANT SELECT ON weekly_adherence_summary TO authenticated;
GRANT SELECT ON weekly_adherence_summary TO service_role;
