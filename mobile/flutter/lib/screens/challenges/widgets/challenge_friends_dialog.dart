import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/services/challenges_service.dart';
import '../../../data/services/api_client.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Signature-v2 onPrimary ink — text/icon color on the solid orange accent.
const Color _onAccent = Color(0xFF160B03);

/// Dialog to challenge friends after completing a workout
class ChallengeFriendsDialog extends ConsumerStatefulWidget {
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
  ConsumerState<ChallengeFriendsDialog> createState() =>
      _ChallengeFriendsDialogState();
}

class _ChallengeFriendsDialogState
    extends ConsumerState<ChallengeFriendsDialog> {
  final Set<String> _selectedFriendIds = {};
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late final ChallengesService _challengesService;
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _challengesService = ChallengesService(ApiClient(storage));
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
        SnackBar(
          content: Text(AppLocalizations.of(context)
              .challengeFriendsPleaseSelectAtLeast),
          backgroundColor: AppColors.error,
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
        challengeMessage: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🏆 Challenge sent to ${_selectedFriendIds.length} friend(s)!'),
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
            backgroundColor: AppColors.error,
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
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Dialog(
      backgroundColor: elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cardBorder),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: orange.withValues(alpha: 0.25)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .challengeFriendsChallengeFriends,
                          style: ZType.disp(22,
                              color: textPrimary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workoutName.toUpperCase(),
                          style:
                              ZType.lbl(12, color: orange, letterSpacing: 1.4),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textMuted),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .challengeFriendsStatsToBeat
                        .toUpperCase(),
                    style:
                        ZType.lbl(11, color: textMuted, letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (widget.workoutData['duration_minutes'] != null)
                        _buildStatChip('⏱️',
                            '${widget.workoutData['duration_minutes']} MIN',
                            orange),
                      if (widget.workoutData['total_volume'] != null)
                        _buildStatChip('💪',
                            '${widget.workoutData['total_volume']} LBS', orange),
                      if (widget.workoutData['exercises_count'] != null)
                        _buildStatChip('🏋️',
                            '${widget.workoutData['exercises_count']} EXERCISES',
                            orange),
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
                style: ZType.sans(14, color: textPrimary, weight: FontWeight.w500),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).groupCreateSearchFriends,
                  hintStyle: ZType.sans(14,
                      color: textMuted, weight: FontWeight.w400),
                  prefixIcon: Icon(Icons.search, size: 20, color: textMuted),
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: orange),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Friend list
            Expanded(
              child: _filteredFriends.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? AppLocalizations.of(context)
                                .challengeFriendsNoFriendsToChallenge
                            : 'No friends found',
                        style: ZType.ser(14, color: textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        final friendId = friend['id'] as String;
                        final isSelected =
                            _selectedFriendIds.contains(friendId);

                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: orange,
                          checkColor: _onAccent,
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
                            style: ZType.sans(15,
                                color: textPrimary, weight: FontWeight.w700),
                          ),
                          subtitle: friend['username'] != null
                              ? Text(
                                  '@${friend['username']}',
                                  style: ZType.sans(12,
                                      color: textMuted,
                                      weight: FontWeight.w400),
                                )
                              : null,
                          secondary: CircleAvatar(
                            radius: 20,
                            backgroundColor: orange.withValues(alpha: 0.15),
                            backgroundImage: friend['avatar_url'] != null
                                ? NetworkImage(friend['avatar_url'])
                                : null,
                            child: friend['avatar_url'] == null
                                ? Text(
                                    (friend['name'] as String)[0]
                                        .toUpperCase(),
                                    style: ZType.disp(16, color: orange),
                                  )
                                : null,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
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
                style:
                    ZType.sans(14, color: textPrimary, weight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)
                      .challengeFriendsAddTrashTalkMessage,
                  hintStyle: ZType.sans(14,
                      color: textMuted, weight: FontWeight.w400),
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: orange),
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
                      onPressed:
                          _isSending ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).buttonCancel.toUpperCase(),
                        style: ZType.lbl(13,
                            color: textPrimary, letterSpacing: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendChallenges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: _onAccent,
                        disabledBackgroundColor:
                            orange.withValues(alpha: 0.5),
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
                                color: _onAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, size: 18, color: _onAccent),
                      label: Text(
                        _isSending
                            ? AppLocalizations.of(context)
                                .challengeFriendsSending
                                .toUpperCase()
                            : 'SEND CHALLENGE (${_selectedFriendIds.length})',
                        style:
                            ZType.lbl(13, color: _onAccent, letterSpacing: 1.2),
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

  Widget _buildStatChip(String emoji, String value, Color orange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            value,
            style: ZType.data(12, color: orange),
          ),
        ],
      ),
    );
  }
}
