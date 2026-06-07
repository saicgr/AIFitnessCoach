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
                          AppLocalizations.of(context).logMealSheetTipAddBrandPortion,
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

    // Solid footer surface. The capture chips and Analyze pill are themselves
    // translucent (tinted Material on the glass sheet); without an opaque
    // backing the scrolling results list reads straight through them. A near-
    // opaque fill + a hairline top divider seats the footer as a clear,
    // self-contained action bar over the glass body.
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: GlassSheetStyle.borderColor(isDark), width: 0.5),
        ),
      ),
      child: Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action row: 5 LABELED capture chips (Photo / Barcode / Menu /
          // Scan / Coach). Laid out as a single Row of equal-width Expanded
          // columns — icon stacked over a label — so all five always fit on
          // one line, from iPhone SE up to iPad. Photo and Scan open a small
          // chooser; Barcode, Menu and Coach act in one tap.
          //
          // Analyze stays the clear primary CTA: a filled accent pill on its
          // own full-width row below the lighter capture chips.
          Row(
            children: [
              // Photo — opens a 2-option chooser (camera / library).
              Expanded(
                child: _CaptureChip(
                  icon: Icons.photo_camera_outlined,
                  label: AppLocalizations.of(context).recipeImportPhoto,
                  color: const Color(0xFF3B82F6), // blue
                  isDark: isDark,
                  onTap: _openPhotoChooser,
                ),
              ),
              const SizedBox(width: 6),

              // Barcode — fastest, most-common scan; promoted to its own
              // top-level chip. One tap straight to the live scanner.
              Expanded(
                child: _CaptureChip(
                  icon: CupertinoIcons.barcode,
                  label: AppLocalizations.of(context).quickActionsRowBarcode,
                  color: const Color(0xFF10B981), // green
                  isDark: isDark,
                  onTap: _openBarcodeScanner,
                ),
              ),
              const SizedBox(width: 6),

              // Menu scan — signature feature, one tap straight to _scanMenu.
              Expanded(
                child: _CaptureChip(
                  icon: Icons.menu_book_outlined,
                  label: AppLocalizations.of(context).quickActionsRowMenu,
                  color: const Color(0xFFF59E0B), // amber
                  isDark: isDark,
                  onTap: _scanMenu,
                ),
              ),
              const SizedBox(width: 6),

              // Scan — opens a 2-option chooser (nutrition label / app
              // screenshot).
              Expanded(
                child: _CaptureChip(
                  icon: Icons.document_scanner_outlined,
                  label: AppLocalizations.of(context).quickLogFabScan,
                  color: const Color(0xFF8B5CF6), // violet
                  isDark: isDark,
                  onTap: _openScanChooser,
                ),
              ),
              const SizedBox(width: 6),

              // Coach — context-aware AI meal-suggestion popup. Fixed rose so
              // it never collides with the (orange-ish) accent / amber Menu
              // chip.
              Expanded(
                child: _CaptureChip(
                  icon: Icons.auto_awesome_outlined,
                  label: AppLocalizations.of(context).quickActionsRowCoach,
                  color: const Color(0xFFEC4899), // rose
                  isDark: isDark,
                  onTap: _openAiCoachSheet,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Analyze — primary CTA. Full-width filled accent pill, visually
          // dominant over the lighter capture chips above.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasText ? _handleAnalyze : null,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(AppLocalizations.of(context).nutritionShowcaseAnalyze,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: orange.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Daily macro summary pill
          _buildDailyMacroBar(isDark),
        ],
      ),
      ),
    );
  }

  // ─── Bottom-bar choosers ──────────────────────────────────────

  /// Photo chip → small 2-option chooser: take a photo with the camera
  /// (multi-shot loop) or choose existing photos from the library. Both
  /// delegate to the existing [_pickImages].
  Future<void> _openPhotoChooser() async {
    const blue = Color(0xFF3B82F6);
    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chooserHeader(
                      colors, blue, Icons.photo_camera_outlined, 'Add Food Photo'),
                  _GlassMenuOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(context).recipesTakePhoto,
                    subtitle: AppLocalizations.of(context).logMealSheetUpTo5Shots,
                    color: blue,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(context).logMealSheetChooseFromLibrary,
                    subtitle: AppLocalizations.of(context).logMealSheetPickUpTo5,
                    color: blue,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    await _pickImages(source);
  }

  /// Scan chip → 2-option chooser: nutrition label or app screenshot. Both
  /// route through the existing label/screenshot OCR flows. Barcode is now a
  /// dedicated top-level chip and no longer appears here.
  Future<void> _openScanChooser() async {
    const violet = Color(0xFF8B5CF6);
    final choice = await showGlassSheet<String>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final isDark = colors.isDark;
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chooserHeader(colors, violet,
                      Icons.document_scanner_outlined, 'Scan & Import'),
                  _GlassMenuOption(
                    icon: Icons.qr_code_2_outlined,
                    label: AppLocalizations.of(context).logMealSheetNutritionLabel,
                    subtitle: AppLocalizations.of(context).logMealSheetReadMacrosOffA,
                    color: violet,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'label'),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.screenshot_outlined,
                    label: AppLocalizations.of(context).logMealSheetScreenshot,
                    subtitle: AppLocalizations.of(context).logMealSheetImportALogFrom,
                    color: violet,
                    isDark: isDark,
                    onTap: () => Navigator.pop(ctx, 'screenshot'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'label':
        await _scanNutritionLabel();
        break;
      case 'screenshot':
        await _scanAppScreenshot();
        break;
    }
  }

  /// Shared header row for the bottom-bar choosers — matches the existing
  /// `_scanMenu` / `_openImportScanSheet` chooser styling (tinted icon tile +
  /// title).
  Widget _chooserHeader(
      ThemeColors colors, Color color, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDailyMacroBar(bool isDark) {
    final state = ref.watch(dailyNutritionProvider(todayNutritionKey()));
    final summary = state.summary;
    final targets = ref.watch(nutritionMetaProvider).targets;
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
            Text(AppLocalizations.of(context).habitsCardU1f525, style: const TextStyle(fontSize: 13)),
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
                              AppLocalizations.of(context).logMealSheetPortionsAdjustedReviewWei,
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

                // A3 — "Applied: …" note. When the user supplied an
                // instruction and it changed the analysis, the backend
                // returns a short past-tense summary of WHAT changed.
                if (response.appliedInstructionNote != null &&
                    response.appliedInstructionNote!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: orange.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_fix_high, size: 16, color: orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: textPrimary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Applied: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: orange,
                                    ),
                                  ),
                                  TextSpan(
                                    text: response.appliedInstructionNote!.trim(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // L3 — "It remembers you". When a learned per-user correction
                // (>= 2 consistent edits) was auto-applied, the backend
                // returns a short affirmation. Surfaced as a "Remembered" chip.
                if (response.rememberedMessage != null &&
                    response.rememberedMessage!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppColors.purple.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 16, color: AppColors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              response.rememberedMessage!.trim(),
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Gap 1 — water-in-text. When the entry also mentioned a
                // beverage, show that it'll be logged to hydration on confirm.
                if (_pendingHydration != null &&
                    ((_pendingHydration!['amount_ml'] as num?) ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.waterBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.waterBlue.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.water_drop_rounded,
                              size: 16, color: AppColors.waterBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '+${(_pendingHydration!['amount_ml'] as num).toInt()} ml water will be logged',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
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
                    Text(AppLocalizations.of(context).logMealSheetEstimatedNutrition, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                    if (response.overallMealScore != null) ...[
                      const SizedBox(width: 8),
                      CompactGoalScore(score: response.overallMealScore!, isDark: isDark),
                    ],
                    if (_analysisElapsedMs != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _analysisElapsedMs! < 500 ? AppLocalizations.of(context).logMealSheetCached : '(${(_analysisElapsedMs! / 1000).toStringAsFixed(1)}s)',
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
                      if (_capturedImagePath != null || response.imageUrl != null)
                        const SizedBox(width: 10),
                      // Text column beside the thumbnail: a one-line summary of
                      // the detected item names (so the user sees WHAT was
                      // detected without expanding the "N Food Items" section),
                      // plus the AI plate description underneath when present.
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_detectedItemsSummary(response).isNotEmpty)
                              Text(
                                _detectedItemsSummary(response),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (response.plateDescription != null && response.plateDescription!.isNotEmpty) ...[
                              if (_detectedItemsSummary(response).isNotEmpty)
                                const SizedBox(height: 3),
                              Text(
                                response.plateDescription!,
                                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // Action buttons row — a Wrap so the 5 actions (Save, Edit,
                // Add, Refine, Report) reflow to a second line on small
                // devices instead of overflowing.
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Order: Add · Refine · Edit · ★ · Report — the
                    // emphasized result-fixing actions lead, Favorite is
                    // secondary, the Report flag is always last.
                    // Manual "Add" chip — open a tiny text-input sheet, run
                    // text-analyze, append to current items. Avoids re-snapping.
                    Builder(builder: (ctx) {
                      final teal = isDark ? AppColors.teal : AppColorsLight.teal;
                      return GestureDetector(
                        onTap: _addingFoodItem
                            ? null
                            : () => _handleAddFoodItem(entryPoint: 'top_action_row'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: teal),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_addingFoodItem)
                                SizedBox(
                                  width: 12, height: 12,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: teal),
                                )
                              else
                                Icon(Icons.add, size: 14, color: teal),
                              const SizedBox(width: 4),
                              Text(AppLocalizations.of(context).logMealSheetAddSauceSide,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: teal,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Refine with AI — opens a correction note sheet, sends the
                    // note + current items to the streaming text-analysis
                    // endpoint framed as a correction, and REPLACES the item
                    // set with the result (Add appends — Refine replaces).
                    Builder(builder: (ctx) {
                      final purple = isDark ? AppColors.purple : AppColorsLight.purple;
                      return GestureDetector(
                        onTap: _refiningMeal ? null : _handleRefineMeal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_refiningMeal)
                              SizedBox(
                                width: 12, height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: purple),
                              )
                            else
                              Icon(Icons.auto_fix_high, size: 14, color: purple),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context).logMealSheetRefine,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: purple,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }),
                    // Edit — modify the analyzed values.
                    GestureDetector(
                      onTap: _handleEdit,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context).commonEdit, style: TextStyle(fontSize: 12, color: textMuted)),
                        ],
                      ),
                    ),
                    // Favorite — save this meal for one-tap re-logging.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _isSaved || _isSaving ? null : _handleSaveAsFavorite,
                      child: _isSaving
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary))
                          : Icon(_isSaved ? Icons.star : Icons.star_border, size: 22, color: _isSaved ? AppColors.yellow : textMuted),
                    ),
                    // Report — flag an inaccurate AI analysis. Always last.
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_outlined, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context).logMealSheetReport, style: TextStyle(fontSize: 12, color: textMuted)),
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
                    // Pass AI-emitted reasons through, falling back to local
                    // derivation if older response didn't include them.
                    healthScoreReasons: healthReasonsFromSignals(
                      aiReasons: response.healthScoreReasons,
                      calories: response.totalCalories,
                      proteinG: response.proteinG,
                      fiberG: response.fiberG,
                      sugarG: response.sugarG,
                      isUltraProcessed: response.isUltraProcessed,
                      inflammationScore: response.inflammationScore,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // L4 — "accuracy you can trust". Flag low-confidence items
                // and offer a single 1-tap confirm before the item list.
                _buildLowConfidenceReview(isDark, response),

                // Food items — always visible (primary content)
                if (response.foodItems.isNotEmpty)
                  CollapsibleFoodItemsSection(
                    foodItems: response.foodItemsRanked,
                    isDark: isDark,
                    onItemWeightChanged: (index, updatedItem) => _handleFoodItemWeightChange(index, updatedItem),
                    onItemRemoved: _handleFoodItemRemoved,
                    onItemFieldEdited: _handleFoodItemFieldEdited,
                    editedIndices: _pendingItemEdits.keys.toSet(),
                    onAddItem: _addingFoodItem
                        ? null
                        : () => _handleAddFoodItem(entryPoint: 'list_bottom'),
                  ),
                if (response.foodItems.isNotEmpty) const SizedBox(height: 12),

                // Smart sauce/side suggestions — tappable chips that append
                // instantly. Arrive with the deferred `coach_tips` event.
                _buildSuggestedAddons(isDark, response),

                // AI Coach Tip (also surfaces the personal_history pill when
                // the server flagged this food as one the user has had bad
                // reactions to before).
                //
                // The card renders when the analysis carries any tip field
                // OR while we're still awaiting the late `coach_tips` SSE
                // event (_awaitingCoachTip) — in which case it shows a
                // shimmer placeholder that swaps to the real tip on arrival.
                if (_awaitingCoachTip ||
                    (response.aiSuggestion != null && response.aiSuggestion!.trim().isNotEmpty) ||
                    (response.encouragements != null && response.encouragements!.any((e) => e.trim().isNotEmpty)) ||
                    (response.warnings != null && response.warnings!.any((w) => w.trim().isNotEmpty)) ||
                    (response.recommendedSwap != null && response.recommendedSwap!.trim().isNotEmpty) ||
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
                      isLoading: _awaitingCoachTip,
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

                // L1 — "every log is coaching". A live "fits your day" line,
                // one concrete next-meal suggestion, and (when well over
                // budget) a coach fork. Rendered right under the Coach's-take
                // so the two read as one coaching surface.
                _buildCoachingExtras(isDark, response),

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
                Text(AppLocalizations.of(context).logMealSheetEstimatesBasedOnYour, style: TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
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
              label: Text(_isSaving ? AppLocalizations.of(context).workoutReviewSaving : AppLocalizations.of(context).logMealSheetLogThisMeal, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

  /// One-line summary of detected food item names, e.g.
  /// "Whole grain pancakes · Blueberry compote · Maple syrup +1".
  /// Shows the first ~3 names joined with " · "; remaining items collapse
  /// into a "+N" suffix. Returns '' when there are no named items.
  String _detectedItemsSummary(dynamic response) {
    final items = response.foodItemsRanked as List;
    final names = items
        .map((it) => (it.name as String?)?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '';
    const shown = 3;
    if (names.length <= shown) return names.join('  ·  ');
    final extra = names.length - shown;
    return '${names.take(shown).join('  ·  ')}  +$extra';
  }

  void _showFullScreenImage(BuildContext context, String? localPath, String? networkUrl) {
    showFullscreenImage(
      context,
      localPath: localPath,
      networkUrl: networkUrl,
      heroTag: 'food_image_preview',
    );
  }

  // ─── L1 — "every log is coaching" ─────────────────────────────

  /// Renders the coaching extras under the Coach's-take:
  /// • a live "fits your day" line (calories + protein remaining vs targets,
  ///   scoped to the logged date — C7),
  /// • one concrete next-meal suggestion,
  /// • the over-budget coach fork (lighter next meal OR a tomorrow-workout
  ///   tweak) when the day is well over budget.
  /// Returns an empty box when there is nothing coach-worthy to show.
  /// Smart sauce/side suggestion chips. Each appends instantly on tap (no
  /// server round-trip). Renders nothing until the deferred `coach_tips` event
  /// supplies suggestions.
  Widget _buildSuggestedAddons(bool isDark, LogFoodResponse response) {
    final addons = response.suggestedAddons;
    if (addons == null || addons.isEmpty) return const SizedBox.shrink();

    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_outlined, size: 15, color: textMuted),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).logMealSheetAddSauceOrSide,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final addon in addons)
                GestureDetector(
                  onTap: () => _addSuggestedAddon(addon),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: teal.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: teal),
                        const SizedBox(width: 4),
                        Text(
                          addon.name,
                          style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                        if (addon.calories > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            '${addon.calories} kcal',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCoachingExtras(bool isDark, LogFoodResponse response) {
    final fits = _computeFitsYourDay();
    final nextMeal = response.nextMealSuggestion?.trim() ?? '';
    final fork = response.overBudgetFork;

    // C7 — only show the fork when the day is genuinely over budget AND it
    // is not a planned refeed / high-output day (don't guilt a planned day).
    final overBudget = fits != null && fits.caloriesRemaining < 0;
    final showFork =
        fork != null && overBudget && !fits.isPlannedHighDay;

    // Nothing to render — skip entirely (e.g. no targets set, no suggestion).
    if (fits == null && nextMeal.isEmpty) return const SizedBox.shrink();

    final accent = AccentColorScope.of(context).getColor(isDark);
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              teal.withValues(alpha: 0.10),
              teal.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teal.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── "Fits your day" line (C7 — skipped when no targets) ──
            if (fits != null) ...[
              Row(
                children: [
                  Icon(
                      overBudget
                          ? Icons.warning_amber_rounded
                          : Icons.track_changes_rounded,
                      size: 16,
                      color: overBudget ? AppColors.coral : teal),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text('${fits.dateLabel}: ',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted)),
                          Text(
                            overBudget
                                ? '${(-fits.caloriesRemaining)} kcal over'
                                : '${fits.caloriesRemaining} kcal left',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: overBudget
                                    ? AppColors.coral
                                    : textPrimary),
                          ),
                          if (fits.proteinRemaining != null) ...[
                            Text(' · ',
                                style: TextStyle(
                                    fontSize: 13.5, color: textMuted)),
                            Text(
                              '${fits.proteinRemaining! < 0 ? 0 : fits.proteinRemaining}g protein left',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: purple),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (fits.isPlannedHighDay && overBudget) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).logMealSheetPlannedHighOutputDay,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: textMuted),
                ),
              ],
            ],

            // ── Concrete next-meal suggestion ────────────────────────
            if (nextMeal.isNotEmpty) ...[
              if (fits != null) const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.restaurant_rounded, size: 16, color: accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 13, height: 1.4, color: textPrimary),
                        children: [
                          TextSpan(
                            text: 'Next meal: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: accent),
                          ),
                          TextSpan(text: nextMeal),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Over-budget coach fork (C7 — suppressed on planned days) ──
            if (showFork) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).logMealSheetOverBudgetPickOne,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMuted),
              ),
              const SizedBox(height: 8),
              _coachForkOption(
                isDark,
                Icons.local_dining_outlined,
                'Lighter next meal',
                fork.lighterNextMeal,
                accent,
              ),
              const SizedBox(height: 8),
              _coachForkOption(
                isDark,
                Icons.fitness_center_rounded,
                'Tomorrow workout tweak',
                fork.workoutTweak,
                purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _coachForkOption(bool isDark, IconData icon, String title,
      String body, Color color) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: textPrimary.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── L4 — "accuracy you can trust" ────────────────────────────

  /// Flags low-confidence food items with a single 1-tap "Looks right"
  /// confirm. C10 — when EVERY item is low-confidence (bad photo) we ask the
  /// user to re-photo instead of firing N separate confirmations. Verified
  /// (override-DB cross-checked) items are never flagged.
  Widget _buildLowConfidenceReview(bool isDark, LogFoodResponse response) {
    final items = response.foodItemsRanked;
    if (items.isEmpty) return const SizedBox.shrink();

    final lowIdx = <int>[];
    var verifiedCount = 0;
    for (var i = 0; i < items.length; i++) {
      if (items[i].isLowConfidence) lowIdx.add(i);
      if (items[i].isVerified) verifiedCount++;
    }

    // L4 — when nothing is shaky but some items were cross-checked against
    // verified food-DB data, surface that as a small trust signal so the
    // user knows the numbers aren't a pure guess.
    if (lowIdx.isEmpty) {
      if (verifiedCount == 0) return const SizedBox.shrink();
      final teal = isDark ? AppColors.teal : AppColorsLight.teal;
      final tMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
      // F2 — tappable "source" affordance: opens a sheet listing which items
      // were cross-checked against verified data and the matched source row.
      final verifiedItems =
          items.where((i) => i.isVerified).toList(growable: false);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          button: true,
          label: 'View verified nutrition source',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showVerifiedSourceSheet(isDark, verifiedItems),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      verifiedCount == items.length
                          ? AppLocalizations.of(context).logMealSheetAllItemsMatchedVerified
                          : '$verifiedCount of ${items.length} items matched verified nutrition data',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: tMuted),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: tMuted),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const amber = Color(0xFFF59E0B);

    // C10 — every item shaky → one re-photo prompt, not a confirm storm.
    final allLow = lowIdx.length == items.length && items.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: amber.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 16, color: amber),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    allLow
                        ? AppLocalizations.of(context).logMealSheetThisPhotoWasHard
                        : 'Quick check — ${lowIdx.length == 1 ? 'one item is' : '${lowIdx.length} items are'} a rough estimate',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (allLow) ...[
              Text(
                'I couldn’t estimate these confidently. Re-take a clearer, '
                'well-lit photo for a better result — or edit the values below.',
                style: TextStyle(
                    fontSize: 12, height: 1.4, color: textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text(AppLocalizations.of(context).logMealSheetReTakePhoto,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: amber,
                    side: const BorderSide(color: amber),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).logMealSheetTapToConfirmEach,
                      style: TextStyle(
                          fontSize: 12, height: 1.35, color: textMuted),
                    ),
                  ),
                  // F2 — "Why this estimate?" explainer for low-confidence items.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showWhyEstimateSheet(
                        isDark, [for (final i in lowIdx) items[i]]),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Why this estimate?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: amber,
                          decoration: TextDecoration.underline,
                          decorationColor: amber.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final idx in lowIdx)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _lowConfidenceRow(isDark, idx, items[idx], amber),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lowConfidenceRow(
      bool isDark, int index, FoodItemRanking item, Color amber) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final reasoning = item.estimateReasoning?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name}${item.amount != null && item.amount!.isNotEmpty ? ' · ${item.amount}' : ''}',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // L4 — grounded reasoning ("~220g; plate reads ~10in"),
                // shown only when the backend supplied a real basis.
                if (reasoning.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reasoning,
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _confirmFoodItem(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: amber,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(AppLocalizations.of(context).logMealSheetLooksRight,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// F2 — "Verified from <source>" sheet. Lists each cross-checked item and the
  /// matched source row (override DB / global DB) so the user can see the
  /// numbers came from real verified data, not a pure AI guess.
  void _showVerifiedSourceSheet(bool isDark, List<FoodItemRanking> verified) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    String sourceLabel(String? src) {
      switch (src) {
        case 'override_db':
          return 'Verified food database';
        case 'global_db':
          return 'Global nutrition database';
        default:
          return 'Verified nutrition data';
      }
    }

    showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, size: 20, color: teal),
                  const SizedBox(width: 8),
                  Text('Verified nutrition source',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'These items were cross-checked against verified nutrition '
                'data, so the numbers are more than an AI estimate.',
                style: TextStyle(fontSize: 13, height: 1.4, color: textMuted),
              ),
              const SizedBox(height: 14),
              ...verified.map((item) {
                final matched = item.verifiedMatchName?.trim();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        matched != null && matched.isNotEmpty
                            ? 'Matched: $matched · ${sourceLabel(item.verifiedSource)}'
                            : sourceLabel(item.verifiedSource),
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// F2 — "Why this estimate?" explainer for low-confidence items. Shows the
  /// grounded reasoning the backend supplied (or a factual fallback) so the
  /// user understands what the estimate is based on and can edit it.
  void _showWhyEstimateSheet(bool isDark, List<FoodItemRanking> lowItems) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const amber = Color(0xFFF59E0B);

    showGlassSheet(
      context: context,
      builder: (_) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, size: 20, color: amber),
                  const SizedBox(width: 8),
                  Text('Why this estimate?',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'These items were estimated from the photo or text without a '
                'verified database match. Here is what each estimate is based '
                'on — tap "Looks right" to confirm, or edit the values.',
                style: TextStyle(fontSize: 13, height: 1.4, color: textMuted),
              ),
              const SizedBox(height: 14),
              ...lowItems.map((item) {
                final reasoning = item.estimateReasoning?.trim();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        reasoning != null && reasoning.isNotEmpty
                            ? reasoning
                            : 'Estimated from the image/description; no verified '
                                'database match was found, so values may vary.',
                        style: TextStyle(
                            fontSize: 12, height: 1.35, color: textMuted),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

}

/// Labeled capture action used in the Search-mode bottom bar — a compact
/// icon + text chip. Replaces the old bare [ActionIconButton] icons so every
/// action is self-describing. Sized to keep four chips on one line on an
/// iPhone SE, but laid out inside a [Wrap] so it degrades gracefully.
class _CaptureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _CaptureChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    // Vertical layout (icon over label) so five equal-width chips fit on a
    // single Row. The label is wrapped in a FittedBox(scaleDown) so even on
    // the narrowest device ('Barcode' on an iPhone SE) it shrinks to fit
    // rather than overflowing or wrapping.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.30 : 0.28),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
