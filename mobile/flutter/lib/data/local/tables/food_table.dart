import 'package:drift/drift.dart';

/// Table for cached food items (both embedded USDA and API-fetched).
class CachedFoods extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// USDA FDC ID or Open Food Facts barcode
  TextColumn get externalId => text()();

  /// Food name/description
  TextColumn get description => text()();

  /// Food category (e.g., "Poultry", "Vegetables")
  TextColumn get foodCategory => text().nullable()();

  /// Source: 'usda', 'openfoodfacts', 'user'
  TextColumn get source => text().withDefault(const Constant('usda'))();

  /// Barcode (EAN/UPC) if from Open Food Facts
  TextColumn get barcode => text().nullable()();

  /// Brand name (for packaged foods)
  TextColumn get brandName => text().nullable()();

  /// Serving size in grams
  RealColumn get servingSizeG =>
      real().withDefault(const Constant(100.0))();

  /// Household serving description (e.g., "1 cup", "1 large")
  TextColumn get householdServing => text().nullable()();

  // Macronutrients (per serving)
  RealColumn get calories => real().withDefault(const Constant(0))();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  RealColumn get carbsG => real().withDefault(const Constant(0))();
  RealColumn get fiberG => real().withDefault(const Constant(0))();
  RealColumn get sugarG => real().withDefault(const Constant(0))();
  RealColumn get sodiumMg => real().withDefault(const Constant(0))();

  // Micronutrients (optional, per serving)
  RealColumn get vitaminAMcg => real().nullable()();
  RealColumn get vitaminCMg => real().nullable()();
  RealColumn get calciumMg => real().nullable()();
  RealColumn get ironMg => real().nullable()();
  RealColumn get potassiumMg => real().nullable()();

  /// Image URL (from Open Food Facts)
  TextColumn get imageUrl => text().nullable()();

  /// Whether this food is in user's favorites
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  /// Last time this food was used (for "recent foods" feature)
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  /// When this record was cached/created
  DateTimeColumn get cachedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {externalId, source}
      ];
}
