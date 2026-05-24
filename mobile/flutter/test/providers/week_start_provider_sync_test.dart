// Tests for cross-device sync behaviour added in SLICE_F to
// [WeekStartNotifier]. Exercises the four paths called out in the brief:
//   1. Authenticated load → reads backend (backend-wins).
//   2. Anonymous load → SharedPreferences only.
//   3. Toggle writes both local + backend in parallel.
//   4. refreshFromBackend conflict resolution (backend-wins).
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/week_start_provider.dart';
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/data/services/api_client.dart';

class _MockApiClient extends Mock implements ApiClient {}

/// Mocktail fake — subclasses [AuthNotifier] so the StateNotifierProvider
/// type system accepts it, while skipping the real ctor's init() side
/// effects. We never invoke any AuthNotifier methods in these tests; the
/// provider only reads `.state`.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState initial) : super(_FakeAuthRepository(), _NoopRef()) {
    // ignore: invalid_use_of_protected_member
    state = initial;
  }
}

class _FakeAuthRepository extends Mock implements AuthRepository {}

class _NoopRef extends Mock implements Ref {}

AuthState _authedState() => const AuthState(
      status: AuthStatus.authenticated,
      user: app_user.User(
        id: 'user-uuid-1',
        email: 'tester@example.com',
        name: 'Tester',
      ),
    );

const _anonState = AuthState(status: AuthStatus.unauthenticated);

Response<T> _resp<T>(T data) => Response<T>(
      data: data,
      requestOptions: RequestOptions(path: '/users/me/preferences'),
      statusCode: 200,
    );

ProviderContainer _makeContainer({
  required AuthState authState,
  required ApiClient apiClient,
}) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
      apiClientProvider.overrideWithValue(apiClient),
    ],
  );
}

/// Wait for the notifier's init() to resolve (it is fire-and-forget from
/// the constructor). We loop on the test-only [backendResolved] flag so we
/// don't race init.
Future<void> _waitForInit(WeekStartNotifier n) async {
  for (var i = 0; i < 50; i++) {
    if (n.backendResolved) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(Options());
  });

  group('WeekStartNotifier — cross-device sync', () {
    test('authenticated load reads backend (backend-wins over local)',
        () async {
      // Local has FALSE cached; backend reports TRUE → backend wins.
      SharedPreferences.setMockInitialValues({'week_starts_sunday': false});

      final api = _MockApiClient();
      when(() => api.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => _resp<Map<String, dynamic>>(
          <String, dynamic>{'week_starts_sunday': true, 'distance_unit': 'mi'},
        ),
      );

      final container =
          _makeContainer(authState: _authedState(), apiClient: api);
      addTearDown(container.dispose);

      final notifier = container.read(weekStartsSundayProvider.notifier);
      await _waitForInit(notifier);

      expect(container.read(weekStartsSundayProvider), isTrue,
          reason: 'backend value should overwrite stale local cache');

      // And the local cache should now reflect the backend value too.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('week_starts_sunday'), isTrue);

      verify(() => api.get<Map<String, dynamic>>('/users/me/preferences'))
          .called(1);
    });

    test('anonymous load reads SharedPreferences only — no HTTP', () async {
      SharedPreferences.setMockInitialValues({'week_starts_sunday': true});

      final api = _MockApiClient();
      // If anything calls .get / .patch we want to fail loudly.
      when(() => api.get<Map<String, dynamic>>(any()))
          .thenThrow(StateError('anon must not hit backend'));
      when(() => api.patch<Map<String, dynamic>>(any(),
              data: any(named: 'data')))
          .thenThrow(StateError('anon must not hit backend'));

      final container =
          _makeContainer(authState: _anonState, apiClient: api);
      addTearDown(container.dispose);

      final notifier = container.read(weekStartsSundayProvider.notifier);
      await _waitForInit(notifier);

      expect(container.read(weekStartsSundayProvider), isTrue);
      verifyNever(() => api.get<Map<String, dynamic>>(any()));
      verifyNever(() => api.patch<Map<String, dynamic>>(any(),
          data: any(named: 'data')));
    });

    test('setStartsSunday writes both SharedPreferences and backend',
        () async {
      SharedPreferences.setMockInitialValues({});

      final api = _MockApiClient();
      // Init fetch returns null → no clobber.
      when(() => api.get<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => _resp<Map<String, dynamic>>(
          <String, dynamic>{'week_starts_sunday': null, 'distance_unit': null},
        ),
      );
      when(() => api.patch<Map<String, dynamic>>(any(),
          data: any(named: 'data'))).thenAnswer(
        (_) async => _resp<Map<String, dynamic>>(
          <String, dynamic>{'week_starts_sunday': true, 'distance_unit': null},
        ),
      );

      final container =
          _makeContainer(authState: _authedState(), apiClient: api);
      addTearDown(container.dispose);

      final notifier = container.read(weekStartsSundayProvider.notifier);
      await _waitForInit(notifier);

      await notifier.setStartsSunday(true);

      expect(container.read(weekStartsSundayProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('week_starts_sunday'), isTrue,
          reason: 'local cache must be updated');

      // Verify the PATCH carried the right payload.
      final captured = verify(() => api.patch<Map<String, dynamic>>(
            '/users/me/preferences',
            data: captureAny(named: 'data'),
          )).captured;
      expect(captured.isNotEmpty, isTrue);
      expect(captured.last, {'week_starts_sunday': true});
    });

    test('refreshFromBackend resolves conflict in backend-wins direction',
        () async {
      SharedPreferences.setMockInitialValues({});

      final api = _MockApiClient();
      // First call (during init) returns FALSE. Second call (the refresh)
      // returns TRUE → notifier should flip + update local cache.
      var callCount = 0;
      when(() => api.get<Map<String, dynamic>>(any())).thenAnswer((_) async {
        callCount += 1;
        return _resp<Map<String, dynamic>>(<String, dynamic>{
          'week_starts_sunday': callCount == 1 ? false : true,
          'distance_unit': null,
        });
      });
      when(() => api.patch<Map<String, dynamic>>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => _resp<Map<String, dynamic>>(
                <String, dynamic>{},
              ));

      final container =
          _makeContainer(authState: _authedState(), apiClient: api);
      addTearDown(container.dispose);

      final notifier = container.read(weekStartsSundayProvider.notifier);
      await _waitForInit(notifier);
      expect(container.read(weekStartsSundayProvider), isFalse);

      await notifier.refreshFromBackend();

      expect(container.read(weekStartsSundayProvider), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('week_starts_sunday'), isTrue);
    });
  });
}
