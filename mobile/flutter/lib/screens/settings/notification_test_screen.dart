import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../data/services/notification_service.dart';

/// Screen for testing all notification types via Firebase
class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends ConsumerState<NotificationTestScreen> {
  String? _sendingType;
  String? _lastResult;

  Future<void> _sendNotification(String type, String endpoint, {Map<String, dynamic>? queryParams}) async {
    setState(() {
      _sendingType = type;
      _lastResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final notificationService = ref.read(notificationServiceProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Ensure FCM token is registered with backend first
      final fcmToken = notificationService.fcmToken;
      if (fcmToken == null) {
        throw Exception('No FCM token available. Please enable notifications.');
      }
      await notificationService.registerTokenWithBackend(apiClient, userId);

      String url = '/notifications/$endpoint/$userId';
      if (queryParams != null && queryParams.isNotEmpty) {
        final params = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
        url += '?$params';
      }

      await apiClient.post(url);

      setState(() {
        _lastResult = '✅ $type sent successfully!';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _sendingType = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Testing',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Result Banner
          if (_lastResult != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lastResult!.startsWith('✅')
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lastResult!.startsWith('✅')
                      ? AppColors.success
                      : AppColors.error,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastResult!.startsWith('✅') ? Icons.check_circle : Icons.error,
                    color: _lastResult!.startsWith('✅') ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lastResult!,
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: textMuted),
                    onPressed: () => setState(() => _lastResult = null),
                  ),
                ],
              ),
            ),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These notifications are sent via Firebase Cloud Messaging through your backend.',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Workout Notifications
          _buildSectionHeader('Workout Notifications', Icons.fitness_center, AppColors.cyan, textPrimary),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationButton(
                  icon: Icons.alarm,
                  title: 'Workout Reminder',
                  subtitle: '"Time to train! 💪"',
                  color: AppColors.cyan,
                  onTap: () => _sendNotification('Workout Reminder', 'workout-reminder'),
                  isLoading: _sendingType == 'Workout Reminder',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.sentiment_dissatisfied,
                  title: 'Guilt (1 day missed)',
                  subtitle: '"Your muscles miss you! 💪"',
                  color: AppColors.orange,
                  onTap: () => _sendNotification('Guilt (1 day)', 'guilt', queryParams: {'days_missed': 1}),
                  isLoading: _sendingType == 'Guilt (1 day)',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.sentiment_very_dissatisfied,
                  title: 'Guilt (2 days missed)',
                  subtitle: '"Your AI Coach is getting lonely... 🥺"',
                  color: AppColors.orange,
                  onTap: () => _sendNotification('Guilt (2 days)', 'guilt', queryParams: {'days_missed': 2}),
                  isLoading: _sendingType == 'Guilt (2 days)',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.warning_amber,
                  title: 'Guilt (3+ days missed)',
                  subtitle: '"It\'s been X days! 😱"',
                  color: AppColors.error,
                  onTap: () => _sendNotification('Guilt (3+ days)', 'guilt', queryParams: {'days_missed': 5}),
                  isLoading: _sendingType == 'Guilt (3+ days)',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nutrition Notifications
          _buildSectionHeader('Nutrition Notifications', Icons.restaurant, AppColors.green, textPrimary),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationButton(
                  icon: Icons.free_breakfast,
                  title: 'Breakfast Reminder',
                  subtitle: '"Time to log your breakfast! 📸"',
                  color: AppColors.green,
                  onTap: () => _sendNotification('Breakfast Reminder', 'nutrition-reminder', queryParams: {'meal_type': 'breakfast'}),
                  isLoading: _sendingType == 'Breakfast Reminder',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.lunch_dining,
                  title: 'Lunch Reminder',
                  subtitle: '"Time to log your lunch! 📸"',
                  color: AppColors.green,
                  onTap: () => _sendNotification('Lunch Reminder', 'nutrition-reminder', queryParams: {'meal_type': 'lunch'}),
                  isLoading: _sendingType == 'Lunch Reminder',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.dinner_dining,
                  title: 'Dinner Reminder',
                  subtitle: '"Time to log your dinner! 📸"',
                  color: AppColors.green,
                  onTap: () => _sendNotification('Dinner Reminder', 'nutrition-reminder', queryParams: {'meal_type': 'dinner'}),
                  isLoading: _sendingType == 'Dinner Reminder',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hydration Notifications
          _buildSectionHeader('Hydration Notifications', Icons.water_drop, AppColors.electricBlue, textPrimary),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationButton(
                  icon: Icons.water_drop_outlined,
                  title: 'Low Progress (40%)',
                  subtitle: '"Stay hydrated! 💧 You\'re at 40%"',
                  color: AppColors.electricBlue,
                  onTap: () => _sendNotification('Hydration Low', 'hydration-reminder', queryParams: {'current_ml': 800, 'goal_ml': 2000}),
                  isLoading: _sendingType == 'Hydration Low',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                Divider(height: 1, indent: 56, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildNotificationButton(
                  icon: Icons.water_drop,
                  title: 'Good Progress (70%)',
                  subtitle: '"Keep it up! 💧 Almost there!"',
                  color: AppColors.electricBlue,
                  onTap: () => _sendNotification('Hydration Good', 'hydration-reminder', queryParams: {'current_ml': 1400, 'goal_ml': 2000}),
                  isLoading: _sendingType == 'Hydration Good',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Other Notifications
          _buildSectionHeader('Other Notifications', Icons.notifications, AppColors.purple, textPrimary),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildNotificationButton(
                  icon: Icons.science_outlined,
                  title: 'Basic Test',
                  subtitle: '"Your AI Coach is ready! 💪"',
                  color: AppColors.purple,
                  onTap: () => _sendTestNotification(),
                  isLoading: _sendingType == 'Basic Test',
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _sendingType = 'Basic Test';
      _lastResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final notificationService = ref.read(notificationServiceProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get actual FCM token
      final fcmToken = notificationService.fcmToken;
      if (fcmToken == null) {
        throw Exception('No FCM token available. Please enable notifications.');
      }

      // First register the token with backend
      await notificationService.registerTokenWithBackend(apiClient, userId);

      // Then send the test notification
      await apiClient.post(
        '/notifications/test',
        data: {
          'user_id': userId,
          'fcm_token': fcmToken,
        },
      );

      setState(() {
        _lastResult = '✅ Basic Test sent successfully!';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _sendingType = null;
      });
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, Color textColor) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
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

  Widget _buildNotificationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
    required Color textPrimary,
    required Color textMuted,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(
                Icons.send,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
