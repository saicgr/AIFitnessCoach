import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/data/providers/exercise_progression_provider.dart'
    show repPreferencesProvider;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/sections/preferences_section.dart';

import '../../../helpers/fake_supabase.dart';

/// Pump the real section with:
///  * the app localization delegates — every row title/subtitle comes from
///    `AppLocalizations`, so without them the build throws before any finder
///    can run; and
///  * `repPreferencesProvider` stubbed to null, so the section's own training
///    focus row does not have to walk `exerciseProgressionProvider` → the
///    network. Null is a genuine production state (preferences not loaded yet)
///    and the widget already defaults to `TrainingFocus.hypertrophy`.
///
/// The rest of the card's rows fan out across a wide provider surface that all
/// bottoms out in `Supabase.instance`; [initFakeSupabase] gives them a real,
/// signed-out, offline singleton instead of stubbing each one.
Future<void> _pumpSection(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repPreferencesProvider.overrideWith((ref) => null),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: PreferencesSection()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(initFakeSupabase);

  group('PreferencesSection', () {
    testWidgets('displays section header', (tester) async {
      await _pumpSection(tester);

      expect(find.text('PREFERENCES'), findsOneWidget);
    });

    testWidgets('displays the theme mode row', (tester) async {
      await _pumpSection(tester);

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System, Light, or Dark'), findsOneWidget);
    });

    testWidgets('displays the accent colour row', (tester) async {
      await _pumpSection(tester);

      expect(find.text('Accent Color'), findsOneWidget);
    });

    testWidgets('displays the theme palette icon', (tester) async {
      await _pumpSection(tester);

      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('displays the accent colour icon', (tester) async {
      await _pumpSection(tester);

      expect(find.byIcon(Icons.color_lens_outlined), findsOneWidget);
    });

    testWidgets('exposes the gym profiles, timezone and weight unit rows',
        (tester) async {
      await _pumpSection(tester);

      expect(find.text('Gym Profiles'), findsOneWidget);
      expect(find.text('Timezone'), findsOneWidget);
      expect(find.text('Weight Unit'), findsOneWidget);
    });

    testWidgets('is a Column widget', (tester) async {
      await _pumpSection(tester);

      expect(find.byType(Column), findsWidgets);
    });
  });
}
