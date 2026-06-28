"""Unit tests for the nutrition importer parsers + normalization (no DB).

These exercise the pure parse/group path against synthetic samples encoding the
best-known vendor headers. Real-export validation is gated separately (see
services/nutrition_import/fixtures/README.md) before production enablement.
"""
from services.nutrition_import import parse_export
from services.nutrition_import import normalize as nz
from services.nutrition_import.transform import group_food_logs

MFP = (
    "Date,Meal,Food,Calories,Fat (g),Carbohydrates (g),Fiber,Protein (g),Sodium (mg)\n"
    "2026-01-05,Breakfast,Oatmeal,300,5,54,8,10,2\n"
    "2026-01-05,Breakfast,Banana,105,0,27,3,1,1\n"
    "2026-01-05,Lunch,Chicken Salad,450,20,12,4,40,600\n"
    "2026-01-06,Dinner,Salmon,500,30,0,0,42,300\n"
)

MACROFACTOR = (
    "Date,Calories,Protein (g),Carbs (g),Fat (g),Fiber (g),Scale Weight (kg)\n"
    "2026-02-01,2100,160,210,70,30,80.5\n"
    "2026-02-02,1980,150,200,65,28,80.3\n"
)

CRONOMETER = (
    "Day,Time,Group,Food Name,Amount,Energy (kcal),Protein (g),Carbohydrates (g),Fat (g),Fiber (g)\n"
    "2026-03-10,08:00,Breakfast,Eggs,2 large,140,12,1,10,0\n"
    "2026-03-10,12:30,Lunch,Rice,200 g,260,5,56,1,1\n"
)

# kJ energy + EU day-first date + decimal comma
EU_KJ = (
    "Date;Meal;Calories (kJ);Protein (g);Carbs (g);Fat (g)\n"
    "13/04/2026;Lunch;2092;30,5;40,0;10,2\n"
)


def test_mfp_groups_by_date_and_meal():
    res = parse_export(data=MFP.encode(), filename="mfp.csv", source="myfitnesspal")
    assert res.source == "myfitnesspal"
    assert len(res.food_rows) == 4
    logs = group_food_logs("u1", res.source, res.food_rows)
    # 3 groups: (1/5 breakfast), (1/5 lunch), (1/6 dinner)
    assert len(logs) == 3
    bfast = next(l for l in logs if l["_date"] == "2026-01-05" and l["meal_type"] == "breakfast")
    assert bfast["total_calories"] == 405  # 300 + 105
    assert len(bfast["food_items"]) == 2
    # deterministic idempotency key is stable
    again = group_food_logs("u1", res.source, res.food_rows)
    assert {l["idempotency_key"] for l in logs} == {l["idempotency_key"] for l in again}


def test_macrofactor_daily_totals_and_weight():
    res = parse_export(data=MACROFACTOR.encode(), filename="mf.csv", source="macrofactor")
    assert len(res.food_rows) == 2            # one daily total per day
    assert res.food_rows[0].name == "Imported daily total"
    assert len(res.weight_rows) == 2
    assert abs(res.weight_rows[0].weight_kg - 80.5) < 0.01


def test_cronometer_servings_with_names():
    res = parse_export(data=CRONOMETER.encode(), filename="crono.csv", source="cronometer")
    assert len(res.food_rows) == 2
    names = {r.name for r in res.food_rows}
    assert "Eggs" in names and "Rice" in names


def test_kj_and_eu_locale_normalization():
    res = parse_export(data=EU_KJ.encode(), filename="eu.csv", source="auto")
    assert len(res.food_rows) == 1
    row = res.food_rows[0]
    # 2092 kJ ≈ 500 kcal
    assert 495 <= row.calories <= 505
    assert abs(row.protein_g - 30.5) < 0.1     # decimal comma parsed
    assert row.date.day == 13 and row.date.month == 4  # day-first respected


def test_auto_detect_source():
    assert parse_export(data=CRONOMETER.encode(), source="auto").source == "cronometer"
    assert parse_export(data=MFP.encode(), source="auto").source == "myfitnesspal"


def test_unit_helpers():
    assert nz.energy_to_kcal("2092", "calories kj") == round(2092 / 4.184, 1)
    assert nz.to_float("1.234,5") == 1234.5     # EU thousands + decimal
    assert nz.to_float("1,234.5") == 1234.5     # US thousands + decimal
    assert nz.map_meal("Snacks") == "snack"


def test_apple_health_rows():
    rows = [
        {"date": "2026-05-01", "calories": 1800, "protein_g": 120, "weight_kg": 79.0},
        {"date": "2026-05-02", "calories": 0},  # no food → skipped
    ]
    res = parse_export(source="apple_health", apple_health_rows=rows)
    assert len(res.food_rows) == 1
    assert len(res.weight_rows) == 1
