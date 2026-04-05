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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Text(
                getMealEmoji(log.mealType),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$foodName$extraCount',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${log.proteinG.round()}P / ${log.carbsG.round()}C / ${log.fatG.round()}F',
                          style: TextStyle(color: textMuted, fontSize: 11),
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
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: textMuted, size: 18),
            ],
          ),
        ),
      ),
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

class _EditFoodLogSheet extends StatefulWidget {
  final FoodLog log;
  final bool isDark;
  final Future<void> Function(double multiplier) onSave;

  const _EditFoodLogSheet({
    required this.log,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_EditFoodLogSheet> createState() => _EditFoodLogSheetState();
}


class _EditFoodLogSheetState extends State<_EditFoodLogSheet> {
  double _multiplier = 1.0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;
    final bg = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;

    final foodName = widget.log.foodItems.isNotEmpty
        ? widget.log.foodItems.first.name
        : widget.log.mealType;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: teal, size: 22),
                const SizedBox(width: 10),
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
                        maxLines: 1,
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

          const SizedBox(height: 16),

          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(_multiplier);
                        if (mounted) setState(() => _saving = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: teal.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

