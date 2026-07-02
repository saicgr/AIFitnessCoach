import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Lifecycle of the undo card within a single chat bubble.
enum _UndoUiState { idle, undoing, undone, failed, expired }

/// Compact "Logged ✓ · Undo" card shown below an assistant message after the
/// AI Coach logs a wellness event via the universal logger (Phase 6).
///
/// Backed by the signed `undo_token` the backend mints on every
/// `/events/log` write — tapping Undo calls `POST /events/undo`, which
/// reverses the insert within the 30-second token window. After the window
/// the card self-disables (X8 — every chat-log is undoable while fresh).
///
/// Handles BOTH the single-event payload (`event_id`/`undo_token` flat on
/// `actionData`) and the multi-event payload (an `events` list) — one row
/// with an Undo button per logged event.
class EventLoggedUndoCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> actionData;

  const EventLoggedUndoCard({super.key, required this.actionData});

  @override
  ConsumerState<EventLoggedUndoCard> createState() =>
      _EventLoggedUndoCardState();
}

class _EventLoggedUndoCardState extends ConsumerState<EventLoggedUndoCard> {
  /// Per-event UI state, keyed by event index.
  final Map<int, _UndoUiState> _state = {};
  Timer? _expiryTimer;

  /// Signed undo tokens are valid for 30s server-side. We disable the
  /// buttons a touch early (28s) to avoid a guaranteed-to-fail tap.
  static const Duration _undoWindow = Duration(seconds: 28);

  List<Map<String, dynamic>> get _events {
    final list = widget.actionData['events'];
    if (list is List && list.isNotEmpty) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    // Single-event payload — wrap the flat actionData.
    return [Map<String, dynamic>.from(widget.actionData)];
  }

  @override
  void initState() {
    super.initState();
    // Self-expire the undo affordance when the token window closes.
    _expiryTimer = Timer(_undoWindow, () {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _events.length; i++) {
          if ((_state[i] ?? _UndoUiState.idle) == _UndoUiState.idle) {
            _state[i] = _UndoUiState.expired;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Future<void> _undo(int index, Map<String, dynamic> event) async {
    final undoToken = event['undo_token'] as String?;
    if (undoToken == null || undoToken.isEmpty) return;

    HapticService.light();
    setState(() => _state[index] = _UndoUiState.undoing);

    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
      if (userId == null) {
        setState(() => _state[index] = _UndoUiState.failed);
        return;
      }
      final resp = await api.post(
        '/events/undo',
        data: {'user_id': userId, 'undo_token': undoToken},
      );
      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() => _state[index] = _UndoUiState.undone);
      } else {
        setState(() => _state[index] = _UndoUiState.failed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state[index] = _UndoUiState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    // Nothing actionable if no event carries an undo token.
    if (events.every((e) => (e['undo_token'] as String?)?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < events.length; i++)
            _buildRow(context, i, events[i]),
        ],
      ),
    );
  }

  /// Where a logged event can be VIEWED, by domain. Null = no destination
  /// (the row stays non-navigable). Workout/sleep events are `workouts` rows,
  /// so they deep-link straight to that entry's summary.
  String? _routeFor(Map<String, dynamic> e) {
    final domain = (e['domain'] as String?) ?? '';
    final eventId = (e['event_id'] as String?) ?? '';
    final rawId = eventId.contains(':') ? eventId.split(':').last : eventId;
    switch (domain) {
      case 'workout':
      case 'sleep':
        return rawId.isNotEmpty ? '/workout-summary/$rawId' : null;
      case 'water':
        return '/hydration';
      case 'weight':
      case 'measurement':
        return '/measurements';
      case 'habit':
        return '/habits';
      case 'fasting':
        return '/fasting';
      default:
        return null;
    }
  }

  Widget _buildRow(BuildContext context, int index, Map<String, dynamic> e) {
    final theme = Theme.of(context);
    final state = _state[index] ?? _UndoUiState.idle;
    final name = (e['name'] as String?) ?? 'Logged';
    final hasToken = (e['undo_token'] as String?)?.isNotEmpty ?? false;
    // Tap-to-view: only while the row still represents a live entry.
    final route = (state == _UndoUiState.idle || state == _UndoUiState.expired)
        ? _routeFor(e)
        : null;

    Widget trailing;
    switch (state) {
      case _UndoUiState.idle:
        trailing = hasToken
            ? TextButton(
                onPressed: () => _undo(index, e),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(AppLocalizations.of(context).workoutUiBuildersUndo),
              )
            : const SizedBox.shrink();
        break;
      case _UndoUiState.undoing:
        trailing = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case _UndoUiState.undone:
        trailing = Text(
          AppLocalizations.of(context).eventLoggedUndoRemoved,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        );
        break;
      case _UndoUiState.failed:
        trailing = TextButton(
          onPressed: () => _undo(index, e),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(AppLocalizations.of(context).buttonRetry),
        );
        break;
      case _UndoUiState.expired:
        trailing = Text(
          AppLocalizations.of(context).savedHubSaved,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
        break;
    }

    final bool struck = state == _UndoUiState.undone;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            struck ? Icons.undo_rounded : Icons.check_circle_rounded,
            size: 16,
            color: struck
                ? theme.colorScheme.error
                : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration:
                    struck ? TextDecoration.lineThrough : TextDecoration.none,
                color: struck
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          trailing,
          if (route != null) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    if (route == null) return row;
    // Whole row opens the surface where the entry now lives (the Undo
    // TextButton keeps its own hit target).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        context.push(route);
      },
      child: row,
    );
  }
}
