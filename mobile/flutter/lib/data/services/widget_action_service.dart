import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/nutrition/quick_log_overlay.dart';

/// Service that listens for widget action commands from native Android code
/// This allows widgets to trigger UI actions without going through navigation
class WidgetActionService {
  static const platform = MethodChannel('com.fitwiz.app/widget_actions');

  BuildContext? _context;
  WidgetRef? _ref;
  bool _initialized = false;

  /// Initialize the service with app context
  void initialize(BuildContext context, WidgetRef ref) {
    // Update context and ref every time (in case widget rebuilds)
    _context = context;
    _ref = ref;

    // Only set up the method channel handler once
    if (!_initialized) {
      platform.setMethodCallHandler(_handleMethodCall);
      _initialized = true;
      debugPrint('✅ [WidgetAction] Service initialized and listening for widget actions');
    }
  }

  /// Handle method calls from Android native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('🔔 [WidgetAction] Received method call: ${call.method}');

    switch (call.method) {
      case 'showQuickLogOverlay':
        _showQuickLogOverlay();
        break;
      default:
        debugPrint('⚠️ [WidgetAction] Unknown method: ${call.method}');
    }
  }

  /// Show the quick log overlay without any navigation
  void _showQuickLogOverlay() {
    if (_context == null || _ref == null) {
      debugPrint('❌ [WidgetAction] Context or ref not initialized');
      return;
    }

    debugPrint('✅ [WidgetAction] Context available, scheduling overlay display');

    // Wait longer to ensure the app is fully visible and in foreground
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_context != null && _context!.mounted) {
        debugPrint('✅ [WidgetAction] App should be visible now, showing quick log overlay');
        showQuickLogOverlay(_context!, _ref!);
      } else {
        debugPrint('❌ [WidgetAction] Context no longer mounted when trying to show overlay');
      }
    });
  }
}

/// Provider for the widget action service
final widgetActionServiceProvider = Provider<WidgetActionService>((ref) {
  return WidgetActionService();
});
