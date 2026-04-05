part of 'activity_card.dart';


/// Mini leaderboard widget shown on challenge_victory / challenge_completed activity cards.
/// Fetches data lazily and only shows if there are 2+ entries.
class _ChallengeLeaderboard extends StatefulWidget {
  final String activityId;

  const _ChallengeLeaderboard({required this.activityId});

  @override
  State<_ChallengeLeaderboard> createState() => _ChallengeLeaderboardState();
}


class _ChallengeLeaderboardState extends State<_ChallengeLeaderboard> {
  List<Map<String, dynamic>>? _entries;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );
      final service = ChallengesService(ApiClient(storage));
      final entries = await service.getActivityLeaderboard(activityId: widget.activityId);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ChallengeLeaderboard] Error: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_error || _entries == null || _entries!.length < 2) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_rounded, size: 16, color: AppColors.orange),
                const SizedBox(width: 6),
                Text(
                  'Leaderboard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._entries!.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final name = data['user_name'] as String? ?? 'Unknown';
              final didBeat = data['did_beat'] as bool? ?? false;
              final duration = data['duration_minutes'];
              final volume = data['total_volume'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Position
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: index == 0 ? const Color(0xFFFFD700) : AppColors.textMuted,
                        ),
                      ),
                    ),
                    // Name
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Beat indicator
                    if (didBeat)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle, size: 14, color: Colors.green),
                      ),
                    // Stats
                    if (duration != null)
                      Text(
                        '${duration}m',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (duration != null && volume != null)
                      Text(
                        ' | ',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    if (volume != null)
                      Text(
                        '${volume is double ? volume.toStringAsFixed(0) : volume} lbs',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

