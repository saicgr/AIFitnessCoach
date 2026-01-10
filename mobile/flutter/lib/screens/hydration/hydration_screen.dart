import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/hydration.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/main_shell.dart';

class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null) {
      setState(() => _userId = userId);
      ref.read(hydrationProvider.notifier).loadTodaySummary(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        title: Text('Hydration', style: TextStyle(color: textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: () => _showGoalSettings(context, isDark),
          ),
        ],
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(color: electricBlue),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: electricBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Water bottle progress
                    _WaterProgress(
                      currentMl: state.todaySummary?.totalMl ?? 0,
                      goalMl: state.dailyGoalMl,
                      isDark: isDark,
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 32),

                    // Quick add buttons
                    _QuickAddSection(
                      onAdd: (amount) => _quickLog(amount),
                      isDark: isDark,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),

                    // Drink type buttons
                    _DrinkTypeSection(
                      onSelect: (type) => _showAddDialog(type, isDark),
                      isDark: isDark,
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),

                    // Today's breakdown
                    if (state.todaySummary != null)
                      _TodayBreakdown(
                              summary: state.todaySummary!, isDark: isDark)
                          .animate()
                          .fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    // Recent entries
                    if (state.todaySummary?.entries.isNotEmpty == true) ...[
                      _SectionHeader(title: 'TODAY\'S LOG', isDark: isDark),
                      const SizedBox(height: 12),
                      ...state.todaySummary!.entries.asMap().entries.map((e) {
                        return _LogEntry(
                          log: e.value,
                          onDelete: () => _deleteLog(e.value.id),
                          isDark: isDark,
                        ).animate().fadeIn(delay: (50 * e.key).ms);
                      }),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _quickLog(int amountMl) async {
    if (_userId == null) return;
    final success = await ref.read(hydrationProvider.notifier).quickLog(
          userId: _userId!,
          amountMl: amountMl,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${amountMl}ml of water'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAddDialog(DrinkType type, bool isDark) async {
    final amountController = TextEditingController(text: '250');
    final notesController = TextEditingController();
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;

    // Hide floating nav bar when sheet opens
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: nearBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  'Log ${type.label}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                labelStyle: TextStyle(color: textMuted),
                suffixText: 'ml',
                suffixStyle: TextStyle(color: textMuted),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: textMuted),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text) ?? 250;
                  Navigator.pop(context, {
                    'amount': amount,
                    'notes': notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );

    // Show floating nav bar when sheet closes
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;

    if (result != null && _userId != null) {
      final success = await ref.read(hydrationProvider.notifier).logHydration(
            userId: _userId!,
            drinkType: type.value,
            amountMl: result['amount'],
            notes: result['notes'],
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result['amount']}ml of ${type.label}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteLog(String logId) async {
    if (_userId == null) return;
    await ref.read(hydrationProvider.notifier).deleteLog(_userId!, logId);
  }

  void _showGoalSettings(BuildContext context, bool isDark) {
    final state = ref.read(hydrationProvider);
    final controller =
        TextEditingController(text: state.dailyGoalMl.toString());
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;

    // Hide floating nav bar when sheet opens
    ref.read(floatingNavBarVisibleProvider.notifier).state = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: nearBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Goal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Goal (ml)',
                labelStyle: TextStyle(color: textMuted),
                suffixText: 'ml',
                suffixStyle: TextStyle(color: textMuted),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended: 2000-3000ml per day',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final goal = int.tryParse(controller.text) ?? 2500;
                  if (_userId != null) {
                    ref
                        .read(hydrationProvider.notifier)
                        .updateGoal(_userId!, goal);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Update Goal'),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Show floating nav bar when sheet closes
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    });
  }
}

// ─────────────────────────────────────────────────────────────────
// Water Progress Widget
// ─────────────────────────────────────────────────────────────────

class _WaterProgress extends StatelessWidget {
  final int currentMl;
  final int goalMl;
  final bool isDark;

  const _WaterProgress({
    required this.currentMl,
    required this.goalMl,
    required this.isDark,
  });

  double get percentage => (currentMl / goalMl).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            electricBlue.withOpacity(0.2),
            cyan.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: electricBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 12,
                    backgroundColor: glassSurface,
                    color: glassSurface,
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    color: electricBlue,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 32,
                      color: electricBlue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${currentMl}ml / ${goalMl}ml',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(goalMl - currentMl).clamp(0, goalMl)}ml to go',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Quick Add Section
// ─────────────────────────────────────────────────────────────────

class _QuickAddSection extends StatelessWidget {
  final Function(int) onAdd;
  final bool isDark;

  const _QuickAddSection({required this.onAdd, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'QUICK ADD WATER', isDark: isDark),
        const SizedBox(height: 12),
        Row(
          children: QuickAmount.defaults.map((amount) {
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
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final QuickAmount amount;
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
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: electricBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: electricBlue,
              size: 20,
            ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted,
                ),
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'OTHER DRINKS', isDark: isDark),
        const SizedBox(height: 12),
        Row(
          children:
              DrinkType.values.where((t) => t != DrinkType.water).map((type) {
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
                        Text(
                          type.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                          ),
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
  final bool isDark;

  const _TodayBreakdown({required this.summary, required this.isDark});

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
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '🥤',
            label: 'Protein Shake',
            value: summary.proteinShakeMl,
            total: summary.totalMl,
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '⚡',
            label: 'Sports Drink',
            value: summary.sportsDrinkMl,
            total: summary.totalMl,
            isDark: isDark,
          ),
          _BreakdownRow(
            emoji: '🥛',
            label: 'Other',
            value: summary.otherMl,
            total: summary.totalMl,
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
  final bool isDark;

  const _BreakdownRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

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
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
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
            '${value}ml',
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
  final VoidCallback onDelete;
  final bool isDark;

  const _LogEntry({
    required this.log,
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final electricBlue =
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;

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
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${log.amountMl}ml',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: electricBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
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
