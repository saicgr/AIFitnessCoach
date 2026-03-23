-- Migration 046: Add unit support to goals (reps, seconds, minutes, kg, km, miles, steps, calories)
-- and widen numeric columns to NUMERIC(10,2) to support decimals (kg: 82.5, km: 5.5)

-- weekly_personal_goals: add unit column, widen numeric fields
ALTER TABLE weekly_personal_goals
  ADD COLUMN IF NOT EXISTS unit VARCHAR(20) NOT NULL DEFAULT 'reps',
  ALTER COLUMN target_value  TYPE NUMERIC(10,2),
  ALTER COLUMN current_value TYPE NUMERIC(10,2),
  ALTER COLUMN personal_best TYPE NUMERIC(10,2);

-- goal_attempts: widen attempt_value
ALTER TABLE goal_attempts
  ALTER COLUMN attempt_value TYPE NUMERIC(10,2);

-- personal_goal_records: widen record columns
ALTER TABLE personal_goal_records
  ALTER COLUMN record_value   TYPE NUMERIC(10,2),
  ALTER COLUMN previous_value TYPE NUMERIC(10,2);

-- goal_suggestions: add unit column, widen suggested_target
ALTER TABLE goal_suggestions
  ADD COLUMN IF NOT EXISTS unit VARCHAR(20) NOT NULL DEFAULT 'reps',
  ALTER COLUMN suggested_target TYPE NUMERIC(10,2);
