import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/support_provider.dart';

/// Help & Support screen with various support options.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withOpacity(0.2),
                      AppColors.purple.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
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
                      child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
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
                    data: (tickets) => tickets.any((t) => t.hasUnreadUpdates),
                    loading: () => false,
                    error: (_, __) => false,
                  );
                  final unreadCount = ticketsAsync.when(
                    data: (tickets) => tickets.where((t) => t.hasUnreadUpdates).length,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

              // Chat with AI Support
              _HelpOptionCard(
                icon: Icons.smart_toy,
                iconColor: AppColors.cyan,
                title: 'Chat with AI Support',
                subtitle: 'Get instant answers from our AI assistant',
                onTap: () => context.push('/chat'),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 12),

              // Feature Request
              _HelpOptionCard(
                icon: Icons.lightbulb_outline,
                iconColor: AppColors.orange,
                title: 'Feature Request',
                subtitle: 'Suggest new features or improvements',
                onTap: () => _showFeatureRequestSheet(context, isDark),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 12),

              // Send Feedback
              _HelpOptionCard(
                icon: Icons.feedback_outlined,
                iconColor: AppColors.purple,
                title: 'Send Feedback',
                subtitle: 'Tell us about your experience',
                onTap: () => _showFeedbackSheet(context, isDark),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 12),

              // Report a Bug
              _HelpOptionCard(
                icon: Icons.bug_report_outlined,
                iconColor: AppColors.error,
                title: 'Report a Bug',
                subtitle: 'Help us fix issues you encounter',
                onTap: () => _showBugReportSheet(context, isDark),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 24),

              // Section: Contact Us
              Text(
                'CONTACT US',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Email
              _HelpOptionCard(
                icon: Icons.email_outlined,
                iconColor: AppColors.cyan,
                title: 'Email Support',
                subtitle: 'support@fitwiz.app',
                onTap: () => _launchEmail(),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showArrow: false,
                trailing: Icon(Icons.open_in_new, size: 18, color: textSecondary),
              ),

              const SizedBox(height: 24),

              // Section: Follow Us
              Text(
                'FOLLOW US',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Social Networks Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SocialButton(
                      icon: Icons.camera_alt,
                      label: 'Instagram',
                      color: const Color(0xFFE4405F),
                      onTap: () => _launchUrl('https://instagram.com/fitwizapp'),
                    ),
                    _SocialButton(
                      icon: Icons.play_circle_filled,
                      label: 'YouTube',
                      color: const Color(0xFFFF0000),
                      onTap: () => _launchUrl('https://youtube.com/@fitwizapp'),
                    ),
                    _SocialButton(
                      icon: Icons.alternate_email,
                      label: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      onTap: () => _launchUrl('https://twitter.com/fitwizapp'),
                    ),
                    _SocialButton(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () => _launchUrl('https://facebook.com/fitwizapp'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section: Resources
              Text(
                'RESOURCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ
              _HelpOptionCard(
                icon: Icons.quiz_outlined,
                iconColor: AppColors.success,
                title: 'FAQ',
                subtitle: 'Frequently asked questions',
                onTap: () => _launchUrl('https://fitwiz.app/faq'),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showArrow: false,
                trailing: Icon(Icons.open_in_new, size: 18, color: textSecondary),
              ),

              const SizedBox(height: 12),

              // Privacy Policy
              _HelpOptionCard(
                icon: Icons.privacy_tip_outlined,
                iconColor: textSecondary,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _launchUrl('https://fitwiz.app/privacy'),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showArrow: false,
                trailing: Icon(Icons.open_in_new, size: 18, color: textSecondary),
              ),

              const SizedBox(height: 12),

              // Terms of Service
              _HelpOptionCard(
                icon: Icons.description_outlined,
                iconColor: textSecondary,
                title: 'Terms of Service',
                subtitle: 'Our terms and conditions',
                onTap: () => _launchUrl('https://fitwiz.app/terms'),
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showArrow: false,
                trailing: Icon(Icons.open_in_new, size: 18, color: textSecondary),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final uri = Uri.parse('mailto:support@fitwiz.app?subject=FitWiz Support Request');
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

  void _showFeatureRequestSheet(BuildContext context, bool isDark) {
    _showFeedbackBottomSheet(
      context: context,
      isDark: isDark,
      title: 'Feature Request',
      icon: Icons.lightbulb_outline,
      iconColor: AppColors.orange,
      hintText: 'Describe the feature you\'d like to see...',
      submitLabel: 'Submit Request',
    );
  }

  void _showFeedbackSheet(BuildContext context, bool isDark) {
    _showFeedbackBottomSheet(
      context: context,
      isDark: isDark,
      title: 'Send Feedback',
      icon: Icons.feedback_outlined,
      iconColor: AppColors.purple,
      hintText: 'Tell us about your experience...',
      submitLabel: 'Send Feedback',
    );
  }

  void _showBugReportSheet(BuildContext context, bool isDark) {
    _showFeedbackBottomSheet(
      context: context,
      isDark: isDark,
      title: 'Report a Bug',
      icon: Icons.bug_report_outlined,
      iconColor: AppColors.error,
      hintText: 'Describe the issue you encountered...',
      submitLabel: 'Submit Report',
    );
  }

  void _showFeedbackBottomSheet({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String hintText,
    required String submitLabel,
  }) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Text field
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
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
                    borderSide: BorderSide(color: iconColor),
                  ),
                ),
                style: TextStyle(color: textPrimary),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for your $title!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    submitLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
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
                    color: iconColor.withOpacity(0.15),
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
                trailing ?? (showArrow ? Icon(Icons.chevron_right, color: textSecondary) : const SizedBox()),
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
              color: color.withOpacity(0.15),
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
