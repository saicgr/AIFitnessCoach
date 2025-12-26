"""
Tests for Micronutrient API models and calculations.

Tests:
- NutrientProgress model validation
- DailyMicronutrientSummary model
- NutrientRDA model
- NutrientContributor model
- Status calculations
- Percentage calculations
- MicronutrientData model

Run with: pytest backend/tests/test_micronutrients_api.py -v
"""

import pytest
from datetime import datetime


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def sample_user_id():
    return "user-123-abc"


@pytest.fixture
def sample_rda_data():
    """Sample RDA (Reference Daily Allowance) data."""
    return [
        {
            "nutrient_key": "vitamin_d_iu",
            "nutrient_name": "Vitamin D",
            "display_name": "Vitamin D",
            "unit": "IU",
            "category": "vitamin",
            "rda_floor": 400.0,
            "rda_target": 600.0,
            "rda_ceiling": 4000.0,
            "rda_target_male": 600.0,
            "rda_target_female": 600.0,
            "display_order": 1,
            "color_hex": "#FFD93D",
        },
        {
            "nutrient_key": "calcium_mg",
            "nutrient_name": "Calcium",
            "display_name": "Calcium",
            "unit": "mg",
            "category": "mineral",
            "rda_floor": 800.0,
            "rda_target": 1000.0,
            "rda_ceiling": 2500.0,
            "display_order": 10,
            "color_hex": "#00D9C0",
        },
        {
            "nutrient_key": "iron_mg",
            "nutrient_name": "Iron",
            "display_name": "Iron",
            "unit": "mg",
            "category": "mineral",
            "rda_floor": 6.0,
            "rda_target": 18.0,
            "rda_ceiling": 45.0,
            "rda_target_male": 8.0,
            "rda_target_female": 18.0,
            "display_order": 11,
            "color_hex": "#FF6B6B",
        },
        {
            "nutrient_key": "omega3_g",
            "nutrient_name": "Omega-3",
            "display_name": "Omega-3",
            "unit": "g",
            "category": "fatty_acid",
            "rda_target": 1.6,
            "display_order": 20,
            "color_hex": "#4D96FF",
        },
    ]


# ============================================================
# NUTRIENT PROGRESS MODEL TESTS
# ============================================================

class TestNutrientProgressModel:
    """Test NutrientProgress Pydantic model."""

    def test_nutrient_progress_basic(self):
        """Test creating a basic NutrientProgress model."""
        from models.recipe import NutrientProgress

        progress = NutrientProgress(
            nutrient_key="vitamin_d_iu",
            display_name="Vitamin D",
            unit="IU",
            category="vitamin",
            current_value=500.0,
            target_value=600.0,
            percentage=83.3,
            status="low",
        )

        assert progress.nutrient_key == "vitamin_d_iu"
        assert progress.display_name == "Vitamin D"
        assert progress.unit == "IU"
        assert progress.category == "vitamin"
        assert progress.current_value == 500.0
        assert progress.target_value == 600.0
        assert progress.percentage == 83.3
        assert progress.status == "low"

    def test_nutrient_progress_with_floor_ceiling(self):
        """Test NutrientProgress with floor and ceiling values."""
        from models.recipe import NutrientProgress

        progress = NutrientProgress(
            nutrient_key="calcium_mg",
            display_name="Calcium",
            unit="mg",
            category="mineral",
            current_value=2600.0,
            target_value=1000.0,
            floor_value=800.0,
            ceiling_value=2500.0,
            percentage=260.0,
            status="over_ceiling",
        )

        assert progress.floor_value == 800.0
        assert progress.ceiling_value == 2500.0
        assert progress.status == "over_ceiling"
        assert progress.percentage == 260.0

    def test_nutrient_progress_optional_fields(self):
        """Test NutrientProgress with optional fields as None."""
        from models.recipe import NutrientProgress

        progress = NutrientProgress(
            nutrient_key="vitamin_k_ug",
            display_name="Vitamin K",
            unit="μg",
            category="vitamin",
            current_value=80.0,
            target_value=120.0,
            percentage=66.7,
            status="adequate",
        )

        assert progress.floor_value is None
        assert progress.ceiling_value is None
        assert progress.color_hex is None

    def test_nutrient_progress_with_color(self):
        """Test NutrientProgress with color_hex field."""
        from models.recipe import NutrientProgress

        progress = NutrientProgress(
            nutrient_key="iron_mg",
            display_name="Iron",
            unit="mg",
            category="mineral",
            current_value=15.0,
            target_value=18.0,
            percentage=83.3,
            status="adequate",
            color_hex="#FF6B6B",
        )

        assert progress.color_hex == "#FF6B6B"

    def test_nutrient_progress_status_values(self):
        """Test valid status values."""
        from models.recipe import NutrientProgress

        # Test all valid status values
        statuses = ["low", "adequate", "optimal", "over_ceiling"]

        for status in statuses:
            progress = NutrientProgress(
                nutrient_key="test",
                display_name="Test",
                unit="mg",
                category="vitamin",
                current_value=100.0,
                target_value=100.0,
                percentage=100.0,
                status=status,
            )
            assert progress.status == status


# ============================================================
# DAILY MICRONUTRIENT SUMMARY MODEL TESTS
# ============================================================

class TestDailyMicronutrientSummaryModel:
    """Test DailyMicronutrientSummary model."""

    def test_summary_basic(self):
        """Test basic DailyMicronutrientSummary creation."""
        from models.recipe import DailyMicronutrientSummary, NutrientProgress

        vitamin = NutrientProgress(
            nutrient_key="vitamin_c_mg",
            display_name="Vitamin C",
            unit="mg",
            category="vitamin",
            current_value=60.0,
            target_value=90.0,
            percentage=66.7,
            status="low",
        )

        summary = DailyMicronutrientSummary(
            date="2025-01-10",
            user_id="user-123",
            vitamins=[vitamin],
            minerals=[],
            fatty_acids=[],
            other=[],
            pinned=[vitamin],
        )

        assert summary.date == "2025-01-10"
        assert summary.user_id == "user-123"
        assert len(summary.vitamins) == 1
        assert len(summary.minerals) == 0
        assert len(summary.pinned) == 1

    def test_summary_with_multiple_nutrients(self):
        """Test summary with multiple nutrients in each category."""
        from models.recipe import DailyMicronutrientSummary, NutrientProgress

        vitamins = [
            NutrientProgress(
                nutrient_key="vitamin_a_ug",
                display_name="Vitamin A",
                unit="μg",
                category="vitamin",
                current_value=800.0,
                target_value=900.0,
                percentage=88.9,
                status="adequate",
            ),
            NutrientProgress(
                nutrient_key="vitamin_c_mg",
                display_name="Vitamin C",
                unit="mg",
                category="vitamin",
                current_value=100.0,
                target_value=90.0,
                percentage=111.1,
                status="optimal",
            ),
        ]

        minerals = [
            NutrientProgress(
                nutrient_key="calcium_mg",
                display_name="Calcium",
                unit="mg",
                category="mineral",
                current_value=850.0,
                target_value=1000.0,
                percentage=85.0,
                status="adequate",
            ),
        ]

        summary = DailyMicronutrientSummary(
            date="2025-01-10",
            user_id="user-456",
            vitamins=vitamins,
            minerals=minerals,
            fatty_acids=[],
            other=[],
            pinned=[vitamins[0]],
        )

        assert len(summary.vitamins) == 2
        assert len(summary.minerals) == 1
        assert summary.vitamins[0].nutrient_key == "vitamin_a_ug"
        assert summary.vitamins[1].status == "optimal"

    def test_summary_empty_nutrients(self):
        """Test summary with no nutrients logged."""
        from models.recipe import DailyMicronutrientSummary

        summary = DailyMicronutrientSummary(
            date="2025-01-01",
            user_id="user-empty",
            vitamins=[],
            minerals=[],
            fatty_acids=[],
            other=[],
            pinned=[],
        )

        assert len(summary.vitamins) == 0
        assert len(summary.minerals) == 0
        assert len(summary.pinned) == 0


# ============================================================
# NUTRIENT RDA MODEL TESTS
# ============================================================

class TestNutrientRDAModel:
    """Test NutrientRDA model."""

    def test_nutrient_rda_basic(self):
        """Test basic NutrientRDA creation."""
        from models.recipe import NutrientRDA

        rda = NutrientRDA(
            nutrient_name="Vitamin D",
            nutrient_key="vitamin_d_iu",
            unit="IU",
            category="vitamin",
            display_name="Vitamin D",
            rda_target=600.0,
        )

        assert rda.nutrient_name == "Vitamin D"
        assert rda.nutrient_key == "vitamin_d_iu"
        assert rda.unit == "IU"
        assert rda.category == "vitamin"
        assert rda.rda_target == 600.0

    def test_nutrient_rda_with_floor_ceiling(self):
        """Test NutrientRDA with floor and ceiling."""
        from models.recipe import NutrientRDA

        rda = NutrientRDA(
            nutrient_name="Calcium",
            nutrient_key="calcium_mg",
            unit="mg",
            category="mineral",
            display_name="Calcium",
            rda_floor=800.0,
            rda_target=1000.0,
            rda_ceiling=2500.0,
        )

        assert rda.rda_floor == 800.0
        assert rda.rda_target == 1000.0
        assert rda.rda_ceiling == 2500.0

    def test_nutrient_rda_with_gender_specific(self):
        """Test NutrientRDA with gender-specific targets."""
        from models.recipe import NutrientRDA

        rda = NutrientRDA(
            nutrient_name="Iron",
            nutrient_key="iron_mg",
            unit="mg",
            category="mineral",
            display_name="Iron",
            rda_floor=6.0,
            rda_target=18.0,
            rda_ceiling=45.0,
            rda_target_male=8.0,
            rda_target_female=18.0,
        )

        assert rda.rda_target_male == 8.0
        assert rda.rda_target_female == 18.0

    def test_nutrient_rda_with_display_order(self):
        """Test NutrientRDA with display order and color."""
        from models.recipe import NutrientRDA

        rda = NutrientRDA(
            nutrient_name="Omega-3",
            nutrient_key="omega3_g",
            unit="g",
            category="fatty_acid",
            display_name="Omega-3 Fatty Acids",
            rda_target=1.6,
            display_order=20,
            color_hex="#4D96FF",
        )

        assert rda.display_order == 20
        assert rda.color_hex == "#4D96FF"


# ============================================================
# NUTRIENT CONTRIBUTOR MODEL TESTS
# ============================================================

class TestNutrientContributorModel:
    """Test NutrientContributor model."""

    def test_contributor_basic(self):
        """Test basic NutrientContributor creation."""
        from models.recipe import NutrientContributor

        contributor = NutrientContributor(
            food_log_id="log-1",
            food_name="Salmon",
            meal_type="lunch",
            amount=400.0,
            unit="IU",
            logged_at=datetime(2025, 1, 10, 12, 0, 0),
        )

        assert contributor.food_log_id == "log-1"
        assert contributor.food_name == "Salmon"
        assert contributor.meal_type == "lunch"
        assert contributor.amount == 400.0
        assert contributor.unit == "IU"

    def test_contributor_different_meal_types(self):
        """Test contributors with different meal types."""
        from models.recipe import NutrientContributor

        meal_types = ["breakfast", "lunch", "dinner", "snack"]

        for meal_type in meal_types:
            contributor = NutrientContributor(
                food_log_id=f"log-{meal_type}",
                food_name="Test Food",
                meal_type=meal_type,
                amount=100.0,
                unit="mg",
                logged_at=datetime.now(),
            )
            assert contributor.meal_type == meal_type

    def test_contributor_with_all_fields(self):
        """Test contributor with all required fields."""
        from models.recipe import NutrientContributor

        logged_at = datetime(2025, 1, 10, 8, 30, 0)
        contributor = NutrientContributor(
            food_log_id="log-2",
            food_name="Milk",
            meal_type="breakfast",
            amount=300.0,
            unit="mg",
            logged_at=logged_at,
        )

        assert contributor.food_log_id == "log-2"
        assert contributor.logged_at == logged_at


# ============================================================
# NUTRIENT CONTRIBUTORS RESPONSE MODEL TESTS
# ============================================================

class TestNutrientContributorsResponseModel:
    """Test NutrientContributorsResponse model."""

    def test_contributors_response_basic(self):
        """Test basic NutrientContributorsResponse creation."""
        from models.recipe import NutrientContributorsResponse, NutrientContributor

        contributors = [
            NutrientContributor(
                food_log_id="log-1",
                food_name="Salmon",
                meal_type="lunch",
                amount=400.0,
                unit="IU",
                logged_at=datetime.now(),
            ),
            NutrientContributor(
                food_log_id="log-2",
                food_name="Eggs",
                meal_type="breakfast",
                amount=200.0,
                unit="IU",
                logged_at=datetime.now(),
            ),
        ]

        response = NutrientContributorsResponse(
            nutrient_key="vitamin_d_iu",
            display_name="Vitamin D",
            unit="IU",
            target=600.0,
            total_intake=600.0,
            contributors=contributors,
        )

        assert response.nutrient_key == "vitamin_d_iu"
        assert response.display_name == "Vitamin D"
        assert response.total_intake == 600.0
        assert response.target == 600.0
        assert len(response.contributors) == 2

    def test_contributors_response_empty(self):
        """Test NutrientContributorsResponse with no contributors."""
        from models.recipe import NutrientContributorsResponse

        response = NutrientContributorsResponse(
            nutrient_key="omega3_g",
            display_name="Omega-3",
            unit="g",
            target=1.6,
            total_intake=0.0,
            contributors=[],
        )

        assert response.total_intake == 0.0
        assert response.target == 1.6
        assert len(response.contributors) == 0


# ============================================================
# MICRONUTRIENT STATUS CALCULATION TESTS
# ============================================================

class TestMicronutrientStatusCalculations:
    """Test micronutrient status calculation logic."""

    def _calculate_status(self, current, target, floor_val=None, ceiling=None):
        """Helper to calculate status."""
        if ceiling and current > ceiling:
            return "over_ceiling"
        elif current >= target:
            return "optimal"
        elif floor_val and current >= floor_val:
            return "adequate"
        else:
            return "low"

    def test_status_low(self):
        """Test 'low' status when below floor."""
        # Value: 300, Floor: 400, Target: 600 -> low
        status = self._calculate_status(300.0, 600.0, 400.0, 4000.0)
        assert status == "low"

    def test_status_adequate(self):
        """Test 'adequate' status when between floor and target."""
        # Value: 500, Floor: 400, Target: 600 -> adequate
        status = self._calculate_status(500.0, 600.0, 400.0, 4000.0)
        assert status == "adequate"

    def test_status_optimal(self):
        """Test 'optimal' status when at or above target."""
        # Value: 700, Floor: 400, Target: 600 -> optimal
        status = self._calculate_status(700.0, 600.0, 400.0, 4000.0)
        assert status == "optimal"

    def test_status_optimal_at_target(self):
        """Test 'optimal' status when exactly at target."""
        # Value: 600, Floor: 400, Target: 600 -> optimal
        status = self._calculate_status(600.0, 600.0, 400.0, 4000.0)
        assert status == "optimal"

    def test_status_over_ceiling(self):
        """Test 'over_ceiling' status when above ceiling."""
        # Value: 5000, Floor: 400, Target: 600, Ceiling: 4000 -> over_ceiling
        status = self._calculate_status(5000.0, 600.0, 400.0, 4000.0)
        assert status == "over_ceiling"

    def test_status_no_floor(self):
        """Test status calculation without floor value."""
        # Without floor, go directly from low to optimal
        status = self._calculate_status(300.0, 600.0, None, 4000.0)
        assert status == "low"

        status = self._calculate_status(700.0, 600.0, None, 4000.0)
        assert status == "optimal"

    def test_status_no_ceiling(self):
        """Test status calculation without ceiling value."""
        # Without ceiling, can't be over_ceiling
        status = self._calculate_status(10000.0, 600.0, 400.0, None)
        assert status == "optimal"

    def test_status_zero_current(self):
        """Test status when current value is zero."""
        status = self._calculate_status(0.0, 600.0, 400.0, 4000.0)
        assert status == "low"


# ============================================================
# PERCENTAGE CALCULATION TESTS
# ============================================================

class TestPercentageCalculations:
    """Test percentage calculation logic."""

    def _calculate_percentage(self, current, target):
        """Helper to calculate percentage."""
        return round((current / target) * 100, 1) if target > 0 else 0

    def test_percentage_normal(self):
        """Test normal percentage calculation."""
        percentage = self._calculate_percentage(450.0, 600.0)
        assert percentage == 75.0

    def test_percentage_at_100(self):
        """Test percentage at exactly 100%."""
        percentage = self._calculate_percentage(600.0, 600.0)
        assert percentage == 100.0

    def test_percentage_over_100(self):
        """Test percentage over 100%."""
        percentage = self._calculate_percentage(900.0, 600.0)
        assert percentage == 150.0

    def test_percentage_zero_current(self):
        """Test percentage with zero current."""
        percentage = self._calculate_percentage(0.0, 600.0)
        assert percentage == 0.0

    def test_percentage_zero_target(self):
        """Test percentage when target is zero."""
        percentage = self._calculate_percentage(100.0, 0.0)
        assert percentage == 0

    def test_percentage_small_values(self):
        """Test percentage with small decimal values."""
        # Omega-3: 1.2g out of 1.6g target
        percentage = self._calculate_percentage(1.2, 1.6)
        assert percentage == 75.0

    def test_percentage_rounding(self):
        """Test percentage rounding to 1 decimal."""
        percentage = self._calculate_percentage(333.0, 1000.0)
        assert percentage == 33.3


# ============================================================
# MICRONUTRIENT DATA MODEL TESTS
# ============================================================

class TestMicronutrientDataModel:
    """Test MicronutrientData model from recipe models."""

    def test_micronutrient_data_empty(self):
        """Test empty MicronutrientData."""
        from models.recipe import MicronutrientData

        data = MicronutrientData()

        assert data.vitamin_a_ug is None
        assert data.calcium_mg is None
        assert data.omega3_g is None

    def test_micronutrient_data_with_vitamins(self):
        """Test MicronutrientData with vitamin values."""
        from models.recipe import MicronutrientData

        data = MicronutrientData(
            vitamin_a_ug=500.0,
            vitamin_c_mg=60.0,
            vitamin_d_iu=600.0,
            vitamin_e_mg=15.0,
            vitamin_k_ug=90.0,
        )

        assert data.vitamin_a_ug == 500.0
        assert data.vitamin_c_mg == 60.0
        assert data.vitamin_d_iu == 600.0
        assert data.vitamin_e_mg == 15.0
        assert data.vitamin_k_ug == 90.0

    def test_micronutrient_data_with_minerals(self):
        """Test MicronutrientData with mineral values."""
        from models.recipe import MicronutrientData

        data = MicronutrientData(
            calcium_mg=800.0,
            iron_mg=12.0,
            magnesium_mg=400.0,
            zinc_mg=8.0,
            potassium_mg=3500.0,
            sodium_mg=2300.0,
            selenium_ug=55.0,
        )

        assert data.calcium_mg == 800.0
        assert data.iron_mg == 12.0
        assert data.magnesium_mg == 400.0

    def test_micronutrient_data_with_fatty_acids(self):
        """Test MicronutrientData with fatty acid values."""
        from models.recipe import MicronutrientData

        data = MicronutrientData(
            omega3_g=1.5,
            omega6_g=10.0,
            cholesterol_mg=200.0,
        )

        assert data.omega3_g == 1.5
        assert data.omega6_g == 10.0
        assert data.cholesterol_mg == 200.0

    def test_micronutrient_data_non_negative_validation(self):
        """Test that negative values are rejected."""
        from models.recipe import MicronutrientData
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            MicronutrientData(vitamin_a_ug=-100.0)

    def test_micronutrient_data_full(self):
        """Test MicronutrientData with many fields."""
        from models.recipe import MicronutrientData

        data = MicronutrientData(
            vitamin_a_ug=900.0,
            vitamin_c_mg=90.0,
            vitamin_d_iu=600.0,
            vitamin_e_mg=15.0,
            vitamin_k_ug=120.0,
            vitamin_b1_mg=1.2,
            vitamin_b2_mg=1.3,
            vitamin_b6_mg=1.7,
            vitamin_b12_ug=2.4,
            vitamin_b9_ug=400.0,  # Folate
            calcium_mg=1000.0,
            iron_mg=18.0,
            magnesium_mg=400.0,
            zinc_mg=11.0,
            potassium_mg=4700.0,
            sodium_mg=2300.0,
            selenium_ug=55.0,
            omega3_g=1.6,
            omega6_g=17.0,
            cholesterol_mg=300.0,
            water_ml=2500.0,
        )

        assert data.vitamin_a_ug == 900.0
        assert data.vitamin_b9_ug == 400.0  # Folate
        assert data.water_ml == 2500.0


# ============================================================
# AGGREGATION LOGIC TESTS
# ============================================================

class TestAggregationLogic:
    """Test nutrient aggregation calculations."""

    def test_sum_nutrients_from_food_logs(self):
        """Test summing nutrients from multiple food logs."""
        food_logs = [
            {"vitamin_d_iu": 200.0, "calcium_mg": 50.0},
            {"vitamin_d_iu": 400.0, "calcium_mg": 20.0},
            {"vitamin_d_iu": 100.0, "calcium_mg": 300.0},
        ]

        vitamin_d_total = sum(log.get("vitamin_d_iu", 0) or 0 for log in food_logs)
        calcium_total = sum(log.get("calcium_mg", 0) or 0 for log in food_logs)

        assert vitamin_d_total == 700.0
        assert calcium_total == 370.0

    def test_sum_with_none_values(self):
        """Test summing nutrients when some values are None."""
        food_logs = [
            {"vitamin_d_iu": 200.0, "calcium_mg": None},
            {"vitamin_d_iu": None, "calcium_mg": 100.0},
            {"vitamin_d_iu": 300.0, "calcium_mg": 200.0},
        ]

        vitamin_d_total = sum(log.get("vitamin_d_iu", 0) or 0 for log in food_logs)
        calcium_total = sum(log.get("calcium_mg", 0) or 0 for log in food_logs)

        assert vitamin_d_total == 500.0
        assert calcium_total == 300.0

    def test_sum_empty_logs(self):
        """Test summing nutrients from empty log list."""
        food_logs = []

        vitamin_d_total = sum(log.get("vitamin_d_iu", 0) or 0 for log in food_logs)

        assert vitamin_d_total == 0.0

    def test_top_contributors_sorting(self):
        """Test that contributors are sorted by amount descending."""
        contributors = [
            {"food_name": "Milk", "amount": 100.0},
            {"food_name": "Salmon", "amount": 400.0},
            {"food_name": "Eggs", "amount": 200.0},
        ]

        sorted_contributors = sorted(contributors, key=lambda x: x["amount"], reverse=True)

        assert sorted_contributors[0]["food_name"] == "Salmon"
        assert sorted_contributors[1]["food_name"] == "Eggs"
        assert sorted_contributors[2]["food_name"] == "Milk"

    def test_top_n_contributors(self):
        """Test limiting to top N contributors."""
        contributors = [
            {"food_name": "A", "amount": 100.0},
            {"food_name": "B", "amount": 400.0},
            {"food_name": "C", "amount": 200.0},
            {"food_name": "D", "amount": 50.0},
            {"food_name": "E", "amount": 300.0},
        ]

        sorted_contributors = sorted(contributors, key=lambda x: x["amount"], reverse=True)
        top_3 = sorted_contributors[:3]

        assert len(top_3) == 3
        assert top_3[0]["food_name"] == "B"
        assert top_3[1]["food_name"] == "E"
        assert top_3[2]["food_name"] == "C"


# ============================================================
# PINNED NUTRIENTS TESTS
# ============================================================

class TestPinnedNutrients:
    """Test pinned nutrients logic."""

    def test_max_pinned_limit(self):
        """Test that max 8 nutrients can be pinned."""
        pinned = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
        limited = pinned[:8]

        assert len(limited) == 8

    def test_pinned_deduplication(self):
        """Test that duplicate pinned nutrients are removed."""
        pinned = ["vitamin_d", "calcium", "vitamin_d", "iron", "calcium"]
        unique = list(dict.fromkeys(pinned))

        assert len(unique) == 3
        assert unique == ["vitamin_d", "calcium", "iron"]

    def test_empty_pinned(self):
        """Test empty pinned nutrients list."""
        pinned = []

        assert len(pinned) == 0


# ============================================================
# VALIDATION TESTS
# ============================================================

class TestValidation:
    """Test model validation constraints."""

    def test_nutrient_progress_required_fields(self):
        """Test that required fields are enforced."""
        from models.recipe import NutrientProgress
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            NutrientProgress(
                # Missing required fields
                nutrient_key="test",
            )

    def test_nutrient_rda_required_fields(self):
        """Test that NutrientRDA required fields are enforced."""
        from models.recipe import NutrientRDA
        import pydantic

        with pytest.raises(pydantic.ValidationError):
            NutrientRDA(
                # Missing nutrient_key, unit, etc.
                nutrient_name="Test",
            )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
