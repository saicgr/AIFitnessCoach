part of 'nutrition_repository.dart';

/// Methods extracted from NutritionRepository
extension NutritionRepositoryExt on NutritionRepository {

  /// Refresh the signed image URL for a specific food log. Used when
  /// `Image.network` 403s on an expired presigned URL so the UI can retry
  /// with a fresh 24-hour URL instead of falling back to the emoji
  /// placeholder permanently.
  Future<String?> refreshFoodLogImageUrl(String logId) async {
    try {
      final response = await _client.get('/nutrition/food-logs/$logId/image-url');
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map)['image_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [NutritionRepo] refreshFoodLogImageUrl failed for $logId: $e');
      return null;
    }
  }

  /// Get food logs for a user
  Future<List<FoodLog>> getFoodLogs(
    String userId, {
    int limit = 50,
    String? fromDate,
    String? toDate,
    String? mealType,
  }) async {
    try {
      final tz = await _cachedTz();
      final queryParams = <String, dynamic>{'limit': limit};
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      if (mealType != null) queryParams['meal_type'] = mealType;
      if (tz.isNotEmpty) queryParams['tz'] = tz;

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


  /// Returns the set of `yyyy-MM-dd` (local) keys for days within the last
  /// [days] days where the user has at least one food_log row. Used by the
  /// Nutrition tab's date strip to render a dot under each day with a log.
  ///
  /// Implementation note: there's no dedicated backend endpoint yet — we
  /// reduce the existing `getFoodLogs` response client-side. Bumping `limit`
  /// to cover ~5 logs per day for the requested window keeps a single
  /// round-trip sufficient for typical users.
  Future<Set<String>> getLoggedDateKeys(
    String userId, {
    int days = 90,
  }) async {
    try {
      final now = DateTime.now();
      final from = now.subtract(Duration(days: days));
      // toDate extends 1 day past today so logs that land on the next UTC day
      // (e.g. 7 PM CT = 00:xx UTC next day) are included.
      final tomorrow = now.add(const Duration(days: 1));
      final fromStr =
          '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
      final toStr =
          '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      final logs = await getFoodLogs(
        userId,
        limit: min(days * 6, 500),
        fromDate: fromStr,
        toDate: toStr,
      );
      final keys = <String>{};
      for (final log in logs) {
        final local = log.loggedAt.isUtc ? log.loggedAt.toLocal() : log.loggedAt;
        keys.add(
          '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
        );
      }
      return keys;
    } catch (e) {
      debugPrint('Error building logged-date keys: $e');
      return <String>{};
    }
  }

  /// Get daily nutrition summary
  Future<DailyNutritionSummary> getDailySummary(String userId, {String? date}) async {
    try {
      final tz = await _cachedTz();
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      if (tz.isNotEmpty) queryParams['tz'] = tz;

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


  /// Update macros/weight on an existing food log (portion adjustment).
  ///
  /// [itemEdits] carries optional per-field audit rows — sent alongside the
  /// update so the backend can write them to the food_log_edits table atomically.
  /// [foodItems] is the full updated items array — required when individual
  /// item macros were edited so the JSONB column reflects the new values.
  Future<Map<String, dynamic>> updateFoodLog({
    required String logId,
    required int totalCalories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double? fiberG,
    double? weightG,
    double? portionMultiplier,
    List<FoodItemEdit> itemEdits = const [],
    List<Map<String, dynamic>>? foodItems,
  }) async {
    try {
      final body = <String, dynamic>{
        'total_calories': totalCalories,
        'protein_g': proteinG,
        'carbs_g': carbsG,
        'fat_g': fatG,
      };
      if (fiberG != null) body['fiber_g'] = fiberG;
      if (weightG != null) body['weight_g'] = weightG;
      if (portionMultiplier != null) body['portion_multiplier'] = portionMultiplier;
      if (foodItems != null) body['food_items'] = foodItems;
      if (itemEdits.isNotEmpty) {
        body['item_edits'] = itemEdits.map((e) => e.toJson()).toList();
      }

      final response = await _client.put(
        '/nutrition/food-logs/$logId',
        data: body,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating food log: $e');
      rethrow;
    }
  }

  /// Fetch per-field edit history for a food log.
  Future<List<FoodLogEditRecord>> listFoodLogEdits(String logId) async {
    try {
      final response = await _client.get('/nutrition/food-logs/$logId/edits');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(FoodLogEditRecord.fromJson)
          .toList();
    } catch (e) {
      debugPrint('Error listing food log edits: $e');
      rethrow;
    }
  }


  /// Move a food log to a different meal type
  Future<Map<String, dynamic>> moveFoodLog({
    required String logId,
    required String mealType,
  }) async {
    try {
      final response = await _client.put(
        '/nutrition/food-logs/$logId',
        data: {'meal_type': mealType},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error moving food log: $e');
      rethrow;
    }
  }


  /// Update the logged_at time on a food log
  Future<Map<String, dynamic>> updateFoodLogTime({
    required String logId,
    required String loggedAt,
  }) async {
    try {
      final response = await _client.put(
        '/nutrition/food-logs/$logId',
        data: {'logged_at': loggedAt},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating food log time: $e');
      rethrow;
    }
  }


  /// Update notes on a food log
  Future<Map<String, dynamic>> updateFoodLogNotes({
    required String logId,
    required String notes,
  }) async {
    try {
      final response = await _client.put(
        '/nutrition/food-logs/$logId',
        data: {'notes': notes},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating food log notes: $e');
      rethrow;
    }
  }


  /// Update mood/energy on a food log. On success, also cancels the 45-min
  /// reminder push if one was scheduled for this log — no point nudging the
  /// user after they've already answered.
  Future<Map<String, dynamic>> updateFoodLogMood({
    required String logId,
    String? moodBefore,
    String? moodAfter,
    int? energyLevel,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (moodBefore != null) body['mood_before'] = moodBefore;
      if (moodAfter != null) body['mood_after'] = moodAfter;
      if (energyLevel != null) body['energy_level'] = energyLevel;

      final response = await _client.patch(
        '/nutrition/food-logs/$logId/mood',
        data: body,
      );
      // Best-effort cancel — don't block the mood save if it throws.
      if (moodAfter != null || energyLevel != null) {
        try {
          await PostMealCheckinReminderService.instance.cancelForLog(logId);
        } catch (cancelErr) {
          debugPrint('⚠️ reminder cancel failed: $cancelErr');
        }
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updating food log mood: $e');
      rethrow;
    }
  }


  /// Copy a food log to a different meal type, optionally on a specific date
  Future<Map<String, dynamic>> copyFoodLog({
    required String logId,
    required String mealType,
    String? date,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/food-logs/$logId/copy',
        queryParameters: {
          'meal_type': mealType,
          if (date != null) 'target_date': date,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error copying food log: $e');
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
      final result = LogBarcodeResponse.fromJson(response.data);

      // Fire-and-forget: sync meal to Health Connect / HealthKit
      HealthService.syncMealToHealthIfEnabled(
        mealType: mealType,
        calories: result.totalCalories.toDouble(),
        proteinG: result.proteinG,
        carbsG: result.carbsG,
        fatG: result.fatG,
        name: result.productName,
      );

      return result;
    } catch (e) {
      debugPrint('Error logging food from barcode: $e');
      rethrow;
    }
  }


  /// Log food from image using AI Vision
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
      final result = LogFoodResponse.fromJson(response.data);

      // Fire-and-forget: sync meal to Health Connect / HealthKit
      HealthService.syncMealToHealthIfEnabled(
        mealType: mealType,
        calories: result.totalCalories.toDouble(),
        proteinG: result.proteinG,
        carbsG: result.carbsG,
        fatG: result.fatG,
        fiberG: result.fiberG,
        sodiumMg: result.sodiumMg,
        sugarG: result.sugarG,
        cholesterolMg: result.cholesterolMg,
        potassiumMg: result.potassiumMg,
        vitaminAIu: result.vitaminAIu,
        vitaminCMg: result.vitaminCMg,
        vitaminDIu: result.vitaminDIu,
        calciumMg: result.calciumMg,
        ironMg: result.ironMg,
        saturatedFatG: result.saturatedFatG,
      );

      return result;
    } catch (e) {
      debugPrint('Error logging food from image: $e');
      rethrow;
    }
  }


  /// Analyze natural-language food text (multi-item) without logging.
  /// Returns the raw response map from POST /nutrition/analyze-text.
  Future<Map<String, dynamic>> analyzeText(String description) async {
    try {
      final response = await _client.post(
        '/nutrition/analyze-text',
        data: {'description': description},
        options: Options(
          receiveTimeout: ApiConstants.aiReceiveTimeout,
        ),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error analyzing text: $e');
      rethrow;
    }
  }


  /// Log food from text description using AI
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
        options: Options(
          receiveTimeout: ApiConstants.aiReceiveTimeout,
        ),
      );
      final result = LogFoodResponse.fromJson(response.data);

      // Fire-and-forget: sync meal to Health Connect / HealthKit
      HealthService.syncMealToHealthIfEnabled(
        mealType: mealType,
        calories: result.totalCalories.toDouble(),
        proteinG: result.proteinG,
        carbsG: result.carbsG,
        fatG: result.fatG,
        fiberG: result.fiberG,
        sodiumMg: result.sodiumMg,
        sugarG: result.sugarG,
        cholesterolMg: result.cholesterolMg,
        potassiumMg: result.potassiumMg,
        vitaminAIu: result.vitaminAIu,
        vitaminCMg: result.vitaminCMg,
        vitaminDIu: result.vitaminDIu,
        calciumMg: result.calciumMg,
        ironMg: result.ironMg,
        saturatedFatG: result.saturatedFatG,
      );

      // Meal-suggestion widget refresh on log — staged, see Coming Soon.
      // _refreshMealSuggestionWidget();

      return result;
    } catch (e) {
      debugPrint('Error logging food from text: $e');
      rethrow;
    }
  }

  // Re-enable when the meal-suggestion widget feature goes live.
  // void _refreshMealSuggestionWidget() {
  //   try {
  //     MealSuggestionWidgetService.instance.refreshNow();
  //   } catch (_) {
  //     // intentional: widget refresh is never required to succeed
  //   }
  // }


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
    /// Specific input method (lowercase; see CHECK constraint for allowed values).
    String? inputType,
    String? notes,
    /// ISO-8601 timestamp for the food log. Pass the Nutrition-tab selected
    /// date (with current local time) when the user is reviewing a past day —
    /// otherwise the log lands on today by default.
    String? loggedAt,
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
    // Image storage
    String? imageUrl,
    String? imageStorageKey,
    // AI/vision description of the meal (preserved so the meal list shows
    // what the AI saw instead of the generic "Logged via image" placeholder).
    String? aiFeedback,
    // Originating user input (caption, dish name, chat prompt).
    String? userQuery,
    // Scores
    int? healthScore,
    int? overallMealScore,
    // Per-field edits made in the Log Meal sheet before saving (audit trail)
    List<FoodItemEdit> itemEdits = const [],
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
          if (inputType != null) 'input_type': inputType,
          if (notes != null) 'notes': notes,
          if (loggedAt != null) 'logged_at': loggedAt,
          if (imageUrl != null) 'image_url': imageUrl,
          if (imageStorageKey != null) 'image_storage_key': imageStorageKey,
          if (aiFeedback != null) 'ai_feedback': aiFeedback,
          if (userQuery != null) 'user_query': userQuery,
          if (healthScore != null) 'health_score': healthScore,
          if (overallMealScore != null) 'overall_meal_score': overallMealScore,
          if (itemEdits.isNotEmpty)
            'item_edits': itemEdits.map((e) => e.toJson()).toList(),
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
      final result = LogFoodResponse.fromJson(response.data);

      // Fire-and-forget: sync meal to Health Connect / HealthKit
      HealthService.syncMealToHealthIfEnabled(
        mealType: mealType,
        calories: totalCalories.toDouble(),
        proteinG: totalProtein.toDouble(),
        carbsG: totalCarbs.toDouble(),
        fatG: totalFat.toDouble(),
        fiberG: totalFiber?.toDouble(),
        sodiumMg: sodiumMg,
        sugarG: sugarG,
        saturatedFatG: saturatedFatG,
        cholesterolMg: cholesterolMg,
        potassiumMg: potassiumMg,
        vitaminAIu: vitaminAUg,
        vitaminCMg: vitaminCMg,
        vitaminDIu: vitaminDIu,
        calciumMg: calciumMg,
        ironMg: ironMg,
        name: foodItems.isNotEmpty ? (foodItems.first['name'] as String?) : null,
      );

      return result;
    } catch (e) {
      debugPrint('Error logging adjusted food: $e');
      rethrow;
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
    /// Specific input method — populates food_logs.input_type. Accepted values
    /// match the backend CHECK constraint: text, voice, camera, gallery,
    /// barcode, menu_scan, buffet_scan, multi_image_scan, chat, ai_suggestion,
    /// manual, image, copy, watch.
    String? inputType,
    /// ISO-8601 timestamp for the resulting food_log row. When the user is
    /// viewing a past date, pass it so the meal lands on THAT date rather
    /// than server-side "now".
    String? loggedAt,
    List<FoodItemEdit> itemEdits = const [],
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

    // Adjust food items — serialize typed rankings back to JSON maps for the
    // backend request, then apply the portion multiplier in-place.
    final adjustedItems = analyzedFood.foodItems.map((item) {
      final raw = item.toJson();
      return {
        ...raw,
        'calories': (((raw['calories'] as num?) ?? 0) * portionMultiplier).round(),
        'protein_g': (((raw['protein_g'] as num?) ?? 0) * portionMultiplier).round(),
        'carbs_g': (((raw['carbs_g'] as num?) ?? 0) * portionMultiplier).round(),
        'fat_g': (((raw['fat_g'] as num?) ?? 0) * portionMultiplier).round(),
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
      inputType: inputType,
      loggedAt: loggedAt,
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
      // Image storage and scores from analysis
      imageUrl: analyzedFood.imageUrl,
      imageStorageKey: analyzedFood.imageStorageKey,
      // Forward the vision description (analyze-image-stream aliases Gemini's
      // `feedback` string onto `ai_suggestion`). This is what the meal list
      // surfaces instead of the generic "Logged via image" placeholder.
      aiFeedback: analyzedFood.aiSuggestion,
      healthScore: analyzedFood.healthScore,
      overallMealScore: analyzedFood.overallMealScore,
      itemEdits: itemEdits,
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
    String? search,
    String? sortBy,
    String? sortOrder,
    double? minProteinG,
    int? maxCalories,
    String? tag,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'user_id': userId,
        'limit': limit,
        'offset': offset,
      };
      if (sourceType != null) queryParams['source_type'] = sourceType;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (minProteinG != null) queryParams['min_protein_g'] = minProteinG;
      if (maxCalories != null) queryParams['max_calories'] = maxCalories;
      if (tag != null) queryParams['tag'] = tag;

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


  /// Re-log a saved food, optionally on a specific date
  Future<LogFoodResponse> relogSavedFood({
    required String userId,
    required String savedFoodId,
    required String mealType,
    String? date,
  }) async {
    try {
      final response = await _client.post(
        '/nutrition/saved-foods/$savedFoodId/log',
        queryParameters: {
          'user_id': userId,
          if (date != null) 'target_date': date,
        },
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
    String sortBy = 'created_desc',
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


  /// Select a recommendation option (aggressive, moderate, conservative)
  Future<bool> selectRecommendationOption({
    required String userId,
    required String optionType,
  }) async {
    try {
      debugPrint('✅ [Nutrition] Selecting recommendation option: $optionType for $userId');
      await _client.post(
        '/nutrition/recommendations/$userId/select',
        data: {'option_type': optionType},
      );

      return true;
    } catch (e) {
      debugPrint('❌ [Nutrition] Error selecting recommendation option: $e');
      return false;
    }
  }

}
