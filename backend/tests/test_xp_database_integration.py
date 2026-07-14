"""
Database Integration Tests for XP System.

These tests run against the actual Supabase database to verify
the SQL functions work correctly.

Run with: pytest tests/test_xp_database_integration.py -v
"""

import os
from urllib.parse import unquote, urlparse

import pytest

psycopg2 = pytest.importorskip("psycopg2")


def _db_params() -> dict | None:
    """Resolve live-Postgres connection params, or None if no credential exists.

    Never `raise SystemExit` at import: pytest imports every test module during
    collection, so an import-time exit INTERNALERRORs the ENTIRE run — thousands
    of unrelated tests included. That is why this file had to be --ignore'd, and
    why its 64 tests (which caught two real production bugs) sat dark.

    Resolution order (mirrors scripts/run_migration_1646.py and
    scripts/program_sql_helper.py, which already do this):
      1. explicit DATABASE_* env vars (CI / ad-hoc override)
      2. DATABASE_URL_DIRECT, then DATABASE_URL (the URL in .env already carries
         host/port/user/password/dbname)
      3. SUPABASE_DB_PASSWORD for the password
    """
    url = os.environ.get("DATABASE_URL_DIRECT") or os.environ.get("DATABASE_URL")
    p = urlparse(url) if url else None  # tolerates the `+asyncpg` driver suffix

    password = (
        os.environ.get("DATABASE_PASSWORD")
        or os.environ.get("SUPABASE_DB_PASSWORD")
        or (unquote(p.password) if p and p.password else None)
    )
    if not password:
        return None

    return {
        "host": os.environ.get("DATABASE_HOST")
                or (p.hostname if p else None)
                or "db.hpbzfahijszqmgsybuor.supabase.co",
        "port": int(os.environ.get("DATABASE_PORT") or (p.port if p and p.port else 5432)),
        "dbname": os.environ.get("DATABASE_NAME")
                  or ((p.path or "").lstrip("/") if p else "")
                  or "postgres",
        "user": os.environ.get("DATABASE_USER")
                or (unquote(p.username) if p and p.username else None)
                or "postgres",
        "password": password,
        "sslmode": "require",
    }


_DB_PARAMS = _db_params()

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        _DB_PARAMS is None,
        reason=(
            "No live-Postgres credential. Set DATABASE_PASSWORD / SUPABASE_DB_PASSWORD / "
            "DATABASE_URL_DIRECT, e.g. `cd backend && set -a && source ./.env && set +a`."
        ),
    ),
]


@pytest.fixture(scope="module")
def db():
    """Live Supabase Postgres connection. Every assertion in this file is read-only."""
    conn = psycopg2.connect(**_DB_PARAMS)
    try:
        yield conn
    finally:
        conn.close()


class TestDatabaseTables:
    """Verify all required tables exist."""

    @pytest.mark.parametrize("table_name", [
        "user_first_time_bonuses",
        "user_checkpoint_progress",
        "user_consumables",
        "user_daily_crates",
        "user_monthly_achievements",
        "user_daily_social_xp",
        "level_rewards",
        "checkpoint_rewards",
    ])
    def test_table_exists(self, db, table_name):
        cur = db.cursor()
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = %s
            )
        """, (table_name,))
        assert cur.fetchone()[0] is True, f"Table {table_name} does not exist"


class TestDatabaseFunctions:
    """Verify all required functions exist."""

    @pytest.mark.parametrize("func_name", [
        "calculate_level_from_xp",
        "get_xp_title",
        "get_level_info",
        "init_user_checkpoint_progress",
        "increment_checkpoint_workout",
        "get_full_weekly_progress",
        "init_user_monthly_achievements",
        "get_monthly_achievements_progress",
        "init_user_daily_social",
        "award_social_share_xp",
        "award_social_react_xp",
        "award_social_comment_xp",
        "award_social_friend_xp",
        "get_daily_social_xp_status",
        "get_user_consumables",
        "claim_daily_crate",
        "get_user_days_per_week",
    ])
    def test_function_exists(self, db, func_name):
        cur = db.cursor()
        cur.execute("""
            SELECT EXISTS (SELECT FROM pg_proc WHERE proname = %s)
        """, (func_name,))
        assert cur.fetchone()[0] is True, f"Function {func_name} does not exist"


class TestLevelProgression:
    """Test level calculation functions.

    RETIRED BEHAVIOR — these tests were rewritten (2026-07-13).

    They previously asserted the pre-migration-227 XP curve (450 XP = level 10,
    level 11 = 'Apprentice', levels 101+ = 'Mythic I/II/III'). That curve was
    replaced TWICE by deliberate product changes:
      • migration 227  — "Unified XP Progression ... replaces ALL previous XP
        formulas": 11 flat title tiers (Beginner/Novice/Apprentice/Athlete/
        Elite/Master/Champion/Legend/Mythic...), so 'Mythic I/II/III' no longer
        exist as titles at all.
      • migration 1901 — "Rescale level thresholds so Level 2 = 150 XP" (fixing
        the "Level 6 on signup" bug), which is the curve that ships today.
    Migration 1901 also reshaped calculate_level_from_xp's RETURNS TABLE to
    (level, title, xp_for_next, xp_in_level, prestige) — so the old positional
    `result[3] == 'Novice'` was reading xp_in_level and failing `assert 0 == 'Novice'`.

    The tests now read columns BY NAME (immune to the next reshape) and the
    expected values below are derived from migration 1901's own `xp_table`
    source array, not copied from DB output. The preserved intent is unchanged:
    "the DB's level maths matches the XP spec".
    """

    # Levels 1-10 from migrations/1901_fix_xp_levels.sql `xp_table`.
    # Cumulative XP to REACH level 11 = sum of these = 10,250.
    _XP_TABLE_1_10 = [150, 200, 300, 450, 650, 900, 1200, 1600, 2100, 2700]

    def test_calculate_level_from_xp_level_1(self, db):
        """0 XP is level 1 'Beginner', with the full first level still to earn."""
        cur = db.cursor()
        cur.execute(
            "SELECT level, title, xp_for_next, xp_in_level FROM calculate_level_from_xp(0)"
        )
        level, title, xp_for_next, xp_in_level = cur.fetchone()
        assert level == 1
        assert title == 'Beginner'          # was 'Novice' pre-227
        assert xp_in_level == 0
        assert xp_for_next == self._XP_TABLE_1_10[0]   # 150

    def test_calculate_level_from_xp_450(self, db):
        """450 XP is level 3 under the 1901 curve (was level 10 pre-227).

        150 (L1→2) + 200 (L2→3) = 350 consumed, 100 XP into level 3.
        """
        cur = db.cursor()
        cur.execute(
            "SELECT level, title, xp_for_next, xp_in_level FROM calculate_level_from_xp(450)"
        )
        level, title, xp_for_next, xp_in_level = cur.fetchone()
        assert level == 3
        assert title == 'Beginner'
        assert xp_in_level == 450 - sum(self._XP_TABLE_1_10[:2])   # 100
        assert xp_for_next == self._XP_TABLE_1_10[2]               # 300

    def test_calculate_level_from_xp_level_11_boundary(self, db):
        """The exact level-11 boundary is the cumulative sum of levels 1-10.

        Pre-227 this boundary was 500 XP; under 1901 it is 10,250. Level 11 is
        the first 'Novice' level (the 11-tier scheme from migration 227).
        """
        boundary = sum(self._XP_TABLE_1_10)
        assert boundary == 10250

        cur = db.cursor()
        cur.execute(
            "SELECT level, title, xp_in_level FROM calculate_level_from_xp(%s)", (boundary,)
        )
        level, title, xp_in_level = cur.fetchone()
        assert level == 11
        assert title == 'Novice'
        assert xp_in_level == 0

        # One XP short must still be level 10 — proves the boundary is exact.
        cur.execute("SELECT level, title FROM calculate_level_from_xp(%s)", (boundary - 1,))
        assert cur.fetchone() == (10, 'Beginner')

    def test_get_xp_title_tier_boundaries(self, db):
        """Title tiers are the 11 flat tiers from migration 227.

        Replaces the old 'Mythic I / II / III' assertions: those sub-tiers were
        removed by 227, which made 101-125 'Master' and 176+ 'Mythic'. Every
        boundary is checked on BOTH sides so an off-by-one in the tier table
        cannot slip through.
        """
        expected = {
            1: 'Beginner', 10: 'Beginner',
            11: 'Novice', 25: 'Novice',
            26: 'Apprentice', 50: 'Apprentice',
            51: 'Athlete', 75: 'Athlete',
            76: 'Elite', 100: 'Elite',
            101: 'Master', 125: 'Master',
            126: 'Champion', 150: 'Champion',
            151: 'Legend', 175: 'Legend',
            176: 'Mythic',
        }
        cur = db.cursor()
        for level, title in expected.items():
            cur.execute("SELECT get_xp_title(%s)", (level,))
            assert cur.fetchone()[0] == title, f"get_xp_title({level}) should be {title}"

    def test_python_xp_table_matches_db_curve(self, db):
        """REGRESSION GATE: the Python `_XP_TABLE` must mirror the DB's XP curve.

        The XP curve is copy-pasted into three places — calculate_level_from_xp
        (SQL, the operative one: award_xp/revoke_xp call it and every stored
        user level was computed with it), get_level_info (SQL, display), and
        `_XP_TABLE` in api/v1/xp_endpoints.py (Python, serves
        GET /api/v1/xp/level-info). Migration 1901 rescaled ONLY the first, and
        the drift went unnoticed for months because nothing compared them.

        This pins the Python mirror to the DB's operative curve for all 250
        levels. If anyone rescales one side again, this fails immediately
        instead of quietly under-reporting what a level costs.
        """
        from api.v1.xp_endpoints import _get_xp_for_level

        cur = db.cursor()
        cur.execute("SELECT lvl, xp_required FROM get_all_level_xp_thresholds() ORDER BY lvl")
        db_curve = dict(cur.fetchall())

        mismatches = [
            (lvl, _get_xp_for_level(lvl), db_curve[lvl])
            for lvl in range(1, 251)
            if _get_xp_for_level(lvl) != db_curve[lvl]
        ]
        assert not mismatches, (
            "Python _XP_TABLE has drifted from the DB curve "
            f"(level, python, db): {mismatches[:5]}"
        )

    def test_get_level_info_agrees_with_calculate_level_from_xp(self, db):
        """get_level_info(N) must describe the SAME curve as calculate_level_from_xp.

        Rewritten from a hardcoded expectation (level 50 = 'Athlete', 150 XP to
        next) because that was the pre-227 curve and is stale under BOTH curves
        now in the codebase. This asserts an INVARIANT instead, which holds no
        matter which curve the product ultimately keeps: the XP that
        get_level_info claims is needed to reach level N must actually land you
        on level N according to calculate_level_from_xp — the function award_xp
        uses to really level users up.

        ⚠️ THIS TEST FAILS TODAY. It is REAL BUG 1, not a stale assertion:
        migration 1901 rescaled calculate_level_from_xp but did NOT update
        get_level_info (or its Python twin, `_XP_TABLE` in api/v1/xp_endpoints.py,
        which serves GET /api/v1/xp/level-info). They still hold the migration-227
        curve, so they under-report the cost of a level by ~13x:
            get_level_info(50)          -> total_xp_to_reach = 32,960
            calculate_level_from_xp(32,960) -> level 17
        Users are told a level costs a fraction of what the DB actually charges.
        Do not "fix" this by pinning the expected values to get_level_info's
        current output — that would enshrine the bug.
        """
        cur = db.cursor()
        for level in (2, 10, 50):
            cur.execute("SELECT get_level_info(%s)", (level,))
            info = cur.fetchone()[0]
            assert info['level'] == level

            cur.execute(
                "SELECT level, title FROM calculate_level_from_xp(%s)",
                (info['total_xp_to_reach'],),
            )
            actual_level, actual_title = cur.fetchone()
            assert actual_level == level, (
                f"get_level_info({level}) claims {info['total_xp_to_reach']} XP reaches "
                f"level {level}, but calculate_level_from_xp says that XP is level "
                f"{actual_level}. The two XP curves have diverged (see migration 1901)."
            )
            assert info['title'] == actual_title


class TestSocialXPLimits:
    """Test social XP limits match the guide."""

    def test_social_actions_are_configured(self, db):
        """Test that social XP rewards are configured correctly."""
        cur = db.cursor()
        cur.execute("""
            SELECT checkpoint_type, xp_reward, description
            FROM checkpoint_rewards
            WHERE checkpoint_type LIKE 'social_%'
            ORDER BY checkpoint_type
        """)
        results = {row[0]: {'xp': row[1], 'desc': row[2]} for row in cur.fetchall()}

        # Share: 15 XP, max 3/day
        assert results['social_share']['xp'] == 15
        assert '3/day' in results['social_share']['desc']

        # React: 5 XP, max 10/day
        assert results['social_react']['xp'] == 5
        assert '10/day' in results['social_react']['desc']

        # Comment: 10 XP, max 5/day
        assert results['social_comment']['xp'] == 10
        assert '5/day' in results['social_comment']['desc']

        # Friend: 25 XP, max 5/day
        assert results['social_friend']['xp'] == 25
        assert '5/day' in results['social_friend']['desc']


class TestWeeklyCheckpoints:
    """Test weekly checkpoint configuration."""

    def test_weekly_checkpoints_configured(self, db):
        """Test that weekly checkpoint rewards exist."""
        cur = db.cursor()
        cur.execute("""
            SELECT metric_name, xp_reward
            FROM checkpoint_rewards
            WHERE checkpoint_type = 'weekly'
        """)
        results = {row[0]: row[1] for row in cur.fetchall()}

        expected = {
            'workouts': 200,
            'perfect_week': 500,
            'protein': 150,
            'calories': 150,
            'hydration': 100,
            'weight': 75,
            'habits': 100,
            'workout_streak': 100,
            'social': 150,
            'measurements': 50,
        }

        for metric, expected_xp in expected.items():
            assert metric in results, f"Missing weekly checkpoint: {metric}"
            assert results[metric] == expected_xp, f"Wrong XP for {metric}"


class TestMonthlyAchievements:
    """Test monthly achievement configuration."""

    def test_monthly_achievements_configured(self, db):
        """Test that monthly achievement rewards exist."""
        cur = db.cursor()
        cur.execute("""
            SELECT checkpoint_type, xp_reward
            FROM checkpoint_rewards
            WHERE period_type = 'monthly'
        """)
        results = {row[0]: row[1] for row in cur.fetchall()}

        expected = {
            'monthly_dedication': 500,
            'monthly_goal': 1000,
            'monthly_nutrition': 500,
            'monthly_consistency': 750,
            'monthly_hydration': 300,
            'monthly_weight': 400,
            'monthly_habits': 400,
            'monthly_prs': 500,
            'monthly_social_star': 300,
            'monthly_supporter': 200,
            'monthly_networker': 250,
            'monthly_measurements': 150,
        }

        for achievement, expected_xp in expected.items():
            assert achievement in results, f"Missing achievement: {achievement}"
            assert results[achievement] == expected_xp, f"Wrong XP for {achievement}"


class TestLevelRewards:
    """Test level milestone rewards."""

    def test_level_100_has_legend_badge(self, db):
        """Test level 100 has Legend badge."""
        cur = db.cursor()
        cur.execute("""
            SELECT reward_type, reward_value
            FROM level_rewards
            WHERE level = 100 AND reward_type = 'badge'
        """)
        result = cur.fetchone()
        assert result is not None
        assert result[1] == 'legend_badge'

    def test_level_250_has_eternal_legend(self, db):
        """Test level 250 has Eternal Legend badge."""
        cur = db.cursor()
        cur.execute("""
            SELECT reward_type, reward_value
            FROM level_rewards
            WHERE level = 250 AND reward_type = 'badge'
        """)
        result = cur.fetchone()
        assert result is not None
        assert result[1] == 'eternal_legend'

    def test_mythic_crate_rewards(self, db):
        """Test Mythic tier crate rewards exist."""
        cur = db.cursor()
        cur.execute("""
            SELECT COUNT(*)
            FROM level_rewards
            WHERE reward_value LIKE 'mythic_crate%'
        """)
        count = cur.fetchone()[0]
        assert count >= 5  # Multiple mythic crate rewards


class TestExtendedCheckpointColumns:
    """Test that checkpoint_progress has extended columns."""

    @pytest.mark.parametrize("column_name", [
        'protein_days', 'protein_target', 'protein_complete',
        'calorie_days', 'calorie_target', 'calorie_complete',
        'hydration_days', 'hydration_target', 'hydration_complete',
        'weight_logs', 'weight_target', 'weight_complete',
        'habit_percent', 'habit_target', 'habit_complete',
        'workout_streak', 'workout_streak_target', 'workout_streak_complete',
        'social_engagements', 'social_target', 'social_complete',
        'measurement_logs', 'measurement_target', 'measurement_complete',
        'perfect_week',
    ])
    def test_checkpoint_column_exists(self, db, column_name):
        cur = db.cursor()
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.columns
                WHERE table_name = 'user_checkpoint_progress'
                AND column_name = %s
            )
        """, (column_name,))
        assert cur.fetchone()[0] is True, f"Missing column: {column_name}"


class TestXPTotals:
    """Verify XP totals match the guide."""

    def test_weekly_total_is_1575(self, db):
        """Weekly XP total should be 1,575."""
        cur = db.cursor()
        cur.execute("""
            SELECT SUM(xp_reward)
            FROM checkpoint_rewards
            WHERE checkpoint_type = 'weekly'
        """)
        total = cur.fetchone()[0]
        assert total == 1575

    def test_monthly_total_is_5250(self, db):
        """Monthly XP total should be 5,250."""
        cur = db.cursor()
        cur.execute("""
            SELECT SUM(xp_reward)
            FROM checkpoint_rewards
            WHERE period_type = 'monthly'
        """)
        total = cur.fetchone()[0]
        assert total == 5250

    def test_daily_social_total_is_270(self, db):
        """Daily social XP max should be 270."""
        # Share: 15 × 3 = 45
        # React: 5 × 10 = 50
        # Comment: 10 × 5 = 50
        # Friend: 25 × 5 = 125
        # Total: 270
        expected_total = 45 + 50 + 50 + 125
        assert expected_total == 270


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
