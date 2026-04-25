import 'dart:async';

import 'package:flutter/material.dart';

/// Wraps a child loader (typically a CircularProgressIndicator). After
/// [softTimeout] elapses without the parent rebuilding, fades in a small
/// "Taking longer than usual…" hint below the loader. After [hardTimeout]
/// it surfaces a "We're having trouble reaching our servers" message with
/// an optional [onRetry] action.
///
/// Designed to be a drop-in replacement for a bare CircularProgressIndicator
/// inside a FutureBuilder/AsyncValue.when(loading:) branch — pass [child]
/// as your existing loader and SlowLoadIndicator handles the soft hint.
class SlowLoadIndicator extends StatefulWidget {
  const SlowLoadIndicator({
    super.key,
    required this.child,
    this.softTimeout = const Duration(seconds: 8),
    this.hardTimeout = const Duration(seconds: 15),
    this.onRetry,
    this.compact = false,
  });

  final Widget child;
  final Duration softTimeout;
  final Duration hardTimeout;
  final VoidCallback? onRetry;

  /// When true, only shows the soft hint (one line). For places where we
  /// can't afford an extra row (e.g. inside a fixed-height card).
  final bool compact;

  @override
  State<SlowLoadIndicator> createState() => _SlowLoadIndicatorState();
}

class _SlowLoadIndicatorState extends State<SlowLoadIndicator> {
  Timer? _softTimer;
  Timer? _hardTimer;
  bool _showSoft = false;
  bool _showHard = false;

  @override
  void initState() {
    super.initState();
    _softTimer = Timer(widget.softTimeout, () {
      if (mounted) setState(() => _showSoft = true);
    });
    _hardTimer = Timer(widget.hardTimeout, () {
      if (mounted) setState(() => _showHard = true);
    });
  }

  @override
  void dispose() {
    _softTimer?.cancel();
    _hardTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dim = theme.colorScheme.onSurface.withOpacity(0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: !_showSoft
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _showHard && !widget.compact
                        ? "We're having trouble reaching our servers."
                        : 'Taking longer than usual…',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: dim),
                  ),
                ),
        ),
        if (_showHard && !widget.compact && widget.onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: widget.onRetry,
              child: const Text('Try again'),
            ),
          ),
      ],
    );
  }
}
