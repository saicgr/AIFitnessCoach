import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/health_service.dart';

/// Provider that fetches last night's sleep data from Health Connect.
/// Returns null if Health Connect is not connected.
final sleepProvider = FutureProvider.autoDispose<SleepSummary?>((ref) async {
  final syncState = ref.watch(healthSyncProvider);
  if (!syncState.isConnected) return null;

  final healthService = ref.watch(healthServiceProvider);
  try {
    final sleep = await healthService.getSleepData(days: 1);
    if (!sleep.hasData) return null;
    return sleep;
  } catch (e) {
    debugPrint('❌ [SleepProvider] Error fetching sleep data: $e');
    return null;
  }
});
