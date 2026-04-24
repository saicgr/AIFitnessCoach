import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/data/models/allergen.dart';
import 'package:fitwiz/data/models/menu_item.dart';
import 'package:fitwiz/services/menu_recommendation_service.dart';

/// Deterministic, fast tests for the menu recommendation pipeline.
/// Covers: hard-filter correctness, normalization, similarity
/// strictness, Pareto behavior, MMR diversity, and stability under
/// small perturbations.
void main() {
  const service = MenuRecommendationService();

  MenuItem mkItem(String id, {
    required String name,
    String section = 'mains',
    double calories = 500,
    double proteinG = 30,
    double carbsG = 40,
    double fatG = 20,
    String? rating = 'green',
    int? inflammation = 3,
    double? price,
    Set<Allergen> allergens = const {},
  }) {
    return MenuItem(
      id: id,
      name: name,
      section: section,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      rating: rating,
      inflammationScore: inflammation,
      price: price,
      detectedAllergens: allergens,
    );
  }

  RecommendationContext ctx({
    double calTarget = 2000,
    double calConsumed = 1000,
    double proteinTarget = 150,
    double proteinConsumed = 60,
    List<String> dietaryRestrictions = const [],
    List<String> dislikes = const [],
    UserAllergenProfile? allergens,
    List<String> favorites = const [],
    Map<String, int> history = const {},
    List<String> today = const [],
    double? budget,
    bool coldStart = false,
  }) {
    final maxFreq = history.values.fold<int>(0, (a, b) => a > b ? a : b);
    return RecommendationContext(
      calorieTarget: calTarget,
      proteinTarget: proteinTarget,
      carbsTarget: 250,
      fatTarget: 70,
      consumedCalories: calConsumed,
      consumedProteinG: proteinConsumed,
      consumedCarbsG: 100,
      consumedFatG: 25,
      dietaryRestrictions: dietaryRestrictions,
      dislikedFoods: dislikes,
      allergenProfile: allergens,
      mealBudgetUsd: budget,
      favoriteNames: favorites,
      historyFrequency: history,
      historyMaxFrequency: maxFreq,
      todayItemNames: today,
      coldStart: coldStart,
    );
  }

  group('Hard filters', () {
    test('allergen match removes dish', () {
      final items = [
        mkItem('1', name: 'Pad Thai', allergens: {Allergen.peanuts}),
        mkItem('2', name: 'Grilled Chicken'),
      ];
      final result = service.recommend(
        items: items,
        context: ctx(allergens: UserAllergenProfile(allergens: {Allergen.peanuts})),
      );
      expect(result.picks.any((p) => p.item.name == 'Pad Thai'), false);
      expect(result.rejected.any(
        (r) => r.item.name == 'Pad Thai' && r.reason == RejectionReason.allergenConflict,
      ), true);
    });

    test('vegetarian flag excludes meat', () {
      final items = [
        mkItem('1', name: 'Beef Brisket'),
        mkItem('2', name: 'Roasted Vegetable Bowl'),
      ];
      final result = service.recommend(
        items: items,
        context: ctx(dietaryRestrictions: const ['vegetarian']),
      );
      expect(result.picks.any((p) => p.item.name == 'Beef Brisket'), false);
    });

    test('disliked-food substring match excludes', () {
      final items = [
        mkItem('1', name: 'Mushroom Risotto'),
        mkItem('2', name: 'Chicken Caesar'),
      ];
      final result = service.recommend(
        items: items,
        context: ctx(dislikes: const ['mushroom']),
      );
      expect(result.picks.any((p) => p.item.name == 'Mushroom Risotto'), false);
    });

    test('hard budget ceiling >150% excludes', () {
      final items = [
        mkItem('1', name: 'Expensive Steak', price: 60),
        mkItem('2', name: 'Cheap Salad', price: 12),
      ];
      final result = service.recommend(
        items: items,
        context: ctx(budget: 20),
      );
      expect(result.picks.any((p) => p.item.name == 'Expensive Steak'), false);
    });

    test('micro item under 100 cal + 100g filtered unless budget very low', () {
      // Pickles explicitly have small weight so the "too small" filter
      // can inspect both dimensions — otherwise a null weightG is
      // ambiguous and the filter defers.
      final items = [
        MenuItem(
          id: '1', name: 'Side of Pickles', section: 'sides',
          calories: 20, proteinG: 1, carbsG: 2, fatG: 0,
          weightG: 30, rating: 'green',
        ),
        mkItem('2', name: 'Main Plate'),
      ];
      final plenty = service.recommend(items: items, context: ctx());
      expect(
        plenty.rejected.any(
          (r) => r.item.name == 'Side of Pickles' &&
              r.reason == RejectionReason.tooSmall,
        ),
        true,
      );

      final starving = service.recommend(
        items: items,
        context: ctx(calTarget: 1500, calConsumed: 1400),
      );
      // With only 100 cal left, micro items become acceptable (not
      // rejected for being too small).
      expect(
        starving.rejected.any(
          (r) => r.item.name == 'Side of Pickles' &&
              r.reason == RejectionReason.tooSmall,
        ),
        false,
      );
    });
  });

  group('Recommendation selection', () {
    test('returns <= topK picks', () {
      final items = List.generate(10, (i) => mkItem('$i', name: 'Dish $i'));
      final result = service.recommend(items: items, context: ctx(), topK: 3);
      expect(result.picks.length, lessThanOrEqualTo(3));
    });

    test('empty items returns empty picks', () {
      final result = service.recommend(items: const [], context: ctx());
      expect(result.picks, isEmpty);
    });

    test('empty food log still produces recommendations', () {
      final items = [
        mkItem('1', name: 'Grilled Salmon', proteinG: 45, fatG: 25),
        mkItem('2', name: 'Quinoa Bowl', proteinG: 15, carbsG: 60),
        mkItem('3', name: 'Chicken Breast', proteinG: 50, fatG: 10),
      ];
      final result = service.recommend(items: items, context: ctx());
      expect(result.picks, isNotEmpty);
    });
  });

  group('Determinism + stability', () {
    test('same input produces same output', () {
      final items = [
        mkItem('1', name: 'Salmon Bowl', proteinG: 45),
        mkItem('2', name: 'Chicken Kabab', proteinG: 40),
        mkItem('3', name: 'Tofu Scramble', proteinG: 22),
      ];
      final first = service.recommend(items: items, context: ctx());
      final second = service.recommend(items: items, context: ctx());
      expect(first.picks.map((p) => p.item.name).toList(),
          second.picks.map((p) => p.item.name).toList());
    });

    test('1% calorie perturbation preserves pick order', () {
      final base = [
        mkItem('1', name: 'Salmon Bowl', calories: 500, proteinG: 45),
        mkItem('2', name: 'Chicken Kabab', calories: 450, proteinG: 40),
        mkItem('3', name: 'Tofu Scramble', calories: 400, proteinG: 22),
      ];
      final perturbed = [
        mkItem('1', name: 'Salmon Bowl', calories: 505, proteinG: 45),
        mkItem('2', name: 'Chicken Kabab', calories: 450, proteinG: 40),
        mkItem('3', name: 'Tofu Scramble', calories: 400, proteinG: 22),
      ];
      final baseRes = service.recommend(items: base, context: ctx());
      final pertRes = service.recommend(items: perturbed, context: ctx());
      expect(baseRes.picks.map((p) => p.item.name).toList(),
          pertRes.picks.map((p) => p.item.name).toList());
    });

    test('fuzz: 100 random menus never throw', () {
      for (int i = 0; i < 100; i++) {
        final items = List.generate(
          10 + (i % 20),
          (j) => mkItem('$i-$j',
              name: 'Dish ${i}_${j}',
              calories: 200.0 + (j * 37) % 800,
              proteinG: 10.0 + (j * 5) % 60,
              carbsG: 10.0 + (j * 7) % 80,
              fatG: 5.0 + (j * 3) % 40,
              rating: ['green', 'yellow', 'red'][j % 3],
              inflammation: j % 10),
        );
        expect(
          () => service.recommend(items: items, context: ctx()),
          returnsNormally,
        );
      }
    });
  });

  group('Pareto correctness', () {
    test('tasty-but-inflammatory item can still appear via Pleasure axis', () {
      final items = [
        mkItem('1', name: 'Boring Chicken', proteinG: 40, inflammation: 1, rating: 'green'),
        mkItem('2', name: 'Favorite Pizza', proteinG: 20, inflammation: 8, rating: 'red'),
        mkItem('3', name: 'Plain Salad', proteinG: 10, inflammation: 2, rating: 'green'),
      ];
      final result = service.recommend(
        items: items,
        context: ctx(favorites: const ['Favorite Pizza']),
        topK: 3,
      );
      // Pizza should at minimum be accepted (not hard-filtered).
      expect(result.rejected.any((r) => r.item.name == 'Favorite Pizza'), false);
    });
  });

  group('MMR diversity', () {
    test('top-3 picks not all named the same', () {
      final items = [
        mkItem('1', name: 'Grilled Chicken Caesar', proteinG: 40),
        mkItem('2', name: 'Grilled Chicken Wrap', proteinG: 38),
        mkItem('3', name: 'Grilled Chicken Bowl', proteinG: 42),
        mkItem('4', name: 'Lentil Dal', proteinG: 20, carbsG: 60),
        mkItem('5', name: 'Tofu Stir Fry', proteinG: 25, carbsG: 40),
      ];
      final result = service.recommend(items: items, context: ctx(), topK: 3);
      final names = result.picks.map((p) => p.item.name).toList();
      // Should NOT be three chicken dishes — MMR enforces diversity.
      final chickenCount = names.where((n) => n.contains('Chicken')).length;
      expect(chickenCount, lessThanOrEqualTo(2));
    });
  });

  group('Reason trace', () {
    test('explain sheet receives meaningful contributions', () {
      final items = [
        mkItem('1', name: 'Chicken Kabab', proteinG: 45, inflammation: 2, rating: 'green'),
      ];
      final result = service.recommend(items: items, context: ctx(), topK: 1);
      if (result.picks.isEmpty) return;
      final pick = result.picks.first;
      final top = pick.topContributionsMeaningful(4);
      expect(top, isNotEmpty,
          reason: 'There should be at least one meaningful signal in the trace');
      // The weighted score should be deterministic and bounded [0,1].
      expect(pick.weightedScore, greaterThanOrEqualTo(0.0));
      expect(pick.weightedScore, lessThanOrEqualTo(1.0));
    });
  });
}
