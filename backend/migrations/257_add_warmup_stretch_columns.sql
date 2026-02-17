-- Add warmup_json and stretch_json columns to workouts table
-- These store structured warmup/stretch routines alongside the workout
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS warmup_json JSONB;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS stretch_json JSONB;
