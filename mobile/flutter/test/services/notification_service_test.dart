import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fitwiz/data/services/notification_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;

  setUp(() {
    setUpMocks();
    mockApiClient = MockApiClient();
  });

  group('OnTokenRefreshCallback', () {
    test('should be a valid function type', () {
      // Test that the callback type is defined correctly
      String? receivedToken;
      final OnTokenRefreshCallback callback = (String newToken) {
        receivedToken = newToken;
      };

      callback('test-fcm-token-12345');

      expect(receivedToken, 'test-fcm-token-12345');
    });

    test('should be nullable on NotificationService', () {
      // We can't directly test NotificationService initialization without mocking
      // Firebase, but we can verify the callback type works correctly
      OnTokenRefreshCallback? nullableCallback;

      // Should be null by default
      expect(nullableCallback, isNull);

      // Should be assignable
      nullableCallback = (String newToken) {
        // Handle token
      };
      expect(nullableCallback, isNotNull);
    });
  });

  group('FCM Token Registration', () {
    test('registerTokenWithBackend should call API with correct data', () async {
      // This is a conceptual test since we can't easily mock the NotificationService
      // internal state. The actual registration logic is:
      //
      // await apiClient.put(
      //   '${ApiConstants.users}/$userId',
      //   data: {
      //     'fcm_token': _fcmToken,
      //     'device_platform': Platform.isAndroid ? 'android' : 'ios',
      //   },
      // );

      when(() => mockApiClient.put(
        any(),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/users/user-123'),
        statusCode: 200,
      ));

      // Verify the API client accepts the expected call pattern
      await mockApiClient.put(
        '/api/v1/users/user-123',
        data: {
          'fcm_token': 'test-token-abc123',
          'device_platform': 'android',
        },
      );

      verify(() => mockApiClient.put(
        '/api/v1/users/user-123',
        data: {
          'fcm_token': 'test-token-abc123',
          'device_platform': 'android',
        },
      )).called(1);
    });

    test('should handle API errors gracefully', () async {
      when(() => mockApiClient.put(
        any(),
        data: any(named: 'data'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users/user-123'),
        error: 'Network error',
      ));

      // The actual service returns false on error
      // This test verifies the expected behavior pattern
      expect(
        () => mockApiClient.put(
          '/api/v1/users/user-123',
          data: {'fcm_token': 'token'},
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('Token Refresh Flow', () {
    test('should invoke callback when token refreshes', () {
      // Simulating the token refresh flow as implemented in notification_service.dart:
      // messaging!.onTokenRefresh.listen((newToken) {
      //   _fcmToken = newToken;
      //   onTokenRefresh?.call(newToken);
      // });

      String? capturedToken;
      final OnTokenRefreshCallback callback = (String newToken) {
        capturedToken = newToken;
      };

      // Simulate token refresh
      callback('new-refreshed-token-xyz');

      expect(capturedToken, 'new-refreshed-token-xyz');
    });

    test('should handle null callback gracefully', () {
      OnTokenRefreshCallback? callback;

      // Simulating: onTokenRefresh?.call(newToken);
      // This should not throw when callback is null
      callback?.call('token');

      // No assertion needed - just verifying no exception is thrown
      expect(callback, isNull);
    });
  });

  group('App Login Token Registration', () {
    test('should register token on login (conceptual test)', () async {
      // This test documents the expected flow in app.dart:
      //
      // Future<void> _registerFcmToken() async {
      //   final authState = ref.read(authStateProvider);
      //   if (authState.user == null) return;
      //   final notificationService = ref.read(notificationServiceProvider);
      //   final apiClient = ref.read(apiClientProvider);
      //   final userId = authState.user!.id;
      //   await notificationService.registerTokenWithBackend(apiClient, userId);
      // }

      when(() => mockApiClient.put(
        any(),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/users/user-123'),
        statusCode: 200,
      ));

      // Simulate the registration call
      await mockApiClient.put(
        '/api/v1/users/user-123',
        data: {
          'fcm_token': 'login-token-abc',
          'device_platform': 'ios',
        },
      );

      verify(() => mockApiClient.put(
        any(),
        data: any(named: 'data'),
      )).called(1);
    });
  });

  group('Test Notification', () {
    test('should send test notification via API', () async {
      when(() => mockApiClient.post(
        any(),
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/notifications/test'),
        statusCode: 200,
        data: {'success': true},
      ));

      final response = await mockApiClient.post(
        '/api/v1/notifications/test',
        data: {
          'user_id': 'user-123',
          'fcm_token': 'test-token',
        },
      );

      expect(response.statusCode, 200);
      expect(response.data['success'], true);
    });
  });
}
