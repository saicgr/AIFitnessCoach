import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity status for the app.
enum ConnectivityStatus { online, offline, unknown }

/// Service that monitors network connectivity using connectivity_plus
/// with an HTTP reachability fallback for devices where the plugin
/// reports false negatives (common on Samsung custom firmware).
///
/// Flow:
/// 1. Trust connectivity_plus for "online" (wifi/mobile/ethernet/vpn).
/// 2. When connectivity_plus says "offline" or "none", verify with a
///    lightweight HTTP HEAD to Google's connectivity-check endpoint.
/// 3. Only commit to offline if the HTTP check also fails.
///
/// Features:
/// - 1.5s debounce on rapid connectivity changes
/// - HTTP reachability fallback for false negatives
/// - Immediate recheck on app resume (no debounce)
/// - Stream-based status updates
/// - Auto-triggers sync on offline -> online transition
class ConnectivityService with WidgetsBindingObserver {
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
    // Register for app lifecycle events to recheck on resume
    WidgetsBinding.instance.addObserver(this);

    // Check initial status from the OS
    _connectivity.checkConnectivity().then((results) async {
      final pluginStatus = _mapResults(results);
      debugPrint(
          '📡 [Connectivity] Plugin initial: $pluginStatus (raw: $results)');

      // If plugin says offline, verify with HTTP before committing
      final status = pluginStatus == ConnectivityStatus.offline
          ? await _verifyWithHttp()
          : pluginStatus;

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
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
        final pluginStatus = _mapResults(results);

        // If plugin says offline, verify with HTTP before committing
        final newStatus = pluginStatus == ConnectivityStatus.offline
            ? await _verifyWithHttp()
            : pluginStatus;

        _applyStatus(newStatus);
      });
    });
  }

  /// Called automatically when the app comes back to the foreground.
  /// Cancels any pending debounce and rechecks immediately so the
  /// offline banner doesn't flash on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      recheckNow();
    }
  }

  /// Force an immediate connectivity recheck (no debounce).
  /// Call this on app resume or when you suspect stale state.
  Future<void> recheckNow() async {
    _debounceTimer?.cancel();
    try {
      final results = await _connectivity.checkConnectivity();
      final pluginStatus = _mapResults(results);

      final status = pluginStatus == ConnectivityStatus.offline
          ? await _verifyWithHttp()
          : pluginStatus;

      _applyStatus(status);
      debugPrint('📡 [Connectivity] Recheck: $status');
    } catch (e) {
      debugPrint('❌ [Connectivity] Recheck error: $e');
    }
  }

  /// Apply a new status, emit to stream if changed.
  void _applyStatus(ConnectivityStatus newStatus) {
    if (newStatus != _currentStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      _statusController.add(newStatus);
      debugPrint(
          '📡 [Connectivity] Status changed: $previousStatus -> $newStatus');

      if (previousStatus == ConnectivityStatus.offline &&
          newStatus == ConnectivityStatus.online) {
        debugPrint('📡 [Connectivity] Back online — sync should trigger');
      }
    }
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

  /// HTTP reachability check — used when connectivity_plus reports offline
  /// to guard against false negatives on Samsung/custom Android firmware.
  ///
  /// Uses Google's lightweight connectivity-check endpoint (returns 204).
  /// 3-second timeout to avoid blocking the UI.
  Future<ConnectivityStatus> _verifyWithHttp() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final request = await client.headUrl(
        Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      client.close(force: true);

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint(
            '📡 [Connectivity] HTTP check: reachable (plugin was wrong)');
        return ConnectivityStatus.online;
      }
      debugPrint(
          '📡 [Connectivity] HTTP check: status ${response.statusCode}');
      return ConnectivityStatus.offline;
    } catch (e) {
      debugPrint('📡 [Connectivity] HTTP check: unreachable ($e)');
      return ConnectivityStatus.offline;
    }
  }

  /// Clean up resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
