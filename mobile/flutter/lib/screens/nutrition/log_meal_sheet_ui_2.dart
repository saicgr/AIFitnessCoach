part of 'log_meal_sheet.dart';

/// Methods extracted from _LogMealSheetState
extension __LogMealSheetStateExt2 on _LogMealSheetState {

  // ─── Input View ───────────────────────────────────────────────

  /// Top-level input view. A Search | Snap | Describe | Voice segmented
  /// control sits above a mode-specific body. Search is the first tab and
  /// the default mode; the other tabs surface the AI-logging paths.
  Widget _buildInputView(bool isDark) {
    return Column(
      children: [
        // Back to results button (only when returning from results view)
        if (_previousResponse != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: GestureDetector(
              onTap: _handleBackToResults,
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 14,
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context).logMealSheetBackToResults,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

        // Snap | Describe | Search segmented control
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _buildAiModeSelector(isDark),
        ),

        // Mode-specific body
        Expanded(
          child: switch (_aiMode) {
            _AiLogMode.snap => _buildSnapPanel(isDark),
            _AiLogMode.describe => _buildDescribePanel(isDark),
            _AiLogMode.voice => _buildVoicePanel(isDark),
            _AiLogMode.search => _buildSearchPanel(isDark),
          },
        ),
      ],
    );
  }

  // ─── Mode selector ────────────────────────────────────────────

  Widget _buildAiModeSelector(bool isDark) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    Widget seg(_AiLogMode mode, IconData icon, String label) {
      final selected = _aiMode == mode;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isAnalyzing || _isLoading || _describeAnalyzing
              ? null
              : () => setState(() => _aiMode = mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              // The one active state per selector uses the reserved accent.
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            // 4 segments must not overflow on an iPhone SE — FittedBox
            // scales the icon+label down before it can clip.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16,
                      color: selected ? tc.accentContrast : textMuted),
                  const SizedBox(width: 5),
                  Text(
                    label.toUpperCase(),
                    style: ZType.lbl(12.5,
                        color: selected ? tc.accentContrast : textMuted,
                        letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Search is the first tab and the sheet's default mode — the
          // typed food-search / browser path the user reaches for most.
          seg(_AiLogMode.search, Icons.search_rounded, 'Search'),
          seg(_AiLogMode.snap, Icons.bolt_rounded, 'Snap'),
          seg(_AiLogMode.describe, Icons.notes_rounded, 'Describe'),
          // L2 — Voice is a first-class hands-free mode, not a buried
          // mic icon.
          seg(_AiLogMode.voice, Icons.mic_rounded, 'Voice'),
        ],
      ),
    );
  }

  // ─── Snap panel ───────────────────────────────────────────────

  /// Snap — one tap → camera → instant single-photo analysis. Minimal
  /// chrome, fastest path. The result sheet is fully refinable.
  Widget _buildSnapPanel(bool isDark) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLoading ? null : () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent,
                    accent.withValues(alpha: 0.78),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 44, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context).logMealSheetSnapAPhoto,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).logMealSheetOneTapInstantNutrition,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Secondary affordance: snap from the gallery instead.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLoading ? null : () => _pickImage(ImageSource.gallery),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 16, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).logMealSheetPickFromGallery,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppLocalizations.of(context).logMealSheetNeedToAddNotes,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 18),
          // Other scan paths stay one tap away.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _snapSecondaryChip(isDark, Icons.qr_code_scanner,
                  'Barcode', _openBarcodeScanner),
              _snapSecondaryChip(isDark, Icons.menu_book_outlined,
                  'Scan menu', _scanMenu),
              _snapSecondaryChip(isDark, Icons.chat_bubble_outline_rounded,
                  'Ask coach', _openAiCoachSheet),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).logMealSheetAiEstimatesFromA,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: textMuted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapSecondaryChip(
      bool isDark, IconData icon, String label, VoidCallback onTap) {
    final tc = ThemeColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tc.textSecondary),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: ZType.lbl(11, color: tc.textSecondary, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Describe panel ───────────────────────────────────────────

  /// Describe — multi-photo picker + a prominent instruction field +
  /// one Analyze button → one round trip. Either photos OR text is
  /// enough to analyze (edge case C3).
  Widget _buildDescribePanel(bool isDark) {
    final tc = ThemeColors.of(context);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = tc.accent;
    final hasPhotos = _describePhotos.isNotEmpty;
    final hasInput = hasPhotos ||
        _describeInstructionController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo picker ───────────────────────────────────────
          ZealovaSectionKicker(AppLocalizations.of(context).progressPhotos),
          const SizedBox(height: 3),
          Text(
            'Add up to 5 photos — the meal, its components, or a menu. '
            '3 clear shots work best.',
            style: TextStyle(fontSize: 11.5, height: 1.4, color: textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < _describePhotos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _describeThumb(isDark, i),
                  ),
                if (_describePhotos.length < 5)
                  _describeAddTile(isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Instruction field ──────────────────────────────────
          ZealovaSectionKicker(AppLocalizations.of(context).logMealSheetInstructionsOptional),
          const SizedBox(height: 3),
          Text(
            AppLocalizations.of(context).logMealSheetTellTheAiAnything,
            style: TextStyle(fontSize: 11.5, height: 1.4, color: textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _describeInstructionController,
              minLines: 2,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: tc.textPrimary, fontSize: 15, height: 1.4),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: AppLocalizations.of(context).logMealSheetEGGrilledChicken,
                hintStyle: TextStyle(
                    color: textMuted.withValues(alpha: 0.7), fontSize: 14, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Example hint chips — tapping appends the phrase.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hint in const [
                'I ate half',
                'exclude the bread',
                'no oil',
                'the plate is ~10in',
              ])
                _describeHintChip(isDark, hint),
            ],
          ),
          const SizedBox(height: 18),

          // ── Analyze button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!hasInput || _describeAnalyzing)
                  ? null
                  : _handleDescribeAnalyze,
              icon: _describeAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _describeAnalyzing ? AppLocalizations.of(context).recipeBuilderSheetAnalyzing : AppLocalizations.of(context).nutritionShowcaseAnalyze,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (!hasInput) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).logMealSheetAddAPhotoOr,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5, color: textMuted, fontStyle: FontStyle.italic),
            ),
          ],

          // L1 / seam-fix 2 — the daily "remaining today" line. It lived in
          // the old Search-mode bottom bar and was lost from Snap/Describe;
          // re-surface it here so the user always sees their budget.
          const SizedBox(height: 14),
          _buildRemainingTodayLine(isDark),

          const SizedBox(height: 14),
          // Seam-fix 1 — scan-label / scan-app-screenshot belong with the
          // photo flows, so they live in Describe (not buried in Search).
          // Barcode + menu remain reachable from Describe too.
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _snapSecondaryChip(isDark, Icons.qr_code_2_outlined,
                    'Scan label', _scanNutritionLabel),
                _snapSecondaryChip(isDark, Icons.screenshot_outlined,
                    'Scan screenshot', _scanAppScreenshot),
                _snapSecondaryChip(
                    isDark, Icons.qr_code_scanner, 'Barcode', _openBarcodeScanner),
                _snapSecondaryChip(
                    isDark, Icons.menu_book_outlined, 'Scan menu', _scanMenu),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// L1 — compact "fits your day" line for the input panels. Shows calories
  /// and protein remaining vs the user's targets, scoped to the sheet's
  /// [selectedDate] (so a PAST-date log reads that date — C7). Returns an
  /// empty box when the user has no targets set (C7 "no targets → skip").
  Widget _buildRemainingTodayLine(bool isDark) {
    final fits = _computeFitsYourDay();
    if (fits == null) return const SizedBox.shrink();

    final accent = AccentColorScope.of(context).getColor(isDark);
    final tc = ThemeColors.of(context);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final over = fits.caloriesRemaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(over ? Icons.warning_amber_rounded : Icons.track_changes_rounded,
              size: 15, color: over ? AppColors.coral : accent),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    fits.dateLabel,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textMuted),
                  ),
                  Text('  ', style: TextStyle(fontSize: 12.5, color: textMuted)),
                  Text(
                    over
                        ? '${(-fits.caloriesRemaining)} kcal over'
                        : '${fits.caloriesRemaining} kcal left',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: over ? AppColors.coral : textPrimary),
                  ),
                  if (fits.proteinRemaining != null) ...[
                    Text(' · ',
                        style: TextStyle(fontSize: 13, color: textMuted)),
                    Text(
                      '${fits.proteinRemaining! < 0 ? 0 : fits.proteinRemaining}g protein left',
                      style: TextStyle(
                          fontSize: 13,
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
    );
  }

  Widget _describeThumb(bool isDark, int index) {
    final file = _describePhotos[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(file.path),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _describePhotos.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _describeAddTile(bool isDark) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _describeAnalyzing ? null : _addDescribePhotos,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.45),
            width: 1.2,
          ),
          color: accent.withValues(alpha: 0.06),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 22, color: accent),
            const SizedBox(height: 4),
            Text(
              _describePhotos.isEmpty ? AppLocalizations.of(context).tilePickerAdd : '${_describePhotos.length}/5',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _describeHintChip(bool isDark, String hint) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final current = _describeInstructionController.text.trimRight();
        final next = current.isEmpty ? hint : '$current, $hint';
        _describeInstructionController.text = next;
        _describeInstructionController.selection =
            TextSelection.collapsed(offset: next.length);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 13, color: accent),
            const SizedBox(width: 4),
            Text(
              hint,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: accent),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search panel ─────────────────────────────────────────────

  /// Search — the existing typed food-search + browser experience.
  Widget _buildSearchPanel(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Reserved accent for the single active listening state (was a hardcoded
    // orange literal).
    final orange = ThemeColors.of(context).accent;

    return Column(
      children: [
        // L2 — meal-slot prediction hint + one-tap re-log strip sit at
        // the top of Search so a repeat meal is a single tap away.
        if (!_isListening) ...[
          _buildMealSlotPredictionHint(isDark),
          _buildFrequentMealsStrip(isDark),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                focusNode: _textFieldFocusNode,
                maxLines: null,
                minLines: 2,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _triggerImmediateSearch(),
                style: TextStyle(color: textPrimary, fontSize: 18, height: 1.4),
                decoration: InputDecoration(
                  hintText: _isListening ? AppLocalizations.of(context).quickLogFabListening : AppLocalizations.of(context).nutritionShowcaseWhatDidYouEat,
                  hintStyle: TextStyle(
                    color: _isListening ? orange : textMuted.withValues(alpha: 0.6),
                    fontSize: 18,
                    fontStyle: _isListening ? FontStyle.italic : FontStyle.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _descriptionController.text.trim().length >= 3
                      ? IconButton(
                          icon: Icon(Icons.search, color: textMuted, size: 22),
                          onPressed: _triggerImmediateSearch,
                          tooltip: AppLocalizations.of(context).logMealSheetSearchFoods,
                        )
                      : IconButton(
                          icon: Icon(
                            _isListening
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                            color: _isListening
                                ? const Color(0xFFEF4444)
                                : textMuted,
                            size: 22,
                          ),
                          onPressed: _toggleVoiceInput,
                          tooltip:
                              _isListening ? AppLocalizations.of(context).logMealSheetStopListening : AppLocalizations.of(context).logMealSheetVoiceInput,
                        ),
                ),
              ),
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(orange)),
                      ),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context).logMealSheetSpeakNowTapMic,
                          style: TextStyle(
                              fontSize: 12,
                              color: orange,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              _buildInputQualityHint(isDark),
            ],
          ),
        ),
        if (!_isListening)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: FoodBrowserPanel(
                userId: widget.userId,
                mealType: _selectedMealType,
                isDark: isDark,
                searchQuery: _searchQuery,
                filter: _browserFilter,
                onFilterChanged: (filter) {
                  setState(() => _browserFilter = filter);
                  // ignore: unawaited_futures
                  ref
                      .read(lastUsedServiceProvider)
                      .set(_kFoodBrowserLastUsedKey, filter.name);
                },
                onFoodLogged: () {
                  ref
                      .read(dailyNutritionProvider(todayNutritionKey()).notifier)
                      .load(widget.userId);
                },
                selectedDate: widget.selectedDate,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Describe actions ─────────────────────────────────────────

  /// Stage photos into the Describe form. Camera adds one shot at a
  /// time (so users can keep shooting); gallery multi-picks. Capped at
  /// 5 with a clear message (edge case C3 / C1 ">5 photos").
  Future<void> _addDescribePhotos() async {
    final remaining = 5 - _describePhotos.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).logMealSheetUpTo5Photos)),
        );
      }
      return;
    }

    final source = await showGlassSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final colors = ThemeColors.of(ctx);
        final accent = AccentColorScope.of(ctx).getColor(colors.isDark);
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Text(
                      AppLocalizations.of(context).logMealSheetAddPhotos,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  _GlassMenuOption(
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(context).logMealSheetTakeAPhoto,
                    color: accent,
                    isDark: colors.isDark,
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  const SizedBox(height: 10),
                  _GlassMenuOption(
                    icon: Icons.collections_outlined,
                    label: AppLocalizations.of(context).recipesChooseFromGallery,
                    subtitle: 'Pick up to $remaining',
                    color: accent,
                    isDark: colors.isDark,
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

    try {
      if (source == ImageSource.camera) {
        final picker = ImagePicker();
        final shot = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 90,
        );
        if (shot != null && mounted) {
          setState(() => _describePhotos.add(shot));
        }
      } else {
        final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
        if (picked.isNotEmpty && mounted) {
          setState(() {
            _describePhotos.addAll(picked.take(remaining));
          });
          if (picked.length > remaining) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context).logMealSheetAddedTheFirst5)),
            );
          }
        }
      }
    } catch (e) {
      // Permission denied / picker failure — clear message, no crash (C3).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access ${source == ImageSource.camera ? 'camera' : 'photos'}. '
              'Check permissions in Settings, or type the meal instead.',
            ),
          ),
        );
      }
    }
  }

  /// Single Analyze round trip for the Describe form. Routes photos+text
  /// through the multi-image pipeline, or text-only through text
  /// analysis. Blocks re-entrancy while a previous run streams (C3).
  Future<void> _handleDescribeAnalyze() async {
    if (_describeAnalyzing || _isAnalyzing || _isLoading) return;

    final instruction = _describeInstructionController.text.trim();
    final hasPhotos = _describePhotos.isNotEmpty;
    // C3 — empty Describe submit: nothing to analyze.
    if (!hasPhotos && instruction.isEmpty) return;

    if (!hasPhotos) {
      // Text-only Describe → reuse the text-analysis path. Mirror the
      // instruction into the search field so _handleAnalyze (which reads
      // _descriptionController) picks it up.
      _descriptionController.text = instruction;
      await _handleAnalyze();
      return;
    }

    setState(() => _describeAnalyzing = true);
    try {
      // Photos (+ optional instruction) → one multi-image round trip.
      // userMessage carries the instruction as `user_message` so the
      // hardened vision prompt can follow it.
      await _analyzeMultiImages(
        files: List<XFile>.from(_describePhotos),
        analysisMode: 'auto',
        inputType: _describePhotos.length > 1 ? 'multi_image_scan' : 'gallery',
        userMessage: instruction.isEmpty ? null : instruction,
      );
    } finally {
      if (mounted) setState(() => _describeAnalyzing = false);
    }
  }

  // ─── L1 — "fits your day" computation ─────────────────────────

  /// L1 — compute calories/protein remaining vs the user's targets, scoped
  /// to the sheet's [selectedDate]. Returns null when the user has no real
  /// targets set (C7 "no targets → skip") or when the cached daily summary
  /// belongs to a different date than [selectedDate] (C7 PAST-date scoping —
  /// we never show stale "today" numbers against another day).
  _FitsYourDay? _computeFitsYourDay() {
    final prefsState = ref.watch(nutritionPreferencesProvider);
    // C7 — no targets set: a real target must exist (dynamic or saved
    // preference). The getters fall back to 2000/150 defaults, so check the
    // raw sources instead of the getter.
    final hasRealCalorieTarget = prefsState.dynamicTargets != null ||
        prefsState.preferences?.targetCalories != null;
    if (!hasRealCalorieTarget) return null;

    // C7 — scope "remaining" to the date being logged. The daily provider is
    // now per-date, so watching the provider keyed by the target date inherently
    // gives us the summary for that day (no cross-date staleness). selectedDate
    // == null means "today".
    final target = widget.selectedDate ?? DateTime.now();
    final state = ref.watch(dailyNutritionProvider(nutritionKeyFor(target)));
    final summary = state.summary;

    final consumedCal = summary != null ? summary.totalCalories : 0;
    final consumedProtein =
        summary != null ? summary.totalProteinG.round() : 0;

    final calTarget = prefsState.currentCalorieTarget;
    final proteinTarget = prefsState.currentProteinTarget;

    return _FitsYourDay(
      caloriesRemaining: calTarget - consumedCal,
      proteinRemaining:
          prefsState.preferences?.targetProteinG != null ||
                  prefsState.dynamicTargets != null
              ? proteinTarget - consumedProtein
              : null,
      dateLabel: _fitsDateLabel(target),
      // C7 — a planned refeed / high-output day surfaces as a positive
      // calorie adjustment with a non-base adjustment reason. The result
      // sheet uses this to suppress the over-budget guilt fork.
      isPlannedHighDay: prefsState.dynamicTargets != null &&
          prefsState.dynamicTargets!.adjustmentReason != 'base_targets' &&
          prefsState.dynamicTargets!.calorieAdjustment > 0,
    );
  }

  /// Human label for the fits-your-day line: "Today" / "Yesterday" / a short
  /// date for older logs (C7 — past-date logs read that date, not "today").
  String _fitsDateLabel(DateTime target) {
    final now = DateTime.now();
    final t = DateTime(target.year, target.month, target.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(t).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.day}';
  }
}

/// L1 — computed daily-budget snapshot for the "fits your day" line.
class _FitsYourDay {
  final int caloriesRemaining;
  final int? proteinRemaining;
  final String dateLabel;
  final bool isPlannedHighDay;

  const _FitsYourDay({
    required this.caloriesRemaining,
    required this.proteinRemaining,
    required this.dateLabel,
    required this.isPlannedHighDay,
  });
}
