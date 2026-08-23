-- 2423_merch_claims_drop_orphaned_not_null.sql
-- Finding #443 (Level-gated rewards never unlock -- the physical-merch half).
--
-- Root cause: merch_claims still carries three NOT NULL columns from its
-- ORIGINAL (pre-1929) schema -- reward_type, shipping_name, shipping_address
-- (jsonb) -- with no DEFAULT and no BEFORE INSERT trigger to fill them.
-- distribute_level_rewards' level-up INSERT (migration 1935) only supplies
-- (user_id, merch_type, awarded_at_level, status):
--
--   INSERT INTO merch_claims (user_id, merch_type, awarded_at_level, status)
--   VALUES (p_user_id, v_merch_type, v_level, 'pending_address')
--   ON CONFLICT (user_id, awarded_at_level) DO NOTHING;
--
-- That INSERT violates reward_type/shipping_name/shipping_address's NOT NULL
-- constraints on every single execution, and neither distribute_level_rewards
-- nor its caller award_xp wraps the call in an EXCEPTION block -- the error
-- propagates and rolls back the ENTIRE award_xp transaction. So a merch
-- reward has never once been created for ANY account (verified: `merch_claims`
-- is empty in production -- 0 rows, `select count(*) from merch_claims`),
-- and the first real user to level up across 50/100/150/200/250 would have
-- that XP-earning API call fail outright, not just silently skip the merch
-- grant. This is a strictly bigger defect than "the reward doesn't unlock
-- retroactively" -- the reward doesn't unlock AT ALL, even freshly earned.
--
-- Confirmed orphaned (unused by any current code path): the live merch flow
-- reads/writes shipping_full_name, shipping_address_line1/2, shipping_city,
-- shipping_state, shipping_postal_code, shipping_country, shipping_phone,
-- sizes -- NOT shipping_name / shipping_address. `reward_type` on this table
-- is likewise never read (the app's `reward_type` string elsewhere is a key
-- in claim_daily_crate's RPC response JSON, an unrelated table). Table is
-- empty, so this is a pure constraint relaxation -- no data migration.
--
-- FIX: drop NOT NULL from the three orphaned columns so the existing,
-- otherwise-correct level-up INSERT (and the retroactive backfill added
-- alongside this migration in api/v1/xp_endpoints.py, mirroring the
-- existing cosmetics retroactive-grant) can actually succeed.

ALTER TABLE merch_claims ALTER COLUMN reward_type DROP NOT NULL;
ALTER TABLE merch_claims ALTER COLUMN shipping_name DROP NOT NULL;
ALTER TABLE merch_claims ALTER COLUMN shipping_address DROP NOT NULL;

-- VERIFY: insert into merch_claims (user_id, merch_type, awarded_at_level, status) select id, 'sticker_pack', 50, 'pending_address' from users limit 1 returning id; -- should succeed (no not-null violation); then delete that test row.
