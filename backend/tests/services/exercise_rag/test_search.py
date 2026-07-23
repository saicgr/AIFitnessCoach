"""
Tests for exercise RAG search functions.
"""

import pytest
from unittest.mock import patch, MagicMock


class TestBuildSearchQuery:
    """Tests for build_search_query function."""

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_builds_basic_query(self, mock_keywords):
        """Test building basic search query."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="chest",
            equipment=["Dumbbells"],
            fitness_level="intermediate",
            goals=["Build Muscle"]
        )

        assert "chest" in query.lower()
        assert "dumbbell" in query.lower()
        assert "intermediate" in query.lower()
        assert "muscle" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_uses_focus_area_keywords(self, mock_keywords):
        """Test using predefined focus area keywords."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="full_body",
            equipment=["Bodyweight"],
            fitness_level="beginner",
            goals=[]
        )

        assert "full body" in query.lower()
        assert "compound" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_sport_specific_keywords(self, mock_keywords):
        """Test sport-specific focus areas."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="boxing",
            equipment=["Bodyweight"],
            fitness_level="intermediate",
            goals=[]
        )

        assert "boxing" in query.lower()
        assert "punch" in query.lower() or "power" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_includes_goal_keywords(self, mock_keywords):
        """Test including goal-specific keywords."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="legs",
            equipment=["Full Gym"],
            fitness_level="advanced",
            goals=["Lose Weight", "Improve Endurance"]
        )

        assert "fat" in query.lower() or "metabolic" in query.lower()
        assert "endurance" in query.lower() or "cardio" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_includes_training_program_keywords(self, mock_keywords):
        """Test including training program keywords."""
        mock_keywords.return_value = {
            "HYROX Training": "hyrox functional running endurance"
        }

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="full_body",
            equipment=["Full Gym"],
            fitness_level="intermediate",
            goals=["HYROX Training"]
        )

        assert "hyrox" in query.lower() or "functional" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_handles_empty_equipment(self, mock_keywords):
        """Test handling empty equipment list."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="core",
            equipment=[],
            fitness_level="beginner",
            goals=[]
        )

        assert "bodyweight" in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_unknown_focus_area(self, mock_keywords):
        """Test handling unknown focus area."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="unknown_area",
            equipment=["Dumbbells"],
            fitness_level="intermediate",
            goals=[]
        )

        assert "unknown_area" in query.lower()



# ─────────────────────────────────────────────────────────────────────────────
# REAL PRODUCTION INVENTORIES
#
# These are literal transcriptions of the four lists the Flutter client can put
# in `users.equipment`. They are NOT hand-shaped to make the implementation
# pass — `test_fixtures_match_the_dart_sources` re-parses the Dart files and
# fails if any of them drifts.
#
#   COMMERCIAL_GYM_DEFAULT_EQUIPMENT
#       mobile/flutter/lib/core/providers/environment_equipment_provider.dart
#       :137-228 — `WorkoutEnvironment.commercialGym.defaultEquipment`.
#       83 entries, and the comment at :134 says it DELIBERATELY omits the
#       `full_gym` marker. This is what a gym-profile user actually sends, so
#       it must NOT reach a full-gym collapse.
#   GYM_EQUIPMENT_SHEET_ALL_ITEMS
#       mobile/flutter/lib/screens/home/widgets/gym_equipment_sheet.dart:13-67.
#       The sheet STRIPS `full_gym` (:212-218) and writes back these 43 items.
#   ONBOARDING_COMMERCIAL_GYM_PRESET
#       mobile/flutter/lib/screens/onboarding/pre_auth_quiz_screen_ext.dart
#       :22-126 — the ONE path that does keep `full_gym` (88 entries).
#   HOME_GYM_DEFAULT_EQUIPMENT
#       environment_equipment_provider.dart:230-243 (12 entries, no marker).
#
# Plus backend/api/v1/users/models.py:10-20, which sends the one-element lists
# ['full_gym'] / ['home_gym'] / ['bodyweight'].
# ─────────────────────────────────────────────────────────────────────────────

DART_INVENTORY_SOURCES = {
    # name -> (repo-relative dart path, start line, end line, dropped literals)
    "COMMERCIAL_GYM_DEFAULT_EQUIPMENT": (
        "mobile/flutter/lib/core/providers/environment_equipment_provider.dart",
        137, 228, frozenset(),
    ),
    "HOME_GYM_DEFAULT_EQUIPMENT": (
        "mobile/flutter/lib/core/providers/environment_equipment_provider.dart",
        230, 243, frozenset(),
    ),
    "ONBOARDING_COMMERCIAL_GYM_PRESET": (
        "mobile/flutter/lib/screens/onboarding/pre_auth_quiz_screen_ext.dart",
        22, 126, frozenset(),
    ),
    "GYM_EQUIPMENT_SHEET_ALL_ITEMS": (
        "mobile/flutter/lib/screens/home/widgets/gym_equipment_sheet.dart",
        13, 67,
        frozenset({
            "Free Weights", "Machines", "Cardio", "Racks & Benches",
            "Bodyweight & Accessories",
        }),
    ),
}

COMMERCIAL_GYM_DEFAULT_EQUIPMENT = [  # 83 entries
    'bodyweight', 'barbell', 'ez_curl_bar', 'EZ Bar', 'Trap Bar', 'dumbbells',
    'kettlebell', 'kettlebells', 'weight_plates', 'Weight Plate', 'pull_up_bar',
    'dip_station', 'Dip Station', 'Assisted Pull Up Machine', 'Ab Roller',
    'Balance Board', 'Box', 'Chair', 'Exercise Ball', 'Hyperextension Bench',
    'Jump rope', 'Loop Resistance Band', 'resistance_bands', 'Yoga Mat',
    'bench', 'Bench', 'bench_press', 'adjustable_bench', 'squat_rack',
    'power_rack', 'smith_machine', 'Smith Machine', 'cable_machine',
    'Cable Pulley Machine', 'Cable Row Machine', 'Chest Press Machine',
    'chest_fly_machine', 'shoulder_press_machine', 'Hammer Strength Machines',
    'Hack Squat Machine', 'hack_squat', 'lat_pulldown', 'Lat Pull Down Machine',
    'seated_row_machine', 'leg_press', 'Leg Press Machine', 'leg_curl_machine',
    'leg_extension_machine', 'Leg Extension Machine', 'calf_raise_machine',
    'Seated Hip Abductor Machine', 'Triceps Extension Machine', 'treadmill',
    'Treadmill', 'stationary_bike', 'Stationary Exercise Bike', 'Airbike',
    'Ski Ergometer', 'elliptical', 'Elliptical Machine', 'rowing_machine',
    'Rowing Machine', 'medicine_ball', 'Medicine Ball', 'Slam Ball',
    'battle_ropes', 'battle ropes', 'rope', 'sandbag', 'tire', 'tire, sledgehammer',
    'hay bale', 'trx', 'suspension_trainer', 'Suspension Trainer', 'gada (mace)',
    'gar nal (stone neck ring)', 'jori (indian clubs)', 'lathi (bamboo staff)',
    'mallakhamb pole', 'matka (water pot)', 'nal (stone lock)', 'samtola (indian barbell)',
]

HOME_GYM_DEFAULT_EQUIPMENT = [  # 12 entries
    'barbell', 'dumbbells', 'kettlebells', 'pull_up_bar', 'resistance_bands',
    'adjustable_bench', 'squat_rack', 'weight_plates', 'ez_curl_bar',
    'dip_station', 'medicine_ball', 'yoga_mat',
]

ONBOARDING_COMMERCIAL_GYM_PRESET = [  # 88 entries
    'full_gym', 'bodyweight', 'barbell', 'olympic_barbell', 'ez_bar',
    'trap_bar', 'safety_squat_bar', 'cambered_bar', 'swiss_bar', 'log_bar',
    'dumbbells', 'kettlebell', 'kettlebells', 'weight_plates', 'Weight Plate',
    'Bumper Plates', 'pull_up_bar', 'dip_station', 'Dip Station', 'Assisted Pull Up Machine',
    'Ab Roller', 'Balance Board', 'Box', 'Chair', 'Exercise Ball', 'Hyperextension Bench',
    'Jump rope', 'Loop Resistance Band', 'resistance_bands', 'Yoga Mat',
    'bench', 'Bench', 'adjustable_bench', 'squat_rack', 'power_rack',
    'smith_machine', 'Smith Machine', 'cable_machine', 'Cable Pulley Machine',
    'Cable Row Machine', 'Chest Press Machine', 'chest_fly_machine',
    'shoulder_press_machine', 'Hammer Strength Machines', 'Hack Squat Machine',
    'hack_squat', 'lat_pulldown', 'Lat Pull Down Machine', 'seated_row_machine',
    'leg_press', 'Leg Press Machine', 'leg_curl_machine', 'leg_extension_machine',
    'Leg Extension Machine', 'calf_raise_machine', 'Hip Abductor Machine',
    'Triceps Extension Machine', 'treadmill', 'Treadmill', 'stationary_bike',
    'Stationary Exercise Bike', 'Assault Bike', 'Ski Ergometer', 'elliptical',
    'Elliptical Machine', 'rowing_machine', 'Rowing Machine', 'medicine_ball',
    'Medicine Ball', 'Slam Ball', 'battle_ropes', 'battle ropes', 'rope',
    'sandbag', 'tire', 'sledgehammer', 'hay bale', 'trx', 'suspension_trainer',
    'Suspension Trainer', 'gada (mace)', 'gar nal (stone neck ring)',
    'jori (indian clubs)', 'lathi (bamboo staff)', 'mallakhamb pole',
    'matka (water pot)', 'nal (stone lock)', 'samtola (indian barbell)',
]

GYM_EQUIPMENT_SHEET_ALL_ITEMS = [  # 43 entries
    'bumper_plates', 'dumbbells', 'kettlebells', 'barbell', 'ez_curl_bar',
    'trap_bar', 'weight_plates', 'medicine_ball', 'cable_machine', 'smith_machine',
    'leg_press', 'lat_pulldown', 'leg_curl_machine', 'leg_extension_machine',
    'chest_fly_machine', 'shoulder_press_machine', 'hack_squat', 'seated_row_machine',
    'chest_press_machine', 'assisted_pullup_machine', 'treadmill', 'stationary_bike',
    'elliptical', 'rowing_machine', 'stair_climber', 'assault_bike',
    'bench', 'squat_rack', 'adjustable_bench', 'flat_bench', 'incline_bench',
    'decline_bench', 'bodyweight', 'pull_up_bar', 'dip_station', 'resistance_bands',
    'yoga_mat', 'stability_ball', 'foam_roller', 'ab_wheel', 'jump_rope',
    'trx', 'battle_ropes',
]

# Every inventory that reaches the CAP path (no `full_gym` marker anywhere).
INVENTORIES_WITHOUT_FULL_GYM_MARKER = {
    "commercialGym.defaultEquipment": COMMERCIAL_GYM_DEFAULT_EQUIPMENT,
    "GymEquipmentSheet(all categories)": GYM_EQUIPMENT_SHEET_ALL_ITEMS,
    "homeGym.defaultEquipment": HOME_GYM_DEFAULT_EQUIPMENT,
}

# Tokens that must never survive into the embedded query for a gym user: they
# are the equipment nouns that produced the original junk picks
# ("Assault Airbike Sprint", "Balance Board Lateral Squat", "Band Squat Row").
RETRIEVAL_NOISE_TOKENS = (
    "airbike", "assault bike", "balance board", "elliptical", "treadmill",
    "stair climber", "ski erg", "hay bale", "sandbag", "tire", "gada",
    "mallakhamb", "matka", "samtola", "chair", "yoga mat", "jump rope",
)


def _parse_dart_string_literals(repo_root, spec):
    """Re-extract a Dart const list so fixtures cannot silently drift."""
    import re

    rel, start, end, drop = spec
    path = repo_root / rel
    if not path.exists():
        return None
    lines = path.read_text().split("\n")
    segment = "\n".join(lines[start - 1:end])
    return [
        s for s in re.findall(r"'([^']*)'", segment) if s not in drop
    ]


class TestFixturesAreTheRealInventories:
    """The fixtures above must equal the Dart sources, byte for byte."""

    def test_fixtures_match_the_dart_sources(self):
        from pathlib import Path

        repo_root = Path(__file__).resolve().parents[4]
        if not (repo_root / "mobile" / "flutter").exists():
            pytest.skip(
                f"Flutter tree not present under {repo_root} "
                "(backend-only checkout) — cannot verify fixture drift"
            )

        expected = {
            "COMMERCIAL_GYM_DEFAULT_EQUIPMENT": COMMERCIAL_GYM_DEFAULT_EQUIPMENT,
            "HOME_GYM_DEFAULT_EQUIPMENT": HOME_GYM_DEFAULT_EQUIPMENT,
            "ONBOARDING_COMMERCIAL_GYM_PRESET": ONBOARDING_COMMERCIAL_GYM_PRESET,
            "GYM_EQUIPMENT_SHEET_ALL_ITEMS": GYM_EQUIPMENT_SHEET_ALL_ITEMS,
        }
        for name, spec in DART_INVENTORY_SOURCES.items():
            parsed = _parse_dart_string_literals(repo_root, spec)
            assert parsed is not None, f"{spec[0]} missing"
            assert parsed == expected[name], (
                f"{name} drifted from {spec[0]}:{spec[1]}-{spec[2]}.\n"
                f"  dart   ({len(parsed)}): {parsed}\n"
                f"  python ({len(expected[name])}): {expected[name]}"
            )

    def test_only_onboarding_carries_the_full_gym_marker(self):
        """The reviewer-reproduced fact this whole design hangs on."""
        assert "full_gym" in ONBOARDING_COMMERCIAL_GYM_PRESET
        for name, inv in INVENTORIES_WITHOUT_FULL_GYM_MARKER.items():
            assert not any("full_gym" in e or "full gym" in e.lower() for e in inv), (
                f"{name} unexpectedly contains a full_gym marker"
            )

    def test_inventory_sizes(self):
        assert len(COMMERCIAL_GYM_DEFAULT_EQUIPMENT) == 83
        assert len(GYM_EQUIPMENT_SHEET_ALL_ITEMS) == 43
        assert len(ONBOARDING_COMMERCIAL_GYM_PRESET) == 88
        assert len(HOME_GYM_DEFAULT_EQUIPMENT) == 12


class TestCanonicalKeyHandlesRealDuplicates:
    """
    The dedupe must collapse the spellings that ACTUALLY appear in the Dart
    lists — case differences, embedded "Machine", plurals and multiword
    synonyms — not just the shapes a hand-written fixture happened to contain.
    """

    # (label, [spellings that must share one canonical key])
    REAL_DUPLICATE_GROUPS = [
        ("cable station", ["cable_machine", "Cable Pulley Machine"]),
        ("ez curl bar", ["ez_curl_bar", "EZ Bar", "ez_bar"]),
        ("lat pulldown", ["lat_pulldown", "Lat Pull Down Machine"]),
        ("stationary bike", ["stationary_bike", "Stationary Exercise Bike"]),
        ("suspension", ["trx", "suspension_trainer", "Suspension Trainer"]),
        ("smith", ["smith_machine", "Smith Machine"]),
        ("bench", ["bench", "Bench", "bench_press", "adjustable_bench",
                   "flat_bench", "incline_bench", "decline_bench"]),
        ("rack", ["squat_rack", "power_rack"]),
        ("dip station", ["dip_station", "Dip Station"]),
        ("kettlebell", ["kettlebell", "kettlebells"]),
        ("weight plate", ["weight_plates", "Weight Plate", "Bumper Plates",
                          "bumper_plates"]),
        ("leg press", ["leg_press", "Leg Press Machine"]),
        ("leg extension", ["leg_extension_machine", "Leg Extension Machine"]),
        ("hack squat", ["hack_squat", "Hack Squat Machine"]),
        ("hip abductor", ["Seated Hip Abductor Machine", "Hip Abductor Machine"]),
        ("treadmill", ["treadmill", "Treadmill"]),
        ("elliptical", ["elliptical", "Elliptical Machine"]),
        ("rower", ["rowing_machine", "Rowing Machine"]),
        ("medicine ball", ["medicine_ball", "Medicine Ball"]),
        ("battle rope", ["battle_ropes", "battle ropes"]),
        ("air bike", ["Airbike", "Assault Bike", "assault_bike"]),
        ("ski erg", ["Ski Ergometer"]),
        ("resistance band", ["resistance_bands", "Loop Resistance Band"]),
        ("ab wheel", ["Ab Roller", "ab_wheel"]),
        ("assisted pull up", ["Assisted Pull Up Machine",
                              "assisted_pullup_machine"]),
        ("stability ball", ["Exercise Ball", "stability_ball"]),
        ("barbell", ["barbell", "olympic_barbell"]),
        ("pull up bar", ["pull_up_bar"]),
    ]

    @pytest.mark.parametrize("label,spellings", REAL_DUPLICATE_GROUPS,
                             ids=[g[0] for g in REAL_DUPLICATE_GROUPS])
    def test_group_shares_one_canonical_key(self, label, spellings):
        from services.exercise_rag.search import canonical_equipment_key

        keys = {canonical_equipment_key(s) for s in spellings}
        assert len(keys) == 1, (
            f"{label}: spellings {spellings} produced {len(keys)} keys {keys}"
        )
        assert keys != {""}

    def test_distinct_implements_do_not_collapse(self):
        """Aliasing must not over-merge genuinely different equipment."""
        from services.exercise_rag.search import canonical_equipment_key

        distinct = [
            "barbell", "dumbbells", "kettlebell", "cable_machine", "bench",
            "Hyperextension Bench", "squat_rack", "smith_machine",
            "leg_press", "leg_curl_machine", "leg_extension_machine",
            "Cable Row Machine", "seated_row_machine", "Chest Press Machine",
            "chest_fly_machine", "shoulder_press_machine", "Slam Ball",
            "medicine_ball", "sandbag", "tire", "sledgehammer", "rope",
            "battle_ropes", "trx", "treadmill", "elliptical", "Airbike",
            "rowing_machine", "Ski Ergometer", "stair_climber",
        ]
        keys = [canonical_equipment_key(d) for d in distinct]
        assert len(keys) == len(set(keys)), (
            "over-merged: "
            + repr([k for k in keys if keys.count(k) > 1])
        )

    def test_multi_implement_entry_is_split(self):
        """`'tire, sledgehammer'` is ONE real entry containing TWO implements."""
        from services.exercise_rag.search import (
            split_equipment_entries, canonical_equipment_key,
        )

        assert "tire, sledgehammer" in COMMERCIAL_GYM_DEFAULT_EQUIPMENT
        assert split_equipment_entries(["tire, sledgehammer"]) == [
            "tire", "sledgehammer",
        ]
        # ...and it must not survive as a bogus single implement.
        assert canonical_equipment_key("tire, sledgehammer") != (
            canonical_equipment_key("tire")
        )

    def test_real_83_entry_inventory_actually_collapses(self):
        """
        Round-1 regression: on the REAL list the dedupe only reached 83 -> 69
        with 'cable machine'/'Cable Pulley Machine' surviving as two items.
        """
        from services.exercise_rag.search import (
            dedupe_equipment, canonical_equipment_key,
        )

        deduped = dedupe_equipment(COMMERCIAL_GYM_DEFAULT_EQUIPMENT)
        keys = [canonical_equipment_key(e) for e in deduped]
        assert len(keys) == len(set(keys)), "residual duplicate canonical keys"
        assert len(deduped) == 60, (
            f"expected 83 -> 60 distinct implements, got {len(deduped)}: "
            f"{deduped}"
        )

        # Named survivors from the reviewer's re-run must be gone.
        lowered = [e.lower() for e in deduped]
        assert lowered.count("cable machine") + lowered.count(
            "cable pulley machine") == 1
        for a, b in [("ez curl bar", "ez bar"),
                     ("lat pulldown", "lat pull down machine"),
                     ("stationary bike", "stationary exercise bike"),
                     ("trx", "suspension trainer")]:
            assert not (a in lowered and b in lowered), (
                f"'{a}' and '{b}' both survived dedupe: {deduped}"
            )


class TestClauseForInventoriesWithoutTheFullGymMarker:
    """
    THE path real gym users take. `commercialGym.defaultEquipment` (83) and the
    GymEquipmentSheet write-back (43) carry NO `full_gym` marker, so they hit
    the dedupe + rank + cap path, and the ranking has to be right for them.
    """

    @pytest.mark.parametrize(
        "name", sorted(INVENTORIES_WITHOUT_FULL_GYM_MARKER),
    )
    def test_does_not_reach_the_full_gym_collapse(self, name):
        from services.exercise_rag.search import build_equipment_clause

        clause = build_equipment_clause(INVENTORIES_WITHOUT_FULL_GYM_MARKER[name])
        assert clause != "Equipment: full gym", (
            f"{name} has no full_gym marker but was collapsed anyway"
        )

    @pytest.mark.parametrize(
        "name", sorted(INVENTORIES_WITHOUT_FULL_GYM_MARKER),
    )
    def test_capped_and_noise_free(self, name):
        from services.exercise_rag.search import (
            build_equipment_clause, MAX_EQUIPMENT_TERMS_IN_QUERY,
        )

        clause = build_equipment_clause(INVENTORIES_WITHOUT_FULL_GYM_MARKER[name])
        assert clause.startswith("Equipment: ")
        terms = clause[len("Equipment: "):].split(", ")
        assert len(terms) <= MAX_EQUIPMENT_TERMS_IN_QUERY
        lowered = clause.lower()
        for noise in RETRIEVAL_NOISE_TOKENS:
            assert noise not in lowered, (
                f"{name}: retrieval-noise token '{noise}' reached the query: "
                f"{clause}"
            )

    def test_commercial_gym_83_summary_is_the_primary_implements(self):
        """Exact expected output for the single most common real inventory."""
        from services.exercise_rag.search import build_equipment_clause

        assert build_equipment_clause(COMMERCIAL_GYM_DEFAULT_EQUIPMENT) == (
            "Equipment: barbell, dumbbells, kettlebell, bench, squat rack, "
            "cable machine"
        )

    def test_gym_equipment_sheet_43_summary(self):
        from services.exercise_rag.search import build_equipment_clause

        assert build_equipment_clause(GYM_EQUIPMENT_SHEET_ALL_ITEMS) == (
            "Equipment: dumbbells, kettlebells, barbell, cable machine, bench, "
            "squat rack"
        )

    def test_home_gym_defaults_summary(self):
        from services.exercise_rag.search import build_equipment_clause

        assert build_equipment_clause(HOME_GYM_DEFAULT_EQUIPMENT) == (
            "Equipment: barbell, dumbbells, kettlebells, pull up bar, "
            "adjustable bench, squat rack"
        )

    def test_unknown_implements_never_displace_known_primaries(self):
        """
        Ranking is an EXACT canonical-key lookup. Substring matching used to
        rank 'samtola (indian barbell)' as a barbell and 'Box' as a plyo box.
        """
        from services.exercise_rag.search import (
            build_equipment_clause, _equipment_relevance_rank,
            _EQUIPMENT_PRIORITY,
        )

        clause = build_equipment_clause(COMMERCIAL_GYM_DEFAULT_EQUIPMENT).lower()
        assert "samtola" not in clause
        assert "box" not in clause
        assert _equipment_relevance_rank("samtola (indian barbell)") == len(
            _EQUIPMENT_PRIORITY
        )
        assert _equipment_relevance_rank("Box") == len(_EQUIPMENT_PRIORITY)
        assert _equipment_relevance_rank("barbell") == 0


class TestFullGymCollapseIsNarrowAndJustified:
    """
    Collapsing to a capability phrase is only lossless where
    `filter_by_equipment` short-circuits availability entirely.
    """

    def test_onboarding_preset_collapses(self):
        from services.exercise_rag.search import build_equipment_clause

        assert build_equipment_clause(ONBOARDING_COMMERCIAL_GYM_PRESET) == (
            "Equipment: full gym"
        )

    def test_bare_full_gym_token_collapses(self):
        from services.exercise_rag.search import build_equipment_clause

        # backend/api/v1/users/models.py:16 sends exactly this.
        assert build_equipment_clause(["full_gym"]) == "Equipment: full gym"

    def test_collapse_matches_the_filter_short_circuit_exactly(self):
        """
        The clause may only collapse for inventories the equipment filter
        unconditionally passes. Anything the filter still enforces must not.
        """
        from services.exercise_rag.search import (
            build_equipment_clause, _FULL_GYM_MARKERS,
        )
        from services.exercise_rag.filters import filter_by_equipment

        assert _FULL_GYM_MARKERS == ("full gym",), (
            "markers must mirror filters.filter_by_equipment's has_full_gym test"
        )
        # A full-gym user genuinely passes everything, so nothing is lost.
        for exotic in ("Assault Bike", "Balance Board", "landmine",
                       "gada (mace)", "Hammer Strength Machines"):
            assert filter_by_equipment(exotic, ["full_gym"], "Some Exercise")

        # "commercial_gym" is NOT short-circuited by the filter, so it must not
        # collapse either.
        clause = build_equipment_clause(["commercial_gym", "dumbbells", "bench"])
        assert clause != "Equipment: full gym"
        assert "dumbbells" in clause


class TestHomeGymKeepsItsSignal:
    """
    filters.py:723-733 EXPANDS 'home_gym' to HOME_EQUIPPED_EQUIPMENT and then
    enforces every entry — there is no `return True` short-circuit — so
    collapsing it to "Equipment: home gym" discards signal the filter needs.
    """

    def test_home_gym_is_not_collapsed_to_a_phrase(self):
        from services.exercise_rag.search import build_equipment_clause

        clause = build_equipment_clause(["home_gym"])
        assert clause != "Equipment: home gym"
        assert clause.count(",") >= 3, f"expected an enumeration, got {clause}"

    def test_home_gym_expansion_matches_what_the_filter_enforces(self):
        from services.exercise_rag.search import (
            build_equipment_clause, canonical_equipment_key,
        )
        from services.exercise_rag.filters import HOME_EQUIPPED_EQUIPMENT

        clause = build_equipment_clause(["home_gym"])
        terms = clause[len("Equipment: "):].split(", ")
        enforced = {canonical_equipment_key(e) for e in HOME_EQUIPPED_EQUIPMENT}
        for term in terms:
            assert canonical_equipment_key(term) in enforced, (
                f"'{term}' is not in the set filter_by_equipment enforces for "
                f"a home_gym user"
            )
        # Every emitted term must actually pass the downstream filter.
        from services.exercise_rag.filters import filter_by_equipment
        for term in terms:
            assert filter_by_equipment(term, ["home_gym"], "Some Exercise"), (
                f"clause advertises '{term}' but the filter rejects it"
            )

    def test_home_gym_plus_explicit_extras_keeps_the_extras(self):
        """A cable machine the user really has must not vanish from the query."""
        from services.exercise_rag.search import build_equipment_clause

        clause = build_equipment_clause(["home_gym", "cable_machine"])
        assert "cable machine" in clause.lower()

    def test_bare_home_gym_token_still_produces_useful_terms(self):
        from services.exercise_rag.search import build_equipment_clause

        # backend/api/v1/users/models.py:18 sends exactly this.
        clause = build_equipment_clause(["home_gym"]).lower()
        assert "dumbbell" in clause
        assert "bench" in clause


class TestNoFabricatedCapability:
    """
    An inventory that is non-empty but unparseable means UNKNOWN. Claiming
    "Equipment: bodyweight" would be a fabrication, because
    `filter_by_equipment` still treats such a user as EQUIPPED.
    """

    def test_unparseable_inventory_emits_no_clause(self):
        from services.exercise_rag.search import (
            build_equipment_clause, equipment_query_clause,
        )

        for junk in (["___"], ["___", "..."], ["!!!", "###"]):
            assert build_equipment_clause(junk) == ""
            assert equipment_query_clause(junk) == ""

    def test_the_filter_really_treats_such_a_user_as_equipped(self):
        """Proof that 'bodyweight' would have been a lie, not a safe default."""
        from services.exercise_rag.filters import filter_by_equipment

        # Equipped user + strength goal => generic bodyweight move is REJECTED.
        assert filter_by_equipment(
            "bodyweight", ["___"], "Burpee", goals=["strength"]
        ) is False
        # A genuinely bodyweight-only user gets it.
        assert filter_by_equipment(
            "bodyweight", ["bodyweight"], "Burpee", goals=["strength"]
        ) is True

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_query_omits_the_clause_entirely(self, mock_keywords):
        mock_keywords.return_value = {}
        from services.exercise_rag.search import build_search_query

        query = build_search_query(
            focus_area="lower", equipment=["___"],
            fitness_level="beginner", goals=[],
        )
        assert "Equipment:" not in query
        assert "  " not in query, f"empty part left a double space: {query!r}"
        assert "Fitness level: beginner" in query

    def test_truly_empty_inventory_is_bodyweight(self):
        """Empty/None/bodyweight tokens ARE an honest bodyweight declaration."""
        from services.exercise_rag.search import equipment_query_clause

        for equipment in ([], None, ["bodyweight"], ["body weight", "none"]):
            assert equipment_query_clause(equipment) == "Equipment: bodyweight"


class TestClauseIsTheOneUsedInTheQuery:
    """
    service.py logs `equipment_query_clause(equipment)`; that must be the
    verbatim substring embedded in the query, on BOTH branches — the round-1
    detector recomputed a different string and printed a bogus percentage.
    """

    ALL_REAL_INVENTORIES = {
        "commercial83": COMMERCIAL_GYM_DEFAULT_EQUIPMENT,
        "sheet43": GYM_EQUIPMENT_SHEET_ALL_ITEMS,
        "onboarding88": ONBOARDING_COMMERCIAL_GYM_PRESET,
        "homegym12": HOME_GYM_DEFAULT_EQUIPMENT,
        "full_gym_token": ["full_gym"],
        "home_gym_token": ["home_gym"],
        "bodyweight_token": ["bodyweight"],
        "empty": [],
    }

    @pytest.mark.parametrize("name", sorted(ALL_REAL_INVENTORIES))
    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_clause_is_a_substring_of_the_query(self, mock_keywords, name):
        mock_keywords.return_value = {}
        from services.exercise_rag.search import (
            build_search_query, equipment_query_clause,
        )

        equipment = self.ALL_REAL_INVENTORIES[name]
        query = build_search_query("lower", equipment, "beginner", ["Build Muscle"])
        clause = equipment_query_clause(equipment)
        assert clause, f"{name} produced no clause"
        assert clause in query, (
            f"{name}: logged clause {clause!r} is not in the query {query!r}"
        )

    def test_service_imports_the_shared_helper(self):
        """service.py must not recompute its own clause."""
        from pathlib import Path

        src = (
            Path(__file__).resolve().parents[3]
            / "services" / "exercise_rag" / "service.py"
        ).read_text()
        assert "equipment_query_clause(equipment)" in src
        assert "len(build_equipment_clause(equipment))" not in src


class TestEquipmentClauseDoesNotFloodQuery:
    """
    Regression tests for the equipment-dominated embedding bug.

    The ChromaDB search is a VECTOR similarity search: the old
    `f"Equipment: {', '.join(equipment)}"` dumped the whole inventory next to a
    ~12-word focus phrase, so the embedding pointed at equipment nouns. A
    beginner commercial-gym user asking for `lower` got "Assault Airbike
    Sprint", "Balance Board Lateral Squat", "Band Squat Row" — every pick
    matched an equipment token, not the movement.
    """

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_real_83_entry_query_is_not_equipment_dominated(self, mock_keywords):
        mock_keywords.return_value = {}
        from services.exercise_rag.search import (
            build_search_query, equipment_query_clause, FOCUS_AREA_KEYWORDS,
        )

        equipment = COMMERCIAL_GYM_DEFAULT_EQUIPMENT
        query = build_search_query("lower", equipment, "beginner", ["Build Muscle"])

        focus_words = FOCUS_AREA_KEYWORDS["lower"].split()
        equipment_words = equipment_query_clause(equipment).split()

        # Measured: 11 focus words vs 9 equipment words (was ~12 vs ~90).
        assert len(equipment_words) <= len(focus_words), (
            f"{len(equipment_words)} equipment words vs {len(focus_words)} "
            f"focus words: {query}"
        )
        # The raw dump for this inventory is >900 chars.
        assert len(", ".join(equipment)) > 900
        assert len(query) < 300, f"query is {len(query)} chars: {query}"
        for movement in ("squats", "lunges", "deadlifts", "glutes", "hamstrings"):
            assert movement in query.lower()

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_no_gym_inventory_produces_a_dump(self, mock_keywords):
        mock_keywords.return_value = {}
        from services.exercise_rag.search import build_search_query

        for name, equipment in list(INVENTORIES_WITHOUT_FULL_GYM_MARKER.items()) + [
            ("onboarding preset", ONBOARDING_COMMERCIAL_GYM_PRESET),
        ]:
            query = build_search_query(
                "lower", equipment, "beginner", ["Build Muscle"],
            )
            assert len(query) < 300, f"{name}: {len(query)} chars: {query}"

    def test_short_inventory_is_preserved_verbatim(self):
        """Normal users keep their exact (deduped) equipment terms."""
        from services.exercise_rag.search import build_equipment_clause

        assert build_equipment_clause(["Dumbbells", "Bench"]) == (
            "Equipment: Dumbbells, Bench"
        )

    @patch('services.exercise_rag.search.get_training_program_keywords_sync')
    def test_bodyweight_only_branch_unchanged(self, mock_keywords):
        """The bodyweight-only branch must not regress."""
        mock_keywords.return_value = {}

        from services.exercise_rag.search import build_search_query

        for equipment in ([], ["Bodyweight"], ["body weight", "none"]):
            query = build_search_query(
                focus_area="full_body",
                equipment=equipment,
                fitness_level="beginner",
                goals=[],
            )
            assert "Equipment: bodyweight" in query
            assert "calisthenics" in query.lower()
            assert "no equipment" in query.lower()
            assert "Fitness level: beginner" in query

    def test_canonical_key_handles_garbage_input(self):
        """None / empty / punctuation-only entries are dropped, not crashed on."""
        from services.exercise_rag.search import (
            canonical_equipment_key, dedupe_equipment, build_equipment_clause,
        )

        assert canonical_equipment_key(None) == ""
        assert canonical_equipment_key("   ") == ""
        assert canonical_equipment_key("---") == ""
        assert dedupe_equipment([None, "", "  ", "___"]) == []
        # Nothing parseable and nothing declared -> no clause, no fabrication.
        assert build_equipment_clause([None, ""]) == ""


class TestFocusAreaKeywords:
    """Tests for FOCUS_AREA_KEYWORDS constant."""

    def test_contains_body_parts(self):
        """Test that common body parts are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        expected_areas = ["full_body", "chest", "back", "legs", "core"]
        # Note: FOCUS_AREA_KEYWORDS might not have all these, but should have focus areas
        assert "full_body" in FOCUS_AREA_KEYWORDS
        assert "boxing" in FOCUS_AREA_KEYWORDS

    def test_contains_sports(self):
        """Test that sport-specific areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "boxing" in FOCUS_AREA_KEYWORDS
        assert "hyrox" in FOCUS_AREA_KEYWORDS
        assert "crossfit" in FOCUS_AREA_KEYWORDS

    def test_contains_upper_lower_split(self):
        """Test that upper/lower split focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "upper" in FOCUS_AREA_KEYWORDS
        assert "lower" in FOCUS_AREA_KEYWORDS
        assert "upper body" in FOCUS_AREA_KEYWORDS["upper"].lower()
        assert "lower body" in FOCUS_AREA_KEYWORDS["lower"].lower()

    def test_contains_ppl_split(self):
        """Test that push/pull/legs split focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "push" in FOCUS_AREA_KEYWORDS
        assert "pull" in FOCUS_AREA_KEYWORDS
        assert "legs" in FOCUS_AREA_KEYWORDS
        assert "chest" in FOCUS_AREA_KEYWORDS["push"].lower()
        assert "back" in FOCUS_AREA_KEYWORDS["pull"].lower()

    def test_contains_phul_focus_areas(self):
        """Test that PHUL focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "upper_power" in FOCUS_AREA_KEYWORDS
        assert "lower_power" in FOCUS_AREA_KEYWORDS
        assert "upper_hypertrophy" in FOCUS_AREA_KEYWORDS
        assert "lower_hypertrophy" in FOCUS_AREA_KEYWORDS

    def test_contains_arnold_split(self):
        """Test that Arnold split focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "chest_back" in FOCUS_AREA_KEYWORDS
        assert "shoulders_arms" in FOCUS_AREA_KEYWORDS

    def test_contains_bro_split(self):
        """Test that bro split / body part focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "chest" in FOCUS_AREA_KEYWORDS
        assert "back" in FOCUS_AREA_KEYWORDS
        assert "shoulders" in FOCUS_AREA_KEYWORDS
        assert "arms" in FOCUS_AREA_KEYWORDS

    def test_contains_hyrox_variants(self):
        """Test that HYROX-specific focus areas are included."""
        from services.exercise_rag.search import FOCUS_AREA_KEYWORDS

        assert "hyrox_strength" in FOCUS_AREA_KEYWORDS
        assert "hyrox_running" in FOCUS_AREA_KEYWORDS
        assert "hyrox_stations" in FOCUS_AREA_KEYWORDS
        assert "hyrox_endurance" in FOCUS_AREA_KEYWORDS
        assert "hyrox_simulation" in FOCUS_AREA_KEYWORDS


class TestGoalKeywords:
    """Tests for GOAL_KEYWORDS constant."""

    def test_contains_common_goals(self):
        """Test that common goals are included."""
        from services.exercise_rag.search import GOAL_KEYWORDS

        assert "Build Muscle" in GOAL_KEYWORDS
        assert "Lose Weight" in GOAL_KEYWORDS
        assert "Increase Strength" in GOAL_KEYWORDS
        assert "Improve Endurance" in GOAL_KEYWORDS
        assert "General Fitness" in GOAL_KEYWORDS

    def test_goal_values_are_strings(self):
        """Test that goal keywords are strings."""
        from services.exercise_rag.search import GOAL_KEYWORDS

        for goal, keywords in GOAL_KEYWORDS.items():
            assert isinstance(keywords, str)
            assert len(keywords) > 0
