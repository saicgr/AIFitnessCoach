part of 'log_meal_sheet.dart';

/// Methods extracted from _LogMealSheetState
extension __LogMealSheetStateExt2 on _LogMealSheetState {

  // ─── Input View ───────────────────────────────────────────────

  Widget _buildInputView(bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    const orange = Color(0xFFF97316);

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
                  Icon(Icons.arrow_back_ios, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Back to results',
                    style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        // Text input (compact)
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
                  hintText: _isListening ? 'Listening...' : 'What did you eat?',
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
                          tooltip: 'Search foods',
                        )
                      : null,
                ),
              ),
              // Listening indicator
              if (_isListening)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(orange)),
                      ),
                      const SizedBox(width: 8),
                      Text('Speak now... tap mic to stop', style: TextStyle(fontSize: 12, color: orange, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              // Input quality hint — nudge users to be more specific
              _buildInputQualityHint(isDark),
            ],
          ),
        ),
        // Food browser panel (replaces quick suggestions)
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
                onFilterChanged: (filter) => setState(() => _browserFilter = filter),
                onFoodLogged: () {
                  // Refresh nutrition data
                  ref.read(nutritionProvider.notifier).loadTodaySummary(widget.userId);
                },
                selectedDate: widget.selectedDate,
              ),
            ),
          ),
      ],
    );
  }

}
