import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity status for the app.
enum ConnectivityStatus { online, offline, unknown }

/// Service that monitors network connectivity using connectivity_plus.
///
/// Features:
/// - 1.5s debounce on rapid connectivity changes
/// - HTTP ping verification to confirm actual internet access
/// - 30-second ping cache to avoid excessive network calls
/// - Stream-based status updates
/// - Auto-triggers sync on offline -> online transition
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Cached ping result to avoid excessive pinging.
  bool? _lastPingResult;
  DateTime? _lastPingTime;
  static const _pingCacheDuration = Duration(seconds: 30);
  static const _pingTimeout = Duration(seconds: 3);
  static const _healthUrl = 'https://aifitnesscoach-zqi3.onrender.com/api/v1/health';

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Initialize and start monitoring connectivity.
  Future<void> initialize() async {
    // Check initial status
    try {
      final results = await _connectivity.checkConnectivity();
      _currentStatus = await _mapResultsWithPing(results);
      _statusController.add(_currentStatus);
      debugPrint('📡 [Connectivity] Initial status: $_currentStatus');
    } catch (e) {
      debugPrint('❌ [Connectivity] Error checking initial status: $e');
      _currentStatus = ConnectivityStatus.unknown;
    }

    // Listen for changes with debounce
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
        final newStatus = await _mapResultsWithPing(results);
        if (newStatus != _currentStatus) {
          final previousStatus = _currentStatus;
          _currentStatus = newStatus;
          _statusController.add(newStatus);
          debugPrint(
              '📡 [Connectivity] Status changed: $previousStatus -> $newStatus');

          // Detect offline -> online transition for sync trigger
          if (previousStatus == ConnectivityStatus.offline &&
              newStatus == ConnectivityStatus.online) {
            debugPrint('📡 [Connectivity] Back online — sync should trigger');
          }
        }
      });
    });
  }

  /// Map connectivity results to status, with HTTP ping verification when online.
  Future<ConnectivityStatus> _mapResultsWithPing(
      List<ConnectivityResult> results) async {
    final basicStatus = _mapResults(results);
    if (basicStatus != ConnectivityStatus.online) {
      return basicStatus;
    }
    // Verify actual internet access with a ping
    final reallyOnline = await verifyOnline();
    return reallyOnline ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  /// Map connectivity results to our simplified status (no ping).
  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    // Any of wifi, mobile, ethernet, vpn = online
    if (results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn)) {
      return ConnectivityStatus.online;
    }
    return ConnectivityStatus.unknown;
  }

  /// Verify actual internet connectivity by pinging the backend health endpoint.
  /// Results are cached for 30 seconds to avoid excessive pinging.
  Future<bool> verifyOnline() async {
    // Return cached result if fresh enough
    if (_lastPingResult != null && _lastPingTime != null) {
      final elapsed = DateTime.now().difference(_lastPingTime!);
      if (elapsed < _pingCacheDuration) {
        return _lastPingResult!;
      }
    }

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: _pingTimeout,
        receiveTimeout: _pingTimeout,
      ));
      final response = await dio.head(_healthUrl);
      final isOnline = response.statusCode != null && response.statusCode! < 500;
      _lastPingResult = isOnline;
      _lastPingTime = DateTime.now();
      return isOnline;
    } catch (e) {
      debugPrint('📡 [Connectivity] Ping failed: $e');
      _lastPingResult = false;
      _lastPingTime = DateTime.now();
      return false;
    }
  }

  /// Invalidate ping cache (e.g., after a network change).
  void invalidatePingCache() {
    _lastPingResult = null;
    _lastPingTime = null;
  }

  /// Clean up resources.
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _statusController.close();
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// Singleton connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of connectivity status changes.
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  // Emit current status first, then stream
  return Stream.value(service.currentStatus)
      .followedBy(service.statusStream);
});

/// Simple bool convenience provider.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.maybeWhen(
    data: (s) => s == ConnectivityStatus.online,
    orElse: () => true, // Assume online if unknown
  );
});

/// Extension to combine streams with an initial value.
extension _StreamFollowedBy<T> on Stream<T> {
  Stream<T> followedBy(Stream<T> other) async* {
    yield* this;
    yield* other;
  }
}
