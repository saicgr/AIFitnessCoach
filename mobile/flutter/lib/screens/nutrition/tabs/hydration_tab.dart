import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/custom_bottle_store.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton_box.dart';
import '../../../widgets/liquid_glass_action_bar.dart';
import '../../../core/services/posthog_service.dart';
import '../../../data/models/hydration.dart';
import '../../../data/repositories/hydration_repository.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/design_system/zealova.dart';
import '../widgets/liquid_body_hydration.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../common/app_refresh_indicator.dart';
part 'hydration_tab_part_stat_item.dart';


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

  // Gap 5 — saved custom bottles (e.g. "32oz Stanley"). Persisted locally per
  // user so they survive restarts; one-tap logs the saved volume.
  List<CustomBottle> _customBottles = const [];

  @override
  void initState() {
    super.initState();
    _loadCustomBottles();
  }

  Future<void> _loadCustomBottles() async {
    final bottles = await CustomBottleStore.load(widget.userId);
    if (mounted) setState(() => _customBottles = bottles);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);
    final electricBlue = widget.isDark
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

    if (state.isLoading) {
      // Layout-matched skeleton instead of a full-screen spinner, so the tab
      // structure paints instantly and fills in when the (disk-cached) summary
      // resolves. Width-adaptive (stretch/Expanded) — no overflow SE→iPad.
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8),
            SkeletonBox(height: 28, width: 160, radius: 8),
            SizedBox(height: 24),
            Center(child: SkeletonCircle(size: 180)),
            SizedBox(height: 24),
            SkeletonBox(height: 56, radius: 16),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 64, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 64, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 64, radius: 16)),
              ],
            ),
            SizedBox(height: 24),
            SkeletonBox(height: 120, radius: 16),
          ],
        ),
      );
    }

    return AppRefreshIndicator(
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

            // Gap 5 — your saved bottles (one-tap log; long-press to remove).
            _buildCustomBottles().animate().fadeIn(delay: 120.ms),
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
              _SectionHeader(title: AppLocalizations.of(context).hydrationTodaySLog, isDark: widget.isDark),
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

            // Clearance for floating tab bar + MainShell nav.
            SizedBox(
              height: MediaQuery.of(context).viewPadding.bottom +
                  76 +
                  kLiquidGlassActionBarHeight +
                  16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tc = ThemeColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Settings gear — plain hairline icon button (transparent, muted icon).
        IconButton(
          icon: Icon(Icons.settings_outlined, color: tc.textMuted, size: 20),
          onPressed: () => _showGoalSettings(),
          tooltip: AppLocalizations.of(context).hydrationHydrationSettings,
        ),

        // Unit selector — v2 hairline pill (current unit + chevron). Opens the
        // same unit-selection logic via a popup menu over HydrationUnit.values.
        PopupMenuButton<HydrationUnit>(
          initialValue: _selectedUnit,
          color: tc.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.cardBorder),
          ),
          onSelected: (unit) => setState(() => _selectedUnit = unit),
          itemBuilder: (ctx) => HydrationUnit.values.map((unit) {
            return PopupMenuItem<HydrationUnit>(
              value: unit,
              child: Text(
                unit.label.toUpperCase(),
                style: ZType.lbl(
                  12,
                  color: unit == _selectedUnit ? tc.accent : tc.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedUnit.label.toUpperCase(),
                  style: ZType.lbl(10, color: tc.textPrimary, letterSpacing: 1.5),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    color: tc.textMuted, size: 16),
              ],
            ),
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
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

    return ZealovaCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _StatItem(
              label: AppLocalizations.of(context).workoutPlanDrawerCurrent,
              value: _selectedUnit.format(currentMl),
              unit: _selectedUnit.label,
              color: electricBlue,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.cardBorder,
          ),
          Expanded(
            child: _StatItem(
              label: AppLocalizations.of(context).challengeCreateFieldGoal,
              value: _selectedUnit.format(goalMl),
              unit: _selectedUnit.label,
              color: textSecondary,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.cardBorder,
          ),
          Expanded(
            child: _StatItem(
              label: AppLocalizations.of(context).hydrationRemaining,
              value: _selectedUnit.format(remaining),
              unit: _selectedUnit.label,
              color: remaining > 0 ? AppColors.orange : AppColors.success,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
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
      ref.read(posthogServiceProvider).capture(
        eventName: 'water_quick_logged',
        properties: <String, Object>{'amount_ml': amountMl},
      );
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

  /// Gap 5 — the "Your bottles" section: saved presets as one-tap chips plus
  /// an "Add bottle" chip. Long-press a chip to remove it. Width-adaptive Wrap
  /// so it never overflows SE→iPad.
  Widget _buildCustomBottles() {
    final tc = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_drink_outlined, size: 16, color: tc.textMuted),
            const SizedBox(width: 8),
            Text(
              'Your bottles'.toUpperCase(),
              style: ZType.lbl(12, color: tc.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in _customBottles)
              // Hairline v2 chip; label folds in the saved volume. Long-press
              // still removes the saved bottle (ZealovaChip wraps tap only, so
              // the GestureDetector adds the long-press affordance).
              GestureDetector(
                onLongPress: () => _confirmDeleteBottle(b),
                child: ZealovaChip(
                  icon: Icons.water_drop_rounded,
                  label:
                      '${b.label} · ${_selectedUnit.format(b.ml)}${_selectedUnit.label}',
                  onTap: () => _quickLog(b.ml),
                ),
              ),
            // Add-bottle chip
            ZealovaChip(
              icon: Icons.add,
              label: _customBottles.isEmpty ? 'Save a bottle' : 'Add bottle',
              onTap: _showAddBottleDialog,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteBottle(CustomBottle bottle) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove "${bottle.label}"?'),
        content: const Text('This only removes the saved bottle, not any logged water.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) {
      final next = _customBottles.where((b) => b.id != bottle.id).toList();
      await CustomBottleStore.save(widget.userId, next);
      if (mounted) setState(() => _customBottles = next);
    }
  }

  Future<void> _showAddBottleDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final textMuted =
        widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final blue =
        widget.isDark ? AppColors.waterBlue : AppColorsLight.waterBlue;

    final added = await showGlassSheet<bool>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_drink_outlined, color: blue, size: 26),
                  const SizedBox(width: 12),
                  const Text('Save a bottle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Name it and set its size for one-tap logging.',
                  style: TextStyle(fontSize: 14, color: textMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Stanley)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Size',
                  suffixText: 'ml',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final ml = int.tryParse(amountController.text.trim());
                    final name = nameController.text.trim();
                    if (ml != null && ml > 0 && ml <= 10000 && name.isNotEmpty) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Save bottle',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (added == true) {
      final ml = int.tryParse(amountController.text.trim());
      final name = nameController.text.trim();
      if (ml != null && ml > 0 && name.isNotEmpty) {
        final bottle = CustomBottle(
          id: 'b${DateTime.now().microsecondsSinceEpoch}',
          label: name,
          ml: ml.clamp(1, 10000),
        );
        final next = [..._customBottles, bottle];
        await CustomBottleStore.save(widget.userId, next);
        if (mounted) setState(() => _customBottles = next);
      }
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
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

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
                  AppLocalizations.of(context).hydrationCustomAmount,
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
              AppLocalizations.of(context).hydrationEnterAnyAmountIn,
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
                labelText: AppLocalizations.of(context).recipeBuilderSheetAmount,
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
                child: Text(
                  AppLocalizations.of(context).hydrationAddWater,
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
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

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
                labelText: AppLocalizations.of(context).hydrationAmountMl,
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
                labelText: AppLocalizations.of(context).recordAttemptNotesOptional,
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
                child: Text(AppLocalizations.of(context).tilePickerAdd),
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
            // Logs initiated from the Fuel/Water tab — distinguishes from
            // home-screen quick-add and workout rest-timer prompts.
            source: HydrationSource.nutrition,
          );
      if (success && mounted) {
        ref.read(posthogServiceProvider).capture(
          eventName: 'drink_logged',
          properties: <String, Object>{
            'drink_type': type.value,
            'amount_ml': (result['amount'] as num).toInt(),
          },
        );
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
        ? AppColors.waterBlue
        : AppColorsLight.waterBlue;

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
                AppLocalizations.of(context).hydrationDailyGoal,
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
                labelText: AppLocalizations.of(context).hydrationGoalMl,
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
              AppLocalizations.of(context).hydrationRecommended20003000mlPer,
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
                child: Text(AppLocalizations.of(context).hydrationUpdateGoal),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// CustomBottle + CustomBottleStore moved to
// lib/data/services/custom_bottle_store.dart so the home-screen widget sync can
// read saved bottles without a UI→repository import cycle.
