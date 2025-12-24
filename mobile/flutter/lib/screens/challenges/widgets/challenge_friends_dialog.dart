import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/api_client.dart';

/// Dialog to challenge friends after completing a workout
class ChallengeFriendsDialog extends StatefulWidget {
  final String userId;
  final String workoutLogId;
  final String workoutName;
  final Map<String, dynamic> workoutData;
  final List<Map<String, dynamic>> friends; // List of friends to choose from

  const ChallengeFriendsDialog({
    super.key,
    required this.userId,
    required this.workoutLogId,
    required this.workoutName,
    required this.workoutData,
    required this.friends,
  });

  @override
  State<ChallengeFriendsDialog> createState() => _ChallengeFriendsDialogState();
}

class _ChallengeFriendsDialogState extends State<ChallengeFriendsDialog> {
  final Set<String> _selectedFriendIds = {};
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late final ChallengesService _challengesService;
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _challengesService = ChallengesService(ApiClient());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return widget.friends;
    }
    return widget.friends.where((friend) {
      final name = (friend['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _sendChallenges() async {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _challengesService.sendChallenges(
        userId: widget.userId,
        toUserIds: _selectedFriendIds.toList(),
        workoutName: widget.workoutName,
        workoutData: widget.workoutData,
        workoutLogId: widget.workoutLogId,
        challengeMessage: _messageController.text.isNotEmpty ? _messageController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 Challenge sent to ${_selectedFriendIds.length} friend(s)!'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send challenges: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Dialog(
      backgroundColor: elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Challenge Friends',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workoutName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Stats to beat
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stats to Beat:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (widget.workoutData['duration_minutes'] != null)
                        _buildStatChip('⏱️', '${widget.workoutData['duration_minutes']} min'),
                      if (widget.workoutData['total_volume'] != null)
                        _buildStatChip('💪', '${widget.workoutData['total_volume']} lbs'),
                      if (widget.workoutData['exercises_count'] != null)
                        _buildStatChip('🏋️', '${widget.workoutData['exercises_count']} exercises'),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.background : AppColorsLight.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Friend list
            Expanded(
              child: _filteredFriends.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No friends to challenge' : 'No friends found',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        final friendId = friend['id'] as String;
                        final isSelected = _selectedFriendIds.contains(friendId);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (value == true) {
                                _selectedFriendIds.add(friendId);
                              } else {
                                _selectedFriendIds.remove(friendId);
                              }
                            });
                          },
                          title: Text(
                            friend['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: friend['username'] != null
                              ? Text('@${friend['username']}')
                              : null,
                          secondary: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                            backgroundImage: friend['avatar_url'] != null
                                ? NetworkImage(friend['avatar_url'])
                                : null,
                            child: friend['avatar_url'] == null
                                ? Text(
                                    (friend['name'] as String)[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          activeColor: AppColors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      },
                    ),
            ),

            // Optional trash talk message
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _messageController,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add trash talk message (optional) 💪',
                  filled: true,
                  fillColor: isDark ? AppColors.background : AppColorsLight.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSending ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendChallenges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                        _isSending
                            ? 'Sending...'
                            : 'Send Challenge (${_selectedFriendIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
