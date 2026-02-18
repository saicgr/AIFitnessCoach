import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/glass_back_button.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';

/// Paywall Screen 2: Trial Timeline
/// Shows users what to expect during their free trial
class PaywallTimelineScreen extends ConsumerWidget {
  const PaywallTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);
    final now = DateTime.now();
    final chargeDate = now.add(const Duration(days: 7));
    final dateFormat = DateFormat('MMMM d');

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FoldableQuizScaffold(
          headerTitle: '',
          headerOverlay: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassBackButton(
                onTap: () => context.pop(),
              ),
            ),
          ),
          headerExtra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'How your free trial works',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Trust badges
              _TrustItem(
                icon: Icons.lock_outline,
                text: 'Cancel anytime from settings',
                colors: colors,
              ),
              const SizedBox(height: 8),
              _TrustItem(
                icon: Icons.notifications_none,
                text: 'Reminder before you\'re charged',
                colors: colors,
              ),
              const SizedBox(height: 8),
              _TrustItem(
                icon: Icons.credit_card_off_outlined,
                text: 'No charge during trial',
                colors: colors,
              ),
              const SizedBox(height: 8),
              _TrustItem(
                icon: Icons.support_agent,
                text: 'Full support during trial',
                colors: colors,
              ),
              const SizedBox(height: 14),

              // Charge date callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18, color: colors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'First charge: ${dateFormat.format(chargeDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Free tier note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Even without premium, you can use FitWiz completely free for workout tracking, logging sets & reps, and monitoring your progress.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Show title inline only on phone
                if (!isFoldable) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: colors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fitness_center,
                          size: 40,
                          color: colors.accentContrast,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                ],

                if (isFoldable) const SizedBox(height: 16),

                // Timeline
                _TimelineItem(
                  icon: Icons.card_giftcard,
                  iconColor: colors.accent,
                  title: 'Today',
                  subtitle: 'Unlimited workouts, food scanning, injury tracking, skill progressions & more',
                  isFirst: true,
                  isLast: false,
                  colors: colors,
                ),
                _TimelineItem(
                  icon: Icons.notifications_outlined,
                  iconColor: colors.accent,
                  title: 'In 5 days',
                  subtitle: 'We\'ll remind you before your trial ends - no surprises',
                  isFirst: false,
                  isLast: false,
                  colors: colors,
                ),
                _TimelineItem(
                  icon: Icons.credit_card_outlined,
                  iconColor: colors.textSecondary,
                  title: 'In 7 days',
                  subtitle: 'You\'ll be charged on ${dateFormat.format(chargeDate)}. Cancel anytime before - no questions asked.',
                  isFirst: false,
                  isLast: true,
                  colors: colors,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          button: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push('/paywall-pricing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentContrast,
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
        ),
      ),
    );
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
                    color: colors.accent.withOpacity(0.3),
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
                      color: colors.accent.withOpacity(0.3),
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

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeColors colors;

  const _TrustItem({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
