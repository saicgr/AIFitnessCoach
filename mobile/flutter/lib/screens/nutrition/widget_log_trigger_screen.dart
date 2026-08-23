import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'quick_log_overlay.dart';

/// Screen that immediately shows the quick log overlay and stays on current screen
/// Used when widgets trigger the log meal action via deep link
class WidgetLogTriggerScreen extends ConsumerStatefulWidget {
  const WidgetLogTriggerScreen({super.key});

  @override
  ConsumerState<WidgetLogTriggerScreen> createState() => _WidgetLogTriggerScreenState();
}

class _WidgetLogTriggerScreenState extends ConsumerState<WidgetLogTriggerScreen> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    // Show dialog and pop this route immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dialogShown) {
        _dialogShown = true;

        if (Navigator.of(context).canPop()) {
          // Pop this route immediately - there's a screen underneath from
          // the widget (app was already running in the background).
          Navigator.of(context).pop();

          // Show the dialog on the previous screen
          showQuickLogOverlay(context, ref);
        } else {
          // Cold-start deep link: nothing is underneath to pop back to, so
          // popping is a no-op and this screen's empty SizedBox would be
          // left on screen with no nav bar and no way out. Land on Home
          // instead of stranding the user on a blank screen.
          context.go('/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return a completely empty, invisible widget
    return const SizedBox.shrink();
  }
}
