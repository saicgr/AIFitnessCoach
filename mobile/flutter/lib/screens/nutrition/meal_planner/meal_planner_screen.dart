/// Meal Planner — day view with 4 meal slots, live macro projection,
/// AI coach review, and Apply-to-today.
library;

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
        const SizedBox(height: 12),
        if (_sim != null) _MacroProjectionCard(sim: _sim!, isDark: widget.isDark, accent: accent),
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

class _MacroProjectionCard extends StatelessWidget {
  final SimulateResponse sim;
  final bool isDark;
  final Color accent;
  const _MacroProjectionCard({required this.sim, required this.isDark, required this.accent});
  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macro projection', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _row('Calories', sim.totals.calories, sim.targetSnapshot['calories'], 'kcal', text, accent, muted),
          _row('Protein', sim.totals.proteinG, sim.targetSnapshot['protein_g'], 'g', text, AppColors.success, muted),
          _row('Carbs', sim.totals.carbsG, sim.targetSnapshot['carbs_g'], 'g', text, AppColors.yellow, muted),
          _row('Fat', sim.totals.fatG, sim.targetSnapshot['fat_g'], 'g', text, AppColors.purple, muted),
        ],
      ),
    );
  }

  Widget _row(String label, double cur, dynamic targetRaw, String unit, Color text, Color color, Color muted) {
    final target = (targetRaw as num?)?.toDouble() ?? 0;
    final pct = target > 0 ? (cur / target).clamp(0, 1.5) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: text, fontSize: 12))),
          Text('${cur.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: TextStyle(color: muted, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.toDouble(), minHeight: 6,
            color: color, backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ]),
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
