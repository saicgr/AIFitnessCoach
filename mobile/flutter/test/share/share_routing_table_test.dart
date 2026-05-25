import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/screens/share/share_routing_table.dart';

void main() {
  group('destinationForContentType', () {
    test('food_plate routes to logFood', () {
      expect(destinationForContentType('food_plate'), ShareDestination.logFood);
    });
    test('food_buffet routes to logFood', () {
      expect(destinationForContentType('food_buffet'), ShareDestination.logFood);
    });
    test('food_menu routes to scanMenu', () {
      expect(destinationForContentType('food_menu'), ShareDestination.scanMenu);
    });
    test('exercise_form routes to formCheck', () {
      expect(destinationForContentType('exercise_form'), ShareDestination.formCheck);
    });
    test('progress_photo routes to progressUpload', () {
      expect(destinationForContentType('progress_photo'), ShareDestination.progressUpload);
    });
    test('gym_equipment routes to importEquipment', () {
      expect(destinationForContentType('gym_equipment'), ShareDestination.importEquipment);
    });
    test('recipe_handwritten routes to importRecipePhoto', () {
      expect(destinationForContentType('recipe_handwritten'), ShareDestination.importRecipePhoto);
    });
    test('unknown / document fall through to chooser', () {
      expect(destinationForContentType('unknown'), ShareDestination.chooser);
      expect(destinationForContentType('document'), ShareDestination.chooser);
    });
    test('totally invalid content_type falls through to chooser', () {
      expect(destinationForContentType('not-a-real-type'), ShareDestination.chooser);
    });
  });

  group('destinationForIntent', () {
    test('workout_extract → review screen', () {
      expect(destinationForIntent('workout_extract'),
          ShareDestination.importWorkoutReview);
    });
    test('recipe_extract → paste tab', () {
      expect(destinationForIntent('recipe_extract'),
          ShareDestination.importRecipePaste);
    });
    test('meal_plan_extract → meal plan import', () {
      expect(destinationForIntent('meal_plan_extract'),
          ShareDestination.importMealPlan);
    });
    test('form_check / progress_log / tip_save / discuss', () {
      expect(destinationForIntent('form_check'), ShareDestination.formCheck);
      expect(destinationForIntent('progress_log'), ShareDestination.progressUpload);
      expect(destinationForIntent('tip_save'), ShareDestination.savedTip);
      expect(destinationForIntent('discuss'), ShareDestination.chat);
      expect(destinationForIntent('nutrition_question'), ShareDestination.chat);
    });
    test('unknown intent falls through to chat', () {
      expect(destinationForIntent('garbage'), ShareDestination.chat);
    });
  });

  group('categoryForIntent', () {
    test('every intent has a category', () {
      for (final i in [
        'workout_extract',
        'recipe_extract',
        'meal_plan_extract',
        'food_log_extract',
        'form_check',
        'progress_log',
        'tip_save',
        'nutrition_question',
        'discuss',
      ]) {
        // Should not throw; should return a non-null category.
        expect(categoryForIntent(i), isNotNull);
      }
    });
    test('null intent → other', () {
      expect(categoryForIntent(null), ImportCategory.other);
    });
  });

  group('categoryForContentType', () {
    test('food_menu → menu', () {
      expect(categoryForContentType('food_menu'), ImportCategory.menu);
    });
    test('exercise_form → formCheck', () {
      expect(categoryForContentType('exercise_form'), ImportCategory.formCheck);
    });
  });

  group('label helpers', () {
    test('originLabel maps the well-known origins', () {
      expect(originLabel('youtube'), 'YouTube');
      expect(originLabel('instagram'), 'Instagram');
      expect(originLabel('chatgpt'), 'ChatGPT');
      expect(originLabel('voicememos'), 'Voice Memos');
    });
    test('originLabel echoes unknown origins back', () {
      expect(originLabel('zzz_unknown'), 'zzz_unknown');
    });
    test('originLabel null → Shared', () {
      expect(originLabel(null), 'Shared');
    });
    test('categoryLabel + formatLabel return non-empty for every enum', () {
      for (final c in ImportCategory.values) {
        expect(categoryLabel(c).isNotEmpty, isTrue);
      }
      for (final f in ImportFormat.values) {
        expect(formatLabel(f).isNotEmpty, isTrue);
      }
    });
  });

  group('formatFromString / categoryFromString round-trips', () {
    test('image / video / audio / pdf / url / text / carousel', () {
      expect(formatFromString('image'), ImportFormat.image);
      expect(formatFromString('photo'), ImportFormat.image);
      expect(formatFromString('video'), ImportFormat.video);
      expect(formatFromString('audio'), ImportFormat.audio);
      expect(formatFromString('pdf'), ImportFormat.pdf);
      expect(formatFromString('url'), ImportFormat.url);
      expect(formatFromString('text'), ImportFormat.text);
      expect(formatFromString('carousel'), ImportFormat.carousel);
      expect(formatFromString('garbage'), isNull);
    });
    test('workout / recipe / meal_plan / food_log / menu / ...', () {
      expect(categoryFromString('workout'), ImportCategory.workout);
      expect(categoryFromString('recipe'), ImportCategory.recipe);
      expect(categoryFromString('meal_plan'), ImportCategory.mealPlan);
      expect(categoryFromString('garbage'), isNull);
    });
  });

  group('ShareDecision', () {
    test('isConfident is true only when confidence == high', () {
      expect(
        ShareDecision(destination: ShareDestination.logFood, confidence: 'high').isConfident,
        isTrue,
      );
      expect(
        ShareDecision(destination: ShareDestination.logFood, confidence: 'medium').isConfident,
        isFalse,
      );
      expect(
        ShareDecision(destination: ShareDestination.logFood, confidence: 'low').isConfident,
        isFalse,
      );
    });
  });
}
