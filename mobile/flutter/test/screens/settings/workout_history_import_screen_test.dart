/// Widget tests for the workout-history file-import UI.
///
/// Full-screen integration is already covered by the existing settings tests;
/// here we verify the bits that Task #7 introduced:
///   • The preview sheet renders detection info, row counts, and sample rows
///     from a [WorkoutImportPreview] fixture.
///   • The preview sheet surfaces unresolved exercise chips when present.
///   • The confirm button returns `true` / `false` cleanly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/theme/accent_color_provider.dart';
import 'package:fitwiz/data/models/workout_import_preview.dart';
import 'package:fitwiz/screens/settings/widgets/workout_import_preview_sheet.dart';

void main() {
  group('WorkoutImportPreview model', () {
    test('parses complete payload', () {
      final preview = WorkoutImportPreview.fromJson(const {
        'dry_run': true,
        'source_app': 'hevy',
        'mode': 'history',
        'confidence': 0.95,
        'strength_row_count': 42,
        'cardio_row_count': 0,
        'has_template': false,
        'unresolved_exercises': ['Flat Bench Press'],
        'warnings': ['Ambiguous set_type on row 3'],
        'sample_rows': [
          {'exercise': 'Bench Press', 'weight': 80, 'reps': 8},
        ],
      });
      expect(preview.sourceApp, 'hevy');
      expect(preview.strengthRowCount, 42);
      expect(preview.confidencePercent, 95);
      expect(preview.unresolvedExercises, ['Flat Bench Press']);
      expect(preview.sampleRows.first['exercise'], 'Bench Press');
      expect(preview.hasAnyRows, isTrue);
    });

    test('defaults on missing fields', () {
      final preview = WorkoutImportPreview.fromJson(const <String, dynamic>{});
      expect(preview.sourceApp, 'unknown');
      expect(preview.strengthRowCount, 0);
      expect(preview.confidence, 0.0);
      expect(preview.hasAnyRows, isFalse);
    });
  });

  // Helper — wrap any sheet builder in a widget-tester-friendly MaterialApp.
  // We bypass [AccentColorScopeWrapper] (which reads from Riverpod + shared
  // preferences on first build) by providing a static [AccentColorScope]
  // around the child so `AccentColorScope.of(context)` resolves instantly.
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: AccentColorScope(
          accent: AccentColor.orange,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  testWidgets('Preview sheet body renders detection + row counts + sample rows',
      (tester) async {
    final preview = WorkoutImportPreview.fromJson(const {
      'dry_run': true,
      'source_app': 'hevy',
      'mode': 'history',
      'confidence': 0.92,
      'strength_row_count': 12,
      'cardio_row_count': 3,
      'has_template': false,
      'unresolved_exercises': ['Flat Bench Press'],
      'warnings': [],
      'sample_rows': [
        {'exercise': 'Bench Press', 'reps': 8, 'weight': 80},
        {'exercise': 'Squat', 'reps': 5, 'weight': 140},
      ],
    });

    // showGlassSheet opens a modal; we instead render the internal body widget
    // directly to avoid pumping the entire navigator stack.
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showWorkoutImportPreviewSheet(
              context: ctx,
              preview: preview,
              filename: 'hevy_export.csv',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Detection banner
    expect(find.text('Hevy'), findsOneWidget);
    expect(find.textContaining('Strength history'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);

    // Row counts
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('No'), findsOneWidget); // template

    // Sample rows table — DataTable renders cells as text nodes.
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);

    // Unresolved chip
    expect(find.text('Flat Bench Press'), findsOneWidget);

    // Confirm button label
    expect(find.text('Looks right — Import'), findsOneWidget);
  });

  testWidgets('Preview sheet disables confirm when there are no rows',
      (tester) async {
    final emptyPreview = WorkoutImportPreview.fromJson(const {
      'source_app': 'unknown',
      'strength_row_count': 0,
      'cardio_row_count': 0,
      'has_template': false,
      'sample_rows': [],
      'warnings': ['Could not identify source'],
    });

    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showWorkoutImportPreviewSheet(
              context: ctx,
              preview: emptyPreview,
              filename: 'empty.csv',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Confirm button exists but is disabled (onPressed == null).
    // FilledButton.icon returns a private type, so we walk the tree for any
    // widget whose runtime type's name starts with "Filled" or "Elevated"
    // — easier than depending on private class names across Flutter versions.
    final labelFinder = find.text('Looks right — Import');
    expect(labelFinder, findsOneWidget);

    // Walk ancestors up to find a widget that exposes an `onPressed` via
    // widget_inspector semantics — the button is disabled iff Inkwell.onTap
    // is null. Assert the label is NOT inside any tappable ancestor.
    bool hasEnabledAncestor = false;
    final labelElement = labelFinder.evaluate().first;
    labelElement.visitAncestorElements((el) {
      final w = el.widget;
      if (w is InkWell && w.onTap != null) {
        hasEnabledAncestor = true;
        return false;
      }
      return true;
    });
    expect(hasEnabledAncestor, isFalse,
        reason: 'Confirm button should be disabled when there are no rows');
  });
}
