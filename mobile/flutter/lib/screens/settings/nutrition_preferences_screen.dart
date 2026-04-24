/// Menu-of-sections Nutrition Preferences screen. Each tile opens its
/// own sub-screen so users don't scroll a mile-long settings form.
///
/// See plan block F-settings for the UX rationale (Settings-app style
/// list, deep-linked from Settings + Nutrition tab).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/allergen.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../widgets/pill_app_bar.dart';

class NutritionPreferencesScreen extends ConsumerWidget {
  const NutritionPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const PillAppBar(title: 'Nutrition Preferences'),
      body: ListView(
        children: [
          _tile(context, 'Diet & allergens', Icons.restaurant_menu,
              'Diet type, FDA Big 9 allergens, dietary flags',
              () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const DietAndAllergensScreen(),
                  ))),
          _tile(context, 'Foods to avoid', Icons.block,
              'Ingredients or dishes you don\'t eat',
              () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const FoodsToAvoidScreen(),
                  ))),
          _tile(context, 'Budget', Icons.payments_outlined,
              'Meal + daily food spending caps',
              () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const FoodBudgetScreen(),
                  ))),
          _tile(context, 'Inflammation tolerance', Icons.local_fire_department,
              'How strict to be about inflammatory foods',
              () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const InflammationToleranceScreen(),
                  ))),
        ],
      ),
    );
  }

  Widget _tile(BuildContext ctx, String title, IconData icon, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

// ───────────────────── Diet & Allergens ─────────────────────

class DietAndAllergensScreen extends ConsumerStatefulWidget {
  const DietAndAllergensScreen({super.key});

  @override
  ConsumerState<DietAndAllergensScreen> createState() => _DietAndAllergensScreenState();
}

class _DietAndAllergensScreenState extends ConsumerState<DietAndAllergensScreen> {
  static const _dietTypes = [
    'omnivore', 'vegetarian', 'vegan', 'pescatarian',
    'keto', 'paleo', 'mediterranean', 'other',
  ];

  static const _dietaryFlags = [
    'gluten_free', 'dairy_free', 'halal', 'kosher',
    'low_fodmap', 'low_sodium', 'diabetic_friendly',
  ];

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(nutritionPreferencesProvider).preferences;
    if (prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: const PillAppBar(title: 'Diet & Allergens'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Diet type'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in _dietTypes)
              ChoiceChip(
                label: Text(_humanize(d)),
                selected: prefs.dietType == d,
                onSelected: (_) => _savePrefs(prefs.copyWith(dietType: d)),
              ),
          ]),
          const SizedBox(height: 24),
          const _SectionTitle('FDA Big 9 allergens'),
          Column(children: [
            for (final a in Allergen.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${a.glyph}  ${a.displayName}'),
                value: prefs.allergies.contains(a.code),
                onChanged: (v) {
                  final next = [...prefs.allergies];
                  if (v == true) {
                    if (!next.contains(a.code)) next.add(a.code);
                  } else {
                    next.remove(a.code);
                  }
                  _savePrefs(prefs.copyWith(allergies: next));
                },
              ),
          ]),
          const SizedBox(height: 16),
          _FreeTextList(
            title: 'Other allergens',
            subtitle: 'Outside the FDA Big 9 (e.g. mango, nightshade, corn)',
            values: prefs.customAllergens,
            onChanged: (v) => _savePrefs(prefs.copyWith(customAllergens: v)),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Dietary flags'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final flag in _dietaryFlags)
              FilterChip(
                label: Text(_humanize(flag)),
                selected: prefs.dietaryRestrictions.contains(flag),
                onSelected: (sel) {
                  final next = [...prefs.dietaryRestrictions];
                  if (sel) {
                    if (!next.contains(flag)) next.add(flag);
                  } else {
                    next.remove(flag);
                  }
                  _savePrefs(prefs.copyWith(dietaryRestrictions: next));
                },
              ),
          ]),
        ],
      ),
    );
  }

  void _savePrefs(NutritionPreferences p) {
    ref.read(nutritionPreferencesProvider.notifier)
        .savePreferences(userId: p.userId, preferences: p);
  }

  static String _humanize(String raw) =>
      raw.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}

// ───────────────────── Foods to avoid ─────────────────────

class FoodsToAvoidScreen extends ConsumerWidget {
  const FoodsToAvoidScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(nutritionPreferencesProvider).preferences;
    if (prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: const PillAppBar(title: 'Foods to avoid'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FreeTextList(
            title: 'Dislikes',
            subtitle: 'Dishes or ingredients you prefer we hide from recommendations',
            values: prefs.dislikedFoods,
            onChanged: (v) {
              final next = prefs.copyWith(dislikedFoods: v);
              ref.read(nutritionPreferencesProvider.notifier)
                  .savePreferences(userId: next.userId, preferences: next);
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Budget ─────────────────────

class FoodBudgetScreen extends ConsumerStatefulWidget {
  const FoodBudgetScreen({super.key});

  @override
  ConsumerState<FoodBudgetScreen> createState() => _FoodBudgetScreenState();
}

class _FoodBudgetScreenState extends ConsumerState<FoodBudgetScreen> {
  final _mealController = TextEditingController();
  final _dailyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (prefs != null) {
      _mealController.text = prefs.mealBudgetUsd?.toStringAsFixed(2) ?? '';
      _dailyController.text = prefs.dailyFoodBudgetUsd?.toStringAsFixed(2) ?? '';
    }
  }

  @override
  void dispose() {
    _mealController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PillAppBar(title: 'Food budget'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Used by Menu Analysis to filter dishes above your budget and by '
            'recommendations to avoid pushing you over.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _mealController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Meal budget (USD)',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            onChanged: _saveDebounced,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dailyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Daily food budget (USD, optional)',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            onChanged: _saveDebounced,
          ),
        ],
      ),
    );
  }

  void _saveDebounced(String _) {
    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (prefs == null) return;
    final meal = double.tryParse(_mealController.text.trim());
    final daily = double.tryParse(_dailyController.text.trim());
    final next = prefs.copyWith(
      mealBudgetUsd: meal,
      dailyFoodBudgetUsd: daily,
    );
    ref.read(nutritionPreferencesProvider.notifier)
        .savePreferences(userId: next.userId, preferences: next);
  }
}

// ───────────────────── Inflammation tolerance ─────────────────────

class InflammationToleranceScreen extends ConsumerWidget {
  const InflammationToleranceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(nutritionPreferencesProvider).preferences;
    if (prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: const PillAppBar(title: 'Inflammation tolerance'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'How strict should we be when flagging inflammatory foods? '
            '1 = don\'t penalize · 5 = penalize heavily.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Slider(
            value: prefs.inflammationSensitivity.toDouble(),
            min: 1, max: 5, divisions: 4,
            label: '${prefs.inflammationSensitivity}',
            activeColor: AppColors.orange,
            onChanged: (v) {
              final next = prefs.copyWith(inflammationSensitivity: v.round());
              ref.read(nutritionPreferencesProvider.notifier)
                  .savePreferences(userId: next.userId, preferences: next);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Lenient', style: TextStyle(fontSize: 11)),
              Text('Strict', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Shared helpers ─────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _FreeTextList extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  const _FreeTextList({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.onChanged,
  });
  @override
  State<_FreeTextList> createState() => _FreeTextListState();
}

class _FreeTextListState extends State<_FreeTextList> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    if (widget.values.contains(v)) return;
    widget.onChanged([...widget.values, v]);
    _controller.clear();
  }

  void _remove(String v) {
    widget.onChanged([...widget.values]..remove(v));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(widget.title),
        Text(widget.subtitle, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final v in widget.values)
            InputChip(label: Text(v), onDeleted: () => _remove(v)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Add…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _add,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
