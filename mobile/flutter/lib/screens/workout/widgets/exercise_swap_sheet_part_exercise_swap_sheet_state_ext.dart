part of 'exercise_swap_sheet.dart';

/// Methods extracted from _ExerciseSwapSheetState
extension __ExerciseSwapSheetStateExt on _ExerciseSwapSheetState {

  /// AI Picks tab - slow AI-powered suggestions (~10s)
  /// Now includes text + voice input for custom requests
  Widget _buildAITab(Color textMuted, Color textPrimary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Input field with mic and search buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiInputController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "I only have dumbbells"',
                    hintStyle: TextStyle(color: textMuted, fontSize: 14),
                    filled: true,
                    fillColor: cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(color: textPrimary),
                  onSubmitted: (_) {
                    setState(() => _aiLoaded = false);
                    _loadAISuggestions();
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Mic button
              GestureDetector(
                onTap: _isSpeechAvailable || !_isListening
                    ? _toggleListening
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.cyan
                        : (_isSpeechAvailable
                            ? cardBackground
                            : cardBackground.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.white
                        : (_isSpeechAvailable ? textMuted : textMuted.withOpacity(0.5)),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Search button
              GestureDetector(
                onTap: _isLoadingAI
                    ? null
                    : () {
                        setState(() => _aiLoaded = false);
                        _loadAISuggestions();
                      },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLoadingAI
                        ? AppColors.cyan.withOpacity(0.5)
                        : AppColors.cyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLoadingAI ? Icons.hourglass_empty : Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Listening indicator
        if (_isListening)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyan.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Listening... speak now',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Loading state
        if (_isLoadingAI)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.cyan),
                  const SizedBox(height: 16),
                  Text(
                    'Getting AI suggestions...',
                    style: TextStyle(color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take 10-15 seconds',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          )
        // Not loaded yet - show prompt
        else if (!_aiLoaded)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppColors.cyan.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ask AI for suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your equipment or preferences\ne.g., "I have a bad shoulder" or "bodyweight only"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _loadAISuggestions();
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Get AI Suggestions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        // Empty state — distinguish "the request failed" from "the server
        // returned 0 suggestions" so the user knows what actually happened.
        else if (_aiSuggestions.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _aiError != null
                          ? Icons.error_outline
                          : Icons.auto_awesome,
                      size: 48,
                      color: _aiError != null ? AppColors.error : textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _aiError != null
                          ? 'AI Picks unavailable'
                          : 'No alternatives matched your request',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiError ??
                          'Try rephrasing your request above, picking a different reason, or check the Library tab.',
                      style: TextStyle(fontSize: 13, color: textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() => _aiLoaded = false);
                        _loadAISuggestions();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          )
        // Results list
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _aiSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _aiSuggestions[index];
                final name = suggestion['name'] ?? 'Exercise';
                final reason = suggestion['reason'] ?? '';
                final rank = suggestion['rank'] ?? (index + 1);
                final equipment = suggestion['equipment'] ?? '';
                final targetMuscle =
                    suggestion['target_muscle'] ?? suggestion['body_part'] ?? '';

                // Create subtitle from reason or equipment/muscle info
                final subtitle = reason.isNotEmpty
                    ? reason
                    : [targetMuscle, equipment]
                        .where((s) => s.isNotEmpty)
                        .join(' • ');

                // Badge text based on rank
                String badge;
                Color badgeColor;
                if (rank == 1) {
                  badge = 'Best Match';
                  badgeColor = AppColors.success;
                } else if (rank <= 3) {
                  badge = 'Top Pick';
                  badgeColor = AppColors.cyan;
                } else {
                  badge = equipment.isNotEmpty ? equipment : 'Alternative';
                  badgeColor = AppColors.purple;
                }

                return _ExerciseOptionCard(
                  name: name,
                  subtitle: subtitle,
                  badge: badge,
                  badgeColor: badgeColor,
                  onTap: () => _swapExercise(name, source: 'ai_suggestion'),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                );
              },
            ),
          ),
      ],
    );
  }


  void _showExercisePreviewAndSwap({
    required String name,
    String? targetMuscle,
    String? equipment,
    String? instructions,
    required String source,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Exercise image
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: glassSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.hardEdge,
                child: ExerciseImage(
                  exerciseName: name,
                  width: double.infinity,
                  height: 180,
                  borderRadius: 16,
                  backgroundColor: glassSurface,
                  iconColor: textMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exercise name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Muscle + Equipment chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (targetMuscle != null && targetMuscle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        targetMuscle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cyan,
                        ),
                      ),
                    ),
                  if (equipment != null && equipment.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        equipment,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Instructions (scrollable)
            if (instructions != null && instructions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  size: 16, color: AppColors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            instructions,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Big swap button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _swapExercise(name, source: source);
                  },
                  icon: const Icon(Icons.swap_horiz, size: 22),
                  label: const Text(
                    'Swap to this exercise',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
