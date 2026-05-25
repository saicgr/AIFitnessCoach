import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/buddy_workout_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Phase 6 #15 — live buddy progress bar inside the active workout screen.
///
/// Subscribes to `buddy_set_events` Realtime for `sessionId`, surfacing the
/// partner's last completed set. Self-echo events are filtered out by
/// matching `user_id` against the authed user.
class BuddyWorkoutBar extends ConsumerStatefulWidget {
  const BuddyWorkoutBar({
    super.key,
    required this.sessionId,
    required this.partnerUserId,
    required this.partnerDisplayName,
  });

  final String sessionId;
  final String partnerUserId;
  final String partnerDisplayName;

  @override
  ConsumerState<BuddyWorkoutBar> createState() => _BuddyWorkoutBarState();
}

class _BuddyWorkoutBarState extends ConsumerState<BuddyWorkoutBar> {
  Map<String, dynamic>? _lastPartnerEvent;
  int _partnerSetsLogged = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final svc = ref.read(buddyWorkoutServiceProvider);
    // Replay history first so the bar isn't empty on attach.
    try {
      final events = await svc.replayEvents(widget.sessionId);
      final partnerEvents =
          events.where((e) => e['user_id'] == widget.partnerUserId).toList();
      if (mounted) {
        setState(() {
          _partnerSetsLogged = partnerEvents.length;
          if (partnerEvents.isNotEmpty) {
            _lastPartnerEvent = partnerEvents.last;
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ [BuddyWorkoutBar] replay failed: $e');
    }
    // Subscribe to live updates. Channel handle is stored inside the service
    // singleton — we cancel it from dispose() via svc.unsubscribe().
    svc.subscribe(
      sessionId: widget.sessionId,
      onEvent: _onEvent,
    );
  }

  void _onEvent(Map<String, dynamic> row) {
    // Ignore self — we only want the partner's progress.
    if (row['user_id'] == widget.partnerUserId) {
      if (mounted) {
        setState(() {
          _lastPartnerEvent = row;
          _partnerSetsLogged += 1;
        });
      }
    }
  }

  @override
  void dispose() {
    ref.read(buddyWorkoutServiceProvider).unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final last = _lastPartnerEvent;
    final subtitle = last == null
        ? 'Waiting for ${widget.partnerDisplayName} to start…'
        : _formatLastEvent(last);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _initials(widget.partnerDisplayName),
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.partnerDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _LiveDot(),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.buddyWorkoutBarSets(_partnerSetsLogged),
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String _formatLastEvent(Map<String, dynamic> e) {
    final name = (e['exercise_name'] ?? e['exercise_id'] ?? 'exercise').toString();
    final set = e['set_number'];
    final w = e['weight_kg'];
    final r = e['reps'];
    final wPart = (w == null) ? '' : ' @ ${_fmtNum(w)}kg';
    final rPart = (r == null) ? '' : ' × $r';
    return 'Set $set — $name$wPart$rPart';
  }

  static String _fmtNum(dynamic v) {
    if (v is num) {
      if (v == v.roundToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(1);
    }
    return v.toString();
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.6 + 0.4 * _ctrl.value),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
