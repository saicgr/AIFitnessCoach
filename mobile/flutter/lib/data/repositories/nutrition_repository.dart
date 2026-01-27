import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/nutrition.dart';
import '../models/micronutrients.dart';
import '../models/nutrition_preferences.dart';
import '../models/recipe.dart';
import '../services/api_client.dart';

/// Progress event for streaming food logging
class FoodLoggingProgress {
  /// Current step number (1-indexed)
  final int step;

  /// Total number of steps
  final int totalSteps;

  /// Human-readable status message
  final String message;

  /// Additional detail about the current step
  final String? detail;

  /// Time elapsed since start in milliseconds
  final int elapsedMs;

  /// The logged food response (only set when complete)
  final LogFoodResponse? foodLog;

  /// Whether logging completed successfully
  final bool isCompleted;

  /// Whether an error occurred
  final bool hasError;

  /// Whether this is an analysis-only result (not yet saved to database)
  final bool isAnalysisOnly;

  FoodLoggingProgress({
    required this.step,
    required this.totalSteps,
    required this.message,
    this.detail,
    required this.elapsedMs,
    this.foodLog,
    this.isCompleted = false,
    this.hasError = false,
    this.isAnalysisOnly = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progress => totalSteps > 0 ? step / totalSteps : 0;

  /// Whether logging is still in progress
  bool get isLoading => !isCompleted && !hasError;

  @override
  String toString() => 'FoodLoggingProgress(step: $step/$totalSteps, message: $message, elapsedMs: $elapsedMs)';
}

/// Nutrition repository provider
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider));
});

/// Nutrition state
class NutritionState {
  final bool isLoading;
  final String? error;
  final DailyNutritionSummary? todaySummary;
  final NutritionTargets? targets;
  final List<FoodLog> recentLogs;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.todaySummary,
    this.targets,
    this.recentLogs = const [],
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    DailyNutritionSummary? todaySummary,
    NutritionTargets? targets,
    List<FoodLog>? recentLogs,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaySummary: todaySummary ?? this.todaySummary,
      targets: targets ?? this.targets,
      recentLogs: recentLogs ?? this.recentLogs,
    );
  }
}

/// Nutrition state provider
final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref.watch(nutritionRepositoryProvider));
});

/// Nutrition state notifier
class NutritionNotifier extends StateNotifier<NutritionState> {
  final NutritionRepository _repository;
  String? _lastLoadedUserId;  // Track which user data is loaded for
  DateTime? _lastLoadTime;     // Track when data was last loaded

  NutritionNotifier(this._repository) : super(const NutritionState());

  /// Check if we should skip loading (data is fresh - less than 5 minutes old)
  bool _shouldSkipLoad(String userId) {
    if (_lastLoadedUserId != userId) return false;
    if (_lastLoadTime == null) return false;
    final elapsed = DateTime.now().difference(_lastLoadTime!);
    return elapsed.inMinutes < 5;  // Cache for 5 minutes to improve navigation speed
  }

  /// Load today's nutrition summary
  Future<void> loadTodaySummary(String userId, {bool forceRefresh = false}) async {
    // Skip if data is fresh (prevents redundant calls on tab switch)
    if (!forceRefresh && _shouldSkipLoad(userId) && state.todaySummary != null) {
      debugPrint('🥗 [NutritionProvider] Skipping loadTodaySummary - data is fresh');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _repository.getDailySummary(userId);
      state = state.copyWith(isLoading: false, todaySummary: summary);
      _lastLoadedUserId = userId;
      _lastLoadTime = DateTime.now();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load nutrition targets
  Future<void> loadTargets(String userId, {bool forceRefresh = false}) async {
    // Skip if data is fresh
    if (!forceRefresh && _shouldSkipLoad(userId) && state.targets != null) {
      return;
    }

    try {
      final targets = await _repository.getTargets(userId);
      state = state.copyWith(targets: targets);
    } catch (e) {
      debugPrint('Error loading nutrition targets: $e');
    }
  }

  /// Load recent food logs
  Future<void> loadRecentLogs(String userId, {int limit = 50, bool forceRefresh = false}) async {
    // Skip if data is fresh
    if (!forceRefresh && _shouldSkipLoad(userId) && state.recentLogs.isNotEmpty) {
      debugPrint('🥗 [NutritionProvider] Skipping loadRecentLogs - data is fresh');
      return;
    }

    try {
      final logs = await _repository.getFoodLogs(userId, limit: limit);
      state = state.copyWith(recentLogs: logs);
    } catch (e) {
      debugPrint('Error loading recent food logs: $e');
    }
  }

  /// Force refresh all data (use after logging a meal, etc.)
  Future<void> refreshAll(String userId) async {
    _lastLoadTime = null;  // Clear cache
    await Future.wait([
      loadTodaySummary(userId, forceRefresh: true),
      loadTargets(userId, forceRefresh: true),
      loadRecentLogs(userId, forceRefresh: true),
    ]);
  }

  /// Delete a food log
  Future<void> deleteLog(String userId, String logId) async {
    try {
      await _repository.deleteFoodLog(logId);
      await loadTodaySummary(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _repository.updateTargets(
        userId,
        calorieTarget: calorieTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
      );
      await loadTargets(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Nutrition repository
class NutritionRepository {
  final ApiClient _client;

  NutritionRepository(this._client);

  /// Get food logs for a user
  Future<List<FoodLog>> getFoodLogs(
    String userId, {
    int limit = 50,
    String? fromDate,
    String? toDate,
    String? mealType,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      if (mealType != null) queryParams['meal_type'] = mealType;

      final response = await _client.get(
        '/nutrition/food-logs/$userId',
        queryParameters: queryParams,
      );
      final data = response.data as List;
      return data.map((json) => FoodLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting food logs: $e');
      rethrow;
    }
  }

  /// Get daily nutrition summary
  Future<DailyNutritionSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/summary/daily/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyNutritionSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily nutrition summary: $e');
      rethrow;
    }
  }

  /// Delete a food log
  Future<void> deleteFoodLog(String logId) async {
    try {
      await _client.delete('/nutrition/food-logs/$logId');
    } catch (e) {
      debugPrint('Error deleting food log: $e');
      rethrow;
    }
  }

  /// Get nutrition targets
  Future<NutritionTargets> getTargets(String userId) async {
    try {
      final response = await _client.get('/nutrition/targets/$userId');
      return NutritionTargets.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting nutrition targets: $e');
      rethrow;
    }
  }

  /// Update nutrition targets
  Future<void> updateTargets(
    String userId, {
    int? calorieTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
  }) async {
    try {
      await _client.put(
        '/nutrition/targets/$userId',
        data: {
          'user_id': userId,
          if (calorieTarget != null) 'daily_calorie_target': calorieTarget,
          if (proteinTarget != null) 'daily_protein_target_g': proteinTarget,
          if (carbsTarget != null) 'daily_carbs_target_g': carbsTarget,
          if (fatTarget != null) 'daily_fat_target_g': fatTarget,
        },
      );
    } catch (e) {
      debugPrint('Error updating nutrition targets: $e');
      rethrow;
    }
  }

  // ============================================
  // Barcode & AI Food Logging Methods
  // ============================================

  /// Lookup a product by barcode
  Future<BarcodeProduct> lookupBarcode(String barcode) async {
    try {
      final response = await _client.get('/nutrition/barcode/$barcode');
      return BarcodeProduct.fromJson(response.data);
    } catch (e) {
      debugPrint('Error looking up barcode: $e');
      rethrow;
    }
  }

  /// Log food from barcode scan
  Future<LogBarcodeResponse> logFoodFromBarcode({
    required String userId,
    required String barcode,
    required String mealType,
    double servings = 1.0,
    double? servingSizeG,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/log-barcode',
        data: {
          'user_id': userId,
          'barcode': barcode,
          'meal_type': mealType,
          'servings': servings,
          if (servingSizeG != null) 'serving_size_g': servingSizeG,
        },
      );
      return LogBarcodeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from barcode: $e');
      rethrow;
    }
  }

  /// Log food from image using Gemini Vision
  Future<LogFoodResponse> logFoodFromImage({
    required String userId,
    required String mealType,
    required File imageFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'food_image.jpg',
        ),
      });

      final response = await _client.post(
        '/nutrition/log-image',
        data: formData,
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from image: $e');
      rethrow;
    }
  }

  /// Log food from text description using Gemini
  Future<LogFoodResponse> logFoodFromText({
    required String userId,
    required String description,
    required String mealType,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/log-text',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
        },
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging food from text: $e');
      rethrow;
    }
  }

  /// Log pre-analyzed food directly (for restaurant mode, manual adjustments)
  Future<LogFoodResponse> logAdjustedFood({
    required String userId,
    required String mealType,
    required List<Map<String, dynamic>> foodItems,
    required int totalCalories,
    required int totalProtein,
    required int totalCarbs,
    required int totalFat,
    int? totalFiber,
    String sourceType = 'restaurant',
    String? notes,
    // Micronutrients (optional)
    double? sodiumMg,
    double? sugarG,
    double? saturatedFatG,
    double? cholesterolMg,
    double? potassiumMg,
    double? vitaminAUg,
    double? vitaminCMg,
    double? vitaminDIu,
    double? vitaminEMg,
    double? vitaminKUg,
    double? vitaminB1Mg,
    double? vitaminB2Mg,
    double? vitaminB3Mg,
    double? vitaminB5Mg,
    double? vitaminB6Mg,
    double? vitaminB7Ug,
    double? vitaminB9Ug,
    double? vitaminB12Ug,
    double? calciumMg,
    double? ironMg,
    double? magnesiumMg,
    double? zincMg,
    double? phosphorusMg,
    double? copperMg,
    double? manganeseMg,
    double? seleniumUg,
    double? cholineMg,
    double? omega3G,
    double? omega6G,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/log-direct',
        data: {
          'user_id': userId,
          'meal_type': mealType,
          'food_items': foodItems,
          'total_calories': totalCalories,
          'total_protein': totalProtein,
          'total_carbs': totalCarbs,
          'total_fat': totalFat,
          if (totalFiber != null) 'total_fiber': totalFiber,
          'source_type': sourceType,
          if (notes != null) 'notes': notes,
          // Micronutrients
          if (sodiumMg != null) 'sodium_mg': sodiumMg,
          if (sugarG != null) 'sugar_g': sugarG,
          if (saturatedFatG != null) 'saturated_fat_g': saturatedFatG,
          if (cholesterolMg != null) 'cholesterol_mg': cholesterolMg,
          if (potassiumMg != null) 'potassium_mg': potassiumMg,
          if (vitaminAUg != null) 'vitamin_a_ug': vitaminAUg,
          if (vitaminCMg != null) 'vitamin_c_mg': vitaminCMg,
          if (vitaminDIu != null) 'vitamin_d_iu': vitaminDIu,
          if (vitaminEMg != null) 'vitamin_e_mg': vitaminEMg,
          if (vitaminKUg != null) 'vitamin_k_ug': vitaminKUg,
          if (vitaminB1Mg != null) 'vitamin_b1_mg': vitaminB1Mg,
          if (vitaminB2Mg != null) 'vitamin_b2_mg': vitaminB2Mg,
          if (vitaminB3Mg != null) 'vitamin_b3_mg': vitaminB3Mg,
          if (vitaminB5Mg != null) 'vitamin_b5_mg': vitaminB5Mg,
          if (vitaminB6Mg != null) 'vitamin_b6_mg': vitaminB6Mg,
          if (vitaminB7Ug != null) 'vitamin_b7_ug': vitaminB7Ug,
          if (vitaminB9Ug != null) 'vitamin_b9_ug': vitaminB9Ug,
          if (vitaminB12Ug != null) 'vitamin_b12_ug': vitaminB12Ug,
          if (calciumMg != null) 'calcium_mg': calciumMg,
          if (ironMg != null) 'iron_mg': ironMg,
          if (magnesiumMg != null) 'magnesium_mg': magnesiumMg,
          if (zincMg != null) 'zinc_mg': zincMg,
          if (phosphorusMg != null) 'phosphorus_mg': phosphorusMg,
          if (copperMg != null) 'copper_mg': copperMg,
          if (manganeseMg != null) 'manganese_mg': manganeseMg,
          if (seleniumUg != null) 'selenium_ug': seleniumUg,
          if (cholineMg != null) 'choline_mg': cholineMg,
          if (omega3G != null) 'omega3_g': omega3G,
          if (omega6G != null) 'omega6_g': omega6G,
        },
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging adjusted food: $e');
      rethrow;
    }
  }

  /// Log food from text description with streaming progress updates
  ///
  /// Returns a Stream that emits progress as food is analyzed:
  /// - Step 1: Loading user profile
  /// - Step 2: Analyzing food with AI
  /// - Step 3: Calculating nutrition
  /// - Step 4: Saving to database
  Stream<FoodLoggingProgress> logFoodFromTextStreaming({
    required String userId,
    required String description,
    required String mealType,
  }) async* {
    debugPrint('🍽️ [Nutrition] Starting streaming food logging for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Starting analysis...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '/nutrition/log-text-stream',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Meal logged!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming food logging error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to log food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  /// Log food from image with streaming progress updates
  ///
  /// Returns a Stream that emits progress as image is analyzed:
  /// - Step 1: Processing image
  /// - Step 2: AI analyzing food
  /// - Step 3: Calculating nutrition
  /// - Step 4: Saving to database
  Stream<FoodLoggingProgress> logFoodFromImageStreaming({
    required String userId,
    required String mealType,
    required File imageFile,
  }) async* {
    debugPrint('📸 [Nutrition] Starting streaming image food logging for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Preparing image...',
        elapsedMs: 0,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'food_image.jpg',
        ),
      });

      final response = await streamingDio.post(
        '/nutrition/log-image-stream',
        data: formData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 4,
                    message: data['message'] as String? ?? 'Processing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'done') {
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Meal logged!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming image food logging error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to log food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  // ============================================
  // Analyze-Only Streaming Methods (No Save)
  // ============================================

  /// Analyze food from text description with streaming progress updates
  ///
  /// DOES NOT save to database - returns analysis only for user review.
  /// Call logFoodDirect() after user confirmation to actually save.
  ///
  /// Returns a Stream that emits progress as text is analyzed:
  /// - Step 1: Loading user profile and goals
  /// - Step 2: Analyzing food with AI
  /// - Step 3: Calculating nutrition (analysis complete)
  Stream<FoodLoggingProgress> analyzeFoodFromTextStreaming({
    required String userId,
    required String description,
    required String mealType,
  }) async* {
    debugPrint('🔍 [Nutrition] Starting streaming food ANALYSIS for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Starting analysis...',
        elapsedMs: 0,
        isAnalysisOnly: true,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final response = await streamingDio.post(
        '/nutrition/analyze-text-stream',
        data: {
          'user_id': userId,
          'description': description,
          'meal_type': mealType,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      debugPrint('🔍 [Nutrition-Text] Starting to read SSE stream...');
      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);
        debugPrint('🔍 [Nutrition-Text] SSE chunk: ${bytes.length} bytes');

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              debugPrint('🔍 [Nutrition-Text] Event: $eventType');
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  debugPrint('🔍 [Nutrition-Text] Progress: ${data['step']}/${data['total_steps']} - ${data['message']}');
                  yield FoodLoggingProgress(
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 3,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'done') {
                  debugPrint('✅ [Nutrition-Text] Analysis complete! Parsing JSON...');
                  try {
                    final foodLog = LogFoodResponse.fromJson(data);
                    debugPrint('✅ [Nutrition-Text] Parsed: ${foodLog.totalCalories} cal, ${foodLog.foodItems.length} items');
                    yield FoodLoggingProgress(
                      step: 3,
                      totalSteps: 3,
                      message: 'Analysis complete!',
                      elapsedMs: elapsedMs,
                      foodLog: foodLog,
                      isCompleted: true,
                      isAnalysisOnly: true,
                    );
                  } catch (parseError) {
                    debugPrint('❌ [Nutrition-Text] JSON parse error: $parseError');
                    debugPrint('❌ [Nutrition-Text] Raw data: $eventData');
                    yield FoodLoggingProgress(
                      step: 0,
                      totalSteps: 3,
                      message: 'Failed to parse response: $parseError',
                      elapsedMs: elapsedMs,
                      hasError: true,
                      isAnalysisOnly: true,
                    );
                  }
                } else if (eventType == 'error') {
                  debugPrint('❌ [Nutrition-Text] Server error: ${data['error']}');
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 3,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                    isAnalysisOnly: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition-Text] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
      debugPrint('🔍 [Nutrition-Text] SSE stream ended');
    } catch (e) {
      debugPrint('❌ [Nutrition-Text] Streaming food analysis error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Failed to analyze food: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
        isAnalysisOnly: true,
      );
    }
  }

  /// Analyze food from image with streaming progress updates
  ///
  /// DOES NOT save to database - returns analysis only for user review.
  /// Call logFoodDirect() after user confirmation to actually save.
  ///
  /// Returns a Stream that emits progress as image is analyzed:
  /// - Step 1: Processing image
  /// - Step 2: AI analyzing food
  /// - Step 3: Calculating nutrition (analysis complete)
  Stream<FoodLoggingProgress> analyzeFoodFromImageStreaming({
    required String userId,
    required String mealType,
    required File imageFile,
  }) async* {
    debugPrint('📸 [Nutrition] Starting streaming image ANALYSIS for $userId');
    final startTime = DateTime.now();

    try {
      // Emit initial status
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Preparing image...',
        elapsedMs: 0,
        isAnalysisOnly: true,
      );

      // Get the base URL from API client
      final baseUrl = _client.baseUrl;

      // Create a new Dio instance for streaming
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ));

      // Add auth headers from existing client
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'food_image.jpg',
        ),
      });

      final response = await streamingDio.post(
        '/nutrition/analyze-image-stream',
        data: formData,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      // Handle the response stream properly - cast to ResponseBody first
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        // Decode bytes to string and add to buffer
        buffer += utf8.decode(bytes);

        // Process complete lines from buffer
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            // End of event
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

                if (eventType == 'progress') {
                  yield FoodLoggingProgress(
                    step: data['step'] as int? ?? 0,
                    totalSteps: data['total_steps'] as int? ?? 3,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'done') {
                  final foodLog = LogFoodResponse.fromJson(data);
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Analysis complete!',
                    elapsedMs: elapsedMs,
                    foodLog: foodLog,
                    isCompleted: true,
                    isAnalysisOnly: true,
                  );
                } else if (eventType == 'error') {
                  yield FoodLoggingProgress(
                    step: 0,
                    totalSteps: 3,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                    isAnalysisOnly: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition] Error parsing SSE data: $e');
              }
              eventType = '';
              eventData = '';
            }
            continue;
          }

          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [Nutrition] Streaming image analysis error: $e');
      yield FoodLoggingProgress(
        step: 0,
        totalSteps: 3,
        message: 'Failed to analyze image: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
        isAnalysisOnly: true,
      );
    }
  }

  /// Log food directly from an analyzed response (after user confirmation)
  ///
  /// Use this method after the user has reviewed and confirmed the analysis
  /// from analyzeFoodFromTextStreaming() or analyzeFoodFromImageStreaming().
  Future<LogFoodResponse> logFoodDirect({
    required String userId,
    required String mealType,
    required LogFoodResponse analyzedFood,
    double portionMultiplier = 1.0,
    String sourceType = 'text',
  }) async {
    debugPrint('💾 [Nutrition] Saving analyzed food for $userId');

    // Adjust nutrition values by portion multiplier
    final adjustedCalories = (analyzedFood.totalCalories * portionMultiplier).round();
    final adjustedProtein = (analyzedFood.proteinG * portionMultiplier).round();
    final adjustedCarbs = (analyzedFood.carbsG * portionMultiplier).round();
    final adjustedFat = (analyzedFood.fatG * portionMultiplier).round();
    final adjustedFiber = ((analyzedFood.fiberG ?? 0) * portionMultiplier).round();

    // Adjust micronutrients by portion multiplier
    final adjustedSugar = analyzedFood.sugarG != null ? analyzedFood.sugarG! * portionMultiplier : null;
    final adjustedSodium = analyzedFood.sodiumMg != null ? analyzedFood.sodiumMg! * portionMultiplier : null;
    final adjustedCholesterol = analyzedFood.cholesterolMg != null ? analyzedFood.cholesterolMg! * portionMultiplier : null;
    final adjustedVitaminA = analyzedFood.vitaminAIu != null ? analyzedFood.vitaminAIu! * portionMultiplier : null;
    final adjustedVitaminC = analyzedFood.vitaminCMg != null ? analyzedFood.vitaminCMg! * portionMultiplier : null;
    final adjustedVitaminD = analyzedFood.vitaminDIu != null ? analyzedFood.vitaminDIu! * portionMultiplier : null;
    final adjustedCalcium = analyzedFood.calciumMg != null ? analyzedFood.calciumMg! * portionMultiplier : null;
    final adjustedIron = analyzedFood.ironMg != null ? analyzedFood.ironMg! * portionMultiplier : null;
    final adjustedPotassium = analyzedFood.potassiumMg != null ? analyzedFood.potassiumMg! * portionMultiplier : null;

    // Adjust food items
    final adjustedItems = analyzedFood.foodItems.map((item) {
      return {
        ...item,
        'calories': ((item['calories'] ?? 0) * portionMultiplier).round(),
        'protein_g': ((item['protein_g'] ?? 0) * portionMultiplier).round(),
        'carbs_g': ((item['carbs_g'] ?? 0) * portionMultiplier).round(),
        'fat_g': ((item['fat_g'] ?? 0) * portionMultiplier).round(),
        if (portionMultiplier != 1.0) 'portion_adjusted': true,
        if (portionMultiplier != 1.0) 'portion_multiplier': portionMultiplier,
      };
    }).toList();

    return logAdjustedFood(
      userId: userId,
      mealType: mealType,
      foodItems: adjustedItems,
      totalCalories: adjustedCalories,
      totalProtein: adjustedProtein,
      totalCarbs: adjustedCarbs,
      totalFat: adjustedFat,
      totalFiber: adjustedFiber,
      sourceType: sourceType,
      // Pass micronutrients from AI analysis
      sugarG: adjustedSugar,
      sodiumMg: adjustedSodium,
      cholesterolMg: adjustedCholesterol,
      vitaminAUg: adjustedVitaminA,
      vitaminCMg: adjustedVitaminC,
      vitaminDIu: adjustedVitaminD,
      calciumMg: adjustedCalcium,
      ironMg: adjustedIron,
      potassiumMg: adjustedPotassium,
    );
  }

  // ============================================
  // Saved Foods (Favorite Recipes) Methods
  // ============================================

  /// Save a food as favorite
  Future<SavedFood> saveFood({
    required String userId,
    required SaveFoodRequest request,
  }) async {
    debugPrint('⭐ [NutritionRepo] saveFood called for user: $userId');
    try {
      final requestJson = request.toJson();
      debugPrint('⭐ [NutritionRepo] Request data: $requestJson');

      final response = await _client.post(
        '/nutrition/saved-foods/save',
        queryParameters: {'user_id': userId},
        data: requestJson,
      );

      debugPrint('✅ [NutritionRepo] Save food response: ${response.data}');
      return SavedFood.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('❌ [NutritionRepo] DioException saving food: ${e.message}');
      debugPrint('❌ [NutritionRepo] Response status: ${e.response?.statusCode}');
      debugPrint('❌ [NutritionRepo] Response data: ${e.response?.data}');

      if (e.response?.statusCode == 422) {
        // Validation error from backend
        final detail = e.response?.data?['detail'];
        throw Exception('Validation error: $detail');
      } else if (e.response?.statusCode == 500) {
        final detail = e.response?.data?['detail'] ?? 'Server error';
        throw Exception('Server error: $detail');
      }
      throw Exception('Failed to save food: ${e.message}');
    } catch (e) {
      debugPrint('❌ [NutritionRepo] Error saving food: $e');
      rethrow;
    }
  }

  /// Get list of saved foods
  Future<SavedFoodsResponse> getSavedFoods({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? sourceType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      };
      if (sourceType != null) queryParams['source_type'] = sourceType;

      final response = await _client.get(
        '/nutrition/saved-foods',
        queryParameters: queryParams,
      );
      return SavedFoodsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting saved foods: $e');
      rethrow;
    }
  }

  /// Get a specific saved food
  Future<SavedFood> getSavedFood({
    required String userId,
    required String savedFoodId,
  }) async {
    try {
      final response = await _client.get(
        '/nutrition/saved-foods/$savedFoodId',
        queryParameters: {'user_id': userId},
      );
      return SavedFood.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting saved food: $e');
      rethrow;
    }
  }

  /// Delete a saved food
  Future<void> deleteSavedFood({
    required String userId,
    required String savedFoodId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/saved-foods/$savedFoodId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error deleting saved food: $e');
      rethrow;
    }
  }

  /// Re-log a saved food
  Future<LogFoodResponse> relogSavedFood({
    required String userId,
    required String savedFoodId,
    required String mealType,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/saved-foods/$savedFoodId/log',
        queryParameters: {'user_id': userId},
        data: {'meal_type': mealType},
      );
      return LogFoodResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error re-logging saved food: $e');
      rethrow;
    }
  }

  // ============================================
  // Recipe Methods
  // ============================================

  /// Create a new recipe
  Future<Recipe> createRecipe({
    required String userId,
    required RecipeCreate request,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes',
        queryParameters: {'user_id': userId},
        data: request.toJson(),
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error creating recipe: $e');
      rethrow;
    }
  }

  /// Get list of user's recipes
  Future<RecipesResponse> getRecipes({
    required String userId,
    int limit = 50,
    int offset = 0,
    String? category,
    String? search,
    String sortBy = 'created_at',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
        'sort_by': sortBy,
      };
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      final response = await _client.get(
        '/nutrition/recipes',
        queryParameters: queryParams,
      );
      return RecipesResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting recipes: $e');
      rethrow;
    }
  }

  /// Get a specific recipe with ingredients
  Future<Recipe> getRecipe({
    required String userId,
    required String recipeId,
  }) async {
    try {
      final response = await _client.get(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting recipe: $e');
      rethrow;
    }
  }

  /// Update a recipe
  Future<Recipe> updateRecipe({
    required String userId,
    required String recipeId,
    required RecipeUpdate request,
  }) async {
    try {
      final response = await _client.put(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
        data: request.toJson(),
      );
      return Recipe.fromJson(response.data);
    } catch (e) {
      debugPrint('Error updating recipe: $e');
      rethrow;
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/recipes/$recipeId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      rethrow;
    }
  }

  /// Log a recipe as a meal
  Future<LogRecipeResponse> logRecipe({
    required String userId,
    required String recipeId,
    required String mealType,
    double servings = 1.0,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes/$recipeId/log',
        queryParameters: {'user_id': userId},
        data: {
          'meal_type': mealType,
          'servings': servings,
        },
      );
      return LogRecipeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error logging recipe: $e');
      rethrow;
    }
  }

  /// Add ingredient to a recipe
  Future<RecipeIngredient> addIngredient({
    required String userId,
    required String recipeId,
    required RecipeIngredientCreate ingredient,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/recipes/$recipeId/ingredients',
        queryParameters: {'user_id': userId},
        data: ingredient.toJson(),
      );
      return RecipeIngredient.fromJson(response.data);
    } catch (e) {
      debugPrint('Error adding ingredient: $e');
      rethrow;
    }
  }

  /// Remove ingredient from a recipe
  Future<void> removeIngredient({
    required String userId,
    required String recipeId,
    required String ingredientId,
  }) async {
    try {
      await _client.delete(
        '/nutrition/recipes/$recipeId/ingredients/$ingredientId',
        queryParameters: {'user_id': userId},
      );
    } catch (e) {
      debugPrint('Error removing ingredient: $e');
      rethrow;
    }
  }

  // ============================================
  // Micronutrient Methods
  // ============================================

  /// Get daily micronutrient summary
  Future<DailyMicronutrientSummary> getDailyMicronutrients({
    required String userId,
    String? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/micronutrients/$userId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return DailyMicronutrientSummary.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting daily micronutrients: $e');
      rethrow;
    }
  }

  /// Get top contributors for a specific nutrient
  Future<NutrientContributorsResponse> getNutrientContributors({
    required String userId,
    required String nutrientKey,
    String? date,
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (date != null) queryParams['date'] = date;

      final response = await _client.get(
        '/nutrition/micronutrients/$userId/contributors/$nutrientKey',
        queryParameters: queryParams,
      );
      return NutrientContributorsResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('Error getting nutrient contributors: $e');
      rethrow;
    }
  }

  /// Get all RDA (Reference Daily Allowance) values
  Future<List<NutrientRDA>> getAllRDAs() async {
    try {
      final response = await _client.get('/nutrition/rdas');
      final data = response.data as List;
      return data.map((json) => NutrientRDA.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting RDAs: $e');
      rethrow;
    }
  }

  /// Update user's pinned nutrients
  Future<void> updatePinnedNutrients({
    required String userId,
    required List<String> pinnedNutrients,
  }) async {
    try {
      await _client.put(
        '/nutrition/pinned-nutrients/$userId',
        data: {'pinned_nutrients': pinnedNutrients},
      );
    } catch (e) {
      debugPrint('Error updating pinned nutrients: $e');
      rethrow;
    }
  }

  // ============================================
  // Adaptive TDEE & Weekly Check-in Methods
  // ============================================

  /// Get the latest adaptive TDEE calculation
  Future<AdaptiveCalculation?> getAdaptiveCalculation(String userId) async {
    try {
      debugPrint('🔍 [Nutrition] Getting adaptive calculation for $userId');
      final response = await _client.get('/nutrition/adaptive/$userId');

      if (response.data == null) {
        return null;
      }

      return AdaptiveCalculation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting adaptive calculation: $e');
      return null;
    }
  }

  /// Calculate adaptive TDEE based on food intake and weight changes
  Future<AdaptiveCalculation?> calculateAdaptiveTdee(
    String userId, {
    int days = 14,
  }) async {
    try {
      debugPrint('🧮 [Nutrition] Calculating adaptive TDEE for $userId over $days days');
      final response = await _client.post(
        '/nutrition/adaptive/$userId/calculate',
        queryParameters: {'days': days},
      );

      return AdaptiveCalculation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error calculating adaptive TDEE: $e');
      return null;
    }
  }

  /// Get weekly summary data (food logs, weight, etc.)
  Future<WeeklySummaryData?> getWeeklySummary(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting weekly summary for $userId');
      final response = await _client.get('/nutrition/weekly-summary/$userId');

      return WeeklySummaryData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly summary: $e');
      return null;
    }
  }

  /// Get the latest weekly nutrition recommendation
  Future<WeeklyRecommendation?> getWeeklyRecommendation(String userId) async {
    try {
      debugPrint('💡 [Nutrition] Getting weekly recommendation for $userId');
      final response = await _client.get('/nutrition/recommendations/$userId');

      if (response.data == null) {
        return null;
      }

      return WeeklyRecommendation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly recommendation: $e');
      return null;
    }
  }

  /// Respond to a weekly nutrition recommendation (accept or decline)
  Future<bool> respondToRecommendation({
    required String userId,
    required String recommendationId,
    required bool accepted,
    int? modifiedCalories,
  }) async {
    try {
      debugPrint('📝 [Nutrition] Responding to recommendation $recommendationId: accepted=$accepted');
      await _client.post(
        '/nutrition/recommendations/$recommendationId/respond',
        queryParameters: {
          'user_id': userId,
          'accepted': accepted,
        },
        data: modifiedCalories != null ? {'modified_calories': modifiedCalories} : null,
      );

      return true;
    } catch (e) {
      debugPrint('❌ [Nutrition] Error responding to recommendation: $e');
      return false;
    }
  }

  /// Generate a new weekly recommendation based on current data
  Future<WeeklyRecommendation?> generateWeeklyRecommendation(String userId) async {
    try {
      debugPrint('🎯 [Nutrition] Generating weekly recommendation for $userId');
      final response = await _client.post('/nutrition/recommendations/$userId/generate');

      return WeeklyRecommendation.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error generating weekly recommendation: $e');
      return null;
    }
  }

  // ============================================
  // MacroFactor-Style Enhanced Methods
  // ============================================

  /// Get detailed TDEE with confidence intervals and metabolic adaptation detection
  Future<DetailedTDEE?> getDetailedTDEE(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting detailed TDEE for $userId');
      final response = await _client.get('/nutrition/tdee/$userId/detailed');

      if (response.data == null) {
        return null;
      }

      return DetailedTDEE.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting detailed TDEE: $e');
      return null;
    }
  }

  /// Get adherence summary with sustainability score
  Future<AdherenceSummary?> getAdherenceSummary(
    String userId, {
    int weeks = 4,
  }) async {
    try {
      debugPrint('📈 [Nutrition] Getting adherence summary for $userId (${weeks}w)');
      final response = await _client.get(
        '/nutrition/adherence/$userId/summary',
        queryParameters: {'weeks': weeks},
      );

      if (response.data == null) {
        return null;
      }

      return AdherenceSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting adherence summary: $e');
      return null;
    }
  }

  /// Get multi-option recommendations (aggressive, moderate, conservative)
  Future<RecommendationOptions?> getRecommendationOptions(String userId) async {
    try {
      debugPrint('🎯 [Nutrition] Getting recommendation options for $userId');
      final response = await _client.get('/nutrition/recommendations/$userId/options');

      if (response.data == null) {
        return null;
      }

      return RecommendationOptions.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting recommendation options: $e');
      return null;
    }
  }

  /// Select a recommendation option (aggressive, moderate, conservative)
  Future<bool> selectRecommendationOption({
    required String userId,
    required String optionType,
  }) async {
    try {
      debugPrint('✅ [Nutrition] Selecting recommendation option: $optionType for $userId');
      await _client.post(
        '/nutrition/recommendations/$userId/select',
        queryParameters: {'option_type': optionType},
      );

      return true;
    } catch (e) {
      debugPrint('❌ [Nutrition] Error selecting recommendation option: $e');
      return false;
    }
  }

  /// Get all data needed for the enhanced weekly check-in
  /// Returns combined data: DetailedTDEE, AdherenceSummary, RecommendationOptions
  Future<WeeklyCheckinData?> getWeeklyCheckinData(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Loading weekly check-in data for $userId');

      // Fetch all data in parallel for performance
      final results = await Future.wait([
        getDetailedTDEE(userId),
        getAdherenceSummary(userId),
        getRecommendationOptions(userId),
        getWeeklySummary(userId),
      ]);

      final detailedTdee = results[0] as DetailedTDEE?;
      final adherence = results[1] as AdherenceSummary?;
      final options = results[2] as RecommendationOptions?;
      final summary = results[3] as WeeklySummaryData?;

      return WeeklyCheckinData(
        detailedTdee: detailedTdee,
        adherenceSummary: adherence,
        recommendationOptions: options,
        weeklySummary: summary,
      );
    } catch (e) {
      debugPrint('❌ [Nutrition] Error loading weekly check-in data: $e');
      return null;
    }
  }
}

/// Combined data for the enhanced weekly check-in screen
class WeeklyCheckinData {
  final DetailedTDEE? detailedTdee;
  final AdherenceSummary? adherenceSummary;
  final RecommendationOptions? recommendationOptions;
  final WeeklySummaryData? weeklySummary;

  const WeeklyCheckinData({
    this.detailedTdee,
    this.adherenceSummary,
    this.recommendationOptions,
    this.weeklySummary,
  });

  /// Check if we have enough data for a meaningful check-in
  bool get hasEnoughData =>
      detailedTdee != null ||
      adherenceSummary != null ||
      recommendationOptions != null;

  /// Check if metabolic adaptation was detected
  bool get hasMetabolicAdaptation =>
      detailedTdee?.hasAdaptation ?? false;

  /// Get the current sustainability rating
  String? get sustainabilityRating =>
      adherenceSummary?.sustainabilityRating;

  /// Check if there are multiple recommendation options
  bool get hasMultipleOptions =>
      (recommendationOptions?.options.length ?? 0) > 1;
}
