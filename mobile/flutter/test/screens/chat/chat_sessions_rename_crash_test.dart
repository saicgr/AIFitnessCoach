// Regression gate for the rename-chat crash: Coach tab -> Chats -> row menu
// -> "Rename chat" -> Save replaced the whole screen with the branded error
// boundary, throwing:
//
//   'package:flutter/src/widgets/framework.dart': Failed assertion: line
//   6268 pos 12: '_dependents.isEmpty': is not true.
//
// That assertion is InheritedElement.debugDeactivated() firing because some
// descendant Element still depended on an InheritedElement that was being
// torn down. Reproduced here end-to-end through the real ChatSessionsScreen:
// open a row's overflow menu (a modal-bottom-sheet route), tap Rename (which
// pops the sheet AND, in the same tap handler, synchronously pushes a
// showDialog route while the sheet's own exit transition is still playing),
// type a new title, and tap Save.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/constants/api_constants.dart';
import 'package:fitwiz/core/providers/locale_provider.dart' show supportedAppLocales;
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/data/repositories/chat_repository.dart';
import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/data/services/data_cache_service.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/chat/chat_sessions_screen.dart';

import '../../helpers/test_helpers.dart';

/// Mirrors the `_FakeAuthNotifier` pattern used by
/// `test/providers/week_start_provider_sync_test.dart` — a real
/// [AuthNotifier] subclass so the StateNotifierProvider type checks pass,
/// with the real ctor's Supabase listener side effects skipped and `state`
/// stamped directly.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState initial)
      : super(_FakeAuthRepository(), _NoopRef()) {
    // ignore: invalid_use_of_protected_member
    state = initial;
  }
}

class _FakeAuthRepository extends Mock implements AuthRepository {}

class _NoopRef extends Mock implements Ref {}

Response<T> _json<T>(String path, int status, T body) => Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: body,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient api;

  setUp(() async {
    setUpMocks();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // The notifier keeps a STATIC in-memory cache across provider instances
    // (project_tab_instant_perf) — wipe it so each test starts cold instead
    // of instant-painting a previous test's session list.
    ChatSessionsNotifier.resetInMemoryCache('test-user-id');
    await DataCacheService.instance.invalidate(DataCacheService.chatSessionsKey);

    api = MockApiClient();
    when(() => api.getUserId()).thenAnswer((_) async => 'test-user-id');
    when(() => api.get(
          ApiConstants.coachSessions,
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _json(ApiConstants.coachSessions, 200, {
          'items': [
            {
              'id': 'session-1',
              'title': 'Leg day questions',
              'preview': 'How many sets should I do?',
              'is_archived': false,
              'message_count': 4,
              'created_at': '2026-08-01T10:00:00Z',
              'updated_at': '2026-08-01T10:05:00Z',
              'last_message_at': '2026-08-01T10:05:00Z',
            },
          ],
        }));
    when(() => api.patch(
          ApiConstants.coachSessionItem('session-1'),
          data: any(named: 'data'),
        )).thenAnswer((invocation) async {
      final data = invocation.namedArguments[#data] as Map<String, dynamic>;
      return _json(ApiConstants.coachSessionItem('session-1'), 200, {
        'id': 'session-1',
        'title': data['title'],
        'preview': 'How many sets should I do?',
        'is_archived': false,
        'message_count': 4,
        'created_at': '2026-08-01T10:00:00Z',
        'updated_at': '2026-08-05T09:00:00Z',
        'last_message_at': '2026-08-01T10:05:00Z',
      });
    });
  });

  Widget harness() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier(AuthState(
              status: AuthStatus.authenticated,
              user: const app_user.User(
                id: 'test-user-id',
                email: 'tester@example.com',
                name: 'Tester',
              ),
            ))),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedAppLocales,
        home: const ChatSessionsScreen(),
      ),
    );
  }

  testWidgets(
      'renaming a chat via the row menu does not crash with a stale '
      'InheritedElement dependent', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Leg day questions'), findsOneWidget);

    // The GlassSheet menu's ListTiles throw a benign, PRE-EXISTING
    // "background color may be invisible" layout assertion every time the
    // menu renders (unrelated to this bug — the ListTile paints on the
    // nearest Material ancestor, which sits above a DecoratedBox). Intercept
    // FlutterError.onError for the WHOLE interaction (menu-open included) and
    // drop only that one; record everything else, in particular the
    // InheritedElement assertion this test guards against. Installed before
    // the menu opens: tester.takeException() collapses multiple queued
    // errors into one opaque "Multiple exceptions (N)..." summary once more
    // than one is pending, which is too lossy to filter by message after the
    // fact — so nothing here is allowed to reach that queue unfiltered.
    final unexpected = <Object>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception
          .toString()
          .contains('background color or ink splashes')) {
        return;
      }
      unexpected.add(details.exception);
    };

    try {
      // Open the row's overflow menu (a modal-bottom-sheet route on the root
      // navigator).
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsOneWidget);

      // Tapping "Rename" pops the bottom-sheet route AND, in the same
      // synchronous tap handler, pushes a showDialog route — the sheet's
      // exit transition and the dialog's entrance transition run
      // concurrently.
      await tester.tap(find.text('Rename'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(dialogField, findsOneWidget);
      await tester.enterText(dialogField, 'New leg day plan');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      // Pop the dialog, dispose its controller, await the rename() mutation,
      // and let the screen rebuild while the dialog's exit transition plays.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    } catch (e) {
      unexpected.add(e);
    } finally {
      FlutterError.onError = originalOnError;
    }
    // Anything the handler above didn't intercept (e.g. a raw exception
    // thrown synchronously back into the test zone) still needs draining so
    // it doesn't fail the test via the binding's own leftover-exception check.
    Object? leftover;
    while ((leftover = tester.takeException()) != null) {
      if (!leftover.toString().contains('background color or ink splashes')) {
        unexpected.add(leftover!);
      }
    }

    expect(unexpected, isEmpty,
        reason: 'Rename crashed the screen: $unexpected');
    // The screen must still be showing the chat list, not the branded error
    // boundary that replaces it on an uncaught framework exception.
    expect(find.text('New leg day plan'), findsOneWidget);
  });
}
