/// Integration test for Daily Crate API
///
/// This test verifies the claim-daily-crate endpoint is working correctly
/// after the JSON serialization fix (migration 230).
///
/// Run with: flutter test test/integration/daily_crate_api_test.dart
///
/// Note: This test requires a valid auth token. Update the token before running.

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fitwiz/data/repositories/xp_repository.dart';

void main() {
  const baseUrl = 'https://aifitnesscoach-zqi3.onrender.com/api/v1';

  // IMPORTANT: Update this token before running the test
  // Get a fresh token by logging into the app and copying from debug logs
  const authToken = 'YOUR_AUTH_TOKEN_HERE';

  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  });

  tearDown(() {
    dio.close();
  });

  group('Daily Crate API Integration Tests', () {
    test('claim-daily-crate returns valid JSON structure', () async {
      // Skip if no auth token provided
      if (authToken == 'YOUR_AUTH_TOKEN_HERE') {
        print('⚠️  Skipping test: No auth token provided');
        print('   Update authToken in the test file with a valid token');
        return;
      }

      try {
        final response = await dio.post(
          '/xp/claim-daily-crate',
          data: {'crate_type': 'daily'},
        );

        print('✅ API Response: ${response.data}');
        print('   Status: ${response.statusCode}');

        // Parse the response
        final result = CrateRewardResult.fromJson(response.data);

        // Verify structure
        expect(response.statusCode, equals(200));

        if (result.success) {
          print('🎁 Crate claimed successfully!');
          print('   Reward type: ${result.reward?.type}');
          print('   Reward amount: ${result.reward?.amount}');
          print('   Display name: ${result.reward?.displayName}');

          expect(result.reward, isNotNull);
          expect(result.reward!.type, isNotEmpty);
          expect(result.reward!.amount, greaterThan(0));
          expect(result.reward!.displayName, isNotEmpty);
        } else {
          print('ℹ️  Crate not claimed: ${result.message}');
          // This is expected if already claimed today
          expect(result.message, isNotNull);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          print('❌ Auth token expired. Please update the token.');
          return;
        }

        // Check if it's the old JSON serialization error
        final errorData = e.response?.data;
        if (errorData != null && errorData.toString().contains('JSON could not be generated')) {
          fail('❌ FAILED: Still getting JSON serialization error!\n'
              '   This means the fix is not deployed or not working.\n'
              '   Error: $errorData');
        }

        print('❌ API Error: ${e.message}');
        print('   Response: ${e.response?.data}');
        rethrow;
      }
    }, skip: authToken == 'YOUR_AUTH_TOKEN_HERE');

    test('get-daily-crates returns valid state', () async {
      if (authToken == 'YOUR_AUTH_TOKEN_HERE') {
        print('⚠️  Skipping test: No auth token provided');
        return;
      }

      try {
        final response = await dio.get('/xp/daily-crates');

        print('✅ Daily Crates State: ${response.data}');

        expect(response.statusCode, equals(200));

        final state = DailyCratesState.fromJson(response.data);

        print('📦 Daily crate available: ${state.dailyCrateAvailable}');
        print('🔥 Streak crate available: ${state.streakCrateAvailable}');
        print('⚡ Activity crate available: ${state.activityCrateAvailable}');
        print('✓  Already claimed: ${state.claimed}');
        print('   Selected crate: ${state.selectedCrate}');

        expect(state.dailyCrateAvailable, isNotNull);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          print('❌ Auth token expired. Please update the token.');
          return;
        }
        print('❌ API Error: ${e.message}');
        rethrow;
      }
    }, skip: authToken == 'YOUR_AUTH_TOKEN_HERE');
  });

  group('Response Parsing Tests (Offline)', () {
    test('parses actual API success response format', () {
      // This is the exact format returned by the fixed backend
      final json = {
        'success': true,
        'crate_type': 'daily',
        'reward': {
          'type': 'xp',
          'amount': 32,
          'display_name': '+32 XP',
        },
        'message': 'Crate opened!',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.crateType, equals('daily'));
      expect(result.reward, isNotNull);
      expect(result.reward!.type, equals('xp'));
      expect(result.reward!.amount, equals(32));
      expect(result.reward!.displayName, equals('+32 XP'));
      expect(result.message, equals('Crate opened!'));

      print('✅ Response parsing test passed');
      print('   Reward: ${result.reward!.displayName}');
    });

    test('parses already claimed response', () {
      final json = {
        'success': false,
        'crate_type': 'daily',
        'message': 'Crate already claimed today',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.message, equals('Crate already claimed today'));
      expect(result.reward, isNull);

      print('✅ Already claimed response parsing test passed');
    });

    test('parses streak shield reward', () {
      final json = {
        'success': true,
        'crate_type': 'daily',
        'reward': {
          'type': 'streak_shield',
          'amount': 1,
          'display_name': '1 Streak Shield',
        },
        'message': 'Crate opened!',
      };

      final result = CrateRewardResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.reward!.type, equals('streak_shield'));
      expect(result.reward!.isConsumable, isTrue);
      expect(result.reward!.isXP, isFalse);

      print('✅ Streak shield reward parsing test passed');
    });
  });
}
