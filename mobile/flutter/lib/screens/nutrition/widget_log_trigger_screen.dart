import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        // Pop this route immediately - there's always a screen underneath from the widget
        Navigator.of(context).pop();

        // Show the dialog on the previous screen
        showQuickLogOverlay(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return a completely empty, invisible widget
    return const SizedBox.shrink();
  }
}
