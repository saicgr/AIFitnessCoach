import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/pages/vacation_mode_page.dart';

import '../../../helpers/fake_supabase.dart';

// REGRESSION (E2E settings row 81): ZealovaButton has no built-in disabled
// visual treatment — passing `onTap: null` still renders full-brightness
// accent fill, so the "no changes to save" state of this screen's save
// button used to look identical to its live, tappable state.
void main() {
  setUpAll(initFakeSupabase);

  testWidgets(
      'save button is dimmed when there are no unsaved vacation-mode changes',
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
          home: const VacationModePage(),
        ),
      ),
    );
    await tester.pump();

    // No interaction happened, so canSave is false — the button must be
    // visibly dimmed, not rendered at full brightness like a live CTA.
    final opacity = tester.widget<Opacity>(
      find.byKey(const Key('vacation_save_button_opacity')),
    );
    expect(opacity.opacity, lessThan(1.0));
  });
}
