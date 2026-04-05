part of 'hydration_tab.dart';


// ─────────────────────────────────────────────────────────────────
// Stat Item Widget
// ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Quick Add Section
// ─────────────────────────────────────────────────────────────────

class _QuickAddSection extends StatelessWidget {
  final List<QuickAmountUnit> amounts;
  final Function(int) onAdd;
  final VoidCallback onCustom;
  final bool isDark;

  const _QuickAddSection({
    required this.amounts,
    required this.onAdd,
    required this.onCustom,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final electricBlue =
        isDark ? AppColors.waterBlue : AppColorsLight.waterBlue;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'QUICK ADD WATER', isDark: isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            // Preset amounts (first 3 only to make room for custom)
            ...amounts.take(3).map((amount) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _QuickAddButton(
                    amount: amount,
                    onTap: () => onAdd(amount.ml),
                    isDark: isDark,
                  ),
                ),
              );
            }),
            // Custom button
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: onCustom,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: electricBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: electricBlue,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Custom',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Any ml',
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class _QuickAddButton extends StatelessWidget {
  final QuickAmountUnit amount;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAddButton({
    required this.amount,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final electricBlue = isDark
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: electricBlue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: electricBlue, size: 20),
            const SizedBox(height: 4),
            Text(
              amount.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (amount.description != null)
              Text(
                amount.description!,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Drink Type Section
// ─────────────────────────────────────────────────────────────────

class _DrinkTypeSection extends StatelessWidget {
  final Function(DrinkType) onSelect;
  final bool isDark;

  const _DrinkTypeSection({required this.onSelect, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'OTHER DRINKS', isDark: isDark),
        const SizedBox(height: 12),
        Row(
          children: DrinkType.values
              .where((t) => t != DrinkType.water)
              .map((type) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onSelect(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(type.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(fontSize: 10, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Today's Breakdown
// ─────────────────────────────────────────────────────────────────

class _TodayBreakdown extends StatelessWidget {
  final DailyHydrationSummary summary;
  final HydrationUnit unit;
  final bool isDark;

  const _TodayBreakdown({
    required this.summary,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BREAKDOWN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            emoji: '💧',
            label: 'Water',
            value: summary.waterMl,
            total: summary.totalMl,
            unit: unit,
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '🥤',
            label: 'Protein Shake',
            value: summary.proteinShakeMl,
            total: summary.totalMl,
            unit: unit,
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '⚡',
            label: 'Sports Drink',
            value: summary.sportsDrinkMl,
            total: summary.totalMl,
            unit: unit,
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '🥛',
            label: 'Other',
            value: summary.otherMl,
            total: summary.totalMl,
            unit: unit,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}


class _BreakdownRow extends StatelessWidget {
  final String emoji;
  final String label;
  final int value;
  final int total;
  final HydrationUnit unit;
  final bool isDark;

  const _BreakdownRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.total,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;
    final glassSurface = isDark
        ? AppColors.glassSurface
        : AppColorsLight.glassSurface;
    final electricBlue = isDark
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: glassSurface,
                  color: electricBlue,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${unit.format(value)}${unit.label}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Log Entry
// ─────────────────────────────────────────────────────────────────

class _LogEntry extends StatelessWidget {
  final HydrationLog log;
  final HydrationUnit unit;
  final VoidCallback onDelete;
  final bool isDark;

  const _LogEntry({
    required this.log,
    required this.unit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final type = DrinkType.fromValue(log.drinkType);
    final time = log.loggedAt != null
        ? '${log.loggedAt!.hour.toString().padLeft(2, '0')}:${log.loggedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final electricBlue = isDark
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Text(
                    log.notes!,
                    style: TextStyle(fontSize: 12, color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${unit.format(log.amountMl)}${unit.label}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: electricBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: textMuted,
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        letterSpacing: 1.5,
      ),
    );
  }
}

