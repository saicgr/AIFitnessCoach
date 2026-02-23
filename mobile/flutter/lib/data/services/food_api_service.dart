import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/database.dart';
import '../local/database_provider.dart';

/// Service for fetching food data from online APIs.
///
/// Sources:
/// - Open Food Facts (free, 4M+ products, barcode support)
/// - USDA FoodData Central API (lab-tested nutrition data)
///
/// Every API result is cached locally for offline access.
class FoodApiService {
  final Dio _dio;
  final AppDatabase _db;

  static const String _openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v2';
  static const String _usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _usdaApiKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: 'DEMO_KEY',
  );

  FoodApiService(this._dio, this._db);

  /// Search Open Food Facts by text query.
  Future<List<CachedFood>> searchOpenFoodFacts(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '$_openFoodFactsBaseUrl/search',
        queryParameters: {
          'search_terms': query,
          'page_size': limit,
          'fields':
              'code,product_name,brands,nutriments,serving_size,image_front_small_url,categories_tags',
          'json': 1,
        },
      );

      if (response.statusCode == 200) {
        final products = response.data['products'] as List? ?? [];
        final results = <CachedFood>[];

        for (final product in products) {
          final p = product as Map<String, dynamic>;
          final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};

          final companion = CachedFoodsCompanion.insert(
            externalId: (p['code'] ?? '').toString(),
            description:
                (p['product_name'] ?? 'Unknown Product') as String,
            foodCategory: Value(_extractCategory(p['categories_tags'])),
            source: const Value('openfoodfacts'),
            barcode: Value(p['code']?.toString()),
            brandName: Value(p['brands']?.toString()),
            servingSizeG:
                Value(_parseDouble(p['serving_size']) ?? 100.0),
            householdServing: Value(p['serving_size']?.toString()),
            calories: Value(_parseDouble(
                    nutriments['energy-kcal_serving'] ??
                        nutriments['energy-kcal_100g']) ??
                0),
            proteinG: Value(_parseDouble(nutriments['proteins_serving'] ??
                    nutriments['proteins_100g']) ??
                0),
            fatG: Value(_parseDouble(
                    nutriments['fat_serving'] ?? nutriments['fat_100g']) ??
                0),
            carbsG: Value(_parseDouble(
                    nutriments['carbohydrates_serving'] ??
                        nutriments['carbohydrates_100g']) ??
                0),
            fiberG: Value(_parseDouble(nutriments['fiber_serving'] ??
                    nutriments['fiber_100g']) ??
                0),
            sugarG: Value(_parseDouble(nutriments['sugars_serving'] ??
                    nutriments['sugars_100g']) ??
                0),
            sodiumMg: Value((_parseDouble(nutriments['sodium_serving'] ??
                        nutriments['sodium_100g']) ??
                    0) *
                1000),
            imageUrl: Value(p['image_front_small_url']?.toString()),
            cachedAt: DateTime.now(),
          );

          await _db.foodDao.upsertFood(companion);
          final cached = await _db.foodDao
              .getByExternalId(p['code'].toString(), 'openfoodfacts');
          if (cached != null) results.add(cached);
        }

        debugPrint(
            '✅ [FoodAPI] Found ${results.length} results from Open Food Facts');
        return results;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [FoodAPI] Open Food Facts search error: $e');
      return [];
    }
  }

  /// Look up food by barcode (Open Food Facts).
  Future<CachedFood?> lookupBarcode(String barcode) async {
    // Check local cache first
    final cached = await _db.foodDao.getByBarcode(barcode);
    if (cached != null) {
      debugPrint('✅ [FoodAPI] Barcode $barcode found in cache');
      return cached;
    }

    try {
      final response = await _dio.get(
        '$_openFoodFactsBaseUrl/product/$barcode',
        queryParameters: {
          'fields':
              'code,product_name,brands,nutriments,serving_size,image_front_small_url,categories_tags',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 1) {
        final p = response.data['product'] as Map<String, dynamic>;
        final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};

        final companion = CachedFoodsCompanion.insert(
          externalId: barcode,
          description:
              (p['product_name'] ?? 'Unknown Product') as String,
          foodCategory: Value(_extractCategory(p['categories_tags'])),
          source: const Value('openfoodfacts'),
          barcode: Value(barcode),
          brandName: Value(p['brands']?.toString()),
          servingSizeG:
              Value(_parseDouble(p['serving_size']) ?? 100.0),
          householdServing: Value(p['serving_size']?.toString()),
          calories: Value(_parseDouble(
                  nutriments['energy-kcal_serving'] ??
                      nutriments['energy-kcal_100g']) ??
              0),
          proteinG: Value(_parseDouble(nutriments['proteins_serving'] ??
                  nutriments['proteins_100g']) ??
              0),
          fatG: Value(_parseDouble(
                  nutriments['fat_serving'] ?? nutriments['fat_100g']) ??
              0),
          carbsG: Value(_parseDouble(
                  nutriments['carbohydrates_serving'] ??
                      nutriments['carbohydrates_100g']) ??
              0),
          fiberG: Value(_parseDouble(nutriments['fiber_serving'] ??
                  nutriments['fiber_100g']) ??
              0),
          sugarG: Value(_parseDouble(nutriments['sugars_serving'] ??
                  nutriments['sugars_100g']) ??
              0),
          sodiumMg: Value((_parseDouble(nutriments['sodium_serving'] ??
                      nutriments['sodium_100g']) ??
                  0) *
              1000),
          imageUrl: Value(p['image_front_small_url']?.toString()),
          cachedAt: DateTime.now(),
        );

        await _db.foodDao.upsertFood(companion);
        return _db.foodDao.getByBarcode(barcode);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [FoodAPI] Barcode lookup error: $e');
      return null;
    }
  }

  /// Search USDA FoodData Central.
  Future<List<CachedFood>> searchUSDA(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '$_usdaBaseUrl/foods/search',
        queryParameters: {
          'api_key': _usdaApiKey,
          'query': query,
          'pageSize': limit,
          'dataType': 'SR Legacy,Foundation',
        },
      );

      if (response.statusCode == 200) {
        final foods = response.data['foods'] as List? ?? [];
        final results = <CachedFood>[];

        for (final food in foods) {
          final f = food as Map<String, dynamic>;
          final nutrients =
              _extractUSDANutrients(f['foodNutrients'] as List? ?? []);

          final companion = CachedFoodsCompanion.insert(
            externalId: f['fdcId'].toString(),
            description: f['description'] as String? ?? 'Unknown',
            foodCategory: Value(f['foodCategory'] as String?),
            source: const Value('usda'),
            servingSizeG: const Value(100.0),
            calories: Value(nutrients['energy'] ?? 0),
            proteinG: Value(nutrients['protein'] ?? 0),
            fatG: Value(nutrients['fat'] ?? 0),
            carbsG: Value(nutrients['carbs'] ?? 0),
            fiberG: Value(nutrients['fiber'] ?? 0),
            sugarG: Value(nutrients['sugars'] ?? 0),
            sodiumMg: Value(nutrients['sodium'] ?? 0),
            cachedAt: DateTime.now(),
          );

          await _db.foodDao.upsertFood(companion);
          final cached = await _db.foodDao
              .getByExternalId(f['fdcId'].toString(), 'usda');
          if (cached != null) results.add(cached);
        }

        debugPrint(
            '✅ [FoodAPI] Found ${results.length} results from USDA');
        return results;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [FoodAPI] USDA search error: $e');
      return [];
    }
  }

  Map<String, double> _extractUSDANutrients(List<dynamic> nutrients) {
    final result = <String, double>{};
    for (final n in nutrients) {
      final nutrient = n as Map<String, dynamic>;
      final name = nutrient['nutrientName'] as String? ?? '';
      final value = (nutrient['value'] as num?)?.toDouble() ?? 0;
      if (name.contains('Energy')) result['energy'] = value;
      if (name.contains('Protein')) result['protein'] = value;
      if (name == 'Total lipid (fat)') result['fat'] = value;
      if (name.contains('Carbohydrate')) result['carbs'] = value;
      if (name.contains('Fiber')) result['fiber'] = value;
      if (name.contains('Sugars, total')) result['sugars'] = value;
      if (name.contains('Sodium')) result['sodium'] = value;
    }
    return result;
  }

  String? _extractCategory(dynamic categoriesTags) {
    if (categoriesTags is List && categoriesTags.isNotEmpty) {
      final tag = categoriesTags.first.toString();
      return tag.replaceAll('en:', '').replaceAll('-', ' ');
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final numStr = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numStr);
    }
    return null;
  }
}

final foodApiServiceProvider = Provider<FoodApiService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  final db = ref.watch(appDatabaseProvider);
  return FoodApiService(dio, db);
});
