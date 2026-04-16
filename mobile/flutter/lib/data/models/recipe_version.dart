/// Recipe version history + diff models.
library;

class RecipeVersionSummary {
  final String id;
  final String recipeId;
  final int versionNumber;
  final String? changeSummary;
  final String? editedBy;
  final DateTime editedAt;

  const RecipeVersionSummary({
    required this.id,
    required this.recipeId,
    required this.versionNumber,
    required this.editedAt,
    this.changeSummary,
    this.editedBy,
  });

  factory RecipeVersionSummary.fromJson(Map<String, dynamic> j) => RecipeVersionSummary(
        id: j['id'] as String,
        recipeId: j['recipe_id'] as String,
        versionNumber: j['version_number'] as int,
        changeSummary: j['change_summary'] as String?,
        editedBy: j['edited_by'] as String?,
        editedAt: DateTime.parse(j['edited_at'] as String),
      );
}

class RecipeVersionsResponse {
  final List<RecipeVersionSummary> items;
  final int totalCount;
  final int currentVersion;

  const RecipeVersionsResponse({
    required this.items,
    required this.totalCount,
    required this.currentVersion,
  });

  factory RecipeVersionsResponse.fromJson(Map<String, dynamic> j) => RecipeVersionsResponse(
        items: (j['items'] as List? ?? [])
            .map((e) => RecipeVersionSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: j['total_count'] as int? ?? 0,
        currentVersion: j['current_version'] as int? ?? 0,
      );
}

class FieldDiff {
  final String field;
  final dynamic before;
  final dynamic after;
  const FieldDiff({required this.field, this.before, this.after});
  factory FieldDiff.fromJson(Map<String, dynamic> j) =>
      FieldDiff(field: j['field'] as String, before: j['before'], after: j['after']);
}

class IngredientDiff {
  final String change; // added | removed | modified
  final String foodName;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  const IngredientDiff({required this.change, required this.foodName, this.before, this.after});
  factory IngredientDiff.fromJson(Map<String, dynamic> j) => IngredientDiff(
        change: j['change'] as String,
        foodName: j['food_name'] as String,
        before: (j['before'] as Map?)?.cast<String, dynamic>(),
        after: (j['after'] as Map?)?.cast<String, dynamic>(),
      );
}

class RecipeDiff {
  final int fromVersion;
  final int toVersion;
  final List<FieldDiff> fieldDiffs;
  final List<IngredientDiff> ingredientDiffs;

  const RecipeDiff({
    required this.fromVersion,
    required this.toVersion,
    required this.fieldDiffs,
    required this.ingredientDiffs,
  });

  factory RecipeDiff.fromJson(Map<String, dynamic> j) => RecipeDiff(
        fromVersion: j['from_version'] as int,
        toVersion: j['to_version'] as int,
        fieldDiffs: (j['field_diffs'] as List? ?? [])
            .map((e) => FieldDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
        ingredientDiffs: (j['ingredient_diffs'] as List? ?? [])
            .map((e) => IngredientDiff.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RecipeRevertResponse {
  final bool success;
  final int newCurrentVersion;
  final String message;
  final int schedulesUsingRecipeCount;

  const RecipeRevertResponse({
    required this.success,
    required this.newCurrentVersion,
    required this.message,
    this.schedulesUsingRecipeCount = 0,
  });

  factory RecipeRevertResponse.fromJson(Map<String, dynamic> j) => RecipeRevertResponse(
        success: j['success'] as bool? ?? false,
        newCurrentVersion: j['new_current_version'] as int? ?? 0,
        message: (j['message'] ?? '') as String,
        schedulesUsingRecipeCount: j['schedules_using_recipe_count'] as int? ?? 0,
      );
}
