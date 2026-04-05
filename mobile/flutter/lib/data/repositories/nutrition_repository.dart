import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/nutrition.dart';
import '../models/micronutrients.dart';
import '../models/nutrition_preferences.dart';
import '../models/recipe.dart';
import '../services/api_client.dart';
import '../services/health_service.dart';
import '../providers/xp_provider.dart';

part 'nutrition_repository_part_food_logging_progress.dart';

part 'nutrition_repository_ui.dart';


/// Nutrition repository provider
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(ref.watch(apiClientProvider));
});

/// Nutrition state provider
final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref.watch(nutritionRepositoryProvider), ref);
});

/// Nutrition repository
class NutritionRepository {
  final ApiClient _client;

  NutritionRepository(this._client);

  // --- Client-side LRU cache for food text analysis ---
  static const int _maxCacheSize = 50;
  static final Map<String, LogFoodResponse> _analysisCache = {};
  static final List<String> _cacheOrder = []; // LRU order: most recent at end

  /// Normalize description for cache key: lowercase, trimmed, collapsed spaces
  static String _normalizeCacheKey(String description) {
    return description.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Store a result in the LRU cache, evicting oldest if full
  static void _cacheResult(String key, LogFoodResponse result) {
    // If key already exists, move it to end (most recent)
    _cacheOrder.remove(key);
    _cacheOrder.add(key);
    _analysisCache[key] = result;

    // Evict oldest entries if over capacity
    while (_cacheOrder.length > _maxCacheSize) {
      final evicted = _cacheOrder.removeAt(0);
      _analysisCache.remove(evicted);
    }
  }

  /// Look up a cached result, returning null on miss
  static LogFoodResponse? _getCached(String key) {
    final result = _analysisCache[key];
    if (result != null) {
      // Move to end (most recently used)
      _cacheOrder.remove(key);
      _cacheOrder.add(key);
    }
    return result;
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
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
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
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
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
    String? moodBefore,
  }) async* {
    debugPrint('🔍 [Nutrition] Starting streaming food ANALYSIS for $userId');
    final startTime = DateTime.now();

    // --- Check client-side cache first ---
    final cacheKey = _normalizeCacheKey(description);
    final cached = _getCached(cacheKey);
    if (cached != null) {
      debugPrint('✅ [Nutrition] Cache HIT for: "$cacheKey"');
      yield FoodLoggingProgress(
        step: 3,
        totalSteps: 3,
        message: 'Analysis complete!',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        foodLog: cached,
        isCompleted: true,
        isAnalysisOnly: true,
      );
      return;
    }
    debugPrint('🔍 [Nutrition] Cache MISS for: "$cacheKey"');

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
          if (moodBefore != null) 'mood_before': moodBefore,
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
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 3,
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
                    // Cache the successful result
                    _cacheResult(cacheKey, foodLog);
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
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 3,
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

  /// Get weekly nutrition data with daily breakdown (for charts)
  Future<WeeklyNutritionData?> getWeeklyNutrition(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Getting weekly nutrition data for $userId');
      final response = await _client.get('/nutrition/summary/weekly/$userId');

      if (response.data == null) {
        return null;
      }

      return WeeklyNutritionData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [Nutrition] Error getting weekly nutrition data: $e');
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

  /// Get all data needed for the enhanced weekly check-in
  /// Returns combined data: DetailedTDEE, AdherenceSummary, RecommendationOptions
  Future<WeeklyCheckinData?> getWeeklyCheckinData(String userId) async {
    try {
      debugPrint('📊 [Nutrition] Loading weekly check-in data for $userId');

      // Fetch all data in parallel — each guarded so one failure doesn't nuke all
      final results = await Future.wait([
        getDetailedTDEE(userId).catchError((_) => null),
        getAdherenceSummary(userId).catchError((_) => null),
        getRecommendationOptions(userId).catchError((_) => null),
        getWeeklySummary(userId).catchError((_) => null),
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
