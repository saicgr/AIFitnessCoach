part of 'log_meal_sheet.dart';

/// UI builder methods extracted from _LogMealSheetState
extension _LogMealSheetStateUI on _LogMealSheetState {

  // ─── Input quality hint ────────────────────────────────────────

  Widget _buildInputQualityHint(bool isDark) {
    final text = _descriptionController.text;
    final trimmed = text.trim();
    final isVague = trimmed.isNotEmpty &&
        trimmed.split(RegExp(r'\s+')).length <= 2 &&
        !RegExp(r'\d').hasMatch(text);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        opacity: isVague ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: isVague
            ? Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.amber.withValues(alpha: 0.12)
                        : Colors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: isDark ? 0.25 : 0.30),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: isDark ? Colors.amber[300] : Colors.amber[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tip: Add brand & portion for better accuracy (e.g., 'Chipotle chicken bowl' or '2 slices Domino\u2019s')",
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark ? Colors.amber[200] : Colors.amber[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }


  // ─── Header ───────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    final timeText = _selectedTime.format(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          // Time picker pill
          GestureDetector(
            onTap: _showTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 16, color: textMuted),
                  const SizedBox(width: 6),
                  Text(timeText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Meal type pill
          GestureDetector(
            onTap: _showMealTypePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: glassSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedMealType.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(_selectedMealType.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: textMuted),
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }


  // ─── Bottom Bar ───────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    final accentEnum = AccentColorScope.of(context);
    final orange = accentEnum.getColor(isDark);
    final hasText = _descriptionController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, MediaQuery.of(context).padding.bottom + 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons row: icon buttons left, analyze pill right
          Row(
            children: [
              // Mic button
              ActionIconButton(
                icon: _isListening ? Icons.stop : Icons.mic,
                isActive: _isListening,
                onTap: _toggleVoiceInput,
                isDark: isDark,
                color: const Color(0xFFEF4444), // red
              ),
              const SizedBox(width: 2),

              // Camera button
              ActionIconButton(
                icon: Icons.camera_alt,
                onTap: () => _pickImage(ImageSource.camera),
                isDark: isDark,
                color: const Color(0xFF3B82F6), // blue
              ),
              const SizedBox(width: 2),

              // Gallery button
              ActionIconButton(
                icon: Icons.photo_library_outlined,
                onTap: () => _pickImage(ImageSource.gallery),
                isDark: isDark,
                color: const Color(0xFF8B5CF6), // purple
              ),
              const SizedBox(width: 2),

              // Barcode button
              ActionIconButton(
                icon: Icons.qr_code_scanner,
                onTap: _openBarcodeScanner,
                isDark: isDark,
                color: const Color(0xFF10B981), // green
              ),
              const SizedBox(width: 2),

              // AI Coach button — opens a context-aware popup with preset
              // questions informed by today's logged meals, workout, and
              // favorites. Does NOT replace the Analyze pill.
              ActionIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: _openAiCoachSheet,
                isDark: isDark,
                color: AccentColorScope.of(context).getColor(isDark),
              ),

              const Spacer(),

              // Analyze pill button
              ElevatedButton.icon(
                onPressed: hasText ? _handleAnalyze : null,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Analyze', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: orange.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Daily macro summary pill
          _buildDailyMacroBar(isDark),
        ],
      ),
    );
  }


  Widget _buildDailyMacroBar(bool isDark) {
    final state = ref.watch(nutritionProvider);
    final summary = state.todaySummary;
    final targets = state.targets;
    final prefsState = ref.watch(nutritionPreferencesProvider);
    final dynamicTargets = prefsState.dynamicTargets;

    final cal = summary?.totalCalories ?? 0;
    final carbs = summary?.totalCarbsG.round() ?? 0;
    final protein = summary?.totalProteinG.round() ?? 0;
    final fat = summary?.totalFatG.round() ?? 0;

    final calTarget = prefsState.currentCalorieTarget;
    final carbsTarget = prefsState.currentCarbsTarget;
    final proteinTarget = prefsState.currentProteinTarget;
    final fatTarget = prefsState.currentFatTarget;

    // Build adjustment label for training/rest day
    final adjustmentLabel = dynamicTargets != null &&
            dynamicTargets.adjustmentReason != 'base_targets' &&
            dynamicTargets.calorieAdjustment != 0
        ? ' (${dynamicTargets.calorieAdjustment > 0 ? '+' : ''}${dynamicTargets.calorieAdjustment})'
        : '';

    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final amber = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final purple = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final coral = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    Widget macroSegment(String label, int value, int target, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 2),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
          Text('/$target', style: TextStyle(fontSize: 13, color: textMuted)),
        ],
      );
    }

    final separator = Text(' · ', style: TextStyle(fontSize: 13, color: textMuted));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calories
            Text('\u{1F525}', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 2),
            Text('$cal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            Text('/$calTarget', style: TextStyle(fontSize: 13, color: textMuted)),
            if (adjustmentLabel.isNotEmpty)
              Text(adjustmentLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF26A69A))),
            separator,
            macroSegment('C', carbs, carbsTarget, amber),
            separator,
            macroSegment('P', protein, proteinTarget, purple),
            separator,
            macroSegment('F', fat, fatTarget, coral),
          ],
        ),
      ),
    );
  }


  // ─── Nutrition Preview ────────────────────────────────────────

  Widget _buildNutritionPreview(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accentEnumPreview = AccentColorScope.of(context);
    final orange = accentEnumPreview.getColor(isDark);

    final response = _analyzedResponse!;
    final description = _descriptionController.text.trim();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity mismatch warning
                if (_hasQuantityMismatch(description, response.foodItemsRanked))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: orange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Portions adjusted — review weights below',
                              style: TextStyle(fontSize: 11, color: orange, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Source label banner (for contextual meal references)
                if (response.sourceLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.teal : AppColorsLight.teal).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isDark ? AppColors.teal : AppColorsLight.teal).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16, color: isDark ? AppColors.teal : AppColorsLight.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              response.sourceLabel!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.teal : AppColorsLight.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Estimated Nutrition header — two rows
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text('Estimated Nutrition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    if (response.overallMealScore != null) ...[
                      const SizedBox(width: 8),
                      CompactGoalScore(score: response.overallMealScore!, isDark: isDark),
                    ],
                    if (_analysisElapsedMs != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _analysisElapsedMs! < 500 ? '(Cached)' : '(${(_analysisElapsedMs! / 1000).toStringAsFixed(1)}s)',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ],
                ),
                // Plate description + food image thumbnail (image analysis only)
                if (_sourceType == 'image' && (response.plateDescription != null && response.plateDescription!.isNotEmpty || _capturedImagePath != null || response.imageUrl != null)) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food image thumbnail
                      if (_capturedImagePath != null || response.imageUrl != null)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(context, _capturedImagePath, response.imageUrl),
                          child: Hero(
                            tag: 'food_image_preview',
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _capturedImagePath != null
                                        ? Image.file(
                                            File(_capturedImagePath!),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            response.imageUrl!,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if ((_capturedImagePath != null || response.imageUrl != null) && response.plateDescription != null && response.plateDescription!.isNotEmpty)
                        const SizedBox(width: 10),
                      // Plate description text
                      if (response.plateDescription != null && response.plateDescription!.isNotEmpty)
                        Expanded(
                          child: Text(
                            response.plateDescription!,
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textMuted),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // Action buttons row
                Row(
                  children: [
                    // Star button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isSaved || _isSaving ? null : _handleSaveAsFavorite,
                      child: _isSaving
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary))
                          : Icon(_isSaved ? Icons.star : Icons.star_border, size: 22, color: _isSaved ? AppColors.yellow : textMuted),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _handleEdit,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Flag / report inaccuracy
                    GestureDetector(
                      onTap: () {
                        final items = response.foodItemsRanked;
                        final mainFood = items.isNotEmpty ? items.first.name : description;
                        showFoodReportDialog(
                          context,
                          apiClient: ref.read(apiClientProvider),
                          foodName: mainFood,
                          originalCalories: response.totalCalories,
                          originalProtein: response.proteinG,
                          originalCarbs: response.carbsG,
                          originalFat: response.fatG,
                          dataSource: 'ai_analysis',
                          originalQuery: description,
                          allFoodItems: items.map((f) => f.toJson()).toList(),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text('Report', style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Search query display — tap to go back to input
                if (description.isNotEmpty)
                  GestureDetector(
                    onTap: _handleEdit,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '"$description"',
                              style: TextStyle(
                                fontSize: 15,
                                color: textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 12, color: textMuted),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Compact macros row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      AnimatedCalorieChip(calories: response.totalCalories, color: AppColors.coral),
                      CompactMacroChip(icon: Icons.fitness_center, value: '${response.proteinG.toStringAsFixed(0)}g', unit: 'Protein', color: AppColors.macroProtein),
                      CompactMacroChip(icon: Icons.grain, value: '${response.carbsG.toStringAsFixed(0)}g', unit: 'Carbs', color: AppColors.macroCarbs),
                      CompactMacroChip(icon: Icons.opacity, value: '${response.fatG.toStringAsFixed(0)}g', unit: 'Fat', color: AppColors.macroFat),
                    ],
                  ),
                ),
                // Secondary score breakdown (health score + goal alignment %)
                if (response.healthScore != null ||
                    response.goalAlignmentPercentage != null) ...[
                  const SizedBox(height: 8),
                  MealScoreBreakdownRow(
                    healthScore: response.healthScore,
                    goalAlignmentPercentage: response.goalAlignmentPercentage,
                  ),
                ],
                const SizedBox(height: 12),

                // Food items — always visible (primary content)
                if (response.foodItems.isNotEmpty)
                  CollapsibleFoodItemsSection(
                    foodItems: response.foodItemsRanked,
                    isDark: isDark,
                    onItemWeightChanged: (index, updatedItem) => _handleFoodItemWeightChange(index, updatedItem),
                    onItemRemoved: _handleFoodItemRemoved,
                    onItemFieldEdited: _handleFoodItemFieldEdited,
                    editedIndices: _pendingItemEdits.keys.toSet(),
                  ),
                if (response.foodItems.isNotEmpty) const SizedBox(height: 12),

                // AI Coach Tip (also surfaces the personal_history pill when
                // the server flagged this food as one the user has had bad
                // reactions to before).
                if (response.aiSuggestion != null ||
                    (response.encouragements != null && response.encouragements!.isNotEmpty) ||
                    (response.warnings != null && response.warnings!.isNotEmpty) ||
                    (response.personalHistoryNote != null &&
                        response.personalHistoryNote!.trim().isNotEmpty))
                  Builder(builder: (_) {
                    final aiSettings = ref.read(aiSettingsProvider);
                    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
                    return CollapsibleAISuggestion(
                      suggestion: response.aiSuggestion,
                      encouragements: response.encouragements,
                      warnings: response.warnings,
                      recommendedSwap: response.recommendedSwap,
                      personalHistoryNote: response.personalHistoryNote,
                      isDark: isDark,
                      coach: coach,
                      onHistoryTap: () {
                        // Close the meal log sheet, then jump into the
                        // Patterns tab so the user can see the full history.
                        Navigator.of(context).pop();
                        // Give the nav stack a frame to settle before routing.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          try {
                            context.go('/nutrition?tab=2');
                          } catch (_) {
                            // If router isn't ready, silently fall back —
                            // the user is already back on the Nutrition screen.
                          }
                        });
                      },
                    );
                  }),

                // Inflammation score + ultra-processed tags (before macros deep-dive)
                if (response.inflammationScore != null ||
                    response.isUltraProcessed == true) ...[
                  const SizedBox(height: 12),
                  InflammationTagsSection(
                    inflammationScore: response.inflammationScore,
                    isUltraProcessed: response.isUltraProcessed,
                    isDark: isDark,
                  ),
                ],

                // Micronutrients
                if (_hasMicronutrients(response)) ...[
                  const SizedBox(height: 12),
                  MicronutrientsSection(response: response, isDark: isDark),
                ],

                const SizedBox(height: 8),
                Text('Estimates based on your photo/description', style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),

        // Fixed Log button at bottom
        Padding(
          key: AppTourKeys.logMealButtonKey,
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleLog,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Log This Meal', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: orange.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String? localPath, String? networkUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'food_image_preview',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: localPath != null
                            ? Image.file(File(localPath), fit: BoxFit.contain)
                            : Image.network(networkUrl!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
