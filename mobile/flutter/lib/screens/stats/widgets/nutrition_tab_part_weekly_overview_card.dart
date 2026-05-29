part of 'nutrition_tab.dart';

// The Weekly Overview, Calorie Trend, and Macro Breakdown cards (and the TDEE
// card) that previously lived here as private classes have been promoted to
// reusable public widgets under lib/widgets/nutrition_stats/ so both the
// /stats Nutrition tab and the Nutrition tab's "Nutrition stats" section share
// one implementation:
//   - WeeklyOverviewCard  → lib/widgets/nutrition_stats/weekly_overview_card.dart
//   - CalorieTrendCard     → lib/widgets/nutrition_stats/calorie_trend_card.dart
//   - MacroBreakdownCard   → lib/widgets/nutrition_stats/macro_breakdown_card.dart
//   - TDEECard             → lib/widgets/nutrition_stats/tdee_card.dart
//
// nutrition_tab.dart imports those widgets directly. This part file is kept as
// an (intentionally empty) part so the existing `part` directive stays valid.
