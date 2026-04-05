"""Helper functions extracted from assessment.
Flexibility Assessment Service.

Handles flexibility testing, evaluation, progress tracking, and personalized recommendations.


"""
def _get_age_group(age: int) -> str:
    """Get the age group string for norm lookup."""
    if age < 30:
        return "18-29"
    elif age < 40:
        return "30-39"
    elif age < 50:
        return "40-49"
    elif age < 60:
        return "50-59"
    else:
        return "60+"


def _get_rating_from_norms(
    measurement: float,
    norms: TestNorms,
    higher_is_better: bool
) -> FlexibilityRating:
    """Determine the rating based on measurement and norms."""
    if higher_is_better:
        if measurement >= norms.excellent[0]:
            return FlexibilityRating.EXCELLENT
        elif measurement >= norms.good[0]:
            return FlexibilityRating.GOOD
        elif measurement >= norms.fair[0]:
            return FlexibilityRating.FAIR
        else:
            return FlexibilityRating.POOR
    else:
        # For tests where lower is better (like shoulder gap, hip flexor angle)
        if measurement <= norms.excellent[1]:
            return FlexibilityRating.EXCELLENT
        elif measurement <= norms.good[1]:
            return FlexibilityRating.GOOD
        elif measurement <= norms.fair[1]:
            return FlexibilityRating.FAIR
        else:
            return FlexibilityRating.POOR


def calculate_percentile(
    test_type: str,
    measurement: float,
    gender: str,
    age: int
) -> int:
    """Calculate the approximate percentile for a flexibility measurement."""
    test = FLEXIBILITY_TESTS.get(test_type)
    if not test:
        return 50  # Default to median if test not found

    gender_key = gender.lower() if gender.lower() in ["male", "female"] else "male"
    age_group = _get_age_group(age)

    if gender_key not in test.norms or age_group not in test.norms[gender_key]:
        return 50

    norms = test.norms[gender_key][age_group]
    higher_is_better = test.higher_is_better

    # Calculate percentile based on where measurement falls in the ranges
    if higher_is_better:
        # Poor: 0-25, Fair: 25-50, Good: 50-75, Excellent: 75-100
        if measurement <= norms.poor[1]:
            # Poor range: 0-25%
            range_size = norms.poor[1] - norms.poor[0]
            if range_size == 0:
                return 12
            position = (measurement - norms.poor[0]) / range_size
            return max(1, min(24, int(position * 24)))
        elif measurement <= norms.fair[1]:
            # Fair range: 25-50%
            range_size = norms.fair[1] - norms.fair[0]
            if range_size == 0:
                return 37
            position = (measurement - norms.fair[0]) / range_size
            return 25 + int(position * 25)
        elif measurement <= norms.good[1]:
            # Good range: 50-75%
            range_size = norms.good[1] - norms.good[0]
            if range_size == 0:
                return 62
            position = (measurement - norms.good[0]) / range_size
            return 50 + int(position * 25)
        else:
            # Excellent range: 75-100%
            range_size = norms.excellent[1] - norms.excellent[0]
            if range_size == 0:
                return 87
            position = min(1.0, (measurement - norms.excellent[0]) / range_size)
            return min(99, 75 + int(position * 25))
    else:
        # For lower-is-better tests, invert the logic
        if measurement >= norms.poor[0]:
            # Poor range: 0-25%
            range_size = norms.poor[1] - norms.poor[0]
            if range_size == 0:
                return 12
            position = 1 - ((measurement - norms.poor[0]) / range_size)
            return max(1, min(24, int(position * 24)))
        elif measurement >= norms.fair[0]:
            # Fair range: 25-50%
            range_size = norms.fair[1] - norms.fair[0]
            if range_size == 0:
                return 37
            position = 1 - ((measurement - norms.fair[0]) / range_size)
            return 25 + int(position * 25)
        elif measurement >= norms.good[0]:
            # Good range: 50-75%
            range_size = norms.good[1] - norms.good[0]
            if range_size == 0:
                return 62
            position = 1 - ((measurement - norms.good[0]) / range_size)
            return 50 + int(position * 25)
        else:
            # Excellent range: 75-100%
            range_size = norms.excellent[1] - norms.excellent[0]
            if range_size == 0:
                return 87
            position = min(1.0, 1 - ((measurement - norms.excellent[0]) / max(0.1, range_size)))
            return min(99, 75 + int(position * 25))


def get_recommendations(test_type: str, rating: str) -> List[Dict[str, Any]]:
    """Get stretch recommendations based on test result."""
    if test_type not in STRETCH_RECOMMENDATIONS:
        return []

    rating_lower = rating.lower()
    if rating_lower not in STRETCH_RECOMMENDATIONS[test_type]:
        return []

    return STRETCH_RECOMMENDATIONS[test_type][rating_lower]


def evaluate_flexibility(
    test_type: str,
    measurement: float,
    gender: str,
    age: int,
    notes: Optional[str] = None
) -> Dict[str, Any]:
    """
    Evaluate a flexibility measurement and return rating, percentile, and recommendations.

    Args:
        test_type: The type of flexibility test (e.g., 'sit_and_reach')
        measurement: The measured value
        gender: 'male' or 'female'
        age: Age in years
        notes: Optional notes about the assessment

    Returns:
        Dictionary with evaluation results
    """
    test = FLEXIBILITY_TESTS.get(test_type)
    if not test:
        logger.warning(f"Unknown flexibility test type: {test_type}")
        return {
            "error": f"Unknown test type: {test_type}",
            "available_tests": list(FLEXIBILITY_TESTS.keys())
        }

    gender_key = gender.lower() if gender.lower() in ["male", "female"] else "male"
    age_group = _get_age_group(age)

    if gender_key not in test.norms:
        logger.warning(f"No norms for gender: {gender_key}")
        gender_key = "male"  # Fallback

    if age_group not in test.norms[gender_key]:
        logger.warning(f"No norms for age group: {age_group}")
        age_group = "18-29"  # Fallback

    norms = test.norms[gender_key][age_group]
    rating = _get_rating_from_norms(measurement, norms, test.higher_is_better)
    percentile = calculate_percentile(test_type, measurement, gender, age)
    recommendations = get_recommendations(test_type, rating.value)

    # Generate improvement tips based on rating
    improvement_message = ""
    if rating == FlexibilityRating.POOR:
        improvement_message = f"Focus on daily stretching. With consistent practice, you can improve your {test.name.lower().replace(' test', '')} significantly in 4-6 weeks."
    elif rating == FlexibilityRating.FAIR:
        improvement_message = f"You're on the right track! Regular stretching 3-4 times per week will help you move into the 'good' range."
    elif rating == FlexibilityRating.GOOD:
        improvement_message = f"Great flexibility! Continue your current routine and consider adding variety to reach excellent levels."
    else:
        improvement_message = "Excellent flexibility! Maintain your routine to keep this level."

    return {
        "test_type": test_type,
        "test_name": test.name,
        "measurement": measurement,
        "unit": test.unit,
        "rating": rating.value,
        "percentile": percentile,
        "age_group": age_group,
        "gender": gender_key,
        "target_muscles": test.target_muscles,
        "recommendations": recommendations,
        "improvement_message": improvement_message,
        "tips": test.tips,
        "common_mistakes": test.common_mistakes,
        "notes": notes
    }


class FlexibilityAssessmentService:
    """
    Service for managing flexibility assessments, tracking progress, and generating reports.
    """

    def __init__(self):
        """Initialize the flexibility assessment service."""
        self.tests = FLEXIBILITY_TESTS

    def get_all_tests(self) -> List[Dict[str, Any]]:
        """Get all available flexibility tests with their details."""
        return [
            {
                "id": test.id,
                "name": test.name,
                "description": test.description,
                "instructions": test.instructions,
                "unit": test.unit,
                "target_muscles": test.target_muscles,
                "equipment_needed": test.equipment_needed,
                "tips": test.tips,
                "common_mistakes": test.common_mistakes,
                "video_url": test.video_url,
                "image_url": test.image_url,
            }
            for test in self.tests.values()
        ]

    def get_test_by_id(self, test_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific test by its ID."""
        test = self.tests.get(test_id)
        if not test:
            return None

        return {
            "id": test.id,
            "name": test.name,
            "description": test.description,
            "instructions": test.instructions,
            "unit": test.unit,
            "target_muscles": test.target_muscles,
            "equipment_needed": test.equipment_needed,
            "tips": test.tips,
            "common_mistakes": test.common_mistakes,
            "video_url": test.video_url,
            "image_url": test.image_url,
        }

    def get_tests_by_muscle(self, muscle: str) -> List[Dict[str, Any]]:
        """Get tests that target a specific muscle group."""
        results = []
        muscle_lower = muscle.lower()

        for test in self.tests.values():
            if any(muscle_lower in m.lower() for m in test.target_muscles):
                results.append({
                    "id": test.id,
                    "name": test.name,
                    "description": test.description,
                    "target_muscles": test.target_muscles,
                    "unit": test.unit,
                })

        return results

    def evaluate(
        self,
        test_type: str,
        measurement: float,
        gender: str,
        age: int,
        notes: Optional[str] = None
    ) -> Dict[str, Any]:
        """Evaluate a flexibility measurement."""
        return evaluate_flexibility(test_type, measurement, gender, age, notes)

    def compare_assessments(
        self,
        assessments: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Compare multiple assessments to show progress over time.

        Args:
            assessments: List of assessment results ordered from oldest to newest

        Returns:
            Comparison data with trends and improvements
        """
        if len(assessments) < 2:
            return {
                "error": "Need at least 2 assessments to compare",
                "assessments_provided": len(assessments)
            }

        first = assessments[0]
        last = assessments[-1]

        improvement = last["measurement"] - first["measurement"]
        test = self.tests.get(first["test_type"])

        # Determine if improvement is positive based on test type
        if test and not test.higher_is_better:
            # For tests where lower is better, negate the improvement
            improvement = -improvement

        improvement_percentage = 0
        if first["measurement"] != 0:
            improvement_percentage = (improvement / abs(first["measurement"])) * 100

        rating_improved = last["rating"] != first["rating"]
        rating_change = 0
        ratings_order = ["poor", "fair", "good", "excellent"]
        if first["rating"] in ratings_order and last["rating"] in ratings_order:
            rating_change = ratings_order.index(last["rating"]) - ratings_order.index(first["rating"])

        return {
            "test_type": first["test_type"],
            "test_name": first.get("test_name", "Unknown Test"),
            "unit": first.get("unit", ""),
            "first_assessment": {
                "measurement": first["measurement"],
                "rating": first["rating"],
                "percentile": first.get("percentile", 50),
                "date": first.get("assessed_at")
            },
            "latest_assessment": {
                "measurement": last["measurement"],
                "rating": last["rating"],
                "percentile": last.get("percentile", 50),
                "date": last.get("assessed_at")
            },
            "total_assessments": len(assessments),
            "improvement": {
                "absolute": round(improvement, 2),
                "percentage": round(improvement_percentage, 1),
                "is_positive": improvement > 0,
                "rating_improved": rating_improved,
                "rating_levels_gained": rating_change
            },
            "trend_data": [
                {
                    "measurement": a["measurement"],
                    "rating": a["rating"],
                    "date": a.get("assessed_at")
                }
                for a in assessments
            ]
        }

    def get_overall_flexibility_score(
        self,
        assessments: Dict[str, Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Calculate an overall flexibility score based on multiple test results.

        Args:
            assessments: Dictionary mapping test_type to assessment result

        Returns:
            Overall score and breakdown by category
        """
        if not assessments:
            return {"error": "No assessments provided"}

        rating_scores = {
            "poor": 1,
            "fair": 2,
            "good": 3,
            "excellent": 4
        }

        total_score = 0
        max_possible = len(assessments) * 4

        category_scores = {}
        for test_type, result in assessments.items():
            rating = result.get("rating", "poor").lower()
            score = rating_scores.get(rating, 1)
            total_score += score

            test = self.tests.get(test_type)
            if test:
                for muscle in test.target_muscles:
                    if muscle not in category_scores:
                        category_scores[muscle] = {"total": 0, "count": 0}
                    category_scores[muscle]["total"] += score
                    category_scores[muscle]["count"] += 1

        overall_percentage = (total_score / max_possible) * 100 if max_possible > 0 else 0

        # Determine overall rating
        if overall_percentage >= 75:
            overall_rating = "excellent"
        elif overall_percentage >= 50:
            overall_rating = "good"
        elif overall_percentage >= 25:
            overall_rating = "fair"
        else:
            overall_rating = "poor"

        # Calculate category averages
        category_averages = {}
        for muscle, data in category_scores.items():
            avg = data["total"] / data["count"] if data["count"] > 0 else 0
            if avg >= 3.5:
                category_averages[muscle] = "excellent"
            elif avg >= 2.5:
                category_averages[muscle] = "good"
            elif avg >= 1.5:
                category_averages[muscle] = "fair"
            else:
                category_averages[muscle] = "poor"

        return {
            "overall_score": round(overall_percentage, 1),
            "overall_rating": overall_rating,
            "tests_completed": len(assessments),
            "category_ratings": category_averages,
            "improvement_priority": self._get_improvement_priorities(assessments)
        }

    def _get_improvement_priorities(
        self,
        assessments: Dict[str, Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """Get prioritized list of areas to improve."""
        priorities = []

        rating_order = {"poor": 0, "fair": 1, "good": 2, "excellent": 3}

        for test_type, result in assessments.items():
            rating = result.get("rating", "poor").lower()
            if rating in ["poor", "fair"]:
                test = self.tests.get(test_type)
                priorities.append({
                    "test_type": test_type,
                    "test_name": test.name if test else test_type,
                    "current_rating": rating,
                    "priority": 1 if rating == "poor" else 2,
                    "target_muscles": test.target_muscles if test else [],
                    "recommendations": get_recommendations(test_type, rating)[:2]  # Top 2 stretches
                })

        # Sort by priority (poor first)
        priorities.sort(key=lambda x: x["priority"])

        return priorities


# Singleton instance
_flexibility_service: Optional[FlexibilityAssessmentService] = None


def get_flexibility_assessment_service() -> FlexibilityAssessmentService:
    """Get the FlexibilityAssessmentService singleton instance."""
    global _flexibility_service
    if _flexibility_service is None:
        _flexibility_service = FlexibilityAssessmentService()
    return _flexibility_service
