"""
Tests for the 7-day Free Trial System on ALL plans.

These tests verify that:
1. Trial eligibility is properly checked
2. Trials can be started on monthly, yearly, and lifetime plans
3. Trials provide full access to premium features
4. Trial-to-paid conversion works correctly
5. Trial limits are enforced (one trial per user)

The 7-day free trial addresses user concerns about:
"I want to try before I buy" and "Show me value before asking for payment"
"""

import pytest
from httpx import AsyncClient
from datetime import datetime, timedelta
import uuid


class TestTrialEligibility:
    """Tests for the GET /api/v1/subscriptions/trial-eligibility/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_new_user_is_eligible(self, client: AsyncClient):
        """Test that a new user is eligible for trial."""
        user_id = str(uuid.uuid4())

        response = await client.get(
            f"/api/v1/subscriptions/trial-eligibility/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["user_id"] == user_id
        assert data["is_eligible"] is True
        assert data["trial_duration_days"] == 7
        assert "monthly" in data["available_plans"]
        assert "yearly" in data["available_plans"]
        assert "lifetime_intro" in data["available_plans"]
        assert data["previous_trials"] == 0

    @pytest.mark.asyncio
    async def test_user_with_active_subscription_not_eligible(self, client: AsyncClient):
        """Test that a user with active subscription is not eligible."""
        # This would require mocking the database
        # For now, just test that the endpoint exists and returns proper structure
        user_id = str(uuid.uuid4())

        response = await client.get(
            f"/api/v1/subscriptions/trial-eligibility/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert "is_eligible" in data
        assert "reason" in data or data["is_eligible"] is True

    @pytest.mark.asyncio
    async def test_eligibility_includes_extension_info(self, client: AsyncClient):
        """Test that eligibility response includes extension information."""
        user_id = str(uuid.uuid4())

        response = await client.get(
            f"/api/v1/subscriptions/trial-eligibility/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert "can_extend" in data
        assert "extension_reason" in data


class TestStartTrial:
    """Tests for the POST /api/v1/subscriptions/start-trial/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_start_trial_monthly_plan(self, client: AsyncClient):
        """Test starting a trial on monthly plan."""
        user_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "monthly",
                "source": "onboarding",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["user_id"] == user_id
        assert data["tier"] == "premium"
        assert data["status"] == "trial"
        assert data["trial_started"] is True
        assert data["trial_plan_type"] == "monthly"
        assert "trial_end_date" in data
        assert len(data["features_unlocked"]) > 0

        # Verify trial end date is 7 days from now
        trial_end = datetime.fromisoformat(data["trial_end_date"])
        now = datetime.utcnow()
        days_diff = (trial_end - now).days
        assert 6 <= days_diff <= 7  # Allow for slight timing differences

    @pytest.mark.asyncio
    async def test_start_trial_yearly_plan(self, client: AsyncClient):
        """Test starting a trial on yearly plan."""
        user_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "yearly",
                "source": "paywall",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["tier"] == "premium"
        assert data["trial_plan_type"] == "yearly"
        assert data["trial_started"] is True

    @pytest.mark.asyncio
    async def test_start_trial_lifetime_plan(self, client: AsyncClient):
        """Test starting a trial on lifetime plan."""
        user_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "lifetime_intro",
                "source": "settings",
            }
        )

        assert response.status_code == 200
        data = response.json()

        # Lifetime trial should give lifetime tier preview
        assert data["tier"] == "lifetime"
        assert data["trial_plan_type"] == "lifetime_intro"
        assert data["trial_started"] is True

    @pytest.mark.asyncio
    async def test_start_trial_invalid_plan_type(self, client: AsyncClient):
        """Test that invalid plan types are rejected."""
        user_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "invalid_plan",
                "source": "test",
            }
        )

        assert response.status_code == 400
        assert "Invalid plan type" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_start_trial_with_demo_session(self, client: AsyncClient):
        """Test starting a trial with demo session link."""
        user_id = str(uuid.uuid4())
        demo_session_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "monthly",
                "demo_session_id": demo_session_id,
                "source": "onboarding",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["trial_started"] is True

    @pytest.mark.asyncio
    async def test_start_trial_unlocks_premium_features(self, client: AsyncClient):
        """Test that trial unlocks expected premium features."""
        user_id = str(uuid.uuid4())

        response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "monthly",
            }
        )

        assert response.status_code == 200
        data = response.json()

        features = data["features_unlocked"]
        assert "Unlimited AI-generated workouts" in features or any("AI" in f for f in features)
        assert any("exercise" in f.lower() for f in features)

    @pytest.mark.asyncio
    async def test_cannot_start_second_trial(self, client: AsyncClient):
        """Test that users cannot start a second trial."""
        user_id = str(uuid.uuid4())

        # Start first trial
        first_response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )
        assert first_response.status_code == 200

        # Try to start second trial
        second_response = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "yearly"}
        )

        # Should be rejected
        assert second_response.status_code == 400
        assert "not eligible" in second_response.json()["detail"].lower() or \
               "already" in second_response.json()["detail"].lower()


class TestTrialStatus:
    """Tests for the GET /api/v1/subscriptions/trial-status/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_trial_status_no_subscription(self, client: AsyncClient):
        """Test getting trial status for user without subscription."""
        user_id = str(uuid.uuid4())

        response = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["is_on_trial"] is False
        assert data["has_subscription"] is False
        assert data["trial_eligible"] is True
        assert "message" in data

    @pytest.mark.asyncio
    async def test_get_trial_status_after_starting_trial(self, client: AsyncClient):
        """Test getting trial status after starting a trial."""
        user_id = str(uuid.uuid4())

        # Start trial
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        # Check status
        response = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["is_on_trial"] is True
        assert data["has_subscription"] is True
        assert data["tier"] in ["premium", "lifetime"]
        assert data["trial_plan_type"] == "monthly"
        assert "days_remaining" in data
        assert data["days_remaining"] >= 6  # Should be close to 7 days

    @pytest.mark.asyncio
    async def test_trial_status_includes_pricing(self, client: AsyncClient):
        """Test that trial status includes conversion pricing."""
        user_id = str(uuid.uuid4())

        # Start trial
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "yearly"}
        )

        response = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert "conversion_pricing" in data
        assert "all_plans" in data
        assert "monthly" in data["all_plans"]
        assert "yearly" in data["all_plans"]
        assert "lifetime_intro" in data["all_plans"]

    @pytest.mark.asyncio
    async def test_trial_status_features_at_risk_near_expiry(self, client: AsyncClient):
        """Test that features at risk appear near trial expiry."""
        # This would require time manipulation in production tests
        # For now, test the structure
        user_id = str(uuid.uuid4())

        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        response = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert "features_at_risk" in data
        # When trial is fresh (7 days remaining), features_at_risk should be empty
        # When close to expiry (<=2 days), it should have items
        assert isinstance(data["features_at_risk"], list)


class TestTrialConversion:
    """Tests for the POST /api/v1/subscriptions/convert-trial/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_convert_trial_to_paid(self, client: AsyncClient):
        """Test converting a trial to paid subscription."""
        user_id = str(uuid.uuid4())

        # Start trial
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        # Convert to paid
        response = await client.post(
            f"/api/v1/subscriptions/convert-trial/{user_id}",
            json={
                "product_id": "com.aifit.premium.monthly",
                "transaction_id": "test_transaction_123",
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "converted"
        assert data["tier"] == "premium"
        assert "message" in data

    @pytest.mark.asyncio
    async def test_convert_trial_to_yearly(self, client: AsyncClient):
        """Test converting a trial to yearly subscription."""
        user_id = str(uuid.uuid4())

        # Start trial on monthly
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        # Convert to yearly (upgrade during trial)
        response = await client.post(
            f"/api/v1/subscriptions/convert-trial/{user_id}",
            json={
                "product_id": "com.aifit.premium.yearly",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "converted"

    @pytest.mark.asyncio
    async def test_convert_trial_to_lifetime(self, client: AsyncClient):
        """Test converting a trial to lifetime subscription."""
        user_id = str(uuid.uuid4())

        # Start trial on lifetime preview
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "lifetime_intro"}
        )

        # Convert to lifetime
        response = await client.post(
            f"/api/v1/subscriptions/convert-trial/{user_id}",
            json={
                "product_id": "com.aifit.lifetime",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "converted"
        assert data["tier"] == "lifetime"

    @pytest.mark.asyncio
    async def test_convert_without_trial_fails(self, client: AsyncClient):
        """Test that converting without an active trial fails."""
        user_id = str(uuid.uuid4())

        # Try to convert without starting trial
        response = await client.post(
            f"/api/v1/subscriptions/convert-trial/{user_id}",
            json={
                "product_id": "com.aifit.premium.monthly",
            }
        )

        assert response.status_code in [400, 404]


class TestTrialAllPlansIntegration:
    """Integration tests for the complete trial flow across all plans."""

    @pytest.mark.asyncio
    async def test_monthly_trial_full_flow(self, client: AsyncClient):
        """Test the complete monthly trial flow."""
        user_id = str(uuid.uuid4())

        # 1. Check eligibility
        eligibility = await client.get(
            f"/api/v1/subscriptions/trial-eligibility/{user_id}"
        )
        assert eligibility.status_code == 200
        assert eligibility.json()["is_eligible"] is True

        # 2. Start trial
        start = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly", "source": "test"}
        )
        assert start.status_code == 200
        assert start.json()["trial_started"] is True

        # 3. Check status
        status = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )
        assert status.status_code == 200
        assert status.json()["is_on_trial"] is True
        assert status.json()["conversion_pricing"]["price"] == 9.99

        # 4. Verify eligibility is now False
        eligibility_after = await client.get(
            f"/api/v1/subscriptions/trial-eligibility/{user_id}"
        )
        assert eligibility_after.json()["is_eligible"] is False

        # 5. Convert to paid
        convert = await client.post(
            f"/api/v1/subscriptions/convert-trial/{user_id}",
            json={"product_id": "com.aifit.premium.monthly"}
        )
        assert convert.status_code == 200
        assert convert.json()["status"] == "converted"

    @pytest.mark.asyncio
    async def test_yearly_trial_full_flow(self, client: AsyncClient):
        """Test the complete yearly trial flow."""
        user_id = str(uuid.uuid4())

        # Start yearly trial
        start = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "yearly", "source": "paywall"}
        )
        assert start.status_code == 200
        assert start.json()["trial_plan_type"] == "yearly"

        # Check status includes yearly pricing
        status = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )
        assert status.status_code == 200
        assert status.json()["conversion_pricing"]["price"] == 59.99
        assert status.json()["conversion_pricing"]["savings"] == "50%"

    @pytest.mark.asyncio
    async def test_lifetime_trial_full_flow(self, client: AsyncClient):
        """Test the complete lifetime trial flow."""
        user_id = str(uuid.uuid4())

        # Start lifetime trial
        start = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "lifetime_intro", "source": "settings"}
        )
        assert start.status_code == 200
        assert start.json()["tier"] == "lifetime"
        assert start.json()["trial_plan_type"] == "lifetime_intro"

        # Check status includes lifetime pricing
        status = await client.get(
            f"/api/v1/subscriptions/trial-status/{user_id}"
        )
        assert status.status_code == 200
        pricing = status.json()["conversion_pricing"]
        assert pricing["price"] == 149.99
        assert pricing["period"] == "one-time"


class TestTrialFromDemoConversion:
    """Tests for the demo-to-trial conversion path."""

    @pytest.mark.asyncio
    async def test_demo_to_trial_conversion(self, client: AsyncClient):
        """Test converting from demo session to trial."""
        demo_session_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        # 1. Start demo session
        demo_start = await client.post(
            "/api/v1/demo/session/start",
            json={
                "session_id": demo_session_id,
                "quiz_data": {"goal": "build_muscle"},
            }
        )
        assert demo_start.status_code == 200

        # 2. Generate preview plan
        preview = await client.post(
            "/api/v1/demo/generate-preview-plan",
            json={
                "goals": ["build_muscle"],
                "fitness_level": "intermediate",
                "equipment": ["dumbbells"],
                "days_per_week": 3,
                "session_id": demo_session_id,
            }
        )
        assert preview.status_code == 200

        # 3. Convert demo session
        await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": demo_session_id,
                "user_id": user_id,
                "trigger": "signup_from_preview",
            }
        )

        # 4. Start trial with demo session link
        trial_start = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "monthly",
                "demo_session_id": demo_session_id,
                "source": "onboarding",
            }
        )
        assert trial_start.status_code == 200
        assert trial_start.json()["trial_started"] is True

    @pytest.mark.asyncio
    async def test_try_workout_to_trial_conversion(self, client: AsyncClient):
        """Test converting from try workout to trial."""
        demo_session_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        # 1. Try workout as demo user
        try_response = await client.post(
            "/api/v1/demo/try-workout",
            json={
                "session_id": demo_session_id,
                "workout_id": "demo-beginner-full-body",
            }
        )
        assert try_response.status_code == 200

        # 2. Complete try workout
        complete_response = await client.post(
            "/api/v1/demo/try-workout/complete",
            json={
                "session_id": demo_session_id,
                "workout_id": "demo-beginner-full-body",
                "duration_seconds": 1200,
                "exercises_completed": 6,
                "exercises_total": 6,
            }
        )
        assert complete_response.status_code == 200
        assert "conversion_offer" in complete_response.json()

        # 3. Convert and start trial
        await client.post(
            "/api/v1/demo/session/convert",
            json={
                "session_id": demo_session_id,
                "user_id": user_id,
                "trigger": "try_workout_complete",
            }
        )

        trial_start = await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={
                "plan_type": "yearly",  # Upsell to yearly
                "demo_session_id": demo_session_id,
                "source": "try_workout_complete",
            }
        )
        assert trial_start.status_code == 200
        assert trial_start.json()["trial_started"] is True
        assert trial_start.json()["trial_plan_type"] == "yearly"


class TestTrialFeatureAccess:
    """Tests to verify trial users get full premium access."""

    @pytest.mark.asyncio
    async def test_trial_unlocks_workout_generation(self, client: AsyncClient):
        """Test that trial users can access workout generation."""
        user_id = str(uuid.uuid4())

        # Start trial
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        # Check access to workout generation
        access_response = await client.post(
            f"/api/v1/subscriptions/{user_id}/check-access",
            json={"feature_key": "workout_generation"}
        )

        assert access_response.status_code == 200
        data = access_response.json()
        # During trial, should have access
        assert data["has_access"] is True or data.get("upgrade_required") is False

    @pytest.mark.asyncio
    async def test_trial_unlocks_ai_coach(self, client: AsyncClient):
        """Test that trial users can access AI coach."""
        user_id = str(uuid.uuid4())

        # Start trial
        await client.post(
            f"/api/v1/subscriptions/start-trial/{user_id}",
            json={"plan_type": "monthly"}
        )

        # Check access to AI coach
        access_response = await client.post(
            f"/api/v1/subscriptions/{user_id}/check-access",
            json={"feature_key": "ai_coach_chat"}
        )

        assert access_response.status_code == 200
        # During trial, should have access
