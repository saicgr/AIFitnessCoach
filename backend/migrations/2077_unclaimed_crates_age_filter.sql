-- 2077_unclaimed_crates_age_filter.sql
-- ---------------------------------------------------------------------------
-- Bug: "Failed to open crates" on the home-screen "Open All" flow.
--
-- get_unclaimed_crates() returned the 9 most-recent unclaimed crates with NO
-- age limit, but the /xp/claim-daily-crate HTTP handler rejects any crate
-- older than 9 DAYS. So the app would offer an expired crate (e.g. a 12-day-
-- old one), the user taps "Open All", that one claim 400s, and the whole
-- batch fails.
--
-- Fix: the RPC's "9" was a row LIMIT, not an age window. Add an age filter so
-- the RPC only ever returns crates the handler will actually accept — i.e.
-- claimed within 9 days of the user's local date. The handler keeps its own
-- 9-day check as defense-in-depth (and now returns a graceful result instead
-- of a hard 400 — see api/v1/xp_endpoints.py).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_unclaimed_crates(p_user_id uuid, p_user_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'crate_date', sub.crate_date,
        'daily_crate_available', sub.daily_crate_available,
        'streak_crate_available', sub.streak_crate_available,
        'activity_crate_available', sub.activity_crate_available
      ) ORDER BY sub.crate_date
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT crate_date, daily_crate_available, streak_crate_available, activity_crate_available
    FROM user_daily_crates
    WHERE user_id = p_user_id
      AND selected_crate IS NULL
      AND crate_date <= p_user_date
      -- Only offer crates the claim handler will accept: within 9 days of the
      -- user's local date. Matches the (today - crate_date).days > 9 reject
      -- rule in claim_daily_crate's HTTP handler.
      AND crate_date >= p_user_date - INTERVAL '9 days'
    ORDER BY crate_date DESC
    LIMIT 9
  ) sub;
$function$;
