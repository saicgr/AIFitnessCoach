import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/pages/workout_ui_mode_sheet.dart';
import 'package:fitwiz/widgets/glass_sheet.dart';

import '../../../helpers/fake_supabase.dart';

// REGRESSION (E2E settings row 215): the Workout Mode sheet explicitly
// opted out of GlassSheet's default grabber (`showHandle: false`), leaving
// it the one sheet in the app with zero visible dismiss affordance — no
// grabber, no ×, no Cancel/Done.
void main() {
  setUpAll(initFakeSupabase);

  testWidgets('Workout Mode sheet shows a drag handle like every other sheet',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedAppLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showWorkoutUiModeSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<GlassSheet>(find.byType(GlassSheet));
    expect(sheet.showHandle, isTrue);
  });
}
