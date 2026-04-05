part of 'nutrition_preferences.dart';


// ============================================
// Weekly Nutrition Data (for stats charts)
// ============================================

/// Weekly nutrition data with daily breakdown for charts
class WeeklyNutritionData {
  final String startDate;
  final String endDate;
  final List<DailyNutritionEntry> dailySummaries;
  final int totalCalories;
  final double averageDailyCalories;
  final int totalMeals;

  const WeeklyNutritionData({
    required this.startDate,
    required this.endDate,
    required this.dailySummaries,
    required this.totalCalories,
    required this.averageDailyCalories,
    required this.totalMeals,
  });

  factory WeeklyNutritionData.fromJson(Map<String, dynamic> json) {
    final summaries = (json['daily_summaries'] as List?)
            ?.map((d) => DailyNutritionEntry.fromJson(d as Map<String, dynamic>))
            .toList() ??
        [];

    return WeeklyNutritionData(
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      dailySummaries: summaries,
      totalCalories: json['total_calories'] as int? ?? 0,
      averageDailyCalories:
          (json['average_daily_calories'] as num?)?.toDouble() ?? 0.0,
      totalMeals: json['total_meals'] as int? ?? 0,
    );
  }

  /// Average macros across days with data
  ({double protein, double carbs, double fat}) get averageMacros {
    final daysWithData =
        dailySummaries.where((d) => d.calories > 0).toList();
    if (daysWithData.isEmpty) {
      return (protein: 0.0, carbs: 0.0, fat: 0.0);
    }
    final avgP = daysWithData.fold(0.0, (s, d) => s + d.proteinG) /
        daysWithData.length;
    final avgC =
        daysWithData.fold(0.0, (s, d) => s + d.carbsG) / daysWithData.length;
    final avgF =
        daysWithData.fold(0.0, (s, d) => s + d.fatG) / daysWithData.length;
    return (protein: avgP, carbs: avgC, fat: avgF);
  }

  /// Number of days with logged data
  int get daysWithData =>
      dailySummaries.where((d) => d.calories > 0).length;
}


/// A single day's nutrition entry
class DailyNutritionEntry {
  final String date;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int meals;

  const DailyNutritionEntry({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.meals,
  });

  factory DailyNutritionEntry.fromJson(Map<String, dynamic> json) {
    return DailyNutritionEntry(
      date: json['date'] as String? ?? '',
      calories: (json['total_calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0.0,
      meals: (json['meal_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Day of week abbreviation (Mon, Tue, etc.)
  String get dayLabel {
    try {
      final dt = DateTime.parse(date);
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }
}

