import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fitwiz/core/providers/locale_provider.dart'
    show supportedAppLocales;
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/settings/sections/contribute_food_data_section.dart';

class _MockApiClient extends Mock implements ApiClient {}

// REGRESSION (E2E settings row 2 — CRIT): GET /users/me 403s for every user
// (backend IDOR guard treats the literal path segment "me" as a target user
// id — see backend/api/v1/users/profile.py route ordering, out of this
// lane's scope). Before this fix, the section defaulted `_enabled = true`
// and rendered the switch ON regardless of the fetch outcome — a fabricated
// value contradicting the "Could not load setting" error shown right next
// to it. It must never render a switch (ON or OFF) for a setting it never
// actually confirmed with the server.
void main() {
  Future<void> pumpSection(WidgetTester tester, ApiClient client) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedAppLocales,
          home: const Scaffold(body: ContributeFoodDataSection()),
        ),
      ),
    );
    await tester.pump(); // build
    await tester.pump(); // let the fetch's Future resolve
  }

  testWidgets(
      'shows no switch (not a fabricated ON) when the fetch 403s, plus the error',
      (tester) async {
    final client = _MockApiClient();
    when(() => client.get<dynamic>('/users/me')).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/users/me')),
    );

    await pumpSection(tester, client);

    expect(find.byType(Switch), findsNothing);
    expect(find.text('Could not load setting'), findsOneWidget);
  });

  testWidgets('shows the real switch value once the fetch succeeds',
      (tester) async {
    final client = _MockApiClient();
    when(() => client.get<dynamic>('/users/me')).thenAnswer(
      (_) async => Response(
        data: {'contribute_food_data': false},
        requestOptions: RequestOptions(path: '/users/me'),
        statusCode: 200,
      ),
    );

    await pumpSection(tester, client);

    expect(find.byType(Switch), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.value, isFalse);
  });
}
