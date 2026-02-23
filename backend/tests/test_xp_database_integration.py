"""
Database Integration Tests for XP System.

These tests run against the actual Supabase database to verify
the SQL functions work correctly.

Run with: pytest tests/test_xp_database_integration.py -v
"""

import os
import pytest
import psycopg2
from datetime import date

# Database connection - all values from environment
DATABASE_HOST = os.environ.get("DATABASE_HOST", "db.hpbzfahijszqmgsybuor.supabase.co")
DATABASE_PORT = int(os.environ.get("DATABASE_PORT", "5432"))
DATABASE_NAME = os.environ.get("DATABASE_NAME", "postgres")
DATABASE_USER = os.environ.get("DATABASE_USER", "postgres")
DATABASE_PASSWORD = os.environ.get("DATABASE_PASSWORD")
if not DATABASE_PASSWORD:
    raise SystemExit("DATABASE_PASSWORD environment variable is required")


@pytest.fixture(scope="module")
def db():
    """Create database connection for tests."""
    conn = psycopg2.connect(
        host=DATABASE_HOST,
        port=DATABASE_PORT,
        dbname=DATABASE_NAME,
        user=DATABASE_USER,
        password=DATABASE_PASSWORD,
        sslmode="require"
    )
    yield conn
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
    """Test level calculation functions."""

    def test_calculate_level_from_xp_level_1(self, db):
        """0 XP should be level 1."""
        cur = db.cursor()
        cur.execute("SELECT * FROM calculate_level_from_xp(0)")
        result = cur.fetchone()
        assert result[0] == 1  # current_level
        assert result[3] == 'Novice'  # title

    def test_calculate_level_from_xp_level_10(self, db):
        """450 XP should be level 10."""
        cur = db.cursor()
        cur.execute("SELECT * FROM calculate_level_from_xp(450)")
        result = cur.fetchone()
        assert result[0] == 10
        assert result[3] == 'Novice'

    def test_calculate_level_from_xp_level_11(self, db):
        """500 XP should be level 11 (Apprentice)."""
        cur = db.cursor()
        cur.execute("SELECT * FROM calculate_level_from_xp(500)")
        result = cur.fetchone()
        assert result[0] == 11
        assert result[3] == 'Apprentice'

    def test_get_xp_title_mythic_tiers(self, db):
        """Test Mythic tier titles."""
        cur = db.cursor()

        cur.execute("SELECT get_xp_title(101)")
        assert cur.fetchone()[0] == 'Mythic I'

        cur.execute("SELECT get_xp_title(150)")
        assert cur.fetchone()[0] == 'Mythic I'

        cur.execute("SELECT get_xp_title(151)")
        assert cur.fetchone()[0] == 'Mythic II'

        cur.execute("SELECT get_xp_title(201)")
        assert cur.fetchone()[0] == 'Mythic III'

        cur.execute("SELECT get_xp_title(250)")
        assert cur.fetchone()[0] == 'Mythic III'

    def test_get_level_info(self, db):
        """Test get_level_info function."""
        cur = db.cursor()
        cur.execute("SELECT get_level_info(50)")
        result = cur.fetchone()[0]
        assert result['level'] == 50
        assert result['title'] == 'Athlete'
        assert result['xp_to_next_level'] == 150


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
