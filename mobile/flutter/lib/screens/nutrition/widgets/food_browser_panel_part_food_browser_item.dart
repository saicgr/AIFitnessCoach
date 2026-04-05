part of 'food_browser_panel.dart';


// ─── Food Browser Item ─────────────────────────────────────────

class _FoodBrowserItem extends StatelessWidget {
  final String name;
  final int calories;
  final String? subtitle;
  final _LogState? logState;
  final VoidCallback onAdd;
  final bool isDark;

  const _FoodBrowserItem({
    required this.name,
    required this.calories,
    this.subtitle,
    this.logState,
    required this.onAdd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: textMuted, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$calories',
            style: TextStyle(
              color: teal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ' kcal',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          // Add button with loading/done states
          GestureDetector(
            onTap: logState == null ? onAdd : null,
            child: SizedBox(
              width: 28,
              height: 28,
              child: _buildAddButton(teal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Color teal) {
    if (logState == _LogState.loading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: teal),
        ),
      );
    }
    if (logState == _LogState.done) {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    return Icon(Icons.add_circle, color: teal, size: 24);
  }
}


// ─── Goal Tag Chip ─────────────────────────────────────────────

class _GoalTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _GoalTag({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


// ─── AI Food Review Card (Coach Tip) ───────────────────────────

class _FoodReviewCard extends StatefulWidget {
  final search.FoodReview? review;
  final bool isLoading;
  final bool isDark;

  const _FoodReviewCard({
    required this.review,
    required this.isLoading,
    required this.isDark,
  });

  @override
  State<_FoodReviewCard> createState() => _FoodReviewCardState();
}


class _FoodReviewCardState extends State<_FoodReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.review == null) return const SizedBox.shrink();

    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // While loading, show compact loading header
    if (widget.isLoading) {
      return _buildCollapsedHeader(teal, textPrimary, textMuted, loading: true);
    }

    final r = widget.review!;
    final hasContent = r.encouragements.isNotEmpty ||
        r.warnings.isNotEmpty ||
        (r.aiSuggestion != null && r.aiSuggestion!.isNotEmpty) ||
        (r.recommendedSwap != null && r.recommendedSwap!.isNotEmpty);
    if (!hasContent) return const SizedBox.shrink();

    // Collapsed: just the header row (icon + "Coach Tip" + score + chevron)
    if (!_isExpanded) {
      return _buildCollapsedHeader(teal, textPrimary, textMuted);
    }

    // Expanded: full card
    final encourageColor = widget.isDark ? AppColors.green : AppColorsLight.green;
    final warningColor = widget.isDark ? AppColors.error : AppColorsLight.error;
    final swapColor = widget.isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            teal.withValues(alpha: 0.1),
            teal.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isExpanded = false),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.psychology, size: 16, color: teal),
                ),
                const SizedBox(width: 8),
                Text(
                  'Coach Tip',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                if (r.healthScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _scoreColor(r.healthScore!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${r.healthScore}/10',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor(r.healthScore!),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.expand_less, size: 18, color: textMuted),
              ],
            ),
          ),

          // Encouragements
          if (r.encouragements.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...r.encouragements.take(2).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.thumb_up, size: 12, color: encourageColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 12, color: encourageColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],

          // Warnings
          if (r.warnings.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...r.warnings.take(2).map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, size: 12, color: warningColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      w,
                      style: TextStyle(fontSize: 12, color: warningColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],

          // AI suggestion
          if (r.aiSuggestion != null && r.aiSuggestion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              r.aiSuggestion!,
              style: TextStyle(fontSize: 12, color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Recommended swap
          if (r.recommendedSwap != null && r.recommendedSwap!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: swapColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: swapColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: swapColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.recommendedSwap!,
                      style: TextStyle(fontSize: 11, color: swapColor, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedHeader(Color teal, Color textPrimary, Color textMuted, {bool loading = false}) {
    final r = widget.review;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teal.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.psychology, size: 16, color: teal),
            ),
            const SizedBox(width: 8),
            Text(
              'Coach Tip',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
            ),
            if (!loading && r?.healthScore != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _scoreColor(r!.healthScore!).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.healthScore}/10',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(r.healthScore!),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (loading)
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: teal),
              )
            else
              Icon(Icons.expand_more, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 7) return widget.isDark ? AppColors.green : AppColorsLight.green;
    if (score >= 4) return const Color(0xFFF97316);
    return widget.isDark ? AppColors.error : AppColorsLight.error;
  }
}


// ─── Shared Flag Icon Button ─────────────────────────────────────────────────

class _FlagIconButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _FlagIconButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.flag_outlined,
          size: 14,
          color: textMuted.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}


// ─── Expandable Search Result Card ───────────────────────────────

class _ExpandableSearchCard extends StatefulWidget {
  final search.FoodSearchResult result;
  final _LogState? logState;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(String description) onLog;
  final bool isWeightEditable;
  final double baseWeightG;
  final bool isDark;
  final List<_GoalTag> goalTags;
  final ApiClient? apiClient;
  final search.FoodSearchService searchService;
  final bool isSelected;
  final VoidCallback? onToggleSelect;

  const _ExpandableSearchCard({
    super.key,
    required this.result,
    this.logState,
    required this.isExpanded,
    required this.onTap,
    required this.onLog,
    this.isWeightEditable = true,
    this.baseWeightG = 100.0,
    required this.isDark,
    this.goalTags = const [],
    this.apiClient,
    required this.searchService,
    this.isSelected = false,
    this.onToggleSelect,
  });

  @override
  State<_ExpandableSearchCard> createState() => _ExpandableSearchCardState();
}

