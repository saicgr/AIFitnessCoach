import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';

/// Signature-v2 onPrimary ink — text/icon color on the solid orange accent.
const Color _onAccent = Color(0xFF160B03);

/// Full-screen side-by-side comparison of challenge results.
///
/// Shows overall stats (time, volume, sets) and per-exercise breakdown
/// with indicators for who won each metric.
class ChallengeCompareScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeCompareScreen({super.key, required this.challengeId});

  @override
  ConsumerState<ChallengeCompareScreen> createState() =>
      _ChallengeCompareScreenState();
}

class _ChallengeCompareScreenState
    extends ConsumerState<ChallengeCompareScreen> {
  Map<String, dynamic>? _challengeData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(posthogServiceProvider)
          .capture(eventName: 'challenge_compare_viewed');
    });
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final challengesService = ChallengesService(ref.read(apiClientProvider));
      final data =
          await challengesService.getChallenge(challengeId: widget.challengeId);
      if (mounted) {
        setState(() {
          _challengeData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CompareScreen] Error loading challenge: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).challengeCompareChallengeResults,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: orange))
          : _error != null
              ? _buildError(isDark)
              : _buildComparison(context, isDark),
    );
  }

  Widget _buildError(bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).challengeCompareFailedToLoadChallenge,
              textAlign: TextAlign.center,
              style: ZType.sans(16, color: textPrimary, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: ZType.ser(13, color: textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadChallenge,
              icon: const Icon(Icons.refresh, size: 18, color: _onAccent),
              label: Text(
                AppLocalizations.of(context).buttonRetry.toUpperCase(),
                style: ZType.lbl(13, color: _onAccent, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: _onAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(BuildContext context, bool isDark) {
    final data = _challengeData!;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    final didBeat = data['did_beat'] as bool? ?? false;
    final workoutName = data['workout_name'] as String? ?? 'Workout';

    // User info
    final fromUser = data['from_user'] as Map<String, dynamic>? ?? {};
    final toUser = data['to_user'] as Map<String, dynamic>? ?? {};
    final challengerName = fromUser['name'] as String? ?? 'Challenger';
    final challengerAvatar = fromUser['avatar_url'] as String?;
    final challengedName = toUser['name'] as String? ?? 'You';
    final challengedAvatar = toUser['avatar_url'] as String?;

    // Stats
    final challengerStats =
        data['challenger_stats'] as Map<String, dynamic>? ?? {};
    final challengedStats =
        data['challenged_stats'] as Map<String, dynamic>? ?? {};

    // Exercise performances
    final challengerExercises =
        challengerStats['exercises_performance'] as List<dynamic>? ?? [];
    final challengedExercises =
        challengedStats['exercises_performance'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // VS Header
          _buildVsHeader(
            isDark: isDark,
            elevated: elevated,
            cardBorder: cardBorder,
            orange: orange,
            challengerName: challengerName,
            challengerAvatar: challengerAvatar,
            challengedName: challengedName,
            challengedAvatar: challengedAvatar,
            didBeat: didBeat,
          ),

          const SizedBox(height: 20),

          // Workout name
          Text(
            workoutName,
            textAlign: TextAlign.center,
            style: ZType.disp(24, color: orange, letterSpacing: 0.5),
          ),

          const SizedBox(height: 24),

          // Overall Stats
          _buildSectionHeader('Overall', orange),
          const SizedBox(height: 4),
          _StatBlock(
            cardBorder: cardBorder,
            children: [
              _buildComparisonRow(
                emoji: '⏱️',
                label: AppLocalizations.of(context).workoutShowcaseTime,
                valueA: challengerStats['duration_minutes'],
                valueB: challengedStats['duration_minutes'],
                formatFn: (v) => '$v MIN',
                lowerIsBetter: true,
                textColor: textColor,
                textMuted: textMuted,
              ),
              _buildComparisonRow(
                emoji: '💪',
                label:
                    AppLocalizations.of(context).workoutSummaryAdvancedVolume,
                valueA: challengerStats['total_volume'],
                valueB: challengedStats['total_volume'],
                formatFn: (v) => _formatVolume(v),
                lowerIsBetter: false,
                textColor: textColor,
                textMuted: textMuted,
              ),
              _buildComparisonRow(
                emoji: '📊',
                label: AppLocalizations.of(context).workoutSummaryGeneralSets,
                valueA: challengerStats['total_sets'],
                valueB: challengedStats['total_sets'],
                formatFn: (v) => '$v',
                lowerIsBetter: false,
                textColor: textColor,
                textMuted: textMuted,
              ),
              _buildComparisonRow(
                emoji: '🔄',
                label: AppLocalizations.of(context).workoutSummaryGeneralReps,
                valueA: challengerStats['total_reps'],
                valueB: challengedStats['total_reps'],
                formatFn: (v) => '$v',
                lowerIsBetter: false,
                textColor: textColor,
                textMuted: textMuted,
                isLast: true,
              ),
            ],
          ),

          // Exercise Breakdown
          if (challengerExercises.isNotEmpty ||
              challengedExercises.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Exercise Breakdown', orange),
            const SizedBox(height: 4),
            _buildExerciseBreakdown(
              challengerExercises: challengerExercises,
              challengedExercises: challengedExercises,
              isDark: isDark,
              cardBorder: cardBorder,
              textColor: textColor,
              textMuted: textMuted,
            ),
          ],

          const SizedBox(height: 32),

          // Action buttons
          _buildActionButtons(context, data, isDark),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildVsHeader({
    required bool isDark,
    required Color elevated,
    required Color cardBorder,
    required Color orange,
    required String challengerName,
    required String? challengerAvatar,
    required String challengedName,
    required String? challengedAvatar,
    required bool didBeat,
  }) {
    final accent = didBeat ? Colors.green : orange;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Challenger (UserA)
          Expanded(
            child: _buildUserColumn(
              name: challengerName,
              avatarUrl: challengerAvatar,
              isWinner: !didBeat,
              orange: orange,
              isDark: isDark,
            ),
          ),

          // VS badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.pureBlack : AppColorsLight.background,
              shape: BoxShape.circle,
              border: Border.all(color: orange.withValues(alpha: 0.5), width: 2),
            ),
            child: Center(
              child: Text(
                'VS',
                style: ZType.disp(16, color: orange, letterSpacing: 0.5),
              ),
            ),
          ),

          // Challenged (UserB)
          Expanded(
            child: _buildUserColumn(
              name: challengedName,
              avatarUrl: challengedAvatar,
              isWinner: didBeat,
              orange: orange,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserColumn({
    required String name,
    required String? avatarUrl,
    required bool isWinner,
    required Color orange,
    required bool isDark,
  }) {
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: orange.withValues(alpha: 0.15),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: ZType.disp(22, color: orange),
                    )
                  : null,
            ),
            if (isWinner)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.sans(14,
              color: isWinner ? Colors.green : textColor,
              weight: FontWeight.w700),
        ),
        if (isWinner)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              AppLocalizations.of(context).challengeCompareWinner.toUpperCase(),
              style: ZType.lbl(10, color: Colors.green, letterSpacing: 1.6),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color orange) {
    return ZSectionKickerLocal(label: title, color: orange);
  }

  Widget _buildComparisonRow({
    required String emoji,
    required String label,
    required dynamic valueA,
    required dynamic valueB,
    required String Function(dynamic) formatFn,
    required bool lowerIsBetter,
    required Color textColor,
    required Color textMuted,
    bool isLast = false,
  }) {
    final numA = _toDouble(valueA);
    final numB = _toDouble(valueB);
    final hasValues = numA != null && numB != null;

    bool aWins = false;
    bool bWins = false;
    if (hasValues) {
      if (lowerIsBetter) {
        aWins = numA < numB;
        bWins = numB < numA;
      } else {
        aWins = numA > numB;
        bWins = numB > numA;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairline),
              ),
            ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              label.toUpperCase(),
              style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.0),
            ),
          ),
          // UserA value
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    valueA != null ? formatFn(valueA) : '-',
                    textAlign: TextAlign.center,
                    style: ZType.data(13.5,
                        color: aWins ? Colors.green : textColor),
                  ),
                ),
                if (aWins) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                ],
              ],
            ),
          ),
          Text('vs', style: ZType.lbl(10, color: textMuted, letterSpacing: 1.0)),
          // UserB value
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    valueB != null ? formatFn(valueB) : '-',
                    textAlign: TextAlign.center,
                    style: ZType.data(13.5,
                        color: bWins ? Colors.green : textColor),
                  ),
                ),
                if (bWins) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBreakdown({
    required List<dynamic> challengerExercises,
    required List<dynamic> challengedExercises,
    required bool isDark,
    required Color cardBorder,
    required Color textColor,
    required Color textMuted,
  }) {
    // Build a combined list using challenger exercises as base
    final maxLen = challengerExercises.length > challengedExercises.length
        ? challengerExercises.length
        : challengedExercises.length;

    return _StatBlock(
      cardBorder: cardBorder,
      children: List.generate(maxLen, (index) {
        final exA = index < challengerExercises.length
            ? challengerExercises[index] as Map<String, dynamic>
            : null;
        final exB = index < challengedExercises.length
            ? challengedExercises[index] as Map<String, dynamic>
            : null;

        final name = exA?['name'] ?? exB?['name'] ?? 'Exercise ${index + 1}';

        final setsA = exA?['sets'] as int?;
        final repsA = exA?['reps'] as int?;
        final weightA = _toDouble(exA?['weight_kg']);

        final setsB = exB?['sets'] as int?;
        final repsB = exB?['reps'] as int?;
        final weightB = _toDouble(exB?['weight_kg']);

        String formatExercise(int? sets, int? reps, double? weight) {
          final parts = <String>[];
          if (sets != null && reps != null) parts.add('${sets}x$reps');
          if (weight != null && weight > 0) {
            parts.add('@ ${weight.toStringAsFixed(0)}kg');
          }
          return parts.isNotEmpty ? parts.join(' ') : '-';
        }

        final strA = formatExercise(setsA, repsA, weightA);
        final strB = formatExercise(setsB, repsB, weightB);

        // Determine winner by weight (higher is better)
        final aWins =
            weightA != null && weightB != null && weightA > weightB;
        final bWins =
            weightA != null && weightB != null && weightB > weightA;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: index == maxLen - 1
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.hairline),
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name as String,
                style: ZType.sans(14, color: textColor, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            strA,
                            style: ZType.data(12.5,
                                color: aWins ? Colors.green : textMuted),
                          ),
                        ),
                        if (aWins) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              size: 12, color: Colors.green),
                        ],
                      ],
                    ),
                  ),
                  Text('vs',
                      style:
                          ZType.lbl(10, color: textMuted, letterSpacing: 1.0)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            strB,
                            textAlign: TextAlign.end,
                            style: ZType.data(12.5,
                                color: bWins ? Colors.green : textMuted),
                          ),
                        ),
                        if (bWins) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle,
                              size: 12, color: Colors.green),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Map<String, dynamic> data, bool isDark) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    return Row(
      children: [
        // Rematch button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sendRematch(data),
            icon: const Icon(Icons.replay_rounded, size: 20, color: _onAccent),
            label: Text(
              AppLocalizations.of(context).challengeCompareRematch.toUpperCase(),
              style: ZType.lbl(13, color: _onAccent, letterSpacing: 1.2),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: _onAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Share button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go('/social');
            },
            icon: Icon(Icons.feed_rounded, size: 20, color: textPrimary),
            label: Text(
              AppLocalizations.of(context)
                  .challengeCompareViewFeed
                  .toUpperCase(),
              style: ZType.lbl(13, color: textPrimary, letterSpacing: 1.2),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cardBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendRematch(Map<String, dynamic> data) async {
    HapticFeedback.mediumImpact();

    try {
      final challengesService = ChallengesService(ref.read(apiClientProvider));
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      // Determine opponent
      final fromUserId = data['from_user_id'] as String;
      final toUserId = data['to_user_id'] as String;
      final opponentId = userId == toUserId ? fromUserId : toUserId;

      await challengesService.sendChallenges(
        userId: userId,
        toUserIds: [opponentId],
        workoutName: data['workout_name'] as String? ?? 'Workout',
        workoutData: data['workout_data'] as Map<String, dynamic>? ?? {},
        isRetry: true,
        retriedFromChallengeId: widget.challengeId,
        challengeMessage: 'Rematch time!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).challengeCompareRematchSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [CompareScreen] Error sending rematch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send rematch: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _formatVolume(dynamic volume) {
    if (volume == null) return '-';
    final v = _toDouble(volume);
    if (v == null) return '-';
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}K LBS';
    }
    return '${v.toStringAsFixed(0)} LBS';
  }
}

/// A boxed group of comparison rows separated by hairline rules — the
/// signature-v2 alternative to a heavy Material card.
class _StatBlock extends StatelessWidget {
  final List<Widget> children;
  final Color cardBorder;

  const _StatBlock({required this.children, required this.cardBorder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }
}

/// Local Barlow-uppercase section kicker (the screen renders its own headers,
/// not via a rail). Matches the signature `ZSectionKicker` look.
class ZSectionKickerLocal extends StatelessWidget {
  final String label;
  final Color color;

  const ZSectionKickerLocal({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: ZType.lbl(12, color: color, letterSpacing: 2.0),
      ),
    );
  }
}
