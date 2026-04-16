/// Grocery list models — derived from a meal plan or single recipe.
library;

enum Aisle {
  produce('produce', 'Produce'),
  dairy('dairy', 'Dairy'),
  meatSeafood('meat_seafood', 'Meat & Seafood'),
  pantry('pantry', 'Pantry'),
  frozen('frozen', 'Frozen'),
  bakery('bakery', 'Bakery'),
  beverages('beverages', 'Beverages'),
  condiments('condiments', 'Condiments'),
  spices('spices', 'Spices'),
  snacks('snacks', 'Snacks'),
  household('household', 'Household'),
  other('other', 'Other');

  final String value;
  final String label;
  const Aisle(this.value, this.label);
  static Aisle? fromValue(String? v) =>
      v == null ? null : Aisle.values.firstWhere((e) => e.value == v, orElse: () => Aisle.other);
}

class GroceryListItem {
  final String id;
  final String listId;
  final String ingredientName;
  final double? quantity;
  final String? unit;
  final Aisle? aisle;
  final bool isChecked;
  final bool isStapleSuppressed;
  final List<String> sourceRecipeIds;
  final String? notes;

  const GroceryListItem({
    required this.id,
    required this.listId,
    required this.ingredientName,
    this.quantity,
    this.unit,
    this.aisle,
    this.isChecked = false,
    this.isStapleSuppressed = false,
    this.sourceRecipeIds = const [],
    this.notes,
  });

  factory GroceryListItem.fromJson(Map<String, dynamic> json) => GroceryListItem(
        id: json['id'] as String,
        listId: json['list_id'] as String,
        ingredientName: json['ingredient_name'] as String,
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        aisle: Aisle.fromValue(json['aisle'] as String?),
        isChecked: json['is_checked'] as bool? ?? false,
        isStapleSuppressed: json['is_staple_suppressed'] as bool? ?? false,
        sourceRecipeIds:
            (json['source_recipe_ids'] as List?)?.map((e) => e as String).toList() ?? const [],
        notes: json['notes'] as String?,
      );

  GroceryListItem copyWith({bool? isChecked, double? quantity, String? unit, Aisle? aisle, String? notes}) =>
      GroceryListItem(
        id: id,
        listId: listId,
        ingredientName: ingredientName,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        aisle: aisle ?? this.aisle,
        isChecked: isChecked ?? this.isChecked,
        isStapleSuppressed: isStapleSuppressed,
        sourceRecipeIds: sourceRecipeIds,
        notes: notes ?? this.notes,
      );
}

class GroceryList {
  final String id;
  final String userId;
  final String? mealPlanId;
  final String? sourceRecipeId;
  final String? name;
  final String? notes;
  final List<GroceryListItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryList({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.mealPlanId,
    this.sourceRecipeId,
    this.name,
    this.notes,
  });

  factory GroceryList.fromJson(Map<String, dynamic> json) => GroceryList(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mealPlanId: json['meal_plan_id'] as String?,
        sourceRecipeId: json['source_recipe_id'] as String?,
        name: json['name'] as String?,
        notes: json['notes'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => GroceryListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class GroceryListSummary {
  final String id;
  final String? name;
  final int itemCount;
  final int checkedCount;
  final String? mealPlanId;
  final String? sourceRecipeId;
  final DateTime createdAt;

  const GroceryListSummary({
    required this.id,
    required this.itemCount,
    required this.checkedCount,
    required this.createdAt,
    this.name,
    this.mealPlanId,
    this.sourceRecipeId,
  });

  factory GroceryListSummary.fromJson(Map<String, dynamic> json) => GroceryListSummary(
        id: json['id'] as String,
        name: json['name'] as String?,
        itemCount: json['item_count'] as int? ?? 0,
        checkedCount: json['checked_count'] as int? ?? 0,
        mealPlanId: json['meal_plan_id'] as String?,
        sourceRecipeId: json['source_recipe_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class GroceryListCreate {
  final String? mealPlanId;
  final String? sourceRecipeId;
  final String? name;
  final String? notes;
  final bool suppressStaples;

  const GroceryListCreate({
    this.mealPlanId,
    this.sourceRecipeId,
    this.name,
    this.notes,
    this.suppressStaples = true,
  });

  Map<String, dynamic> toJson() => {
        if (mealPlanId != null) 'meal_plan_id': mealPlanId,
        if (sourceRecipeId != null) 'source_recipe_id': sourceRecipeId,
        if (name != null) 'name': name,
        if (notes != null) 'notes': notes,
        'suppress_staples': suppressStaples,
      };
}
