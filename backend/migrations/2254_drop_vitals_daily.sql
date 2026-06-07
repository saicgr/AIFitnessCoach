-- Migration 2254: drop the redundant vitals_daily table (created in 2249).
--
-- 2249 created vitals_daily before we noticed daily_activity ALREADY has the
-- columns hrv, blood_oxygen, body_temperature, respiratory_rate and
-- resting_heart_rate (the client simply stopped populating them on 2026-05-07
-- when the Health Connect scope was trimmed). The Vitals feature reads those
-- columns straight from daily_activity — same table the rest of the daily
-- health sync already upserts — so a parallel vitals_daily table is dead
-- weight. Drop it; the Vitals service reads daily_activity.
--
-- Idempotent: DROP TABLE IF EXISTS.

DROP TABLE IF EXISTS vitals_daily;
