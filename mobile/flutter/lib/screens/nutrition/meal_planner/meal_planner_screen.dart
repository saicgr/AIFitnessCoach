/// Meal Planner — day view with 4 meal slots, live macro projection,
/// AI coach review, and Apply-to-today.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/coach_review.dart';
import '../../../data/models/grocery_list.dart';
import '../../../data/models/meal_plan.dart';
import '../../../data/models/scheduled_recipe.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../grocery/grocery_list_screen.dart';
import '../recipes/widgets/coach_review_sheet.dart';

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

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  MealPlan? _plan;
  SimulateResponse? _sim;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _hideNavBar();
  }

  @override
  void reassemble() {
    super.reassemble();
    _hideNavBar();
  }

  void _hideNavBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final repo = ref.read(recipeRepositoryProvider);
    try {
      final plans = await repo.listMealPlans(widget.userId, planDate: widget.date);
      MealPlan plan;
      if (plans.isEmpty) {
        plan = await repo.createMealPlan(
          widget.userId,
          MealPlanCreate(planDate: widget.date, name: 'Plan for ${widget.date.month}/${widget.date.day}'),
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
      final sim = await repo.simulatePlan(plan.id, withSwaps: false);
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
                  child: Text('Plan day',
                    style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Save as template',
                  icon: Icon(Icons.bookmark_add_outlined, color: muted),
                  onPressed: _plan == null ? null : () async {
                    await ref.read(recipeRepositoryProvider).updateMealPlan(_plan!.id, {'is_template': true});
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved as template')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    backgroundColor: surface,
                    builder: (_) => CoachReviewSheet(
                      subjectType: CoachReviewSubject.mealPlan,
                      subjectId: _plan!.id, userId: widget.userId, isDark: isDark,
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_outlined),
                label: const Text('Coach review'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
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
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Grocery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final res = await ref.read(recipeRepositoryProvider).applyPlan(_plan!.id, widget.date);
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
                icon: const Icon(Icons.check),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody(Color accent, Color text, Color muted, Color surface) {
    final p = _plan!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // Macro projection at TOP — ring-based so the user sees nutrition
        // progress toward their targets at a glance without scrolling.
        if (_sim != null) ...[
          _MacroRingsHeader(sim: _sim!, isDark: widget.isDark, accent: accent),
          const SizedBox(height: 12),
        ],
        for (final m in MealSlot.values)
          _MealSlotCard(
            mealType: m, items: p.items.where((i) => i.mealType == m).toList(),
            isDark: widget.isDark, accent: accent,
            onAdd: () => _addToSlot(m),
            onRemove: (id) async {
              await ref.read(recipeRepositoryProvider).removePlanItem(p.id, id);
              await _load();
            },
          ),
      ],
    );
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

class _MealSlotCard extends StatelessWidget {
  final MealSlot mealType;
  final List<MealPlanItem> items;
  final bool isDark;
  final Color accent;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  const _MealSlotCard({
    required this.mealType, required this.items, required this.isDark,
    required this.accent, required this.onAdd, required this.onRemove,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('$emoji ${mealType.value.toUpperCase()}',
                style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const Spacer(),
            IconButton(icon: Icon(Icons.add_circle_outline, color: accent), onPressed: onAdd),
          ]),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text('(empty — tap + to add)', style: TextStyle(color: muted, fontSize: 12)),
            )
          else
            ...items.map((i) => ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.restaurant_menu, color: accent, size: 18),
              title: Text(i.recipeId != null ? 'Recipe' : 'Custom items',
                  style: TextStyle(color: text)),
              subtitle: Text('×${i.servings.toStringAsFixed(1)} servings',
                  style: TextStyle(color: muted, fontSize: 11)),
              trailing: IconButton(
                icon: Icon(Icons.close, size: 16, color: muted),
                onPressed: () => onRemove(i.id),
              ),
            )),
        ],
      ),
    );
  }
}

/// Top-of-screen ring-based macro projection.
///
/// Layout: a large calories ring on the left (showing kcal / target in the
/// center) + three smaller macro ring tiles on the right (protein, carbs, fat).
/// Replaces the linear-bar "Macro projection" section that used to sit at the
/// bottom — moving it to the top so users see plan nutrition at a glance.
class _MacroRingsHeader extends StatelessWidget {
  final SimulateResponse sim;
  final bool isDark;
  final Color accent;
  const _MacroRingsHeader({required this.sim, required this.isDark, required this.accent});

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

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Macro projection',
                style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large calories ring
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _SingleRingPainter(
                    progress: calTarget > 0 ? (cal / calTarget).clamp(0.0, 1.5) : 0,
                    color: accent,
                    trackColor: trackColor,
                    strokeWidth: 14,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cal.toStringAsFixed(0),
                          style: TextStyle(
                            color: text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '/ ${calTarget.toStringAsFixed(0)}',
                          style: TextStyle(color: muted, fontSize: 11, height: 1.0),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'kcal',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Macro mini-rings
              Expanded(
                child: Column(
                  children: [
                    _MacroMiniRing(
                      label: 'Protein',
                      current: protein,
                      target: proteinTarget,
                      color: AppColors.macroProtein,
                      trackColor: trackColor,
                      text: text,
                      muted: muted,
                    ),
                    const SizedBox(height: 10),
                    _MacroMiniRing(
                      label: 'Carbs',
                      current: carbs,
                      target: carbsTarget,
                      color: AppColors.macroCarbs,
                      trackColor: trackColor,
                      text: text,
                      muted: muted,
                    ),
                    const SizedBox(height: 10),
                    _MacroMiniRing(
                      label: 'Fat',
                      current: fat,
                      target: fatTarget,
                      color: AppColors.macroFat,
                      trackColor: trackColor,
                      text: text,
                      muted: muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMiniRing extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final Color trackColor;
  final Color text;
  final Color muted;
  const _MacroMiniRing({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.trackColor,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _SingleRingPainter(
              progress: pct.toDouble(),
              color: color,
              trackColor: trackColor,
              strokeWidth: 5,
            ),
            child: Center(
              child: Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} g',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints a single progress ring (track + arc from 12 o'clock).
/// Used for the big calories ring + the 3 macro mini-rings.
class _SingleRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  _SingleRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final effective = progress <= 0 ? 0.0 : progress;
    final clamped = effective.clamp(0.0, 1.0);
    final sweep = 2 * math.pi * clamped;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (clamped > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    }

    // Overshoot (lighter color wrapping around) when over 100%.
    if (progress > 1.0) {
      final overshoot = (progress - 1.0).clamp(0.0, 0.5);
      final overshootSweep = 2 * math.pi * overshoot;
      final overshootPaint = Paint()
        ..color = Color.lerp(color, Colors.white, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, overshootSweep, false, overshootPaint);
    }
  }

  @override
  bool shouldRepaint(_SingleRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
      title: const Text('Add a recipe'),
      content: SizedBox(
        width: 320,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search your recipes…'),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _q.length < 2
                  ? Center(child: Text('Type 2+ chars', style: TextStyle(color: accent)))
                  : Consumer(builder: (_, ref, __) {
                      return FutureBuilder(
                        future: ref.read(recipeRepositoryProvider).search(widget.userId, query: _q),
                        builder: (_, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
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
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
      ],
    );
  }
}
