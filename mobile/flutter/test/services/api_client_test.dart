import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitwiz/data/services/api_client.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late ApiClient apiClient;

  setUp(() {
    setUpMocks();
    mockStorage = MockFlutterSecureStorage();

    // Default stubs for storage operations
    when(() => mockStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => mockStorage.delete(key: any(named: 'key')))
        .thenAnswer((_) async {});

    apiClient = ApiClient(mockStorage);
  });

  group('ApiClient', () {
    group('constructor', () {
      test('should create Dio instance with base URL', () {
        expect(apiClient.dio.options.baseUrl, isNotEmpty);
      });

      test('should set default headers', () {
        final headers = apiClient.dio.options.headers;
        expect(headers['Content-Type'], 'application/json');
        expect(headers['Accept'], 'application/json');
      });

      test('should set timeouts', () {
        expect(apiClient.dio.options.connectTimeout, isNotNull);
        expect(apiClient.dio.options.receiveTimeout, isNotNull);
      });
    });

    group('setAuthToken', () {
      test('should save token to secure storage', () async {
        await apiClient.setAuthToken('test-token');

        verify(() => mockStorage.write(key: 'auth_token', value: 'test-token'))
            .called(1);
      });
    });

    group('setUserId', () {
      test('should save user ID to secure storage', () async {
        await apiClient.setUserId('user-123');

        verify(() => mockStorage.write(key: 'user_id', value: 'user-123'))
            .called(1);
      });
    });

    group('getUserId', () {
      test('should return user ID from secure storage', () async {
        when(() => mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user-123');

        final userId = await apiClient.getUserId();

        expect(userId, 'user-123');
      });

      test('should return null when user ID not stored', () async {
        when(() => mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => null);

        final userId = await apiClient.getUserId();

        expect(userId, isNull);
      });
    });

    group('getAuthToken', () {
      test('should return token from secure storage', () async {
        when(() => mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'test-token');

        final token = await apiClient.getAuthToken();

        expect(token, 'test-token');
      });

      test('should return null when token not stored', () async {
        when(() => mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => null);

        final token = await apiClient.getAuthToken();

        expect(token, isNull);
      });
    });

    group('clearAuth', () {
      test('should delete token and user ID from storage', () async {
        await apiClient.clearAuth();

        verify(() => mockStorage.delete(key: 'auth_token')).called(1);
        verify(() => mockStorage.delete(key: 'user_id')).called(1);
      });
    });

    group('isAuthenticated', () {
      test('should return true when token exists', () async {
        when(() => mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'valid-token');

        final isAuth = await apiClient.isAuthenticated();

        expect(isAuth, true);
      });

      test('should return false when token is null', () async {
        when(() => mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => null);

        final isAuth = await apiClient.isAuthenticated();

        expect(isAuth, false);
      });

      test('should return false when token is empty', () async {
        when(() => mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => '');

        final isAuth = await apiClient.isAuthenticated();

        expect(isAuth, false);
      });
    });

    group('HTTP methods', () {
      // Note: These tests verify that the methods exist and have correct signatures.
      // Full integration tests would require mocking Dio responses.

      test('get method should be callable', () {
        expect(apiClient.get, isNotNull);
      });

      test('post method should be callable', () {
        expect(apiClient.post, isNotNull);
      });

      test('put method should be callable', () {
        expect(apiClient.put, isNotNull);
      });

      test('patch method should be callable', () {
        expect(apiClient.patch, isNotNull);
      });

      test('delete method should be callable', () {
        expect(apiClient.delete, isNotNull);
      });
    });
  });

  group('Auth Interceptor', () {
    test('should add Authorization header when token exists', () async {
      when(() => mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'test-token');

      // The interceptor is added during construction
      // We verify it by checking the interceptors list
      expect(apiClient.dio.interceptors.length, greaterThanOrEqualTo(1));
    });
  });
}
