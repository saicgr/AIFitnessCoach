-- ============================================================================
-- Migration 2080: Nutrient Rush mini-game — persisted personal best + leaderboard
-- ============================================================================
--
-- Adds a per-user persisted high score for the "Nutrient Rush" celebration
-- mini-game and wires it into the EXISTING leaderboard system (the
-- `LeaderboardType` board family powering the Social → Leaderboard tab:
-- challenge_masters / volume_kings / streaks / weekly_challenges).
--
-- New board id: `nutrient_rush`.
--
-- Design notes:
--  * `minigame_scores` is keyed (user_id, game_key) so future mini-games reuse
--    the same table without a schema change.
--  * `leaderboard_minigame` is a REGULAR view (NOT materialized) — a high score
--    must reflect on the board immediately after a game-over submit; there is
--    no hourly REFRESH step for it (unlike the workout-derived matviews).
--  * Score 0 is intentionally NOT stored as a leaderboard entry: the view
--    filters `high_score > 0`, so a user who has only ever scored 0 simply
--    does not appear on the board.
-- ============================================================================

-- ── Table: per-user mini-game high scores ──────────────────────────────────
CREATE TABLE IF NOT EXISTS minigame_scores (
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_key    TEXT NOT NULL DEFAULT 'nutrient_rush',
    high_score  INTEGER NOT NULL DEFAULT 0 CHECK (high_score >= 0),
    plays       INTEGER NOT NULL DEFAULT 0 CHECK (plays >= 0),
    best_at     TIMESTAMPTZ,                      -- when the current best was set
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, game_key)
);

CREATE INDEX IF NOT EXISTS idx_minigame_scores_board
    ON minigame_scores (game_key, high_score DESC);

COMMENT ON TABLE minigame_scores IS
    'Per-user persisted high score for celebration mini-games. (user_id, game_key) keyed; game_key=nutrient_rush is the only game today.';

-- ── View: Nutrient Rush leaderboard ────────────────────────────────────────
-- Regular view (instant freshness). Shape mirrors the other leaderboard_*
-- objects (user_id / user_name / avatar_url / country_code + a metric) so the
-- existing LeaderboardService.get_leaderboard_entries() can query it directly.
CREATE OR REPLACE VIEW leaderboard_minigame AS
SELECT
    u.id            AS user_id,
    u.name          AS user_name,
    u.avatar_url,
    u.country_code,
    ms.high_score   AS minigame_high_score,
    ms.plays        AS minigame_plays,
    ms.best_at      AS last_workout_date,   -- reuse generic "last activity" slot
    ms.updated_at   AS last_updated
FROM minigame_scores ms
JOIN users u ON u.id = ms.user_id
WHERE ms.game_key = 'nutrient_rush'
  AND ms.high_score > 0;          -- score-0-only users are not ranked

COMMENT ON VIEW leaderboard_minigame IS
    'Leaderboard: Nutrient Rush mini-game best score (board id = nutrient_rush).';

-- ── RPC: submit a mini-game score (last-best-wins, server-side anti-cheat) ──
-- Upsert that only raises the stored best. Always increments `plays`.
-- p_score is sanity-bounded by the API layer; this function additionally
-- clamps defensively (negative -> rejected by CHECK; absurd -> capped is the
-- API's job, the function trusts the already-validated value).
CREATE OR REPLACE FUNCTION submit_minigame_score(
    p_user_id   UUID,
    p_game_key  TEXT,
    p_score     INTEGER
)
RETURNS TABLE(high_score INTEGER, plays INTEGER, is_new_best BOOLEAN)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_prev_best INTEGER;
BEGIN
    IF p_score < 0 THEN
        RAISE EXCEPTION 'score must be non-negative';
    END IF;

    SELECT ms.high_score INTO v_prev_best
    FROM minigame_scores ms
    WHERE ms.user_id = p_user_id AND ms.game_key = p_game_key;

    INSERT INTO minigame_scores AS ms (user_id, game_key, high_score, plays, best_at, updated_at)
    VALUES (
        p_user_id, p_game_key, p_score, 1,
        CASE WHEN p_score > 0 THEN NOW() ELSE NULL END,
        NOW()
    )
    ON CONFLICT (user_id, game_key) DO UPDATE SET
        high_score = GREATEST(ms.high_score, EXCLUDED.high_score),
        plays      = ms.plays + 1,
        best_at    = CASE
                        WHEN EXCLUDED.high_score > ms.high_score THEN NOW()
                        ELSE ms.best_at
                     END,
        updated_at = NOW();

    RETURN QUERY
    SELECT ms.high_score, ms.plays,
           (v_prev_best IS NULL OR p_score > v_prev_best) AS is_new_best
    FROM minigame_scores ms
    WHERE ms.user_id = p_user_id AND ms.game_key = p_game_key;
END;
$$;

COMMENT ON FUNCTION submit_minigame_score IS
    'Upsert a mini-game score: raises the stored best only, always +1 plays. Returns the post-update best.';

-- ── Extend get_user_leaderboard_rank with the `nutrient_rush` branch ───────
-- CREATE OR REPLACE on the live 3-arg signature (the one the API calls).
CREATE OR REPLACE FUNCTION get_user_leaderboard_rank(
    p_user_id UUID,
    p_leaderboard_type VARCHAR DEFAULT 'challenge_masters',
    p_country_filter VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    rank BIGINT,
    total_users BIGINT,
    percentile DECIMAL
)
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    user_rank BIGINT;
    total_count BIGINT;
BEGIN
    IF p_leaderboard_type = 'challenge_masters' THEN
        WITH ranked_users AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (ORDER BY first_wins DESC, win_rate DESC, last_updated ASC) AS row_rank
            FROM leaderboard_challenge_masters
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT ru.row_rank, COUNT(*) OVER () INTO user_rank, total_count
        FROM ranked_users ru WHERE ru.user_id = p_user_id;

    ELSIF p_leaderboard_type = 'volume_kings' THEN
        WITH ranked_users AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (ORDER BY total_volume_lbs DESC) AS row_rank
            FROM leaderboard_volume_kings
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT ru.row_rank, COUNT(*) OVER () INTO user_rank, total_count
        FROM ranked_users ru WHERE ru.user_id = p_user_id;

    ELSIF p_leaderboard_type = 'streaks' THEN
        WITH ranked_users AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (ORDER BY best_streak DESC, current_streak DESC) AS row_rank
            FROM leaderboard_streaks
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT ru.row_rank, COUNT(*) OVER () INTO user_rank, total_count
        FROM ranked_users ru WHERE ru.user_id = p_user_id;

    ELSIF p_leaderboard_type = 'weekly_challenges' THEN
        WITH ranked_users AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (ORDER BY weekly_wins DESC, weekly_win_rate DESC) AS row_rank
            FROM leaderboard_weekly_challenges
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT ru.row_rank, COUNT(*) OVER () INTO user_rank, total_count
        FROM ranked_users ru WHERE ru.user_id = p_user_id;

    ELSIF p_leaderboard_type = 'nutrient_rush' THEN
        WITH ranked_users AS (
            SELECT user_id,
                   ROW_NUMBER() OVER (ORDER BY minigame_high_score DESC, last_updated ASC) AS row_rank
            FROM leaderboard_minigame
            WHERE (p_country_filter IS NULL OR country_code = p_country_filter)
        )
        SELECT ru.row_rank, COUNT(*) OVER () INTO user_rank, total_count
        FROM ranked_users ru WHERE ru.user_id = p_user_id;
    END IF;

    RETURN QUERY SELECT
        COALESCE(user_rank, 0) AS rank,
        COALESCE(total_count, 0) AS total_users,
        CASE
            WHEN total_count > 0 THEN ROUND((user_rank::DECIMAL / total_count * 100), 1)
            ELSE 0
        END AS percentile;
END;
$$;

COMMENT ON FUNCTION get_user_leaderboard_rank(UUID, VARCHAR, VARCHAR) IS
    'Get user rank in specified leaderboard (incl. nutrient_rush mini-game board) with optional country filter';
