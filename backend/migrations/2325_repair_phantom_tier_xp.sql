-- Migration 2325: repair XP inflated by the phantom leaderboard rewards that
-- migration 2324 now prevents. Backs everything up to _bak_2325_* tables first
-- (reversible), deletes the phantom reward rows, then recomputes user_xp from
-- the surviving transactions. Verified dry-run + post-apply: grandheclan
-- 11546 XP / L11 → 186 XP / L2; 7 accounts corrected; 73 phantom xp_transactions
-- (72,800 XP) removed.
--
-- Reversal: the deleted rows live in _bak_2325_xp_transactions,
-- _bak_2325_user_first_time_bonuses, _bak_2325_user_achievements,
-- _bak_2325_weekly_tier_rewards_audit, _bak_2325_user_tier_history,
-- _bak_2325_user_tier_cumulative, _bak_2325_tier_streaks; the pre-repair
-- user_xp snapshot is _bak_2325_user_xp.

DROP TABLE IF EXISTS _bak_2325_xp_transactions;
CREATE TABLE _bak_2325_xp_transactions AS
  SELECT * FROM xp_transactions
   WHERE source IN ('tier_first_time','tier_persistence','tier_cumulative','phoenix_rising','peak_rank','rising_star');

DROP TABLE IF EXISTS _bak_2325_user_first_time_bonuses;
CREATE TABLE _bak_2325_user_first_time_bonuses AS
  SELECT * FROM user_first_time_bonuses WHERE bonus_type LIKE 'discover_%';

DROP TABLE IF EXISTS _bak_2325_user_achievements;
CREATE TABLE _bak_2325_user_achievements AS
  SELECT * FROM user_achievements WHERE achievement_id LIKE 'discover_%';

DROP TABLE IF EXISTS _bak_2325_weekly_tier_rewards_audit;
CREATE TABLE _bak_2325_weekly_tier_rewards_audit AS SELECT * FROM weekly_tier_rewards_audit;

DROP TABLE IF EXISTS _bak_2325_user_tier_history;
CREATE TABLE _bak_2325_user_tier_history AS SELECT * FROM user_tier_history;

DROP TABLE IF EXISTS _bak_2325_user_tier_cumulative;
CREATE TABLE _bak_2325_user_tier_cumulative AS SELECT * FROM user_tier_cumulative;

DROP TABLE IF EXISTS _bak_2325_tier_streaks;
CREATE TABLE _bak_2325_tier_streaks AS SELECT * FROM tier_streaks;

DROP TABLE IF EXISTS _bak_2325_user_xp;
CREATE TABLE _bak_2325_user_xp AS SELECT * FROM user_xp;

DELETE FROM xp_transactions
 WHERE source IN ('tier_first_time','tier_persistence','tier_cumulative','phoenix_rising','peak_rank','rising_star');
DELETE FROM user_first_time_bonuses WHERE bonus_type LIKE 'discover_%';
DELETE FROM user_achievements WHERE achievement_id LIKE 'discover_%';
DELETE FROM weekly_tier_rewards_audit;
DELETE FROM user_tier_history;
DELETE FROM user_tier_cumulative;
DELETE FROM tier_streaks;

UPDATE user_xp x SET
  total_xp = s.new_total,
  current_level = lv.level,
  xp_to_next_level = lv.xp_for_next,
  xp_in_current_level = lv.xp_in_level,
  prestige_level = lv.prestige,
  title = lv.title,
  updated_at = NOW()
FROM (
  SELECT b.user_id, COALESCE(SUM(t.xp_amount), 0) AS new_total
    FROM (SELECT DISTINCT user_id FROM _bak_2325_xp_transactions) b
    LEFT JOIN xp_transactions t ON t.user_id = b.user_id
   GROUP BY b.user_id
) s,
LATERAL calculate_level_from_xp(s.new_total) lv
WHERE x.user_id = s.user_id;
