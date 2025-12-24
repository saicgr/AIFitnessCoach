import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/data/repositories/auth_repository.dart';
import 'package:ai_fitness_coach/data/models/user.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthStatus', () {
    test('should have all expected values', () {
      expect(AuthStatus.values.length, 5);
      expect(AuthStatus.values, contains(AuthStatus.initial));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.error));
    });
  });

  group('AuthState', () {
    test('should have default values', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create with custom values', () {
      final user = TestFixtures.createUser();
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.user, user);
      expect(state.errorMessage, isNull);
    });

    test('should create with error', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Authentication failed',
      );

      expect(state.status, AuthStatus.error);
      expect(state.user, isNull);
      expect(state.errorMessage, 'Authentication failed');
    });

    group('copyWith', () {
      test('should copy with new status', () {
        const original = AuthState(status: AuthStatus.initial);
        final copied = original.copyWith(status: AuthStatus.loading);

        expect(copied.status, AuthStatus.loading);
        expect(copied.user, isNull);
        expect(copied.errorMessage, isNull);
      });

      test('should copy with new user', () {
        const original = AuthState(status: AuthStatus.loading);
        final user = TestFixtures.createUser();
        final copied = original.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );

        expect(copied.status, AuthStatus.authenticated);
        expect(copied.user, user);
      });

      test('should copy with error message', () {
        final user = TestFixtures.createUser();
        final original = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        final copied = original.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Session expired',
        );

        expect(copied.status, AuthStatus.error);
        expect(copied.user, user); // User preserved
        expect(copied.errorMessage, 'Session expired');
      });

      test('should preserve values when not specified', () {
        final user = TestFixtures.createUser();
        final original = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
        final copied = original.copyWith();

        expect(copied.status, AuthStatus.authenticated);
        expect(copied.user, user);
        expect(copied.errorMessage, isNull);
      });

      test('should allow clearing error message', () {
        const original = AuthState(
          status: AuthStatus.error,
          errorMessage: 'Some error',
        );
        final copied = original.copyWith(
          status: AuthStatus.loading,
          errorMessage: null,
        );

        expect(copied.status, AuthStatus.loading);
        expect(copied.errorMessage, isNull);
      });
    });
  });

  group('GoogleAuthRequest', () {
    test('should serialize to JSON', () {
      const request = GoogleAuthRequest(accessToken: 'test-access-token');
      final json = request.toJson();

      expect(json['access_token'], 'test-access-token');
    });

    test('should deserialize from JSON', () {
      final json = {'access_token': 'parsed-token'};
      final request = GoogleAuthRequest.fromJson(json);

      expect(request.accessToken, 'parsed-token');
    });

    test('should be Equatable', () {
      const request1 = GoogleAuthRequest(accessToken: 'token-1');
      const request2 = GoogleAuthRequest(accessToken: 'token-1');
      const request3 = GoogleAuthRequest(accessToken: 'token-2');

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });

  // Note: AuthRepository and AuthNotifier tests require mocking GoogleSignIn and Supabase
  // which is complex. The state classes are fully tested above.
  // For full repository testing, consider using integration tests or
  // abstracting the auth providers behind interfaces.

  group('Auth State Transitions', () {
    test('initial -> loading -> authenticated flow', () {
      const initial = AuthState(status: AuthStatus.initial);

      final loading = initial.copyWith(status: AuthStatus.loading);
      expect(loading.status, AuthStatus.loading);

      final user = TestFixtures.createUser();
      final authenticated = loading.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
      expect(authenticated.status, AuthStatus.authenticated);
      expect(authenticated.user, isNotNull);
    });

    test('initial -> loading -> unauthenticated flow', () {
      const initial = AuthState(status: AuthStatus.initial);

      final loading = initial.copyWith(status: AuthStatus.loading);
      expect(loading.status, AuthStatus.loading);

      final unauthenticated = loading.copyWith(
        status: AuthStatus.unauthenticated,
      );
      expect(unauthenticated.status, AuthStatus.unauthenticated);
      expect(unauthenticated.user, isNull);
    });

    test('initial -> loading -> error flow', () {
      const initial = AuthState(status: AuthStatus.initial);

      final loading = initial.copyWith(status: AuthStatus.loading);
      expect(loading.status, AuthStatus.loading);

      final error = loading.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Network error',
      );
      expect(error.status, AuthStatus.error);
      expect(error.errorMessage, 'Network error');
    });

    test('authenticated -> loading -> unauthenticated (sign out)', () {
      final user = TestFixtures.createUser();
      final authenticated = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

      final loading = authenticated.copyWith(status: AuthStatus.loading);
      expect(loading.status, AuthStatus.loading);
      expect(loading.user, user); // User still present during sign out

      const unauthenticated = AuthState(status: AuthStatus.unauthenticated);
      expect(unauthenticated.status, AuthStatus.unauthenticated);
      expect(unauthenticated.user, isNull);
    });
  });
}
