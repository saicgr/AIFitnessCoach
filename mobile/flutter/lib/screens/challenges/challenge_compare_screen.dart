import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../data/services/challenges_service.dart';

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
    final textColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Challenge Results',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDark)
              : _buildComparison(context, isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load challenge',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadChallenge,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.orange,
            ),
          ),

          const SizedBox(height: 20),

          // Overall Stats
          _buildSectionHeader('Overall', Icons.analytics_outlined, textColor),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildComparisonRow(
                  emoji: '⏱️',
                  label: 'Time',
                  valueA: challengerStats['duration_minutes'],
                  valueB: challengedStats['duration_minutes'],
                  formatFn: (v) => '${v} min',
                  lowerIsBetter: true,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),
                _buildComparisonRow(
                  emoji: '💪',
                  label: 'Volume',
                  valueA: challengerStats['total_volume'],
                  valueB: challengedStats['total_volume'],
                  formatFn: (v) => _formatVolume(v),
                  lowerIsBetter: false,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),
                _buildComparisonRow(
                  emoji: '📊',
                  label: 'Sets',
                  valueA: challengerStats['total_sets'],
                  valueB: challengedStats['total_sets'],
                  formatFn: (v) => '$v',
                  lowerIsBetter: false,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 16),
                _buildComparisonRow(
                  emoji: '🔄',
                  label: 'Reps',
                  valueA: challengerStats['total_reps'],
                  valueB: challengedStats['total_reps'],
                  formatFn: (v) => '$v',
                  lowerIsBetter: false,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),

          // Exercise Breakdown
          if (challengerExercises.isNotEmpty ||
              challengedExercises.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader(
                'Exercise Breakdown', Icons.list_rounded, textColor),
            const SizedBox(height: 12),
            _buildExerciseBreakdown(
              challengerExercises: challengerExercises,
              challengedExercises: challengedExercises,
              isDark: isDark,
              elevated: elevated,
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
    required String challengerName,
    required String? challengerAvatar,
    required String challengedName,
    required String? challengedAvatar,
    required bool didBeat,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: didBeat
              ? [
                  Colors.green.withValues(alpha: 0.1),
                  AppColors.cyan.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.orange.withValues(alpha: 0.1),
                  AppColors.orange.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (didBeat ? Colors.green : AppColors.orange)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Challenger (UserA)
          Expanded(
            child: _buildUserColumn(
              name: challengerName,
              avatarUrl: challengerAvatar,
              isWinner: !didBeat,
            ),
          ),

          // VS badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: elevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ),
          ),

          // Challenged (UserB)
          Expanded(
            child: _buildUserColumn(
              name: challengedName,
              avatarUrl: challengedAvatar,
              isWinner: didBeat,
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
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
            color: isWinner ? Colors.green : null,
          ),
        ),
        if (isWinner)
          const Text(
            'WINNER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
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

    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ),
        // UserA value
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valueA != null ? formatFn(valueA) : '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: aWins ? FontWeight.bold : FontWeight.w500,
                  color: aWins ? Colors.green : textColor,
                ),
              ),
              if (aWins) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
              ],
            ],
          ),
        ),
        Text(
          'vs',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        // UserB value
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                valueB != null ? formatFn(valueB) : '-',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bWins ? FontWeight.bold : FontWeight.w500,
                  color: bWins ? Colors.green : textColor,
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
    );
  }

  Widget _buildExerciseBreakdown({
    required List<dynamic> challengerExercises,
    required List<dynamic> challengedExercises,
    required bool isDark,
    required Color elevated,
    required Color cardBorder,
    required Color textColor,
    required Color textMuted,
  }) {
    // Build a combined list using challenger exercises as base
    final maxLen = challengerExercises.length > challengedExercises.length
        ? challengerExercises.length
        : challengedExercises.length;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: maxLen,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: cardBorder.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
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
          final aWins = weightA != null &&
              weightB != null &&
              weightA > weightB;
          final bWins = weightA != null &&
              weightB != null &&
              weightB > weightA;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            strA,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  aWins ? FontWeight.bold : FontWeight.w400,
                              color: aWins ? Colors.green : textMuted,
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
                    Text('vs', style: TextStyle(fontSize: 11, color: textMuted)),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            strB,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  bWins ? FontWeight.bold : FontWeight.w400,
                              color: bWins ? Colors.green : textMuted,
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
        },
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Map<String, dynamic> data, bool isDark) {
    return Row(
      children: [
        // Rematch button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sendRematch(data),
            icon: const Icon(Icons.replay_rounded, size: 20),
            label: const Text(
              'REMATCH',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
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
              context.push('/social');
            },
            icon: Icon(
              Icons.feed_rounded,
              size: 20,
              color: isDark ? AppColors.cyan : AppColorsLight.textPrimary,
            ),
            label: Text(
              'View Feed',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.cyan : AppColorsLight.textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: (isDark ? AppColors.cyan : AppColorsLight.textPrimary)
                    .withValues(alpha: 0.5),
              ),
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
          const SnackBar(
            content: Text('Rematch sent!'),
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
      return '${(v / 1000).toStringAsFixed(1)}K lbs';
    }
    return '${v.toStringAsFixed(0)} lbs';
  }
}
