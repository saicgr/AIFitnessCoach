import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/glass_back_button.dart';
import '../onboarding/widgets/foldable_quiz_scaffold.dart';

import '../../l10n/generated/app_localizations.dart';

/// Signature v2 single orange accent.
const Color _kSigAccent = AppColors.orange;

/// Dark ink for text/iconography sitting on the orange CTA fill (signature-v2).
const Color _kOnAccent = Color(0xFF160B03);

/// Paywall Screen 2: Trial Timeline
/// Shows users what to expect during their free trial
class PaywallTimelineScreen extends ConsumerWidget {
  const PaywallTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track paywall timeline screen view
    Future.microtask(() {
      ref
          .read(posthogServiceProvider)
          .capture(eventName: 'paywall_timeline_viewed');
    });

    final colors = ref.colors(context);
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(
      windowState,
    );
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
              alignment: AlignmentDirectional.centerStart,
              child: GlassBackButton(onTap: () => context.pop()),
            ),
          ),
          headerExtra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                AppLocalizations.of(
                  context,
                ).paywallTimelineHowYourFreeTrial.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 26,
                  color: colors.textPrimary,
                  height: 1.1,
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
                        AppLocalizations.of(
                          context,
                        )!.paywallTimelineScreenFirstCharge(
                          dateFormat.format(chargeDate),
                        ),
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

              // Cancel anytime reassurance
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
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).paywallTimelineCancelAnytimeDuringOr,
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
                    AppLocalizations.of(
                      context,
                    ).paywallTimelineHowYourFree.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 28,
                      height: 1.05,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).paywallTimelineTrialWorks.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 28,
                      height: 1.05,
                      color: _kSigAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (isFoldable) const SizedBox(height: 16),

                // Timeline
                _TimelineItem(
                  icon: Icons.card_giftcard,
                  iconColor: _kSigAccent,
                  title: AppLocalizations.of(context).todayScoreCardToday,
                  subtitle: AppLocalizations.of(
                    context,
                  ).paywallTimelineUnlimitedWorkoutsFoodScann,
                  isFirst: true,
                  isLast: false,
                  colors: colors,
                ),
                _TimelineItem(
                  icon: Icons.notifications_outlined,
                  iconColor: _kSigAccent,
                  title: AppLocalizations.of(context).paywallTimelineIn5Days,
                  subtitle: AppLocalizations.of(
                    context,
                  ).paywallTimelineWeLlRemindYou,
                  isFirst: false,
                  isLast: false,
                  colors: colors,
                ),
                _TimelineItem(
                  icon: Icons.credit_card_outlined,
                  iconColor: colors.textSecondary,
                  title: AppLocalizations.of(context).paywallTimelineIn7Days,
                  subtitle: AppLocalizations.of(context)!
                      .paywallTimelineScreenYouLlBeCharged(
                        dateFormat.format(chargeDate),
                      ),
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
                  backgroundColor: _kSigAccent,
                  foregroundColor: _kOnAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).onboardingContinueButton.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Barlow Condensed',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: _kOnAccent,
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
                  child: Icon(icon, color: iconColor, size: 22),
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
        Icon(icon, size: 18, color: _kSigAccent),
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
