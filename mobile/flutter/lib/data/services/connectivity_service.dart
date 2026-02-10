import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity status for the app.
enum ConnectivityStatus { online, offline, unknown }

/// Service that monitors network connectivity using connectivity_plus.
///
/// Trusts the OS-level connectivity result (wifi, mobile, ethernet, vpn)
/// for immediate status. No HTTP ping is required — this avoids false
/// "offline" states on app startup due to DNS delays, cold backends, or
/// transient network issues.
///
/// Features:
/// - 1.5s debounce on rapid connectivity changes
/// - Stream-based status updates
/// - Auto-triggers sync on offline -> online transition
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Initialize and start monitoring connectivity.
  void initialize() {
    // Check initial status synchronously from the OS
    _connectivity.checkConnectivity().then((results) {
      final status = _mapResults(results);
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('📡 [Connectivity] Initial status: $status');
    }).catchError((e) {
      debugPrint('❌ [Connectivity] Error checking initial status: $e');
      // Assume online on error — better UX than falsely showing offline
      _currentStatus = ConnectivityStatus.online;
      _statusController.add(_currentStatus);
    });

    // Listen for changes with debounce
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        final newStatus = _mapResults(results);
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

  /// Map connectivity results to our simplified status.
  ///
  /// Trusts the OS — if wifi/mobile/ethernet/vpn is reported, we're online.
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
  // Emit current status first, then stream future changes
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
