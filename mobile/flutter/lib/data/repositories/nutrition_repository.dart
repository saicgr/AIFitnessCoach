import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/nutrition.dart';
import '../models/food_patterns.dart';
import '../models/micronutrients.dart';
import '../models/nutrition_preferences.dart';
import '../models/companion_suggestion.dart';
import '../models/recipe.dart';
import '../services/api_client.dart';
import '../../utils/tz.dart';
import '../services/health_service.dart';
import '../providers/xp_provider.dart';
import '../../services/post_meal_checkin_reminder.dart';
// Meal-suggestion widget — staged. Re-enable once widget feature ships.
// import '../../services/meal_suggestion_widget_service.dart';

part 'nutrition_repository_part_food_logging_progress.dart';

part 'nutrition_repository_ui.dart';

/// Reads the cached IANA timezone string from SharedPreferences.
/// Returns empty string on any error — callers skip the `tz` param if empty.
Future<String> _cachedTz() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_timezone') ?? '';
  } catch (_) {
    return '';
  }
}

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
      // Hold the `done` payload so the late `coach_tips` event can be merged
      // into a COMPLETE foodLog (the coach-tip card needs the full meal).
      Map<String, dynamic>? doneData;

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
                    doneData = data;
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
                } else if (eventType == 'coach_tips') {
                  // Late-arriving coaching tips — streamed AFTER `done` so the
                  // macro card already rendered fast. Merge the tip fields
                  // into the stored `done` payload and re-emit a COMPLETE
                  // foodLog so the UI can swap the shimmer for the real tip.
                  final merged = <String, dynamic>{...?doneData};
                  for (final k in const [
                    'ai_suggestion', 'encouragements', 'warnings',
                    'recommended_swap', 'health_score', 'health_score_reasons',
                  ]) {
                    if (data[k] != null) merged[k] = data[k];
                  }
                  LogFoodResponse? mergedLog;
                  if (merged.isNotEmpty) {
                    try {
                      mergedLog = LogFoodResponse.fromJson(merged);
                      _cacheResult(cacheKey, mergedLog);
                    } catch (e) {
                      debugPrint('⚠️ [Nutrition-Text] coach_tips merge parse error: $e');
                    }
                  }
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Coach tips ready',
                    elapsedMs: elapsedMs,
                    foodLog: mergedLog,
                    isCompleted: true,
                    isAnalysisOnly: true,
                    coachTips: data,
                  );
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
    Uint8List? thumbBytes, // Phase-2: 768px-resized JPEG for Vision API
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

      // Phase-2 §2.0: two-artifact upload when thumbBytes provided.
      //   `image`           = 768px thumb (used by Vision API; ~120KB)
      //   `image_original`  = full-res original (archived to S3 for view-later)
      // Legacy callers (no thumbBytes) keep working — backend treats it as
      // the single-artifact path and uses `image` for both purposes.
      final formData = FormData.fromMap({
        'user_id': userId,
        'meal_type': mealType,
        if (thumbBytes != null)
          'image': MultipartFile.fromBytes(
            thumbBytes,
            filename: 'food_thumb.jpg',
          )
        else
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'food_image.jpg',
          ),
        if (thumbBytes != null)
          'image_original': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'food_original.jpg',
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
      // Hold the `done` payload so the late `coach_tips` event can be merged
      // into it and re-emitted as a complete foodLog (tips included).
      Map<String, dynamic>? doneData;

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
                  doneData = data;
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
                } else if (eventType == 'coach_tips') {
                  // Late-arriving coaching tips — streamed AFTER `done` so the
                  // card already rendered fast. Merge the tip fields into the
                  // stored `done` payload and re-emit a COMPLETE foodLog; the
                  // UI re-renders the card with tips. Missing event = no tips.
                  final merged = <String, dynamic>{...?doneData};
                  for (final k in const [
                    'ai_suggestion', 'encouragements', 'warnings',
                    'recommended_swap', 'health_score', 'health_score_reasons',
                  ]) {
                    if (data[k] != null) merged[k] = data[k];
                  }
                  yield FoodLoggingProgress(
                    step: 3,
                    totalSteps: 3,
                    message: 'Coach tips ready',
                    elapsedMs: elapsedMs,
                    foodLog: merged.isNotEmpty
                        ? LogFoodResponse.fromJson(merged)
                        : null,
                    isCompleted: true,
                    isAnalysisOnly: true,
                    coachTips: data,
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

  /// Stream progress while analyzing 1..N food photos. Backend decides the
  /// analysis mode when `analysisMode="auto"` (classifies plate vs menu vs
  /// buffet). Plate mode auto-logs one food_log row. Menu / buffet mode
  /// returns structured dish data without logging — the caller renders the
  /// MenuAnalysisSheet checklist and later calls [logSelectedMealItems] with
  /// the ticked items.
  Stream<MultiImageAnalysisProgress> analyzeFoodFromImagesStreaming({
    required String userId,
    required String mealType,
    required List<File> imageFiles,
    /// Phase-2: 768px-resized JPEG bytes per image (parallel-indexed with
    /// imageFiles). When provided, backend uses these for Vision and
    /// archives the originals to S3.
    List<Uint8List>? thumbBytesList,
    String analysisMode = 'auto',
    String? userMessage,
    String? inputType,
    /// When true, backend analyzes but does NOT persist a food_log row for
    /// plate-classified responses; the client is responsible for opening a
    /// review UI and calling [logFoodDirect] on confirmation.
    bool confirmBeforeLog = false,
  }) async* {
    final startTime = DateTime.now();
    try {
      yield MultiImageAnalysisProgress(
        step: 0,
        totalSteps: 4,
        message: 'Preparing ${imageFiles.length} photo${imageFiles.length == 1 ? '' : 's'}...',
        elapsedMs: 0,
      );

      final baseUrl = _client.baseUrl;
      final streamingDio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
      ));
      final authHeaders = await _client.getAuthHeaders();
      streamingDio.options.headers.addAll(authHeaders);

      // Phase-2: paired multipart when thumbBytesList provided.
      //   `images[]`           = 768px thumbs (Vision API)
      //   `images_original[]`  = full-res originals (S3 archive)
      // Backend's analyze_food_from_s3_keys path falls back to images[] for
      // both purposes when images_original[] absent (legacy path).
      final useTwoArtifact = thumbBytesList != null
          && thumbBytesList.length == imageFiles.length;
      final multipart = <MapEntry<String, MultipartFile>>[];
      for (var i = 0; i < imageFiles.length; i++) {
        if (useTwoArtifact) {
          multipart.add(MapEntry(
            'images',
            MultipartFile.fromBytes(thumbBytesList![i], filename: 'food_thumb_$i.jpg'),
          ));
          multipart.add(MapEntry(
            'images_original',
            await MultipartFile.fromFile(imageFiles[i].path, filename: 'food_original_$i.jpg'),
          ));
        } else {
          multipart.add(MapEntry(
            'images',
            await MultipartFile.fromFile(imageFiles[i].path, filename: 'food_$i.jpg'),
          ));
        }
      }
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('user_id', userId),
        MapEntry('meal_type', mealType),
        MapEntry('analysis_mode', analysisMode),
        if (userMessage != null && userMessage.isNotEmpty) MapEntry('user_message', userMessage),
        if (inputType != null && inputType.isNotEmpty) MapEntry('input_type', inputType),
        if (confirmBeforeLog) const MapEntry('confirm_before_log', 'true'),
      ]);
      formData.files.addAll(multipart);

      final response = await streamingDio.post(
        '/nutrition/log-multi-image-stream',
        data: formData,
        options: Options(responseType: ResponseType.stream),
      );
      final responseBody = response.data as ResponseBody;

      String eventType = '';
      String eventData = '';
      String buffer = '';

      await for (final bytes in responseBody.stream) {
        buffer += utf8.decode(bytes);
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);
          if (line.isEmpty) {
            if (eventType.isNotEmpty && eventData.isNotEmpty) {
              try {
                final data = jsonDecode(eventData) as Map<String, dynamic>;
                final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
                if (eventType == 'progress') {
                  yield MultiImageAnalysisProgress(
                    step: (data['step'] as num?)?.toInt() ?? 0,
                    totalSteps: (data['total_steps'] as num?)?.toInt() ?? 4,
                    message: data['message'] as String? ?? 'Analyzing...',
                    detail: data['detail'] as String?,
                    elapsedMs: elapsedMs,
                  );
                } else if (eventType == 'page') {
                  final rawItems = (data['items'] as List?) ?? const [];
                  final items = rawItems
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                  final pageNum = (data['page'] as num?)?.toInt() ?? 0;
                  final totalPages = (data['total_pages'] as num?)?.toInt() ?? 0;
                  yield MultiImageAnalysisProgress(
                    step: pageNum,
                    totalSteps: totalPages,
                    message: 'Page $pageNum of $totalPages analyzed',
                    elapsedMs: elapsedMs,
                    isPageEvent: true,
                    pageNumber: pageNum,
                    totalPages: totalPages,
                    pageItems: items,
                    pageAnalysisType: data['analysis_type'] as String?,
                    pageImageUrl: data['image_url'] as String?,
                    pageStorageKey: data['storage_key'] as String?,
                  );
                } else if (eventType == 'page_error') {
                  final pageNum = (data['page'] as num?)?.toInt() ?? 0;
                  final totalPages = (data['total_pages'] as num?)?.toInt() ?? 0;
                  yield MultiImageAnalysisProgress(
                    step: pageNum,
                    totalSteps: totalPages,
                    message: 'Page $pageNum failed: ${data['error'] ?? 'unknown error'}',
                    elapsedMs: elapsedMs,
                    isPageError: true,
                    pageNumber: pageNum,
                    totalPages: totalPages,
                  );
                } else if (eventType == 'done') {
                  yield MultiImageAnalysisProgress(
                    step: 4,
                    totalSteps: 4,
                    message: 'Analysis complete!',
                    elapsedMs: elapsedMs,
                    isCompleted: true,
                    result: data,
                  );
                } else if (eventType == 'error') {
                  yield MultiImageAnalysisProgress(
                    step: 0,
                    totalSteps: 4,
                    message: data['error'] as String? ?? 'Unknown error',
                    elapsedMs: elapsedMs,
                    hasError: true,
                  );
                }
              } catch (e) {
                debugPrint('⚠️ [Nutrition multi] SSE parse error: $e');
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
      yield MultiImageAnalysisProgress(
        step: 0,
        totalSteps: 4,
        message: 'Failed to analyze images: $e',
        elapsedMs: DateTime.now().difference(startTime).inMilliseconds,
        hasError: true,
      );
    }
  }

  /// Persist the items the user ticked off from a menu / buffet analysis.
  /// One food_log row per item so daily aggregates stay correct.
  Future<Map<String, dynamic>> logSelectedMealItems({
    required String userId,
    required String mealType,
    required String analysisType, // "menu" | "buffet" | "plate"
    required List<Map<String, dynamic>> items,
    String? inputType,
    String? imageUrl,
    String? imageStorageKey,
  }) async {
    final response = await _client.post(
      '/nutrition/log-selected-items',
      data: {
        'user_id': userId,
        'meal_type': mealType,
        'analysis_type': analysisType,
        'items': items,
        if (inputType != null) 'input_type': inputType,
        if (imageUrl != null) 'image_url': imageUrl,
        if (imageStorageKey != null) 'image_storage_key': imageStorageKey,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Fetch typical-companion suggestions for a primary food.
  ///
  /// Backend merges the user's own cross-log co-occurrence history with a
  /// cached Gemini call ("often paired with this") and applies the user's
  /// rejected-pair suppressions. An **empty** list is a valid response — it
  /// tells the UI to log the primary silently without showing any sheet.
  Future<List<CompanionSuggestion>> fetchCompanions({
    required String userId,
    required String primaryFoodName,
    required String mealType,
    String locale = 'en',
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/companions',
        data: {
          'user_id': userId,
          'primary_food_name': primaryFoodName,
          'meal_type': mealType,
          'locale': locale,
        },
      );
      final raw = (response.data as Map<String, dynamic>?)?['suggestions']
              as List<dynamic>? ??
          const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CompanionSuggestion.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [Nutrition] fetchCompanions failed: $e');
      // Never fabricate sides. Let the caller fall through to silent log.
      return const [];
    }
  }

  /// Record a user-taught negative — suppress `companionName` on future
  /// companion prompts for `primaryFoodName`. Idempotent.
  Future<void> rejectCompanion({
    required String userId,
    required String primaryFoodName,
    required String companionName,
  }) async {
    try {
      await _client.post(
        '/nutrition/companions/reject',
        data: {
          'user_id': userId,
          'primary_food_name': primaryFoodName,
          'companion_name': companionName,
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Nutrition] rejectCompanion failed (non-fatal): $e');
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

  // ── Food Patterns (Nutrition > Patterns tab) ──────────────────────────────

  Future<FoodPatternsMoodResponse> getMoodPatterns(
    String userId, {
    int days = 90,
    int minLogs = 3,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/mood/$userId',
      queryParameters: {'days': days, 'min_logs': minLogs},
    );
    return FoodPatternsMoodResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<TopFoodsResponse> getTopFoods(
    String userId, {
    String metric = 'calories',
    String range = 'week',
    String? date,
    int limit = 20,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/top-foods/$userId',
      queryParameters: {
        'metric': metric,
        'range': range,
        if (date != null) 'date': date,
        'limit': limit,
      },
    );
    return TopFoodsResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<MacrosSummaryResponse> getMacrosSummary(
    String userId, {
    String range = 'week',
    String? date,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/macros-summary/$userId',
      queryParameters: {
        'range': range,
        if (date != null) 'date': date,
      },
    );
    return MacrosSummaryResponse.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Raw food_log rows for the Patterns timeline (Section 4).
  Future<List<Map<String, dynamic>>> getPatternsHistory(
    String userId, {
    String range = 'week',
    String? date,
    int limit = 50,
    int offset = 0,
  }) async {
    final resp = await _client.get(
      '/nutrition/food-patterns/history/$userId',
      queryParameters: {
        'range': range,
        if (date != null) 'date': date,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = Map<String, dynamic>.from(resp.data as Map);
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return items;
  }

  Future<PatternsSettings> getPatternsSettings(String userId) async {
    final resp = await _client.get('/nutrition/food-patterns/settings/$userId');
    return PatternsSettings.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  Future<PatternsSettings> updatePatternsSettings(
    String userId, {
    bool? postMealCheckinDisabled,
    bool? postMealReminderEnabled,
    bool? passiveInferenceEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (postMealCheckinDisabled != null) {
      body['post_meal_checkin_disabled'] = postMealCheckinDisabled;
    }
    if (postMealReminderEnabled != null) {
      body['post_meal_reminder_enabled'] = postMealReminderEnabled;
    }
    if (passiveInferenceEnabled != null) {
      body['passive_inference_enabled'] = passiveInferenceEnabled;
    }
    final resp = await _client.patch(
      '/nutrition/food-patterns/settings/$userId',
      data: body,
    );
    return PatternsSettings.fromJson(
      Map<String, dynamic>.from(resp.data as Map),
    );
  }

  /// Confirm or dismiss a passive mood-inference guess on a food log.
  Future<void> patchInference(String logId, {required bool confirm}) async {
    await _client.patch(
      '/nutrition/food-logs/$logId/inference',
      data: {'action': confirm ? 'confirm' : 'dismiss'},
    );
  }

  // =========================================================================
  // Phase-2 §2.9: Dish variants (powers per-item edit Region dropdown)
  // =========================================================================

  /// Fetch regional/restaurant variants of a dish via trigram fuzzy match
  /// against food_nutrition_overrides_canonical. Returns up to 10 alternates.
  ///
  /// Used by the per-item edit sheet in [LogMealSheet] — when the user taps
  /// to edit "Chicken Biryani", show Indian / Pakistani / Hyderabadi / etc.
  /// as options.
  Future<List<DishVariant>> fetchDishVariants(String dishName) async {
    if (dishName.trim().isEmpty) return const [];
    try {
      final resp = await _client.get(
        '/nutrition/dish-variants',
        queryParameters: {'name': dishName},
      );
      final data = resp.data as Map<String, dynamic>;
      final variants = (data['variants'] as List?) ?? const [];
      return variants
          .map((v) => DishVariant.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    } catch (e) {
      debugPrint('[Nutrition] fetchDishVariants($dishName) failed: $e');
      return const [];
    }
  }

  /// Swap a logged food_item to a different regional/restaurant variant.
  /// Returns the new macros (calories, protein, carbs, fat) for the item
  /// after the swap.
  Future<DishVariantSwapResult?> swapDishVariant({
    required String foodLogId,
    required int foodItemIndex,
    required int newOverrideId,
  }) async {
    try {
      final resp = await _client.post(
        '/nutrition/dish-variants/swap',
        data: {
          'food_log_id': foodLogId,
          'food_item_index': foodItemIndex,
          'new_override_id': newOverrideId,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      return DishVariantSwapResult.fromJson(data);
    } catch (e) {
      debugPrint('[Nutrition] swapDishVariant failed: $e');
      return null;
    }
  }
}

/// Phase-2 §2.9 — one regional/restaurant variant of a dish.
class DishVariant {
  final int id;
  final String foodNameNormalized;
  final String displayName;
  final String? region;
  final String? restaurantName;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  const DishVariant({
    required this.id,
    required this.foodNameNormalized,
    required this.displayName,
    this.region,
    this.restaurantName,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
  });

  factory DishVariant.fromJson(Map<String, dynamic> j) => DishVariant(
        id: (j['id'] as num).toInt(),
        foodNameNormalized: j['food_name_normalized'] as String? ?? '',
        displayName: j['display_name'] as String? ?? '',
        region: j['region'] as String?,
        restaurantName: j['restaurant_name'] as String?,
        caloriesPer100g: (j['calories_per_100g'] as num?)?.toDouble(),
        proteinPer100g: (j['protein_per_100g'] as num?)?.toDouble(),
        carbsPer100g: (j['carbs_per_100g'] as num?)?.toDouble(),
        fatPer100g: (j['fat_per_100g'] as num?)?.toDouble(),
      );

  /// Display label for the dropdown — prefers restaurant > region > display.
  String get dropdownLabel {
    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return '$restaurantName · $displayName';
    }
    if (region != null && region!.isNotEmpty) {
      return '$region · $displayName';
    }
    return displayName;
  }
}

/// Phase-2 §2.9 — response from POST /dish-variants/swap.
class DishVariantSwapResult {
  final bool success;
  final int? newCalories;
  final double? newProteinG;
  final double? newCarbsG;
  final double? newFatG;

  const DishVariantSwapResult({
    required this.success,
    this.newCalories,
    this.newProteinG,
    this.newCarbsG,
    this.newFatG,
  });

  factory DishVariantSwapResult.fromJson(Map<String, dynamic> j) =>
      DishVariantSwapResult(
        success: j['success'] as bool? ?? false,
        newCalories: (j['new_calories'] as num?)?.toInt(),
        newProteinG: (j['new_protein_g'] as num?)?.toDouble(),
        newCarbsG: (j['new_carbs_g'] as num?)?.toDouble(),
        newFatG: (j['new_fat_g'] as num?)?.toDouble(),
      );
}
