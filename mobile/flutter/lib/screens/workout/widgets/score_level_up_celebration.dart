// Strength-Score LEVEL-UP celebration (B6, vs Gravl).
//
// Self-contained card shown on the workout-complete screen when the just-
// finished workout pushed a muscle's (or the overall) strength score across a
// level threshold. Fetches GET /api/v1/scores/recent-level-ups in its own
// initState, fires confetti + a spring-in animation on a crossing, and
// collapses to `SizedBox.shrink()` when there's nothing to celebrate.
//
// Owns its own ConfettiController + fetch so the parent workout-complete
// screen needs no new state — it just drops this widget into its column.

import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/services/api_client.dart';

class ScoreLevelUpCelebration extends ConsumerStatefulWidget {
  /// Lowercased muscle names trained in this workout. The fetch is unfiltered
  /// (server scopes by recency), but this lets us prioritize the headline to a
  /// muscle the user actually trained when several crossed at once.
  final Set<String> trainedMuscles;

  const ScoreLevelUpCelebration({
    super.key,
    this.trainedMuscles = const {},
  });

  @override
  ConsumerState<ScoreLevelUpCelebration> createState() =>
      _ScoreLevelUpCelebrationState();
}

class _ScoreLevelUpCelebrationState
    extends ConsumerState<ScoreLevelUpCelebration> {
  late final ConfettiController _confetti;
  List<Map<String, dynamic>> _muscleLevelUps = const [];
  Map<String, dynamic>? _overallLevelUp;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1400));
    _fetch();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get<dynamic>('/scores/recent-level-ups');
      if (!mounted) return;
      if (resp.statusCode == 200 && resp.data is Map) {
        final map = Map<String, dynamic>.from(resp.data as Map);
        final muscles = (map['muscle_level_ups'] as List?)
                ?.whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList() ??
            const <Map<String, dynamic>>[];
        // Prioritize a muscle trained in THIS workout for the headline.
        if (widget.trainedMuscles.isNotEmpty && muscles.length > 1) {
          muscles.sort((a, b) {
            final aTrained = widget.trainedMuscles
                .contains((a['muscle_group'] as String?)?.toLowerCase());
            final bTrained = widget.trainedMuscles
                .contains((b['muscle_group'] as String?)?.toLowerCase());
            if (aTrained == bTrained) return 0;
            return aTrained ? -1 : 1;
          });
        }
        final overall = map['overall_level_up'];
        setState(() {
          _muscleLevelUps = muscles;
          _overallLevelUp =
              overall is Map ? Map<String, dynamic>.from(overall) : null;
          _loaded = true;
        });
        if (_muscleLevelUps.isNotEmpty || _overallLevelUp != null) {
          _confetti.play();
          HapticService.instance.success();
        }
      } else {
        setState(() => _loaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    if (_muscleLevelUps.isEmpty && _overallLevelUp == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Headline: overall level-up wins, else the strongest muscle crossing.
    final String headline;
    final String subline;
    if (_overallLevelUp != null) {
      final lvl = _titleCase(_overallLevelUp!['new_level'] as String? ?? '');
      headline = 'Level Up! You\'re now $lvl';
      subline = _muscleLevelUps.isNotEmpty
          ? '${_muscleLevelUps.length} muscle${_muscleLevelUps.length == 1 ? '' : 's'} also leveled up'
          : 'Your overall fitness score crossed a new tier';
    } else {
      final top = _muscleLevelUps.first;
      final muscle = _titleCase(top['muscle_group'] as String? ?? 'Muscle');
      final lvl = _titleCase(top['new_level'] as String? ?? '');
      headline = '$muscle Level Up — $lvl!';
      subline = _muscleLevelUps.length > 1
          ? '${_muscleLevelUps.length} muscles crossed a new strength tier'
          : 'Your $muscle strength score crossed a new tier';
    }

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.28 : 0.18),
            AppColors.purple.withValues(alpha: isDark ? 0.18 : 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: Colors.white, size: 26),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 700.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [accent, AppColors.purple],
                  ).createShader(b),
                  child: Text(
                    headline,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subline,
                  style: TextStyle(fontSize: 12.5, color: textSecondary),
                ),
                if (_muscleLevelUps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final lu in _muscleLevelUps.take(5))
                        _MuscleLevelChip(
                          muscle: _titleCase(
                              lu['muscle_group'] as String? ?? ''),
                          newLevel:
                              _titleCase(lu['new_level'] as String? ?? ''),
                          accent: accent,
                          textPrimary: textPrimary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      // Carry our own bottom gap so the parent doesn't add a stray space when
      // this collapses to SizedBox.shrink() (no level-up).
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          card
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                duration: 420.ms,
                curve: Curves.elasticOut,
              ),
          Positioned(
            top: -6,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2, // downward
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 18,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
              colors: [
                accent,
                AppColors.purple,
                AppColors.orange,
                Colors.white
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleLevelChip extends StatelessWidget {
  final String muscle;
  final String newLevel;
  final Color accent;
  final Color textPrimary;

  const _MuscleLevelChip({
    required this.muscle,
    required this.newLevel,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            '$muscle · $newLevel',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
