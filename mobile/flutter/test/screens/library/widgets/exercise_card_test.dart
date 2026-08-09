import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/constants/app_colors.dart';
import 'package:fitwiz/screens/library/widgets/exercise_card.dart';
import 'package:fitwiz/data/models/exercise.dart';
import 'package:fitwiz/widgets/signature/signature.dart';

// The signature-v2 redesign turned ExerciseCard from a badge-stack card into a
// dense [ZHairlineRow]: the muscle group / difficulty / equipment now render as
// ONE uppercase metadata line (`●LEVEL · MUSCLE · EQUIPMENT`) instead of
// separate title-case badges, and the trailing chevron was replaced by three
// inline actions (favourite / add-to-workout / alternatives). These tests
// assert that shape.
void main() {
  group('ExerciseCard', () {
    LibraryExercise createExercise({
      String name = 'Bench Press',
      String? bodyPart,
      String? difficultyLevel,
      String? equipment,
      String? videoUrl,
    }) {
      return LibraryExercise(
        id: 'test-id',
        nameValue: name,
        bodyPart: bodyPart,
        difficultyLevelValue: difficultyLevel,
        equipmentValue: equipment,
        videoUrl: videoUrl,
      );
    }

    testWidgets('renders exercise name', (WidgetTester tester) async {
      final exercise = createExercise(name: 'Squat');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Squat'), findsOneWidget);
    });

    testWidgets('renders muscle group in the metadata line when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Bench Press',
        bodyPart: 'Chest',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('CHEST'), findsOneWidget);
    });

    testWidgets('renders difficulty level when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Deadlift',
        difficultyLevel: 'Intermediate',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('INTERMEDIATE'), findsOneWidget);
    });

    testWidgets('renders the primary equipment when provided',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Incline Press',
        equipment: 'Barbell, Bench',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // The dense row shows only the primary (first) piece of equipment so the
      // metadata line stays on one line at 9.5px.
      expect(find.text('BARBELL'), findsOneWidget);
      expect(find.textContaining('Bench'), findsNothing);
    });

    testWidgets('shows video indicator when video is available',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Pull-up',
        videoUrl: 'https://example.com/video.mp4',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('hides video indicator when no video',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Push-up',
        videoUrl: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('shows the inline row actions instead of a chevron',
        (WidgetTester tester) async {
      final exercise = createExercise();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // The trailing chevron was replaced by three inline actions: favourite,
      // add-to-workout and alternatives.
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    });

    testWidgets('the row is tappable', (WidgetTester tester) async {
      final exercise = createExercise();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // Actually firing the tap would push the exercise-browse route, which
      // resolves the library repository (and therefore Supabase) — out of
      // reach in a widget test. Assert the tap affordance is wired instead.
      final row = tester.widget<ZHairlineRow>(find.byType(ZHairlineRow));
      expect(row.onTap, isNotNull);
    });

    testWidgets('renders correctly in dark mode',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Lat Pulldown',
        bodyPart: 'Back',
        difficultyLevel: 'Beginner',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Lat Pulldown'), findsOneWidget);
      // Level + muscle share one metadata line: `BEGINNER · BACK`.
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.textContaining('BACK'), findsOneWidget);
    });

    testWidgets('renders correctly in light mode',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Bicep Curl',
        bodyPart: 'Arms',
        difficultyLevel: 'Beginner',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      expect(find.text('Bicep Curl'), findsOneWidget);
      expect(find.text('BEGINNER'), findsOneWidget);
      expect(find.textContaining('ARMS'), findsOneWidget);
    });

    testWidgets('truncates long equipment list',
        (WidgetTester tester) async {
      final exercise = createExercise(
        name: 'Cable Crossover',
        equipment: 'Cable Machine, D-Handle, Extra Handle',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseCard(exercise: exercise),
            ),
          ),
        ),
      );

      // Only the first equipment item survives into the dense metadata line.
      expect(find.text('CABLE MACHINE'), findsOneWidget);
      expect(find.textContaining('D-Handle'), findsNothing);
      expect(find.textContaining('Extra Handle'), findsNothing);
    });

    testWidgets(
      'metadata line puts equipment BEFORE muscle group (E2E row 120) so a '
      'long muscle name eats itself in the maxLines:1 ellipsis, not the '
      'short, load-bearing equipment token',
      (WidgetTester tester) async {
        final exercise = createExercise(
          name: 'Barbell Squat',
          bodyPart: 'Quadriceps',
          equipment: 'Barbell',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ExerciseCard(exercise: exercise),
              ),
            ),
          ),
        );

        // Level is absent, so the whole tail is ONE Text widget — its exact
        // content pins the order directly. The old order rendered
        // "QUADRICEPS · BARBELL", putting equipment last (and therefore
        // first in line to be ellipsized on a long muscle name).
        expect(find.text('BARBELL · QUADRICEPS'), findsOneWidget);
        expect(find.text('QUADRICEPS · BARBELL'), findsNothing);
      },
    );

    testWidgets(
      'the exercise-name Text allows 2 lines (E2E row 101) so a '
      'distinguishing trailing qualifier is not always clipped',
      (WidgetTester tester) async {
        final exercise = createExercise(
          name: '45 Degree Hyperextension (No Equipment)',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ExerciseCard(exercise: exercise),
              ),
            ),
          ),
        );

        final nameText = tester.widget<Text>(
          find.text('45 Degree Hyperextension (No Equipment)'),
        );
        expect(nameText.maxLines, 2);
      },
    );

    // Regression gate for the light-mode "black block" bug: the leading
    // thumbnail's fill/border were painted with `AppColors.surface2` /
    // `AppColors.cardBorder` (dark-theme literals) regardless of the active
    // theme, so in light mode the 40×40 icon tile rendered as a near-black
    // square on an otherwise white row. The thumbnail now resolves its fill
    // and border through `ThemeColors.of(context)`. This test pumps the card
    // under `ThemeData.light()` and asserts the RESOLVED decoration colors —
    // not just that the widget renders — so a regression back to a raw
    // `AppColors.*` literal fails the assertion instead of silently
    // reintroducing the bug.
    testWidgets(
      'leading thumbnail resolves a light-theme fill and border in light '
      'mode, not the dark-theme literal',
      (WidgetTester tester) async {
        final exercise = createExercise(
          name: 'Face Pull',
          bodyPart: 'Back', // -> Icons.airline_seat_flat fallback icon
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: ExerciseCard(exercise: exercise),
              ),
            ),
          ),
        );
        await tester.pump();

        final iconFinder = find.byIcon(Icons.airline_seat_flat);
        expect(iconFinder, findsOneWidget);

        final thumbContainer = tester.widget<Container>(
          find
              .ancestor(of: iconFinder, matching: find.byType(Container))
              .first,
        );
        final deco = thumbContainer.decoration as BoxDecoration;
        final fill = deco.color;
        final border = deco.border as Border?;
        final borderColor = border?.top.color;

        expect(fill, isNotNull);
        expect(borderColor, isNotNull);

        // Must NOT be the dark-theme literals this bug regresses to.
        expect(fill, isNot(equals(AppColors.surface2)),
            reason: 'Thumbnail fill must not be the dark-theme literal '
                '(AppColors.surface2) while the active theme is light.');
        expect(borderColor, isNot(equals(AppColors.cardBorder)),
            reason: 'Thumbnail border must not be the dark-theme literal '
                '(AppColors.cardBorder) while the active theme is light.');

        // Must resolve to the actual light-theme tokens.
        expect(fill, equals(AppColorsLight.surface));
        expect(borderColor, equals(AppColorsLight.cardBorder));

        // Contrast is real, not just "a different token": the fallback
        // icon color must read against the resolved fill.
        final iconWidget = tester.widget<Icon>(iconFinder);
        final iconColor = iconWidget.color!;
        final fillLuminance = fill!.computeLuminance();
        final iconLuminance = iconColor.computeLuminance();
        expect((fillLuminance - iconLuminance).abs(), greaterThan(0.15),
            reason: 'Fill and icon luminance must contrast; a near-equal '
                'pair is unreadable even if both are "correct" colors '
                'individually.');
      },
    );
  });
}
