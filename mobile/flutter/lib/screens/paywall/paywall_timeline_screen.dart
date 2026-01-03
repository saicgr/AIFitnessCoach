import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';

/// Paywall Screen 2: Trial Timeline
/// Shows users what to expect during their free trial
class PaywallTimelineScreen extends ConsumerWidget {
  const PaywallTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = DateTime.now();
    final reminderDate = now.add(const Duration(days: 5));
    final chargeDate = now.add(const Duration(days: 7));
    final dateFormat = DateFormat('MMMM d');

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button only (no X on this screen)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: colors.cyan,
                          size: 28,
                        ),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: colors.cyan,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Logo/Mascot
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.cyan,
                            colors.cyanDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'How your free',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'trial works',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Timeline
                    _TimelineItem(
                      icon: Icons.card_giftcard,
                      iconColor: Colors.amber,
                      title: 'Today',
                      subtitle: 'Get unlimited access to all AI Coach features',
                      isFirst: true,
                      isLast: false,
                      colors: colors,
                    ),
                    _TimelineItem(
                      icon: Icons.notifications_outlined,
                      iconColor: colors.cyan,
                      title: 'In 5 days',
                      subtitle: 'Get a reminder your trial is about to end',
                      isFirst: false,
                      isLast: false,
                      colors: colors,
                    ),
                    _TimelineItem(
                      icon: Icons.credit_card_outlined,
                      iconColor: colors.textSecondary,
                      title: 'In 7 days',
                      subtitle: 'You\'ll be charged based on your selected plan on ${dateFormat.format(chargeDate)}. Cancel anytime before to avoid charges.',
                      isFirst: false,
                      isLast: true,
                      colors: colors,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/paywall-pricing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _skipToFree(BuildContext context, WidgetRef ref) async {
    await ref.read(subscriptionProvider.notifier).skipToFree();
    if (context.mounted) {
      context.go('/home');
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final ThemeColors colors;

  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isFirst,
    required this.isLast,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Top line
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: colors.cyan.withOpacity(0.3),
                  ),
                // Dot with icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                // Bottom line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.cyan.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
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
