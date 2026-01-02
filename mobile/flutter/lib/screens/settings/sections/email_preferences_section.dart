import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/email_preferences_provider.dart';
import '../../../data/repositories/email_preferences_repository.dart';
import '../../../data/services/api_client.dart';
import '../widgets/widgets.dart';

/// The email preferences section for managing email subscription settings.
///
/// Allows users to control what emails they receive from FitWiz.
/// Addresses user review: "Had to give out email and can't find anywhere to unsubscribe."
class EmailPreferencesSection extends StatelessWidget {
  const EmailPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'EMAIL PREFERENCES'),
        SizedBox(height: 12),
        _EmailPreferencesCard(),
      ],
    );
  }
}

class _EmailPreferencesCard extends ConsumerStatefulWidget {
  const _EmailPreferencesCard();

  @override
  ConsumerState<_EmailPreferencesCard> createState() =>
      _EmailPreferencesCardState();
}

class _EmailPreferencesCardState extends ConsumerState<_EmailPreferencesCard> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      await ref.read(emailPreferencesProvider.notifier).initialize(userId);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  Future<void> _updatePreference(
      EmailPreferenceType type, bool enabled) async {
    HapticFeedback.lightImpact();
    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null) {
      await ref.read(emailPreferencesProvider.notifier).updatePreference(
            userId: userId,
            type: type,
            enabled: enabled,
          );
    }
  }

  Future<void> _unsubscribeFromMarketing() async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _UnsubscribeConfirmDialog(),
    );

    if (confirmed == true && mounted) {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId != null) {
        final success = await ref
            .read(emailPreferencesProvider.notifier)
            .unsubscribeFromMarketing(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Unsubscribed from marketing emails'
                    : 'Failed to unsubscribe. Please try again.',
              ),
              backgroundColor: success ? AppColors.success : AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final emailPrefsState = ref.watch(emailPreferencesProvider);
    final prefs = emailPrefsState.preferences;

    // Show loading state
    if (!_isInitialized || emailPrefsState.isLoading && prefs == null) {
      return Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.cyan,
          ),
        ),
      );
    }

    // Show error state
    if (emailPrefsState.error != null && prefs == null) {
      return Container(
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load email preferences',
              style: TextStyle(color: textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initializePreferences,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Description text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Control what emails you receive from FitWiz',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // Workout Reminders (essential)
          SettingSwitchTile(
            icon: Icons.fitness_center,
            iconColor: AppColors.cyan,
            title: 'Workout Reminders',
            subtitle: 'Daily reminders about your scheduled workouts',
            value: prefs?.workoutReminders ?? true,
            onChanged: (value) => _updatePreference(
              EmailPreferenceType.workoutReminders,
              value,
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Weekly Summary
          SettingSwitchTile(
            icon: Icons.bar_chart,
            iconColor: AppColors.purple,
            title: 'Weekly Summary',
            subtitle: 'Your weekly progress report every Sunday',
            value: prefs?.weeklySummary ?? true,
            onChanged: (value) => _updatePreference(
              EmailPreferenceType.weeklySummary,
              value,
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Coach Tips
          SettingSwitchTile(
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.orange,
            title: 'Coach Tips',
            subtitle: 'AI coach tips and motivational messages',
            value: prefs?.coachTips ?? true,
            onChanged: (value) => _updatePreference(
              EmailPreferenceType.coachTips,
              value,
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Product Updates
          SettingSwitchTile(
            icon: Icons.new_releases_outlined,
            iconColor: AppColors.success,
            title: 'Product Updates',
            subtitle: 'New features and app improvements',
            value: prefs?.productUpdates ?? true,
            onChanged: (value) => _updatePreference(
              EmailPreferenceType.productUpdates,
              value,
            ),
          ),
          Divider(height: 1, color: cardBorder, indent: 50),

          // Promotional (opt-in)
          SettingSwitchTile(
            icon: Icons.local_offer_outlined,
            iconColor: Colors.pink,
            title: 'Promotional',
            subtitle: 'Special offers and discounts',
            value: prefs?.promotional ?? false,
            onChanged: (value) => _updatePreference(
              EmailPreferenceType.promotional,
              value,
            ),
          ),
          Divider(height: 1, color: cardBorder),

          // Quick unsubscribe button
          InkWell(
            onTap: _unsubscribeFromMarketing,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.unsubscribe_outlined,
                    color: AppColors.error.withOpacity(0.8),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unsubscribe from All Marketing',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.error.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          'Keep only essential workout reminders',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog for unsubscribing from marketing emails
class _UnsubscribeConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.unsubscribe_outlined, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Text(
            'Unsubscribe',
            style: TextStyle(color: textPrimary, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will turn off all marketing emails:',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Weekly Summary', textSecondary),
          _buildBulletPoint('Coach Tips', textSecondary),
          _buildBulletPoint('Product Updates', textSecondary),
          _buildBulletPoint('Promotional', textSecondary),
          const SizedBox(height: 12),
          Text(
            'You will still receive essential workout reminders.',
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Unsubscribe',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
