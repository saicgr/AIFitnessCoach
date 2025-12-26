import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/social_provider.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// Provider for social privacy settings state
final socialPrivacySettingsProvider = StateNotifierProvider<SocialPrivacySettingsNotifier, SocialPrivacyState>((ref) {
  return SocialPrivacySettingsNotifier(ref);
});

/// State class for social privacy settings
class SocialPrivacyState {
  final bool isLoading;
  final bool requireFollowApproval;
  final bool allowFriendRequests;
  final bool allowChallengeInvites;
  final bool showOnLeaderboards;
  final bool notifyFriendRequests;
  final bool notifyReactions;
  final bool notifyComments;
  final bool notifyChallengeInvites;
  final bool notifyFriendActivity;
  final String? error;

  const SocialPrivacyState({
    this.isLoading = true,
    this.requireFollowApproval = false,
    this.allowFriendRequests = true,
    this.allowChallengeInvites = true,
    this.showOnLeaderboards = true,
    this.notifyFriendRequests = true,
    this.notifyReactions = true,
    this.notifyComments = true,
    this.notifyChallengeInvites = true,
    this.notifyFriendActivity = true,
    this.error,
  });

  SocialPrivacyState copyWith({
    bool? isLoading,
    bool? requireFollowApproval,
    bool? allowFriendRequests,
    bool? allowChallengeInvites,
    bool? showOnLeaderboards,
    bool? notifyFriendRequests,
    bool? notifyReactions,
    bool? notifyComments,
    bool? notifyChallengeInvites,
    bool? notifyFriendActivity,
    String? error,
  }) {
    return SocialPrivacyState(
      isLoading: isLoading ?? this.isLoading,
      requireFollowApproval: requireFollowApproval ?? this.requireFollowApproval,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowChallengeInvites: allowChallengeInvites ?? this.allowChallengeInvites,
      showOnLeaderboards: showOnLeaderboards ?? this.showOnLeaderboards,
      notifyFriendRequests: notifyFriendRequests ?? this.notifyFriendRequests,
      notifyReactions: notifyReactions ?? this.notifyReactions,
      notifyComments: notifyComments ?? this.notifyComments,
      notifyChallengeInvites: notifyChallengeInvites ?? this.notifyChallengeInvites,
      notifyFriendActivity: notifyFriendActivity ?? this.notifyFriendActivity,
      error: error,
    );
  }
}

/// State notifier for social privacy settings
class SocialPrivacySettingsNotifier extends StateNotifier<SocialPrivacyState> {
  final Ref _ref;
  String? _userId;

  SocialPrivacySettingsNotifier(this._ref) : super(const SocialPrivacyState()) {
    _init();
  }

  Future<void> _init() async {
    final apiClient = _ref.read(apiClientProvider);
    _userId = await apiClient.getUserId();
    if (_userId != null) {
      await _loadSettings();
    } else {
      state = state.copyWith(isLoading: false, error: 'User not logged in');
    }
  }

  Future<void> _loadSettings() async {
    if (_userId == null) {
      state = state.copyWith(isLoading: false, error: 'User not logged in');
      return;
    }

    try {
      final socialService = _ref.read(socialServiceProvider);
      final settings = await socialService.getSocialPrivacySettings(userId: _userId!);
      state = SocialPrivacyState(
        isLoading: false,
        requireFollowApproval: settings['require_follow_approval'] as bool? ?? false,
        allowFriendRequests: settings['allow_friend_requests'] as bool? ?? true,
        allowChallengeInvites: settings['allow_challenge_invites'] as bool? ?? true,
        showOnLeaderboards: settings['show_on_leaderboards'] as bool? ?? true,
        notifyFriendRequests: settings['notify_friend_requests'] as bool? ?? true,
        notifyReactions: settings['notify_reactions'] as bool? ?? true,
        notifyComments: settings['notify_comments'] as bool? ?? true,
        notifyChallengeInvites: settings['notify_challenge_invites'] as bool? ?? true,
        notifyFriendActivity: settings['notify_friend_activity'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('Error loading social settings: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    if (_userId == null) return;

    try {
      final socialService = _ref.read(socialServiceProvider);
      await socialService.updateSocialPrivacySettings(
        userId: _userId!,
        notifyFriendRequests: updates['notify_friend_requests'] as bool?,
        notifyReactions: updates['notify_reactions'] as bool?,
        notifyComments: updates['notify_comments'] as bool?,
        notifyChallengeInvites: updates['notify_challenge_invites'] as bool?,
        notifyFriendActivity: updates['notify_friend_activity'] as bool?,
        requireFollowApproval: updates['require_follow_approval'] as bool?,
      );
    } catch (e) {
      debugPrint('Error updating social settings: $e');
    }
  }

  void setRequireFollowApproval(bool value) {
    state = state.copyWith(requireFollowApproval: value);
    _updateSettings({'require_follow_approval': value});
  }

  void setAllowFriendRequests(bool value) {
    state = state.copyWith(allowFriendRequests: value);
    _updateSettings({'allow_friend_requests': value});
  }

  void setAllowChallengeInvites(bool value) {
    state = state.copyWith(allowChallengeInvites: value);
    _updateSettings({'allow_challenge_invites': value});
  }

  void setShowOnLeaderboards(bool value) {
    state = state.copyWith(showOnLeaderboards: value);
    _updateSettings({'show_on_leaderboards': value});
  }

  void setNotifyFriendRequests(bool value) {
    state = state.copyWith(notifyFriendRequests: value);
    _updateSettings({'notify_friend_requests': value});
  }

  void setNotifyReactions(bool value) {
    state = state.copyWith(notifyReactions: value);
    _updateSettings({'notify_reactions': value});
  }

  void setNotifyComments(bool value) {
    state = state.copyWith(notifyComments: value);
    _updateSettings({'notify_comments': value});
  }

  void setNotifyChallengeInvites(bool value) {
    state = state.copyWith(notifyChallengeInvites: value);
    _updateSettings({'notify_challenge_invites': value});
  }

  void setNotifyFriendActivity(bool value) {
    state = state.copyWith(notifyFriendActivity: value);
    _updateSettings({'notify_friend_activity': value});
  }
}

/// The social privacy section for configuring social and privacy settings.
///
/// Allows users to control who can follow them, send friend requests,
/// and which social notifications to receive.
class SocialPrivacySection extends StatelessWidget {
  const SocialPrivacySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'SOCIAL & PRIVACY'),
        SizedBox(height: 12),
        _SocialPrivacyCard(),
      ],
    );
  }
}

class _SocialPrivacyCard extends ConsumerWidget {
  const _SocialPrivacyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final socialSettings = ref.watch(socialPrivacySettingsProvider);

    if (socialSettings.isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy Settings Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Private Account Toggle
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.shield_outlined,
            iconColor: AppColors.purple,
            title: 'Private Account',
            subtitle: 'Require approval for follow requests',
            value: socialSettings.requireFollowApproval,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setRequireFollowApproval(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Allow Friend Requests
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.person_add_outlined,
            iconColor: AppColors.cyan,
            title: 'Allow Friend Requests',
            subtitle: 'Let others send you friend requests',
            value: socialSettings.allowFriendRequests,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setAllowFriendRequests(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Allow Challenge Invites
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.orange,
            title: 'Allow Challenge Invites',
            subtitle: 'Let others invite you to challenges',
            value: socialSettings.allowChallengeInvites,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setAllowChallengeInvites(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Show on Leaderboards
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.leaderboard_outlined,
            iconColor: AppColors.success,
            title: 'Show on Leaderboards',
            subtitle: 'Appear in public and friend leaderboards',
            value: socialSettings.showOnLeaderboards,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setShowOnLeaderboards(value);
            },
            textMuted: textMuted,
          ),

          const SizedBox(height: 16),

          // Social Notifications Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Social Notifications',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Notify Friend Requests
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.person_add_alt_1_rounded,
            iconColor: AppColors.cyan,
            title: 'Friend Requests',
            subtitle: 'When someone sends you a friend request',
            value: socialSettings.notifyFriendRequests,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setNotifyFriendRequests(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Notify Reactions
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.favorite_outline,
            iconColor: AppColors.pink,
            title: 'Reactions',
            subtitle: 'When someone reacts to your posts',
            value: socialSettings.notifyReactions,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setNotifyReactions(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Notify Comments
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.purple,
            title: 'Comments',
            subtitle: 'When someone comments on your posts',
            value: socialSettings.notifyComments,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setNotifyComments(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Notify Challenge Invites
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.sports_score_rounded,
            iconColor: AppColors.orange,
            title: 'Challenge Invites',
            subtitle: 'When someone invites you to a challenge',
            value: socialSettings.notifyChallengeInvites,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setNotifyChallengeInvites(value);
            },
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder.withValues(alpha: 0.3), indent: 50),

          // Notify Friend Activity
          _buildPrivacyToggle(
            context: context,
            ref: ref,
            icon: Icons.directions_run_rounded,
            iconColor: AppColors.success,
            title: 'Friend Activity',
            subtitle: 'When friends complete workouts or hit milestones',
            value: socialSettings.notifyFriendActivity,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              ref.read(socialPrivacySettingsProvider.notifier).setNotifyFriendActivity(value);
            },
            textMuted: textMuted,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textMuted,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: value ? iconColor : textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.cyan.withValues(alpha: 0.5),
            activeThumbColor: AppColors.cyan,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
