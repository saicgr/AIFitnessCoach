part of 'food_history_screen.dart';


// ─── Frequent Food Chip ─────────────────────────────────────────────────────

class _FrequentFoodChip extends StatelessWidget {
  final SavedFood food;
  final int rank;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final VoidCallback onTap;

  const _FrequentFoodChip({
    required this.food,
    required this.rank,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    required this.onTap,
  });

  String _rankMedal(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _rankMedal(rank),
                  style: TextStyle(fontSize: rank <= 3 ? 14 : 11),
                ),
                const Spacer(),
                Icon(Icons.add_circle_outline, size: 16, color: teal),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              food.name,
              style: TextStyle(
                color: textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${food.totalCalories ?? 0}',
                  style: TextStyle(
                    color: teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' cal',
                  style: TextStyle(color: textMuted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${food.timesLogged}x',
                  style: TextStyle(
                    color: purple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Food Log Tile ──────────────────────────────────────────────────────────

class _FoodLogTile extends StatelessWidget {
  final FoodLog log;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color teal;
  final String Function(String) getMealEmoji;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final ApiClient? apiClient;

  const _FoodLogTile({
    required this.log,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.teal,
    required this.getMealEmoji,
    required this.onTap,
    required this.onDismissed,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    final foodName = log.foodItems.isNotEmpty
        ? log.foodItems.first.name
        : log.mealType;
    final extraCount = log.foodItems.length > 1 ? ' +${log.foodItems.length - 1}' : '';
    final timeStr = DateFormat('h:mm a').format(log.loggedAt);
    final mealLabel = _mealLabel(log.mealType);
    final sourceIcon = _sourceIconFor(log.sourceType);

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              // Leading: photo thumbnail when present, else meal-type emoji.
              // Photo is the strongest at-a-glance cue that this row came
              // from a scan; fall back preserves the prior emoji affordance.
              _LeadingThumb(
                imageUrl: log.imageUrl,
                logId: log.id,
                fallbackEmoji: getMealEmoji(log.mealType),
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$foodName$extraCount',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sourceIcon != null) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: _sourceLabel(log.sourceType),
                            child: Icon(
                              sourceIcon,
                              size: 12,
                              color: textMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        // Meal-type chip (Breakfast/Lunch/Dinner/Snack).
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mealLabel,
                            style: TextStyle(
                              color: teal,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeStr,
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${log.proteinG.round()}P · ${log.carbsG.round()}C · ${log.fatG.round()}F',
                            style: TextStyle(color: textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${log.totalCalories}',
                style: TextStyle(
                  color: teal,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' cal',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
              if (apiClient != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    final foodName = log.foodItems.isNotEmpty
                        ? log.foodItems.first.name
                        : log.mealType;
                    showFoodReportDialog(
                      context,
                      apiClient: apiClient!,
                      foodName: foodName,
                      originalCalories: log.totalCalories,
                      originalProtein: log.proteinG,
                      originalCarbs: log.carbsG,
                      originalFat: log.fatG,
                      dataSource: 'food_log',
                      foodLogId: log.id,
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, color: textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _mealLabel(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return 'BREAKFAST';
      case 'lunch': return 'LUNCH';
      case 'dinner': return 'DINNER';
      case 'snack': return 'SNACK';
      default: return type.toUpperCase();
    }
  }

  IconData? _sourceIconFor(String? src) {
    switch (src) {
      case 'image':
      case 'camera':
      case 'gallery':
      case 'plate':
      case 'buffet':
        return Icons.photo_camera_outlined;
      case 'barcode':
        return Icons.qr_code_scanner_outlined;
      case 'menu':
      case 'menu_scan':
      case 'restaurant':
        return Icons.menu_book_outlined;
      case 'voice':
        return Icons.mic_none_outlined;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'parse_app_screenshot':
        return Icons.crop_square_outlined;
      case 'parse_nutrition_label':
        return Icons.label_outline;
      case 'text':
        return Icons.edit_outlined;
      default:
        return null;
    }
  }

  String _sourceLabel(String? src) {
    switch (src) {
      case 'image': return 'Photo';
      case 'camera': return 'Camera';
      case 'gallery': return 'Gallery';
      case 'plate': return 'Plate photo';
      case 'buffet': return 'Buffet photo';
      case 'barcode': return 'Barcode';
      case 'menu':
      case 'menu_scan': return 'Menu scan';
      case 'restaurant': return 'Restaurant';
      case 'voice': return 'Voice';
      case 'chat': return 'Chat';
      case 'parse_app_screenshot': return 'App screenshot';
      case 'parse_nutrition_label': return 'Nutrition label';
      case 'text': return 'Text';
      default: return 'Logged';
    }
  }
}

/// Square thumbnail for the leading column — photo if available, else emoji.
///
/// S3 URLs carry a 7-day presigned TTL (see backend/api/v1/nutrition/helpers.py);
/// the read path re-signs to 24h on every fetch but cached responses can still
/// contain stale URLs if the app stays open past the window. On Image.network
/// failure (403/expired) we hit `/nutrition/food-logs/{id}/image-url` for a
/// fresh URL and retry once before falling back to the emoji box.
class _LeadingThumb extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? logId;
  final String fallbackEmoji;
  final bool isDark;

  const _LeadingThumb({
    required this.imageUrl,
    required this.logId,
    required this.fallbackEmoji,
    required this.isDark,
  });

  @override
  ConsumerState<_LeadingThumb> createState() => _LeadingThumbState();
}

class _LeadingThumbState extends ConsumerState<_LeadingThumb> {
  String? _activeUrl;
  bool _refreshAttempted = false;
  bool _hardFailed = false;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant _LeadingThumb old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _activeUrl = widget.imageUrl;
      _refreshAttempted = false;
      _hardFailed = false;
    }
  }

  Future<void> _tryRefresh() async {
    if (_refreshAttempted || widget.logId == null) {
      if (mounted) setState(() => _hardFailed = true);
      return;
    }
    _refreshAttempted = true;
    final fresh = await ref
        .read(nutritionRepositoryProvider)
        .refreshFoodLogImageUrl(widget.logId!);
    if (!mounted) return;
    if (fresh != null && fresh.isNotEmpty) {
      setState(() => _activeUrl = fresh);
    } else {
      setState(() => _hardFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final hasImage = (_activeUrl != null && _activeUrl!.isNotEmpty) && !_hardFailed;
    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _activeUrl!,
          key: ValueKey(_activeUrl), // force rebuild on URL refresh
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // Kick off a one-shot refresh; paint emoji placeholder meanwhile.
            // The setState inside _tryRefresh will swap _activeUrl and re-render.
            WidgetsBinding.instance.addPostFrameCallback((_) => _tryRefresh());
            return _emojiBox();
          },
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _emojiBox();
          },
        ),
      );
    }
    return _emojiBox();
  }

  Widget _emojiBox() {
    const size = 40.0;
    final bg = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(widget.fallbackEmoji, style: const TextStyle(fontSize: 22)),
    );
  }
}


// ─── Error State ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, color: teal),
            label: Text(
              'Retry',
              style: TextStyle(color: teal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Edit Food Log Sheet ────────────────────────────────────────────────────

class _EditFoodLogSheet extends ConsumerStatefulWidget {
  final FoodLog log;
  final bool isDark;
  final Future<void> Function(double multiplier) onSave;

  const _EditFoodLogSheet({
    required this.log,
    required this.isDark,
    required this.onSave,
  });

  @override
  ConsumerState<_EditFoodLogSheet> createState() => _EditFoodLogSheetState();
}


class _EditFoodLogSheetState extends ConsumerState<_EditFoodLogSheet> {
  double _multiplier = 1.0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bg = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    // Use the user's selected accent color so the primary CTA reads as
    // "action" — a fixed teal button looked disabled in some themes.
    final accent = ref.watch(accentColorProvider).getColor(widget.isDark);

    final foodName = widget.log.foodItems.isNotEmpty
        ? widget.log.foodItems.first.name
        : widget.log.mealType;
    final hasImage = widget.log.imageUrl != null && widget.log.imageUrl!.isNotEmpty;
    final hasInflammation = widget.log.inflammationScore != null;
    final hasAiTip = widget.log.aiFeedback != null && widget.log.aiFeedback!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row: thumbnail (if present) + title + subtitle.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  if (hasImage)
                    _LeadingThumb(
                      imageUrl: widget.log.imageUrl,
                      logId: widget.log.id,
                      fallbackEmoji: '🍽️',
                      isDark: widget.isDark,
                    )
                  else
                    Icon(Icons.edit_outlined, color: accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Portion',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          foodName,
                          style: TextStyle(fontSize: 13, color: textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Portion input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PortionAmountInput(
                initialMultiplier: 1.0,
                baseCalories: widget.log.totalCalories,
                baseProtein: widget.log.proteinG,
                baseCarbs: widget.log.carbsG,
                baseFat: widget.log.fatG,
                isDark: widget.isDark,
                onMultiplierChanged: (m) => setState(() => _multiplier = m),
              ),
            ),

            // Inflammation score (cached on the log — no re-analysis call).
            if (hasInflammation) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InflammationRow(
                  score: widget.log.inflammationScore!,
                  isDark: widget.isDark,
                ),
              ),
            ],

            // AI coach tip — same copy the user saw at log time, so
            // historical review stays consistent with the original log flow.
            if (hasAiTip) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _AiCoachTipRow(
                  message: widget.log.aiFeedback!.trim(),
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: widget.isDark,
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Save button. Always enabled — even at 1.0× the user may have
            // tapped "Save" to dismiss intentionally; a confirmed close is
            // nicer than a silent no-op. Shows an accent-colored CTA, never
            // the grey "disabled" look the user reported.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await widget.onSave(_multiplier);
                          if (mounted) setState(() => _saving = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accent.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Save Changes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Compact inflammation score row — shows the cached integer 0-10 with a
/// label and color ramp. No network call (the score is stored on the
/// FoodLog at log time).
class _InflammationRow extends StatelessWidget {
  final int score;
  final bool isDark;

  const _InflammationRow({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 0-3 anti-inflammatory (green), 4-6 neutral (amber), 7-10 inflammatory
    final tone = score <= 3
        ? const Color(0xFF10B981) // emerald
        : score <= 6
            ? const Color(0xFFF59E0B) // amber
            : const Color(0xFFEF4444); // red
    final label = score <= 3
        ? 'Anti-inflammatory'
        : score <= 6
            ? 'Mildly inflammatory'
            : 'Highly inflammatory';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$score',
              style: TextStyle(
                color: tone,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inflammation Score',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: tone, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AI coach tip row — surfaces the cached ai_feedback for the log so users
/// can re-read the advice they got when they logged (matches what other
/// log modes show at creation time).
class _AiCoachTipRow extends StatelessWidget {
  final String message;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _AiCoachTipRow({
    required this.message,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach tip',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

