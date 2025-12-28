import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../repositories/nutrition_repository.dart';

/// Headless service for widget actions (no UI dependencies)
/// Can run without BuildContext - perfect for background Flutter engine
class WidgetActionHeadlessService {
  static const platform = MethodChannel('com.aifitnesscoach.app/widget_actions');

  final Ref _ref;
  bool _initialized = false;

  WidgetActionHeadlessService(this._ref);

  /// Initialize the service (call at app startup)
  void initialize() {
    if (!_initialized) {
      platform.setMethodCallHandler(_handleMethodCall);
      _initialized = true;
      debugPrint('✅ [WidgetHeadless] Service initialized for native widget actions');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('🔔 [WidgetHeadless] Received: ${call.method}');

    try {
      switch (call.method) {
        case 'logMealFromText':
          return await _logMealFromText(call.arguments);
        case 'logMealFromImage':
          return await _logMealFromImage(call.arguments);
        case 'logMealFromBarcode':
          return await _logMealFromBarcode(call.arguments);
        case 'lookupBarcode':
          return await _lookupBarcode(call.arguments);
        case 'getUserId':
          return await _getUserId();
        default:
          throw PlatformException(
            code: 'NOT_IMPLEMENTED',
            message: 'Method ${call.method} not implemented',
          );
      }
    } catch (e, stack) {
      debugPrint('❌ [WidgetHeadless] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _logMealFromText(dynamic args) async {
    final data = args as Map<dynamic, dynamic>;
    final userId = data['userId'] as String;
    final description = data['description'] as String;
    final mealType = data['mealType'] as String;

    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromText(
        userId: userId,
        description: description,
        mealType: mealType,
      );

      return {
        'success': true,
        'calories': response.totalCalories,
        'protein': response.proteinG,
        'carbs': response.carbsG,
        'fat': response.fatG,
        'productName': description,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _lookupBarcode(dynamic args) async {
    final data = args as Map<dynamic, dynamic>;
    final barcode = data['barcode'] as String;

    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      final product = await repository.lookupBarcode(barcode);

      return {
        'success': true,
        'productName': product.productName,
        'brand': product.brand ?? '',
        'calories': product.caloriesPer100g.toInt(),
        'protein': product.proteinPer100g,
        'carbs': product.carbsPer100g,
        'fat': product.fatPer100g,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _logMealFromBarcode(dynamic args) async {
    final data = args as Map<dynamic, dynamic>;
    final userId = data['userId'] as String;
    final barcode = data['barcode'] as String;
    final mealType = data['mealType'] as String;

    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromBarcode(
        userId: userId,
        barcode: barcode,
        mealType: mealType,
      );

      return {
        'success': true,
        'productName': response.productName,
        'calories': response.totalCalories,
        'protein': response.proteinG,
        'carbs': response.carbsG,
        'fat': response.fatG,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _logMealFromImage(dynamic args) async {
    final data = args as Map<dynamic, dynamic>;
    final userId = data['userId'] as String;
    final imagePath = data['imagePath'] as String;
    final mealType = data['mealType'] as String;

    try {
      final repository = _ref.read(nutritionRepositoryProvider);
      final response = await repository.logFoodFromImage(
        userId: userId,
        mealType: mealType,
        imageFile: File(imagePath),
      );

      // Extract food description from AI-identified items
      final foodDescription = response.foodItems
          .map((item) => item['name'] as String)
          .join(', ');

      return {
        'success': true,
        'productName': foodDescription,
        'calories': response.totalCalories,
        'protein': response.proteinG,
        'carbs': response.carbsG,
        'fat': response.fatG,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<String> _getUserId() async {
    // Query secure storage for current user ID
    // Use AndroidOptions to ensure we can read the same storage as ApiClient
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
    final userId = await secureStorage.read(key: 'user_id');

    debugPrint('🔍 [WidgetHeadless] getUserId called, result: ${userId != null ? "found" : "null"}');

    if (userId == null || userId.isEmpty) {
      throw PlatformException(
        code: 'NOT_LOGGED_IN',
        message: 'User not logged in',
      );
    }
    return userId;
  }
}

/// Provider for headless widget service
final widgetActionHeadlessServiceProvider = Provider<WidgetActionHeadlessService>((ref) {
  return WidgetActionHeadlessService(ref);
});
