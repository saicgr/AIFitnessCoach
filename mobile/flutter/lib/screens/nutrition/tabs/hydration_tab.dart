import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hydration.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../widgets/liquid_body_hydration.dart';

/// Hydration unit for display conversion
enum HydrationUnit {
  ml('ml', 1.0),
  oz('oz', 0.0338140227),
  gallon('gal', 0.000264172);

  final String label;
  final double fromMlFactor;
  const HydrationUnit(this.label, this.fromMlFactor);

  double convert(int ml) => ml * fromMlFactor;

  String format(int ml) {
    final value = convert(ml);
    if (this == gallon) return value.toStringAsFixed(2);
    if (this == oz) return value.toStringAsFixed(1);
    return value.round().toString();
  }

  /// Get quick add amounts in this unit
  List<QuickAmountUnit> getQuickAmounts() {
    switch (this) {
      case HydrationUnit.ml:
        return const [
          QuickAmountUnit(250, '250ml', 'Glass'),
          QuickAmountUnit(500, '500ml', 'Bottle'),
          QuickAmountUnit(750, '750ml', 'Large'),
          QuickAmountUnit(1000, '1L', 'Liter'),
        ];
      case HydrationUnit.oz:
        return const [
          QuickAmountUnit(237, '8oz', 'Cup'),
          QuickAmountUnit(355, '12oz', 'Can'),
          QuickAmountUnit(473, '16oz', 'Pint'),
          QuickAmountUnit(591, '20oz', 'Bottle'),
        ];
      case HydrationUnit.gallon:
        return const [
          QuickAmountUnit(473, '1/8 gal', 'Pint'),
          QuickAmountUnit(946, '1/4 gal', 'Quart'),
          QuickAmountUnit(1893, '1/2 gal', 'Half'),
          QuickAmountUnit(3785, '1 gal', 'Gallon'),
        ];
    }
  }
}

class QuickAmountUnit {
  final int ml;
  final String label;
  final String? description;

  const QuickAmountUnit(this.ml, this.label, [this.description]);
}

/// Hydration tab for the nutrition screen
class HydrationTab extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final VoidCallback? onGoalSettingsTap;

  const HydrationTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.onGoalSettingsTap,
  });

  @override
  ConsumerState<HydrationTab> createState() => _HydrationTabState();
}

class _HydrationTabState extends ConsumerState<HydrationTab> {
  HydrationUnit _selectedUnit = HydrationUnit.ml;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);
    final electricBlue = widget.isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: electricBlue),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.userId.isNotEmpty) {
          ref.read(hydrationProvider.notifier).loadTodaySummary(widget.userId);
        }
      },
      color: electricBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with settings and unit selector
            _buildHeader(),
            const SizedBox(height: 16),

            // Body hydration animation
            _buildBodyAnimation(state).animate().fadeIn().scale(),
            const SizedBox(height: 16),

            // Current stats
            _buildStats(state).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 24),

            // Quick add buttons
            _QuickAddSection(
              amounts: _selectedUnit.getQuickAmounts(),
              onAdd: (amount) => _quickLog(amount),
              onCustom: () => _showCustomAmountDialog(),
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),

            // Drink type buttons
            _DrinkTypeSection(
              onSelect: (type) => _showAddDialog(type),
              isDark: widget.isDark,
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 24),

            // Today's breakdown
            if (state.todaySummary != null)
              _TodayBreakdown(
                summary: state.todaySummary!,
                unit: _selectedUnit,
                isDark: widget.isDark,
              ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),

            // Recent entries
            if (state.todaySummary?.entries.isNotEmpty == true) ...[
              _SectionHeader(title: 'TODAY\'S LOG', isDark: widget.isDark),
              const SizedBox(height: 12),
              ...state.todaySummary!.entries.asMap().entries.map((e) {
                return _LogEntry(
                  log: e.value,
                  unit: _selectedUnit,
                  onDelete: () => _deleteLog(e.value.id),
                  isDark: widget.isDark,
                ).animate().fadeIn(delay: (50 * e.key).ms);
              }),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = widget.isDark
        ? AppColors.textMuted
        : AppColorsLight.textMuted;
    final elevated = widget.isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Settings button
        IconButton(
          icon: Icon(Icons.settings_outlined, color: textMuted),
          onPressed: () => _showGoalSettings(),
          tooltip: 'Hydration Settings',
        ),

        // Unit selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButton<HydrationUnit>(
            value: _selectedUnit,
            underline: const SizedBox.shrink(),
            isDense: true,
            dropdownColor: elevated,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
            items: HydrationUnit.values.map((unit) {
              return DropdownMenuItem(
                value: unit,
                child: Text(unit.label.toUpperCase()),
              );
            }).toList(),
            onChanged: (unit) {
              if (unit != null) {
                setState(() => _selectedUnit = unit);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBodyAnimation(HydrationState state) {
    final currentMl = state.todaySummary?.totalMl ?? 0;
    final goalMl = state.dailyGoalMl;
    final percentage = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: LiquidBodyHydration(
        fillPercentage: percentage,
        isDark: widget.isDark,
        width: 180,
        height: 260,
      ),
    );
  }

  Widget _buildStats(HydrationState state) {
    final currentMl = state.todaySummary?.totalMl ?? 0;
    final goalMl = state.dailyGoalMl;
    final remaining = (goalMl - currentMl).clamp(0, goalMl);

    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final electricBlue = widget.isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            electricBlue.withValues(alpha: 0.15),
            electricBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: electricBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Current',
            value: _selectedUnit.format(currentMl),
            unit: _selectedUnit.label,
            color: electricBlue,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: electricBlue.withValues(alpha: 0.3),
          ),
          _StatItem(
            label: 'Goal',
            value: _selectedUnit.format(goalMl),
            unit: _selectedUnit.label,
            color: textSecondary,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Container(
            width: 1,
            height: 40,
            color: electricBlue.withValues(alpha: 0.3),
          ),
          _StatItem(
            label: 'Remaining',
            value: _selectedUnit.format(remaining),
            unit: _selectedUnit.label,
            color: remaining > 0 ? AppColors.orange : AppColors.success,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Future<void> _quickLog(int amountMl) async {
    if (widget.userId.isEmpty) return;
    final success = await ref.read(hydrationProvider.notifier).quickLog(
          userId: widget.userId,
          amountMl: amountMl,
        );
    if (success && mounted) {
      final displayAmount = _selectedUnit.format(amountMl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $displayAmount${_selectedUnit.label} of water'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCustomAmountDialog() async {
    final amountController = TextEditingController();
    final nearBlack = widget.isDark
        ? AppColors.nearBlack
        : AppColorsLight.nearWhite;
    final elevated = widget.isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    final textMuted = widget.isDark
        ? AppColors.textMuted
        : AppColorsLight.textMuted;
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final electricBlue = widget.isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

    final result = await showGlassSheet<int>(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: electricBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Custom Amount',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter any amount in milliliters',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: textMuted),
                suffixText: 'ml',
                suffixStyle: TextStyle(
                  color: textMuted,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: electricBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [100, 150, 200, 300, 350, 400].map((ml) {
                return GestureDetector(
                  onTap: () {
                    amountController.text = ml.toString();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: electricBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${ml}ml',
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context, amount);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Water',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );

    if (result != null && result > 0) {
      await _quickLog(result);
    }
  }

  Future<void> _showAddDialog(DrinkType type) async {
    final amountController = TextEditingController(text: '250');
    final notesController = TextEditingController();
    final nearBlack = widget.isDark
        ? AppColors.nearBlack
        : AppColorsLight.nearWhite;
    final elevated = widget.isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    final textMuted = widget.isDark
        ? AppColors.textMuted
        : AppColorsLight.textMuted;
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final electricBlue = widget.isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

    final result = await showGlassSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  'Log ${type.label}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textPrimary),
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
              style: TextStyle(color: textPrimary),
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
      ),
    );

    if (result != null && widget.userId.isNotEmpty) {
      final success = await ref.read(hydrationProvider.notifier).logHydration(
            userId: widget.userId,
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
    if (widget.userId.isEmpty) return;
    await ref.read(hydrationProvider.notifier).deleteLog(widget.userId, logId);
  }

  void _showGoalSettings() {
    final state = ref.read(hydrationProvider);
    final controller = TextEditingController(
      text: state.dailyGoalMl.toString(),
    );
    final nearBlack = widget.isDark
        ? AppColors.nearBlack
        : AppColorsLight.nearWhite;
    final elevated = widget.isDark
        ? AppColors.elevated
        : AppColorsLight.elevated;
    final textMuted = widget.isDark
        ? AppColors.textMuted
        : AppColorsLight.textMuted;
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final electricBlue = widget.isDark
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  if (widget.userId.isNotEmpty) {
                    ref
                        .read(hydrationProvider.notifier)
                        .updateGoal(widget.userId, goal);
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
      ),
    );
  }
}

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
        isDark ? AppColors.electricBlue : AppColorsLight.electricBlue;
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
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;
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
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;
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
        ? AppColors.electricBlue
        : AppColorsLight.electricBlue;

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
