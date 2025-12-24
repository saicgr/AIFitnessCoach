import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/challenges_service.dart';
import '../../data/api_client.dart';
import '../challenges/widgets/challenge_friends_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Challenge History Screen - Shows all challenges with outcomes and retry options
class ChallengeHistoryScreen extends ConsumerStatefulWidget {
  final String userId;

  const ChallengeHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ChallengeHistoryScreen> createState() => _ChallengeHistoryScreenState();
}

class _ChallengeHistoryScreenState extends ConsumerState<ChallengeHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChallengesService _challengesService;

  List<Map<String, dynamic>> _allChallenges = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _challengesService = ChallengesService(ref.read(apiClientProvider));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load both received and sent challenges
      final receivedResponse = await _challengesService.getReceivedChallenges(
        userId: widget.userId,
        status: null, // Get all statuses
      );

      final sentResponse = await _challengesService.getSentChallenges(
        userId: widget.userId,
        status: null,
      );

      // Load stats
      final statsResponse = await _challengesService.getChallengeStats(
        userId: widget.userId,
      );

      setState(() {
        // Combine received and sent, marking which is which
        _allChallenges = [
          ...((receivedResponse['challenges'] as List?) ?? []).map((c) => {
                ...c as Map<String, dynamic>,
                'direction': 'received',
              }),
          ...((sentResponse['challenges'] as List?) ?? []).map((c) => {
                ...c as Map<String, dynamic>,
                'direction': 'sent',
              }),
        ];

        // Sort by most recent first
        _allChallenges.sort((a, b) {
          final aDate = DateTime.parse(a['created_at'] as String);
          final bDate = DateTime.parse(b['created_at'] as String);
          return bDate.compareTo(aDate);
        });

        _stats = statsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ [ChallengeHistory] Error loading data: $e');
    }
  }

  List<Map<String, dynamic>> _filterChallenges(int tabIndex) {
    switch (tabIndex) {
      case 0: // All
        return _allChallenges;
      case 1: // Won
        return _allChallenges.where((c) {
          return c['status'] == 'completed' &&
              c['did_beat'] == true &&
              c['direction'] == 'received';
        }).toList();
      case 2: // Lost
        return _allChallenges.where((c) {
          return c['status'] == 'completed' &&
              c['did_beat'] == false &&
              c['direction'] == 'received';
        }).toList();
      case 3: // Abandoned
        return _allChallenges.where((c) {
          return c['status'] == 'abandoned';
        }).toList();
      case 4: // Pending
        return _allChallenges.where((c) {
          return c['status'] == 'pending' || c['status'] == 'accepted';
        }).toList();
      default:
        return _allChallenges;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Challenge History'),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      // Stats overview
                      if (_stats != null) _buildStatsOverview(isDark),

                      // Tabs
                      Container(
                        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: AppColors.cyan,
                          labelColor: AppColors.cyan,
                          unselectedLabelColor: AppColors.textMuted,
                          tabs: [
                            _buildTab('All', _allChallenges.length),
                            _buildTab('Won', _stats?['challenges_won'] ?? 0),
                            _buildTab('Lost', _stats?['challenges_lost'] ?? 0),
                            _buildTab('Quit', _getAbandonedCount()),
                            _buildTab('Pending', _getPendingCount()),
                          ],
                        ),
                      ),

                      // Challenge list
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: List.generate(5, (index) {
                            final challenges = _filterChallenges(index);
                            return _buildChallengeList(challenges, index);
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(bool isDark) {
    final wonCount = _stats?['challenges_won'] ?? 0;
    final lostCount = _stats?['challenges_lost'] ?? 0;
    final totalCompleted = wonCount + lostCount;
    final winRate = totalCompleted > 0 ? (wonCount / totalCompleted * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.1),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.cyan, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Challenge Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Won', wonCount, Colors.green),
              _buildStatDivider(),
              _buildStatColumn('Lost', lostCount, Colors.red),
              _buildStatDivider(),
              _buildStatColumn('Win Rate', '${winRate.toStringAsFixed(0)}%', AppColors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.cardBorder.withValues(alpha: 0.3),
    );
  }

  Widget _buildChallengeList(List<Map<String, dynamic>> challenges, int tabIndex) {
    if (challenges.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final status = challenge['status'] as String;
    final direction = challenge['direction'] as String;
    final isReceived = direction == 'received';

    // Determine opponent
    final opponentName = isReceived
        ? (challenge['from_user_name'] ?? 'Someone')
        : (challenge['to_user_name'] ?? 'Someone');
    final opponentAvatar = isReceived
        ? challenge['from_user_avatar']
        : challenge['to_user_avatar'];

    final workoutName = challenge['workout_name'] ?? 'Unknown Workout';
    final createdAt = DateTime.parse(challenge['created_at'] as String);

    // Determine result
    String resultText = '';
    Color resultColor = AppColors.textMuted;
    IconData resultIcon = Icons.schedule;

    if (status == 'completed') {
      final didBeat = challenge['did_beat'] == true;
      if (isReceived) {
        if (didBeat) {
          resultText = 'VICTORY!';
          resultColor = Colors.green;
          resultIcon = Icons.emoji_events;
        } else {
          resultText = 'Failed to beat';
          resultColor = Colors.red;
          resultIcon = Icons.close;
        }
      } else {
        // Sent challenges
        if (didBeat) {
          resultText = 'They won';
          resultColor = Colors.orange;
          resultIcon = Icons.person;
        } else {
          resultText = 'They failed';
          resultColor = Colors.green;
          resultIcon = Icons.check;
        }
      }
    } else if (status == 'abandoned') {
      resultText = 'QUIT';
      resultColor = Colors.red;
      resultIcon = Icons.flag;
    } else if (status == 'accepted') {
      resultText = 'In Progress';
      resultColor = AppColors.orange;
      resultIcon = Icons.fitness_center;
    } else if (status == 'pending') {
      resultText = 'Pending';
      resultColor = AppColors.textMuted;
      resultIcon = Icons.schedule;
    }

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Opponent avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                  backgroundImage: opponentAvatar != null ? NetworkImage(opponentAvatar) : null,
                  child: opponentAvatar == null
                      ? Text(
                          opponentName[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            opponentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isReceived ? Icons.arrow_forward : Icons.arrow_back,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isReceived ? 'You' : 'Them',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Result badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: resultColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(resultIcon, size: 14, color: resultColor),
                      const SizedBox(width: 4),
                      Text(
                        resultText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: resultColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3)),

          // Workout info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workoutName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                // Stats comparison (if completed)
                if (status == 'completed') ...[
                  const SizedBox(height: 12),
                  _buildStatsComparison(challenge, isReceived),
                ],

                // Quit reason (if abandoned)
                if (status == 'abandoned' && challenge['quit_reason'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🐔', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            challenge['quit_reason'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Retry button (if failed or abandoned, and received)
                if (isReceived && (status == 'completed' || status == 'abandoned')) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _retryChallenge(challenge),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry Challenge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.orange,
                        side: BorderSide(color: AppColors.orange.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsComparison(Map<String, dynamic> challenge, bool isReceived) {
    final workoutData = challenge['workout_data'] as Map<String, dynamic>?;
    final challengedStats = challenge['challenged_stats'] as Map<String, dynamic>?;
    final didBeat = challenge['did_beat'] == true;

    if (workoutData == null || challengedStats == null) return const SizedBox.shrink();

    final targetDuration = workoutData['duration_minutes'];
    final targetVolume = workoutData['total_volume'];
    final yourDuration = challengedStats['duration_minutes'];
    final yourVolume = challengedStats['total_volume'];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: didBeat
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (targetDuration != null && yourDuration != null)
            _buildStatRow('⏱️', 'Time', '$yourDuration min', '$targetDuration min', yourDuration <= targetDuration),
          if (targetDuration != null && yourDuration != null && targetVolume != null && yourVolume != null)
            const SizedBox(height: 8),
          if (targetVolume != null && yourVolume != null)
            _buildStatRow('💪', 'Volume', '${yourVolume.toStringAsFixed(0)} lbs', '${targetVolume.toStringAsFixed(0)} lbs', yourVolume >= targetVolume),
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, String yourValue, String targetValue, bool youWon) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'You: ',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    yourValue,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: youWon ? Colors.green : Colors.red,
                    ),
                  ),
                  if (youWon) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 12, color: Colors.green),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    'Target: ',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    targetValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String message;
    IconData icon;

    switch (tabIndex) {
      case 1: // Won
        message = 'No victories yet. Accept challenges and crush them! 💪';
        icon = Icons.emoji_events;
        break;
      case 2: // Lost
        message = 'You haven\'t lost any challenges! Keep it up! 🔥';
        icon = Icons.celebration;
        break;
      case 3: // Abandoned
        message = 'No abandoned challenges. You\'re committed! 💯';
        icon = Icons.check_circle;
        break;
      case 4: // Pending
        message = 'No pending challenges. Challenge your friends!';
        icon = Icons.people;
        break;
      default:
        message = 'No challenges yet. Start competing with friends!';
        icon = Icons.fitness_center;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load challenges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retryChallenge(Map<String, dynamic> challenge) {
    HapticFeedback.mediumImpact();

    final challengeId = challenge['id'] as String;
    final fromUserId = challenge['from_user_id'] as String;
    final workoutName = challenge['workout_name'] as String;
    final workoutData = challenge['workout_data'] as Map<String, dynamic>;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => _RetryConfirmationDialog(
        challengerName: challenge['from_user_name'] ?? 'them',
        workoutName: workoutName,
        workoutData: workoutData,
        onConfirm: () async {
          Navigator.pop(context);

          // Create retry challenge (reverse direction: you challenge them back)
          try {
            await _challengesService.sendChallenges(
              userId: widget.userId,
              toUserIds: [fromUserId],  // Challenge the original challenger
              workoutName: workoutName,
              workoutData: workoutData,
              isRetry: true,  // Mark as retry
              retriedFromChallengeId: challengeId,  // Reference original challenge
              challengeMessage: 'Round 2! 💪',  // Optional retry message
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔥 Retry challenge sent! Time for redemption!'),
                backgroundColor: AppColors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Refresh challenges list
            _loadChallenges();
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send retry: $e'),
                backgroundColor: AppColors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  int _getAbandonedCount() {
    return _allChallenges.where((c) => c['status'] == 'abandoned').length;
  }

  int _getPendingCount() {
    return _allChallenges.where((c) =>
        c['status'] == 'pending' || c['status'] == 'accepted').length;
  }
}

/// Retry Confirmation Dialog
class _RetryConfirmationDialog extends StatelessWidget {
  final String challengerName;
  final String workoutName;
  final Map<String, dynamic> workoutData;
  final VoidCallback onConfirm;

  const _RetryConfirmationDialog({
    required this.challengerName,
    required this.workoutName,
    required this.workoutData,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final duration = workoutData['duration_minutes'];
    final volume = workoutData['total_volume'];

    return Dialog(
      backgroundColor: elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'RETRY CHALLENGE?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  const TextSpan(text: 'Ready to take on '),
                  TextSpan(
                    text: '$challengerName\'s',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: workoutName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                  const TextSpan(text: ' again?'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Target stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (duration != null)
                    _buildTargetStat('⏱️', 'Time to Beat', '$duration min'),
                  if (duration != null && volume != null)
                    const SizedBox(height: 8),
                  if (volume != null)
                    _buildTargetStat('💪', 'Volume to Beat', '${volume.toStringAsFixed(0)} lbs'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    child: const Text('Let\'s Go! 💪'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetStat(String emoji, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }
}
