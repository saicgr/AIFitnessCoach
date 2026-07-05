/// "How did I do?" — a per-exercise AI critique surfaced DURING the workout
/// once the user has logged ≥1 working set on the current exercise. It POSTs
/// the just-logged sets to `/feedback/exercise-critique` and renders a short,
/// honest markdown critique (load vs target, rep trend, RIR, one concrete cue).
///
/// Two pieces:
///   • [HowDidIDoPill] — the accent pill button (used in the Easy view + as a
///     builder; Advanced surfaces it as an action chip that calls the sheet).
///   • [showHowDidIDoSheet] — opens the critique sheet. The CALLER prepares the
///     `sets` list in **kg** so unit-correctness lives where the data semantics
///     are known (the active-workout state), not in this presentational sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/simple_markdown_text.dart';

/// Accent pill: "✨ How did I do?". Fully tappable.
class HowDidIDoPill extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  const HowDidIDoPill({
    super.key,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.tap();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: compact ? 13 : 15, color: accent),
            const SizedBox(width: 6),
            Text(
              'How did I do?',
              style: ZType.lbl(
                compact ? 11 : 12,
                color: accent,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Open the critique sheet. [sets] entries should each carry kg-based numbers:
/// `{weight_kg, reps, rir?, duration_seconds?, set_type?}`.
Future<void> showHowDidIDoSheet(
  BuildContext context, {
  required String exerciseName,
  String? exerciseId,
  required List<Map<String, dynamic>> sets,
  Map<String, dynamic>? target,
  required bool useKg,
}) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: true,
      child: _HowDidIDoContent(
        exerciseName: exerciseName,
        exerciseId: exerciseId,
        sets: sets,
        target: target,
        useKg: useKg,
      ),
    ),
  );
}

class _HowDidIDoContent extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? exerciseId;
  final List<Map<String, dynamic>> sets;
  final Map<String, dynamic>? target;
  final bool useKg;

  const _HowDidIDoContent({
    required this.exerciseName,
    required this.exerciseId,
    required this.sets,
    required this.target,
    required this.useKg,
  });

  @override
  ConsumerState<_HowDidIDoContent> createState() => _HowDidIDoContentState();
}

class _HowDidIDoContentState extends ConsumerState<_HowDidIDoContent> {
  bool _loading = true;
  String? _markdown;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await ref
          .read(apiClientProvider)
          .post(
            '/feedback/exercise-critique',
            data: {
              'exercise_name': widget.exerciseName,
              'exercise_id': widget.exerciseId,
              'target': widget.target,
              'sets': widget.sets,
              'use_kg': widget.useKg,
            },
          );
      final data = res.data;
      final md = (data is Map) ? data['critique_markdown'] as String? : null;
      if (!mounted) return;
      if (md == null || md.trim().isEmpty) {
        setState(() {
          _loading = false;
          _error = true;
        });
        return;
      }
      setState(() {
        _markdown = md;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ [HowDidIDo] critique failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How did I do · ${widget.exerciseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(13, color: c.textMuted, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const _CritiqueSkeleton()
          else if (_error)
            _ErrorState(
              onRetry: _fetch,
              color: c.accent,
              textColor: c.textSecondary,
            )
          else
            SimpleMarkdownText(_markdown ?? ''),
        ],
      ),
      ),
    );
  }
}

class _CritiqueSkeleton extends StatelessWidget {
  const _CritiqueSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    Widget bar(double w) => Container(
      width: w,
      height: 12,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.textMuted.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(220), bar(double.infinity), bar(180), bar(200)],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final Color color;
  final Color textColor;
  const _ErrorState({
    required this.onRetry,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Couldn't get your critique just now.",
          style: TextStyle(fontSize: 14, color: textColor),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: Icon(Icons.refresh_rounded, size: 18, color: color),
          label: Text('Try again', style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
