/// Regression coverage for E2E row #454.
///
/// The register claimed the zero-friends empty state in GroupCreateSheet
/// got a Find Friends CTA. It never did — the empty state was (and, before
/// this fix, still is) a plain centered "No friends to add" Text with no
/// way out of the dead end. This test asserts the CTA exists and routes to
/// FriendSearchScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/data/providers/social_provider.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/social/friend_search_screen.dart';
import 'package:fitwiz/screens/social/group_create_sheet.dart';

class _StubAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _StubAuthNotifier(app_user.User user)
      : super(AuthState(status: AuthStatus.authenticated, user: user));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('#454: zero-friends empty state offers a Find Friends CTA that opens friend search', (tester) async {
    const user = app_user.User(id: 'u1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _StubAuthNotifier(user)),
          friendsListProvider('u1').overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: const Scaffold(body: GroupCreateSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No friends to add'), findsOneWidget);

    final ctaFinder = find.widgetWithText(OutlinedButton, 'Find Friends');
    expect(ctaFinder, findsOneWidget);

    await tester.tap(ctaFinder);
    await tester.pumpAndSettle();

    expect(find.byType(FriendSearchScreen), findsOneWidget);
  });
}
