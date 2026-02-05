/// Live API test for Daily Crate fix verification
///
/// Run this script to test the daily crate endpoint with a valid auth token.
///
/// Usage:
///   1. Get your auth token from the app's debug logs (look for "Bearer ...")
///   2. Run: dart test_daily_crate_live.dart <YOUR_AUTH_TOKEN>
///
/// Example:
///   dart test_daily_crate_live.dart eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

import 'dart:convert';
import 'dart:io';

const baseUrl = 'https://aifitnesscoach-zqi3.onrender.com/api/v1';

Future<void> main(List<String> args) async {
  print('');
  print('=' * 60);
  print('DAILY CRATE FIX VERIFICATION TEST');
  print('=' * 60);
  print('');

  if (args.isEmpty) {
    print('❌ Error: No auth token provided');
    print('');
    print('Usage: dart test_daily_crate_live.dart <YOUR_AUTH_TOKEN>');
    print('');
    print('To get your token:');
    print('  1. Open the app and login');
    print('  2. Look in the debug console for "Bearer ..."');
    print('  3. Copy the token (everything after "Bearer ")');
    exit(1);
  }

  final authToken = args[0];
  print('🔑 Using auth token: ${authToken.substring(0, 20)}...');
  print('');

  final client = HttpClient();

  try {
    // Test 1: Get daily crates state
    print('📋 TEST 1: Get Daily Crates State');
    print('-' * 40);

    final getCratesRequest = await client.getUrl(
      Uri.parse('$baseUrl/xp/daily-crates'),
    );
    getCratesRequest.headers.set('Authorization', 'Bearer $authToken');
    getCratesRequest.headers.set('Content-Type', 'application/json');

    final getCratesResponse = await getCratesRequest.close();
    final getCratesBody = await getCratesResponse.transform(utf8.decoder).join();

    print('Status: ${getCratesResponse.statusCode}');

    if (getCratesResponse.statusCode == 200) {
      final state = jsonDecode(getCratesBody);
      print('✅ Success!');
      print('   Daily crate available: ${state['daily_crate_available']}');
      print('   Streak crate available: ${state['streak_crate_available']}');
      print('   Activity crate available: ${state['activity_crate_available']}');
      print('   Already claimed: ${state['claimed']}');
      print('   Selected crate: ${state['selected_crate']}');
    } else if (getCratesResponse.statusCode == 401) {
      print('❌ Auth token expired or invalid');
      exit(1);
    } else {
      print('❌ Error: $getCratesBody');
    }

    print('');

    // Test 2: Claim daily crate
    print('🎁 TEST 2: Claim Daily Crate');
    print('-' * 40);

    final claimRequest = await client.postUrl(
      Uri.parse('$baseUrl/xp/claim-daily-crate'),
    );
    claimRequest.headers.set('Authorization', 'Bearer $authToken');
    claimRequest.headers.set('Content-Type', 'application/json');
    claimRequest.write(jsonEncode({'crate_type': 'daily'}));

    final claimResponse = await claimRequest.close();
    final claimBody = await claimResponse.transform(utf8.decoder).join();

    print('Status: ${claimResponse.statusCode}');

    if (claimResponse.statusCode == 200) {
      final result = jsonDecode(claimBody);
      print('✅ Success! No 500 error!');
      print('');
      print('Response:');
      print('   success: ${result['success']}');
      print('   crate_type: ${result['crate_type']}');
      print('   message: ${result['message']}');

      if (result['reward'] != null) {
        print('   reward:');
        print('      type: ${result['reward']['type']}');
        print('      amount: ${result['reward']['amount']}');
        print('      display_name: ${result['reward']['display_name']}');
      }

      print('');
      if (result['success'] == true) {
        print('🎉 CRATE CLAIMED SUCCESSFULLY!');
        print('   You received: ${result['reward']?['display_name'] ?? 'Unknown'}');
      } else {
        print('ℹ️  Crate not claimed: ${result['message']}');
        print('   (This is expected if you already claimed today)');
      }
    } else if (claimResponse.statusCode == 500) {
      print('❌ FAILED: Got 500 error');
      print('');
      print('Response: $claimBody');
      print('');

      if (claimBody.contains('JSON could not be generated')) {
        print('⚠️  THE FIX IS NOT WORKING!');
        print('   The backend is still returning the JSON serialization error.');
        print('   Make sure the migration was run and backend was deployed.');
      }
    } else if (claimResponse.statusCode == 401) {
      print('❌ Auth token expired or invalid');
    } else {
      print('❌ Error: $claimBody');
    }

    print('');
    print('=' * 60);
    print('TEST COMPLETE');
    print('=' * 60);
  } finally {
    client.close();
  }
}
