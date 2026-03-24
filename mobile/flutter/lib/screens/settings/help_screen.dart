import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../data/providers/support_provider.dart';
import '../../data/services/haptic_service.dart';

/// Help & Support screen with various support options.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final pillColor = isDark ? const Color(0xFF1C1C1E) : elevated;
    final pillBorder = isDark
        ? null
        : Border.all(color: cardBorder.withValues(alpha: 0.3));
    final pillShadow = BoxShadow(
      color: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 72,
                bottom: 80 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan.withValues(alpha: 0.2),
                          AppColors.purple.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.cyan, AppColors.purple],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.support_agent,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose an option below to get support',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // My Support Tickets
                  Consumer(
                    builder: (context, ref, child) {
                      final ticketsAsync = ref.watch(supportTicketsProvider);
                      final hasUnread = ticketsAsync.when(
                        data: (tickets) =>
                            tickets.any((t) => t.hasUnreadUpdates),
                        loading: () => false,
                        error: (_, __) => false,
                      );
                      final unreadCount = ticketsAsync.when(
                        data: (tickets) =>
                            tickets.where((t) => t.hasUnreadUpdates).length,
                        loading: () => 0,
                        error: (_, __) => 0,
                      );

                      return _HelpOptionCard(
                        icon: Icons.confirmation_number_outlined,
                        iconColor: AppColors.purple,
                        title: 'My Support Tickets',
                        subtitle: 'View and manage your support requests',
                        onTap: () => context.push('/support-tickets'),
                        elevated: elevated,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        trailing: hasUnread
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Feature Request
                  _HelpOptionCard(
                    icon: Icons.lightbulb_outline,
                    iconColor: AppColors.orange,
                    title: 'Feature Request',
                    subtitle: 'Vote & suggest features',
                    onTap: () => context.push('/features'),
                    elevated: elevated,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 24),

                  // Section: Contact Us
                  _SectionHeader(text: 'CONTACT US', color: textSecondary),
                  const SizedBox(height: 12),

                  _HelpOptionCard(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.cyan,
                    title: 'Email Support',
                    subtitle: AppLinks.supportEmail,
                    onTap: () => _launchEmail(),
                    elevated: elevated,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showArrow: false,
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: textSecondary),
                  ),

                  // Section: Follow Us (only if social links exist)
                  if (AppLinks.activeSocialLinks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(text: 'FOLLOW US', color: textSecondary),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            AppLinks.activeSocialLinks.entries.map((e) {
                          return _SocialButton(
                            icon: _socialIcon(e.key),
                            label: _socialLabel(e.key),
                            color: _socialColor(e.key),
                            onTap: () => _launchUrl(e.value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Section: Resources
                  _SectionHeader(text: 'RESOURCES', color: textSecondary),
                  const SizedBox(height: 12),

                  _HelpOptionCard(
                    icon: Icons.quiz_outlined,
                    iconColor: AppColors.success,
                    title: 'FAQ',
                    subtitle: 'Frequently asked questions',
                    onTap: () => _launchUrl(AppLinks.website.isNotEmpty
                        ? '${AppLinks.website}/faq'
                        : 'https://fitwiz.us/faq'),
                    elevated: elevated,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showArrow: false,
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: textSecondary),
                  ),

                  const SizedBox(height: 12),

                  _HelpOptionCard(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: textSecondary,
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => _launchUrl(AppLinks.privacyPolicy.isNotEmpty
                        ? AppLinks.privacyPolicy
                        : 'https://fitwiz.us/privacy'),
                    elevated: elevated,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showArrow: false,
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: textSecondary),
                  ),

                  const SizedBox(height: 12),

                  _HelpOptionCard(
                    icon: Icons.description_outlined,
                    iconColor: textSecondary,
                    title: 'Terms of Service',
                    subtitle: 'Our terms and conditions',
                    onTap: () =>
                        _launchUrl(AppLinks.termsOfService.isNotEmpty
                            ? AppLinks.termsOfService
                            : 'https://fitwiz.us/terms'),
                    elevated: elevated,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    showArrow: false,
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: textSecondary),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Floating pill app bar — same style as Settings screen
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back button circle
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    context.pop();
                  },
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(22),
                      border: pillBorder,
                      boxShadow: [pillShadow],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : AppColorsLight.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title pill
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(22),
                      border: pillBorder,
                      boxShadow: [pillShadow],
                    ),
                    child: Center(
                      child: Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColorsLight.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _socialIcon(String key) {
    switch (key) {
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle_filled;
      case 'twitter':
        return Icons.alternate_email;
      case 'discord':
        return Icons.forum_outlined;
      case 'reddit':
        return Icons.reddit;
      case 'facebook':
        return Icons.facebook;
      case 'tiktok':
        return Icons.music_note;
      case 'snapchat':
        return Icons.snapchat;
      default:
        return Icons.link;
    }
  }

  static String _socialLabel(String key) {
    switch (key) {
      case 'twitter':
        return 'X';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  static Color _socialColor(String key) {
    switch (key) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'discord':
        return const Color(0xFF5865F2);
      case 'reddit':
        return const Color(0xFFFF4500);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      default:
        return const Color(0xFF666666);
    }
  }

  void _launchEmail() async {
    final uri = Uri.parse(
        'mailto:${AppLinks.supportEmail}?subject=FitWiz Support Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Section header text
class _SectionHeader extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionHeader({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// Help option card widget
class _HelpOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final bool showArrow;
  final Widget? trailing;

  const _HelpOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.showArrow = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    (showArrow
                        ? Icon(Icons.chevron_right, color: textSecondary)
                        : const SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Social button widget
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
