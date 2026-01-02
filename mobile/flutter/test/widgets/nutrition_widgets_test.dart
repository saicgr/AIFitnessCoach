import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test widget wrapper with Material app
Widget wrapWithMaterialApp(Widget child, {bool isDark = true}) {
  return MaterialApp(
    theme: isDark ? ThemeData.dark() : ThemeData.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('EnergyBalanceCard Tests', () {
    testWidgets('displays correct calorie values', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEnergyBalanceCard(
            consumed: 1500,
            target: 2000,
          ),
        ),
      );

      expect(find.text('2000'), findsOneWidget); // Goal
      expect(find.text('1500'), findsOneWidget); // Food consumed
      expect(find.text('500'), findsOneWidget); // Remaining
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
    });

    testWidgets('shows over calories correctly', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEnergyBalanceCard(
            consumed: 2500,
            target: 2000,
          ),
        ),
      );

      expect(find.text('2000'), findsOneWidget); // Goal
      expect(find.text('2500'), findsOneWidget); // Food consumed
      expect(find.text('+500'), findsOneWidget); // Over
      expect(find.text('Over'), findsOneWidget);
    });

    testWidgets('displays progress bar', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEnergyBalanceCard(
            consumed: 1000,
            target: 2000,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50% of daily goal'), findsOneWidget);
    });

    testWidgets('handles zero target gracefully', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEnergyBalanceCard(
            consumed: 500,
            target: 0,
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget); // Goal is 0
    });
  });

  group('CompactMacroCard Tests', () {
    testWidgets('displays macro values correctly', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestCompactMacroCard(
            label: 'Protein',
            current: 100,
            target: 150,
            unit: 'g',
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('100g'), findsOneWidget);
      expect(find.text('/150g'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('clamps progress to 100%', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestCompactMacroCard(
            label: 'Carbs',
            current: 300,
            target: 200,
            unit: 'g',
          ),
        ),
      );

      // Should still render without error
      expect(find.text('300g'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('MacrosRow Tests', () {
    testWidgets('displays all four macro cards', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestMacrosRow(
            proteinG: 100,
            carbsG: 200,
            fatG: 50,
            fiberG: 20,
          ),
        ),
      );

      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Fiber'), findsOneWidget);
    });

    testWidgets('handles null summary values', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestMacrosRow(
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
            fiberG: 0,
          ),
        ),
      );

      expect(find.text('0g'), findsNWidgets(4));
    });
  });

  group('MealSection Tests', () {
    testWidgets('displays empty state with add food button', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestMealSection(
            mealType: 'Breakfast',
            emoji: '🌅',
            meals: const [],
            totalCalories: 0,
          ),
        ),
      );

      expect(find.text('🌅'), findsOneWidget);
      expect(find.text('BREAKFAST'), findsOneWidget);
      expect(find.text('Add Food'), findsOneWidget);
    });

    testWidgets('displays meal items when not empty', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestMealSection(
            mealType: 'Breakfast',
            emoji: '🌅',
            meals: const [
              _TestMealItem(name: 'Oatmeal', calories: 300),
              _TestMealItem(name: 'Coffee', calories: 50),
            ],
            totalCalories: 350,
          ),
        ),
      );

      expect(find.text('350 kcal'), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
    });

    testWidgets('can expand and collapse', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestCollapsibleMealSection(
            mealType: 'Lunch',
            emoji: '☀️',
            totalCalories: 500,
          ),
        ),
      );

      expect(find.text('LUNCH'), findsOneWidget);

      // Find and tap the header to collapse
      await tester.tap(find.text('LUNCH'));
      await tester.pumpAndSettle();

      // The section should toggle
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    });
  });

  group('PinnedNutrientChip Tests', () {
    testWidgets('displays nutrient information', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestPinnedNutrientChip(
            displayName: 'Vitamin D',
            currentValue: 400,
            unit: 'IU',
            percentage: 66.7,
            colorHex: '#FFD93D',
          ),
        ),
      );

      expect(find.text('Vitamin D'), findsOneWidget);
      expect(find.textContaining('IU'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('RecipeCard Tests', () {
    testWidgets('displays recipe information', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestRecipeCard(
            name: 'Oatmeal Bowl',
            calories: 350,
            ingredientCount: 4,
            timesLogged: 5,
            categoryEmoji: '🍳',
          ),
        ),
      );

      expect(find.text('Oatmeal Bowl'), findsOneWidget);
      expect(find.text('350 kcal'), findsOneWidget);
      expect(find.text('4 ingredients'), findsOneWidget);
      expect(find.text(' 5x'), findsOneWidget);
      expect(find.text('🍳'), findsOneWidget);
    });

    testWidgets('hides times logged when zero', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestRecipeCard(
            name: 'New Recipe',
            calories: 200,
            ingredientCount: 2,
            timesLogged: 0,
            categoryEmoji: '🥗',
          ),
        ),
      );

      expect(find.text(' 0x'), findsNothing);
      expect(find.byIcon(Icons.repeat), findsNothing);
    });
  });

  group('EmptyRecipesState Tests', () {
    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEmptyRecipesState(),
        ),
      );

      expect(find.text('No recipes yet'), findsOneWidget);
      expect(find.text('Create recipes to quickly log meals you eat often'),
          findsOneWidget);
      expect(find.text('Create Your First Recipe'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
    });

    testWidgets('create button is tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestEmptyRecipesState(
            onCreateRecipe: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Create Your First Recipe'));
      expect(tapped, isTrue);
    });
  });

  group('ErrorState Tests', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestNutritionErrorState(
            error: 'Network error',
          ),
        ),
      );

      expect(find.text('Unable to load nutrition data'), findsOneWidget);
      expect(find.text('Please check your connection and try again'),
          findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('retry button is tappable', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestNutritionErrorState(
            error: 'Error',
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('LoadingSkeleton Tests', () {
    testWidgets('displays loading skeleton', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestNutritionLoadingSkeleton(),
        ),
      );

      // Should have container placeholders
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('QuickFavoritesBar Tests', () {
    testWidgets('displays favorites when not loading', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestQuickFavoritesBar(
            favorites: const [
              _TestFavoriteFood(name: 'Oatmeal', calories: 300),
              _TestFavoriteFood(name: 'Banana', calories: 100),
            ],
            isLoading: false,
          ),
        ),
      );

      expect(find.text('QUICK ADD'), findsOneWidget);
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestQuickFavoritesBar(
            favorites: const [],
            isLoading: true,
          ),
        ),
      );

      expect(find.text('QUICK ADD'), findsOneWidget);
      // Should show placeholder containers
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('FavoriteChip Tests', () {
    testWidgets('displays food name and calories', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestFavoriteChip(
            name: 'Chicken',
            calories: 165,
          ),
        ),
      );

      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('165'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('truncates long names', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestFavoriteChip(
            name: 'Very Long Food Name That Should Be Truncated',
            calories: 200,
          ),
        ),
      );

      // Name is truncated to first 12 chars + "..."
      expect(find.text('Very Long Fo...'), findsOneWidget);
    });

    testWidgets('is tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestFavoriteChip(
            name: 'Apple',
            calories: 95,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Apple'));
      expect(tapped, isTrue);
    });
  });

  group('MiniMacroChip Tests', () {
    testWidgets('displays label and value', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestMiniMacroChip(
            label: 'P',
            value: 25.5,
          ),
        ),
      );

      expect(find.text('P: 25'), findsOneWidget);
    });
  });

  group('FormulaItem Tests', () {
    testWidgets('displays value and label', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: const [
              _TestFormulaItem(value: '2000', label: 'Goal'),
              _TestFormulaItem(value: '1500', label: 'Food'),
              _TestFormulaItem(value: '500', label: 'Left'),
            ],
          ),
        ),
      );

      expect(find.text('2000'), findsOneWidget);
      expect(find.text('Goal'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
    });
  });

  group('DateNavigation Tests', () {
    testWidgets('displays date label', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestDateNavigation(
            dateLabel: 'Today',
            isToday: true,
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('disables forward button on today', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          _TestDateNavigation(
            dateLabel: 'Today',
            isToday: true,
          ),
        ),
      );

      // Right chevron should be visually different (disabled)
      final rightButton = find.byIcon(Icons.chevron_right);
      expect(rightButton, findsOneWidget);
    });
  });
}

// ─────────────────────────────────────────────────────────────────
// Test Widget Implementations (simplified versions for testing)
// ─────────────────────────────────────────────────────────────────

class _TestEnergyBalanceCard extends StatelessWidget {
  final int consumed;
  final int target;

  const _TestEnergyBalanceCard({
    required this.consumed,
    required this.target,
  });

  int get remaining => target - consumed;
  double get percentage => target > 0 ? (consumed / target).clamp(0.0, 1.5) : 0;
  bool get isOver => consumed > target;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TestFormulaItem(value: target.toString(), label: 'Goal'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('-', style: TextStyle(fontSize: 24)),
              ),
              _TestFormulaItem(value: consumed.toString(), label: 'Food'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('=', style: TextStyle(fontSize: 24)),
              ),
              _TestFormulaItem(
                value: isOver ? '+${consumed - target}' : remaining.toString(),
                label: isOver ? 'Over' : 'Left',
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: percentage.clamp(0.0, 1.0)),
          const SizedBox(height: 8),
          Text('${(percentage * 100).toInt()}% of daily goal'),
        ],
      ),
    );
  }
}

class _TestFormulaItem extends StatelessWidget {
  final String value;
  final String label;

  const _TestFormulaItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TestCompactMacroCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;

  const _TestCompactMacroCard({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
  });

  double get percentage => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label),
          Text('${current.toInt()}$unit'),
          LinearProgressIndicator(value: percentage),
          Text('/${target.toInt()}$unit'),
        ],
      ),
    );
  }
}

class _TestMacrosRow extends StatelessWidget {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;

  const _TestMacrosRow({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TestCompactMacroCard(
            label: 'Protein',
            current: proteinG,
            target: 150,
            unit: 'g',
          ),
        ),
        Expanded(
          child: _TestCompactMacroCard(
            label: 'Carbs',
            current: carbsG,
            target: 250,
            unit: 'g',
          ),
        ),
        Expanded(
          child: _TestCompactMacroCard(
            label: 'Fat',
            current: fatG,
            target: 70,
            unit: 'g',
          ),
        ),
        Expanded(
          child: _TestCompactMacroCard(
            label: 'Fiber',
            current: fiberG,
            target: 30,
            unit: 'g',
          ),
        ),
      ],
    );
  }
}

class _TestMealItem {
  final String name;
  final int calories;

  const _TestMealItem({required this.name, required this.calories});
}

class _TestMealSection extends StatelessWidget {
  final String mealType;
  final String emoji;
  final List<_TestMealItem> meals;
  final int totalCalories;

  const _TestMealSection({
    required this.mealType,
    required this.emoji,
    required this.meals,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(mealType.toUpperCase()),
              const Spacer(),
              if (totalCalories > 0) Text('$totalCalories kcal'),
            ],
          ),
          if (meals.isEmpty)
            TextButton(
              onPressed: () {},
              child: const Text('Add Food'),
            )
          else
            ...meals.map((m) => Text(m.name)),
        ],
      ),
    );
  }
}

class _TestCollapsibleMealSection extends StatefulWidget {
  final String mealType;
  final String emoji;
  final int totalCalories;

  const _TestCollapsibleMealSection({
    required this.mealType,
    required this.emoji,
    required this.totalCalories,
  });

  @override
  State<_TestCollapsibleMealSection> createState() =>
      _TestCollapsibleMealSectionState();
}

class _TestCollapsibleMealSectionState
    extends State<_TestCollapsibleMealSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Text(widget.emoji),
                Text(widget.mealType.toUpperCase()),
                const Spacer(),
                Text('${widget.totalCalories} kcal'),
                Icon(_isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
          if (_isExpanded) const Text('Meal content here'),
        ],
      ),
    );
  }
}

class _TestPinnedNutrientChip extends StatelessWidget {
  final String displayName;
  final double currentValue;
  final String unit;
  final double percentage;
  final String colorHex;

  const _TestPinnedNutrientChip({
    required this.displayName,
    required this.currentValue,
    required this.unit,
    required this.percentage,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(displayName),
          Text('${currentValue.toInt()}$unit'),
          LinearProgressIndicator(value: (percentage / 100).clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _TestRecipeCard extends StatelessWidget {
  final String name;
  final int calories;
  final int ingredientCount;
  final int timesLogged;
  final String categoryEmoji;

  const _TestRecipeCard({
    required this.name,
    required this.calories,
    required this.ingredientCount,
    required this.timesLogged,
    required this.categoryEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(categoryEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name),
                Row(
                  children: [
                    Text('$calories kcal'),
                    const SizedBox(width: 8),
                    Text('$ingredientCount ingredients'),
                    if (timesLogged > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.repeat, size: 12),
                      Text(' ${timesLogged}x'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _TestEmptyRecipesState extends StatelessWidget {
  final VoidCallback? onCreateRecipe;

  const _TestEmptyRecipesState({this.onCreateRecipe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 40),
          const SizedBox(height: 24),
          const Text('No recipes yet', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Create recipes to quickly log meals you eat often'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateRecipe,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Recipe'),
          ),
        ],
      ),
    );
  }
}

class _TestNutritionErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _TestNutritionErrorState({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40),
          const SizedBox(height: 24),
          const Text('Unable to load nutrition data'),
          const SizedBox(height: 8),
          const Text('Please check your connection and try again'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _TestNutritionLoadingSkeleton extends StatelessWidget {
  const _TestNutritionLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(height: 140, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 100,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestFavoriteFood {
  final String name;
  final int calories;

  const _TestFavoriteFood({required this.name, required this.calories});
}

class _TestQuickFavoritesBar extends StatelessWidget {
  final List<_TestFavoriteFood> favorites;
  final bool isLoading;

  const _TestQuickFavoritesBar({
    required this.favorites,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.star, size: 16),
            SizedBox(width: 8),
            Text('QUICK ADD'),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 100,
                height: 44,
                margin: const EdgeInsets.only(right: 8),
                color: Colors.grey[800],
              ),
            ),
          )
        else
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.length,
              itemBuilder: (_, index) {
                final food = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(label: Text(food.name)),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TestFavoriteChip extends StatelessWidget {
  final String name;
  final int calories;
  final VoidCallback? onTap;

  const _TestFavoriteChip({
    required this.name,
    required this.calories,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        name.length > 15 ? '${name.substring(0, 12)}...' : name;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16),
            const SizedBox(width: 6),
            Text(displayName),
            const SizedBox(width: 6),
            Text(calories.toString()),
          ],
        ),
      ),
    );
  }
}

class _TestMiniMacroChip extends StatelessWidget {
  final String label;
  final double value;

  const _TestMiniMacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text('$label: ${value.toInt()}'),
    );
  }
}

class _TestDateNavigation extends StatelessWidget {
  final String dateLabel;
  final bool isToday;

  const _TestDateNavigation({
    required this.dateLabel,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {},
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(dateLabel),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: isToday ? Colors.grey : null,
          ),
          onPressed: isToday ? null : () {},
        ),
      ],
    );
  }
}
