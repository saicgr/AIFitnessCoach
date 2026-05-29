part of 'nutrition_tab.dart';

// The Adherence & Consistency card that previously lived here as a private
// class has been promoted to a reusable public widget so both the /stats
// Nutrition tab and the Nutrition tab's "Nutrition stats" section share one
// implementation:
//   - AdherenceCard → lib/widgets/nutrition_stats/adherence_card.dart
//
// nutrition_tab.dart imports it directly. This part file is kept as an
// (intentionally empty) part so the existing `part` directive stays valid.
