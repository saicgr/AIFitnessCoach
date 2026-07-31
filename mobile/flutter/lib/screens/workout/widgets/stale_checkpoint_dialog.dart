// E2E #136 — a freshly started workout used to open with a stale session
// already running (23m37s / 161 kcal / 666 kg) because the crash-safe
// checkpoint (`active_workout_session_provider.dart`) rehydrated SILENTLY,
// no matter how old it was. This is the explicit Resume / Start fresh
// prompt both the Easy and Advanced active-workout screens show when
// `ActiveWorkoutSessionNotifier.peekStaleCheckpoint` reports a checkpoint
// older than `kCheckpointStalePromptThreshold`.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Human-friendly "23m ago" / "1h 40m ago" / "yesterday" age string.
String formatCheckpointAge(Duration age) {
  if (age.inMinutes < 1) return 'moments ago';
  if (age.inMinutes < 60) return '${age.inMinutes}m ago';
  if (age.inHours < 24) {
    final mins = age.inMinutes % 60;
    return mins == 0 ? '${age.inHours}h ago' : '${age.inHours}h ${mins}m ago';
  }
  return age.inDays == 1 ? 'yesterday' : '${age.inDays} days ago';
}

/// Shows the Resume / Start Fresh choice. Returns `true` to resume the
/// on-disk checkpoint, `false` to discard it and start clean, or `null` if
/// dismissed (treated as "start fresh" by callers — never silently resume
/// on an ambiguous dismissal).
Future<bool?> showStaleCheckpointDialog(
  BuildContext context, {
  required Duration age,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Resume your workout?'),
      content: Text(
        'You have an in-progress session from ${formatCheckpointAge(age)} '
        'with logged sets. Pick up where you left off, or start a new '
        'session from scratch.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.textMuted : AppColorsLight.textSecondary,
          ),
          child: const Text('Start fresh'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Resume'),
        ),
      ],
    ),
  );
}
