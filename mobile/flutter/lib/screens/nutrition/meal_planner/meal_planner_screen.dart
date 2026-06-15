/// Meal Planner — day view with 4 meal slots, live macro projection,
/// AI coach review, and Apply-to-today.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/widgets/skeleton/skeleton.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../data/models/coach_review.dart';
import '../../../data/models/grocery_list.dart';
import '../../../data/models/meal_plan.dart';
import '../../../data/models/scheduled_recipe.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/nav_bar_hider_mixin.dart';
import '../grocery/grocery_list_screen.dart';
import '../recipes/widgets/coach_review_sheet.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
class MealPlannerScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final DateTime date;
  final String? addRecipeId; // when launched from a recipe's "Add to plan" CTA
  const MealPlannerScreen({
    super.key,
    required this.userId,
    required this.isDark,
    required this.date,
    this.addRecipeId,
  });
  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen>
    with NavBarHiderMixin {
  MealPlan? _plan;
  SimulateResponse? _sim;
  bool _loading = true;
  String? _error;

  /// The day currently being planned. Initialised from the route/caller's
  /// `date`, then swapped by the multi-day day-strip — each day has its own
  /// per-date meal plan (the backend is per-date), so changing the day just
  /// re-fetches/creates that day's plan.
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.date);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(recipeRepositoryProvider);
    try {
      final plans = await repo.listMealPlans(widget.userId, planDate: _selectedDate);
      MealPlan plan;
      if (plans.isEmpty) {
        plan = await repo.createMealPlan(
          widget.userId,
          MealPlanCreate(planDate: _selectedDate, name: 'Plan for ${_selectedDate.month}/${_selectedDate.day}'),
        );
      } else {
        plan = plans.first;
      }
      // If launched with an add request, append it
      if (widget.addRecipeId != null) {
        await repo.addPlanItem(plan.id, MealPlanItemCreate(
          mealType: MealSlot.lunch, recipeId: widget.addRecipeId,
        ));
        plan = await repo.getMealPlan(plan.id);
      }
      // withSwaps: true so the backend returns per-item AI alternates
      // (`swap_suggestions`) — surfaced as a one-tap "↻ swap" on each slot.
      final sim = await repo.simulatePlan(plan.id, withSwaps: true);
      if (mounted) setState(() { _plan = plan; _sim = sim; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          SizedBox(height: topPad + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocalizations.of(context).recipesPlanDay.toUpperCase(),
                    style: ZType.disp(26, color: text, letterSpacing: 0.5)),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).mealPlannerSaveAsTemplate,
                  icon: Icon(Icons.bookmark_add_outlined, color: muted),
                  onPressed: _plan == null ? null : () async {
                    await ref.read(recipeRepositoryProvider).updateMealPlan(_plan!.id, {'is_template': true});
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).mealPlannerSavedAsTemplate)));
                  },
                ),
              ],
            ),
          ),
          // Multi-day strip — plan any of the next two weeks, not just today.
          _buildDayStrip(text, muted, accent, surface),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                // Layout-matched skeleton: a macro-rings header block + four
                // meal-slot card placeholders, mirroring _buildBody so the
                // skeleton→content swap is reflow-free. No blocking spinner.
                ? const _MealPlannerSkeleton()
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Error: $_error',
                              style: TextStyle(color: muted), textAlign: TextAlign.center),
                        ),
                      )
                    : _buildBody(accent, text, muted, surface),
          ),
        ],
      ),
      bottomNavigationBar: _plan == null ? null : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          // LayoutBuilder lets us swap Row→Wrap on narrow devices (iPhone SE
          // is 320dp). Per feedback_no_overflow_adaptive_screens.md — never
          // overflow on small screens. ✅
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ✦ Coach review — ghost (secondary). Opens the glass score sheet.
              final coachBtn = ZealovaButton(
                label: AppLocalizations.of(context).recipeDetailCoachReview,
                variant: ZealovaButtonVariant.ghost,
                height: 48,
                onTap: () {
                  showGlassSheet<void>(
                    context: context,
                    builder: (_) => GlassSheet(
                      child: CoachReviewSheet(
                        subjectType: CoachReviewSubject.mealPlan,
                        subjectId: _plan!.id, userId: widget.userId, isDark: isDark,
                      ),
                    ),
                  );
                },
              );
              // 🛒 Grocery — ghost (secondary). Builds the list.
              final groceryBtn = ZealovaButton(
                label: AppLocalizations.of(context).mealPlannerGrocery,
                variant: ZealovaButtonVariant.ghost,
                height: 48,
                onTap: () async {
                  try {
                    final list = await ref.read(recipeRepositoryProvider).buildGroceryList(
                      widget.userId, GroceryListCreate(mealPlanId: _plan!.id),
                    );
                    if (mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                          GroceryListScreen(listId: list.id, userId: widget.userId, isDark: isDark)));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
              );
              // ✓ Apply day — THE one reserved-accent CTA. Logs every slot.
              final applyBtn = ZealovaButton(
                label: AppLocalizations.of(context).setAdjustmentSheetApply,
                variant: ZealovaButtonVariant.primary,
                height: 48,
                trailingIcon: Icons.check,
                onTap: () async {
                  try {
                    final res = await ref.read(recipeRepositoryProvider).applyPlan(_plan!.id, _selectedDate);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
                        'Logged ${res.foodLogIds.length} item(s)'
                        '${res.duplicatesWarning != null ? ' (${res.duplicatesWarning})' : ''}',
                      )));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
              );

              // Below ~420dp width, three buttons in a Row clip "Coach review"
              // and "Grocery" to "Co...", "Gro..." even with ellipsis (icon +
              // padding eats most of the per-button width on iPhone 17 Pro
              // class devices). Switch to a 2-column Wrap so labels stay
              // readable. ⚠️
              if (constraints.maxWidth < 420) {
                final btnWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: btnWidth, child: coachBtn),
                    SizedBox(width: btnWidth, child: groceryBtn),
                    // Apply spans full width on a third row for emphasis
                    SizedBox(width: constraints.maxWidth, child: applyBtn),
                  ],
                );
              }

              return Row(children: [
                Expanded(child: coachBtn),
                const SizedBox(width: 8),
                Expanded(child: groceryBtn),
                const SizedBox(width: 8),
                Expanded(child: applyBtn),
              ]);
            },
          ),
        ),
      ),
    );
  }

  /// Horizontal day selector — today + the next 13 days. Tapping a day swaps
  /// `_selectedDate` and re-fetches that day's plan. Keeps the planner a
  /// multi-day tool rather than today-only.
  Widget _buildDayStrip(Color text, Color muted, Color accent, Color surface) {
    final today = DateUtils.dateOnly(DateTime.now());
    const weekday = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = today.add(Duration(days: i));
          final selected = DateUtils.isSameDay(day, _selectedDate);
          final isToday = i == 0;
          return GestureDetector(
            onTap: selected
                ? null
                : () {
                    setState(() => _selectedDate = day);
                    _load();
                  },
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: selected ? accent : surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? accent : AppColors.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : weekday[day.weekday],
                    style: ZType.lbl(9,
                        color: selected
                            ? ThemeColors.of(context).accentContrast
                            : muted,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: ZType.disp(18,
                        color: selected
                            ? ThemeColors.of(context).accentContrast
                            : text),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(Color accent, Color text, Color muted, Color surface) {
    final p = _plan!;
    // Per-item AI alternates from the simulate pass. Only recipe-backed swaps
    // are one-tap-applicable here (the Dart model carries `newRecipeId`).
    final swaps = <String, AiSwapSuggestion>{};
    for (final s in _sim?.swapSuggestions ?? const <AiSwapSuggestion>[]) {
      final id = s.itemId;
      if (id != null && s.newRecipeId != null) swaps[id] = s;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // Macro projection at TOP — Signature hairline bars (no rings) so the
        // user sees planned nutrition toward their targets at a glance.
        if (_sim != null) ...[
          _MacroProjection(sim: _sim!, isDark: widget.isDark),
          const SizedBox(height: 12),
        ],
        for (final m in MealSlot.values)
          _MealSlotCard(
            mealType: m, items: p.items.where((i) => i.mealType == m).toList(),
            isDark: widget.isDark, accent: accent,
            swaps: swaps,
            onAdd: () => _addToSlot(m),
            onRemove: (id) async {
              await ref.read(recipeRepositoryProvider).removePlanItem(p.id, id);
              await _load();
            },
            onSwap: (item, s) => _applySwap(m, item, s),
          ),
      ],
    );
  }

  /// Apply an AI swap to a slot item: drop the current recipe, add the
  /// suggested alternate, and re-simulate. Reuses the existing add/remove
  /// plan-item endpoints (no new backend).
  Future<void> _applySwap(MealSlot meal, MealPlanItem item, AiSwapSuggestion s) async {
    final newId = s.newRecipeId;
    if (newId == null || _plan == null) return;
    final repo = ref.read(recipeRepositoryProvider);
    try {
      await repo.removePlanItem(_plan!.id, item.id);
      await repo.addPlanItem(
        _plan!.id,
        MealPlanItemCreate(mealType: meal, recipeId: newId, servings: item.servings),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Swapped to ${s.toLabel}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Swap failed: $e')));
      }
    }
  }

  Future<void> _addToSlot(MealSlot meal) async {
    final repo = ref.read(recipeRepositoryProvider);
    // Simple inline picker: show a search-result list of the user's recipes
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => _AddRecipeDialog(userId: widget.userId, isDark: widget.isDark),
    );
    if (res == null || _plan == null) return;
    await repo.addPlanItem(_plan!.id, MealPlanItemCreate(mealType: meal, recipeId: res));
    await _load();
  }
}

/// Layout-matched loading placeholder for the meal planner body.
///
/// Mirrors [_MealPlannerScreenState._buildBody]: a tall macro-rings header
/// card followed by four meal-slot card placeholders. Rendered while the plan
/// is being fetched/created so the user never sees a blocking spinner.
class _MealPlannerSkeleton extends StatelessWidget {
  const _MealPlannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Non-scrolling feel — placeholder content fits a phone screen — but a
      // ListView keeps it robust on short devices (iPhone SE) without overflow.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: const [
        // Macro projection header block (≈148pt tall, matching the real
        // rings card).
        SkeletonBox(height: 148, radius: 16),
        SizedBox(height: 12),
        // Four meal-slot card placeholders.
        SkeletonBox(height: 96, radius: 14),
        SizedBox(height: 10),
        SkeletonBox(height: 96, radius: 14),
        SizedBox(height: 10),
        SkeletonBox(height: 96, radius: 14),
        SizedBox(height: 10),
        SkeletonBox(height: 96, radius: 14),
      ],
    );
  }
}

class _MealSlotCard extends StatelessWidget {
  final MealSlot mealType;
  final List<MealPlanItem> items;
  final bool isDark;
  final Color accent;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  /// itemId → AI alternate suggestion (recipe-backed) for that slot item.
  final Map<String, AiSwapSuggestion> swaps;
  final void Function(MealPlanItem item, AiSwapSuggestion swap) onSwap;
  const _MealSlotCard({
    required this.mealType, required this.items, required this.isDark,
    required this.accent, required this.onAdd, required this.onRemove,
    this.swaps = const {}, required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final emoji = switch (mealType) {
      MealSlot.breakfast => '🌅', MealSlot.lunch => '☀️',
      MealSlot.dinner => '🌙', MealSlot.snack => '🍎',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Text(mealType.value.toUpperCase(),
                style: ZType.lbl(12, color: text, letterSpacing: 1.6)),
            const Spacer(),
            // "+" quick-add — white glyph on surface, never accent-filled.
            ZealovaPlusButton(onTap: onAdd, size: 30),
          ]),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 2),
              child: Text(AppLocalizations.of(context).mealPlannerEmptyTapToAdd,
                  style: ZType.lbl(11, color: muted, letterSpacing: 1.2)),
            )
          else
            ...items.map((i) {
              final swap = swaps[i.id];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  ZealovaListRow(
                    icon: Icons.restaurant_menu,
                    label: i.recipeId != null
                        ? AppLocalizations.of(context).mealPlannerRecipe
                        : AppLocalizations.of(context).mealPlannerCustomItems,
                    value: '×${i.servings.toStringAsFixed(1)}',
                    showChevron: false,
                    hairline: false,
                    trailing: IconButton(
                      icon: Icon(Icons.close, size: 16, color: muted),
                      onPressed: () => onRemove(i.id),
                    ),
                  ),
                  // AI alternate for this exact slot — one tap to swap. Hairline
                  // ghost affordance; accent stays reserved for Apply day.
                  if (swap != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 6),
                      child: InkWell(
                        onTap: () => onSwap(i, swap),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.autorenew, size: 14, color: text),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Swap to ${swap.toLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ZType.lbl(11, color: text, letterSpacing: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

/// Top-of-screen macro projection — Signature hairline bars (no rings).
///
/// Layout: a big Anton "planned / target" kcal numeral over three hairline
/// P/C/F bars with semantic macro colors, each showing planned/target grams.
/// Replaces the ring-based header per the Signature spec ("no rings,
/// hairline-led"). Reads the same simulate totals + target snapshot.
class _MacroProjection extends StatelessWidget {
  final SimulateResponse sim;
  final bool isDark;
  const _MacroProjection({required this.sim, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final cal = sim.totals.calories;
    final calTarget = (sim.targetSnapshot['calories'] as num?)?.toDouble() ?? 0;
    final protein = sim.totals.proteinG;
    final proteinTarget = (sim.targetSnapshot['protein_g'] as num?)?.toDouble() ?? 0;
    final carbs = sim.totals.carbsG;
    final carbsTarget = (sim.targetSnapshot['carbs_g'] as num?)?.toDouble() ?? 0;
    final fat = sim.totals.fatG;
    final fatTarget = (sim.targetSnapshot['fat_g'] as num?)?.toDouble() ?? 0;

    String fmt(double v) => v
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZealovaSectionKicker(
            AppLocalizations.of(context).mealPlannerMacroProjection,
            fontSize: 11,
          ),
          const SizedBox(height: 10),
          // Big planned/target calorie numeral — Anton.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(fmt(cal), style: ZType.disp(34, color: text)),
              const SizedBox(width: 4),
              Text('/ ${fmt(calTarget)}',
                  style: ZType.disp(18, color: muted)),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('KCAL',
                    style: ZType.lbl(10, color: muted, letterSpacing: 1.6)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MacroBar(
            keyLabel: 'P',
            current: protein,
            target: proteinTarget,
            color: AppColors.macroProtein,
            text: text,
            muted: muted,
          ),
          const SizedBox(height: 9),
          _MacroBar(
            keyLabel: 'C',
            current: carbs,
            target: carbsTarget,
            color: AppColors.macroCarbs,
            text: text,
            muted: muted,
          ),
          const SizedBox(height: 9),
          _MacroBar(
            keyLabel: 'F',
            current: fat,
            target: fatTarget,
            color: AppColors.macroFat,
            text: text,
            muted: muted,
          ),
        ],
      ),
    );
  }
}

/// A single hairline macro projection bar — key letter, filled bar toward
/// target (semantic color), and a mono planned/target readout.
class _MacroBar extends StatelessWidget {
  final String keyLabel;
  final double current;
  final double target;
  final Color color;
  final Color text;
  final Color muted;
  const _MacroBar({
    required this.keyLabel,
    required this.current,
    required this.target,
    required this.color,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(keyLabel,
              style: ZType.lbl(12, color: color, letterSpacing: 0.5)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: AppColors.hairlineStrong,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.toDouble(),
                child: Container(color: color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${current.toStringAsFixed(0)}/${target.toStringAsFixed(0)}',
          style: ZType.data(11, color: muted),
        ),
      ],
    );
  }
}

class _AddRecipeDialog extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const _AddRecipeDialog({required this.userId, required this.isDark});
  @override
  ConsumerState<_AddRecipeDialog> createState() => _AddRecipeDialogState();
}

class _AddRecipeDialogState extends ConsumerState<_AddRecipeDialog> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    return AlertDialog(
      title: Text(AppLocalizations.of(context).mealPlannerAddARecipe),
      content: SizedBox(
        width: 320,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: AppLocalizations.of(context).mealPlannerSearchYourRecipes),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _q.length < 2
                  ? Center(child: Text(AppLocalizations.of(context).mealPlannerType2Chars, style: TextStyle(color: accent)))
                  : Consumer(builder: (_, ref, __) {
                      return FutureBuilder(
                        future: ref.read(recipeRepositoryProvider).search(widget.userId, query: _q),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            // Skeleton rows instead of a blocking spinner.
                            return const SkeletonList(
                              scrollable: true,
                              itemCount: 5,
                            );
                          }
                          final items = snap.data!.items;
                          return ListView(
                            children: items.map((r) => ListTile(
                              title: Text(r.name),
                              subtitle: Text('${r.caloriesPerServing ?? 0} kcal'),
                              onTap: () => Navigator.pop(context, r.id),
                            )).toList(),
                          );
                        },
                      );
                    }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: Text(AppLocalizations.of(context).buttonCancel)),
      ],
    );
  }
}
