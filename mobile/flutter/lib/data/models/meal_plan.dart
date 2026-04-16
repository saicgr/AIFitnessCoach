/// Meal plan models — daily planning + simulation + apply-to-today.
library;

import 'scheduled_recipe.dart' show MealSlot;

class MealPlanItem {
  final String id;
  final String planId;
  final MealSlot mealType;
  final int slotOrder;
  final String? recipeId;
  final List<Map<String, dynamic>>? foodItems;
  final double servings;
  final DateTime createdAt;

  const MealPlanItem({
    required this.id,
    required this.planId,
    required this.mealType,
    required this.servings,
    required this.createdAt,
    this.slotOrder = 0,
    this.recipeId,
    this.foodItems,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) => MealPlanItem(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        mealType: MealSlot.fromValue(json['meal_type'] as String?),
        slotOrder: (json['slot_order'] as int?) ?? 0,
        recipeId: json['recipe_id'] as String?,
        foodItems: (json['food_items'] as List?)?.cast<Map<String, dynamic>>(),
        servings: (json['servings'] as num?)?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'meal_type': mealType.value,
        'slot_order': slotOrder,
        'recipe_id': recipeId,
        'food_items': foodItems,
        'servings': servings,
        'created_at': createdAt.toIso8601String(),
      };
}

class MealPlanItemCreate {
  final MealSlot mealType;
  final int slotOrder;
  final String? recipeId;
  final List<Map<String, dynamic>>? foodItems;
  final double servings;

  const MealPlanItemCreate({
    required this.mealType,
    this.slotOrder = 0,
    this.recipeId,
    this.foodItems,
    this.servings = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'meal_type': mealType.value,
        'slot_order': slotOrder,
        if (recipeId != null) 'recipe_id': recipeId,
        if (foodItems != null) 'food_items': foodItems,
        'servings': servings,
      };
}

class MealPlan {
  final String id;
  final String userId;
  final String? name;
  final DateTime? planDate;
  final bool isTemplate;
  final Map<String, dynamic>? targetSnapshot;
  final String? notes;
  final List<MealPlanItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MealPlan({
    required this.id,
    required this.userId,
    required this.isTemplate,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.planDate,
    this.targetSnapshot,
    this.notes,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String?,
        planDate: json['plan_date'] != null ? DateTime.parse(json['plan_date']) : null,
        isTemplate: json['is_template'] as bool? ?? false,
        targetSnapshot: (json['target_snapshot'] as Map?)?.cast<String, dynamic>(),
        notes: json['notes'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => MealPlanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class MealPlanCreate {
  final String? name;
  final DateTime? planDate;
  final bool isTemplate;
  final String? notes;
  final List<MealPlanItemCreate> items;

  const MealPlanCreate({
    this.name,
    this.planDate,
    this.isTemplate = false,
    this.notes,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (planDate != null)
          'plan_date': '${planDate!.year.toString().padLeft(4, '0')}-'
              '${planDate!.month.toString().padLeft(2, '0')}-'
              '${planDate!.day.toString().padLeft(2, '0')}',
        'is_template': isTemplate,
        if (notes != null) 'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class MacroTotals {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  const MacroTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
  });

  factory MacroTotals.fromJson(Map<String, dynamic> json) => MacroTotals(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
        sugarG: (json['sugar_g'] as num?)?.toDouble() ?? 0,
        sodiumMg: (json['sodium_mg'] as num?)?.toDouble() ?? 0,
      );
}

class MacroRemainder {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const MacroRemainder({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
  factory MacroRemainder.fromJson(Map<String, dynamic> json) => MacroRemainder(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      );
}

class AiSwapSuggestion {
  final String? itemId;
  final String fromLabel;
  final String toLabel;
  final String rationale;
  final Map<String, double> deltas;
  final String? newRecipeId;

  const AiSwapSuggestion({
    required this.fromLabel,
    required this.toLabel,
    required this.rationale,
    this.itemId,
    this.deltas = const {},
    this.newRecipeId,
  });

  factory AiSwapSuggestion.fromJson(Map<String, dynamic> json) {
    final deltasRaw = (json['deltas'] as Map?) ?? {};
    return AiSwapSuggestion(
      itemId: json['item_id'] as String?,
      fromLabel: (json['from_label'] ?? '') as String,
      toLabel: (json['to_label'] ?? '') as String,
      rationale: (json['rationale'] ?? '') as String,
      deltas: deltasRaw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      newRecipeId: json['new_recipe_id'] as String?,
    );
  }
}

class SimulateResponse {
  final String planId;
  final MacroTotals totals;
  final Map<String, dynamic> targetSnapshot;
  final MacroRemainder remainder;
  final bool overBudget;
  final Map<String, double> adherencePct;
  final List<AiSwapSuggestion> swapSuggestions;
  final String? coachSummary;

  const SimulateResponse({
    required this.planId,
    required this.totals,
    required this.targetSnapshot,
    required this.remainder,
    required this.overBudget,
    required this.adherencePct,
    required this.swapSuggestions,
    this.coachSummary,
  });

  factory SimulateResponse.fromJson(Map<String, dynamic> json) {
    final adh = (json['adherence_pct'] as Map?) ?? {};
    return SimulateResponse(
      planId: json['plan_id'] as String,
      totals: MacroTotals.fromJson((json['totals'] as Map).cast<String, dynamic>()),
      targetSnapshot: (json['target_snapshot'] as Map?)?.cast<String, dynamic>() ?? {},
      remainder: MacroRemainder.fromJson((json['remainder'] as Map).cast<String, dynamic>()),
      overBudget: json['over_budget'] as bool? ?? false,
      adherencePct: adh.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      swapSuggestions: (json['swap_suggestions'] as List? ?? [])
          .map((e) => AiSwapSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      coachSummary: json['coach_summary'] as String?,
    );
  }
}

class ApplyResponse {
  final String planId;
  final DateTime targetDate;
  final List<String> foodLogIds;
  final int duplicatesSkipped;
  final String? duplicatesWarning;

  const ApplyResponse({
    required this.planId,
    required this.targetDate,
    required this.foodLogIds,
    this.duplicatesSkipped = 0,
    this.duplicatesWarning,
  });

  factory ApplyResponse.fromJson(Map<String, dynamic> json) => ApplyResponse(
        planId: json['plan_id'] as String,
        targetDate: DateTime.parse(json['target_date'] as String),
        foodLogIds: (json['food_log_ids'] as List).map((e) => e as String).toList(),
        duplicatesSkipped: (json['duplicates_skipped'] as int?) ?? 0,
        duplicatesWarning: json['duplicates_warning'] as String?,
      );
}
